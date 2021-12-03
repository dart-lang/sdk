// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'tree_shake_enum_from_lib.lib.dart';

enum UnusedEnum { a, b }
enum UsedEnum {
  unusedValue,
  usedValue,
}

usedMethod(UnusedInterface c) {
  c.usedInterfaceField = c.usedInterfaceField;
}

unusedMethod() {}

class UnusedInterface {
  int? usedInterfaceField;

  UnusedInterface(this.usedInterfaceField);
}

class UsedClass implements UnusedInterface {
  int? unusedField;
  int? usedField;
  int? usedInterfaceField;
}

class UnusedClass {}

main() {
  usedMethod(new UsedClass()..usedField);
  UsedEnum.usedValue;
  List<UnusedEnum> list = [];
  if (list.isNotEmpty) {
    new ConstClass().method(null as dynamic);
  }
}
