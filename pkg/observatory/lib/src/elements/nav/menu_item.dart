// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:web/web.dart';

import '../helpers/custom_element.dart';
import '../helpers/element_utils.dart';
import '../helpers/rendering_scheduler.dart';

class NavMenuItemElement extends CustomElement implements Renderable {
  late RenderingScheduler<NavMenuItemElement> _r;

  Stream<RenderedEvent<NavMenuItemElement>> get onRendered => _r.onRendered;

  late String _label;
  late String _link;
  List<HTMLElement> _content = const <HTMLElement>[];

  String get label => _label;
  String get link => _link;
  List<HTMLElement> get content => _content;

  set label(String value) => _label = _r.checkAndReact(_label, value);
  set link(String value) => _link = _r.checkAndReact(_link, value);
  set content(Iterable<HTMLElement> value) {
    _content = value.toList();
    _r.dirty();
  }

  factory NavMenuItemElement(
    String label, {
    String link = '',
    RenderingQueue? queue,
  }) {
    NavMenuItemElement e = new NavMenuItemElement.created();
    e._r = new RenderingScheduler<NavMenuItemElement>(e, queue: queue);
    e._label = label;
    e._link = link;
    return e;
  }

  NavMenuItemElement.created() : super.created('nav-menu-item');

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    _r.disable(notify: true);
    removeChildren();
  }

  void render() {
    children = <HTMLElement>[
      new HTMLLIElement()
        ..className = 'nav-menu-item'
        ..appendChildren(<HTMLElement>[
          new HTMLAnchorElement()
            ..href = link
            ..text = label,
          new HTMLUListElement()..appendChildren(_content),
        ]),
    ];
  }
}
