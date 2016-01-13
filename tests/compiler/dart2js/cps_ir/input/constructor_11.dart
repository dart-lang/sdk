class A {
  var x;
  A() : this.b(1);
  A.b(this.x);
}
main() {
  print(new A().x);
}
