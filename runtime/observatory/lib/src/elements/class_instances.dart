// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/class_ref.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/inbound_references.dart';
import 'package:observatory/src/elements/retaining_path.dart';
import 'package:observatory/src/elements/sentinel_value.dart';
import 'package:observatory/src/elements/strongly_reachable_instances.dart';
import 'package:observatory/src/elements/top_retaining_instances.dart';
import 'package:observatory/utils.dart';

class ClassInstancesElement extends HtmlElement implements Renderable {
  static const tag =
      const Tag<ClassInstancesElement>('class-instances', dependencies: const [
    ClassRefElement.tag,
    InboundReferencesElement.tag,
    RetainingPathElement.tag,
    TopRetainingInstancesElement.tag
  ]);

  RenderingScheduler<ClassInstancesElement> _r;

  Stream<RenderedEvent<ClassInstancesElement>> get onRendered => _r.onRendered;

  M.IsolateRef _isolate;
  M.Class _cls;
  M.RetainedSizeRepository _retainedSizes;
  M.ReachableSizeRepository _reachableSizes;
  M.StronglyReachableInstancesRepository _stronglyReachableInstances;
  M.TopRetainingInstancesRepository _topRetainingInstances;
  M.ObjectRepository _objects;
  M.Guarded<M.Instance> _retainedSize = null;
  bool _loadingRetainedBytes = false;
  M.Guarded<M.Instance> _reachableSize = null;
  bool _loadingReachableBytes = false;

  M.IsolateRef get isolate => _isolate;
  M.Class get cls => _cls;

  factory ClassInstancesElement(
      M.IsolateRef isolate,
      M.Class cls,
      M.RetainedSizeRepository retainedSizes,
      M.ReachableSizeRepository reachableSizes,
      M.StronglyReachableInstancesRepository stronglyReachableInstances,
      M.TopRetainingInstancesRepository topRetainingInstances,
      M.ObjectRepository objects,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(cls != null);
    assert(retainedSizes != null);
    assert(reachableSizes != null);
    assert(stronglyReachableInstances != null);
    assert(topRetainingInstances != null);
    assert(objects != null);
    ClassInstancesElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._cls = cls;
    e._retainedSizes = retainedSizes;
    e._reachableSizes = reachableSizes;
    e._stronglyReachableInstances = stronglyReachableInstances;
    e._topRetainingInstances = topRetainingInstances;
    e._objects = objects;
    return e;
  }

  ClassInstancesElement.created() : super.created();

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

  StronglyReachableInstancesElement _strong;
  TopRetainingInstancesElement _topRetainig;

  void render() {
    _strong = _strong ??
        new StronglyReachableInstancesElement(
            _isolate, _cls, _stronglyReachableInstances, _objects,
            queue: _r.queue);
    _topRetainig = _topRetainig ??
        new TopRetainingInstancesElement(
            _isolate, _cls, _topRetainingInstances, _objects,
            queue: _r.queue);
    final instanceCount =
        _cls.newSpace.current.instances + _cls.oldSpace.current.instances;
    final size = Utils
        .formatSize(_cls.newSpace.current.bytes + _cls.oldSpace.current.bytes);
    children = [
      new DivElement()
        ..classes = ['memberList']
        ..children = [
          new DivElement()
            ..classes = const ['memberItem']
            ..children = [
              new DivElement()
                ..classes = const ['memberName']
                ..text = 'currently allocated',
              new DivElement()
                ..classes = const ['memberValue']
                ..text = 'count ${instanceCount} (shallow size ${size})'
            ],
          new DivElement()
            ..classes = ['memberItem']
            ..children = [
              new DivElement()
                ..classes = ['memberName']
                ..text = 'strongly reachable ',
              new DivElement()
                ..classes = ['memberValue']
                ..children = [_strong]
            ],
          new DivElement()
            ..classes = ['memberItem']
            ..title = 'Space reachable from this object, '
                'excluding class references'
            ..children = [
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
            ..children = [
              new DivElement()
                ..classes = ['memberName']
                ..text = 'Retained size ',
              new DivElement()
                ..classes = ['memberValue']
                ..children = _createRetainedSizeValue()
            ],
          new DivElement()
            ..classes = ['memberItem']
            ..children = [
              new DivElement()
                ..classes = ['memberName']
                ..text = 'toplist by retained memory ',
              new DivElement()
                ..classes = ['memberValue']
                ..children = [_topRetainig]
            ]
        ]
    ];
  }

  List<Element> _createReachableSizeValue() {
    final content = <Element>[];
    if (_reachableSize != null) {
      if (_reachableSize.isSentinel) {
        content.add(new SentinelValueElement(_reachableSize.asSentinel,
            queue: _r.queue));
      } else {
        content.add(new SpanElement()
          ..text = Utils
              .formatSize(int.parse(_reachableSize.asValue.valueAsString)));
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
      _reachableSize = await _reachableSizes.get(_isolate, _cls.id);
      _r.dirty();
    });
    content.add(button);
    return content;
  }

  List<Element> _createRetainedSizeValue() {
    final content = <Element>[];
    if (_retainedSize != null) {
      if (_retainedSize.isSentinel) {
        content.add(new SentinelValueElement(_retainedSize.asSentinel,
            queue: _r.queue));
      } else {
        content.add(new SpanElement()
          ..text =
              Utils.formatSize(int.parse(_retainedSize.asValue.valueAsString)));
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
      _retainedSize = await _retainedSizes.get(_isolate, _cls.id);
      _r.dirty();
    });
    content.add(button);
    return content;
  }
}
