// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of touch;

/**
 * Implementation of a scrollbar for the custom scrolling behavior
 * defined in [:Scroller:].
 */
class Scrollbar implements ScrollListener {
  /**
   * The minimum size of scrollbars when not compressed.
   */
  static const _MIN_SIZE = 30;

  /**
   * The minimum compressed size of scrollbars. Scrollbars are compressed when
   * the content is stretching past its boundaries.
   */
  static const _MIN_COMPRESSED_SIZE = 8;
  /** Padding in pixels to add above and bellow the scrollbar. */
  static const _PADDING_LENGTH = 10;
  /**
   * The amount of time to wait before hiding scrollbars after showing them.
   * Measured in ms.
   */
  static const _DISPLAY_TIME = 300;
  static const DRAG_CLASS_NAME = 'drag';

  Scroller _scroller;
  Element _frame;
  bool _scrollInProgress = false;
  bool _scrollBarDragInProgressValue = false;

  /**
   * Cached values of height and width. Keys will be 'height' and 'width'
   * depending on if they are applied to vertical or horizontal scrollbar.
   */
  Map<String, num> _cachedSize;

  /**
   * This bound function will be used as the input to window.setTimeout when
   * scheduling the hiding of the scrollbars.
   */
  Function _boundHideFn;

  Element _verticalElement;
  Element _horizontalElement;

  int _currentScrollStartMouse;
  num _currentScrollStartOffset;
  bool _currentScrollVertical;
  num _currentScrollRatio;
  Timer _timer;

  bool _displayOnHover;
  bool _hovering = false;

  Scrollbar(Scroller scroller, [displayOnHover = true])
      : _displayOnHover = displayOnHover,
        _scroller = scroller,
        _frame = scroller.getFrame(),
        _cachedSize = new Map<String, num>() {
    _boundHideFn = () {
      _showScrollbars(false);
    };
  }

  bool get _scrollBarDragInProgress => _scrollBarDragInProgressValue;

  void set _scrollBarDragInProgress(bool value) {
    _scrollBarDragInProgressValue = value;
    _toggleClass(
        _verticalElement, DRAG_CLASS_NAME, value && _currentScrollVertical);
    _toggleClass(
        _horizontalElement, DRAG_CLASS_NAME, value && !_currentScrollVertical);
  }

  // TODO(jacobr): move this helper method into the DOM.
  void _toggleClass(Element e, String className, bool enabled) {
    if (enabled) {
      if (!e.classes.contains(className)) {
        e.classes.add(className);
      }
    } else {
      e.classes.remove(className);
    }
  }

  /**
   * Initializes elements and event handlers. Must be called after
   * construction and before usage.
   */
  void initialize() {
    // Don't initialize if we have already been initialized.
    // TODO(jacobr): remove this once bugs are fixed and enterDocument is only
    // called once by each view.
    if (_verticalElement != null) {
      return;
    }
    _verticalElement = new Element.html(
        '<div class="touch-scrollbar touch-scrollbar-vertical"></div>');
    _horizontalElement = new Element.html(
        '<div class="touch-scrollbar touch-scrollbar-horizontal"></div>');
    _scroller.addScrollListener(this);

    Element scrollerEl = _scroller.getElement();

    if (!Device.supportsTouch) {
      _addEventListeners(
          _verticalElement, _onStart, _onMove, _onEnd, _onEnd, true);
      _addEventListeners(
          _horizontalElement, _onStart, _onMove, _onEnd, _onEnd, true);
    }

    _scroller.addScrollListener(this);
    _showScrollbars(false);
    _scroller.onScrollerStart.listen(_onScrollerStart);
    _scroller.onScrollerEnd.listen(_onScrollerEnd);
    if (_displayOnHover) {
      // TODO(jacobr): rather than adding all these event listeners we could
      // instead attach a single global event listener and let data in the
      // DOM drive.
      _frame.onClick.listen((Event e) {
        // Always focus on click as one of our children isn't all focused.
        if (!_frame.contains(document.activeElement)) {
          scrollerEl.focus();
        }
      });
      _frame.onMouseOver.listen((Event e) {
        final activeElement = document.activeElement;
        // TODO(jacobr): don't steal focus from a child element or a truly
        // focusable element. Only support stealing focus from another
        // element that was given fake focus.
        if (activeElement is BodyElement ||
            (!_frame.contains(activeElement) && activeElement is DivElement)) {
          scrollerEl.focus();
        }
        if (_hovering == false) {
          _hovering = true;
          _cancelTimeout();
          _showScrollbars(true);
          refresh();
        }
      });
      _frame.onMouseOut.listen((e) {
        _hovering = false;
        // Start hiding immediately if we aren't
        // scrolling or already in the process of
        // hiding the scrollbar
        if (!_scrollInProgress && _timer == null) {
          _boundHideFn();
        }
      });
    }
  }

