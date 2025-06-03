// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library instance_view_element;

import 'dart:async';

import 'package:web/web.dart';

import '../../models.dart' as M;
import 'curly_block.dart';
import 'eval_box.dart';
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
import '../../utils.dart';

class InstanceViewElement extends CustomElement implements Renderable {
  late RenderingScheduler<InstanceViewElement> _r;

  Stream<RenderedEvent<InstanceViewElement>> get onRendered => _r.onRendered;

  late M.VM _vm;
  late M.IsolateRef _isolate;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  late M.Instance _instance;
  M.LibraryRef? _library;
  late M.ObjectRepository _objects;
  late M.ClassRepository _classes;
  late M.RetainedSizeRepository _retainedSizes;
  late M.ReachableSizeRepository _reachableSizes;
  late M.InboundReferencesRepository _references;
  late M.RetainingPathRepository _retainingPaths;
  late M.ScriptRepository _scripts;
  late M.EvalRepository _eval;
  M.TypeArguments? _typeArguments;
  late M.TypeArgumentsRepository _arguments;
  late M.BreakpointRepository _breakpoints;
  late M.FunctionRepository _functions;
  M.SourceLocation? _location;

  M.VMRef get vm => _vm;
  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;
  M.Instance get instance => _instance;

  factory InstanceViewElement(
    M.VM vm,
    M.IsolateRef isolate,
    M.Instance instance,
    M.EventRepository events,
    M.NotificationRepository notifications,
    M.ObjectRepository objects,
    M.ClassRepository classes,
    M.RetainedSizeRepository retainedSizes,
    M.ReachableSizeRepository reachableSizes,
    M.InboundReferencesRepository references,
    M.RetainingPathRepository retainingPaths,
    M.ScriptRepository scripts,
    M.EvalRepository eval,
    M.TypeArgumentsRepository arguments,
    M.BreakpointRepository breakpoints,
    M.FunctionRepository functions, {
    RenderingQueue? queue,
  }) {
    InstanceViewElement e = new InstanceViewElement.created();
    e._r = new RenderingScheduler<InstanceViewElement>(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._instance = instance;
    e._objects = objects;
    e._classes = classes;
    e._retainedSizes = retainedSizes;
    e._reachableSizes = reachableSizes;
    e._references = references;
    e._retainingPaths = retainingPaths;
    e._scripts = scripts;
    e._eval = eval;
    e._arguments = arguments;
    e._breakpoints = breakpoints;
    e._functions = functions;
    return e;
  }

  InstanceViewElement.created() : super.created('instance-view');

  @override
  attached() {
    super.attached();
    _r.enable();
    _loadExtraData();
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    removeChildren();
  }

  void render() {
    final content = <HTMLElement>[
      new HTMLHeadingElement.h2()
        ..textContent = M.isAbstractType(_instance.kind)
            ? 'type ${_instance.name}'
            : 'instance of ${_instance.clazz!.name}',
      new HTMLHRElement(),
      new ObjectCommonElement(
        _isolate,
        _instance,
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
      new EvalBoxElement(
        _isolate,
        _instance,
        _objects,
        _eval,
        quickExpressions: const ['toString()', 'runtimeType'],
        queue: _r.queue,
      ).element,
    ];
    if (_location != null) {
      content.addAll([
        new HTMLHRElement(),
        new SourceInsetElement(
          _isolate,
          _location!,
          _scripts,
          _objects,
          _events,
          queue: _r.queue,
        ).element,
      ]);
    }
    children = <HTMLElement>[
      navBar(_createMenu()),
      new HTMLDivElement()
        ..className = 'content-centered-big'
        ..appendChildren(content),
    ];
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
    }
    menu.addAll(<HTMLElement>[
      new NavClassMenuElement(
        _isolate,
        _instance.clazz!,
        queue: _r.queue,
      ).element,
      navMenu('instance'),
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

  HTMLElement memberHalf(String cssClass, dynamic half) {
    var result = new HTMLDivElement()..className = cssClass;
    if (half is String) {
      result.textContent = half;
    } else {
      result.setChildren(<HTMLElement>[
        anyRef(_isolate, half, _objects, queue: _r.queue),
      ]);
    }
    return result;
  }

  HTMLElement member(dynamic name, dynamic value) {
    return new HTMLDivElement()
      ..className = 'memberItem'
      ..appendChildren(<HTMLElement>[
        memberHalf('memberName', name),
        memberHalf('memberValue', value),
      ]);
  }

  List<HTMLElement> _createMembers() {
    final members = <HTMLElement>[];
    if (_instance.valueAsString != null) {
      if (_instance.kind == M.InstanceKind.string) {
        members.add(
          member(
            'value as literal',
            Utils.formatStringAsLiteral(
              _instance.valueAsString!,
              _instance.valueAsStringIsTruncated!,
            ),
          ),
        );
      } else {
        members.add(member('value', _instance.valueAsString));
      }
    }
    if (_instance.typeClass != null) {
      members.add(member('type class', _instance.typeClass));
    }
    if (_typeArguments != null && _typeArguments!.types!.isNotEmpty) {
      members.add(
        new HTMLDivElement()
          ..className = 'memberItem'
          ..appendChildren(<HTMLElement>[
            new HTMLDivElement()
              ..className = 'memberName'
              ..textContent = 'type arguments',
            new HTMLDivElement()
              ..className = 'memberValue'
              ..appendChildren(
                ([new HTMLSpanElement()..textContent = '< ']
                  ..addAll(
                    _typeArguments!.types!.expand(
                      (type) => [
                        new InstanceRefElement(
                          _isolate,
                          type,
                          _objects,
                          queue: _r.queue,
                        ).element,
                        new HTMLSpanElement()..textContent = ', ',
                      ],
                    ),
                  )
                  ..removeLast()
                  ..add(new HTMLSpanElement()..textContent = ' >')),
              ),
          ]),
      );
    }
    if (_instance.parameterizedClass != null) {
      members.add(member('parameterized class', _instance.parameterizedClass));
    }
    if (_instance.parameterIndex != null) {
      members.add(member('parameter index', '${_instance.parameterIndex}'));
    }
    if (_instance.bound != null) {
      members.add(member('bound', _instance.bound));
    }
    if (_instance.closureFunction != null) {
      members.add(member('closure function', _instance.closureFunction));
    }
    if (_instance.closureContext != null) {
      members.add(member('closure context', _instance.closureContext));
    }
    if (_instance.closureReceiver != null) {
      members.add(member('closure receiver', _instance.closureReceiver));
    }
    if (_instance.kind == M.InstanceKind.closure) {
      late HTMLButtonElement btn;
      members.add(
        new HTMLDivElement()
          ..className = 'memberItem'
          ..appendChildren(<HTMLElement>[
            new HTMLDivElement()
              ..className = 'memberName'
              ..textContent = 'closure breakpoint',
            new HTMLDivElement()
              ..className = 'memberValue'
              ..appendChildren(<HTMLElement>[
                btn = new HTMLButtonElement()
                  ..textContent = _instance.activationBreakpoint == null
                      ? 'break on activation'
                      : 'remove'
                  ..onClick.listen((_) {
                    btn.disabled = true;
                    _toggleBreakpoint();
                  }),
              ]),
          ]),
      );
    }

    if (_instance.nativeFields != null && _instance.nativeFields!.isNotEmpty) {
      int i = 0;
      members.add(
        new HTMLDivElement()
          ..className = 'memberItem'
          ..appendChildren(<HTMLElement>[
            new HTMLDivElement()
              ..className = 'memberName'
              ..textContent =
                  'native fields (${_instance.nativeFields!.length})',
            new HTMLDivElement()
              ..className = 'memberName'
              ..appendChildren(<HTMLElement>[
                (new CurlyBlockElement(
                        expanded: _instance.nativeFields!.length <= 100,
                        queue: _r.queue,
                      )
                      ..content = <HTMLElement>[
                        new HTMLDivElement()
                          ..className = 'memberList'
                          ..appendChildren(
                            _instance.nativeFields!.map<HTMLElement>(
                              (f) => member('[ ${i++} ]', '[ ${f.value} ]'),
                            ),
                          ),
                      ])
                    .element,
              ]),
          ]),
      );
    }

    if (_instance.fields != null && _instance.fields!.isNotEmpty) {
      final fields = _instance.fields!.toList();
      members.add(
        new HTMLDivElement()
          ..className = 'memberItem'
          ..appendChildren(<HTMLElement>[
            new HTMLDivElement()
              ..className = 'memberName'
              ..textContent = 'fields (${fields.length})',
            new HTMLDivElement()
              ..className = 'memberName'
              ..appendChildren(<HTMLElement>[
                (new CurlyBlockElement(
                        expanded: fields.length <= 100,
                        queue: _r.queue,
                      )
                      ..content = <HTMLElement>[
                        new HTMLDivElement()
                          ..className = 'memberList'
                          ..appendChildren(
                            fields.map<HTMLElement>((f) {
                              final name =
                                  _instance.kind == M.InstanceKind.record
                                  ? f.name
                                  : f.decl;
                              return member(name, f.value);
                            }),
                          ),
                      ])
                    .element,
              ]),
          ]),
      );
    }

    if (_instance.elements != null && _instance.elements!.isNotEmpty) {
      final elements = _instance.elements!.toList();
      int i = 0;
      members.add(
        new HTMLDivElement()
          ..className = 'memberItem'
          ..appendChildren(<HTMLElement>[
            new HTMLDivElement()
              ..className = 'memberName'
              ..textContent = 'elements (${_instance.length})',
            new HTMLDivElement()
              ..className = 'memberValue'
              ..appendChildren(<HTMLElement>[
                (new CurlyBlockElement(
                        expanded: elements.length <= 100,
                        queue: _r.queue,
                      )
                      ..content = <HTMLElement>[
                        new HTMLDivElement()
                          ..className = 'memberList'
                          ..appendChildren(
                            elements.map<HTMLElement>(
                              (element) => member('[ ${i++} ]', element),
                            ),
                          ),
                      ])
                    .element,
              ]),
          ]),
      );
      if (_instance.length != elements.length) {
        members.add(
          member(
            '...',
            '${_instance.length! - elements.length} omitted elements',
          ),
        );
      }
    }

    if (_instance.associations != null && _instance.associations!.isNotEmpty) {
      final associations = _instance.associations!.toList();
      members.add(
        new HTMLDivElement()
          ..className = 'memberItem'
          ..appendChildren(<HTMLElement>[
            new HTMLDivElement()
              ..className = 'memberName'
              ..textContent = 'associations (${_instance.length})',
            new HTMLDivElement()
              ..className = 'memberName'
              ..appendChildren(<HTMLElement>[
                (new CurlyBlockElement(
                        expanded: associations.length <= 100,
                        queue: _r.queue,
                      )
                      ..content = <HTMLElement>[
                        new HTMLDivElement()
                          ..className = 'memberList'
                          ..appendChildren(
                            associations.map<HTMLElement>(
                              (a) => new HTMLDivElement()
                                ..className = 'memberItem'
                                ..appendChildren(<HTMLElement>[
                                  new HTMLDivElement()
                                    ..className = 'memberName'
                                    ..appendChildren(<HTMLElement>[
                                      new HTMLSpanElement()..textContent = '[ ',
                                      anyRef(
                                        _isolate,
                                        a.key,
                                        _objects,
                                        queue: _r.queue,
                                      ),
                                      new HTMLSpanElement()..textContent = ' ]',
                                    ]),
                                  new HTMLDivElement()
                                    ..className = 'memberValue'
                                    ..appendChildren(<HTMLElement>[
                                      anyRef(
                                        _isolate,
                                        a.value,
                                        _objects,
                                        queue: _r.queue,
                                      ),
                                    ]),
                                ]),
                            ),
                          ),
                      ])
                    .element,
              ]),
          ]),
      );
      if (_instance.length != associations.length) {
        members.add(
          member(
            '...',
            '${_instance.length! - associations.length} omitted elements',
          ),
        );
      }
    }

    if (_instance.typedElements != null &&
        _instance.typedElements!.isNotEmpty) {
      final typedElements = _instance.typedElements!.toList();
      int i = 0;
      members.add(
        new HTMLDivElement()
          ..className = 'memberItem'
          ..appendChildren(<HTMLElement>[
            new HTMLDivElement()
              ..className = 'memberName'
              ..textContent = 'elements (${_instance.length})',
            new HTMLDivElement()
              ..className = 'memberValue'
              ..appendChildren(<HTMLElement>[
                (new CurlyBlockElement(
                        expanded: typedElements.length <= 100,
                        queue: _r.queue,
                      )
                      ..content = <HTMLElement>[
                        new HTMLDivElement()
                          ..className = 'memberList'
                          ..appendChildren(
                            typedElements.map<HTMLElement>(
                              (e) => member('[ ${i++} ]', '$e'),
                            ),
                          ),
                      ])
                    .element,
              ]),
          ]),
      );
      if (_instance.length != typedElements.length) {
        members.add(
          member(
            '...',
            '${_instance.length! - typedElements.length} omitted elements',
          ),
        );
      }
    }

    if (_instance.kind == M.InstanceKind.regExp) {
      members.add(member('pattern', _instance.pattern));
      members.add(
        member('isCaseSensitive', _instance.isCaseSensitive! ? 'yes' : 'no'),
      );
      members.add(member('isMultiLine', _instance.isMultiLine! ? 'yes' : 'no'));
      if (_instance.oneByteFunction != null) {
        members.add(member('oneByteFunction', _instance.oneByteFunction));
      }
      if (_instance.twoByteFunction != null) {
        members.add(member('twoByteFunction', _instance.twoByteFunction));
      }
      if (_instance.oneByteBytecode != null) {
        members.add(member('oneByteBytecode', _instance.oneByteBytecode));
      }
      if (_instance.twoByteBytecode != null) {
        members.add(member('twoByteBytecode', _instance.twoByteBytecode));
      }
    }

    if (_instance.kind == M.InstanceKind.mirrorReference) {
      members.add(member('referent', _instance.referent));
    }

    if (_instance.kind == M.InstanceKind.weakReference) {
      members.add(member('target', _instance.target));
    }

    if (_instance.kind == M.InstanceKind.weakProperty) {
      members.add(member('key', _instance.key));
      members.add(member('value', _instance.value));
    }

    if (_instance.kind == M.InstanceKind.finalizer) {
      members.add(member('callback', _instance.callback));
      members.add(member('allEntries', _instance.allEntries));
    }

    if (_instance.kind == M.InstanceKind.nativeFinalizer) {
      members.add(member('callback', _instance.allEntries));
    }

    if (_instance.kind == M.InstanceKind.finalizerEntry) {
      members.add(member('value', _instance.value));
      members.add(member('detach', _instance.detach));
      members.add(member('token', _instance.token));
    }

    return members;
  }

  Future _refresh() async {
    _instance = await _objects.get(_isolate, _instance.id!) as M.Instance;
    await _loadExtraData();
    _r.dirty();
  }

  Future _loadExtraData() async {
    _library = (await _classes.get(_isolate, _instance.clazz!.id!)).library!;
    if (_instance.typeArguments != null) {
      _typeArguments = await _arguments.get(
        _isolate,
        _instance.typeArguments!.id!,
      );
    } else {
      _typeArguments = null;
    }
    if (_instance.closureFunction != null) {
      _location = (await _functions.get(
        _isolate,
        _instance.closureFunction!.id!,
      )).location;
    } else if (_instance.typeClass != null) {
      _location = (await _classes.get(
        _isolate,
        _instance.typeClass!.id!,
      )).location;
    }
    _r.dirty();
  }

  Future _toggleBreakpoint() async {
    if (_instance.activationBreakpoint == null) {
      await _breakpoints.addOnActivation(_isolate, _instance);
    } else {
      await _breakpoints.remove(_isolate, _instance.activationBreakpoint!);
    }
    await _refresh();
  }
}
