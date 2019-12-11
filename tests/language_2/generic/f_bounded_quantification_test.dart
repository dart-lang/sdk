// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for F-Bounded Quantification.

class FBound<F extends FBound<F>> {}

class Bar extends FBound<Bar> {}

class SubBar extends Bar {}

class Baz<T> extends FBound<Baz<T>> {}

class SubBaz<T> extends Baz<T> {}

main() {
  FBound<Bar> fb = new FBound<Bar>();
  FBound<SubBar> fsb = new FBound<SubBar>();
  //     ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  //             ^
  // [cfe] Type argument 'SubBar' doesn't conform to the bound 'FBound<F>' of the type variable 'F' on 'FBound'.
  //                       ^
  // [cfe] Type argument 'SubBar' doesn't conform to the bound 'FBound<F>' of the type variable 'F' on 'FBound'.
  //                              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

  FBound<Baz<Bar>> fbb = new FBound<Baz<Bar>>();
  FBound<SubBaz<Bar>> fsbb = new FBound<SubBaz<Bar>>();
  //     ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  //                  ^
  // [cfe] Type argument 'SubBaz<Bar>' doesn't conform to the bound 'FBound<F>' of the type variable 'F' on 'FBound'.
  //                             ^
  // [cfe] Type argument 'SubBaz<Bar>' doesn't conform to the bound 'FBound<F>' of the type variable 'F' on 'FBound'.
  //                                    ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
}
