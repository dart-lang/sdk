// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

/*@testedFeatures=inference*/
library test;

var /*@topType=dynamic*/ a = null;

main() {
  var /*@type=dynamic*/ b = null;
}
