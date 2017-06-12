// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_view_element;

import 'dart:async';
import 'dart:html';
import 'package:observatory/cpu_profile.dart';
import 'package:observatory/service.dart' as S;
import 'package:observatory/models.dart' as M;
import 'package:observatory/app.dart'
    show SortedTable, SortedTableColumn, SortedTableRow;
import 'package:observatory/src/elements/curly_block.dart';
import 'package:observatory/src/elements/function_ref.dart';
import 'package:observatory/src/elements/helpers/any_ref.dart';
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/nav/class_menu.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/src/elements/object_common.dart';
import 'package:observatory/src/elements/objectpool_ref.dart';
import 'package:observatory/utils.dart';

class DisassemblyTable extends SortedTable {
  DisassemblyTable(columns) : super(columns);
}

class InlineTable extends SortedTable {
  InlineTable(columns) : super(columns);
}

class CodeViewElement extends HtmlElement implements Renderable {
  static const tag =
      const Tag<CodeViewElement>('code-view', dependencies: const [
    CurlyBlockElement.tag,
    FunctionRefElement.tag,
    NavClassMenuElement.tag,
    NavTopMenuElement.tag,
    NavVMMenuElement.tag,
    NavIsolateMenuElement.tag,
    NavRefreshElement.tag,
    NavNotifyElement.tag,
    ObjectCommonElement.tag,
    ObjectPoolRefElement.tag,
  ]);

  RenderingScheduler<CodeViewElement> _r;

  Stream<RenderedEvent<CodeViewElement>> get onRendered => _r.onRendered;

  M.VM _vm;
  M.IsolateRef _isolate;
  M.EventRepository _events;
  M.NotificationRepository _notifications;
  M.Code _code;
  M.RetainedSizeRepository _retainedSizes;
  M.ReachableSizeRepository _reachableSizes;
  M.InboundReferencesRepository _references;
  M.RetainingPathRepository _retainingPaths;
  M.ObjectRepository _objects;
  DisassemblyTable disassemblyTable;
  InlineTable inlineTable;

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
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(isolate != null);
    assert(events != null);
    assert(notifications != null);
    assert(code != null);
    assert(objects != null);
    assert(retainedSizes != null);
    assert(reachableSizes != null);
    assert(references != null);
    assert(retainingPaths != null);
    CodeViewElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
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

  CodeViewElement.created() : super.created() {
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
    children = [];
  }

  TableElement _disassemblyTable;
  TableElement _inlineRangeTable;
  Element _disassemblyTableBody;
  Element _inlineRangeTableBody;

