// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: C:checkedInstance,checks=[],instance*/
class C<T> {}

@pragma('dart2js:noInline')
test(o) => o is C<String>;

main() {
  test(new C<String>());
  test(new C<int>());
}
