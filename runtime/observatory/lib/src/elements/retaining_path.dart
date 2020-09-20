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
import 'package:observatory/src/elements/helpers/custom_element.dart';

class RetainingPathElement extends CustomElement implements Renderable {
  RenderingScheduler<RetainingPathElement> _r;

  Stream<RenderedEvent<RetainingPathElement>> get onRendered => _r.onRendered;

  M.IsolateRef _isolate;
  M.ObjectRef _object;
  M.RetainingPathRepository _retainingPaths;
  M.ObjectRepository _objects;
  M.RetainingPath _path;
  bool _expanded = false;

  M.IsolateRef get isolate => _isolate;
  M.ObjectRef get object => _object;

  factory RetainingPathElement(M.IsolateRef isolate, M.ObjectRef object,
      M.RetainingPathRepository retainingPaths, M.ObjectRepository objects,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(object != null);
    assert(retainingPaths != null);
    assert(objects != null);
    RetainingPathElement e = new RetainingPathElement.created();
    e._r = new RenderingScheduler<RetainingPathElement>(e, queue: queue);
    e._isolate = isolate;
    e._object = object;
    e._retainingPaths = retainingPaths;
    e._objects = objects;
    return e;
  }

  RetainingPathElement.created() : super.created('retaining-path');

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
    final curlyBlock =
        new CurlyBlockElement(expanded: _expanded, queue: _r.queue)
          ..content = _createContent()
          ..onToggle.listen((e) async {
            _expanded = e.control.expanded;
            if (_expanded) {
              e.control.disabled = true;
              await _refresh();
              e.control.disabled = false;
            }
          });
    children = <Element>[curlyBlock.element];
    _r.waitFor([curlyBlock.onRendered.first]);
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

    var elements = <Element>[];
    bool first = true;
    for (var item in _path.elements) {
      elements.add(_createItem(item, first));
      first = false;
    }
    elements.add(_createGCRootItem(_path.gcRootType));
    return elements;
  }

  Element _createItem(M.RetainingPathItem item, bool first) {
    final content = <Element>[];

    if (first) {
      // No prefix.
    } else if (item.parentField != null) {
      content
          .add(new SpanElement()..text = 'retained by ${item.parentField} of ');
    } else if (item.parentListIndex != null) {
      content.add(new SpanElement()
        ..text = 'retained by [ ${item.parentListIndex} ] of ');
    } else if (item.parentWordOffset != null) {
      content.add(new SpanElement()
        ..text = 'retained by offset ${item.parentWordOffset} of ');
    } else {
      content.add(new SpanElement()..text = 'retained by ');
    }

    content.add(anyRef(_isolate, item.source, _objects, queue: _r.queue));

    return new DivElement()
      ..classes = ['indent']
      ..children = content;
  }

  Element _createGCRootItem(String gcRootType) {
    return new DivElement()
      ..classes = ['indent']
      ..text = 'retained by a GC root ($gcRootType)';
  }
}
