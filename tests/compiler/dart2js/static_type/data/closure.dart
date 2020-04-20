// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class Class {
  Class next;
}

main() {
  closure1(null);
  closure2(null);
  closure3(null);
  closure4(null);
  closure4a(null);
  closure5(null);
  closure6(null);
  closure7();
}

closure1(dynamic c) {
  if (/*dynamic*/ c is Class) {
    /*Class*/ c.next;
    local() {
      /*dynamic*/ c.next;
      if (/*dynamic*/ c is Class) {
        /*Class*/ c.next;
      }
      c = 0;
    }

    /*dynamic*/ c.next;
    /*invoke: [Null Function()]->Null*/ local();
    /*dynamic*/ c.next;
  }
}

closure2(dynamic c) {
  if (/*dynamic*/ c is Class) {
    /*Class*/ c.next;
    local() {
      /*Class*/ c.next;
    }

    /*Class*/ c.next;
    /*invoke: [Null Function()]->Null*/ local();
    /*Class*/ c.next;
  }
}

closure3(dynamic c) {
  if (/*dynamic*/ c is Class) {
    /*Class*/ c.next;
    local() {
      /*dynamic*/ c.next;
    }

    c = 0;
    /*dynamic*/ c.next;
    /*invoke: [Null Function()]->Null*/ local();
    /*dynamic*/ c.next;
  }
}

closure4(dynamic c) {
  if (/*dynamic*/ c is Class) {
    /*Class*/ c.next;
    local() {
      /*dynamic*/ c.next;
    }

    /*Class*/ c.next;
    /*invoke: [Null Function()]->Null*/ local();
    /*Class*/ c.next;
    c = 0;
    /*dynamic*/ c.next;
  }
}

closure4a(dynamic c) {
  if (/*dynamic*/ c is Class) {
    /*Class*/ c.next;
    local() {
      /*dynamic*/ c.next;
      c = 0;
    }

    /*dynamic*/ c.next;
    /*invoke: [Null Function()]->Null*/ local();
    /*dynamic*/ c.next;
    c = 0;
    /*dynamic*/ c.next;
  }
}

closure5(dynamic c) {
  /*dynamic*/ c.next;
  local() {
    /*dynamic*/ c.next;
    if (/*dynamic*/ c is! Class) return;
    /*Class*/ c.next;
  }

  /*dynamic*/ c.next;
  /*invoke: [Null Function()]->Null*/ local();
  /*dynamic*/ c.next;
  c = 0;
  /*dynamic*/ c.next;
}

_returnTrue(_) => true;

class A {}

class B extends A {
  f() {}
}

closure6(var x) {
  var closure;
  /*dynamic*/ x is B &&
      _returnTrue(
          closure = () => /*dynamic*/ x. /*invoke: [dynamic]->dynamic*/ f());
  /*dynamic*/ x;
  x = new A();
  /*dynamic*/ closure. /*invoke: [dynamic]->dynamic*/ call();
  /*dynamic*/ x;
}

class C {}

class D extends C {
  f() {}
}

class E extends D {
  g() {}
}

_closure7(C x) {
  /*C*/ x is D && _returnTrue((() => /*C*/ x))
      ? /*D*/ x. /*invoke: [D]->dynamic*/ f()
      : x = new C();
  _returnTrue((() => /*C*/ x)) && /*C*/ x is D
      ? /*D*/ x. /*invoke: [D]->dynamic*/ f()
      : x = new C();

  (/*C*/ x is D && _returnTrue((() => /*C*/ x))) &&
          (/*D*/ x is E && _returnTrue((() => /*C*/ x)))
      ? /*E*/ x. /*invoke: [E]->dynamic*/ g()
      : x = new C();

  (_returnTrue((() => /*C*/ x)) && /*C*/ x is E) &&
          (_returnTrue((() => /*C*/ x)) && /*E*/ x is D)
      ? /*E*/ x. /*invoke: [E]->dynamic*/ g()
      : x = new C();
}

closure7() {
  _closure7(new D());
  _closure7(new E());
}
