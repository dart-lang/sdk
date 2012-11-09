class A {
  String get className => runtimeType;
}

main() {
  Expect.isTrue(new A().className is Type);
}
