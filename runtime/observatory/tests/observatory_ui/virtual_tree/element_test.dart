// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/containers/virtual_collection.dart';
import 'package:observatory/src/elements/containers/virtual_tree.dart';

main() {
  VirtualTreeElement.tag.ensureRegistration();

  final cTag = VirtualCollectionElement.tag.name;

  var container;
  setUp(() {
    container = document.body.getElementsByClassName('test_container').first;
  });
  group('instantiation', () {
    test('default', () {
      final e = new VirtualTreeElement((_) {}, (_1, _2, _3) {}, (_) {});
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.items, isNotNull, reason: 'items not null');
      expect(e.items, isEmpty, reason: 'no items');
    });
    test('items: []', () {
      final items = ["1", 2, {}];
      final e =
          new VirtualTreeElement((_) {}, (_1, _2, _3) {}, (_) {}, items: items);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.items, isNot(same(items)), reason: 'avoid side effect');
      expect(e.items, equals(items), reason: 'same items');
    });
  });
  test('elements created after attachment', () async {
    final create = (toggle) => new DivElement()..classes = ['test_item'];
    final update = (HtmlElement el, item, depth) {
      el.text = item.toString();
    };
    final children = (item) => [];
    final items = ["1", 2, {}];
    final e = new VirtualTreeElement(create, update, children);
    container.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    expect(e.querySelectorAll(cTag).length, same(1));
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
  test('expand single child', () async {
    const max_depth = 100000;
    final create = (toggle) => new DivElement()..classes = ['test_item'];
    final update = (HtmlElement el, item, depth) {
      el.text = item.toString();
    };
    final children = (item) => item >= max_depth ? [] : [item + 1];
    final items = [0];
    final e = new VirtualTreeElement(create, update, children, items: items);
    container.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    final VirtualCollectionElement collection = e.querySelectorAll(cTag).first;
    expect(collection.items.length, equals(1), reason: 'begin');
    e.expand(0, autoExpandSingleChildNodes: true);
    await e.onRendered.first;
    expect(collection.items.length, equals(max_depth + 1), reason: 'expanded');
    e.collapse(0, autoCollapseSingleChildNodes: true);
    await e.onRendered.first;
    expect(collection.items.length, equals(1), reason: 'collapsed');
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });

  test('expand whole tree', () async {
    const max_depth = 100000;
    final create = (toggle) => new DivElement()..classes = ['test_item'];
    final update = (HtmlElement el, item, depth) {
      el.text = item.toString();
    };
    // We want to generated a tree that doesn't collapse to a chain of items
    // while avoiding to generate an exponential number of items
    final children = (item) {
      if (item < 2 * max_depth) {
        if (item % 200 == 0) {
          return [item + 1, item + 2];
        } else if (item % 2 == 0) {
          return [item + 2];
        }
      }
      return [];
    };
    final items = [0];
    final e = new VirtualTreeElement(create, update, children, items: items);
    container.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    final VirtualCollectionElement collection = e.querySelectorAll(cTag).first;
    expect(collection.items.length, equals(1), reason: 'begin');
    e.expand(0, autoExpandWholeTree: true);
    await e.onRendered.first;
    expect(collection.items.length, equals(max_depth + max_depth / 100 + 1),
        reason: 'expanded');
    e.collapse(0, autoCollapseWholeTree: true);
    await e.onRendered.first;
    expect(collection.items.length, equals(1), reason: 'collapsed');
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
}
