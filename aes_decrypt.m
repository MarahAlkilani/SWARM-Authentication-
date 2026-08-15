function plaintext_str = aes_decrypt(ciphertext, key_bytes, iv)
    import javax.crypto.Cipher;
    import javax.crypto.spec.SecretKeySpec;
    import javax.crypto.spec.GCMParameterSpec;
    
    % Rebuild AES-GCM parameters
    secretKey = SecretKeySpec(int8(key_bytes), 'AES');
    cipher = Cipher.getInstance('AES/GCM/NoPadding');
    gcmSpec = GCMParameterSpec(128, iv);
    
    cipher.init(Cipher.DECRYPT_MODE, secretKey, gcmSpec);
    
    try
        % Decrypt and simultaneously authenticate the GCM tag
        plaintext_bytes = cipher.doFinal(ciphertext);
        plaintext_str = native2unicode(typecast(plaintext_bytes, 'uint8'), 'UTF-8');
    catch ME
        error('AEADBadTagException: Ciphertext or IV was tampered with in transit!');
    end
end