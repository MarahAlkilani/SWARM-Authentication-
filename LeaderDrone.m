classdef LeaderDrone < handle
    properties
        Registry
        ActiveChallenges
        SessionKeys
        MaxTimeDelta = 3
        GroupKey % True 256-bit Swarm Group Key
    end
    
    methods
        function obj = LeaderDrone(registry)
            obj.Registry = registry;
            obj.ActiveChallenges = containers.Map();
            obj.SessionKeys = containers.Map();
            obj.GroupKey = sprintf('%02x', randi([0, 255], 1, 32)); % 256-bit Hex
        end
        
        function [nonce_L, ts, leader_hmac, status] = issueChallenge(obj, drone_id, nonce_W)
            if ~obj.Registry.isKey(drone_id)
                nonce_L = ''; ts = 0; leader_hmac = ''; status = 'REJECT_UNKNOWN_ID';
                return;
            end
            
            % Generate True 256-bit Nonce and UTC Timestamp
            nonce_L = sprintf('%02x', randi([0, 255], 1, 32));
            ts = posixtime(datetime('now', 'TimeZone', 'UTC'));
            
            % MUTUAL AUTH: Leader calculates HMAC to prove its identity to the Wingman
            secret_key = obj.Registry(drone_id);
            leader_hmac = compute_hmac(secret_key, [nonce_W, nonce_L]);
            
            obj.ActiveChallenges(drone_id) = struct('nonce_L', nonce_L, 'ts', ts);
            status = 'CHALLENGE_ISSUED';
        end
        
        function [enc_payload, auth_status] = verifyResponse(obj, drone_id, nonce_L, ts, hmac_W)
            enc_payload = '';
            if ~obj.ActiveChallenges.isKey(drone_id)
                auth_status = 'REJECT_NO_ACTIVE_CHALLENGE'; return;
            end
            
            challenge = obj.ActiveChallenges(drone_id);
            current_time = posixtime(datetime('now', 'TimeZone', 'UTC'));
            
            % REPLAY CHECK
            if ~strcmp(challenge.nonce_L, nonce_L) || abs(current_time - ts) > obj.MaxTimeDelta
                auth_status = 'REJECT_REPLAY_ATTACK'; return;
            end
            
            secret_key = obj.Registry(drone_id);
            expected_hmac = compute_hmac(secret_key, [nonce_L, num2str(ts)]);
            
            if strcmp(expected_hmac, hmac_W)
                auth_status = 'ACCEPT';
                
                % SECURE KEY EXCHANGE: Encrypt Session & Group keys before sending
                sess_key = sprintf('%02x', randi([0, 255], 1, 32));
                obj.SessionKeys(drone_id) = sess_key;
                
                payload = [sess_key, ':', obj.GroupKey];
                enc_payload = aes_encrypt(secret_key, payload);
            else
                auth_status = 'REJECT_INVALID_HMAC';
            end
            remove(obj.ActiveChallenges, drone_id);
        end
    end
end