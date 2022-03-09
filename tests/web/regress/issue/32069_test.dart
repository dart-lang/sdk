// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  var m1 = {
    'hello': <String>['hi', 'howdy'],
    'bye': <String>[]
  };
  var m = new Map<String, List<String>>.unmodifiable(m1);
  print(m);
  Expect.isTrue(m is Map<String, List<String>>);
  Expect.isFalse(m is Map<List<String>, String>);
}
