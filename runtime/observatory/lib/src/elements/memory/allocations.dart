// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This Element is part of MemoryDashboardElement.
///
/// The Element is stripped down version of AllocationProfileElement where
/// concepts like old and new space has been hidden away.
///
/// For each class in the system it is shown the Total number of instances
/// alive, the Total memory used by these instances, the number of instances
/// created since the last reset, the memory used by these instances.
///
/// When a GC event is received the profile is reloaded.

import 'dart:async';
import 'dart:html';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/class_ref.dart';
import 'package:observatory/src/elements/containers/virtual_collection.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/utils.dart';

enum _SortingField {
  accumulatedSize,
  accumulatedInstances,
  currentSize,
  currentInstances,
  className,
}

enum _SortingDirection { ascending, descending }

class MemoryAllocationsElement extends HtmlElement implements Renderable {
  static const tag = const Tag<MemoryAllocationsElement>('memory-allocations',
      dependencies: const [ClassRefElement.tag, VirtualCollectionElement.tag]);

  RenderingScheduler<MemoryAllocationsElement> _r;

  Stream<RenderedEvent<MemoryAllocationsElement>> get onRendered =>
      _r.onRendered;

  M.IsolateRef _isolate;
  M.EventRepository _events;
  M.AllocationProfileRepository _repository;
  M.AllocationProfile _profile;
  M.EditorRepository _editor;
  StreamSubscription _gcSubscription;
  _SortingField _sortingField = _SortingField.accumulatedInstances;
  _SortingDirection _sortingDirection = _SortingDirection.descending;

  M.IsolateRef get isolate => _isolate;

  factory MemoryAllocationsElement(
      M.IsolateRef isolate,
      M.EditorRepository editor,
      M.EventRepository events,
      M.AllocationProfileRepository repository,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(events != null);
    assert(editor != null);
    assert(repository != null);
    MemoryAllocationsElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._editor = editor;
    e._events = events;
    e._repository = repository;
    return e;
  }

  MemoryAllocationsElement.created() : super.created();

  @override
  attached() {
    super.attached();
    _r.enable();
    _refresh();
    _gcSubscription = _events.onGCEvent.listen((e) {
      if (e.isolate.id == _isolate.id) {
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

  Future reload({bool gc = false, bool reset = false}) async {
    return _refresh(gc: gc, reset: reset);
  }

  void render() {
    if (_profile == null) {
      children = [
        new DivElement()
          ..classes = ['content-centered-big']
          ..children = [new HeadingElement.h2()..text = 'Loading...']
      ];
    } else {
      children = [
        new VirtualCollectionElement(
            _createCollectionLine, _updateCollectionLine,
            createHeader: _createCollectionHeader,
            items: _profile.members.toList()..sort(_createSorter()),
            queue: _r.queue)
      ];
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

  static HtmlElement _createCollectionLine() => new DivElement()
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
      new SpanElement()..classes = ['name']
    ];

  List<HtmlElement> _createCollectionHeader() {
    final resetAccumulators = new ButtonElement();
    return [
      new DivElement()
        ..classes = ['collection-item']
        ..children = [
          new SpanElement()
            ..classes = ['group']
            ..children = [
              new Text('Since Last '),
              resetAccumulators
                ..text = 'Reset↺'
                ..title = 'Reset'
                ..onClick.listen((_) async {
                  resetAccumulators.disabled = true;
                  await _refresh(reset: true);
                  resetAccumulators.disabled = false;
                })
            ],
          new SpanElement()
            ..classes = ['group']
            ..text = 'Current'
        ],
      new DivElement()
        ..classes = ['collection-item']
        ..children = [
          _createHeaderButton(const ['bytes'], 'Size',
              _SortingField.accumulatedSize, _SortingDirection.descending),
          _createHeaderButton(const ['instances'], 'Instances',
              _SortingField.accumulatedInstances, _SortingDirection.descending),
          _createHeaderButton(const ['bytes'], 'Size',
              _SortingField.currentSize, _SortingDirection.descending),
          _createHeaderButton(const ['instances'], 'Instances',
              _SortingField.currentInstances, _SortingDirection.descending),
          _createHeaderButton(const ['name'], 'Class', _SortingField.className,
              _SortingDirection.ascending)
        ],
    ];
  }

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
    e.children[4] = new ClassRefElement(_isolate, item.clazz, queue: _r.queue)
      ..classes = ['name'];
    Element.clickEvent.forTarget(e.children[4], useCapture: true).listen((e) {
      if (_editor.isAvailable) {
        e.preventDefault();
        _editor.openClass(isolate, item.clazz);
      }
    });
  }

  Future _refresh({bool gc: false, bool reset: false}) async {
    _profile = null;
    _r.dirty();
    _profile = await _repository.get(_isolate, gc: gc, reset: reset);
    _r.dirty();
  }

  static int _getAccumulatedSize(M.ClassHeapStats s) =>
      s.newSpace.accumulated.bytes + s.oldSpace.accumulated.bytes;
  static int _getAccumulatedInstances(M.ClassHeapStats s) =>
      s.newSpace.accumulated.instances + s.oldSpace.accumulated.instances;
  static int _getCurrentSize(M.ClassHeapStats s) =>
      s.newSpace.current.bytes + s.oldSpace.current.bytes;
  static int _getCurrentInstances(M.ClassHeapStats s) =>
      s.newSpace.current.instances + s.oldSpace.current.instances;
}
