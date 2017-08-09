// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:charted/charted.dart';
import "package:charted/charts/charts.dart";
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/class_ref.dart';
import 'package:observatory/src/elements/containers/virtual_collection.dart';
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/utils.dart';

enum _SortingField {
  accumulatedSize,
  accumulatedInstances,
  currentSize,
  currentInstances,
  newAccumulatedSize,
  newAccumulatedInstances,
  newCurrentSize,
  newCurrentInstances,
  oldAccumulatedSize,
  oldAccumulatedInstances,
  oldCurrentSize,
  oldCurrentInstances,
  className,
}

enum _SortingDirection { ascending, descending }

class AllocationProfileElement extends HtmlElement implements Renderable {
  static const tag = const Tag<AllocationProfileElement>('allocation-profile',
      dependencies: const [
        ClassRefElement.tag,
        NavTopMenuElement.tag,
        NavVMMenuElement.tag,
        NavIsolateMenuElement.tag,
        NavRefreshElement.tag,
        NavNotifyElement.tag,
        VirtualCollectionElement.tag
      ]);

  RenderingScheduler<AllocationProfileElement> _r;

  Stream<RenderedEvent<AllocationProfileElement>> get onRendered =>
      _r.onRendered;

  M.VM _vm;
  M.IsolateRef _isolate;
  M.EventRepository _events;
  M.NotificationRepository _notifications;
  M.AllocationProfileRepository _repository;
  M.AllocationProfile _profile;
  bool _autoRefresh = false;
  bool _isCompacted = false;
  StreamSubscription _gcSubscription;
  _SortingField _sortingField = _SortingField.currentSize;
  _SortingDirection _sortingDirection = _SortingDirection.descending;

  M.VMRef get vm => _vm;
  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;

  factory AllocationProfileElement(
      M.VM vm,
      M.IsolateRef isolate,
      M.EventRepository events,
      M.NotificationRepository notifications,
      M.AllocationProfileRepository repository,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(isolate != null);
    assert(events != null);
    assert(notifications != null);
    assert(repository != null);
    AllocationProfileElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._repository = repository;
    return e;
  }

  AllocationProfileElement.created() : super.created();

  @override
  attached() {
    super.attached();
    _r.enable();
    _refresh();
    _gcSubscription = _events.onGCEvent.listen((e) {
      if (_autoRefresh && (e.isolate.id == _isolate.id)) {
        _refresh();
      }
    });
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    children = [];
    _gcSubscription.cancel();
  }

