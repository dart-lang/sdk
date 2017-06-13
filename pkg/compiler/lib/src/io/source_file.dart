// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.io.source_file;

import 'dart:convert' show UTF8;
import 'dart:math';
import 'dart:typed_data' show Uint8List;

import 'package:kernel/ast.dart' as kernel show Location, Source;
import 'location_provider.dart' show LocationProvider;
import '../../compiler_new.dart';

/// Represents a file of source code. The content can be either a [String] or
/// a UTF-8 encoded [List<int>] of bytes.
abstract class SourceFile<T> implements Input<T>, LocationProvider {
  /// The absolute URI of the source file.
  Uri get uri;

  InputKind get inputKind => InputKind.utf8;

  kernel.Source cachedKernelSource;

  kernel.Source get kernelSource {
    return cachedKernelSource ??=
        new kernel.Source(lineStarts, slowUtf8ZeroTerminatedBytes())
          ..cachedText = slowText();
  }

  /// The name of the file.
  ///
  /// This is [uri], maybe relativized to a more human-readable form.
  String get filename => uri.toString();

  /// The text content of the file represented as a String
  String slowText();

  /// The content of the file represented as a UTF-8 encoded [List<int>],
  /// terminated with a trailing 0 byte.
  List<int> slowUtf8ZeroTerminatedBytes();

  /// The length of the string representation of this source file, i.e.,
  /// equivalent to [:slowText().length:], but faster.
  int get length;

  /// Sets the string length of this source file. For source files based on
  /// UTF-8 byte arrays, the string length is computed and assigned by the
  /// scanner.
  set length(int v);

  /// A map from line numbers to offsets in the string text representation of
  /// this source file.
  List<int> get lineStarts {
    if (lineStartsCache == null) {
      // When reporting errors during scanning, the line numbers are not yet
      // available and need to be computed using this slow path.
      lineStartsCache = lineStartsFromString(slowText());
    }
    return lineStartsCache;
  }

  /// Sets the line numbers map for this source file. This map is computed and
  /// assigned by the scanner, avoiding a separate traversal of the source file.
  ///
  /// The map contains one additional entry at the end of the file, as if the
  /// source file had one more empty line at the end. This simplifies the binary
  /// search in [getLocation].
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

  kernel.Location getLocation(int offset) {
    return kernelSource.getLocation(null, offset);
  }

  String slowSubstring(int start, int end);

  /// Create a pretty string representation for [message] from a character
  /// range `[start, end]` in this file.
  ///
  /// If [includeSourceLine] is `true` the first source line code line that
  /// contains the range will be included as well as marker characters ('^')
  /// underlining the range.
  ///
  /// Use [colorize] to wrap source code text and marker characters in color
  /// escape codes.
  String getLocationMessage(String message, int start, int end,
      {bool includeSourceLine: true, String colorize(String text)}) {
    if (colorize == null) {
      colorize = (text) => text;
    }
    if (end > length) {
      start = length - 1;
      end = length;
    }

    kernel.Location startLocation = kernelSource.getLocation(null, start);
    kernel.Location endLocation = kernelSource.getLocation(null, end);
    int lineStart = startLocation.line - 1;
    int columnStart = startLocation.column - 1;
    int lineEnd = endLocation.line - 1;
    int columnEnd = endLocation.column - 1;

    StringBuffer buf = new StringBuffer('${filename}:');
    if (start != end || start != 0) {
      // Line/column info is relevant.
      buf.write('${lineStart + 1}:${columnStart + 1}:');
    }
    buf.write('\n$message\n');

    if (start != end && includeSourceLine) {
      if (lineStart == lineEnd) {
        String textLine = kernelSource.getTextLine(startLocation.line);

        int toColumn = min(columnStart + (end - start), textLine.length);
        buf.write(textLine.substring(0, columnStart));
        buf.write(colorize(textLine.substring(columnStart, toColumn)));
        buf.writeln(textLine.substring(toColumn));

        int i = 0;
        for (; i < columnStart; i++) {
          buf.write(' ');
        }

        for (; i < toColumn; i++) {
          buf.write(colorize('^'));
        }
      } else {
        for (int line = lineStart; line <= lineEnd; line++) {
          String textLine = kernelSource.getTextLine(line + 1);
          if (line == lineStart) {
            buf.write(textLine.substring(0, columnStart));
            buf.writeln(colorize(textLine.substring(columnStart)));
          } else if (line == lineEnd) {
            buf.write(colorize(textLine.substring(0, columnEnd)));
            buf.writeln(textLine.substring(columnEnd));
          } else {
            buf.writeln(colorize(textLine));
          }
        }
      }
    }

    return buf.toString();
  }

  int get lines => lineStarts.length - 1;
}

List<int> _zeroTerminateIfNecessary(List<int> bytes) {
  if (bytes.length > 0 && bytes.last == 0) return bytes;
  List<int> result = new Uint8List(bytes.length + 1);
  result.setRange(0, bytes.length, bytes);
  result[result.length - 1] = 0;
  return result;
}

class Utf8BytesSourceFile extends SourceFile<List<int>> {
  final Uri uri;

  /// The UTF-8 encoded content of the source file.
  final List<int> zeroTerminatedContent;

  /// Creates a Utf8BytesSourceFile.
  ///
  /// If possible, the given [content] should be zero-terminated. If it isn't,
  /// the constructor clones the content and adds a trailing 0.
  Utf8BytesSourceFile(this.uri, List<int> content)
      : this.zeroTerminatedContent = _zeroTerminateIfNecessary(content);

  List<int> get data => zeroTerminatedContent;

  String slowText() {
    // Don't convert the trailing zero byte.
    return UTF8.decoder
        .convert(zeroTerminatedContent, 0, zeroTerminatedContent.length - 1);
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
      lengthCache = slowText().length;
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

class StringSourceFile extends SourceFile<String> {
  final Uri uri;
  final String filename;
  final String text;

  StringSourceFile(this.uri, this.filename, this.text);

  StringSourceFile.fromUri(Uri uri, String text)
      : this(uri, uri.toString(), text);

  StringSourceFile.fromName(String filename, String text)
      : this(new Uri(path: filename), filename, text);

  String get data => text;

  int get length => text.length;
  set length(int v) {}

  String slowText() => text;

  List<int> slowUtf8ZeroTerminatedBytes() {
    return _zeroTerminateIfNecessary(UTF8.encode(text));
  }

  String slowSubstring(int start, int end) => text.substring(start, end);
}

/// Binary input data.
class Binary implements Input<List<int>> {
  final Uri uri;
  final List<int> data;

  Binary(this.uri, this.data);

  InputKind get inputKind => InputKind.binary;
}
