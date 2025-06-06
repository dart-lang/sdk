// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:web/web.dart';

import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/element_utils.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';

class SearchResultSelected {
  final SearchBarElement element;
  final dynamic item;
  SearchResultSelected(this.element, this.item);
}

typedef Iterable<dynamic> SearchBarSearchCallback(Pattern pattern);

class SearchBarElement extends CustomElement implements Renderable {
  late RenderingScheduler<SearchBarElement> _r;

  StreamController<SearchResultSelected> _onSearchResultSelected =
      new StreamController<SearchResultSelected>.broadcast();

  Stream<RenderedEvent<SearchBarElement>> get onRendered => _r.onRendered;
  Stream<SearchResultSelected> get onSearchResultSelected =>
      _onSearchResultSelected.stream;

  late StreamSubscription _onKeyDownSubscription;

  HTMLElement? _workspace;
  late SearchBarSearchCallback _search;
  late bool _isOpen;
  bool _focusRequested = false;
  String _lastValue = '';
  List _results = const [];
  int _current = 0;

  bool get isOpen => _isOpen;
  dynamic get current => _results.isNotEmpty ? _results[_current] : null;

  set isOpen(bool value) {
    if (!value) {
      _input!.value = '';
      _lastValue = '';
      if (_results.isNotEmpty) {
        _results = const [];
        _current = 0;
        _triggerSearchResultSelected();
      }
    }
    _isOpen = _r.checkAndReact(_isOpen, value);
  }

  factory SearchBarElement(SearchBarSearchCallback search,
      {bool isOpen = false, HTMLElement? workspace, RenderingQueue? queue}) {
    SearchBarElement e = new SearchBarElement.created();
    e._r = new RenderingScheduler<SearchBarElement>(e, queue: queue);
    e._search = search;
    e._isOpen = isOpen;
    e._workspace = workspace;
    return e;
  }

  SearchBarElement.created() : super.created('search-bar');

  @override
  attached() {
    super.attached();
    _r.enable();
    _workspace?.tabIndex = 1;
//    _onKeyDownSubscription = (_workspace ?? window).onKeyDown.listen((e) {
    _onKeyDownSubscription = window.onKeyDown.listen((e) {
      if (e.key.toLowerCase() == 'f' &&
          !e.shiftKey &&
          !e.altKey &&
          e.ctrlKey != e.metaKey) {
        if (e.metaKey == window.navigator.platform.startsWith('Mac')) {
          e.stopPropagation();
          e.preventDefault();
          isOpen = true;
          _focusRequested = true;
          _r.dirty();
        }
      }
    });
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    _onKeyDownSubscription.cancel();
  }

  HTMLInputElement? _input;
  HTMLSpanElement? _resultsArea;

  void render() {
    if (_input == null) {
      _input = new HTMLInputElement()
        ..onKeyPress.listen((e) {
          if (e.keyCode == KeyCode.ENTER) {
            if (_input!.value == '') {
              _lastValue = '';
              if (_results.isNotEmpty) {
                _results = const [];
                _current = 0;
                _triggerSearchResultSelected();
                _r.dirty();
              }
            } else if (_input!.value != _lastValue) {
              _lastValue = _input!.value;
              _results = _doSearch(_input!.value);
              _current = 0;
              _triggerSearchResultSelected();
              _r.dirty();
            } else {
              if (e.shiftKey) {
                _prev();
              } else {
                _next();
              }
            }
          }
        });
      _resultsArea = new HTMLSpanElement();
      children = <HTMLElement>[
        _input!,
        _resultsArea!,
        new HTMLButtonElement()
          ..textContent = '❌'
          ..onClick.listen((_) {
            isOpen = false;
          })
      ];
    }
    _resultsArea!.appendChildren(<HTMLElement>[
      new HTMLButtonElement()
        ..textContent = '▲'
        ..disabled = _results.isEmpty
        ..onClick.listen((_) => _prev()),
      new HTMLSpanElement()
        ..textContent =
            '${math.min(_current + 1, _results.length)} / ${_results.length}',
      new HTMLButtonElement()
        ..textContent = '▼'
        ..disabled = _results.isEmpty
        ..onClick.listen((_) => _next())
    ]);
    style.visibility = isOpen ? '' : 'collapse';
    if (_focusRequested) {
      _input!.focus();
      _focusRequested = false;
    }
  }

  void update() {
    if (!isOpen || _lastValue == '') {
      return;
    }
    final item = current;
    _results = _doSearch(_lastValue);
    _current = math.max(0, _results.indexOf(item));
    _r.dirty();
  }

  List<dynamic> _doSearch(String value) =>
      _search(new _CaseInsensitivePatternString(value)).toList(growable: false);

  void _prev() {
    if (_results.isEmpty) {
      return;
    }
    _current = (_current + _results.length - 1) % _results.length;
    _triggerSearchResultSelected();
    _r.dirty();
  }

  void _next() {
    if (_results.isEmpty) {
      return;
    }
    _current = (_current + 1) % _results.length;
    _triggerSearchResultSelected();
    _r.dirty();
  }

  void _triggerSearchResultSelected() {
    _onSearchResultSelected.add(new SearchResultSelected(this, current));
  }
}

class _CaseInsensitivePatternString implements Pattern {
  final String _pattern;

  _CaseInsensitivePatternString(String pattern)
      : this._pattern = pattern.toLowerCase();

  Iterable<Match> allMatches(String string, [int start = 0]) =>
      _pattern.allMatches(string.toLowerCase(), start);

  Match? matchAsPrefix(String string, [int start = 0]) =>
      _pattern.matchAsPrefix(string.toLowerCase(), start);
}
