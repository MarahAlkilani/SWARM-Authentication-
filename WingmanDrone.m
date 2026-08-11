classdef WingmanDrone < handle
    properties
        DroneID
        SecretKey
        SessionKey
        GroupKey
        State
        MyNonce
    end
    
    methods
        function obj = WingmanDrone(id, key)
            obj.DroneID = id; obj.SecretKey = key; obj.State = 'IDLE';
        end
        
        function [req_id, my_nonce] = sendJoinRequest(obj)
            % Send request with a 256-bit Wingman Nonce
            obj.MyNonce = sprintf('%02x', randi([0, 255], 1, 32));
            req_id = obj.DroneID; my_nonce = obj.MyNonce;
            obj.State = 'WAIT_FOR_CHALLENGE';
        end
        
        function hmac_response = processChallenge(obj, nonce_L, ts, leader_hmac)
            % MUTUAL AUTH: Verify the Leader is not a rogue drone
            expected_l_hmac = compute_hmac(obj.SecretKey, [obj.MyNonce, nonce_L]);
            if ~strcmp(expected_l_hmac, leader_hmac)
                error('[!] Mutual Authentication Failed! Rogue Leader detected.');
            end
            
            hmac_response = compute_hmac(obj.SecretKey, [nonce_L, num2str(ts)]);
            obj.State = 'WAIT_FOR_DECISION';
        end
        
        function receiveKeys(obj, enc_payload)
            % Decrypt the payload securely
            payload = aes_decrypt(obj.SecretKey, enc_payload);
            keys = strsplit(payload, ':');
            if length(keys) == 2
                obj.SessionKey = keys{1};
                obj.GroupKey = keys{2};
                obj.State = 'SECURE_SESSION'; % Conditional update!
            end
        end
        
        % P2P ENCRYPTED COMMUNICATION (Encrypt-then-MAC)
        function [cipher, mac] = sendGroupMessage(obj, msg)
            if ~strcmp(obj.State, 'SECURE_SESSION')
                error('Cannot send: Not in secure session.');
            end
            cipher = aes_encrypt(obj.GroupKey, msg);
            mac = compute_hmac(obj.GroupKey, cipher);
        end
        
        function msg = receiveGroupMessage(obj, cipher, mac, sender_id)
            % Verify Integrity First, then Decrypt
            expected_mac = compute_hmac(obj.GroupKey, cipher);
            if ~strcmp(expected_mac, mac)
                error('Message integrity check failed! Packet modified.');
            end
            msg = aes_decrypt(obj.GroupKey, cipher);
            fprintf('[%s] Decrypted P2P msg from %s: "%s"\n', obj.DroneID, sender_id, msg);
        end
    end
end