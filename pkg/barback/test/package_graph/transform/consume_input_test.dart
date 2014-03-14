// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.package_graph.transform.pass_through_test;

import 'package:barback/src/utils.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../../utils.dart';

main() {
  initConfig();
  test("a transform consumes its input without overwriting it", () {
    initGraph([
      "app|foo.txt"
    ], {
      "app": [[new RewriteTransformer("txt", "out")..consumePrimary = true]]
    });

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.out", "foo.out");
    expectNoAsset("app|foo.txt");
    buildShouldSucceed();
  });

  test("a transform consumes its input while a sibling overwrites it", () {
    initGraph([
      "app|foo.txt"
    ], {
      "app": [[
        new RewriteTransformer("txt", "out")..consumePrimary = true,
        new RewriteTransformer("txt", "txt")
      ]]
    });

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.out", "foo.out");
    expectAsset("app|foo.txt", "foo.txt");
    buildShouldSucceed();
  });

  test("a transform stops consuming its input", () {
    initGraph({
      "app|foo.txt": "yes"
    }, {
      "app": [[
        new ConditionallyConsumePrimaryTransformer("txt", "out", "yes")
      ]]
    });

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.out", "yes.out");
    expectNoAsset("app|foo.txt");
    buildShouldSucceed();

    modifyAsset("app|foo.txt", "no");
    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.out", "no.out");
    expectAsset("app|foo.txt", "no");
    buildShouldSucceed();
  });

  test("two sibling transforms both consume their input", () {
    initGraph(["app|foo.txt"], {
      "app": [[
        new RewriteTransformer("txt", "one")..consumePrimary = true,
        new RewriteTransformer("txt", "two")..consumePrimary = true
      ]]
    });

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.one", "foo.one");
    expectAsset("app|foo.two", "foo.two");
    expectNoAsset("app|foo.txt");
    buildShouldSucceed();
  });

  test("a transform stops consuming its input but a sibling is still "
      "consuming it", () {
    initGraph({
      "app|foo.txt": "yes"
    }, {
      "app": [[
        new RewriteTransformer("txt", "one")..consumePrimary = true,
        new ConditionallyConsumePrimaryTransformer("txt", "two", "yes")
      ]]
    });

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.one", "yes.one");
    expectAsset("app|foo.two", "yes.two");
    expectNoAsset("app|foo.txt");
    buildShouldSucceed();

    modifyAsset("app|foo.txt", "no");
    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.one", "no.one");
    expectAsset("app|foo.two", "no.two");
    expectNoAsset("app|foo.txt");
    buildShouldSucceed();
  });

  test("a transform consumes its input and emits nothing", () {
    initGraph([
      "app|foo.txt"
    ], {
      "app": [[new EmitNothingTransformer("txt")..consumePrimary = true]]
    });

    updateSources(["app|foo.txt"]);
    expectNoAsset("app|foo.txt");
    buildShouldSucceed();
  });

  test("a transform consumes its input, then is removed", () {
    initGraph([
      "app|foo.txt"
    ], {
      "app": [[new RewriteTransformer("txt", "out")..consumePrimary = true]]
    });

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.out", "foo.out");
    expectNoAsset("app|foo.txt");
    buildShouldSucceed();

    updateTransformers("app", [[]]);
    expectNoAsset("app|foo.out");
    expectAsset("app|foo.txt", "foo");
    buildShouldSucceed();
  });

  test("a transform consumes its input and emits nothing, then is removed",
      () {
    initGraph([
      "app|foo.txt"
    ], {
      "app": [[new EmitNothingTransformer("txt")..consumePrimary = true]]
    });

    updateSources(["app|foo.txt"]);
    expectNoAsset("app|foo.txt");
    buildShouldSucceed();

    updateTransformers("app", [[]]);
    expectAsset("app|foo.txt", "foo");
    buildShouldSucceed();
  });

  test("a transform which consumes its input is added", () {
    initGraph([
      "app|foo.txt"
    ], {
      "app": [[]]
    });

    updateSources(["app|foo.txt"]);
    expectNoAsset("app|foo.out");
    expectAsset("app|foo.txt", "foo");
    buildShouldSucceed();

    updateTransformers("app", [[
      new RewriteTransformer("txt", "out")..consumePrimary = true
    ]]);
    expectAsset("app|foo.out", "foo.out");
    expectNoAsset("app|foo.txt");
    buildShouldSucceed();
  });
}