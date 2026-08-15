function [ciphertext, iv] = aes_encrypt(plaintext_str, key_bytes)
    import javax.crypto.Cipher;
    import javax.crypto.spec.SecretKeySpec;
    import javax.crypto.spec.GCMParameterSpec;
    
    % Generate a fresh 96-bit (12-byte) IV for GCM
    iv = randi([0 255], 1, 12, 'int8');
    
    % Initialize AES-GCM
    secretKey = SecretKeySpec(int8(key_bytes), 'AES');
    cipher = Cipher.getInstance('AES/GCM/NoPadding');
    gcmSpec = GCMParameterSpec(128, iv);
    
    cipher.init(Cipher.ENCRYPT_MODE, secretKey, gcmSpec);
    
    % Encrypt the payload
    plaintext_bytes = int8(unicode2native(plaintext_str, 'UTF-8'));
    ciphertext = cipher.doFinal(plaintext_bytes);
end