class A {
  var field;
}

class B {
  var field;
}

class C {
  operator ==(x) => false;
}

class X implements A, B {
  var field;
}

void useAsA(A object) {
  var _ = object.field;
}

void useAsB(B object) {
  var _ = object.field;
  escape(object);
}

void escape(x) {
  x ??= "";
  x ??= 45;
  if (x is! int && x is! String) {
    x.field = 45;
  }
}

main() {
  // escape("");
  // escape(45);

  var object = new X();
  useAsA(new A());
  useAsA(object);

  useAsB(new B());
  useAsB(object);
}
