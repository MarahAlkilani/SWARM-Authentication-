function SwarmAuth_ControlPanel
% SWARMAUTH_CONTROLPANEL_FIXED
% Launches the robust standalone SwarmAuth live simulation.
%
% Run:
%   clear functions
%   close all
%   SwarmAuth_ControlPanel_FIXED

    old = findall(0,'Type','figure','-regexp','Name','.*SwarmAuth.*');
    if ~isempty(old)
        try
            delete(old);
        catch
        end
    end

    SwarmAuth_LiveDemo;
end
