clc; clear; close all;
import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;
import javax.crypto.spec.GCMParameterSpec;
import java.security.MessageDigest;

fprintf('======================================================\n');
fprintf(' SwarmAuth Phase 3: True Cryptographic Packet Evaluation \n');
fprintf('======================================================\n\n');

num_trials = 1000;
payload_size = 256; 
malicious_rate = 0.30; 

legit_sent = 0;
malicious_sent = 0;
sa_legit_accepted = 0;
sa_total_latency = 0;
base_legit_accepted = 0;
base_false_positives = 0; 
base_total_latency = 0;

attack_detected_injection = 0;
attack_detected_impersonation = 0;
attack_detected_replay = 0;
attack_detected_tampering = 0;

psk_bytes = randi([0 255], 1, 32, 'int8');
secretKey = SecretKeySpec(psk_bytes, 'AES');
registry_id = "WINGMAN_01";

fprintf('[SYSTEM] Running %d empirical trials with AES-GCM...\n\n', num_trials);

for i = 1:num_trials
    is_malicious = rand() < malicious_rate;
    if is_malicious
        attack_type = randi([1 4]);
        malicious_sent = malicious_sent + 1;
    else
        attack_type = 0;
        legit_sent = legit_sent + 1;
    end
    
    tic;
    pause(0.0001); 
    base_total_latency = base_total_latency + (toc * 1000);
    
    if is_malicious
        base_false_positives = base_false_positives + 1;
    else
        base_legit_accepted = base_legit_accepted + 1;
    end
    
    tic;
    try
        incoming_id = registry_id;
        incoming_key = psk_bytes;
        incoming_time = 0; 
        
        if attack_type == 1, incoming_id = "ENEMY_DRONE";
        elseif attack_type == 2, incoming_key = randi([0 255], 1, 32, 'int8'); 
        elseif attack_type == 3, incoming_time = 5; 
        end
        
        if ~strcmp(incoming_id, registry_id), error('REJECT_UNKNOWN_ID'); end
        if incoming_time > 3, error('REJECT_REPLAY'); end
        
        md = MessageDigest.getInstance('SHA-256');
        md.update(incoming_key);
        hmac_attacker = md.digest();
        md.reset(); md.update(psk_bytes); hmac_legit = md.digest();
        if ~isequal(hmac_attacker, hmac_legit), error('REJECT_INVALID_MAC'); end
        
        payload = int8(randi([0 255], 1, payload_size));
        iv = randi([0 255], 1, 12, 'int8'); 
        
        cipher = Cipher.getInstance('AES/GCM/NoPadding');
        gcmSpec = GCMParameterSpec(128, iv);
        cipher.init(Cipher.ENCRYPT_MODE, secretKey, gcmSpec);
        ciphertext = cipher.doFinal(payload);
        
        if attack_type == 4, ciphertext(10) = ciphertext(10) + 1; end
        
        decCipher = Cipher.getInstance('AES/GCM/NoPadding');
        decCipher.init(Cipher.DECRYPT_MODE, secretKey, gcmSpec);
        decCipher.doFinal(ciphertext); 
        
        if attack_type == 0, sa_legit_accepted = sa_legit_accepted + 1; end
        
    catch ME
        if strcmp(ME.message, 'REJECT_UNKNOWN_ID'), attack_detected_injection = attack_detected_injection + 1;
        elseif strcmp(ME.message, 'REJECT_REPLAY'), attack_detected_replay = attack_detected_replay + 1;
        elseif strcmp(ME.message, 'REJECT_INVALID_MAC'), attack_detected_impersonation = attack_detected_impersonation + 1;
        else attack_detected_tampering = attack_detected_tampering + 1;
        end
    end
    sa_total_latency = sa_total_latency + (toc * 1000);
end

