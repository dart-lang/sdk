// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/instance_ref.dart';

class FieldRefElement extends HtmlElement implements Renderable {
  static const tag = const Tag<FieldRefElement>('field-ref',
      dependencies: const [InstanceRefElement.tag]);

  RenderingScheduler<FieldRefElement> _r;

  Stream<RenderedEvent<FieldRefElement>> get onRendered => _r.onRendered;

  M.IsolateRef _isolate;
  M.FieldRef _field;
  M.ObjectRepository _objects;
  bool _expandable;

  M.IsolateRef get isolate => _isolate;
  M.FieldRef get field => _field;

  factory FieldRefElement(
      M.IsolateRef isolate, M.FieldRef field, M.ObjectRepository objects,
      {RenderingQueue queue, bool expandable: true}) {
    assert(isolate != null);
    assert(field != null);
    assert(objects != null);
    FieldRefElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._field = field;
    e._objects = objects;
    e._expandable = expandable;
    return e;
  }

  FieldRefElement.created() : super.created();

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

  void render() {
    var header = '';
    if (_field.isStatic) {
      if (_field.dartOwner is M.ClassRef) {
        header += 'static ';
      } else {
        header += 'top-level ';
      }
    }
    if (_field.isFinal) {
      header += 'final ';
    } else if (_field.isConst) {
      header += 'const ';
    } else if (_field.declaredType.name == 'dynamic') {
      header += 'var ';
    }
    if (_field.declaredType.name == 'dynamic') {
      children = [
        new SpanElement()..text = header,
        new AnchorElement(href: Uris.inspect(_isolate, object: _field))
          ..text = _field.name
      ];
    } else {
      children = [
        new SpanElement()..text = header,
        new InstanceRefElement(_isolate, _field.declaredType, _objects,
            queue: _r.queue, expandable: _expandable),
        new SpanElement()..text = ' ',
        new AnchorElement(href: Uris.inspect(_isolate, object: _field))
          ..text = _field.name
      ];
    }
  }
}
