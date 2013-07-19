// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.package_graph.transform_test;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../utils.dart';

main() {
  initConfig();
  test("gets a transformed asset with a different path", () {
    initGraph(["app|foo.blub"], {"app": [
      [new RewriteTransformer("blub", "blab")]
    ]});
    updateSources(["app|foo.blub"]);
    expectAsset("app|foo.blab", "foo.blab");
    buildShouldSucceed();
  });

  test("gets a transformed asset with the same path", () {
    initGraph(["app|foo.blub"], {"app": [
      [new RewriteTransformer("blub", "blub")]
    ]});
    updateSources(["app|foo.blub"]);
    expectAsset("app|foo.blub", "foo.blub");
    buildShouldSucceed();
  });

  test("doesn't find an output from a later phase", () {
    initGraph(["app|foo.a"], {"app": [
      [new RewriteTransformer("b", "c")],
      [new RewriteTransformer("a", "b")]
    ]});
    updateSources(["app|foo.a"]);
    expectNoAsset("app|foo.c");
    buildShouldSucceed();
  });

  test("doesn't find an output from the same phase", () {
    initGraph(["app|foo.a"], {"app": [
      [
        new RewriteTransformer("a", "b"),
        new RewriteTransformer("b", "c")
      ]
    ]});
    updateSources(["app|foo.a"]);
    expectAsset("app|foo.b", "foo.b");
    expectNoAsset("app|foo.c");
    buildShouldSucceed();
  });

  test("finds the latest output before the transformer's phase", () {
    initGraph(["app|foo.blub"], {"app": [
      [new RewriteTransformer("blub", "blub")],
      [
        new RewriteTransformer("blub", "blub"),
        new RewriteTransformer("blub", "done")
      ],
      [new RewriteTransformer("blub", "blub")]
    ]});
    updateSources(["app|foo.blub"]);
    expectAsset("app|foo.done", "foo.blub.done");
    buildShouldSucceed();
  });

  test("applies multiple transformations to an asset", () {
    initGraph(["app|foo.a"], {"app": [
      [new RewriteTransformer("a", "b")],
      [new RewriteTransformer("b", "c")],
      [new RewriteTransformer("c", "d")],
      [new RewriteTransformer("d", "e")],
      [new RewriteTransformer("e", "f")],
      [new RewriteTransformer("f", "g")],
      [new RewriteTransformer("g", "h")],
      [new RewriteTransformer("h", "i")],
      [new RewriteTransformer("i", "j")],
      [new RewriteTransformer("j", "k")],
    ]});
    updateSources(["app|foo.a"]);
    expectAsset("app|foo.k", "foo.b.c.d.e.f.g.h.i.j.k");
    buildShouldSucceed();
  });

  test("only runs a transform once for all of its outputs", () {
    var transformer = new RewriteTransformer("blub", "a b c");
    initGraph(["app|foo.blub"], {"app": [[transformer]]});
    updateSources(["app|foo.blub"]);
    expectAsset("app|foo.a", "foo.a");
    expectAsset("app|foo.b", "foo.b");
    expectAsset("app|foo.c", "foo.c");
    buildShouldSucceed();
    schedule(() {
      expect(transformer.numRuns, equals(1));
    });
  });

  test("runs transforms in the same phase in parallel", () {
    var transformerA = new RewriteTransformer("txt", "a");
    var transformerB = new RewriteTransformer("txt", "b");
    initGraph(["app|foo.txt"], {"app": [[transformerA, transformerB]]});

    transformerA.wait();
    transformerB.wait();

    schedule(() {
      updateSources(["app|foo.txt"]);

      // Wait for them both to start.
      return Future.wait([transformerA.started, transformerB.started]);
    });

    schedule(() {
      // They should both still be running.
      expect(transformerA.isRunning, isTrue);
      expect(transformerB.isRunning, isTrue);

      transformerA.complete();
      transformerB.complete();
    });

    expectAsset("app|foo.a", "foo.a");
    expectAsset("app|foo.b", "foo.b");
    buildShouldSucceed();
  });

  test("does not reapply transform when inputs are not modified", () {
    var transformer = new RewriteTransformer("blub", "blab");
    initGraph(["app|foo.blub"], {"app": [[transformer]]});
    updateSources(["app|foo.blub"]);
    expectAsset("app|foo.blab", "foo.blab");
    expectAsset("app|foo.blab", "foo.blab");
    expectAsset("app|foo.blab", "foo.blab");
    buildShouldSucceed();

    schedule(() {
      expect(transformer.numRuns, equals(1));
    });
  });

  test("reapplies a transform when its input is modified", () {
    var transformer = new RewriteTransformer("blub", "blab");
    initGraph(["app|foo.blub"], {"app": [[transformer]]});

    schedule(() {
      updateSources(["app|foo.blub"]);
    });

    expectAsset("app|foo.blab", "foo.blab");
    buildShouldSucceed();

    schedule(() {
      updateSources(["app|foo.blub"]);
    });

    expectAsset("app|foo.blab", "foo.blab");
    buildShouldSucceed();

    schedule(() {
      updateSources(["app|foo.blub"]);
    });

    expectAsset("app|foo.blab", "foo.blab");
    buildShouldSucceed();

    schedule(() {
      expect(transformer.numRuns, equals(3));
    });
  });

  test("does not reapply transform when a removed input is modified", () {
    var transformer = new ManyToOneTransformer("txt");
    initGraph({
      "app|a.txt": "a.inc,b.inc",
      "app|a.inc": "a",
      "app|b.inc": "b"
    }, {"app": [[transformer]]});

    updateSources(["app|a.txt", "app|a.inc", "app|b.inc"]);

    expectAsset("app|a.out", "ab");
    buildShouldSucceed();

    // Remove the dependency on the non-primary input.
    schedule(() {
      modifyAsset("app|a.txt", "a.inc");
      updateSources(["app|a.txt"]);
    });

    // Process it again.
    expectAsset("app|a.out", "a");
    buildShouldSucceed();

    // Now touch the removed input. It should not trigger another build.
    schedule(() {
      updateSources(["app|b.inc"]);
    });

    expectAsset("app|a.out", "a");
    buildShouldSucceed();

    schedule(() {
      expect(transformer.numRuns, equals(2));
    });
  });

  test("allows a transform to generate multiple outputs", () {
    initGraph({"app|foo.txt": "a.out,b.out"}, {"app": [
      [new OneToManyTransformer("txt")]
    ]});

    updateSources(["app|foo.txt"]);

    expectAsset("app|a.out", "spread txt");
    expectAsset("app|b.out", "spread txt");
    buildShouldSucceed();
  });

  test("does not rebuild transforms that don't use modified source", () {
    var a = new RewriteTransformer("a", "aa");
    var aa = new RewriteTransformer("aa", "aaa");
    var b = new RewriteTransformer("b", "bb");
    var bb = new RewriteTransformer("bb", "bbb");
    initGraph(["app|foo.a", "app|foo.b"], {"app": [
      [a, b],
      [aa, bb],
    ]});

    updateSources(["app|foo.a"]);
    updateSources(["app|foo.b"]);

    expectAsset("app|foo.aaa", "foo.aa.aaa");
    expectAsset("app|foo.bbb", "foo.bb.bbb");
    buildShouldSucceed();

    schedule(() {
      updateSources(["app|foo.a"]);
    });

    expectAsset("app|foo.aaa", "foo.aa.aaa");
    expectAsset("app|foo.bbb", "foo.bb.bbb");
    buildShouldSucceed();

    schedule(() {
      expect(aa.numRuns, equals(2));
      expect(bb.numRuns, equals(1));
    });
  });

  test("doesn't get an output from a transform whose primary input is removed",
      () {
    initGraph(["app|foo.txt"], {"app": [
      [new RewriteTransformer("txt", "out")]
    ]});

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.out", "foo.out");
    buildShouldSucceed();

    schedule(() {
      removeSources(["app|foo.txt"]);
    });

    expectNoAsset("app|foo.out");
    buildShouldSucceed();
  });

  test("reapplies a transform when a non-primary input changes", () {
   initGraph({
      "app|a.txt": "a.inc",
      "app|a.inc": "a"
    }, {"app": [[new ManyToOneTransformer("txt")]]});

    updateSources(["app|a.txt", "app|a.inc"]);
    expectAsset("app|a.out", "a");
    buildShouldSucceed();

    schedule(() {
      modifyAsset("app|a.inc", "after");
      updateSources(["app|a.inc"]);
    });

    expectAsset("app|a.out", "after");
    buildShouldSucceed();
  });

  test("restarts processing if a change occurs during processing", () {
    var transformer = new RewriteTransformer("txt", "out");
    initGraph(["app|foo.txt"], {"app": [[transformer]]});

    transformer.wait();

    schedule(() {
      updateSources(["app|foo.txt"]);

      // Wait for the transform to start.
      return transformer.started;
    });

    schedule(() {
      // Now update the graph during it.
      updateSources(["app|foo.txt"]);
    });

    schedule(() {
      transformer.complete();
    });

    expectAsset("app|foo.out", "foo.out");
    buildShouldSucceed();

    schedule(() {
      expect(transformer.numRuns, equals(2));
    });
  });

  test("handles an output moving from one transformer to another", () {
    // In the first run, "shared.out" is created by the "a.a" transformer.
    initGraph({
      "app|a.a": "a.out,shared.out",
      "app|b.b": "b.out"
    }, {"app": [
      [new OneToManyTransformer("a"), new OneToManyTransformer("b")]
    ]});

    updateSources(["app|a.a", "app|b.b"]);

    expectAsset("app|a.out", "spread a");
    expectAsset("app|b.out", "spread b");
    expectAsset("app|shared.out", "spread a");
    buildShouldSucceed();

    // Now switch their contents so that "shared.out" will be output by "b.b"'s
    // transformer.
    schedule(() {
      modifyAsset("app|a.a", "a.out");
      modifyAsset("app|b.b", "b.out,shared.out");
      updateSources(["app|a.a", "app|b.b"]);
    });

    expectAsset("app|a.out", "spread a");
    expectAsset("app|b.out", "spread b");
    expectAsset("app|shared.out", "spread b");
    buildShouldSucceed();
  });

  test("restarts before finishing later phases when a change occurs", () {
    var txtToInt = new RewriteTransformer("txt", "int");
    var intToOut = new RewriteTransformer("int", "out");
    initGraph(["app|foo.txt", "app|bar.txt"],
        {"app": [[txtToInt], [intToOut]]});

    txtToInt.wait();

    schedule(() {
      updateSources(["app|foo.txt"]);

      // Wait for the first transform to start.
      return txtToInt.started;
    });

    schedule(() {
      // Now update the graph during it.
      updateSources(["app|bar.txt"]);
    });

    schedule(() {
      txtToInt.complete();
    });

    expectAsset("app|foo.out", "foo.int.out");
    expectAsset("app|bar.out", "bar.int.out");
    buildShouldSucceed();

    schedule(() {
      // Should only have run each transform once for each primary.
      expect(txtToInt.numRuns, equals(2));
      expect(intToOut.numRuns, equals(2));
    });
  });

  test("applies transforms to the correct packages", () {
    var rewrite1 = new RewriteTransformer("txt", "out1");
    var rewrite2 = new RewriteTransformer("txt", "out2");
    initGraph([
      "pkg1|foo.txt",
      "pkg2|foo.txt"
    ], {"pkg1": [[rewrite1]], "pkg2": [[rewrite2]]});

    updateSources(["pkg1|foo.txt", "pkg2|foo.txt"]);
    expectAsset("pkg1|foo.out1", "foo.out1");
    expectAsset("pkg2|foo.out2", "foo.out2");
    buildShouldSucceed();
  });

  test("transforms don't see generated assets in other packages", () {
    var fooToBar = new RewriteTransformer("foo", "bar");
    var barToBaz = new RewriteTransformer("bar", "baz");
    initGraph(["pkg1|file.foo"], {"pkg1": [[fooToBar]], "pkg2": [[barToBaz]]});

    updateSources(["pkg1|file.foo"]);
    expectAsset("pkg1|file.bar", "file.bar");
    expectNoAsset("pkg2|file.baz");
    buildShouldSucceed();
  });

  test("doesn't emit a result until all builds are finished", () {
    var rewrite = new RewriteTransformer("txt", "out");
    initGraph([
      "pkg1|foo.txt",
      "pkg2|foo.txt"
    ], {"pkg1": [[rewrite]], "pkg2": [[rewrite]]});

    // First, run both packages' transformers so both packages are successful.
    updateSources(["pkg1|foo.txt", "pkg2|foo.txt"]);
    expectAsset("pkg1|foo.out", "foo.out");
    expectAsset("pkg2|foo.out", "foo.out");
    buildShouldSucceed();

    // pkg1 is still successful, but pkg2 is waiting on the provider, so the
    // overall build shouldn't finish.
    pauseProvider();
    schedule(() => updateSources(["pkg2|foo.txt"]));
    expectAsset("pkg1|foo.out", "foo.out");
    buildShouldNotBeDone();

    // Now that the provider is unpaused, pkg2's transforms finish and the
    // overall build succeeds.
    resumeProvider();
    buildShouldSucceed();
  });
}
