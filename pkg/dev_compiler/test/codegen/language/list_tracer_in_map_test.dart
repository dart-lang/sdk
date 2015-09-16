// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js, whose type inferrer used to not see
// literal maps as places where a list could escape.

var b = [42];
var a = {'foo': b};

main() {
  a['foo'].clear();
  if (b.length != 0) throw 'Test failed';
}
