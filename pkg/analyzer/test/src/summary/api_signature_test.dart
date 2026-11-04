// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/binary/binary_reader.dart';
import 'package:analyzer/src/binary/binary_writer.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' show md5;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utilities/hash/blake3_reference.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ApiSignatureTest);
    defineReflectiveTests(Blake3ApiSignatureTest);
  });
}

@reflectiveTest
class ApiSignatureTest {
  ApiSignature sig = ApiSignature.unversioned();

  void checkBytes(List<int> bytes) {
    expect(sig.getBytes_forDebug(), bytes);
    expect(sig.toHex(), hex.encode(md5.convert(bytes).bytes));
  }

  void test_addBool() {
    sig.addBool(true);
    sig.addBool(true);
    sig.addBool(false);
    sig.addBool(true);
    sig.addBool(false);
    sig.addBool(false);
    sig.addBool(true);
    sig.addBool(false);
    checkBytes([1, 1, 0, 1, 0, 0, 1, 0]);
  }

  void test_addBytes() {
    // Check that offset works correctly by adding bytes in 2 chunks.
    sig.addBytes([1, 2, 3, 4, 5]);
    sig.addBytes([0xff, 0xfe, 0xfd, 0xfc, 0xfb]);
    checkBytes([1, 2, 3, 4, 5, 0xff, 0xfe, 0xfd, 0xfc, 0xfb]);
  }

  void test_addDouble() {
    sig.addDouble(1.0 / 3.0);
    sig.addDouble(-1.0);
    checkBytes([85, 85, 85, 85, 85, 85, 213, 63, 0, 0, 0, 0, 0, 0, 240, 191]);
  }

  void test_addInt() {
    sig.addInt(1);
    sig.addInt(1000);
    sig.addInt(1000000);
    sig.addInt(1000000000);
    checkBytes([
      1,
      0,
      0,
      0,
      0xe8,
      3,
      0,
      0,
      0x40,
      0x42,
      0xf,
      0,
      0,
      0xca,
      0x9a,
      0x3b,
    ]);
  }

  void test_addString() {
    sig.addString('abc');
    sig.addString('\u00f8');
    checkBytes([3, 0, 0, 0, 0x61, 0x62, 0x63, 2, 0, 0, 0, 0xc3, 0xb8]);
  }

  void test_manyInts() {
    // This verifies that the logic to extend the internal buffer works
    // properly.
    List<int> expectedResult = [];
    for (int i = 0; i < 100000; i++) {
      sig.addInt(i);
      expectedResult.add(i % 0x100);
      expectedResult.add((i ~/ 0x100) % 0x100);
      expectedResult.add((i ~/ 0x10000) % 0x100);
      expectedResult.add((i ~/ 0x1000000) % 0x100);
    }
    checkBytes(expectedResult);
  }
}

@reflectiveTest
class Blake3ApiSignatureTest {
  void checkSignature(Blake3ApiSignature signature, ApiSignature encoding) {
    var expected = referenceBlake3(encoding.getBytes_forDebug());
    expect(signature.toByteList(), expected);
    expect(signature.toHex(), hex.encode(expected));
    expect(signature.toUint32List().buffer.asUint8List(), expected);
    var hash = signature.toHash();
    expect(hash.toString(), hex.encode(expected));
    var writer = BinaryWriter();
    hash.write(writer);
    var restored = Hash.read(BinaryReader(writer.takeBytes()));
    expect(restored, hash);
    expect(restored.hashCode, hash.hashCode);
  }

  void test_addBytes_bufferBoundaries() {
    for (var prefix in [0, 1, 3, 4, 59, 60, 61, 63, 64, 65]) {
      for (var length in [0, 1, 3, 4, 63, 64, 65, 127, 128, 1025, 4097]) {
        var input = _bytes(length);
        var signature = Blake3ApiSignature()
          ..addBytes(_bytes(prefix))
          ..addBytes(input)
          ..addInt(0x12345678)
          ..addBytes(input)
          ..addBytes(_bytes(65));
        var encoding = ApiSignature.unversioned()
          ..addBytes(_bytes(prefix))
          ..addBytes(input)
          ..addInt(0x12345678)
          ..addBytes(input)
          ..addBytes(_bytes(65));
        input.fillRange(0, input.length, 0);
        checkSignature(signature, encoding);
      }
    }
  }

  void test_addBytes_interleavedPrimitives() {
    for (var prefix in [0, 1, 3, 4, 55, 56, 57, 60, 61, 63, 64, 65]) {
      for (var length in [0, 1, 63, 64, 65, 1023, 1024, 1025, 4092, 4096]) {
        var bytes = _bytes(length);
        var signature = Blake3ApiSignature()
          ..addBytes(_bytes(prefix))
          ..addInt(0x12345678)
          ..addDouble(1 / 3)
          ..addBytes(bytes)
          ..addBool(true)
          ..addBytes(Uint8List(0));
        var encoding = ApiSignature.unversioned()
          ..addBytes(_bytes(prefix))
          ..addInt(0x12345678)
          ..addDouble(1 / 3)
          ..addBytes(bytes)
          ..addBool(true)
          ..addBytes([]);
        checkSignature(signature, encoding);
      }
    }
  }

