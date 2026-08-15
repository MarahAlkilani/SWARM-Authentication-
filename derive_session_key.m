function key = derive_session_key(psk, drone_id, nonce_w, nonce_l, timestamp_ms)
% Domain-separated PSK key derivation.  The HMAC output is a 256-bit AES key.
context = sprintf('SwarmAuth-v1|SESSION|%s|%s|%s|%d', ...
    drone_id, nonce_w, nonce_l, timestamp_ms);
key = compute_hmac(psk, context);
end
