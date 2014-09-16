// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library commando;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:ddbg/terminfo.dart';

typedef List<String> CommandCompleter(List<String> commandParts);

class Commando {
  // Ctrl keys
  static const runeCtrlA   = 0x01;
  static const runeCtrlB   = 0x02;
  static const runeCtrlD   = 0x04;
  static const runeCtrlE   = 0x05;
  static const runeCtrlF   = 0x06;
  static const runeTAB     = 0x09;
  static const runeNewline = 0x0a;
  static const runeCtrlK   = 0x0b;
  static const runeCtrlL   = 0x0c;
  static const runeCtrlN   = 0x0e;
  static const runeCtrlP   = 0x10;
  static const runeCtrlU   = 0x15;
  static const runeCtrlY   = 0x19;
  static const runeESC     = 0x1b;
  static const runeSpace   = 0x20;
  static const runeDEL     = 0x7F;

  StreamController<String> _commandController;

  Stream get commands => _commandController.stream;

  Commando({consoleIn,
            consoleOut,
            this.prompt : '> ',
          this.completer : null}) {
    _stdin = (consoleIn != null ? consoleIn : stdin);
    _stdout = (consoleOut != null ? consoleOut : stdout);
    _commandController = new StreamController<String>(
        onCancel: _onCancel);
    _stdin.echoMode = false;
    _stdin.lineMode = false;
    _screenWidth = _term.cols - 1;
    _writePrompt();
    // TODO(turnidge): Handle errors in _stdin here.
    _stdinSubscription =
        _stdin.transform(UTF8.decoder).listen(_handleText, onDone:_done);
  }

  Future _onCancel() {
    _stdin.echoMode = true;
    _stdin.lineMode = true;
    var future = _stdinSubscription.cancel();
    if (future != null) {
      return future;
    } else {
      return new Future.value();
    }
  }

  // Before terminating, call close() to restore terminal settings.
  void _done() {
    _onCancel().then((_) {
        _commandController.close();
      });
  }
  
  void _handleText(String text) {
    try {
      if (!_promptShown) {
        _bufferedInput.write(text);
        return;
      }

      var runes = text.runes.toList();
      var pos = 0;
      while (pos < runes.length) {
        if (!_promptShown) {
          // A command was processed which hid the prompt.  Buffer
          // the rest of the input.
          //
          // TODO(turnidge): Here and elsewhere in the file I pass
          // runes to String.fromCharCodes.  Does this work?
          _bufferedInput.write(
              new String.fromCharCodes(runes.skip(pos)));
          return;
        }

        var rune = runes[pos];

        // Count consecutive tabs because double-tab is meaningful.
        if (rune == runeTAB) {
          _tabCount++;
        } else {
          _tabCount = 0;
        }

        if (_isControlRune(rune)) {
          pos += _handleControlSequence(runes, pos);
        } else {
          pos += _handleRegularSequence(runes, pos);
        }
      }
    } catch(e, trace) {
      _commandController.addError(e, trace);
    }
  }

  int _handleControlSequence(List<int> runes, int pos) {
    var runesConsumed = 1;  // Most common result.
    var char = runes[pos];
    switch (char) {
      case runeCtrlA:
        _home();
        break;
           
      case runeCtrlB:
        _leftArrow();
        break;

      case runeCtrlD:
        if (_currentLine.length == 0) {
          // ^D on an empty line means quit.
          _stdout.writeln("^D");
          _done();
        } else {
          _delete();
        }
        break;
           
      case runeCtrlE:
        _end();
        break;
           
      case runeCtrlF:
        _rightArrow();
        break;

      case runeTAB:
        if (_complete(_tabCount > 1)) {
          _tabCount = 0;
        }
        break;
      
      case runeNewline:
        _newline();
        break;
      
      case runeCtrlK:
        _kill();
        break;
           
      case runeCtrlL:
        _clearScreen();
        break;
           
      case runeCtrlN:
        _historyNext();
        break;

      case runeCtrlP:
        _historyPrevious();
        break;

      case runeCtrlU:
        _clearLine();
        break;
           
      case runeCtrlY:
        _yank();
        break;
           
      case runeESC:
        // Check to see if this is an arrow key.
        if (pos + 2 < runes.length &&  // must be a 3 char sequence.
            runes[pos + 1] == 0x5b) {  // second char must be '['.
          switch (runes[pos + 2]) {
            case 0x41:  // ^[[A = up arrow
              _historyPrevious();
              runesConsumed = 3;
              break;

            case 0x42:  // ^[[B = down arrow
              _historyNext();
              runesConsumed = 3;
              break;

            case 0x43:  // ^[[C = right arrow
              _rightArrow();
              runesConsumed = 3;
              break;
        
            case 0x44:  // ^[[D = left arrow
              _leftArrow();
              runesConsumed = 3;
              break;

            default:
              // Ignore the escape character.
              break;
          }
        }
        break;

      case runeDEL:
        _backspace();
        break;

      default:
        // Ignore the escape character.
        break;
    }
    return runesConsumed;
  }

