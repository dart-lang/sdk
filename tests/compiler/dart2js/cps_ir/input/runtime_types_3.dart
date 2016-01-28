class C<T> {
  foo() => new D<C<T>>();
}
class D<T> {
  bar() => T;
}
main() {
  print(new C<int>().foo().bar());
}
