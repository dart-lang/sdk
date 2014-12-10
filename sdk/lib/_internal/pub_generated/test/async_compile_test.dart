// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_process.dart';

import 'test_pub.dart';
import '../lib/src/io.dart';

void main() {
  integration("the generated pub source is up to date", () {
    var compilerArgs = Platform.executableArguments.toList()..addAll(
        [
            p.join(pubRoot, 'bin', 'async_compile.dart'),
            '--force',
            '--verbose',
            p.join(sandboxDir, "pub_generated")]);

    new ScheduledProcess.start(Platform.executable, compilerArgs).shouldExit(0);

    new d.DirectoryDescriptor.fromFilesystem(
        "pub_generated",
        p.join(pubRoot, "..", "pub_generated")).validate();
  });
}
