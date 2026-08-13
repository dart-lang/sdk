// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=anonymous-methods

import 'package:expect/expect.dart';

void main() {
  final int? x = 2;
  (x != null).{
    Expect.isTrue(this ? x.isEven : false);
  };
  (x != null).(b) {
    Expect.isTrue(b ? x.isEven : false);
  };
}
