// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Message logging.
library log;

import 'dart:async';
import 'dart:io';
import 'io.dart';

typedef LogFn(Entry entry);
final Map<Level, LogFn> _loggers = new Map<Level, LogFn>();

/// The list of recorded log messages. Will only be recorded if
/// [recordTranscript()] is called.
List<Entry> _transcript;

/// An enum type for defining the different logging levels. By default, [ERROR]
/// and [WARNING] messages are printed to sterr. [MESSAGE] messages are printed
/// to stdout, and others are ignored.
class Level {
  /// An error occurred and an operation could not be completed. Usually shown
  /// to the user on stderr.
  static const ERROR = const Level._("ERR ");

  /// Something unexpected happened, but the program was able to continue,
  /// though possibly in a degraded fashion.
  static const WARNING = const Level._("WARN");

  /// A message intended specifically to be shown to the user.
  static const MESSAGE = const Level._("MSG ");

  /// Some interaction with the external world occurred, such as a network
  /// operation, process spawning, or file IO.
  static const IO = const Level._("IO  ");

  /// Fine-grained and verbose additional information. Can be used to provide
  /// program state context for other logs (such as what pub was doing when an
  /// IO operation occurred) or just more detail for an operation.
  static const FINE = const Level._("FINE");

  const Level._(this.name);
  final String name;

  String toString() => name;
  int get hashCode => name.hashCode;
}

/// A single log entry.
class Entry {
  final Level level;
  final List<String> lines;

  Entry(this.level, this.lines);
}

/// Logs [message] at [Level.ERROR].
void error(message) => write(Level.ERROR, message);

/// Logs [message] at [Level.WARNING].
void warning(message) => write(Level.WARNING, message);

/// Logs [message] at [Level.MESSAGE].
void message(message) => write(Level.MESSAGE, message);

/// Logs [message] at [Level.IO].
void io(message) => write(Level.IO, message);

/// Logs [message] at [Level.FINE].
void fine(message) => write(Level.FINE, message);

/// Logs [message] at [level].
void write(Level level, message) {
  if (_loggers.isEmpty) showNormal();

  var lines = message.toString().split(NEWLINE_PATTERN);
  var entry = new Entry(level, lines);

  var logFn = _loggers[level];
  if (logFn != null) logFn(entry);

  if (_transcript != null) _transcript.add(entry);
}

/// Logs an asynchronous IO operation. Logs [startMessage] before the operation
/// starts, then when [operation] completes, invokes [endMessage] with the
/// completion value and logs the result of that. Returns a future that
/// completes after the logging is done.
///
/// If [endMessage] is omitted, then logs "Begin [startMessage]" before the
/// operation and "End [startMessage]" after it.
Future ioAsync(String startMessage, Future operation,
               [String endMessage(value)]) {
  if (endMessage == null) {
    io("Begin $startMessage.");
  } else {
    io(startMessage);
  }

  return operation.then((result) {
    if (endMessage == null) {
      io("End $startMessage.");
    } else {
      io(endMessage(result));
    }
    return result;
  });
}

/// Logs the spawning of an [executable] process with [arguments] at [IO]
/// level.
void process(String executable, List<String> arguments) {
  io("Spawning $executable ${Strings.join(arguments, ' ')}");
}

/// Logs the results of running [executable].
void processResult(String executable, PubProcessResult result) {
  // Log it all as one message so that it shows up as a single unit in the logs.
  var buffer = new StringBuffer();
  buffer.add("Finished $executable. Exit code ${result.exitCode}.");

  dumpOutput(String name, List<String> output) {
    if (output.length == 0) {
      buffer.add("Nothing output on $name.");
    } else {
      buffer.add("$name:");
      var numLines = 0;
      for (var line in output) {
        if (++numLines > 1000) {
          buffer.add('[${output.length - 1000}] more lines of output '
                     'truncated...]');
          break;
        }

        buffer.add(line);
      }
    }
  }

  dumpOutput("stdout", result.stdout);
  dumpOutput("stderr", result.stderr);

  io(buffer.toString());
}

/// Enables recording of log entries.
void recordTranscript() {
  _transcript = <Entry>[];
}

/// If [recordTranscript()] was called, then prints the previously recorded log
/// transcript to stderr.
void dumpTranscript() {
  if (_transcript == null) return;

  stderr.writeString('---- Log transcript ----\n');
  for (var entry in _transcript) {
    _logToStderrWithLabel(entry);
  }
  stderr.writeString('---- End log transcript ----\n');
}

/// Sets the verbosity to "normal", which shows errors, warnings, and messages.
void showNormal() {
  _loggers[Level.ERROR]   = _logToStderr;
  _loggers[Level.WARNING] = _logToStderr;
  _loggers[Level.MESSAGE] = _logToStdout;
  _loggers[Level.IO]      = null;
  _loggers[Level.FINE]    = null;
}

/// Sets the verbosity to "io", which shows errors, warnings, messages, and IO
/// event logs.
void showIO() {
  _loggers[Level.ERROR]   = _logToStderrWithLabel;
  _loggers[Level.WARNING] = _logToStderrWithLabel;
  _loggers[Level.MESSAGE] = _logToStdoutWithLabel;
  _loggers[Level.IO]      = _logToStderrWithLabel;
  _loggers[Level.FINE]    = null;
}

/// Sets the verbosity to "all", which logs ALL the things.
void showAll() {
  _loggers[Level.ERROR]   = _logToStderrWithLabel;
  _loggers[Level.WARNING] = _logToStderrWithLabel;
  _loggers[Level.MESSAGE] = _logToStdoutWithLabel;
  _loggers[Level.IO]      = _logToStderrWithLabel;
  _loggers[Level.FINE]    = _logToStderrWithLabel;
}

/// Log function that prints the message to stdout.
void _logToStdout(Entry entry) {
  _logToStream(stdout, entry, showLabel: false);
}

/// Log function that prints the message to stdout with the level name.
void _logToStdoutWithLabel(Entry entry) {
  _logToStream(stdout, entry, showLabel: true);
}

/// Log function that prints the message to stderr.
void _logToStderr(Entry entry) {
  _logToStream(stderr, entry, showLabel: false);
}

/// Log function that prints the message to stderr with the level name.
void _logToStderrWithLabel(Entry entry) {
  _logToStream(stderr, entry, showLabel: true);
}

void _logToStream(OutputStream stream, Entry entry, {bool showLabel}) {
  bool firstLine = true;
  for (var line in entry.lines) {
    if (showLabel) {
      if (firstLine) {
        stream.writeString(entry.level.name);
        stream.writeString(': ');
      } else {
        stream.writeString('    | ');
      }
    }

    stream.writeString(line);
    stream.writeString('\n');

    firstLine = false;
  }
}
