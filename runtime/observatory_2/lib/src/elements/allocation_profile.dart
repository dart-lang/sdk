// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:observatory_2/models.dart' as M;
import 'package:observatory_2/src/elements/class_ref.dart';
import 'package:observatory_2/src/elements/containers/virtual_collection.dart';
import 'package:observatory_2/src/elements/helpers/nav_bar.dart';
import 'package:observatory_2/src/elements/helpers/nav_menu.dart';
import 'package:observatory_2/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory_2/src/elements/helpers/custom_element.dart';
import 'package:observatory_2/src/elements/nav/isolate_menu.dart';
import 'package:observatory_2/src/elements/nav/notify.dart';
import 'package:observatory_2/src/elements/nav/refresh.dart';
import 'package:observatory_2/src/elements/nav/top_menu.dart';
import 'package:observatory_2/src/elements/nav/vm_menu.dart';
import 'package:observatory_2/utils.dart';

enum _SortingField {
  newInstances,
  newInternalSize,
  newExternalSize,
  newSize,
  oldInstances,
  oldInternalSize,
  oldExternalSize,
  oldSize,
  instances,
  internalSize,
  externalSize,
  size,
  className,
}

enum _SortingDirection { ascending, descending }

class AllocationProfileElement extends CustomElement implements Renderable {
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
  _SortingField _sortingField = _SortingField.size;
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
    AllocationProfileElement e = new AllocationProfileElement.created();
    e._r = new RenderingScheduler<AllocationProfileElement>(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._repository = repository;
    return e;
  }

