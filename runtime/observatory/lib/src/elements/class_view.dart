// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library class_view_element;

import 'dart:async';

import 'package:web/web.dart';

import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/class_allocation_profile.dart';
import 'package:observatory/src/elements/class_instances.dart';
import 'package:observatory/src/elements/class_ref.dart';
import 'package:observatory/src/elements/curly_block.dart';
import 'package:observatory/src/elements/error_ref.dart';
import 'package:observatory/src/elements/eval_box.dart';
import 'package:observatory/src/elements/field_ref.dart';
import 'package:observatory/src/elements/function_ref.dart';
import 'package:observatory/src/elements/helpers/any_ref.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/element_utils.dart';
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/instance_ref.dart';
import 'package:observatory/src/elements/library_ref.dart';
import 'package:observatory/src/elements/nav/class_menu.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/src/elements/object_common.dart';
import 'package:observatory/src/elements/source_inset.dart';
import 'package:observatory/src/elements/source_link.dart';

class ClassViewElement extends CustomElement implements Renderable {
  late RenderingScheduler<ClassViewElement> _r;

  Stream<RenderedEvent<ClassViewElement>> get onRendered => _r.onRendered;

  late M.VM _vm;
  late M.IsolateRef _isolate;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  late M.Class _cls;
  late M.ClassRepository _classes;
  late M.RetainedSizeRepository _retainedSizes;
  late M.ReachableSizeRepository _reachableSizes;
  late M.InboundReferencesRepository _references;
  late M.RetainingPathRepository _retainingPaths;
  late M.StronglyReachableInstancesRepository _stronglyReachableInstances;
  late M.FieldRepository _fields;
  late M.ScriptRepository _scripts;
  late M.ObjectRepository _objects;
  late M.EvalRepository _eval;
  late M.ClassSampleProfileRepository _profiles;
  Iterable<M.Field>? _classFields;

  M.VMRef get vm => _vm;
  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;
  M.Class get cls => _cls;

