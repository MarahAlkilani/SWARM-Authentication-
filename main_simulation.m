% =========================================================================
% MODULE 5: Main Simulation Testbench (main_simulation.m)
% SwarmAuth Phase 2 - Tactical Drone Swarm Authentication
% =========================================================================

clc; clear; close all;
fprintf('======================================================\n');
fprintf('   SwarmAuth Phase 2: Tactical Authentication Test    \n');
fprintf('======================================================\n\n');

%% Step 1: Initialization & Registry Setup
fprintf('[SYSTEM] Initializing C2 Leader Registry...\n');

% Simulate the offline pre-flight registration (Module 1)
registry = containers.Map();
secret_key_01 = '7A3B9C2E5D8F1A4B7C9D2E5F8A1B4C7D'; % 256-bit Hex Key
secret_key_02 = 'F1A4B7C9D2E5F8A1B4C7D7A3B9C2E5D8'; % 256-bit Hex Key
registry('WINGMAN_01') = secret_key_01;
registry('WINGMAN_02') = secret_key_02;

% Instantiate the Leader (C2 Node)
C2_Leader = LeaderDrone(registry);

% Instantiate legitimate Wingmen
Wingman1 = WingmanDrone('WINGMAN_01', secret_key_01);
Wingman2 = WingmanDrone('WINGMAN_02', secret_key_02);

fprintf('[SYSTEM] Swarm initialization complete.\n\n');

%% Scenario 1: Legitimate Authentication (Wingman 1)
fprintf('--- SCENARIO 1: Legitimate Authentication ---\n');

% 1. Wingman sends join request
req_id = Wingman1.sendJoinRequest();

% 2. Leader receives request and issues challenge
[nonce, timestamp, status] = C2_Leader.issueChallenge(req_id);

if strcmp(status, 'CHALLENGE_ISSUED')
    % 3. Wingman computes response
    hmac_response = Wingman1.computeResponse(nonce, timestamp);

    % 4. Leader verifies response
    [session_key, auth_status] = C2_Leader.verifyResponse(req_id, nonce, timestamp, hmac_response);

    if strcmp(auth_status, 'ACCEPT')
        Wingman1.SessionKey = session_key;
        Wingman1.State = 'SECURE_SESSION';
        fprintf('[SUCCESS] Wingman 1 successfully authenticated and session key established.\n');
    end
end
fprintf('\n');

%% Scenario 2: Unauthorized Node Injection
fprintf('--- SCENARIO 2: Unauthorized Node Injection ---\n');

% Unknown drone tries to join
unknown_id = 'ENEMY_DRONE';
fprintf('[%s] Attempting to send Join Request...\n', unknown_id);

% Leader receives request
[~, ~, status2] = C2_Leader.issueChallenge(unknown_id);

if strcmp(status2, 'REJECT_UNKNOWN_ID')
    fprintf('[SUCCESS] Leader instantly blocked the unauthorized node injection.\n');
end
fprintf('\n');

%% Scenario 3: Impersonation Attack
fprintf('--- SCENARIO 3: Impersonation Attack ---\n');

% Attacker claims to be WINGMAN_02 but uses a fake key
fake_key = '00000000000000000000000000000000';
Attacker = WingmanDrone('WINGMAN_02', fake_key);

% 1. Attacker sends join request (pretending to be WINGMAN_02)
req_id3 = Attacker.sendJoinRequest();

% 2. Leader issues challenge (thinking it's WINGMAN_02)
[nonce3, timestamp3, status3] = C2_Leader.issueChallenge(req_id3);

if strcmp(status3, 'CHALLENGE_ISSUED')
    % 3. Attacker computes response using the WRONG key
    hmac_response3 = Attacker.computeResponse(nonce3, timestamp3);

    % 4. Leader verifies response
    [~, auth_status3] = C2_Leader.verifyResponse(req_id3, nonce3, timestamp3, hmac_response3);

    if strcmp(auth_status3, 'REJECT_INVALID_HMAC')
        fprintf('[SUCCESS] Leader caught the impersonation attack. HMAC validation failed.\n');
    end
end
fprintf('\n');

fprintf('======================================================\n');
fprintf('               TESTBENCH COMPLETE                     \n');
fprintf('======================================================\n');