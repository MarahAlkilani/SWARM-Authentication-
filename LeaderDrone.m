classdef LeaderDrone < handle
    properties
        Registry            
        ActiveChallenges    
        SessionKeys         
        MaxTimeDelta = 3    
    end
    
    methods
        function obj = LeaderDrone(registry)
            obj.Registry = registry;
            obj.ActiveChallenges = containers.Map();
            obj.SessionKeys = containers.Map();
        end
        
        function [nonce, timestamp, status] = issueChallenge(obj, drone_id)
            if ~obj.Registry.isKey(drone_id)
                nonce = ''; timestamp = 0;
                status = 'REJECT_UNKNOWN_ID';
                fprintf('[LEADER] REJECT: Unknown drone %s attempted to join!\n', drone_id);
                return;
            end
            
            nonce = num2hex(rand(1, 'single')); 
            % FIXED: Lock to UTC to prevent timezone drift triggering a Replay Attack
            timestamp = posixtime(datetime('now', 'TimeZone', 'UTC'));
            
            obj.ActiveChallenges(drone_id) = struct('nonce', nonce, 'timestamp', timestamp);
            status = 'CHALLENGE_ISSUED';
            fprintf('[LEADER] Challenge issued to %s (Nonce: %s)\n', drone_id, nonce);
        end
        
        function [session_key, auth_status] = verifyResponse(obj, drone_id, nonce, timestamp, received_hmac)
            session_key = '';
            
            if ~obj.ActiveChallenges.isKey(drone_id)
                auth_status = 'REJECT_NO_ACTIVE_CHALLENGE';
                return;
            end
            
            challenge = obj.ActiveChallenges(drone_id);
            
            % FIXED: Compare against current UTC time
            current_time = posixtime(datetime('now', 'TimeZone', 'UTC'));
            if ~strcmp(challenge.nonce, nonce) || abs(current_time - timestamp) > obj.MaxTimeDelta
                auth_status = 'REJECT_REPLAY_ATTACK';
                fprintf('[LEADER] REJECT: Replay attack detected for %s!\n', drone_id);
                return;
            end
            
            secret_key = obj.Registry(drone_id);
            expected_hmac = compute_hmac(secret_key, [nonce, num2str(timestamp)]);
            
            if strcmp(expected_hmac, received_hmac)
                auth_status = 'ACCEPT';
                session_key = num2hex(rand(1, 'single')); 
                obj.SessionKeys(drone_id) = session_key;
                fprintf('[LEADER] ACCEPT: Identity verified for %s. Session key generated.\n', drone_id);
            else
                auth_status = 'REJECT_INVALID_HMAC';
                fprintf('[LEADER] REJECT: Invalid HMAC from %s. Impersonation detected!\n', drone_id);
            end
            
            remove(obj.ActiveChallenges, drone_id);
        end
    end
end