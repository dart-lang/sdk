// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

f() {
  var a = 0;
  var b = null;
  var c = throw 'foo';
  var d = () => 0;
  var e = () => null;
  var f = () => throw 'foo';
  var g = () {
    return 0;
  };
  var h = () {
    return null;
  };
  var i = () {
    return (throw 'foo');
  };
}

main() {}
