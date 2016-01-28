class C<T> {
  foo() => T;
}
main() {
  print(new C<int>().foo());
}
