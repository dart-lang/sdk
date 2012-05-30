// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Library tag to allow the test to run on Dartium.
#library('base64_test');

#import("dart:crypto");

// Data from http://tools.ietf.org/html/rfc4648.
var inputs =
    const [ '', 'f', 'fo', 'foo', 'foob', 'fooba', 'foobar' ];
var results =
    const [ '', 'Zg==', 'Zm8=', 'Zm9v', 'Zm9vYg==', 'Zm9vYmE=', 'Zm9vYmFy' ];

var longLine =
    "Man is distinguished, not only by his reason, but by this singular "
    "passion from other animals, which is a lust of the mind, that by a "
    "perseverance of delight in the continued and indefatigable generation "
    "of knowledge, exceeds the short vehemence of any carnal pleasure.";

var longLineResult =
    "TWFuIGlzIGRpc3Rpbmd1aXNoZWQsIG5vdCBvbm"
    "x5IGJ5IGhpcyByZWFzb24sIGJ1dCBieSB0aGlz\r\n"
    "IHNpbmd1bGFyIHBhc3Npb24gZnJvbSBvdGhlci"
    "BhbmltYWxzLCB3aGljaCBpcyBhIGx1c3Qgb2Yg\r\n"
    "dGhlIG1pbmQsIHRoYXQgYnkgYSBwZXJzZXZlcm"
    "FuY2Ugb2YgZGVsaWdodCBpbiB0aGUgY29udGlu\r\n"
    "dWVkIGFuZCBpbmRlZmF0aWdhYmxlIGdlbmVyYX"
    "Rpb24gb2Yga25vd2xlZGdlLCBleGNlZWRzIHRo\r\n"
    "ZSBzaG9ydCB2ZWhlbWVuY2Ugb2YgYW55IGNhcm"
    "5hbCBwbGVhc3VyZS4=";

var longLineResultNoBreak =
    "TWFuIGlzIGRpc3Rpbmd1aXNoZWQsIG5vdCBvbm"
    "x5IGJ5IGhpcyByZWFzb24sIGJ1dCBieSB0aGlz"
    "IHNpbmd1bGFyIHBhc3Npb24gZnJvbSBvdGhlci"
    "BhbmltYWxzLCB3aGljaCBpcyBhIGx1c3Qgb2Yg"
    "dGhlIG1pbmQsIHRoYXQgYnkgYSBwZXJzZXZlcm"
    "FuY2Ugb2YgZGVsaWdodCBpbiB0aGUgY29udGlu"
    "dWVkIGFuZCBpbmRlZmF0aWdhYmxlIGdlbmVyYX"
    "Rpb24gb2Yga25vd2xlZGdlLCBleGNlZWRzIHRo"
    "ZSBzaG9ydCB2ZWhlbWVuY2Ugb2YgYW55IGNhcm"
    "5hbCBwbGVhc3VyZS4=";

void main() {
  for (var i = 0; i < inputs.length; i++) {
    var enc = CryptoUtils.bytesToBase64(inputs[i].charCodes());
    Expect.equals(results[i], enc);
  }
  Expect.equals(CryptoUtils.bytesToBase64(longLine.charCodes(), 76),
                longLineResult);
  Expect.equals(CryptoUtils.bytesToBase64(longLine.charCodes()),
                longLineResultNoBreak);
}
