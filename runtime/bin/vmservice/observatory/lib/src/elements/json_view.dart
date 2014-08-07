// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_view_element;

import 'package:polymer/polymer.dart';
import 'observatory_element.dart';
import 'package:observatory/service.dart';

class JsonPrettyPrinter {
  String prettyPrint(ServiceMap map) {
    _buffer.clear();
    _buffer.write('{\n');
    _printMap(map, 0);
    _buffer.write('}\n');
    return _buffer.toString();
  }

  void _printMap(ObservableMap map, int depth) {
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

  void _printList(ObservableList list, int depth) {
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
    const tab = '  ';  // 2 spaces.
    _buffer.write(tab * depth);
  }

  final _buffer = new StringBuffer();
  final _seen = new Set();
}


@CustomTag('json-view')
class JsonViewElement extends ObservatoryElement {
  @published ServiceMap map;
  @observable String mapAsString;
  JsonViewElement.created() : super.created();

  void mapChanged(oldValue) {
    var jpp = new JsonPrettyPrinter();
    mapAsString = jpp.prettyPrint(map);
  }
}
