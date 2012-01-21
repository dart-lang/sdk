// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class PageState {
  final ObservableValue<int> current;
  final ObservableValue<int> target;
  final ObservableValue<int> length;
  PageState() :
    current = new ObservableValue<int>(0),
    target = new ObservableValue<int>(0),
    length = new ObservableValue<int>(1);
}

/** Simplifies using a PageNumberView and PagedColumnView together. */
class PagedContentView extends CompositeView {
  final View content;
  final PageState pages;

  PagedContentView(this.content)
    : super('paged-content'),
      pages = new PageState() {
    addChild(new PagedColumnView(pages, content));
    addChild(new PageNumberView(pages));
  }
}

/** Displays current page and a left/right arrow. Used with [PagedColumnView] */
class PageNumberView extends View {
  final PageState pages;
  Element _label;
  Element _left, _right;

  PageNumberView(this.pages) : super();

  Element render() {
    // TODO(jmesserly): this was supposed to use the somewhat flatter unicode
    // glyphs that Chrome uses on the new tab page, but the text is getting
    // corrupted.
    final node = new Element.html('''
        <div class="page-number">
          <div class="page-number-left">&lsaquo;</div>
          <div class="page-number-label"></div>
          <div class="page-number-right">&rsaquo;</div>
        </div>
        ''');
    _left = node.query('.page-number-left');
    _label = node.query('.page-number-label');
    _right = node.query('.page-number-right');
    return node;
  }

  void enterDocument() {
    watch(pages.current, (s) => _update());
    watch(pages.length, (s) => _update());

    _left.on.click.add((e) {
      if (pages.current.value > 0) {
        pages.target.value = pages.current.value - 1;
      }
    });

    _right.on.click.add((e) {
      if (pages.current.value + 1 < pages.length.value) {
        pages.target.value = pages.current.value + 1;
      }
    });
  }

  void _update() {
    _label.text = '${pages.current.value + 1} of ${pages.length.value}';
  }
}

/**
 * A horizontal scrolling view that snaps to items like [ConveyorView], but only
 * has one child. Instead of scrolling between views, it scrolls between content
 * that flows horizontally in columns. Supports left/right swipe to switch
 * between pages. Can also be used with [PageNumberView].
 *
 * This control assumes that it is styled with fixed or percent width and
 * height, so the content will flow out horizontally. This allows it to compute
 * the number of pages using [:scrollWidth:] and [:offsetWidth:].
 */
class PagedColumnView extends View {

  static final MIN_THROW_PAGE_FRACTION = 0.01;
  final View contentView;

  final PageState pages;

  Element _container;
  int _columnGap, _columnWidth;
  int _viewportSize;
  Scroller scroller;

  PagedColumnView(this.pages, this.contentView) : super();

  Element render() {
    final node = new Element.html('''
      <div class="paged-column">
        <div class="paged-column-container"></div>
      </div>''');
    _container = node.query('.paged-column-container');
    _container.nodes.add(contentView.node);

    // TODO(jmesserly): if we end up with empty columns on the last page,
    // this causes the last page to end up right justified. But it seems to
    // work reasonably well for both clicking and throwing. So for now, leave
    // the scroller configured the default way.

    // TODO(jacobr): use named arguments when available.
    scroller = new Scroller(
        _container,
        false /* verticalScrollEnabled */,
        true /* horizontalScrollEnabled */,
        true /* momementumEnabled */,
        () {
          assert(window.inMeasurementFrame);
          return new Size(_getViewLength(), 1);
        },
        Scroller.FAST_SNAP_DECELERATION_FACTOR);

    scroller.onDecelStart.add(_snapToPage);
    scroller.onScrollerDragEnd.add(_snapToPage);
    scroller.onContentMoved.add(_onContentMoved); 
    return node;
  }

  int _getViewLength() {
    assert(window.inMeasurementFrame);
    return _computePageSize() * pages.length.value;
  }

  // TODO(jmesserly): would be better to not have this code in enterDocument.
  // But we need computedStyle to read our CSS properties.
  void enterDocument() {
    window.requestMeasurementFrame(() {
      _computeColumnGap();

      // Trigger a fake resize event so we measure our height.
      windowResized();
    });

    // If the selected page changes, animate to it.
    watch(pages.target, (s) => _onPageSelected());
    watch(pages.length, (s) => _onPageSelected());

    // Hook img onload events, so we find out about changes in content size
    for (ImageElement img in contentView.node.queryAll("img")) {
      if (!img.complete) {
        img.on.load.add((e) {
          _updatePageCount();
        });
      }
    }
  }

