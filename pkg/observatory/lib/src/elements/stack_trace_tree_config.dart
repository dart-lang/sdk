// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:web/web.dart';

import '../../models.dart' as M;
import 'helpers/custom_element.dart';
import 'helpers/element_utils.dart';
import 'helpers/rendering_scheduler.dart';

enum ProfileTreeMode { code, function }

class StackTraceTreeConfigChangedEvent {
  final StackTraceTreeConfigElement element;
  StackTraceTreeConfigChangedEvent(this.element);
}

class StackTraceTreeConfigElement extends CustomElement implements Renderable {
  late RenderingScheduler<StackTraceTreeConfigElement> _r;

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

  late bool _showMode;
  late bool _showDirection;
  late bool _showFilter;
  late ProfileTreeMode _mode;
  late M.ProfileTreeDirection _direction;
  late String _filter;

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

  factory StackTraceTreeConfigElement({
    bool showMode = true,
    bool showDirection = true,
    bool showFilter = true,
    String filter = '',
    ProfileTreeMode mode = ProfileTreeMode.function,
    M.ProfileTreeDirection direction = M.ProfileTreeDirection.exclusive,
    RenderingQueue? queue,
  }) {
    StackTraceTreeConfigElement e = new StackTraceTreeConfigElement.created();
    e._r = new RenderingScheduler<StackTraceTreeConfigElement>(e, queue: queue);
    e._showMode = showMode;
    e._showDirection = showDirection;
    e._showFilter = showFilter;
    e._mode = mode;
    e._direction = direction;
    e._filter = filter;
    return e;
  }

  StackTraceTreeConfigElement.created()
    : super.created('stack-trace-tree-config');

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
    children = <HTMLElement>[
      new HTMLDivElement()
        ..className = 'content-centered-big'
        ..appendChildren(<HTMLElement>[
          new HTMLHeadingElement.h2()..textContent = 'Tree display',
          new HTMLHRElement(),
          new HTMLDivElement()
            ..className = 'row'
            ..appendChildren(<HTMLElement>[
              new HTMLDivElement()
                ..className = 'memberList'
                ..appendChildren(_createMembers()),
            ]),
        ]),
    ];
  }

  List<HTMLElement> _createMembers() {
    var members = <HTMLElement>[];
    if (_showMode) {
      members.add(
        new HTMLDivElement()
          ..className = 'memberItem'
          ..appendChildren(<HTMLElement>[
            new HTMLDivElement()
              ..className = 'memberName'
              ..textContent = 'Mode',
            new HTMLDivElement()
              ..className = 'memberValue'
              ..appendChildren(_createModeSelect()),
          ]),
      );
    }
    if (_showDirection) {
      members.add(
        new HTMLDivElement()
          ..className = 'memberItem'
          ..appendChildren(<HTMLElement>[
            new HTMLDivElement()
              ..className = 'memberName'
              ..textContent = 'Call Tree Direction',
            new HTMLSpanElement()
              ..className = 'memberValue'
              ..appendChildren(_createDirectionSelect()),
          ]),
      );
    }
    if (showFilter) {
      members.add(
        new HTMLDivElement()
          ..className = 'memberItem'
          ..appendChildren(<HTMLElement>[
            new HTMLDivElement()
              ..className = 'memberName'
              ..textContent = 'Call Tree Filter'
              ..title = 'case-sensitive substring match',
            new HTMLSpanElement()
              ..className = 'memberValue'
              ..appendChildren(_createFilter()),
          ]),
      );
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

  List<HTMLElement> _createModeSelect() {
    final s = HTMLSelectElement()
      ..className = 'mode-select'
      ..value = modeToString(_mode)
      ..appendChildren(
        ProfileTreeMode.values.map(
          (mode) => HTMLOptionElement()
            ..value = modeToString(mode)
            ..selected = _mode == mode
            ..text = modeToString(mode),
        ),
      );
    return [
      s
        ..onChange.listen((_) {
          _mode = ProfileTreeMode.values[s.selectedIndex];
          _r.dirty();
        })
        ..onChange.map(_toEvent).listen(_triggerModeChange),
      HTMLSpanElement()..textContent = ' $modeDescription',
    ];
  }

  String get directionDescription {
    if (_direction == M.ProfileTreeDirection.inclusive) {
      return 'Tree is rooted at "main". Child nodes are callees.';
    } else {
      return 'Tree is rooted at top-of-stack. Child nodes are callers.';
    }
  }

  List<HTMLElement> _createDirectionSelect() {
    final s = HTMLSelectElement()
      ..className = 'direction-select'
      ..value = directionToString(_direction)
      ..appendChildren(
        M.ProfileTreeDirection.values.map((direction) {
          return HTMLOptionElement()
            ..value = directionToString(direction)
            ..selected = _direction == direction
            ..text = directionToString(direction);
        }),
      );
    return [
      s
        ..onChange.listen((_) {
          _direction = M.ProfileTreeDirection.values[s.selectedIndex];
          _r.dirty();
        })
        ..onChange.map(_toEvent).listen(_triggerDirectionChange),
      new HTMLSpanElement()..textContent = ' $directionDescription',
    ];
  }

  List<HTMLElement> _createFilter() {
    var t;
    return [
      t = new HTMLInputElement()
        ..placeholder = 'Search filter'
        ..value = filter
        ..onChange.listen((_) {
          _filter = t.value;
        })
        ..onChange.map(_toEvent).listen(_triggerFilterChange),
    ];
  }

  static String modeToString(ProfileTreeMode mode) {
    switch (mode) {
      case ProfileTreeMode.code:
        return 'Code';
      case ProfileTreeMode.function:
        return 'Function';
    }
  }

  static String directionToString(M.ProfileTreeDirection direction) {
    switch (direction) {
      case M.ProfileTreeDirection.inclusive:
        return 'Top down';
      case M.ProfileTreeDirection.exclusive:
        return 'Bottom up';
    }
  }

  StackTraceTreeConfigChangedEvent _toEvent(_) {
    return new StackTraceTreeConfigChangedEvent(this);
  }

  void _triggerModeChange(e) => _onModeChange.add(e);
  void _triggerDirectionChange(e) => _onDirectionChange.add(e);
  void _triggerFilterChange(e) => _onFilterChange.add(e);
}