  int _handleRegularSequence(List<int> runes, int pos) {
    var len = pos + 1;
    while (len < runes.length && !_isControlRune(runes[len])) {
      len++;
    }
    _addChars(runes.getRange(pos, len));
    return len;
  }

  bool _isControlRune(int char) {
    return (char >= 0x00 && char < 0x20) || (char == 0x7f);
  }

  void _writePromptAndLine() {
    _writePrompt();
    var pos = _writeRange(_currentLine, 0, _currentLine.length);
    _cursorPos = _move(pos, _cursorPos);
  }

  void _writePrompt() {
    _stdout.write(prompt);
  }

  void _addChars(Iterable<int> chars) {
    var newLine = [];
    newLine..addAll(_currentLine.take(_cursorPos))
           ..addAll(chars)
           ..addAll(_currentLine.skip(_cursorPos));
    _update(newLine, (_cursorPos + chars.length));
  }

  void _backspace() {
    if (_cursorPos == 0) {
      return;
    }

    var newLine = [];
    newLine..addAll(_currentLine.take(_cursorPos - 1))
           ..addAll(_currentLine.skip(_cursorPos));
    _update(newLine, (_cursorPos - 1));
  }

  void _delete() {
    if (_cursorPos == _currentLine.length) {
      return;
    }

    var newLine = [];
    newLine..addAll(_currentLine.take(_cursorPos))
           ..addAll(_currentLine.skip(_cursorPos + 1));
    _update(newLine, _cursorPos);
  }

  void _home() {
    _updatePos(0);
  }

  void _end() {
    _updatePos(_currentLine.length);
  }

  void _clearScreen() {
    _stdout.write(_term.clear);
    _term.resize();
    _screenWidth = _term.cols - 1;
    _writePromptAndLine();
  }

  void _kill() {
    var newLine = [];
    newLine.addAll(_currentLine.take(_cursorPos));
    _killBuffer = _currentLine.skip(_cursorPos).toList();
    _update(newLine, _cursorPos);
  }

  void _clearLine() {
    _update([], 0);
  }

  void _yank() {
    var newLine = [];
    newLine..addAll(_currentLine.take(_cursorPos))
           ..addAll(_killBuffer)
           ..addAll(_currentLine.skip(_cursorPos));
    _update(newLine, (_cursorPos + _killBuffer.length));
  }

  static String _trimLeadingSpaces(String line) {
    bool _isSpace(int rune) {
      return rune == runeSpace;
    }
    return new String.fromCharCodes(line.runes.skipWhile(_isSpace));
  }

  static String _sharedPrefix(String one, String two) {
    var len = min(one.length, two.length);
    var runesOne = one.runes.toList();
    var runesTwo = two.runes.toList();
    var pos;
    for (pos = 0; pos < len; pos++) {
      if (runesOne[pos] != runesTwo[pos]) {
        break;
      }
    }
    var shared =  new String.fromCharCodes(runesOne.take(pos));
    return shared;
  }

  bool _complete(bool showCompletions) {
    if (completer == null) {
      return false;
    }

    var linePrefix = _currentLine.take(_cursorPos).toList();
    List<String> commandParts =
        _trimLeadingSpaces(new String.fromCharCodes(linePrefix)).split(' ');
    List<String> completionList = completer(commandParts);
    var completion = '';

    if (completionList.length == 0) {
      // The current line admits no possible completion.
      return false;

    } else if (completionList.length == 1) {
      // There is a single, non-ambiguous completion for the current line.
      completion = completionList[0];

      // If we are at the end of the line, add a space to signal that
      // the completion is unambiguous.
      if (_currentLine.length == _cursorPos) {
        completion = completion + ' ';
      }
    } else {
      // There are ambiguous completions. Find the longest common
      // shared prefix of all of the completions.
      completion = completionList.fold(completionList[0], _sharedPrefix);
    }

    var lastWord = commandParts.last;
    if (completion == lastWord) {
      // The completion does not add anything.
      if (showCompletions) {
        // User hit double-TAB.  Show them all possible completions.
        _move(_cursorPos, _currentLine.length);
        _stdout.writeln();
        _stdout.writeln(completionList);
        _writePromptAndLine();
      }
      return false;
    } else {
      // Apply the current completion.
      var completionRunes = completion.runes.toList();

      var newLine = [];
      newLine..addAll(linePrefix)
             ..addAll(completionRunes.skip(lastWord.length))
             ..addAll(_currentLine.skip(_cursorPos));
      _update(newLine, _cursorPos + completionRunes.length - lastWord.length);
      return true;
    }
  }

