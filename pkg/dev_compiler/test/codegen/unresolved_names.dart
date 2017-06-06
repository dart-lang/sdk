// compile options: --unsafe-force-compile

class C {}

main() {
  new Foo();
  new C.bar();
  print(baz);
  print(C.quux);
}
