// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ensure list tracing recognizes List `first` and `last` setters as
// potentially modifying the type-value of the List.

import 'package:expect/expect.dart';

void main() {
  List<bool> a = [true, true];

  Expect.isTrue(a.first);
  Expect.isTrue(a.last);

  a.first = false;
  Expect.isFalse(a.first);
  Expect.isTrue(a.last);

  a.last = false;
  Expect.isFalse(a.first);
  Expect.isFalse(a.last);
}
