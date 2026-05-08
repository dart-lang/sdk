// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

final a = A(bExt: .f(c: .f(0)));

class A {
  final BExt bExt;

  const A({required this.bExt});
}
