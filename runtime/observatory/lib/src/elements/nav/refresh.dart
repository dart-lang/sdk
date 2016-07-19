// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';

class RefreshEvent {
  final NavRefreshElement element;
  RefreshEvent(this.element);
}

class NavRefreshElement extends HtmlElement implements Renderable {
  static const tag = const Tag<NavRefreshElement>('nav-refresh-wrapped');

  RenderingScheduler _r;

  Stream<RenderedEvent<NavRefreshElement>> get onRendered => _r.onRendered;

  final StreamController<RefreshEvent> _onRefresh =
                                new StreamController<RefreshEvent>.broadcast();
  Stream<RefreshEvent> get onRefresh => _onRefresh.stream;

  bool _disabled;
  String _label;
  bool get disabled => _disabled;
  String get label => _label;
  set disabled(bool value) {
    if (_disabled != value) {
      _disabled = value;
      _r.dirty();
    } else {
      _r.scheduleNotification();
    }
  }
  set label(String value) {
    if (_label != value) {
      _label = value;
      _r.dirty();
    } else {
      _r.scheduleNotification();
    }
  }


  factory NavRefreshElement({String label: 'Refresh', bool disabled: false,
                             RenderingQueue queue}) {
    assert(label != null);
    assert(disabled != null);
    NavRefreshElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._label = label;
    e._disabled = disabled;
    return e;
  }

  NavRefreshElement.created() : super.created();

  @override
  void attached() { super.attached(); _r.enable(); }

  @override
  void detached() { super.detached(); children = []; _r.disable(notify: true); }

  void render() {
    children = [
      new LIElement()
        ..children = [
          new ButtonElement()
            ..text = label
            ..disabled = disabled
            ..onClick.map(_toEvent).listen(_refresh)
        ]
    ];
  }

  RefreshEvent _toEvent(_) {
    return new RefreshEvent(this);
  }

  void _refresh(RefreshEvent e) {
    if (_disabled) return;
    _onRefresh.add(e);
  }

  void refresh() {
    if (_disabled) return;
    _refresh(new RefreshEvent(this));
  }
}
