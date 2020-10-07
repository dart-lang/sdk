// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library instance_view_element;

import 'dart:async';
import 'dart:html';
import 'package:observatory_2/models.dart' as M;
import 'package:observatory_2/src/elements/class_ref.dart';
import 'package:observatory_2/src/elements/context_ref.dart';
import 'package:observatory_2/src/elements/curly_block.dart';
import 'package:observatory_2/src/elements/eval_box.dart';
import 'package:observatory_2/src/elements/field_ref.dart';
import 'package:observatory_2/src/elements/function_ref.dart';
import 'package:observatory_2/src/elements/helpers/any_ref.dart';
import 'package:observatory_2/src/elements/helpers/nav_bar.dart';
import 'package:observatory_2/src/elements/helpers/nav_menu.dart';
import 'package:observatory_2/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory_2/src/elements/helpers/custom_element.dart';
import 'package:observatory_2/src/elements/instance_ref.dart';
import 'package:observatory_2/src/elements/nav/class_menu.dart';
import 'package:observatory_2/src/elements/nav/isolate_menu.dart';
import 'package:observatory_2/src/elements/nav/library_menu.dart';
import 'package:observatory_2/src/elements/nav/notify.dart';
import 'package:observatory_2/src/elements/nav/refresh.dart';
import 'package:observatory_2/src/elements/nav/top_menu.dart';
import 'package:observatory_2/src/elements/nav/vm_menu.dart';
import 'package:observatory_2/src/elements/object_common.dart';
import 'package:observatory_2/src/elements/source_inset.dart';
import 'package:observatory_2/src/elements/source_link.dart';
import 'package:observatory_2/src/elements/view_footer.dart';
import 'package:observatory_2/utils.dart';

