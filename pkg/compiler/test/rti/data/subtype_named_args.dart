// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// From co19/Language/Types/Function_Types/subtype_named_args_t02.

import 'package:expect/expect.dart';

/*spec.class: A:explicit=[A*,G<A*,A1*,A1*,A1*>*,dynamic Function({a:A*,b:A1*,c:A1*,d:A1*})*,dynamic Function({a:A*,b:B*,c:C*,d:D*})*,dynamic Function({b:B*,f:dynamic Function({f1:dynamic Function({a:A*,b:B*,c:C*,d:D*})*,f2:dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})*})*,g:G<A*,B*,C*,D*>*,x:dynamic})*,dynamic Function({f1:dynamic Function({a:A*,b:B*,c:C*,d:D*})*,f2:dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})*})*,dynamic Function({g:G<A*,A1*,A1*,A1*>*,l:List<List<A1*>*>*,m:Map<num*,num*>*})*,dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,dynamic Function({v:dynamic Function({a:A*,b:B*,c:C*,d:D*})*,x:int*,y:bool*,z:List<Map*>*})*,dynamic Function({v:dynamic,x:A*,y:G*,z:dynamic Function({b:B*,f:dynamic Function({f1:dynamic Function({a:A*,b:B*,c:C*,d:D*})*,f2:dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})*})*,g:G<A*,B*,C*,D*>*,x:dynamic})*})*]*/
/*prod.class: A:explicit=[dynamic Function({a:A*,b:B*,c:C*,d:D*})*,dynamic Function({f1:dynamic Function({a:A*,b:B*,c:C*,d:D*})*,f2:dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})*})*,dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*]*/
class A {}

/*spec.class: A1:explicit=[A1*,G<A*,A1*,A1*,A1*>*,List<List<A1*>*>*,dynamic Function({a:A*,b:A1*,c:A1*,d:A1*})*,dynamic Function({g:G<A*,A1*,A1*,A1*>*,l:List<List<A1*>*>*,m:Map<num*,num*>*})*]*/
class A1 {}

/*spec.class: A2:explicit=[A2*]*/
class A2 {}

/*spec.class: B:explicit=[B*,dynamic Function({a:A*,b:B*,c:C*,d:D*})*,dynamic Function({b:B*,f:dynamic Function({f1:dynamic Function({a:A*,b:B*,c:C*,d:D*})*,f2:dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})*})*,g:G<A*,B*,C*,D*>*,x:dynamic})*,dynamic Function({f1:dynamic Function({a:A*,b:B*,c:C*,d:D*})*,f2:dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})*})*,dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,dynamic Function({v:dynamic Function({a:A*,b:B*,c:C*,d:D*})*,x:int*,y:bool*,z:List<Map*>*})*,dynamic Function({v:dynamic,x:A*,y:G*,z:dynamic Function({b:B*,f:dynamic Function({f1:dynamic Function({a:A*,b:B*,c:C*,d:D*})*,f2:dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})*})*,g:G<A*,B*,C*,D*>*,x:dynamic})*})*]*/
/*prod.class: B:explicit=[dynamic Function({a:A*,b:B*,c:C*,d:D*})*,dynamic Function({f1:dynamic Function({a:A*,b:B*,c:C*,d:D*})*,f2:dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})*})*,dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*]*/
class B implements A, A1, A2 {}

/*spec.class: C:explicit=[C*,dynamic Function({a:A*,b:B*,c:C*,d:D*})*,dynamic Function({b:B*,f:dynamic Function({f1:dynamic Function({a:A*,b:B*,c:C*,d:D*})*,f2:dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})*})*,g:G<A*,B*,C*,D*>*,x:dynamic})*,dynamic Function({f1:dynamic Function({a:A*,b:B*,c:C*,d:D*})*,f2:dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})*})*,dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,dynamic Function({v:dynamic Function({a:A*,b:B*,c:C*,d:D*})*,x:int*,y:bool*,z:List<Map*>*})*,dynamic Function({v:dynamic,x:A*,y:G*,z:dynamic Function({b:B*,f:dynamic Function({f1:dynamic Function({a:A*,b:B*,c:C*,d:D*})*,f2:dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})*})*,g:G<A*,B*,C*,D*>*,x:dynamic})*})*]*/
/*prod.class: C:explicit=[dynamic Function({a:A*,b:B*,c:C*,d:D*})*,dynamic Function({f1:dynamic Function({a:A*,b:B*,c:C*,d:D*})*,f2:dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})*})*,dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*]*/
class C implements B {}

/*spec.class: D:explicit=[D*,G<D*,D*,D*,D*>*,List<List<D*>*>*,dynamic Function({a:A*,b:B*,c:C*,d:D*})*,dynamic Function({a:D*,b:D*,c:D*,d:D*})*,dynamic Function({b:B*,f:dynamic Function({f1:dynamic Function({a:A*,b:B*,c:C*,d:D*})*,f2:dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})*})*,g:G<A*,B*,C*,D*>*,x:dynamic})*,dynamic Function({f1:dynamic Function({a:A*,b:B*,c:C*,d:D*})*,f2:dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})*})*,dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,dynamic Function({g:G<D*,D*,D*,D*>*,l:List<List<D*>*>*,m:Map<int*,int*>*})*,dynamic Function({v:dynamic Function({a:A*,b:B*,c:C*,d:D*})*,x:int*,y:bool*,z:List<Map*>*})*,dynamic Function({v:dynamic,x:A*,y:G*,z:dynamic Function({b:B*,f:dynamic Function({f1:dynamic Function({a:A*,b:B*,c:C*,d:D*})*,f2:dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})*})*,g:G<A*,B*,C*,D*>*,x:dynamic})*})*]*/
/*prod.class: D:explicit=[dynamic Function({a:A*,b:B*,c:C*,d:D*})*,dynamic Function({f1:dynamic Function({a:A*,b:B*,c:C*,d:D*})*,f2:dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})*})*,dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*]*/
class D implements C {}

