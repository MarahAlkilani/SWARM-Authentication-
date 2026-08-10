classdef WingmanDrone < handle
    properties
        DroneID
        SecretKey
        SessionKey
        State
    end
    
    methods
        function obj = WingmanDrone(id, key)
            obj.DroneID = id;
            obj.SecretKey = key;
            obj.State = 'IDLE';
            obj.SessionKey = '';
        end
        
        function req_id = sendJoinRequest(obj)
            req_id = obj.DroneID;
            obj.State = 'WAIT_FOR_CHALLENGE';
            fprintf('[%s] Sent Join Request.\n', obj.DroneID);
        end
        
        function hmac_response = computeResponse(obj, nonce, timestamp)
            if ~strcmp(obj.State, 'WAIT_FOR_CHALLENGE')
                error('Drone is not expecting a challenge!');
            end
            
            hmac_response = compute_hmac(obj.SecretKey, [nonce, num2str(timestamp)]);
            obj.State = 'WAIT_FOR_DECISION';
            fprintf('[%s] Computed HMAC response.\n', obj.DroneID);
        end
    end
end