class A {
  A.c1(a) : assert(a != null); // OK
  A.c2(a) { // LINT
    assert(a != null);
  }
  A.c3(a) {} // OK
  A.c4(a) { // OK
    print('');
    assert(a != null);
  }
}
