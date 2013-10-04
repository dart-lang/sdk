// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.constructor_kinds_test;

import 'dart:mirrors';
import 'package:expect/expect.dart';

class ClassWithDefaultConstructor {}

class Class {
  Class.generative();
  Class.redirectingGenerative() : this.generative();
  factory Class.faktory () => new Class.generative();
  factory Class.redirectingFactory() = Class.faktory;

  const Class.constGenerative();
  const Class.constRedirectingGenerative() : this.constGenerative();
  // Not legal.
  // const factory Class.constFaktory () => const Class.constGenerative();
  const factory Class.constRedirectingFactory() = Class.constGenerative;
}

main() {
  ClassMirror cm;
  MethodMirror mm;

  new Class.generative();  
  new Class.redirectingGenerative();
  new Class.faktory();
  new Class.redirectingFactory();
  const Class.constGenerative();
  const Class.constRedirectingGenerative();
  const Class.constRedirectingFactory();

  cm = reflectClass(ClassWithDefaultConstructor);
  mm = cm.constructors.values.single;
  Expect.isTrue(mm.isConstructor);
  Expect.isTrue(mm.isGenerativeConstructor);
  Expect.isFalse(mm.isFactoryConstructor);
  Expect.isFalse(mm.isRedirectingConstructor);
  Expect.isFalse(mm.isConstConstructor);


  cm = reflectClass(Class);

  mm = cm.constructors[#generative];
  Expect.isTrue(mm.isConstructor);
  Expect.isTrue(mm.isGenerativeConstructor);
  Expect.isFalse(mm.isFactoryConstructor);
  Expect.isFalse(mm.isRedirectingConstructor);
  Expect.isFalse(mm.isConstConstructor);

  mm = cm.constructors[#redirectingGenerative];
  Expect.isTrue(mm.isConstructor);
  Expect.isTrue(mm.isGenerativeConstructor);
  Expect.isFalse(mm.isFactoryConstructor);
  Expect.isTrue(mm.isRedirectingConstructor);
  Expect.isFalse(mm.isConstConstructor);

  mm = cm.constructors[#faktory];
  Expect.isTrue(mm.isConstructor);
  Expect.isFalse(mm.isGenerativeConstructor);
  Expect.isTrue(mm.isFactoryConstructor);
  Expect.isFalse(mm.isRedirectingConstructor);
  Expect.isFalse(mm.isConstConstructor);

  mm = cm.constructors[#redirectingFactory];
  Expect.isTrue(mm.isConstructor);
  Expect.isFalse(mm.isGenerativeConstructor);
  Expect.isTrue(mm.isFactoryConstructor);
  Expect.isTrue(mm.isRedirectingConstructor);
  Expect.isFalse(mm.isConstConstructor);

  mm = cm.constructors[#constGenerative];
  Expect.isTrue(mm.isConstructor);
  Expect.isTrue(mm.isGenerativeConstructor);
  Expect.isFalse(mm.isFactoryConstructor);
  Expect.isFalse(mm.isRedirectingConstructor);
  Expect.isTrue(mm.isConstConstructor);

  mm = cm.constructors[#constRedirectingGenerative];
  Expect.isTrue(mm.isConstructor);
  Expect.isTrue(mm.isGenerativeConstructor);
  Expect.isFalse(mm.isFactoryConstructor);
  Expect.isTrue(mm.isRedirectingConstructor);
  Expect.isTrue(mm.isConstConstructor);

  // Not legal.
  // mm = cm.constructors[#constFaktory];
  // Expect.isTrue(mm.isConstructor);
  // Expect.isFalse(mm.isGenerativeConstructor);
  // Expect.isTrue(mm.isFactoryConstructor);
  // Expect.isFalse(mm.isRedirectingConstructor);
  // Expect.isTrue(mm.isConstConstructor);

  mm = cm.constructors[#constRedirectingFactory];
  Expect.isTrue(mm.isConstructor);
  Expect.isFalse(mm.isGenerativeConstructor);
  Expect.isTrue(mm.isFactoryConstructor);
  Expect.isTrue(mm.isRedirectingConstructor);
  Expect.isTrue(mm.isConstConstructor);
}
