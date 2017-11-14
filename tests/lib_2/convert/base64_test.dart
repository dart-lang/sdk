// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import "dart:typed_data";
import "package:expect/expect.dart";

main() {
  for (var list in [
    <int>[],
    [0x00],
    [0xff, 0x00],
    [0xff, 0xaa, 0x55],
    [0x00, 0x01, 0x02, 0x03],
    new Iterable<int>.generate(13).toList(),
    new Iterable<int>.generate(254).toList(),
    new Iterable<int>.generate(255).toList(),
    new Iterable<int>.generate(256).toList()
  ]) {
    testRoundtrip(list, "List#${list.length}");
    testRoundtrip(new Uint8List.fromList(list), "Uint8List#${list.length}");
  }
  testErrors();
  testIssue25577();

  // Decoder is lenienet with mixed styles.
  Expect.listEquals([0xfb, 0xff, 0xbf, 0x00], BASE64.decode("-_+/AA%3D="));
  Expect.listEquals([0xfb, 0xff, 0xbf, 0x00], BASE64.decode("-_+/AA=%3D"));
}

void testRoundtrip(List<int> list, String name) {
  // Direct.
  String encodedNormal = BASE64.encode(list);
  String encodedPercent = encodedNormal.replaceAll("=", "%3D");
  String uriEncoded = BASE64URL.encode(list);
  String expectedUriEncoded =
      encodedNormal.replaceAll("+", "-").replaceAll("/", "_");
  Expect.equals(expectedUriEncoded, uriEncoded);

  List result = BASE64.decode(encodedNormal);
  Expect.listEquals(list, result, name);
  result = BASE64.decode(encodedPercent);
  Expect.listEquals(list, result, name);
  result = BASE64.decode(uriEncoded);
  Expect.listEquals(list, result, name);

  int increment = list.length ~/ 7 + 1;
  // Chunked.
  for (int i = 0; i < list.length; i += increment) {
    for (int j = i; j < list.length; j += increment) {
      // Normal
      {
        // Using add/close
        var results;
        var sink = new ChunkedConversionSink<String>.withCallback((v) {
          results = v;
        });
        var encoder = BASE64.encoder.startChunkedConversion(sink);
        encoder.add(list.sublist(0, i));
        encoder.add(list.sublist(i, j));
        encoder.add(list.sublist(j, list.length));
        encoder.close();
        var name = "0-$i-$j-${list.length}: list";
        Expect.equals(encodedNormal, results.join(""), name);
      }
      {
        // Using addSlice
        var results;
        var sink = new ChunkedConversionSink<String>.withCallback((v) {
          results = v;
        });
        var encoder = BASE64.encoder.startChunkedConversion(sink);
        encoder.addSlice(list, 0, i, false);
        encoder.addSlice(list, i, j, false);
        encoder.addSlice(list, j, list.length, true);
        var name = "0-$i-$j-${list.length}: $list";
        Expect.equals(encodedNormal, results.join(""), name);
      }
      // URI
      {
        // Using add/close
        var results;
        var sink = new ChunkedConversionSink<String>.withCallback((v) {
          results = v;
        });
        var encoder = BASE64URL.encoder.startChunkedConversion(sink);
        encoder.add(list.sublist(0, i));
        encoder.add(list.sublist(i, j));
        encoder.add(list.sublist(j, list.length));
        encoder.close();
        var name = "0-$i-$j-${list.length}: list";
        Expect.equals(uriEncoded, results.join(""), name);
      }
      {
        // Using addSlice
        var results;
        var sink = new ChunkedConversionSink<String>.withCallback((v) {
          results = v;
        });
        var encoder = BASE64URL.encoder.startChunkedConversion(sink);
        encoder.addSlice(list, 0, i, false);
        encoder.addSlice(list, i, j, false);
        encoder.addSlice(list, j, list.length, true);
        var name = "0-$i-$j-${list.length}: $list";
        Expect.equals(uriEncoded, results.join(""), name);
      }
    }
  }

  for (var encoded in [encodedNormal, encodedPercent, uriEncoded]) {
    increment = encoded.length ~/ 7 + 1;
    for (int i = 0; i < encoded.length; i += increment) {
      for (int j = i; j < encoded.length; j += increment) {
        {
          // Using add/close
          List<List<int>> results;
          var sink = new ChunkedConversionSink<List<int>>.withCallback((v) {
            results = v;
          });
          var decoder = BASE64.decoder.startChunkedConversion(sink);
          decoder.add(encoded.substring(0, i));
          decoder.add(encoded.substring(i, j));
          decoder.add(encoded.substring(j, encoded.length));
          decoder.close();
          var name = "0-$i-$j-${encoded.length}: $encoded";
          Expect.listEquals(list, results.expand((x) => x).toList(), name);
        }
        {
          // Using addSlice
          List<List<int>> results;
          var sink = new ChunkedConversionSink<List<int>>.withCallback((v) {
            results = v;
          });
          var decoder = BASE64.decoder.startChunkedConversion(sink);
          decoder.addSlice(encoded, 0, i, false);
          decoder.addSlice(encoded, i, j, false);
          decoder.addSlice(encoded, j, encoded.length, true);
          var name = "0-$i-$j-${encoded.length}: $encoded";
          Expect.listEquals(list, results.expand((x) => x).toList(), name);
        }
      }
    }
  }
}

