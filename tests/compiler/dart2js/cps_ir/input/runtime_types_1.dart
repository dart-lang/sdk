class C<T> {
  foo() => print(T);
}

main() {
  new C<int>().foo();
}
