// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_js_helper";
import "package:expect/expect.dart";

abstract class Window {
  final int document;
}

// Defining this global object makes Frog eager on optimizing
// call sites where the receiver is typed 'Window'.
@Native("@*DOMWindow")
class _DOMWindowJs implements Window {
  final int document;
}

class Win implements Window {
}

main() {
  // By not typing the variable, Frog does not try to optimize calls
  // on it.
  var win = new Win();
  Expect.throws(() => win.document,
                (e) => e is NoSuchMethodError);
}
