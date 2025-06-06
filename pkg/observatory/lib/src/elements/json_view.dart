// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_view_element;

import 'dart:async';

import 'package:web/web.dart';

import '../../models.dart' as M;
import 'helpers/custom_element.dart';
import 'helpers/element_utils.dart';
import 'helpers/nav_bar.dart';
import 'helpers/rendering_scheduler.dart';
import 'nav/notify.dart';
import 'nav/top_menu.dart';

class JSONViewElement extends CustomElement implements Renderable {
  late RenderingScheduler<JSONViewElement> _r;

  Stream<RenderedEvent<JSONViewElement>> get onRendered => _r.onRendered;

  late M.NotificationRepository _notifications;
  late Map _map;

  M.NotificationRepository get notifications => _notifications;
  Map get map => _map;

  factory JSONViewElement(
    Map map,
    M.NotificationRepository notifications, {
    RenderingQueue? queue,
  }) {
    JSONViewElement e = new JSONViewElement.created();
    e._r = new RenderingScheduler<JSONViewElement>(e, queue: queue);
    e._notifications = notifications;
    e._map = map;
    return e;
  }

  JSONViewElement.created() : super.created('json-view');

  @override
  attached() {
    super.attached();
    _r.enable();
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    removeChildren();
  }

  void render() {
    children = <HTMLElement>[
      navBar(<HTMLElement>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavNotifyElement(_notifications, queue: _r.queue).element,
      ]),
      new HTMLDivElement()
        ..className = 'content-centered-big'
        ..appendChildren(<HTMLElement>[
          new HTMLHeadingElement.h2()..textContent = 'Object',
          new HTMLHRElement(),
          new HTMLPreElement.pre()..textContent = JSONPretty.stringify(_map),
        ]),
    ];
  }
}

class JSONPretty {
  JSONPretty._();

  static String stringify(Map map) => new JSONPretty._()._stringify(map);

  String _stringify(Map map) {
    _buffer.clear();
    _buffer.write('{\n');
    _printMap(map, 0);
    _buffer.write('}\n');
    return _buffer.toString();
  }

  void _printMap(Map map, int depth) {
    if (_seen.contains(map)) {
      return;
    }
    _seen.add(map);
    for (var k in map.keys) {
      var v = map[k];
      if (v is Map) {
        _writeIndent(depth);
        _buffer.write('"$k": {\n');
        _printMap(v, depth + 1);
        _writeIndent(depth);
        _buffer.write('}\n');
      } else if (v is List) {
        _writeIndent(depth);
        _buffer.write('"$k": [\n');
        _printList(v, depth + 1);
        _writeIndent(depth);
        _buffer.write(']\n');
      } else {
        _writeIndent(depth);
        _buffer.write('"$k": $v');
        _buffer.write('\n');
      }
    }
    _seen.remove(map);
  }

  void _printList(List list, int depth) {
    if (_seen.contains(list)) {
      return;
    }
    _seen.add(list);
    for (var v in list) {
      if (v is Map) {
        _writeIndent(depth);
        _buffer.write('{\n');
        _printMap(v, depth + 1);
        _writeIndent(depth);
        _buffer.write('}\n');
      } else if (v is List) {
        _writeIndent(depth);
        _buffer.write('[\n');
        _printList(v, depth + 1);
        _writeIndent(depth);
        _buffer.write(']\n');
      } else {
        _writeIndent(depth);
        _buffer.write(v);
        _buffer.write('\n');
      }
    }
    _seen.remove(list);
  }

  void _writeIndent(int depth) {
    const tab = '  '; // 2 spaces.
    _buffer.write(tab * depth);
  }

  final _buffer = new StringBuffer();
  final _seen = new Set();
}
