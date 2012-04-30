// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(ager): Replace with "dart:crypto" when ready.
#import("../../../lib/crypto/crypto.dart");

#source('hmac_sha1_test_vectors.dart');

String digestToString(List<int> digest) {
  var buf = new StringBuffer();
  for (var part in digest) {
    buf.add("${(part < 16) ? "0" : ""}${part.toRadixString(16).toLowerCase()}");
  }
  return buf.toString();
}

void testStandardVectors(inputs, keys, macs) {
  for (var i = 0; i < inputs.length; i++) {
    var d = new HMAC(new SHA1(), keys[i]).update(inputs[i]).digest();
    Expect.isTrue(digestToString(d).startsWith(macs[i]), '$i');
  }
}

void main() {
  testStandardVectors(hmac_sha1_inputs, hmac_sha1_keys, hmac_sha1_macs);
}
