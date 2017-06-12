// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of layout;

/**
 * Implements a grid-based layout system based on:
 * [http://dev.w3.org/csswg/css3-grid-align/]
 *
 * This layout is designed to support animations and work on browsers that
 * don't support grid natively. As such, we implement it on top of absolute
 * positioning.
 */
// TODO(jmesserly): the DOM integration still needs work:
//  - The grid assumes it is absolutely positioned in its container.
//    Because of that, the grid doesn't work right unless it has at least one
//    fractional size in each dimension. In other words, only "top down" grids
//    work at the moment, because the grid can't determine its own size.
//    The core algorithm supports computing min breadth; the issue is about how
//    to integrate it into our View layer.
//  - Unless a child element is "display: inline-block" we can't get its
//    horizontal content size.
//  - Once we set an element's size to "position: absolute", we lose the
//    ability to get its original content size. If the width or height gets
//    set to something other than the content size, we can't recover the
//    original content size.
//  - There's some rounding to ints when we want to set the positions of our
//    tracks. I don't think we necessarily need to do that.
//
// TODO(jmesserly): Some features of the spec are unimplemented:
//  - grid-flow & items that have row and column set to 'auto'.
//  - Grid writing modes (right to left languages, etc)
//  - We don't do a second calculation pass if min content size of a grid-item
//    changes due to column width.
//  - The CSS parsing is not 100% complete, see the parser TODOs.
//  - We don't implement error recovery for invalid combinations of CSS
//    properties, or invalid CSS property values. Instead we throw an error.
//
// TODO(jmesserly): high level performance optimizations we could do:
//  - Optimize for the common case of spanCount = 1
//  - Optimize for the vbox/hbox case (1 row or 1 column)
//  - Optimize for the case of no content sized tracks
//  - Optimize for the "incremental update" cases
class GridLayout extends ViewLayout {
  /** Configuration parameters defined in CSS. */
  final GridTrackList rows;
  final GridTrackList columns;
  final GridTemplate template;

  /** The default sizing for new rows. */
  final TrackSizing rowSizing;

  /** The default sizing for new columns. */
  final TrackSizing columnSizing;

  /**
   * This stores the grid's size during a layout.
   * Used for rows/columns with % or fr units.
   */
  int _gridWidth, _gridHeight;

  /**
   * During a layout, this stores all row/column size information.
   * Because grid-items can implicitly specify their own rows/columns, we can't
   * compute this until we know the set of items.
   */
  List<GridTrack> _rowTracks, _columnTracks;

  /** During a layout, tracks which dimension we're processing. */
  Dimension _dimension;

  GridLayout(Positionable view)
      : super(view),
        rows = _GridTrackParser.parse(view.customStyle['grid-rows']),
        columns = _GridTrackParser.parse(view.customStyle['grid-columns']),
        template = _GridTemplateParser.parse(view.customStyle['grid-template']),
        rowSizing = _GridTrackParser
            .parseTrackSizing(view.customStyle['grid-row-sizing']),
        columnSizing = _GridTrackParser
            .parseTrackSizing(view.customStyle['grid-column-sizing']) {
    _rowTracks = rows != null ? rows.tracks : new List<GridTrack>();
    _columnTracks = columns != null ? columns.tracks : new List<GridTrack>();
  }

  int get currentWidth => _gridWidth;
  int get currentHeight => _gridHeight;

  void cacheExistingBrowserLayout() {
    // We don't need to do anything as we don't rely on the _cachedViewRect
    // when the grid layout is used.
  }

  // TODO(jacobr): cleanup this method so that it returns a Future
  // rather than taking a Completer as an argument.
  /** The main entry point for layout computation. */
  void measureLayout(Future<Size> size, Completer<bool> changed) {
    _ensureAllTracks();
    size.then((value) {
      _gridWidth = value.width;
      _gridHeight = value.height;

      if (_rowTracks.length > 0 && _columnTracks.length > 0) {
        _measureTracks();
        _setBoundsOfChildren();
        if (changed != null) {
          changed.complete(true);
        }
      }
    });
  }

  /**
   * The top level measurement function.
   * [http://dev.w3.org/csswg/css3-grid-align/#calculating-size-of-grid-tracks]
   */
  void _measureTracks() {
    // Resolve logical width, then height. Width comes first so we can use
    // the width when determining the content-sized height.
    try {
      _dimension = Dimension.WIDTH;
      _computeUsedBreadthOfTracks(_columnTracks);
      _dimension = Dimension.HEIGHT;
      _computeUsedBreadthOfTracks(_rowTracks);
    } finally {
      _dimension = null;
    }

    // TODO(jmesserly): we're supposed to detect a min-content size change
    // due to our computed width and trigger a new layout.
    // How do we implement that?
  }

