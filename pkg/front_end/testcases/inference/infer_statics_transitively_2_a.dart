// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'infer_statics_transitively.dart';
import 'infer_statics_transitively_b.dart';

final a1 = m2;

class A {
  static final a2 = b1;
}

main() {
  a1;
}
