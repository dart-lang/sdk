enum E<F> {
  v<int>/*about to write () or .foo()*/,
  v<int>.foo();

  const E();
  const E.foo();
}
