// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.package_graph.transform.pass_through_test;

import 'package:barback/src/utils.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../../utils.dart';

main() {
  initConfig();
  test("can access other packages' source assets", () {
    initGraph({
      "pkg1|a.txt": "pkg2|a.inc",
      "pkg2|a.inc": "a"
    }, {"pkg1": [[new ManyToOneTransformer("txt")]]});

    updateSources(["pkg1|a.txt", "pkg2|a.inc"]);
    expectAsset("pkg1|a.out", "a");
    buildShouldSucceed();
  });

  test("can access other packages' transformed assets", () {
    initGraph({
      "pkg1|a.txt": "pkg2|a.inc",
      "pkg2|a.txt": "a"
    }, {
      "pkg1": [[new ManyToOneTransformer("txt")]],
      "pkg2": [[new RewriteTransformer("txt", "inc")]]
    });

    updateSources(["pkg1|a.txt", "pkg2|a.txt"]);
    expectAsset("pkg1|a.out", "a.inc");
    buildShouldSucceed();
  });

  test("re-runs a transform when an input from another package changes", () {
    initGraph({
      "pkg1|a.txt": "pkg2|a.inc",
      "pkg2|a.inc": "a"
    }, {
      "pkg1": [[new ManyToOneTransformer("txt")]]
    });

    updateSources(["pkg1|a.txt", "pkg2|a.inc"]);
    expectAsset("pkg1|a.out", "a");
    buildShouldSucceed();

    modifyAsset("pkg2|a.inc", "new a");
    updateSources(["pkg2|a.inc"]);
    expectAsset("pkg1|a.out", "new a");
    buildShouldSucceed();
  });

  test("re-runs a transform when a transformed input from another package "
      "changes", () {
    initGraph({
      "pkg1|a.txt": "pkg2|a.inc",
      "pkg2|a.txt": "a"
    }, {
      "pkg1": [[new ManyToOneTransformer("txt")]],
      "pkg2": [[new RewriteTransformer("txt", "inc")]]
    });

    updateSources(["pkg1|a.txt", "pkg2|a.txt"]);
    expectAsset("pkg1|a.out", "a.inc");
    buildShouldSucceed();

    modifyAsset("pkg2|a.txt", "new a");
    updateSources(["pkg2|a.txt"]);
    expectAsset("pkg1|a.out", "new a.inc");
    buildShouldSucceed();
  });

  test("doesn't complete the build until all packages' transforms are "
      "finished running", () {
    var transformer = new ManyToOneTransformer("txt");
    initGraph({
      "pkg1|a.txt": "pkg2|a.inc",
      "pkg2|a.inc": "a"
    }, {
      "pkg1": [[transformer]]
    });

    updateSources(["pkg1|a.txt", "pkg2|a.inc"]);
    expectAsset("pkg1|a.out", "a");
    buildShouldSucceed();

    transformer.pauseApply();
    modifyAsset("pkg2|a.inc", "new a");
    updateSources(["pkg2|a.inc"]);
    buildShouldNotBeDone();

    transformer.resumeApply();
    buildShouldSucceed();
  });

  test("runs a transform that's added because of a change in another package",
      () {
    initGraph({
      "pkg1|a.txt": "pkg2|a.inc",
      "pkg2|a.inc": "b"
    }, {
      "pkg1": [
        [new ManyToOneTransformer("txt")],
        [new OneToManyTransformer("out")],
        [new RewriteTransformer("md", "done")]
      ],
    });

    // pkg1|a.txt generates outputs based on the contents of pkg2|a.inc. At
    // first pkg2|a.inc only includes "b", which is not transformed. Then
    // pkg2|a.inc is updated to include "b,c.md". pkg1|c.md triggers the
    // md->done rewrite transformer, producing pkg1|c.done.

    updateSources(["pkg1|a.txt", "pkg2|a.inc"]);
    expectAsset("pkg1|b", "spread out");
    buildShouldSucceed();

    modifyAsset("pkg2|a.inc", "b,c.md");
    updateSources(["pkg2|a.inc"]);
    expectAsset("pkg1|b", "spread out");
    expectAsset("pkg1|c.done", "spread out.done");
    buildShouldSucceed();
  });

  test("doesn't run a transform that's removed because of a change in "
      "another package", () {
    initGraph({
      "pkg1|a.txt": "pkg2|a.inc",
      "pkg2|a.inc": "b,c.md"
    }, {
      "pkg1": [
        [new ManyToOneTransformer("txt")],
        [new OneToManyTransformer("out")],
        [new RewriteTransformer("md", "done")]
      ],
    });

    updateSources(["pkg1|a.txt", "pkg2|a.inc"]);
    expectAsset("pkg1|b", "spread out");
    expectAsset("pkg1|c.done", "spread out.done");
    buildShouldSucceed();

    modifyAsset("pkg2|a.inc", "b");
    updateSources(["pkg2|a.inc"]);
    expectAsset("pkg1|b", "spread out");
    expectNoAsset("pkg1|c.done");
    buildShouldSucceed();
  });

  test("sees a transformer that's newly applied to a cross-package "
      "dependency", () {
    initGraph({
      "pkg1|a.txt": "pkg2|a.inc",
      "pkg2|a.inc": "a"
    }, {
      "pkg1": [[new ManyToOneTransformer("txt")]],
      "pkg2": [[new CheckContentTransformer("b", " transformed")]]
    });

    updateSources(["pkg1|a.txt", "pkg2|a.inc"]);
    expectAsset("pkg1|a.out", "a");
    buildShouldSucceed();

    modifyAsset("pkg2|a.inc", "b");
    updateSources(["pkg2|a.inc"]);
    expectAsset("pkg1|a.out", "b transformed");
    buildShouldSucceed();
  });

  test("doesn't see a transformer that's newly not applied to a "
      "cross-package dependency", () {
    initGraph({
      "pkg1|a.txt": "pkg2|a.inc",
      "pkg2|a.inc": "a"
    }, {
      "pkg1": [[new ManyToOneTransformer("txt")]],
      "pkg2": [[new CheckContentTransformer("a", " transformed")]]
    });

    updateSources(["pkg1|a.txt", "pkg2|a.inc"]);
    expectAsset("pkg1|a.out", "a transformed");
    buildShouldSucceed();

    modifyAsset("pkg2|a.inc", "b");
    updateSources(["pkg2|a.inc"]);
    expectAsset("pkg1|a.out", "b");
    buildShouldSucceed();
  });

  test("re-runs if the primary input is invalidated before accessing", () {
    var transformer1 = new RewriteTransformer("txt", "mid");
    var transformer2 = new RewriteTransformer("mid", "out");

    initGraph([
      "app|foo.txt"
    ], {"app": [
      [transformer1],
      [transformer2]
    ]});

    transformer2.pausePrimaryInput();
    updateSources(["app|foo.txt"]);

    // Wait long enough to ensure that transformer1 has completed and
    // transformer2 has started.
    schedule(pumpEventQueue);

    // Update the source again so that transformer1 invalidates the primary
    // input of transformer2.
    transformer1.pauseApply();
    updateSources(["app|foo.txt"]);

    transformer2.resumePrimaryInput();
    transformer1.resumeApply();

    expectAsset("app|foo.out", "foo.mid.out");
    buildShouldSucceed();

    expect(transformer1.numRuns, completion(equals(2)));
    expect(transformer2.numRuns, completion(equals(2)));
  });
}