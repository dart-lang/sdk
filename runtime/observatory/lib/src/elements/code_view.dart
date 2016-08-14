// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_view_element;

import 'dart:async';
import 'dart:html';
import 'observatory_element.dart';
import 'service_ref.dart';
import 'package:observatory/app.dart';
import 'package:observatory/service.dart';
import 'package:observatory/cpu_profile.dart';
import 'package:polymer/polymer.dart';

class DisassemblyTable extends SortedTable {
  DisassemblyTable(columns) : super(columns);
}

class InlineTable extends SortedTable {
  InlineTable(columns) : super(columns);
}

@CustomTag('code-view')
class CodeViewElement extends ObservatoryElement {
  @observable Code code;
  ProfileCode get profile => code == null ? null : code.profile;
  DisassemblyTable disassemblyTable;
  InlineTable inlineTable;

  static const kDisassemblyColumnIndex = 3;

  CodeViewElement.created() : super.created() {
    // Create table models.
    var columns = [
        new SortedTableColumn('Address'),
        new SortedTableColumn('Inclusive'),
        new SortedTableColumn('Exclusive'),
        new SortedTableColumn('Disassembly'),
        new SortedTableColumn('Objects'),
    ];
    disassemblyTable = new DisassemblyTable(columns);
    columns = [
        new SortedTableColumn('Address'),
        new SortedTableColumn('Inclusive'),
        new SortedTableColumn('Exclusive'),
        new SortedTableColumn('Functions'),
    ];
    inlineTable = new InlineTable(columns);
  }

  @override
  void attached() {
    super.attached();
  }

  void codeChanged(oldValue) {
    if (code == null) {
      return;
    }
    code.load().then((Code c) {
      c.loadScript();
      _updateDisassembly();
      _updateInline();
    });
  }

  Future refresh() {
    return code.reload();
  }

  Future refreshTicks() {
    var isolate = code.isolate;
    return isolate.invokeRpc('_getCpuProfile', { 'tags': 'None' })
        .then((ServiceMap response) {
            var cpuProfile = new CpuProfile();
            cpuProfile.load(isolate, response);
            _updateDisassembly();
            _updateInline();
          });
  }

  String formattedAddress(CodeInstruction instruction) {
    if (instruction.address == 0) {
      return '';
    }
    return '0x${instruction.address.toRadixString(16)}';
  }

  String formattedAddressRange(CodeInlineInterval interval) {
    String start = interval.start.toRadixString(16);
    String end = interval.end.toRadixString(16);
    return '[0x$start, 0x$end)';
  }

  String formattedInclusiveInterval(CodeInlineInterval interval) {
    if (code == null) {
      return '';
    }
    if (code.profile == null) {
      return '';
    }
    var intervalTick = code.profile.intervalTicks[interval.start];
    if (intervalTick == null) {
      return '';
    }
    // Don't show inclusive ticks if they are the same as exclusive ticks.
    if (intervalTick.inclusiveTicks == intervalTick.exclusiveTicks) {
      return '';
    }
    var pcent = Utils.formatPercent(intervalTick.inclusiveTicks,
                                    code.profile.profile.sampleCount);
    return '$pcent (${intervalTick.inclusiveTicks})';
  }

  String formattedExclusiveInterval(CodeInlineInterval interval) {
    if (code == null) {
      return '';
    }
    if (code.profile == null) {
      return '';
    }
    var intervalTick = code.profile.intervalTicks[interval.start];
    if (intervalTick == null) {
      return '';
    }
    var pcent = Utils.formatPercent(intervalTick.exclusiveTicks,
                                    code.profile.profile.sampleCount);
    return '$pcent (${intervalTick.exclusiveTicks})';
  }


