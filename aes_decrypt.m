function plaintext = aes_decrypt(hex_key, packet, aad)
% AES-256-GCM authenticated decryption.  Throws if ciphertext/AAD is altered.
    if nargin < 3, aad = ''; end
    key_bytes = typecast(uint8(hex2dec(reshape(hex_key, 2, [])')), 'int8');
    nonce_bytes = typecast(uint8(hex2dec(reshape(packet.nonce, 2, [])')), 'int8');
    cipher_bytes = uint8(hex2dec(reshape(packet.ciphertext, 2, [])'));
    tag_bytes = uint8(hex2dec(reshape(packet.tag, 2, [])'));
    cipher = javaMethod('getInstance', 'javax.crypto.Cipher', 'AES/GCM/NoPadding');
    key = javaObject('javax.crypto.spec.SecretKeySpec', key_bytes, 'AES');
    spec = javaObject('javax.crypto.spec.GCMParameterSpec', 128, nonce_bytes);
    cipher.init(2, key, spec);
    cipher.updateAAD(typecast(uint8(char(aad)), 'int8'));
    plaintext = char(typecast(cipher.doFinal(typecast([cipher_bytes; tag_bytes], 'int8')), 'uint8'))';
end