  num _getRemainingSpace(List<GridTrack> tracks) {
    num remaining = _getGridContentSize();
    remaining -= CollectionUtils.sum(tracks, (t) => t.usedBreadth);
    return Math.max(0, remaining);
  }

  /**
   * This is the core Grid Track sizing algorithm. It is run for Grid columns
   * and Grid rows. The goal of the function is to ensure:
   *   1. That each Grid Track satisfies its minSizing
   *   2. That each Grid Track grows from the breadth which satisfied its
   *      minSizing to a breadth which satifies its
   *      maxSizing, subject to RemainingSpace.
   */
  // Note: spec does not correctly doc all the parameters to this function.
  void _computeUsedBreadthOfTracks(List<GridTrack> tracks) {
    // TODO(jmesserly): as a performance optimization we could cache this
    final items = view.childViews.map((view_) => view_.layout).toList();
    CollectionUtils.sortBy(items, (item) => _getSpanCount(item));

    // 1. Initialize per Grid Track variables
    for (final t in tracks) {
      // percentage or length sizing functions will return a value
      // min-content, max-content, or a fraction will be set to 0
      t.usedBreadth = t.minSizing.resolveLength(_getGridContentSize());
      t.maxBreadth = t.maxSizing.resolveLength(_getGridContentSize());
      t.updatedBreadth = 0;
    }

    // 2. Resolve content-based MinTrackSizingFunctions
    final USED_BREADTH = const _UsedBreadthAccumulator();
    final MAX_BREADTH = const _MaxBreadthAccumulator();

    _distributeSpaceBySpanCount(items, ContentSizeMode.MIN, USED_BREADTH);

    _distributeSpaceBySpanCount(items, ContentSizeMode.MAX, USED_BREADTH);

    // 3. Ensure that maxBreadth is as big as usedBreadth for each track
    for (final t in tracks) {
      if (t.maxBreadth < t.usedBreadth) {
        t.maxBreadth = t.usedBreadth;
      }
    }

    // 4. Resolve content-based MaxTrackSizingFunctions
    _distributeSpaceBySpanCount(items, ContentSizeMode.MIN, MAX_BREADTH);

    _distributeSpaceBySpanCount(items, ContentSizeMode.MAX, MAX_BREADTH);

    // 5. Grow all Grid Tracks in GridTracks from their usedBreadth up to their
    //    maxBreadth value until RemainingSpace is exhausted.
    // Note: it's not spec'd what to pass as the accumulator, but usedBreadth
    // seems right.
    _distributeSpaceToTracks(
        tracks, _getRemainingSpace(tracks), USED_BREADTH, false);

    // Spec wording is confusing about which direction this assignment happens,
    // but this is the way that makes sense.
    for (final t in tracks) {
      t.usedBreadth = t.updatedBreadth;
    }

    // 6. Grow all Grid Tracks having a fraction as their maxSizing
    final tempBreadth = _calcNormalizedFractionBreadth(tracks);
    for (final t in tracks) {
      t.usedBreadth =
          Math.max(t.usedBreadth, tempBreadth * t.maxSizing.fractionValue);
    }

    _computeTrackPositions(tracks);
  }

  /**
   * Final steps to finish positioning tracks. Takes the track size and uses
   * it to get start and end positions. Also rounds the positions to integers.
   */
  void _computeTrackPositions(List<GridTrack> tracks) {
    // Compute start positions of tracks, as well as the final position

    num position = 0;
    for (final t in tracks) {
      t.start = position;
      position += t.usedBreadth;
    }

    // Now, go through and round each position to an integer. Then
    // compute the sizes based on those integers.
    num finalPosition = position;

    for (int i = 0; i < tracks.length; i++) {
      int startEdge = tracks[i].start;
      int endEdge;
      if (i < tracks.length - 1) {
        endEdge = tracks[i + 1].start.round();
        tracks[i + 1].start = endEdge;
      } else {
        endEdge = finalPosition.round();
      }
      int breadth = endEdge - startEdge;

      // check that we're not off by >= 1px.
      assert((endEdge - startEdge - tracks[i].usedBreadth).abs() < 1);

      tracks[i].usedBreadth = breadth;
    }
  }

