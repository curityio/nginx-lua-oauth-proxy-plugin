'use strict';

const crypto = require('crypto');
const {exit} = require('process');
const ENCRYPTION_KEY = 'NF65meV>Ls#8GP>;!Cnov)rIPRoK^.NP';

try {

    var args = process.argv.slice(2);
    if (args.length < 1) {
        throw new Error('Please supply the plaintext data as a command line parameter');
    }

    const iv = crypto.randomBytes(16);
    let cipher = crypto.createCipheriv('aes-256-cbc', ENCRYPTION_KEY, iv);
    var ciphertext = cipher.update(args[0], 'utf8', 'hex');
    ciphertext += cipher.final('hex');
    console.log(`${iv.toString('hex')}:${ciphertext}`);
    exit(0);

} catch (e) {

    console.log(`utils.encrypt error:  ${e.message}`);
    exit(1);
}
