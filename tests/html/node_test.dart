// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library NodeTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:html';

Node makeNode() => new Element.tag('div');
Node makeNodeWithChildren() =>
  new Element.html("<div>Foo<br/><!--baz--></div>");

main() {
  useHtmlIndividualConfiguration();

  var isText = predicate((x) => x is Text, 'is a Text');
  var isComment = predicate((x) => x is Comment, 'is a Comment');
  var isBRElement = predicate((x) => x is BRElement, 'is a BRElement');
  var isHRElement = predicate((x) => x is HRElement, 'is a HRElement');
  var isNodeList = predicate((x) => x is List<Node>, 'is a List<Node>');
  var isImageElement =
      predicate((x) => x is ImageElement, 'is an ImageElement');
  var isInputElement =
      predicate((x) => x is InputElement, 'is an InputElement');

  test('replaceWith', () {
    final node = makeNodeWithChildren();
    final subnode = node.nodes[1];
    final out = subnode.replaceWith(new Text('Bar'));
    expect(out, equals(subnode), reason: '#replaceWith should be chainable');
    expect(node.nodes.length, 3);
    expect(node.nodes[0], isText);
    expect(node.nodes[0].text, 'Foo');
    expect(node.nodes[1], isText);
    expect(node.nodes[1].text, 'Bar');
    expect(node.nodes[2], isComment);
  });

  test('remove', () {
    final node = makeNodeWithChildren();
    final subnode = node.nodes[1];
    final out = subnode.remove();
    expect(out, isNull);
    expect(node.nodes.length, 2);
    expect(node.nodes[0], isText);
    expect(node.nodes[1], isComment);
  });

  test('contains', () {
    final Node node = new Element.html("<div>Foo<span>Bar</span></div>");
    expect(node.contains(node.nodes.first), isTrue);
    expect(node.contains(node.nodes[1].nodes.first), isTrue);
    expect(node.contains(new Text('Foo')), isFalse);
  });

  group('nodes', () {
    test('is a NodeList', () {
      expect(makeNodeWithChildren().nodes, isNodeList);
    });

    test('first', () {
      var node = makeNodeWithChildren();
      expect(node.nodes.first, isText);
    });

    test('last', () {
      var node = makeNodeWithChildren();
      expect(node.nodes.last, isComment);
    });

    test('forEach', () {
      var nodes = [];
      var node = makeNodeWithChildren();
      node.nodes.forEach((n) => nodes.add(n));
      expect(nodes[0], isText);
      expect(nodes[1], isBRElement);
      expect(nodes[2], isComment);
    });

    test('filter', () {
      var filtered = makeNodeWithChildren().nodes.filter((n) => n is BRElement);
      expect(filtered.length, 1);
      expect(filtered[0], isBRElement);
      expect(filtered, isNodeList);
    });

    test('every', () {
      var node = makeNodeWithChildren();
      expect(node.nodes.every((n) => n is Node), isTrue);
      expect(node.nodes.every((n) => n is Comment), isFalse);
    });

    test('some', () {
      var node = makeNodeWithChildren();
      expect(node.nodes.some((n) => n is Comment), isTrue);
      expect(node.nodes.some((n) => n is SVGElement), isFalse);
    });

    test('isEmpty', () {
      expect(makeNode().nodes.isEmpty, isTrue);
      expect(makeNodeWithChildren().nodes.isEmpty, isFalse);
    });

    test('length', () {
      expect(makeNode().nodes.length, 0);
      expect(makeNodeWithChildren().nodes.length, 3);
    });

    test('[]', () {
      var node = makeNodeWithChildren();
      expect(node.nodes[0], isText);
      expect(node.nodes[1], isBRElement);
      expect(node.nodes[2], isComment);
    });

    test('[]=', () {
      var node = makeNodeWithChildren();
      node.nodes[1] = new Element.tag('hr');
      expect(node.nodes[0], isText);
      expect(node.nodes[1], isHRElement);
      expect(node.nodes[2], isComment);
    });

    test('add', () {
      var node = makeNode();
      node.nodes.add(new Element.tag('hr'));
      expect(node.nodes.last, isHRElement);
    });

    test('addLast', () {
      var node = makeNode();
      node.nodes.addLast(new Element.tag('hr'));
      expect(node.nodes.last, isHRElement);
    });

    test('iterator', () {
      var nodes = [];
      var node = makeNodeWithChildren();
      for (var subnode in node.nodes) {
        nodes.add(subnode);
      }
      expect(nodes[0], isText);
      expect(nodes[1], isBRElement);
      expect(nodes[2], isComment);
    });

    test('addAll', () {
      var node = makeNodeWithChildren();
      node.nodes.addAll([
        new Element.tag('hr'),
        new Element.tag('img'),
        new Element.tag('input')
      ]);
      expect(node.nodes[0], isText);
      expect(node.nodes[1], isBRElement);
      expect(node.nodes[2], isComment);
      expect(node.nodes[3], isHRElement);
      expect(node.nodes[4], isImageElement);
      expect(node.nodes[5], isInputElement);
    });

    test('clear', () {
      var node = makeNodeWithChildren();
      node.nodes.clear();
      expect(node.nodes, []);
    });

    test('removeLast', () {
      var node = makeNodeWithChildren();
      expect(node.nodes.removeLast(), isComment);
      expect(node.nodes.length, 2);
      expect(node.nodes.removeLast(), isBRElement);
      expect(node.nodes.length, 1);
    });

    test('getRange', () {
      var node = makeNodeWithChildren();
      expect(node.nodes.getRange(1, 2), isNodeList);
    });
  });

  group('_NodeList', () {
    List<Node> makeNodeList() =>
      makeNodeWithChildren().nodes.filter((_) => true);

    test('first', () {
      var nodes = makeNodeList();
      expect(nodes.first, isText);
    });

    test('filter', () {
      var filtered = makeNodeList().filter((n) => n is BRElement);
      expect(filtered.length, 1);
      expect(filtered[0], isBRElement);
      expect(filtered, isNodeList);
    });

    test('getRange', () {
      var range = makeNodeList().getRange(1, 2);
      expect(range, isNodeList);
      expect(range[0], isBRElement);
      expect(range[1], isComment);
    });
  });
}
