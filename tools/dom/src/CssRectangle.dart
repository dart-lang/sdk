// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

/**
 * A rectangle representing all the content of the element in the
 * [box model](http://www.w3.org/TR/CSS2/box.html).
 */
class _ContentCssRect extends CssRect {
  _ContentCssRect(Element element) : super(element);

  num get height =>
      _element.offsetHeight + _addOrSubtractToBoxModel(_HEIGHT, _CONTENT);

  num get width =>
      _element.offsetWidth + _addOrSubtractToBoxModel(_WIDTH, _CONTENT);

  /**
   * Set the height to `newHeight`.
   *
   * newHeight can be either a [num] representing the height in pixels or a
   * [Dimension] object. Values of newHeight that are less than zero are
   * converted to effectively setting the height to 0. This is equivalent to the
   * `height` function in jQuery and the calculated `height` CSS value,
   * converted to a num in pixels.
   */
  set height(dynamic newHeight) {
    if (newHeight is Dimension) {
      if (newHeight.value < 0) newHeight = new Dimension.px(0);
      _element.style.height = newHeight.toString();
    } else if (newHeight is num) {
      if (newHeight < 0) newHeight = 0;
      _element.style.height = '${newHeight}px';
    } else {
      throw new ArgumentError("newHeight is not a Dimension or num");
    }
  }

  /**
   * Set the current computed width in pixels of this element.
   *
   * newWidth can be either a [num] representing the width in pixels or a
   * [Dimension] object. This is equivalent to the `width` function in jQuery
   * and the calculated
   * `width` CSS value, converted to a dimensionless num in pixels.
   */
  set width(dynamic newWidth) {
    if (newWidth is Dimension) {
      if (newWidth.value < 0) newWidth = new Dimension.px(0);
      _element.style.width = newWidth.toString();
    } else if (newWidth is num) {
      if (newWidth < 0) newWidth = 0;
      _element.style.width = '${newWidth}px';
    } else {
      throw new ArgumentError("newWidth is not a Dimension or num");
    }
  }

  num get left =>
      _element.getBoundingClientRect().left -
      _addOrSubtractToBoxModel(['left'], _CONTENT);
  num get top =>
      _element.getBoundingClientRect().top -
      _addOrSubtractToBoxModel(['top'], _CONTENT);
}

/**
 * A list of element content rectangles in the
 * [box model](http://www.w3.org/TR/CSS2/box.html).
 */
class _ContentCssListRect extends _ContentCssRect {
  List<Element> _elementList;

  _ContentCssListRect(List<Element> elementList) : super(elementList.first) {
    _elementList = elementList;
  }

  /**
   * Set the height to `newHeight`.
   *
   * Values of newHeight that are less than zero are converted to effectively
   * setting the height to 0. This is equivalent to the `height`
   * function in jQuery and the calculated `height` CSS value, converted to a
   * num in pixels.
   */
  set height(newHeight) {
    _elementList.forEach((e) => e.contentEdge.height = newHeight);
  }

  /**
   * Set the current computed width in pixels of this element.
   *
   * This is equivalent to the `width` function in jQuery and the calculated
   * `width` CSS value, converted to a dimensionless num in pixels.
   */
  set width(newWidth) {
    _elementList.forEach((e) => e.contentEdge.width = newWidth);
  }
}

/**
 * A rectangle representing the dimensions of the space occupied by the
 * element's content + padding in the
 * [box model](http://www.w3.org/TR/CSS2/box.html).
 */
class _PaddingCssRect extends CssRect {
  _PaddingCssRect(element) : super(element);
  num get height =>
      _element.offsetHeight + _addOrSubtractToBoxModel(_HEIGHT, _PADDING);
  num get width =>
      _element.offsetWidth + _addOrSubtractToBoxModel(_WIDTH, _PADDING);

  num get left =>
      _element.getBoundingClientRect().left -
      _addOrSubtractToBoxModel(['left'], _PADDING);
  num get top =>
      _element.getBoundingClientRect().top -
      _addOrSubtractToBoxModel(['top'], _PADDING);
}

