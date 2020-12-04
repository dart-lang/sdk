// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library class_tree_element;

import 'dart:html';
import 'dart:async';
import 'package:observatory_2/models.dart' as M;
import 'package:observatory_2/src/elements/class_ref.dart';
import 'package:observatory_2/src/elements/containers/virtual_tree.dart';
import 'package:observatory_2/src/elements/helpers/nav_bar.dart';
import 'package:observatory_2/src/elements/helpers/nav_menu.dart';
import 'package:observatory_2/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory_2/src/elements/helpers/custom_element.dart';
import 'package:observatory_2/src/elements/nav/isolate_menu.dart';
import 'package:observatory_2/src/elements/nav/notify.dart';
import 'package:observatory_2/src/elements/nav/top_menu.dart';
import 'package:observatory_2/src/elements/nav/vm_menu.dart';

class ClassTreeElement extends CustomElement implements Renderable {
  RenderingScheduler<ClassTreeElement> _r;

  Stream<RenderedEvent<ClassTreeElement>> get onRendered => _r.onRendered;

  M.VMRef _vm;
  M.IsolateRef _isolate;
  M.EventRepository _events;
  M.NotificationRepository _notifications;
  M.ClassRepository _classes;
  M.Class _object;
  final _subclasses = <String, Iterable<M.Class>>{};
  final _mixins = <String, List<M.Instance>>{};

  factory ClassTreeElement(
      M.VMRef vm,
      M.IsolateRef isolate,
      M.EventRepository events,
      M.NotificationRepository notifications,
      M.ClassRepository classes,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(isolate != null);
    assert(events != null);
    assert(notifications != null);
    assert(classes != null);
    ClassTreeElement e = new ClassTreeElement.created();
    e._r = new RenderingScheduler<ClassTreeElement>(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._classes = classes;
    return e;
  }

  ClassTreeElement.created() : super.created('class-tree');

  @override
  void attached() {
    super.attached();
    _refresh();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    children = <Element>[];
    _r.disable(notify: true);
  }

  VirtualTreeElement _tree;

  void render() {
    children = <Element>[
      navBar(<Element>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue).element,
        navMenu('class hierarchy'),
        new NavNotifyElement(_notifications, queue: _r.queue).element
      ]),
      new DivElement()
        ..classes = ['content-centered']
        ..children = <Element>[
          new HeadingElement.h1()
            ..text = 'Class Hierarchy (${_subclasses.length})',
          new BRElement(),
          new HRElement(),
          _object == null
              ? (new HeadingElement.h2()..text = 'Loading...')
              : _createTree()
        ]
    ];
  }

  Element _createTree() {
    _tree = new VirtualTreeElement(_create, _update, _children,
        items: [_object], search: _search, queue: _r.queue);
    _tree.expand(_object, autoExpandSingleChildNodes: true);
    return _tree.element;
  }

  Future _refresh() async {
    _object = null;
    _subclasses.clear();
    _mixins.clear();
    _object = await _register(await _classes.getObject(_isolate));
    _r.dirty();
  }

  Future<M.Class> _register(M.Class cls) async {
    _subclasses[cls.id] = await Future.wait(
        (await Future.wait(cls.subclasses.map(_getActualChildrens)))
            .expand((f) => f)
            .map(_register));
    return cls;
  }

  Future<Iterable<M.Class>> _getActualChildrens(M.ClassRef ref) async {
    var cls = await _classes.get(_isolate, ref.id);
    if (cls.isPatch) {
      return const [];
    }
    if (cls.mixin == null) {
      return [cls];
    }
    return (await Future.wait(cls.subclasses.map(_getActualChildrens)))
        .expand((f) => f)
          ..forEach((subcls) {
            _mixins[subcls.id] = (_mixins[subcls.id] ?? [])..add(cls.mixin);
          });
  }

  static HtmlElement _create(toggle) {
    return new DivElement()
      ..classes = ['class-tree-item']
      ..children = <Element>[
        new SpanElement()..classes = ['lines'],
        new ButtonElement()
          ..classes = ['expander']
          ..onClick.listen((_) => toggle(autoToggleSingleChildNodes: true)),
        new SpanElement()..classes = ['name']
      ];
  }

  void _update(HtmlElement el, classDynamic, int index) {
    M.Class cls = classDynamic;
    virtualTreeUpdateLines(el.children[0], index);
    if (cls.subclasses.isEmpty) {
      el.children[1].text = '';
    } else {
      el.children[1].text = _tree.isExpanded(cls) ? '▼' : '►';
    }
    el.children[2].children = <Element>[
      new ClassRefElement(_isolate, cls, queue: _r.queue).element
    ];
    if (_mixins[cls.id] != null) {
      el.children[2].children.addAll(_createMixins(_mixins[cls.id]));
    }
  }

  bool _search(Pattern pattern, classDynamic) {
    M.Class cls = classDynamic;
    return cls.name.contains(pattern);
  }

  List<Element> _createMixins(List<M.Instance> types) {
    final children = types
        .expand((type) => <Element>[
              new SpanElement()..text = ', ',
              type.typeClass == null
                  ? (new SpanElement()..text = type.name.split('<').first)
                  : new ClassRefElement(_isolate, type.typeClass,
                          queue: _r.queue)
                      .element
            ])
        .toList();
    children.first.text = ' with ';
    return children;
  }

  Iterable<M.Class> _children(classDynamic) {
    M.Class cls = classDynamic;
    return _subclasses[cls.id];
  }
}
