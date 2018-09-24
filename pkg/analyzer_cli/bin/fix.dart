#!/usr/bin/env dart
// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_cli/src/fix/driver.dart';

/// The entry point for dartfix.
main(List<String> args) async {
  Driver starter = new Driver();

  // Wait for the starter to complete.
  await starter.start(args);
}
