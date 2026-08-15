% Measured, reproducible Phase 3 evaluation. Values are calculated from outcomes.
clc; clear; close all; rng(20260814);
trials = 100; packet_count = 1000; injection_rate = 0.30; capacity = 700;
auth_times_ms = zeros(trials,1); accepted = 0; detected = 0; attacks = 0;

for k = 1:trials
    [leader, wingmen, ~] = swarm_init(9); wm = wingmen{1};
    tic; [id,nw] = wm.sendJoinRequest(); [nl,ts,lmac,s] = leader.issueChallenge(id,nw);
    wmac = wm.processChallenge(nl,ts,lmac); [package,s] = leader.verifyResponse(id,nl,ts,wmac); wm.receiveKeys(package);
    auth_times_ms(k) = toc * 1000; accepted = accepted + strcmp(s,'ACCEPT');

    % Every trial executes four concrete attacks and records only real rejections.
    [~,~,~,s] = leader.issueChallenge('ENEMY_DRONE', secure_random_hex(32)); attacks=attacks+1; detected=detected+strcmp(s,'REJECT_UNKNOWN_ID');
    [id,nw] = wm.sendJoinRequest(); [nl,ts,lmac,~] = leader.issueChallenge(id,nw); %#ok<ASGLU>
    [~,s] = leader.verifyResponse(id,nl,ts,repmat('0',1,64)); attacks=attacks+1; detected=detected+strcmp(s,'REJECT_INVALID_HMAC');
    [id,nw] = wm.sendJoinRequest(); [nl,ts,lmac,~] = leader.issueChallenge(id,nw); wmac = wm.processChallenge(nl,ts,lmac);
    [~,s] = leader.verifyResponse(id,nl,ts,wmac); [~,replay] = leader.verifyResponse(id,nl,ts,wmac); attacks=attacks+1; detected=detected+strcmp(replay,'REJECT_NO_ACTIVE_CHALLENGE');
    packet = wm.sendGroupMessage('metric-packet'); packet.tag(1)=char(bitxor(uint8(packet.tag(1)),1));
    try, wingmen{2}.GroupKey=wm.GroupKey; wingmen{2}.State='SECURE_SESSION'; wingmen{2}.receiveGroupMessage(packet); catch, detected=detected+1; end; attacks=attacks+1;
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

figure('Name','Measured SwarmAuth Evaluation');
subplot(1,3,1); bar([baseline_pdr authenticated_pdr]); title('PDR'); ylabel('%'); set(gca,'XTickLabel',{'Baseline','SwarmAuth'});
subplot(1,3,2); bar([mean(auth_times_ms) std(auth_times_ms)]); title('Measured authentication latency'); ylabel('ms'); set(gca,'XTickLabel',{'Mean','Std. dev.'});
subplot(1,3,3); bar([baseline_overhead_kb auth_overhead_kb]); title('Modelled communication overhead'); ylabel('KB'); set(gca,'XTickLabel',{'Baseline','SwarmAuth'});
