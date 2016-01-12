class A {
  a() => 1;
  b() => () => a();
}
main() {
  print(new A().b()());
}

