// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:expect/expect.dart';

class ClassWithDefaultConstructor {}

mixin Mixin {}

class ClassWithConstDefaultConstructor = Object with Mixin;

class Class {
  Class.generativeConstructor();
  Class.redirectingGenerativeConstructor() : this.constGenerativeConstructor();
  factory Class.factoryConstructor() => Class.generativeConstructor();
  factory Class.redirectingFactoryConstructor() =
      Class.constGenerativeConstructor;

  // There is no constant non-redirecting factory constructor,
  // (dartbug.com/language/3356).

  const Class.constGenerativeConstructor();
  const Class.constRedirectingGenerativeConstructor()
    : this.constGenerativeConstructor();
  const factory Class.constRedirectingFactoryConstructor() =
      Class.constGenerativeConstructor;
}

void main() {
  ClassMirror cm;
  MethodMirror mm;

  cm = reflectClass(ClassWithDefaultConstructor);
  mm =
      cm.declarations.values.singleWhere(
            (d) => d is MethodMirror && d.isConstructor,
          )
          as MethodMirror;
  Expect.isTrue(mm.isConstructor);
  Expect.isTrue(mm.isGenerativeConstructor);
  Expect.isFalse(mm.isFactoryConstructor);
  Expect.isFalse(mm.isRedirectingConstructor);
  Expect.isFalse(mm.isConstConstructor);

  cm = reflectClass(ClassWithConstDefaultConstructor);
  mm =
      cm.declarations.values.singleWhere(
            (d) => d is MethodMirror && d.isConstructor,
          )
          as MethodMirror;
  Expect.isTrue(mm.isConstructor);
  Expect.isTrue(mm.isGenerativeConstructor);
  Expect.isFalse(mm.isFactoryConstructor);
  Expect.isFalse(mm.isRedirectingConstructor);
  Expect.isTrue(mm.isConstConstructor);

  cm = reflectClass(Class);

  mm = cm.declarations[#Class.generativeConstructor] as MethodMirror;
  Expect.isTrue(mm.isConstructor);
  Expect.isTrue(mm.isGenerativeConstructor);
  Expect.isFalse(mm.isFactoryConstructor);
  Expect.isFalse(mm.isRedirectingConstructor);
  Expect.isFalse(mm.isConstConstructor);

  mm = cm.declarations[#Class.redirectingGenerativeConstructor] as MethodMirror;
  Expect.isTrue(mm.isConstructor);
  Expect.isTrue(mm.isGenerativeConstructor);
  Expect.isFalse(mm.isFactoryConstructor);
  Expect.isFalse(mm.isRedirectingConstructor); // NOTICE: Wrong value.
  Expect.isFalse(mm.isConstConstructor);

  mm = cm.declarations[#Class.factoryConstructor] as MethodMirror;
  Expect.isTrue(mm.isConstructor);
  Expect.isFalse(mm.isGenerativeConstructor);
  Expect.isTrue(mm.isFactoryConstructor);
  Expect.isFalse(mm.isRedirectingConstructor);
  Expect.isFalse(mm.isConstConstructor);

  mm = cm.declarations[#Class.redirectingFactoryConstructor] as MethodMirror;
  Expect.isTrue(mm.isConstructor);
  Expect.isFalse(mm.isGenerativeConstructor);
  Expect.isTrue(mm.isFactoryConstructor);
  Expect.isFalse(mm.isRedirectingConstructor); // NOTICE: Wrong value.
  Expect.isFalse(mm.isConstConstructor);

  mm = cm.declarations[#Class.constGenerativeConstructor] as MethodMirror;
  Expect.isTrue(mm.isConstructor);
  Expect.isTrue(mm.isGenerativeConstructor);
  Expect.isFalse(mm.isFactoryConstructor);
  Expect.isFalse(mm.isRedirectingConstructor);
  Expect.isTrue(mm.isConstConstructor);

  mm =
      cm.declarations[#Class.constRedirectingGenerativeConstructor]
          as MethodMirror;
  Expect.isTrue(mm.isConstructor);
  Expect.isTrue(mm.isGenerativeConstructor);
  Expect.isFalse(mm.isFactoryConstructor);
  Expect.isFalse(mm.isRedirectingConstructor); // NOTICE: Wrong value.
  Expect.isTrue(mm.isConstConstructor);

  mm =
      cm.declarations[#Class.constRedirectingFactoryConstructor]
          as MethodMirror;
  Expect.isTrue(mm.isConstructor);
  Expect.isFalse(mm.isGenerativeConstructor);
  Expect.isTrue(mm.isFactoryConstructor);
  Expect.isFalse(mm.isRedirectingConstructor); // NOTICE: Wrong value.
  Expect.isFalse(mm.isConstConstructor); // NOTICE: Wrong value.

  // Constructors work.
  ClassWithDefaultConstructor();
  Class.generativeConstructor();
  Class.redirectingGenerativeConstructor();
  Class.factoryConstructor();
  Class.redirectingFactoryConstructor();
  const Class.constGenerativeConstructor();
  const Class.constRedirectingGenerativeConstructor();
  const Class.constRedirectingFactoryConstructor();
}
