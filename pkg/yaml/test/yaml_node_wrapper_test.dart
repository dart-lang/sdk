// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library yaml.node_wrapper_test;

import 'package:source_maps/source_maps.dart';
import 'package:unittest/unittest.dart';
import 'package:yaml/yaml.dart';

main() {
  test("YamlMap() with no sourceUrl", () {
    var map = new YamlMap();
    expect(map, isEmpty);
    expect(map.nodes, isEmpty);
    expect(map.span, isNullSpan(isNull));
  });

  test("YamlMap() with a sourceUrl", () {
    var map = new YamlMap(sourceUrl: "source");
    expect(map.span, isNullSpan("source"));
  });

  test("YamlList() with no sourceUrl", () {
    var list = new YamlList();
    expect(list, isEmpty);
    expect(list.nodes, isEmpty);
    expect(list.span, isNullSpan(isNull));
  });

  test("YamlList() with a sourceUrl", () {
    var list = new YamlList(sourceUrl: "source");
    expect(list.span, isNullSpan("source"));
  });

  test("YamlMap.wrap() with no sourceUrl", () {
    var map = new YamlMap.wrap({
      "list": [1, 2, 3],
      "map": {
        "foo": "bar",
        "nested": [4, 5, 6]
      },
      "scalar": "value"
    });

    expect(map, equals({
      "list": [1, 2, 3],
      "map": {
        "foo": "bar",
        "nested": [4, 5, 6]
      },
      "scalar": "value"
    }));

    expect(map.span, isNullSpan(isNull));
    expect(map["list"], new isInstanceOf<YamlList>());
    expect(map["list"].nodes[0], new isInstanceOf<YamlScalar>());
    expect(map["list"].span, isNullSpan(isNull));
    expect(map["map"], new isInstanceOf<YamlMap>());
    expect(map["map"].nodes["foo"], new isInstanceOf<YamlScalar>());
    expect(map["map"]["nested"], new isInstanceOf<YamlList>());
    expect(map["map"].span, isNullSpan(isNull));
    expect(map.nodes["scalar"], new isInstanceOf<YamlScalar>());
    expect(map.nodes["scalar"].value, "value");
    expect(map.nodes["scalar"].span, isNullSpan(isNull));
    expect(map["scalar"], "value");
    expect(map.keys, unorderedEquals(["list", "map", "scalar"]));
    expect(map.nodes.keys, everyElement(new isInstanceOf<YamlScalar>()));
    expect(map.nodes[new YamlScalar.wrap("list")], equals([1, 2, 3]));
  });

  test("YamlMap.wrap() with a sourceUrl", () {
    var map = new YamlMap.wrap({
      "list": [1, 2, 3],
      "map": {
        "foo": "bar",
        "nested": [4, 5, 6]
      },
      "scalar": "value"
    }, sourceUrl: "source");

    expect(map.span, isNullSpan("source"));
    expect(map["list"].span, isNullSpan("source"));
    expect(map["map"].span, isNullSpan("source"));
    expect(map.nodes["scalar"].span, isNullSpan("source"));
  });

  test("YamlList.wrap() with no sourceUrl", () {
    var list = new YamlList.wrap([
      [1, 2, 3],
      {
        "foo": "bar",
        "nested": [4, 5, 6]
      },
      "value"
    ]);

    expect(list, equals([
      [1, 2, 3],
      {
        "foo": "bar",
        "nested": [4, 5, 6]
      },
      "value"
    ]));

    expect(list.span, isNullSpan(isNull));
    expect(list[0], new isInstanceOf<YamlList>());
    expect(list[0].nodes[0], new isInstanceOf<YamlScalar>());
    expect(list[0].span, isNullSpan(isNull));
    expect(list[1], new isInstanceOf<YamlMap>());
    expect(list[1].nodes["foo"], new isInstanceOf<YamlScalar>());
    expect(list[1]["nested"], new isInstanceOf<YamlList>());
    expect(list[1].span, isNullSpan(isNull));
    expect(list.nodes[2], new isInstanceOf<YamlScalar>());
    expect(list.nodes[2].value, "value");
    expect(list.nodes[2].span, isNullSpan(isNull));
    expect(list[2], "value");
  });

  test("YamlList.wrap() with a sourceUrl", () {
    var list = new YamlList.wrap([
      [1, 2, 3],
      {
        "foo": "bar",
        "nested": [4, 5, 6]
      },
      "value"
    ]);

    expect(list.span, isNullSpan(isNull));
    expect(list[0].span, isNullSpan(isNull));
    expect(list[1].span, isNullSpan(isNull));
    expect(list.nodes[2].span, isNullSpan(isNull));
  });

  solo_test("re-wrapped objects equal one another", () {
    var list = new YamlList.wrap([
      [1, 2, 3],
      {"foo": "bar"}
    ]);

    expect(list[0] == list[0], isTrue);
    expect(list[0].nodes == list[0].nodes, isTrue);
    expect(list[0] == new YamlList.wrap([1, 2, 3]), isFalse);
    expect(list[1] == list[1], isTrue);
    expect(list[1].nodes == list[1].nodes, isTrue);
    expect(list[1] == new YamlMap.wrap({"foo": "bar"}), isFalse);
  });
}

Matcher isNullSpan(sourceUrl) => predicate((span) {
  expect(span, new isInstanceOf<Span>());
  expect(span.length, equals(0));
  expect(span.text, isEmpty);
  expect(span.isIdentifier, isFalse);
  expect(span.start, equals(span.end));
  expect(span.start.offset, equals(0));
  expect(span.start.line, equals(0));
  expect(span.start.column, equals(0));
  expect(span.sourceUrl, sourceUrl);
  return true;
});
