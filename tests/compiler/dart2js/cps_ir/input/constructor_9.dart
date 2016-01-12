// Method to test: generative_constructor(C#)
class C<T> {
  C() { print(T); }
  foo() => print(T);
}
main() {
  new C<int>();
}
