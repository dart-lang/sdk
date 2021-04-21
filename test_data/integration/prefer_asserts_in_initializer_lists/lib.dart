class A {
  A.c1(a) : assert(a != null); // OK
  A.c2(a)
    : assert(a != null) // OK
  {
    assert(a != null); // LINT
    print('');
    assert(a != null); // OK
  }
}
