// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.package_graph.group_test;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../utils.dart';

main() {
  initConfig();
  test("runs transforms in a group", () {
    initGraph(["app|foo.a"], {"app": [
      [new TransformerGroup([
        [new RewriteTransformer("a", "b")],
        [new RewriteTransformer("b", "c")]
      ])]
    ]});
    updateSources(["app|foo.a"]);
    expectAsset("app|foo.c", "foo.b.c");
    buildShouldSucceed();
  });

  test("passes the output of a group to the next phase", () {
    initGraph(["app|foo.a"], {"app": [
      [new TransformerGroup([
        [new RewriteTransformer("a", "b")],
        [new RewriteTransformer("b", "c")]
      ])],
      [new RewriteTransformer("c", "d")]
    ]});
    updateSources(["app|foo.a"]);
    expectAsset("app|foo.d", "foo.b.c.d");
    buildShouldSucceed();
  });

  test("passes the output of a previous phase to a group", () {
    initGraph(["app|foo.a"], {"app": [
      [new RewriteTransformer("a", "b")],
      [new TransformerGroup([
        [new RewriteTransformer("b", "c")],
        [new RewriteTransformer("c", "d")]
      ])]
    ]});
    updateSources(["app|foo.a"]);
    expectAsset("app|foo.d", "foo.b.c.d");
    buildShouldSucceed();
  });

  test("intermediate assets in a group are usable as secondary inputs within "
      "that group", () {
    initGraph({
      "app|foo.a": "contents",
      "app|bar.txt": "foo.inc"
    }, {"app": [
      [new TransformerGroup([
        [new RewriteTransformer("a", "inc")],
        [new ManyToOneTransformer("txt")]
      ])]
    ]});

    updateSources(["app|foo.a", "app|bar.txt"]);
    expectAsset("app|bar.out", "contents.inc");
    buildShouldSucceed();
  });

  test("groups can be nested", () {
    initGraph(["app|foo.a", "app|bar.x"], {"app": [
      [new TransformerGroup([
        [new TransformerGroup([
          [new RewriteTransformer("a", "b")],
          [new RewriteTransformer("b", "c")]
        ]), new TransformerGroup([
          [new RewriteTransformer("x", "y"), new RewriteTransformer("a", "y")],
          [new RewriteTransformer("y", "z")]
        ])],
        [new RewriteTransformer("c", "d")]
      ])]
    ]});
    updateSources(["app|foo.a", "app|bar.x"]);
    expectAsset("app|foo.d", "foo.b.c.d");
    expectAsset("app|foo.z", "foo.y.z");
    expectAsset("app|bar.z", "bar.y.z");
    buildShouldSucceed();
  });

  test("an updated asset is propagated through a group", () {
    initGraph(["app|foo.a"], {"app": [
      [new TransformerGroup([
        [new RewriteTransformer("a", "b")],
        [new RewriteTransformer("b", "c")]
      ])]
    ]});

    updateSources(["app|foo.a"]);
    expectAsset("app|foo.c", "foo.b.c");
    buildShouldSucceed();

    modifyAsset("app|foo.a", "new foo");
    updateSources(["app|foo.a"]);
    expectAsset("app|foo.c", "new foo.b.c");
    buildShouldSucceed();
  });

  test("an updated asset only runs the necessary transforms in a group", () {
    var rewriteA = new RewriteTransformer("a", "b");
    var rewriteX = new RewriteTransformer("x", "b");
    initGraph(["app|foo.a", "app|bar.x"], {"app": [
      [new TransformerGroup([
        [rewriteA, rewriteX],
        [new RewriteTransformer("b", "c")]
      ])]
    ]});

    updateSources(["app|foo.a", "app|bar.x"]);
    expectAsset("app|foo.c", "foo.b.c");
    expectAsset("app|bar.c", "bar.b.c");
    buildShouldSucceed();

    modifyAsset("app|foo.a", "new foo");
    updateSources(["app|foo.a"]);
    expectAsset("app|foo.c", "new foo.b.c");
    buildShouldSucceed();

    expect(rewriteA.numRuns, completion(equals(2)));
    expect(rewriteX.numRuns, completion(equals(1)));
  });

  group("encapsulation", () {
    test("a group can't see a parallel transform's outputs", () {
      initGraph(["app|foo.x"], {"app": [[
        new TransformerGroup([
          [new RewriteTransformer("a", "b")],
          [new RewriteTransformer("b", "c")]
        ]),
        new RewriteTransformer("x", "b")
      ]]});
      updateSources(["app|foo.x"]);
      expectAsset("app|foo.b", "foo.b");
      expectNoAsset("app|foo.c");
      buildShouldSucceed();
    });

    test("a parallel transform can't see a group's outputs", () {
      initGraph(["app|foo.a"], {"app": [[
        new TransformerGroup([
          [new RewriteTransformer("a", "b")],
          [new RewriteTransformer("b", "c")]
        ]),
        new RewriteTransformer("c", "z")
      ]]});
      updateSources(["app|foo.a"]);
      expectAsset("app|foo.c", "foo.b.c");
      expectNoAsset("app|foo.z");
      buildShouldSucceed();
    });

    test("a parallel transform can't see a group's intermediate assets", () {
      initGraph(["app|foo.a"], {"app": [[
        new TransformerGroup([
          [new RewriteTransformer("a", "b")],
          [new RewriteTransformer("b", "c")]
        ]),
        new RewriteTransformer("b", "z")
      ]]});
      updateSources(["app|foo.a"]);
      expectAsset("app|foo.c", "foo.b.c");
      expectNoAsset("app|foo.z");
      buildShouldSucceed();
    });

    test("parallel groups can't see one another's intermediate assets", () {
      initGraph(["app|foo.a", "app|bar.x"], {"app": [
        [new TransformerGroup([
          [new RewriteTransformer("a", "b")],
          [new RewriteTransformer("b", "c")]
        ]), new TransformerGroup([
          [new RewriteTransformer("x", "b")],
          [new RewriteTransformer("b", "z")]
        ])]
      ]});
      updateSources(["app|foo.a", "app|bar.x"]);
      expectAsset("app|foo.c", "foo.b.c");
      expectAsset("app|bar.z", "bar.b.z");
      expectNoAsset("app|foo.z");
      expectNoAsset("app|bar.c");
      buildShouldSucceed();
    });

    test("parallel groups' intermediate assets can't collide", () {
      initGraph(["app|foo.a", "app|foo.x"], {"app": [
        [new TransformerGroup([
          [new RewriteTransformer("a", "b")],
          [new RewriteTransformer("b", "c")..consumePrimary = true]
        ]), new TransformerGroup([
          [new RewriteTransformer("x", "b")],
          [new RewriteTransformer("b", "z")..consumePrimary = true]
        ])]
      ]});
      updateSources(["app|foo.a", "app|foo.x"]);
      expectAsset("app|foo.a");
      expectAsset("app|foo.x");
      expectAsset("app|foo.c", "foo.b.c");
      expectAsset("app|foo.z", "foo.b.z");
      buildShouldSucceed();
    });
  });

  group("pass-through", () {
    test("passes an unused input through a group", () {
      initGraph(["app|foo.x"], {"app": [
        [new TransformerGroup([
          [new RewriteTransformer("a", "b")],
          [new RewriteTransformer("b", "c")]
        ])]
      ]});
      updateSources(["app|foo.x"]);
      expectNoAsset("app|foo.c");
      expectAsset("app|foo.x", "foo");
      buildShouldSucceed();
    });

    test("passes non-overwritten inputs through a group", () {
      initGraph(["app|foo.a"], {"app": [
        [new TransformerGroup([
          [new RewriteTransformer("a", "b")],
          [new RewriteTransformer("b", "c")]
        ])]
      ]});
      updateSources(["app|foo.a"]);
      expectAsset("app|foo.a", "foo");
      expectAsset("app|foo.b", "foo.b");
      expectAsset("app|foo.c", "foo.b.c");
      buildShouldSucceed();
    });

    test("passes an unused input through parallel groups", () {
      initGraph(["app|foo.x"], {"app": [
        [new TransformerGroup([
          [new RewriteTransformer("a", "b")],
          [new RewriteTransformer("b", "c")]
        ]), new TransformerGroup([
          [new RewriteTransformer("1", "2")],
          [new RewriteTransformer("2", "3")]
        ])]
      ]});
      updateSources(["app|foo.x"]);
      expectNoAsset("app|foo.c");
      expectNoAsset("app|foo.3");
      expectAsset("app|foo.x", "foo");
      buildShouldSucceed();
    });

    test("passes an unused input through a group and a transform", () {
      initGraph(["app|foo.x"], {"app": [[
        new TransformerGroup([
          [new RewriteTransformer("a", "b")],
          [new RewriteTransformer("b", "c")]
        ]),
        new RewriteTransformer("1", "2")
      ]]});
      updateSources(["app|foo.x"]);
      expectNoAsset("app|foo.c");
      expectNoAsset("app|foo.2");
      expectAsset("app|foo.x", "foo");
      buildShouldSucceed();
    });

    test("doesn't pass through an input that's overwritten by a group but not "
        "by transformers", () {
      initGraph(["app|foo.a"], {"app": [[
        new TransformerGroup([
          [new RewriteTransformer("a", "a")],
        ]),
        new RewriteTransformer("x", "y")
      ]]});
      updateSources(["app|foo.a"]);
      expectNoAsset("app|foo.y");
      expectAsset("app|foo.a", "foo.a");
      buildShouldSucceed();
    });

    test("doesn't pass through an input that's overwritten by transformers but "
        "not by a group", () {
      initGraph(["app|foo.x"], {"app": [[
        new TransformerGroup([
          [new RewriteTransformer("a", "b")],
          [new RewriteTransformer("b", "c")]
        ]),
        new RewriteTransformer("x", "x")
      ]]});
      updateSources(["app|foo.x"]);
      expectNoAsset("app|foo.c");
      expectAsset("app|foo.x", "foo.x");
      buildShouldSucceed();
    });

    test("doesn't pass through an input that's consumed by a group but not "
        "by transformers", () {
      initGraph(["app|foo.a"], {"app": [[
        new TransformerGroup([
          [new RewriteTransformer("a", "b")..consumePrimary = true],
        ]),
        new RewriteTransformer("x", "y")
      ]]});
      updateSources(["app|foo.a"]);
      expectNoAsset("app|foo.a");
      expectAsset("app|foo.b", "foo.b");
      buildShouldSucceed();
    });

    test("doesn't pass through an input that's consumed by transformers but "
        "not by a group", () {
      initGraph(["app|foo.x"], {"app": [[
        new TransformerGroup([
          [new RewriteTransformer("a", "b")],
          [new RewriteTransformer("b", "c")]
        ]),
        new RewriteTransformer("x", "y")..consumePrimary = true
      ]]});
      updateSources(["app|foo.x"]);
      expectNoAsset("app|foo.x");
      expectAsset("app|foo.y", "foo.y");
      buildShouldSucceed();
    });

    test("doesn't detect a collision for an input that's modified in-place by "
        "a transformer", () {
      initGraph(["app|foo.x"], {"app": [[
        new TransformerGroup([
          [new RewriteTransformer("a", "b")],
          [new RewriteTransformer("b", "c")]
        ]),
        new RewriteTransformer("x", "x")
      ]]});
      updateSources(["app|foo.x"]);
      expectAsset("app|foo.x", "foo.x");
      buildShouldSucceed();
    });

    test("doesn't detect a collision for an input that's modified in-place by "
        "a group", () {
      initGraph(["app|foo.a"], {"app": [[
        new TransformerGroup([[new RewriteTransformer("a", "a")]]),
        new RewriteTransformer("x", "y")
      ]]});
      updateSources(["app|foo.a"]);
      expectAsset("app|foo.a", "foo.a");
      buildShouldSucceed();
    });
  });

  test("runs transforms in an added group", () {
    var rewrite = new RewriteTransformer("a", "z");
    initGraph(["app|foo.a"], {"app": [[rewrite]]});

    updateSources(["app|foo.a"]);
    expectAsset("app|foo.z", "foo.z");
    buildShouldSucceed();

    updateTransformers("app", [[
      rewrite,
      new TransformerGroup([
        [new RewriteTransformer("a", "b")],
        [new RewriteTransformer("b", "c")]
      ])
    ]]);
    expectAsset("app|foo.z", "foo.z");
    expectAsset("app|foo.c", "foo.b.c");
    buildShouldSucceed();
  });

  test("doesn't re-run transforms in a re-added group", () {
    var rewrite1 = new RewriteTransformer("a", "b");
    var rewrite2 = new RewriteTransformer("b", "c");
    var group = new TransformerGroup([[rewrite1], [rewrite2]]);
    initGraph(["app|foo.a"], {"app": [[group]]});

    updateSources(["app|foo.a"]);
    expectAsset("app|foo.c", "foo.b.c");
    buildShouldSucceed();

    updateTransformers("app", [
      [group, new RewriteTransformer("a", "z")]
    ]);
    expectAsset("app|foo.c", "foo.b.c");
    expectAsset("app|foo.z", "foo.z");
    buildShouldSucceed();

    expect(rewrite1.numRuns, completion(equals(1)));
    expect(rewrite2.numRuns, completion(equals(1)));
  });

  test("doesn't run transforms in a removed group", () {
    var rewrite1 = new RewriteTransformer("a", "b");
    var rewrite2 = new RewriteTransformer("b", "c");
    var group = new TransformerGroup([[rewrite1], [rewrite2]]);
    initGraph(["app|foo.a"], {"app": [[group]]});

    updateSources(["app|foo.a"]);
    expectAsset("app|foo.c", "foo.b.c");
    buildShouldSucceed();

    updateTransformers("app", []);
    expectNoAsset("app|foo.c");
    buildShouldSucceed();
  });

  test("doesn't pass through an input that's overwritten by an added group",
      () {
    var rewrite = new RewriteTransformer("x", "z");
    initGraph(["app|foo.a"], {"app": [[rewrite]]});

    updateSources(["app|foo.a"]);
    expectAsset("app|foo.a", "foo");
    buildShouldSucceed();

    updateTransformers("app", [
      [rewrite, new TransformerGroup([[new RewriteTransformer("a", "a")]])]
    ]);
    expectAsset("app|foo.a", "foo.a");
    buildShouldSucceed();
  });

  // TODO(nweiz): make the collision error message nice
  test("reports collisions within a group", () {
    initGraph(["app|foo.a", "app|foo.x"], {"app": [
      [new TransformerGroup([
        [new RewriteTransformer("a", "b")],
        [new RewriteTransformer("x", "b")]
      ])]
    ]});
    updateSources(["app|foo.a", "app|foo.x"]);
    buildShouldFail([isAssetCollisionException("app|foo.b")]);
  });

  test("reports collisions between a group and a non-grouped transform", () {
    initGraph(["app|foo.a", "app|foo.x"], {"app": [[
      new TransformerGroup([
        [new RewriteTransformer("a", "b")],
        [new RewriteTransformer("b", "c")]
      ]),
      new RewriteTransformer("x", "c")
    ]]});
    updateSources(["app|foo.a", "app|foo.x"]);
    buildShouldFail([isAssetCollisionException("app|foo.c")]);
  });

  // Regression test for issue 18872.
  test("a multi-phase group's outputs should be visible as secondary inputs "
      "for a following group", () {
    initGraph({
      "app|foo.txt": "bar.c",
      "app|bar.a": "bar"
    }, {"app": [
      [new TransformerGroup([
        [new RewriteTransformer("a", "b")],
        [new RewriteTransformer("b", "c")]
      ])],
      [new TransformerGroup([
        [new ManyToOneTransformer("txt")]
      ])]
    ]});

    updateSources(["app|foo.txt", "app|bar.a"]);
    expectAsset("app|foo.out", "bar.b.c");
    buildShouldSucceed();
  });
}
