function hex = secure_random_hex(nbytes)
hex = sprintf('%02x', secure_random_bytes(nbytes));
end
