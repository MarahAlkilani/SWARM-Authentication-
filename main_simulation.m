clc; clear; close all;
fprintf('SwarmAuth: authenticated 10-node UAV swarm demonstration\n\n');
[leader, wingmen, registry] = swarm_init(9);

% Normal operation: authenticate every legitimate member.
success_count = 0;
for i = 1:numel(wingmen)
    wm = wingmen{i}; [id, nonce_w] = wm.sendJoinRequest();
    [nonce_l, ts, leader_mac, status] = leader.issueChallenge(id, nonce_w);
    assert(strcmp(status, 'CHALLENGE_ISSUED'));
    response_mac = wm.processChallenge(nonce_l, ts, leader_mac);
    [key_packet, status] = leader.verifyResponse(id, nonce_l, ts, response_mac);
    assert(strcmp(status, 'ACCEPT')); wm.receiveKeys(key_packet); success_count = success_count + 1;
end
fprintf('[PASS] %d/9 members mutually authenticated.\n', success_count);

% P2P authenticated encryption. Sender metadata is bound as AES-GCM AAD.
packet = wingmen{1}.sendGroupMessage('Target locked at Sector 7G.');
wingmen{2}.receiveGroupMessage(packet);

% Injection and forged-identity tests.
[~, ~, ~, status] = leader.issueChallenge('ENEMY_DRONE', secure_random_hex(32));
assert(strcmp(status, 'REJECT_UNKNOWN_ID')); fprintf('[PASS] Unknown-ID injection rejected.\n');
attacker = WingmanDrone('WINGMAN_05', secure_random_hex(32));
[id, nonce_w] = attacker.sendJoinRequest(); [nonce_l, ts, leader_mac, ~] = leader.issueChallenge(id, nonce_w);
leader_rejected = false;
try
    attacker.processChallenge(nonce_l, ts, leader_mac); error('Attack unexpectedly passed.');
catch
    leader_rejected = true;
end
assert(leader_rejected); fprintf('[PASS] Forged identity rejected by mutual authentication.\n');

% Also verify that a forged client proof is rejected at the Leader.
[id, nonce_w] = wingmen{5}.sendJoinRequest(); [nonce_l, ts, ~, ~] = leader.issueChallenge(id, nonce_w);
[~, forged_status] = leader.verifyResponse(id, nonce_l, ts, repmat('0', 1, 64));
assert(strcmp(forged_status, 'REJECT_INVALID_HMAC')); fprintf('[PASS] Forged client HMAC rejected by Leader.\n');

% A true replay occurs after the original response has been accepted.
wm = wingmen{8}; [id, nonce_w] = wm.sendJoinRequest(); [nonce_l, ts, leader_mac, ~] = leader.issueChallenge(id, nonce_w);
response_mac = wm.processChallenge(nonce_l, ts, leader_mac); [key_packet, status] = leader.verifyResponse(id, nonce_l, ts, response_mac);
assert(strcmp(status, 'ACCEPT')); wm.receiveKeys(key_packet);
[~, replay_status] = leader.verifyResponse(id, nonce_l, ts, response_mac);
assert(strcmp(replay_status, 'REJECT_NO_ACTIVE_CHALLENGE')); fprintf('[PASS] Replayed response rejected.\n');

% Tampering must be detected by the GCM authentication tag.
tampered = packet; tampered.ciphertext(1) = char(bitxor(uint8(tampered.ciphertext(1)), 1));
try
    wingmen{2}.receiveGroupMessage(tampered); error('Tampering unexpectedly passed.');
catch
    fprintf('[PASS] Modified P2P packet rejected.\n');
end

fprintf('\nRun swarmauth_performance_metrics for repeatable measured metrics.\n');
