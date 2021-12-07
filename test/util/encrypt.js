'use strict';

const crypto = require('crypto');
const {exit} = require('process');

const plaintext = '1234567890';
const ENC_KEY = 'NF65meV>Ls#8GP>;!Cnov)rIPRoK^.NP';
const IV = '551fbedfde28c548c5b43a8de98c7b59';

try {
    let cipher = crypto.createCipheriv('aes-256-cbc', ENC_KEY, Buffer.from(IV, 'hex'));
    var ciphertext = cipher.update(plaintext, 'utf8', 'hex');
    ciphertext += cipher.final('hex');
    console.log(`${IV}:${ciphertext}`);
    exit(0);

} catch (e) {

    console.log(e)
    exit(1);
}
