// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.asset_test;

import 'dart:async';
import 'dart:convert' show Encoding, UTF8, LATIN1;
import 'dart:io';
import 'dart:utf';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as pathos;
import 'package:unittest/unittest.dart';

import 'utils.dart';

/// The contents of the test binary file.
final binaryContents = [0, 1, 2, 3, 4];

main() {
  initConfig();

  Directory tempDir;
  String binaryFilePath;
  String textFilePath;
  String utf32FilePath;

  setUp(() {
    // Create a temp file we can use for assets.
    tempDir = new Directory("").createTempSync();
    binaryFilePath = pathos.join(tempDir.path, "file.bin");
    new File(binaryFilePath).writeAsBytesSync(binaryContents);

    textFilePath = pathos.join(tempDir.path, "file.txt");
    new File(textFilePath).writeAsStringSync("çøñ†éℵ™");

    utf32FilePath = pathos.join(tempDir.path, "file.utf32");
    new File(utf32FilePath).writeAsBytesSync(encodeUtf32("çøñ†éℵ™"));
  });

  tearDown(() {
    if (tempDir != null) tempDir.deleteSync(recursive: true);
  });

  var id = new AssetId.parse("package|path/to/asset.txt");

  group("Asset.fromBytes", () {
    test("returns an asset with the given ID", () {
      var asset = new Asset.fromBytes(id, [1]);
      expect(asset.id, equals(id));
    });
  });

  group("Asset.fromFile", () {
    test("returns an asset with the given ID", () {
      var asset = new Asset.fromFile(id, new File("asset.txt"));
      expect(asset.id, equals(id));
    });
  });

  group("Asset.fromPath", () {
    test("returns an asset with the given ID", () {
      var asset = new Asset.fromPath(id, "asset.txt");
      expect(asset.id, equals(id));
    });
  });

  group("Asset.fromString", () {
    test("returns an asset with the given ID", () {
      var asset = new Asset.fromString(id, "content");
      expect(asset.id, equals(id));
    });
  });

  group("read()", () {
    test("gets the UTF-8-encoded string for a string asset", () {
      var asset = new Asset.fromString(id, "çøñ†éℵ™");
      expect(asset.read().toList(),
          completion(equals([encodeUtf8("çøñ†éℵ™")])));
    });

    test("gets the raw bytes for a byte asset", () {
      var asset = new Asset.fromBytes(id, binaryContents);
      expect(asset.read().toList(),
          completion(equals([binaryContents])));
    });

    test("gets the raw bytes for a binary file", () {
      var asset = new Asset.fromPath(id, binaryFilePath);
      expect(asset.read().toList(),
          completion(equals([binaryContents])));
    });

    test("gets the raw bytes for a text file", () {
      var asset = new Asset.fromPath(id, textFilePath);
      expect(asset.read().toList(),
          completion(equals([encodeUtf8("çøñ†éℵ™")])));
    });
  });

  group("readAsString()", () {
    group("byte asset", () {
      test("defaults to UTF-8 if encoding is omitted", () {
        var asset = new Asset.fromBytes(id, encodeUtf8("çøñ†éℵ™"));
        expect(asset.readAsString(),
            completion(equals("çøñ†éℵ™")));
      });

      test("supports UTF-8", () {
        var asset = new Asset.fromBytes(id, encodeUtf8("çøñ†éℵ™"));
        expect(asset.readAsString(encoding: UTF8),
            completion(equals("çøñ†éℵ™")));
      });

      // TODO(rnystrom): Test other encodings once #6284 is fixed.
    });

    group("string asset", () {
      test("gets the string", () {
        var asset = new Asset.fromString(id, "contents");
        expect(asset.readAsString(),
            completion(equals("contents")));
      });

      test("ignores the encoding", () {
        var asset = new Asset.fromString(id, "contents");
        expect(asset.readAsString(encoding: LATIN1),
            completion(equals("contents")));
      });
    });

    group("file asset", () {
      test("defaults to UTF-8 if encoding is omitted", () {
        var asset = new Asset.fromPath(id, textFilePath);
        expect(asset.readAsString(),
            completion(equals("çøñ†éℵ™")));
      });
    });
  });

  group("toString()", () {
    group("byte asset", () {
      test("shows the list of bytes in hex", () {
        var asset = new Asset.fromBytes(id,
            [0, 1, 2, 4, 8, 16, 32, 64, 128, 255]);
        expect(asset.toString(), equals(
            "Bytes [00 01 02 04 08 10 20 40 80 ff]"));
      });

      test("truncates the middle of there are more than ten bytes", () {
        var asset = new Asset.fromBytes(id,
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]);
        expect(asset.toString(), equals(
            "Bytes [01 02 03 04 05 ... 0a 0b 0c 0d 0e]"));
      });
    });

    group("string asset", () {
      test("shows the contents", () {
        var asset = new Asset.fromString(id, "contents");
        expect(asset.toString(), equals(
            'String "contents"'));
      });

      test("truncates the middle of there are more than 40 characters", () {
        var asset = new Asset.fromString(id,
            "this is a fairly long string asset content that gets shortened");
        expect(asset.toString(), equals(
            'String "this is a fairly lon ...  that gets shortened"'));
      });
    });

    group("file asset", () {
      test("shows the file path", () {
        var asset = new Asset.fromPath(id, "path.txt");
        expect(asset.toString(), equals('File "path.txt"'));
      });
    });
  });
}
