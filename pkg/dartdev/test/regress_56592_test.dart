// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:expect/expect.dart';

// Passing --disable-dart-dev after a DartDev command should cause the VM to
// exit with an error, not cause a segfault.
//
// See https://github.com/dart-lang/sdk/issues/56592 for details.

Future<void> main() async {
  final result = await Process.run(
    Platform.resolvedExecutable,
    [
      'test',
      '--disable-dart-dev',
    ],
  );
  Expect.contains(
    'Attempted to use --disable-dart-dev with a Dart CLI command.',
    result.stderr,
  );
}