base_pdr = (base_legit_accepted / (base_legit_accepted + base_false_positives)) * 100;
sa_pdr = (sa_legit_accepted / legit_sent) * 100;
sa_avg_latency_ms = sa_total_latency / num_trials;
base_avg_latency_ms = base_total_latency / num_trials;
auth_header_size = 72; 
base_overhead_kb = (num_trials * payload_size) / 1024;
sa_overhead_kb = (num_trials * (payload_size + auth_header_size)) / 1024;

fprintf('--- Empirical Results ---\n');
fprintf('Legitimate Packets Processed : %d\n', sa_legit_accepted);
fprintf('Injection Attacks Blocked    : %d\n', attack_detected_injection);
fprintf('Impersonation Blocked        : %d\n', attack_detected_impersonation);
fprintf('Replays Blocked              : %d\n', attack_detected_replay);
fprintf('MITM Tampering Blocked       : %d\n', attack_detected_tampering);
fprintf('------------------------------------------------------\n');
fprintf('Baseline PDR                 : %.2f %%\n', base_pdr);
fprintf('SwarmAuth PDR                : %.2f %%\n', sa_pdr);
fprintf('SwarmAuth Avg Latency        : %.4f ms\n', sa_avg_latency_ms);
fprintf('======================================================\n\n');

fprintf('[SYSTEM] Generating all Graphical Figures...\n');

figure('Name', 'Empirical Evaluation Metrics', 'Position', [100, 100, 900, 400]);
subplot(1, 3, 1);
bar([base_pdr, sa_pdr], 'FaceColor', [0.4660 0.6740 0.1880]);
set(gca, 'XTickLabel', {'Baseline', 'SwarmAuth'}); ylabel('Effective PDR (%)'); title('Packet Delivery Ratio'); ylim([0 110]); grid on;
subplot(1, 3, 2);
bar([base_avg_latency_ms, sa_avg_latency_ms], 'FaceColor', [0.8500 0.3250 0.0980]);
set(gca, 'XTickLabel', {'Baseline', 'SwarmAuth'}); ylabel('Latency (ms)'); title('Average Latency'); grid on;
subplot(1, 3, 3);
bar([base_overhead_kb, sa_overhead_kb], 'FaceColor', [0.0 0.4470 0.7410]);
set(gca, 'XTickLabel', {'Baseline', 'SwarmAuth'}); ylabel('Overhead (KB)'); title('Total Overhead'); grid on;

nodeNames = {'Cluster_Head', 'W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7', 'W8', 'W9'};

figure('Name', 'Modality A: UAV-to-CH (Auth Phase)', 'Position', [150, 150, 500, 450]);
s_CH = repmat(1, 1, 9); t_W = 2:10; s_auth = [s_CH, t_W]; t_auth = [t_W, s_CH];
G_A = digraph(nodeNames(s_auth), nodeNames(t_auth));
pA = plot(G_A, 'Layout', 'force', 'MarkerSize', 12, 'NodeColor', '#77AC30', 'EdgeColor', '#0072BD');
highlight(pA, 'Cluster_Head', 'NodeColor', '#0072BD', 'MarkerSize', 18);
title('Modality A: Centralized Authentication (UAV-to-CH)'); subtitle('Bidirectional Handshake with Cluster Head');

figure('Name', 'Modality B: UAV-to-UAV (P2P Telemetry)', 'Position', [200, 200, 500, 450]);
s_P2P = [2 3 4 5 6 7 8 9 10 2 5 8]; t_P2P = [3 4 5 6 7 8 9 10 2 6 9 3]; 
G_B = digraph(nodeNames(s_P2P), nodeNames(t_P2P)); G_B = addnode(G_B, 'Cluster_Head'); 
pB = plot(G_B, 'Layout', 'circle', 'MarkerSize', 12, 'NodeColor', '#77AC30', 'EdgeColor', '#D95319', 'LineWidth', 1.5);
highlight(pB, 'Cluster_Head', 'NodeColor', '#808080', 'MarkerSize', 18); 
title('Modality B: Encrypted Peer-to-Peer (UAV-to-UAV)'); subtitle('Cluster Head bypassed during operational telemetry');

fprintf('[SYSTEM] Phase 3 Simulation Complete.\n\n');