  String formattedInclusive(CodeInstruction instruction) {
    if (code == null) {
      return '';
    }
    if (code.profile == null) {
      return '';
    }
    var tick = code.profile.addressTicks[instruction.address];
    if (tick == null) {
      return '';
    }
    // Don't show inclusive ticks if they are the same as exclusive ticks.
    if (tick.inclusiveTicks == tick.exclusiveTicks) {
      return '';
    }
    var pcent = Utils.formatPercent(tick.inclusiveTicks,
                                    code.profile.profile.sampleCount);
    return '$pcent (${tick.inclusiveTicks})';
  }

  String formattedExclusive(CodeInstruction instruction) {
    if (code == null) {
      return '';
    }
    if (code.profile == null) {
      return '';
    }
    var tick = code.profile.addressTicks[instruction.address];
    if (tick == null) {
      return '';
    }
    var pcent = Utils.formatPercent(tick.exclusiveTicks,
                                    code.profile.profile.sampleCount);
    return '$pcent (${tick.exclusiveTicks})';
  }

  void _updateDiasssemblyTable() {
    disassemblyTable.clearRows();
    if (code == null) {
      return;
    }
    for (CodeInstruction instruction in code.instructions) {
      var row = [formattedAddress(instruction),
                 formattedInclusive(instruction),
                 formattedExclusive(instruction),
                 instruction.human,
                 instruction.object];
      disassemblyTable.addRow(new SortedTableRow(row));
    }
  }

  void _addDisassemblyDOMRow() {
    var tableBody = $['disassemblyTableBody'];
    assert(tableBody != null);
    var tr = new TableRowElement();

    var cell;

    // Add new space.
    cell = tr.insertCell(-1);
    cell.classes.add('monospace');
    cell = tr.insertCell(-1);
    cell.classes.add('monospace');
    cell = tr.insertCell(-1);
    cell.classes.add('monospace');
    cell = tr.insertCell(-1);
    cell.classes.add('monospace');
    cell = tr.insertCell(-1);
    cell.classes.add('monospace');

    tableBody.children.add(tr);
  }

  void _fillDisassemblyDOMRow(TableRowElement tr, int rowIndex) {
    final row = disassemblyTable.rows[rowIndex];
    final n = row.values.length;
    for (var i = 0; i < n; i++) {
      final cell = tr.children[i];
      final content = row.values[i];
      if (content is ServiceObject) {
        ServiceRefElement element = new Element.tag('any-service-ref');
        element.ref = content;
        cell.children = [element];
      } else if (content != null) {
        String text = '$content';
        if (i == kDisassemblyColumnIndex) {
          // Disassembly might be a comment. Reduce indentation, change styling,
          // widen to span next column (which should be empty).
          if (text.startsWith('        ;;')) {
            cell.attributes['colspan'] = '2';
            cell.classes.add('code-comment');
            text = text.substring(6);
          } else {
            cell.attributes['colspan'] = '1';
            cell.classes.remove('code-comment');
          }
        }
        cell.text = text;
      }
    }
  }

  void _updateDisassemblyDOMTable() {
    var tableBody = $['disassemblyTableBody'];
    assert(tableBody != null);
    // Resize DOM table.
    if (tableBody.children.length > disassemblyTable.sortedRows.length) {
      // Shrink the table.
      var deadRows =
      tableBody.children.length - disassemblyTable.sortedRows.length;
      for (var i = 0; i < deadRows; i++) {
        tableBody.children.removeLast();
      }
    } else if (tableBody.children.length < disassemblyTable.sortedRows.length) {
      // Grow table.
      var newRows =
          disassemblyTable.sortedRows.length - tableBody.children.length;
      for (var i = 0; i < newRows; i++) {
        _addDisassemblyDOMRow();
      }
    }

    assert(tableBody.children.length == disassemblyTable.sortedRows.length);

    // Fill table.
    var i = 0;
    for (var tr in tableBody.children) {
      var rowIndex = disassemblyTable.sortedRows[i];
      _fillDisassemblyDOMRow(tr, rowIndex);
      i++;
    }
  }

  void _updateDisassembly() {
    _updateDiasssemblyTable();
    _updateDisassemblyDOMTable();
  }

