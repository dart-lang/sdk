// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Contains a code printer that generates code by recording the source maps.
library source_maps.printer;

import 'package:source_span/source_span.dart' as source_span;

import 'builder.dart';
import 'span.dart';
import 'src/span_wrapper.dart';

const int _LF = 10;
const int _CR = 13;

/// A simple printer that keeps track of offset locations and records source
/// maps locations.
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
    var chars = str.runes.toList();
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
    if (mark is Location || mark is source_span.SourceLocation) {
      loc = LocationWrapper.wrap(mark);
    } else if (mark is Span || mark is source_span.SourceSpan) {
      mark = SpanWrapper.wrap(mark);
      loc = mark.start;
      if (mark.isIdentifier) identifier = mark.text;
    }
    _maps.addLocation(loc,
        new FixedLocation(_buff.length, null, _line, _column), identifier);
    _loc = loc;
  }
}

/// A more advanced printer that keeps track of offset locations to record
/// source maps, but additionally allows nesting of different kind of items,
/// including [NestedPrinter]s, and it let's you automatically indent text.
///
/// This class is especially useful when doing code generation, where different
/// peices of the code are generated independently on separate printers, and are
/// finally put together in the end.
class NestedPrinter implements NestedItem {

  /// Items recoded by this printer, which can be [String] literals,
  /// [NestedItem]s, and source map information like [Location] and [Span].
  List _items = [];

  /// Internal buffer to merge consecutive strings added to this printer.
  StringBuffer _buff;

  /// Current indentation, which can be updated from outside this class.
  int indent;

  /// Item used to indicate that the following item is copied from the original
  /// source code, and hence we should preserve source-maps on every new line.
  static final _ORIGINAL = new Object();

  NestedPrinter([this.indent = 0]);

  /// Adds [object] to this printer. [object] can be a [String],
  /// [NestedPrinter], or anything implementing [NestedItem]. If [object] is a
  /// [String], the value is appended directly, without doing any formatting
  /// changes. If you wish to add a line of code with automatic indentation, use
  /// [addLine] instead.  [NestedPrinter]s and [NestedItem]s are not processed
  /// until [build] gets called later on. We ensure that [build] emits every
  /// object in the order that they were added to this printer.
  ///
  /// The [location] and [span] parameters indicate the corresponding source map
  /// location of [object] in the original input. Only one, [location] or
  /// [span], should be provided at a time.
  ///
  /// [location] can be either a [Location] or a [SourceLocation]. [span] can be
  /// either a [Span] or a [SourceSpan]. Using a [Location] or a [Span] is
  /// deprecated and will be unsupported in version 0.10.0.
  ///
  /// Indicate [isOriginal] when [object] is copied directly from the user code.
  /// Setting [isOriginal] will make this printer propagate source map locations
  /// on every line-break.
  void add(object, {location, span, bool isOriginal: false}) {
    if (object is! String || location != null || span != null || isOriginal) {
      _flush();
      assert(location == null || span == null);
      if (location != null) _items.add(LocationWrapper.wrap(location));
      if (span != null) _items.add(SpanWrapper.wrap(span));
      if (isOriginal) _items.add(_ORIGINAL);
    }

    if (object is String) {
      _appendString(object);
    } else {
      _items.add(object);
    }
  }

  /// Append `2 * indent` spaces to this printer.
  void insertIndent() => _indent(indent);

  /// Add a [line], autoindenting to the current value of [indent]. Note,
  /// indentation is not inferred from the contents added to this printer. If a
  /// line starts or ends an indentation block, you need to also update [indent]
  /// accordingly. Also, indentation is not adapted for nested printers. If
  /// you add a [NestedPrinter] to this printer, its indentation is set
  /// separately and will not include any the indentation set here.
  ///
  /// The [location] and [span] parameters indicate the corresponding source map
  /// location of [object] in the original input. Only one, [location] or
  /// [span], should be provided at a time.
  ///
  /// [location] can be either a [Location] or a [SourceLocation]. [span] can be
  /// either a [Span] or a [SourceSpan]. Using a [Location] or a [Span] is
  /// deprecated and will be unsupported in version 0.10.0.
  void addLine(String line, {location, span}) {
    if (location != null || span != null) {
      _flush();
      assert(location == null || span == null);
      if (location != null) _items.add(LocationWrapper.wrap(location));
      if (span != null) _items.add(SpanWrapper.wrap(span));
    }
    if (line == null) return;
    if (line != '') {
      // We don't indent empty lines.
      _indent(indent);
      _appendString(line);
    }
    _appendString('\n');
  }

  /// Appends a string merging it with any previous strings, if possible.
  void _appendString(String s) {
    if (_buff == null) _buff = new StringBuffer();
    _buff.write(s);
  }

  /// Adds all of the current [_buff] contents as a string item.
  void _flush() {
    if (_buff != null) {
      _items.add(_buff.toString());
      _buff = null;
    }
  }

  void _indent(int indent) {
    for (int i = 0; i < indent; i++) _appendString('  ');
  }

  /// Returns a string representation of all the contents appended to this
  /// printer, including source map location tokens.
  String toString() {
    _flush();
    return (new StringBuffer()..writeAll(_items)).toString();
  }

  /// [Printer] used during the last call to [build], if any.
  Printer printer;

  /// Returns the text produced after calling [build].
  String get text => printer.text;

  /// Returns the source-map information produced after calling [build].
  String get map => printer.map;

  /// Builds the output of this printer and source map information. After
  /// calling this function, you can use [text] and [map] to retrieve the
  /// geenrated code and source map information, respectively.
  void build(String filename) {
    writeTo(printer = new Printer(filename));
  }

  /// Implements the [NestedItem] interface.
  void writeTo(Printer printer) {
    _flush();
    bool propagate = false;
    for (var item in _items) {
      if (item is NestedItem) {
        item.writeTo(printer);
      } else if (item is String) {
        printer.add(item, projectMarks: propagate);
        propagate = false;
      } else if (item is Location || item is Span) {
        printer.mark(item);
      } else if (item == _ORIGINAL) {
        // we insert booleans when we are about to quote text that was copied
        // from the original source. In such case, we will propagate marks on
        // every new-line.
        propagate = true;
      } else {
        throw new UnsupportedError('Unknown item type: $item');
      }
    }
  }
}

/// An item added to a [NestedPrinter].
abstract class NestedItem {
  /// Write the contents of this item into [printer].
  void writeTo(Printer printer);
}
