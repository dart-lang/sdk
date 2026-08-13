class A {
  operator [](int index) => index;
}

main() {
  A? a = null;
  a!?.toString();
  a!?.[42];
  a!?[42];
  a! ? [42];
}