  void _updateInlineTable() {
    inlineTable.clearRows();
    if (code == null) {
      return;
    }
    for (CodeInlineInterval interval in code.inlineIntervals) {
      var row = [interval,
                 formattedInclusiveInterval(interval),
                 formattedExclusiveInterval(interval),
                 interval.functions];
      inlineTable.addRow(new SortedTableRow(row));
    }
  }

  void _addInlineDOMRow() {
    var tableBody = shadowRoot.querySelector('#inlineRangeTableBody');
    assert(tableBody != null);
    var tr = new TableRowElement();

    var cell;

    // Add new space.
    cell = tr.insertCell(-1);
    cell.classes.add('monospace');
    cell = tr.insertCell(-1);
    cell.classes.add('monospace');
    cell = tr.insertCell(-1);
    cell.classes.add('monospace');
    cell = tr.insertCell(-1);

    tableBody.children.add(tr);
  }

  void _fillInlineDOMRow(TableRowElement tr, int rowIndex) {
    var row = inlineTable.rows[rowIndex];
    var columns = row.values.length;
    var addressRangeColumn = 0;
    var functionsColumn = columns - 1;

    {
      var addressRangeCell = tr.children[addressRangeColumn];
      var interval = row.values[addressRangeColumn];
      var addressRangeString = formattedAddressRange(interval);
      var addressRangeElement = new SpanElement();
      addressRangeElement.classes.add('monospace');
      addressRangeElement.text = addressRangeString;
      addressRangeCell.children.clear();
      addressRangeCell.children.add(addressRangeElement);
    }

    for (var i = addressRangeColumn + 1; i < columns - 1; i++) {
      var cell = tr.children[i];
      cell.text = row.values[i].toString();
    }
    var functions = row.values[functionsColumn];
    var functionsCell = tr.children[functionsColumn];
    functionsCell.children.clear();
    for (var func in functions) {
      var functionRef = new Element.tag('function-ref');
      functionRef.ref = func;
      functionsCell.children.add(functionRef);
      var gap = new SpanElement();
      gap.style.minWidth = '1em';
      gap.text = ' ';
      functionsCell.children.add(gap);
    }
  }

  void _updateInlineDOMTable() {
    var tableBody = shadowRoot.querySelector('#inlineRangeTableBody');
    // Resize DOM table.
    if (tableBody.children.length > inlineTable.sortedRows.length) {
      // Shrink the table.
      var deadRows =
      tableBody.children.length - inlineTable.sortedRows.length;
      for (var i = 0; i < deadRows; i++) {
        tableBody.children.removeLast();
      }
    } else if (tableBody.children.length < inlineTable.sortedRows.length) {
      // Grow table.
      var newRows = inlineTable.sortedRows.length - tableBody.children.length;
      for (var i = 0; i < newRows; i++) {
        _addInlineDOMRow();
      }
    }
    assert(tableBody.children.length == inlineTable.sortedRows.length);
    // Fill table.
    for (var i = 0; i < inlineTable.sortedRows.length; i++) {
      var rowIndex = inlineTable.sortedRows[i];
      var tr = tableBody.children[i];
      _fillInlineDOMRow(tr, rowIndex);
    }
  }

  void _updateInline() {
    _updateInlineTable();
    _updateInlineDOMTable();
  }

  Element _findJumpTarget(Element target) {
    var jumpTarget = target.attributes['data-jump-target'];
    if (jumpTarget == '') {
      return null;
    }
    var address = int.parse(jumpTarget);
    var node = shadowRoot.querySelector('#addr-$address');
    if (node == null) {
      return null;
    }
    return node;
  }

  void mouseOver(Event e, var detail, Node target) {
    var jt = _findJumpTarget(target);
    if (jt == null) {
      return;
    }
    jt.classes.add('highlight');
  }

  void mouseOut(Event e, var detail, Node target) {
    var jt = _findJumpTarget(target);
    if (jt == null) {
      return;
    }
    jt.classes.remove('highlight');
  }
}
