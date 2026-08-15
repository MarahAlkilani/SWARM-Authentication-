function plaintext_str = aes_decrypt(key_input, ciphertext_with_iv)
    % =====================================================================
    % SwarmAuth: AES-GCM Decryption & Tag Verification
    % Extracts the IV, parses Hex keys, and validates MITM tampering.
    % =====================================================================
    import javax.crypto.Cipher;
    import javax.crypto.spec.SecretKeySpec;
    import javax.crypto.spec.GCMParameterSpec;
    
    % Safely convert 64-character Hex string back into 32 raw bytes for Java
    if (ischar(key_input) || isstring(key_input)) && length(char(key_input)) == 64
        key_bytes = hex2dec(reshape(char(key_input), 2, [])').';
    elseif length(key_input) == 64
        key_bytes = hex2dec(reshape(char(key_input), 2, [])').';
    else
        key_bytes = key_input;
    end
    
    % Cast to int8 for Java compatibility
    key_bytes_int8 = typecast(uint8(key_bytes), 'int8');
    
    % Use typecast instead of int8() to prevent MATLAB from capping values at 127
    iv = typecast(uint8(ciphertext_with_iv(1:12)), 'int8');
    ciphertext = typecast(uint8(ciphertext_with_iv(13:end)), 'int8');
    
    % Rebuild AES-GCM parameters
    secretKey = SecretKeySpec(key_bytes_int8, 'AES');
    cipher = Cipher.getInstance('AES/GCM/NoPadding');
    gcmSpec = GCMParameterSpec(128, iv);
    
    cipher.init(Cipher.DECRYPT_MODE, secretKey, gcmSpec);
    
    try
        % Decrypt and simultaneously authenticate the GCM tag
        plaintext_bytes = cipher.doFinal(ciphertext);
        
        % FIX: Force plaintext_bytes into a row vector using (:)' so strsplit doesn't crash!
        plaintext_str = native2unicode(typecast(plaintext_bytes(:)', 'uint8'), 'UTF-8');
    catch ME
        error('AEADBadTagException: Ciphertext or IV was tampered with in transit!');
    end
end