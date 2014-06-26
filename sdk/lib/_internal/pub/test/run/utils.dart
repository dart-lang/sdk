// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_process.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../test_pub.dart';

/// Schedules starting the "pub run" process and validates the expected startup
/// output.
///
/// if [transformers] is given, it should contain a list of transformer IDs
/// (like "myapp/src/transformer") and this will validate that the output for
/// loading those is shown.
///
/// Returns the `pub run` process.
ScheduledProcess pubRun({Iterable<String> args,
  Iterable<String> transformers}) {
  var pub = startPub(args: ["run"]..addAll(args));

  // This isn't normally printed, but the pub test infrastructure runs pub in
  // verbose mode, which enables this.
  pub.stdout.expect(startsWith("Loading source assets"));

  if (transformers != null) {
    for (var transformer in transformers) {
      pub.stdout.expect(startsWith("Loading $transformer transformers"));
    }
  }
  return pub;
}
