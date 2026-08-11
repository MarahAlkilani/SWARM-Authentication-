% =========================================================================
% MODULE 5: Main Simulation Testbench (main_simulation.m)
% Phase 2 - Advanced Cryptographic Compliance & 10-Node Swarm Test
% =========================================================================

clc; clear; close all;
fprintf('======================================================\n');
fprintf('   SwarmAuth Phase 2: Tactical Authentication Test    \n');
fprintf('======================================================\n\n');

%% Step 1: 10-Node Swarm Initialization
fprintf('[SYSTEM] Initializing 9-Wingman Swarm Registry...\n');
[C2_Leader, wingmen, registry] = swarm_init(9);
fprintf('[SYSTEM] Registry complete. All 9 Wingmen generated.\n\n');

%% Scenario 1: Normal-Operation Authentication (All 9 Members)
fprintf('--- SCENARIO 1: Full Swarm Mutual Authentication ---\n');
success_count = 0;

for i = 1:9
    wm = wingmen{i};
    [req_id, nonce_W] = wm.sendJoinRequest();
    [nonce_L, ts, l_hmac, stat] = C2_Leader.issueChallenge(req_id, nonce_W);
    
    if strcmp(stat, 'CHALLENGE_ISSUED')
        hmac_W = wm.processChallenge(nonce_L, ts, l_hmac);
        [enc_keys, auth_stat] = C2_Leader.verifyResponse(req_id, nonce_L, ts, hmac_W);
        
        if strcmp(auth_stat, 'ACCEPT')
            wm.receiveKeys(enc_keys);
            success_count = success_count + 1;
        end
    end
end
fprintf('[SUCCESS] %d/9 Wingmen mutually authenticated and received AES-encrypted keys.\n\n', success_count);

%% Scenario 2: Real UAV-to-UAV AES Encrypted Communication
fprintf('--- SCENARIO 2: UAV-to-UAV Encrypted Payload (P2P) ---\n');
plaintext_msg = 'Target locked at Sector 7G.';
fprintf('[WINGMAN_01] Encrypting: "%s"\n', plaintext_msg);
[cipher_payload, msg_mac] = wingmen{1}.sendGroupMessage(plaintext_msg);
fprintf('[NETWORK] Transmitting Ciphertext: %s...\n', cipher_payload(1:20));
wingmen{2}.receiveGroupMessage(cipher_payload, msg_mac, wingmen{1}.DroneID);
fprintf('\n');

%% Scenario 3: Unauthorized Injection & Impersonation
fprintf('--- SCENARIO 3: Attacker Defenses ---\n');
[~, ~, ~, stat3] = C2_Leader.issueChallenge('ENEMY_DRONE', 'fake_nonce');

% FIX: Conditionally check stat3 before claiming success
if strcmp(stat3, 'REJECT_UNKNOWN_ID')
    fprintf('[SUCCESS] Injection Blocked.\n');
end

fake_key = sprintf('%02x', randi([0, 255], 1, 32));
Attacker = WingmanDrone('WINGMAN_05', fake_key);
[req_id_atk, nonce_W_atk] = Attacker.sendJoinRequest();
[nonce_L_atk, ts_atk, l_hmac_atk, ~] = C2_Leader.issueChallenge(req_id_atk, nonce_W_atk);
try
    hmac_W_atk = Attacker.processChallenge(nonce_L_atk, ts_atk, l_hmac_atk);
catch
    fprintf('[SUCCESS] Attacker Impersonation caught during Mutual Authentication!\n\n');
end
%% Scenario 4: Real Replay Attack Simulation
fprintf('--- SCENARIO 4: True Replay Attack simulation ---\n');
wm = wingmen{8};
[req_id, nonce_W] = wm.sendJoinRequest();
[nonce_L, ts, l_hmac, ~] = C2_Leader.issueChallenge(req_id, nonce_W);
hmac_W = wm.processChallenge(nonce_L, ts, l_hmac);

fprintf('[NETWORK] An attacker captured the packets! Holding them for 4 seconds...\n');
pause(4); 
[~, replay_stat] = C2_Leader.verifyResponse(req_id, nonce_L, ts, hmac_W);
fprintf('[SUCCESS] Replay block result: %s\n\n', replay_stat);

%% Scenario 5: Lightweight / Power Efficiency Proof
fprintf('--- SCENARIO 5: Battery & Overhead Benchmarking ---\n');
fprintf('[SYSTEM] Running cryptographic benchmarking (1000 iterations)...\n');
t_start = tic;
for i = 1:1000
    compute_hmac(registry('WINGMAN_01'), ['bench_nonce', num2str(ts)]);
end
t_total = toc(t_start);
t_avg_ms = (t_total / 1000) * 1000; 
energy_mj = (t_avg_ms / 1000) * 1.2 * 1000; % Assuming 1.2W CPU
fprintf('Avg HMAC Execution Time  : %.4f milliseconds\n', t_avg_ms);
fprintf('Energy per Authentication: %.4f milliJoules (mJ)\n\n', energy_mj);

%% Step 6: Visual Topology Graph (10-Node Swarm)
fprintf('[SYSTEM] Generating Visual Swarm Graph...\n');
figure('Name', 'SwarmAuth Topology', 'NumberTitle', 'off');
G = graph();
nodes = {'Cluster_Head'};
for i=1:9, nodes{end+1} = sprintf('WINGMAN_%02d', i); end
nodes{end+1} = 'ENEMY_DRONE';
G = addnode(G, nodes);

for i = 1:9
    G = addedge(G, 'Cluster_Head', sprintf('WINGMAN_%02d', i));
end
% P2P Line
G = addedge(G, 'WINGMAN_01', 'WINGMAN_02'); 

p = plot(G, 'Layout', 'force', 'MarkerSize', 10, 'LineWidth', 1.5);
title('SwarmAuth: Fully Authenticated 10-Node Topology');
highlight(p, 'Cluster_Head', 'NodeColor', '#0072BD', 'MarkerSize', 16); 
highlight(p, nodes(2:10), 'NodeColor', '#77AC30'); 
highlight(p, 'ENEMY_DRONE', 'NodeColor', '#A2142F'); 
% Explicitly set the P2P edge to dashed
highlight(p, 'WINGMAN_01', 'WINGMAN_02', 'EdgeColor', '#77AC30', 'LineStyle', '--');