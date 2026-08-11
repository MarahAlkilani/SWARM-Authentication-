function hex_cipher = aes_encrypt(hex_key, plaintext)
    % AES-256 Encryption using Java Cryptography Extension (Safe Byte Casting)
    
    % Properly cast hex to uint8, then typecast to Java's signed int8
    key_uint8 = uint8(hex2dec(reshape(hex_key, 2, [])'));
    key_bytes = typecast(key_uint8, 'int8');
    
    secretKey = javaObject('javax.crypto.spec.SecretKeySpec', key_bytes, 'AES');
    cipher = javaMethod('getInstance', 'javax.crypto.Cipher', 'AES/ECB/PKCS5Padding');
    cipher.init(1, secretKey); % 1 = ENCRYPT_MODE
    
    % Safely cast plaintext characters to bytes
    pt_bytes = typecast(uint8(char(plaintext)), 'int8');
    enc_bytes = cipher.doFinal(pt_bytes);
    
    hex_cipher = sprintf('%02x', typecast(enc_bytes, 'uint8'));
end