void fn1<T>() {
  void fn2<T>() {} // LINT
  void fn3<U>() {} // OK
  void fn4() {} // OK
}

// TODO(srawlins): Lint on this stuff as well when the analyzer/language(?)
// support it. Right now analyzer spits out a compile time error: "Analysis of
// generic function typed parameters is not yet supported."
// void fn2<T>(void Function<T>()) {} // NOT OK

class A<T> {
  static void fn1<T>() {} // OK
}

class B<T> {
  void fn1<T>() {} // LINT
  void fn2<U>() {} // OK
  void fn3<V>() {} // OK
}

class C<T> {
  void fn1<U>() {
    void fn2<T>() {} // LINT
    void fn3<U>() {} // LINT
    void fn4<V>() {} // OK
    void fn5() {} // OK
  }
}

class D<T> {
  void fn1<U>() {
    void fn2<V>() {
      void fn3<T>() {} // LINT
      void fn4<U>() {} // LINT
      void fn5<V>() {} // LINT
      void fn6<W>() {} // OK
      void fn7() {} // OK
    }
  }
}

// Make sure we don't hit any null pointers when none of a function or method's
// ancestors have type parameters.
class E {
  void fn1() {
    void fn2() {
      void fn3<T>() {} // OK
    }
  }

  void fn4<T>() {} // OK
}
