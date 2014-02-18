// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

/**
 * A rectangle representing all the content of the element in the
 * [box model](http://www.w3.org/TR/CSS2/box.html).
 */
class _ContentCssRect extends CssRect {

  _ContentCssRect(element) : super(element);

  num get height => _element.offsetHeight +
      _addOrSubtractToBoxModel(_HEIGHT, _CONTENT);

  num get width => _element.offsetWidth +
      _addOrSubtractToBoxModel(_WIDTH, _CONTENT);

  /**
   * Set the height to `newHeight`.
   *
   * newHeight can be either a [num] representing the height in pixels or a
   * [Dimension] object. Values of newHeight that are less than zero are
   * converted to effectively setting the height to 0. This is equivalent to the
   * `height` function in jQuery and the calculated `height` CSS value,
   * converted to a num in pixels.
   */
  void set height(newHeight) {
    if (newHeight is Dimension) {
      if (newHeight.value < 0) newHeight = new Dimension.px(0);
      _element.style.height = newHeight.toString();
    } else {
      if (newHeight < 0) newHeight = 0;
      _element.style.height = '${newHeight}px';
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
  void set width(newWidth) {
    if (newWidth is Dimension) {
      if (newWidth.value < 0) newWidth = new Dimension.px(0);
      _element.style.width = newWidth.toString();
    } else {
      if (newWidth < 0) newWidth = 0;
      _element.style.width = '${newWidth}px';
    }
  }

  num get left => _element.getBoundingClientRect().left -
      _addOrSubtractToBoxModel(['left'], _CONTENT);
  num get top => _element.getBoundingClientRect().top -
      _addOrSubtractToBoxModel(['top'], _CONTENT);
}

/**
 * A list of element content rectangles in the
 * [box model](http://www.w3.org/TR/CSS2/box.html).
 */
class _ContentCssListRect extends _ContentCssRect {
  List<Element> _elementList;

  _ContentCssListRect(elementList) : super(elementList.first) {
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
  void set height(newHeight) {
    _elementList.forEach((e) => e.contentEdge.height = newHeight);
  }

  /**
   * Set the current computed width in pixels of this element.
   *
   * This is equivalent to the `width` function in jQuery and the calculated
   * `width` CSS value, converted to a dimensionless num in pixels.
   */
  void set width(newWidth) {
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
  num get height => _element.offsetHeight +
      _addOrSubtractToBoxModel(_HEIGHT, _PADDING);
  num get width => _element.offsetWidth +
      _addOrSubtractToBoxModel(_WIDTH, _PADDING);

  num get left => _element.getBoundingClientRect().left -
      _addOrSubtractToBoxModel(['left'], _PADDING);
  num get top => _element.getBoundingClientRect().top -
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
  num get height => _element.offsetHeight +
      _addOrSubtractToBoxModel(_HEIGHT, _MARGIN);
  num get width =>
      _element.offsetWidth + _addOrSubtractToBoxModel(_WIDTH, _MARGIN);

  num get left => _element.getBoundingClientRect().left -
      _addOrSubtractToBoxModel(['left'], _MARGIN);
  num get top => _element.getBoundingClientRect().top -
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
abstract class CssRect extends MutableRectangle<num> {
  Element _element;

  CssRect(this._element) : super(0, 0, 0, 0);

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
  void set height(newHeight) {
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
  void set width(newWidth) {
    throw new UnsupportedError("Can only set width for content rect.");
  }

  /**
   * Return a value that is used to modify the initial height or width
   * measurement of an element. Depending on the value (ideally an enum) passed
   * to augmentingMeasurement, we may need to add or subtract margin, padding,
   * or border values, depending on the measurement we're trying to obtain.
   */
  num _addOrSubtractToBoxModel(List<String> dimensions,
      String augmentingMeasurement) {
    // getComputedStyle always returns pixel values (hence, computed), so we're
    // always dealing with pixels in this method.
    var styles = _element.getComputedStyle();

    var val = 0;

    for (String measurement in dimensions) {
      // The border-box and default box model both exclude margin in the regular
      // height/width calculation, so add it if we want it for this measurement.
      if (augmentingMeasurement == _MARGIN) {
        val += new Dimension.css(styles.getPropertyValue(
            '$augmentingMeasurement-$measurement')).value;
      }

      // The border-box includes padding and border, so remove it if we want
      // just the content itself.
      if (augmentingMeasurement == _CONTENT) {
      	val -= new Dimension.css(
            styles.getPropertyValue('${_PADDING}-$measurement')).value;
      }

      // At this point, we don't wan't to augment with border or margin,
      // so remove border.
      if (augmentingMeasurement != _MARGIN) {
	      val -= new Dimension.css(styles.getPropertyValue(
            'border-${measurement}-width')).value;
      }
    }
    return val;
  }
}

final _HEIGHT = ['top', 'bottom'];
final _WIDTH = ['right', 'left'];
final _CONTENT = 'content';
final _PADDING = 'padding';
final _MARGIN = 'margin';