  factory ClassViewElement(
      M.VM vm,
      M.IsolateRef isolate,
      M.Class cls,
      M.EventRepository events,
      M.NotificationRepository notifications,
      M.ClassRepository classes,
      M.RetainedSizeRepository retainedSizes,
      M.ReachableSizeRepository reachableSizes,
      M.InboundReferencesRepository references,
      M.RetainingPathRepository retainingPaths,
      M.FieldRepository fields,
      M.ScriptRepository scripts,
      M.ObjectRepository objects,
      M.EvalRepository eval,
      M.StronglyReachableInstancesRepository stronglyReachable,
      M.ClassSampleProfileRepository profiles,
      {RenderingQueue? queue}) {
    ClassViewElement e = new ClassViewElement.created();
    e._r = new RenderingScheduler<ClassViewElement>(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._cls = cls;
    e._classes = classes;
    e._retainedSizes = retainedSizes;
    e._reachableSizes = reachableSizes;
    e._references = references;
    e._retainingPaths = retainingPaths;
    e._fields = fields;
    e._scripts = scripts;
    e._objects = objects;
    e._eval = eval;
    e._stronglyReachableInstances = stronglyReachable;
    e._profiles = profiles;
    return e;
  }

  ClassViewElement.created() : super.created('class-view');

  @override
  attached() {
    super.attached();
    _r.enable();
    _loadAdditionalData();
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    removeChildren();
  }

  ObjectCommonElement? _common;
  ClassInstancesElement? _classInstances;
  bool _loadProfile = false;

  void render() {
    _common = _common ??
        new ObjectCommonElement(_isolate, _cls, _retainedSizes, _reachableSizes,
            _references, _retainingPaths, _objects,
            queue: _r.queue);
    _classInstances = _classInstances ??
        new ClassInstancesElement(_isolate, _cls, _retainedSizes,
            _reachableSizes, _stronglyReachableInstances, _objects,
            queue: _r.queue);
    var header = '';
    if (_cls.isAbstract!) {
      header += 'abstract ';
    }
    if (_cls.isPatch!) {
      header += 'patch ';
    }
    setChildren(<HTMLElement>[
      navBar(<HTMLElement>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue).element,
        new NavClassMenuElement(_isolate, _cls, queue: _r.queue).element,
        (new NavRefreshElement(
                label: 'Refresh Allocation Profile', queue: _r.queue)
              ..onRefresh.listen((e) {
                e.element.disabled = true;
                _loadProfile = true;
                _r.dirty();
              }))
            .element,
        (new NavRefreshElement(queue: _r.queue)
              ..onRefresh.listen((e) {
                e.element.disabled = true;
                _common = null;
                _classInstances = null;
                _fieldsExpanded = null;
                _functionsExpanded = null;
                _refresh();
              }))
            .element,
        new NavNotifyElement(_notifications, queue: _r.queue).element
      ]),
      new HTMLDivElement()
        ..className = 'content-centered-big'
        ..appendChildren(<HTMLElement>[
          new HTMLHeadingElement.h2()
            ..textContent = '$header class ${_cls.name}',
          new HTMLHRElement(),
          _common!.element,
          new HTMLBRElement(),
          new HTMLDivElement()
            ..className = 'memberList'
            ..appendChildren(_createMembers()),
          new HTMLDivElement()
            ..appendChildren(_cls.error == null
                ? const []
                : [
                    new HTMLHRElement(),
                    new ErrorRefElement(_cls.error!, queue: _r.queue).element
                  ]),
          new HTMLHRElement(),
          new EvalBoxElement(_isolate, _cls, _objects, _eval, queue: _r.queue)
              .element,
          new HTMLHRElement(),
          new HTMLHeadingElement.h2()..textContent = 'Fields & Functions',
          new HTMLDivElement()
            ..className = 'memberList'
            ..appendChildren(_createElements()),
          new HTMLHRElement(),
          new HTMLHeadingElement.h2()..textContent = 'Instances',
          new HTMLDivElement()..appendChild(_classInstances!.element),
          new HTMLHRElement(),
          new HTMLHeadingElement.h2()..textContent = 'Allocations',
          new HTMLDivElement()
            ..className = 'memberList'
            ..appendChildren(<HTMLElement>[
              new HTMLDivElement()
                ..className = 'memberName'
                ..textContent = 'Tracing allocations?	',
              new HTMLDivElement()
                ..className = 'memberValue'
                ..appendChildren(_cls.traceAllocations!
                    ? [
                        new HTMLSpanElement()..textContent = 'Yes ',
                        new HTMLButtonElement()
                          ..textContent = 'disable'
                          ..onClick.listen((e) async {
                            (e.target as HTMLButtonElement).disabled = true;
                            await _profiles.disable(_isolate, _cls);
                            _loadProfile = true;
                            _refresh();
                          })
                      ]
                    : [
                        new HTMLSpanElement()..textContent = 'No ',
                        new HTMLButtonElement()
                          ..textContent = 'enable'
                          ..onClick.listen((e) async {
                            (e.target as HTMLButtonElement).disabled = true;
                            await _profiles.enable(_isolate, _cls);
                            _refresh();
                          })
                      ])
            ]),
          new HTMLDivElement()
            ..appendChildren(_loadProfile
                ? [
                    new ClassAllocationProfileElement(
                            _vm, _isolate, _cls, _profiles,
                            queue: _r.queue)
                        .element
                  ]
                : const []),
          new HTMLDivElement()
            ..appendChildren(_cls.location != null
                ? [
                    new HTMLHRElement(),
                    new SourceInsetElement(_isolate, _cls.location!, _scripts,
                            _objects, _events,
                            queue: _r.queue)
                        .element
                  ]
                : const []),
        ])
    ]);
  }

  bool? _fieldsExpanded;
  bool? _functionsExpanded;

  List<HTMLElement> _createMembers() {
    final members = <HTMLElement>[];
    if (_cls.library != null) {
      members.add(new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'library',
          new HTMLDivElement()
            ..className = 'memberValue'
            ..appendChildren(<HTMLElement>[
              new LibraryRefElement(_isolate, _cls.library!, queue: _r.queue)
                  .element
            ])
        ]));
    }
    if (_cls.location != null) {
      members.add(new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'script',
          new HTMLDivElement()
            ..className = 'memberValue'
            ..appendChildren(<HTMLElement>[
              new SourceLinkElement(_isolate, _cls.location!, _scripts,
                      queue: _r.queue)
                  .element
            ])
        ]));
    }
    if (_cls.superclass != null) {
      members.add(new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'superclass',
          new HTMLDivElement()
            ..className = 'memberValue'
            ..appendChildren(<HTMLElement>[
              new ClassRefElement(_isolate, _cls.superclass!, queue: _r.queue)
                  .element
            ])
        ]));
    }
    if (_cls.superType != null) {
      members.add(new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'supertype',
          new HTMLDivElement()
            ..className = 'memberValue'
            ..appendChildren(<HTMLElement>[
              new InstanceRefElement(_isolate, _cls.superType!, _objects,
                      queue: _r.queue)
                  .element
            ])
        ]));
    }
    if (cls.mixin != null) {
      members.add(new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'mixin',
          new HTMLDivElement()
            ..className = 'memberValue'
            ..appendChildren(<HTMLElement>[
              new InstanceRefElement(_isolate, _cls.mixin!, _objects,
                      queue: _r.queue)
                  .element
            ])
        ]));
    }
    if (_cls.subclasses!.length > 0) {
      members.add(new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'extended by',
          new HTMLDivElement()
            ..className = 'memberValue'
            ..appendChildren((_cls.subclasses!.expand((subcls) => <HTMLElement>[
                  new ClassRefElement(_isolate, subcls, queue: _r.queue)
                      .element,
                  new HTMLSpanElement()..textContent = ', '
                ])).toList()
              ..removeLast())
        ]));
    }

    members.add(new HTMLBRElement());

    if (_cls.interfaces!.length > 0) {
      members.add(new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'implements',
          new HTMLDivElement()
            ..className = 'memberValue'
            ..appendChildren((_cls.interfaces!.expand((interf) => <HTMLElement>[
                  new InstanceRefElement(_isolate, interf, _objects,
                          queue: _r.queue)
                      .element,
                  new HTMLSpanElement()..textContent = ', '
                ])).toList()
              ..removeLast())
        ]));
    }
    if (_cls.name != _cls.vmName) {
      members.add(new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'vm name',
          new HTMLDivElement()
            ..className = 'memberValue'
            ..textContent = '${_cls.vmName}'
        ]));
    }
    return members;
  }

  List<HTMLElement> _createElements() {
    final members = <HTMLElement>[];
    if (_classFields != null && _classFields!.isNotEmpty) {
      final fields = _classFields!.toList();
      _fieldsExpanded = _fieldsExpanded ?? (fields.length <= 8);
      members.add(new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'fields ${fields.length}',
          new HTMLDivElement()
            ..className = 'memberValue'
            ..appendChildren(<HTMLElement>[
              (new CurlyBlockElement(expanded: _fieldsExpanded!)
                    ..onToggle
                        .listen((e) => _fieldsExpanded = e.control.expanded)
                    ..content = <HTMLElement>[
                      new HTMLDivElement()
                        ..className = 'memberList'
                        ..appendChildren(
                            fields.map<HTMLElement>((f) => new HTMLDivElement()
                              ..className = 'memberItem'
                              ..appendChildren(<HTMLElement>[
                                new HTMLDivElement()
                                  ..className = 'memberName'
                                  ..appendChildren(<HTMLElement>[
                                    new FieldRefElement(_isolate, f, _objects,
                                            queue: _r.queue)
                                        .element
                                  ]),
                                new HTMLDivElement()
                                  ..className = 'memberValue'
                                  ..appendChildren(f.staticValue == null
                                      ? const []
                                      : [
                                          anyRef(
                                              _isolate, f.staticValue, _objects,
                                              queue: _r.queue)
                                        ])
                              ])))
                    ])
                  .element
            ])
        ]));
    }

    if (_cls.functions!.isNotEmpty) {
      final functions = _cls.functions!.toList();
      _functionsExpanded = _functionsExpanded ?? (functions.length <= 8);
      members.add(new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'functions (${functions.length})',
          new HTMLDivElement()
            ..className = 'memberValue'
            ..appendChild((new CurlyBlockElement(expanded: _functionsExpanded!)
                  ..onToggle
                      .listen((e) => _functionsExpanded = e.control.expanded)
                  ..content = (functions.map<HTMLElement>((f) =>
                      new HTMLDivElement()
                        ..className = 'indent'
                        ..appendChild(
                            new FunctionRefElement(_isolate, f, queue: _r.queue)
                                .element))))
                .element)
        ]));
    }
    return members;
  }

  Future _refresh() async {
    _cls = await _classes.get(_isolate, _cls.id!);
    await _loadAdditionalData();
    _r.dirty();
  }

  Future _loadAdditionalData() async {
    _classFields = await Future.wait(
        _cls.fields!.map((f) => _fields.get(_isolate, f.id!)));
    _r.dirty();
  }
}