  void render() {
    if (_inlineRangeTable == null) {
      _inlineRangeTable = new TableElement()..classes = ['table'];
      _inlineRangeTable.createTHead().children = [
        new TableRowElement()
          ..children = [
            document.createElement('th')
              ..classes = ['address']
              ..text = 'Address Range',
            document.createElement('th')
              ..classes = ['tick']
              ..text = 'Inclusive',
            document.createElement('th')
              ..classes = ['tick']
              ..text = 'Exclusive',
            document.createElement('th')..text = 'Functions',
          ]
      ];
      _inlineRangeTableBody = _inlineRangeTable.createTBody();
      _inlineRangeTableBody.classes = ['monospace'];
    }
    if (_disassemblyTable == null) {
      _disassemblyTable = new TableElement()..classes = ['table'];
      _disassemblyTable.createTHead().children = [
        new TableRowElement()
          ..children = [
            document.createElement('th')
              ..classes = ['address']
              ..text = 'Address Range',
            document.createElement('th')
              ..classes = ['tick']
              ..title = 'Ticks with PC on the stack'
              ..text = 'Inclusive',
            document.createElement('th')
              ..classes = ['tick']
              ..title = 'Ticks with PC at top of stack'
              ..text = 'Exclusive',
            document.createElement('th')
              ..classes = ['disassembly']
              ..text = 'Disassembly',
            document.createElement('th')
              ..classes = ['object']
              ..text = 'Object',
          ]
      ];
      _disassemblyTableBody = _disassemblyTable.createTBody();
      _disassemblyTableBody.classes = ['monospace'];
    }
    final inlinedFunctions = _code.inlinedFunctions.toList();
    final S.Code code = _code as S.Code;
    children = [
      navBar([
        new NavTopMenuElement(queue: _r.queue),
        new NavVMMenuElement(_vm, _events, queue: _r.queue),
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue),
        navMenu(_code.name),
        new NavRefreshElement(queue: _r.queue)
          ..onRefresh.listen((e) async {
            e.element.disabled = true;
            _refresh();
          }),
        new NavRefreshElement(label: 'refresh ticks', queue: _r.queue)
          ..onRefresh.listen((e) async {
            e.element.disabled = true;
            _refreshTicks();
          }),
        new NavNotifyElement(_notifications, queue: _r.queue)
      ]),
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = [
          new HeadingElement.h1()
            ..text = (M.isDartCode(_code.kind) && _code.isOptimized)
                ? 'Optimized code for ${_code.name}'
                : 'Code for ${_code.name}',
          new HRElement(),
          new ObjectCommonElement(_isolate, _code, _retainedSizes,
              _reachableSizes, _references, _retainingPaths, _objects,
              queue: _r.queue),
          new BRElement(),
          new DivElement()
            ..classes = ['memberList']
            ..children = [
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'Kind',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = _codeKindToString(_code.kind)
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = M.isDartCode(_code.kind)
                    ? const []
                    : [
                        new DivElement()
                          ..classes = ['memberName']
                          ..text = 'Optimized',
                        new DivElement()
                          ..classes = ['memberValue']
                          ..text = _code.isOptimized ? 'Yes' : 'No'
                      ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'Function',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..children = [
                      new FunctionRefElement(_isolate, _code.function,
                          queue: _r.queue)
                    ]
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = code.profile == null
                    ? const []
                    : [
                        new DivElement()
                          ..classes = ['memberName']
                          ..text = 'Inclusive',
                        new DivElement()
                          ..classes = ['memberValue']
                          ..text = '${code.profile.formattedInclusiveTicks}'
                      ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = code.profile == null
                    ? const []
                    : [
                        new DivElement()
                          ..classes = ['memberName']
                          ..text = 'Exclusive',
                        new DivElement()
                          ..classes = ['memberValue']
                          ..text = '${code.profile.formattedExclusiveTicks}'
                      ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'Object pool',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..children = [
                      new ObjectPoolRefElement(_isolate, _code.objectPool,
                          queue: _r.queue)
                    ]
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = inlinedFunctions.isNotEmpty
                    ? const []
                    : [
                        new DivElement()
                          ..classes = ['memberName']
                          ..text =
                              'inlined functions (${inlinedFunctions.length})',
                        new DivElement()
                          ..classes = ['memberValue']
                          ..children = [
                            new CurlyBlockElement(
                                expanded: inlinedFunctions.length < 8,
                                queue: _r.queue)
                              ..content = inlinedFunctions
                                  .map((f) => new FunctionRefElement(
                                      _isolate, f,
                                      queue: _r.queue))
                                  .toList()
                          ]
                      ]
            ],
          new HRElement(),
          _inlineRangeTable,
          new HRElement(),
          _disassemblyTable
        ],
    ];
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
    final isolate = code.isolate;
    S.ServiceMap response =
        await isolate.invokeRpc('_getCpuProfile', {'tags': 'None'});
    final cpuProfile = new CpuProfile();
    await cpuProfile.load(isolate, response);
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
    var intervalTick = code.profile.intervalTicks[interval.start];
    if (intervalTick == null) {
      return '';
    }
    // Don't show inclusive ticks if they are the same as exclusive ticks.
    if (intervalTick.inclusiveTicks == intervalTick.exclusiveTicks) {
      return '';
    }
    var pcent = Utils.formatPercent(
        intervalTick.inclusiveTicks, code.profile.profile.sampleCount);
    return '$pcent (${intervalTick.inclusiveTicks})';
  }

  String _formattedExclusiveInterval(S.CodeInlineInterval interval) {
    S.Code code = _code as S.Code;
    if (code.profile == null) {
      return '';
    }
    var intervalTick = code.profile.intervalTicks[interval.start];
    if (intervalTick == null) {
      return '';
    }
    var pcent = Utils.formatPercent(
        intervalTick.exclusiveTicks, code.profile.profile.sampleCount);
    return '$pcent (${intervalTick.exclusiveTicks})';
  }

  String _formattedInclusive(S.CodeInstruction instruction) {
    S.Code code = _code as S.Code;
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
    var pcent = Utils.formatPercent(
        tick.inclusiveTicks, code.profile.profile.sampleCount);
    return '$pcent (${tick.inclusiveTicks})';
  }

  String _formattedExclusive(S.CodeInstruction instruction) {
    S.Code code = _code as S.Code;
    if (code.profile == null) {
      return '';
    }
    var tick = code.profile.addressTicks[instruction.address];
    if (tick == null) {
      return '';
    }
    var pcent = Utils.formatPercent(
        tick.exclusiveTicks, code.profile.profile.sampleCount);
    return '$pcent (${tick.exclusiveTicks})';
  }

  void _updateDisassemblyTable() {
    S.Code code = _code as S.Code;
    disassemblyTable.clearRows();
    if (code == null) {
      return;
    }
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
    var tableBody = _disassemblyTableBody;
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
      if (content is S.HeapObject) {
        cell.children = [anyRef(_isolate, content, _objects, queue: _r.queue)];
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
    var tableBody = _disassemblyTableBody;
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
    var tableBody = _inlineRangeTableBody;
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
      var addressRangeString = _formattedAddressRange(interval);
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
      functionsCell.children
          .add(new FunctionRefElement(_isolate, func, queue: _r.queue));
      var gap = new SpanElement();
      gap.style.minWidth = '1em';
      gap.text = ' ';
      functionsCell.children.add(gap);
    }
  }

  void _updateInlineDOMTable() {
    var tableBody = _inlineRangeTableBody;
    // Resize DOM table.
    if (tableBody.children.length > inlineTable.sortedRows.length) {
      // Shrink the table.
      var deadRows = tableBody.children.length - inlineTable.sortedRows.length;
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

  static String _codeKindToString(M.CodeKind kind) {
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
    }
    throw new Exception('Unknown CodeKind ($kind)');
  }
}
