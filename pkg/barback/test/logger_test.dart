// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.logger_test;

import 'package:barback/barback.dart';
import 'package:scheduled_test/scheduled_test.dart';

import 'utils.dart';
import 'transformer/log.dart';

main() {
  initConfig();

  test("logs messages from a transformer", () {
    var transformer = new LogTransformer([
      "error: This is an error.",
      "warning: This is a warning.",
      "info: This is info.",
      "fine: This is fine."
    ]);
    initGraph(["app|foo.txt"], {
      "app": [[transformer]]
    });

    updateSources(["app|foo.txt"]);
    buildShouldLog(LogLevel.ERROR, equals("This is an error."));
    buildShouldLog(LogLevel.WARNING, equals("This is a warning."));
    buildShouldLog(LogLevel.INFO, equals("This is info."));
    buildShouldLog(LogLevel.FINE, equals("This is fine."));
  });

  test("logs messages from a transformer group", () {
    var transformer = new LogTransformer([
      "error: This is an error.",
      "warning: This is a warning.",
      "info: This is info.",
      "fine: This is fine."
    ]);

    initGraph(["app|foo.txt"], {"app": [
      [new TransformerGroup([[transformer]])]
    ]});

    updateSources(["app|foo.txt"]);
    buildShouldLog(LogLevel.ERROR, equals("This is an error."));
    buildShouldLog(LogLevel.WARNING, equals("This is a warning."));
    buildShouldLog(LogLevel.INFO, equals("This is info."));
    buildShouldLog(LogLevel.FINE, equals("This is fine."));
  });
}