  void _onStart(/*MouseEvent | Touch*/ e) {
    Element elementOver = e.target;
    if (elementOver == _verticalElement || elementOver == _horizontalElement) {
      _currentScrollVertical = elementOver == _verticalElement;
      if (_currentScrollVertical) {
        _currentScrollStartMouse = e.page.y;
        _currentScrollStartOffset = _scroller.getVerticalOffset();
      } else {
        _currentScrollStartMouse = e.page.x;
        _currentScrollStartOffset = _scroller.getHorizontalOffset();
      }
      _refreshScrollRatio();
      _scrollBarDragInProgress = true;
      _scroller._momentum.abort();
      e.stopPropagation();
    }
  }

  void _refreshScrollRatio() {
    Size contentSize = _scroller._getAdjustedContentSize();
    if (_currentScrollVertical) {
      _refreshScrollRatioHelper(
          _scroller._scrollSize.height, contentSize.height);
    } else {
      _refreshScrollRatioHelper(_scroller._scrollSize.width, contentSize.width);
    }
  }

  void _refreshScrollRatioHelper(num frameSize, num contentSize) {
    num frameTravelDistance = frameSize -
        _defaultScrollSize(frameSize, contentSize) -
        _PADDING_LENGTH * 2;
    if (frameTravelDistance < 0.001) {
      _currentScrollRatio = 0;
    } else {
      _currentScrollRatio = (contentSize - frameSize) / frameTravelDistance;
    }
  }

  void _onMove(/*MouseEvent | Touch*/ e) {
    if (!_scrollBarDragInProgress) {
      return;
    }
    _refreshScrollRatio();
    int coordinate = _currentScrollVertical ? e.page.y : e.page.x;
    num delta = (coordinate - _currentScrollStartMouse) * _currentScrollRatio;
    if (delta != 0) {
      num x;
      num y;
      _currentScrollStartOffset -= delta;
      if (_currentScrollVertical) {
        x = _scroller.getHorizontalOffset();
        y = _currentScrollStartOffset.toInt();
      } else {
        x = _currentScrollStartOffset.toInt();
        y = _scroller.getVerticalOffset();
      }
      _scroller.setPosition(x, y);
    }
    _currentScrollStartMouse = coordinate;
  }

  void _onEnd(UIEvent e) {
    _scrollBarDragInProgress = false;
    // TODO(jacobr): make scrollbar less tightly coupled to the scroller.
    _scroller._onScrollerDragEnd.add(new Event(ScrollerEventType.DRAG_END));
  }

  /**
   * When scrolling ends, schedule a timeout to hide the scrollbars.
   */
  void _onScrollerEnd(Event e) {
    _cancelTimeout();
    _timer =
        new Timer(const Duration(milliseconds: _DISPLAY_TIME), _boundHideFn);
    _scrollInProgress = false;
  }

