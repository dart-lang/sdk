// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_view_element;

import 'dart:async';
import 'dart:html';
import 'package:observatory_2/models.dart' as M;
import 'package:observatory_2/src/elements/helpers/nav_bar.dart';
import 'package:observatory_2/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory_2/src/elements/helpers/custom_element.dart';
import 'package:observatory_2/src/elements/nav/notify.dart';
import 'package:observatory_2/src/elements/nav/top_menu.dart';
import 'package:observatory_2/src/elements/view_footer.dart';

class JSONViewElement extends CustomElement implements Renderable {
  RenderingScheduler<JSONViewElement> _r;

  Stream<RenderedEvent<JSONViewElement>> get onRendered => _r.onRendered;

  M.NotificationRepository _notifications;
  Map _map;

  M.NotificationRepository get notifications => _notifications;
  Map get map => _map;

  factory JSONViewElement(Map map, M.NotificationRepository notifications,
      {RenderingQueue queue}) {
    assert(notifications != null);
    assert(map != null);
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
    children = <Element>[];
  }

  void render() {
    children = <Element>[
      navBar(<Element>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavNotifyElement(_notifications, queue: _r.queue).element
      ]),
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = <Element>[
          new HeadingElement.h2()..text = 'Object',
          new HRElement(),
          new PreElement()..text = JSONPretty.stringify(_map),
          new HRElement(),
          new ViewFooterElement(queue: _r.queue).element
        ]
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