  /**
   * This method computes a '1fr' value, referred to as the
   * tempBreadth, for a set of Grid Tracks. The value computed
   * will ensure that when the tempBreadth is multiplied by the
   * fractions associated with tracks, that the UsedBreadths of tracks
   * will increase by an amount equal to the maximum of zero and the specified
   * freeSpace less the sum of the current UsedBreadths.
   */
  num _calcNormalizedFractionBreadth(List<GridTrack> tracks) {
    final fractionTracks = tracks.where((t) => t.maxSizing.isFraction).toList();

    // Note: the spec has various bugs in this function, such as mismatched
    // identifiers and names that aren't defined. For the most part it's
    // possible to figure out the meaning. It's also a bit confused about
    // how to compute spaceNeededFromFractionTracks, but that should just be the
    // set to the remaining free space after usedBreadth is accounted for.

    // We use the tempBreadth field to store the normalized fraction breadth
    for (final t in fractionTracks) {
      t.tempBreadth = t.usedBreadth / t.maxSizing.fractionValue;
    }

    CollectionUtils.sortBy(fractionTracks, (t) => t.tempBreadth);

    num spaceNeededFromFractionTracks = _getRemainingSpace(tracks);
    num currentBandFractionBreadth = 0;
    num accumulatedFractions = 0;
    for (final t in fractionTracks) {
      if (t.tempBreadth != currentBandFractionBreadth) {
        if (t.tempBreadth * accumulatedFractions >
            spaceNeededFromFractionTracks) {
          break;
        }
        currentBandFractionBreadth = t.tempBreadth;
      }
      accumulatedFractions += t.maxSizing.fractionValue;
      spaceNeededFromFractionTracks += t.usedBreadth;
    }
    return spaceNeededFromFractionTracks / accumulatedFractions;
  }

  /**
   * Ensures that for each Grid Track in tracks, a value will be
   * computed, updatedBreadth, that represents the Grid Track's share of
   * freeSpace.
   */
  void _distributeSpaceToTracks(List<GridTrack> tracks, num freeSpace,
      _BreadthAccumulator breadth, bool ignoreMaxBreadth) {
    // TODO(jmesserly): in some cases it would be safe to sort the passed in
    // list in place. Not always though.
    tracks = CollectionUtils.orderBy(
        tracks, (t) => t.maxBreadth - breadth.getSize(t));

    // Give each Grid Track an equal share of the space, but without exceeding
    // their maxBreadth values. Because there are different MaxBreadths
    // assigned to the different Grid Tracks, this can result in uneven growth.
    for (int i = 0; i < tracks.length; i++) {
      num share = freeSpace / (tracks.length - i);
      share = Math.min(share, tracks[i].maxBreadth);
      tracks[i].tempBreadth = share;
      freeSpace -= share;
    }

    // If the first loop completed having grown every Grid Track to its
    // maxBreadth, and there is still freeSpace, then divide that space
    // evenly and assign it to each Grid Track without regard for its
    // maxBreadth. This phase of growth will always be even, but only occurs
    // when the ignoreMaxBreadth flag is true.
    if (freeSpace > 0 && ignoreMaxBreadth) {
      for (int i = 0; i < tracks.length; i++) {
        final share = freeSpace / (tracks.length - i);
        tracks[i].tempBreadth += share;
        freeSpace -= share;
      }
    }

    // Note: the spec has us updating all grid tracks, not just the passed in
    // tracks, but I think that's a spec bug.
    for (final t in tracks) {
      t.updatedBreadth = Math.max(t.updatedBreadth, t.tempBreadth);
    }
  }

  /**
   * This function prioritizes the distribution of space driven by Grid Items
   * in content-sized Grid Tracks by the Grid Item's spanCount. That is, Grid
   * Items having a lower spanCount have an opportunity to increase the size of
   * the Grid Tracks they cover before those with larger SpanCounts.
   *
   * Note: items are assumed to be already sorted in increasing span count
   */
  void _distributeSpaceBySpanCount(List<ViewLayout> items,
      ContentSizeMode sizeMode, _BreadthAccumulator breadth) {
    items = items
        .where((item) =>
            _hasContentSizedTracks(_getTracks(item), sizeMode, breadth))
        .toList();

    var tracks = [];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];

      final itemTargetSize = item.measureContent(this, _dimension, sizeMode);

      final spannedTracks = _getTracks(item);
      _distributeSpaceToTracks(spannedTracks, itemTargetSize, breadth, true);

      // Remember that we need to update the sizes on these tracks
      tracks.addAll(spannedTracks);

      // Each time we transition to a new spanCount, update any modified tracks
      bool spanCountFinished = false;
      if (i + 1 == items.length) {
        spanCountFinished = true;
      } else if (_getSpanCount(item) != _getSpanCount(items[i + 1])) {
        spanCountFinished = true;
      }

