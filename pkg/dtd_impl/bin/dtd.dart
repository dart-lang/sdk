// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

import 'package:dtd_impl/dtd.dart';

/// Starts the Dart Tooling Daemon with a list of arguments and a nullable
/// Object [port], which will be cast as a [SendPort?] object.
///
/// When [port] is non-null, the [DartToolingDaemon.startService] method will
/// send information about the DTD connection back over [port] instead of
/// printing it to stdout.
void main(List<String> args, dynamic port) async {
  await DartToolingDaemon.startService(
    args,
    sendPort: port as SendPort?,
  );
}
