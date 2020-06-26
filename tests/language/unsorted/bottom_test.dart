// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

Never never() => throw "!";

void main() {
  final f1 = () => throw never();
  final f2 = () => never();
  Expect.equals(f1.runtimeType, f2.runtimeType);

  final Bottom = (<F>(F Function() f) => F)(() => throw never());
  Expect.equals(Never, Bottom);
}
