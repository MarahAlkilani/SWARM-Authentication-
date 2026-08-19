function SwarmAuth_ControlPanel
% SWARMAUTH_CONTROLPANEL
% Live demonstration GUI for the existing SwarmAuth MATLAB project.
% Put this file in the same folder as:
%   swarm_init.m, LeaderDrone.m, WingmanDrone.m,
%   compute_hmac.m, aes_encrypt.m, aes_decrypt.m,
%   derive_session_key.m, secure_random_hex.m
%
% This GUI does NOT replace the cryptographic implementation.  It calls the
% existing project classes/functions so the professor can see the protocol
% working live.

    clc;
    close all;

    % -------------------- Project state --------------------
    [leader, wingmen, registry] = swarm_init(9); %#ok<ASGLU>
    authenticated = false(1,9);
    nodeState = repmat({'IDLE'},1,9);
    challengeCache = cell(1,9);

    % -------------------- GUI --------------------
    fig = uifigure('Name','SwarmAuth - Live Security Demonstration', ...
        'Position',[80 50 1450 820], ...
        'Color',[0.055 0.075 0.12]);

    gl = uigridlayout(fig,[1 2]);
    gl.ColumnWidth = {'1.8x','1x'};
    gl.RowHeight = {'1x'};
    gl.Padding = [12 12 12 12];
    gl.ColumnSpacing = 12;

    % LEFT: topology
    left = uipanel(gl,'Title','LIVE 10-NODE SWARM', ...
        'FontWeight','bold','ForegroundColor',[0.3 0.85 0.95], ...
        'BackgroundColor',[0.075 0.10 0.16]);

    ax = uiaxes(left,'Position',[20 125 900 590], ...
        'Color',[0.035 0.045 0.075], ...
        'XColor',[0.55 0.62 0.72], 'YColor',[0.55 0.62 0.72]);
    ax.XLim = [0 10]; ax.YLim = [0 10];
    ax.XTick = []; ax.YTick = [];
    ax.Box = 'on';
    title(ax,'SwarmAuth Security State','Color',[0.95 0.97 1], ...
        'FontWeight','bold','FontSize',18);

    % Leader at the center, 9 wingmen around it.
    leaderPos = [5 5];
    theta = linspace(0,2*pi,10); theta(end)=[];
    radius = 3.4;
    wingPos = [5 + radius*cos(theta(:)), 5 + radius*sin(theta(:))];

    % Star links
    edgeH = gobjects(9,1);
    for i=1:9
        edgeH(i) = plot(ax,[leaderPos(1) wingPos(i,1)], ...
            [leaderPos(2) wingPos(i,2)],'--', ...
            'Color',[0.28 0.32 0.40],'LineWidth',1.1);
    end

    % Leader node
    leaderH = plot(ax,leaderPos(1),leaderPos(2),'o', ...
        'MarkerSize',28,'MarkerFaceColor',[0.12 0.45 0.85], ...
        'MarkerEdgeColor',[0.8 0.9 1],'LineWidth',2);
    text(ax,leaderPos(1),leaderPos(2),'LEADER', ...
        'HorizontalAlignment','center','VerticalAlignment','middle', ...
        'Color','white','FontWeight','bold','FontSize',9);

    nodeH = gobjects(9,1);
    labelH = gobjects(9,1);
    for i=1:9
        nodeH(i) = plot(ax,wingPos(i,1),wingPos(i,2),'o', ...
            'MarkerSize',23,'MarkerFaceColor',[0.38 0.42 0.48], ...
            'MarkerEdgeColor',[0.9 0.9 0.95],'LineWidth',1.5);
        labelH(i) = text(ax,wingPos(i,1),wingPos(i,2),sprintf('W%d',i), ...
            'HorizontalAlignment','center','VerticalAlignment','middle', ...
            'Color','white','FontWeight','bold','FontSize',9);
    end

    % Legend
    uilabel(left,'Position',[35 75 830 25], ...
        'Text','BLUE = Leader    GREEN = Authenticated    GRAY = Idle    RED = Attack / Rejected', ...
        'FontColor',[0.82 0.86 0.92],'FontSize',12,'HorizontalAlignment','center');

    statusLabel = uilabel(left,'Position',[35 35 830 32], ...
        'Text','READY — initialize the swarm and choose a live attack/authentication test.', ...
        'FontColor',[0.3 0.85 0.95],'FontSize',13,'FontWeight','bold', ...
        'HorizontalAlignment','center');

    % RIGHT: controls + protocol log
    right = uipanel(gl,'Title','CONTROL PANEL', ...
        'FontWeight','bold','ForegroundColor',[0.3 0.85 0.95], ...
        'BackgroundColor',[0.075 0.10 0.16]);

    uilabel(right,'Position',[25 745 500 28], ...
        'Text','1. AUTHENTICATION', ...
        'FontColor',[0.3 0.85 0.95],'FontWeight','bold','FontSize',14);

    btnAuth = uibutton(right,'push','Text','Authenticate WINGMAN_03', ...
        'Position',[25 705 250 38], 'ButtonPushedFcn',@(~,~)authenticateDrone(3));
    btnAll = uibutton(right,'push','Text','Authenticate ALL 9 DRONES', ...
        'Position',[285 705 250 38], 'ButtonPushedFcn',@(~,~)authenticateAll());

    uilabel(right,'Position',[25 660 500 28], ...
        'Text','2. LIVE ATTACKS', ...
        'FontColor',[0.95 0.70 0.25],'FontWeight','bold','FontSize',14);

    uibutton(right,'push','Text','Impersonation / Forged HMAC', ...
        'Position',[25 615 250 38], 'ButtonPushedFcn',@(~,~)impersonationAttack());
    uibutton(right,'push','Text','Replay Attack', ...
        'Position',[285 615 250 38], 'ButtonPushedFcn',@(~,~)replayAttack());
    uibutton(right,'push','Text','Unauthorized Node Injection', ...
        'Position',[25 570 250 38], 'ButtonPushedFcn',@(~,~)unknownNodeAttack());
    uibutton(right,'push','Text','MITM / Bit-Flip Tampering', ...
        'Position',[285 570 250 38], 'ButtonPushedFcn',@(~,~)tamperAttack());

    uilabel(right,'Position',[25 525 500 28], ...
        'Text','3. SECURE COMMUNICATION', ...
        'FontColor',[0.35 0.85 0.55],'FontWeight','bold','FontSize',14);
    uibutton(right,'push','Text','Send AES-GCM Telemetry', ...
        'Position',[25 480 250 38], 'ButtonPushedFcn',@(~,~)secureTelemetry());
    uibutton(right,'push','Text','RUN FULL LIVE DEMO', ...
        'Position',[285 480 250 38], ...
        'BackgroundColor',[0.15 0.55 0.75], ...
        'FontWeight','bold', ...
        'ButtonPushedFcn',@(~,~)fullDemo());

    uilabel(right,'Position',[25 430 500 28], ...
        'Text','PROTOCOL / SECURITY LOG', ...
        'FontColor',[0.75 0.80 0.90],'FontWeight','bold','FontSize',14);

    logBox = uitextarea(right,'Position',[25 70 510 350], ...
        'Editable','off', 'FontName','Consolas', 'FontSize',11, ...
        'BackgroundColor',[0.025 0.035 0.06], ...
        'FontColor',[0.85 0.90 0.96], ...
        'Value',{'SwarmAuth control panel started.'; ...
                 '10 nodes initialized: 1 Leader + 9 Wingmen.'; ...
                 'Choose a button to demonstrate the protocol.'});

    uibutton(right,'push','Text','RESET DEMO', ...
        'Position',[25 20 510 36], ...
        'ButtonPushedFcn',@(~,~)resetDemo());

    % Initial state
    updateStatus('READY — waiting for a live demonstration.');

    % ============================================================
    % CALLBACKS
    % ============================================================

    function authenticateDrone(i)
        if authenticated(i)
            log(sprintf('[INFO] %s is already authenticated.',wingmen{i}.DroneID));
            updateStatus(sprintf('%s already has SECURE_SESSION.',wingmen{i}.DroneID));
            return;
        end

        id = wingmen{i}.DroneID;
        log('');
        log(sprintf('=== AUTHENTICATING %s ===',id));
        updateStatus(sprintf('%s → Leader : JOIN',id));
        pauseStep();

        [reqID, nonceW] = wingmen{i}.sendJoinRequest();
        log(sprintf('[1] JOIN        ID=%s',reqID));
        log(sprintf('[1] Nonce_W     %s...',nonceW(1:16)));
        pauseStep();

        [nonceL, ts, leaderMac, status] = leader.issueChallenge(reqID,nonceW);
        if ~strcmp(status,'CHALLENGE_ISSUED')
            markNode(i,'red');
            log(sprintf('[FAIL] Leader rejected challenge: %s',status));
            updateStatus(sprintf('%s REJECTED',id));
            return;
        end
        log('[2] Leader → Drone : CHALLENGE');
        log(sprintf('    Nonce_L     %s...',nonceL(1:16)));
        log(sprintf('    Timestamp   %d',ts));
        log(sprintf('    HMAC-L      %s...',leaderMac(1:16)));
        pauseStep();

        try
            responseMac = wingmen{i}.processChallenge(nonceL,ts,leaderMac);
        catch ME
            markNode(i,'red');
            log(sprintf('[FAIL] Leader authentication failed: %s',ME.message));
            updateStatus(sprintf('%s could not authenticate Leader',id));
            return;
        end
        log('[3] Drone verifies Leader HMAC : VALID ✓');
        log(sprintf('    HMAC-W      %s...',responseMac(1:16)));
        pauseStep();

        [keyPacket, authStatus] = leader.verifyResponse(id,nonceL,ts,responseMac);
        log(sprintf('[4] Leader verifies Drone HMAC : %s',authStatus));
        pauseStep();

        if strcmp(authStatus,'ACCEPT')
            wingmen{i}.receiveKeys(keyPacket);
            authenticated(i) = true;
            nodeState{i} = 'SECURE_SESSION';
            markNode(i,'green');
            edgeH(i).Color = [0.25 0.80 0.45];
            log('[5] Key package decrypted and verified ✓');
            log('[6] SECURE_SESSION established ✓');
            updateStatus(sprintf('%s AUTHENTICATED ✓',id));
        else
            markNode(i,'red');
            log(sprintf('[FAIL] Authentication rejected: %s',authStatus));
            updateStatus(sprintf('%s REJECTED ✗',id));
        end
    end

    function authenticateAll()
        log('');
        log('############################################');
        log('       FULL 9-NODE AUTHENTICATION');
        log('############################################');
        for i=1:9
            authenticateDrone(i);
        end
        log(sprintf('=== RESULT: %d/9 authenticated ===',sum(authenticated)));
        updateStatus(sprintf('%d/9 WINGMEN in SECURE_SESSION',sum(authenticated)));
    end

    function impersonationAttack()
        i = 3; % WINGMAN_03
        log('');
        log('=== IMPERSONATION / FORGED HMAC ATTACK ===');
        id = wingmen{i}.DroneID;
        [~,nonceW] = wingmen{i}.sendJoinRequest();
        [nonceL,ts,~,status] = leader.issueChallenge(id,nonceW);
        if ~strcmp(status,'CHALLENGE_ISSUED')
            log('[FAIL] Could not create attack challenge.');
            return;
        end
        fakeKey = secure_random_hex(32);
        fakeResponse = compute_hmac(fakeKey, ...
            sprintf('SwarmAuth-v1|RESPONSE|%s|%s|%s|%d',id,nonceW,nonceL,ts));
        log(sprintf('[ATTACKER] Claims identity = %s',id));
        log(sprintf('[ATTACKER] Uses WRONG secret key.'));
        log(sprintf('[ATTACKER] Forged HMAC = %s...',fakeResponse(1:16)));
        pauseStep();

        [~,result] = leader.verifyResponse(id,nonceL,ts,fakeResponse);
        if strcmp(result,'REJECT_INVALID_HMAC')
            markNode(i,'red');
            log('[DEFENSE] HMAC verification FAILED ✓');
            log('[DEFENSE] IMPERSONATION BLOCKED ✓');
            updateStatus('IMPERSONATION BLOCKED ✓');
        else
            log(sprintf('[CRITICAL] Unexpected result: %s',result));
            updateStatus('WARNING — unexpected result');
        end
    end

    function replayAttack()
        i = 4; % WINGMAN_04
        log('');
        log('=== REPLAY ATTACK ===');
        if ~authenticated(i)
            authenticateDrone(i);
        end

        % Create a fresh valid exchange and capture the response.
        [id,nonceW] = wingmen{i}.sendJoinRequest();
        [nonceL,ts,leaderMac,status] = leader.issueChallenge(id,nonceW);
        if ~strcmp(status,'CHALLENGE_ISSUED')
            log('[FAIL] Challenge not issued.'); return;
        end
        responseMac = wingmen{i}.processChallenge(nonceL,ts,leaderMac);
        [~,firstStatus] = leader.verifyResponse(id,nonceL,ts,responseMac);
        log(sprintf('[1] Original authentication = %s ✓',firstStatus));
        log('[2] Attacker captures the valid response.');
        pauseStep();

        [~,replayStatus] = leader.verifyResponse(id,nonceL,ts,responseMac);
        log(sprintf('[3] Same response sent again → %s',replayStatus));
        if strcmp(replayStatus,'REJECT_NO_ACTIVE_CHALLENGE')
            markNode(i,'red');
            pauseStep();
            markNode(i,'green');
            log('[DEFENSE] Replay BLOCKED: challenge was one-time-use ✓');
            updateStatus('REPLAY ATTACK BLOCKED ✓');
        else
            updateStatus(sprintf('Replay result: %s',replayStatus));
        end
    end

    function unknownNodeAttack()
        log('');
        log('=== UNAUTHORIZED NODE INJECTION ===');
        enemyID = 'ENEMY_DRONE';
        enemyNonce = secure_random_hex(32);
        log(sprintf('[ATTACKER] JOIN with ID = %s',enemyID));
        pauseStep();
        [~,~,~,status] = leader.issueChallenge(enemyID,enemyNonce);
        log(sprintf('[LEADER] Registry lookup → %s',status));
        if strcmp(status,'REJECT_UNKNOWN_ID')
            log('[DEFENSE] Unknown node rejected BEFORE authentication ✓');
            updateStatus('UNAUTHORIZED NODE BLOCKED ✓');
        else
            updateStatus(sprintf('Unexpected result: %s',status));
        end
    end

    function tamperAttack()
        sender = 1; receiver = 2;
        log('');
        log('=== MITM / BIT-FLIP TAMPERING ATTACK ===');
        if ~authenticated(sender), authenticateDrone(sender); end
        if ~authenticated(receiver), authenticateDrone(receiver); end

        packet = wingmen{sender}.sendGroupMessage('Target locked at Sector 7G.');
        log(sprintf('[1] %s → %s : AES-GCM encrypted telemetry', ...
            wingmen{sender}.DroneID,wingmen{receiver}.DroneID));
        log(sprintf('    Ciphertext = %s...',packet.ciphertext(1:min(32,end))));
        pauseStep();

        % Tamper with one byte of ciphertext.
        tampered = packet;
        tampered.ciphertext(1) = char(bitxor(uint8(tampered.ciphertext(1)),1));
        log('[2] MITM flips one ciphertext bit.');
        pauseStep();

        try
            wingmen{receiver}.receiveGroupMessage(tampered);
            log('[CRITICAL] Tampering was NOT detected.');
            updateStatus('WARNING — tampering passed');
        catch
            log('[3] AES-GCM authentication tag verification FAILED ✓');
            log('[DEFENSE] Modified packet rejected ✓');
            updateStatus('MITM TAMPERING BLOCKED ✓');
        end
    end

    function secureTelemetry()
        sender = 1; receiver = 2;
        log('');
        log('=== SECURE AES-GCM TELEMETRY ===');
        if ~authenticated(sender), authenticateDrone(sender); end
        if ~authenticated(receiver), authenticateDrone(receiver); end

        message = 'Target locked at Sector 7G.';
        packet = wingmen{sender}.sendGroupMessage(message);
        log(sprintf('[1] Plaintext: "%s"',message));
        log('[2] AES-GCM encryption + AAD applied ✓');
        log(sprintf('    IV/Nonce   : %s...',packet.nonce(1:min(24,end))));
        log(sprintf('    Ciphertext : %s...',packet.ciphertext(1:min(32,end))));
        log(sprintf('    Tag        : %s...',packet.tag(1:min(24,end))));
        pauseStep();
        decrypted = wingmen{receiver}.receiveGroupMessage(packet);
        log(sprintf('[3] Receiver decrypts → "%s" ✓',decrypted));
        updateStatus('AES-GCM TELEMETRY DECRYPTED ✓');
    end

    function fullDemo()
        resetDemo();
        log('');
        log('################################################');
        log('          SWARMAUTH FULL LIVE DEMO');
        log('################################################');
        authenticateAll();
        pauseStep();
        unknownNodeAttack();
        pauseStep();
        impersonationAttack();
        pauseStep();
        replayAttack();
        pauseStep();
        secureTelemetry();
        pauseStep();
        tamperAttack();
        log('');
        log('################################################');
        log('                 DEMO COMPLETE');
        log('################################################');
        updateStatus('FULL DEMO COMPLETE — all major defenses demonstrated.');
    end

    function resetDemo()
        % Re-create the actual project objects so the state is truly reset.
        [leader, wingmen, registry] = swarm_init(9); %#ok<ASGLU>
        authenticated(:) = false;
        nodeState(:) = {'IDLE'};
        challengeCache(:) = {[]}; %#ok<NASGU>
        for j=1:9
            markNode(j,'gray');
            edgeH(j).Color = [0.28 0.32 0.40];
        end
        leaderH.MarkerFaceColor = [0.12 0.45 0.85];
        logBox.Value = {'[RESET] New Leader + 9 Wingmen created.'; ...
                        '[RESET] New cryptographic keys generated.'; ...
                        '[READY] Waiting for live demonstration...'};
        updateStatus('READY — fresh 10-node swarm initialized.');
    end

    % -------------------- UI helpers --------------------
    function markNode(i,kind)
        switch lower(kind)
            case 'green'
                c = [0.20 0.75 0.38];
            case 'red'
                c = [0.90 0.18 0.20];
            case 'yellow'
                c = [0.95 0.70 0.20];
            otherwise
                c = [0.38 0.42 0.48];
        end
        nodeH(i).MarkerFaceColor = c;
        drawnow limitrate;
    end

    function updateStatus(msg)
        if isvalid(statusLabel)
            statusLabel.Text = msg;
        end
        drawnow limitrate;
    end

    function log(msg)
        if ~isvalid(logBox), return; end
        old = logBox.Value;
        if ischar(old), old = {old}; end
        logBox.Value = [old; {char(msg)}];
        logBox.Value = logBox.Value(max(1,end-38):end);
        drawnow limitrate;
    end

    function pauseStep()
        pause(0.45);
        drawnow limitrate;
    end
end
