// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'required_parameter_mixed_from_opt_out_lib.dart';

class Super {
  void method({required covariant int named}) {}
}

class Class extends Super with Mixin {}

class SubClass extends Class {
  void method({required covariant int named}) {}
}

main() {}
