// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library curly_block_element;

import 'dart:async';

import 'package:web/web.dart';

import 'helpers/custom_element.dart';
import 'helpers/rendering_scheduler.dart';

class CurlyBlockToggleEvent {
  final CurlyBlockElement control;

  CurlyBlockToggleEvent(this.control);
}

class CurlyBlockElement extends CustomElement implements Renderable {
  late RenderingScheduler<CurlyBlockElement> _r;

  final StreamController<CurlyBlockToggleEvent> _onToggle =
      new StreamController<CurlyBlockToggleEvent>.broadcast();
  Stream<CurlyBlockToggleEvent> get onToggle => _onToggle.stream;
  Stream<RenderedEvent<CurlyBlockElement>> get onRendered => _r.onRendered;

  late bool _expanded;
  late bool _disabled;
  Iterable<HTMLElement> _content = const [];

  bool get expanded => _expanded;
  bool get disabled => _disabled;
  Iterable<HTMLElement> get content => _content;

  set expanded(bool value) {
    if (_expanded != value) _onToggle.add(new CurlyBlockToggleEvent(this));
    _expanded = _r.checkAndReact(_expanded, value);
  }

  set disabled(bool value) => _disabled = _r.checkAndReact(_disabled, value);
  set content(Iterable<HTMLElement> value) {
    _content = value.toList();
    _r.dirty();
  }

  factory CurlyBlockElement({
    bool expanded = false,
    bool disabled = false,
    RenderingQueue? queue,
  }) {
    CurlyBlockElement e = new CurlyBlockElement.created();
    e._r = new RenderingScheduler<CurlyBlockElement>(e, queue: queue);
    e._expanded = expanded;
    e._disabled = disabled;
    return e;
  }

  CurlyBlockElement.created() : super.created('curly-block');

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    _r.disable(notify: true);
    removeChildren();
  }

  void toggle() {
    if (disabled) {
      _r.scheduleNotification();
      return;
    }
    expanded = !expanded;
  }

  void render() {
    List<HTMLElement> content = <HTMLElement>[
      new HTMLSpanElement()..textContent = '{',
    ];
    HTMLSpanElement label = new HTMLSpanElement()
      ..className = disabled ? 'curly-block disabled' : 'curly-block'
      ..textContent = expanded ? '\xa0\xa0⊟\xa0\xa0' : '\xa0\xa0⊞\xa0\xa0';
    if (disabled) {
      content.add(label);
    } else {
      content.add(
        new HTMLAnchorElement()
          ..onClick.listen((_) {
            toggle();
          })
          ..appendChild(label),
      );
    }
    if (expanded) {
      content.add(new HTMLBRElement());
      content.addAll(_content);
    }
    content.add(new HTMLSpanElement()..textContent = '}');
    setChildren(content);
  }
}
