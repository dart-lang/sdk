// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library cpu_profile_table_element;

import 'dart:async';

import 'package:web/web.dart';

import '../../models.dart' as M;
import 'containers/virtual_collection.dart';
import 'cpu_profile/virtual_tree.dart';
import 'function_ref.dart';
import 'helpers/custom_element.dart';
import 'helpers/element_utils.dart';
import 'helpers/nav_bar.dart';
import 'helpers/nav_menu.dart';
import 'helpers/rendering_scheduler.dart';
import 'nav/isolate_menu.dart';
import 'nav/notify.dart';
import 'nav/refresh.dart';
import 'nav/top_menu.dart';
import 'nav/vm_menu.dart';
import 'sample_buffer_control.dart';
import 'stack_trace_tree_config.dart';
import '../../utils.dart';

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
    M.IsolateSampleProfileRepository profiles, {
    RenderingQueue? queue,
  }) {
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
    removeChildren();
  }

  void render() {
    var content = <HTMLElement>[
      navBar(<HTMLElement>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue).element,
        navMenu('cpu profile (table)'),
        (new NavRefreshElement(
          queue: _r.queue,
        )..onRefresh.listen(_refresh)).element,
        (new NavRefreshElement(
          label: 'Clear',
          queue: _r.queue,
        )..onRefresh.listen(_clearCpuSamples)).element,
        new NavNotifyElement(_notifications, queue: _r.queue).element,
      ]),
    ];
    if (_progress == null) {
      setChildren(content);
      return;
    }
    content.add(
      new SampleBufferControlElement(
        _vm,
        _progress!,
        _progressStream,
        showTag: false,
        queue: _r.queue,
      ).element,
    );
    if (_progress!.status == M.SampleProfileLoadingStatus.loaded) {
      content.add(new HTMLBRElement());
      content.addAll(_createTables());
      content.add(new HTMLBRElement());
      content.addAll(_createTree());
    }
    setChildren(content);
  }

  M.ProfileFunction? _selected;
  VirtualCollectionElement? _functions;
  VirtualCollectionElement? _callers;
  VirtualCollectionElement? _callees;

  List<HTMLElement> _createTables() {
    _functions =
        _functions ??
        new VirtualCollectionElement(
          _createFunction,
          _updateFunction,
          createHeader: _createFunctionHeader,
          search: _searchFunction,
          queue: _r.queue,
        );
    // If there's no samples, don't populate the function list.
    _functions!.items =
        (_progress!.profile.sampleCount != 0)
              ? _progress!.profile.functions.toList()
              : []
          ..sort(_createSorter(_Table.functions));
    _functions!.takeIntoView(_selected);
    _callers =
        _callers ??
        new VirtualCollectionElement(
          _createCaller,
          _updateCaller,
          createHeader: _createCallerHeader,
          search: _searchFunction,
          queue: _r.queue,
        );
    _callees =
        _callees ??
        new VirtualCollectionElement(
          _createCallee,
          _updateCallee,
          createHeader: _createCalleeHeader,
          search: _searchFunction,
          queue: _r.queue,
        );
    if (_selected != null) {
      _callers!.items = _selected!.callers.keys.toList()
        ..sort(_createSorter(_Table.caller));
      _callees!.items = _selected!.callees.keys.toList()
        ..sort(_createSorter(_Table.callee));
    } else {
      _callers!.items = const [];
      _callees!.items = const [];
    }
    return <HTMLElement>[
      new HTMLDivElement()
        ..className = 'profile-trees'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'profile-trees-all'
            ..appendChildren(<HTMLElement>[_functions!.element]),
          new HTMLDivElement()
            ..className = 'profile-trees-current'
            ..appendChildren(<HTMLElement>[
              new HTMLDivElement()
                ..className = 'profile-trees-caller'
                ..appendChildren(<HTMLElement>[_callers!.element]),
              new HTMLDivElement()
                ..className = 'profile-trees-selected'
                ..setChildren(
                  _selected == null
                      ? [
                          new HTMLSpanElement()
                            ..textContent = 'No element selected',
                        ]
                      : [
                          new FunctionRefElement(
                            _isolate,
                            _selected!.function!,
                            queue: _r.queue,
                          ).element,
                        ],
                ),
              new HTMLDivElement()
                ..className = 'profile-trees-callee'
                ..appendChildren(<HTMLElement>[_callees!.element]),
            ]),
        ]),
    ];
  }

  HTMLElement _createFunction() {
    final element = new HTMLDivElement()
      ..className = 'function-item'
      ..appendChildren(<HTMLElement>[
        new HTMLSpanElement()
          ..className = 'exclusive'
          ..textContent = '0%',
        new HTMLSpanElement()
          ..className = 'inclusive'
          ..textContent = '0%',
        new HTMLSpanElement()..className = 'name',
      ]);
    element.onClick.listen((e) {
      if (e.target is HTMLAnchorElement) {
        return;
      }
      _selected = _functions!.getItemFromElement(element);
      _r.dirty();
    });
    return element;
  }

  void _updateFunction(HTMLElement e, itemDynamic, int index) {
    M.ProfileFunction item = itemDynamic;
    if (item == _selected) {
      e.className = 'function-item selected';
    } else {
      e.className = 'function-item';
    }
    (e.children.item(0) as HTMLElement).textContent =
        Utils.formatPercentNormalized(_getExclusiveT(item));
    (e.children.item(1) as HTMLElement).textContent =
        Utils.formatPercentNormalized(_getInclusiveT(item));
    (e.children.item(2) as HTMLElement).textContent = M.getFunctionFullName(
      item.function!,
    );
  }

  List<HTMLElement> _createFunctionHeader() => [
    new HTMLDivElement()
      ..className = 'function-item'
      ..appendChildren(<HTMLElement>[
        _createHeaderButton(
          'exclusive',
          'Execution(%)',
          _Table.functions,
          _SortingField.exclusive,
          _SortingDirection.descending,
        ),
        _createHeaderButton(
          'inclusive',
          'Stack(%)',
          _Table.functions,
          _SortingField.inclusive,
          _SortingDirection.descending,
        ),
        _createHeaderButton(
          'name',
          'Method',
          _Table.functions,
          _SortingField.method,
          _SortingDirection.ascending,
        ),
      ]),
  ];

  bool _searchFunction(Pattern pattern, itemDynamic) {
    M.ProfileFunction item = itemDynamic;
    return M.getFunctionFullName(item.function!).contains(pattern);
  }

  void _setSorting(
    _Table table,
    _SortingField field,
    _SortingDirection defaultDirection,
  ) {
    if (_sortingField[table] == field) {
      switch (_sortingDirection[table]!) {
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

  HTMLElement _createCallee() {
    final element = new HTMLDivElement()
      ..className = 'function-item'
      ..appendChildren(<HTMLElement>[
        new HTMLSpanElement()
          ..className = 'inclusive'
          ..textContent = '0%',
        new HTMLSpanElement()..className = 'name',
      ]);
    element.onClick.listen((e) {
      if (e.target is HTMLAnchorElement) {
        return;
      }
      _selected = _callees!.getItemFromElement(element);
      _r.dirty();
    });
    return element;
  }

  void _updateCallee(HTMLElement e, item, int index) {
    (e.children.item(0) as HTMLElement).textContent =
        Utils.formatPercentNormalized(_getCalleeT(item));
    (e.children.item(1) as HTMLElement).textContent = M.getFunctionFullName(
      item.function,
    );
  }

  List<HTMLElement> _createCalleeHeader() => [
    new HTMLDivElement()
      ..className = 'function-item'
      ..appendChildren(<HTMLElement>[
        _createHeaderButton(
          'inclusive',
          'Callees(%)',
          _Table.callee,
          _SortingField.callee,
          _SortingDirection.descending,
        ),
        _createHeaderButton(
          'name',
          'Method',
          _Table.callee,
          _SortingField.method,
          _SortingDirection.ascending,
        ),
      ]),
  ];

  HTMLElement _createCaller() {
    final element = new HTMLDivElement()
      ..className = 'function-item'
      ..appendChildren(<HTMLElement>[
        new HTMLSpanElement()
          ..className = 'inclusive'
          ..textContent = '0%',
        new HTMLSpanElement()..className = 'name',
      ]);
    element.onClick.listen((e) {
      if (e.target is HTMLAnchorElement) {
        return;
      }
      _selected = _callers!.getItemFromElement(element);
      _r.dirty();
    });
    return element;
  }

  void _updateCaller(HTMLElement e, item, int index) {
    (e.children.item(0) as HTMLElement).textContent =
        Utils.formatPercentNormalized(_getCallerT(item));
    (e.children.item(1) as HTMLElement).textContent = M.getFunctionFullName(
      item.function,
    );
  }

  List<HTMLElement> _createCallerHeader() => [
    new HTMLDivElement()
      ..className = 'function-item'
      ..appendChildren(<HTMLElement>[
        _createHeaderButton(
          'inclusive',
          'Callers(%)',
          _Table.caller,
          _SortingField.caller,
          _SortingDirection.descending,
        ),
        _createHeaderButton(
          'name',
          'Method',
          _Table.caller,
          _SortingField.method,
          _SortingDirection.ascending,
        ),
      ]),
  ];

  HTMLButtonElement _createHeaderButton(
    String className,
    String text,
    _Table table,
    _SortingField field,
    _SortingDirection direction,
  ) => new HTMLButtonElement()
    ..className = className
    ..textContent = _sortingField[table] != field
        ? text
        : _sortingDirection[table] == _SortingDirection.ascending
        ? '$text▼'
        : '$text▲'
    ..onClick.listen((_) => _setSorting(table, field, direction));

  List<HTMLElement> _createTree() {
    late CpuProfileVirtualTreeElement tree;
    return [
      (new StackTraceTreeConfigElement(
              showMode: false,
              showDirection: false,
              mode: ProfileTreeMode.function,
              direction: M.ProfileTreeDirection.exclusive,
              filter: _filter,
              queue: _r.queue,
            )
            ..onFilterChange.listen((e) {
              _filter = e.element.filter.trim();
              tree.filters = _filter.isNotEmpty
                  ? [
                      _filterTree,
                      (node) {
                        return node.name.contains(_filter);
                      },
                    ]
                  : [_filterTree];
            }))
          .element,
      new HTMLBRElement(),
      (tree =
              new CpuProfileVirtualTreeElement(
                  _isolate,
                  _progress!.profile,
                  mode: ProfileTreeMode.function,
                  direction: M.ProfileTreeDirection.exclusive,
                  queue: _r.queue,
                )
                ..filters = _filter.isNotEmpty
                    ? [
                        _filterTree,
                        (node) {
                          return node.name.contains(_filter);
                        },
                      ]
                    : [_filterTree])
          .element,
    ];
  }

  bool _filterTree(nodeDynamic) {
    M.FunctionCallTreeNode node = nodeDynamic;
    return node.profileFunction == _selected;
  }

  Future _request({bool clear = false, bool forceFetch = false}) async {
    _progress = null;
    _progressStream = _profiles.get(
      isolate,
      M.SampleProfileTag.vmOnly,
      clear: clear,
      forceFetch: forceFetch,
    );
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
    switch (_sortingField[table]!) {
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
    switch (_sortingDirection[table]!) {
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