  AllocationProfileElement.created() : super.created('allocation-profile');

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
    children = <Element>[];
    _gcSubscription.cancel();
  }

  void render() {
    children = <Element>[
      navBar(<Element>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue).element,
        navMenu('allocation profile'),
        (new NavRefreshElement(
                label: 'Download', disabled: _profile == null, queue: _r.queue)
              ..onRefresh.listen((_) => _downloadCSV()))
            .element,
        (new NavRefreshElement(label: 'GC', queue: _r.queue)
              ..onRefresh.listen((_) => _refresh(gc: true)))
            .element,
        (new NavRefreshElement(queue: _r.queue)
              ..onRefresh.listen((_) => _refresh()))
            .element,
        new DivElement()
          ..classes = ['nav-option']
          ..children = <Element>[
            new CheckboxInputElement()
              ..id = 'allocation-profile-auto-refresh'
              ..checked = _autoRefresh
              ..onChange.listen((_) => _autoRefresh = !_autoRefresh),
            new LabelElement()
              ..htmlFor = 'allocation-profile-auto-refresh'
              ..text = 'Auto-refresh on GC'
          ],
        new NavNotifyElement(_notifications, queue: _r.queue).element
      ]),
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = <Element>[
          new HeadingElement.h2()..text = 'Allocation Profile',
          new HRElement()
        ]
    ];
    if (_profile == null) {
      children.addAll([
        new DivElement()
          ..classes = ['content-centered-big']
          ..children = <Element>[new HeadingElement.h2()..text = 'Loading...']
      ]);
    } else {
      children.addAll([
        new DivElement()
          ..classes = ['content-centered-big']
          ..children = _isCompacted
              ? []
              : [
                  new DivElement()
                    ..classes = ['memberList']
                    ..children = <Element>[
                      new DivElement()
                        ..classes = ['memberItem']
                        ..children = <Element>[
                          new DivElement()
                            ..classes = ['memberName']
                            ..text = 'last forced GC at',
                          new DivElement()
                            ..classes = ['memberValue']
                            ..text = _profile.lastServiceGC == null
                                ? '---'
                                : '${_profile.lastServiceGC}',
                        ],
                    ],
                  new HRElement(),
                ],
        new DivElement()
          ..classes = ['content-centered-big', 'compactable']
          ..children = <Element>[
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
                    ],
            new DivElement()
              ..classes = ['heap-space', 'left']
              ..children = _isCompacted
                  ? [
                      new HeadingElement.h2()
                        ..text = 'Old Generation '
                            '(${_usedCaption(_profile.oldSpace)})',
                    ]
                  : [
                      new HeadingElement.h2()..text = 'Old Generation',
                      new BRElement(),
                      new DivElement()
                        ..classes = ['memberList']
                        ..children = _createSpaceMembers(_profile.oldSpace),
                    ],
            new DivElement()
              ..classes = ['heap-space', 'left']
              ..children = _isCompacted
                  ? [
                      new HeadingElement.h2()
                        ..text = 'Total '
                            '(${_usedCaption(_profile.totalSpace)})',
                    ]
                  : [
                      new HeadingElement.h2()..text = 'Total',
                      new BRElement(),
                      new DivElement()
                        ..classes = ['memberList']
                        ..children = _createSpaceMembers(_profile.totalSpace),
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
          ..children = <Element>[
            new VirtualCollectionElement(
                    _createCollectionLine, _updateCollectionLine,
                    createHeader: _createCollectionHeader,
                    search: _search,
                    items: _profile.members.toList()..sort(_createSorter()),
                    queue: _r.queue)
                .element
          ]
      ]);
    }
  }

  _createSorter() {
    var getter;
    switch (_sortingField) {
      case _SortingField.newInternalSize:
        getter = _getNewInternalSize;
        break;
      case _SortingField.newExternalSize:
        getter = _getNewExternalSize;
        break;
      case _SortingField.newSize:
        getter = _getNewSize;
        break;
      case _SortingField.newInstances:
        getter = _getNewInstances;
        break;
      case _SortingField.oldInternalSize:
        getter = _getOldInternalSize;
        break;
      case _SortingField.oldExternalSize:
        getter = _getOldExternalSize;
        break;
      case _SortingField.oldSize:
        getter = _getOldSize;
        break;
      case _SortingField.oldInstances:
        getter = _getOldInstances;
        break;
      case _SortingField.internalSize:
        getter = _getInternalSize;
        break;
      case _SortingField.externalSize:
        getter = _getExternalSize;
        break;
      case _SortingField.size:
        getter = _getSize;
        break;
      case _SortingField.instances:
        getter = _getInstances;
        break;
      case _SortingField.className:
        getter = (M.ClassHeapStats s) => s.clazz.name;
        break;
    }
    switch (_sortingDirection) {
      case _SortingDirection.ascending:
        int sort(M.ClassHeapStats a, M.ClassHeapStats b) {
          return getter(a).compareTo(getter(b));
        }
        return sort;
      case _SortingDirection.descending:
        int sort(M.ClassHeapStats a, M.ClassHeapStats b) {
          return getter(b).compareTo(getter(a));
        }
        return sort;
    }
  }

  static HtmlElement _createCollectionLine() => new DivElement()
    ..classes = ['collection-item']
    ..children = <Element>[
      new SpanElement()
        ..classes = ['bytes']
        ..text = '0B',
      new SpanElement()
        ..classes = ['bytes']
        ..text = '0B',
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
        ..classes = ['bytes']
        ..text = '0B',
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
        ..classes = ['bytes']
        ..text = '0B',
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
          ..children = <Element>[
            new SpanElement()
              ..classes = ['group']
              ..text = 'New Generation',
            new SpanElement()
              ..classes = ['group']
              ..text = 'Old Generation',
            new SpanElement()
              ..classes = ['group']
              ..text = 'Total',
            new SpanElement()
              ..classes = ['group']
              ..text = '',
          ],
        new DivElement()
          ..classes = ['collection-item']
          ..children = <Element>[
            _createHeaderButton(const ['bytes'], 'Internal',
                _SortingField.newInternalSize, _SortingDirection.descending),
            _createHeaderButton(const ['bytes'], 'External',
                _SortingField.newExternalSize, _SortingDirection.descending),
            _createHeaderButton(const ['bytes'], 'Size', _SortingField.newSize,
                _SortingDirection.descending),
            _createHeaderButton(const ['instances'], 'Instances',
                _SortingField.newInstances, _SortingDirection.descending),
            _createHeaderButton(const ['bytes'], 'Internal',
                _SortingField.oldInternalSize, _SortingDirection.descending),
            _createHeaderButton(const ['bytes'], 'External',
                _SortingField.oldExternalSize, _SortingDirection.descending),
            _createHeaderButton(const ['bytes'], 'Size', _SortingField.oldSize,
                _SortingDirection.descending),
            _createHeaderButton(const ['instances'], 'Instances',
                _SortingField.oldInstances, _SortingDirection.descending),
            _createHeaderButton(const ['bytes'], 'Internal',
                _SortingField.internalSize, _SortingDirection.descending),
            _createHeaderButton(const ['bytes'], 'External',
                _SortingField.externalSize, _SortingDirection.descending),
            _createHeaderButton(const ['bytes'], 'Size', _SortingField.size,
                _SortingDirection.descending),
            _createHeaderButton(const ['instances'], 'Instances',
                _SortingField.instances, _SortingDirection.descending),
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

  void _updateCollectionLine(Element e, itemDynamic, index) {
    M.ClassHeapStats item = itemDynamic;
    e.children[0].text = Utils.formatSize(_getNewInternalSize(item));
    e.children[1].text = Utils.formatSize(_getNewExternalSize(item));
    e.children[2].text = Utils.formatSize(_getNewSize(item));
    e.children[3].text = '${_getNewInstances(item)}';
    e.children[4].text = Utils.formatSize(_getOldInternalSize(item));
    e.children[5].text = Utils.formatSize(_getOldExternalSize(item));
    e.children[6].text = Utils.formatSize(_getOldSize(item));
    e.children[7].text = '${_getOldInstances(item)}';
    e.children[8].text = Utils.formatSize(_getInternalSize(item));
    e.children[9].text = Utils.formatSize(_getExternalSize(item));
    e.children[10].text = Utils.formatSize(_getSize(item));
    e.children[11].text = '${_getInstances(item)}';
    e.children[12] = new ClassRefElement(_isolate, item.clazz, queue: _r.queue)
        .element
      ..classes = ['name'];
  }

  bool _search(Pattern pattern, itemDynamic) {
    M.ClassHeapStats item = itemDynamic;
    return item.clazz.name.contains(pattern);
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
        ..children = <Element>[
          new DivElement()
            ..classes = ['memberName']
            ..text = 'used',
          new DivElement()
            ..classes = ['memberValue']
            ..text = used
        ],
      new DivElement()
        ..classes = ['memberItem']
        ..children = <Element>[
          new DivElement()
            ..classes = ['memberName']
            ..text = 'external',
          new DivElement()
            ..classes = ['memberValue']
            ..text = ext
        ],
      new DivElement()
        ..classes = ['memberItem']
        ..children = <Element>[
          new DivElement()
            ..classes = ['memberName']
            ..text = 'collections',
          new DivElement()
            ..classes = ['memberValue']
            ..text = collections
        ],
      new DivElement()
        ..classes = ['memberItem']
        ..children = <Element>[
          new DivElement()
            ..classes = ['memberName']
            ..text = 'average collection time',
          new DivElement()
            ..classes = ['memberValue']
            ..text = avgCollectionTime
        ],
    ];
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
          '"New Internal"',
          '"New External"',
          '"New Size"',
          '"New Instances"',
          '"Old Internal"',
          '"Old External"',
          '"Old Size"',
          '"Old Instances"',
          '"Internal"',
          '"External"',
          '"Size"',
          '"Instances"',
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
      _getNewInternalSize(s),
      _getNewExternalSize(s),
      _getNewSize(s),
      _getNewInstances(s),
      _getOldInternalSize(s),
      _getOldExternalSize(s),
      _getOldSize(s),
      _getOldInstances(s),
      _getInternalSize(s),
      _getExternalSize(s),
      _getSize(s),
      _getInstances(s),
      s.clazz.name
    ].join(',');
  }

  static int _getNewInstances(M.ClassHeapStats s) => s.newSpace.instances;
  static int _getNewInternalSize(M.ClassHeapStats s) => s.newSpace.internalSize;
  static int _getNewExternalSize(M.ClassHeapStats s) => s.newSpace.externalSize;
  static int _getNewSize(M.ClassHeapStats s) => s.newSpace.size;
  static int _getOldInstances(M.ClassHeapStats s) => s.oldSpace.instances;
  static int _getOldInternalSize(M.ClassHeapStats s) => s.oldSpace.internalSize;
  static int _getOldExternalSize(M.ClassHeapStats s) => s.oldSpace.externalSize;
  static int _getOldSize(M.ClassHeapStats s) => s.oldSpace.size;
  static int _getInstances(M.ClassHeapStats s) =>
      s.newSpace.instances + s.oldSpace.instances;
  static int _getInternalSize(M.ClassHeapStats s) =>
      s.newSpace.internalSize + s.oldSpace.internalSize;
  static int _getExternalSize(M.ClassHeapStats s) =>
      s.newSpace.externalSize + s.oldSpace.externalSize;
  static int _getSize(M.ClassHeapStats s) => s.newSpace.size + s.oldSpace.size;
}
