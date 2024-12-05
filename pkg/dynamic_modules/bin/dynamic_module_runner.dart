// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dynamic_modules/dynamic_modules.dart' show loadModuleFromBytes;

main(List<String> args) {
  final bytes = File(args[0]).readAsBytesSync();
  return loadModuleFromBytes(bytes);
}
