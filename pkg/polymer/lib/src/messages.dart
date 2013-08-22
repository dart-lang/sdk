// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library messages;

import 'dart:json' as json;

import 'package:barback/barback.dart' show TransformLogger;
import 'package:source_maps/span.dart' show Span;
import 'package:logging/logging.dart' show Level;

import 'compiler_options.dart';
import 'utils.dart';

/** Map between error levels and their display color. */
final Map<Level, String> _ERROR_COLORS = (() {
  var colorsMap = new Map<Level, String>();
  colorsMap[Level.SEVERE] = RED_COLOR;
  colorsMap[Level.WARNING] = MAGENTA_COLOR;
  colorsMap[Level.INFO] = GREEN_COLOR;
  return colorsMap;
})();

/** A single message from the compiler. */
class Message {
  final Level level;
  final String message;
  final Span span;
  final bool useColors;

  Message(this.level, this.message, {this.span, this.useColors: false});

  String get kind => level == Level.SEVERE ? 'error' :
      (level == Level.WARNING ? 'warning' : 'info');

  String toString() {
    var output = new StringBuffer();
    bool colors = useColors && _ERROR_COLORS.containsKey(level);
    var levelColor =  _ERROR_COLORS[level];
    if (colors) output.write(levelColor);
    output..write(kind)..write(' ');
    if (colors) output.write(NO_COLOR);

    if (span == null) {
      output.write(message);
    } else {
      output.write(span.getLocationMessage(message, useColors: colors,
          color: levelColor));
    }

    return output.toString();
  }

  String toJson() {
    if (span == null) return toString();
    return json.stringify([{
      'method': kind,
      'params': {
        'file': span.sourceUrl,
        'message': message,
        'line': span.start.line + 1,
        'charStart': span.start.offset,
        'charEnd': span.end.offset,
      }
    }]);
  }
}

/**
 * This class tracks and prints information, warnings, and errors emitted by the
 * compiler.
 */
class Messages implements TransformLogger {
  final CompilerOptions options;
  final bool shouldPrint;

  final List<Message> messages = <Message>[];

  Messages({CompilerOptions options, this.shouldPrint: true})
      : options = options != null ? options : new CompilerOptions();

  /**
   * Creates a new instance of [Messages] which doesn't write messages to
   * the console.
   */
  Messages.silent(): this(shouldPrint: false);

  /**
   * True if we have an error that prevents correct codegen.
   * For example, if we failed to read an input file.
   */
  bool get hasErrors => messages.any((m) => m.level == Level.SEVERE);

  // Convenience methods for testing
  int get length => messages.length;

  Message operator[](int index) => messages[index];

  void clear() {
    messages.clear();
  }

  /** [message] is considered a static compile-time error by the Dart lang. */
  void error(String message, [Span span]) {
    var msg = new Message(Level.SEVERE, message, span: span,
        useColors: options.useColors);

    messages.add(msg);
    printMessage(msg);
  }

  /** [message] is considered a type warning by the Dart lang. */
  void warning(String message, [Span span]) {
    if (options.warningsAsErrors) {
      error(message, span);
    } else {
      var msg = new Message(Level.WARNING, message,
          span: span, useColors: options.useColors);

      messages.add(msg);
      printMessage(msg);
    }
  }

  /// the list of error messages. Empty list, if there are no error messages.
  List<Message> get errors =>
        messages.where((m) => m.level == Level.SEVERE).toList();

  /// the list of warning messages. Empty list if there are no warning messages.
  List<Message> get warnings =>
        messages.where((m) => m.level == Level.WARNING).toList();

  /**
   * [message] at [span] will tell the user about what the compiler
   * is doing.
   */
  void info(String message, [Span span]) {
    var msg = new Message(Level.INFO, message, span: span,
        useColors: options.useColors);

    messages.add(msg);
    if (options.verbose) printMessage(msg);
  }

  void printMessage(msg) {
    if (shouldPrint) print(options.jsonFormat ? msg.toJson() : msg);
  }
}
