// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dds/src/dds_cli_entrypoint.dart';

Future<void> main(List<String> args) async {
  // This level of indirection is only here so DDS can be configured for
  // google3 specific functionality as it's not possible to import files under
  // a package's bin directory to wrap the entrypoint.
  await runDartDevelopmentServiceFromCLI(args);
}
