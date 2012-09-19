// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** The one true [World]. */
World world;

typedef void MessageHandler(String prefix, String message, SourceSpan span);
typedef void PrintHandler(String message);

/**
 * Should be called exactly once to setup singleton world.
 * Can use world.reset() to reinitialize.
 */
void initializeWorld(var files) {
  assert(world == null);
  world = new World(files);
  world.init();
}

/** Can be thrown on any compiler error and includes source location. */
class CompilerException implements Exception {
  final String _message;
  final SourceSpan _location;

  CompilerException(this._message, this._location);

  String toString() {
    if (_location != null) {
      return 'CompilerException: ${_location.toMessageString(_message)}';
    } else {
      return 'CompilerException: $_message';
    }
  }
}

/** Represents a Dart template "world". */
class World {
  String template;

  var files;

  int errors = 0, warnings = 0;
  bool seenFatal = false;
  MessageHandler messageHandler;
  PrintHandler printHandler;

  World(this.files);

  void reset() {
    errors = warnings = 0;
    seenFatal = false;
    init();
  }

  init() {
  }


  // ********************** Message support ***********************

  void _message(String color, String prefix, String message,
      SourceSpan span, SourceSpan span1, SourceSpan span2, bool throwing) {
    if (messageHandler != null) {
      // TODO(jimhug): Multiple spans cleaner...
      messageHandler(prefix, message, span);
      if (span1 != null) {
        messageHandler(prefix, message, span1);
      }
      if (span2 != null) {
        messageHandler(prefix, message, span2);
      }
    } else {
      final messageWithPrefix = options.useColors
          ? "$color$prefix$_NO_COLOR$message" : "$prefix$message";

      var text = messageWithPrefix;
      if (span != null) {
        text = span.toMessageString(messageWithPrefix);
      }

      String span1Text = span1 != null ?
          span1.toMessageString(messageWithPrefix) : "";
      String span2Text = span2 != null ?
          span2.toMessageString(messageWithPrefix) : "";

      if (printHandler == null) {
        print(text);
        if (span1 != null) {
          print(span1Text);
        }
        if (span2 != null) {
          print(span2Text);
        }
      } else {
        printHandler("${text}\r${span1Text}\r${span2Text}");
      }
    }

    if (throwing) {
      throw new CompilerException("$prefix$message", span);
    }
  }

  /** [message] is considered a static compile-time error by the Dart lang. */
  void error(String message,
      [SourceSpan span, SourceSpan span1, SourceSpan span2]) {
    errors++;
    _message(_RED_COLOR, 'error: ', message,
        span, span1, span2, options.throwOnErrors);
  }

  /** [message] is considered a type warning by the Dart lang. */
  void warning(String message,
      [SourceSpan span, SourceSpan span1, SourceSpan span2]) {
    if (options.warningsAsErrors) {
      error(message, span, span1, span2);
      return;
    }
    warnings++;
    if (options.showWarnings) {
      _message(_MAGENTA_COLOR, 'warning: ', message,
          span, span1, span2, options.throwOnWarnings);
    }
  }

  /** [message] at [location] is so bad we can't generate runnable code. */
  void fatal(String message,
      [SourceSpan span, SourceSpan span1, SourceSpan span2]) {
    errors++;
    seenFatal = true;
    _message(_RED_COLOR, 'fatal: ', message,
        span, span1, span2, options.throwOnFatal || options.throwOnErrors);
  }

  /** [message] at [location] is about a bug in the compiler. */
  void internalError(String message,
      [SourceSpan span, SourceSpan span1, SourceSpan span2]) {
    _message(_NO_COLOR,
        'We are sorry, but...', message, span, span1, span2, true);
  }

  /**
   * [message] at [location] will tell the user about what the compiler
   * is doing.
   */
  void info(String message,
      [SourceSpan span, SourceSpan span1, SourceSpan span2]) {
    if (options.showInfo) {
      _message(_GREEN_COLOR, 'info: ', message, span, span1, span2, false);
    }
  }

  bool get hasErrors => errors > 0;

  withTiming(String name, f()) {
    final sw = new Stopwatch();
    sw.start();
    var result = f();
    sw.stop();
    info('$name in ${sw.elapsedInMs()}msec');
    return result;
  }
}

String _GREEN_COLOR = '\u001b[32m';
String _RED_COLOR = '\u001b[31m';
String _MAGENTA_COLOR = '\u001b[35m';
String _NO_COLOR = '\u001b[0m';
