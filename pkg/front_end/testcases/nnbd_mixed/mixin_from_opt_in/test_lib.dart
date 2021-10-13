// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'opt_out_lib.dart';

test() {
  SubClass sub = new SubClass();
  int i = sub.classMethod(null);
  int j = sub.mixinMethod(null);
  sub.classField2 = sub.classField1;
  sub.mixinField2 = sub.mixinField1;
}
