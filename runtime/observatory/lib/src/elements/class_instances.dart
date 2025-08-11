// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:web/web.dart';

import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/any_ref.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/element_utils.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/sentinel_value.dart';
import 'package:observatory/src/elements/strongly_reachable_instances.dart';
import 'package:observatory/utils.dart';

class ClassInstancesElement extends CustomElement implements Renderable {
  late RenderingScheduler<ClassInstancesElement> _r;

  Stream<RenderedEvent<ClassInstancesElement>> get onRendered => _r.onRendered;

  late M.IsolateRef _isolate;
  late M.Class _cls;
  late M.RetainedSizeRepository _retainedSizes;
  late M.ReachableSizeRepository _reachableSizes;
  late M.StronglyReachableInstancesRepository _stronglyReachableInstances;
  late M.ObjectRepository _objects;
  M.Guarded<M.InstanceRef>? _allInstances = null;
  bool _loadingAllInstances = false;
  M.Guarded<M.InstanceRef>? _allSubclassInstances = null;
  bool _loadingAllSubclassInstances = false;
  M.Guarded<M.InstanceRef>? _allImplementorInstances = null;
  bool _loadingAllImplementorInstances = false;
  M.Guarded<M.Instance>? _retainedSize = null;
  bool _loadingRetainedBytes = false;
  M.Guarded<M.Instance>? _reachableSize = null;
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
      {RenderingQueue? queue}) {
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
    removeChildren();
  }

  StronglyReachableInstancesElement? _strong;

  void render() {
    _strong = _strong ??
        new StronglyReachableInstancesElement(
            _isolate, _cls, _stronglyReachableInstances, _objects,
            queue: _r.queue);
    final instanceCount = _cls.newSpace!.instances + _cls.oldSpace!.instances;
    final size = Utils.formatSize(_cls.newSpace!.size + _cls.oldSpace!.size);
    removeChildren();
    appendChildren(<HTMLElement>[
      new HTMLDivElement()
        ..className = 'memberList'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberItem'
            ..appendChildren(<HTMLElement>[
              new HTMLDivElement()
                ..className = 'memberName'
                ..textContent = 'currently allocated',
              new HTMLDivElement()
                ..className = 'memberValue'
                ..textContent = 'count ${instanceCount} (shallow size ${size})'
            ]),
          new HTMLDivElement()
            ..className = 'memberItem'
            ..appendChildren(<HTMLElement>[
              new HTMLDivElement()
                ..className = 'memberName'
                ..textContent = 'strongly reachable ',
              new HTMLDivElement()
                ..className = 'memberValue'
                ..appendChild(_strong!.element)
            ]),
          new HTMLDivElement()
            ..className = 'memberItem'
            ..appendChildren(<HTMLElement>[
              new HTMLDivElement()
                ..className = 'memberName'
                ..textContent = 'all direct instances'
                ..title = 'All instances whose class is exactly this class',
              new HTMLDivElement()
                ..className = 'memberValue'
                ..appendChildren(_createAllInstances())
            ]),
          new HTMLDivElement()
            ..className = 'memberItem'
            ..appendChildren(<HTMLElement>[
              new HTMLDivElement()
                ..className = 'memberName'
                ..textContent = 'all instances of subclasses'
                ..title =
                    'All instances whose class is a subclass of this class',
              new HTMLDivElement()
                ..className = 'memberValue'
                ..appendChildren(_createAllSubclassInstances())
            ]),
          new HTMLDivElement()
            ..className = 'memberItem'
            ..appendChildren(<HTMLElement>[
              new HTMLDivElement()
                ..className = 'memberName'
                ..textContent = 'all instances of implementors'
                ..title =
                    'All instances whose class implements the implicit interface of this class',
              new HTMLDivElement()
                ..className = 'memberValue'
                ..appendChildren(_createAllImplementorInstances())
            ]),
          new HTMLDivElement()
            ..className = 'memberItem'
            ..title = 'Space reachable from this object, '
                'excluding class references'
            ..appendChildren(<HTMLElement>[
              new HTMLDivElement()
                ..className = 'memberName'
                ..textContent = 'Reachable size ',
              new HTMLDivElement()
                ..className = 'memberValue'
                ..appendChildren(_createReachableSizeValue())
            ]),
          new HTMLDivElement()
            ..className = 'memberItem'
            ..title = 'Space that would be reclaimed if references to this '
                'object were replaced with null'
            ..appendChildren(<HTMLElement>[
              new HTMLDivElement()
                ..className = 'memberName'
                ..textContent = 'Retained size ',
              new HTMLDivElement()
                ..className = 'memberValue'
                ..appendChildren(_createRetainedSizeValue())
            ]),
        ])
    ]);
  }

  List<HTMLElement> _createAllInstances() {
    final content = <HTMLElement>[];
    if (_allInstances != null) {
      if (_allInstances!.isSentinel) {
        content.add(new SentinelValueElement(_allInstances!.asSentinel!,
                queue: _r.queue)
            .element);
      } else {
        content.add(anyRef(_isolate, _allInstances!.asValue!, _objects));
      }
    } else {
      content.add(new HTMLSpanElement()..textContent = '...');
    }
    final button = new HTMLButtonElement()
      ..className = 'reachable_size'
      ..disabled = _loadingAllInstances
      ..textContent = '↺';
    button.onClick.listen((_) async {
      button.disabled = true;
      _loadingAllInstances = true;
      _allInstances =
          await _stronglyReachableInstances.getAsArray(_isolate, _cls);
      _loadingAllInstances = false;
      _r.dirty();
    });
    content.add(button);
    return content;
  }

  List<HTMLElement> _createAllSubclassInstances() {
    final content = <HTMLElement>[];
    if (_allSubclassInstances != null) {
      if (_allSubclassInstances!.isSentinel) {
        content.add(new SentinelValueElement(_allSubclassInstances!.asSentinel!,
                queue: _r.queue)
            .element);
      } else {
        content
            .add(anyRef(_isolate, _allSubclassInstances!.asValue!, _objects));
      }
    } else {
      content.add(new HTMLSpanElement()..textContent = '...');
    }
    final button = new HTMLButtonElement()
      ..className = 'reachable_size'
      ..disabled = _loadingAllSubclassInstances
      ..textContent = '↺';
    button.onClick.listen((_) async {
      button.disabled = true;
      _loadingAllSubclassInstances = true;
      _allSubclassInstances = await _stronglyReachableInstances
          .getAsArray(_isolate, _cls, includeSubclasses: true);
      _loadingAllSubclassInstances = false;
      _r.dirty();
    });
    content.add(button);
    return content;
  }

  List<HTMLElement> _createAllImplementorInstances() {
    final content = <HTMLElement>[];
    if (_allImplementorInstances != null) {
      if (_allImplementorInstances!.isSentinel) {
        content.add(new SentinelValueElement(
                _allImplementorInstances!.asSentinel!,
                queue: _r.queue)
            .element);
      } else {
        content.add(
            anyRef(_isolate, _allImplementorInstances!.asValue!, _objects));
      }
    } else {
      content.add(new HTMLSpanElement()..textContent = '...');
    }
    final button = new HTMLButtonElement()
      ..className = 'reachable_size'
      ..disabled = _loadingAllImplementorInstances
      ..textContent = '↺';
    button.onClick.listen((_) async {
      button.disabled = true;
      _loadingAllImplementorInstances = true;
      _allImplementorInstances = await _stronglyReachableInstances
          .getAsArray(_isolate, _cls, includeImplementors: true);
      _loadingAllImplementorInstances = false;
      _r.dirty();
    });
    content.add(button);
    return content;
  }

  List<HTMLElement> _createReachableSizeValue() {
    final content = <HTMLElement>[];
    if (_reachableSize != null) {
      if (_reachableSize!.isSentinel) {
        content.add(new SentinelValueElement(_reachableSize!.asSentinel!,
                queue: _r.queue)
            .element);
      } else {
        content.add(new HTMLSpanElement()
          ..textContent = Utils.formatSize(
              int.parse(_reachableSize!.asValue!.valueAsString!)));
      }
    } else {
      content.add(new HTMLSpanElement()..textContent = '...');
    }
    final button = new HTMLButtonElement()
      ..className = 'reachable_size'
      ..disabled = _loadingReachableBytes
      ..textContent = '↺';
    button.onClick.listen((_) async {
      button.disabled = true;
      _loadingReachableBytes = true;
      _reachableSize = await _reachableSizes.get(_isolate, _cls.id!);
      _loadingReachableBytes = false;
      _r.dirty();
    });
    content.add(button);
    return content;
  }

  List<HTMLElement> _createRetainedSizeValue() {
    final content = <HTMLElement>[];
    if (_retainedSize != null) {
      if (_retainedSize!.isSentinel) {
        content.add(new SentinelValueElement(_retainedSize!.asSentinel!,
                queue: _r.queue)
            .element);
      } else {
        content.add(new HTMLSpanElement()
          ..textContent = Utils.formatSize(
              int.parse(_retainedSize!.asValue!.valueAsString!)));
      }
    } else {
      content.add(new HTMLSpanElement()..textContent = '...');
    }
    final button = new HTMLButtonElement()
      ..className = 'retained_size'
      ..disabled = _loadingRetainedBytes
      ..textContent = '↺';
    button.onClick.listen((_) async {
      button.disabled = true;
      _loadingRetainedBytes = true;
      _retainedSize = await _retainedSizes.get(_isolate, _cls.id!);
      _loadingRetainedBytes = false;
      _r.dirty();
    });
    content.add(button);
    return content;
  }
}
