// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:svg' as svg;

import 'package:expect/minitest.dart';

Node makeNode() => new Element.tag('div');
Element makeNodeWithChildren() =>
    new Element.html("<div>Foo<br/><!--baz--></div>");

void testUnsupported(String name, void f()) {
  test(name, () {
    expect(f, throwsUnsupportedError);
  });
}

main() {
  var isText = predicate((x) => x is Text, 'is a Text');
  var isComment = predicate((x) => x is Comment, 'is a Comment');
  var isBRElement = predicate((x) => x is BRElement, 'is a BRElement');
  var isHRElement = predicate((x) => x is HRElement, 'is a HRElement');
  var isNodeList = predicate((x) => x is List<Node>, 'is a List<Node>');
  var isImageElement =
      predicate((x) => x is ImageElement, 'is an ImageElement');
  var isInputElement =
      predicate((x) => x is InputElement, 'is an InputElement');

  group('functional', () {
    test('toString', () {
      final nodes = makeNodeWithChildren();
      // TODO(efortuna): Update this test when you have actual toString methods
      // for the items in the node List as well.
      expect(nodes.nodes.toString(), "[Foo, br, baz]");
      final node = makeNode();
      expect(node.nodes.toString(), '[]');
    });

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

    test('append', () {
      var node = makeNode();
      node.append(new Element.tag('hr'));
      expect(node.nodes.last, isHRElement);
    });

    test('remove', () {
      final node = makeNodeWithChildren();
      final subnode = node.nodes[1];
      subnode.remove();
      expect(node.nodes.length, 2);
      expect(node.nodes[0], isText);
      expect(node.nodes[1], isComment);
    });

    test('contains', () {
      final Node node =
          new Element.html("<div>Foo<span><div>Bar<div></span></div>");
      // IE10 returns false for contains of nodes.
      //expect(node.contains(node.nodes.first), isTrue);
      expect(node.contains(node.nodes[1].nodes.first), isTrue);
      expect(node.contains(new Text('Foo')), isFalse);
    });

    test('insertAllBefore', () {
      var node = makeNodeWithChildren();
      var b = new DivElement();
      b.nodes.addAll([new HRElement(), new ImageElement(), new InputElement()]);
      node.insertAllBefore(b.nodes, node.nodes[1]);
      expect(node.nodes[0], isText);
      expect(node.nodes[1], isHRElement);
      expect(node.nodes[2], isImageElement);
      expect(node.nodes[3], isInputElement);
      expect(node.nodes[4], isBRElement);
      expect(node.nodes[5], isComment);

      var nodes = [new HRElement(), new ImageElement(), new InputElement()];
      node.insertAllBefore(nodes, node.nodes[5]);

      expect(node.nodes[0], isText);
      expect(node.nodes[1], isHRElement);
      expect(node.nodes[2], isImageElement);
      expect(node.nodes[3], isInputElement);
      expect(node.nodes[4], isBRElement);
      expect(node.nodes[5], isHRElement);
      expect(node.nodes[6], isImageElement);
      expect(node.nodes[7], isInputElement);
      expect(node.nodes[8], isComment);
    });
  });

  group('nodes', () {
    test('is a NodeList', () {
      expect(makeNodeWithChildren().nodes, isNodeList);
    });

    test('indexer', () {
      var node = new DivElement();
      expect(() {
        node.nodes[0];
      }, throwsRangeError);

      expect(() {
        node.nodes[-1];
      }, throwsRangeError);
    });

    test('first', () {
      var node = makeNodeWithChildren();
      expect(node.nodes.first, isText);

      node = new DivElement();
      expect(() {
        node = node.nodes.first;
      }, throwsStateError);
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

    test('where', () {
      var filtered =
          makeNodeWithChildren().nodes.where((n) => n is BRElement).toList();
      expect(filtered.length, 1);
      expect(filtered[0], isBRElement);
      expect(filtered, isNodeList);
    });

    test('every', () {
      var node = makeNodeWithChildren();
      expect(node.nodes.every((n) => n is Node), isTrue);
      expect(node.nodes.every((n) => n is Comment), isFalse);
    });

    test('any', () {
      var node = makeNodeWithChildren();
      expect(node.nodes.any((n) => n is Comment), isTrue);
      expect(node.nodes.any((n) => n is svg.SvgElement), isFalse);
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

      var a = makeNodeWithChildren();
      var b = makeNodeWithChildren();
      var childrenLength = a.children.length + b.children.length;
      var nodesLength = a.nodes.length + b.nodes.length;

      a.children.addAll(b.children);
      expect(b.children.length, 0);
      expect(a.children.length, childrenLength);

      b.nodes.addAll(a.children);
      expect(a.children.length, 0);
      expect(b.children.length, childrenLength);

      a.nodes.addAll(b.nodes);
      expect(b.nodes.length, 0);
      expect(a.nodes.length, nodesLength);
    });

    test('insert', () {
      var node = new DivElement();
      node.nodes.insert(0, new BRElement());
      expect(node.nodes[0], isBRElement);
      node.nodes.insert(0, new HRElement());
      expect(node.nodes[0], isHRElement);
      node.nodes.insert(1, new ImageElement());
      expect(node.nodes[1], isImageElement);
      node.nodes.insert(node.nodes.length, new InputElement());
      expect(node.nodes.last, isInputElement);
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
      var items = makeNodeWithChildren().nodes.getRange(0, 1);
      expect(items.length, 1);
      expect(items.first, isText);
    });

    test('sublist', () {
      var node = makeNodeWithChildren();
      expect(node.nodes.sublist(1, 3), isNodeList);
    });

    test('insertAll', () {
      var node = makeNodeWithChildren();
      var b = new DivElement();
      b.nodes.addAll([new HRElement(), new ImageElement(), new InputElement()]);
      node.nodes.insertAll(1, b.nodes);
      expect(node.nodes[0], isText);
      expect(node.nodes[1], isHRElement);
      expect(node.nodes[2], isImageElement);
      expect(node.nodes[3], isInputElement);
      expect(node.nodes[4], isBRElement);
      expect(node.nodes[5], isComment);

      var nodes = [new HRElement(), new ImageElement(), new InputElement()];
      node.nodes.insertAll(5, nodes);

      expect(node.nodes[0], isText);
      expect(node.nodes[1], isHRElement);
      expect(node.nodes[2], isImageElement);
      expect(node.nodes[3], isInputElement);
      expect(node.nodes[4], isBRElement);
      expect(node.nodes[5], isHRElement);
      expect(node.nodes[6], isImageElement);
      expect(node.nodes[7], isInputElement);
      expect(node.nodes[8], isComment);

      var d = new DivElement();
      var ns = d.nodes;
      // `insertAll` should work when positioned at end.
      ns.insertAll(ns.length, [new HRElement()]);
      expect(ns.length, 1);
      expect(ns[0], isHRElement);
    });

    testUnsupported('removeRange', () {
      makeNodeWithChildren().nodes.removeRange(0, 1);
    });

    testUnsupported('replaceRange', () {
      makeNodeWithChildren().nodes.replaceRange(0, 1, [new InputElement()]);
    });

    testUnsupported('fillRange', () {
      makeNodeWithChildren().nodes.fillRange(0, 1, null);
    });

    testUnsupported('setAll', () {
      makeNodeWithChildren().nodes.setAll(0, [new InputElement()]);
    });
  });

  group('iterating', () {
    test('NodeIterator', () {
      var root = makeNodeWithChildren();
      var nodeIterator = new NodeIterator(root, NodeFilter.SHOW_COMMENT);
      expect(nodeIterator.nextNode(), isComment);
      expect(nodeIterator.nextNode(), isNull);
    });

    test('TreeWalker', () {
      var root = makeNodeWithChildren();
      var treeWalker = new TreeWalker(root, NodeFilter.SHOW_COMMENT);
      expect(treeWalker.nextNode(), isComment);
      expect(treeWalker.nextNode(), isNull);
    });
  });
}
