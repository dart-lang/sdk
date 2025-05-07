// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_view_element;

import 'dart:async';

import 'package:web/web.dart';

import 'package:observatory/models.dart' as M;
import 'package:observatory/sample_profile.dart';
import 'package:observatory/service.dart' as S;
import 'package:observatory/src/elements/curly_block.dart';
import 'package:observatory/src/elements/function_ref.dart';
import 'package:observatory/src/elements/helpers/any_ref.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/element_utils.dart';
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/src/elements/object_common.dart';
import 'package:observatory/src/elements/objectpool_ref.dart';
import 'package:observatory/utils.dart';

import 'package:observatory/app.dart'
    show SortedTable, SortedTableColumn, SortedTableRow;

class DisassemblyTable extends SortedTable {
  DisassemblyTable(columns) : super(columns);
}

class InlineTable extends SortedTable {
  InlineTable(columns) : super(columns);
}

class CodeViewElement extends CustomElement implements Renderable {
  late RenderingScheduler<CodeViewElement> _r;

  Stream<RenderedEvent<CodeViewElement>> get onRendered => _r.onRendered;

  late M.VM _vm;
  late M.IsolateRef _isolate;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  late M.Code _code;
  late M.RetainedSizeRepository _retainedSizes;
  late M.ReachableSizeRepository _reachableSizes;
  late M.InboundReferencesRepository _references;
  late M.RetainingPathRepository _retainingPaths;
  late M.ObjectRepository _objects;
  late DisassemblyTable disassemblyTable;
  late InlineTable inlineTable;

  static const kDisassemblyColumnIndex = 3;

  M.VMRef get vm => _vm;
  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;
  M.Code get context => _code;

