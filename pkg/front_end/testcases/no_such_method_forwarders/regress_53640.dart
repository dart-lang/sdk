// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  int m();
  dynamic noSuchMethod(Invocation i) => "C";
}

mixin M {
  int m();
  dynamic noSuchMethod(Invocation i) => "M";
}

class MA = Object with M;

throws(void Function() f) {
  try {
    f();
  } on TypeError catch (e) {
    print(e);
    return;
  }
  throw 'Missing TypeError';
}

main() {
  // Unhandled exception: type 'String' is not a subtype of type 'int'
  throws(() => C().m());
  throws(() => MA().m());
}
