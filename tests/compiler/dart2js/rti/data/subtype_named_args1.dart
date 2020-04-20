// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// From co19/Language/Types/Function_Types/subtype_named_args_t01.

import "package:expect/expect.dart";

/*strong.class: A:explicit=[A,dynamic Function({a:A})]*/
class A {}

/*strong.class: B:explicit=[B,dynamic Function({a:B}),dynamic Function({f:dynamic Function({a:B})})]*/
/*omit.class: B:explicit=[dynamic Function({a:B}),dynamic Function({f:dynamic Function({a:B})})]*/
class B implements A {}

/*strong.class: C:explicit=[C,dynamic Function({a:C}),dynamic Function({c:C})]*/
/*omit.class: C:explicit=[dynamic Function({c:C})]*/
class C implements B {}

/*strong.class: D:explicit=[D,dynamic Function({a:D})]*/
class D implements C {}

typedef t1({B a});
typedef t2({C c});
typedef t3({int i});
typedef t4({var v});
typedef t5({Map m});
typedef t6({Map<int, num> m});
typedef t7({t1 f});
typedef t8({Object a});

typedef okWithT1_1({A a});
typedef okWithT1_2({B a});
typedef okWithT1_3({C a});
typedef okWithT1_4({D a});

main() {
  Expect.isTrue(/*needsSignature*/ ({A a}) {} is t1);
  Expect.isTrue(/*needsSignature*/ ({B a}) {} is t1);
  Expect.isTrue(/*strong.needsSignature*/ ({C a}) {} is t1);
  Expect.isTrue(/*strong.needsSignature*/ ({D a}) {} is t1);
  Expect.isTrue(/*needsSignature*/ ({Object a}) {} is t1);
  Expect.isTrue(/*needsSignature*/ ({var a}) {} is t1);

  Expect.isTrue(/*needsSignature*/ ({A c}) {} is t2);
  Expect.isTrue(/*needsSignature*/ ({B c}) {} is t2);
  Expect.isTrue(/*needsSignature*/ ({C c}) {} is t2);
  Expect.isTrue(({D c}) {} is t2);
  Expect.isTrue(/*needsSignature*/ ({Object c}) {} is t2);
  Expect.isTrue(/*needsSignature*/ ({var c}) {} is t2);

  Expect.isTrue(/*needsSignature*/ ({num i}) {} is t3);
  Expect.isTrue(/*needsSignature*/ ({int i}) {} is t3);
  Expect.isTrue(/*needsSignature*/ ({Object i}) {} is t3);
  Expect.isTrue(/*needsSignature*/ ({var i}) {} is t3);

  Expect.isTrue(({A v}) {} is t4);
  Expect.isTrue(({B v}) {} is t4);
  Expect.isTrue(({C v}) {} is t4);
  Expect.isTrue(({D v}) {} is t4);
  Expect.isTrue(/*needsSignature*/ ({Object v}) {} is t4);
  Expect.isTrue(/*needsSignature*/ ({var v}) {} is t4);
  Expect.isTrue(({num v}) {} is t4);
  Expect.isTrue(({int v}) {} is t4);
  Expect.isTrue(({Map v}) {} is t4);
  Expect.isTrue(({Map<List<Map<List, List<int>>>, List> v}) {} is t4);
  Expect.isTrue(({List v}) {} is t4);
  Expect.isTrue(({t8 v}) {} is t4);
  Expect.isTrue(({t7 v}) {} is t4);

  Expect.isTrue(/*needsSignature*/ ({Map m}) {} is t5);
  Expect.isTrue(({Map<List, t8> m}) {} is t5);
  Expect.isTrue(/*needsSignature*/ ({Object m}) {} is t5);
  Expect.isTrue(/*needsSignature*/ ({var m}) {} is t5);
  Expect.isTrue(({Map<List, List> m}) {} is t5);
  Expect.isTrue(({Map<int, t8> m}) {} is t5);

  Expect.isTrue(/*needsSignature*/ ({Map<num, num> m}) {} is t6);
  Expect.isTrue(({Map<int, int> m}) {} is t6);
  Expect.isTrue(/*needsSignature*/ ({Map m}) {} is t6);
  Expect.isTrue(/*needsSignature*/ ({Object m}) {} is t6);
  Expect.isTrue(/*needsSignature*/ ({var m}) {} is t6);

  Expect.isTrue(({okWithT1_1 f}) {} is t7);
  Expect.isTrue(/*needsSignature*/ ({okWithT1_2 f}) {} is t7);
  Expect.isTrue(/*needsSignature*/ ({okWithT1_3 f}) {} is t7);
  Expect.isTrue(/*needsSignature*/ ({okWithT1_4 f}) {} is t7);

  Expect.isTrue(/*needsSignature*/ ({A a}) {} is t8);
  Expect.isTrue(/*needsSignature*/ ({B a}) {} is t8);
  Expect.isTrue(/*strong.needsSignature*/ ({C a}) {} is t8);
  Expect.isTrue(/*strong.needsSignature*/ ({D a}) {} is t8);
  Expect.isTrue(/*needsSignature*/ ({Object a}) {} is t8);
  Expect.isTrue(/*needsSignature*/ ({var a}) {} is t8);
  Expect.isTrue(({num a}) {} is t8);
  Expect.isTrue(({int a}) {} is t8);
  Expect.isTrue(({Map a}) {} is t8);
  Expect.isTrue(({Map<List<Map<List, List<int>>>, List> a}) {} is t8);
  Expect.isTrue(({List a}) {} is t8);
}