  factory CodeViewElement(
      M.VM vm,
      M.IsolateRef isolate,
      M.Code code,
      M.EventRepository events,
      M.NotificationRepository notifications,
      M.RetainedSizeRepository retainedSizes,
      M.ReachableSizeRepository reachableSizes,
      M.InboundReferencesRepository references,
      M.RetainingPathRepository retainingPaths,
      M.ObjectRepository objects,
      {RenderingQueue? queue}) {
    CodeViewElement e = new CodeViewElement.created();
    e._r = new RenderingScheduler<CodeViewElement>(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._code = code;
    e._objects = objects;
    e._retainedSizes = retainedSizes;
    e._reachableSizes = reachableSizes;
    e._references = references;
    e._retainingPaths = retainingPaths;
    return e;
  }

  CodeViewElement.created() : super.created('code-view') {
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
  attached() {
    super.attached();
    _r.enable();
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    removeChildren();
  }

  HTMLTableElement? _disassemblyTable;
  HTMLTableElement? _inlineRangeTable;
  HTMLTableSectionElement? _disassemblyTableBody;
  HTMLTableSectionElement? _inlineRangeTableBody;

  void render() {
    if (_inlineRangeTable == null) {
      _inlineRangeTable = new HTMLTableElement()..className = 'table';
      _inlineRangeTable!.createTHead().insertRow().appendChildren(<HTMLElement>[
        new HTMLTableCellElement.th()
          ..className = 'address'
          ..textContent = 'Address Range',
        new HTMLTableCellElement.th()
          ..className = 'tick'
          ..textContent = 'Inclusive',
        new HTMLTableCellElement.th()
          ..className = 'tick'
          ..textContent = 'Exclusive',
        new HTMLTableCellElement.th()..textContent = 'Functions',
      ]);
      _inlineRangeTableBody = _inlineRangeTable!.createTBody()
        ..className = 'monospace';
    }
    if (_disassemblyTable == null) {
      _disassemblyTable = new HTMLTableElement()..className = 'table';
      _disassemblyTable!.createTHead().insertRow().appendChildren(<HTMLElement>[
        new HTMLTableCellElement.th()
          ..className = 'address'
          ..textContent = 'Address Range',
        new HTMLTableCellElement.th()
          ..className = 'tick'
          ..title = 'Ticks with PC on the stack'
          ..textContent = 'Inclusive',
        new HTMLTableCellElement.th()
          ..className = 'tick'
          ..title = 'Ticks with PC at top of stack'
          ..textContent = 'Exclusive',
        new HTMLTableCellElement.th()
          ..className = 'disassembly'
          ..textContent = 'Disassembly',
        new HTMLTableCellElement.th()
          ..className = 'object'
          ..textContent = 'Object',
      ]);
      _disassemblyTableBody = _disassemblyTable!.createTBody()
        ..className = 'monospace';
    }
    final inlinedFunctions = _code.inlinedFunctions!.toList();
    final S.Code code = _code as S.Code;
    setChildren(<HTMLElement>[
      navBar(<HTMLElement>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue).element,
        navMenu(_code.name!),
        (new NavRefreshElement(queue: _r.queue)
              ..onRefresh.listen((e) async {
                e.element.disabled = true;
                _refresh();
              }))
            .element,
        (new NavRefreshElement(label: 'refresh ticks', queue: _r.queue)
              ..onRefresh.listen((e) async {
                e.element.disabled = true;
                _refreshTicks();
              }))
            .element,
        new NavNotifyElement(_notifications, queue: _r.queue).element
      ]),
      new HTMLDivElement()
        ..className = 'content-centered-big'
        ..appendChildren(<HTMLElement>[
          new HTMLHeadingElement.h1()
            ..textContent = (M.isDartCode(_code.kind) && _code.isOptimized!)
                ? 'Optimized code for ${_code.name}'
                : 'Code for ${_code.name}',
          new HTMLHRElement(),
          new ObjectCommonElement(_isolate, _code, _retainedSizes,
                  _reachableSizes, _references, _retainingPaths, _objects,
                  queue: _r.queue)
              .element,
          new HTMLBRElement(),
          new HTMLDivElement()
            ..className = 'memberList'
            ..appendChildren(<HTMLElement>[
              new HTMLDivElement()
                ..className = 'memberItem'
                ..appendChildren(<HTMLElement>[
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..textContent = 'Kind',
                  new HTMLDivElement()
                    ..className = 'memberValue'
                    ..textContent = _codeKindToString(_code.kind)
                ]),
              new HTMLDivElement()
                ..className = 'memberItem'
                ..appendChildren(M.isDartCode(_code.kind)
                    ? const []
                    : [
                        new HTMLDivElement()
                          ..className = 'memberName'
                          ..textContent = 'Optimized',
                        new HTMLDivElement()
                          ..className = 'memberValue'
                          ..textContent = _code.isOptimized! ? 'Yes' : 'No'
                      ]),
              new HTMLDivElement()
                ..className = 'memberItem'
                ..appendChildren(<HTMLElement>[
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..textContent = 'Function',
                  new HTMLDivElement()
                    ..className = 'memberValue'
                    ..appendChild(new FunctionRefElement(
                            _isolate, _code.function!,
                            queue: _r.queue)
                        .element)
                ]),
              new HTMLDivElement()
                ..className = 'memberItem'
                ..appendChildren(code.profile == null
                    ? const []
                    : [
                        new HTMLDivElement()
                          ..className = 'memberName'
                          ..textContent = 'Inclusive',
                        new HTMLDivElement()
                          ..className = 'memberValue'
                          ..textContent =
                              '${code.profile!.formattedInclusiveTicks}'
                      ]),
              new HTMLDivElement()
                ..className = 'memberItem'
                ..appendChildren(code.profile == null
                    ? const []
                    : [
                        new HTMLDivElement()
                          ..className = 'memberName'
                          ..textContent = 'Exclusive',
                        new HTMLDivElement()
                          ..className = 'memberValue'
                          ..textContent =
                              '${code.profile!.formattedExclusiveTicks}'
                      ]),
              new HTMLDivElement()
                ..className = 'memberItem'
                ..appendChildren(<HTMLElement>[
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..textContent = 'Object pool',
                  new HTMLDivElement()
                    ..className = 'memberValue'
                    ..appendChildren(<HTMLElement>[
                      new ObjectPoolRefElement(_isolate, _code.objectPool!,
                              queue: _r.queue)
                          .element
                    ])
                ]),
              new HTMLDivElement()
                ..className = 'memberItem'
                ..appendChildren(inlinedFunctions.isNotEmpty
                    ? const []
                    : [
                        new HTMLDivElement()
                          ..className = 'memberName'
                          ..textContent =
                              'inlined functions (${inlinedFunctions.length})',
                        new HTMLDivElement()
                          ..className = 'memberValue'
                          ..appendChildren(<HTMLElement>[
                            (new CurlyBlockElement(
                                    expanded: inlinedFunctions.length < 8,
                                    queue: _r.queue)
                                  ..content = inlinedFunctions
                                      .map<HTMLElement>((f) =>
                                          new FunctionRefElement(_isolate, f,
                                                  queue: _r.queue)
                                              .element)
                                      .toList())
                                .element
                          ])
                      ]),
              new HTMLHRElement(),
              _inlineRangeTable!,
              new HTMLHRElement(),
              _disassemblyTable!
            ])
        ])
    ]);
    _updateDisassembly();
    _updateInline();
  }