/**
 * A rectangle representing the dimensions of the space occupied by the
 * element's content + padding + border in the
 * [box model](http://www.w3.org/TR/CSS2/box.html).
 */
class _BorderCssRect extends CssRect {
  _BorderCssRect(element) : super(element);
  num get height => _element.offsetHeight;
  num get width => _element.offsetWidth;

  num get left => _element.getBoundingClientRect().left;
  num get top => _element.getBoundingClientRect().top;
}

/**
 * A rectangle representing the dimensions of the space occupied by the
 * element's content + padding + border + margin in the
 * [box model](http://www.w3.org/TR/CSS2/box.html).
 */
class _MarginCssRect extends CssRect {
  _MarginCssRect(element) : super(element);
  num get height =>
      _element.offsetHeight + _addOrSubtractToBoxModel(_HEIGHT, _MARGIN);
  num get width =>
      _element.offsetWidth + _addOrSubtractToBoxModel(_WIDTH, _MARGIN);

  num get left =>
      _element.getBoundingClientRect().left -
      _addOrSubtractToBoxModel(['left'], _MARGIN);
  num get top =>
      _element.getBoundingClientRect().top -
      _addOrSubtractToBoxModel(['top'], _MARGIN);
}

/**
 * A class for representing CSS dimensions.
 *
 * In contrast to the more general purpose [Rectangle] class, this class's
 * values are mutable, so one can change the height of an element
 * programmatically.
 *
 * _Important_ _note_: use of these methods will perform CSS calculations that
 * can trigger a browser reflow. Therefore, use of these properties _during_ an
 * animation frame is discouraged. See also:
 * [Browser Reflow](https://developers.google.com/speed/articles/reflow)
 */
abstract class CssRect implements Rectangle<num> {
  Element _element;

  CssRect(this._element);

  num get left;

  num get top;

  /**
   * The height of this rectangle.
   *
   * This is equivalent to the `height` function in jQuery and the calculated
   * `height` CSS value, converted to a dimensionless num in pixels. Unlike
   * [getBoundingClientRect], `height` will return the same numerical width if
   * the element is hidden or not.
   */
  num get height;

  /**
   * The width of this rectangle.
   *
   * This is equivalent to the `width` function in jQuery and the calculated
   * `width` CSS value, converted to a dimensionless num in pixels. Unlike
   * [getBoundingClientRect], `width` will return the same numerical width if
   * the element is hidden or not.
   */
  num get width;

  /**
   * Set the height to `newHeight`.
   *
   * newHeight can be either a [num] representing the height in pixels or a
   * [Dimension] object. Values of newHeight that are less than zero are
   * converted to effectively setting the height to 0. This is equivalent to the
   * `height` function in jQuery and the calculated `height` CSS value,
   * converted to a num in pixels.
   *
   * Note that only the content height can actually be set via this method.
   */
  set height(dynamic newHeight) {
    throw new UnsupportedError("Can only set height for content rect.");
  }

  /**
   * Set the current computed width in pixels of this element.
   *
   * newWidth can be either a [num] representing the width in pixels or a
   * [Dimension] object. This is equivalent to the `width` function in jQuery
   * and the calculated
   * `width` CSS value, converted to a dimensionless num in pixels.
   *
   * Note that only the content width can be set via this method.
   */
  set width(dynamic newWidth) {
    throw new UnsupportedError("Can only set width for content rect.");
  }

