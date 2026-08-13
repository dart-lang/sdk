enum E<F> {
  v1<int>./*about to write foo()*/,
  v2<int>.foo();

  const E();
  const E.foo();
}
