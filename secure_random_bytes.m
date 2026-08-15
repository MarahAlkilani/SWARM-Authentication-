function bytes = secure_random_bytes(n)
% Uses Java SecureRandom rather than MATLAB's simulation PRNG.
rng = javaObject('java.security.SecureRandom');
signed = zeros(1, n, 'int8');
rng.nextBytes(signed);
bytes = typecast(signed, 'uint8');
end
