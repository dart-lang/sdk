// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

import 'package:dartdev/dartdev.dart';
import 'package:pub/src/http.dart';

/// The entry point for dartdev.
Future<void> main(List<String> args, SendPort? port) async {
  try {
    await runDartdev(args, port);
  } finally {
    // TODO(https://github.com/dart-lang/pub/issues/4209). Handle this in a more
    // structured way.
    globalHttpClient.close();
  }
}
