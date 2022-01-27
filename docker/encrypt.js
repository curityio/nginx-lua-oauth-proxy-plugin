'use strict';

const crypto = require('crypto');
const {exit} = require('process');
const ENCRYPTION_KEY = '4e4636356d65563e4c73233847503e3b21436e6f7629724950526f4b5e2e4e50';
const GCM_IV_SIZE = 12;
const CURRENT_VERSION = 1;

try {

    var args = process.argv.slice(2);
    if (args.length < 1) {
        throw new Error('Please supply the plaintext data as a command line parameter');
    }

    const payloadText = args[0];
    const encryptionKeyBytes = Buffer.from(ENCRYPTION_KEY, 'hex');
    const ivBytes = crypto.randomBytes(GCM_IV_SIZE);
    const cipher = crypto.createCipheriv('aes-256-gcm', encryptionKeyBytes, ivBytes);
    
    const versionBytes = Buffer.from(new Uint8Array([CURRENT_VERSION]));
    const plaintextBytes = Buffer.from(payloadText);
    
    const encryptedBytes = cipher.update(plaintextBytes);
    const finalBytes = cipher.final()
    
    const ciphertextBytes = Buffer.concat([encryptedBytes, finalBytes]);
    const tagBytes = cipher.getAuthTag();

    const allBytes = Buffer.concat([versionBytes, ivBytes, ciphertextBytes, tagBytes]);
    const base64urlencoded = allBytes.toString('base64')
        .replace(/=/g, "")
        .replace(/\+/g, "-")
        .replace(/\//g, "_");

    console.log(base64urlencoded);
    exit(0);

} catch (e) {

    console.log(`utils.encrypt error:  ${e.message}`);
    exit(1);
}
