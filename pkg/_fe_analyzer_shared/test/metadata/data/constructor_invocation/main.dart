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
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedIdentifier(Class)
    ())))))
resolved=ConstructorInvocation(
  Class.new())*/
void constructorInvocations1() {}

@Helper(Class.new())
/*member: constructorInvocations2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedIdentifier(Class).new)
    ())))))
resolved=ConstructorInvocation(
  Class.new())*/
void constructorInvocations2() {}

@Helper(Class.named())
/*member: constructorInvocations3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedIdentifier(Class).named)
    ())))))
resolved=ConstructorInvocation(
  Class.named())*/
void constructorInvocations3() {}

@Helper(self.Class())
/*member: constructorInvocations4:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedIdentifier(self).Class)
    ())))))
resolved=ConstructorInvocation(
  Class.new())*/
void constructorInvocations4() {}

@Helper(self.Class.new())
/*member: constructorInvocations5:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedAccess(
        UnresolvedIdentifier(self).Class).new)
    ())))))
resolved=ConstructorInvocation(
  Class.new())*/
void constructorInvocations5() {}

@Helper(self.Class.named())
/*member: constructorInvocations6:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedAccess(
        UnresolvedIdentifier(self).Class).named)
    ())))))
resolved=ConstructorInvocation(
  Class.named())*/
void constructorInvocations6() {}

@Helper(GenericClass())
/*member: constructorInvocations7:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedIdentifier(GenericClass)
    ())))))
resolved=ConstructorInvocation(
  GenericClass.new())*/
void constructorInvocations7() {}

@Helper(GenericClass<Class, Class>())
/*member: constructorInvocations8:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedInstantiate(
      UnresolvedIdentifier(GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedIdentifier(Class)}>)
    ())))))
resolved=ConstructorInvocation(
  GenericClass<Class,Class>.new())*/
void constructorInvocations8() {}

@Helper(GenericClass.named())
/*member: constructorInvocations10:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedIdentifier(GenericClass).named)
    ())))))
resolved=ConstructorInvocation(
  GenericClass.named())*/
void constructorInvocations10() {}

@Helper(GenericClass<Class, self.Class>.named())
/*member: constructorInvocations11:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedInstantiate(
        UnresolvedIdentifier(GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedAccess(
          UnresolvedIdentifier(self).Class)}>).named)
    ())))))
resolved=ConstructorInvocation(
  GenericClass<Class,Class>.named())*/
void constructorInvocations11() {}

@Helper(self.GenericClass.named())
/*member: constructorInvocations12:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedAccess(
        UnresolvedIdentifier(self).GenericClass).named)
    ())))))
resolved=ConstructorInvocation(
  GenericClass.named())*/
void constructorInvocations12() {}

@Helper(
  self.GenericClass<
    GenericClass?,
    self.GenericClass<Class, self.Class?>
  >.named(),
)
/*member: constructorInvocations13:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedInstantiate(
        UnresolvedAccess(
          UnresolvedIdentifier(self).GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(GenericClass)}?,{unresolved-type-annotation:UnresolvedInstantiate(
          UnresolvedAccess(
            UnresolvedIdentifier(self).GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedAccess(
            UnresolvedIdentifier(self).Class)}?>)}>).named)
    ())))))
resolved=ConstructorInvocation(
  GenericClass<GenericClass?,GenericClass<Class,Class?>>.named())*/
void constructorInvocations13() {}

@Helper(const Class())
/*member: constructorInvocations14:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedIdentifier(Class)
    ())))))
resolved=ConstructorInvocation(
  Class.new())*/
void constructorInvocations14() {}

@Helper(const Class.new())
/*member: constructorInvocations15:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedIdentifier(Class).new)
    ())))))
resolved=ConstructorInvocation(
  Class.new())*/
void constructorInvocations15() {}

@Helper(const Class.named())
/*member: constructorInvocations16:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedIdentifier(Class).named)
    ())))))
resolved=ConstructorInvocation(
  Class.named())*/
void constructorInvocations16() {}

@Helper(const self.Class())
/*member: constructorInvocations17:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedIdentifier(self).Class)
    ())))))
resolved=ConstructorInvocation(
  Class.new())*/
void constructorInvocations17() {}

@Helper(const self.Class.new())
/*member: constructorInvocations18:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedAccess(
        UnresolvedIdentifier(self).Class).new)
    ())))))
resolved=ConstructorInvocation(
  Class.new())*/
void constructorInvocations18() {}

@Helper(const self.Class.named())
/*member: constructorInvocations19:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedAccess(
        UnresolvedIdentifier(self).Class).named)
    ())))))
resolved=ConstructorInvocation(
  Class.named())*/
void constructorInvocations19() {}

@Helper(const GenericClass())
/*member: constructorInvocations20:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedIdentifier(GenericClass)
    ())))))
resolved=ConstructorInvocation(
  GenericClass.new())*/
void constructorInvocations20() {}

@Helper(const GenericClass.new())
/*member: constructorInvocations21:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedIdentifier(GenericClass).new)
    ())))))
resolved=ConstructorInvocation(
  GenericClass.new())*/
void constructorInvocations21() {}

@Helper(const GenericClass<Class, Class>())
/*member: constructorInvocations22:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedInstantiate(
      UnresolvedIdentifier(GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedIdentifier(Class)}>)
    ())))))
resolved=ConstructorInvocation(
  GenericClass<Class,Class>.new())*/
void constructorInvocations22() {}

@Helper(const GenericClass<Class, Class>.new())
/*member: constructorInvocations23:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedInstantiate(
        UnresolvedIdentifier(GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedIdentifier(Class)}>).new)
    ())))))
resolved=ConstructorInvocation(
  GenericClass<Class,Class>.new())*/
void constructorInvocations23() {}

@Helper(const GenericClass.named())
/*member: constructorInvocations24:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedIdentifier(GenericClass).named)
    ())))))
resolved=ConstructorInvocation(
  GenericClass.named())*/
void constructorInvocations24() {}

@Helper(const GenericClass<Class, self.Class>.named())
/*member: constructorInvocations25:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedInstantiate(
        UnresolvedIdentifier(GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedAccess(
          UnresolvedIdentifier(self).Class)}>).named)
    ())))))
resolved=ConstructorInvocation(
  GenericClass<Class,Class>.named())*/
void constructorInvocations25() {}

@Helper(const self.GenericClass.named())
/*member: constructorInvocations26:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedAccess(
        UnresolvedIdentifier(self).GenericClass).named)
    ())))))
resolved=ConstructorInvocation(
  GenericClass.named())*/
void constructorInvocations26() {}

@Helper(
  const self.GenericClass<
    GenericClass?,
    self.GenericClass<Class, self.Class?>
  >.named(),
)
/*member: constructorInvocations27:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedInstantiate(
        UnresolvedAccess(
          UnresolvedIdentifier(self).GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(GenericClass)}?,{unresolved-type-annotation:UnresolvedInstantiate(
          UnresolvedAccess(
            UnresolvedIdentifier(self).GenericClass)<{unresolved-type-annotation:UnresolvedIdentifier(Class)},{unresolved-type-annotation:UnresolvedAccess(
            UnresolvedIdentifier(self).Class)}?>)}>).named)
    ())))))
resolved=ConstructorInvocation(
  GenericClass<GenericClass?,GenericClass<Class,Class?>>.named())*/
void constructorInvocations27() {}
