class C<T, U> {
  foo() => print(U);
}

class D extends C<int, double> {}

main() {
  new D().foo();
}
