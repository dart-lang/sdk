// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

final int opaqueOne = int.parse('1');

void main() {
  final d = Derived<String>("hello", 42 * opaqueOne);
  Expect.equals("hello", d.t);
  Expect.equals(42, d.u);
  Expect.equals("hello", d.v);
  Expect.isTrue(d.t is String);
  Expect.isTrue(d.u is int);

  {
    final c = InitCapture(10 * opaqueOne);
    Expect.equals(10, c.getP());
  }

  {
    final c = BodyCapture(20 * opaqueOne);
    Expect.equals(20, c.getP());
  }

  {
    final c = BodyCaptureType<num>(opaqueOne);
    Expect.equals(1, c.p);
    Expect.equals(num, c.getT());
  }
  {
    final c = BodyCaptureParamField(opaqueOne);
    Expect.equals(1, c.p);
    Expect.equals(1, c.getP());
  }

  {
    final c = InitCaptureModify(30 * opaqueOne);
    Expect.equals(32, c.pAfter);
    Expect.equals(33, c.getP());
    Expect.equals(34, c.getP());
  }

  {
    final c = BodyCaptureModify(40 * opaqueOne);
    Expect.equals(50, c.pInBody);
    Expect.equals(51, c.getP());
    Expect.equals(52, c.getP());
  }

  {
    final c = InitStoreModify(60 * opaqueOne);
    Expect.equals(60, c.field1);
    Expect.equals(61, c.field2);
  }

  {
    final c = BodyModify(70 * opaqueOne);
    Expect.equals(70, c.field);
    Expect.equals(170, c.finalP);
  }

  {
    final c = SuperDerived(90 * opaqueOne);
    Expect.equals(90, c.y);
    Expect.equals(91, c.x);
  }

  {
    final c = ModifyInInitAndUseInBody(100 * opaqueOne);
    Expect.equals(101, c.inInit);
    Expect.equals(101, c.inBody);
  }

  {
    final c = CaptureInInitModifyInBody(200 * opaqueOne);
    Expect.equals(210, c.inBody);
    Expect.equals(210, c.closure());
  }

  {
    final c = DoubleCapture(300 * opaqueOne);
    Expect.equals(310, c.initClosure());
    Expect.equals(310, c.bodyClosure());
  }

  {
    final c1 = MixedParams(opaqueOne);
    Expect.equals(1, c1.a);
    Expect.equals(2, c1.b);
    Expect.equals(3, c1.c);

    final c2 = MixedParams(opaqueOne, 10 * opaqueOne);
    Expect.equals(1, c2.a);
    Expect.equals(10, c2.b);
    Expect.equals(3, c2.c);
  }

  {
    final c1 = NamedParams(a: 5 * opaqueOne);
    Expect.equals(5, c1.a);
    Expect.equals(20, c1.b);

    final c2 = NamedParams(b: 30 * opaqueOne, a: 7 * opaqueOne);
    Expect.equals(7, c2.a);
    Expect.equals(30, c2.b);
  }

  {
    final c = RedirectDerived(10 * opaqueOne, 20 * opaqueOne);
    Expect.equals(30, c.c);
    Expect.equals(10, c.a);
    Expect.equals(11, c.b);
  }

  {
    final c = FactoryClass(50 * opaqueOne);
    Expect.equals(150, c.x);
  }

  {
    final c = MultiUse(400 * opaqueOne);
    Expect.equals(400, c.a);
    Expect.equals(401, c.b);
    Expect.equals(401, c.c);
  }

  {
    final c = CaptureAndModifyInInit(500 * opaqueOne);
    Expect.equals(505, c.field);
    Expect.equals(505, c.getP());
  }
}

// Generic class inheritance with partial type arguments
class Base<T, U> {
  T t;
  U u;
  Base(this.t, this.u);
}

class Derived<V> extends Base<V, int> {
  V v;
  Derived(V v_in, int i) : v = v_in, super(v_in, i);
}

// Initializer captures parameter (via closure)
class InitCapture {
  final int Function() getP;
  InitCapture(int p) : getP = (() => p);
}

// Body captures parameter (via closure)
class BodyCapture {
  late final int Function() getP;
  BodyCapture(int p) {
    getP = () => p;
  }
}

class BodyCaptureParamField {
  final int p;
  late int Function() getP;

  BodyCaptureParamField(this.p) {
    getP = (() => p);
  }
}

class BodyCaptureType<T> {
  final int p;
  late Type Function() getT;

  BodyCaptureType(this.p) {
    getT = (() => T);
  }
}

// Initializer captures and modifies parameter
class InitCaptureModify {
  final int Function() getP;
  final int pAfter;
  InitCaptureModify(int p)
    : getP = (() {
        p = p + 1;
        return p;
      }),
      pAfter = (p = p + 2);
}

// Body captures and modifies parameter
class BodyCaptureModify {
  late final int Function() getP;
  int pInBody = 0;
  BodyCaptureModify(int p) {
    p = p + 10;
    pInBody = p;
    getP = () {
      p = p + 1;
      return p;
    };
  }
}

// Initializer stores parameter in field but also modifies it
class InitStoreModify {
  int field1;
  int field2;
  InitStoreModify(int p) : field1 = p, field2 = (p = p + 1);
}

// Constructor body that modifies parameter
class BodyModify {
  int field;
  int finalP = 0;
  BodyModify(int p) : field = p {
    p = p + 100;
    finalP = p;
  }
}

// Super call with modified parameters
class SuperBase {
  int x;
  SuperBase(this.x);
}

class SuperDerived extends SuperBase {
  int y;
  SuperDerived(int p) : y = p, super(p = p + 1);
}

// Parameter modified in initializer and then used in body
class ModifyInInitAndUseInBody {
  int inInit;
  int inBody = 0;
  ModifyInInitAndUseInBody(int p) : inInit = (p = p + 1) {
    inBody = p;
  }
}

// Closure created in initializer captures p, and p is modified in body
class CaptureInInitModifyInBody {
  int Function() closure;
  int inBody = 0;
  CaptureInInitModifyInBody(int p) : closure = (() => p) {
    p = p + 10;
    inBody = p;
  }
}

// Double capture (both in initializer and body)
class DoubleCapture {
  int Function() initClosure;
  late final int Function() bodyClosure;
  DoubleCapture(int p) : initClosure = (() => p) {
    p = p + 5;
    bodyClosure = () => p;
    p = p + 5;
  }
}

// Mixed parameters (named, optional)
class MixedParams {
  int a;
  int b;
  int c;
  MixedParams(this.a, [this.b = 2, this.c = 3]);
}

class NamedParams {
  int a;
  int b;
  NamedParams({required this.a, this.b = 20});
}

// Redirecting constructors
class RedirectBase {
  int a;
  int b;
  RedirectBase(this.a, this.b);
  RedirectBase.named(int x) : this(x, x + 1);
}

class RedirectDerived extends RedirectBase {
  int c;
  RedirectDerived(int x, int y) : c = x + y, super.named(x);
}

// Factory constructors
class FactoryClass {
  int x;
  FactoryClass._(this.x);
  factory FactoryClass(int x) => FactoryClass._(x + 100);
}

// Parameter used in multiple initializers and body
class MultiUse {
  int a;
  int b;
  int c = 0;
  MultiUse(int p) : a = p, b = (p = p + 1) {
    c = p;
  }
}

// Parameter captured in initializer and modified in initializer
class CaptureAndModifyInInit {
  int Function() getP;
  int field;
  CaptureAndModifyInInit(int p) : getP = (() => p), field = (p = p + 5);
}
