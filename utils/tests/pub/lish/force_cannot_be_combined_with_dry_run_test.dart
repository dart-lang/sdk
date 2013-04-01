// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:json' as json;

import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_server.dart';

import '../../../pub/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  setUp(d.validPackage.create);

  integration('--force cannot be combined with --dry-run', () {
    schedulePub(args: ['lish', '--force', '--dry-run'],
        error: "Cannot use both --force and --dry-run.",
        exitCode: exit_codes.USAGE);
  });
}
