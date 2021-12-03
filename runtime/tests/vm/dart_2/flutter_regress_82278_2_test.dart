// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:expect/expect.dart';

dynamic global;

class Foo<T0, T1, T2, T3, T4, T5, T6, T7, T8, T9,
          T10, T11, T12, T13, T14, T15, T16, T17, T18, T19,
          T20, T21, T22, T23, T24, T25, T26, T27, T28, T29,
          T30, T31> {
  @pragma('vm:never-inline')
  Generic<T31> testForT31(dynamic arg) {
    global = '''$T0 $T1 $T2 $T3 $T4 $T5 $T6 $T7 $T8 $T9
            $T10 $T11 $T12 $T13 $T14 $T15 $T16 $T17 $T18 $T19
            $T20 $T21 $T22 $T23 $T24 $T25 $T26 $T27 $T28 $T29
            $T30 $T31''';
    return arg as Generic<T31>;
  }

}

@pragma('vm:never-inline')
Generic<T31> foo<T0, T1, T2, T3, T4, T5, T6, T7, T8, T9,
                 T10, T11, T12, T13, T14, T15, T16, T17, T18, T19,
                 T20, T21, T22, T23, T24, T25, T26, T27, T28, T29,
                 T30, T31>(dynamic arg) {
  global = '''$T0 $T1 $T2 $T3 $T4 $T5 $T6 $T7 $T8 $T9
          $T10 $T11 $T12 $T13 $T14 $T15 $T16 $T17 $T18 $T19
          $T20 $T21 $T22 $T23 $T24 $T25 $T26 $T27 $T28 $T29
          $T30 $T31''';
 return arg as Generic<T31>;
}

class Generic<T> {}

main() {
  final genericString = Generic<String>();
  Expect.isTrue(identical(Foo<bool, bool, bool, bool, bool, bool, bool, bool, bool, bool,
              bool, bool, bool, bool, bool, bool, bool, bool, bool, bool,
              bool, bool, bool, bool, bool, bool, bool, bool, bool, bool,
              bool, String>().testForT31(genericString), genericString));
  Expect.isTrue((global as String).endsWith('bool String'));

  Expect.isTrue(identical(
    foo<int, int, int, int, int, int, int, int, int, int,
              int, int, int, int, int, int, int, int, int, int,
              int, int, int, int, int, int, int, int, int, int,
              int, String>(genericString), genericString));
  Expect.isTrue((global as String).endsWith('int String'));
}
