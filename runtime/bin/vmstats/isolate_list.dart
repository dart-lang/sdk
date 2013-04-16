// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.vmstats;

class IsolateList {
  TableElement _isolateTable;

  static const String DETAILS = 'isolate_details';
  static const String VISIBLE = 'visible';
  static const String HIDDEN  = 'hidden';
  static const String ISOLATE_LIST_ITEM = 'isolate_list_item';
  static const String ISOLATE_DETAILS_COLUMN = 'isolate_details_column';
  static const String ISOLATE_ROW = 'isolate_row';
  static const String ISOLATE_STACKTRACE_COLUMN = 'isolate_stacktrace_column';
  static const String NEW_SPACE = 'new_space';
  static const String OLD_SPACE = 'old_space';
  static const String STACK_FRAME = 'stack_frame';
  static const String EMPTY_STACK_FRAME = 'empty_stack_frame';
  static const String STACK_LIMIT = 'stack_limit';
  static const String STACK_TRACE = 'stack_trace';
  static const String STACK_TRACE_TITLE = 'stack_trace_title';

  IsolateList(this._isolateTable) {}

  void updateList(IsolateListModel model) {
    var iterator = model.iterator;
    while (iterator.moveNext()) {
      var isolate = iterator.current;
      var isolateId = 'isolate-${isolate.port}';
      var isolateRow = _isolateTable.query('#$isolateId');
      if (isolateRow != null) {
        updateIsolateDetails(isolate, isolateRow);
      } else {
        isolateRow = new TableRowElement();
        isolateRow.$dom_className = ISOLATE_ROW;
        isolateRow.id = isolateId;
        _isolateTable.children.add(isolateRow);
        var detailsCell = new TableCellElement();
        detailsCell.$dom_className = ISOLATE_DETAILS_COLUMN;
        isolateRow.children.add(detailsCell);
        var basicData = new DivElement();
        basicData.text = isolate.name
          .replaceAll('\$', ': ')  // Split script from isolate, and ...
          .replaceAll('-', ' ');   // ... split name from port number.
        detailsCell.children.add(basicData);

        // Add isolate details as hidden children.
        var details = new DivElement();
        details.classes.addAll([DETAILS, HIDDEN]);
        detailsCell.children.add(details);

        // Add stacktrace column.
        var stacktraceCell = new TableCellElement();
        stacktraceCell.classes.addAll([ISOLATE_STACKTRACE_COLUMN, HIDDEN]);
        isolateRow.children.add(stacktraceCell);
        var stacktrace = new DivElement();
        stacktrace.classes.addAll([STACK_TRACE, HIDDEN]);
        stacktraceCell.children.add(stacktrace);

        isolateRow.onClick.listen((e) => toggleRow(isolateRow));
        updateIsolateDetails(isolate, isolateRow);
      }
    }
  }

  void setStacktrace(DivElement element, String json) {
    element.children.clear();
    var response = JSON.parse(json);
    element.id = response['handle'];
    var title = new DivElement();
    title.$dom_className = STACK_TRACE_TITLE;
    title.text = "Stack Trace";
    element.children.add(title);

    var stackTrace = response['stacktrace'];
    if (stackTrace.length > 0) {
      var stackIterator = response['stacktrace'].iterator;
      var i = 0;
      while (stackIterator.moveNext()) {
        i++;
        var frame = stackIterator.current;
        var frameElement = new DivElement();
        var text = '$i: ${frame["url"]}:${frame["line"]}: ${frame["function"]}';
        var code = frame["code"];
        if (code['optimized']) {
          text = '$text (optimized)';
        }
        frameElement.text = text;
        frameElement.$dom_className = STACK_FRAME;
        element.children.add(frameElement);
      }
    } else {
      DivElement noStack = new DivElement();
      noStack.$dom_className = EMPTY_STACK_FRAME;
      noStack.text = "<no stack>";
      element.children.add(noStack);
    }
  }

  Element findOrAddChild(DivElement parent, String className) {
    var child = parent.query('.$className');
    if (child == null) {
      child = new DivElement();
      child.$dom_className = className;
      parent.children.add(child);
    }
    return child;
  }

  void updateIsolateDetails(Isolate isolate, TableRowElement row) {
    var details = row.query('.$DETAILS');
    var newSpace = findOrAddChild(details, NEW_SPACE);
    newSpace.text = 'New space: ${isolate.newSpace.used}K';
    var oldSpace = findOrAddChild(details, OLD_SPACE);
    oldSpace.text = 'Old space: ${isolate.oldSpace.used}K';
    var stackLimit = findOrAddChild(details, STACK_LIMIT);
    stackLimit.text =
        'Stack limit: ${(isolate.stackLimit.abs() / 1000000).round()}M';
    var stackTrace = findOrAddChild(row, ISOLATE_STACKTRACE_COLUMN);
    HttpRequest.getString('/isolate/${isolate.handle}/stacktrace').then(
        (String response) => setStacktrace(stackTrace, response));
  }

  void toggleRow(TableRowElement row) {
    toggleElement(row.query('.$DETAILS'));
    toggleElement(row.query('.$ISOLATE_STACKTRACE_COLUMN'));
  }

  void toggleElement(Element e) {
    e.classes.toggle(VISIBLE);
    e.classes.toggle(HIDDEN);
  }
}
