// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that downwards inference uses the promoted type of the variable in an
/// assignment as the context, but still considers the assignment as a valid
/// promotion/demotion point.

/// A generic class to serve as the base type.
class C<S> {
  S cMethod(S x) => x;
}

/// An inference context C<S> constrains the first type variable of D but not
/// the second.
class D<S, T> extends C<S> {
  S dMethod1(S x) => x;
  T dMethod2(T x) => x;
}

/// Generic function which if inferred in a context C<A> with argument type B,
/// should infer to mkD<A, B>
D<S, T> mkD<S, T>(T x) => D();

/// Generic function which if inferred in a context D<S0, S1> with argument type
/// D<T0, T1>, should infer to useD<T0>.
C<T> useD<T>(D<T, int> d) => d;

void main() {
  {
    C<String> x = C();

    // Inference uses C<String> as a downwards context, constraining S from
    // mkD<S,T> to String.  Upwards inference constrains T to int.  D<String,
    // int> is not a type of interest so no promotion should happen.
    {
      // y has the type of the RHS of the assignment
      var y = x = mkD(3);

      // x still has type C<String>
      x.dMethod1("hello");
      //^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
      // [cfe] The method 'dMethod1' isn't defined for the class 'C<String>'.
      x.dMethod2(3);
      //^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
      // [cfe] The method 'dMethod2' isn't defined for the class 'C<String>'.

      var t0 = x.cMethod("hello");
      t0.length;
      t0.arglebargle; // t0 is not dynamic
      // ^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'arglebargle' isn't defined for the class 'String'.

      // y has type D<String, int>
      var t1 = y.dMethod1("hello");
      t1.length;
      t1.arglebargle; // t1 is not dynamic
      // ^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'arglebargle' isn't defined for the class 'String'.
      var t2 = y.dMethod2(3);
      t2.isEven;
      t2.arglebargle; // t2 is not dynamic
      // ^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'arglebargle' isn't defined for the class 'int'.
    }

    // Establish D<String, int> as a type of interest
    if (x is D<String, int>) {}
    // Inference uses C<String> as a downwards context, constraining S from
    // mkD<S,T> to String.  Upwards inference constrains T to int.  D<String,
    // int> is a type of interest so promotion should happen.
    {
      // y has the type of the RHS of the assignment
      var y = x = mkD(3);

      // x has type D<String, int>
      var t0 = x.dMethod1("hello");
      t0.length;
      t0.arglebargle; // t0 is not dynamic
      // ^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'arglebargle' isn't defined for the class 'String'.
      var t1 = x.dMethod2(3);
      t1.isEven;
      t1.arglebargle; // t1 is not dynamic
      // ^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'arglebargle' isn't defined for the class 'int'.

      // y has type D<String, int>
      var t2 = y.dMethod1("hello");
      t2.length;
      t2.arglebargle; // t2 is not dynamic
      // ^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'arglebargle' isn't defined for the class 'String'.
      var t3 = y.dMethod2(3);
      t3.isEven;
      t3.arglebargle; // t3 is not dynamic
      // ^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'arglebargle' isn't defined for the class 'int'.
    }

    // Inference should use D<String, int> as a downwards context, T from
    // useD<T> to int.  The variable x as an argument has type D<String, int>
    // which is assignable to D<String, int> so the call should have no error.
    // C<String> is a type of interest, so x should be demoted after the call.
    {
      // y has the type of the RHS of the assignment
      var y = x = useD(x);

      // x has type C<String>, and not D<String, int>
      x.dMethod1("hello");
      //^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
      // [cfe] The method 'dMethod1' isn't defined for the class 'C<String>'.
      x.dMethod2(3);
      //^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
      // [cfe] The method 'dMethod2' isn't defined for the class 'C<String>'.

      var t0 = x.cMethod("hello");
      t0.length;
      t0.arglebargle; // t0 is not dynamic
      // ^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'arglebargle' isn't defined for the class 'String'.

      // C<String>, and not D<String, int>
      y.dMethod1("hello");
      //^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
      // [cfe] The method 'dMethod1' isn't defined for the class 'C<String>'.
      y.dMethod2(3);
      //^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
      // [cfe] The method 'dMethod2' isn't defined for the class 'C<String>'.
      var t1 = y.cMethod("hello");
      t1.length;
      t1.arglebargle; // t0 is not dynamic
      // ^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'arglebargle' isn't defined for the class 'String'.
    }
  }
}
