// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.io.source_file;

import 'dart:math';
import 'dart:convert' show UTF8;
import 'dart:typed_data' show Uint8List;

import 'line_column_provider.dart';

/**
 * Represents a file of source code. The content can be either a [String] or
 * a UTF-8 encoded [List<int>] of bytes.
 */
abstract class SourceFile implements LineColumnProvider {
  /// The absolute URI of the source file.
  Uri get uri;

  /// The name of the file.
  ///
  /// This is [uri], maybe relativized to a more human-readable form.
  String get filename => uri.toString();

  /** The text content of the file represented as a String. */
  String slowText();

  /**
   * The content of the file represented as a UTF-8 encoded [List<int>],
   * terminated with a trailing 0 byte.
   */
  List<int> slowUtf8ZeroTerminatedBytes();

  /**
   * The length of the string representation of this source file, i.e.,
   * equivalent to [:slowText().length:], but faster.
   */
  int get length;

  /**
   * Sets the string length of this source file. For source files based on UTF-8
   * byte arrays, the string length is computed and assigned by the scanner.
   */
  set length(int v);

  /**
   * A map from line numbers to offsets in the string text representation of
   * this source file.
   */
  List<int> get lineStarts {
    if (lineStartsCache == null) {
      // When reporting errors during scanning, the line numbers are not yet
      // available and need to be computed using this slow path.
      lineStartsCache = lineStartsFromString(slowText());
    }
    return lineStartsCache;
  }

  /**
   * Sets the line numbers map for this source file. This map is computed and
   * assigned by the scanner, avoiding a separate traversal of the source file.
   *
   * The map contains one additional entry at the end of the file, as if the
   * source file had one more empty line at the end. This simplifies the binary
   * search in [getLine].
   */
  set lineStarts(List<int> v) => lineStartsCache = v;

  List<int> lineStartsCache;

  List<int> lineStartsFromString(String text) {
    var starts = [0];
    var index = 0;
    while (index < text.length) {
      index = text.indexOf('\n', index) + 1;
      if (index <= 0) break;
      starts.add(index);
    }
    starts.add(text.length + 1); // One additional line start at the end.
    return starts;
  }

  /**
   * Returns the line number for the offset [position] in the string
   * representation of this source file.
   */
  int getLine(int position) {
    List<int> starts = lineStarts;
    if (position < 0 || starts.last <= position) {
      throw 'bad position #$position in file $filename with '
            'length ${length}.';
    }
    int first = 0;
    int count = starts.length;
    while (count > 1) {
      int step = count ~/ 2;
      int middle = first + step;
      int lineStart = starts[middle];
      if (position < lineStart) {
        count = step;
      } else {
        first = middle;
        count -= step;
      }
    }
    return first;
  }

  /**
   * Returns the column number for the offset [position] in the string
   * representation of this source file.
   */
  int getColumn(int line, int position) {
    return position - lineStarts[line];
  }

  String slowSubstring(int start, int end);

  /**
   * Create a pretty string representation for [message] from a character
   * range `[start, end]` in this file.
   *
   * If [includeSourceLine] is `true` the first source line code line that
   * contains the range will be included as well as marker characters ('^')
   * underlining the range.
   *
   * Use [colorize] to wrap source code text and marker characters in color
   * escape codes.
   */
  String getLocationMessage(String message, int start, int end,
                            {bool includeSourceLine: true,
                             String colorize(String text)}) {
    if (colorize == null) {
      colorize = (text) => text;
    }
    var line = getLine(start);
    var column = getColumn(line, start);

    var buf = new StringBuffer('${filename}:');
    if (start != end || start != 0) {
      // Line/column info is relevant.
      buf.write('${line + 1}:${column + 1}:');
    }
    buf.write('\n$message\n');

    if (start != end && includeSourceLine) {
      String textLine;
      // +1 for 0-indexing, +1 again to avoid the last line of the file
      if ((line + 2) < lineStarts.length) {
        textLine = slowSubstring(lineStarts[line], lineStarts[line+1]);
      } else {
        textLine = '${slowSubstring(lineStarts[line], length)}\n';
      }

      int toColumn = min(column + (end-start), textLine.length);
      buf.write(textLine.substring(0, column));
      buf.write(colorize(textLine.substring(column, toColumn)));
      buf.write(textLine.substring(toColumn));

      int i = 0;
      for (; i < column; i++) {
        buf.write(' ');
      }

      for (; i < toColumn; i++) {
        buf.write(colorize('^'));
      }
    }

    return buf.toString();
  }
}

List<int> _zeroTerminateIfNecessary(List<int> bytes) {
  if (bytes.length > 0 && bytes.last == 0) return bytes;
  List<int> result = new Uint8List(bytes.length + 1);
  result.setRange(0, bytes.length, bytes);
  result[result.length - 1] = 0;
  return result;
}

class Utf8BytesSourceFile extends SourceFile {
  final Uri uri;

  /** The UTF-8 encoded content of the source file. */
  final List<int> zeroTerminatedContent;

  /**
   * Creates a Utf8BytesSourceFile.
   *
   * If possible, the given [content] should be zero-terminated. If it isn't,
   * the constructor clones the content and adds a trailing 0.
   */
  Utf8BytesSourceFile(this.uri, List<int> content)
    : this.zeroTerminatedContent = _zeroTerminateIfNecessary(content);

  String slowText() {
    // Don't convert the trailing zero byte.
    return UTF8.decoder.convert(
        zeroTerminatedContent, 0, zeroTerminatedContent.length - 1);
  }

  List<int> slowUtf8ZeroTerminatedBytes() => zeroTerminatedContent;

  String slowSubstring(int start, int end) {
    // TODO(lry): to make this faster, the scanner could record the UTF-8 slack
    // for all positions of the source text. We could use [:content.sublist:].
    return slowText().substring(start, end);
  }

  int get length {
    if (lengthCache == -1) {
      // During scanning the length is not yet assigned, so we use a slow path.
      length = slowText().length;
    }
    return lengthCache;
  }
  set length(int v) => lengthCache = v;
  int lengthCache = -1;
}

class CachingUtf8BytesSourceFile extends Utf8BytesSourceFile {
  String cachedText;
  final String filename;

  CachingUtf8BytesSourceFile(Uri uri, this.filename, List<int> content)
      : super(uri, content);

  String slowText() {
    if (cachedText == null) {
      cachedText = super.slowText();
    }
    return cachedText;
  }
}

class StringSourceFile extends SourceFile {
  final Uri uri;
  final String filename;
  final String text;

  StringSourceFile(this.uri, this.filename, this.text);

  StringSourceFile.fromUri(Uri uri, String text)
      : this(uri, uri.toString(), text);

  StringSourceFile.fromName(String filename, String text)
      : this(new Uri(path: filename), filename, text);

  int get length => text.length;
  set length(int v) { }

  String slowText() => text;

  List<int> slowUtf8ZeroTerminatedBytes() {
    return _zeroTerminateIfNecessary(UTF8.encode(text));
  }

  String slowSubstring(int start, int end) => text.substring(start, end);
}