  Future _refresh() async {
    S.Code code = _code as S.Code;
    await code.reload();
    _r.dirty();
  }

  Future _refreshTicks() async {
    S.Code code = _code as S.Code;
    final isolate = code.isolate!;
    var response = await isolate.invokeRpc('getCpuSamples', {'_code': true});
    final cpuProfile = new SampleProfile();
    await cpuProfile.load(isolate, response as S.ServiceMap);
    _r.dirty();
  }

  String _formattedAddress(S.CodeInstruction instruction) {
    if (instruction.address == 0) {
      return '';
    }
    return '0x${instruction.address.toRadixString(16)}';
  }

  String _formattedAddressRange(S.CodeInlineInterval interval) {
    String start = interval.start.toRadixString(16);
    String end = interval.end.toRadixString(16);
    return '[0x$start, 0x$end)';
  }

  String _formattedInclusiveInterval(S.CodeInlineInterval interval) {
    S.Code code = _code as S.Code;
    if (code.profile == null) {
      return '';
    }
    var intervalTick = code.profile!.intervalTicks[interval.start];
    if (intervalTick == null) {
      return '';
    }
    // Don't show inclusive ticks if they are the same as exclusive ticks.
    if (intervalTick.inclusiveTicks == intervalTick.exclusiveTicks) {
      return '';
    }
    var pcent = Utils.formatPercent(
        intervalTick.inclusiveTicks, code.profile!.profile.sampleCount);
    return '$pcent (${intervalTick.inclusiveTicks})';
  }

  String _formattedExclusiveInterval(S.CodeInlineInterval interval) {
    S.Code code = _code as S.Code;
    if (code.profile == null) {
      return '';
    }
    var intervalTick = code.profile!.intervalTicks[interval.start];
    if (intervalTick == null) {
      return '';
    }
    var pcent = Utils.formatPercent(
        intervalTick.exclusiveTicks, code.profile!.profile.sampleCount);
    return '$pcent (${intervalTick.exclusiveTicks})';
  }

  String _formattedInclusive(S.CodeInstruction instruction) {
    S.Code code = _code as S.Code;
    var profile = code.profile;
    if (profile == null) {
      return '';
    }
    var tick = profile.addressTicks[instruction.address];
    if (tick == null) {
      return '';
    }
    // Don't show inclusive ticks if they are the same as exclusive ticks.
    if (tick.inclusiveTicks == tick.exclusiveTicks) {
      return '';
    }
    var pcent =
        Utils.formatPercent(tick.inclusiveTicks, profile.profile.sampleCount);
    return '$pcent (${tick.inclusiveTicks})';
  }

  String _formattedExclusive(S.CodeInstruction instruction) {
    S.Code code = _code as S.Code;
    var profile = code.profile;
    if (profile == null) {
      return '';
    }
    var tick = profile.addressTicks[instruction.address];
    if (tick == null) {
      return '';
    }
    var pcent =
        Utils.formatPercent(tick.exclusiveTicks, profile.profile.sampleCount);
    return '$pcent (${tick.exclusiveTicks})';
  }

  void _updateDisassemblyTable() {
    S.Code code = _code as S.Code;
    disassemblyTable.clearRows();
    for (S.CodeInstruction instruction in code.instructions) {
      var row = [
        _formattedAddress(instruction),
        _formattedInclusive(instruction),
        _formattedExclusive(instruction),
        instruction.human,
        instruction.object
      ];
      disassemblyTable.addRow(new SortedTableRow(row));
    }
  }

  void _addDisassemblyDOMRow() {
    // Add new space.
    _disassemblyTableBody!.insertRow()
      ..insertCell(-1).className = 'monospace'
      ..insertCell(-1).className = 'monospace'
      ..insertCell(-1).className = 'monospace'
      ..insertCell(-1).className = 'monospace'
      ..insertCell(-1).className = 'monospace';
  }

  void _fillDisassemblyDOMRow(HTMLTableRowElement tr, int rowIndex) {
    final row = disassemblyTable.rows[rowIndex];
    final n = row.values.length;
    for (var i = 0; i < n; i++) {
      HTMLTableCellElement cell = tr.cells.item(i) as HTMLTableCellElement;
      final content = row.values[i];
      if (content is S.HeapObject) {
        cell.innerHTML = anyRef(_isolate, content, _objects, queue: _r.queue);
      } else if (content != null) {
        String text = '$content';
        if (i == kDisassemblyColumnIndex) {
          // Disassembly might be a comment. Reduce indentation, change styling,
          // widen to span next column (which should be empty).
          if (text.startsWith('        ;;')) {
            cell.colSpan = 2;
            cell.className = 'code-comment';
            text = text.substring(6);
          } else {
            cell.colSpan = 1;
            cell.className = '';
          }
        }
        cell.textContent = text;
      }
    }
  }

