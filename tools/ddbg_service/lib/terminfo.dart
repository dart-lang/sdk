// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library terminfo;

import 'dart:convert';
import 'dart:io';

int _tputGetInteger(String capName) {
  var result = Process.runSync('tput',  ['$capName'], stdoutEncoding:UTF8);
  if (result.exitCode != 0) {
    return 0;
  }
  return int.parse(result.stdout);
}

String _tputGetSequence(String capName) {
  var result = Process.runSync('tput',  ['$capName'], stdoutEncoding:UTF8);
  if (result.exitCode != 0) {
    return '';
  }
  return result.stdout;
}

class TermInfo {
  TermInfo() {
    resize();
  }

  int get lines => _lines;
  int get cols => _cols;

  int _lines;
  int _cols;

  void resize() {
    _lines = _tputGetInteger('lines');
    _cols = _tputGetInteger('cols');
  }

  // Back one character.
  final String cursorBack = _tputGetSequence('cub1');

  // Forward one character.
  final String cursorForward = _tputGetSequence('cuf1');

  // Up one character.
  final String cursorUp = _tputGetSequence('cuu1');

  // Down one character.
  final String cursorDown = _tputGetSequence('cud1');

  // Clear to end of line.
  final String clrEOL = _tputGetSequence('el');

  // Clear screen and home cursor.
  final String clear = _tputGetSequence('clear');
}
