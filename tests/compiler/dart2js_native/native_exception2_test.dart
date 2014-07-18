// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Similar to native_exception_test.dart but also defines a native
// class.  This exercises a different code path in emitter.dart.

library native_exception2_test;

import 'native_exception_test.dart' as other;
import 'dart:_js_helper';

@Native("NativeClass")
class NativeClass {
}

makeNativeClass() native;

setup() native """
function NativeClass() {}
makeNativeClass = function() { return new NativeClass; }
""";

main() {
  setup();
  other.main();
}
