// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.8

import 'covariant_from_opt_in_lib.dart';

class SubClass extends Class with Mixin {
  void covariant(SubClass cls) {} // ok
  void invariant(SubClass cls) {} // error
  void contravariant(Object cls) {} // ok
}

main() {}
