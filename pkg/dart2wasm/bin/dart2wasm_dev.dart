// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart2wasm/dev/compile.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('Usage: dart2wasm_dev.dart <output.wasm>');
    exit(64);
  }
  File(args.single).writeAsBytesSync(compile());
}
