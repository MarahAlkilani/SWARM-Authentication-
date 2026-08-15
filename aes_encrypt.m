function ciphertext_with_iv = aes_encrypt(key_input, plaintext_str)
    % =====================================================================
    % SwarmAuth: AES-GCM Encryption Module
    % Automatically parses 64-char Hex strings into 32-byte AES keys.
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
    
    % Generate a fresh 96-bit (12-byte) IV for GCM
    iv = randi([0 255], 1, 12, 'int8');
    
    % Initialize AES-GCM
    secretKey = SecretKeySpec(key_bytes_int8, 'AES');
    cipher = Cipher.getInstance('AES/GCM/NoPadding');
    gcmSpec = GCMParameterSpec(128, iv);
    
    cipher.init(Cipher.ENCRYPT_MODE, secretKey, gcmSpec);
    
    % Encrypt the payload
    plaintext_bytes = int8(unicode2native(char(plaintext_str), 'UTF-8'));
    ciphertext = cipher.doFinal(plaintext_bytes);
    
    % Bundle IV and Ciphertext together into a single network packet
    % FIX: Force both to be row vectors using (:)' to prevent horzcat errors
    ciphertext_with_iv = [typecast(iv(:)', 'uint8'), typecast(ciphertext(:)', 'uint8')];
end