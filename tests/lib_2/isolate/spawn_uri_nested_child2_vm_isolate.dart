// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Child isolate code to be spawned from a URI to this file.
library NestedSpawnUriChild2Library;

import 'dart:isolate';

void main(List<String> args, SendPort replyTo) {
  var data = args[0];
  replyTo.send('re: $data');
}
