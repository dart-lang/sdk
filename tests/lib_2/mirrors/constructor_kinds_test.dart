// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.constructor_kinds_test;

import 'dart:mirrors';
import 'package:expect/expect.dart';

class ClassWithDefaultConstructor {}

class Class {
  Class.generativeConstructor();
  Class.redirectingGenerativeConstructor() : this.generativeConstructor();
  factory Class.factoryConstructor() => new Class.generativeConstructor();
  factory Class.redirectingFactoryConstructor() = Class.factoryConstructor;

  const Class.constGenerativeConstructor();
  const Class.constRedirectingGenerativeConstructor()
      : this.constGenerativeConstructor();
  // Not legal.
  // const factory Class.constFactoryConstructor() => ...
  const factory Class.constRedirectingFactoryConstructor() =
      Class.constGenerativeConstructor;
}

main() {
  ClassMirror cm;
  MethodMirror mm;

  // Multitest with and without constructor calls. On the VM, we want to check
  // that constructor properties are correctly set even if the constructor
  // hasn't been fully compiled. On dart2js, we want to check that constructors
  // are retain even if there are no base-level calls.
  new ClassWithDefaultConstructor(); // //# 01: ok
  new Class.generativeConstructor(); // //# 01: ok
  new Class.redirectingGenerativeConstructor(); // //# 01: ok
  new Class.factoryConstructor(); // //# 01: ok
  new Class.redirectingFactoryConstructor(); // //# 01: ok
  const Class.constGenerativeConstructor(); // //# 01: ok
  const Class.constRedirectingGenerativeConstructor(); // //# 01: ok
  const Class.constRedirectingFactoryConstructor(); // //# 01: ok

  cm = reflectClass(ClassWithDefaultConstructor);
  mm = cm.declarations.values
      .where((d) => d is MethodMirror && d.isConstructor)
      .single;
  Expect.isTrue(mm.isConstructor);
  Expect.isTrue(mm.isGenerativeConstructor);
  Expect.isFalse(mm.isFactoryConstructor);
  Expect.isFalse(mm.isRedirectingConstructor);
  Expect.isFalse(mm.isConstConstructor);

  cm = reflectClass(Class);

  mm = cm.declarations[#Class.generativeConstructor];
  Expect.isTrue(mm.isConstructor);
  Expect.isTrue(mm.isGenerativeConstructor);
  Expect.isFalse(mm.isFactoryConstructor);
  Expect.isFalse(mm.isRedirectingConstructor);
  Expect.isFalse(mm.isConstConstructor);

  mm = cm.declarations[#Class.redirectingGenerativeConstructor];
  Expect.isTrue(mm.isConstructor);
  Expect.isTrue(mm.isGenerativeConstructor);
  Expect.isFalse(mm.isFactoryConstructor);
  Expect.isTrue(mm.isRedirectingConstructor);
  Expect.isFalse(mm.isConstConstructor);

  mm = cm.declarations[#Class.factoryConstructor];
  Expect.isTrue(mm.isConstructor);
  Expect.isFalse(mm.isGenerativeConstructor);
  Expect.isTrue(mm.isFactoryConstructor);
  Expect.isFalse(mm.isRedirectingConstructor);
  Expect.isFalse(mm.isConstConstructor);

  mm = cm.declarations[#Class.redirectingFactoryConstructor];
  Expect.isTrue(mm.isConstructor);
  Expect.isFalse(mm.isGenerativeConstructor);
  Expect.isTrue(mm.isFactoryConstructor);
  Expect.isTrue(mm.isRedirectingConstructor);
  Expect.isFalse(mm.isConstConstructor);

  mm = cm.declarations[#Class.constGenerativeConstructor];
  Expect.isTrue(mm.isConstructor);
  Expect.isTrue(mm.isGenerativeConstructor);
  Expect.isFalse(mm.isFactoryConstructor);
  Expect.isFalse(mm.isRedirectingConstructor);
  Expect.isTrue(mm.isConstConstructor);

  mm = cm.declarations[#Class.constRedirectingGenerativeConstructor];
  Expect.isTrue(mm.isConstructor);
  Expect.isTrue(mm.isGenerativeConstructor);
  Expect.isFalse(mm.isFactoryConstructor);
  Expect.isTrue(mm.isRedirectingConstructor);
  Expect.isTrue(mm.isConstConstructor);

  // Not legal.
  // mm = cm.declarations[#Class.constFactoryConstructor];
  // Expect.isTrue(mm.isConstructor);
  // Expect.isFalse(mm.isGenerativeConstructor);
  // Expect.isTrue(mm.isFactoryConstructor);
  // Expect.isFalse(mm.isRedirectingConstructor);
  // Expect.isTrue(mm.isConstConstructor);

  mm = cm.declarations[#Class.constRedirectingFactoryConstructor];
  Expect.isTrue(mm.isConstructor);
  Expect.isFalse(mm.isGenerativeConstructor);
  Expect.isTrue(mm.isFactoryConstructor);
  Expect.isTrue(mm.isRedirectingConstructor);
  Expect.isTrue(mm.isConstConstructor);
}
