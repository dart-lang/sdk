// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Common effects related helpers.
 */
class FxUtil {
  /** On transition end event. */
  static final TRANSITION_END_EVENT = 'webkitTransitionEnd';

  /** The translate3d transform function. */
  static final TRANSLATE_3D = 'translate3d';

  /** The rotate transform function. */
  static final ROTATE = 'rotate';

  /** The scale transform function. */
  static final SCALE = 'scale';

  /**
   * Apply a -webkit-transition on an element using the [duration] of this
   * animation in ms.
   */
  static void setWebkitTransition(
      Element el, num duration,
      [String property = StyleUtil.TRANSFORM_STYLE,
       String timingFunction = TransitionTimingFunction.EASE_IN_OUT]) {
    el.style.transition = '${property} ${duration}ms ${timingFunction}';
  }

  /** Stops and clears the transition on an element. */
  static void clearWebkitTransition(Element el) {
    el.style.transition = '';
  }

  static void setPosition(Element el, Coordinate point) {
    num x = point.x;
    num y = point.y;
    el.style.transform = '${TRANSLATE_3D}(${x}px,${y}px,0px)';
  }

  /** Apply a transform using translate3d to an HTML element. */
  static void setTranslate(Element el, num x, num y, num z) {
    el.style.transform = '${TRANSLATE_3D}(${x}px,${y}px,${z}px)';
  }

  /** Apply a -webkit-transform using translate3d to an HTML element. */
  static void setWebkitTransform(
      Element el, num x, num y, [num z = 0,
      num rotation = null, num scale = null,
      num originX = null, num originY = null]) {
    final style = el.style;
    // TODO(jacobr): create a helper class that simplifies building
    // transformation matricies that will be set as CSS styles. We should
    // consider using CSSMatrix although that may be overkill.
    String transform = '${TRANSLATE_3D}(${x}px,${y}px,${z}px)';
    if (rotation !== null) {
      transform = transform.concat(' ${ROTATE}(${rotation}deg)');
    }
    if (scale !== null) {
      transform = transform.concat(' ${SCALE}(${scale})');
    }
    style.transform = transform;
    if (originX !== null || originY !== null) {
      assert(originX !== null && originY !== null);
      style.transformOrigin = '${originX}px ${originY}px';
    }
  }

  /**
   * Determine the position of an [element] relative to a [target] element.
   * Moving the [element] to be a child of [target] and setting the
   * [element]'s top and left values to the returned coordinate should result
   * in the [element]'s position remaining unchanged while its parent is
   * changed.
   */
  static Coordinate computeRelativePosition(Element element, Element target) {
    final testPoint = new Point(0, 0);
    final pagePoint =
        window.webkitConvertPointFromNodeToPage(element, testPoint);
    final pointRelativeToTarget =
        window.webkitConvertPointFromPageToNode(target, pagePoint);
    return new Coordinate(pointRelativeToTarget.x, pointRelativeToTarget.y);
  }

  /** Clear a -webkit-transform from an element. */
  static void clearWebkitTransform(Element el) {
    el.style.transform = '';
  }

  /**
   * Checks whether an element has a translate3d webkit transform applied.
   */
  static bool hasWebkitTransform(Element el) {
    return el.style.transform.indexOf(TRANSLATE_3D, 0) != -1;
  }

  /**
   * Translates [el], an HTML element that has a relative CSS
   * position, by setting its left and top CSS styles.
   */
  static void setLeftAndTop(Element el, num x, num y) {
    final style = el.style;
    style.left = '${x}px';
    style.top = '${y}px';
  }
}


/**
 * Utilities for element styles.
 */
class StyleUtil {
  // TODO(jacobr): Need a good way to set this to -moz, or -o names.
  /** Style name for transform. */
  static final TRANSFORM_STYLE = '-webkit-transform';

  /**
   * Retrieves a computed style value of a node.
   *
   * Limitations:
   * - Does not report border styles correctly in Webkit.
   */
  static CSSStyleDeclaration getComputedStyle(Element element) {
    // TODO(jmesserly): last param should be null, see b/5045788
    return window.getComputedStyle(element, '');
  }

  /** Retrieves the current transform of an element. */
  static CSSMatrix getCurrentTransformMatrix(Element element) {
    // TODO(jacobr): when poossible switch back to
    // return new CSSMatrix(transform);
    return new CSSMatrix(
        getComputedStyle(element).transform);
  }
}

class TransitionTimingFunction {
  static final EASE_IN = 'ease-in';
  static final EASE_OUT = 'ease-out';
  static final EASE_IN_OUT = 'ease-in-out';
}
