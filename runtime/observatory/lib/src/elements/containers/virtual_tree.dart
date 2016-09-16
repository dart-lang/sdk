// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'dart:math' as Math;
import 'package:observatory/src/elements/containers/virtual_collection.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';

typedef HtmlElement VirtualTreeCreateCallback(
    toggle({bool autoToggleSingleChildNodes, bool autoToggleWholeTree}));
typedef void VirtualTreeUpdateCallback(HtmlElement el, dynamic item, int depth);
typedef Iterable<dynamic> VritualTreeGetChildrenCallback(dynamic value);

void virtualTreeUpdateLines(SpanElement element, int n) {
  n = Math.max(0, n);
  while (element.children.length > n) {
    element.children.removeLast();
  }
  while (element.children.length < n) {
    element.children.add(new SpanElement());
  }
}

class VirtualTreeElement extends HtmlElement implements Renderable {
  static const tag = const Tag<VirtualTreeElement>('virtual-tree',
      dependencies: const [VirtualCollectionElement.tag]);

  RenderingScheduler<VirtualTreeElement> _r;

  Stream<RenderedEvent<VirtualTreeElement>> get onRendered => _r.onRendered;

  VritualTreeGetChildrenCallback _children;
  List _items;
  List _depths;
  final Set _expanded = new Set();

  List get items => _items;

  set items(Iterable value) {
    _items = new List.unmodifiable(value);
    _expanded.clear();
    _r.dirty();
  }

  factory VirtualTreeElement(VirtualTreeCreateCallback create,
      VirtualTreeUpdateCallback update, VritualTreeGetChildrenCallback children,
      {Iterable items: const [], RenderingQueue queue}) {
    assert(create != null);
    assert(update != null);
    assert(children != null);
    assert(items != null);
    VirtualTreeElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._children = children;
    e._collection = new VirtualCollectionElement(() {
      var element;
      return element = create((
          {bool autoToggleSingleChildNodes: false,
          bool autoToggleWholeTree: false}) {
        var item = e._collection.getItemFromElement(element);
        if (e.isExpanded(item)) {
          e.collapse(item,
              autoCollapseWholeTree: autoToggleWholeTree,
              autoCollapseSingleChildNodes: autoToggleSingleChildNodes);
        } else {
          e.expand(item,
              autoExpandWholeTree: autoToggleWholeTree,
              autoExpandSingleChildNodes: autoToggleSingleChildNodes);
        }
      });
    }, (HtmlElement el, dynamic item, int index) {
      update(el, item, e._depths[index]);
    }, queue: queue);
    e._items = new List.unmodifiable(items);
    return e;
  }

  VirtualTreeElement.created() : super.created();

  bool isExpanded(item) {
    return _expanded.contains(item);
  }

  void expand(item,
      {bool autoExpandSingleChildNodes: false,
      bool autoExpandWholeTree: false}) {
    if (_expanded.add(item)) _r.dirty();
    if (autoExpandWholeTree) {
      for (final child in _children(item)) {
        expand(child, autoExpandWholeTree: true);
      }
    } else if (autoExpandSingleChildNodes) {
      var children = _children(item);
      while (children.length == 1) {
        _expanded.add(children.first);
        children = _children(children.first);
      }
    }
  }

  void collapse(item,
      {bool autoCollapseSingleChildNodes: false,
      bool autoCollapseWholeTree: false}) {
    if (_expanded.remove(item)) _r.dirty();
    if (autoCollapseWholeTree) {
      for (final child in _children(item)) {
        collapse(child, autoCollapseWholeTree: true);
      }
    } else if (autoCollapseSingleChildNodes) {
      var children = _children(item);
      while (children.length == 1) {
        _expanded.remove(children.first);
        children = _children(children.first);
      }
    }
  }

  @override
  attached() {
    super.attached();
    _r.enable();
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    children = const [];
  }

  VirtualCollectionElement _collection;

  void render() {
    if (children.length == 0) {
      children = [_collection];
    }
    Iterable _toList(item) {
      if (isExpanded(item)) {
        Iterable children = _children(item);
        if (children.isNotEmpty) {
          return [item]..addAll(children.expand(_toList));
        }
      }
      return [item];
    }

    _collection.items = _items.expand(_toList);
    var depth = 0;
    Iterable _toDepth(item) {
      if (isExpanded(item)) {
        Iterable children = _children(item);
        if (children.isNotEmpty) {
          depth++;
          return children.expand(_toDepth).toList()..insert(0, --depth);
        }
      }
      return [depth];
    }

    _depths = _items.expand(_toDepth).toList();
  }
}
