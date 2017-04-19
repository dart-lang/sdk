// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of touch;

/**
 * Click buster implementation, which is a behavior that prevents native clicks
 * from firing at undesirable times. There are two scenarios where we may want
 * to 'bust' a click.
 *
 * Buttons implemented with touch events usually have click handlers as well.
 * This is because sometimes touch events stop working, and the click handler
 * serves as a fallback. Here we use a click buster to prevent the native click
 * from firing if the touchend event was succesfully handled.
 *
 * When native scrolling behavior is disabled (see Scroller), click events will
 * fire after the touchend event when the drag sequence is complete. The click
 * event also happens to fire at the location of the touchstart event which can
 * lead to some very strange behavior.
 *
 * This class puts a single click handler on the body, and calls preventDefault
 * on the click event if we detect that there was a touchend event that already
 * fired in the same spot recently.
 */
class ClickBuster {
  /**
   * The threshold for how long we allow a click to occur after a touchstart.
   */
  static const _TIME_THRESHOLD = 2500;

  /**
   * The threshold for how close a click has to be to the saved coordinate for
   * us to allow it.
   */
  static const _DISTANCE_THRESHOLD = 25;

  /**
   * The list of coordinates that we use to measure the distance of clicks from.
   * If a click is within the distance threshold of any of these coordinates
   * then we allow the click.
   */
  static DoubleLinkedQueue<num> _coordinates;

  /** The last time preventGhostClick was called. */
  static int _lastPreventedTime;

  /**
   * This handler will prevent the default behavior for any clicks unless the
   * click is within the distance threshold of one of the temporary allowed
   * coordinates.
   */
  static void _onClick(Event e) {
    if (TimeUtil.now() - _lastPreventedTime > _TIME_THRESHOLD) {
      return;
    }
    final coord = new Coordinate.fromClient(e);
    // TODO(rnystrom): On Android, we get spurious click events at (0, 0). We
    // *do* want those clicks to be busted, so commenting this out fixes it.
    // Leaving it commented out instead of just deleting it because I'm not sure
    // what this code was intended to do to begin with.
    /*
    if (coord.x < 1 && coord.y < 1) {
      // TODO(jacobr): implement a configurable logging framework.
      // _logger.warning(
      //     "Not busting click on label elem at(${coord.x}, ${coord.y})");
      return;
    }
    */
    DoubleLinkedQueueEntry<num> entry = _coordinates.firstEntry();
    while (entry != null) {
      if (_hitTest(
          entry.element, entry.nextEntry().element, coord.x, coord.y)) {
        entry.nextEntry().remove();
        entry.remove();
        return;
      } else {
        entry = entry.nextEntry().nextEntry();
      }
    }

    // TODO(jacobr): implement a configurable logging framework.
    // _logger.warning("busting click at ${coord.x}, ${coord.y}");
    e.stopPropagation();
    e.preventDefault();
  }

  /**
   * This handler will temporarily allow a click to occur near the touch event's
   * coordinates.
   */
  static void _onTouchStart(Event e) {
    TouchEvent te = e;
    final coord = new Coordinate.fromClient(te.touches[0]);
    _coordinates.add(coord.x);
    _coordinates.add(coord.y);
    new Timer(const Duration(milliseconds: _TIME_THRESHOLD), () {
      _removeCoordinate(coord.x, coord.y);
    });
    _toggleTapHighlights(true);
  }

  /**
   * Hit test for whether a coordinate is within the distance threshold of an
   * event.
   */
  static bool _hitTest(num x, num y, num eventX, num eventY) {
    return (eventX - x).abs() < _DISTANCE_THRESHOLD &&
        (eventY - y).abs() < _DISTANCE_THRESHOLD;
  }

  /**
   * Remove one specified coordinate from the coordinates list.
   */
  static void _removeCoordinate(num x, num y) {
    DoubleLinkedQueueEntry<num> entry = _coordinates.firstEntry();
    while (entry != null) {
      if (entry.element == x && entry.nextEntry().element == y) {
        entry.nextEntry().remove();
        entry.remove();
        return;
      } else {
        entry = entry.nextEntry().nextEntry();
      }
    }
  }

