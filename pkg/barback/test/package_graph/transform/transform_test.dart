// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This library contains tests for transformer behavior that relates to actions
// happening concurrently or other complex asynchronous timing behavior.
library barback.test.package_graph.transform.transform_test;

import 'package:barback/src/utils.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../../utils.dart';

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
    expect(transformer.numRuns, completion(equals(1)));
  });

  test("outputs are passed through transformers by default", () {
    initGraph(["app|foo.a"], {"app": [
      [new RewriteTransformer("a", "b")],
      [new RewriteTransformer("a", "c")]
    ]});
    updateSources(["app|foo.a"]);
    expectAsset("app|foo.a", "foo");
    expectAsset("app|foo.b", "foo.b");
    expectAsset("app|foo.c", "foo.c");
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

    expect(transformer.numRuns, completion(equals(1)));
  });

  test("reapplies a transform when its input is modified", () {
    var transformer = new RewriteTransformer("blub", "blab");
    initGraph(["app|foo.blub"], {"app": [[transformer]]});

    updateSources(["app|foo.blub"]);
    expectAsset("app|foo.blab", "foo.blab");
    buildShouldSucceed();

    updateSources(["app|foo.blub"]);
    expectAsset("app|foo.blab", "foo.blab");
    buildShouldSucceed();

    updateSources(["app|foo.blub"]);
    expectAsset("app|foo.blab", "foo.blab");
    buildShouldSucceed();

    expect(transformer.numRuns, completion(equals(3)));
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
    updateSources(["app|a.txt"]);

    // Process it again.
    expectAsset("app|a.out", "a");
    buildShouldSucceed();

    // Now touch the removed input. It should not trigger another build.
    updateSources(["app|b.inc"]);
    expectAsset("app|a.out", "a");
    buildShouldSucceed();

    expect(transformer.numRuns, completion(equals(2)));
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

    updateSources(["app|foo.a"]);
    expectAsset("app|foo.aaa", "foo.aa.aaa");
    expectAsset("app|foo.bbb", "foo.bb.bbb");
    buildShouldSucceed();

    expect(aa.numRuns, completion(equals(2)));
    expect(bb.numRuns, completion(equals(1)));
  });

  test("doesn't get an output from a transform whose primary input is removed",
      () {
    initGraph(["app|foo.txt"], {"app": [
      [new RewriteTransformer("txt", "out")]
    ]});

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.out", "foo.out");
    buildShouldSucceed();

    removeSources(["app|foo.txt"]);
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
    updateSources(["app|a.inc"]);

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
    updateSources(["app|foo.txt"]);

    expectAsset("app|foo.txt", "that and the other");
    buildShouldSucceed();
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
    updateSources(["app|a.a", "app|b.b"]);

    expectAsset("app|a.out", "spread a");
    expectAsset("app|b.out", "spread b");
    expectAsset("app|shared.out", "spread b");
    buildShouldSucceed();
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

  test("removes pipelined transforms when the root primary input is removed",
      () {
    initGraph(["app|foo.txt"], {"app": [
      [new RewriteTransformer("txt", "mid")],
      [new RewriteTransformer("mid", "out")]
    ]});

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.out", "foo.mid.out");
    buildShouldSucceed();

    removeSources(["app|foo.txt"]);
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
    updateSources(["app|foo.txt"]);
    expectNoAsset('app|foo.out');
    expectAsset('app|bar.out', 'spread txt.out');
    buildShouldSucceed();
  });

  group("Transform.hasInput", () {
    test("returns whether an input exists", () {
      initGraph(["app|foo.txt", "app|bar.txt"], {'app': [
        [new HasInputTransformer(['app|foo.txt', 'app|bar.txt', 'app|baz.txt'])]
      ]});

      updateSources(['app|foo.txt', 'app|bar.txt']);
      expectAsset('app|foo.txt',
          'app|foo.txt: true, app|bar.txt: true, app|baz.txt: false');
      buildShouldSucceed();
    });

    test("re-runs the transformer when an input stops existing", () {
      initGraph(["app|foo.txt", "app|bar.txt"], {'app': [
        [new HasInputTransformer(['app|bar.txt'])]
      ]});

      updateSources(['app|foo.txt', 'app|bar.txt']);
      expectAsset('app|foo.txt', 'app|bar.txt: true');
      buildShouldSucceed();

      removeSources(['app|bar.txt']);
      expectAsset('app|foo.txt', 'app|bar.txt: false');
      buildShouldSucceed();
    });

    test("re-runs the transformer when an input starts existing", () {
      initGraph(["app|foo.txt", "app|bar.txt"], {'app': [
        [new HasInputTransformer(['app|bar.txt'])]
      ]});
    
      updateSources(['app|foo.txt']);
      expectAsset('app|foo.txt', 'app|bar.txt: false');
      buildShouldSucceed();
    
      updateSources(['app|bar.txt']);
      expectAsset('app|foo.txt', 'app|bar.txt: true');
      buildShouldSucceed();
    });
  });
}
