// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library persitent_handles_page;

import 'dart:async';
import 'dart:html';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/containers/virtual_collection.dart';
import 'package:observatory/src/elements/helpers/any_ref.dart';
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/instance_ref.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/utils.dart';

enum _SortingField { externalSize, peer, finalizerCallback }

enum _SortingDirection { ascending, descending }

class PersistentHandlesPageElement extends HtmlElement implements Renderable {
  static const tag = const Tag<PersistentHandlesPageElement>(
      'persistent-handles-page',
      dependencies: const [
        InstanceRefElement.tag,
        NavTopMenuElement.tag,
        NavVMMenuElement.tag,
        NavIsolateMenuElement.tag,
        NavRefreshElement.tag,
        NavNotifyElement.tag,
        VirtualCollectionElement.tag
      ]);

  RenderingScheduler<PersistentHandlesPageElement> _r;

  Stream<RenderedEvent<PersistentHandlesPageElement>> get onRendered =>
      _r.onRendered;

  M.VM _vm;
  M.IsolateRef _isolate;
  M.EventRepository _events;
  M.NotificationRepository _notifications;
  M.PersistentHandlesRepository _repository;
  M.ObjectRepository _objects;
  M.PersistentHandles _handles;
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
      M.ObjectRepository objects,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(isolate != null);
    assert(events != null);
    assert(notifications != null);
    assert(repository != null);
    assert(objects != null);
    PersistentHandlesPageElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._repository = repository;
    e._objects = objects;
    return e;
  }

  PersistentHandlesPageElement.created() : super.created();

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
    children = [];
  }

  void render() {
    children = [
      navBar([
        new NavTopMenuElement(queue: _r.queue),
        new NavVMMenuElement(_vm, _events, queue: _r.queue),
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue),
        navMenu('persistent handles'),
        new NavRefreshElement(queue: _r.queue)
          ..onRefresh.listen((_) => _refresh()),
        new NavNotifyElement(_notifications, queue: _r.queue)
      ])
    ]
      ..addAll(_createHandlers('Persistent Handles',
          _handles?.elements?.toList(), _createLine, _updateLine))
      ..add(new BRElement())
      ..addAll(_createHandlers(
          'Weak Persistent Handles',
          _handles == null
              ? null
              : (_handles.weakElements.toList()..sort(_createSorter())),
          _createWeakLine,
          _updateWeakLine,
          createHeader: _createWeakHeader));
  }

  List<Element> _createHandlers(String name, List items, create, update,
      {createHeader}) {
    return [
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = [
          new HeadingElement.h1()
            ..text = items == null ? '$name' : '$name (${items.length})',
          new HRElement(),
        ],
      new DivElement()
        ..classes = ['persistent-handles']
        ..children = [
          items == null
              ? (new HeadingElement.h2()
                ..classes = ['content-centered-big']
                ..text = 'Loading...')
              : new VirtualCollectionElement(create, update,
                  items: items, createHeader: createHeader, queue: _r.queue)
        ]
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
        return (a, b) => getter(a).compareTo(getter(b));
      case _SortingDirection.descending:
        return (a, b) => getter(b).compareTo(getter(a));
    }
  }

  static Element _createLine() => new DivElement()
    ..classes = ['collection-item']
    ..text = 'object';

  static Element _createWeakLine() => new DivElement()
    ..classes = ['weak-item']
    ..children = [
      new SpanElement()
        ..classes = ['external-size']
        ..text = '0B',
      new SpanElement()
        ..classes = ['peer']
        ..text = '0x00000',
      new SpanElement()..classes = ['object'],
      new SpanElement()
        ..classes = ['finalizer']
        ..text = 'dart::Class::Method()'
    ];

  List<HtmlElement> _createWeakHeader() => [
        new DivElement()
          ..classes = ['weak-item']
          ..children = [
            _createHeaderButton(const ['external-size'], 'External Size',
                _SortingField.externalSize, _SortingDirection.descending),
            _createHeaderButton(const ['peer'], 'Peer', _SortingField.peer,
                _SortingDirection.descending),
            new SpanElement()
              ..classes = ['object']
              ..text = 'Object',
            _createHeaderButton(const ['finalizer'], 'Finalizer Callback',
                _SortingField.finalizerCallback, _SortingDirection.ascending)
          ]
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

  void _updateWeakLine(Element e, M.WeakPersistentHandle item, index) {
    e.children[0].text = Utils.formatSize(_getExternalSize(item));
    e.children[1].text = '${_getPeer(item)}';
    e.children[2] = anyRef(_isolate, item.object, _objects, queue: _r.queue)
      ..classes = ['object'];
    e.children[3]
      ..text = '${_getFinalizerCallback(item)}'
      ..title = '${_getFinalizerCallback(item)}';
  }

  void _updateLine(Element e, M.PersistentHandle item, index) {
    e.children = [
      anyRef(_isolate, item.object, _objects, queue: _r.queue)
        ..classes = ['object']
    ];
  }

  Future _refresh({bool gc: false, bool reset: false}) async {
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
