// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('NodeTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

Node makeNode() => new Element.tag('div');
Node makeNodeWithChildren() =>
  new Element.html("<div>Foo<br/><!--baz--></div>");

main() {
  useHtmlConfiguration();

  test('replaceWith', () {
    final node = makeNodeWithChildren();
    final subnode = node.nodes[1];
    final out = subnode.replaceWith(new Text('Bar'));
    Expect.equals(subnode, out, '#replaceWith should be chainable');
    Expect.equals(3, node.nodes.length);
    Expect.isTrue(node.nodes[0] is Text);
    Expect.equals('Foo', node.nodes[0].text);
    Expect.isTrue(node.nodes[1] is Text);
    Expect.equals('Bar', node.nodes[1].text);
    Expect.isTrue(node.nodes[2] is Comment);
  });

  test('remove', () {
    final node = makeNodeWithChildren();
    final subnode = node.nodes[1];
    final out = subnode.remove();
    Expect.isNull(out);
    Expect.equals(2, node.nodes.length);
    Expect.isTrue(node.nodes[0] is Text);
    Expect.isTrue(node.nodes[1] is Comment);
  });

  test('contains', () {
    final Node node = new Element.html("<div>Foo<span>Bar</span></div>");
    Expect.isTrue(node.contains(node.nodes.first));
    Expect.isTrue(node.contains(node.nodes[1].nodes.first));
    Expect.isFalse(node.contains(new Text('Foo')));
  });

  group('nodes', () {
    test('is a NodeList', () {
      Expect.isTrue(makeNodeWithChildren().nodes is List<Node>);
    });

    test('first', () {
      var node = makeNodeWithChildren();
      Expect.isTrue(node.nodes.first is Text);
    });

    test('last', () {
      var node = makeNodeWithChildren();
      Expect.isTrue(node.nodes.last() is Comment);
    });

    test('forEach', () {
      var nodes = [];
      var node = makeNodeWithChildren();
      node.nodes.forEach((n) => nodes.add(n));
      Expect.isTrue(nodes[0] is Text);
      Expect.isTrue(nodes[1] is BRElement);
      Expect.isTrue(nodes[2] is Comment);
    });

    test('filter', () {
      var filtered = makeNodeWithChildren().nodes.filter((n) => n is BRElement);
      Expect.equals(1, filtered.length);
      Expect.isTrue(filtered[0] is BRElement);
      Expect.isTrue(filtered is List<Node>);
    });

    test('every', () {
      var node = makeNodeWithChildren();
      Expect.isTrue(node.nodes.every((n) => n is Node));
      Expect.isFalse(node.nodes.every((n) => n is Comment));
    });

    test('some', () {
      var node = makeNodeWithChildren();
      Expect.isTrue(node.nodes.some((n) => n is Comment));
      Expect.isFalse(node.nodes.some((n) => n is SVGElement));
    });

    test('isEmpty', () {
      Expect.isTrue(makeNode().nodes.isEmpty());
      Expect.isFalse(makeNodeWithChildren().nodes.isEmpty());
    });

    test('length', () {
      Expect.equals(0, makeNode().nodes.length);
      Expect.equals(3, makeNodeWithChildren().nodes.length);
    });

    test('[]', () {
      var node = makeNodeWithChildren();
      Expect.isTrue(node.nodes[0] is Text);
      Expect.isTrue(node.nodes[1] is BRElement);
      Expect.isTrue(node.nodes[2] is Comment);
    });

    test('[]=', () {
      var node = makeNodeWithChildren();
      node.nodes[1] = new Element.tag('hr');
      Expect.isTrue(node.nodes[0] is Text);
      Expect.isTrue(node.nodes[1] is HRElement);
      Expect.isTrue(node.nodes[2] is Comment);
    });

    test('add', () {
      var node = makeNode();
      node.nodes.add(new Element.tag('hr'));
      Expect.isTrue(node.nodes.last() is HRElement);
    });

    test('addLast', () {
      var node = makeNode();
      node.nodes.addLast(new Element.tag('hr'));
      Expect.isTrue(node.nodes.last() is HRElement);
    });

    test('iterator', () {
      var nodes = [];
      var node = makeNodeWithChildren();
      for (var subnode in node.nodes) {
        nodes.add(subnode);
      }
      Expect.isTrue(nodes[0] is Text);
      Expect.isTrue(nodes[1] is BRElement);
      Expect.isTrue(nodes[2] is Comment);
    });

    test('addAll', () {
      var node = makeNodeWithChildren();
      node.nodes.addAll([
        new Element.tag('hr'),
        new Element.tag('img'),
        new Element.tag('input')
      ]);
      Expect.isTrue(node.nodes[0] is Text);
      Expect.isTrue(node.nodes[1] is BRElement);
      Expect.isTrue(node.nodes[2] is Comment);
      Expect.isTrue(node.nodes[3] is HRElement);
      Expect.isTrue(node.nodes[4] is ImageElement);
      Expect.isTrue(node.nodes[5] is InputElement);
    });

    test('clear', () {
      var node = makeNodeWithChildren();
      node.nodes.clear();
      Expect.listEquals([], node.nodes);
    });

    test('removeLast', () {
      var node = makeNodeWithChildren();
      Expect.isTrue(node.nodes.removeLast() is Comment);
      Expect.equals(2, node.nodes.length);
      Expect.isTrue(node.nodes.removeLast() is BRElement);
      Expect.equals(1, node.nodes.length);
    });

    test('getRange', () {
      var node = makeNodeWithChildren();
      Expect.isTrue(node.nodes.getRange(1, 2) is List<Node>);
    });
  });

  group('_NodeList', () {
    List<Node> makeNodeList() =>
      makeNodeWithChildren().nodes.filter((_) => true);

    test('first', () {
      var nodes = makeNodeList();
      Expect.isTrue(nodes.first is Text);
    });

    test('filter', () {
      var filtered = makeNodeList().filter((n) => n is BRElement);
      Expect.equals(1, filtered.length);
      Expect.isTrue(filtered[0] is BRElement);
      Expect.isTrue(filtered is List<Node>);
    });

    test('getRange', () {
      var range = makeNodeList().getRange(1, 2);
      Expect.isTrue(range is List<Node>);
      Expect.isTrue(range[0] is BRElement);
      Expect.isTrue(range[1] is Comment);
    });
  });
}
