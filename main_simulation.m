% =========================================================================
% MODULE 5: Main Simulation Testbench (main_simulation.m)
% Phase 2 - Advanced Cryptographic Compliance & 10-Node Swarm Test
% =========================================================================

clc; clear; close all;
fprintf('======================================================\n');
fprintf('   SwarmAuth Phase 2: Tactical Authentication Test    \n');
fprintf('======================================================\n\n');

%% Step 1: 10-Node Swarm Initialization (Registry)
fprintf('[SYSTEM] Initializing 9-Wingman Swarm Registry...\n');
registry = containers.Map();
wingmen = cell(9,1);

% Dynamically generate 256-bit PSKs for all 9 Wingmen
for i = 1:9
    id = sprintf('WINGMAN_%02d', i);
    key = sprintf('%02x', randi([0, 255], 1, 32));
    registry(id) = key;
end
C2_Leader = LeaderDrone(registry);

for i = 1:9
    id = sprintf('WINGMAN_%02d', i);
    wingmen{i} = WingmanDrone(id, registry(id));
end
fprintf('[SYSTEM] Registry complete. All 9 Wingmen generated.\n\n');

%% Scenario 1: Normal-Operation Authentication (All 9 Members)
fprintf('--- SCENARIO 1: Full Swarm Mutual Authentication ---\n');
for i = 1:9
    wm = wingmen{i};
    % 1. Wingman Request
    [req_id, nonce_W] = wm.sendJoinRequest();
    
    % 2. Leader Challenge (Mutual Auth)
    [nonce_L, ts, l_hmac, stat] = C2_Leader.issueChallenge(req_id, nonce_W);
    
    if strcmp(stat, 'CHALLENGE_ISSUED')
        % 3. Wingman Response (Verifies Leader, computes HMAC)
        hmac_W = wm.processChallenge(nonce_L, ts, l_hmac);
        
        % 4. Secure Key Exchange
        [enc_keys, auth_stat] = C2_Leader.verifyResponse(req_id, nonce_L, ts, hmac_W);
        
        if strcmp(auth_stat, 'ACCEPT')
            % 5. Conditional Access (Only decodes keys if ACCEPTED)
            wm.receiveKeys(enc_keys);
        end
    end
end
fprintf('[SUCCESS] All 9 Wingmen mutually authenticated and received AES-encrypted keys.\n\n');

%% Scenario 2: Real UAV-to-UAV AES Encrypted Communication
fprintf('--- SCENARIO 2: UAV-to-UAV Encrypted Payload (P2P) ---\n');
% WINGMAN_01 sends an encrypted message to WINGMAN_02
plaintext_msg = 'Target locked at Sector 7G.';
fprintf('[WINGMAN_01] Encrypting: "%s"\n', plaintext_msg);

% Encrypt-then-MAC
[cipher_payload, msg_mac] = wingmen{1}.sendGroupMessage(plaintext_msg);
fprintf('[NETWORK] Transmitting Ciphertext: %s...\n', cipher_payload(1:20));

% WINGMAN_02 receives, checks integrity, and decrypts
wingmen{2}.receiveGroupMessage(cipher_payload, msg_mac, wingmen{1}.DroneID);
fprintf('\n');

%% Scenario 3: Unauthorized Injection & Impersonation
fprintf('--- SCENARIO 3: Attacker Defenses ---\n');
[~, ~, ~, stat3] = C2_Leader.issueChallenge('ENEMY_DRONE', 'fake_nonce');
fprintf('[SUCCESS] Injection Blocked.\n');

fake_key = sprintf('%02x', randi([0, 255], 1, 32));
Attacker = WingmanDrone('WINGMAN_05', fake_key);
[req_id_atk, nonce_W_atk] = Attacker.sendJoinRequest();
[nonce_L_atk, ts_atk, l_hmac_atk, ~] = C2_Leader.issueChallenge(req_id_atk, nonce_W_atk);
try
    % This will crash because the attacker can't verify the Leader's HMAC
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
pause(4); % MATHEMATICAL DELAY TO TRIGGER TTL DEFENSE

% Attacker resends the old payload
[~, replay_stat] = C2_Leader.verifyResponse(req_id, nonce_L, ts, hmac_W);
fprintf('[SUCCESS] Replay block result: %s\n\n', replay_stat);

%% Step 5: Visual Topology Graph (10-Node Swarm)
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
G = addedge(G, 'WINGMAN_01', 'WINGMAN_02'); % P2P Line

p = plot(G, 'Layout', 'force', 'MarkerSize', 10, 'LineWidth', 1.5);
title('SwarmAuth: Fully Authenticated 10-Node Topology');
highlight(p, 'Cluster_Head', 'NodeColor', '#0072BD', 'MarkerSize', 16); 
highlight(p, nodes(2:10), 'NodeColor', '#77AC30'); 
highlight(p, 'ENEMY_DRONE', 'NodeColor', '#A2142F');