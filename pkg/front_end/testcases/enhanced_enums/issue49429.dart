class A {
  const A();
  const factory A.redir() = A;
}

enum E {
  element(A.redir());

  const E(A a);
}

main() {}
