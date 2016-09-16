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

class RetainingPathElement extends HtmlElement implements Renderable {
  static const tag = const Tag<RetainingPathElement>('retaining-path',
      dependencies: const [CurlyBlockElement.tag, InstanceRefElement.tag]);

  RenderingScheduler<RetainingPathElement> _r;

  Stream<RenderedEvent<RetainingPathElement>> get onRendered => _r.onRendered;

  M.IsolateRef _isolate;
  M.ObjectRef _object;
  M.RetainingPathRepository _retainingPaths;
  M.InstanceRepository _instances;
  M.RetainingPath _path;
  bool _expanded = false;

  M.IsolateRef get isolate => _isolate;
  M.ObjectRef get object => _object;

  factory RetainingPathElement(M.IsolateRef isolate, M.ObjectRef object,
      M.RetainingPathRepository retainingPaths, M.InstanceRepository instances,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(object != null);
    assert(retainingPaths != null);
    assert(instances != null);
    RetainingPathElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._object = object;
    e._retainingPaths = retainingPaths;
    e._instances = instances;
    return e;
  }

  RetainingPathElement.created() : super.created();

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
        ..content = _createContent()
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
    _path = null;
    _path = await _retainingPaths.get(_isolate, _object.id);
    _r.dirty();
  }

  List<Element> _createContent() {
    if (_path == null) {
      return [new SpanElement()..text = 'Loading'];
    }
    return _path.elements.map(_createItem).toList();
  }

  Element _createItem(M.RetainingPathItem item) {
    final content = <Element>[];

    if (item.parentField != null) {
      content.add(new SpanElement()
        ..children = [
          new SpanElement()..text = 'from ',
          anyRef(_isolate, item.parentField, _instances, queue: _r.queue),
          new SpanElement()..text = ' of ',
        ]);
    } else if (item.parentListIndex != null) {
      content.add(
          new SpanElement()..text = 'from [ ${item.parentListIndex} ] of ');
    } else if (item.parentWordOffset != null) {
      content.add(new SpanElement()
        ..text = 'from word [ ${item.parentWordOffset} ] of ');
    } else {
      content.add(new SpanElement()..text = 'from ');
    }

    content.add(anyRef(_isolate, item.source, _instances, queue: _r.queue));

    return new DivElement()
      ..classes = ['indent']
      ..children = content;
  }
}
