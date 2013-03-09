// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  final x = '';
}

main() {
  Expect.equals('', new Bar().x);
  Expect.equals('', const Bar().x);
}
