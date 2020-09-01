// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import "dart:isolate";

class Application {
  int lastKnownTerminalColumns;
  int lastKnownTerminalLines;
  RawReceivePort preventClose;
  StreamSubscription<List<int>> stdinListen;
  StreamSubscription<ProcessSignal> sigintListen;
  StreamSubscription<ProcessSignal> sigwinchListen;
  Timer timer;
  final Widget widget;
  bool started = false;

  Application(this.widget) {
    lastKnownTerminalColumns = stdout.terminalColumns;
    lastKnownTerminalLines = stdout.terminalLines;
    preventClose = new RawReceivePort();
    stdin.echoMode = false;
    stdin.lineMode = false;

    stdinListen = stdin.listen(stdinListener);
    sigintListen = ProcessSignal.sigint.watch().listen((ProcessSignal signal) {
      quit();
      exit(0);
    });
    if (!Platform.isWindows) {
      sigwinchListen =
          ProcessSignal.sigwinch.watch().listen((ProcessSignal signal) {
        lastKnownTerminalColumns = stdout.terminalColumns;
        lastKnownTerminalLines = stdout.terminalLines;
        clearScreenAlt();
        widget.print(this);
      });
    }
  }

  void stdinListener(List<int> data) {
    try {
      widget.input(this, data);
    } catch (e) {
      quit();
      rethrow;
    }
  }

  void quit() {
    gotoMainScreenBuffer();
    showCursor();
    // clearScreenAlt();
    timer.cancel();
    preventClose.close();
    stdinListen.cancel();
    sigintListen.cancel();
    sigwinchListen?.cancel();
  }

  void start() {
    if (started) throw "Already started!";
    started = true;

    gotoAlternativeScreenBuffer();
    hideCursor();
    // clearScreen();
    widget.print(this);
    timer = new Timer.periodic(new Duration(milliseconds: 100), (t) {
      var x = stdout.terminalColumns;
      bool changed = false;
      if (x != lastKnownTerminalColumns) {
        lastKnownTerminalColumns = x;
        changed = true;
      }
      x = stdout.terminalLines;
      if (x != lastKnownTerminalLines) {
        lastKnownTerminalLines = x;
        changed = true;
      }

      if (changed) {
        clearScreenAlt();
        widget.print(this);
      }
    });
  }
}

abstract class Widget {
  void print(Application app);

  void input(Application app, List<int> data) {}
}

// "ESC [" is "Control Sequence Introducer" (CSI) according to Wikipedia
// (https://en.wikipedia.org/wiki/ANSI_escape_code#Escape_sequences).
const String CSI = "\x1b[";

void setCursorPosition(int row, int column) {
  // "CSI n ; m H": Cursor Position.
  stdout.write("${CSI}${row};${column}H");
}

void gotoAlternativeScreenBuffer() {
  // "CSI ? 1049 h": Enable alternative screen buffer.
  stdout.write("${CSI}?1049h");
}

void gotoMainScreenBuffer() {
  // "CSI ? 1049 l": Disable alternative screen buffer.
  stdout.write("${CSI}?1049l");
}

void clearScreen() {
  // "CSI n J": Erase in Display. Clears part of the screen.
  // If n is 2, clear entire screen [...].
  stdout.write("${CSI}2J");
  setCursorPosition(0, 0);
}

void clearScreenAlt() {
  setCursorPosition(0, 0);
  // "CSI n J": Erase in Display. Clears part of the screen.
  // If n is 0 (or missing), clear from cursor to end of screen.
  stdout.write("${CSI}0J");
  setCursorPosition(0, 0);
}

void hideCursor() {
  // "CSI ? 25 l": DECTCEM Hides the cursor.
  stdout.write("${CSI}?25l");
}

void showCursor() {
  // "CSI ? 25 h": DECTCEM Shows the cursor, from the VT320.
  stdout.write("${CSI}?25h");
}

void printAt(int row, int column, String s) {
  setCursorPosition(row, column);
  stdout.write(s);
  setCursorPosition(stdout.terminalLines, stdout.terminalColumns);
}

