// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
/**
 * The default implementation of IDescription. This should rarely need
 * substitution, although conceivably it is a place where other languages
 * could be supported.
 */

part of matcher;

class StringDescription implements Description {
  var _out;

  /** Initialize the description with initial contents [init]. */
  StringDescription([String init = '']) {
    _out = init;
  }

  /** Get the description as a string. */
  String toString() => _out;

  /** Append some plain [text] to the description.  */
  Description add(String text) {
    _out = '${_out}${text}';
    return this;
  }

  /** Change the value of the description. */
  Description replace(String text) {
    _out = text;
    return this;
  }

  /**
   * Appends a description of [value]. If it is an IMatcher use its
   * describe method; if it is a string use its literal value after
   * escaping any embedded control characters; otherwise use its
   * toString() value and wrap it in angular "quotes".
   */
  Description addDescriptionOf(value) {
    if (value is Matcher) {
      value.describe(this);
    } else if (value is String) {
      _addEscapedString(value);
    } else {
      String description = (value == null) ? "null" : value.toString();
      if (description.startsWith('<') && description.endsWith('>')) {
          add(description);
      } else {
        add('<');
        add(description);
        add('>');
      }
    }
    return this;
  }

  /**
   * Append an [Iterable] [list] of objects to the description, using the
   * specified [separator] and framing the list with [start]
   * and [end].
   */
  Description addAll(String start, String separator, String end,
                       Iterable list) {
    var separate = false;
    add(start);
    for (var item in list) {
      if (separate) {
        add(separator);
      }
      addDescriptionOf(item);
      separate = true;
    }
    add(end);
    return this;
  }

  /** Escape the control characters in [string] so that they are visible. */
  _addEscapedString(String string) {
    add("'");
    for (var i = 0; i < string.length; i++) {
      add(_escape(string[i]));
    }
    add("'");
  }

  /** Return the escaped form of a character [ch]. */
  _escape(ch) {
    if (ch == "'")
      return "\'";
    else if (ch == '\n')
      return '\\n';
    else if (ch == '\r')
      return '\\r';
    else if (ch == '\t')
      return '\\t';
    else
      return ch;
  }
}
