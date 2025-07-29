// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'unresolved_constructor.dart' as lib;
import 'unresolved_constructor_lib.dart' as lib;
import 'unresolved_constructor_lib.dart';

test() {
  Unresolved(); // Error
  new Unresolved(); // Error
  const Unresolved(); // Error

  Unresolved.named(); // Error
  new Unresolved.named(); // Error
  const Unresolved.named(); // Error

  lib.Unresolved(); // Error
  new lib.Unresolved(); // Error
  const lib.Unresolved(); // Error

  lib.Unresolved.named(); // Error
  new lib.Unresolved.named(); // Error
  const lib.Unresolved.named(); // Error

  Private._named(); // Error
  new Private._named(); // Error
  const Private._named(); // Error

  lib.Private._named(); // Error
  new lib.Private._named(); // Error
  const lib.Private._named(); // Error

}

class Super {
  Super.constructor();
  Super.constructor1() : this(); // Error
  Super.constructor2() : this.named(); // Error
}

class Class1 extends Super {
  Class1() : super(); // Error
  Class1.named() : super.named(); // Error
}

class Class2 extends Private {
  Class2.named() : super._named(); // Error
}

mixin Mixin {}

class Class3 extends Private with Mixin {
  Class3.named() : super._named(); // Error
}


