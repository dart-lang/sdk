// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for generating code to be extended with source location mapping.
 */
class CodeWriter {
  static final INDENTATION = '  ';

  static final int INC_INDENT = +1;
  static final int DEC_INDENT = -1;
  static final NEWLINE = null;       // Anything but an int, String or List.

  List _buf;
  bool writeComments;

  CodeWriter(): _buf = [], writeComments = options.emitCodeComments;

  bool get isEmpty() => _buf.length == 0;

  String get text() {
    StringBuffer sb = new StringBuffer();
    int indentation = 0;
    bool pendingIndent = false;
    void _walk(list) {
      for (var thing in list) {
        if (thing is String) {
          if (pendingIndent) {
            for (int i = 0; i < indentation; i++) {
              sb.add(INDENTATION);
            }
            pendingIndent = false;
          }
          sb.add(thing);
        } else if (thing === NEWLINE) {
          sb.add('\n');
          pendingIndent = true;
        } else if (thing is int) {
          indentation += thing;
        } else if (thing is CodeWriter) {
          _walk(thing._buf);
        }
      }
    }
    _walk(_buf);
    return sb.toString();
  }

  /** Returns a CodeWriter that writes at the current position. */
  CodeWriter subWriter() {
    CodeWriter sub = new CodeWriter();
    sub.writeComments = writeComments;
    _buf.add(sub);   // Splice subwriter's output into this parent writer.
    return sub;
  }

  comment(String text) {
    if (writeComments) {
      writeln(text);
    }
  }

  _writeFragment(String text) {
    if (text.length == 0) return;
    _buf.add(text);
  }

  write(String text) {
    if (text.length == 0) return;

    // TODO(jimhug): Check perf consequences of this split.
    if (text.indexOf('\n') != -1) {
      var lines = text.split('\n');
      _writeFragment(lines[0]);
      for (int i = 1; i < lines.length; i++) {
        _buf.add(NEWLINE);
        _writeFragment(lines[i]);
      }
    } else {
      _buf.add(text);
    }
  }

  writeln([String text = null]) {
    if (text == null) {
      _buf.add(NEWLINE);
    } else {
      write(text);
      if (!text.endsWith('\n')) _buf.add(NEWLINE);
    }
  }

  enterBlock(String text) {
    writeln(text);
    _buf.add(INC_INDENT);
  }

  exitBlock(String text) {
    _buf.add(DEC_INDENT);
    writeln(text);
  }

  /** Switch to an adjacent block in one line, e.g. "} else if (...) {" */
  nextBlock(String text) {
    _buf.add(DEC_INDENT);
    writeln(text);
    _buf.add(INC_INDENT);
  }
}
