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

class InboundReferencesElement extends HtmlElement implements Renderable {
  static const tag = const Tag<InboundReferencesElement>('inbound-references',
      dependencies: const [CurlyBlockElement.tag, InstanceRefElement.tag]);

  RenderingScheduler<InboundReferencesElement> _r;

  Stream<RenderedEvent<InboundReferencesElement>> get onRendered =>
      _r.onRendered;

  M.IsolateRef _isolate;
  M.ObjectRef _object;
  M.InboundReferencesRepository _references;
  M.ObjectRepository _objects;
  M.InboundReferences _inbounds;
  bool _expanded = false;

  M.IsolateRef get isolate => _isolate;
  M.ObjectRef get object => _object;

  factory InboundReferencesElement(M.IsolateRef isolate, M.ObjectRef object,
      M.InboundReferencesRepository references, M.ObjectRepository objects,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(object != null);
    assert(references != null);
    assert(objects != null);
    InboundReferencesElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._object = object;
    e._references = references;
    e._objects = objects;
    return e;
  }

  InboundReferencesElement.created() : super.created();

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
    children = [curlyBlock];
    _r.waitFor([curlyBlock.onRendered.first]);
  }

  Future _refresh() async {
    _inbounds = await _references.get(_isolate, _object.id);
    _r.dirty();
  }

  List<Element> _createContent() {
    if (_inbounds == null) {
      return const [];
    }
    return _inbounds.elements.map(_createItem).toList();
  }

  Element _createItem(M.InboundReference reference) {
    final content = <Element>[];

    if (reference.parentField != null) {
      content.addAll([
        new SpanElement()..text = 'referenced by ',
        anyRef(_isolate, reference.parentField, _objects, queue: _r.queue),
        new SpanElement()..text = ' of '
      ]);
    } else if (reference.parentListIndex != null) {
      content.add(new SpanElement()
        ..text = 'referenced by [ ${reference.parentListIndex} ] of ');
    } else if (reference.parentWordOffset != null) {
      content.add(new SpanElement()
        ..text = 'referenced by offset ${reference.parentWordOffset} of ');
    }

    content.addAll([
      anyRef(_isolate, reference.source, _objects, queue: _r.queue),
      new InboundReferencesElement(
          _isolate, reference.source, _references, _objects,
          queue: _r.queue)
    ]);

    return new DivElement()
      ..classes = ['indent']
      ..children = content;
  }
}
