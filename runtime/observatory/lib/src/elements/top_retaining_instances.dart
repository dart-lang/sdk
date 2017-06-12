// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/curly_block.dart';
import 'package:observatory/src/elements/instance_ref.dart';
import 'package:observatory/src/elements/helpers/any_ref.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/utils.dart';

class TopRetainingInstancesElement extends HtmlElement implements Renderable {
  static const tag = const Tag<TopRetainingInstancesElement>(
      'top-retainig-instances',
      dependencies: const [CurlyBlockElement.tag, InstanceRefElement.tag]);

  RenderingScheduler<TopRetainingInstancesElement> _r;

  Stream<RenderedEvent<TopRetainingInstancesElement>> get onRendered =>
      _r.onRendered;

  M.IsolateRef _isolate;
  M.ClassRef _cls;
  M.TopRetainingInstancesRepository _topRetainingInstances;
  M.ObjectRepository _objects;
  Iterable<M.RetainingObject> _topRetaining;
  bool _expanded = false;

  M.IsolateRef get isolate => _isolate;
  M.ClassRef get cls => _cls;

  factory TopRetainingInstancesElement(
      M.IsolateRef isolate,
      M.ClassRef cls,
      M.TopRetainingInstancesRepository topRetainingInstances,
      M.ObjectRepository objects,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(cls != null);
    assert(topRetainingInstances != null);
    assert(objects != null);
    TopRetainingInstancesElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._cls = cls;
    e._topRetainingInstances = topRetainingInstances;
    e._objects = objects;
    return e;
  }

  TopRetainingInstancesElement.created() : super.created();

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

  void render() {
    children = [
      new CurlyBlockElement(expanded: _expanded, queue: _r.queue)
        ..content = [
          new DivElement()
            ..classes = ['memberList']
            ..children = _createContent()
        ]
        ..onToggle.listen((e) async {
          _expanded = e.control.expanded;
          if (_expanded) {
            e.control.disabled = true;
            await _refresh();
            e.control.disabled = false;
          }
        })
    ];
  }

  Future _refresh() async {
    _topRetaining = null;
    _topRetaining = await _topRetainingInstances.get(_isolate, _cls);
    _r.dirty();
  }

  List<Element> _createContent() {
    if (_topRetaining == null) {
      return [new SpanElement()..text = 'Loading...'];
    }
    return _topRetaining
        .map((r) => new DivElement()
          ..classes = ['memberItem']
          ..children = [
            new DivElement()
              ..classes = ['memberName']
              ..text = '${Utils.formatSize(r.retainedSize)} ',
            new DivElement()
              ..classes = ['memberValue']
              ..children = [
                anyRef(_isolate, r.object, _objects, queue: _r.queue)
              ]
          ])
        .toList();
  }
}
