// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'transitive_parameter_default_lib.dart';

main() {
  new C1();
  new C2();
  topLevelFunction1(null);
  topLevelFunction2(null);
}