  void _newline() {
    _addLineToHistory(_currentLine);
    _linePos = _lines.length;

    _end();
    _stdout.writeln();

    // Call the user's command handler.
    _commandController.add(new String.fromCharCodes(_currentLine));
    
    _currentLine = [];
    _cursorPos = 0;
    if (_promptShown) {
      _writePrompt();
    }
  }

  void _leftArrow() {
    _updatePos(_cursorPos - 1);
  }

  void _rightArrow() {
    _updatePos(_cursorPos + 1);
  }

  void _addLineToHistory(List<int> line) {
    if (_tempLineAdded) {
      _lines.removeLast();
      _tempLineAdded = false;
    }
    if (line.length > 0) {
      _lines.add(line);
    }
  }

  void _addTempLineToHistory(List<int> line) {
    _lines.add(line);
    _tempLineAdded = true;
  }

  void _replaceHistory(List<int> line, int linePos) {
    _lines[linePos] = line;
  }

  void _historyPrevious() {
    if (_linePos == 0) {
      return;
    }

    if (_linePos == _lines.length) {
      // The current in-progress line gets temporarily stored in history.
      _addTempLineToHistory(_currentLine);
    } else {
      // Any edits get committed to history.
      _replaceHistory(_currentLine, _linePos);
    }

    _linePos -= 1;
    var line = _lines[_linePos];
    _update(line, line.length);
  }

  void _historyNext() {
    // For the very first command, _linePos (0) will exceed
    // (_lines.length - 1) (-1) so we use a ">=" here instead of an "==".
    if (_linePos >= (_lines.length - 1)) {
      return;
    }

    // Any edits get committed to history.
    _replaceHistory(_currentLine, _linePos);

    _linePos += 1;
    var line = _lines[_linePos];
    _update(line, line.length);
  }

  void _updatePos(int newCursorPos) {
    if (newCursorPos < 0) {
      return;
    }
    if (newCursorPos > _currentLine.length) {
      return;
    }

    _cursorPos = _move(_cursorPos, newCursorPos);
  }

  void _update(List<int> newLine, int newCursorPos) {
    var pos = _cursorPos;
    var diffPos;
    var sharedLen = min(_currentLine.length, newLine.length);

    // Find first difference.
    for (diffPos = 0; diffPos < sharedLen; diffPos++) {
      if (_currentLine[diffPos] != newLine[diffPos]) {
        break;
      }
    }

    // Move the cursor to where the difference begins.
    pos = _move(pos, diffPos);

    // Write the new text.
    pos = _writeRange(newLine, pos, newLine.length);

    // Clear any extra characters at the end.
    pos = _clearRange(pos, _currentLine.length);

    // Move the cursor back to the input point.
    _cursorPos = _move(pos, newCursorPos);
    _currentLine = newLine;    
  }

  void print(String text) {
    bool togglePrompt = _promptShown;
    if (togglePrompt) {
      hide();
    }
    _stdout.writeln(text);
    if (togglePrompt) {
      show();
    }
  }
  
  void hide() {
    if (!_promptShown) {
      return;
    }
    _promptShown = false;
    // We need to erase everything, including the prompt.
    var curLine = _getLine(_cursorPos);
    var lastLine = _getLine(_currentLine.length);

    // Go to last line.
    if (curLine < lastLine) {
      for (var i = 0; i < (lastLine - curLine); i++) {
        // This moves us to column 0.
        _stdout.write(_term.cursorDown);
      }
      curLine = lastLine;
    } else {
      // Move to column 0.
      _stdout.write('\r');
    }

    // Work our way up, clearing lines.
    while (true) {
      _stdout.write(_term.clrEOL);
      if (curLine > 0) {
        _stdout.write(_term.cursorUp);
      } else {
        break;
      }
    }
  }

  void show() {
    if (_promptShown) {
      return;
    }
    _promptShown = true;
    _writePromptAndLine();

    // If input was buffered while the prompt was hidden, process it
    // now.
    if (!_bufferedInput.isEmpty) {
      var input = _bufferedInput.toString();
      _bufferedInput.clear();
      _handleText(input);
    }
  }

  int _writeRange(List<int> text, int pos, int writeToPos) {
    if (pos >= writeToPos) {
      return pos;
    }
    while (pos < writeToPos) {
      var margin = _nextMargin(pos);
      var limit = min(writeToPos, margin);
      _stdout.write(new String.fromCharCodes(text.getRange(pos, limit)));
      pos = limit;
      if (pos == margin) {
        _stdout.write('\n');
      }
    }
    return pos;
  }

