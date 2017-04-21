// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test ensuring that compiler can parse metadata. Need to add negative
// test cases with illegal metadata annotations.

library metadata_test.dart;

import "package:expect/expect.dart";
import "metadata_lib.dart" as Meta;

class Tag {
  final String annotation;
  const Tag(this.annotation);
}

const meta1 = 1;
const meta2 = const Tag("meta2");

const extern = const Tag("external");

@meta1
var topLevelVar;
@Meta.Alien.unspecified()
List unknownUnknowns;

@meta1
typedef int DingDong<@meta2 T>(@meta1 event);

@meta1
class A<@Tag("typeParam") T> {
  @meta1
  @meta2
  static String staticField;

  @Meta.Alien("ET")
  int foo(@meta1 bool fool, {@meta1 @Tag("opt") x: 100}) {
    g() => 10;
    return x * g();
  }

  @Tag(r"timewarp")
  List<int> getNextWeeksLottoNumbers() => [1, 2, 3, 4, 5, 6];
}

@meta1
main() {
  @meta1
  var a = new A();
  Expect.equals(0, a.foo(false, x: 0));

  for (@Tag("loopvar")
  int i = 0;
      i < 10;
      i++) {
    // Do something.
  }

  @meta1
  var s = r'This is a raw \\ string.';
}
