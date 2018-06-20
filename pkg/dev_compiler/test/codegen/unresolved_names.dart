// compile options: --unsafe-force-compile

class C {}

main() {
  Foo();
  C.bar();
  print(baz);
  print(C.quux);
}
