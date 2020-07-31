// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that const/new-insertion does the right thing for default values.
// A default-value expression does not introduce a const context.

main() {
  foo();
  bar();
  baz();
  qux();
  C.foo();
  C.bar();
  new C().baz();
  new C().qux();
  new C.pos();
  new C.nam();
  const C.pos();
  const C.nam();
}

// Default arguments must be const to be accepted
foo([x //
  = const [C()] //     //# o1: ok
  = const {42: C()} // //# o2: ok
  = const C(C()) //    //# o3: ok
  = [42] //            //# e1: compile-time error
  = {42: 42} //        //# e2: compile-time error
  = C([]) //           //# e3: compile-time error
  ]) {
}

bar({x //
  = const [C()] //     //# o4: ok
  = const {42: C()} // //# o5: ok
  = const C(C()) //    //# o6: ok
  = [42] //            //# e4: compile-time error
  = {42: 42} //        //# e5: compile-time error
  = C([]) //           //# e6: compile-time error
  }) {
}

var baz = ([x
  = const [C()] //     //# o7: ok
  = const {42: C()} // //# o8: ok
  = const C(C()) //    //# o9: ok
  = [42] //            //# e7: compile-time error
  = {42: 42} //        //# e8: compile-time error
  = C([]) //           //# e9: compile-time error
]) => 42;

var qux = ({x
  = const [C()] //     //# o10: ok
  = const {42: C()} // //# o11: ok
  = const C(C()) //    //# o12: ok
  = [42] //            //# e10: compile-time error
  = {42: 42} //        //# e11: compile-time error
  = C([]) //           //# e12: compile-time error
}) => 42;

class C {
  final x;
  const C([this.x]);

  const C.pos([this.x //
    = const [C()] //     //# o13: ok
    = const {42: C()} // //# o14: ok
    = const C(C()) //    //# o15: ok
    = [42] //            //# e13: compile-time error
    = {42: 42} //        //# e14: compile-time error
    = C([]) //           //# e15: compile-time error
  ]);

  const C.nam({this.x //
    = const [C()] //     //# o16: ok
    = const {42: C()} // //# o17: ok
    = const C(C()) //    //# o18: ok
    = [42] //            //# e16: compile-time error
    = {42: 42} //        //# e17: compile-time error
    = C([]) //           //# e18: compile-time error
  });

  static foo([x //
    = const [C()] //     //# o19: ok
    = const {42: C()} // //# o20: ok
    = const C(C()) //    //# o21: ok
    = [42] //            //# e19: compile-time error
    = {42: 42} //        //# e20: compile-time error
    = C([]) //           //# e21: compile-time error
    ]) {
  }

  static bar({x //
    = const [C()] //     //# o22: ok
    = const {42: C()} // //# o23: ok
    = const C(C()) //    //# o24: ok
    = [42] //            //# e22: compile-time error
    = {42: 42} //        //# e23: compile-time error
    = C([]) //           //# e24: compile-time error
    }) {
  }

  baz([x //
    = const [C()] //     //# o25: ok
    = const {42: C()} // //# o26: ok
    = const C(C()) //    //# o27: ok
    = [42] //            //# e25: compile-time error
    = {42: 42} //        //# e26: compile-time error
    = C([]) //           //# e27: compile-time error
    ]) {
  }

  qux({x //
    = const [C()] //     //# o28: ok
    = const {42: C()} // //# o29: ok
    = const C(C()) //    //# o30: ok
    = [42] //            //# e28: compile-time error
    = {42: 42} //        //# e29: compile-time error
    = C([]) //           //# e30: compile-time error
    }) {
  }
}
