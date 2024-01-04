// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart2wasm/dart2wasm.dart' as dart2wasm;

Future<void> main(List<String> args) async {
  exitCode = await dart2wasm.main(args);
}
