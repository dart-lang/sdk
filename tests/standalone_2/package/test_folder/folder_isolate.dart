// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library folder_isolate;

// This is a package that's not available to the main isolate
import 'package:folder_lib.dart' as isolate_package;
import 'dart:isolate';

// This file is spawned from package_isolate_test.dart
main(List<String> args, Sendport replyTo) {
  isolate_package.count = 1;
  replyTo.send('isolate');
}
