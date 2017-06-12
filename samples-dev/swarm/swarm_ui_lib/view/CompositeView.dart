// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of view;

/**
 * A View that is composed of child views.
 */
class CompositeView extends View {
  List<View> childViews;

  // TODO(rnystrom): Allowing this to be public is gross. CompositeView should
  // encapsulate its markup and provide accessors to do the limited amount of
  // things that external users need to access this for.
  Element container;

  Scroller scroller;
  Scrollbar _scrollbar;

  final String _cssName;
  final bool _scrollable;
  final bool _vertical;
  final bool _nestedContainer;
  final bool _showScrollbar;

  CompositeView(String this._cssName,
      [nestedContainer = false,
      scrollable = false,
      vertical = false,
      showScrollbar = false])
      : super(),
        _nestedContainer = nestedContainer,
        _scrollable = scrollable,
        _vertical = vertical,
        _showScrollbar = showScrollbar,
        childViews = new List<View>() {}

  Element render() {
    Element node = new Element.html('<div class="$_cssName"></div>');

    if (_nestedContainer) {
      container = new Element.html('<div class="scroll-container"></div>');
      node.nodes.add(container);
    } else {
      container = node;
    }

    if (_scrollable) {
      scroller = new Scroller(
          container,
          _vertical /* verticalScrollEnabled */,
          !_vertical /* horizontalScrollEnabled */,
          true /* momementumEnabled */);
      if (_showScrollbar) {
        _scrollbar = new Scrollbar(scroller);
      }
    }

    for (View childView in childViews) {
      container.nodes.add(childView.node);
    }

    return node;
  }

  void afterRender(Element node) {
    if (_scrollbar != null) {
      _scrollbar.initialize();
    }
  }

  View addChild(View view) {
    childViews.add(view);
    // TODO(rnystrom): Container shouldn't be null. Remove this check.
    if (container != null) {
      container.nodes.add(view.node);
    }
    childViewAdded(view);
    return view;
  }

  void removeChild(View view) {
    childViews = childViews.where((e) {
      return view != e;
    }).toList();
    // TODO(rnystrom): Container shouldn't be null. Remove this check.
    if (container != null) {
      view.node.remove();
    }
  }
}
