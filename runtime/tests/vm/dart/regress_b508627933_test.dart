// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that RawZLibFilter.process validates its arguments.

import 'dart:io';
import 'package:expect/expect.dart';

void main() {
  Expect.throwsRangeError(
    () => RawZLibFilter.deflateFilter().process([1, 2, 3], -1, 0),
  );
  Expect.throwsRangeError(
    () => RawZLibFilter.deflateFilter().process([1, 2, 3], -2, -1),
  );
  Expect.throwsRangeError(
    () => RawZLibFilter.deflateFilter().process([1, 2, 3], 0, -1),
  );
  Expect.throwsRangeError(
    () => RawZLibFilter.deflateFilter().process([1, 2, 3], 4, 2),
  );
  Expect.throwsRangeError(
    () => RawZLibFilter.deflateFilter().process([1, 2, 3], 2, 4),
  );
  Expect.throwsRangeError(
    () => RawZLibFilter.deflateFilter().process([1, 2, 3], 5, 6),
  );
}
