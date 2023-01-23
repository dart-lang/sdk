// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of layout;

/// Caches the layout parameters that were specified in CSS during a layout
/// computation. These values are immutable during a layout.
// TODO(jmesserly): I would like all fields to be final, but it's too painful
// to do this right now in Dart. If I create a factory constructor, then I need
// to create locals, and pass all parameters to the real constructor. Each
// field ends up being mentioned 4 times instead of just twice.
class GridLayoutParams extends LayoutParams {
  /// The coordinates of this item in the grid. */
  int? row;
  int? column;
  int? rowSpan;
  int? columnSpan;
  @override
  int? layer;

  /// Alignment within its box */
  GridItemAlignment rowAlign;
  GridItemAlignment columnAlign;

  GridLayoutParams(Positionable view, GridLayout layout)
      : rowAlign =
            GridItemAlignment.fromString(view.customStyle['grid-row-align']),
        columnAlign =
            GridItemAlignment.fromString(view.customStyle['grid-column-align']),
        super(view.node) {
    // TODO(jmesserly): this can be cleaned up a lot by just passing "view"
    // into the parsers.
    layer = StringUtils.parseInt(view.customStyle['grid-layer'], 0);

    rowSpan = StringUtils.parseInt(view.customStyle['grid-row-span']);
    columnSpan = StringUtils.parseInt(view.customStyle['grid-column-span']);

    var line = _GridItemParser.parse(view.customStyle['grid-row'], layout.rows);
    if (line != null) {
      row = line.start;
      if (line.length != null) {
        if (rowSpan != null) {
          throw UnsupportedError(
              'grid-row-span cannot be with grid-row that defines an end');
        }
        rowSpan = line.length;
      }
    }

    line =
        _GridItemParser.parse(view.customStyle['grid-column'], layout.columns);

    if (line != null) {
      column = line.start;
      if (line.length != null) {
        if (columnSpan != null) {
          throw UnsupportedError(
              'grid-column-span cannot be with grid-column that defines an end');
        }
        columnSpan = line.length;
      }
    }

    String? cell = _GridTemplateParser.parseCell(view.customStyle['grid-cell']);
    if (cell != null && cell != 'none') {
      // TODO(jmesserly): I didn't see anything spec'd about conflicts and
      // error handling. For now, throw an error on a misconfigured view.
      // CSS is designed to be a permissive language, though, so we should do
      // better and resolve conflicts more intelligently.
      if (row != null ||
          column != null ||
          rowSpan != null ||
          columnSpan != null) {
        throw UnsupportedError(
            'grid-cell cannot be used with grid-row and grid-column');
      }

      if (layout.template == null) {
        throw UnsupportedError(
            'grid-cell requires that grid-template is set on the parent');
      }

      final rect = layout.template!.lookupCell(cell);
      row = rect.row;
      column = rect.column;
      rowSpan = rect.rowSpan;
      columnSpan = rect.columnSpan;
    } else {
      // Apply default row, column span values.
      rowSpan ??= 1;
      columnSpan ??= 1;

      if (row == null && column == null) {
        throw UnsupportedError('grid-flow is not implemented'
            ' so at least one row or one column must be defined');
      }

      row ??= 1;
      column ??= 1;
    }

    assert(row! > 0 && rowSpan! > 0 && column! > 0 && columnSpan! > 0);
  }
}
