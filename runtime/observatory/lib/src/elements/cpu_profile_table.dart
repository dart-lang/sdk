// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library cpu_profile_table_element;

import 'dart:async';
import 'dart:html';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/containers/virtual_collection.dart';
import 'package:observatory/src/elements/cpu_profile/virtual_tree.dart';
import 'package:observatory/src/elements/function_ref.dart';
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/src/elements/sample_buffer_control.dart';
import 'package:observatory/src/elements/stack_trace_tree_config.dart';
import 'package:observatory/utils.dart';

enum _Table { functions, caller, callee }

enum _SortingField { exclusive, inclusive, caller, callee, method }

enum _SortingDirection { ascending, descending }

class CpuProfileTableElement extends HtmlElement implements Renderable {
  static const tag = const Tag<CpuProfileTableElement>('cpu-profile-table',
      dependencies: const [
        FunctionRefElement.tag,
        NavTopMenuElement.tag,
        NavVMMenuElement.tag,
        NavIsolateMenuElement.tag,
        NavRefreshElement.tag,
        NavNotifyElement.tag,
        SampleBufferControlElement.tag,
        StackTraceTreeConfigElement.tag,
        CpuProfileVirtualTreeElement.tag,
        VirtualCollectionElement.tag
      ]);

  RenderingScheduler<CpuProfileTableElement> _r;

  Stream<RenderedEvent<CpuProfileTableElement>> get onRendered => _r.onRendered;

  M.VM _vm;
  M.IsolateRef _isolate;
  M.EventRepository _events;
  M.NotificationRepository _notifications;
  M.IsolateSampleProfileRepository _profiles;
  Stream<M.SampleProfileLoadingProgressEvent> _progressStream;
  M.SampleProfileLoadingProgress _progress;
  final _sortingField = <_Table, _SortingField>{
    _Table.functions: _SortingField.exclusive,
    _Table.caller: _SortingField.caller,
    _Table.callee: _SortingField.callee,
  };
  final _sortingDirection = <_Table, _SortingDirection>{
    _Table.functions: _SortingDirection.descending,
    _Table.caller: _SortingDirection.descending,
    _Table.callee: _SortingDirection.descending,
  };
  String _filter = '';

  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;
  M.IsolateSampleProfileRepository get profiles => _profiles;
  M.VMRef get vm => _vm;

  factory CpuProfileTableElement(
      M.VM vm,
      M.IsolateRef isolate,
      M.EventRepository events,
      M.NotificationRepository notifications,
      M.IsolateSampleProfileRepository profiles,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(isolate != null);
    assert(events != null);
    assert(notifications != null);
    assert(profiles != null);
    CpuProfileTableElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._profiles = profiles;
    return e;
  }

  CpuProfileTableElement.created() : super.created();

  @override
  attached() {
    super.attached();
    _r.enable();
    _request();
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    children = [];
  }

