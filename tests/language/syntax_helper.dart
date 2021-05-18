// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import "package:expect/expect.dart";

/// Helper class for determining when no argument is passed to a function.
class Absent {
  const Absent();
}

const absent = Absent();

/// Returns an approximate representation of the syntax that was used to
/// construct [x].  Extra parentheses are used around unary and binary
/// expressions to disambiguate precedence.
String syntax(Object? x) {
  var knownSyntax = SyntaxTracker.known[x];
  if (knownSyntax != null) return knownSyntax;
  if (x is SyntaxTracker || x is num) {
    return x.toString();
  } else if (x is List) {
    return '[${x.map(syntax).join(', ')}]';
  } else if (x is Set) {
    if (x.isEmpty) return 'Set()';
    return '{${x.map(syntax).join(', ')}}';
  } else if (x is Map) {
    if (x.isEmpty) return '{}';
    var entries = x.entries
        .map((entry) => '${syntax(entry.key)}: ${syntax(entry.value)}');
    return '{ ${entries.join(', ')} }';
  } else if (x is String) {
    return json.encode(x);
  } else {
    throw UnimplementedError('Unknown syntax for $x.  '
        'Consider adding to `SyntaxTracker.known`.');
  }
}

/// Instances of this class record the syntax of operations performed on them.
class SyntaxTracker {
  final String _syntax;

  SyntaxTracker(this._syntax);

  String toString() => _syntax;

  static String args([Object? x = absent, Object? y = absent]) =>
      '(${[x, y].where((v) => v is! Absent).join(', ')})';

  static String typeArgs(Type T, Type U) =>
      T == dynamic && U == dynamic ? '' : '<${syntax(T)}, ${syntax(U)}>';

  /// Simple objects with known syntactic representations.  Tests can add to
  /// this map.
  static Map<Object?, String> known = {
    true: 'true',
    false: 'false',
    null: 'null'
  };
}

/// Extension allowing us to detect the syntax of most operations performed on
/// arbitrary types.
extension SyntaxTrackingExtension on Object? {
  Object? method<T, U>([Object? x = absent, Object? y = absent]) => SyntaxTracker(
      '${syntax(this)}.method${SyntaxTracker.typeArgs(T, U)}${SyntaxTracker.args(x, y)}');

  Object? call<T, U>([Object? x = absent, Object? y = absent]) => SyntaxTracker(
      '${syntax(this)}${SyntaxTracker.typeArgs(T, U)}${SyntaxTracker.args(x, y)}');

  Object? get getter => SyntaxTracker('${syntax(this)}.getter');

  Object? operator [](Object? index) =>
      SyntaxTracker('${syntax(this)}[${syntax(index)}]');

  Object? operator -() => SyntaxTracker('(-${syntax(this)})');

  Object? operator ~() => SyntaxTracker('(~${syntax(this)})');

  Object? operator *(Object? other) =>
      SyntaxTracker('(${syntax(this)} * ${syntax(other)})');

  Object? operator /(Object? other) =>
      SyntaxTracker('(${syntax(this)} / ${syntax(other)})');

  Object? operator ~/(Object? other) =>
      SyntaxTracker('(${syntax(this)} ~/ ${syntax(other)})');

  Object? operator %(Object? other) =>
      SyntaxTracker('(${syntax(this)} % ${syntax(other)})');

  Object? operator +(Object? other) =>
      SyntaxTracker('(${syntax(this)} + ${syntax(other)})');

  Object? operator -(Object? other) =>
      SyntaxTracker('(${syntax(this)} - ${syntax(other)})');

  Object? operator <<(Object? other) =>
      SyntaxTracker('(${syntax(this)} << ${syntax(other)})');

  Object? operator >>(Object? other) =>
      SyntaxTracker('(${syntax(this)} >> ${syntax(other)})');

  Object? operator &(Object? other) =>
      SyntaxTracker('(${syntax(this)} & ${syntax(other)})');

  Object? operator ^(Object? other) =>
      SyntaxTracker('(${syntax(this)} ^ ${syntax(other)})');

  Object? operator |(Object? other) =>
      SyntaxTracker('(${syntax(this)} | ${syntax(other)})');

  Object? operator <(Object? other) =>
      SyntaxTracker('(${syntax(this)} < ${syntax(other)})');

  Object? operator >(Object? other) =>
      SyntaxTracker('(${syntax(this)} > ${syntax(other)})');

  Object? operator <=(Object? other) =>
      SyntaxTracker('(${syntax(this)} <= ${syntax(other)})');

  Object? operator >=(Object? other) =>
      SyntaxTracker('(${syntax(this)} >= ${syntax(other)})');
}

void checkSyntax(Object? x, String expectedSyntax) {
  Expect.equals(expectedSyntax, syntax(x));
}

Object? f<T, U>([Object? x = absent, Object? y = absent]) => SyntaxTracker(
    'f${SyntaxTracker.typeArgs(T, U)}${SyntaxTracker.args(x, y)}');

Object? x = SyntaxTracker('x');
