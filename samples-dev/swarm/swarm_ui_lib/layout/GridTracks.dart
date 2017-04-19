// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of layout;

// This file has classes representing the grid tracks and grid template

/**
 * The data structure representing the grid-rows or grid-columns
 * properties.
 */
class GridTrackList {
  /** The set of tracks defined in CSS via grid-rows and grid-columns */
  final List<GridTrack> tracks;

  /**
   * Maps edge names to the corresponding track. Depending on whether the index
   * is used as a start or end, it might be interpreted exclusively or
   * inclusively.
   */
  final Map<String, int> lineNames;

  GridTrackList(this.tracks, this.lineNames) {}
}

/** Represents a row or a column. */
class GridTrack {
  /**
   * The start position of this track. Equal to the sum of previous track's
   * usedBreadth.
   */
  num start;

  /** The final computed breadth of this track. */
  num usedBreadth;

  // Fields used internally by the sizing algorithm
  num maxBreadth;
  num updatedBreadth;
  num tempBreadth;

  final TrackSizing sizing;

  GridTrack(this.sizing) {}

  /**
   * Support for the feature that repeats rows and columns, e.g.
   * [:grid-columns: 10px ("content" 250px 10px)[4]:]
   */
  GridTrack clone() => new GridTrack(sizing.clone());

  /** The min sizing function for the track. */
  SizingFunction get minSizing => sizing.min;

  /** The min sizing function for the track. */
  SizingFunction get maxSizing => sizing.max;

  num get end => start + usedBreadth;

  bool get isFractional => minSizing.isFraction || maxSizing.isFraction;
}

/** Represents the grid-row-align or grid-column-align. */
class GridItemAlignment {
  // TODO(jmesserly): should this be stored as an int for performance?
  final String value;

  // 'start' | 'end' | 'center' | 'stretch'
  GridItemAlignment.fromString(String value)
      : this.value = (value == null) ? 'stretch' : value {
    switch (this.value) {
      case 'start':
      case 'end':
      case 'center':
      case 'stretch':
        break;
      default:
        throw new UnsupportedError('invalid row/column alignment "$value"');
    }
  }

  _GridLocation align(_GridLocation span, int size) {
    switch (value) {
      case 'start':
        return new _GridLocation(span.start, size);
      case 'end':
        return new _GridLocation(span.end - size, size);
      case 'center':
        size = Math.min(size, span.length);
        num center = span.start + span.length / 2;
        num left = center - size / 2;
        return new _GridLocation(left.round(), size);
      case 'stretch':
        return span;
    }
  }
}

/**
 * Represents a grid-template. Used in conjunction with a grid-cell to
 * place cells in the grid, without needing to specify the exact row/column.
 */
class GridTemplate {
  final Map<int, _GridTemplateRect> _rects;
  final int _numRows;

  GridTemplate(List<String> rows)
      : _rects = new Map<int, _GridTemplateRect>(),
        _numRows = rows.length {
    _buildRects(rows);
  }

  /** Scans the template strings and computes bounds for each one. */
  void _buildRects(List<String> templateRows) {
    for (int r = 0; r < templateRows.length; r++) {
      String row = templateRows[r];
      for (int c = 0; c < row.length; c++) {
        int cell = row.codeUnitAt(c);
        final rect = _rects[cell];
        if (rect != null) {
          rect.add(r + 1, c + 1);
        } else {
          _rects[cell] = new _GridTemplateRect(cell, r + 1, c + 1);
        }
      }
    }

    // Finally, check that each rectangle is valid (i.e. all spaces filled)
    for (final rect in _rects.values) {
      rect.checkValid();
    }
  }

  /**
   * Looks up the given cell in the template, and returns the rect.
   */
  _GridTemplateRect lookupCell(String cell) {
    if (cell.length != 1) {
      throw new UnsupportedError(
          'grid-cell "$cell" must be a one character string');
    }
    final rect = _rects[cell.codeUnitAt(0)];
    if (rect == null) {
      throw new UnsupportedError(
          'grid-cell "$cell" not found in parent\'s grid-template');
    }
    return rect;
  }
}

/** Used by GridTemplate to track a single cell's bounds. */
class _GridTemplateRect {
  int row, column, rowSpan, columnSpan, _count, _char;
  _GridTemplateRect(this._char, this.row, this.column)
      : rowSpan = 1,
        columnSpan = 1,
        _count = 1 {}

  void add(int r, int c) {
    assert(r >= row && c >= column);
    _count++;
    rowSpan = Math.max(rowSpan, r - row + 1);
    columnSpan = Math.max(columnSpan, c - column + 1);
  }

  void checkValid() {
    int expected = rowSpan * columnSpan;
    if (expected != _count) {
      // TODO(jmesserly): not sure if we should throw here, due to CSS's
      // permissiveness. At the moment we're noisy about errors.
      String cell = new String.fromCharCodes([_char]);
      throw new UnsupportedError('grid-template "$cell"'
          ' is not square, expected $expected cells but got $_count');
    }
  }
}

/**
 * Used to return a row/column and span during parsing of grid-row and
 * grid-column during parsing.
 */
class _GridLocation {
  final int start, length;
  _GridLocation(this.start, this.length) {}

  int get end => start + length;
}
