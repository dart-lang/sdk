// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library instance_view_element;

import 'dart:async';
import 'dart:html';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/class_ref.dart';
import 'package:observatory/src/elements/context_ref.dart';
import 'package:observatory/src/elements/curly_block.dart';
import 'package:observatory/src/elements/eval_box.dart';
import 'package:observatory/src/elements/field_ref.dart';
import 'package:observatory/src/elements/function_ref.dart';
import 'package:observatory/src/elements/helpers/any_ref.dart';
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/instance_ref.dart';
import 'package:observatory/src/elements/nav/class_menu.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';
import 'package:observatory/src/elements/nav/library_menu.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/src/elements/object_common.dart';
import 'package:observatory/src/elements/source_inset.dart';
import 'package:observatory/src/elements/source_link.dart';
import 'package:observatory/src/elements/view_footer.dart';
import 'package:observatory/utils.dart';

class InstanceViewElement extends HtmlElement implements Renderable {
  static const tag =
      const Tag<InstanceViewElement>('instance-view', dependencies: const [
    ClassRefElement.tag,
    ContextRefElement.tag,
    CurlyBlockElement.tag,
    FieldRefElement.tag,
    FunctionRefElement.tag,
    InstanceRefElement.tag,
    NavClassMenuElement.tag,
    NavLibraryMenuElement.tag,
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

  RenderingScheduler<InstanceViewElement> _r;

  Stream<RenderedEvent<InstanceViewElement>> get onRendered => _r.onRendered;

  M.VM _vm;
  M.IsolateRef _isolate;
  M.EventRepository _events;
  M.NotificationRepository _notifications;
  M.Instance _instance;
  M.LibraryRef _library;
  M.ObjectRepository _objects;
  M.ClassRepository _classes;
  M.RetainedSizeRepository _retainedSizes;
  M.ReachableSizeRepository _reachableSizes;
  M.InboundReferencesRepository _references;
  M.RetainingPathRepository _retainingPaths;
  M.ScriptRepository _scripts;
  M.EvalRepository _eval;
  M.TypeArguments _typeArguments;
  M.TypeArgumentsRepository _arguments;
  M.BreakpointRepository _breakpoints;
  M.FunctionRepository _functions;
  M.SourceLocation _location;

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
      M.FunctionRepository functions,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(isolate != null);
    assert(events != null);
    assert(notifications != null);
    assert(instance != null);
    assert(objects != null);
    assert(classes != null);
    assert(retainedSizes != null);
    assert(reachableSizes != null);
    assert(references != null);
    assert(retainingPaths != null);
    assert(scripts != null);
    assert(eval != null);
    assert(arguments != null);
    assert(breakpoints != null);
    assert(functions != null);
    InstanceViewElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
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

  InstanceViewElement.created() : super.created();

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
    children = [];
  }

  void render() {
    final content = [
      new HeadingElement.h2()
        ..text = M.isAbstractType(_instance.kind)
            ? 'type ${_instance.name}'
            : 'instance of ${_instance.clazz.name}',
      new HRElement(),
      new ObjectCommonElement(_isolate, _instance, _retainedSizes,
          _reachableSizes, _references, _retainingPaths, _objects,
          queue: _r.queue),
      new BRElement(),
      new DivElement()
        ..classes = ['memberList']
        ..children = _createMembers(),
      new HRElement(),
      new EvalBoxElement(_isolate, _instance, _objects, _eval,
          quickExpressions: const ['toString()', 'runtimeType'],
          queue: _r.queue)
    ];
    if (_location != null) {
      content.addAll([
        new HRElement(),
        new SourceInsetElement(_isolate, _location, _scripts, _objects, _events,
            queue: _r.queue)
      ]);
    }
    content.addAll([new HRElement(), new ViewFooterElement(queue: _r.queue)]);
    children = [
      navBar(_createMenu()),
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = content
    ];
  }

  List<Element> _createMenu() {
    final menu = [
      new NavTopMenuElement(queue: _r.queue),
      new NavVMMenuElement(_vm, _events, queue: _r.queue),
      new NavIsolateMenuElement(_isolate, _events, queue: _r.queue)
    ];
    if (_library != null) {
      menu.add(new NavLibraryMenuElement(_isolate, _library, queue: _r.queue));
    }
    menu.addAll([
      new NavClassMenuElement(_isolate, _instance.clazz, queue: _r.queue),
      navMenu('instance'),
      new NavRefreshElement(queue: _r.queue)
        ..onRefresh.listen((e) {
          e.element.disabled = true;
          _refresh();
        }),
      new NavNotifyElement(_notifications, queue: _r.queue)
    ]);
    return menu;
  }

  List<Element> _createMembers() {
    final members = <Element>[];
    if (_instance.valueAsString != null) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = _instance.kind == M.InstanceKind.string
                ? 'value as literal'
                : 'value',
          new DivElement()
            ..classes = ['memberValue']
            ..text = _instance.kind == M.InstanceKind.string
                ? Utils.formatStringAsLiteral(
                    _instance.valueAsString, _instance.valueAsStringIsTruncated)
                : _instance.valueAsString
        ]);
    }
    if (_instance.typeClass != null) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'type class',
          new DivElement()
            ..classes = ['memberValue']
            ..children = [
              new ClassRefElement(_isolate, _instance.typeClass,
                  queue: _r.queue)
            ]
        ]);
    }
    if (_typeArguments != null && _typeArguments.types.isNotEmpty) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'type arguments',
          new DivElement()
            ..classes = ['memberValue']
            ..children = ([new SpanElement()..text = '< ']
              ..addAll(_typeArguments.types.expand((type) => [
                    new InstanceRefElement(_isolate, type, _objects,
                        queue: _r.queue),
                    new SpanElement()..text = ', '
                  ]))
              ..removeLast()
              ..add(new SpanElement()..text = ' >'))
        ]);
    }
    if (_instance.parameterizedClass != null) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'parameterized class',
          new DivElement()
            ..classes = ['memberValue']
            ..children = [
              new ClassRefElement(_isolate, _instance.parameterizedClass,
                  queue: _r.queue)
            ]
        ]);
    }
    if (_instance.parameterIndex != null) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'parameter index',
          new DivElement()
            ..classes = ['memberValue']
            ..text = '${_instance.parameterIndex}'
        ]);
    }
    if (_instance.targetType != null) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'target type',
          new DivElement()
            ..classes = ['memberValue']
            ..children = [
              new InstanceRefElement(_isolate, _instance.targetType, _objects,
                  queue: _r.queue)
            ]
        ]);
    }
    if (_instance.bound != null) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'bound',
          new DivElement()
            ..classes = ['memberValue']
            ..children = [
              new InstanceRefElement(_isolate, _instance.bound, _objects,
                  queue: _r.queue)
            ]
        ]);
    }
    if (_instance.closureFunction != null) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'closure function',
          new DivElement()
            ..classes = ['memberValue']
            ..children = [
              new FunctionRefElement(_isolate, _instance.closureFunction,
                  queue: _r.queue)
            ]
        ]);
    }
    if (_instance.closureContext != null) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'closure context',
          new DivElement()
            ..classes = ['memberValue']
            ..children = [
              new ContextRefElement(
                  _isolate, _instance.closureContext, _objects,
                  queue: _r.queue)
            ]
        ]);
    }
    if (_instance.kind == M.InstanceKind.closure) {
      ButtonElement btn;
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'closure breakpoint',
          new DivElement()
            ..classes = ['memberValue']
            ..children = [
              btn = new ButtonElement()
                ..text = _instance.activationBreakpoint == null
                    ? 'break on activation'
                    : 'remove'
                ..onClick.listen((_) {
                  btn.disabled = true;
                  _toggleBreakpoint();
                })
            ]
        ]);
    }

    if (_instance.nativeFields != null && _instance.nativeFields.isNotEmpty) {
      int i = 0;
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'native fields (${_instance.nativeFields.length})',
          new DivElement()
            ..classes = ['memberName']
            ..children = [
              new CurlyBlockElement(
                  expanded: _instance.nativeFields.length <= 100,
                  queue: _r.queue)
                ..content = [
                  new DivElement()
                    ..classes = ['memberList']
                    ..children = _instance.nativeFields
                        .map((f) => new DivElement()
                          ..classes = ['memberItem']
                          ..children = [
                            new DivElement()
                              ..classes = ['memberName']
                              ..text = '[ ${i++} ]',
                            new DivElement()
                              ..classes = ['memberValue']
                              ..text = '[ ${f.value} ]'
                          ])
                        .toList()
                ]
            ]
        ]);
    }

    if (_instance.fields != null && _instance.fields.isNotEmpty) {
      final fields = _instance.fields.toList();
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'fields (${fields.length})',
          new DivElement()
            ..classes = ['memberName']
            ..children = [
              new CurlyBlockElement(
                  expanded: fields.length <= 100, queue: _r.queue)
                ..content = [
                  new DivElement()
                    ..classes = ['memberList']
                    ..children = fields
                        .map((f) => new DivElement()
                          ..classes = ['memberItem']
                          ..children = [
                            new DivElement()
                              ..classes = ['memberName']
                              ..children = [
                                new FieldRefElement(_isolate, f.decl, _objects,
                                    queue: _r.queue)
                              ],
                            new DivElement()
                              ..classes = ['memberValue']
                              ..children = [
                                new SpanElement()..text = ' = ',
                                anyRef(_isolate, f.value, _objects,
                                    queue: _r.queue)
                              ]
                          ])
                        .toList()
                ]
            ]
        ]);
    }

    if (_instance.elements != null && _instance.elements.isNotEmpty) {
      final elements = _instance.elements.toList();
      int i = 0;
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'elements (${_instance.length})',
          new DivElement()
            ..classes = ['memberValue']
            ..children = [
              new CurlyBlockElement(
                  expanded: elements.length <= 100, queue: _r.queue)
                ..content = [
                  new DivElement()
                    ..classes = ['memberList']
                    ..children = elements
                        .map((element) => new DivElement()
                          ..classes = ['memberItem']
                          ..children = [
                            new DivElement()
                              ..classes = ['memberName']
                              ..text = '[ ${i++} ]',
                            new DivElement()
                              ..classes = ['memberValue']
                              ..children = [
                                anyRef(_isolate, element, _objects,
                                    queue: _r.queue)
                              ]
                          ])
                        .toList()
                ]
            ]
        ]);
      if (_instance.length != elements.length) {
        members.add(new DivElement()
          ..classes = ['memberItem']
          ..children = [
            new DivElement()
              ..classes = ['memberName']
              ..text = '...',
            new DivElement()
              ..classes = ['memberValue']
              ..text = '${_instance.length - elements.length} omitted elements'
          ]);
      }
    }

    if (_instance.associations != null && _instance.associations.isNotEmpty) {
      final associations = _instance.associations.toList();
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'associations (${_instance.length})',
          new DivElement()
            ..classes = ['memberName']
            ..children = [
              new CurlyBlockElement(
                  expanded: associations.length <= 100, queue: _r.queue)
                ..content = [
                  new DivElement()
                    ..classes = ['memberList']
                    ..children = associations
                        .map((a) => new DivElement()
                          ..classes = ['memberItem']
                          ..children = [
                            new DivElement()
                              ..classes = ['memberName']
                              ..children = [
                                new SpanElement()..text = '[ ',
                                anyRef(_isolate, a.key, _objects,
                                    queue: _r.queue),
                                new SpanElement()..text = ' ]',
                              ],
                            new DivElement()
                              ..classes = ['memberValue']
                              ..children = [
                                anyRef(_isolate, a.value, _objects,
                                    queue: _r.queue)
                              ]
                          ])
                        .toList()
                ]
            ]
        ]);
      if (_instance.length != associations.length) {
        members.add(new DivElement()
          ..classes = ['memberItem']
          ..children = [
            new DivElement()
              ..classes = ['memberName']
              ..text = '...',
            new DivElement()
              ..classes = ['memberValue']
              ..text = '${_instance.length - associations.length} '
                  'omitted elements'
          ]);
      }
    }

    if (_instance.typedElements != null && _instance.typedElements.isNotEmpty) {
      final typedElements = _instance.typedElements.toList();
      int i = 0;
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'elements (${_instance.length})',
          new DivElement()
            ..classes = ['memberValue']
            ..children = [
              new CurlyBlockElement(
                  expanded: typedElements.length <= 100, queue: _r.queue)
                ..content = [
                  new DivElement()
                    ..classes = ['memberList']
                    ..children = typedElements
                        .map((e) => new DivElement()
                          ..classes = ['memberItem']
                          ..children = [
                            new DivElement()
                              ..classes = ['memberName']
                              ..text = '[ ${i++} ]',
                            new DivElement()
                              ..classes = ['memberValue']
                              ..text = '$e'
                          ])
                        .toList()
                ]
            ]
        ]);
      if (_instance.length != typedElements.length) {
        members.add(new DivElement()
          ..classes = ['memberItem']
          ..children = [
            new DivElement()
              ..classes = ['memberName']
              ..text = '...',
            new DivElement()
              ..classes = ['memberValue']
              ..text = '${_instance.length - typedElements.length} '
                  'omitted elements'
          ]);
      }
    }

    if (_instance.kind == M.InstanceKind.regExp) {
      members.addAll([
        new DivElement()
          ..classes = ['memberItem']
          ..children = [
            new DivElement()
              ..classes = ['memberName']
              ..text = 'pattern',
            new DivElement()
              ..classes = ['memberValue']
              ..children = [
                anyRef(_isolate, _instance.pattern, _objects, queue: _r.queue)
              ]
          ],
        new DivElement()
          ..classes = ['memberItem']
          ..children = [
            new DivElement()
              ..classes = ['memberName']
              ..text = 'isCaseSensitive',
            new DivElement()
              ..classes = ['memberValue']
              ..text = _instance.isCaseSensitive ? 'yes' : 'no'
          ],
        new DivElement()
          ..classes = ['memberItem']
          ..children = [
            new DivElement()
              ..classes = ['memberName']
              ..text = 'isMultiLine',
            new DivElement()
              ..classes = ['memberValue']
              ..text = _instance.isMultiLine ? 'yes' : 'no'
          ],
        new DivElement()
          ..classes = ['memberItem']
          ..children = [
            new DivElement()
              ..classes = ['memberName']
              ..text = 'oneByteFunction',
            new DivElement()
              ..classes = ['memberValue']
              ..children = [
                new FunctionRefElement(_isolate, _instance.oneByteFunction,
                    queue: _r.queue)
              ]
          ],
        new DivElement()
          ..classes = ['memberItem']
          ..children = [
            new DivElement()
              ..classes = ['memberName']
              ..text = 'twoByteFunction',
            new DivElement()
              ..classes = ['memberValue']
              ..children = [
                new FunctionRefElement(_isolate, _instance.twoByteFunction,
                    queue: _r.queue)
              ]
          ],
        new DivElement()
          ..classes = ['memberItem']
          ..children = [
            new DivElement()
              ..classes = ['memberName']
              ..text = 'externalOneByteFunction',
            new DivElement()
              ..classes = ['memberValue']
              ..children = [
                new FunctionRefElement(
                    _isolate, _instance.externalOneByteFunction,
                    queue: _r.queue)
              ]
          ],
        new DivElement()
          ..classes = ['memberItem']
          ..children = [
            new DivElement()
              ..classes = ['memberName']
              ..text = 'externalTwoByteFunction',
            new DivElement()
              ..classes = ['memberValue']
              ..children = [
                new FunctionRefElement(
                    _isolate, _instance.externalTwoByteFunction,
                    queue: _r.queue)
              ]
          ],
        new DivElement()
          ..classes = ['memberItem']
          ..children = [
            new DivElement()
              ..classes = ['memberName']
              ..text = 'oneByteBytecode',
            new DivElement()
              ..classes = ['memberValue']
              ..children = [
                new InstanceRefElement(
                    _isolate, _instance.oneByteBytecode, _objects,
                    queue: _r.queue)
              ]
          ],
        new DivElement()
          ..classes = ['memberItem']
          ..children = [
            new DivElement()
              ..classes = ['memberName']
              ..text = 'twoByteBytecode',
            new DivElement()
              ..classes = ['memberValue']
              ..children = [
                new InstanceRefElement(
                    _isolate, _instance.twoByteBytecode, _objects,
                    queue: _r.queue)
              ]
          ]
      ]);
    }

    if (_instance.kind == M.InstanceKind.mirrorReference) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'referent',
          new DivElement()
            ..classes = ['memberValue']
            ..children = [
              anyRef(_isolate, _instance.referent, _objects, queue: _r.queue)
            ]
        ]);
    }
    if (_instance.kind == M.InstanceKind.weakProperty) {
      members.addAll([
        new DivElement()
          ..classes = ['memberItem']
          ..children = [
            new DivElement()
              ..classes = ['memberName']
              ..text = 'key',
            new DivElement()
              ..classes = ['memberValue']
              ..children = [
                new InstanceRefElement(_isolate, _instance.key, _objects,
                    queue: _r.queue),
              ]
          ],
        new DivElement()
          ..classes = ['memberItem']
          ..children = [
            new DivElement()
              ..classes = ['memberName']
              ..text = 'value',
            new DivElement()
              ..classes = ['memberValue']
              ..children = [
                new InstanceRefElement(_isolate, _instance.value, _objects,
                    queue: _r.queue),
              ]
          ]
      ]);
    }
    return members;
  }

  Future _refresh() async {
    _instance = await _objects.get(_isolate, _instance.id);
    await _loadExtraData();
    _r.dirty();
  }

  Future _loadExtraData() async {
    _library = (await _classes.get(_isolate, _instance.clazz.id)).library;
    if (_instance.typeArguments != null) {
      _typeArguments =
          await _arguments.get(_isolate, _instance.typeArguments.id);
    } else {
      _typeArguments = null;
    }
    if (_instance.closureFunction != null) {
      _location = (await _functions.get(_isolate, _instance.closureFunction.id))
          .location;
    } else if (_instance.typeClass != null) {
      _location =
          (await _classes.get(_isolate, _instance.typeClass.id)).location;
    }
    _r.dirty();
  }

  Future _toggleBreakpoint() async {
    if (_instance.activationBreakpoint == null) {
      await _breakpoints.addOnActivation(_isolate, _instance);
    } else {
      await _breakpoints.remove(_isolate, _instance.activationBreakpoint);
    }
    await _refresh();
  }
}
