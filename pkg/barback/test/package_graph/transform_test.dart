// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.package_graph.transform_test;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:barback/src/utils.dart';
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

    transformerA.pauseApply();
    transformerB.pauseApply();

    schedule(() {
      updateSources(["app|foo.txt"]);

      // Wait for them both to start.
      return Future.wait([transformerA.started, transformerB.started]);
    });

    schedule(() {
      // They should both still be running.
      expect(transformerA.isRunning, isTrue);
      expect(transformerB.isRunning, isTrue);

      transformerA.resumeApply();
      transformerB.resumeApply();
    });

    expectAsset("app|foo.a", "foo.a");
    expectAsset("app|foo.b", "foo.b");
    buildShouldSucceed();
  });

  test("outputs are inaccessible once used", () {
    initGraph(["app|foo.a"], {"app": [
      [new RewriteTransformer("a", "b")],
      [new RewriteTransformer("a", "c")]
    ]});
    updateSources(["app|foo.a"]);
    expectAsset("app|foo.b", "foo.b");
    expectNoAsset("app|foo.a");
    expectNoAsset("app|foo.c");
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
    modifyAsset("app|a.txt", "a.inc");
    schedule(() => updateSources(["app|a.txt"]));

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

  test("discards outputs from a transform whose primary input is removed "
      "during processing", () {
    var rewrite = new RewriteTransformer("txt", "out");
    initGraph(["app|foo.txt"], {"app": [[rewrite]]});

    rewrite.pauseApply();
    updateSources(["app|foo.txt"]);
    schedule(() => rewrite.started);
    schedule(() {
      removeSources(["app|foo.txt"]);
      rewrite.resumeApply();
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

    modifyAsset("app|a.inc", "after");
    schedule(() => updateSources(["app|a.inc"]));

    expectAsset("app|a.out", "after");
    buildShouldSucceed();
  });

  test("applies a transform when it becomes newly primary", () {
    initGraph({
      "app|foo.txt": "this",
    }, {"app": [[new CheckContentTransformer("that", " and the other")]]});

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.txt", "this");
    buildShouldSucceed();

    modifyAsset("app|foo.txt", "that");
    schedule(() => updateSources(["app|foo.txt"]));

    expectAsset("app|foo.txt", "that and the other");
    buildShouldSucceed();
  });

  test("applies the correct transform if an asset is modified during isPrimary",
      () {
    var check1 = new CheckContentTransformer("first", "#1");
    var check2 = new CheckContentTransformer("second", "#2");
    initGraph({
      "app|foo.txt": "first",
    }, {"app": [[check1, check2]]});

    check1.pauseIsPrimary("app|foo.txt");
    updateSources(["app|foo.txt"]);
    // Ensure that we're waiting on check1's isPrimary.
    schedule(pumpEventQueue);

    modifyAsset("app|foo.txt", "second");
    schedule(() {
      updateSources(["app|foo.txt"]);
      check1.resumeIsPrimary("app|foo.txt");
    });

    expectAsset("app|foo.txt", "second#2");
    buildShouldSucceed();
  });

  test("applies the correct transform if an asset is removed and added during "
      "isPrimary", () {
    var check1 = new CheckContentTransformer("first", "#1");
    var check2 = new CheckContentTransformer("second", "#2");
    initGraph({
      "app|foo.txt": "first",
    }, {"app": [[check1, check2]]});

    check1.pauseIsPrimary("app|foo.txt");
    updateSources(["app|foo.txt"]);
    // Ensure that we're waiting on check1's isPrimary.
    schedule(pumpEventQueue);

    schedule(() => removeSources(["app|foo.txt"]));
    modifyAsset("app|foo.txt", "second");
    schedule(() {
      updateSources(["app|foo.txt"]);
      check1.resumeIsPrimary("app|foo.txt");
    });

    expectAsset("app|foo.txt", "second#2");
    buildShouldSucceed();
  });

  test("restarts processing if a change occurs during processing", () {
    var transformer = new RewriteTransformer("txt", "out");
    initGraph(["app|foo.txt"], {"app": [[transformer]]});

    transformer.pauseApply();

    schedule(() {
      updateSources(["app|foo.txt"]);

      // Wait for the transform to start.
      return transformer.started;
    });

    schedule(() {
      // Now update the graph during it.
      updateSources(["app|foo.txt"]);
      transformer.resumeApply();
    });

    expectAsset("app|foo.out", "foo.out");
    buildShouldSucceed();

    schedule(() {
      expect(transformer.numRuns, equals(2));
    });
  });

  test("aborts processing if the primary input is removed during processing",
      () {
    var transformer = new RewriteTransformer("txt", "out");
    initGraph(["app|foo.txt"], {"app": [[transformer]]});

    transformer.pauseApply();

    schedule(() {
      updateSources(["app|foo.txt"]);

      // Wait for the transform to start.
      return transformer.started;
    });

    schedule(() {
      // Now remove its primary input while it's running.
      removeSources(["app|foo.txt"]);
      transformer.resumeApply();
    });

    expectNoAsset("app|foo.out");
    buildShouldSucceed();

    schedule(() {
      expect(transformer.numRuns, equals(1));
    });
  });

  test("restarts processing if a change to a new secondary input occurs during "
      "processing", () {
    var transformer = new ManyToOneTransformer("txt");
    initGraph({
      "app|foo.txt": "bar.inc",
      "app|bar.inc": "bar"
    }, {"app": [[transformer]]});

    transformer.pauseApply();

    updateSources(["app|foo.txt", "app|bar.inc"]);
    // Wait for the transform to start.
    schedule(() => transformer.started);

    // Give the transform time to load bar.inc the first time.
    schedule(pumpEventQueue);

    // Now update the secondary input before the transform finishes.
    modifyAsset("app|bar.inc", "baz");
    schedule(() => updateSources(["app|bar.inc"]));
    // Give bar.inc enough time to be loaded and marked available before the
    // transformer completes.
    schedule(pumpEventQueue);

    schedule(transformer.resumeApply);

    expectAsset("app|foo.out", "baz");
    buildShouldSucceed();

    schedule(() {
      expect(transformer.numRuns, equals(2));
    });
  });

  test("doesn't restart processing if a change to an old secondary input "
      "occurs during processing", () {
    var transformer = new ManyToOneTransformer("txt");
    initGraph({
      "app|foo.txt": "bar.inc",
      "app|bar.inc": "bar",
      "app|baz.inc": "baz"
    }, {"app": [[transformer]]});

    updateSources(["app|foo.txt", "app|bar.inc", "app|baz.inc"]);
    expectAsset("app|foo.out", "bar");
    buildShouldSucceed();

    schedule(transformer.pauseApply);
    modifyAsset("app|foo.txt", "baz.inc");
    schedule(() {
      updateSources(["app|foo.txt"]);
      // Wait for the transform to start.
      return transformer.started;
    });

    // Now update the old secondary input before the transform finishes.
    modifyAsset("app|bar.inc", "new bar");
    schedule(() => updateSources(["app|bar.inc"]));
    // Give bar.inc enough time to be loaded and marked available before the
    // transformer completes.
    schedule(pumpEventQueue);

    schedule(transformer.resumeApply);

    expectAsset("app|foo.out", "baz");
    buildShouldSucceed();

    schedule(() {
      // Should have run once the first time, then again when switching to
      // baz.inc. Should not run a third time because of bar.inc being modified.
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
    modifyAsset("app|a.a", "a.out");
    modifyAsset("app|b.b", "b.out,shared.out");
    schedule(() => updateSources(["app|a.a", "app|b.b"]));

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

    txtToInt.pauseApply();

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
      txtToInt.resumeApply();
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

  test("doesn't return an asset until it's finished rebuilding", () {
    initGraph(["app|foo.in"], {"app": [
      [new RewriteTransformer("in", "mid")],
      [new RewriteTransformer("mid", "out")]
    ]});

    updateSources(["app|foo.in"]);
    expectAsset("app|foo.out", "foo.mid.out");
    buildShouldSucceed();

    pauseProvider();
    modifyAsset("app|foo.in", "new");
    schedule(() => updateSources(["app|foo.in"]));
    expectAssetDoesNotComplete("app|foo.out");
    buildShouldNotBeDone();

    resumeProvider();
    expectAsset("app|foo.out", "new.mid.out");
    buildShouldSucceed();
  });

  test("doesn't return an asset until its in-place transform is done", () {
    var rewrite = new RewriteTransformer("txt", "txt");
    initGraph(["app|foo.txt"], {"app": [[rewrite]]});

    rewrite.pauseApply();
    updateSources(["app|foo.txt"]);
    expectAssetDoesNotComplete("app|foo.txt");

    schedule(rewrite.resumeApply);
    expectAsset("app|foo.txt", "foo.txt");
    buildShouldSucceed();
  });

  test("doesn't return an asset until we know it won't be transformed",
      () {
    var rewrite = new RewriteTransformer("txt", "txt");
    initGraph(["app|foo.a"], {"app": [[rewrite]]});

    rewrite.pauseIsPrimary("app|foo.a");
    updateSources(["app|foo.a"]);
    expectAssetDoesNotComplete("app|foo.a");

    schedule(() => rewrite.resumeIsPrimary("app|foo.a"));
    expectAsset("app|foo.a", "foo");
    buildShouldSucceed();
  });

  test("doesn't return a modified asset until we know it will still be "
      "transformed", () {
    var rewrite = new RewriteTransformer("txt", "txt");
    initGraph(["app|foo.txt"], {"app": [[rewrite]]});

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.txt", "foo.txt");
    buildShouldSucceed();

    schedule(() => rewrite.pauseIsPrimary("app|foo.txt"));
    schedule(() => updateSources(["app|foo.txt"]));
    expectAssetDoesNotComplete("app|foo.txt");

    schedule(() => rewrite.resumeIsPrimary("app|foo.txt"));
    expectAsset("app|foo.txt", "foo.txt");
    buildShouldSucceed();
  });

  test("doesn't return an asset that's removed during isPrimary", () {
    var rewrite = new RewriteTransformer("txt", "txt");
    initGraph(["app|foo.txt"], {"app": [[rewrite]]});

    rewrite.pauseIsPrimary("app|foo.txt");
    updateSources(["app|foo.txt"]);
    // Make sure we're waiting on isPrimary.
    schedule(pumpEventQueue);

    schedule(() {
      removeSources(["app|foo.txt"]);
      rewrite.resumeIsPrimary("app|foo.txt");
    });
    expectNoAsset("app|foo.txt");
    buildShouldSucceed();
  });

  test("doesn't transform an asset that goes from primary to non-primary "
      "during isPrimary", () {
    var check = new CheckContentTransformer("do", "ne");
    initGraph({
      "app|foo.txt": "do"
    }, {"app": [[check]]});

    check.pauseIsPrimary("app|foo.txt");
    updateSources(["app|foo.txt"]);
    // Make sure we're waiting on isPrimary.
    schedule(pumpEventQueue);

    modifyAsset("app|foo.txt", "don't");
    schedule(() {
      updateSources(["app|foo.txt"]);
      check.resumeIsPrimary("app|foo.txt");
    });

    expectAsset("app|foo.txt", "don't");
    buildShouldSucceed();
  });

  test("transforms an asset that goes from non-primary to primary "
      "during isPrimary", () {
    var check = new CheckContentTransformer("do", "ne");
    initGraph({
      "app|foo.txt": "don't"
    }, {"app": [[check]]});

    check.pauseIsPrimary("app|foo.txt");
    updateSources(["app|foo.txt"]);
    // Make sure we're waiting on isPrimary.
    schedule(pumpEventQueue);

    modifyAsset("app|foo.txt", "do");
    schedule(() {
      updateSources(["app|foo.txt"]);
      check.resumeIsPrimary("app|foo.txt");
    });

    expectAsset("app|foo.txt", "done");
    buildShouldSucceed();
  });

  test("doesn't return an asset that's removed during another transformer's "
      "isPrimary", () {
    var rewrite1 = new RewriteTransformer("txt", "txt");
    var rewrite2 = new RewriteTransformer("md", "md");
    initGraph(["app|foo.txt", "app|foo.md"], {"app": [[rewrite1, rewrite2]]});

    rewrite2.pauseIsPrimary("app|foo.md");
    updateSources(["app|foo.txt", "app|foo.md"]);
    // Make sure we're waiting on the correct isPrimary.
    schedule(pumpEventQueue);

    schedule(() {
      removeSources(["app|foo.txt"]);
      rewrite2.resumeIsPrimary("app|foo.md");
    });
    expectNoAsset("app|foo.txt");
    expectAsset("app|foo.md", "foo.md");
    buildShouldSucceed();
  });

  test("doesn't transform an asset that goes from primary to non-primary "
      "during another transformer's isPrimary", () {
    var rewrite = new RewriteTransformer("md", "md");
    var check = new CheckContentTransformer("do", "ne");
    initGraph({
      "app|foo.txt": "do",
      "app|foo.md": "foo"
    }, {"app": [[rewrite, check]]});

    rewrite.pauseIsPrimary("app|foo.md");
    updateSources(["app|foo.txt", "app|foo.md"]);
    // Make sure we're waiting on the correct isPrimary.
    schedule(pumpEventQueue);

    modifyAsset("app|foo.txt", "don't");
    schedule(() {
      updateSources(["app|foo.txt"]);
      rewrite.resumeIsPrimary("app|foo.md");
    });

    expectAsset("app|foo.txt", "don't");
    expectAsset("app|foo.md", "foo.md");
    buildShouldSucceed();
  });

  test("transforms an asset that goes from non-primary to primary "
      "during another transformer's isPrimary", () {
    var rewrite = new RewriteTransformer("md", "md");
    var check = new CheckContentTransformer("do", "ne");
    initGraph({
      "app|foo.txt": "don't",
      "app|foo.md": "foo"
    }, {"app": [[rewrite, check]]});

    rewrite.pauseIsPrimary("app|foo.md");
    updateSources(["app|foo.txt", "app|foo.md"]);
    // Make sure we're waiting on the correct isPrimary.
    schedule(pumpEventQueue);

    modifyAsset("app|foo.txt", "do");
    schedule(() {
      updateSources(["app|foo.txt"]);
      rewrite.resumeIsPrimary("app|foo.md");
    });

    expectAsset("app|foo.txt", "done");
    expectAsset("app|foo.md", "foo.md");
    buildShouldSucceed();
  });

  test("removes pipelined transforms when the root primary input is removed",
      () {
    initGraph(["app|foo.txt"], {"app": [
      [new RewriteTransformer("txt", "mid")],
      [new RewriteTransformer("mid", "out")]
    ]});

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.out", "foo.mid.out");
    buildShouldSucceed();

    schedule(() => removeSources(["app|foo.txt"]));
    expectNoAsset("app|foo.out");
    buildShouldSucceed();
  });

  test("removes pipelined transforms when the parent ceases to generate the "
      "primary input", () {
    initGraph({"app|foo.txt": "foo.mid"}, {'app': [
      [new OneToManyTransformer('txt')],
      [new RewriteTransformer('mid', 'out')]
    ]});

    updateSources(['app|foo.txt']);
    expectAsset('app|foo.out', 'spread txt.out');
    buildShouldSucceed();

    modifyAsset("app|foo.txt", "bar.mid");
    schedule(() => updateSources(["app|foo.txt"]));
    expectNoAsset('app|foo.out');
    expectAsset('app|bar.out', 'spread txt.out');
    buildShouldSucceed();
  });

  test("returns an asset even if an unrelated build is running", () {
    initGraph([
      "app|foo.in",
      "app|bar.in",
    ], {"app": [[new RewriteTransformer("in", "out")]]});

    updateSources(["app|foo.in", "app|bar.in"]);
    expectAsset("app|foo.out", "foo.out");
    expectAsset("app|bar.out", "bar.out");
    buildShouldSucceed();

    pauseProvider();
    modifyAsset("app|foo.in", "new");
    schedule(() => updateSources(["app|foo.in"]));
    expectAssetDoesNotComplete("app|foo.out");
    expectAsset("app|bar.out", "bar.out");
    buildShouldNotBeDone();

    resumeProvider();
    expectAsset("app|foo.out", "new.out");
    buildShouldSucceed();
  });

  test("doesn't report AssetNotFound until all builds are finished", () {
    initGraph([
      "app|foo.in",
    ], {"app": [[new RewriteTransformer("in", "out")]]});

    updateSources(["app|foo.in"]);
    expectAsset("app|foo.out", "foo.out");
    buildShouldSucceed();

    pauseProvider();
    schedule(() => updateSources(["app|foo.in"]));
    expectAssetDoesNotComplete("app|foo.out");
    expectAssetDoesNotComplete("app|non-existent.out");
    buildShouldNotBeDone();

    resumeProvider();
    expectAsset("app|foo.out", "foo.out");
    expectNoAsset("app|non-existent.out");
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
