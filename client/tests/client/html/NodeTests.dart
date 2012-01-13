// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


Node makeNode() => new Element.tag('div');
Node makeNodeWithChildren() =>
  new Element.html("<div>Foo<br/><!--baz--></div>");

void testNode() {
  group('nodes', () {
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

    group('setRange', () {
      test('one node', () {
        var node = makeNodeWithChildren();
        node.nodes.setRange(1, 1, [new Element.tag('hr')]);
        Expect.isTrue(node.nodes[0] is Text);
        Expect.isTrue(node.nodes[1] is HRElement);
        Expect.isTrue(node.nodes[2] is Comment);
      });

      test('several nodes', () {
        var node = makeNodeWithChildren();
        node.nodes.setRange(1, 2, [
          new Element.tag('hr'), new Element.tag('img')]);
        Expect.isTrue(node.nodes[0] is Text);
        Expect.isTrue(node.nodes[1] is HRElement);
        Expect.isTrue(node.nodes[2] is ImageElement);
      });

      test('fewer than all source nodes', () {
        var node = makeNodeWithChildren();
        node.nodes.setRange(1, 1, [
          new Element.tag('hr'), new Element.tag('img')]);
        Expect.isTrue(node.nodes[0] is Text);
        Expect.isTrue(node.nodes[1] is HRElement);
        Expect.isTrue(node.nodes[2] is Comment);
      });

      test('startFrom', () {
        var node = makeNodeWithChildren();
        node.nodes.setRange(1, 1, [
          new Element.tag('hr'), new Element.tag('img')], 1);
        Expect.isTrue(node.nodes[0] is Text);
        Expect.isTrue(node.nodes[1] is ImageElement);
        Expect.isTrue(node.nodes[2] is Comment);
      });

      test('negative length', () {
        var node = makeNodeWithChildren();
        Expect.throws(
            () => node.nodes.setRange(1, -1, [new Element.tag('hr')]),
            (e) => e is IllegalArgumentException);
      });

      test('off the end of dest', () {
        var node = makeNodeWithChildren();
        Expect.throws(() {
          node.nodes.setRange(2, 2, [
            new Element.tag('hr'), new Element.tag('img')]);
        }, (e) => e is IndexOutOfRangeException);
      });

      test('off the beginning of dest', () {
        var node = makeNodeWithChildren();
        Expect.throws(
            () => node.nodes.setRange(-1, 1, [new Element.tag('hr')]),
            (e) => e is IndexOutOfRangeException);
      });

      test('off the end of source', () {
        var node = makeNodeWithChildren();
        Expect.throws(
            () => node.nodes.setRange(1, 2, [new Element.tag('hr')]),
            (e) => e is IndexOutOfRangeException);
      });

      test('off the beginning of source', () {
        var node = makeNodeWithChildren();
        Expect.throws(
            () => node.nodes.setRange(1, 1, [new Element.tag('hr')], -1),
            (e) => e is IndexOutOfRangeException);
      });
    });

    group('removeRange', () {
      test('one node', () {
        var node = makeNodeWithChildren();
        node.nodes.removeRange(1, 1);
        Expect.equals(2, node.nodes.length);
        Expect.isTrue(node.nodes[0] is Text);
        Expect.isTrue(node.nodes[1] is Comment);
      });

      test('two nodes', () {
        var node = makeNodeWithChildren();
        node.nodes.removeRange(1, 2);
        Expect.equals(1, node.nodes.length);
        Expect.isTrue(node.nodes[0] is Text);
      });

      test('all nodes', () {
        var node = makeNodeWithChildren();
        node.nodes.removeRange(0, 3);
        Expect.isTrue(node.nodes.isEmpty());
      });

      test('negative length', () {
        var node = makeNodeWithChildren();
        Expect.throws(
            () => node.nodes.removeRange(2, -1),
            (e) => e is IllegalArgumentException);
      });

      test('off the end', () {
        var node = makeNodeWithChildren();
        Expect.throws(
            () => node.nodes.removeRange(2, 3),
            (e) => e is IndexOutOfRangeException);
      });

      test('off the beginning', () {
        var node = makeNodeWithChildren();
        Expect.throws(
            () => node.nodes.removeRange(-1, 1),
            (e) => e is IndexOutOfRangeException);
      });
    });

    group('getRange', () {
      test('one node', () {
        var range = makeNodeWithChildren().nodes.getRange(2, 1);
        Expect.equals(1, range.length);
        Expect.isTrue(range[0] is Comment);
      });

      test('two nodes', () {
        var range = makeNodeWithChildren().nodes.getRange(1, 2);
        Expect.equals(2, range.length);
        Expect.isTrue(range[0] is BRElement);
        Expect.isTrue(range[1] is Comment);
      });

      test('negative length', () {
        Expect.throws(
            () => makeNodeWithChildren().nodes.getRange(2, -1),
            (e) => e is IllegalArgumentException);
      });

      test('off the end', () {
        Expect.throws(
            () => makeNodeWithChildren().nodes.getRange(2, 2),
            (e) => e is IndexOutOfRangeException);
      });

      test('off the beginning', () {
        Expect.throws(
            () => makeNodeWithChildren().nodes.getRange(-1, 2),
            (e) => e is IndexOutOfRangeException);
      });
    });

    test('indexOf', () {
      var node = makeNodeWithChildren();
      Expect.equals(0, node.nodes.indexOf(node.nodes[0]));
      Expect.equals(1, node.nodes.indexOf(node.nodes[1]));
      Expect.equals(2, node.nodes.indexOf(node.nodes[2]));
      Expect.equals(-1, node.nodes.indexOf(new Element.tag('br')));
      Expect.equals(1, node.nodes.indexOf(node.nodes[1], 1));
      Expect.equals(-1, node.nodes.indexOf(node.nodes[1], 2));
    });

    test('lastIndexOf', () {
      var node = makeNodeWithChildren();
      Expect.equals(0, node.nodes.lastIndexOf(node.nodes[0]));
      Expect.equals(1, node.nodes.lastIndexOf(node.nodes[1]));
      Expect.equals(2, node.nodes.lastIndexOf(node.nodes[2]));
      Expect.equals(-1, node.nodes.lastIndexOf(new Element.tag('br')));
      Expect.equals(1, node.nodes.lastIndexOf(node.nodes[1], 1));
      Expect.equals(-1, node.nodes.lastIndexOf(node.nodes[1], 0));
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
  });
}
