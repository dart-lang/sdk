enum E<X, Y> {
  one<int, String>(),
  two<double, num>(),
  three<int, int>.named(42);

  const E();
  const E.named(int value);
}
