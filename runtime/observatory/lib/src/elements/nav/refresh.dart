// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:web/web.dart';

import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/element_utils.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';

class RefreshEvent {
  final NavRefreshElement element;
  RefreshEvent(this.element);
}

class NavRefreshElement extends CustomElement implements Renderable {
  late RenderingScheduler<NavRefreshElement> _r;

  Stream<RenderedEvent<NavRefreshElement>> get onRendered => _r.onRendered;

  final StreamController<RefreshEvent> _onRefresh =
      new StreamController<RefreshEvent>.broadcast();
  Stream<RefreshEvent> get onRefresh => _onRefresh.stream;

  late bool _disabled;
  late String _label;

  bool get disabled => _disabled;
  String get label => _label;

  set disabled(bool value) => _disabled = _r.checkAndReact(_disabled, value);
  set label(String value) => _label = _r.checkAndReact(_label, value);

  factory NavRefreshElement(
      {String label = 'Refresh',
      bool disabled = false,
      RenderingQueue? queue}) {
    NavRefreshElement e = new NavRefreshElement.created();
    e._r = new RenderingScheduler<NavRefreshElement>(e, queue: queue);
    e._label = label;
    e._disabled = disabled;
    return e;
  }

  NavRefreshElement.created() : super.created('nav-refresh');

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    removeChildren();
    _r.disable(notify: true);
  }

  void render() {
    children = <HTMLElement>[
      new HTMLLIElement()
        ..appendChildren(<HTMLElement>[
          new HTMLButtonElement()
            ..textContent = label
            ..disabled = disabled
            ..onClick.map(_toEvent).listen(_refresh)
        ])
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
