#!/usr/bin/env dart
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_cli/starter.dart';

/// The entry point for the command-line analyzer.
main(List<String> args) async {
  CommandLineStarter starter = new CommandLineStarter();

  // Wait for the starter to complete.
  await starter.start(args);
}
