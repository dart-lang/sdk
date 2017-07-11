// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:observatory/models.dart' as M show Target;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';

class TargetEvent {
  final M.Target target;

  TargetEvent(this.target);
}

class VMConnectTargetElement extends HtmlElement implements Renderable {
  static const tag = const Tag<VMConnectTargetElement>('vm-connect-target');

  RenderingScheduler<VMConnectTargetElement> _r;

  Stream<RenderedEvent<VMConnectTargetElement>> get onRendered => _r.onRendered;

  final StreamController<TargetEvent> _onConnect =
      new StreamController<TargetEvent>.broadcast();
  Stream<TargetEvent> get onConnect => _onConnect.stream;
  final StreamController<TargetEvent> _onDelete =
      new StreamController<TargetEvent>.broadcast();
  Stream<TargetEvent> get onDelete => _onDelete.stream;

  M.Target _target;
  bool _current;

  M.Target get target => _target;
  bool get current => _current;

  factory VMConnectTargetElement(M.Target target,
      {bool current: false, RenderingQueue queue}) {
    assert(target != null);
    assert(current != null);
    VMConnectTargetElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._target = target;
    e._current = current;
    return e;
  }

  VMConnectTargetElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    children = [];
    _r.disable(notify: true);
  }

  void connect() {
    _connect(new TargetEvent(target));
  }

  void delete() {
    _delete(new TargetEvent(target));
  }

  void render() {
    children = [
      new AnchorElement()
        ..text = current ? '${target.name} (Connected)' : '${target.name}'
        ..onClick.where(_filter).map(_toEvent).listen(_connect),
      new ButtonElement()
        ..text = '✖ Remove'
        ..classes = ['delete-button']
        ..onClick.map(_toEvent).listen(_delete)
    ];
  }

  void _connect(TargetEvent e) {
    _onConnect.add(e);
  }

  void _delete(TargetEvent e) {
    _onDelete.add(e);
  }

  TargetEvent _toEvent(_) {
    return new TargetEvent(target);
  }

  static bool _filter(MouseEvent event) {
    return !(event.button > 0 ||
        event.metaKey ||
        event.ctrlKey ||
        event.shiftKey ||
        event.altKey);
  }
}
