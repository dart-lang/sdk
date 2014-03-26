// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.utils;

/// Returns the name of the type of [x], or "Unknown" if the type name can't be
/// determined.
String typeName(x) {
  // dart2js blows up on some objects (e.g. window.navigator).
  // So we play safe here.
  try {
    if (x == null) return "null";
    var type = x.runtimeType.toString();
    // TODO(nweiz): if the object's type is private, find a public superclass to
    // display once there's a portable API to do that.
    return type.startsWith("_") ? "?" : type;
  } catch (e) {
    return "?";
  }
}

/// Returns [source] with any control characters replaced by their escape
/// sequences.
///
/// This doesn't add quotes to the string, but it does escape single quote
/// characters so that single quotes can be applied externally.
String escapeString(String source) =>
    source.split("").map(_escapeChar).join("");

/// Return the escaped form of a character [ch].
String _escapeChar(String ch) {
  if (ch == "'")
    return "\\'";
  else if (ch == '\n')
    return '\\n';
  else if (ch == '\r')
    return '\\r';
  else if (ch == '\t')
    return '\\t';
  else
    return ch;
}

/// Indent each line in [str] by two spaces.
String indent(String str) =>
  str.replaceAll(new RegExp("^", multiLine: true), "  ");

/// A pair of values.
class Pair<E, F> {
  final E first;
  final F last;

  Pair(this.first, this.last);

  String toString() => '($first, $last)';

  bool operator ==(other) {
    if (other is! Pair) return false;
    return other.first == first && other.last == last;
  }

  int get hashCode => first.hashCode ^ last.hashCode;
}

