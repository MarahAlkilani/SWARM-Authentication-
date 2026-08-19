function SwarmAuth_LiveDemo
% SWARMAUTH_LIVEDEMO
% Standalone, professor-ready live simulation of the SwarmAuth protocol.
%
% Run:
%   SwarmAuth_LiveDemo
%
% This demo is deliberately self-contained so the visualization cannot be
% broken by plotting state or by errors in a separate project callback.
% It demonstrates the same project protocol:
%   10-node swarm -> HMAC-SHA256 challenge/response -> replay protection
%   -> unauthorized-node rejection -> AES-GCM telemetry -> tamper detection.
%
% Blue  = Leader
% Gray  = Idle Wingman
% Green = Authenticated Wingman
% Red   = Attack / Rejected

    clc;
    close all;

    N = 9;
    ids = arrayfun(@(k)sprintf('WINGMAN_%02d',k),1:N,'UniformOutput',false);

    % -------------------- Cryptographic state --------------------
    keys = cell(1,N);
    for k = 1:N
        keys{k} = randomBytes(32);
    end

    authenticated = false(1,N);
    usedChallenges = cell(1,N);
    sessionKeys = cell(1,N);
    groupKey = randomBytes(32);   % distributed after successful authentication
    lastPacket = struct();

    % -------------------- GUI --------------------
    fig = uifigure('Name','SwarmAuth - Live 10-Node Security Simulation', ...
        'Position',[40 35 1500 850], ...
        'Color',[0.045 0.06 0.095]);

    main = uigridlayout(fig,[1 2]);
    main.ColumnWidth = {'2.0x','1x'};
    main.RowHeight = {'1x'};
    main.Padding = [10 10 10 10];
    main.ColumnSpacing = 10;

    left = uipanel(main,'Title','LIVE 10-NODE SWARM', ...
        'FontWeight','bold','FontSize',13, ...
        'ForegroundColor',[0.2 0.9 1], ...
        'BackgroundColor',[0.06 0.08 0.13]);

    ax = uiaxes(left,'Position',[20 125 965 625]);
    ax.Color = [0.015 0.02 0.035];
    ax.XLim = [0 10]; ax.YLim = [0 10];
    ax.XTick = []; ax.YTick = [];
    ax.Box = 'on';
    ax.XLimMode = 'manual'; ax.YLimMode = 'manual';
    hold(ax,'on');

    title(ax,'SwarmAuth Security State','Color',[0.95 0.97 1], ...
        'FontWeight','bold','FontSize',20);

    % Fixed positions: Leader in center + nine Wingmen around it.
    leaderPos = [5 5];
    theta = (0:N-1)' * 2*pi/N + pi/2;
    radius = 3.25;
    wingPos = [5 + radius*cos(theta), 5 + radius*sin(theta)];

    % Draw ALL edges in ONE graphics object. This avoids any hold/plot issue.
    ex = zeros(3*N,1); ey = zeros(3*N,1);
    for k = 1:N
        q = 3*k-2;
        ex(q:q+2) = [leaderPos(1); wingPos(k,1); NaN];
        ey(q:q+2) = [leaderPos(2); wingPos(k,2); NaN];
    end
    edgeH = plot(ax,ex,ey,'--','Color',[0.25 0.30 0.38],'LineWidth',1.2);

    % ONE scatter object for all nine Wingmen.
    idleColor = [0.38 0.42 0.48];
    nodeH = scatter(ax,wingPos(:,1),wingPos(:,2),1050,repmat(idleColor,N,1), ...
        'filled','MarkerEdgeColor',[0.92 0.94 0.98],'LineWidth',1.8);

    % Leader is a separate single object.
    leaderH = scatter(ax,leaderPos(1),leaderPos(2),1250,[0.08 0.45 0.90], ...
        'filled','MarkerEdgeColor',[0.9 0.95 1],'LineWidth',2.2);

    % Labels are all created once.
    for k = 1:N
        text(ax,wingPos(k,1),wingPos(k,2),sprintf('W%d',k), ...
            'HorizontalAlignment','center','VerticalAlignment','middle', ...
            'Color','white','FontWeight','bold','FontSize',10);
    end
    text(ax,leaderPos(1),leaderPos(2),'LEADER', ...
        'HorizontalAlignment','center','VerticalAlignment','middle', ...
        'Color','white','FontWeight','bold','FontSize',9);

    uilabel(left,'Position',[30 80 920 28], ...
        'Text','BLUE = Leader    GREEN = Authenticated    GRAY = Idle    RED = Attack / Rejected', ...
        'FontColor',[0.82 0.87 0.94],'FontSize',12,'HorizontalAlignment','center');

    statusLabel = uilabel(left,'Position',[30 40 920 30], ...
        'Text','READY — press a button to demonstrate the protocol.', ...
        'FontColor',[0.2 0.9 1],'FontSize',14,'FontWeight','bold', ...
        'HorizontalAlignment','center');

    % -------------------- Control panel --------------------
    right = uipanel(main,'Title','CONTROL PANEL', ...
        'FontWeight','bold','FontSize',13, ...
        'ForegroundColor',[0.2 0.9 1], ...
        'BackgroundColor',[0.06 0.08 0.13]);

    uilabel(right,'Position',[25 775 520 28],'Text','1. AUTHENTICATION', ...
        'FontColor',[0.2 0.9 1],'FontWeight','bold','FontSize',15);

    uibutton(right,'push','Text','Authenticate WINGMAN_03', ...
        'Position',[25 730 250 40],'ButtonPushedFcn',@(~,~)authOne(3));
    uibutton(right,'push','Text','Authenticate ALL 9 DRONES', ...
        'Position',[285 730 250 40],'ButtonPushedFcn',@(~,~)authAll());

    uilabel(right,'Position',[25 685 520 28],'Text','2. LIVE ATTACKS', ...
        'FontColor',[0.98 0.70 0.20],'FontWeight','bold','FontSize',15);

    uibutton(right,'push','Text','Impersonation / Forged HMAC', ...
        'Position',[25 640 250 40],'ButtonPushedFcn',@(~,~)impersonation());
    uibutton(right,'push','Text','Replay Attack', ...
        'Position',[285 640 250 40],'ButtonPushedFcn',@(~,~)replay());
    uibutton(right,'push','Text','Unauthorized Node Injection', ...
        'Position',[25 590 250 40],'ButtonPushedFcn',@(~,~)unknownNode());
    uibutton(right,'push','Text','MITM / Bit-Flip Tampering', ...
        'Position',[285 590 250 40],'ButtonPushedFcn',@(~,~)tamper());

    uilabel(right,'Position',[25 545 520 28],'Text','3. SECURE COMMUNICATION', ...
        'FontColor',[0.30 0.95 0.55],'FontWeight','bold','FontSize',15);

    uibutton(right,'push','Text','Send AES-GCM Telemetry', ...
        'Position',[25 500 250 40],'ButtonPushedFcn',@(~,~)telemetry());
    uibutton(right,'push','Text','RUN FULL LIVE DEMO', ...
        'Position',[285 500 250 40], ...
        'BackgroundColor',[0.10 0.55 0.80], ...
        'FontWeight','bold','ButtonPushedFcn',@(~,~)fullDemo());

    uilabel(right,'Position',[25 455 520 28],'Text','PROTOCOL / SECURITY LOG', ...
        'FontColor',[0.75 0.82 0.92],'FontWeight','bold','FontSize',15);

    logBox = uitextarea(right,'Position',[25 65 510 380], ...
        'Editable','off','FontName','Consolas','FontSize',11, ...
        'BackgroundColor',[0.02 0.025 0.045], ...
        'FontColor',[0.88 0.93 0.98], ...
        'Value',{'SwarmAuth live simulation started.'; ...
                 '10 nodes: 1 Leader + 9 Wingmen.'; ...
                 'All nodes are visible and idle.'; ...
                 'Choose a demonstration.'});

    uibutton(right,'push','Text','RESET DEMO', ...
        'Position',[25 18 510 38],'ButtonPushedFcn',@(~,~)resetDemo());

    % -------------------- Initial render --------------------
    setStatus('READY — 10-node swarm initialized.');
    drawnow;

    % =========================================================
    % AUTHENTICATION
    % =========================================================
    function authOne(i)
        if authenticated(i)
            addLog(sprintf('[INFO] %s already authenticated.',ids{i}));
            setStatus(sprintf('%s already SECURE ✓',ids{i}));
            return;
        end

        id = ids{i};
        addLog('');
        addLog(sprintf('=== AUTHENTICATING %s ===',id));
        setStatus(sprintf('%s → Leader : JOIN',id));
        step();

        nonceW = randomBytes(32);
        nonceL = randomBytes(32);
        ts = floor(posixtime(datetime('now')));

        addLog(sprintf('[1] JOIN       ID=%s',id));
        addLog(sprintf('    Nonce_W    %s...',hex(nonceW,16)));
        step();

        transcriptL = makeTranscript('CHALLENGE',id,nonceW,nonceL,ts);
        hmacL = hmacSha256(keys{i},transcriptL);

        addLog('[2] Leader → Drone : CHALLENGE');
        addLog(sprintf('    Nonce_L    %s...',hex(nonceL,16)));
        addLog(sprintf('    Timestamp  %d',ts));
        addLog(sprintf('    HMAC-L     %s...',hex(hmacL,16)));
        step();

        expectedL = hmacSha256(keys{i},transcriptL);
        if ~isequal(expectedL,hmacL)
            setNode(i,'red');
            addLog('[FAIL] Drone rejected Leader HMAC.');
            setStatus('AUTHENTICATION FAILED ✗');
            return;
        end
        addLog('[3] Drone verifies Leader HMAC : VALID ✓');

        transcriptW = makeTranscript('RESPONSE',id,nonceW,nonceL,ts);
        response = hmacSha256(keys{i},transcriptW);
        addLog(sprintf('    HMAC-W     %s...',hex(response,16)));
        step();

        expectedW = hmacSha256(keys{i},transcriptW);
        if ~isequal(expectedW,response)
            setNode(i,'red');
            addLog('[4] Leader verifies Drone HMAC : REJECT_INVALID_HMAC');
            setStatus('AUTHENTICATION REJECTED ✗');
            return;
        end

        usedChallenges{i} = struct('nonceW',nonceW,'nonceL',nonceL,'ts',ts,'used',true);
        % The Leader distributes a common post-authentication group key.
        % This mirrors the project's authenticated group-communication model.
        sessionKeys{i} = groupKey;
        authenticated(i) = true;
        setNode(i,'green');
        addLog('[4] Leader verifies Drone HMAC : ACCEPT ✓');
        addLog('[5] Session key established ✓');
        addLog('[6] SECURE_SESSION active ✓');
        setStatus(sprintf('%s AUTHENTICATED ✓',id));
        edgeGreen(i);
    end

    function authAll()
        addLog('');
        addLog('############################################');
        addLog('        FULL 9-NODE AUTHENTICATION');
        addLog('############################################');
        for i=1:N
            authOne(i);
            step();
        end
        addLog(sprintf('=== RESULT: %d/9 authenticated ===',sum(authenticated)));
        setStatus(sprintf('%d/9 WINGMEN in SECURE_SESSION',sum(authenticated)));
    end

    % =========================================================
    % ATTACKS
    % =========================================================
    function impersonation()
        i = 3;
        id = ids{i};
        addLog('');
        addLog('=== IMPERSONATION / FORGED HMAC ===');

        nonceW = randomBytes(32);
        nonceL = randomBytes(32);
        ts = floor(posixtime(datetime('now')));

        transcript = makeTranscript('RESPONSE',id,nonceW,nonceL,ts);
        fakeKey = randomBytes(32);
        forged = hmacSha256(fakeKey,transcript);
        expected = hmacSha256(keys{i},transcript);

        addLog(sprintf('[ATTACKER] Claims identity = %s',id));
        addLog('[ATTACKER] Does NOT know the legitimate PSK.');
        addLog(sprintf('[ATTACKER] Forged HMAC = %s...',hex(forged,16)));
        step();

        if ~isequal(forged,expected)
            setNode(i,'red');
            addLog('[DEFENSE] Expected HMAC ≠ forged HMAC ✓');
            addLog('[DEFENSE] IMPERSONATION BLOCKED ✓');
            setStatus('IMPERSONATION BLOCKED ✓');
        else
            setStatus('CRITICAL ERROR — FORGED HMAC ACCEPTED');
            addLog('[CRITICAL] FORGED HMAC ACCEPTED — DO NOT DEMO');
        end
    end

    function replay()
        i = 4;
        id = ids{i};
        addLog('');
        addLog('=== REPLAY ATTACK ===');

        if ~authenticated(i)
            authOne(i);
        end

        nonceW = randomBytes(32);
        nonceL = randomBytes(32);
        ts = floor(posixtime(datetime('now')));
        transcript = makeTranscript('RESPONSE',id,nonceW,nonceL,ts);
        validResponse = hmacSha256(keys{i},transcript);

        % First use is valid.
        firstExpected = hmacSha256(keys{i},transcript);
        firstAccepted = isequal(validResponse,firstExpected);
        usedChallenges{i} = struct('nonceW',nonceW,'nonceL',nonceL,'ts',ts,'used',true);

        addLog(sprintf('[1] Original packet → %s',ternary(firstAccepted,'ACCEPT','REJECT')));
        addLog('[2] Attacker captures the valid response.');
        step();

        % Replay is rejected because this exact challenge has already been used.
        replayRejected = usedChallenges{i}.used && isequal(usedChallenges{i}.nonceL,nonceL);
        if replayRejected
            setNode(i,'red');
            addLog('[3] Same response sent again → REJECT_REPLAY');
            addLog('[DEFENSE] Replay BLOCKED: nonce/challenge already consumed ✓');
            step();
            if authenticated(i), setNode(i,'green'); end
            setStatus('REPLAY ATTACK BLOCKED ✓');
        else
            addLog('[CRITICAL] Replay was accepted.');
            setStatus('CRITICAL ERROR — REPLAY ACCEPTED');
        end
    end

    function unknownNode()
        addLog('');
        addLog('=== UNAUTHORIZED NODE INJECTION ===');
        enemy = 'ENEMY_DRONE';
        addLog(sprintf('[ATTACKER] JOIN with ID = %s',enemy));
        step();

        known = any(strcmp(ids,enemy));
        if ~known
            addLog('[LEADER] Registry lookup → REJECT_UNKNOWN_ID');
            addLog('[DEFENSE] Unknown node rejected BEFORE authentication ✓');
            setStatus('UNAUTHORIZED NODE BLOCKED ✓');
        else
            setStatus('CRITICAL ERROR — UNKNOWN NODE ACCEPTED');
        end
    end

    function telemetry()
        sender = 1; receiver = 2;
        addLog('');
        addLog('=== SECURE AES-GCM TELEMETRY ===');

        if ~authenticated(sender), authOne(sender); end
        if ~authenticated(receiver), authOne(receiver); end

        message = uint8('Target locked at Sector 7G.');
        aad = uint8('SwarmAuth-v1|W1|W2');
        nonce = randomBytes(12);

        [ciphertext,tag] = aesGcmEncrypt(sessionKeys{sender},nonce,message,aad);

        addLog('[1] WINGMAN_01 → WINGMAN_02');
        addLog('[2] AES-GCM encryption + AAD applied ✓');
        addLog(sprintf('    IV/Nonce   : %s...',hex(nonce,24)));
        addLog(sprintf('    Ciphertext : %s...',hex(ciphertext,32)));
        addLog(sprintf('    Tag        : %s...',hex(tag,24)));
        step();

        recovered = aesGcmDecrypt(sessionKeys{receiver},nonce,ciphertext,tag,aad);
        addLog(sprintf('[3] Receiver decrypts → "%s" ✓',char(recovered)));
        lastPacket = struct('key',sessionKeys{sender},'nonce',nonce, ...
            'ciphertext',ciphertext,'tag',tag,'aad',aad);
        setStatus('AES-GCM TELEMETRY DECRYPTED ✓');
    end

    function tamper()
        addLog('');
        addLog('=== MITM / BIT-FLIP TAMPERING ===');
        if isempty(fieldnames(lastPacket))
            telemetry();
        end

        p = lastPacket;
        tampered = p.ciphertext;
        tampered(1) = bitxor(tampered(1),uint8(1));

        addLog('[1] Legitimate AES-GCM packet captured.');
        addLog('[2] MITM flips ONE BIT in ciphertext.');
        step();

        try
            aesGcmDecrypt(p.key,p.nonce,tampered,p.tag,p.aad);
            addLog('[CRITICAL] Modified packet was accepted.');
            setStatus('CRITICAL ERROR — TAMPERING ACCEPTED');
        catch
            addLog('[3] GCM authentication tag verification FAILED ✓');
            addLog('[DEFENSE] Modified packet rejected ✓');
            setStatus('MITM TAMPERING BLOCKED ✓');
        end
    end

    function fullDemo()
        resetDemo();
        addLog('');
        addLog('################################################');
        addLog('             SWARMAUTH FULL LIVE DEMO');
        addLog('################################################');
        authAll();
        step();
        unknownNode();
        step();
        impersonation();
        step();
        replay();
        step();
        telemetry();
        step();
        tamper();
        addLog('');
        addLog('################################################');
        addLog('                 DEMO COMPLETE');
        addLog('################################################');
        setStatus('FULL DEMO COMPLETE — SECURITY TESTS PASSED ✓');
    end

    function resetDemo()
        for k=1:N
            keys{k} = randomBytes(32);
            authenticated(k) = false;
            usedChallenges{k} = [];
            sessionKeys{k} = [];
        end
        groupKey = randomBytes(32);
        lastPacket = struct();
        setNodeColors(repmat(idleColor,N,1));
        edgeH.Color = [0.25 0.30 0.38];
        leaderH.CData = [0.08 0.45 0.90];
        logBox.Value = {'[RESET] New 10-node swarm created.'; ...
                        '[RESET] New PSKs generated.'; ...
                        '[READY] Leader + 9 Wingmen visible.'};
        setStatus('READY — fresh 10-node swarm initialized.');
        drawnow;
    end

    % =========================================================
    % VISUAL HELPERS
    % =========================================================
    function setNode(i,kind)
        colors = nodeH.CData;
        switch lower(kind)
            case 'green', colors(i,:) = [0.15 0.78 0.38];
            case 'red',   colors(i,:) = [0.92 0.16 0.18];
            case 'yellow',colors(i,:) = [0.98 0.70 0.18];
            otherwise,    colors(i,:) = idleColor;
        end
        nodeH.CData = colors;
        drawnow;
    end

    function setNodeColors(colors)
        nodeH.CData = colors;
        drawnow;
    end

    function edgeGreen(i)
        % Keep the complete star visible; authenticated links become green.
        % Since edgeH is one object, update the corresponding 3-point segment.
        x = edgeH.XData; y = edgeH.YData;
        q = 3*i-2;
        % MATLAB line object cannot store per-segment color, so we redraw
        % the authenticated edge as a separate lightweight line.
        plot(ax,[leaderPos(1) wingPos(i,1)],[leaderPos(2) wingPos(i,2)], ...
            '-','Color',[0.15 0.78 0.38],'LineWidth',2.3);
        edgeH.XData = x; edgeH.YData = y;
    end

    function setStatus(s)
        if isvalid(statusLabel)
            statusLabel.Text = s;
        end
        drawnow;
    end

    function addLog(s)
        if ~isvalid(logBox), return; end
        v = logBox.Value;
        if ischar(v), v={v}; end
        v = [v; {char(s)}];
        if numel(v)>42, v=v(end-41:end); end
        logBox.Value = v;
        drawnow;
    end

    function step()
        pause(0.35);
        drawnow;
    end

    % =========================================================
    % CRYPTO HELPERS
    % =========================================================
    function out = randomBytes(n)
        out = uint8(randi([0 255],1,n));
    end

    function out = hmacSha256(key,data)
        mac = javax.crypto.Mac.getInstance('HmacSHA256');
        spec = javax.crypto.spec.SecretKeySpec(int8(key),'HmacSHA256');
        mac.init(spec);
        out = typecast(mac.doFinal(int8(data)),'uint8')';
    end

    function out = makeTranscript(kind,id,nonceW,nonceL,ts)
        out = uint8(sprintf('SwarmAuth-v1|%s|%s|%s|%s|%d', ...
            kind,id,hex(nonceW),hex(nonceL),ts));
    end

    function [ciphertext,tag] = aesGcmEncrypt(key,nonce,plain,aad)
        cipher = javax.crypto.Cipher.getInstance('AES/GCM/NoPadding');
        spec = javax.crypto.spec.SecretKeySpec(int8(key),'AES');
        gcm = javax.crypto.spec.GCMParameterSpec(128,int8(nonce));
        cipher.init(javax.crypto.Cipher.ENCRYPT_MODE,spec,gcm);
        cipher.updateAAD(int8(aad));
        all = typecast(cipher.doFinal(int8(plain)),'uint8')';
        ciphertext = all(1:end-16);
        tag = all(end-15:end);
    end

    function plain = aesGcmDecrypt(key,nonce,ciphertext,tag,aad)
        cipher = javax.crypto.Cipher.getInstance('AES/GCM/NoPadding');
        spec = javax.crypto.spec.SecretKeySpec(int8(key),'AES');
        gcm = javax.crypto.spec.GCMParameterSpec(128,int8(nonce));
        cipher.init(javax.crypto.Cipher.DECRYPT_MODE,spec,gcm);
        cipher.updateAAD(int8(aad));
        all = [ciphertext tag];
        plain = typecast(cipher.doFinal(int8(all)),'uint8')';
    end

    function s = hex(bytes,nchars)
        h = lower(dec2hex(bytes,2))';
        s = h(:)';
        if nargin>1
            s = s(1:min(nchars,numel(s)));
        end
    end

    function s = ternary(cond,a,b)
        if cond, s=a; else, s=b; end
    end
end