  /**
   * Enable or disable tap highlights. They are disabled when preventGhostClick
   * is called so that the flicker on links is not invoked when the ghost click
   * does fire. This is due to a bug: links get highlighted even if the click
   * event has preventDefault called on it.
   */
  static void _toggleTapHighlights(bool enable) {
    document.body.style.setProperty(
        "-webkit-tap-highlight-color", enable ? "" : "rgba(0,0,0,0)", "");
  }

  /**
   * Registers new touches to create temporary "allowable zones" and registers
   * new clicks to be prevented unless they fall in one of the current
   * "allowable zones". Note that if the touchstart and touchend locations are
   * different, it is still possible for a ghost click to be fired if you
   * called preventDefault on all touchmove events. In this case the ghost
   * click will be fired at the location of the touchstart event, so the
   * coordinate you pass in should be the coordinate of the touchstart.
   */
  static void preventGhostClick(num x, num y) {
    // First time this is called the following occurs:
    //   1) Attaches a handler to touchstart events so that each touch will
    //      temporarily create an "allowable zone" for clicks to occur in.
    //   2) Attaches a handler to click events so that each click will be
    //      prevented unless it is in an "allowable zone".
    //
    // Every time this is called (including the first) the following occurs:
    //   1) Removes an allowable zone that contains the specified coordinate.
    //
    // How this enables click busting:
    //   1) User performs first click.
    //     - No attached touchstart handler yet.
    //     - preventGhostClick is called before the click event occurs, it
    //       attaches the touchstart and click handlers.
    //     - The click handler captures the user's click event and prevents it
    //       from propagating since there is no "allowable zone".
    //
    //   2) User performs subsequent, to-be-busted click.
    //     - touchstart event triggers the attached handler and creates a
    //       temporary "allowable zone".
    //     - preventGhostClick is called and removes the "allowable zone".
    //     - The click handler captures the user's click event and prevents it
    //       from propagating since there is no "allowable zone".
    //
    //   3) User performs a should-not-be-busted click.
    //     - touchstart event triggers the attached handler and creates a
    //       temporary "allowable zone".
    //     - The click handler captures the user's click event and allows it to
    //       propagate since the click falls in the "allowable zone".
    if (_coordinates == null) {
      // Listen to clicks on capture phase so they can be busted before anything
      // else gets a chance to handle them.
      Element.clickEvent.forTarget(document, useCapture: true).listen((e) {
        _onClick(e);
      });
      Element.focusEvent.forTarget(document, useCapture: true).listen((e) {
        _lastPreventedTime = 0;
      });

      // Listen to touchstart on capture phase since it must be called prior to
      // every click or else we will accidentally prevent the click even if we
      // don't call preventGhostClick.
      Function startFn = (e) {
        _onTouchStart(e);
      };
      if (!Device.supportsTouch) {
        startFn = mouseToTouchCallback(startFn);
      }
      var stream;
      if (Device.supportsTouch) {
        stream = Element.touchStartEvent.forTarget(document, useCapture: true);
      } else {
        stream = Element.mouseDownEvent.forTarget(document, useCapture: true);
      }
      EventUtil.observe(document, stream, startFn, true);
      _coordinates = new DoubleLinkedQueue<num>();
    }

    // Turn tap highlights off until we know the ghost click has fired.
    _toggleTapHighlights(false);

    // Above all other rules, we won't bust any clicks if there wasn't some call
    // to preventGhostClick in the last time threshold.
    _lastPreventedTime = TimeUtil.now();
    DoubleLinkedQueueEntry<num> entry = _coordinates.firstEntry();
    while (entry != null) {
      if (_hitTest(entry.element, entry.nextEntry().element, x, y)) {
        entry.nextEntry().remove();
        entry.remove();
        return;
      } else {
        entry = entry.nextEntry().nextEntry();
      }
    }
  }
}
