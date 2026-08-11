function [C2_Leader, wingmen, registry] = swarm_init(num_wingmen)
    % Properly encapsulated initialization function
    registry = containers.Map();
    wingmen = cell(num_wingmen, 1);
    
    for i = 1:num_wingmen
        id = sprintf('WINGMAN_%02d', i);
        registry(id) = sprintf('%02x', randi([0, 255], 1, 32));
    end
    
    C2_Leader = LeaderDrone(registry);
    
    for i = 1:num_wingmen
        id = sprintf('WINGMAN_%02d', i);
        wingmen{i} = WingmanDrone(id, registry(id));
    end
end