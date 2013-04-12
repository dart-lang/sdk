// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Library tag to allow the test to run on Dartium.
library base64_test;

import "package:expect/expect.dart";
import 'dart:crypto';
import 'dart:math';

// Data from http://tools.ietf.org/html/rfc4648.
var inputs =
    const [ '', 'f', 'fo', 'foo', 'foob', 'fooba', 'foobar'];
var results =
    const [ '', 'Zg==', 'Zm8=', 'Zm9v', 'Zm9vYg==', 'Zm9vYmE=', 'Zm9vYmFy'];

// Test data with only zeroes.
var inputsWithZeroes = [[0, 0, 0], [0, 0], [0], []];
var resultsWithZeroes = ['AAAA', 'AAA=', 'AA==', ''];

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

testEncoder() {
  for (var i = 0; i < inputs.length; i++) {
    Expect.equals(results[i], CryptoUtils.bytesToBase64(inputs[i].codeUnits));
  }
  for (var i = 0; i < inputsWithZeroes.length; i++) {
    Expect.equals(resultsWithZeroes[i],
        CryptoUtils.bytesToBase64(inputsWithZeroes[i]));
  }
  Expect.equals(
      CryptoUtils.bytesToBase64(longLine.codeUnits, addLineSeparator : true),
      longLineResult);
  Expect.equals(CryptoUtils.bytesToBase64(longLine.codeUnits),
                longLineResultNoBreak);
}

testDecoder() {
  for (var i = 0; i < results.length; i++) {
    Expect.equals(inputs[i],
        new String.fromCharCodes(CryptoUtils.base64StringToBytes(results[i])));
  }
  for (var i = 0; i < resultsWithZeroes.length; i++) {
    Expect.listEquals(inputsWithZeroes[i],
        CryptoUtils.base64StringToBytes(resultsWithZeroes[i]));
  }
  var longLineDecoded = CryptoUtils.base64StringToBytes(longLineResult);
  Expect.equals(new String.fromCharCodes(longLineDecoded), longLine);
  var longLineResultNoBreak = CryptoUtils.base64StringToBytes(longLineResult);
  Expect.equals(new String.fromCharCodes(longLineResultNoBreak), longLine);
}

testDecoderForMalformedInput() {
  Expect.throws(() {
      CryptoUtils.base64StringToBytes('AB~', ignoreInvalidCharacters: false);
    }, (e) => e is FormatException);

  Expect.throws(() {
    CryptoUtils.base64StringToBytes('A');
  }, (e) => e is FormatException);

  Expect.listEquals('f'.codeUnits,
      CryptoUtils.base64StringToBytes('~~Zg==@@@',
          ignoreInvalidCharacters: true));
}

testUrlSafeEncodeDecode() {
  List<int> decUrlSafe = CryptoUtils.base64StringToBytes('-_A=');
  List<int> dec = CryptoUtils.base64StringToBytes('+/A=');
  Expect.listEquals(decUrlSafe, dec);
  Expect.equals('-_A=', CryptoUtils.bytesToBase64(dec, urlSafe: true));
  Expect.equals('+/A=', CryptoUtils.bytesToBase64(dec));
}

testEncodeDecodeLists() {
  for (int i = 0; i < 10; i++) {
    for (int j = 0; j < 256 - i; j++) {
      List<int> x = new List<int>(i);
      for (int k = 0; k < i; k++) {
        x[k] = j;
      }
      var enc = CryptoUtils.bytesToBase64(x);
      var dec = CryptoUtils.base64StringToBytes(enc);
      Expect.listEquals(x, dec);
    }
  }
}

fillRandom(List<int> l) {
  var random = new Random(0xBABE);
  for(int j=0; j < l.length; j++) {
    l[j] = random.nextInt(255);
  }
}

testPerformance() {
    var l = new List<int>(1024);
    var iters = 5000;
    fillRandom(l);
    String enc;
    var w = new Stopwatch()..start();
    for( int i = 0; i < iters; ++i ) {
      enc = CryptoUtils.bytesToBase64(l);
    }
    int ms = w.elapsedMilliseconds;
    int perSec = (iters * l.length) * 1000 ~/ ms;
    // print("Encode 1024 bytes for $iters times: $ms msec. $perSec b/s");
    w..reset();
    for( int i = 0; i < iters; ++i ) {
      CryptoUtils.base64StringToBytes(enc);
    }
    ms = w.elapsedMilliseconds;
    perSec = (iters * l.length) * 1000 ~/ ms;
    // print('''Decode into ${l.length} bytes for $iters
    //     times: $ms msec. $perSec b/s''');
}

void main() {
  testEncoder();
  testDecoder();
  testDecoderForMalformedInput();
  testEncodeDecodeLists();
  testUrlSafeEncodeDecode();
  testPerformance();
}
