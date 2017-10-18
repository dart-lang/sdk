// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:typed_data';

import 'package:expect/minitest.dart';

main() {
  group('supported', () {
    test('supported', () {
      expect(Crypto.supported, true);
    });
  });

  group('functional', () {
    if (Crypto.supported) {
      // This will actually pass on FF since it has a Crypto API, but it is
      // incompatible.
      test('exists', () {
        var crypto = window.crypto;
        expect(crypto is Crypto, isTrue);
      });

      test('successful call', () {
        var crypto = window.crypto;
        var data = new Uint8List(100);
        expect(data.every((e) => e == 0), isTrue);
        crypto.getRandomValues(data);
        // In theory this is flaky. However, in practice you will get 100 zeroes
        // in a row from a cryptographically secure random number generator so
        // rarely that we don't have to worry about it.
        expect(data.any((e) => e != 0), isTrue);
      });

      test('type mismatch', () {
        var crypto = window.crypto;
        var data = new Float32List(100);
        expect(() {
          crypto.getRandomValues(data);
        }, throws, reason: 'Only typed array views with integer types allowed');
      });
    }
  });
}
