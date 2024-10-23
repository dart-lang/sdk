// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:core';
import 'dart:core' as core;
import 'main.dart' as self;

class Helper {
  const Helper(a);
}

class Class {
  const Class([a]);
  const Class.named({a, b});
}

class GenericClass<X, Y> {
  const GenericClass();
  const GenericClass.named({a, b});
}

typedef Alias = Class;
typedef ComplexAlias<X> = Class;
typedef GenericAlias<X, Y> = GenericClass<X, Y>;

@GenericClass<void, dynamic>()
/*member: type1:
ConstructorInvocation(
  GenericClass<void,dynamic>.new())*/
void type1() {}

@GenericClass<FutureOr, FutureOr<void>>()
/*member: type2:
ConstructorInvocation(
  GenericClass<FutureOr,FutureOr<void>>.new())*/
void type2() {}

@GenericClass<Function, Function()>()
/*member: type3:
ConstructorInvocation(
  GenericClass<Function,Function()>.new())*/
void type3() {}

@GenericClass<void Function(), int Function(int)>()
/*member: type4:
ConstructorInvocation(
  GenericClass<void Function(),int Function(int)>.new())*/
void type4() {}

@GenericClass<Object? Function({int a, String b}),
    int Function(int a, {int b})>()
/*member: type5:
ConstructorInvocation(
  GenericClass<Object? Function({int a, String b}),int Function(int a, {int b})>.new())*/
void type5() {}

@GenericClass<void Function() Function(), int Function(void Function())>()
/*member: type6:
ConstructorInvocation(
  GenericClass<void Function() Function(),int Function(void Function())>.new())*/
void type6() {}

@GenericClass<void Function<T>(T), S Function<S, T>(T)>()
/*member: type7:
ConstructorInvocation(
  GenericClass<void Function<(T),S Function<(T)>.new())*/
void type7() {}

@GenericClass<void Function<T extends Class>(T),
    S Function<S, @Class() T extends S>(T)>()
/*member: type8:
ConstructorInvocation(
  GenericClass<void Function<(T),S Function<(T)>.new())*/
void type8() {}

// TODO(johnniwinther): Support this.
//@GenericClass<void Function<T extends Class>(T),
//    S Function<S extends GenericClass<S, T>, T extends S>(T)>()
//void type9() {}

@GenericClass<(), (int,)>()
/*member: type10:
ConstructorInvocation(
  GenericClass<(),(int,)>.new())*/
void type10() {}

@GenericClass<(int, {int a}), ({int a, String b})>()
/*member: type11:
ConstructorInvocation(
  GenericClass<(int, {int a}),({int a, String b})>.new())*/
void type11() {}

@Helper(Alias())
/*member: type12:
ConstructorInvocation(
  Alias.new())*/
void type12() {}

@Helper(Alias.named())
/*member: type13:
ConstructorInvocation(
  Alias.named())*/
void type13() {}

@Helper(ComplexAlias())
/*member: type14:
ConstructorInvocation(
  ComplexAlias.new())*/
void type14() {}

@Helper(ComplexAlias.named())
/*member: type15:
ConstructorInvocation(
  ComplexAlias.named())*/
void type15() {}

@Helper(ComplexAlias<int>())
/*member: type16:
ConstructorInvocation(
  ComplexAlias<int>.new())*/
void type16() {}

@Helper(ComplexAlias<int>.named())
/*member: type17:
ConstructorInvocation(
  ComplexAlias<int>.named())*/
void type17() {}

@Helper(GenericAlias())
/*member: type18:
ConstructorInvocation(
  GenericAlias.new())*/
void type18() {}

@Helper(GenericAlias.named())
/*member: type19:
ConstructorInvocation(
  GenericAlias.named())*/
void type19() {}

@Helper(GenericAlias<int, String>())
/*member: type21:
ConstructorInvocation(
  GenericAlias<int,String>.new())*/
void type21() {}

@Helper(GenericAlias<int, String>.named())
/*member: type22:
ConstructorInvocation(
  GenericAlias<int,String>.named())*/
void type22() {}
