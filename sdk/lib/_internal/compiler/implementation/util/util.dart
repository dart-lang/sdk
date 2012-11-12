// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library org_dartlang_compiler_util;

import 'util_implementation.dart';
import 'characters.dart';

part 'link.dart';

/**
 * Tagging interface for classes from which source spans can be generated.
 */
// TODO(johnniwinther): Find a better name.
// TODO(ahe): How about "Bolt"?
abstract class Spannable {}

class SpannableAssertionFailure {
  final Spannable node;
  final String message;
  SpannableAssertionFailure(this.node, this.message);

  String toString() => 'compiler crashed.';
}

/// Writes the characters of [iterator] on [buffer].  The characters
/// are escaped as suitable for JavaScript and JSON.  [buffer] is
/// anything which supports [:add:] and [:addCharCode:], for example,
/// [StringBuffer].
void writeJsonEscapedCharsOn(Iterator<int> iterator, buffer, onError(code)) {
  while (iterator.hasNext) {
    int code = iterator.next();
    if (identical(code, $SQ)) {
      buffer.add(r"\'");
    } else if (identical(code, $LF)) {
      buffer.add(r'\n');
    } else if (identical(code, $CR)) {
      buffer.add(r'\r');
    } else if (identical(code, $LS)) {
      // This Unicode line terminator and $PS are invalid in JS string
      // literals.
      buffer.add(r'\u2028');
    } else if (identical(code, $PS)) {
      buffer.add(r'\u2029');
    } else if (identical(code, $BACKSLASH)) {
      buffer.add(r'\\');
    } else {
      if (code > 0xffff) {
        if (onError != null) onError(code);
        throw 'Unhandled non-BMP character: ${code.toRadixString(16)}';
      }
      // TODO(lrn): Consider whether all codes above 0x7f really need to
      // be escaped. We build a Dart string here, so it should be a literal
      // stage that converts it to, e.g., UTF-8 for a JS interpreter.
      if (code < 0x20) {
        buffer.add(r'\x');
        if (code < 0x10) buffer.add('0');
        buffer.add(code.toRadixString(16));
      } else if (code >= 0x80) {
        if (code < 0x100) {
          buffer.add(r'\x');
        } else {
          buffer.add(r'\u');
          if (code < 0x1000) {
            buffer.add('0');
          }
        }
        buffer.add(code.toRadixString(16));
      } else {
        buffer.addCharCode(code);
      }
    }
  }
}