  /**
   * Return a value that is used to modify the initial height or width
   * measurement of an element. Depending on the value (ideally an enum) passed
   * to augmentingMeasurement, we may need to add or subtract margin, padding,
   * or border values, depending on the measurement we're trying to obtain.
   */
  num _addOrSubtractToBoxModel(
      List<String> dimensions, String augmentingMeasurement) {
    // getComputedStyle always returns pixel values (hence, computed), so we're
    // always dealing with pixels in this method.
    var styles = _element.getComputedStyle();

    var val = 0;

    for (String measurement in dimensions) {
      // The border-box and default box model both exclude margin in the regular
      // height/width calculation, so add it if we want it for this measurement.
      if (augmentingMeasurement == _MARGIN) {
        val += new Dimension.css(
                styles.getPropertyValue('$augmentingMeasurement-$measurement'))
            .value;
      }

      // The border-box includes padding and border, so remove it if we want
      // just the content itself.
      if (augmentingMeasurement == _CONTENT) {
        val -= new Dimension.css(
                styles.getPropertyValue('${_PADDING}-$measurement'))
            .value;
      }

      // At this point, we don't wan't to augment with border or margin,
      // so remove border.
      if (augmentingMeasurement != _MARGIN) {
        val -= new Dimension.css(
                styles.getPropertyValue('border-${measurement}-width'))
            .value;
      }
    }
    return val;
  }

  // TODO(jacobr): these methods are duplicated from _RectangleBase in dart:math
  // Ideally we would provide a RectangleMixin class that provides this implementation.
  // In an ideal world we would exp
  /** The x-coordinate of the right edge. */
  num get right => left + width;
  /** The y-coordinate of the bottom edge. */
  num get bottom => top + height;

  String toString() {
    return 'Rectangle ($left, $top) $width x $height';
  }

  bool operator ==(other) {
    if (other is! Rectangle) return false;
    return left == other.left &&
        top == other.top &&
        right == other.right &&
        bottom == other.bottom;
  }

  int get hashCode => _JenkinsSmiHash.hash4(
      left.hashCode, top.hashCode, right.hashCode, bottom.hashCode);

  /**
   * Computes the intersection of `this` and [other].
   *
   * The intersection of two axis-aligned rectangles, if any, is always another
   * axis-aligned rectangle.
   *
   * Returns the intersection of this and `other`, or `null` if they don't
   * intersect.
   */
  Rectangle<num> intersection(Rectangle<num> other) {
    var x0 = max(left, other.left);
    var x1 = min(left + width, other.left + other.width);

    if (x0 <= x1) {
      var y0 = max(top, other.top);
      var y1 = min(top + height, other.top + other.height);

      if (y0 <= y1) {
        return new Rectangle<num>(x0, y0, x1 - x0, y1 - y0);
      }
    }
    return null;
  }

  /**
   * Returns true if `this` intersects [other].
   */
  bool intersects(Rectangle<num> other) {
    return (left <= other.left + other.width &&
        other.left <= left + width &&
        top <= other.top + other.height &&
        other.top <= top + height);
  }

  /**
   * Returns a new rectangle which completely contains `this` and [other].
   */
  Rectangle<num> boundingBox(Rectangle<num> other) {
    var right = max(this.left + this.width, other.left + other.width);
    var bottom = max(this.top + this.height, other.top + other.height);

    var left = min(this.left, other.left);
    var top = min(this.top, other.top);

    return new Rectangle<num>(left, top, right - left, bottom - top);
  }

  /**
   * Tests whether `this` entirely contains [another].
   */
  bool containsRectangle(Rectangle<num> another) {
    return left <= another.left &&
        left + width >= another.left + another.width &&
        top <= another.top &&
        top + height >= another.top + another.height;
  }

  /**
   * Tests whether [another] is inside or along the edges of `this`.
   */
  bool containsPoint(Point<num> another) {
    return another.x >= left &&
        another.x <= left + width &&
        another.y >= top &&
        another.y <= top + height;
  }

  Point<num> get topLeft => new Point<num>(this.left, this.top);
  Point<num> get topRight => new Point<num>(this.left + this.width, this.top);
  Point<num> get bottomRight =>
      new Point<num>(this.left + this.width, this.top + this.height);
  Point<num> get bottomLeft =>
      new Point<num>(this.left, this.top + this.height);
}

final _HEIGHT = ['top', 'bottom'];
final _WIDTH = ['right', 'left'];
final _CONTENT = 'content';
final _PADDING = 'padding';
final _MARGIN = 'margin';
