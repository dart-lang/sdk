// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  test(1);
  /*1:main*/ test(null);
  test(2);
}

@pragma('dart2js:never-inline')
test(c) {
  doSomething();
  c /*2:test*/ !;
  doSomething();
}

@pragma('dart2js:never-inline')
doSomething() {}
