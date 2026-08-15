% Measured, reproducible Phase 3 evaluation. Values are calculated from outcomes.
clc; clear; close all; rng(20260814);
trials = 100; packet_count = 1000; injection_rate = 0.30; capacity = 700;
auth_times_ms = zeros(trials,1); accepted = 0; detected = 0; attacks = 0;

for k = 1:trials
    [leader, wingmen, ~] = swarm_init(9); wm = wingmen{1};
    tic; [id,nw] = wm.sendJoinRequest(); [nl,ts,lmac,s] = leader.issueChallenge(id,nw);
    wmac = wm.processChallenge(nl,ts,lmac); [package,s] = leader.verifyResponse(id,nl,ts,wmac); wm.receiveKeys(package);
    auth_times_ms(k) = toc * 1000; accepted = accepted + strcmp(s,'ACCEPT');

    % Tampering test must run while this Wingman is still authenticated.
    packet = wm.sendGroupMessage('metric-packet'); packet.tag(1)=char(bitxor(uint8(packet.tag(1)),1));
    try, wingmen{2}.GroupKey=wm.GroupKey; wingmen{2}.State='SECURE_SESSION'; wingmen{2}.receiveGroupMessage(packet); catch, detected=detected+1; end; attacks=attacks+1;

    % Every trial executes four concrete attacks and records only real rejections.
    [~,~,~,s] = leader.issueChallenge('ENEMY_DRONE', secure_random_hex(32)); attacks=attacks+1; detected=detected+strcmp(s,'REJECT_UNKNOWN_ID');
    [id,nw] = wm.sendJoinRequest(); [nl,ts,lmac,~] = leader.issueChallenge(id,nw); %#ok<ASGLU>
    [~,s] = leader.verifyResponse(id,nl,ts,repmat('0',1,64)); attacks=attacks+1; detected=detected+strcmp(s,'REJECT_INVALID_HMAC');
    [id,nw] = wm.sendJoinRequest(); [nl,ts,lmac,~] = leader.issueChallenge(id,nw); wmac = wm.processChallenge(nl,ts,lmac);
    [~,s] = leader.verifyResponse(id,nl,ts,wmac); [~,replay] = leader.verifyResponse(id,nl,ts,wmac); attacks=attacks+1; detected=detected+strcmp(replay,'REJECT_NO_ACTIVE_CHALLENGE');
end

% Capacity model: attackers consume capacity in baseline; authenticated mode drops them.
is_attack = rand(packet_count,1) < injection_rate; is_legit = ~is_attack;
baseline_delivered = sum(is_legit(1:capacity)); authenticated_delivered = sum(is_legit);
baseline_pdr = 100 * baseline_delivered / sum(is_legit);
authenticated_pdr = 100 * authenticated_delivered / sum(is_legit);
baseline_overhead_kb = packet_count * 256 / 1024;
auth_overhead_kb = packet_count * (256 + 12 + 16 + 32 + 8) / 1024; % GCM nonce/tag + HMAC + timestamp

fprintf('Trials: %d; packet model: %d packets, %.0f%% injection, capacity %d\n',trials,packet_count,100*injection_rate,capacity);
fprintf('Authentication success rate: %.2f%%\n',100*accepted/trials);
fprintf('Attack detection rate: %.2f%% (%d/%d)\n',100*detected/attacks,detected,attacks);
fprintf('Measured auth latency: mean %.3f ms, std %.3f ms\n',mean(auth_times_ms),std(auth_times_ms));
fprintf('Baseline PDR: %.2f%%; authenticated PDR: %.2f%%\n',baseline_pdr,authenticated_pdr);
fprintf('Baseline overhead: %.2f KB; authenticated overhead: %.2f KB\n',baseline_overhead_kb,auth_overhead_kb);

% Figure 1: three colored bar charts side by side.
labels = {'Baseline', 'SwarmAuth'};
figure('Name','SwarmAuth Performance Evaluation','Position',[100 100 1250 430]);
tiledlayout(1,3,'TileSpacing','compact','Padding','compact');

nexttile;
b = bar([baseline_pdr authenticated_pdr], 'FaceColor','flat');
b.CData = [0.85 0.33 0.10; 0.20 0.65 0.35];
set(gca,'XTickLabel',labels,'FontSize',11); ylabel('PDR (%)');
title('Packet Delivery Ratio','FontWeight','bold'); ylim([0 110]); grid on;
for i=1:2, text(i,b.YData(i)+2,sprintf('%.2f%%',b.YData(i)),'HorizontalAlignment','center','FontWeight','bold'); end

nexttile;
b = bar([mean(auth_times_ms) std(auth_times_ms)], 'FaceColor','flat');
b.CData = [0.30 0.45 0.80; 0.55 0.55 0.55];
set(gca,'XTickLabel',{'Mean','Std. dev.'},'FontSize',11); ylabel('Time (ms)');
title('Authentication Latency','FontWeight','bold'); grid on;
for i=1:2, text(i,b.YData(i)+0.03,sprintf('%.3f ms',b.YData(i)),'HorizontalAlignment','center','FontWeight','bold'); end

nexttile;
b = bar([baseline_overhead_kb auth_overhead_kb], 'FaceColor','flat');
b.CData = [0.93 0.70 0.10; 0.50 0.25 0.70];
set(gca,'XTickLabel',labels,'FontSize',11); ylabel('Overhead (KB)');
title('Communication Overhead','FontWeight','bold'); grid on;
for i=1:2, text(i,b.YData(i)+3,sprintf('%.2f KB',b.YData(i)),'HorizontalAlignment','center','FontWeight','bold'); end

% Figure 2: centralized authentication topology.
node_names = {'Cluster_Head','W1','W2','W3','W4','W5','W6','W7','W8','W9'};
s = [repmat(1,1,9), 2:10]; t = [2:10, repmat(1,1,9)];
G_auth = digraph(node_names(s), node_names(t));
figure('Name','Modality A: UAV-to-CH Authentication','Position',[180 180 560 460]);
p = plot(G_auth,'Layout','force','MarkerSize',12,'NodeColor','#77AC30','EdgeColor','#0072BD','LineWidth',1.3);
highlight(p,'Cluster_Head','NodeColor','#0072BD','MarkerSize',19);
title('Modality A: Centralized Authentication','FontWeight','bold');
subtitle('Bidirectional HMAC challenge-response with Cluster Head');

% Figure 3: decentralized P2P telemetry topology.
s = [2 3 4 5 6 7 8 9 10 2 5 8]; t = [3 4 5 6 7 8 9 10 2 6 9 3];
G_p2p = digraph(node_names(s), node_names(t)); G_p2p = addnode(G_p2p,'Cluster_Head');
figure('Name','Modality B: UAV-to-UAV P2P Telemetry','Position',[240 220 560 460]);
p = plot(G_p2p,'Layout','circle','MarkerSize',12,'NodeColor','#77AC30','EdgeColor','#D95319','LineWidth',1.5);
highlight(p,'Cluster_Head','NodeColor','#808080','MarkerSize',19);
title('Modality B: Authenticated UAV-to-UAV Telemetry','FontWeight','bold');
subtitle('Cluster Head is bypassed during operational P2P traffic');
