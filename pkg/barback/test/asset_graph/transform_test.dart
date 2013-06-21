// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.asset_graph.transform_test;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:barback/src/asset_graph.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../utils.dart';

main() {
  initConfig();
  test("gets a transformed asset with a different path", () {
    var provider = new MockProvider(["app|foo.blub"]);
    var graph = new AssetGraph(provider, [
      [new RewriteTransformer("blub", "blab")]
    ]);
    graph.updateSources([new AssetId.parse("app|foo.blub")]);

    expectAsset(graph, "app|foo.blab", "foo.blab");
  });

  test("gets a transformed asset with the same path", () {
    var provider = new MockProvider(["app|foo.blub"]);
    var graph = new AssetGraph(provider, [
      [new RewriteTransformer("blub", "blub")]
    ]);
    graph.updateSources([new AssetId.parse("app|foo.blub")]);

    expectAsset(graph, "app|foo.blub", "foo.blub");
  });

  test("doesn't find an output from a later phase", () {
    var provider = new MockProvider(["app|foo.a"]);
    var graph = new AssetGraph(provider, [
      [new RewriteTransformer("b", "c")],
      [new RewriteTransformer("a", "b")]
    ]);
    graph.updateSources([new AssetId.parse("app|foo.a")]);

    expectNoAsset(graph, "app|foo.c");
  });

  test("doesn't find an output from the same phase", () {
    var provider = new MockProvider(["app|foo.a"]);
    var graph = new AssetGraph(provider, [
      [
        new RewriteTransformer("a", "b"),
        new RewriteTransformer("b", "c")
      ]
    ]);
    graph.updateSources([new AssetId.parse("app|foo.a")]);

    expectAsset(graph, "app|foo.b", "foo.b");
    expectNoAsset(graph, "app|foo.c");
  });

  test("finds the latest output before the transformer's phase", () {
    var provider = new MockProvider(["app|foo.blub"]);
    var graph = new AssetGraph(provider, [
      [new RewriteTransformer("blub", "blub")],
      [
        new RewriteTransformer("blub", "blub"),
        new RewriteTransformer("blub", "done")
      ],
      [new RewriteTransformer("blub", "blub")]
    ]);
    graph.updateSources([new AssetId.parse("app|foo.blub")]);

    expectAsset(graph, "app|foo.done", "foo.blub.done");
  });

  test("applies multiple transformations to an asset", () {
    var provider = new MockProvider(["app|foo.a"]);
    var graph = new AssetGraph(provider, [
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
    ]);
    graph.updateSources([new AssetId.parse("app|foo.a")]);

    expectAsset(graph, "app|foo.k", "foo.b.c.d.e.f.g.h.i.j.k");
  });

  test("only runs a transform once for all of its outputs", () {
    var provider = new MockProvider(["app|foo.blub"]);
    var transformer = new RewriteTransformer("blub", "a b c");
    var graph = new AssetGraph(provider, [[transformer]]);
    graph.updateSources([new AssetId.parse("app|foo.blub")]);

    expectAsset(graph, "app|foo.a", "foo.a");
    expectAsset(graph, "app|foo.b", "foo.b");
    expectAsset(graph, "app|foo.c", "foo.c");
    schedule(() {
      expect(transformer.numRuns, equals(1));
    });
  });

  test("runs transforms in the same phase in parallel", () {
    var provider = new MockProvider(["app|foo.txt"]);
    var transformerA = new RewriteTransformer("txt", "a");
    var transformerB = new RewriteTransformer("txt", "b");
    var graph = new AssetGraph(provider, [[transformerA, transformerB]]);

    transformerA.wait();
    transformerB.wait();

    schedule(() {
      graph.updateSources([new AssetId.parse("app|foo.txt")]);

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

    expectAsset(graph, "app|foo.a", "foo.a");
    expectAsset(graph, "app|foo.b", "foo.b");
  });

  test("does not reapply transform when inputs are not modified", () {
    var provider = new MockProvider(["app|foo.blub"]);
    var transformer = new RewriteTransformer("blub", "blab");
    var graph = new AssetGraph(provider, [[transformer]]);
    graph.updateSources([new AssetId.parse("app|foo.blub")]);
    expectAsset(graph, "app|foo.blab", "foo.blab");
    expectAsset(graph, "app|foo.blab", "foo.blab");
    expectAsset(graph, "app|foo.blab", "foo.blab");

    schedule(() {
      expect(transformer.numRuns, equals(1));
    });
  });

  test("reapplies a transform when its input is modified", () {
    var provider = new MockProvider(["app|foo.blub"]);
    var transformer = new RewriteTransformer("blub", "blab");
    var graph = new AssetGraph(provider, [[transformer]]);

    schedule(() {
      graph.updateSources([new AssetId.parse("app|foo.blub")]);
    });

    expectAsset(graph, "app|foo.blab", "foo.blab");

    schedule(() {
      graph.updateSources([new AssetId.parse("app|foo.blub")]);
    });

    expectAsset(graph, "app|foo.blab", "foo.blab");

    schedule(() {
      graph.updateSources([new AssetId.parse("app|foo.blub")]);
    });

    expectAsset(graph, "app|foo.blab", "foo.blab");

    schedule(() {
      expect(transformer.numRuns, equals(3));
    });
  });

  test("does not reapply transform when a removed input is modified", () {
    var provider = new MockProvider({
      "app|a.txt": "a.inc,b.inc",
      "app|a.inc": "a",
      "app|b.inc": "b"
    });

    var transformer = new ManyToOneTransformer("txt");
    var graph = new AssetGraph(provider, [[transformer]]);

    graph.updateSources([
      new AssetId.parse("app|a.txt"),
      new AssetId.parse("app|a.inc"),
      new AssetId.parse("app|b.inc")
    ]);

    expectAsset(graph, "app|a.out", "ab");

    // Remove the dependency on the non-primary input.
    schedule(() {
      provider.modifyAsset("app|a.txt", "a.inc");
      graph.updateSources([new AssetId.parse("app|a.txt")]);
    });

    // Process it again.
    expectAsset(graph, "app|a.out", "a");

    // Now touch the removed input. It should not trigger another build.
    schedule(() {
      graph.updateSources([new AssetId.parse("app|b.inc")]);
    });

    expectAsset(graph, "app|a.out", "a");

    schedule(() {
      expect(transformer.numRuns, equals(2));
    });
  });

  test("allows a transform to generate multiple outputs", () {
    var provider = new MockProvider({"app|foo.txt": "a.out,b.out"});
    var graph = new AssetGraph(provider, [
      [new OneToManyTransformer("txt")]
    ]);

    graph.updateSources([new AssetId.parse("app|foo.txt")]);

    expectAsset(graph, "app|a.out", "spread txt");
    expectAsset(graph, "app|b.out", "spread txt");
  });

  test("does not rebuild transforms that don't use modified source", () {
    var provider = new MockProvider(["app|foo.a", "app|foo.b"]);
    var a = new RewriteTransformer("a", "aa");
    var aa = new RewriteTransformer("aa", "aaa");
    var b = new RewriteTransformer("b", "bb");
    var bb = new RewriteTransformer("bb", "bbb");

    var graph = new AssetGraph(provider, [
      [a, b],
      [aa, bb],
    ]);

    graph.updateSources([new AssetId.parse("app|foo.a")]);
    graph.updateSources([new AssetId.parse("app|foo.b")]);

    expectAsset(graph, "app|foo.aaa", "foo.aa.aaa");
    expectAsset(graph, "app|foo.bbb", "foo.bb.bbb");

    schedule(() {
      graph.updateSources([new AssetId.parse("app|foo.a")]);
    });

    expectAsset(graph, "app|foo.aaa", "foo.aa.aaa");
    expectAsset(graph, "app|foo.bbb", "foo.bb.bbb");

    schedule(() {
      expect(aa.numRuns, equals(2));
      expect(bb.numRuns, equals(1));
    });
  });

  test("doesn't get an output from a transform whose primary input is removed",
      () {
    var provider = new MockProvider(["app|foo.txt"]);
    var graph = new AssetGraph(provider, [
      [new RewriteTransformer("txt", "out")]
    ]);

    graph.updateSources([new AssetId.parse("app|foo.txt")]);

    expectAsset(graph, "app|foo.out", "foo.out");

    schedule(() {
      graph.removeSources([new AssetId.parse("app|foo.txt")]);
    });

    expectNoAsset(graph, "app|foo.out");
  });

  test("reapplies a transform when a non-primary input changes", () {
    var provider = new MockProvider({
      "app|a.txt": "a.inc",
      "app|a.inc": "a"
    });

    var graph = new AssetGraph(provider, [
      [new ManyToOneTransformer("txt")]
    ]);

    graph.updateSources([
      new AssetId.parse("app|a.txt"),
      new AssetId.parse("app|a.inc")
    ]);

    expectAsset(graph, "app|a.out", "a");

    schedule(() {
      provider.modifyAsset("app|a.inc", "after");
      graph.updateSources([new AssetId.parse("app|a.inc")]);
    });

    expectAsset(graph, "app|a.out", "after");
  });

  test("restarts processing if a change occurs during processing", () {
    var provider = new MockProvider(["app|foo.txt"]);
    var transformer = new RewriteTransformer("txt", "out");
    var graph = new AssetGraph(provider, [[transformer]]);

    transformer.wait();

    schedule(() {
      graph.updateSources([new AssetId.parse("app|foo.txt")]);

      // Wait for the transform to start.
      return transformer.started;
    });

    schedule(() {
      // Now update the graph during it.
      graph.updateSources([new AssetId.parse("app|foo.txt")]);
    });

    schedule(() {
      transformer.complete();
    });

    expectAsset(graph, "app|foo.out", "foo.out");

    schedule(() {
      expect(transformer.numRuns, equals(2));
    });
  });

  test("handles an output moving from one transformer to another", () {
    // In the first run, "shared.out" is created by the "a.a" transformer.
    var provider = new MockProvider({
      "app|a.a": "a.out,shared.out",
      "app|b.b": "b.out"
    });

    var graph = new AssetGraph(provider, [
      [new OneToManyTransformer("a"), new OneToManyTransformer("b")]
    ]);

    graph.updateSources([
      new AssetId.parse("app|a.a"),
      new AssetId.parse("app|b.b")
    ]);

    expectAsset(graph, "app|a.out", "spread a");
    expectAsset(graph, "app|b.out", "spread b");
    expectAsset(graph, "app|shared.out", "spread a");

    // Now switch their contents so that "shared.out" will be output by "b.b"'s
    // transformer.
    schedule(() {
      provider.modifyAsset("app|a.a", "a.out");
      provider.modifyAsset("app|b.b", "b.out,shared.out");
      graph.updateSources([
        new AssetId.parse("app|a.a"),
        new AssetId.parse("app|b.b")
      ]);
    });

    expectAsset(graph, "app|a.out", "spread a");
    expectAsset(graph, "app|b.out", "spread b");
    expectAsset(graph, "app|shared.out", "spread b");
  });

  test("restarts before finishing later phases when a change occurs", () {
    var provider = new MockProvider(["app|foo.txt", "app|bar.txt"]);

    var txtToInt = new RewriteTransformer("txt", "int");
    var intToOut = new RewriteTransformer("int", "out");
    var graph = new AssetGraph(provider, [[txtToInt], [intToOut]]);

    txtToInt.wait();

    schedule(() {
      graph.updateSources([new AssetId.parse("app|foo.txt")]);

      // Wait for the first transform to start.
      return txtToInt.started;
    });

    schedule(() {
      // Now update the graph during it.
      graph.updateSources([new AssetId.parse("app|bar.txt")]);
    });

    schedule(() {
      txtToInt.complete();
    });

    expectAsset(graph, "app|foo.out", "foo.int.out");
    expectAsset(graph, "app|bar.out", "bar.int.out");

    schedule(() {
      // Should only have run each transform once for each primary.
      expect(txtToInt.numRuns, equals(2));
      expect(intToOut.numRuns, equals(2));
    });
  });
}