/*spec.class: G:explicit=[G*,G<A*,A1*,A1*,A1*>*,G<D*,D*,D*,D*>*,dynamic Function({b:B*,f:dynamic Function({f1:dynamic Function({a:A*,b:B*,c:C*,d:D*})*,f2:dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})*})*,g:G<A*,B*,C*,D*>*,x:dynamic})*,dynamic Function({f1:dynamic Function({a:A*,b:B*,c:C*,d:D*})*,f2:dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})*})*,dynamic Function({g:G<A*,A1*,A1*,A1*>*,l:List<List<A1*>*>*,m:Map<num*,num*>*})*,dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,dynamic Function({g:G<D*,D*,D*,D*>*,l:List<List<D*>*>*,m:Map<int*,int*>*})*,dynamic Function({v:dynamic,x:A*,y:G*,z:dynamic Function({b:B*,f:dynamic Function({f1:dynamic Function({a:A*,b:B*,c:C*,d:D*})*,f2:dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})*})*,g:G<A*,B*,C*,D*>*,x:dynamic})*})*],needsArgs*/
/*prod.class: G:explicit=[dynamic Function({f1:dynamic Function({a:A*,b:B*,c:C*,d:D*})*,f2:dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*,f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})*})*,dynamic Function({g:G<A*,B*,C*,D*>*,l:List<List<B*>*>*,m:Map<num*,int*>*})*]*/
class G<T, S, U, W> {}

typedef classesFunc({A a, B b, C c, D d});
typedef genericsFunc({Map<num, int> m, List<List<B>> l, G<A, B, C, D> g});
typedef dynamicFunc({var x, var y, var z, var v});
typedef funcFunc({classesFunc f1, genericsFunc f2, dynamicFunc f3});
typedef mixFunc({var x, B b, G<A, B, C, D> g, funcFunc f});

typedef okWithClassesFunc_1({A a, A1 b, A1 c, A1 d});
typedef okWithClassesFunc_2({D a, D b, D c, D d});

typedef okWithGenericsFunc_1(
    {Map<num, num> m, List<List<A1>> l, G<A, A1, A1, A1> g});
typedef okWithGenericsFunc_2(
    {Map<int, int> m, List<List<D>> l, G<D, D, D, D> g});

typedef okWithDynamicFunc_1({A x, G y, mixFunc z, var v});
typedef okWithDynamicFunc_2({int x, bool y, List<Map> z, classesFunc v});

main() {
  Expect.isTrue(
      /*needsSignature*/
      ({D a, B b, C c, A d}) {} is classesFunc);
  Expect.isTrue(
      /*needsSignature*/
      ({A a, A b, A c, A d}) {} is classesFunc);
  Expect.isTrue(
      /*needsSignature*/
      ({D a, A1 b, A1 c, A1 d}) {} is classesFunc);
  Expect.isTrue(
      /*needsSignature*/
      ({D a, A2 b, A2 c, A2 d}) {} is classesFunc);
  Expect.isTrue(
      /*needsSignature*/
      ({D a, D b, D c, D d}) {} is classesFunc);
  Expect.isTrue(
      /*needsSignature*/
      ({var a, var b, var c, var d}) {} is classesFunc);
  Expect.isTrue(
      /*needsSignature*/
      ({Object a, Object b, Object c, Object d}) {} is classesFunc);

  Expect.isTrue(
      /*needsSignature*/
      ({Map<num, num> m, List<List<A1>> l, G<A, A1, A1, A1> g}) {}
          is genericsFunc);
  Expect.isTrue(
      /*needsSignature*/
      ({Map<int, int> m, List<List<D>> l, G<D, D, D, D> g}) {} is genericsFunc);
  Expect.isTrue(
      /*needsSignature*/
      ({var m, var l, var g}) {} is genericsFunc);
  Expect.isTrue(
      /*needsSignature*/
      ({Object m, Object l, Object g}) {} is genericsFunc);

  Expect.isTrue(
      /*needsSignature*/
      ({A x, G y, mixFunc z, var v}) {} is dynamicFunc);
  Expect.isTrue(
      /*needsSignature*/
      ({int x, bool y, List<Map> z, classesFunc v}) {} is dynamicFunc);

  Expect.isTrue(/*needsSignature*/(
      {okWithClassesFunc_1 f1,
      okWithGenericsFunc_1 f2,
      okWithDynamicFunc_1 f3}) {} is funcFunc);
  Expect.isTrue(
      /*needsSignature*/
      (
          {okWithClassesFunc_2 f1,
          okWithGenericsFunc_2 f2,
          okWithDynamicFunc_2 f3}) {} is funcFunc);
}