  int _clearRange(int pos, int clearToPos) {
    if (pos >= clearToPos) {
      return pos;
    }
    while (true) {
      var limit = _nextMargin(pos);
      _stdout.write(_term.clrEOL);
      if (limit >= clearToPos) {
        return pos;
      }
      _stdout.write('\n');
      pos = limit;
    }
  }

  int _move(int pos, int newPos) {
    if (pos == newPos) {
      return pos;
    }

    var curCol = _getCol(pos);
    var curLine = _getLine(pos);
    var newCol = _getCol(newPos);
    var newLine = _getLine(newPos);

    if (curLine > newLine) {
      for (var i = 0; i < (curLine - newLine); i++) {
        _stdout.write(_term.cursorUp);
      }
    }
    if (curLine < newLine) {
      for (var i = 0; i < (newLine - curLine); i++) {
        _stdout.write(_term.cursorDown);
      }

      // Moving down resets column to zero, oddly.
      curCol = 0;
    }
    if (curCol > newCol) {
      for (var i = 0; i < (curCol - newCol); i++) {
        _stdout.write(_term.cursorBack);
      }
    }
    if (curCol < newCol) {
      for (var i = 0; i < (newCol - curCol); i++) {
        _stdout.write(_term.cursorForward);
      }
    }

    return newPos;
  }
        
  int _nextMargin(int pos) {
    var truePos = pos + prompt.length;
    return ((truePos ~/ _screenWidth) + 1) * _screenWidth - prompt.length;
  }

  int _getLine(int pos) {
    var truePos = pos + prompt.length;
    return truePos ~/ _screenWidth;
  }

  int _getCol(int pos) {
    var truePos = pos + prompt.length;
    return truePos % _screenWidth;
  }

  Stdin _stdin;
  StreamSubscription _stdinSubscription;
  IOSink _stdout;
  final String prompt;
  bool _promptShown = true;
  final CommandCompleter completer;
  TermInfo _term = new TermInfo();

  // TODO(turnidge): See if we can get screen resize events.
  int _screenWidth;
  List<int> _currentLine = [];  // A list of runes.
  StringBuffer _bufferedInput = new StringBuffer();
  List<List<int>> _lines = [];

  // When using the command history, the current line is temporarily
  // added to the history to allow the user to return to it.  This
  // values tracks whether the history has a temporary line at the end.
  bool _tempLineAdded = false;
  int _linePos = 0;
  int _cursorPos = 0;
  int _tabCount = 0;
  List<int> _killBuffer = [];
}


// Demo code.


List<String> _myCompleter(List<String> commandTokens) {
  List<String> completions = new List<String>();

  // First word completions.
  if (commandTokens.length <= 1) {
    String prefix = '';
    if (commandTokens.length == 1) {
      prefix = commandTokens.first;
    }
    if ('quit'.startsWith(prefix)) {
      completions.add('quit');
    }
    if ('help'.startsWith(prefix)) {
      completions.add('help');
    }
    if ('happyface'.startsWith(prefix)) {
      completions.add('happyface');
    }
  }

  // Complete 'foobar' or 'gondola' anywhere in string.
  String lastWord = commandTokens.last;
  if ('foobar'.startsWith(lastWord)) {
    completions.add('foobar');
  }
  if ('gondola'.startsWith(lastWord)) {
    completions.add('gondola');
  }

  return completions;
}


int _helpCount = 0;
Commando cmdo;
var cmdoSubscription;


void _handleCommand(String rawCommand) {
  String command = rawCommand.trim();
  cmdo.hide();
  if (command == 'quit') {
    var future = cmdoSubscription.cancel();
    if (future != null) {
      future.then((_) {
          print('Exiting');
          exit(0);
        });
    } else {
      print('Exiting');
      exit(0);
    }
  } else if (command == 'help') {
    switch (_helpCount) {
      case 0:
        print('I will not help you.');
        break;
      case 1:
        print('I mean it.');
        break;
      case 2:
        print('Seriously.');
        break;
      case 100:
        print('Well now.');
        break;
      default:
        print("Okay.  Type 'quit' to quit");
        break;
    }
    _helpCount++;
  } else if (command == 'happyface') {
    print(':-)');
  } else {
    print('Received command($command)');
  }
  cmdo.show();
}


void main() {
  print('[Commando demo]');
  cmdo = new Commando(completer:_myCompleter);
  cmdoSubscription = cmdo.commands.listen(_handleCommand);
}
