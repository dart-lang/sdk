// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int x;

  static final A a = new A();

  A(){}
}

class WillNotOptimizeFieldAccess {
  WillNotOptimizeFieldAccess(){}
  int x;
}

class WillNotOptimizeFieldAccessSubclass extends WillNotOptimizeFieldAccess {
  WillNotOptimizeFieldAccessSubclass() : super() {}
  
  int get x() {
    return this.x;
  }
}

class B extends A {
    B() : super() { }

    // can be inlined.
    int get x_Getter_WithoutSideEffect() {
        return x;
    }

    // cannot be inlined - getter has side effect.
    int get x_Getter_WithSideEffect() {
        return x + 1;
    }

    // cannot be inlined - underlying value is not a field.
    int get x_Getter_WithSomeExpression() {
        return foo() * 2;
    }

    static foo() { return 123; }

    // cannot be inlined - underlying field is static.
    A get A_Getter() {
        return a;
    }

    // cannot be inlined - cycle.
    int get X_Getter() {
        return this.X_Getter;
    }
}

class C {
  C() { }

  int x;
  A a;

  int get XGetter() {
    return this.x;
  }

  int get AXGetter() {
    return a.x;
  }
}

class Main {
  static void main() {

    A _marker_0 = new A();

    _marker_0.x = 1;

    int x = _marker_0.x;

    WillNotOptimizeFieldAccessSubclass _marker_1 = new WillNotOptimizeFieldAccessSubclass();
    _marker_1.x = 1;
    int y = _marker_1.x;

    B b = new B();
    int _marker_2 = b.x_Getter_WithoutSideEffect;

    int _marker_3 = b.x_Getter_WithSideEffect;

    int _marker_4 = b.x_Getter_WithSomeExpression;

    A _marker_5 = b.A_Getter;

    int _marker_6 = b.X_Getter;

    C c = new C();

    int _marker_7 = c.XGetter;

    int _marker_8 = c.AXGetter;
  }
}

main() {
  Main.main();
}