  void test_addBytes_largeAndFragmented() {
    var bytes = _bytes(65537);
    var encoding = ApiSignature.unversioned()..addBytes(bytes);
    for (var size in [1, 3, 63, 64, 65, 1024, 4096, 65537]) {
      var signature = Blake3ApiSignature();
      for (var start = 0; start < bytes.length; start += size) {
        signature.addBytes(
          Uint8List.sublistView(bytes, start, min(start + size, bytes.length)),
        );
      }
      checkSignature(signature, encoding);
    }
    var large = _bytes(1024 * 1024);
    checkSignature(
      Blake3ApiSignature()..addBytes(large),
      ApiSignature.unversioned()..addBytes(large),
    );
  }

  void test_addBytes_largeViewsAfterPartialBuffers() {
    for (var prefix in [0, 1, 2, 3, 4095, 4096, 4097]) {
      for (var offset = 0; offset < 4; offset++) {
        for (var length in [4096, 4097, 8192, 16385]) {
          var input = Uint8List.sublistView(_bytes(length + offset), offset);
          var signature = Blake3ApiSignature()
            ..addBytes(_bytes(prefix))
            ..addBytes(input.asUnmodifiableView())
            ..addBool(true)
            ..addBytes(input);
          var encoding = ApiSignature.unversioned()
            ..addBytes(_bytes(prefix))
            ..addBytes(input)
            ..addBool(true)
            ..addBytes(input);
          input.fillRange(0, input.length, 0);
          checkSignature(signature, encoding);
        }
      }
    }
  }

  void test_addBytes_viewsAndOwnership() {
    for (var length in [0, 3, 60, 64, 65, 1025, 4097]) {
      for (var offset in [0, 1, 2, 3, 4]) {
        var backing = _bytes(length + 8);
        var before = Uint8List.fromList(backing);
        var view = Uint8List.sublistView(backing, offset, offset + length);
        var encoding = ApiSignature.unversioned()..addBytes(view);
        var signature = Blake3ApiSignature()
          ..addBytes(view.asUnmodifiableView());
        expect(backing, before);
        backing.fillRange(0, backing.length, 0);
        checkSignature(signature, encoding);
      }
      var input = _bytes(length);
      var encoding = ApiSignature.unversioned()..addBytes(input);
      var signature = Blake3ApiSignature()..addBytes(input);
      input.fillRange(0, input.length, 0);
      checkSignature(signature, encoding);
    }
  }

  void test_addCollections() {
    var signature = Blake3ApiSignature();
    var encoding = ApiSignature.unversioned();
    var features = FeatureSet.latestLanguageVersion();
    var version = Version(3, 11, 2);
    var entries = [MapEntry('a', 1), MapEntry('ø', -1)];
    signature
      ..addFeatureSet(features)
      ..addLanguageVersion(version)
      ..addList([1, -1, 3], signature.addInt)
      ..addList<int>([], signature.addInt)
      ..addStringList(['', 'abc', 'ø'])
      ..addMapEntryList(entries, (key, value) {
        signature.addString(key);
        signature.addInt(value);
      });
    encoding
      ..addFeatureSet(features)
      ..addLanguageVersion(version)
      ..addList([1, -1, 3], encoding.addInt)
      ..addList<int>([], encoding.addInt)
      ..addStringList(['', 'abc', 'ø'])
      ..addMapEntryList(entries, (key, value) {
        encoding.addString(key);
        encoding.addInt(value);
      });
    var words = Uint32List.fromList([0, 1, 0xffffffff, 0x12345678]);
    signature.addUint32List(words);
    encoding.addUint32List(words);
    // Match the existing API's whole-backing-buffer behavior for word views.
    var view = Uint32List.sublistView(words, 1, 3);
    signature.addUint32List(view);
    encoding.addUint32List(view);
    checkSignature(signature, encoding);
  }

  void test_addPrimitives() {
    var signature = Blake3ApiSignature();
    var encoding = ApiSignature.unversioned();
    for (var value in [true, false, true]) {
      signature.addBool(value);
      encoding.addBool(value);
    }
    for (var value in [0, 1, -1, 0x80000000, 0xffffffff, 0x100000001]) {
      signature.addInt(value);
      encoding.addInt(value);
    }
    for (var value in [0.0, -0.0, 1 / 3, -1.0, double.infinity]) {
      signature.addDouble(value);
      encoding.addDouble(value);
    }
    checkSignature(signature, encoding);
  }

