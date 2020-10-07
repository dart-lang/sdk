// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library field_view_element;

import 'dart:async';
import 'dart:html';
import 'package:observatory_2/models.dart' as M;
import 'package:observatory_2/src/elements/class_ref.dart';
import 'package:observatory_2/src/elements/curly_block.dart';
import 'package:observatory_2/src/elements/helpers/any_ref.dart';
import 'package:observatory_2/src/elements/helpers/nav_bar.dart';
import 'package:observatory_2/src/elements/helpers/nav_menu.dart';
import 'package:observatory_2/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory_2/src/elements/helpers/custom_element.dart';
import 'package:observatory_2/src/elements/nav/class_menu.dart';
import 'package:observatory_2/src/elements/nav/isolate_menu.dart';
import 'package:observatory_2/src/elements/nav/library_menu.dart';
import 'package:observatory_2/src/elements/nav/notify.dart';
import 'package:observatory_2/src/elements/nav/refresh.dart';
import 'package:observatory_2/src/elements/nav/top_menu.dart';
import 'package:observatory_2/src/elements/nav/vm_menu.dart';
import 'package:observatory_2/src/elements/object_common.dart';
import 'package:observatory_2/src/elements/script_inset.dart';
import 'package:observatory_2/src/elements/source_link.dart';
import 'package:observatory_2/src/elements/view_footer.dart';

class FieldViewElement extends CustomElement implements Renderable {
  RenderingScheduler<FieldViewElement> _r;

  Stream<RenderedEvent<FieldViewElement>> get onRendered => _r.onRendered;

  M.VM _vm;
  M.IsolateRef _isolate;
  M.EventRepository _events;
  M.NotificationRepository _notifications;
  M.Field _field;
  M.LibraryRef _library;
  M.FieldRepository _fields;
  M.ClassRepository _classes;
  M.RetainedSizeRepository _retainedSizes;
  M.ReachableSizeRepository _reachableSizes;
  M.InboundReferencesRepository _references;
  M.RetainingPathRepository _retainingPaths;
  M.ScriptRepository _scripts;
  M.ObjectRepository _objects;

  M.VMRef get vm => _vm;
  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;
  M.Field get field => _field;

  factory FieldViewElement(
      M.VM vm,
      M.IsolateRef isolate,
      M.Field field,
      M.EventRepository events,
      M.NotificationRepository notifications,
      M.FieldRepository fields,
      M.ClassRepository classes,
      M.RetainedSizeRepository retainedSizes,
      M.ReachableSizeRepository reachableSizes,
      M.InboundReferencesRepository references,
      M.RetainingPathRepository retainingPaths,
      M.ScriptRepository scripts,
      M.ObjectRepository objects,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(isolate != null);
    assert(events != null);
    assert(notifications != null);
    assert(field != null);
    assert(fields != null);
    assert(classes != null);
    assert(retainedSizes != null);
    assert(reachableSizes != null);
    assert(references != null);
    assert(retainingPaths != null);
    assert(scripts != null);
    assert(objects != null);
    FieldViewElement e = new FieldViewElement.created();
    e._r = new RenderingScheduler<FieldViewElement>(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._field = field;
    e._fields = fields;
    e._classes = classes;
    e._retainedSizes = retainedSizes;
    e._reachableSizes = reachableSizes;
    e._references = references;
    e._retainingPaths = retainingPaths;
    e._scripts = scripts;
    e._objects = objects;
    if (field.dartOwner is M.LibraryRef) {
      e._library = field.dartOwner;
    }
    return e;
  }

  FieldViewElement.created() : super.created('field-view');

  @override
  attached() {
    super.attached();
    _r.enable();
    _refresh();
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    children = <Element>[];
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
    }
    if (_field.declaredType.name == 'dynamic') {
      header += 'var';
    } else {
      header += _field.declaredType.name;
    }
    children = <Element>[
      navBar(_createMenu()),
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = <Element>[
          new HeadingElement.h2()..text = '$header ${field.name}',
          new HRElement(),
          new ObjectCommonElement(_isolate, _field, _retainedSizes,
                  _reachableSizes, _references, _retainingPaths, _objects,
                  queue: _r.queue)
              .element,
          new BRElement(),
          new DivElement()
            ..classes = ['memberList']
            ..children = _createMembers(),
          new HRElement(),
          new DivElement()
            ..children = _field.location == null
                ? const []
                : [
                    new ScriptInsetElement(_isolate, _field.location.script,
                            _scripts, _objects, _events,
                            startPos: field.location.tokenPos,
                            endPos: field.location.tokenPos,
                            queue: _r.queue)
                        .element
                  ],
          new ViewFooterElement(queue: _r.queue).element
        ]
    ];
  }

