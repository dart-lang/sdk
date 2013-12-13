// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.package_graph.transform_test;

import 'package:barback/src/utils.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../utils.dart';

main() {
  initConfig();

  test("handles many parallel transformers", () {
    currentSchedule.timeout *= 3;
    var files = new List.generate(100, (i) => "app|$i.txt");
    var rewrite = new RewriteTransformer("txt", "out");
    initGraph(files, {"app": [[rewrite]]});

    // Pause and resume apply to simulate parallel long-running transformers.
    rewrite.pauseApply();
    updateSources(files);
    schedule(pumpEventQueue);
    rewrite.resumeApply();

    for (var i = 0; i < 100; i++) {
      expectAsset("app|$i.out", "$i.out");
    }
    buildShouldSucceed();
  });
}
