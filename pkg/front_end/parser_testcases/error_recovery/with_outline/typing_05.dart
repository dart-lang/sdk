// Without specific missing-brace recovery, we'll end up with:
// * Class Foo, member Foo.foo_method1
// With specific missing-brace recovery, we'll end up with the correct:
// * Class Foo, members Foo.foo_method1, Foo.foo_method2
// * Class Bar, members Bar.bar_method1, Bar.bar_method2

class Foo {
  void foo_method1() {
    if (1 + 1 == 2) {
      if (1 + 1 == 2) {
        if (1 + 1 == 2) {
          var x = const {1: 2, 3: 4 /* missing `}` */
        }
      }
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
