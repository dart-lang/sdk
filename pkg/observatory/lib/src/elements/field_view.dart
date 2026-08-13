// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library field_view_element;

import 'dart:async';

import 'package:web/web.dart';

import '../../models.dart' as M;
import 'class_ref.dart';
import 'helpers/any_ref.dart';
import 'helpers/custom_element.dart';
import 'helpers/element_utils.dart';
import 'helpers/nav_bar.dart';
import 'helpers/nav_menu.dart';
import 'helpers/rendering_scheduler.dart';
import 'nav/class_menu.dart';
import 'nav/isolate_menu.dart';
import 'nav/library_menu.dart';
import 'nav/notify.dart';
import 'nav/refresh.dart';
import 'nav/top_menu.dart';
import 'nav/vm_menu.dart';
import 'object_common.dart';
import 'script_inset.dart';
import 'source_link.dart';

class FieldViewElement extends CustomElement implements Renderable {
  late RenderingScheduler<FieldViewElement> _r;

  Stream<RenderedEvent<FieldViewElement>> get onRendered => _r.onRendered;

  late M.VM _vm;
  late M.IsolateRef _isolate;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  late M.Field _field;
  M.LibraryRef? _library;
  late M.FieldRepository _fields;
  late M.ClassRepository _classes;
  late M.RetainedSizeRepository _retainedSizes;
  late M.ReachableSizeRepository _reachableSizes;
  late M.InboundReferencesRepository _references;
  late M.RetainingPathRepository _retainingPaths;
  late M.ScriptRepository _scripts;
  late M.ObjectRepository _objects;

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
    M.ObjectRepository objects, {
    RenderingQueue? queue,
  }) {
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
      e._library = field.dartOwner as M.LibraryRef;
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
    removeChildren();
  }

  void render() {
    var header = '';
    if (_field.isStatic!) {
      if (_field.dartOwner is M.ClassRef) {
        header += 'static ';
      } else {
        header += 'top-level ';
      }
    }
    if (_field.isFinal!) {
      header += 'final ';
    } else if (_field.isConst!) {
      header += 'const ';
    }
    if (_field.declaredType!.name == 'dynamic') {
      header += 'var';
    } else {
      header += _field.declaredType!.name!;
    }
    setChildren(<HTMLElement>[
      navBar(_createMenu()),
      new HTMLDivElement()
        ..className = 'content-centered-big'
        ..appendChildren(<HTMLElement>[
          new HTMLHeadingElement.h2()..textContent = '$header ${field.name}',
          new HTMLHRElement(),
          new ObjectCommonElement(
            _isolate,
            _field,
            _retainedSizes,
            _reachableSizes,
            _references,
            _retainingPaths,
            _objects,
            queue: _r.queue,
          ).element,
          new HTMLBRElement(),
          new HTMLDivElement()
            ..className = 'memberList'
            ..appendChildren(_createMembers()),
          new HTMLHRElement(),
          new HTMLDivElement()..appendChildren(
            _field.location == null
                ? const []
                : [
                    new ScriptInsetElement(
                      _isolate,
                      _field.location!.script!,
                      _scripts,
                      _objects,
                      _events,
                      startPos: field.location!.tokenPos,
                      endPos: field.location!.tokenPos,
                      queue: _r.queue,
                    ).element,
                  ],
          ),
        ]),
    ]);
  }

  List<HTMLElement> _createMenu() {
    final menu = <HTMLElement>[
      new NavTopMenuElement(queue: _r.queue).element,
      new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
      new NavIsolateMenuElement(_isolate, _events, queue: _r.queue).element,
    ];
    if (_library != null) {
      menu.add(
        new NavLibraryMenuElement(_isolate, _library!, queue: _r.queue).element,
      );
    } else if (_field.dartOwner is M.ClassRef) {
      menu.add(
        new NavClassMenuElement(
          _isolate,
          _field.dartOwner as M.ClassRef,
          queue: _r.queue,
        ).element,
      );
    }
    menu.addAll(<HTMLElement>[
      navMenu(_field.name!),
      (new NavRefreshElement(queue: _r.queue)
            ..onRefresh.listen((e) {
              e.element.disabled = true;
              _refresh();
            }))
          .element,
      new NavNotifyElement(_notifications, queue: _r.queue).element,
    ]);
    return menu;
  }

  List<HTMLElement> _createMembers() {
    final members = <HTMLElement>[
      new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'owner',
          new HTMLDivElement()
            ..className = 'memberName'
            ..appendChildren(<HTMLElement>[
              _field.dartOwner == null
                  ? (new HTMLSpanElement()..textContent = '...')
                  : anyRef(
                      _isolate,
                      _field.dartOwner,
                      _objects,
                      queue: _r.queue,
                    ),
            ]),
        ]),
      new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'script',
          new HTMLDivElement()
            ..className = 'memberName'
            ..appendChildren(<HTMLElement>[
              new SourceLinkElement(
                _isolate,
                field.location!,
                _scripts,
                queue: _r.queue,
              ).element,
            ]),
        ]),
    ];
    if (!_field.isStatic!) {
      members.add(
        new HTMLDivElement()
          ..className = 'memberItem'
          ..title =
              'The types observed for this field at runtime. '
              'Fields that are observed to have a single type at runtime '
              'or to never be null may allow for additional optimization.'
          ..appendChildren(<HTMLElement>[
            new HTMLDivElement()
              ..className = 'memberName'
              ..textContent = 'observed types',
            new HTMLDivElement()
              ..className = 'memberName'
              ..appendChildren(_createGuard()),
          ]),
      );
    }
    if (_field.staticValue != null) {
      members.add(
        new HTMLDivElement()
          ..className = 'memberItem'
          ..appendChildren(<HTMLElement>[
            new HTMLDivElement()
              ..className = 'memberName'
              ..textContent = 'static value',
            new HTMLDivElement()
              ..className = 'memberName'
              ..appendChildren(<HTMLElement>[
                anyRef(_isolate, _field.staticValue, _objects, queue: _r.queue),
              ]),
          ]),
      );
    }
    return members;
  }

  List<HTMLElement> _createGuard() {
    final guard = <HTMLElement>[];
    switch (_field.guardClassKind!) {
      case M.GuardClassKind.unknown:
        guard.add(new HTMLSpanElement()..textContent = 'none');
        break;
      case M.GuardClassKind.dynamic:
        guard.add(new HTMLSpanElement()..textContent = 'various');
        break;
      case M.GuardClassKind.single:
        guard.add(
          new ClassRefElement(
            _isolate,
            _field.guardClass!,
            queue: _r.queue,
          ).element,
        );
        break;
    }
    guard.add(
      new HTMLSpanElement()
        ..textContent = _field.guardNullable!
            ? '— null observed'
            : '— null not observed',
    );
    return guard;
  }

  Future _refresh() async {
    _field = await _fields.get(_isolate, _field.id!);
    if (_field.dartOwner is M.LibraryRef) {
      _library = _field.dartOwner as M.LibraryRef;
    } else if (_field.dartOwner is M.ClassRef) {
      var cls = _field.dartOwner as M.ClassRef;
      _library = (await _classes.get(_isolate, cls.id!)).library!;
    }
    _r.dirty();
  }
}
