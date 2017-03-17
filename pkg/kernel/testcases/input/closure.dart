class Foo {
  var _field = new Bar();
}

class Bar {}

useCallback(callback) {
  var _ = callback();
}

main() {
  var x;
  inner() {
    x = new Foo();
    return new Foo();
  }

  useCallback(inner);
  var _ = inner()._field;
}
