function plaintext = aes_decrypt(hex_key, hex_cipher)
    % AES-256 Decryption using Java Cryptography Extension (Safe Byte Casting)
    
    % Properly cast hex to uint8, then typecast to Java's signed int8
    key_uint8 = uint8(hex2dec(reshape(hex_key, 2, [])'));
    key_bytes = typecast(key_uint8, 'int8');
    
    secretKey = javaObject('javax.crypto.spec.SecretKeySpec', key_bytes, 'AES');
    cipher = javaMethod('getInstance', 'javax.crypto.Cipher', 'AES/ECB/PKCS5Padding');
    cipher.init(2, secretKey); % 2 = DECRYPT_MODE
    
    % Safely cast ciphertext hex to bytes
    cipher_uint8 = uint8(hex2dec(reshape(hex_cipher, 2, [])'));
    cipher_bytes = typecast(cipher_uint8, 'int8');
    
    dec_bytes = cipher.doFinal(cipher_bytes);
    plaintext = char(typecast(dec_bytes, 'uint8'))';
end