// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_runtime_service_dds/src/dds_cli_entrypoint.dart';

/// Command-line entrypoint for the Dart Development Service (DDS).
Future<void> main(List<String> args) async {
  await runDartDevelopmentServiceFromCLI(args);
}
