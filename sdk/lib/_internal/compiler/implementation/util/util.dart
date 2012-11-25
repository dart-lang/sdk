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

  String toString() => 'Compiler crashed: $message.';
}

/// Writes the characters of [string] on [buffer].  The characters
/// are escaped as suitable for JavaScript and JSON.  [buffer] is
/// anything which supports [:add:] and [:addCharCode:], for example,
/// [StringBuffer].  Note that JS supports \xnn and \unnnn whereas JSON only
/// supports the \unnnn notation.  Therefore we use the \unnnn notation.
void writeJsonEscapedCharsOn(String string, buffer) {
  void addCodeUnitEscaped(var buffer, int code) {
    assert(code < 0x10000);
    buffer.add(r'\u');
    if (code < 0x1000) {
      buffer.add('0');
      if (code < 0x100) {
        buffer.add('0');
        if (code < 0x10) {
          buffer.add('0');
        }
      }
    }
    buffer.add(code.toRadixString(16));
  }

  void writeEscapedOn(String string, var buffer) {
    for (int i = 0; i < string.length; i++) {
      int code = string.charCodeAt(i);
      if (code == $DQ) {
        buffer.add(r'\"');
      } else if (code == $TAB) {
        buffer.add(r'\t');
      } else if (code == $LF) {
        buffer.add(r'\n');
      } else if (code == $CR) {
        buffer.add(r'\r');
      } else if (code == $DEL) {
        addCodeUnitEscaped(buffer, $DEL);
      } else if (code == $LS) {
        // This Unicode line terminator and $PS are invalid in JS string
        // literals.
        addCodeUnitEscaped(buffer, $LS);  // 0x2028.
      } else if (code == $PS) {
        addCodeUnitEscaped(buffer, $PS);  // 0x2029.
      } else if (code == $BACKSLASH) {
        buffer.add(r'\\');
      } else {
        if (code < 0x20) {
          addCodeUnitEscaped(buffer, code);
          // We emit DEL (ASCII 0x7f) as an escape because it would be confusing
          // to have it unescaped in a string literal.  We also escape
          // everything above 0x7f because that means we don't have to worry
          // about whether the web server serves it up as Latin1 or UTF-8.
        } else if (code < 0x7f) {
          buffer.addCharCode(code);
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
    int code = string.charCodeAt(i);
    if (code < 0x20 || code == $DEL || code == $DQ || code == $LS ||
        code == $PS || code == $BACKSLASH || code >= 0x80) {
      writeEscapedOn(string, buffer);
      return;
    }
  }
  buffer.add(string);
}
