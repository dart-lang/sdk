// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory_2/models.dart' as M;
import 'package:observatory_2/src/elements/class_ref.dart';
import 'package:observatory_2/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory_2/src/elements/helpers/custom_element.dart';
import 'package:observatory_2/src/elements/inbound_references.dart';
import 'package:observatory_2/src/elements/retaining_path.dart';
import 'package:observatory_2/src/elements/sentinel_value.dart';
import 'package:observatory_2/src/elements/strongly_reachable_instances.dart';
import 'package:observatory_2/utils.dart';

class ClassInstancesElement extends CustomElement implements Renderable {
  RenderingScheduler<ClassInstancesElement> _r;

  Stream<RenderedEvent<ClassInstancesElement>> get onRendered => _r.onRendered;

  M.IsolateRef _isolate;
  M.Class _cls;
  M.RetainedSizeRepository _retainedSizes;
  M.ReachableSizeRepository _reachableSizes;
  M.StronglyReachableInstancesRepository _stronglyReachableInstances;
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
      M.ObjectRepository objects,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(cls != null);
    assert(retainedSizes != null);
    assert(reachableSizes != null);
    assert(stronglyReachableInstances != null);
    assert(objects != null);
    ClassInstancesElement e = new ClassInstancesElement.created();
    e._r = new RenderingScheduler<ClassInstancesElement>(e, queue: queue);
    e._isolate = isolate;
    e._cls = cls;
    e._retainedSizes = retainedSizes;
    e._reachableSizes = reachableSizes;
    e._stronglyReachableInstances = stronglyReachableInstances;
    e._objects = objects;
    return e;
  }

  ClassInstancesElement.created() : super.created('class-instances');

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

  StronglyReachableInstancesElement _strong;

  void render() {
    _strong = _strong ??
        new StronglyReachableInstancesElement(
            _isolate, _cls, _stronglyReachableInstances, _objects,
            queue: _r.queue);
    final instanceCount = _cls.newSpace.instances + _cls.oldSpace.instances;
    final size = Utils.formatSize(_cls.newSpace.size + _cls.oldSpace.size);
    children = <Element>[
      new DivElement()
        ..classes = ['memberList']
        ..children = <Element>[
          new DivElement()
            ..classes = const ['memberItem']
            ..children = <Element>[
              new DivElement()
                ..classes = const ['memberName']
                ..text = 'currently allocated',
              new DivElement()
                ..classes = const ['memberValue']
                ..text = 'count ${instanceCount} (shallow size ${size})'
            ],
          new DivElement()
            ..classes = ['memberItem']
            ..children = <Element>[
              new DivElement()
                ..classes = ['memberName']
                ..text = 'strongly reachable ',
              new DivElement()
                ..classes = ['memberValue']
                ..children = <Element>[_strong.element]
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
        ]
    ];
  }

  List<Element> _createReachableSizeValue() {
    final content = <Element>[];
    if (_reachableSize != null) {
      if (_reachableSize.isSentinel) {
        content.add(
            new SentinelValueElement(_reachableSize.asSentinel, queue: _r.queue)
                .element);
      } else {
        content.add(new SpanElement()
          ..text = Utils.formatSize(
              int.parse(_reachableSize.asValue.valueAsString)));
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
        content.add(
            new SentinelValueElement(_retainedSize.asSentinel, queue: _r.queue)
                .element);
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
