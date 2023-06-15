// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow interface classes to be implemented by multiple classes outside its
// library.

import 'package:expect/expect.dart';
import 'interface_class_implement_lib.dart';

abstract class AOutside implements InterfaceClass {}

class AOutsideImpl implements AOutside {
  int foo = 1;
}

class DoesNotPreventExtension extends AOutsideImpl {}

class BOutside implements InterfaceClass {
  int foo = 1;
}

enum EnumOutside implements ClassForEnum { x }

main() {
  Expect.equals(1, AOutsideImpl().foo);
  Expect.equals(1, DoesNotPreventExtension().foo);
  Expect.equals(1, BOutside().foo);
  Expect.equals(0, EnumOutside.x.index);
}
