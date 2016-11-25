class Foo {
  var field;
}

dynamic identity(x) => x;

void use(x) {}

main(List<String> args) {
  dynamic foo = identity(new Foo());
  if (args.length > 1) {
    foo.field = "string";
    var first = foo.field;
    use(first);
    foo.noField = "string";
    var second = foo.noField;
    use(second);
  }
}