  void onScrollerMoved(num scrollX, num scrollY, bool decelerating) {
    if (_scrollInProgress == false) {
      // Display the scrollbar and then immediately prepare to hide it...
      _onScrollerStart(null);
      _onScrollerEnd(null);
    }
    updateScrollbars(scrollX, scrollY);
  }

  void refresh() {
    if (_scrollInProgress == false && _hovering == false) {
      // No need to refresh if not visible.
      return;
    }
    _scroller._resize(() {
      updateScrollbars(
          _scroller.getHorizontalOffset(), _scroller.getVerticalOffset());
    });
  }

  void updateScrollbars(num scrollX, num scrollY) {
    Size contentSize = _scroller._getAdjustedContentSize();
    if (_scroller._shouldScrollHorizontally()) {
      num scrollPercentX = _scroller.getHorizontalScrollPercent(scrollX);
      _updateScrollbar(_horizontalElement, scrollX, scrollPercentX,
          _scroller._scrollSize.width, contentSize.width, 'right', 'width');
    }
    if (_scroller._shouldScrollVertically()) {
      num scrollPercentY = _scroller.getVerticalScrollPercent(scrollY);
      _updateScrollbar(_verticalElement, scrollY, scrollPercentY,
          _scroller._scrollSize.height, contentSize.height, 'bottom', 'height');
    }
  }

  /**
   * When scrolling starts, show scrollbars and clear hide intervals.
   */
  void _onScrollerStart(Event e) {
    _scrollInProgress = true;
    _cancelTimeout();
    _showScrollbars(true);
  }

  void _cancelTimeout() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
  }

  /**
   * Show or hide the scrollbars by changing the opacity.
   */
  void _showScrollbars(bool show) {
    if (_hovering == true && _displayOnHover) {
      show = true;
    }
    _toggleOpacity(_verticalElement, show);
    _toggleOpacity(_horizontalElement, show);
  }

  _toggleOpacity(Element element, bool show) {
    if (show) {
      element.style.removeProperty("opacity");
    } else {
      element.style.opacity = '0';
    }
  }

  num _defaultScrollSize(num frameSize, num contentSize) {
    return GoogleMath.clamp(
        (frameSize - _PADDING_LENGTH * 2) * frameSize / contentSize,
        _MIN_SIZE,
        frameSize - _PADDING_LENGTH * 2);
  }

  /**
   * Update the vertical or horizontal scrollbar based on the new scroll
   * properties. The CSS property to adjust for position (bottom|right) is
   * specified by [cssPos]. The CSS property to adjust for size (height|width)
   * is specified by [cssSize].
   */
  void _updateScrollbar(Element element, num offset, num scrollPercent,
      num frameSize, num contentSize, String cssPos, String cssSize) {
    if (!_cachedSize.containsKey(cssSize)) {
      if (offset == null || contentSize < frameSize) {
        return;
      }
      _frame.nodes.add(element);
    }
    num stretchPercent;
    if (scrollPercent > 1) {
      stretchPercent = scrollPercent - 1;
    } else {
      stretchPercent = scrollPercent < 0 ? -scrollPercent : 0;
    }
    num scrollPx = stretchPercent * (contentSize - frameSize);
    num maxSize = _defaultScrollSize(frameSize, contentSize);
    num size = Math.max(_MIN_COMPRESSED_SIZE, maxSize - scrollPx);
    num maxOffset = frameSize - size - _PADDING_LENGTH * 2;
    num pos = GoogleMath.clamp(scrollPercent * maxOffset, 0, maxOffset) +
        _PADDING_LENGTH;
    pos = pos.round();
    size = size.round();
    final style = element.style;
    style.setProperty(cssPos, '${pos}px', '');
    if (_cachedSize[cssSize] != size) {
      _cachedSize[cssSize] = size;
      style.setProperty(cssSize, '${size}px', '');
    }
    if (element.parent == null) {
      _frame.nodes.add(element);
    }
  }
}
