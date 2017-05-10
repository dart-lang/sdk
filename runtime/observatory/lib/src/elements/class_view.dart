// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library class_view_element;

import 'dart:async';
import 'dart:html';
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
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
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
import 'package:observatory/src/elements/view_footer.dart';

class ClassViewElement extends HtmlElement implements Renderable {
  static const tag =
      const Tag<ClassViewElement>('class-view', dependencies: const [
    ClassInstancesElement.tag,
    ClassRefElement.tag,
    CurlyBlockElement.tag,
    ErrorRefElement.tag,
    EvalBoxElement.tag,
    FieldRefElement.tag,
    FunctionRefElement.tag,
    InstanceRefElement.tag,
    LibraryRefElement.tag,
    NavClassMenuElement.tag,
    NavTopMenuElement.tag,
    NavVMMenuElement.tag,
    NavIsolateMenuElement.tag,
    NavRefreshElement.tag,
    NavNotifyElement.tag,
    ObjectCommonElement.tag,
    SourceInsetElement.tag,
    SourceLinkElement.tag,
    ViewFooterElement.tag
  ]);

  RenderingScheduler<ClassViewElement> _r;

  Stream<RenderedEvent<ClassViewElement>> get onRendered => _r.onRendered;

  M.VM _vm;
  M.IsolateRef _isolate;
  M.EventRepository _events;
  M.NotificationRepository _notifications;
  M.Class _cls;
  M.ClassRepository _classes;
  M.RetainedSizeRepository _retainedSizes;
  M.ReachableSizeRepository _reachableSizes;
  M.InboundReferencesRepository _references;
  M.RetainingPathRepository _retainingPaths;
  M.StronglyReachableInstancesRepository _stronglyReachableInstances;
  M.TopRetainingInstancesRepository _topRetainedInstances;
  M.FieldRepository _fields;
  M.ScriptRepository _scripts;
  M.ObjectRepository _objects;
  M.EvalRepository _eval;
  M.ClassSampleProfileRepository _profiles;
  Iterable<M.Field> _classFields;

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
      M.TopRetainingInstancesRepository topRetained,
      M.ClassSampleProfileRepository profiles,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(isolate != null);
    assert(events != null);
    assert(notifications != null);
    assert(cls != null);
    assert(classes != null);
    assert(retainedSizes != null);
    assert(reachableSizes != null);
    assert(references != null);
    assert(retainingPaths != null);
    assert(fields != null);
    assert(scripts != null);
    assert(objects != null);
    assert(eval != null);
    assert(stronglyReachable != null);
    assert(topRetained != null);
    assert(profiles != null);
    ClassViewElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
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
    e._topRetainedInstances = topRetained;
    e._profiles = profiles;
    return e;
  }

  ClassViewElement.created() : super.created();

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
    children = [];
  }

  ObjectCommonElement _common;
  ClassInstancesElement _classInstances;
  bool _loadProfile = false;

  void render() {
    _common = _common ??
        new ObjectCommonElement(_isolate, _cls, _retainedSizes, _reachableSizes,
            _references, _retainingPaths, _objects,
            queue: _r.queue);
    _classInstances = _classInstances ??
        new ClassInstancesElement(
            _isolate,
            _cls,
            _retainedSizes,
            _reachableSizes,
            _stronglyReachableInstances,
            _topRetainedInstances,
            _objects,
            queue: _r.queue);
    var header = '';
    if (_cls.isAbstract) {
      header += 'abstract ';
    }
    if (_cls.isPatch) {
      header += 'patch ';
    }
    children = [
      navBar([
        new NavTopMenuElement(queue: _r.queue),
        new NavVMMenuElement(_vm, _events, queue: _r.queue),
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue),
        new NavClassMenuElement(_isolate, _cls, queue: _r.queue),
        new NavRefreshElement(
            label: 'Refresh Allocation Profile', queue: _r.queue)
          ..onRefresh.listen((e) {
            e.element.disabled = true;
            _loadProfile = true;
            _r.dirty();
          }),
        new NavRefreshElement(queue: _r.queue)
          ..onRefresh.listen((e) {
            e.element.disabled = true;
            _common = null;
            _classInstances = null;
            _fieldsExpanded = null;
            _functionsExpanded = null;
            _refresh();
          }),
        new NavNotifyElement(_notifications, queue: _r.queue)
      ]),
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = [
          new HeadingElement.h2()..text = '$header class ${_cls.name}',
          new HRElement(),
          _common,
          new BRElement(),
          new DivElement()
            ..classes = ['memberList']
            ..children = _createMembers(),
          new DivElement()
            ..children = _cls.error == null
                ? const []
                : [
                    new HRElement(),
                    new ErrorRefElement(_cls.error, queue: _r.queue)
                  ],
          new HRElement(),
          new EvalBoxElement(_isolate, _cls, _objects, _eval, queue: _r.queue),
          new HRElement(),
          new HeadingElement.h2()..text = 'Fields & Functions',
          new DivElement()
            ..classes = ['memberList']
            ..children = _createElements(),
          new HRElement(),
          new HeadingElement.h2()..text = 'Instances',
          new DivElement()
            ..children = _cls.hasAllocations ? [_classInstances] : const [],
          new HRElement(),
          new HeadingElement.h2()..text = 'Allocations',
          new DivElement()
            ..classes = ['memberList']
            ..children = [
              new DivElement()
                ..classes = ['memberName']
                ..text = 'Tracing allocations?	',
              new DivElement()
                ..classes = ['memberValue']
                ..children = _cls.traceAllocations
                    ? [
                        new SpanElement()..text = 'Yes ',
                        new ButtonElement()
                          ..text = 'disable'
                          ..onClick.listen((e) async {
                            e.target.disabled = true;
                            await _profiles.disable(_isolate, _cls);
                            _loadProfile = true;
                            _refresh();
                          })
                      ]
                    : [
                        new SpanElement()..text = 'No ',
                        new ButtonElement()
                          ..text = 'enable'
                          ..onClick.listen((e) async {
                            e.target.disabled = true;
                            await _profiles.enable(_isolate, _cls);
                            _refresh();
                          })
                      ]
            ],
          new DivElement()
            ..children = _loadProfile
                ? [
                    new ClassAllocationProfileElement(_isolate, _cls, _profiles,
                        queue: _r.queue)
                  ]
                : const [],
          new DivElement()
            ..children = _cls.location != null
                ? [
                    new HRElement(),
                    new SourceInsetElement(
                        _isolate, _cls.location, _scripts, _objects, _events,
                        queue: _r.queue)
                  ]
                : const [],
          new HRElement(),
          new ViewFooterElement(queue: _r.queue)
        ]
    ];
  }

  bool _fieldsExpanded;
  bool _functionsExpanded;

  List<Element> _createMembers() {
    final members = <Element>[];
    if (_cls.library != null) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'library',
          new DivElement()
            ..classes = ['memberValue']
            ..children = [
              new LibraryRefElement(_isolate, _cls.library, queue: _r.queue)
            ]
        ]);
    }
    if (_cls.location != null) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'script',
          new DivElement()
            ..classes = ['memberValue']
            ..children = [
              new SourceLinkElement(_isolate, _cls.location, _scripts,
                  queue: _r.queue)
            ]
        ]);
    }
    if (_cls.superclass != null) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'superclass',
          new DivElement()
            ..classes = ['memberValue']
            ..children = [
              new ClassRefElement(_isolate, _cls.superclass, queue: _r.queue)
            ]
        ]);
    }
    if (_cls.superType != null) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'supertype',
          new DivElement()
            ..classes = ['memberValue']
            ..children = [
              new InstanceRefElement(_isolate, _cls.superType, _objects,
                  queue: _r.queue)
            ]
        ]);
    }
    if (cls.mixin != null) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'mixin',
          new DivElement()
            ..classes = ['memberValue']
            ..children = [
              new InstanceRefElement(_isolate, _cls.mixin, _objects,
                  queue: _r.queue)
            ]
        ]);
    }
    if (_cls.subclasses.length > 0) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'extended by',
          new DivElement()
            ..classes = ['memberValue']
            ..children = (_cls.subclasses
                .expand((subcls) => [
                      new ClassRefElement(_isolate, subcls, queue: _r.queue),
                      new SpanElement()..text = ', '
                    ])
                .toList()
                  ..removeLast())
        ]);
    }

    members.add(new BRElement());

    if (_cls.interfaces.length > 0) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'implements',
          new DivElement()
            ..classes = ['memberValue']
            ..children = (_cls.interfaces
                .expand((interf) => [
                      new InstanceRefElement(_isolate, interf, _objects,
                          queue: _r.queue),
                      new SpanElement()..text = ', '
                    ])
                .toList()
                  ..removeLast())
        ]);
    }
    if (_cls.name != _cls.vmName) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'vm name',
          new DivElement()
            ..classes = ['memberValue']
            ..text = '${_cls.vmName}'
        ]);
    }
    return members;
  }

  List<Element> _createElements() {
    final members = <Element>[];
    if (_classFields != null && _classFields.isNotEmpty) {
      final fields = _classFields.toList();
      _fieldsExpanded = _fieldsExpanded ?? (fields.length <= 8);
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'fields ${fields.length}',
          new DivElement()
            ..classes = ['memberValue']
            ..children = [
              new CurlyBlockElement(expanded: _fieldsExpanded)
                ..onToggle.listen((e) => _fieldsExpanded = e.control.expanded)
                ..content = [
                  new DivElement()
                    ..classes = ['memberList']
                    ..children = (fields
                        .map((f) => new DivElement()
                          ..classes = ['memberItem']
                          ..children = [
                            new DivElement()
                              ..classes = ['memberName']
                              ..children = [
                                new FieldRefElement(_isolate, f, _objects,
                                    queue: _r.queue)
                              ],
                            new DivElement()
                              ..classes = ['memberValue']
                              ..children = f.staticValue == null
                                  ? const []
                                  : [
                                      anyRef(_isolate, f.staticValue, _objects,
                                          queue: _r.queue)
                                    ]
                          ])
                        .toList())
                ]
            ]
        ]);
    }

    if (_cls.functions.isNotEmpty) {
      final functions = _cls.functions.toList();
      _functionsExpanded = _functionsExpanded ?? (functions.length <= 8);
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'functions (${functions.length})',
          new DivElement()
            ..classes = ['memberValue']
            ..children = [
              new CurlyBlockElement(expanded: _functionsExpanded)
                ..onToggle
                    .listen((e) => _functionsExpanded = e.control.expanded)
                ..content = (functions
                    .map((f) => new DivElement()
                      ..classes = ['indent']
                      ..children = [
                        new FunctionRefElement(_isolate, f, queue: _r.queue)
                      ])
                    .toList())
            ]
        ]);
    }
    return members;
  }

  Future _refresh() async {
    _cls = await _classes.get(_isolate, _cls.id);
    await _loadAdditionalData();
    _r.dirty();
  }

  Future _loadAdditionalData() async {
    _classFields =
        await Future.wait(_cls.fields.map((f) => _fields.get(_isolate, f.id)));
    _r.dirty();
  }
}
