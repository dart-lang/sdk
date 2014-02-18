// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Library tag to allow the test to run on Dartium.
library hmac_sha256_test;

import "package:unittest/unittest.dart";
import "package:crypto/crypto.dart";

part 'hmac_sha256_test_vectors.dart';

void main() {
  test('standard vectors', () {
    _testStandardVectors(hmac_sha256_inputs, hmac_sha256_keys,
        hmac_sha256_macs);
  });
}

void _testStandardVectors(inputs, keys, macs) {
  for (var i = 0; i < inputs.length; i++) {
    var hmac = new HMAC(new SHA256(), keys[i]);
    hmac.add(inputs[i]);
    var d = hmac.close();
    expect(CryptoUtils.bytesToHex(d).startsWith(macs[i]), isTrue);
  }
}
