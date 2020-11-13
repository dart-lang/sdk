// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/class_ref.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/inbound_references.dart';
import 'package:observatory/src/elements/retaining_path.dart';
import 'package:observatory/src/elements/sentinel_value.dart';
import 'package:observatory/utils.dart';

class ObjectCommonElement extends CustomElement implements Renderable {
  late RenderingScheduler<ObjectCommonElement> _r;

  Stream<RenderedEvent<ObjectCommonElement>> get onRendered => _r.onRendered;

  late M.IsolateRef _isolate;
  late M.Object _object;
  late M.RetainedSizeRepository _retainedSizes;
  late M.ReachableSizeRepository _reachableSizes;
  late M.InboundReferencesRepository _references;
  late M.RetainingPathRepository _retainingPaths;
  late M.ObjectRepository _objects;
  M.Guarded<M.Instance>? _retainedSize = null;
  bool _loadingRetainedBytes = false;
  M.Guarded<M.Instance>? _reachableSize = null;
  bool _loadingReachableBytes = false;

  M.IsolateRef get isolate => _isolate;
  M.Object get object => _object;

  factory ObjectCommonElement(
      M.IsolateRef isolate,
      M.Object object,
      M.RetainedSizeRepository retainedSizes,
      M.ReachableSizeRepository reachableSizes,
      M.InboundReferencesRepository references,
      M.RetainingPathRepository retainingPaths,
      M.ObjectRepository objects,
      {RenderingQueue? queue}) {
    assert(isolate != null);
    assert(object != null);
    assert(retainedSizes != null);
    assert(reachableSizes != null);
    assert(references != null);
    assert(retainingPaths != null);
    assert(objects != null);
    ObjectCommonElement e = new ObjectCommonElement.created();
    e._r = new RenderingScheduler<ObjectCommonElement>(e, queue: queue);
    e._isolate = isolate;
    e._object = object;
    e._retainedSizes = retainedSizes;
    e._reachableSizes = reachableSizes;
    e._references = references;
    e._objects = objects;
    e._retainingPaths = retainingPaths;
    return e;
  }

  ObjectCommonElement.created() : super.created('object-common');

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    _r.disable(notify: true);
    children = <Element>[];
  }

  RetainingPathElement? _path;
  InboundReferencesElement? _inbounds;

  void render() {
    _path = _path ??
        new RetainingPathElement(_isolate, _object, _retainingPaths, _objects,
            queue: _r.queue);
    _inbounds = _inbounds ??
        new InboundReferencesElement(_isolate, _object, _references, _objects,
            queue: _r.queue);
    children = <Element>[
      new DivElement()
        ..classes = ['memberList']
        ..children = <Element>[
          new DivElement()
            ..classes = ['memberItem']
            ..children = <Element>[
              new DivElement()
                ..classes = ['memberName']
                ..text = 'Class ',
              new DivElement()
                ..classes = ['memberValue']
                ..children = <Element>[
                  _object.clazz == null
                      ? (new SpanElement()..text = '...')
                      : new ClassRefElement(_isolate, _object.clazz!,
                              queue: _r.queue)
                          .element
                ]
            ],
          new DivElement()
            ..classes = ['memberItem']
            ..title = 'Space for this object in memory'
            ..children = <Element>[
              new DivElement()
                ..classes = ['memberName']
                ..text = 'Shallow size ',
              new DivElement()
                ..classes = ['memberValue']
                ..text = Utils.formatSize(_object.size ?? 0)
            ],
          new DivElement()
            ..classes = ['memberItem']
            ..title = 'Space reachable from this object, '
                'excluding class references'
            ..children = <Element>[
              new DivElement()
                ..classes = ['memberName']
                ..text = 'Reachable size ',
              new DivElement()
                ..classes = ['memberValue']
                ..children = _createReachableSizeValue()
            ],
          new DivElement()
            ..classes = ['memberItem']
            ..title = 'Space that would be reclaimed if references to this '
                'object were replaced with null'
            ..children = <Element>[
              new DivElement()
                ..classes = ['memberName']
                ..text = 'Retained size ',
              new DivElement()
                ..classes = ['memberValue']
                ..children = _createRetainedSizeValue()
            ],
          new DivElement()
            ..classes = ['memberItem']
            ..children = <Element>[
              new DivElement()
                ..classes = ['memberName']
                ..text = 'Retaining path ',
              new DivElement()
                ..classes = ['memberValue']
                ..children = <Element>[_path!.element]
            ],
          new DivElement()
            ..classes = ['memberItem']
            ..title = 'Objects which directly reference this object'
            ..children = <Element>[
              new DivElement()
                ..classes = ['memberName']
                ..text = 'Inbound references ',
              new DivElement()
                ..classes = ['memberValue']
                ..children = <Element>[_inbounds!.element]
            ]
        ]
    ];
  }

  List<Element> _createReachableSizeValue() {
    final content = <Element>[];
    if (_reachableSize != null) {
      if (_reachableSize!.isSentinel) {
        content.add(new SentinelValueElement(_reachableSize!.asSentinel!,
                queue: _r.queue)
            .element);
      } else {
        content.add(new SpanElement()
          ..text = Utils.formatSize(
              int.parse(_reachableSize!.asValue!.valueAsString!)));
      }
    } else {
      content.add(new SpanElement()..text = '...');
    }
    final button = new ButtonElement()
      ..classes = ['reachable_size']
      ..disabled = _loadingReachableBytes
      ..text = '↺';
    button.onClick.listen((_) async {
      button.disabled = true;
      _loadingReachableBytes = true;
      _reachableSize = await _reachableSizes.get(_isolate, _object.id!);
      _r.dirty();
    });
    content.add(button);
    return content;
  }

  List<Element> _createRetainedSizeValue() {
    final content = <Element>[];
    if (_retainedSize != null) {
      if (_retainedSize!.isSentinel) {
        content.add(new SentinelValueElement(_retainedSize!.asSentinel!,
                queue: _r.queue)
            .element);
      } else {
        content.add(new SpanElement()
          ..text = Utils.formatSize(
              int.parse(_retainedSize!.asValue!.valueAsString!)));
      }
    } else {
      content.add(new SpanElement()..text = '...');
    }
    final button = new ButtonElement()
      ..classes = ['retained_size']
      ..disabled = _loadingRetainedBytes
      ..text = '↺';
    button.onClick.listen((_) async {
      button.disabled = true;
      _loadingRetainedBytes = true;
      _retainedSize = await _retainedSizes.get(_isolate, _object.id!);
      _r.dirty();
    });
    content.add(button);
    return content;
  }
}
