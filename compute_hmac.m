function hmac_hex = compute_hmac(key_str, data_str)
    % COMPUTE_HMAC Generates an HMAC-SHA256 hash using MATLAB's Java bridge.
    % This provides high-speed, military-grade cryptographic hashing.
    
    try
        % Convert MATLAB strings to Java-compatible byte arrays
        key_bytes = int8(char(key_str));
        data_bytes = int8(char(data_str));
        
        % Setup the Java Cryptography Extension (JCE) Mac object
        mac = javaMethod('getInstance', 'javax.crypto.Mac', 'HmacSHA256');
        secretKey = javaObject('javax.crypto.spec.SecretKeySpec', key_bytes, 'HmacSHA256');
        
        % Initialize and compute the hash
        mac.init(secretKey);
        hash_bytes = mac.doFinal(data_bytes);
        
        % Convert the signed Java bytes into a clean, unsigned hexadecimal string
        hmac_hex = sprintf('%02x', typecast(hash_bytes, 'uint8'));
        
    catch ME
        error('SwarmAuth:CryptoError', 'Failed to compute HMAC. Syntax or Java error.');
    end
end