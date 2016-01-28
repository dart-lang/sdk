class A {
  factory A(x) = B<int>;
  get typevar;
}
class B<T> implements A {
  var x;
  B(this.x);

  get typevar => T;
}
main() {
  new A(5).typevar;
}