  void render() {
    var content = [
      navBar([
        new NavTopMenuElement(queue: _r.queue),
        new NavVMMenuElement(_vm, _events, queue: _r.queue),
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue),
        navMenu('cpu profile (table)'),
        new NavRefreshElement(queue: _r.queue)..onRefresh.listen(_refresh),
        new NavRefreshElement(label: 'Clear', queue: _r.queue)
          ..onRefresh.listen(_clearCpuProfile),
        new NavNotifyElement(_notifications, queue: _r.queue)
      ]),
    ];
    if (_progress == null) {
      children = content;
      return;
    }
    content.add(new SampleBufferControlElement(_vm, _progress, _progressStream,
        showTag: false, queue: _r.queue));
    if (_progress.status == M.SampleProfileLoadingStatus.loaded) {
      content.add(new BRElement());
      content.addAll(_createTables());
      content.add(new BRElement());
      content.addAll(_createTree());
    }
    children = content;
  }

  M.ProfileFunction _selected;
  VirtualCollectionElement _functions;
  VirtualCollectionElement _callers;
  VirtualCollectionElement _callees;

  List<Element> _createTables() {
    _functions = _functions ??
        new VirtualCollectionElement(_createFunction, _updateFunction,
            createHeader: _createFunctionHeader, queue: _r.queue);
    _functions.items = _progress.profile.functions.toList()
      ..sort(_createSorter(_Table.functions));
    _functions.takeIntoView(_selected);
    _callers = _callers ??
        new VirtualCollectionElement(_createCaller, _updateCaller,
            createHeader: _createCallerHeader, queue: _r.queue);
    _callees = _callees ??
        new VirtualCollectionElement(_createCallee, _updateCallee,
            createHeader: _createCalleeHeader, queue: _r.queue);
    if (_selected != null) {
      _callers.items = _selected.callers.keys.toList()
        ..sort(_createSorter(_Table.caller));
      _callees.items = _selected.callees.keys.toList()
        ..sort(_createSorter(_Table.callee));
    } else {
      _callers.items = const [];
      _callees.items = const [];
    }
    return [
      new DivElement()
        ..classes = ['profile-trees']
        ..children = [
          new DivElement()
            ..classes = ['profile-trees-all']
            ..children = [_functions],
          new DivElement()
            ..classes = ['profile-trees-current']
            ..children = [
              new DivElement()
                ..classes = ['profile-trees-caller']
                ..children = [_callers],
              new DivElement()
                ..classes = ['profile-trees-selected']
                ..children = _selected == null
                    ? [new SpanElement()..text = 'No element selected']
                    : [
                        new FunctionRefElement(_isolate, _selected.function,
                            queue: _r.queue)
                      ],
              new DivElement()
                ..classes = ['profile-trees-callee']
                ..children = [_callees]
            ]
        ]
    ];
  }

  Element _createFunction() {
    final element = new DivElement()
      ..classes = ['function-item']
      ..children = [
        new SpanElement()
          ..classes = ['exclusive']
          ..text = '0%',
        new SpanElement()
          ..classes = ['inclusive']
          ..text = '0%',
        new SpanElement()..classes = ['name']
      ];
    element.onClick.listen((e) {
      if (e.target is AnchorElement) {
        return;
      }
      _selected = _functions.getItemFromElement(element);
      _r.dirty();
    });
    return element;
  }

  void _updateFunction(Element e, M.ProfileFunction item, int index) {
    if (item == _selected) {
      e.classes = ['function-item', 'selected'];
    } else {
      e.classes = ['function-item'];
    }
    e.children[0].text = Utils.formatPercentNormalized(_getExclusiveT(item));
    e.children[1].text = Utils.formatPercentNormalized(_getInclusiveT(item));
    e.children[2] =
        new FunctionRefElement(_isolate, item.function, queue: _r.queue)
          ..classes = ['name'];
  }

  List<HtmlElement> _createFunctionHeader() => [
        new DivElement()
          ..classes = ['function-item']
          ..children = [
            _createHeaderButton(
                const ['exclusive'],
                'Execution(%)',
                _Table.functions,
                _SortingField.exclusive,
                _SortingDirection.descending),
            _createHeaderButton(
                const ['inclusive'],
                'Stack(%)',
                _Table.functions,
                _SortingField.inclusive,
                _SortingDirection.descending),
            _createHeaderButton(const ['name'], 'Method', _Table.functions,
                _SortingField.method, _SortingDirection.ascending),
          ]
      ];

  void _setSorting(
      _Table table, _SortingField field, _SortingDirection defaultDirection) {
    if (_sortingField[table] == field) {
      switch (_sortingDirection[table]) {
        case _SortingDirection.descending:
          _sortingDirection[table] = _SortingDirection.ascending;
          break;
        case _SortingDirection.ascending:
          _sortingDirection[table] = _SortingDirection.descending;
          break;
      }
    } else {
      _sortingDirection[table] = defaultDirection;
      _sortingField[table] = field;
    }
    _r.dirty();
  }

  Element _createCallee() {
    final element = new DivElement()
      ..classes = ['function-item']
      ..children = [
        new SpanElement()
          ..classes = ['inclusive']
          ..text = '0%',
        new SpanElement()..classes = ['name']
      ];
    element.onClick.listen((e) {
      if (e.target is AnchorElement) {
        return;
      }
      _selected = _callees.getItemFromElement(element);
      _r.dirty();
    });
    return element;
  }

  void _updateCallee(Element e, item, int index) {
    e.children[0].text = Utils.formatPercentNormalized(_getCalleeT(item));
    e.children[1] =
        new FunctionRefElement(_isolate, item.function, queue: _r.queue)
          ..classes = ['name'];
  }

  List<HtmlElement> _createCalleeHeader() => [
        new DivElement()
          ..classes = ['function-item']
          ..children = [
            _createHeaderButton(
                const ['inclusive'],
                'Callees(%)',
                _Table.callee,
                _SortingField.callee,
                _SortingDirection.descending),
            _createHeaderButton(const ['name'], 'Method', _Table.callee,
                _SortingField.method, _SortingDirection.ascending),
          ]
      ];

  Element _createCaller() {
    final element = new DivElement()
      ..classes = ['function-item']
      ..children = [
        new SpanElement()
          ..classes = ['inclusive']
          ..text = '0%',
        new SpanElement()..classes = ['name']
      ];
    element.onClick.listen((e) {
      if (e.target is AnchorElement) {
        return;
      }
      _selected = _callers.getItemFromElement(element);
      _r.dirty();
    });
    return element;
  }

  void _updateCaller(Element e, item, int index) {
    e.children[0].text = Utils.formatPercentNormalized(_getCallerT(item));
    e.children[1] =
        new FunctionRefElement(_isolate, item.function, queue: _r.queue)
          ..classes = ['name'];
  }

  List<HtmlElement> _createCallerHeader() => [
        new DivElement()
          ..classes = ['function-item']
          ..children = [
            _createHeaderButton(
                const ['inclusive'],
                'Callers(%)',
                _Table.caller,
                _SortingField.caller,
                _SortingDirection.descending),
            _createHeaderButton(const ['name'], 'Method', _Table.caller,
                _SortingField.method, _SortingDirection.ascending),
          ]
      ];

  ButtonElement _createHeaderButton(List<String> classes, String text,
          _Table table, _SortingField field, _SortingDirection direction) =>
      new ButtonElement()
        ..classes = classes
        ..text = _sortingField[table] != field
            ? text
            : _sortingDirection[table] == _SortingDirection.ascending
                ? '$text▼'
                : '$text▲'
        ..onClick.listen((_) => _setSorting(table, field, direction));

  List<Element> _createTree() {
    CpuProfileVirtualTreeElement tree;
    return [
      new StackTraceTreeConfigElement(
          showMode: false,
          showDirection: false,
          mode: ProfileTreeMode.function,
          direction: M.ProfileTreeDirection.exclusive,
          filter: _filter,
          queue: _r.queue)
        ..onFilterChange.listen((e) {
          _filter = e.element.filter.trim();
          tree.filters = _filter.isNotEmpty
              ? [
                  _filterTree,
                  (node) {
                    return node.name.contains(_filter);
                  }
                ]
              : [_filterTree];
        }),
      new BRElement(),
      tree = new CpuProfileVirtualTreeElement(_isolate, _progress.profile,
          mode: ProfileTreeMode.function,
          direction: M.ProfileTreeDirection.exclusive,
          queue: _r.queue)
        ..filters = _filter.isNotEmpty
            ? [
                _filterTree,
                (node) {
                  return node.name.contains(_filter);
                }
              ]
            : [_filterTree]
    ];
  }

  bool _filterTree(M.FunctionCallTreeNode node) =>
      node.profileFunction == _selected;

  Future _request({bool clear: false, bool forceFetch: false}) async {
    _progress = null;
    _progressStream = _profiles.get(isolate, M.SampleProfileTag.none,
        clear: clear, forceFetch: forceFetch);
    _r.dirty();
    _progress = (await _progressStream.first).progress;
    _r.dirty();
    if (M.isSampleProcessRunning(_progress.status)) {
      _progress = (await _progressStream.last).progress;
      _r.dirty();
    }
  }

  Future _clearCpuProfile(RefreshEvent e) async {
    e.element.disabled = true;
    await _request(clear: true);
    e.element.disabled = false;
  }

  Future _refresh(e) async {
    e.element.disabled = true;
    await _request(forceFetch: true);
    e.element.disabled = false;
  }

  _createSorter(_Table table) {
    var getter;
    switch (_sortingField[table]) {
      case _SortingField.exclusive:
        getter = _getExclusiveT;
        break;
      case _SortingField.inclusive:
        getter = _getInclusiveT;
        break;
      case _SortingField.callee:
        getter = _getCalleeT;
        break;
      case _SortingField.caller:
        getter = _getCallerT;
        break;
      case _SortingField.method:
        getter = (M.ProfileFunction s) => M.getFunctionFullName(s.function);
        break;
    }
    switch (_sortingDirection[table]) {
      case _SortingDirection.ascending:
        return (a, b) => getter(a).compareTo(getter(b));
      case _SortingDirection.descending:
        return (a, b) => getter(b).compareTo(getter(a));
    }
  }

  static double _getExclusiveT(M.ProfileFunction f) =>
      f.normalizedExclusiveTicks;
  static double _getInclusiveT(M.ProfileFunction f) =>
      f.normalizedInclusiveTicks;
  double _getCalleeT(M.ProfileFunction f) =>
      _selected.callees[f] / _selected.callees.values.reduce((a, b) => a + b);
  double _getCallerT(M.ProfileFunction f) =>
      _selected.callers[f] / _selected.callers.values.reduce((a, b) => a + b);
}
