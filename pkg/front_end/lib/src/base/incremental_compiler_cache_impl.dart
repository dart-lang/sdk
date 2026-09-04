// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:kernel/ast.dart';

import 'incremental_compiler.dart' show IncrementalCompilerCache;
import 'incremental_serializer.dart';

// Coverage-ignore(suite): Not run.
class IncrementalCompilerCacheImpl implements IncrementalCompilerCache {
  final Directory directory;
  new(String directoryPath) : directory = new Directory(directoryPath);

  @override
  bool get mainDirectoryExists => directory.existsSync();

  @override
  Uint8List? getCachedDillBytes(
    Uri libraryFileUri,
    List<String> usedPackagesPaths,
  ) {
    File file = _getFile(libraryFileUri, usedPackagesPaths);
    if (!file.existsSync()) return null;
    return file.readAsBytesSync();
  }

  @override
  void cacheLibrary(
    Library library,
    List<String> usedPackagesPaths,
    Component fromComponent,
  ) {
    // TODO(jensj): Possibly save under a different name and move the file once
    // finished writing like done in the analyzer.
    File file = _getFile(library.fileUri, usedPackagesPaths);
    file.createSync(recursive: true);
    file.writeAsBytesSync(
      IncrementalSerializer.serialize(fromComponent, [library]),
    );
  }

  File _getFile(Uri libraryFileUri, List<String> usedPackagesPaths) {
    usedPackagesPaths.sort();
    String indexOn = _MD5Ish.hash(
      "$libraryFileUri\n${usedPackagesPaths.join("\n")}",
    );
    return new File.fromUri(directory.uri.resolve(indexOn));
  }
}

// Coverage-ignore(suite): Not run.
/// Copied from package crypto to avoid the dependency.
/// It doesn't actually do a MD5 though (e.g. it takes the string as a list of
/// uint16, ignores endian and doesn't properly pad).
class _MD5Ish {
  static String hash(String s) {
    Uint32List digest = new Uint32List(4);
    digest[0] = 0x67452301;
    digest[1] = 0xefcdab89;
    digest[2] = 0x98badcfe;
    digest[3] = 0x10325476;

    Uint32List chunk32 = new Uint32List(16);
    Uint16List chunk16 = chunk32.buffer.asUint16List();
    int index = 0;
    for (int i = 0; i < s.length; i++) {
      chunk16[index] = s.codeUnitAt(i);
      index++;
      if (index == chunk16.length) {
        _processChunk(chunk32, digest);
        index = 0;
      }
    }
    while (index != 0) {
      chunk16[index++] = 0;
      if (index == chunk16.length) {
        _processChunk(chunk32, digest);
        index = 0;
      }
    }

    return _hexEncode(digest.buffer.asUint8List());
  }

  static String _hexEncode(Uint8List bytes) {
    const String hexDigits = '0123456789abcdef';
    Uint8List charCodes = new Uint8List(bytes.length * 2);
    for (int i = 0, j = 0; i < bytes.length; i++) {
      int byte = bytes[i];
      charCodes[j++] = hexDigits.codeUnitAt((byte >> 4) & 0xF);
      charCodes[j++] = hexDigits.codeUnitAt(byte & 0xF);
    }
    return new String.fromCharCodes(charCodes);
  }

  static void _processChunk(Uint32List chunk, Uint32List digest) {
    // This makes the VM get rid of some "GenericCheckBound" calls.
    // See also https://github.com/dart-lang/sdk/issues/60753.
    // ignore: unnecessary_statements
    chunk[15];

    // Access [3] first to get rid of some "GenericCheckBound" calls.
    int d = digest[3];
    int c = digest[2];
    int b = digest[1];
    int a = digest[0];

    int e = 0;
    int f = 0;

    @pragma('vm:prefer-inline')
    void round(int i) {
      int temp = d;
      d = c;
      c = b;

      b = add32(
        b,
        rotl32(
          add32(add32(a, e), add32(_noise[i], chunk[f])),
          _shiftAmounts[i],
        ),
      );

      a = temp;
    }

    for (int i = 0; i < 16; i++) {
      e = (b & c) | ((~b & mask32) & d);
      // Doing `i % 16` would get rid of a "GenericCheckBound" call in the VM,
      // but is slightly slower anyway.
      // See also https://github.com/dart-lang/sdk/issues/60753.
      f = i;
      round(i);
    }

    for (int i = 16; i < 32; i++) {
      e = (d & b) | ((~d & mask32) & c);
      f = ((5 * i) + 1) % 16;
      round(i);
    }

    for (int i = 32; i < 48; i++) {
      e = b ^ c ^ d;
      f = ((3 * i) + 5) % 16;
      round(i);
    }

    for (int i = 48; i < 64; i++) {
      e = c ^ (b | (~d & mask32));
      f = (7 * i) % 16;
      round(i);
    }

    digest[0] = add32(a, digest[0]);
    digest[1] = add32(b, digest[1]);
    digest[2] = add32(c, digest[2]);
    digest[3] = add32(d, digest[3]);
  }

  static const int mask32 = 0xFFFFFFFF;
  static int add32(int x, int y) => (x + y) & mask32;
  static int rotl32(int val, int shift) {
    int modShift = shift & 31;
    return ((val << modShift) & mask32) | ((val & mask32) >> (32 - modShift));
  }

  /// Data from a non-linear mathematical function that functions as
  /// reproducible noise.
  static const List<int> _noise = [
    // Format hack.
    0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, 0xf57c0faf, 0x4787c62a,
    0xa8304613, 0xfd469501, 0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
    0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821, 0xf61e2562, 0xc040b340,
    0x265e5a51, 0xe9b6c7aa, 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
    0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed, 0xa9e3e905, 0xfcefa3f8,
    0x676f02d9, 0x8d2a4c8a, 0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
    0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70, 0x289b7ec6, 0xeaa127fa,
    0xd4ef3085, 0x04881d05, 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
    0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039, 0x655b59c3, 0x8f0ccc92,
    0xffeff47d, 0x85845dd1, 0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
    0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
  ];

  /// Per-round shift amounts.
  static const List<int> _shiftAmounts = [
    // Format hack.
    07, 12, 17, 22, 07, 12, 17, 22, 07, 12, 17, 22, 07, 12, 17, 22, 05, 09, 14,
    20, 05, 09, 14, 20, 05, 09, 14, 20, 05, 09, 14, 20, 04, 11, 16, 23, 04, 11,
    16, 23, 04, 11, 16, 23, 04, 11, 16, 23, 06, 10, 15, 21, 06, 10, 15, 21, 06,
    10, 15, 21, 06, 10, 15, 21,
  ];
}
