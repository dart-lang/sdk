class A {}

class B {}

class AB1 extends A implements B {}

class AB2 extends A implements B {}

class BA1 extends B implements A {}

class BA2 extends B implements A {}

takeSubclassOfA(obj) {
  // The analysis should at least infer that 'obj' is a subclass of A,
  // When the upper bound is ambiguous, it should use the common superclass, if
  // there is one besides Object.
}

takeSubclassOfB(obj) {
  // Likewise, the analysis should infer that 'obj' is a subclass of B.
}

main() {
  takeSubclassOfA(new AB1());
  takeSubclassOfA(new AB2());

  takeSubclassOfB(new BA1());
  takeSubclassOfB(new BA2());
}
