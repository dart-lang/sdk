// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M
    show IsolateRef, IsolateRepository, EventRepository;
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';

class ReloadEvent {
  final NavReloadElement element;
  ReloadEvent(this.element);
}

class NavReloadElement extends CustomElement implements Renderable {
  late RenderingScheduler<NavReloadElement> _r;

  Stream<RenderedEvent<NavReloadElement>> get onRendered => _r.onRendered;

  final StreamController<ReloadEvent> _onReload =
      new StreamController<ReloadEvent>.broadcast();
  Stream<ReloadEvent> get onReload => _onReload.stream;

  late M.IsolateRef _isolate;
  late M.IsolateRepository _isolates;
  late M.EventRepository _events;
  StreamSubscription? _sub;
  bool _disabled = false;

  factory NavReloadElement(M.IsolateRef isolate, M.IsolateRepository isolates,
      M.EventRepository events,
      {RenderingQueue? queue}) {
    assert(isolate != null);
    assert(isolates != null);
    assert(events != null);
    NavReloadElement e = new NavReloadElement.created();
    e._r = new RenderingScheduler<NavReloadElement>(e, queue: queue);
    e._isolate = isolate;
    e._isolates = isolates;
    e._events = events;
    return e;
  }

  NavReloadElement.created() : super.created('nav-reload');

  @override
  void attached() {
    super.attached();
    _r.enable();
    _sub = _events.onServiceEvent.listen((_) => _r.dirty());
  }

  @override
  void detached() {
    super.detached();
    children = <Element>[];
    _sub!.cancel();
    _sub = null;
    _r.disable(notify: true);
  }

  void render() {
    final children = <Element>[];
    if (_isolates.reloadSourcesServices.isEmpty) {
      children.add(new LIElement()
        ..children = <Element>[
          new ButtonElement()
            ..text = 'Reload Source'
            ..disabled = _disabled
            ..onClick.listen((_) => _reload())
        ]);
    } else if (_isolates.reloadSourcesServices.length == 1) {
      children.add(new LIElement()
        ..children = <Element>[
          new ButtonElement()
            ..text = 'Reload Source'
            ..disabled = _disabled
            ..onClick
                .listen((_) => _reload(_isolates.reloadSourcesServices.single))
        ]);
    } else {
      final content = _isolates.reloadSourcesServices
          .map((s) => new LIElement()
            ..children = <Element>[
              new ButtonElement()
                ..text = s.alias
                ..disabled = _disabled
                ..onClick.listen((_) => _reload(s))
            ])
          .toList();
      children.add(navMenu('Reload Source', content: content));
    }
    this.children = children;
  }

  Future _reload([service]) async {
    _disabled = true;
    _r.dirty();
    await _isolates.reloadSources(_isolate, service: service);
    _disabled = false;
    _r.dirty();
    _onReload.add(new ReloadEvent(this));
  }
}
