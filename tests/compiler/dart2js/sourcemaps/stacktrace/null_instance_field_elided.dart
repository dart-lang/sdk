// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  /*1:main*/ test(new Class());
}

@pragma('dart2js:noInline')
test(c) {
  c.field. /*2:test*/ method();
}

class Class {
  var field;
}
