// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for logging.
 *
 * For information on installing and importing this library, see the
 * [logging package on pub.dartlang.org]
 * (http://pub.dartlang.org/packages/logging).
 *
 * ## Initializing
 *
 * By default, the logging package does not do anything useful with the
 * log messages. You must configure the logging level and add a handler
 * for the log messages.
 *
 * Here is a simple logging configuration that logs all messages
 * via `print`.
 *
 *     Logger.root.level = Level.ALL;
 *     Logger.root.onRecord.listen((LogRecord rec) {
 *       print('${rec.level.name}: ${rec.time}: ${rec.message}');
 *     });
 *
 * First, set the root [Level]. All messages at or above the level are
 * sent to the [onRecord] stream.
 *
 * Then, listen on the [onRecord] stream for [LogRecord] events. The
 * [LogRecord] class has various properties for the message, error,
 * logger name, and more.
 *
 * ## Logging messages
 *
 * Create a [Logger] with a unique name to easily identify the source
 * of the log messages.
 *
 *     final Logger log = new Logger('MyClassName');
 *
 * Here is an example of logging a debug message and an error:
 *
 *     Future future = doSomethingAsync();
 *     future.then((result) {
 *       log.fine('Got the result: $result');
 *       processResult(result);
 *     })
 *     .catchError((e, stackTrace) => log.severe('Oh noes!', e, stackTrace));
 *
 * See the [Logger] class for the different logging methods.
 */
library logging;

import 'dart:async';
import 'package:collection/wrappers.dart';

/**
 * Whether to allow fine-grain logging and configuration of loggers in a
 * hierarchy. When false, all logging is merged in the root logger.
 */
bool hierarchicalLoggingEnabled = false;

/**
 * Level for the root-logger. This will be the level of all loggers if
 * [hierarchicalLoggingEnabled] is false.
 */
Level _rootLevel = Level.INFO;


/**
 * Use a [Logger] to log debug messages. [Logger]s are named using a
 * hierarchical dot-separated name convention.
 */
class Logger {
  /** Simple name of this logger. */
  final String name;

  /** The full name of this logger, which includes the parent's full name. */
  String get fullName =>
      (parent == null || parent.name == '') ? name : '${parent.fullName}.$name';

  /** Parent of this logger in the hierarchy of loggers. */
  final Logger parent;

  /** Logging [Level] used for entries generated on this logger. */
  Level _level;

  final Map<String, Logger> _children;

  /** Children in the hierarchy of loggers, indexed by their simple names. */
  final Map<String, Logger> children;

  /** Controller used to notify when log entries are added to this logger. */
  StreamController<LogRecord> _controller;

  /**
   * Singleton constructor. Calling `new Logger(name)` will return the same
   * actual instance whenever it is called with the same string name.
   */
  factory Logger(String name) {
    return _loggers.putIfAbsent(name, () => new Logger._named(name));
  }

  factory Logger._named(String name) {
    if (name.startsWith('.')) {
      throw new ArgumentError("name shouldn't start with a '.'");
    }
    // Split hierarchical names (separated with '.').
    int dot = name.lastIndexOf('.');
    Logger parent = null;
    String thisName;
    if (dot == -1) {
      if (name != '') parent = new Logger('');
      thisName = name;
    } else {
      parent = new Logger(name.substring(0, dot));
      thisName = name.substring(dot + 1);
    }
    return new Logger._internal(thisName, parent, new Map<String, Logger>());
  }

  Logger._internal(this.name, this.parent, Map<String, Logger> children) :
    this._children = children,
    this.children = new UnmodifiableMapView(children) {
    if (parent != null) parent._children[name] = this;
  }

  /**
   * Effective level considering the levels established in this logger's parents
   * (when [hierarchicalLoggingEnabled] is true).
   */
  Level get level {
    if (hierarchicalLoggingEnabled) {
      if (_level != null) return _level;
      if (parent != null) return parent.level;
    }
    return _rootLevel;
  }

  /** Override the level for this particular [Logger] and its children. */
  void set level(Level value) {
    if (hierarchicalLoggingEnabled && parent != null) {
      _level = value;
    } else {
      if (parent != null) {
        throw new UnsupportedError(
            'Please set "hierarchicalLoggingEnabled" to true if you want to '
            'change the level on a non-root logger.');
      }
      _rootLevel = value;
    }
  }

  /**
   * Returns an stream of messages added to this [Logger]. You can listen for
   * messages using the standard stream APIs, for instance:
   *    logger.onRecord.listen((record) { ... });
   */
  Stream<LogRecord> get onRecord => _getStream();

  void clearListeners() {
    if (hierarchicalLoggingEnabled || parent == null) {
      if (_controller != null) {
        _controller.close();
        _controller = null;
      }
    } else {
      root.clearListeners();
    }
  }

  /** Whether a message for [value]'s level is loggable in this logger. */
  bool isLoggable(Level value) => (value >= level);

  /**
   * Adds a log record for a [message] at a particular [logLevel] if
   * `isLoggable(logLevel)` is true.
   *
   * Use this method to create log entries for user-defined levels. To record a
   * message at a predefined level (e.g. [Level.INFO], [Level.WARNING], etc) you
   * can use their specialized methods instead (e.g. [info], [warning], etc).
   */
  void log(Level logLevel, String message, [Object error,
                                            StackTrace stackTrace]) {
    if (isLoggable(logLevel)) {
      var record = new LogRecord(logLevel, message, fullName, error,
          stackTrace);

      if (hierarchicalLoggingEnabled) {
        var target = this;
        while (target != null) {
          target._publish(record);
          target = target.parent;
        }
      } else {
        root._publish(record);
      }
    }
  }

  /** Log message at level [Level.FINEST]. */
  void finest(String message, [Object error, StackTrace stackTrace]) =>
      log(Level.FINEST, message, error, stackTrace);

  /** Log message at level [Level.FINER]. */
  void finer(String message, [Object error, StackTrace stackTrace]) =>
      log(Level.FINER, message, error, stackTrace);

  /** Log message at level [Level.FINE]. */
  void fine(String message, [Object error, StackTrace stackTrace]) =>
      log(Level.FINE, message, error, stackTrace);

  /** Log message at level [Level.CONFIG]. */
  void config(String message, [Object error, StackTrace stackTrace]) =>
      log(Level.CONFIG, message, error, stackTrace);

  /** Log message at level [Level.INFO]. */
  void info(String message, [Object error, StackTrace stackTrace]) =>
      log(Level.INFO, message, error, stackTrace);

  /** Log message at level [Level.WARNING]. */
  void warning(String message, [Object error, StackTrace stackTrace]) =>
      log(Level.WARNING, message, error, stackTrace);

  /** Log message at level [Level.SEVERE]. */
  void severe(String message, [Object error, StackTrace stackTrace]) =>
      log(Level.SEVERE, message, error, stackTrace);

  /** Log message at level [Level.SHOUT]. */
  void shout(String message, [Object error, StackTrace stackTrace]) =>
      log(Level.SHOUT, message, error, stackTrace);

  Stream<LogRecord> _getStream() {
    if (hierarchicalLoggingEnabled || parent == null) {
      if (_controller == null) {
        _controller = new StreamController<LogRecord>.broadcast(sync: true);
      }
      return _controller.stream;
    } else {
      return root._getStream();
    }
  }

  void _publish(LogRecord record) {
    if (_controller != null) {
      _controller.add(record);
    }
  }

  /** Top-level root [Logger]. */
  static Logger get root => new Logger('');

  /** All [Logger]s in the system. */
  static final Map<String, Logger> _loggers = <String, Logger>{};
}


/** Handler callback to process log entries as they are added to a [Logger]. */
typedef void LoggerHandler(LogRecord);

/**
 * [Level]s to control logging output. Logging can be enabled to include all
 * levels above certain [Level]. [Level]s are ordered using an integer
 * value [Level.value]. The predefined [Level] constants below are sorted as
 * follows (in descending order): [Level.SHOUT], [Level.SEVERE],
 * [Level.WARNING], [Level.INFO], [Level.CONFIG], [Level.FINE], [Level.FINER],
 * [Level.FINEST], and [Level.ALL].
 *
 * We recommend using one of the predefined logging levels. If you define your
 * own level, make sure you use a value between those used in [Level.ALL] and
 * [Level.OFF].
 */
class Level implements Comparable<Level> {

  final String name;

  /**
   * Unique value for this level. Used to order levels, so filtering can exclude
   * messages whose level is under certain value.
   */
  final int value;

  const Level(this.name, this.value);

  /** Special key to turn on logging for all levels ([value] = 0). */
  static const Level ALL = const Level('ALL', 0);

  /** Special key to turn off all logging ([value] = 2000). */
  static const Level OFF = const Level('OFF', 2000);

  /** Key for highly detailed tracing ([value] = 300). */
  static const Level FINEST = const Level('FINEST', 300);

  /** Key for fairly detailed tracing ([value] = 400). */
  static const Level FINER = const Level('FINER', 400);

  /** Key for tracing information ([value] = 500). */
  static const Level FINE = const Level('FINE', 500);

  /** Key for static configuration messages ([value] = 700). */
  static const Level CONFIG = const Level('CONFIG', 700);

  /** Key for informational messages ([value] = 800). */
  static const Level INFO = const Level('INFO', 800);

  /** Key for potential problems ([value] = 900). */
  static const Level WARNING = const Level('WARNING', 900);

  /** Key for serious failures ([value] = 1000). */
  static const Level SEVERE = const Level('SEVERE', 1000);

  /** Key for extra debugging loudness ([value] = 1200). */
  static const Level SHOUT = const Level('SHOUT', 1200);

  static const List<Level> LEVELS = const
      [ALL, FINEST, FINER, FINE, CONFIG, INFO, WARNING, SEVERE, SHOUT, OFF];

  bool operator ==(Object other) => other is Level && value == other.value;
  bool operator <(Level other) => value < other.value;
  bool operator <=(Level other) => value <= other.value;
  bool operator >(Level other) => value > other.value;
  bool operator >=(Level other) => value >= other.value;
  int compareTo(Level other) => value - other.value;
  int get hashCode => value;
  String toString() => name;
}


/**
 * A log entry representation used to propagate information from [Logger] to
 * individual [Handler]s.
 */
class LogRecord {
  final Level level;
  final String message;

  /** Logger where this record is stored. */
  final String loggerName;

  /** Time when this record was created. */
  final DateTime time;

  /** Unique sequence number greater than all log records created before it. */
  final int sequenceNumber;

  static int _nextNumber = 0;

  /** Associated error (if any) when recording errors messages. */
  final Object error;

  /** Associated stackTrace (if any) when recording errors messages. */
  final StackTrace stackTrace;

  LogRecord(this.level, this.message, this.loggerName, [this.error,
                                                        this.stackTrace])
      : time = new DateTime.now(),
        sequenceNumber = LogRecord._nextNumber++;

  String toString() => '[${level.name}] $loggerName: $message';
}
