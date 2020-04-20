// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  bool nullBool = null;
  Expect.throwsAssertionError(() => <int>[if (nullBool) 1]);
  Expect.throwsAssertionError(() => <int, int>{if (nullBool) 1: 1});
  Expect.throwsAssertionError(() => <int>{if (nullBool) 1});
}
