// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

var v;

main(arguments) {
  var w;
  ((x) => v = w = x)(87);
  if (v != 87) {
    throw "Unexpected value in v: $v";
  }
  if (w != 87) {
    throw "Unexpected value in w: $w";
  }
  v = true;
  (() {
    for (; w = v;) {
      v = false;
    }
  })();
  if (v != false) {
    throw "Unexpected value in v: $v";
  }
  if (w != false) {
    throw "Unexpected value in w: $w";
  }
}
