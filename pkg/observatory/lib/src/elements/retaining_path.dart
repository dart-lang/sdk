// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:web/web.dart';

import '../../models.dart' as M;
import 'curly_block.dart';
import 'helpers/any_ref.dart';
import 'helpers/custom_element.dart';
import 'helpers/element_utils.dart';
import 'helpers/rendering_scheduler.dart';

class RetainingPathElement extends CustomElement implements Renderable {
  late RenderingScheduler<RetainingPathElement> _r;

  Stream<RenderedEvent<RetainingPathElement>> get onRendered => _r.onRendered;

  late M.IsolateRef _isolate;
  late M.ObjectRef _object;
  late M.RetainingPathRepository _retainingPaths;
  late M.ObjectRepository _objects;
  M.RetainingPath? _path;
  bool _expanded = false;

  M.IsolateRef get isolate => _isolate;
  M.ObjectRef get object => _object;

  factory RetainingPathElement(
    M.IsolateRef isolate,
    M.ObjectRef object,
    M.RetainingPathRepository retainingPaths,
    M.ObjectRepository objects, {
    RenderingQueue? queue,
  }) {
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
    removeChildren();
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
    children = <HTMLElement>[curlyBlock.element];
    _r.waitFor([curlyBlock.onRendered.first]);
  }

  Future _refresh() async {
    _path = null;
    _path = await _retainingPaths.get(_isolate, _object.id!);
    _r.dirty();
  }

  List<HTMLElement> _createContent() {
    if (_path == null) {
      return [new HTMLSpanElement()..textContent = 'Loading'];
    }

    var elements = <HTMLElement>[];
    bool first = true;
    for (var item in _path!.elements) {
      elements.add(_createItem(item, first));
      first = false;
    }
    elements.add(_createGCRootItem(_path!.gcRootType));
    return elements;
  }

  HTMLElement _createItem(M.RetainingPathItem item, bool first) {
    final content = <HTMLElement>[];

    if (first) {
      // No prefix.
    } else if (item.parentField != null) {
      content.add(
        new HTMLSpanElement()
          ..textContent = 'retained by ${item.parentField} of ',
      );
    } else if (item.parentListIndex != null) {
      content.add(
        new HTMLSpanElement()
          ..textContent = 'retained by [ ${item.parentListIndex} ] of ',
      );
    } else if (item.parentWordOffset != null) {
      content.add(
        new HTMLSpanElement()
          ..textContent = 'retained by offset ${item.parentWordOffset} of ',
      );
    } else {
      content.add(new HTMLSpanElement()..textContent = 'retained by ');
    }

    content.add(anyRef(_isolate, item.source, _objects, queue: _r.queue));

    return new HTMLDivElement()
      ..className = 'indent'
      ..appendChildren(content);
  }

  HTMLElement _createGCRootItem(String gcRootType) {
    return new HTMLDivElement()
      ..className = 'indent'
      ..textContent = 'retained by a GC root ($gcRootType)';
  }
}
