// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library persistent_handles_page;

import 'dart:async';

import 'package:web/web.dart';

import '../../models.dart' as M;
import 'containers/virtual_collection.dart';
import 'helpers/any_ref.dart';
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
import '../../utils.dart';

enum _SortingField { externalSize, peer, finalizerCallback }

enum _SortingDirection { ascending, descending }

class PersistentHandlesPageElement extends CustomElement implements Renderable {
  late RenderingScheduler<PersistentHandlesPageElement> _r;

  Stream<RenderedEvent<PersistentHandlesPageElement>> get onRendered =>
      _r.onRendered;

  late M.VM _vm;
  late M.IsolateRef _isolate;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  late M.PersistentHandlesRepository _repository;
  late M.ObjectRepository _objects;
  M.PersistentHandles? _handles;
  _SortingField _sortingField = _SortingField.externalSize;
  _SortingDirection _sortingDirection = _SortingDirection.descending;

  M.VMRef get vm => _vm;
  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;

  factory PersistentHandlesPageElement(
    M.VM vm,
    M.IsolateRef isolate,
    M.EventRepository events,
    M.NotificationRepository notifications,
    M.PersistentHandlesRepository repository,
    M.ObjectRepository objects, {
    RenderingQueue? queue,
  }) {
    PersistentHandlesPageElement e = new PersistentHandlesPageElement.created();
    e._r = new RenderingScheduler<PersistentHandlesPageElement>(
      e,
      queue: queue,
    );
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._repository = repository;
    e._objects = objects;
    return e;
  }

  PersistentHandlesPageElement.created()
    : super.created('persistent-handles-page');

  @override
  attached() {
    super.attached();
    _r.enable();
    _refresh();
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    removeChildren();
  }

  void render() {
    children =
        <HTMLElement>[
            navBar(<HTMLElement>[
              new NavTopMenuElement(queue: _r.queue).element,
              new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
              new NavIsolateMenuElement(
                _isolate,
                _events,
                queue: _r.queue,
              ).element,
              navMenu('persistent handles'),
              (new NavRefreshElement(
                queue: _r.queue,
              )..onRefresh.listen((_) => _refresh())).element,
              new NavNotifyElement(_notifications, queue: _r.queue).element,
            ]),
          ]
          ..addAll(
            _createHandlers(
              'Persistent Handles',
              _handles?.elements.toList(),
              _createLine,
              _updateLine,
            ),
          )
          ..add(new HTMLBRElement())
          ..addAll(
            _createHandlers(
              'Weak Persistent Handles',
              _handles == null
                  ? null
                  : (_handles!.weakElements.toList()..sort(_createSorter())),
              _createWeakLine,
              _updateWeakLine,
              createHeader: _createWeakHeader,
            ),
          );
  }

  List<HTMLElement> _createHandlers(
    String name,
    List? items,
    create,
    update, {
    createHeader,
  }) {
    return [
      new HTMLDivElement()
        ..className = 'content-centered-big'
        ..appendChildren(<HTMLElement>[
          new HTMLHeadingElement.h1()
            ..textContent = items == null ? '$name' : '$name (${items.length})',
          new HTMLHRElement(),
        ]),
      new HTMLDivElement()
        ..className = 'persistent-handles'
        ..appendChildren(<HTMLElement>[
          items == null
              ? (new HTMLHeadingElement.h2()
                  ..className = 'content-centered-big'
                  ..textContent = 'Loading...')
              : new VirtualCollectionElement(
                  create,
                  update,
                  items: items,
                  createHeader: createHeader,
                  queue: _r.queue,
                ).element,
        ]),
    ];
  }

  _createSorter() {
    var getter;
    switch (_sortingField) {
      case _SortingField.externalSize:
        getter = _getExternalSize;
        break;
      case _SortingField.peer:
        getter = _getPeer;
        break;
      case _SortingField.finalizerCallback:
        getter = _getFinalizerCallback;
        break;
    }
    switch (_sortingDirection) {
      case _SortingDirection.ascending:
        int sort(M.WeakPersistentHandle a, M.WeakPersistentHandle b) {
          return getter(a).compareTo(getter(b));
        }
        return sort;
      case _SortingDirection.descending:
        int sort(M.WeakPersistentHandle a, M.WeakPersistentHandle b) {
          return getter(b).compareTo(getter(a));
        }
        return sort;
    }
  }

  static HTMLElement _createLine() => new HTMLDivElement()
    ..className = 'collection-item'
    ..textContent = 'object';

  static HTMLElement _createWeakLine() => new HTMLDivElement()
    ..className = 'weak-item'
    ..appendChildren(<HTMLElement>[
      new HTMLSpanElement()
        ..className = 'external-size'
        ..textContent = '0B',
      new HTMLSpanElement()
        ..className = 'peer'
        ..textContent = '0x00000',
      new HTMLSpanElement()..className = 'object',
      new HTMLSpanElement()
        ..className = 'finalizer'
        ..textContent = 'dart::Class::Method()',
    ]);

  List<HTMLElement> _createWeakHeader() => [
    new HTMLDivElement()
      ..className = 'weak-item'
      ..appendChildren(<HTMLElement>[
        _createHeaderButton(
          'external-size',
          'External Size',
          _SortingField.externalSize,
          _SortingDirection.descending,
        ),
        _createHeaderButton(
          'peer',
          'Peer',
          _SortingField.peer,
          _SortingDirection.descending,
        ),
        new HTMLSpanElement()
          ..className = 'object'
          ..textContent = 'Object',
        _createHeaderButton(
          'finalizer',
          'Finalizer Callback',
          _SortingField.finalizerCallback,
          _SortingDirection.ascending,
        ),
      ]),
  ];

  HTMLButtonElement _createHeaderButton(
    String className,
    String text,
    _SortingField field,
    _SortingDirection direction,
  ) => new HTMLButtonElement()
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

  void _updateWeakLine(HTMLElement e, itemDynamic, index) {
    M.WeakPersistentHandle item = itemDynamic;
    (e.children.item(0) as HTMLElement).textContent = Utils.formatSize(
      _getExternalSize(item),
    );
    (e.children.item(1) as HTMLElement).textContent = '${_getPeer(item)}';

    final old = e.childNodes.item(2)!;
    e.insertBefore(
      old,
      e.appendChild(
        anyRef(_isolate, item.object, _objects, queue: _r.queue)
          ..className = 'object',
      ),
    );
    e.removeChild(old);
    (e.children.item(3) as HTMLElement)
      ..textContent = '${_getFinalizerCallback(item)}'
      ..title = '${_getFinalizerCallback(item)}';
  }

  void _updateLine(HTMLElement e, itemDynamic, index) {
    M.PersistentHandle item = itemDynamic;
    e.setChildren(<HTMLElement>[
      anyRef(_isolate, item.object, _objects, queue: _r.queue)
        ..className = 'object',
    ]);
  }

  Future _refresh() async {
    _handles = null;
    _r.dirty();
    _handles = await _repository.get(_isolate);
    _r.dirty();
  }

  static int _getExternalSize(M.WeakPersistentHandle h) => h.externalSize;
  static String _getPeer(M.WeakPersistentHandle h) => h.peer;
  static String _getFinalizerCallback(M.WeakPersistentHandle h) =>
      '${h.callbackSymbolName} (${h.callbackAddress})';
}
