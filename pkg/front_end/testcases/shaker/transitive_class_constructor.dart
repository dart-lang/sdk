// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'transitive_class_constructor_lib.dart';

class C extends B {
  C();
  C.named() : super.publicConstructor(null);
}
