// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async" show StreamSubscription, Timer;
import "dart:io" show Platform, ProcessSignal, exit, stdin, stdout;
import "dart:isolate" show RawReceivePort;
import "dart:typed_data" show Uint16List;

class Application {
  int _latestKnownTerminalColumns;
  int _latestKnownTerminalRows;
  RawReceivePort _preventClose;
  StreamSubscription<List<int>> _stdinListen;
  StreamSubscription<ProcessSignal> _sigintListen;
  StreamSubscription<ProcessSignal> _sigwinchListen;
  Timer _timer;
  final Widget _widget;
  _Output _output;
  bool _started = false;

  Application(this._widget) {
    _latestKnownTerminalColumns = stdout.terminalColumns;
    _latestKnownTerminalRows = stdout.terminalLines;
    _preventClose = new RawReceivePort();
    stdin.echoMode = false;
    stdin.lineMode = false;

    _stdinListen = stdin.listen(_stdinListener);
    _sigintListen = ProcessSignal.sigint.watch().listen((ProcessSignal signal) {
      quit();
      exit(0);
    });
    if (!Platform.isWindows) {
      _sigwinchListen =
          ProcessSignal.sigwinch.watch().listen((ProcessSignal signal) {
        _latestKnownTerminalColumns = stdout.terminalColumns;
        _latestKnownTerminalRows = stdout.terminalLines;
        _repaint();
      });
    }
  }

  void _repaint() {
    _output =
        new _Output(_latestKnownTerminalRows, _latestKnownTerminalColumns);
    _widget.print(new WriteOnlyPartialOutput(
        _output, 0, 0, _output.rows, _output.columns));
    _printOutput();
  }

  void _stdinListener(List<int> data) {
    try {
      if (_widget.input(this, data)) {
        _repaint();
      }
    } catch (e) {
      quit();
      rethrow;
    }
  }

  void quit() {
    _gotoMainScreenBuffer();
    _showCursor();
    _timer.cancel();
    _preventClose.close();
    _stdinListen.cancel();
    _sigintListen.cancel();
    _sigwinchListen?.cancel();
  }

  void start() {
    if (_started) throw "Already started!";
    _started = true;

    _gotoAlternativeScreenBuffer();
    _hideCursor();
    _repaint();

    _timer = new Timer.periodic(new Duration(milliseconds: 100), (t) {
      int value = stdout.terminalColumns;
      bool changed = false;
      if (value != _latestKnownTerminalColumns) {
        _latestKnownTerminalColumns = value;
        changed = true;
      }
      value = stdout.terminalLines;
      if (value != _latestKnownTerminalRows) {
        _latestKnownTerminalRows = value;
        changed = true;
      }

      if (changed) {
        _repaint();
      }
    });
  }

  _Output _prevOutput;

  _printOutput() {
    int currentPosRow = -1;
    int currentPosColumn = -1;
    StringBuffer buffer = new StringBuffer();
    if (_prevOutput == null ||
        _prevOutput.columns != _output.columns ||
        _prevOutput.rows != _output.rows) {
      _clearScreenAlt();
      _prevOutput = null;
    }
    for (int row = 0; row < _output.rows; row++) {
      for (int column = 0; column < _output.columns; column++) {
        String char = _output.getChar(row, column);
        int rawModifier = _output.getRawModifiers(row, column);

        if (_prevOutput != null) {
          String prevChar = _prevOutput.getChar(row, column);
          int prevRawModifier = _prevOutput.getRawModifiers(row, column);
          if (prevChar == char && prevRawModifier == rawModifier) continue;
        }

        Modifier modifier = _output.getModifier(row, column);
        switch (modifier) {
          case Modifier.Undefined:
            // Do nothing.
            break;
          case Modifier.Bold:
            buffer.write("${CSI}1m");
            break;
          case Modifier.Italic:
            buffer.write("${CSI}3m");
            break;
          case Modifier.Underline:
            buffer.write("${CSI}4m");
            break;
        }

        ForegroundColor foregroundColor =
            _output.getForegroundColor(row, column);
        switch (foregroundColor) {
          case ForegroundColor.Undefined:
            // Do nothing.
            break;
          case ForegroundColor.Black:
            buffer.write("${CSI}30m");
            break;
          case ForegroundColor.Red:
            buffer.write("${CSI}31m");
            break;
          case ForegroundColor.Green:
            buffer.write("${CSI}32m");
            break;
          case ForegroundColor.Yellow:
            buffer.write("${CSI}33m");
            break;
          case ForegroundColor.Blue:
            buffer.write("${CSI}34m");
            break;
          case ForegroundColor.Magenta:
            buffer.write("${CSI}35m");
            break;
          case ForegroundColor.Cyan:
            buffer.write("${CSI}36m");
            break;
          case ForegroundColor.White:
            buffer.write("${CSI}37m");
            break;
        }

        BackgroundColor backgroundColor =
            _output.getBackgroundColor(row, column);
        switch (backgroundColor) {
          case BackgroundColor.Undefined:
            // Do nothing.
            break;
          case BackgroundColor.Black:
            buffer.write("${CSI}40m");
            break;
          case BackgroundColor.Red:
            buffer.write("${CSI}41m");
            break;
          case BackgroundColor.Green:
            buffer.write("${CSI}42m");
            break;
          case BackgroundColor.Yellow:
            buffer.write("${CSI}43m");
            break;
          case BackgroundColor.Blue:
            buffer.write("${CSI}44m");
            break;
          case BackgroundColor.Magenta:
            buffer.write("${CSI}45m");
            break;
          case BackgroundColor.Cyan:
            buffer.write("${CSI}46m");
            break;
          case BackgroundColor.White:
            buffer.write("${CSI}47m");
            break;
        }

        if (char != null) {
          buffer.write(char);
        } else {
          buffer.write(" ");
        }

        // End old modifier.
        buffer.write("${CSI}0m");

        if (currentPosRow != row || currentPosColumn != column) {
          // 1-indexed.
          _setCursorPosition(row + 1, column + 1);
        }
        stdout.write(buffer.toString());
        buffer.clear();
        currentPosRow = row;
        currentPosColumn = column + 1;
      }
    }

    _prevOutput = _output;
  }

