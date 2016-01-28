// Method to test: generative_constructor(C#)
class C<X, Y, Z> {
  foo() => 'C<$X $Y, $Z>';
}
main() {
  new C<C, int, String>().foo();
}
