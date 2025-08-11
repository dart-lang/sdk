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

class InboundReferencesElement extends CustomElement implements Renderable {
  late RenderingScheduler<InboundReferencesElement> _r;

  Stream<RenderedEvent<InboundReferencesElement>> get onRendered =>
      _r.onRendered;

  late M.IsolateRef _isolate;
  late M.ObjectRef _object;
  late M.InboundReferencesRepository _references;
  late M.ObjectRepository _objects;
  M.InboundReferences? _inbounds;
  bool _expanded = false;

  M.IsolateRef get isolate => _isolate;
  M.ObjectRef get object => _object;

  factory InboundReferencesElement(
    M.IsolateRef isolate,
    M.ObjectRef object,
    M.InboundReferencesRepository references,
    M.ObjectRepository objects, {
    RenderingQueue? queue,
  }) {
    InboundReferencesElement e = new InboundReferencesElement.created();
    e._r = new RenderingScheduler<InboundReferencesElement>(e, queue: queue);
    e._isolate = isolate;
    e._object = object;
    e._references = references;
    e._objects = objects;
    return e;
  }

  InboundReferencesElement.created() : super.created('inbound-references');

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
    setChildren(<HTMLElement>[curlyBlock.element]);
    _r.waitFor([curlyBlock.onRendered.first]);
  }

  Future _refresh() async {
    _inbounds = await _references.get(_isolate, _object.id!);
    _r.dirty();
  }

  List<HTMLElement> _createContent() {
    if (_inbounds == null) {
      return const [];
    }
    return _inbounds!.elements.map<HTMLElement>(_createItem).toList();
  }

  HTMLElement _createItem(M.InboundReference reference) {
    final content = <HTMLElement>[];

    if (reference.parentField is M.Object) {
      content.addAll([
        new HTMLSpanElement()..textContent = 'referenced by ',
        anyRef(_isolate, reference.parentField, _objects, queue: _r.queue),
        new HTMLSpanElement()..textContent = ' of ',
      ]);
    } else if (reference.parentField is String ||
        reference.parentField is int) {
      content.add(
        new HTMLSpanElement()
          ..textContent = 'referenced by [ ${reference.parentField} ] of ',
      );
    } else if (reference.parentListIndex != null) {
      content.add(
        new HTMLSpanElement()
          ..textContent = 'referenced by [ ${reference.parentListIndex} ] of ',
      );
    } else if (reference.parentWordOffset != null) {
      content.add(
        new HTMLSpanElement()
          ..textContent =
              'referenced by offset ${reference.parentWordOffset} of ',
      );
    }

    content.addAll([
      anyRef(_isolate, reference.source, _objects, queue: _r.queue),
      new InboundReferencesElement(
        _isolate,
        reference.source,
        _references,
        _objects,
        queue: _r.queue,
      ).element,
    ]);

    return new HTMLDivElement()
      ..className = 'indent'
      ..appendChildren(content);
  }
}