  // "ESC [" is "Control Sequence Introducer" (CSI) according to Wikipedia
  // (https://en.wikipedia.org/wiki/ANSI_escape_code#Escape_sequences).
  static const String CSI = "\x1b[";

  void _setCursorPosition(int row, int column) {
    // "CSI n ; m H": Cursor Position.
    stdout.write("${CSI}${row};${column}H");
  }

  void _gotoAlternativeScreenBuffer() {
    // "CSI ? 1049 h": Enable alternative screen buffer.
    stdout.write("${CSI}?1049h");
  }

  void _gotoMainScreenBuffer() {
    // "CSI ? 1049 l": Disable alternative screen buffer.
    stdout.write("${CSI}?1049l");
  }

  void _clearScreenAlt() {
    _setCursorPosition(0, 0);
    // "CSI n J": Erase in Display. Clears part of the screen.
    // If n is 0 (or missing), clear from cursor to end of screen.
    stdout.write("${CSI}0J");
    _setCursorPosition(0, 0);
  }

  void _hideCursor() {
    // "CSI ? 25 l": DECTCEM Hides the cursor.
    stdout.write("${CSI}?25l");
  }

  void _showCursor() {
    // "CSI ? 25 h": DECTCEM Shows the cursor, from the VT320.
    stdout.write("${CSI}?25h");
  }
}

abstract class Widget {
  void print(WriteOnlyOutput output);
  bool input(Application app, List<int> data);
}

class BoxedWidget extends Widget {
  final Widget _content;
  BoxedWidget(this._content);

  @override
  bool input(Application app, List<int> data) {
    return _content?.input(app, data) ?? false;
  }

  @override
  void print(WriteOnlyOutput output) {
    // Corners.
    output.setCell(0, 0, char: /*"\u250c"*/ "\u250c");
    output.setCell(0, output.columns - 1, char: "\u2510");
    output.setCell(output.rows - 1, 0, char: "\u2514");
    output.setCell(output.rows - 1, output.columns - 1, char: "\u2518");

    // Top and bottom line.
    for (int i = 1; i < output.columns - 1; i++) {
      output.setCell(0, i, char: "\u2500");
      output.setCell(output.rows - 1, i, char: "\u2500");
    }

    // Left and right line
    for (int i = 1; i < output.rows - 1; i++) {
      output.setCell(i, 0, char: "\u2502");
      output.setCell(i, output.columns - 1, char: "\u2502");
    }

    // Reduce all sides by one.
    _content?.print(new WriteOnlyPartialOutput(
        output, 1, 1, output.rows - 2, output.columns - 2));
  }
}

class QuitOnQWidget extends Widget {
  Widget _contentWidget;

  QuitOnQWidget(this._contentWidget);

  @override
  void print(WriteOnlyOutput output) {
    _contentWidget?.print(output);
  }

  @override
  bool input(Application app, List<int> data) {
    if (data.length == 1 && String.fromCharCode(data[0]) == 'q') {
      app.quit();
      return false;
    }
    return _contentWidget?.input(app, data) ?? false;
  }
}

