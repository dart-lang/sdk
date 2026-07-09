// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'shared.dart';

class Exported {
  int method3() => 3;
}

class Implementation2 implements Interface {
  @override
  int method1() => 4;
}