      if (spanCountFinished) {
        for (final t in tracks) {
          breadth.setSize(t, Math.max(breadth.getSize(t), t.updatedBreadth));
        }
        tracks = [];
      }
    }
  }

  /**
   * Returns true if we have an appropriate content sized dimension, and don't
   * cross a fractional track.
   */
  static bool _hasContentSizedTracks(Iterable<GridTrack> tracks,
      ContentSizeMode sizeMode, _BreadthAccumulator breadth) {
    for (final t in tracks) {
      final fn = breadth.getSizingFunction(t);
      if (sizeMode == ContentSizeMode.MAX && fn.isMaxContentSized ||
          sizeMode == ContentSizeMode.MIN && fn.isContentSized) {
        // Make sure we don't cross a fractional track
        return tracks.length == 1 || !tracks.any((t_) => t_.isFractional);
      }
    }
    return false;
  }

  /** Ensures that the numbered track exists. */
  void _ensureTrack(
      List<GridTrack> tracks, TrackSizing sizing, int start, int span) {
    // Start is 1-based. Make it 0-based.
    start -= 1;

    // Grow the list if needed
    int length = start + span;
    int first = Math.min(start, tracks.length);
    tracks.length = Math.max(tracks.length, length);

    // Fill in tracks
    for (int i = first; i < length; i++) {
      if (tracks[i] == null) {
        tracks[i] = new GridTrack(sizing);
      }
    }
  }

  /**
   * Scans children creating GridLayoutParams as needed, and creates all of the
   * rows and columns that we will need.
   *
   * Note: this can potentially create new rows/columns, so this needs to be
   * run before the track sizing algorithm.
   */
  void _ensureAllTracks() {
    final items = view.childViews.map((view_) => view_.layout);

    for (final child in items) {
      if (child.layoutParams == null) {
        final p = new GridLayoutParams(child.view, this);
        _ensureTrack(_rowTracks, rowSizing, p.row, p.rowSpan);
        _ensureTrack(_columnTracks, columnSizing, p.column, p.columnSpan);
        child.layoutParams = p;
      }
      child.cacheExistingBrowserLayout();
    }
  }

  /**
   * Given the track sizes that were computed, position children in the grid.
   */
  void _setBoundsOfChildren() {
    final items = view.childViews.map((view_) => view_.layout);

    for (final item in items) {
      GridLayoutParams childLayout = item.layoutParams;
      var xPos = _getTrackLocationX(childLayout);
      var yPos = _getTrackLocationY(childLayout);

      int left = xPos.start, width = xPos.length;
      int top = yPos.start, height = yPos.length;

      // Somewhat counterintuitively (at least to me):
      //   grid-col-align is the horizontal alignment
      //   grid-row-align is the vertical alignment
      xPos = childLayout.columnAlign.align(xPos, item.currentWidth);
      yPos = childLayout.rowAlign.align(yPos, item.currentHeight);

      item.setBounds(xPos.start, yPos.start, xPos.length, yPos.length);
    }
  }

  num _getGridContentSize() {
    if (_dimension == Dimension.WIDTH) {
      return _gridWidth;
    } else if (_dimension == Dimension.HEIGHT) {
      return _gridHeight;
    }
  }

  _GridLocation _getTrackLocationX(GridLayoutParams childLayout) {
    int start = childLayout.column - 1;
    int end = start + childLayout.columnSpan - 1;

    start = _columnTracks[start].start;
    end = _columnTracks[end].end;

    return new _GridLocation(start, end - start);
  }

  _GridLocation _getTrackLocationY(GridLayoutParams childLayout) {
    int start = childLayout.row - 1;
    int end = start + childLayout.rowSpan - 1;

    start = _rowTracks[start].start;
    end = _rowTracks[end].end;

    return new _GridLocation(start, end - start);
  }

  /** Gets the tracks that this item crosses. */
  // TODO(jmesserly): might be better to return an iterable
  List<GridTrack> _getTracks(ViewLayout item) {
    GridLayoutParams childLayout = item.layoutParams;

    int start, span;
    List<GridTrack> tracks;
    if (_dimension == Dimension.WIDTH) {
      start = childLayout.column - 1;
      span = childLayout.columnSpan;
      tracks = _columnTracks;
    } else if (_dimension == Dimension.HEIGHT) {
      start = childLayout.row - 1;
      span = childLayout.rowSpan;
      tracks = _rowTracks;
    }

    assert(start >= 0 && span >= 1);

    final result = new List<GridTrack>(span);
    for (int i = 0; i < span; i++) {
      result[i] = tracks[start + i];
    }
    return result;
  }

  int _getSpanCount(ViewLayout item) {
    GridLayoutParams childLayout = item.layoutParams;
    return (_dimension == Dimension.WIDTH
        ? childLayout.columnSpan
        : childLayout.rowSpan);
  }
}
