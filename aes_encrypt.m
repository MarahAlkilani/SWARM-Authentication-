function packet = aes_encrypt(hex_key, plaintext, aad)
% AES-256-GCM encryption.  Returns a struct containing a fresh nonce,
% ciphertext, and authentication tag.  `aad` is authenticated, not encrypted.
    if nargin < 3, aad = ''; end
    key_bytes = typecast(uint8(hex2dec(reshape(hex_key, 2, [])')), 'int8');
    nonce_uint8 = secure_random_bytes(12); % NIST-recommended GCM nonce size
    nonce_bytes = typecast(nonce_uint8, 'int8');
    cipher = javaMethod('getInstance', 'javax.crypto.Cipher', 'AES/GCM/NoPadding');
    key = javaObject('javax.crypto.spec.SecretKeySpec', key_bytes, 'AES');
    spec = javaObject('javax.crypto.spec.GCMParameterSpec', 128, nonce_bytes);
    cipher.init(1, key, spec);
    cipher.updateAAD(typecast(uint8(char(aad)), 'int8'));
    encrypted_with_tag = cipher.doFinal(typecast(uint8(char(plaintext)), 'int8'));
    result = typecast(encrypted_with_tag, 'uint8');
    packet = struct('nonce', sprintf('%02x', nonce_uint8), ...
                    'ciphertext', sprintf('%02x', result(1:end-16)), ...
                    'tag', sprintf('%02x', result(end-15:end)));
end
