enum E<F> {
  v<int>/*about to write () or .foo()*/;

  const E();
  const E.foo();
}