  /** Read the column-gap setting so we know how far to translate the child. */
  void _computeColumnGap() {
    assert(window.inMeasurementFrame);
    final style = contentView.node.computedStyle;
    String gap = style.columnGap;
    if (gap == 'normal') {
      gap = style.fontSize;
    }
    _columnGap = _toPixels(gap, 'column-gap or font-size');
    _columnWidth = _toPixels(style.columnWidth, 'column-width');
  }

  static int _toPixels(String value, String message) {
    // TODO(jmesserly): Safari 4 has a bug where this property does not end
    // in "px" like it should, but the value is correct. Handle that gracefully.
    if (value.endsWith('px')) {
      value = value.substring(0, value.length - 2);
    }
    return Math.parseDouble(value).round().toInt();
  }

  /** Watch for resize and update page count. */
  LayoutCallback windowResized() {
    assert(window.inMeasurementFrame);
    // The content needs to have its height explicitly set, or columns don't
    // flow to the right correctly. So we copy our own height and set the
    // height of the content.
    int offsetHeight = node.rect.offset.height; 
    return () {
      contentView.node.style.height = '${offsetHeight}px';
      _updatePageCount();
    };
  }

  void _updatePageCount() {
    int pageLength = 1;
    window.requestMeasurementFrame(() {
      final rect = _container.rect;
      if (rect.scroll.width > rect.offset.width) {
        pageLength = (rect.scroll.width / _computePageSize( ))
            .ceil().toInt();
      }
      pageLength = Math.max(pageLength, 1);

      int oldPage = pages.target.value;
      int newPage = Math.min(oldPage, pageLength - 1);

      return () {
        // Hacky: make sure a change event always fires.
        // This is so we adjust the 3d transform after resize.
        if (oldPage == newPage) {
          pages.target.value = 0;
        }
        assert(newPage < pageLength);
        pages.target.value = newPage;
        pages.length.value = pageLength;
      };
    });
  }

  void _onContentMoved(Event e) {
    window.requestMeasurementFrame(() {
      num current = scroller.contentOffset.x;    
      int pageSize = _computePageSize();
      return () {
        pages.current.value = -(current / pageSize).round().toInt();
      };
    });
  }

  void _snapToPage(Event e) {
    num current = scroller.contentOffset.x;
    num currentTarget = scroller.currentTarget.x;
    window.requestMeasurementFrame(() {
      int pageSize = _computePageSize();
      int destination;
      num currentPageNumber = -(current / pageSize).round();
      num pageNumber = -currentTarget / pageSize;
      if (current == currentTarget) {
        // User was just static dragging so round to the nearest page.
        pageNumber = pageNumber.round();
      } else {
        if (currentPageNumber == pageNumber.round() &&
          (pageNumber - currentPageNumber).abs() > MIN_THROW_PAGE_FRACTION &&
          -current + _viewportSize < _getViewLength() && current < 0) {
          // The user is trying to throw so we want to round up to the
          // nearest page in the direction they are throwing.
          pageNumber = currentTarget < current
              ? currentPageNumber + 1 : currentPageNumber - 1;
        } else {
          pageNumber = pageNumber.round();
        }
      }
      pageNumber = pageNumber.toInt();
      num translate = -pageNumber * pageSize;
      return () {
        pages.current.value = pageNumber;
        if (currentTarget != translate) {
          scroller.throwTo(translate, 0);
        } else {
          // Update the target page number when we are done animating.
          pages.target.value = pageNumber;
        }
      };
    });
  }

  int _computePageSize() {
    assert(window.inMeasurementFrame);
    final rect = _container.rect;

    // Hacky: we need to duplicate the way the columns are being computed,
    // including rounding, to figure out how far to translate the div.
    // See http://www.w3.org/TR/css3-multicol/#column-width
    _viewportSize = rect.offset.width;

    // Figure out how many columns we're rendering.
    // The algorithm ensures we're bigger than the specified min size.
    int perPage = Math.max(1,
        (_viewportSize + _columnGap) ~/ (_columnWidth + _columnGap));

    // Divide up the viewport between the columns.
    int columnSize = (_viewportSize - (perPage - 1) * _columnGap) ~/ perPage;

    // Finally, compute how big each page is, and how far to translate.
    return perPage * (columnSize + _columnGap);
  }

  void _onPageSelected() {
    window.requestMeasurementFrame(() {
      int translate = -pages.target.value * _computePageSize();
      return () {
        scroller.throwTo(translate, 0);
      };
    });
  }
}
