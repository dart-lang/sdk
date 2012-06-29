// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Provides APIs for debugging and error logging. This library introduces
 * abstractions similar to those used in other languages, such as the Closure JS
 * Logger and java.util.logging.Logger.
 */
#library('logging');

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
  String get fullName() =>
      (parent == null || parent.name == '') ? name : '${parent.fullName}.$name';

  /** Parent of this logger in the hierarchy of loggers. */
  final Logger parent;

  /** Logging [Level] used for entries generated on this logger. */
  Level _level;

  /** Children in the hierarchy of loggers, indexed by their simple names. */
  Map<String, Logger> children;

  /** Handlers used to process log entries in this logger. */
  List<LoggerHandler> _handlers;

  /**
   * Singleton constructor. Calling `new Logger(name)` will return the same
   * actual instance whenever it is called with the same string name.
   */
  factory Logger(String name) {
    if (name.startsWith('.')) {
      throw new IllegalArgumentException("name shouldn't start with a '.'");
    }
    if (_loggers == null) _loggers = <Logger>{};
    if (_loggers.containsKey(name)) return _loggers[name];

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
    final res = new Logger._internal(thisName, parent);
    _loggers[name] = res;
    return res;
  }

  Logger._internal(this.name, this.parent)
      : children = new Map<String, Logger>() {
    if (parent != null) parent.children[name] = this;
  }

  /**
   * Effective level considering the levels established in this logger's parents
   * (when [hierarchicalLoggingEnabled] is true).
   */
  Level get level() {
    if (hierarchicalLoggingEnabled) {
      if (_level != null) return _level;
      if (parent != null) return parent.level;
    }
    return _rootLevel;
  }

  /** Override the level for this particular [Logger] and its children. */
  Level set level(value) {
    if (hierarchicalLoggingEnabled && parent != null) {
      _level = value;
    } else {
      if (parent != null) {
        throw new UnsupportedOperationException(
            'Please set "hierarchicalLoggingEnabled" to true if you want to '
            'change the level on a non-root logger.');
      }
      _rootLevel = value;
    }
  }

  /**
   * Returns an event manager for this [Logger]. You can listen for log messages
   * by adding a [LoggerHandler] to an event from the event manager, for
   * instance:
   *    logger.on.record.add((record) { ... });
   */
  LoggerEvents get on() => new LoggerEvents(this);

  /** Adds a handler to listen whenever a log record is added to this logger. */
  void _addHandler(LoggerHandler handler) {
    if (hierarchicalLoggingEnabled || parent == null) {
      if (_handlers == null) {
        _handlers = new List<LoggerHandler>();
      }
      _handlers.add(handler);
    } else {
      root._addHandler(handler);
    }
  }

  /** Remove a previously added handler. */
  void _removeHandler(LoggerHandler handler) {
    if (hierarchicalLoggingEnabled || parent == null) {
      if (_handlers == null) return;
      int index = _handlers.indexOf(handler);
      if (index != -1) _handlers.removeRange(index, 1);
    } else {
      root._removeHandler(handler);
    }
  }

  /** Removes all handlers previously added to this logger. */
  void _clearHandlers() {
    if (hierarchicalLoggingEnabled || parent == null) {
      _handlers = null;
    } else {
      root._clearHandlers();
    }
  }

  /** Whether a message for [value]'s level is loggable in this logger. */
  bool isLoggable(Level value) => (value >= level);

  /**
   * Adds a log record for a [message] at a particular [logLevel] if
   * `isLoggable(logLevel)` is true. Use this method to create log entries for
   * user-defined levels. To record a message at a predefined level (e.g.
   * [Level.INFO], [Level.WARNING], etc) you can use their specialized methods
   * instead (e.g. [info], [warning], etc).
   */
  // TODO(sigmund): add support for logging exceptions.
  void log(Level logLevel, String message) {
    if (isLoggable(logLevel)) {
      var record = new LogRecord(logLevel, message, fullName);
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
  void finest(String message) => log(Level.FINEST, message);

  /** Log message at level [Level.FINER]. */
  void finer(String message) => log(Level.FINER, message);

  /** Log message at level [Level.FINE]. */
  void fine(String message) => log(Level.FINE, message);

  /** Log message at level [Level.CONFIG]. */
  void config(String message) => log(Level.CONFIG, message);

  /** Log message at level [Level.INFO]. */
  void info(String message) => log(Level.INFO, message);

  /** Log message at level [Level.WARNING]. */
  void warning(String message) => log(Level.WARNING, message);

  /** Log message at level [Level.SEVERE]. */
  void severe(String message) => log(Level.SEVERE, message);

  /** Log message at level [Level.SHOUT]. */
  void shout(String message) => log(Level.SHOUT, message);

  void _publish(LogRecord record) {
    if (_handlers != null) {
      _handlers.forEach((h) => h(record));
    }
  }

  /** Top-level root [Logger]. */
  static get root() => new Logger('');

  /** All [Logger]s in the system. */
  static Map<String, Logger> _loggers;
}


/** Handler callback to process log entries as they are added to a [Logger]. */
typedef void LoggerHandler(LogRecord);


/** Event manager for a [Logger] (holds events that a [Logger] can fire). */
class LoggerEvents {
  final Logger _logger;

  LoggerEvents(this._logger);

  /** Event fired when a log record is added to a [Logger]. */
  LoggerHandlerList get record() => new LoggerHandlerList(_logger);
}


/** List of handlers that will be called on a logger event. */
class LoggerHandlerList {
  Logger _logger;

  LoggerHandlerList(this._logger);

  void add(LoggerHandler handler) => _logger._addHandler(handler);
  void remove(LoggerHandler handler) => _logger._removeHandler(handler);
  void clear() => _logger._clearHandlers();
}


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
class Level implements Comparable, Hashable {

  // TODO(sigmund): mark name/value as 'const' when the language supports it.
  final String name;

  /**
   * Unique value for this level. Used to order levels, so filtering can exclude
   * messages whose level is under certain value.
   */
  final int value;

  const Level(this.name, this.value);

  /** Special key to turn on logging for all levels ([value] = 0). */
  static final Level ALL = const Level('ALL', 0);

  /** Special key to turn off all logging ([value] = 2000). */
  static final Level OFF = const Level('OFF', 2000);

  /** Key for highly detailed tracing ([value] = 300). */
  static final Level FINEST = const Level('FINEST', 300);

  /** Key for fairly detailed tracing ([value] = 400). */
  static final Level FINER = const Level('FINER', 400);

  /** Key for tracing information ([value] = 500). */
  static final Level FINE = const Level('FINE', 500);

  /** Key for static configuration messages ([value] = 700). */
  static final Level CONFIG = const Level('CONFIG', 700);

  /** Key for informational messages ([value] = 800). */
  static final Level INFO = const Level('INFO', 800);

  /** Key for potential problems ([value] = 900). */
  static final Level WARNING = const Level('WARNING', 900);

  /** Key for serious failures ([value] = 1000). */
  static final Level SEVERE = const Level('SEVERE', 1000);

  /** Key for extra debugging loudness ([value] = 1200). */
  static final Level SHOUT = const Level('SHOUT', 1200);

  bool operator ==(Level other) => other != null && value == other.value;
  bool operator <(Level other) => value < other.value;
  bool operator <=(Level other) => value <= other.value;
  bool operator >(Level other) => value > other.value;
  bool operator >=(Level other) => value >= other.value;
  int compareTo(Level other) => value - other.value;
  int hashCode() => value;
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
  final Date time;

  /** Unique sequence number greater than all log records created before it. */
  final int sequenceNumber;

  static int _nextNumber = 0;

  /** Associated exception (if any) when recording errors messages. */
  Exception exception;

  /** Associated exception message (if any) when recording errors messages. */
  String exceptionText;

  LogRecord(
      this.level, this.message, this.loggerName,
      [time, this.exception, this.exceptionText]) :
    this.time = (time == null) ? new Date.now() : time,
    this.sequenceNumber = LogRecord._nextNumber++;
}