class WithSingleLineBottomWidget extends Widget {
  Widget _contentWidget;
  Widget _bottomWidget;

  WithSingleLineBottomWidget(this._contentWidget, this._bottomWidget);

  @override
  void print(WriteOnlyOutput output) {
    // All but the last row.
    _contentWidget?.print(new WriteOnlyPartialOutput(
        output, 0, 0, output.rows - 1, output.columns));

    // Only that last row.
    _bottomWidget?.print(new WriteOnlyPartialOutput(
        output, output.rows - 1, 0, 1, output.columns));
  }

  @override
  bool input(Application app, List<int> data) {
    bool result = _contentWidget?.input(app, data) ?? false;
    result |= _bottomWidget?.input(app, data) ?? false;
    return result;
  }
}

enum Modifier {
  Undefined,
  Bold,
  Italic,
  Underline,
}

enum ForegroundColor {
  Undefined,
  Black,
  Red,
  Green,
  Yellow,
  Blue,
  Magenta,
  Cyan,
  White,
}

enum BackgroundColor {
  Undefined,
  Black,
  Red,
  Green,
  Yellow,
  Blue,
  Magenta,
  Cyan,
  White,
}

class _Output implements WriteOnlyOutput {
  final int rows;
  final int columns;
  final Uint16List _text;
  final Uint16List _modifiers;

  _Output(this.rows, this.columns)
      : _text = new Uint16List(rows * columns),
        _modifiers = new Uint16List(rows * columns);

  int getPosition(int row, int column) {
    return row * columns + column;
  }

  void setCell(int row, int column,
      {String char,
      Modifier modifier,
      ForegroundColor foregroundColor,
      BackgroundColor backgroundColor}) {
    int position = getPosition(row, column);

    if (char != null) {
      List<int> codeUnits = char.codeUnits;
      assert(codeUnits.length == 1);
      _text[position] = codeUnits.single;
    }

    int outModifier = _modifiers[position];
    if (modifier != null) {
      int mask = 0x03 << 8;
      int value = (modifier.index & 0x03) << 8;
      outModifier &= ~mask;
      outModifier |= value;
    }
    if (foregroundColor != null) {
      int mask = 0xF << 4;
      int value = (foregroundColor.index & 0xF) << 4;
      outModifier &= ~mask;
      outModifier |= value;
    }
    if (backgroundColor != null) {
      int mask = 0xF;
      int value = (backgroundColor.index & 0xF);
      outModifier &= ~mask;
      outModifier |= value;
    }

    _modifiers[position] = outModifier;
  }

  String getChar(int row, int column) {
    int position = getPosition(row, column);
    int char = _text[position];
    if (char > 0) return new String.fromCharCode(char);
    return null;
  }

  int getRawModifiers(int row, int column) {
    int position = getPosition(row, column);
    return _modifiers[position];
  }

  Modifier getModifier(int row, int column) {
    int position = getPosition(row, column);
    int modifier = _modifiers[position];
    int value = (modifier >> 8) & 0x3;
    return Modifier.values[value];
  }

  ForegroundColor getForegroundColor(int row, int column) {
    int position = getPosition(row, column);
    int modifier = _modifiers[position];
    int value = (modifier >> 4) & 0xF;
    return ForegroundColor.values[value];
  }

  BackgroundColor getBackgroundColor(int row, int column) {
    int position = getPosition(row, column);
    int modifier = _modifiers[position];
    int value = modifier & 0xF;
    return BackgroundColor.values[value];
  }
}

abstract class WriteOnlyOutput {
  int get rows;
  int get columns;
  void setCell(int row, int column,
      {String char,
      Modifier modifier,
      ForegroundColor foregroundColor,
      BackgroundColor backgroundColor});
}

class WriteOnlyPartialOutput implements WriteOnlyOutput {
  final WriteOnlyOutput _output;
  final int offsetRow;
  final int offsetColumn;
  final int rows;
  final int columns;
  WriteOnlyPartialOutput(this._output, this.offsetRow, this.offsetColumn,
      this.rows, this.columns) {
    if (offsetRow + rows > _output.rows ||
        offsetColumn + columns > _output.columns) {
      throw "Out of bounds";
    }
  }

  @override
  void setCell(int row, int column,
      {String char,
      Modifier modifier,
      ForegroundColor foregroundColor,
      BackgroundColor backgroundColor}) {
    if (row >= rows || column >= columns) return;
    _output.setCell(row + offsetRow, column + offsetColumn,
        char: char,
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor);
  }
}
