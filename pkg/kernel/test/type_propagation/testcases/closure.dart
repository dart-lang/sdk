class Foo {
  var _field = new Bar();
}

class Bar {}

useCallback(callback) {
  var _ = callback();
}

main() {
  inner() {
    return new Foo();
  }
  useCallback(inner);
  var _ = inner()._field;
}
