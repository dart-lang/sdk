// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

class GoogleChart {
  static var _api;

  /// Get access to the JsObject containing the Google Chart API:
  /// https://developers.google.com/chart/interactive/docs/reference
  static get api {
    return _api;
  }

  static Completer _completer = new Completer();

  static Future get onReady => _completer.future;

  static bool get ready => _completer.isCompleted;

  /// Load the Google Chart API. Returns a [Future] which completes
  /// when the API is loaded.
  static Future initOnce() {
    Logger.root.info('Loading Google Charts API');
    context['google'].callMethod('load',
        ['visualization', '1', new JsObject.jsify({
          'packages': ['corechart', 'table'],
          'callback': new JsFunction.withThis(_completer.complete)
    })]);
    return _completer.future.then(_initOnceOnComplete);
  }

  static _initOnceOnComplete(_) {
    Logger.root.info('Google Charts API loaded');
    _api = context['google']['visualization'];
    assert(_api != null);
    return _api;
  }
}

class DataTable {
  final _table = new JsObject(GoogleChart.api['DataTable']);
  /// Construct a Google Chart DataTable.
  DataTable();

  /// Number of columns.
  int get columns => _table.callMethod('getNumberOfColumns');
  /// Number of rows.
  int get rows => _table.callMethod('getNumberOfRows');

  /// Add a new column with [type] and [label].
  /// type must be: 'string', 'number', or 'boolean'.
  void addColumn(String type, String label) {
    _table.callMethod('addColumn', [type, label]);
  }

  /// Add a new column with [type], [label] and [role].
  /// Roles are used for metadata such as 'interval' or 'annotation'.
  /// type must be: 'string', 'number', or 'boolean'.
  void addRoleColumn(String type, String label, String role) {
    _table.callMethod('addColumn', [new JsObject.jsify({
      'type': type,
      'label': label,
      'role': role,
    })]);
  }

  /// Remove rows [start, end).
  void removeRows(int start, int end) {
    _table.callMethod('removeRows', [start, end]);
  }

  /// Remove all rows in the table.
  void clearRows() {
    removeRows(0, rows);
  }

  /// Adds a new row to the table. [row] must have an entry for each
  /// column in the table.
  void addRow(List row) {
    _table.callMethod('addRow', [new JsArray.from(row)]);
  }
}

class Chart {
  var _chart;
  final Map options = new Map();

  /// Create a Google Chart of [chartType]. e.g. 'Table', 'AreaChart',
  /// 'BarChart', the chart is rendered inside [element].
  Chart(String chartType, Element element) {
    _chart = new JsObject(GoogleChart.api[chartType], [element]);
  }

  /// When the user interacts with the table by clicking on columns,
  /// you must call this function before [draw] so that we draw
  /// with the current sort settings.
  void refreshOptionsSortInfo() {
    var props = _chart.callMethod('getSortInfo');
    if ((props != null) && (props['column'] != -1)) {
      // Preserve current sort settings.
      options['sortColumn'] = props['column'];
      options['sortAscending'] = props['ascending'];
    }
  }

  /// Draw this chart using [table] and the current [options].
  void draw(DataTable table) {
    var jsOptions = new JsObject.jsify(options);
    _chart.callMethod('draw', [table._table, jsOptions]);
  }
}
