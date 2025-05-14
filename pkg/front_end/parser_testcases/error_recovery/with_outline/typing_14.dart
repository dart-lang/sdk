// Without specific missing-brace recovery, we'll end up with:
// * Class Foo, member Foo.foo_method1, Foo.toplevel_method1, Foo.toplevel_method2
// With specific missing-brace recovery, we'll end up with the correct:
// * Class Foo, members Foo.foo_method1, Foo.foo_method2
// * Top-level members toplevel_method1, toplevel_method2

class Foo {
  void foo_method1(dynamic input) {
    if (1 + 1 == 2) {
      foo_method2({1, 2, 3 /* missing: }*/)
    // missing: }
  }

  void foo_method2(dynamic whatever) {
    // bla
  }
}

void toplevel_method1() {
  // bla
}

void toplevel_method2() {
  // bla
}
