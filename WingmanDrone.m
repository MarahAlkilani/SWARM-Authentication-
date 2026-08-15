classdef WingmanDrone < handle
    properties
        DroneID
        SecretKey
        SessionKey
        GroupKey
        State
        MyNonce
        LastChallengeNonce
        LastTimestampMs
    end
    methods
        function obj = WingmanDrone(id, key)
            obj.DroneID = id; obj.SecretKey = key; obj.State = 'IDLE';
        end
        function [req_id, my_nonce] = sendJoinRequest(obj)
            obj.MyNonce = secure_random_hex(32);
            req_id = obj.DroneID; my_nonce = obj.MyNonce; obj.State = 'WAIT_FOR_CHALLENGE';
        end
        function hmac_response = processChallenge(obj, nonce_l, timestamp_ms, leader_hmac)
            transcript = sprintf('SwarmAuth-v1|CHALLENGE|%s|%s|%s|%d', obj.DroneID, obj.MyNonce, nonce_l, timestamp_ms);
            if ~strcmp(compute_hmac(obj.SecretKey, transcript), leader_hmac)
                error('SwarmAuth:LeaderAuth', 'Mutual authentication failed: untrusted Leader.');
            end
            obj.LastChallengeNonce = nonce_l; obj.LastTimestampMs = timestamp_ms;
            response = sprintf('SwarmAuth-v1|RESPONSE|%s|%s|%s|%d', obj.DroneID, obj.MyNonce, nonce_l, timestamp_ms);
            hmac_response = compute_hmac(obj.SecretKey, response);
            obj.State = 'WAIT_FOR_DECISION';
        end
        function receiveKeys(obj, key_packet)
            aad = sprintf('SwarmAuth-v1|KEY_PACKAGE|%s|%s|%s|%d', obj.DroneID, obj.MyNonce, obj.LastChallengeNonce, obj.LastTimestampMs);
            payload = aes_decrypt(obj.SecretKey, key_packet, aad);
            keys = strsplit(payload, ':');
            if numel(keys) ~= 2 || ~strcmp(keys{1}, derive_session_key(obj.SecretKey, obj.DroneID, obj.MyNonce, obj.LastChallengeNonce, obj.LastTimestampMs))
                error('SwarmAuth:KeyPackage', 'Invalid authenticated key package.');
            end
            obj.SessionKey = keys{1}; obj.GroupKey = keys{2}; obj.State = 'SECURE_SESSION';
        end
        function packet = sendGroupMessage(obj, msg)
            if ~strcmp(obj.State, 'SECURE_SESSION'), error('SwarmAuth:Session', 'Cannot send before authentication.'); end
            timestamp_ms = floor(posixtime(datetime('now', 'TimeZone', 'UTC')) * 1000);
            aad = sprintf('SwarmAuth-v1|P2P|%s|%d', obj.DroneID, timestamp_ms);
            packet = aes_encrypt(obj.GroupKey, msg, aad);
            packet.sender_id = obj.DroneID; packet.timestamp_ms = timestamp_ms;
        end
        function msg = receiveGroupMessage(obj, packet)
            if ~strcmp(obj.State, 'SECURE_SESSION'), error('SwarmAuth:Session', 'Cannot receive before authentication.'); end
            aad = sprintf('SwarmAuth-v1|P2P|%s|%d', packet.sender_id, packet.timestamp_ms);
            msg = aes_decrypt(obj.GroupKey, packet, aad);
            fprintf('[%s] Decrypted P2P msg from %s: "%s"\n', obj.DroneID, packet.sender_id, msg);
        end
    end
end
