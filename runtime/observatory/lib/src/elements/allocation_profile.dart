// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:web/web.dart';

import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/class_ref.dart';
import 'package:observatory/src/elements/containers/virtual_collection.dart';
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
import 'package:observatory/utils.dart';

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
  late RenderingScheduler<AllocationProfileElement> _r;

  Stream<RenderedEvent<AllocationProfileElement>> get onRendered =>
      _r.onRendered;

  late M.VM _vm;
  late M.IsolateRef _isolate;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  late M.AllocationProfileRepository _repository;
  M.AllocationProfile? _profile;
  bool _autoRefresh = false;
  bool _isCompacted = false;
  late StreamSubscription _gcSubscription;
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
      {RenderingQueue? queue}) {
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
    removeChildren();
    _gcSubscription.cancel();
  }

  void render() {
    children = <HTMLElement>[
      navBar(<HTMLElement>[
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
        new HTMLDivElement()
          ..className = 'nav-option'
          ..appendChildren(<HTMLElement>[
            new HTMLInputElement()
              ..id = 'allocation-profile-auto-refresh'
              ..type = 'checkbox'
              ..checked = _autoRefresh
              ..onChange.listen((_) => _autoRefresh = !_autoRefresh),
            new HTMLLabelElement()
              ..htmlFor = 'allocation-profile-auto-refresh'
              ..textContent = 'Auto-refresh on GC'
          ]),
        new NavNotifyElement(_notifications, queue: _r.queue).element
      ]),
      new HTMLDivElement()
        ..className = 'content-centered-big'
        ..appendChildren(<HTMLElement>[
          new HTMLHeadingElement.h2()..textContent = 'Allocation Profile',
          new HTMLHRElement()
        ])
    ];
    if (_profile == null) {
      appendChild(new HTMLDivElement()
        ..className = 'content-centered-big'
        ..append(new HTMLHeadingElement.h2()..textContent = 'Loading...'));
    } else {
      appendChildren([
        new HTMLDivElement()
          ..className = 'content-centered-big'
          ..appendChildren(_isCompacted
              ? []
              : [
                  new HTMLDivElement()
                    ..className = 'memberList'
                    ..append(
                      new HTMLDivElement()
                        ..className = 'memberItem'
                        ..appendChildren(<HTMLElement>[
                          new HTMLDivElement()
                            ..className = 'memberName'
                            ..textContent = 'last forced GC at',
                          new HTMLDivElement()
                            ..className = 'memberValue'
                            ..textContent = _profile!.lastServiceGC == null
                                ? '---'
                                : '${_profile!.lastServiceGC}'
                        ]),
                    ),
                  new HTMLHRElement(),
                ]),
        new HTMLDivElement()
          ..className = 'content-centered-big compactable'
          ..appendChildren([
            new HTMLDivElement()
              ..className = 'heap-space left'
              ..appendChildren(_isCompacted
                  ? [
                      new HTMLHeadingElement.h2()
                        ..textContent = 'New Generation '
                            '(${_usedCaption(_profile!.newSpace)})',
                    ]
                  : [
                      new HTMLHeadingElement.h2()
                        ..textContent = 'New Generation',
                      new HTMLBRElement(),
                      new HTMLDivElement()
                        ..className = 'memberList'
                        ..appendChildren(
                            _createSpaceMembers(_profile!.newSpace)),
                    ]),
            new HTMLDivElement()
              ..className = 'heap-space left'
              ..appendChildren(_isCompacted
                  ? [
                      new HTMLHeadingElement.h2()
                        ..textContent = 'Old Generation '
                            '(${_usedCaption(_profile!.oldSpace)})',
                    ]
                  : [
                      new HTMLHeadingElement.h2()
                        ..textContent = 'Old Generation',
                      new HTMLBRElement(),
                      new HTMLDivElement()
                        ..className = 'memberList'
                        ..appendChildren(
                            _createSpaceMembers(_profile!.oldSpace)),
                    ]),
            new HTMLDivElement()
              ..className = 'heap-space left'
              ..appendChildren(_isCompacted
                  ? [
                      new HTMLHeadingElement.h2()
                        ..textContent = 'Total '
                            '(${_usedCaption(_profile!.totalSpace)})',
                    ]
                  : [
                      new HTMLHeadingElement.h2()..textContent = 'Total',
                      new HTMLBRElement(),
                      new HTMLDivElement()
                        ..className = 'memberList'
                        ..appendChildren(
                            _createSpaceMembers(_profile!.totalSpace)),
                    ]),
            new HTMLButtonElement()
              ..className = 'compact'
              ..textContent = _isCompacted ? 'expand ▼' : 'compact ▲'
              ..onClick.listen((_) {
                _isCompacted = !_isCompacted;
                _r.dirty();
              }),
            new HTMLHRElement()
          ]),
        new HTMLDivElement()
          ..className = _isCompacted ? 'collection expanded' : 'collection'
          ..appendChild(new VirtualCollectionElement(
                  _createCollectionLine, _updateCollectionLine,
                  createHeader: _createCollectionHeader,
                  search: _search,
                  items: _profile!.members.toList()..sort(_createSorter()),
                  queue: _r.queue)
              .element)
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
        getter = (M.ClassHeapStats s) => s.clazz!.name;
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

  static HTMLElement _createCollectionLine() => new HTMLDivElement()
    ..className = 'collection-item'
    ..appendChildren(<HTMLElement>[
      new HTMLSpanElement()
        ..className = 'bytes'
        ..textContent = '0B',
      new HTMLSpanElement()
        ..className = 'bytes'
        ..textContent = '0B',
      new HTMLSpanElement()
        ..className = 'bytes'
        ..textContent = '0B',
      new HTMLSpanElement()
        ..className = 'instances'
        ..textContent = '0',
      new HTMLSpanElement()
        ..className = 'bytes'
        ..textContent = '0B',
      new HTMLSpanElement()
        ..className = 'bytes'
        ..textContent = '0B',
      new HTMLSpanElement()
        ..className = 'bytes'
        ..textContent = '0B',
      new HTMLSpanElement()
        ..className = 'instances'
        ..textContent = '0',
      new HTMLSpanElement()
        ..className = 'bytes'
        ..textContent = '0B',
      new HTMLSpanElement()
        ..className = 'bytes'
        ..textContent = '0B',
      new HTMLSpanElement()
        ..className = 'bytes'
        ..textContent = '0B',
      new HTMLSpanElement()
        ..className = 'instances'
        ..textContent = '0',
      new HTMLSpanElement()..className = 'name'
    ]);

  List<HTMLElement> _createCollectionHeader() => [
        new HTMLDivElement()
          ..className = 'collection-item'
          ..appendChildren(<HTMLElement>[
            new HTMLSpanElement()
              ..className = 'group'
              ..textContent = 'New Generation',
            new HTMLSpanElement()
              ..className = 'group'
              ..textContent = 'Old Generation',
            new HTMLSpanElement()
              ..className = 'group'
              ..textContent = 'Total',
            new HTMLSpanElement()
              ..className = 'group'
              ..textContent = '',
          ]),
        new HTMLDivElement()
          ..className = 'collection-item'
          ..appendChildren(<Node>[
            _createHeaderButton('bytes', 'Internal',
                _SortingField.newInternalSize, _SortingDirection.descending),
            _createHeaderButton('bytes', 'External',
                _SortingField.newExternalSize, _SortingDirection.descending),
            _createHeaderButton('bytes', 'Size', _SortingField.newSize,
                _SortingDirection.descending),
            _createHeaderButton('instances', 'Instances',
                _SortingField.newInstances, _SortingDirection.descending),
            _createHeaderButton('bytes', 'Internal',
                _SortingField.oldInternalSize, _SortingDirection.descending),
            _createHeaderButton('bytes', 'External',
                _SortingField.oldExternalSize, _SortingDirection.descending),
            _createHeaderButton('bytes', 'Size', _SortingField.oldSize,
                _SortingDirection.descending),
            _createHeaderButton('instances', 'Instances',
                _SortingField.oldInstances, _SortingDirection.descending),
            _createHeaderButton('bytes', 'Internal', _SortingField.internalSize,
                _SortingDirection.descending),
            _createHeaderButton('bytes', 'External', _SortingField.externalSize,
                _SortingDirection.descending),
            _createHeaderButton('bytes', 'Size', _SortingField.size,
                _SortingDirection.descending),
            _createHeaderButton('instances', 'Instances',
                _SortingField.instances, _SortingDirection.descending),
            _createHeaderButton('name', 'Class', _SortingField.className,
                _SortingDirection.ascending)
          ])
      ];

  HTMLButtonElement _createHeaderButton(String className, String text,
          _SortingField field, _SortingDirection direction) =>
      new HTMLButtonElement()
        ..className = className
        ..textContent = _sortingField != field
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

  void _updateCollectionLine(HTMLElement e, itemDynamic, index) {
    M.ClassHeapStats item = itemDynamic;
    e.childNodes.item(0)!.textContent =
        Utils.formatSize(_getNewInternalSize(item));
    e.childNodes.item(1)!.textContent =
        Utils.formatSize(_getNewExternalSize(item));
    e.childNodes.item(2)!.textContent = Utils.formatSize(_getNewSize(item));
    e.childNodes.item(3)!.textContent = '${_getNewInstances(item)}';
    e.childNodes.item(4)!.textContent =
        Utils.formatSize(_getOldInternalSize(item));
    e.childNodes.item(5)!.textContent =
        Utils.formatSize(_getOldExternalSize(item));
    e.childNodes.item(6)!.textContent = Utils.formatSize(_getOldSize(item));
    e.childNodes.item(7)!.textContent = '${_getOldInstances(item)}';
    e.childNodes.item(8)!.textContent =
        Utils.formatSize(_getInternalSize(item));
    e.childNodes.item(9)!.textContent =
        Utils.formatSize(_getExternalSize(item));
    e.childNodes.item(10)!.textContent = Utils.formatSize(_getSize(item));
    e.childNodes.item(11)!.textContent = '${_getInstances(item)}';
    final old = e.childNodes.item(12)!;
    e.insertBefore(
        old,
        e.appendChild(
            (new ClassRefElement(_isolate, item.clazz!, queue: _r.queue).element
              ..className = 'name')));
    e.removeChild(old);
  }

  bool _search(Pattern pattern, itemDynamic) {
    M.ClassHeapStats item = itemDynamic;
    return item.clazz!.name!.contains(pattern);
  }

  static String _usedCaption(M.HeapSpace space) =>
      '${Utils.formatSize(space.used)}'
      ' of '
      '${Utils.formatSize(space.capacity)}';

  static List<HTMLElement> _createSpaceMembers(M.HeapSpace space) {
    final used = _usedCaption(space);
    final ext = '${Utils.formatSize(space.external)}';
    final collections = '${space.collections}';
    final avgCollectionTime =
        '${Utils.formatDurationInMilliseconds(space.avgCollectionTime)} ms';
    return [
      new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'used',
          new HTMLDivElement()
            ..className = 'memberValue'
            ..textContent = used
        ]),
      new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'external',
          new HTMLDivElement()
            ..className = 'memberValue'
            ..textContent = ext
        ]),
      new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'collections',
          new HTMLDivElement()
            ..className = 'memberValue'
            ..textContent = collections
        ]),
      new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'average collection time',
          new HTMLDivElement()
            ..className = 'memberValue'
            ..textContent = avgCollectionTime
        ]),
    ];
  }

  Future _refresh({bool gc = false, bool reset = false}) async {
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
    HTMLAnchorElement tl = document.createElement('a') as HTMLAnchorElement;
    tl
      ..attributes.setNamedItem(document.createAttribute('href')
        ..value = 'data:text/plain;charset=utf-8,' +
            Uri.encodeComponent(header +
                (_profile!.members.toList()..sort(_createSorter()))
                    .map(_csvOut)
                    .join('\n')))
      ..attributes.setNamedItem(
          document.createAttribute('download')..value = 'heap-profile.csv')
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
      s.clazz!.name
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
