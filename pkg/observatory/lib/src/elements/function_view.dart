// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library function_view_element;

import 'dart:async';

import 'package:web/web.dart';

import '../../models.dart' as M;
import 'code_ref.dart';
import 'field_ref.dart';
import 'helpers/any_ref.dart';
import 'helpers/custom_element.dart';
import 'helpers/element_utils.dart';
import 'helpers/nav_bar.dart';
import 'helpers/nav_menu.dart';
import 'helpers/rendering_scheduler.dart';
import 'instance_ref.dart';
import 'nav/class_menu.dart';
import 'nav/isolate_menu.dart';
import 'nav/library_menu.dart';
import 'nav/notify.dart';
import 'nav/refresh.dart';
import 'nav/top_menu.dart';
import 'nav/vm_menu.dart';
import 'object_common.dart';
import 'source_inset.dart';
import 'source_link.dart';

class FunctionViewElement extends CustomElement implements Renderable {
  late RenderingScheduler<FunctionViewElement> _r;

  Stream<RenderedEvent<FunctionViewElement>> get onRendered => _r.onRendered;

  late M.VM _vm;
  late M.IsolateRef _isolate;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  late M.ServiceFunction _function;
  M.LibraryRef? _library;
  late M.FunctionRepository _functions;
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
  M.ServiceFunction get function => _function;

