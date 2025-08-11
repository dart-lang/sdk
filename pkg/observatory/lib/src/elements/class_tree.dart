// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library class_tree_element;

import 'dart:async';

import 'package:web/web.dart';

import '../../models.dart' as M;
import 'class_ref.dart';
import 'containers/virtual_tree.dart';
import 'helpers/custom_element.dart';
import 'helpers/element_utils.dart';
import 'helpers/nav_bar.dart';
import 'helpers/nav_menu.dart';
import 'helpers/rendering_scheduler.dart';
import 'nav/isolate_menu.dart';
import 'nav/notify.dart';
import 'nav/top_menu.dart';
import 'nav/vm_menu.dart';

class ClassTreeElement extends CustomElement implements Renderable {
  late RenderingScheduler<ClassTreeElement> _r;

  Stream<RenderedEvent<ClassTreeElement>> get onRendered => _r.onRendered;

  late M.VM _vm;
  late M.IsolateRef _isolate;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  late M.ClassRepository _classes;
  M.Class? _object;
  final _subclasses = <String, Iterable<M.Class>>{};
  final _mixins = <String, List<M.Instance>?>{};

  factory ClassTreeElement(
    M.VM vm,
    M.IsolateRef isolate,
    M.EventRepository events,
    M.NotificationRepository notifications,
    M.ClassRepository classes, {
    RenderingQueue? queue,
  }) {
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

  VirtualTreeElement? _tree;

  void render() {
    children = <HTMLElement>[
      navBar(<HTMLElement>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue).element,
        navMenu('class hierarchy'),
        new NavNotifyElement(_notifications, queue: _r.queue).element,
      ]),
      new HTMLDivElement()
        ..className = 'content-centered'
        ..appendChildren(<HTMLElement>[
          new HTMLHeadingElement.h1()
            ..textContent = 'Class Hierarchy (${_subclasses.length})',
          new HTMLBRElement(),
          new HTMLHRElement(),
          _object == null
              ? (new HTMLHeadingElement.h2()..textContent = 'Loading...')
              : _createTree(),
        ]),
    ];
  }

  HTMLElement _createTree() {
    _tree = new VirtualTreeElement(
      _create,
      _update,
      _children,
      items: [_object],
      search: _search,
      queue: _r.queue,
    );
    _tree!.expand(_object, autoExpandSingleChildNodes: true);
    return _tree!.element;
  }

  Future _refresh() async {
    _object = null;
    _subclasses.clear();
    _mixins.clear();
    _object = await _register(await _classes.getObject(_isolate));
    _r.dirty();
  }

  Future<M.Class> _register(M.Class cls) async {
    _subclasses[cls.id!] = await Future.wait(
      (await Future.wait(
        cls.subclasses!.map(_getActualChildren),
      )).expand((f) => f).map(_register),
    );
    return cls;
  }

  Future<Iterable<M.Class>> _getActualChildren(M.ClassRef ref) async {
    var cls = await _classes.get(_isolate, ref.id!);
    if (cls.isPatch!) {
      return const [];
    }
    if (cls.mixin == null) {
      return [cls];
    }
    return (await Future.wait(
      cls.subclasses!.map(_getActualChildren),
    )).expand((f) => f)..forEach((subcls) {
      _mixins[subcls.id!] = (_mixins[subcls.id!] ?? [])
        ..add(cls.mixin as M.Instance);
    });
  }

  static HTMLElement _create(toggle) {
    return new HTMLDivElement()
      ..className = 'class-tree-item'
      ..appendChildren(<HTMLElement>[
        new HTMLSpanElement()..className = 'lines',
        new HTMLButtonElement()
          ..className = 'expander'
          ..onClick.listen((_) => toggle(autoToggleSingleChildNodes: true)),
        new HTMLSpanElement()..className = 'name',
      ]);
  }

  void _update(HTMLElement el, classDynamic, int index) {
    M.Class cls = classDynamic;
    virtualTreeUpdateLines(el.childNodes.item(0) as HTMLSpanElement, index);
    if (cls.subclasses!.isEmpty) {
      (el.children.item(1) as HTMLElement).textContent = '';
    } else {
      (el.children.item(1) as HTMLElement).textContent = _tree!.isExpanded(cls)
          ? '▼'
          : '►';
    }
    (el.children.item(2) as HTMLElement)
      ..removeChildren()
      ..appendChild(
        new ClassRefElement(_isolate, cls, queue: _r.queue).element,
      );
    if (_mixins[cls.id] != null) {
      (el.children.item(2) as HTMLElement).appendChildren(
        _createMixins(_mixins[cls.id]!),
      );
    }
  }

  bool _search(Pattern pattern, classDynamic) {
    M.Class cls = classDynamic;
    return cls.name!.contains(pattern);
  }

  List<HTMLElement> _createMixins(List<M.Instance> types) {
    final children = types
        .expand(
          (type) => <HTMLElement>[
            new HTMLSpanElement()..textContent = ', ',
            type.typeClass == null
                ? (new HTMLSpanElement()
                    ..textContent = type.name!.split('<').first)
                : new ClassRefElement(
                    _isolate,
                    type.typeClass!,
                    queue: _r.queue,
                  ).element,
          ],
        )
        .toList();
    children.first.textContent = ' with ';
    return children;
  }

  Iterable<M.Class> _children(classDynamic) {
    M.Class cls = classDynamic;
    return _subclasses[cls.id]!;
  }
}
