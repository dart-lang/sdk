
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sibling_isolate;

import 'package:shared.dart'as shared;
import 'dart:isolate';

// This file is spawned from package_isolate_test.dart
main(List<String args>, SendPort reply) {
  shared.output = 'isolate';
  reply.send(shared.output);
}
