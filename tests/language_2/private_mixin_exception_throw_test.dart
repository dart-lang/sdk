// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/11637

class _C {}

class _E {
  throwIt() => throw "it";
}

class _F {
  throwIt() => throw "IT";
}

class _D extends _C with _E, _F {}

main() {
  var d = new _D();
  try {
    d.throwIt();
  } catch (e, s) {
    print("Exception: $e");
    print("Stacktrace:\n$s");
  }
}
