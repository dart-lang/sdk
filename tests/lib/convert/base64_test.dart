// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import "dart:typed_data";
import "package:expect/expect.dart";

main() {
  for (var list in [[],
                    [0x00],
                    [0xff, 0x00],
                    [0xff, 0xaa, 0x55],
                    [0x00, 0x01, 0x02, 0x03],
                    new Iterable.generate(13).toList(),
                    new Iterable.generate(254).toList(),
                    new Iterable.generate(255).toList(),
                    new Iterable.generate(256).toList()]) {
    testRoundtrip(list, "List#${list.length}");
    testRoundtrip(new Uint8List.fromList(list), "Uint8List#${list.length}");
  }
  testErrors();

  // Decoder is lenienet with mixed styles.
  Expect.listEquals([0xfb, 0xff, 0xbf, 0x00], BASE64.decode("-_+/AA%3D="));
  Expect.listEquals([0xfb, 0xff, 0xbf, 0x00], BASE64.decode("-_+/AA=%3D"));
}

void testRoundtrip(list, name) {
  // Direct.
  String encodedNormal = BASE64.encode(list);
  String encodedPercent = encodedNormal.replaceAll("=", "%3D");
  String uriEncoded = encodedNormal.replaceAll("+", "-").replaceAll("/", "_");
  List result = BASE64.decode(encodedNormal);
  Expect.listEquals(list, result, name);
  result = BASE64.decode(encodedPercent);
  Expect.listEquals(list, result, name);

  int increment = list.length ~/ 7 + 1;
  // Chunked.
  for (int i = 0; i < list.length; i += increment) {
    for (int j = i; j < list.length; j += increment) {
      {
        // Using add/close
        var results;
        var sink = new ChunkedConversionSink.withCallback((v) { results = v; });
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
        var sink = new ChunkedConversionSink.withCallback((v) { results = v; });
        var encoder = BASE64.encoder.startChunkedConversion(sink);
        encoder.addSlice(list, 0, i, false);
        encoder.addSlice(list, i, j, false);
        encoder.addSlice(list, j, list.length, true);
        var name = "0-$i-$j-${list.length}: $list";
        Expect.equals(encodedNormal, results.join(""), name);
      }
    }
  }

  for (var encoded in [encodedNormal, encodedPercent, uriEncoded]) {
    increment = encoded.length ~/ 7 + 1;
    for (int i = 0; i < encoded.length; i += increment) {
      for (int j = i; j < encoded.length; j += increment) {
        {
          // Using add/close
          var results;
          var sink =
              new ChunkedConversionSink.withCallback((v) { results = v; });
          var decoder = BASE64.decoder.startChunkedConversion(sink);
          decoder.add(encoded.substring(0, i));
          decoder.add(encoded.substring(i, j));
          decoder.add(encoded.substring(j, encoded.length));
          decoder.close();
          var name = "0-$i-$j-${encoded.length}: $encoded";
          Expect.listEquals(list, results.expand((x)=>x).toList(), name);
        }
        {
          // Using addSlice
          var results;
          var sink =
              new ChunkedConversionSink.withCallback((v) { results = v; });
          var decoder = BASE64.decoder.startChunkedConversion(sink);
          decoder.addSlice(encoded, 0, i, false);
          decoder.addSlice(encoded, i, j, false);
          decoder.addSlice(encoded, j, encoded.length, true);
          var name = "0-$i-$j-${encoded.length}: $encoded";
          Expect.listEquals(list, results.expand((x)=>x).toList(), name);
        }
      }
    }
  }
}

bool isFormatException(e) => e is FormatException;
bool isArgumentError(e) => e is ArgumentError;

void testErrors() {
  void badChunkDecode(List<String> list) {
    Expect.throws(() {
      var sink = new ChunkedConversionSink.withCallback((v) {
        Expect.fail("Should have thrown: chunk $list");
      });
      var c = BASE64.decoder.startChunkedConversion(sink);
      for (String string in list) {
        c.add(string);
      }
      c.close();
    }, isFormatException, "chunk $list");
  }
  void badDecode(String string) {
    Expect.throws(() => BASE64.decode(string), isFormatException, string);
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


  badChunkEncode(list) {
    for (int i = 0; i < list.length; i++) {
      for (int j = 0; j < list.length; j++) {
        Expect.throws(() {
          var sink = new ChunkedConversionSink.withCallback((v) {
            Expect.fail("Should have thrown: chunked $list");
          });
          var c = BASE64.encoder.startChunkedConversion(sink);
          c.add(list.sublist(0, i));
          c.add(list.sublist(i, j));
          c.add(list.sublist(j, list.length));
          c.close();
        }, isArgumentError, "chunk $list");
      }
    }
    for (int i = 0; i < list.length; i++) {
      for (int j = 0; j < list.length; j++) {
        Expect.throws(() {
          var sink = new ChunkedConversionSink.withCallback((v) {
            Expect.fail("Should have thrown: chunked $list");
          });
          var c = BASE64.encoder.startChunkedConversion(sink);
          c.addSlice(list, 0, i, false);
          c.addSlice(list, i, j, false);
          c.addSlice(list, j, list.length, true);
        }, isArgumentError, "chunk $list");
      }
    }
  }

  void badEncode(int invalid) {
    Expect.throws(() {
      BASE64.encode([invalid]);
    }, isArgumentError, "$invalid");
    Expect.throws(() {
      BASE64.encode([0, invalid, 0]);
    }, isArgumentError, "$invalid");
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
  badEncode(0x100000000);          /// 01: ok
  badEncode(0x10000000000000000);  /// 01: continued
}