class InstanceViewElement extends CustomElement implements Renderable {
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
    children = <Element>[];
  }

  void render() {
    final content = <Element>[
      new HeadingElement.h2()
        ..text = M.isAbstractType(_instance.kind)
            ? 'type ${_instance.name}'
            : 'instance of ${_instance.clazz.name}',
      new HRElement(),
      new ObjectCommonElement(_isolate, _instance, _retainedSizes,
              _reachableSizes, _references, _retainingPaths, _objects,
              queue: _r.queue)
          .element,
      new BRElement(),
      new DivElement()
        ..classes = ['memberList']
        ..children = _createMembers(),
      new HRElement(),
      new EvalBoxElement(_isolate, _instance, _objects, _eval,
              quickExpressions: const ['toString()', 'runtimeType'],
              queue: _r.queue)
          .element
    ];
    if (_location != null) {
      content.addAll([
        new HRElement(),
        new SourceInsetElement(_isolate, _location, _scripts, _objects, _events,
                queue: _r.queue)
            .element
      ]);
    }
    content.addAll(
        [new HRElement(), new ViewFooterElement(queue: _r.queue).element]);
    children = <Element>[
      navBar(_createMenu()),
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = content
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
    }
    menu.addAll(<Element>[
      new NavClassMenuElement(_isolate, _instance.clazz, queue: _r.queue)
          .element,
      navMenu('instance'),
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

  Element memberHalf(String cssClass, dynamic half) {
    var result = new DivElement()..classes = [cssClass];
    if (half is String) {
      result.text = half;
    } else {
      result.children = <Element>[
        anyRef(_isolate, half, _objects, queue: _r.queue)
      ];
    }
    return result;
  }

  Element member(dynamic name, dynamic value) {
    return new DivElement()
      ..classes = ['memberItem']
      ..children = <Element>[
        memberHalf('memberName', name),
        memberHalf('memberValue', value),
      ];
  }

  List<Element> _createMembers() {
    final members = <Element>[];
    if (_instance.valueAsString != null) {
      if (_instance.kind == M.InstanceKind.string) {
        members.add(member(
            'value as literal',
            Utils.formatStringAsLiteral(
                _instance.valueAsString, _instance.valueAsStringIsTruncated)));
      } else {
        members.add(member('value', _instance.valueAsString));
      }
    }
    if (_instance.typeClass != null) {
      members.add(member('type class', _instance.typeClass));
    }
    if (_typeArguments != null && _typeArguments.types.isNotEmpty) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = <Element>[
          new DivElement()
            ..classes = ['memberName']
            ..text = 'type arguments',
          new DivElement()
            ..classes = ['memberValue']
            ..children = ([new SpanElement()..text = '< ']
              ..addAll(_typeArguments.types.expand((type) => [
                    new InstanceRefElement(_isolate, type, _objects,
                            queue: _r.queue)
                        .element,
                    new SpanElement()..text = ', '
                  ]))
              ..removeLast()
              ..add(new SpanElement()..text = ' >'))
        ]);
    }
    if (_instance.parameterizedClass != null) {
      members.add(member('parameterized class', _instance.parameterizedClass));
    }
    if (_instance.parameterIndex != null) {
      members.add(member('parameter index', '${_instance.parameterIndex}'));
    }
    if (_instance.targetType != null) {
      members.add(member('target type', _instance.targetType));
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
    if (_instance.kind == M.InstanceKind.closure) {
      ButtonElement btn;
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = <Element>[
          new DivElement()
            ..classes = ['memberName']
            ..text = 'closure breakpoint',
          new DivElement()
            ..classes = ['memberValue']
            ..children = <Element>[
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
        ..children = <Element>[
          new DivElement()
            ..classes = ['memberName']
            ..text = 'native fields (${_instance.nativeFields.length})',
          new DivElement()
            ..classes = ['memberName']
            ..children = <Element>[
              (new CurlyBlockElement(
                      expanded: _instance.nativeFields.length <= 100,
                      queue: _r.queue)
                    ..content = <Element>[
                      new DivElement()
                        ..classes = ['memberList']
                        ..children = _instance.nativeFields
                            .map<Element>(
                                (f) => member('[ ${i++} ]', '[ ${f.value} ]'))
                            .toList()
                    ])
                  .element
            ]
        ]);
    }

    if (_instance.fields != null && _instance.fields.isNotEmpty) {
      final fields = _instance.fields.toList();
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = <Element>[
          new DivElement()
            ..classes = ['memberName']
            ..text = 'fields (${fields.length})',
          new DivElement()
            ..classes = ['memberName']
            ..children = <Element>[
              (new CurlyBlockElement(
                      expanded: fields.length <= 100, queue: _r.queue)
                    ..content = <Element>[
                      new DivElement()
                        ..classes = ['memberList']
                        ..children = fields
                            .map<Element>((f) => member(f.decl, f.value))
                            .toList()
                    ])
                  .element
            ]
        ]);
    }

    if (_instance.elements != null && _instance.elements.isNotEmpty) {
      final elements = _instance.elements.toList();
      int i = 0;
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = <Element>[
          new DivElement()
            ..classes = ['memberName']
            ..text = 'elements (${_instance.length})',
          new DivElement()
            ..classes = ['memberValue']
            ..children = <Element>[
              (new CurlyBlockElement(
                      expanded: elements.length <= 100, queue: _r.queue)
                    ..content = <Element>[
                      new DivElement()
                        ..classes = ['memberList']
                        ..children = elements
                            .map<Element>(
                                (element) => member('[ ${i++} ]', element))
                            .toList()
                    ])
                  .element
            ]
        ]);
      if (_instance.length != elements.length) {
        members.add(member(
            '...', '${_instance.length - elements.length} omitted elements'));
      }
    }

    if (_instance.associations != null && _instance.associations.isNotEmpty) {
      final associations = _instance.associations.toList();
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = <Element>[
          new DivElement()
            ..classes = ['memberName']
            ..text = 'associations (${_instance.length})',
          new DivElement()
            ..classes = ['memberName']
            ..children = <Element>[
              (new CurlyBlockElement(
                      expanded: associations.length <= 100, queue: _r.queue)
                    ..content = <Element>[
                      new DivElement()
                        ..classes = ['memberList']
                        ..children = associations
                            .map<Element>((a) => new DivElement()
                              ..classes = ['memberItem']
                              ..children = <Element>[
                                new DivElement()
                                  ..classes = ['memberName']
                                  ..children = <Element>[
                                    new SpanElement()..text = '[ ',
                                    anyRef(_isolate, a.key, _objects,
                                        queue: _r.queue),
                                    new SpanElement()..text = ' ]',
                                  ],
                                new DivElement()
                                  ..classes = ['memberValue']
                                  ..children = <Element>[
                                    anyRef(_isolate, a.value, _objects,
                                        queue: _r.queue)
                                  ]
                              ])
                            .toList()
                    ])
                  .element
            ]
        ]);
      if (_instance.length != associations.length) {
        members.add(member('...',
            '${_instance.length - associations.length} omitted elements'));
      }
    }

    if (_instance.typedElements != null && _instance.typedElements.isNotEmpty) {
      final typedElements = _instance.typedElements.toList();
      int i = 0;
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = <Element>[
          new DivElement()
            ..classes = ['memberName']
            ..text = 'elements (${_instance.length})',
          new DivElement()
            ..classes = ['memberValue']
            ..children = <Element>[
              (new CurlyBlockElement(
                      expanded: typedElements.length <= 100, queue: _r.queue)
                    ..content = <Element>[
                      new DivElement()
                        ..classes = ['memberList']
                        ..children = typedElements
                            .map<Element>((e) => member('[ ${i++} ]', '$e'))
                            .toList()
                    ])
                  .element
            ]
        ]);
      if (_instance.length != typedElements.length) {
        members.add(member('...',
            '${_instance.length - typedElements.length} omitted elements'));
      }
    }

    if (_instance.kind == M.InstanceKind.regExp) {
      members.add(member('pattern', _instance.pattern));
      members.add(
          member('isCaseSensitive', _instance.isCaseSensitive ? 'yes' : 'no'));
      members.add(member('isMultiLine', _instance.isMultiLine ? 'yes' : 'no'));
      if (_instance.oneByteFunction != null) {
        members.add(member('oneByteFunction', _instance.oneByteFunction));
      }
      if (_instance.twoByteFunction != null) {
        members.add(member('twoByteFunction', _instance.twoByteFunction));
      }
      if (_instance.externalOneByteFunction != null) {
        members.add(member(
            'externalOneByteFunction', _instance.externalOneByteFunction));
      }
      if (_instance.externalTwoByteFunction != null) {
        members.add(member(
            'externalTwoByteFunction', _instance.externalTwoByteFunction));
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

    if (_instance.kind == M.InstanceKind.weakProperty) {
      members.add(member('key', _instance.key));
      members.add(member('value', _instance.value));
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
