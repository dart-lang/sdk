// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../lib/src/exit_codes.dart' as exit_codes;
import '../test_pub.dart';

/// Runs separate integration tests for "pub build", "pub serve", and
/// "pub build --format json" and validates that in all cases, it fails with
/// an expected error message and exits with [exitCode].
///
/// The integrations assume set up is already done, so you will likely want to
/// call [setUp] before this.
///
/// If [error] is provided, then both pub build and pub serve should exit with
/// that message. Otherwise, [buildError] is the expected error from pub build
/// and [serveError] from pub serve.
void pubBuildAndServeShouldFail(String description, {List<String> args,
    String error, String buildError, String serveError, int exitCode}) {

  if (error != null) {
    assert(buildError == null);
    buildError = error;

    assert(serveError == null);
    serveError = error;
  }

  // Usage errors also print the usage, so validate that.
  var buildExpectation = buildError;
  var serveExpectation = serveError;
  if (exitCode == exit_codes.USAGE) {
    buildExpectation =
        allOf(startsWith(buildExpectation), contains("Usage: pub build"));
    serveExpectation =
        allOf(startsWith(serveExpectation), contains("Usage: pub serve"));
  }

  integration("build fails $description", () {
    schedulePub(
        args: ["build"]..addAll(args),
        error: buildExpectation,
        exitCode: exitCode);
  });

  integration("build --format json fails $description", () {
    schedulePub(args: ["build", "--format", "json"]..addAll(args), outputJson: {
      "error": buildError // No usage in JSON output.
    }, exitCode: exitCode);
  });

  integration("serve fails $description", () {
    schedulePub(
        args: ["serve"]..addAll(args),
        error: serveExpectation,
        exitCode: exitCode);
  });
}
