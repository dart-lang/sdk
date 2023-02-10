// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library frontend_server;

import 'dart:async';
import 'dart:io';

import 'package:frontend_server/starter.dart';

Future<void> main(List<String> args) async {
  exitCode = await starter(args);
  if (exitCode != 0) {
    exit(exitCode);
  }
}
