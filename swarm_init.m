% =========================================================================% SwarmAuth - Module 1: Pre-flight Registration and Provisioning% Role: Generates the Secure Registry for 1 Leader and 9 Members% =========================================================================function swarm_registry = swarm_init()disp('--- Initializing SwarmAuth Pre-flight Registration ---');% Define Swarm Size
num_members = 9;

% Initialize the Leader's Secure Registry (Dictionary/Struct)
% This acts as the Leader's internal memory of who is allowed to join.
swarm_registry = struct();

% 1. Provision the Leader (C2 Node)
leader_id = 'C2_LEADER_01';
disp(['Provisioned Leader Node: ', leader_id]);

% 2. Provision the 9 Tactical Wingmen (Member Drones)
for i = 1:num_members
    % Generate a unique ID for each Wingman (e.g., WINGMAN_01)
    wingman_id = sprintf('WINGMAN_%02d', i);

    % Generate a secure 256-bit Pre-Shared Key (PSK) for mutual trust.
    % In MATLAB, we simulate this by generating 32 random bytes, 
    % then converting them to a hex string.
    raw_key = randi([0, 255], 1, 32, 'uint8');
    hex_key = sprintf('%02x', raw_key);

    % Store in the registry
    swarm_registry.(wingman_id).PSK = hex_key;
    swarm_registry.(wingman_id).Status = 'OFFLINE'; % Default state before join

    fprintf('Provisioned %s with PSK: %s...\n', wingman_id, hex_key(1:16));
end

disp('--- Pre-flight Registration Complete ---');
disp('The Leader Drone registry is locked and loaded.');

end