  void test_addPrimitives_bufferBoundaries() {
    for (var prefix = 4088; prefix <= 4096; prefix++) {
      for (var value in [-1, 0x100000001]) {
        var signature = Blake3ApiSignature();
        var encoding = ApiSignature.unversioned();
        for (var i = 0; i < 3; i++) {
          signature
            ..addBytes(_bytes(prefix))
            ..addInt(value)
            ..addDouble(-0.0)
            ..addBool(true);
          encoding
            ..addBytes(_bytes(prefix))
            ..addInt(value)
            ..addDouble(-0.0)
            ..addBool(true);
        }
        checkSignature(signature, encoding);
      }
      checkSignature(
        Blake3ApiSignature()
          ..addBytes(_bytes(prefix))
          ..addDouble(1 / 3),
        ApiSignature.unversioned()
          ..addBytes(_bytes(prefix))
          ..addDouble(1 / 3),
      );
    }
  }

  void test_addString_bufferBoundaries() {
    for (var prefix in [0, 1, 55, 56, 57, 60, 61, 63, 64, 4093]) {
      var signature = Blake3ApiSignature()..addBytes(_bytes(prefix));
      var encoding = ApiSignature.unversioned()..addBytes(_bytes(prefix));
      for (var value in [
        '',
        'abc',
        '\u0000\u007f',
        'øЖЯ😀',
        '\ud800',
        'a' * 63,
        'b' * 64,
        'c' * 65,
        'a' * 4096,
        'ø' * 2048,
      ]) {
        signature.addString(value);
        encoding.addString(value);
      }
      checkSignature(signature, encoding);
    }
  }

  void test_addString_utf8_bufferBoundaries() {
    var strings = [
      for (var length in [1022, 1023, 1024, 4091, 4092, 4093])
        for (var suffix in [
          '\u007f\u0080\u07ff\u0800\uffff',
          '\ud800',
          '\udc00',
          '\ud800\ud800\udc00\udc00',
          '😀Жø',
        ])
          '${'a' * length}$suffix',
      'øЖ😀\ud800a\udc00' * 4096,
    ];
    var random = Random(42);
    strings.add(
      String.fromCharCodes(
        List.generate(16384, (_) => random.nextInt(0x10000)),
      ),
    );
    for (var prefix in [0, 1, 4091, 4092, 4093]) {
      var signature = Blake3ApiSignature()..addBytes(_bytes(prefix));
      var encoding = ApiSignature.unversioned()..addBytes(_bytes(prefix));
      for (var value in strings) {
        signature.addString(value);
        encoding.addString(value);
      }
      checkSignature(signature, encoding);
    }
  }

  void test_digest_finalizesInput() {
    var finishers = <void Function(Blake3ApiSignature)>[
      (signature) {
        signature.toByteList();
      },
      (signature) {
        signature.toHash();
      },
      (signature) {
        signature.toHex();
      },
      (signature) {
        signature.toUint32List();
      },
    ];
    for (var finish in finishers) {
      var signature = Blake3ApiSignature()..addString('done');
      finish(signature);
      expect(() => signature.addBool(false), throwsStateError);
      expect(() => signature.addBytes(Uint8List(0)), throwsStateError);
      expect(() => signature.addBytes(_bytes(4096)), throwsStateError);
      expect(() => signature.addDouble(0), throwsStateError);
      expect(() => signature.addInt(0), throwsStateError);
      expect(() => signature.addString(''), throwsStateError);
      expect(
        () => signature.addList<int>([], signature.addInt),
        throwsStateError,
      );
      expect(() => signature.addStringList([]), throwsStateError);
      expect(() => signature.addUint32List(Uint32List(0)), throwsStateError);
      checkSignature(signature, ApiSignature.unversioned()..addString('done'));
    }
  }

  void test_digest_interleavedSignatures() {
    var first = Blake3ApiSignature()..addBytes(_bytes(1025));
    var second = Blake3ApiSignature()..addString('second');
    first.addString('first');
    second.addBytes(_bytes(65));
    var encoding = ApiSignature.unversioned()
      ..addBytes(_bytes(1025))
      ..addString('first');
    var saved = first.toHash();
    var expected = first.toByteList();
    first.toByteList().fillRange(0, 32, 0);
    first.toUint32List().fillRange(0, 8, 0);
    checkSignature(
      second,
      ApiSignature.unversioned()
        ..addString('second')
        ..addBytes(_bytes(65)),
    );
    checkSignature(first, encoding);
    expect(saved.toString(), hex.encode(expected));
    expect(first.toHash(), saved);
  }

  void test_empty() {
    checkSignature(Blake3ApiSignature(), ApiSignature.unversioned());
  }

  Uint8List _bytes(int length) =>
      Uint8List.fromList(List.generate(length, (i) => (i * 31 + 17) & 255));
}
