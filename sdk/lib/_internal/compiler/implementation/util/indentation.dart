// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.util;

/// Indentation utility class. Should be used as a mixin in most cases.
class Indentation {
  /// The current indentation string.
  String get indentation {
    // Lazily add new indentation strings as required.
    for (int i = _indentList.length; i <= _indentLevel; i++) {
      _indentList.add(_indentList[i - 1] + indentationUnit);
    }
    return _indentList[_indentLevel];
  }

  /// The current indentation level.
  int _indentLevel = 0;

  /// A cache of all indentation strings used so far.
  /// Always at least of length 1.
  List<String> _indentList = <String>[""];

  /// The indentation unit, defaulting to two spaces. May be overwritten.
  String _indentationUnit = "  ";
  String get indentationUnit => _indentationUnit;
         set indentationUnit(String value) {
           if (value != _indentationUnit) {
             _indentationUnit = value;
             _indentList = <String>[""];
           }
         }

  /// Increases the current level of indentation.
  void indentMore() {
    _indentLevel++;
  }

  /// Decreases the current level of indentation.
  void indentLess() {
    _indentLevel--;
  }

  /// Calls [f] with one more indentation level, restoring indentation context
  /// upon return of [f] and returning its result.
  indentBlock(Function f) {
    indentMore();
    var result = f();
    indentLess();
    return result;
  }
}
