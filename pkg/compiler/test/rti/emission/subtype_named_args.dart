// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// From co19/Language/Types/Function_Types/subtype_named_args_t02.

import 'package:expect/expect.dart';

/*spec.class: A:checkedInstance,checkedTypeArgument,typeArgument*/
/*prod.class: A:checkedTypeArgument,typeArgument*/
class A {}

/*spec.class: A1:checkedInstance,checkedTypeArgument,typeArgument*/
/*prod.class: A1:checkedTypeArgument,typeArgument*/
class A1 {}

/*spec.class: A2:checkedInstance,checkedTypeArgument,typeArgument*/
/*prod.class: A2:checkedTypeArgument,typeArgument*/
class A2 {}

/*spec.class: B:checkedInstance,checkedTypeArgument,typeArgument*/
/*prod.class: B:checkedTypeArgument,typeArgument*/
class B implements A, A1, A2 {}

/*spec.class: C:checkedInstance,checkedTypeArgument,typeArgument*/
/*prod.class: C:checkedTypeArgument,typeArgument*/
class C implements B {}

/*spec.class: D:checkedInstance,checkedTypeArgument,typeArgument*/
/*prod.class: D:checkedTypeArgument,typeArgument*/
class D implements C {}

/*spec.class: G:checkedInstance,checkedTypeArgument,typeArgument*/
/*prod.class: G:checkedTypeArgument,typeArgument*/
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
      /*checks=[$signature],instance*/
      ({D a, B b, C c, A d}) {} is classesFunc);
  Expect.isTrue(
      /*checks=[$signature],instance*/
      ({A a, A b, A c, A d}) {} is classesFunc);
  Expect.isTrue(
      /*checks=[$signature],instance*/
      ({D a, A1 b, A1 c, A1 d}) {} is classesFunc);
  Expect.isTrue(
      /*checks=[$signature],instance*/
      ({D a, A2 b, A2 c, A2 d}) {} is classesFunc);
  Expect.isTrue(
      /*checks=[$signature],instance*/
      ({D a, D b, D c, D d}) {} is classesFunc);
  Expect.isTrue(
      /*checks=[$signature],instance*/
      ({var a, var b, var c, var d}) {} is classesFunc);
  Expect.isTrue(
      /*checks=[$signature],instance*/
      ({Object a, Object b, Object c, Object d}) {} is classesFunc);

  Expect.isTrue(
      /*checks=[$signature],instance*/
      ({Map<num, num> m, List<List<A1>> l, G<A, A1, A1, A1> g}) {}
          is genericsFunc);
  Expect.isTrue(
      /*checks=[$signature],instance*/
      ({Map<int, int> m, List<List<D>> l, G<D, D, D, D> g}) {} is genericsFunc);
  Expect.isTrue(
      /*checks=[$signature],instance*/
      ({var m, var l, var g}) {} is genericsFunc);
  Expect.isTrue(
      /*checks=[$signature],instance*/
      ({Object m, Object l, Object g}) {} is genericsFunc);

  Expect.isTrue(
      /*checks=[$signature],instance*/
      ({A x, G y, mixFunc z, var v}) {} is dynamicFunc);
  Expect.isTrue(
      /*checks=[$signature],instance*/
      ({int x, bool y, List<Map> z, classesFunc v}) {} is dynamicFunc);

  Expect.isTrue(
      /*checks=[$signature],instance*/
      (
          {okWithClassesFunc_1 f1,
          okWithGenericsFunc_1 f2,
          okWithDynamicFunc_1 f3}) {} is funcFunc);
  Expect.isTrue(
      /*checks=[$signature],instance*/
      (
          {okWithClassesFunc_2 f1,
          okWithGenericsFunc_2 f2,
          okWithDynamicFunc_2 f3}) {} is funcFunc);
}
