#!/usr/bin/env dart
// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dartfix/src/driver.dart';

/// The entry point for dartfix.
void main(List<String> args) async {
  Driver starter = Driver();

  // Wait for the starter to complete.
  await starter.start(args);
}
