// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' show min;

export 'package:dart_console/dart_console.dart';
import 'package:dart_console/dart_console.dart';

class SmartConsole extends Console {
  final ScrollbackBuffer history;
  late final List<KeyHandler> handlers;
  KeyHandler? completionHandler;

  SmartConsole({this.completionHandler})
      : history = ScrollbackBuffer(recordBlanks: false) {
    handlers = [
      BashNavigationKeyHandler(),
      BashHistoryKeyHandler(history),
      BashEditKeyHandler(),
    ];
  }

  void moveCursorToColumn(int column) {
    write('\x1b[${column + 1}`');
  }

  void hideCursor() {
    write('\x1b[? 5l');
  }

  void showCursor() {
    write('\x1b[? 5h');
  }

  ReadLineResult smartReadLine() {
    final buffer = LineEditBuffer();

    drawPrompt(buffer);
    while (true) {
      final key = readKey();

      bool wasHandled = false;
      for (final handler in handlers) {
        if (handler.handleKey(buffer, key)) {
          wasHandled = true;
          break;
        }
      }
      if (completionHandler != null &&
          completionHandler!.handleKey(buffer, key)) {
        wasHandled = true;
      }

      if (!wasHandled && key.isControl) {
        switch (key.controlChar) {
          // Accept
          case ControlCharacter.enter:
            history.add(buffer.text);
            writeLine();
            return ReadLineResult(buffer.text, false, false);

          // Cancel this line.
          case ControlCharacter.ctrlC:
            return ReadLineResult('', true, false);

          // EOF
          case ControlCharacter.ctrlD:
            if (!buffer.text.isEmpty) break;
            return ReadLineResult('', true, true);

          // Ignore.
          default:
            break;
        }
      }

      drawPrompt(buffer);
    }
  }

  void drawPrompt(LineEditBuffer buffer) {
    hideCursor();
    const prefix = '(hsa) ';

    moveCursorToColumn(0);
    setForegroundColor(ConsoleColor.brightBlue);
    write(prefix);
    resetColorAttributes();
    setForegroundColor(ConsoleColor.brightGreen);

    eraseCursorToEnd();
    if (buffer.completionText.isNotEmpty) {
      write(buffer.text.substring(0, buffer.index));
      setForegroundColor(ConsoleColor.brightWhite);
      write(buffer.completionText);
      setForegroundColor(ConsoleColor.brightGreen);
      write(buffer.text.substring(buffer.index));
    } else {
      write(buffer.text);
    }

    moveCursorToColumn(prefix.length + buffer.index);
    showCursor();
  }
}

class ReadLineResult {
  final String text;
  final bool wasCancelled;
  final bool shouldExit;

  ReadLineResult(this.text, this.wasCancelled, this.shouldExit);
}

/// Handler of a new key stroke when editing a line.
abstract class KeyHandler {
  bool handleKey(LineEditBuffer buffer, Key key);
}

/// Handles cursor navigation.
class BashNavigationKeyHandler extends KeyHandler {
  bool handleKey(LineEditBuffer buffer, Key key) {
    if (!key.isControl) return false;

    switch (key.controlChar) {
      case ControlCharacter.arrowLeft:
      case ControlCharacter.ctrlB:
        buffer.moveLeft();
        return true;
      case ControlCharacter.arrowRight:
      case ControlCharacter.ctrlF:
        buffer.moveRight();
        return true;
      case ControlCharacter.wordLeft:
        buffer.moveWordLeft();
        return true;
      case ControlCharacter.wordRight:
        buffer.moveWordRight();
        return true;
      case ControlCharacter.home:
      case ControlCharacter.ctrlA:
        buffer.moveStart();
        return true;
      case ControlCharacter.end:
      case ControlCharacter.ctrlE:
        buffer.moveEnd();
        return true;
      default:
        return false;
    }
  }
}

/// Handles history navigation.
class BashHistoryKeyHandler extends KeyHandler {
  ScrollbackBuffer history;

  BashHistoryKeyHandler(this.history);

  bool handleKey(LineEditBuffer buffer, Key key) {
    if (!key.isControl) return false;

    switch (key.controlChar) {
      case ControlCharacter.ctrlP:
      case ControlCharacter.arrowUp:
        buffer.replaceWith(history.up(buffer.text));
        return true;
      case ControlCharacter.ctrlN:
      case ControlCharacter.arrowDown:
        final temp = history.down();
        if (temp != null) {
          buffer.replaceWith(temp);
        }
        return true;
      default:
        return false;
    }
  }
}

/// Handles text edits.
class BashEditKeyHandler extends KeyHandler {
  bool handleKey(LineEditBuffer buffer, Key key) {
    if (!key.isControl) {
      buffer.insert(key.char);
      return true;
    }

    // TODO: Add support for <alt-d> (delete word).
    switch (key.controlChar) {
      case ControlCharacter.backspace:
      case ControlCharacter.ctrlH:
        buffer.backspace();
        return true;
      case ControlCharacter.ctrlU:
        buffer.truncateLeft();
        return true;
      case ControlCharacter.ctrlK:
        buffer.truncateRight();
        return true;
      case ControlCharacter.delete:
      case ControlCharacter.ctrlD:
        final wasDeleted = buffer.delete();
        return wasDeleted;
      default:
        return false;
    }
  }
}

/// Represents the state of [Console.readLine] while editing the line.
class LineEditBuffer {
  /// The _text that was so far entered.
  String _text = '';

  /// The _index into [_text] where the editing cursor is currently being drawn.
  int _index = 0;

  /// The _text to display as inline completion.
  String completionText = '';

  LineEditBuffer();

  String get text => _text;

  int get index => _index;

  void moveWordLeft() {
    if (_index > 0) {
      final textLeftOfCursor = _text.substring(0, _index - 1);
      final lastSpace = textLeftOfCursor.lastIndexOf(' ');
      _index = lastSpace != -1 ? lastSpace + 1 : 0;
    }
  }

  void moveWordRight() {
    if (_index < _text.length) {
      final textRightOfCursor = _text.substring(_index + 1);
      final nextSpace = textRightOfCursor.indexOf(' ');
      _index = nextSpace != -1
          ? min(_index + nextSpace + 2, _text.length)
          : _text.length;
    }
  }

  void moveLeft() {
    if (_index > 0) _index--;
  }

  void moveRight() {
    if (_index < _text.length) _index++;
  }

  void moveStart() {
    _index = 0;
  }

  void moveEnd() {
    _index = _text.length;
  }

  void replaceWith(String newtext) {
    _text = newtext;
    _index = _text.length;
  }

  void truncateRight() {
    _text = _text.substring(0, _index);
  }

  void truncateLeft() {
    _text = _text.substring(_index, _text.length);
    _index = 0;
  }

  void backspace() {
    if (_index > 0) {
      _text = _text.substring(0, _index - 1) + _text.substring(_index);
      _index--;
    }
  }

  bool delete() {
    if (_index < _text.length) {
      _text = _text.substring(0, _index) + _text.substring(_index + 1);
      return true;
    }
    return false;
  }

  void insert(String chars) {
    if (_index == _text.length) {
      _text += chars;
    } else {
      _text = _text.substring(0, _index) + chars + _text.substring(_index);
    }
    _index += chars.length;
  }
}
