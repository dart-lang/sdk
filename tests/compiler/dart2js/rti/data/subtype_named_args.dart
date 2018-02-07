// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// From co19/Language/Types/Function_Types/subtype_named_args_t02.

import 'package:expect/expect.dart';

/*ast.class: A:arg,checks=[A,Object],explicit=[dynamic Function({a:A,b:B,c:C,d:D}),dynamic Function({g:G<A,B,C,D>,l:List<List<B>>,m:Map<num,int>})]*/
/*kernel.class: A:arg,checks=[A,Object],explicit=[dynamic Function({a:A,b:B,c:C,d:D}),dynamic Function({f1:dynamic Function({a:A,b:B,c:C,d:D}),f2:dynamic Function({g:G<A,B,C,D>,l:List<List<B>>,m:Map<num,int>}),f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})}),dynamic Function({g:G<A,B,C,D>,l:List<List<B>>,m:Map<num,int>})]*/
class A {}

/*class: A1:arg,checks=[A1,Object]*/
class A1 {}

/*class: A2:arg,checks=[A2,Object]*/
class A2 {}

/*ast.class: B:arg,checks=[A,A1,A2,B,Object],explicit=[dynamic Function({a:A,b:B,c:C,d:D}),dynamic Function({g:G<A,B,C,D>,l:List<List<B>>,m:Map<num,int>})]*/
/*kernel.class: B:arg,checks=[A,A1,A2,B,Object],explicit=[dynamic Function({a:A,b:B,c:C,d:D}),dynamic Function({f1:dynamic Function({a:A,b:B,c:C,d:D}),f2:dynamic Function({g:G<A,B,C,D>,l:List<List<B>>,m:Map<num,int>}),f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})}),dynamic Function({g:G<A,B,C,D>,l:List<List<B>>,m:Map<num,int>})]*/
class B implements A, A1, A2 {}

/*ast.class: C:arg,checks=[A,A1,A2,B,C,Object],explicit=[dynamic Function({a:A,b:B,c:C,d:D}),dynamic Function({g:G<A,B,C,D>,l:List<List<B>>,m:Map<num,int>})]*/
/*kernel.class: C:arg,checks=[A,A1,A2,B,C,Object],explicit=[dynamic Function({a:A,b:B,c:C,d:D}),dynamic Function({f1:dynamic Function({a:A,b:B,c:C,d:D}),f2:dynamic Function({g:G<A,B,C,D>,l:List<List<B>>,m:Map<num,int>}),f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})}),dynamic Function({g:G<A,B,C,D>,l:List<List<B>>,m:Map<num,int>})]*/
class C implements B {}

/*ast.class: D:arg,checks=[A,A1,A2,B,C,D,Object],explicit=[dynamic Function({a:A,b:B,c:C,d:D}),dynamic Function({g:G<A,B,C,D>,l:List<List<B>>,m:Map<num,int>})]*/
/*kernel.class: D:arg,checks=[A,A1,A2,B,C,D,Object],explicit=[dynamic Function({a:A,b:B,c:C,d:D}),dynamic Function({f1:dynamic Function({a:A,b:B,c:C,d:D}),f2:dynamic Function({g:G<A,B,C,D>,l:List<List<B>>,m:Map<num,int>}),f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})}),dynamic Function({g:G<A,B,C,D>,l:List<List<B>>,m:Map<num,int>})]*/
class D implements C {}

/*ast.class: G:arg,checks=[G,Object],explicit=[dynamic Function({g:G<A,B,C,D>,l:List<List<B>>,m:Map<num,int>})]*/
/*kernel.class: G:arg,checks=[G,Object],explicit=[dynamic Function({f1:dynamic Function({a:A,b:B,c:C,d:D}),f2:dynamic Function({g:G<A,B,C,D>,l:List<List<B>>,m:Map<num,int>}),f3:dynamic Function({v:dynamic,x:dynamic,y:dynamic,z:dynamic})}),dynamic Function({g:G<A,B,C,D>,l:List<List<B>>,m:Map<num,int>})]*/
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
  Expect.isTrue(({D a, B b, C c, A d}) {} is classesFunc);
  Expect.isTrue(({A a, A b, A c, A d}) {} is classesFunc);
  Expect.isTrue(({D a, A1 b, A1 c, A1 d}) {} is classesFunc);
  Expect.isTrue(({D a, A2 b, A2 c, A2 d}) {} is classesFunc);
  Expect.isTrue(({D a, D b, D c, D d}) {} is classesFunc);
  Expect.isTrue(({var a, var b, var c, var d}) {} is classesFunc);
  Expect.isTrue(({Object a, Object b, Object c, Object d}) {} is classesFunc);

  Expect.isTrue(({Map<num, num> m, List<List<A1>> l, G<A, A1, A1, A1> g}) {}
      is genericsFunc);
  Expect.isTrue(
      ({Map<int, int> m, List<List<D>> l, G<D, D, D, D> g}) {} is genericsFunc);
  Expect.isTrue(({var m, var l, var g}) {} is genericsFunc);
  Expect.isTrue(({Object m, Object l, Object g}) {} is genericsFunc);

  Expect.isTrue(({A x, G y, mixFunc z, var v}) {} is dynamicFunc);
  Expect
      .isTrue(({int x, bool y, List<Map> z, classesFunc v}) {} is dynamicFunc);

  Expect.isTrue((
      {okWithClassesFunc_1 f1,
      okWithGenericsFunc_1 f2,
      okWithDynamicFunc_1 f3}) {} is funcFunc);
  Expect.isTrue((
      {okWithClassesFunc_2 f1,
      okWithGenericsFunc_2 f2,
      okWithDynamicFunc_2 f3}) {} is funcFunc);
}
