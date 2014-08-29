// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.util;

import 'dart:collection';
import 'util_implementation.dart';
import 'characters.dart';

export 'setlet.dart';
export 'maplet.dart';

part 'indentation.dart';
part 'link.dart';

/// If an integer is masked by this constant, the result is guaranteed to be in
/// Smi range.
const int SMI_MASK = 0x3fffffff;

/**
 * Tagging interface for classes from which source spans can be generated.
 */
// TODO(johnniwinther): Find a better name.
// TODO(ahe): How about "Bolt"?
abstract class Spannable {}

class _SpannableSentinel implements Spannable {
  final String name;

  const _SpannableSentinel(this.name);

  String toString() => name;
}

/// Sentinel spannable used to mark that diagnostics should point to the
/// current element. Note that the diagnostic reporting will fail if the current
/// element is `null`.
const Spannable CURRENT_ELEMENT_SPANNABLE =
    const _SpannableSentinel("Current element");

/// Sentinel spannable used to mark that there might be no location for the
/// diagnostic. Use this only when it is not an error not to have a current
/// element.
const Spannable NO_LOCATION_SPANNABLE =
    const _SpannableSentinel("No location");

class SpannableAssertionFailure {
  final Spannable node;
  final String message;
  SpannableAssertionFailure(this.node, this.message);

  String toString() => 'Assertion failure'
                       '${message != null ? ': $message' : ''}';
}

bool equalElements(List a, List b) {
  if (a.length != b.length) return false;
  for (int index = 0; index < a.length; index++) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}

/**
 * File name prefix used to shorten the file name in stack traces printed by
 * [trace].
 */
String stackTraceFilePrefix = null;

/// Writes the characters of [string] on [buffer].  The characters
/// are escaped as suitable for JavaScript and JSON.  [buffer] is
/// anything which supports [:write:] and [:writeCharCode:], for example,
/// [StringBuffer].  Note that JS supports \xnn and \unnnn whereas JSON only
/// supports the \unnnn notation.  Therefore we use the \unnnn notation.
void writeJsonEscapedCharsOn(String string, buffer) {
  void addCodeUnitEscaped(var buffer, int code) {
    assert(code < 0x10000);
    buffer.write(r'\u');
    if (code < 0x1000) {
      buffer.write('0');
      if (code < 0x100) {
        buffer.write('0');
        if (code < 0x10) {
          buffer.write('0');
        }
      }
    }
    buffer.write(code.toRadixString(16));
  }

  void writeEscapedOn(String string, var buffer) {
    for (int i = 0; i < string.length; i++) {
      int code = string.codeUnitAt(i);
      if (code == $DQ) {
        buffer.write(r'\"');
      } else if (code == $TAB) {
        buffer.write(r'\t');
      } else if (code == $LF) {
        buffer.write(r'\n');
      } else if (code == $CR) {
        buffer.write(r'\r');
      } else if (code == $DEL) {
        addCodeUnitEscaped(buffer, $DEL);
      } else if (code == $LS) {
        // This Unicode line terminator and $PS are invalid in JS string
        // literals.
        addCodeUnitEscaped(buffer, $LS);  // 0x2028.
      } else if (code == $PS) {
        addCodeUnitEscaped(buffer, $PS);  // 0x2029.
      } else if (code == $BACKSLASH) {
        buffer.write(r'\\');
      } else {
        if (code < 0x20) {
          addCodeUnitEscaped(buffer, code);
          // We emit DEL (ASCII 0x7f) as an escape because it would be confusing
          // to have it unescaped in a string literal.  We also escape
          // everything above 0x7f because that means we don't have to worry
          // about whether the web server serves it up as Latin1 or UTF-8.
        } else if (code < 0x7f) {
          buffer.writeCharCode(code);
        } else {
          // This will output surrogate pairs in the form \udxxx\udyyy, rather
          // than the more logical \u{zzzzzz}.  This should work in JavaScript
          // (especially old UCS-2 based implementations) and is the only
          // format that is allowed in JSON.
          addCodeUnitEscaped(buffer, code);
        }
      }
    }
  }

  for (int i = 0; i < string.length; i++) {
    int code = string.codeUnitAt(i);
    if (code < 0x20 || code == $DEL || code == $DQ || code == $LS ||
        code == $PS || code == $BACKSLASH || code >= 0x80) {
      writeEscapedOn(string, buffer);
      return;
    }
  }
  buffer.write(string);
}

int computeHashCode(part1, [part2, part3, part4, part5]) {
  return (part1.hashCode
          ^ part2.hashCode
          ^ part3.hashCode
          ^ part4.hashCode
          ^ part5.hashCode) & 0x3fffffff;
}

String modifiersToString({bool isStatic: false,
                          bool isAbstract: false,
                          bool isFinal: false,
                          bool isVar: false,
                          bool isConst: false,
                          bool isFactory: false,
                          bool isExternal: false}) {
  LinkBuilder<String> builder = new LinkBuilder<String>();
  if (isStatic) builder.addLast('static');
  if (isAbstract) builder.addLast('abstract');
  if (isFinal) builder.addLast('final');
  if (isVar) builder.addLast('var');
  if (isConst) builder.addLast('const');
  if (isFactory) builder.addLast('factory');
  if (isExternal) builder.addLast('external');
  StringBuffer buffer = new StringBuffer();
  builder.toLink().printOn(buffer, ', ');
  return buffer.toString();
}

class Pair<A, B> {
  final A a;
  final B b;

  Pair(this.a, this.b);

  int get hashCode => 13 * a.hashCode + 17 * b.hashCode;

  bool operator ==(var other) {
    if (identical(this, other)) return true;
    if (other is! Pair) return false;
    return a == other.a && b == other.b;
  }

  String toString() => '($a,$b)';
}


int longestCommonPrefixLength(List a, List b) {
  int index = 0;
  for ( ; index < a.length && index < b.length; index++) {
    if (a[index] != b[index]) {
      break;
    }
  }
  return index;
}

/// Returns [suggestedName] if it is not in [usedNames]. Otherwise concatenates
/// the smallest number that makes it not appear in [usedNames].
///
/// Adds the result to [usedNames].
String makeUnique(String suggestedName, Set<String> usedNames) {
  String result = suggestedName;
  if (usedNames.contains(suggestedName)) {
    int counter = 0;
    while (usedNames.contains(result)) {
      counter++;
      result = "$suggestedName$counter";
    }
  }
  usedNames.add(result);
  return result;
}
