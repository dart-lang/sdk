// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';

enum ProfileTreeMode {
  code,
  function,
}

class StackTraceTreeConfigChangedEvent {
  final StackTraceTreeConfigElement element;
  StackTraceTreeConfigChangedEvent(this.element);
}

class StackTraceTreeConfigElement extends HtmlElement implements Renderable {
  static const tag =
      const Tag<StackTraceTreeConfigElement>('stack-trace-tree-config');

  RenderingScheduler<StackTraceTreeConfigElement> _r;

  Stream<RenderedEvent<StackTraceTreeConfigElement>> get onRendered =>
      _r.onRendered;

  StreamController<StackTraceTreeConfigChangedEvent> _onModeChange =
      new StreamController<StackTraceTreeConfigChangedEvent>.broadcast();
  StreamController<StackTraceTreeConfigChangedEvent> _onDirectionChange =
      new StreamController<StackTraceTreeConfigChangedEvent>.broadcast();
  StreamController<StackTraceTreeConfigChangedEvent> _onFilterChange =
      new StreamController<StackTraceTreeConfigChangedEvent>.broadcast();
  Stream<StackTraceTreeConfigChangedEvent> get onModeChange =>
      _onModeChange.stream;
  Stream<StackTraceTreeConfigChangedEvent> get onDirectionChange =>
      _onDirectionChange.stream;
  Stream<StackTraceTreeConfigChangedEvent> get onFilterChange =>
      _onFilterChange.stream;

  bool _showMode;
  bool _showDirection;
  bool _showFilter;
  ProfileTreeMode _mode;
  M.ProfileTreeDirection _direction;
  String _filter;

  bool get showMode => _showMode;
  bool get showDirection => _showDirection;
  bool get showFilter => _showFilter;
  ProfileTreeMode get mode => _mode;
  M.ProfileTreeDirection get direction => _direction;
  String get filter => _filter;

  set showMode(bool value) => _showMode = _r.checkAndReact(_showMode, value);
  set showDirection(bool value) =>
      _showDirection = _r.checkAndReact(_showDirection, value);
  set showFilter(bool value) =>
      _showFilter = _r.checkAndReact(_showFilter, value);
  set mode(ProfileTreeMode value) => _mode = _r.checkAndReact(_mode, value);
  set direction(M.ProfileTreeDirection value) =>
      _direction = _r.checkAndReact(_direction, value);
  set filter(String value) => _filter = _r.checkAndReact(_filter, value);

  factory StackTraceTreeConfigElement(
      {bool showMode: true,
      bool showDirection: true,
      bool showFilter: true,
      String filter: '',
      ProfileTreeMode mode: ProfileTreeMode.function,
      M.ProfileTreeDirection direction: M.ProfileTreeDirection.exclusive,
      RenderingQueue queue}) {
    assert(showMode != null);
    assert(showDirection != null);
    assert(showFilter != null);
    assert(mode != null);
    assert(direction != null);
    assert(filter != null);
    StackTraceTreeConfigElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._showMode = showMode;
    e._showDirection = showDirection;
    e._showFilter = showFilter;
    e._mode = mode;
    e._direction = direction;
    e._filter = filter;
    return e;
  }

  StackTraceTreeConfigElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    _r.disable(notify: true);
    children = const [];
  }

  void render() {
    children = [
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = [
          new HeadingElement.h2()..text = 'Tree display',
          new HRElement(),
          new DivElement()
            ..classes = ['row']
            ..children = [
              new DivElement()
                ..classes = ['memberList']
                ..children = _createMembers()
            ]
        ]
    ];
  }

  List<Element> _createMembers() {
    var members = <Element>[];
    if (_showMode) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'Mode',
          new DivElement()
            ..classes = ['memberValue']
            ..children = _createModeSelect()
        ]);
    }
    if (_showDirection) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'Call Tree Direction',
          new SpanElement()
            ..classes = ['memberValue']
            ..children = _createDirectionSelect()
        ]);
    }
    if (showFilter) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'Call Tree Filter'
            ..title = 'case-sensitive substring match',
          new SpanElement()
            ..classes = ['memberValue']
            ..children = _createFilter()
        ]);
    }
    return members;
  }

  String get modeDescription {
    if (_mode == ProfileTreeMode.function) {
      return 'Inlined frames expanded.';
    } else {
      return 'Inlined frames not expanded.';
    }
  }

  List<Element> _createModeSelect() {
    var s;
    return [
      s = new SelectElement()
        ..classes = ['mode-select']
        ..value = modeToString(_mode)
        ..children = ProfileTreeMode.values.map((mode) {
          return new OptionElement(
              value: modeToString(mode), selected: _mode == mode)
            ..text = modeToString(mode);
        }).toList(growable: false)
        ..onChange.listen((_) {
          _mode = ProfileTreeMode.values[s.selectedIndex];
          _r.dirty();
        })
        ..onChange.map(_toEvent).listen(_triggerModeChange),
      new SpanElement()..text = ' $modeDescription'
    ];
  }

  String get directionDescription {
    if (_direction == M.ProfileTreeDirection.inclusive) {
      return 'Tree is rooted at "main". Child nodes are callees.';
    } else {
      return 'Tree is rooted at top-of-stack. Child nodes are callers.';
    }
  }

  List<Element> _createDirectionSelect() {
    var s;
    return [
      s = new SelectElement()
        ..classes = ['direction-select']
        ..value = directionToString(_direction)
        ..children = M.ProfileTreeDirection.values.map((direction) {
          return new OptionElement(
              value: directionToString(direction),
              selected: _direction == direction)
            ..text = directionToString(direction);
        }).toList(growable: false)
        ..onChange.listen((_) {
          _direction = M.ProfileTreeDirection.values[s.selectedIndex];
          _r.dirty();
        })
        ..onChange.map(_toEvent).listen(_triggerDirectionChange),
      new SpanElement()..text = ' $directionDescription'
    ];
  }

  List<Element> _createFilter() {
    var t;
    return [
      t = new TextInputElement()
        ..placeholder = 'Search filter'
        ..value = filter
        ..onChange.listen((_) {
          _filter = t.value;
        })
        ..onChange.map(_toEvent).listen(_triggerFilterChange)
    ];
  }

  static String modeToString(ProfileTreeMode mode) {
    switch (mode) {
      case ProfileTreeMode.code:
        return 'Code';
      case ProfileTreeMode.function:
        return 'Function';
    }
    throw new Exception('Unknown ProfileTreeMode');
  }

  static String directionToString(M.ProfileTreeDirection direction) {
    switch (direction) {
      case M.ProfileTreeDirection.inclusive:
        return 'Top down';
      case M.ProfileTreeDirection.exclusive:
        return 'Bottom up';
    }
    throw new Exception('Unknown ProfileTreeDirection');
  }

  StackTraceTreeConfigChangedEvent _toEvent(_) {
    return new StackTraceTreeConfigChangedEvent(this);
  }

  void _triggerModeChange(e) => _onModeChange.add(e);
  void _triggerDirectionChange(e) => _onDirectionChange.add(e);
  void _triggerFilterChange(e) => _onFilterChange.add(e);
}