void testErrors() {
  void badChunkDecode(List<String> list) {
    Expect.throwsFormatException(() {
      var sink = new ChunkedConversionSink<List<int>>.withCallback((v) {
        Expect.fail("Should have thrown: chunk $list");
      });
      var c = BASE64.decoder.startChunkedConversion(sink);
      for (String string in list) {
        c.add(string);
      }
      c.close();
    }, "chunk $list");
  }

  void badDecode(String string) {
    Expect.throwsFormatException(() => BASE64.decode(string), string);
    Expect.throwsFormatException(() => BASE64URL.decode(string), string);
    badChunkDecode([string]);
    badChunkDecode(["", string]);
    badChunkDecode([string, ""]);
    badChunkDecode([string, "", ""]);
    badChunkDecode(["", string, ""]);
  }

  badDecode("A");
  badDecode("AA");
  badDecode("AAA");
  badDecode("AAAAA");
  badDecode("AAAAAA");
  badDecode("AAAAAAA");
  badDecode("AAAA=");
  badDecode("AAAA==");
  badDecode("AAAA===");
  badDecode("AAAA====");
  badDecode("AAAA%");
  badDecode("AAAA%3");
  badDecode("AAAA%3D");
  badDecode("AAA%3D%");
  badDecode("AAA%3D=");
  badDecode("A=");
  badDecode("A=A");
  badDecode("A==");
  badDecode("A==A");
  badDecode("A===");
  badDecode("====");
  badDecode("AA=");
  badDecode("AA%=");
  badDecode("AA%3");
  badDecode("AA%3D");
  badDecode("AA===");
  badDecode("AAA==");
  badDecode("AAA=AAAA");
  badDecode("AAA\x00");
  badDecode("AAA=\x00");
  badDecode("AAA\x80");
  badDecode("AAA\xFF");
  badDecode("AAA\u{141}");
  badDecode("AAA\u{1041}");
  badDecode("AAA\u{10041}");
  badDecode("AA\u{141}=");
  badDecode("AA\u{1041}=");
  badDecode("AA\u{10041}=");

  var alphabet =
      "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/-_";
  var units = alphabet.codeUnits;
  for (int i = 0; i < 128; i++) {
    if (!units.contains(i)) {
      badDecode(new String.fromCharCode(i) * 4);
    }
  }

  badChunkDecode(["A", "A"]);
  badChunkDecode(["A", "A", "A"]);
  badChunkDecode(["A", "A", "="]);
  badChunkDecode(["A", "A", "=", ""]);
  badChunkDecode(["A", "A", "=", "=", "="]);
  badChunkDecode(["AAA", "=="]);
  badChunkDecode(["A", "A", "A"]);
  badChunkDecode(["AAA", ""]);
  badChunkDecode(["AA=", ""]);
  badChunkDecode(["AB==", ""]);

  badChunkEncode(List<int> list) {
    for (int i = 0; i < list.length; i++) {
      for (int j = 0; j < list.length; j++) {
        Expect.throwsArgumentError(() {
          var sink = new ChunkedConversionSink<String>.withCallback((v) {
            Expect.fail("Should have thrown: chunked $list");
          });
          var c = BASE64.encoder.startChunkedConversion(sink);
          c.add(list.sublist(0, i));
          c.add(list.sublist(i, j));
          c.add(list.sublist(j, list.length));
          c.close();
        }, "chunk $list");
      }
    }
    for (int i = 0; i < list.length; i++) {
      for (int j = 0; j < list.length; j++) {
        Expect.throwsArgumentError(() {
          var sink = new ChunkedConversionSink<String>.withCallback((v) {
            Expect.fail("Should have thrown: chunked $list");
          });
          var c = BASE64.encoder.startChunkedConversion(sink);
          c.addSlice(list, 0, i, false);
          c.addSlice(list, i, j, false);
          c.addSlice(list, j, list.length, true);
        }, "chunk $list");
      }
    }
  }

  void badEncode(int invalid) {
    Expect.throwsArgumentError(() => BASE64.encode([invalid]), "$invalid");
    Expect.throwsArgumentError(
        () => BASE64.encode([0, invalid, 0]), "$invalid");
    badChunkEncode([invalid]);
    badChunkEncode([0, invalid]);
    badChunkEncode([0, 0, invalid]);
    badChunkEncode([0, invalid, 0]);
    badChunkEncode([invalid, 0, 0]);
  }

  badEncode(-1);
  badEncode(0x100);
  badEncode(0x1000);
  badEncode(0x10000);
  badEncode(0x100000000); //         //# 01: ok
  badEncode(0x10000000000000000); // //# 01: continued
}

void testIssue25577() {
  // Regression test for http://dartbug.com/25577.
  StringConversionSink decodeSink =
      BASE64.decoder.startChunkedConversion(new TestSink<List<int>>());
  ByteConversionSink encodeSink =
      BASE64.encoder.startChunkedConversion(new TestSink<String>());
}

// Implementation of Sink<T> to test type constraints.
class TestSink<T> implements Sink<T> {
  void add(T value) {}
  void close() {}
}
