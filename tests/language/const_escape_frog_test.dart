class Foo {
  const Bar<Foo> bar = const Bar/* comment here use to trigger bug 323 */();
}

class Bar<T extends Foo> {
  const Bar();
}

main() {
  Expect.equals(new Foo().bar, const Bar());
}
