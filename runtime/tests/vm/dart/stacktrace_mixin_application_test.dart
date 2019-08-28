// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import "package:expect/expect.dart";

mixin Bar {
  bar() => throw "bar";
}

mixin Baz {}

class Foo with Baz, Bar {}

main() {
  final foo = Foo();
  try {
    foo.bar();
  } catch (e, st) {
    final stack = st.toString();
    // Check that stack frames for methods defined in a mixin Bar actually show
    // only the mixin name rather than some combination of the name of the class
    // that mixed in Bar along with other mixin names.
    //
    // Prior to the fix for issue #36999, this frame would have been named
    // Foo&Baz&Bar.bar rather than simply Bar.bar.
    Expect.isTrue(stack.contains('#0      Bar.bar'));
  }
}
