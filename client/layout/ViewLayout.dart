// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** The interface that the layout algorithms use to talk to the view. */
interface Positionable {
  ViewLayout get layout();

  /** Gets our custom CSS properties, as provided by the CSS preprocessor. */
  Map<String, String> get customStyle();

  /** Gets the root DOM used for layout. */
  Element get node();

  /** Gets the collection of child views. */
  Collection<Positionable> get childViews();

  /** Causes a view to layout its children. */
  void doLayout();
}


/**
 * Caches the layout parameters that were specified in CSS during a layout
 * computation. These values are immutable during a layout.
 */
class LayoutParams {
  // TODO(jmesserly): should be const, but there's a bug in DartC preventing us
  // from calling "window." in an initializer. See b/5332777
  CSSStyleDeclaration style;

  int get layer() => 0;

  LayoutParams(Element node) {
    style = window.getComputedStyle(node, '');
  }
}

// TODO(jmesserly): enums would really help here
class Dimension {
  // TODO(jmesserly): perhaps this should be X and Y
  static final WIDTH = const Dimension._internal('width');
  static final HEIGHT = const Dimension._internal('height');

  final String name; // for debugging
  const Dimension._internal(this.name);
}

class ContentSizeMode {
  /** Minimum content size, e.g. min-width and min-height in CSS. */
  static final MIN = const ContentSizeMode._internal('min');

  /** Maximum content size, e.g. min-width and min-height in CSS. */
  static final MAX = const ContentSizeMode._internal('max');

  // TODO(jmesserly): we probably want some sort of "auto" or "best fit" mode
  // Don't need it yet though.

  final String name; // for debugging
  const ContentSizeMode._internal(this.name);
}

/**
 * Abstract base class for View layout. Tracks relevant layout state.
 * This code was inspired by code in Android's View.java; it's needed for the
 * rest of the layout system.
 */
class ViewLayout {
  /**
   * The layout parameters associated with this view and used by the parent
   * to determine how this view should be laid out.
   */
  LayoutParams layoutParams;

  /** The view that this layout belongs to. */
  final Positionable view;

  /**
   * To get a perforant positioning model on top of the DOM, we read all
   * properties in the first pass while computing positions. Then we have a
   * second pass that actually moves everything.
   */
  int _measuredLeft, _measuredTop, _measuredWidth, _measuredHeight;

  ViewLayout(this.view) {}

  /**
   * Creates the appropriate view layout, depending on the properties.
   */
  // TODO(jmesserly): we should support user defined layouts somehow. Perhaps
  // registered with a LayoutProvider.
  factory ViewLayout.fromView(Positionable view) {
    if (hasCustomLayout(view)) {
      return new GridLayout(view);
    } else {
      return new ViewLayout(view);
    }
  }

  static bool hasCustomLayout(Positionable view) {
    return view.customStyle['display'] == "-dart-grid";
  }

  CSSStyleDeclaration get _style() => layoutParams.style;

  int get currentWidth() => view.node.offsetWidth;
  int get currentHeight() => view.node.offsetHeight;

  int get borderLeftWidth() => _toPixels(_style.borderLeftWidth);
  int get borderTopWidth() => _toPixels(_style.borderTopWidth);
  int get borderRightWidth() => _toPixels(_style.borderRightWidth);
  int get borderBottomWidth() => _toPixels(_style.borderBottomWidth);
  int get borderWidth() => borderLeftWidth + borderRightWidth;
  int get borderHeight() => borderTopWidth + borderBottomWidth;

  /** Implements the custom layout computation. */
  bool measureLayout(int width, int height) => false;

  /**
   * Positions the view within its parent container.
   * Also performs a layout of its children.
   */
  void setBounds(int left, int top, int width, int height) {
    assert(width >= 0 && height >= 0);

    _measuredLeft = left;
    _measuredTop = top;

    // Note: we need to save the client height
    _measuredWidth = width - borderWidth;
    _measuredHeight = height - borderHeight;

    measureLayout(_measuredWidth, _measuredHeight);
  }

  /** Applies the layout to the node. */
  void applyLayout() {
    if (_measuredLeft != null) {
      // TODO(jmesserly): benchmark the performance of this DOM interaction
      final style = view.node.style;
      style.position = 'absolute';
      style.left = '${_measuredLeft}px';
      style.top = '${_measuredTop}px';
      style.width = '${_measuredWidth}px';
      style.height = '${_measuredHeight}px';
      style.zIndex = '${layoutParams.layer}';

      _measuredLeft = null;
      _measuredTop = null;
      _measuredWidth = null;
      _measuredHeight = null;

      // Ensure we can handle our custom layout when it is a child of a
      // DOM-positioned node. For example, say we have a View tree like this:
      //
      //   ViewWithLayout   <-- uses our layout engine
      //     childView1     <-- is positioned by our layout engine, but uses
      //                        HTML layout internally
      //       childOfChild <-- uses our layout engine for its own children
      if (!hasCustomLayout(view)) {
        for (final child in view.childViews) {
          child.doLayout();
        }
      }
    }
  }

  int measureContent(ViewLayout parent, Dimension dimension,
                     [ContentSizeMode mode = null]) {
    switch (dimension) {
      case Dimension.WIDTH:
        return measureWidth(parent, mode);
      case Dimension.HEIGHT:
        return measureHeight(parent, mode);
    }
  }

  int measureWidth(ViewLayout parent, ContentSizeMode mode) {
    final style = layoutParams.style;
    switch (mode) {
      case ContentSizeMode.MIN:
        return _styleToPixels(
            style.minWidth, currentWidth, parent.currentWidth);

      case ContentSizeMode.MAX:
        return _styleToPixels(
            style.maxWidth, currentWidth, parent.currentWidth);
    }
  }

  int measureHeight(ViewLayout parent, ContentSizeMode mode) {
    final style = layoutParams.style;
    switch (mode) {
      case ContentSizeMode.MIN:
        return _styleToPixels(
            style.minHeight, currentHeight, parent.currentHeight);

      case ContentSizeMode.MAX:
        return _styleToPixels(
            style.maxHeight, currentHeight, parent.currentHeight);
    }
  }

  static int _toPixels(String style) {
    if (style.endsWith('px')) {
      return Math.parseInt(style.substring(0, style.length - 2));
    } else {
      // TODO(jmesserly): other size units
      throw new UnsupportedOperationException(
          'Unknown min/max content size format: "$style"');
    }
  }

  static int _styleToPixels(String style, num size, num parentSize) {
    if (style == 'none') {
      // For an unset max-content size, use the actual size
      return size;
    }
    if (style.endsWith('%')) {
      num percent = Math.parseDouble(style.substring(0, style.length - 1));
      return ((percent / 100) * parentSize).toInt();
    }
    return _toPixels(style);
  }
}