String colorStringBlack(String s) {
  // "CSI n m": Select Graphic Rendition.
  // m = 0 = Reset / Normal.
  // In in range [30, 37]: Set foreground color.
  // m = 30 = black.
  // In total => start black; print string; reset colors.
  return "${CSI}30m${s}${CSI}0m";
}

String colorStringRed(String s) {
  // See above.
  // m = 31 = red.
  return "${CSI}31m${s}${CSI}0m";
}

String colorStringGreen(String s) {
  // See above.
  // m = 32 = green.
  return "${CSI}32m${s}${CSI}0m";
}

String colorStringYellow(String s) {
  // See above.
  // m = 33 = yellow.
  return "${CSI}33m${s}${CSI}0m";
}

String colorStringBlue(String s) {
  // See above.
  // m = 34 = blue.
  return "${CSI}34m${s}${CSI}0m";
}

String colorStringMagenta(String s) {
  // See above.
  // m = 35 = magenta.
  return "${CSI}35m${s}${CSI}0m";
}

String colorStringCyan(String s) {
  // See above.
  // m = 36 = cyan.
  return "${CSI}36m${s}${CSI}0m";
}

String colorStringWhite(String s) {
  // m = 37 = white.
  return "${CSI}37m${s}${CSI}0m";
}

String colorBackgroundBlack(String s) {
  // "CSI n m": Select Graphic Rendition.
  // m = 0 = Reset / Normal.
  // In in range [40, 47]: Set background color.
  // m = 40 = black.
  // In total => start black; print string; reset colors.
  return "${CSI}40m${s}${CSI}0m";
}

String colorBackgroundRed(String s) {
  // See above.
  // m = 41 = red.
  return "${CSI}41m${s}${CSI}0m";
}

String colorBackgroundGreen(String s) {
  // See above.
  // m = 42 = green.
  return "${CSI}42m${s}${CSI}0m";
}

String colorBackgroundYellow(String s) {
  // See above.
  // m = 43 = yellow.
  return "${CSI}43m${s}${CSI}0m";
}

String colorBackgroundBlue(String s) {
  // See above.
  // m = 44 = blue.
  return "${CSI}44m${s}${CSI}0m";
}

String colorBackgroundMagenta(String s) {
  // See above.
  // m = 45 = magenta.
  return "${CSI}45m${s}${CSI}0m";
}

String colorBackgroundCyan(String s) {
  // See above.
  // m = 46 = cyan.
  return "${CSI}46m${s}${CSI}0m";
}

String colorBackgroundWhite(String s) {
  // See above.
  // m = 47 = white.
  return "${CSI}47m${s}${CSI}0m";
}

String boldString(String s) {
  // "CSI n m": Select Graphic Rendition.
  // m = 0 = Reset / Normal.
  // m = 1 = bold.
  return "${CSI}1m${s}${CSI}0m";
}

String italicString(String s) {
  // "CSI n m": Select Graphic Rendition.
  // m = 0 = Reset / Normal.
  // m = 3 = italic.
  return "${CSI}3m${s}${CSI}0m";
}

/// Note that this doesn't really seem to work.
/// Wikipedia says "Style extensions exist for Kitty, VTE, mintty and iTerm2."
String underlineString(String s) {
  // "CSI n m": Select Graphic Rendition.
  // m = 0 = Reset / Normal.
  // m = 4 = italic.
  return "${CSI}4m${s}${CSI}0m";
}

void drawBox(int row, int column, int length, int height) {
  // Top line
  setCursorPosition(row, column);
  stdout.write("\u250c");
  stdout.write("".padLeft(length - 2, "\u2500"));
  stdout.write("\u2510");

  // Left line
  for (int i = 1; i < height - 1; i++) {
    setCursorPosition(row + i, column);
    stdout.write("\u2502");
  }

  // Right line
  for (int i = 1; i < height - 1; i++) {
    setCursorPosition(row + i, column + length - 1);
    stdout.write("\u2502");
  }

  // Bottom line
  setCursorPosition(row + height - 1, column);
  stdout.write("\u2514");
  stdout.write("".padLeft(length - 2, "\u2500"));
  stdout.write("\u2518");
}
