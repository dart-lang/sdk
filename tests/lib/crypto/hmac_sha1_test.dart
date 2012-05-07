// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Library tag to allow the test to run on Dartium.
#library('hmac_sha1_test');

// TODO(ager): Replace with "dart:crypto" when ready.
#import("../../../lib/crypto/crypto.dart");

#source('hmac_sha1_test_vectors.dart');

void testStandardVectors(inputs, keys, macs) {
  for (var i = 0; i < inputs.length; i++) {
    var d = new HMAC(new SHA1(), keys[i]).update(inputs[i]).digest();
    Expect.isTrue(CryptoUtils.bytesToHex(d).startsWith(macs[i]), '$i');
  }
}

void main() {
  testStandardVectors(hmac_sha1_inputs, hmac_sha1_keys, hmac_sha1_macs);
}