  factory FunctionViewElement(
    M.VM vm,
    M.IsolateRef isolate,
    M.ServiceFunction function,
    M.EventRepository events,
    M.NotificationRepository notifications,
    M.FunctionRepository functions,
    M.ClassRepository classes,
    M.RetainedSizeRepository retainedSizes,
    M.ReachableSizeRepository reachableSizes,
    M.InboundReferencesRepository references,
    M.RetainingPathRepository retainingPaths,
    M.ScriptRepository scripts,
    M.ObjectRepository objects, {
    RenderingQueue? queue,
  }) {
    FunctionViewElement e = new FunctionViewElement.created();
    e._r = new RenderingScheduler<FunctionViewElement>(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._function = function;
    e._functions = functions;
    e._classes = classes;
    e._retainedSizes = retainedSizes;
    e._reachableSizes = reachableSizes;
    e._references = references;
    e._retainingPaths = retainingPaths;
    e._scripts = scripts;
    e._objects = objects;
    if (function.dartOwner is M.LibraryRef) {
      e._library = function.dartOwner as M.LibraryRef;
    }
    return e;
  }

  FunctionViewElement.created() : super.created('function-view');

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
    setChildren(<HTMLElement>[
      navBar(_createMenu()),
      new HTMLDivElement()
        ..className = 'content-centered-big'
        ..appendChildren(<HTMLElement>[
          new HTMLHeadingElement.h2()
            ..textContent = 'Function ${_function.name}',
          new HTMLHRElement(),
          new ObjectCommonElement(
            _isolate,
            _function,
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
            _function.location == null
                ? const []
                : [
                    new SourceInsetElement(
                      _isolate,
                      _function.location!,
                      _scripts,
                      _objects,
                      _events,
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
    } else if (_function.dartOwner is M.ClassRef) {
      menu.add(
        new NavClassMenuElement(
          _isolate,
          _function.dartOwner as M.ClassRef,
          queue: _r.queue,
        ).element,
      );
    }
    menu.addAll(<HTMLElement>[
      navMenu(_function.name!),
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
            ..textContent = 'kind',
          new HTMLDivElement()
            ..className = 'memberName'
            ..appendChildren(<HTMLElement>[
              new HTMLSpanElement()
                ..textContent =
                    '${_function.isStatic! ? "static " : ""}'
                    '${_function.isConst! ? "const " : ""}'
                    '${_functionKindToString(_function.kind)}',
            ]),
        ]),
      new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'owner',
          new HTMLDivElement()
            ..className = 'memberName'
            ..appendChildren(<HTMLElement>[
              _function.dartOwner == null
                  ? (new HTMLSpanElement()..textContent = '...')
                  : anyRef(
                      _isolate,
                      _function.dartOwner,
                      _objects,
                      queue: _r.queue,
                    ),
            ]),
        ]),
    ];
    if (_function.field != null) {
      members.add(
        new HTMLDivElement()
          ..className = 'memberItem'
          ..appendChildren(<HTMLElement>[
            new HTMLDivElement()
              ..className = 'memberName'
              ..textContent = 'script',
            new HTMLDivElement()
              ..className = 'memberName'
              ..appendChildren(<HTMLElement>[
                new FieldRefElement(
                  _isolate,
                  _function.field!,
                  _objects,
                  queue: _r.queue,
                ).element,
              ]),
          ]),
      );
    }
    members.add(
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
                _function.location!,
                _scripts,
                queue: _r.queue,
              ).element,
            ]),
        ]),
    );
    if (_function.code != null) {
      members.add(
        new HTMLDivElement()
          ..className = 'memberItem'
          ..appendChildren(<HTMLElement>[
            new HTMLDivElement()
              ..className = 'memberName'
              ..textContent = 'current code',
            new HTMLDivElement()
              ..className = 'memberName'
              ..appendChildren(<HTMLElement>[
                new CodeRefElement(
                  _isolate,
                  _function.code!,
                  queue: _r.queue,
                ).element,
              ]),
          ]),
      );
    }
    if (_function.unoptimizedCode != null) {
      members.add(
        new HTMLDivElement()
          ..className = 'memberItem'
          ..appendChildren(<HTMLElement>[
            new HTMLDivElement()
              ..className = 'memberName'
              ..textContent = 'unoptimized code',
            new HTMLDivElement()
              ..className = 'memberName'
              ..appendChildren(<HTMLElement>[
                new CodeRefElement(
                  _isolate,
                  _function.unoptimizedCode!,
                  queue: _r.queue,
                ).element,
                new HTMLSpanElement()
                  ..title =
                      'This count is used to determine when a function '
                      'will be optimized.  It is a combination of call '
                      'counts and other factors.'
                  ..textContent = ' (usage count: ${function.usageCounter})',
              ]),
          ]),
      );
    }
    members.add(
      new HTMLDivElement()
        ..className = 'memberItem'
        ..textContent = ' ',
    );

    if (_function.icDataArray != null) {
      members.add(
        new HTMLDivElement()
          ..className = 'memberItem'
          ..appendChildren(<HTMLElement>[
            new HTMLDivElement()
              ..className = 'memberName'
              ..textContent = 'ic data array',
            new HTMLDivElement()
              ..className = 'memberName'
              ..appendChildren(<HTMLElement>[
                new InstanceRefElement(
                  _isolate,
                  _function.icDataArray!,
                  _objects,
                  queue: _r.queue,
                ).element,
              ]),
          ]),
      );
    }

    members.addAll([
      new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'deoptimizations',
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = '${_function.deoptimizations}',
        ]),
      new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'optimizable',
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = _function.isOptimizable! ? 'yes' : 'no',
        ]),
      new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'inlinable',
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = _function.isInlinable! ? 'yes' : 'no',
        ]),
      new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'intrinsic',
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = _function.hasIntrinsic! ? 'yes' : 'no',
        ]),
      new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'recognized',
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = _function.isRecognized! ? 'yes' : 'no',
        ]),
      new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'native',
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = _function.isNative! ? 'yes' : 'no',
        ]),
      new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'vm name',
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = _function.vmName ?? '',
        ]),
    ]);
    return members;
  }

  Future _refresh() async {
    _function = await _functions.get(_isolate, _function.id!);
    if (_function.dartOwner is M.LibraryRef) {
      _library = _function.dartOwner as M.LibraryRef;
    } else if (_function.dartOwner is M.ClassRef) {
      var cls = _function.dartOwner as M.ClassRef;
      _library = (await _classes.get(_isolate, cls.id!)).library!;
    }
    _r.dirty();
  }

  static String _functionKindToString(M.FunctionKind? kind) {
    switch (kind) {
      case M.FunctionKind.regular:
        return 'regular';
      case M.FunctionKind.closure:
        return 'closure';
      case M.FunctionKind.implicitClosure:
        return 'implicit closure';
      case M.FunctionKind.getter:
        return 'getter';
      case M.FunctionKind.setter:
        return 'setter';
      case M.FunctionKind.constructor:
        return 'constructor';
      case M.FunctionKind.implicitGetter:
        return 'implicit getter';
      case M.FunctionKind.implicitSetter:
        return 'implicit setter';
      case M.FunctionKind.implicitStaticGetter:
        return 'implicit static getter';
      case M.FunctionKind.fieldInitializer:
        return 'field initializer';
      case M.FunctionKind.irregexpFunction:
        return 'irregexp function';
      case M.FunctionKind.methodExtractor:
        return 'method extractor';
      case M.FunctionKind.noSuchMethodDispatcher:
        return 'noSuchMethod dispatcher';
      case M.FunctionKind.invokeFieldDispatcher:
        return 'invokeField dispatcher';
      case M.FunctionKind.collected:
        return 'collected';
      case M.FunctionKind.native:
        return 'native';
      case M.FunctionKind.ffiTrampoline:
        return 'ffi trampoline';
      case M.FunctionKind.stub:
        return 'stub';
      case M.FunctionKind.tag:
        return 'tag';
      case M.FunctionKind.dynamicInvocationForwarder:
        return 'dynamic invocation forwarder';
      case M.FunctionKind.recordFieldGetter:
        return 'record field getter';
      default:
        throw new Exception('Unknown Functionkind ($kind)');
    }
  }
}
