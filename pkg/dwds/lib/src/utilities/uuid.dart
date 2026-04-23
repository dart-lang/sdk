// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';
import 'dart:typed_data';

/// A UUID generator.
///
/// This is a lightweight replacement for package:uuid, specifically for
/// generating version 4 (random) UUIDs using a cryptographically secure random
/// number generator.
///
/// See https://datatracker.ietf.org/doc/html/rfc4122#section-4.4
/// See also https://github.com/daegalus/dart-uuid/blob/main/lib/v4.dart
class Uuid {
  static final Random _random = Random.secure();

  const Uuid();

  /// Generates a Version 4 (random) UUID.
  ///
  /// The UUID is formatted as a string:
  /// xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
  /// where x is a random hex digit and y is a random hex digit from 8, 9, a,
  /// or b.
  String v4() {
    final bytes = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      bytes[i] = _random.nextInt(256);
    }

    // Set the version number (4) to 0100
    bytes[6] = (bytes[6] & 0x0f) | 0x40;

    // Set the variant (10xx) to 1000
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final buf = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buf.write('-');
      }
      buf.write(_hex[bytes[i]]);
    }
    return buf.toString();
  }

  /// A pre-computed list of hex strings for all possible byte values (0-255).
  ///
  /// For example, `_hex[255]` is 'ff'.
  static final _hex = List.generate(
    256,
    (i) => i.toRadixString(16).padLeft(2, '0'),
  );
}
