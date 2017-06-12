// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.util;

import 'package:front_end/src/fasta/scanner/characters.dart';
import 'package:front_end/src/fasta/util/link.dart';

export 'emptyset.dart';
export 'maplet.dart';
export 'setlet.dart';
export 'package:front_end/src/fasta/util/link.dart';

part 'indentation.dart';

/// Helper functions for creating hash codes.
class Hashing {
  /// If an integer is masked by this constant, the result is guaranteed to be
  /// in Smi range.
  static const int SMI_MASK = 0x3fffffff;

  /// Mix the bits of [value] and merge them with [existing].
  static int mixHashCodeBits(int existing, int value) {
    // Spread the bits of value. Try to stay in the 30-bit range to
    // avoid overflowing into a more expensive integer representation.
    int h = value & 0x1fffffff;
    h += ((h & 0x3fff) << 15) ^ 0x1fffcd7d;
    h ^= (h >> 10);
    h += ((h & 0x3ffffff) << 3);
    h ^= (h >> 6);
    h += ((h & 0x7ffffff) << 2) + ((h & 0x7fff) << 14);
    h ^= (h >> 16);
    // Combine the two hash values.
    int high = existing >> 15;
    int low = existing & 0x7fff;
    return ((high * 13) ^ (low * 997) ^ h) & SMI_MASK;
  }

  /// Mix the bits of `object.hashCode` with [existing].
  static int objectHash(Object object, [int existing = 0]) {
    return mixHashCodeBits(existing, object.hashCode);
  }

  /// Mix the bits of `.hashCode` all non-null objects.
  static int objectsHash(Object obj1, [Object obj2, Object obj3]) {
    int hash = 0;
    if (obj3 != null) hash = objectHash(obj3, hash);
    if (obj2 != null) hash = objectHash(obj2, hash);
    return objectHash(obj1, hash);
  }

  /// Mix the bits of the element hash codes of [list] with [existing].
  static int listHash(List list, [int existing = 0]) {
    int h = existing;
    int length = list.length;
    for (int i = 0; i < length; i++) {
      h = mixHashCodeBits(h, list[i].hashCode);
    }
    return h;
  }

  /// Mix the bits of the hash codes of the unordered key/value from [map] with
  /// [existing].
  static int unorderedMapHash(Map map, [int existing = 0]) {
    int h = 0;
    for (var key in map.keys) {
      h ^= objectHash(key, objectHash(map[key]));
    }
    return mixHashCodeBits(h, existing);
  }

  /// Mix the bits of the key/value hash codes from [map] with [existing].
  static int mapHash(Map map, [int existing = 0]) {
    int h = existing;
    for (var key in map.keys) {
      h = mixHashCodeBits(h, key.hashCode);
      h = mixHashCodeBits(h, map[key].hashCode);
    }
    return h;
  }
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
        addCodeUnitEscaped(buffer, $LS); // 0x2028.
      } else if (code == $PS) {
        addCodeUnitEscaped(buffer, $PS); // 0x2029.
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
    if (code < 0x20 ||
        code == $DEL ||
        code == $DQ ||
        code == $LS ||
        code == $PS ||
        code == $BACKSLASH ||
        code >= 0x80) {
      writeEscapedOn(string, buffer);
      return;
    }
  }
  buffer.write(string);
}

int computeHashCode(part1, [part2, part3, part4, part5]) {
  return (part1.hashCode ^
          part2.hashCode ^
          part3.hashCode ^
          part4.hashCode ^
          part5.hashCode) &
      0x3fffffff;
}

String modifiersToString(
    {bool isStatic: false,
    bool isAbstract: false,
    bool isFinal: false,
    bool isVar: false,
    bool isConst: false,
    bool isFactory: false,
    bool isExternal: false,
    bool isCovariant: false}) {
  LinkBuilder<String> builder = new LinkBuilder<String>();
  if (isStatic) builder.addLast('static');
  if (isAbstract) builder.addLast('abstract');
  if (isFinal) builder.addLast('final');
  if (isVar) builder.addLast('var');
  if (isConst) builder.addLast('const');
  if (isFactory) builder.addLast('factory');
  if (isExternal) builder.addLast('external');
  if (isCovariant) builder.addLast('covariant');
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
  for (; index < a.length && index < b.length; index++) {
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
