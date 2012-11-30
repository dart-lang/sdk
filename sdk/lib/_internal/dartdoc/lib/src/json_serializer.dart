// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Simple library to serialize acyclic Dart types to JSON.
 * This library is not intended for broad consumption and should be replaced
 * with a more generic Dart serialization library when one is available.
 */
library json_serializer;

import 'dart:mirrors';
import 'dart:json';

String serialize(Object o) {
  var printer = new JsonPrinter();
  _serialize(null, o, printer);
  return printer.toString();
}

void _serialize(String name, Object o, JsonPrinter printer) {
  if (o == null) return;

  if (o is List) {
    _serializeList(name, o, printer);
  } else if (o is Map) {
    _serializeMap(name, o, printer);
  } else if (o is String) {
    printer.addString(name, o);
  } else if (o is bool) {
    printer.addBool(name, o);
  } else {
    _serializeObject(name, o, printer);
  }
}

void _serializeObject(String name, Object o, JsonPrinter printer) {
  printer.startObject(name);

  var mirror = reflect(o);
  var classMirror = mirror.type;
  var members = <String>[];
  determineAllMembers(classMirror, members);

  // TODO(jacobr): this code works only because futures for mirrors return
  // immediately.
  for(String memberName in members) {
    mirror.getField(memberName).then((result) {
      _serialize(memberName, result.reflectee, printer);
    });
  }
  printer.endObject();
}

void determineAllMembers(ClassMirror classMirror,
    List<String> members) {
  for(String getterName in classMirror.getters.keys) {
    if (!members.contains(getterName)) {
      members.add(getterName);
    }
  }
  for(String fieldName in classMirror.variables.keys) {
    if (!members.contains(fieldName)) {
      members.add(fieldName);
    }
  }
  if (classMirror.superclass != null &&
      classMirror.superclass.qualifiedName != classMirror.qualifiedName &&
      classMirror.superclass.qualifiedName != 'dart:core.Object') {
    determineAllMembers(classMirror.superclass, members);
  }
}

void _serializeList(String name, List l, JsonPrinter printer) {
  printer.startList(name);
  for(var o in l) {
    _serialize(null, o, printer);
  }
  printer.endList();
}

void _serializeMap(String name, Map m, JsonPrinter printer) {
}

class JsonPrinter {
  static const int BACKSPACE = 8;
  static const int TAB = 9;
  static const int NEW_LINE = 10;
  static const int FORM_FEED = 12;
  static const int CARRIAGE_RETURN = 13;
  static const int QUOTE = 34;
  static const int BACKSLASH = 92;
  static const int CHAR_B = 98;
  static const int CHAR_F = 102;
  static const int CHAR_N = 110;
  static const int CHAR_R = 114;
  static const int CHAR_T = 116;
  static const int CHAR_U = 117;

  StringBuffer _sb;
  int _indent = 0;
  bool _inSet = false;

  bool _prettyPrint;
  JsonPrinter({this._prettyPrint: true}) {
    _sb = new StringBuffer();
  }

  void startObject(String name) {
    _start(name);
    _sb.add('{');

    _indent += 1;
    _inSet = false;
  }

  void endObject() {
    _indent -= 1;
    if (_inSet) {
      _newline();
    }
    _sb.add('}');
    _inSet = true;
  }

  void startList(String name) {
    _start(name);
    _inSet = false;

    _sb.add('[');
    _indent += 1;
  }

  void endList() {
    _indent -= 1;
    if (_inSet) {
      _newline();
    }
    _sb.add(']');
    _inSet = true;
  }

  void addString(String name, String value) {
    _start(name);
    _sb.add('"');
    _escape(_sb, value);
    _sb.add('"');
    _inSet = true;
  }

  void addBool(String name, bool value) {
    _start(name);
    _sb.add(value.toString());
    _inSet = true;
  }

  void addNum(String name, num value) {
    _start(name);
    _sb.add(value.toString());
    _inSet = true;
  }

  void _start(String name) {
    if (_inSet) {
      _sb.add(',');
    }
    _newline();
    if (name != null) {
      _sb.add('"$name": ');
    }
  }

  void _newline([int indent = 0]) {
    _sb.add('\n');
    _indent += indent;

    for (var i = 0; i < _indent; ++i) {
      _sb.add('  ');
    }
  }

  String toString() {
    if (_prettyPrint) {
      return _sb.toString();
    } else {
      // Convenient hack to remove the pretty printing this serializer adds by
      // default.
      return JSON.stringify(JSON.parse(_sb.toString()));
    }
  }

  static int _hexDigit(int x) => x < 10 ? 48 + x : 87 + x;

  static void _escape(StringBuffer sb, String s) {
    final int length = s.length;
    bool needsEscape = false;
    final charCodes = new List<int>();
    for (int i = 0; i < length; i++) {
      int charCode = s.charCodeAt(i);
      if (charCode < 32) {
        needsEscape = true;
        charCodes.add(JsonPrinter.BACKSLASH);
        switch (charCode) {
        case JsonPrinter.BACKSPACE:
          charCodes.add(JsonPrinter.CHAR_B);
          break;
        case JsonPrinter.TAB:
          charCodes.add(JsonPrinter.CHAR_T);
          break;
        case JsonPrinter.NEW_LINE:
          charCodes.add(JsonPrinter.CHAR_N);
          break;
        case JsonPrinter.FORM_FEED:
          charCodes.add(JsonPrinter.CHAR_F);
          break;
        case JsonPrinter.CARRIAGE_RETURN:
          charCodes.add(JsonPrinter.CHAR_R);
          break;
        default:
          charCodes.add(JsonPrinter.CHAR_U);
          charCodes.add(_hexDigit((charCode >> 12) & 0xf));
          charCodes.add(_hexDigit((charCode >> 8) & 0xf));
          charCodes.add(_hexDigit((charCode >> 4) & 0xf));
          charCodes.add(_hexDigit(charCode & 0xf));
          break;
        }
      } else if (charCode == JsonPrinter.QUOTE ||
          charCode == JsonPrinter.BACKSLASH) {
        needsEscape = true;
        charCodes.add(JsonPrinter.BACKSLASH);
        charCodes.add(charCode);
      } else {
        charCodes.add(charCode);
      }
    }
    sb.add(needsEscape ? new String.fromCharCodes(charCodes) : s);
  }
}
