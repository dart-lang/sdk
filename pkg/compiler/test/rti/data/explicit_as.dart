// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*spec.class: C:direct,explicit=[C.T*,C<String*>*],needsArgs*/
class C<T> {
  T field;
}

main() {
  explicitAs(new C<String>());
}

explicitAs(C<String> i) {
  // ignore: unnecessary_cast
  return i as C<String>;
}
