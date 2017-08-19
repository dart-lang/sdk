// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library curly_block_element;

import 'dart:async';
import 'dart:html';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';

class CurlyBlockToggleEvent {
  final CurlyBlockElement control;

  CurlyBlockToggleEvent(this.control);
}

class CurlyBlockElement extends HtmlElement implements Renderable {
  static const tag = const Tag<CurlyBlockElement>('curly-block');

  RenderingScheduler<CurlyBlockElement> _r;

  final StreamController<CurlyBlockToggleEvent> _onToggle =
      new StreamController<CurlyBlockToggleEvent>.broadcast();
  Stream<CurlyBlockToggleEvent> get onToggle => _onToggle.stream;
  Stream<RenderedEvent<CurlyBlockElement>> get onRendered => _r.onRendered;

  bool _expanded;
  bool _disabled;
  Iterable<Element> _content = const [];

  bool get expanded => _expanded;
  bool get disabled => _disabled;
  Iterable<Element> get content => _content;

  set expanded(bool value) {
    if (_expanded != value) _onToggle.add(new CurlyBlockToggleEvent(this));
    _expanded = _r.checkAndReact(_expanded, value);
  }

  set disabled(bool value) => _disabled = _r.checkAndReact(_disabled, value);
  set content(Iterable<Element> value) {
    _content = value.toList();
    _r.dirty();
  }

  factory CurlyBlockElement(
      {bool expanded: false, bool disabled: false, RenderingQueue queue}) {
    assert(expanded != null);
    assert(disabled != null);
    CurlyBlockElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._expanded = expanded;
    e._disabled = disabled;
    return e;
  }

  CurlyBlockElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    _r.disable(notify: true);
    children = [];
  }

  void toggle() {
    if (disabled) {
      _r.scheduleNotification();
      return;
    }
    expanded = !expanded;
  }

  void render() {
    List<Element> content = [new SpanElement()..text = '{'];
    SpanElement label = new SpanElement()
      ..classes = disabled ? ['curly-block', 'disabled'] : ['curly-block']
      ..innerHtml = expanded
          ? '&nbsp;&nbsp;&#8863;&nbsp;&nbsp;'
          : '&nbsp;&nbsp;&#8862;&nbsp;&nbsp;';
    if (disabled) {
      content.add(label);
    } else {
      content.add(new AnchorElement()
        ..onClick.listen((_) {
          toggle();
        })
        ..children = [label]);
    }
    if (expanded) {
      content.add(new BRElement());
      content.addAll(_content);
    }
    content.add(new SpanElement()..text = '}');
    children = content;
  }
}
