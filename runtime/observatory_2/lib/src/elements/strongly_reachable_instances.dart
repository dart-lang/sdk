// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory_2/models.dart' as M;
import 'package:observatory_2/src/elements/curly_block.dart';
import 'package:observatory_2/src/elements/instance_ref.dart';
import 'package:observatory_2/src/elements/helpers/any_ref.dart';
import 'package:observatory_2/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory_2/src/elements/helpers/custom_element.dart';

class StronglyReachableInstancesElement extends CustomElement
    implements Renderable {
  RenderingScheduler<StronglyReachableInstancesElement> _r;

  Stream<RenderedEvent<StronglyReachableInstancesElement>> get onRendered =>
      _r.onRendered;

  M.IsolateRef _isolate;
  M.ClassRef _cls;
  M.StronglyReachableInstancesRepository _stronglyReachableInstances;
  M.ObjectRepository _objects;
  M.InstanceSet _result;
  bool _expanded = false;

  M.IsolateRef get isolate => _isolate;
  M.ClassRef get cls => _cls;

  factory StronglyReachableInstancesElement(
      M.IsolateRef isolate,
      M.ClassRef cls,
      M.StronglyReachableInstancesRepository stronglyReachable,
      M.ObjectRepository objects,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(cls != null);
    assert(stronglyReachable != null);
    assert(objects != null);
    StronglyReachableInstancesElement e =
        new StronglyReachableInstancesElement.created();
    e._r = new RenderingScheduler<StronglyReachableInstancesElement>(e,
        queue: queue);
    e._isolate = isolate;
    e._cls = cls;
    e._stronglyReachableInstances = stronglyReachable;
    e._objects = objects;
    return e;
  }

  StronglyReachableInstancesElement.created()
      : super.created('strongly-reachable-instances');

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    children = <Element>[];
    _r.disable(notify: true);
  }

  void render() {
    children = <Element>[
      (new CurlyBlockElement(expanded: _expanded, queue: _r.queue)
            ..content = _createContent()
            ..onToggle.listen((e) async {
              _expanded = e.control.expanded;
              e.control.disabled = true;
              await _refresh();
              e.control.disabled = false;
            }))
          .element
    ];
  }

  Future _refresh() async {
    _result = null;
    _result = await _stronglyReachableInstances.get(_isolate, _cls);
    _r.dirty();
  }

  List<Element> _createContent() {
    if (_result == null) {
      return [new SpanElement()..text = 'Loading...'];
    }
    final content = _result.instances
        .map<Element>((sample) => new DivElement()
          ..children = <Element>[
            anyRef(_isolate, sample, _objects, queue: _r.queue)
          ])
        .toList();
    content.add(new DivElement()
      ..children = ([]
        ..addAll(_createShowMoreButton())
        ..add(new SpanElement()..text = ' of total ${_result.count}')));
    return content;
  }

  List<Element> _createShowMoreButton() {
    final samples = _result.instances.toList();
    if (samples.length == _result.count) {
      return [];
    }
    final count = samples.length;
    final button = new ButtonElement()..text = 'show next ${count}';
    button.onClick.listen((_) async {
      button.disabled = true;
      _result = await _stronglyReachableInstances.get(_isolate, _cls,
          limit: count * 2);
      _r.dirty();
    });
    return [button];
  }
}