  List<Element> _createMenu() {
    final menu = <Element>[
      new NavTopMenuElement(queue: _r.queue).element,
      new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
      new NavIsolateMenuElement(_isolate, _events, queue: _r.queue).element
    ];
    if (_library != null) {
      menu.add(new NavLibraryMenuElement(_isolate, _library, queue: _r.queue)
          .element);
    } else if (_field.dartOwner is M.ClassRef) {
      menu.add(
          new NavClassMenuElement(_isolate, _field.dartOwner, queue: _r.queue)
              .element);
    }
    menu.addAll(<Element>[
      navMenu(_field.name),
      (new NavRefreshElement(queue: _r.queue)
            ..onRefresh.listen((e) {
              e.element.disabled = true;
              _refresh();
            }))
          .element,
      new NavNotifyElement(_notifications, queue: _r.queue).element
    ]);
    return menu;
  }

  List<Element> _createMembers() {
    final members = <Element>[
      new DivElement()
        ..classes = ['memberItem']
        ..children = <Element>[
          new DivElement()
            ..classes = ['memberName']
            ..text = 'owner',
          new DivElement()
            ..classes = ['memberName']
            ..children = <Element>[
              _field.dartOwner == null
                  ? (new SpanElement()..text = '...')
                  : anyRef(_isolate, _field.dartOwner, _objects,
                      queue: _r.queue)
            ]
        ],
      new DivElement()
        ..classes = ['memberItem']
        ..children = <Element>[
          new DivElement()
            ..classes = ['memberName']
            ..text = 'script',
          new DivElement()
            ..classes = ['memberName']
            ..children = <Element>[
              new SourceLinkElement(_isolate, field.location, _scripts,
                      queue: _r.queue)
                  .element
            ]
        ]
    ];
    if (!_field.isStatic) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..title = 'The types observed for this field at runtime. '
            'Fields that are observed to have a single type at runtime '
            'or to never be null may allow for additional optimization.'
        ..children = <Element>[
          new DivElement()
            ..classes = ['memberName']
            ..text = 'observed types',
          new DivElement()
            ..classes = ['memberName']
            ..children = _createGuard()
        ]);
    }
    if (_field.staticValue != null) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = <Element>[
          new DivElement()
            ..classes = ['memberName']
            ..text = 'static value',
          new DivElement()
            ..classes = ['memberName']
            ..children = <Element>[
              anyRef(_isolate, _field.staticValue, _objects, queue: _r.queue)
            ]
        ]);
    }
    return members;
  }

  List<Element> _createGuard() {
    final guard = <Element>[];
    switch (_field.guardClassKind) {
      case M.GuardClassKind.unknown:
        guard.add(new SpanElement()..text = 'none');
        break;
      case M.GuardClassKind.dynamic:
        guard.add(new SpanElement()..text = 'various');
        break;
      case M.GuardClassKind.single:
        guard.add(
            new ClassRefElement(_isolate, _field.guardClass, queue: _r.queue)
                .element);
        break;
    }
    guard.add(new SpanElement()
      ..text =
          _field.guardNullable ? '— null observed' : '— null not observed');
    return guard;
  }

  Future _refresh() async {
    _field = await _fields.get(_isolate, _field.id);
    if (_field.dartOwner is M.LibraryRef) {
      _library = _field.dartOwner;
    } else if (_field.dartOwner is M.ClassRef) {
      _library = (await _classes.get(_isolate, _field.dartOwner.id)).library;
    }
    _r.dirty();
  }
}
