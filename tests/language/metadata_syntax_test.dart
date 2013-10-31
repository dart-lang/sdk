// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that is is an error to use type arguments in metadata without
// parens.

@Bar()
@List<String> /// 01: compile-time error
class Bar {
  @Bar()
  @List<String> /// 02: compile-time error
  const Bar();

  @Bar()
  @List<String> /// 03: compile-time error
  final x = 'x';

  @unknown /// 04: compile-time error
  final y = 'y';

  @Bar /// 05: compile-time error
  final z = 'z';

  @1234 /// 06: compile-time error
  final w = 'w';
}

main() {
  Expect.equals('x', new Bar().x);
  Expect.equals('x', const Bar().x);
  Expect.equals('y', new Bar().y);
  Expect.equals('y', const Bar().y);
  Expect.equals('z', new Bar().z);
  Expect.equals('z', const Bar().z);
  Expect.equals('z', new Bar().z);
  Expect.equals('z', const Bar().z);
  Expect.equals('w', new Bar().w);
  Expect.equals('w', const Bar().w);
}