  void _updateDisassemblyDOMTable() {
    var tableBody = _disassemblyTableBody!;
    // Resize DOM table.
    if (tableBody.children.length > disassemblyTable.sortedRows.length) {
      // Shrink the table.
      var deadRows =
          tableBody.children.length - disassemblyTable.sortedRows.length;
      for (var i = 0; i < deadRows; i++) {
        tableBody.deleteRow(tableBody.children.length);
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
    for (int i = 0; i < tableBody.rows.length; i++) {
      final tr = tableBody.rows.item(i);
      final rowIndex = disassemblyTable.sortedRows[i];
      _fillDisassemblyDOMRow(tr as HTMLTableRowElement, rowIndex);
    }
  }

  void _updateDisassembly() {
    _updateDisassemblyTable();
    _updateDisassemblyDOMTable();
  }

  void _updateInlineTable() {
    inlineTable.clearRows();
    S.Code code = _code as S.Code;
    for (S.CodeInlineInterval interval in code.inlineIntervals) {
      var row = [
        interval,
        _formattedInclusiveInterval(interval),
        _formattedExclusiveInterval(interval),
        interval.functions
      ];
      inlineTable.addRow(new SortedTableRow(row));
    }
  }

  void _addInlineDOMRow() {
    _inlineRangeTableBody!.insertRow()
      ..insertCell(-1)
      ..className = 'monospace'
      ..insertCell(-1)
      ..className = 'monospace'
      ..insertCell(-1)
      ..className = 'monospace'
      ..insertCell(-1)
      ..className = 'monospace';
  }

  void _fillInlineDOMRow(HTMLTableRowElement tr, int rowIndex) {
    final row = inlineTable.rows[rowIndex];
    final columns = row.values.length;
    final addressRangeColumn = 0;
    final functionsColumn = columns - 1;

    {
      final addressRangeCell = tr.cells.item(addressRangeColumn)!;
      final interval = row.values[addressRangeColumn];
      final addressRangeString = _formattedAddressRange(interval);
      final addressRangeElement = new HTMLSpanElement();
      addressRangeElement.className = 'monospace';
      addressRangeElement.textContent = addressRangeString;
      addressRangeCell.removeChildren();
      addressRangeCell.appendChild(addressRangeElement);
    }

    for (var i = addressRangeColumn + 1; i < columns - 1; i++) {
      final cell = tr.cells.item(i) as HTMLTableCellElement;
      cell.textContent = row.values[i].toString();
    }
    final functions = row.values[functionsColumn];
    final functionsCell = tr.cells.item(functionsColumn)!;
    functionsCell.removeChildren();
    for (var func in functions) {
      functionsCell
        ..appendChild(
            new FunctionRefElement(_isolate, func, queue: _r.queue).element)
        ..appendChild(HTMLSpanElement()
          ..style.minWidth = '1em'
          ..textContent = ' ');
    }
  }

  void _updateInlineDOMTable() {
    final tableBody = _inlineRangeTableBody!;
    // Resize DOM table.
    if (tableBody.children.length > inlineTable.sortedRows.length) {
      // Shrink the table.
      var deadRows = tableBody.children.length - inlineTable.sortedRows.length;
      for (var i = 0; i < deadRows; i++) {
        tableBody
            .removeChild(tableBody.childNodes.item(tableBody.children.length)!);
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
      final rowIndex = inlineTable.sortedRows[i];
      final tr = tableBody.rows.item(i);
      _fillInlineDOMRow(tr as HTMLTableRowElement, rowIndex);
    }
  }

  void _updateInline() {
    _updateInlineTable();
    _updateInlineDOMTable();
  }

  static String _codeKindToString(M.CodeKind? kind) {
    switch (kind) {
      case M.CodeKind.dart:
        return 'dart';
      case M.CodeKind.native:
        return 'native';
      case M.CodeKind.stub:
        return 'stub';
      case M.CodeKind.tag:
        return 'tag';
      case M.CodeKind.collected:
        return 'collected';
      default:
        throw new Exception('Unknown CodeKind ($kind)');
    }
  }
}
