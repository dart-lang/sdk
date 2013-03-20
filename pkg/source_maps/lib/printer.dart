// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Contains a code printer that generates code by recording the source maps.
library source_maps.printer;

import 'dart:utf' show stringToCodepoints;
import 'builder.dart';
import 'span.dart';

const int _LF = 10;
const int _CR = 13;

/// A printer that keeps track of offset locations and records source maps
/// locations.
class Printer {
  final String filename;
  final StringBuffer _buff = new StringBuffer();
  final SourceMapBuilder _maps = new SourceMapBuilder();
  String get text => _buff.toString();
  String get map => _maps.toJson(filename);

  /// Current source location mapping.
  Location _loc;

  /// Current line in the buffer;
  int _line = 0;

  /// Current column in the buffer.
  int _column = 0;

  Printer(this.filename);

  /// Add [str] contents to the output, tracking new lines to track correct
  /// positions for span locations. When [projectMarks] is true, this method
  /// adds a source map location on each new line, projecting that every new
  /// line in the target file (printed here) corresponds to a new line in the
  /// source file.
  void add(String str, {projectMarks: false}) {
    var chars = stringToCodepoints(str);
    var length = chars.length;
    for (int i = 0; i < length; i++) {
      var c = chars[i];
      if (c == _LF || (c == _CR && (i + 1 == length || chars[i + 1] != _LF))) {
        // Return not followed by line-feed is treated as a new line.
        _line++;
        _column = 0;
        if (projectMarks && _loc != null) {
          if (_loc is FixedLocation) {
            mark(new FixedLocation(0, _loc.sourceUrl, _loc.line + 1, 0));
          } else if (_loc is FileLocation) {
            var file = (_loc as FileLocation).file;
            mark(new FileLocation(file, file.getOffset(_loc.line + 1, 0)));
          }
        }
      } else {
        _column++;
      }
    }
    _buff.write(str);
  }


  /// Append a [total] number of spaces in the target file. Typically used for
  /// formatting indentation.
  void addSpaces(int total) {
    for (int i = 0; i < total; i++) _buff.write(' ');
    _column += total;
  }

  /// Marks that the current point in the target file corresponds to the [mark]
  /// in the source file, which can be either a [Location] or a [Span]. When the
  /// mark is an identifier's Span, this also records the name of the identifier
  /// in the source map information.
  void mark(mark) {
    var loc;
    var identifier = null;
    if (mark is Location) {
      loc = mark;
    } else if (mark is Span) {
      loc = mark.start;
      if (mark.isIdentifier) identifier = mark.text;
    }
    _maps.addLocation(loc,
        new FixedLocation(_buff.length, null, _line, _column), identifier);
    _loc = loc;
  }
}
