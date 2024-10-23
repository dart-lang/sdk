// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main.dart' as self;

class Helper {
  const Helper(a);
}

class Class {
  const Class([a]);
  const Class.named({a, b});
  const Class.mixed(a, b, {c, d});
}

class GenericClass<X, Y> {
  const GenericClass();
  const GenericClass.named({a, b});
}

@Helper(Class())
/*member: constructorInvocations1:
ConstructorInvocation(
  Class.new())*/
void constructorInvocations1() {}

@Helper(Class.new())
/*member: constructorInvocations2:
ConstructorInvocation(
  Class.new())*/
void constructorInvocations2() {}

@Helper(Class.named())
/*member: constructorInvocations3:
ConstructorInvocation(
  Class.named())*/
void constructorInvocations3() {}

@Helper(self.Class())
/*member: constructorInvocations4:
ConstructorInvocation(
  Class.new())*/
void constructorInvocations4() {}

@Helper(self.Class.new())
/*member: constructorInvocations5:
ConstructorInvocation(
  Class.new())*/
void constructorInvocations5() {}

@Helper(self.Class.named())
/*member: constructorInvocations6:
ConstructorInvocation(
  Class.named())*/
void constructorInvocations6() {}

@Helper(GenericClass())
/*member: constructorInvocations7:
ConstructorInvocation(
  GenericClass.new())*/
void constructorInvocations7() {}

@Helper(GenericClass<Class, Class>())
/*member: constructorInvocations8:
ConstructorInvocation(
  GenericClass<Class,Class>.new())*/
void constructorInvocations8() {}

@Helper(GenericClass.named())
/*member: constructorInvocations10:
ConstructorInvocation(
  GenericClass.named())*/
void constructorInvocations10() {}

@Helper(GenericClass<Class, self.Class>.named())
/*member: constructorInvocations11:
ConstructorInvocation(
  GenericClass<Class,Class>.named())*/
void constructorInvocations11() {}

@Helper(self.GenericClass.named())
/*member: constructorInvocations12:
ConstructorInvocation(
  GenericClass.named())*/
void constructorInvocations12() {}

@Helper(self
    .GenericClass<GenericClass?, self.GenericClass<Class, self.Class?>>.named())
/*member: constructorInvocations13:
ConstructorInvocation(
  GenericClass<GenericClass?,GenericClass<Class,Class?>>.named())*/
void constructorInvocations13() {}

@Helper(const Class())
/*member: constructorInvocations14:
ConstructorInvocation(
  Class.new())*/
void constructorInvocations14() {}

@Helper(const Class.new())
/*member: constructorInvocations15:
ConstructorInvocation(
  Class.new())*/
void constructorInvocations15() {}

@Helper(const Class.named())
/*member: constructorInvocations16:
ConstructorInvocation(
  Class.named())*/
void constructorInvocations16() {}

@Helper(const self.Class())
/*member: constructorInvocations17:
ConstructorInvocation(
  Class.new())*/
void constructorInvocations17() {}

@Helper(const self.Class.new())
/*member: constructorInvocations18:
ConstructorInvocation(
  Class.new())*/
void constructorInvocations18() {}

@Helper(const self.Class.named())
/*member: constructorInvocations19:
ConstructorInvocation(
  Class.named())*/
void constructorInvocations19() {}

@Helper(const GenericClass())
/*member: constructorInvocations20:
ConstructorInvocation(
  GenericClass.new())*/
void constructorInvocations20() {}

@Helper(const GenericClass.new())
/*member: constructorInvocations21:
ConstructorInvocation(
  GenericClass.new())*/
void constructorInvocations21() {}

@Helper(const GenericClass<Class, Class>())
/*member: constructorInvocations22:
ConstructorInvocation(
  GenericClass<Class,Class>.new())*/
void constructorInvocations22() {}

@Helper(const GenericClass<Class, Class>.new())
/*member: constructorInvocations23:
ConstructorInvocation(
  GenericClass<Class,Class>.new())*/
void constructorInvocations23() {}

@Helper(const GenericClass.named())
/*member: constructorInvocations24:
ConstructorInvocation(
  GenericClass.named())*/
void constructorInvocations24() {}

@Helper(const GenericClass<Class, self.Class>.named())
/*member: constructorInvocations25:
ConstructorInvocation(
  GenericClass<Class,Class>.named())*/
void constructorInvocations25() {}

@Helper(const self.GenericClass.named())
/*member: constructorInvocations26:
ConstructorInvocation(
  GenericClass.named())*/
void constructorInvocations26() {}

@Helper(const self
    .GenericClass<GenericClass?, self.GenericClass<Class, self.Class?>>.named())
/*member: constructorInvocations27:
ConstructorInvocation(
  GenericClass<GenericClass?,GenericClass<Class,Class?>>.named())*/
void constructorInvocations27() {}
