// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Copying from typed data into an unmodifiable view must throw, not write
// through to the backing store.

import 'dart:typed_data';

import 'package:expect/expect.dart';

void main() {
  final ints = Int32List(4);
  Expect.throwsUnsupportedError(
    () => ints.asUnmodifiableView().setRange(0, 2, Int32List.fromList([7, 8])),
  );
  Expect.throwsUnsupportedError(
    () => ints.asUnmodifiableView().setAll(0, Int32List.fromList([7, 8])),
  );
  Expect.listEquals([0, 0, 0, 0], ints);

  final bytes = Uint8List(4);
  Expect.throwsUnsupportedError(
    () => bytes.asUnmodifiableView().setRange(0, 2, Uint8List.fromList([7, 8])),
  );
  Expect.listEquals([0, 0, 0, 0], bytes);

  final doubles = Float64List(2);
  Expect.throwsUnsupportedError(
    () =>
        doubles.asUnmodifiableView().setRange(0, 1, Float64List.fromList([7])),
  );
  Expect.listEquals([0.0, 0.0], doubles);

  final units = Uint16List(2);
  Expect.throwsUnsupportedError(
    () => units.asUnmodifiableView().setRange(0, 2, 'ab'.codeUnits),
  );
  Expect.listEquals([0, 0], units);
}
