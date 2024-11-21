// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'private.dart';

export 'private.dart' show Exported;

class Triple {
  final Exported e;
  final Interface i1;
  final Interface i2;
  Triple(this.e, this.i1, this.i2);
}

abstract class Interface {
  factory Interface.v1() => _Implemenetation();
  factory Interface.v2() => Implementation2();

  int method1();
}

class _Implemenetation implements Interface {
  @override
  int method1() => 2;
}
