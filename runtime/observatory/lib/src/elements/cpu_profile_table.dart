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
import 'package:observatory/src/elements/helpers/custom_element.dart';
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

class CpuProfileTableElement extends CustomElement implements Renderable {
  late RenderingScheduler<CpuProfileTableElement> _r;

  Stream<RenderedEvent<CpuProfileTableElement>> get onRendered => _r.onRendered;

  late M.VM _vm;
  late M.IsolateRef _isolate;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  late M.IsolateSampleProfileRepository _profiles;
  late Stream<M.SampleProfileLoadingProgressEvent> _progressStream;
  M.SampleProfileLoadingProgress? _progress;
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
      {RenderingQueue? queue}) {
    assert(vm != null);
    assert(isolate != null);
    assert(events != null);
    assert(notifications != null);
    assert(profiles != null);
    CpuProfileTableElement e = new CpuProfileTableElement.created();
    e._r = new RenderingScheduler<CpuProfileTableElement>(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._profiles = profiles;
    return e;
  }

  CpuProfileTableElement.created() : super.created('cpu-profile-table');

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
    children = <Element>[];
  }

  void render() {
    var content = <Element>[
      navBar(<Element>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue).element,
        navMenu('cpu profile (table)'),
        (new NavRefreshElement(queue: _r.queue)..onRefresh.listen(_refresh))
            .element,
        (new NavRefreshElement(label: 'Clear', queue: _r.queue)
              ..onRefresh.listen(_clearCpuSamples))
            .element,
        new NavNotifyElement(_notifications, queue: _r.queue).element
      ]),
    ];
    if (_progress == null) {
      children = content;
      return;
    }
    content.add(new SampleBufferControlElement(_vm, _progress!, _progressStream,
            showTag: false, queue: _r.queue)
        .element);
    if (_progress!.status == M.SampleProfileLoadingStatus.loaded) {
      content.add(new BRElement());
      content.addAll(_createTables());
      content.add(new BRElement());
      content.addAll(_createTree());
    }
    children = content;
  }

  M.ProfileFunction? _selected;
  VirtualCollectionElement? _functions;
  VirtualCollectionElement? _callers;
  VirtualCollectionElement? _callees;

  List<Element> _createTables() {
    _functions = _functions ??
        new VirtualCollectionElement(_createFunction, _updateFunction,
            createHeader: _createFunctionHeader,
            search: _searchFunction,
            queue: _r.queue);
    // If there's no samples, don't populate the function list.
    _functions!.items = (_progress!.profile.sampleCount != 0)
        ? _progress!.profile.functions.toList()
        : []
      ..sort(_createSorter(_Table.functions));
    _functions!.takeIntoView(_selected);
    _callers = _callers ??
        new VirtualCollectionElement(_createCaller, _updateCaller,
            createHeader: _createCallerHeader,
            search: _searchFunction,
            queue: _r.queue);
    _callees = _callees ??
        new VirtualCollectionElement(_createCallee, _updateCallee,
            createHeader: _createCalleeHeader,
            search: _searchFunction,
            queue: _r.queue);
    if (_selected != null) {
      _callers!.items = _selected!.callers.keys.toList()
        ..sort(_createSorter(_Table.caller));
      _callees!.items = _selected!.callees.keys.toList()
        ..sort(_createSorter(_Table.callee));
    } else {
      _callers!.items = const [];
      _callees!.items = const [];
    }
    return <Element>[
      new DivElement()
        ..classes = ['profile-trees']
        ..children = <Element>[
          new DivElement()
            ..classes = ['profile-trees-all']
            ..children = <Element>[_functions!.element],
          new DivElement()
            ..classes = ['profile-trees-current']
            ..children = <Element>[
              new DivElement()
                ..classes = ['profile-trees-caller']
                ..children = <Element>[_callers!.element],
              new DivElement()
                ..classes = ['profile-trees-selected']
                ..children = _selected == null
                    ? [new SpanElement()..text = 'No element selected']
                    : [
                        new FunctionRefElement(_isolate, _selected!.function!,
                                queue: _r.queue)
                            .element
                      ],
              new DivElement()
                ..classes = ['profile-trees-callee']
                ..children = <Element>[_callees!.element]
            ]
        ]
    ];
  }

  HtmlElement _createFunction() {
    final element = new DivElement()
      ..classes = ['function-item']
      ..children = <Element>[
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
      _selected = _functions!.getItemFromElement(element);
      _r.dirty();
    });
    return element;
  }

  void _updateFunction(Element e, itemDynamic, int index) {
    M.ProfileFunction item = itemDynamic;
    if (item == _selected) {
      e.classes = ['function-item', 'selected'];
    } else {
      e.classes = ['function-item'];
    }
    e.children[0].text = Utils.formatPercentNormalized(_getExclusiveT(item));
    e.children[1].text = Utils.formatPercentNormalized(_getInclusiveT(item));
    e.children[2].text = M.getFunctionFullName(item.function!);
  }

  List<HtmlElement> _createFunctionHeader() => [
        new DivElement()
          ..classes = ['function-item']
          ..children = <Element>[
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

  bool _searchFunction(Pattern pattern, itemDynamic) {
    M.ProfileFunction item = itemDynamic;
    return M.getFunctionFullName(item.function!).contains(pattern);
  }

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

  HtmlElement _createCallee() {
    final element = new DivElement()
      ..classes = ['function-item']
      ..children = <Element>[
        new SpanElement()
          ..classes = ['inclusive']
          ..text = '0%',
        new SpanElement()..classes = ['name']
      ];
    element.onClick.listen((e) {
      if (e.target is AnchorElement) {
        return;
      }
      _selected = _callees!.getItemFromElement(element);
      _r.dirty();
    });
    return element;
  }

  void _updateCallee(Element e, item, int index) {
    e.children[0].text = Utils.formatPercentNormalized(_getCalleeT(item));
    e.children[1].text = M.getFunctionFullName(item.function);
  }

  List<HtmlElement> _createCalleeHeader() => [
        new DivElement()
          ..classes = ['function-item']
          ..children = <Element>[
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

  HtmlElement _createCaller() {
    final element = new DivElement()
      ..classes = ['function-item']
      ..children = <Element>[
        new SpanElement()
          ..classes = ['inclusive']
          ..text = '0%',
        new SpanElement()..classes = ['name']
      ];
    element.onClick.listen((e) {
      if (e.target is AnchorElement) {
        return;
      }
      _selected = _callers!.getItemFromElement(element);
      _r.dirty();
    });
    return element;
  }

  void _updateCaller(Element e, item, int index) {
    e.children[0].text = Utils.formatPercentNormalized(_getCallerT(item));
    e.children[1].text = M.getFunctionFullName(item.function);
  }

  List<HtmlElement> _createCallerHeader() => [
        new DivElement()
          ..classes = ['function-item']
          ..children = <Element>[
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
    late CpuProfileVirtualTreeElement tree;
    return [
      (new StackTraceTreeConfigElement(
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
            }))
          .element,
      new BRElement(),
      (tree = new CpuProfileVirtualTreeElement(_isolate, _progress!.profile,
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
                : [_filterTree])
          .element
    ];
  }

  bool _filterTree(nodeDynamic) {
    M.FunctionCallTreeNode node = nodeDynamic;
    return node.profileFunction == _selected;
  }

  Future _request({bool clear: false, bool forceFetch: false}) async {
    _progress = null;
    _progressStream = _profiles.get(isolate, M.SampleProfileTag.vmOnly,
        clear: clear, forceFetch: forceFetch);
    _r.dirty();
    _progress = (await _progressStream.first).progress;
    _r.dirty();
    if (M.isSampleProcessRunning(_progress!.status)) {
      _progress = (await _progressStream.last).progress;
      _r.dirty();
    }
  }

  Future _clearCpuSamples(RefreshEvent e) async {
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
        getter = (M.ProfileFunction s) => M.getFunctionFullName(s.function!);
        break;
    }
    switch (_sortingDirection[table]) {
      case _SortingDirection.ascending:
        int sort(a, b) {
          return getter(a).compareTo(getter(b));
        }
        return sort;
      case _SortingDirection.descending:
        int sort(a, b) {
          return getter(b).compareTo(getter(a));
        }
        return sort;
    }
  }

  static double _getExclusiveT(M.ProfileFunction f) =>
      f.normalizedExclusiveTicks;
  static double _getInclusiveT(M.ProfileFunction f) =>
      f.normalizedInclusiveTicks;
  double _getCalleeT(M.ProfileFunction f) =>
      _selected!.callees[f]! /
      _selected!.callees.values.reduce((a, b) => a + b);
  double _getCallerT(M.ProfileFunction f) =>
      _selected!.callers[f]! /
      _selected!.callers.values.reduce((a, b) => a + b);
}
