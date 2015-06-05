// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domtest;

import 'sunflower/dom.dart';

// https://github.com/dart-lang/dev_compiler/issues/173
testNativeIndexers() {
  var nodes = document.querySelector('body').childNodes;
  for (int i = 0; i < nodes.length; i++) {
    var old = nodes[i];
    nodes[i] = document.createElement('div');
    print(nodes[i] == old);
  }
}
