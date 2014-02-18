// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Library tag to allow the test to run on Dartium.
library base64_test;

import 'dart:math';

import "package:crypto/crypto.dart";
import "package:unittest/unittest.dart";

void main() {
  test('encoder', _testEncoder);
  test('decoder', _testDecoder);
  test('decoder for malformed input', _testDecoderForMalformedInput);
  test('encode decode lists', _testEncodeDecodeLists);
  test('url safe encode-decode', _testUrlSafeEncodeDecode);
  test('performance', _testPerformance);
}

// Data from http://tools.ietf.org/html/rfc4648.
const _INPUTS =
    const [ '', 'f', 'fo', 'foo', 'foob', 'fooba', 'foobar'];
const _RESULTS =
    const [ '', 'Zg==', 'Zm8=', 'Zm9v', 'Zm9vYg==', 'Zm9vYmE=', 'Zm9vYmFy'];

// Test data with only zeroes.
var inputsWithZeroes = [[0, 0, 0], [0, 0], [0], []];
const _RESULTS_WITH_ZEROS = const ['AAAA', 'AAA=', 'AA==', ''];

const _LONG_LINE =
    "Man is distinguished, not only by his reason, but by this singular "
    "passion from other animals, which is a lust of the mind, that by a "
    "perseverance of delight in the continued and indefatigable generation "
    "of knowledge, exceeds the short vehemence of any carnal pleasure.";

const _LONG_LINE_RESULT =
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

const _LONG_LINE_RESULT_NO_BREAK =
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

void _testEncoder() {
  for (var i = 0; i < _INPUTS.length; i++) {
    expect(CryptoUtils.bytesToBase64(_INPUTS[i].codeUnits), _RESULTS[i]);
  }
  for (var i = 0; i < inputsWithZeroes.length; i++) {
    expect(CryptoUtils.bytesToBase64(inputsWithZeroes[i]),
        _RESULTS_WITH_ZEROS[i]);
  }
  expect(
      CryptoUtils.bytesToBase64(_LONG_LINE.codeUnits, addLineSeparator : true),
      _LONG_LINE_RESULT);
  expect(CryptoUtils.bytesToBase64(_LONG_LINE.codeUnits),
      _LONG_LINE_RESULT_NO_BREAK);
}

void _testDecoder() {
  for (var i = 0; i < _RESULTS.length; i++) {
    expect(
        new String.fromCharCodes(CryptoUtils.base64StringToBytes(_RESULTS[i])),
        _INPUTS[i]);
  }
  for (var i = 0; i < _RESULTS_WITH_ZEROS.length; i++) {
    expect(CryptoUtils.base64StringToBytes(_RESULTS_WITH_ZEROS[i]),
        inputsWithZeroes[i]);
  }
  var longLineDecoded = CryptoUtils.base64StringToBytes(_LONG_LINE_RESULT);
  expect(new String.fromCharCodes(longLineDecoded), _LONG_LINE);
  var longLineResultNoBreak =
      CryptoUtils.base64StringToBytes(_LONG_LINE_RESULT);
  expect(new String.fromCharCodes(longLineResultNoBreak), _LONG_LINE);
}

void _testDecoderForMalformedInput() {
  expect(() {
    CryptoUtils.base64StringToBytes('AB~');
  }, throwsFormatException);

  expect(() {
    CryptoUtils.base64StringToBytes('A');
  }, throwsFormatException);
}

void _testUrlSafeEncodeDecode() {
  List<int> decUrlSafe = CryptoUtils.base64StringToBytes('-_A=');
  List<int> dec = CryptoUtils.base64StringToBytes('+/A=');
  expect(decUrlSafe, dec);
  expect(CryptoUtils.bytesToBase64(dec, urlSafe: true), '-_A=');
  expect(CryptoUtils.bytesToBase64(dec), '+/A=');
}

void _testEncodeDecodeLists() {
  for (int i = 0; i < 10; i++) {
    for (int j = 0; j < 256 - i; j++) {
      List<int> x = new List<int>(i);
      for (int k = 0; k < i; k++) {
        x[k] = j;
      }
      var enc = CryptoUtils.bytesToBase64(x);
      var dec = CryptoUtils.base64StringToBytes(enc);
      expect(dec, x);
    }
  }
}

void _fillRandom(List<int> l) {
  var random = new Random(0xBABE);
  for (int j = 0; j < l.length; j++) {
    l[j] = random.nextInt(255);
  }
}

void _testPerformance() {
    var l = new List<int>(1024);
    var iters = 5000;
    _fillRandom(l);
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
