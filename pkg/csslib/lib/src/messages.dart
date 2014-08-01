// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library csslib.src.messages;

import 'package:logging/logging.dart' show Level;
import 'package:source_span/source_span.dart';

import 'options.dart';

// TODO(terry): Remove the global messages, use some object that tracks
//              compilation state.

/** The global [Messages] for tracking info/warnings/messages. */
Messages messages;

// Color constants used for generating messages.
final String GREEN_COLOR = '\u001b[32m';
final String RED_COLOR = '\u001b[31m';
final String MAGENTA_COLOR = '\u001b[35m';
final String NO_COLOR = '\u001b[0m';

/** Map between error levels and their display color. */
final Map<Level, String> _ERROR_COLORS = (() {
  var colorsMap = new Map<Level, String>();
  colorsMap[Level.SEVERE] = RED_COLOR;
  colorsMap[Level.WARNING] = MAGENTA_COLOR;
  colorsMap[Level.INFO] = GREEN_COLOR;
  return colorsMap;
})();

/** Map between error levels and their friendly name. */
final Map<Level, String> _ERROR_LABEL = (() {
  var labels = new Map<Level, String>();
  labels[Level.SEVERE] = 'error';
  labels[Level.WARNING] = 'warning';
  labels[Level.INFO] = 'info';
  return labels;
})();

/** A single message from the compiler. */
class Message {
  final Level level;
  final String message;
  final SourceSpan span;
  final bool useColors;

  Message(this.level, this.message, {SourceSpan span, bool useColors: false})
      : this.span = span, this.useColors = useColors;

  String toString() {
    var output = new StringBuffer();
    bool colors = useColors && _ERROR_COLORS.containsKey(level);
    var levelColor = colors ? _ERROR_COLORS[level] : null;
    if (colors) output.write(levelColor);
    output..write(_ERROR_LABEL[level])..write(' ');
    if (colors) output.write(NO_COLOR);

    if (span == null) {
      output.write(message);
    } else {
      output.write('on ');
      output.write(span.message(message, color: levelColor));
    }

    return output.toString();
  }
}

typedef void PrintHandler(Message obj);

/**
 * This class tracks and prints information, warnings, and errors emitted by the
 * compiler.
 */
class Messages {
  /** Called on every error. Set to blank function to supress printing. */
  final PrintHandler printHandler;

  final PreprocessorOptions options;

  final List<Message> messages = <Message>[];

  Messages({PreprocessorOptions options, this.printHandler: print})
      : options = options != null ? options : new PreprocessorOptions();

  /** Report a compile-time CSS error. */
  void error(String message, SourceSpan span) {
    var msg = new Message(Level.SEVERE, message, span: span,
        useColors: options.useColors);

    messages.add(msg);

    printHandler(msg);
  }

  /** Report a compile-time CSS warning. */
  void warning(String message, SourceSpan span) {
    if (options.warningsAsErrors) {
      error(message, span);
    } else {
      var msg = new Message(Level.WARNING, message, span: span,
          useColors: options.useColors);

      messages.add(msg);
    }
  }

  /** Report and informational message about what the compiler is doing. */
  void info(String message, SourceSpan span) {
    var msg = new Message(Level.INFO, message, span: span,
        useColors: options.useColors);

    messages.add(msg);

    if (options.verbose) printHandler(msg);
  }

  /** Merge [newMessages] to this message lsit. */
  void mergeMessages(Messages newMessages) {
    messages.addAll(newMessages.messages);
    newMessages.messages.where((message) =>
        message.level.value == Level.SEVERE || options.verbose)
        .forEach((message) { printHandler(message); });
  }
}
