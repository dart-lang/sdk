// Without specific missing-brace recovery, we'll end up with:
// * Class Foo, member Foo.foo_method1
// With specific missing-brace recovery, we'll end up with the correct:
// * Class Foo, members Foo.foo_method1, Foo.foo_method2
// * Class Bar, members Bar.bar_method1, Bar.bar_method2

class Foo {
  void foo_method1() {
    if (1+1==2) { // we just typed the begin brace and there's no end brace yet.
    // e.g. we're editing in IntelliJ and we haven't hit enter yet.
    // missing: }

    if (1 + 1 == 2) {
      // This one is fine
    }
  }

  void foo_method2() {
    // bla
  }
}

class Bar {
  void bar_method1() {
    // bla
  }

  void bar_method2() {
    // bla
  }
}
