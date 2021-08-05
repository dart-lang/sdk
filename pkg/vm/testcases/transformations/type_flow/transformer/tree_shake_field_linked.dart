// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'tree_shake_field.lib.dart';

class Class implements Interface {
  int? field1;
  int? field2;
  int? field3;
}

void method(Interface i) {
  i.field2 = i.field1;
  i.field3 = i.field3;
}

main() {
  method(new Class());
}
