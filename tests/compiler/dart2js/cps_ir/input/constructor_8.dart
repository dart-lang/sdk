class C<T> {
  foo() => C;
}
main() {
  print(new C<int>().foo());
}
