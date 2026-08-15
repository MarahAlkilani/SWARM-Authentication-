classdef LeaderDrone < handle
    properties
        Registry
        ActiveChallenges
        SessionKeys
        MaxTimeDelta = 3
        GroupKey
    end
    methods
        function obj = LeaderDrone(registry)
            obj.Registry = registry;
            obj.ActiveChallenges = containers.Map();
            obj.SessionKeys = containers.Map();
            obj.GroupKey = secure_random_hex(32);
        end

        function [nonce_l, timestamp_ms, leader_hmac, status] = issueChallenge(obj, drone_id, nonce_w)
            if ~obj.Registry.isKey(drone_id)
                nonce_l = ''; timestamp_ms = 0; leader_hmac = ''; status = 'REJECT_UNKNOWN_ID'; return;
            end
            nonce_l = secure_random_hex(32);
            timestamp_ms = floor(posixtime(datetime('now', 'TimeZone', 'UTC')) * 1000);
            psk = obj.Registry(drone_id);
            transcript = sprintf('SwarmAuth-v1|CHALLENGE|%s|%s|%s|%d', drone_id, nonce_w, nonce_l, timestamp_ms);
            leader_hmac = compute_hmac(psk, transcript);
            obj.ActiveChallenges(drone_id) = struct('nonce_w', nonce_w, 'nonce_l', nonce_l, 'timestamp_ms', timestamp_ms);
            status = 'CHALLENGE_ISSUED';
        end

        function [key_packet, auth_status] = verifyResponse(obj, drone_id, nonce_l, timestamp_ms, hmac_w)
            key_packet = [];
            if ~obj.ActiveChallenges.isKey(drone_id)
                auth_status = 'REJECT_NO_ACTIVE_CHALLENGE'; return;
            end
            challenge = obj.ActiveChallenges(drone_id);
            remove(obj.ActiveChallenges, drone_id); % every response consumes its challenge
            now_ms = floor(posixtime(datetime('now', 'TimeZone', 'UTC')) * 1000);
            if ~strcmp(challenge.nonce_l, nonce_l) || timestamp_ms ~= challenge.timestamp_ms
                auth_status = 'REJECT_CHALLENGE_MISMATCH'; return;
            end
            if abs(now_ms - timestamp_ms) > obj.MaxTimeDelta * 1000
                auth_status = 'REJECT_EXPIRED_CHALLENGE'; return;
            end
            psk = obj.Registry(drone_id);
            transcript = sprintf('SwarmAuth-v1|RESPONSE|%s|%s|%s|%d', drone_id, challenge.nonce_w, nonce_l, timestamp_ms);
            expected_hmac = compute_hmac(psk, transcript);
            if ~strcmp(expected_hmac, hmac_w)
                auth_status = 'REJECT_INVALID_HMAC'; return;
            end
            session_key = derive_session_key(psk, drone_id, challenge.nonce_w, nonce_l, timestamp_ms);
            obj.SessionKeys(drone_id) = session_key;
            payload = [session_key, ':', obj.GroupKey];
            aad = sprintf('SwarmAuth-v1|KEY_PACKAGE|%s|%s|%s|%d', drone_id, challenge.nonce_w, nonce_l, timestamp_ms);
            key_packet = aes_encrypt(psk, payload, aad);
            auth_status = 'ACCEPT';
        end
    end
end
