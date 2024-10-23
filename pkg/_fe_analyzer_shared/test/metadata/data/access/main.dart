// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'main.dart' as self;

class Helper {
  const Helper(a);
}

const String variable = '';

void function() {}

class Class {
  const Class();
  const Class.named();

  static const String field = '';

  static void method() {}
}

class GenericClass<X, Y> {
  const GenericClass();
  const GenericClass.named();
}

typedef Alias = Class;
typedef ComplexAlias<X> = Class;
typedef GenericAlias<X, Y> = GenericClass<X, Y>;

@Helper(variable)
/*member: access1:
StaticGet(variable)*/
void access1() {}

@Helper(variable.length)
/*member: access2:
PropertyGet(StaticGet(variable).length)*/
void access2() {}

@Helper(function)
/*member: access3:
FunctionTearOff(function)*/
void access3() {}

@Helper(Class)
/*member: access4:
NullAwarePropertyGet(Class)*/
void access4() {}

@Helper(Class.new)
/*member: access5:
ConstructorTearOff(Class.new)*/
void access5() {}

@Helper(Class.named)
/*member: access6:
ConstructorTearOff(Class.named)*/
void access6() {}

@Helper(Class.field)
/*member: access7:
StaticGet(field)*/
void access7() {}

@Helper(Class.field.length)
/*member: access8:
PropertyGet(StaticGet(field).length)*/
void access8() {}

@Helper(Class.method)
/*member: access9:
FunctionTearOff(method)*/
void access9() {}

@Helper(self.variable)
/*member: access10:
StaticGet(variable)*/
void access10() {}

@Helper(self.variable.length)
/*member: access11:
PropertyGet(StaticGet(variable).length)*/
void access11() {}

@Helper(self.function)
/*member: access12:
FunctionTearOff(function)*/
void access12() {}

@Helper(self.Class)
/*member: access13:
NullAwarePropertyGet(Class)*/
void access13() {}

@Helper(self.Class.new)
/*member: access14:
ConstructorTearOff(Class.new)*/
void access14() {}

@Helper(self.Class.named)
/*member: access15:
ConstructorTearOff(Class.named)*/
void access15() {}

@Helper(self.Class.field)
/*member: access16:
StaticGet(field)*/
void access16() {}

@Helper(self.Class.field.length)
/*member: access17:
PropertyGet(StaticGet(field).length)*/
void access17() {}

@Helper(self.Class.method)
/*member: access18:
FunctionTearOff(method)*/
void access18() {}

@Helper(dynamic)
/*member: access19:
NullAwarePropertyGet(dynamic)*/
void access19() {}

@Helper(Alias.new)
/*member: access20:
ConstructorTearOff(Alias.new)*/
void access20() {}

@Helper(Alias.named)
/*member: access21:
ConstructorTearOff(Alias.named)*/
void access21() {}

@Helper(ComplexAlias.new)
/*member: access22:
ConstructorTearOff(ComplexAlias.new)*/
void access22() {}

@Helper(ComplexAlias.named)
/*member: access23:
ConstructorTearOff(ComplexAlias.named)*/
void access23() {}

@Helper(ComplexAlias<int>.new)
/*member: access24:
ConstructorTearOff(ComplexAlias<int>.new)*/
void access24() {}

@Helper(ComplexAlias<int>.named)
/*member: access25:
ConstructorTearOff(ComplexAlias<int>.named)*/
void access25() {}

@Helper(GenericAlias.new)
/*member: access26:
ConstructorTearOff(GenericAlias.new)*/
void access26() {}

@Helper(GenericAlias.named)
/*member: access27:
ConstructorTearOff(GenericAlias.named)*/
void access27() {}

@Helper(GenericAlias<int, String>.new)
/*member: access28:
ConstructorTearOff(GenericAlias<int,String>.new)*/
void access28() {}

@Helper(GenericAlias<int, String>.named)
/*member: access29:
ConstructorTearOff(GenericAlias<int,String>.named)*/
void access29() {}

@Helper(dynamic)
/*member: access30:
NullAwarePropertyGet(dynamic)*/
void access30() {}

@Helper(self.Alias.new)
/*member: access31:
ConstructorTearOff(Alias.new)*/
void access31() {}

@Helper(self.Alias.named)
/*member: access32:
ConstructorTearOff(Alias.named)*/
void access32() {}

@Helper(self.ComplexAlias.new)
/*member: access33:
ConstructorTearOff(ComplexAlias.new)*/
void access33() {}

@Helper(self.ComplexAlias.named)
/*member: access34:
ConstructorTearOff(ComplexAlias.named)*/
void access34() {}

@Helper(self.ComplexAlias<int>.new)
/*member: access35:
ConstructorTearOff(ComplexAlias<int>.new)*/
void access35() {}

@Helper(self.ComplexAlias<int>.named)
/*member: access36:
ConstructorTearOff(ComplexAlias<int>.named)*/
void access36() {}

@Helper(self.GenericAlias.new)
/*member: access37:
ConstructorTearOff(GenericAlias.new)*/
void access37() {}

@Helper(self.GenericAlias.named)
/*member: access38:
ConstructorTearOff(GenericAlias.named)*/
void access38() {}

@Helper(self.GenericAlias<int, String>.new)
/*member: access39:
ConstructorTearOff(GenericAlias<int,String>.new)*/
void access39() {}

@Helper(self.GenericAlias<int, String>.named)
/*member: access40:
ConstructorTearOff(GenericAlias<int,String>.named)*/
void access40() {}