  void render() {
    children = [
      navBar([
        new NavTopMenuElement(queue: _r.queue),
        new NavVMMenuElement(_vm, _events, queue: _r.queue),
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue),
        navMenu('allocation profile'),
        new NavRefreshElement(
            label: 'Download', disabled: _profile == null, queue: _r.queue)
          ..onRefresh.listen((_) => _downloadCSV()),
        new NavRefreshElement(label: 'Reset Accumulator', queue: _r.queue)
          ..onRefresh.listen((_) => _refresh(reset: true)),
        new NavRefreshElement(label: 'GC', queue: _r.queue)
          ..onRefresh.listen((_) => _refresh(gc: true)),
        new NavRefreshElement(queue: _r.queue)
          ..onRefresh.listen((_) => _refresh()),
        new DivElement()
          ..classes = ['nav-option']
          ..children = [
            new CheckboxInputElement()
              ..id = 'allocation-profile-auto-refresh'
              ..checked = _autoRefresh
              ..onChange.listen((_) => _autoRefresh = !_autoRefresh),
            new LabelElement()
              ..htmlFor = 'allocation-profile-auto-refresh'
              ..text = 'Auto-refresh on GC'
          ],
        new NavNotifyElement(_notifications, queue: _r.queue)
      ]),
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = [
          new HeadingElement.h2()..text = 'Allocation Profile',
          new HRElement()
        ]
    ];
    if (_profile == null) {
      children.addAll([
        new DivElement()
          ..classes = ['content-centered-big']
          ..children = [new HeadingElement.h2()..text = 'Loading...']
      ]);
    } else {
      final newChartHost = new DivElement()..classes = ['host'];
      final newChartLegend = new DivElement()..classes = ['legend'];
      final oldChartHost = new DivElement()..classes = ['host'];
      final oldChartLegend = new DivElement()..classes = ['legend'];
      children.addAll([
        new DivElement()
          ..classes = ['content-centered-big']
          ..children = _isCompacted
              ? []
              : [
                  new DivElement()
                    ..classes = ['memberList']
                    ..children = [
                      new DivElement()
                        ..classes = ['memberItem']
                        ..children = [
                          new DivElement()
                            ..classes = ['memberName']
                            ..text = 'last forced GC at',
                          new DivElement()
                            ..classes = ['memberValue']
                            ..text = _profile.lastServiceGC == null
                                ? '---'
                                : '${_profile.lastServiceGC}',
                        ],
                      new DivElement()
                        ..classes = ['memberItem']
                        ..children = [
                          new DivElement()
                            ..classes = ['memberName']
                            ..text = 'last accumulator reset at',
                          new DivElement()
                            ..classes = ['memberValue']
                            ..text = _profile.lastAccumulatorReset == null
                                ? '---'
                                : '${_profile.lastAccumulatorReset}',
                        ]
                    ],
                  new HRElement(),
                ],
        new DivElement()
          ..classes = ['content-centered-big', 'compactable']
          ..children = [
            new DivElement()
              ..classes = ['heap-space', 'left']
              ..children = _isCompacted
                  ? [
                      new HeadingElement.h2()
                        ..text = 'New Generation '
                            '(${_usedCaption(_profile.newSpace)})',
                    ]
                  : [
                      new HeadingElement.h2()..text = 'New Generation',
                      new BRElement(),
                      new DivElement()
                        ..classes = ['memberList']
                        ..children = _createSpaceMembers(_profile.newSpace),
                      new BRElement(),
                      new DivElement()
                        ..classes = ['chart']
                        ..children = [newChartLegend, newChartHost]
                    ],
            new DivElement()
              ..classes = ['heap-space', 'right']
              ..children = _isCompacted
                  ? [
                      new HeadingElement.h2()
                        ..text = '(${_usedCaption(_profile.oldSpace)}) '
                            'Old Generation',
                    ]
                  : [
                      new HeadingElement.h2()..text = 'Old Generation',
                      new BRElement(),
                      new DivElement()
                        ..classes = ['memberList']
                        ..children = _createSpaceMembers(_profile.oldSpace),
                      new BRElement(),
                      new DivElement()
                        ..classes = ['chart']
                        ..children = [oldChartLegend, oldChartHost]
                    ],
            new ButtonElement()
              ..classes = ['compact']
              ..text = _isCompacted ? 'expand ▼' : 'compact ▲'
              ..onClick.listen((_) {
                _isCompacted = !_isCompacted;
                _r.dirty();
              }),
            new HRElement()
          ],
        new DivElement()
          ..classes = _isCompacted ? ['collection', 'expanded'] : ['collection']
          ..children = [
            new VirtualCollectionElement(
                _createCollectionLine, _updateCollectionLine,
                createHeader: _createCollectionHeader,
                items: _profile.members.toList()..sort(_createSorter()),
                queue: _r.queue)
          ]
      ]);
      _renderGraph(newChartHost, newChartLegend, _profile.newSpace);
      _renderGraph(oldChartHost, oldChartLegend, _profile.oldSpace);
    }
  }

  _createSorter() {
    var getter;
    switch (_sortingField) {
      case _SortingField.accumulatedSize:
        getter = _getAccumulatedSize;
        break;
      case _SortingField.accumulatedInstances:
        getter = _getAccumulatedInstances;
        break;
      case _SortingField.currentSize:
        getter = _getCurrentSize;
        break;
      case _SortingField.currentInstances:
        getter = _getCurrentInstances;
        break;
      case _SortingField.newAccumulatedSize:
        getter = _getNewAccumulatedSize;
        break;
      case _SortingField.newAccumulatedInstances:
        getter = _getNewAccumulatedInstances;
        break;
      case _SortingField.newCurrentSize:
        getter = _getNewCurrentSize;
        break;
      case _SortingField.newCurrentInstances:
        getter = _getNewCurrentInstances;
        break;
      case _SortingField.oldAccumulatedSize:
        getter = _getOldAccumulatedSize;
        break;
      case _SortingField.oldAccumulatedInstances:
        getter = _getOldAccumulatedInstances;
        break;
      case _SortingField.oldCurrentSize:
        getter = _getOldCurrentSize;
        break;
      case _SortingField.oldCurrentInstances:
        getter = _getOldCurrentInstances;
        break;
      case _SortingField.className:
        getter = (M.ClassHeapStats s) => s.clazz.name;
        break;
    }
    switch (_sortingDirection) {
      case _SortingDirection.ascending:
        return (a, b) => getter(a).compareTo(getter(b));
      case _SortingDirection.descending:
        return (a, b) => getter(b).compareTo(getter(a));
    }
  }

  static Element _createCollectionLine() => new DivElement()
    ..classes = ['collection-item']
    ..children = [
      new SpanElement()
        ..classes = ['bytes']
        ..text = '0B',
      new SpanElement()
        ..classes = ['instances']
        ..text = '0',
      new SpanElement()
        ..classes = ['bytes']
        ..text = '0B',
      new SpanElement()
        ..classes = ['instances']
        ..text = '0',
      new SpanElement()
        ..classes = ['bytes']
        ..text = '0B',
      new SpanElement()
        ..classes = ['instances']
        ..text = '0',
      new SpanElement()
        ..classes = ['bytes']
        ..text = '0B',
      new SpanElement()
        ..classes = ['instances']
        ..text = '0',
      new SpanElement()
        ..classes = ['bytes']
        ..text = '0B',
      new SpanElement()
        ..classes = ['instances']
        ..text = '0',
      new SpanElement()
        ..classes = ['bytes']
        ..text = '0B',
      new SpanElement()
        ..classes = ['instances']
        ..text = '0',
      new SpanElement()..classes = ['name']
    ];

  List<HtmlElement> _createCollectionHeader() => [
        new DivElement()
          ..classes = ['collection-item']
          ..children = [
            new SpanElement()
              ..classes = ['group']
              ..text = 'Accumulated',
            new SpanElement()
              ..classes = ['group']
              ..text = 'Current',
            new SpanElement()
              ..classes = ['group']
              ..text = '(NEW) Accumulated',
            new SpanElement()
              ..classes = ['group']
              ..text = '(NEW) Current',
            new SpanElement()
              ..classes = ['group']
              ..text = '(OLD) Accumulated',
            new SpanElement()
              ..classes = ['group']
              ..text = '(OLD) Current',
          ],
        new DivElement()
          ..classes = ['collection-item']
          ..children = [
            _createHeaderButton(const ['bytes'], 'Size',
                _SortingField.accumulatedSize, _SortingDirection.descending),
            _createHeaderButton(
                const ['instances'],
                'Instances',
                _SortingField.accumulatedInstances,
                _SortingDirection.descending),
            _createHeaderButton(const ['bytes'], 'Size',
                _SortingField.currentSize, _SortingDirection.descending),
            _createHeaderButton(const ['instances'], 'Instances',
                _SortingField.currentInstances, _SortingDirection.descending),
            _createHeaderButton(const ['bytes'], 'Size',
                _SortingField.newAccumulatedSize, _SortingDirection.descending),
            _createHeaderButton(
                const ['instances'],
                'Instances',
                _SortingField.newAccumulatedInstances,
                _SortingDirection.descending),
            _createHeaderButton(const ['bytes'], 'Size',
                _SortingField.newCurrentSize, _SortingDirection.descending),
            _createHeaderButton(
                const ['instances'],
                'Instances',
                _SortingField.newCurrentInstances,
                _SortingDirection.descending),
            _createHeaderButton(const ['bytes'], 'Size',
                _SortingField.oldAccumulatedSize, _SortingDirection.descending),
            _createHeaderButton(
                const ['instances'],
                'Instances',
                _SortingField.oldAccumulatedInstances,
                _SortingDirection.descending),
            _createHeaderButton(const ['bytes'], 'Size',
                _SortingField.oldCurrentSize, _SortingDirection.descending),
            _createHeaderButton(
                const ['instances'],
                'Instances',
                _SortingField.oldCurrentInstances,
                _SortingDirection.descending),
            _createHeaderButton(const ['name'], 'Class',
                _SortingField.className, _SortingDirection.ascending)
          ],
      ];

  ButtonElement _createHeaderButton(List<String> classes, String text,
          _SortingField field, _SortingDirection direction) =>
      new ButtonElement()
        ..classes = classes
        ..text = _sortingField != field
            ? text
            : _sortingDirection == _SortingDirection.ascending
                ? '$text▼'
                : '$text▲'
        ..onClick.listen((_) => _setSorting(field, direction));

  void _setSorting(_SortingField field, _SortingDirection defaultDirection) {
    if (_sortingField == field) {
      switch (_sortingDirection) {
        case _SortingDirection.descending:
          _sortingDirection = _SortingDirection.ascending;
          break;
        case _SortingDirection.ascending:
          _sortingDirection = _SortingDirection.descending;
          break;
      }
    } else {
      _sortingDirection = defaultDirection;
      _sortingField = field;
    }
    _r.dirty();
  }

  void _updateCollectionLine(Element e, M.ClassHeapStats item, index) {
    e.children[0].text = Utils.formatSize(_getAccumulatedSize(item));
    e.children[1].text = '${_getAccumulatedInstances(item)}';
    e.children[2].text = Utils.formatSize(_getCurrentSize(item));
    e.children[3].text = '${_getCurrentInstances(item)}';
    e.children[4].text = Utils.formatSize(_getNewAccumulatedSize(item));
    e.children[5].text = '${_getNewAccumulatedInstances(item)}';
    e.children[6].text = Utils.formatSize(_getNewCurrentSize(item));
    e.children[7].text = '${_getNewCurrentInstances(item)}';
    e.children[8].text = Utils.formatSize(_getOldAccumulatedSize(item));
    e.children[9].text = '${_getOldAccumulatedInstances(item)}';
    e.children[10].text = Utils.formatSize(_getOldCurrentSize(item));
    e.children[11].text = '${_getOldCurrentInstances(item)}';
    e.children[12] = new ClassRefElement(_isolate, item.clazz, queue: _r.queue)
      ..classes = ['name'];
  }

  static String _usedCaption(M.HeapSpace space) =>
      '${Utils.formatSize(space.used)}'
      ' of '
      '${Utils.formatSize(space.capacity)}';

  static List<Element> _createSpaceMembers(M.HeapSpace space) {
    final used = _usedCaption(space);
    final ext = '${Utils.formatSize(space.external)}';
    final collections = '${space.collections}';
    final avgCollectionTime =
        '${Utils.formatDurationInMilliseconds(space.avgCollectionTime)} ms';
    final totalCollectionTime =
        '${Utils.formatDurationInSeconds(space.totalCollectionTime)} secs';
    final avgCollectionPeriod =
        '${Utils.formatDurationInMilliseconds(space.avgCollectionPeriod)} ms';
    return [
      new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'used',
          new DivElement()
            ..classes = ['memberValue']
            ..text = used
        ],
      new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'external',
          new DivElement()
            ..classes = ['memberValue']
            ..text = ext
        ],
      new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'collections',
          new DivElement()
            ..classes = ['memberValue']
            ..text = collections
        ],
      new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'average collection time',
          new DivElement()
            ..classes = ['memberValue']
            ..text = avgCollectionTime
        ],
      new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'cumulative collection time',
          new DivElement()
            ..classes = ['memberValue']
            ..text = totalCollectionTime
        ],
      new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'average time between collections',
          new DivElement()
            ..classes = ['memberValue']
            ..text = avgCollectionPeriod
        ]
    ];
  }

  static final _columns = [
    new ChartColumnSpec(label: 'Type', type: ChartColumnSpec.TYPE_STRING),
    new ChartColumnSpec(label: 'Size', formatter: (v) => v.toString())
  ];

  static void _renderGraph(Element host, Element legend, M.HeapSpace space) {
    final series = [
      new ChartSeries("Work", [1], new PieChartRenderer(sortDataByValue: false))
    ];
    final rect = host.getBoundingClientRect();
    final minSize = new Rect.size(rect.width, rect.height);
    final config = new ChartConfig(series, [0])
      ..minimumSize = minSize
      ..legend = new ChartLegend(legend, showValues: true);
    final data = new ChartData(_columns, [
      ['Used', space.used],
      ['Free', space.capacity - space.used],
      ['External', space.external]
    ]);

    new LayoutArea(host, data, config,
        state: new ChartState(), autoUpdate: true)
      ..draw();
  }

  Future _refresh({bool gc: false, bool reset: false}) async {
    _profile = null;
    _r.dirty();
    _profile = await _repository.get(_isolate, gc: gc, reset: reset);
    _r.dirty();
  }

  void _downloadCSV() {
    assert(_profile != null);
    final header = [
          '"Accumulator Size"',
          '"Accumulator Instances"',
          '"Current Size"',
          '"Current Instances"',
          '"(NEW) Accumulator Size"',
          '"(NEW) Accumulator Instances"',
          '"(NEW) Current Size"',
          '"(NEW) Current Instances"',
          '"(OLD) Accumulator Size"',
          '"(OLD) Accumulator Instances"',
          '"(OLD) Current Size"',
          '"(OLD) Current Instances"',
          'Class'
        ].join(',') +
        '\n';
    AnchorElement tl = document.createElement('a');
    tl
      ..attributes['href'] = 'data:text/plain;charset=utf-8,' +
          Uri.encodeComponent(header +
              (_profile.members.toList()..sort(_createSorter()))
                  .map(_csvOut)
                  .join('\n'))
      ..attributes['download'] = 'heap-profile.csv'
      ..click();
  }

  static _csvOut(M.ClassHeapStats s) {
    return [
      _getAccumulatedSize(s),
      _getAccumulatedInstances(s),
      _getCurrentSize(s),
      _getCurrentInstances(s),
      _getNewAccumulatedSize(s),
      _getNewAccumulatedInstances(s),
      _getNewCurrentSize(s),
      _getNewCurrentInstances(s),
      _getOldAccumulatedSize(s),
      _getOldAccumulatedInstances(s),
      _getOldCurrentSize(s),
      _getOldCurrentInstances(s),
      s.clazz.name
    ].join(',');
  }

  static int _getAccumulatedSize(M.ClassHeapStats s) =>
      s.newSpace.accumulated.bytes + s.oldSpace.accumulated.bytes;
  static int _getAccumulatedInstances(M.ClassHeapStats s) =>
      s.newSpace.accumulated.instances + s.oldSpace.accumulated.instances;
  static int _getCurrentSize(M.ClassHeapStats s) =>
      s.newSpace.current.bytes + s.oldSpace.current.bytes;
  static int _getCurrentInstances(M.ClassHeapStats s) =>
      s.newSpace.current.instances + s.oldSpace.current.instances;
  static int _getNewAccumulatedSize(M.ClassHeapStats s) =>
      s.newSpace.accumulated.bytes;
  static int _getNewAccumulatedInstances(M.ClassHeapStats s) =>
      s.newSpace.accumulated.instances;
  static int _getNewCurrentSize(M.ClassHeapStats s) => s.newSpace.current.bytes;
  static int _getNewCurrentInstances(M.ClassHeapStats s) =>
      s.newSpace.current.instances;
  static int _getOldAccumulatedSize(M.ClassHeapStats s) =>
      s.oldSpace.accumulated.bytes;
  static int _getOldAccumulatedInstances(M.ClassHeapStats s) =>
      s.oldSpace.accumulated.instances;
  static int _getOldCurrentSize(M.ClassHeapStats s) => s.oldSpace.current.bytes;
  static int _getOldCurrentInstances(M.ClassHeapStats s) =>
      s.oldSpace.current.instances;
}
