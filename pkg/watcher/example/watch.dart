// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Watches the given directory and prints each modification to it.
library watch;

import 'dart:io';

import 'package:pathos/path.dart' as pathos;
import 'package:watcher/watcher.dart';

main() {
  var args = new Options().arguments;
  if (args.length != 1) {
    print("Usage: watch <directory path>");
    return;
  }

  var watcher = new DirectoryWatcher(pathos.absolute(args[0]));
  watcher.events.listen((event) {
    print(event);
  });
}