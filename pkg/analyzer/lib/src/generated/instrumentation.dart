// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.instrumentation;

import 'java_core.dart';

/**
 * The class `Instrumentation` implements support for logging instrumentation information.
 *
 * Instrumentation information consists of information about specific operations. Those operations
 * can range from user-facing operations, such as saving the changes to a file, to internal
 * operations, such as tokenizing source code. The information to be logged is gathered by
 * [InstrumentationBuilder], created by one of the static methods on
 * this class such as [builder] or [builder].
 *
 * Note, however, that until an instrumentation logger is installed using the method
 * [setLogger], all instrumentation data will be lost.
 *
 * <b>Example</b>
 *
 * To collect metrics about how long it took to save a file, you would write something like the
 * following:
 *
 * <pre>
 * InstrumentationBuilder instrumentation = Instrumentation.builder(this.getClass());
 * // save the file
 * instrumentation.metric("chars", fileLength).log();
 * </pre>
 * The `Instrumentation.builder` method creates a new [InstrumentationBuilder
 ] and records the time at which it was created. The
 * [InstrumentationBuilder#metric] appends the information specified by the
 * arguments and records the time at which the method is called so that the time to complete the
 * save operation can be calculated. The `log` method tells the builder that all of the data
 * has been collected and that the resulting information should be logged.
 *
 * @coverage dart.engine.utilities
 */
class Instrumentation {
  /**
   * A builder that will silently ignore all data and logging requests.
   */
  static final InstrumentationBuilder nullBuilder = new InstrumentationBuilder_18();

  /**
   * An instrumentation logger that can be used when no other instrumentation logger has been
   * configured. This logger will silently ignore all data and logging requests.
   */
  static InstrumentationLogger _NULL_LOGGER = new InstrumentationLogger_19();

  /**
   * The current instrumentation logger.
   */
  static InstrumentationLogger _CURRENT_LOGGER = _NULL_LOGGER;

  /**
   * Create a builder that can collect the data associated with an operation.
   *
   * @param clazz the class performing the operation (not `null`)
   * @return the builder that was created (not `null`)
   */
  static InstrumentationBuilder builder(Type clazz) => _CURRENT_LOGGER.createBuilder(clazz.toString());

  /**
   * Create a builder that can collect the data associated with an operation.
   *
   * @param name the name used to uniquely identify the operation (not `null`)
   * @return the builder that was created (not `null`)
   */
  static InstrumentationBuilder builder2(String name) => _CURRENT_LOGGER.createBuilder(name);

  /**
   * Get the currently active instrumentation logger
   */
  static InstrumentationLogger get logger => _CURRENT_LOGGER;

  /**
   * Is this instrumentation system currently configured to drop instrumentation data provided to
   * it?
   *
   * @return
   */
  static bool get isNullLogger => identical(_CURRENT_LOGGER, _NULL_LOGGER);

  /**
   * Set the logger that should receive instrumentation information to the given logger.
   *
   * @param logger the logger that should receive instrumentation information
   */
  static void set logger(InstrumentationLogger logger) {
    _CURRENT_LOGGER = logger == null ? _NULL_LOGGER : logger;
  }
}

class InstrumentationBuilder_18 implements InstrumentationBuilder {
  InstrumentationBuilder data(String name, bool value) => this;

  InstrumentationBuilder data2(String name, int value) => this;

  InstrumentationBuilder data3(String name, String value) => this;

  InstrumentationBuilder data4(String name, List<String> value) => this;

  InstrumentationLevel get instrumentationLevel => InstrumentationLevel.OFF;

  void log() {
  }

  void log2(int minTimeToLong) {
  }

  InstrumentationBuilder metric(String name, bool value) => this;

  InstrumentationBuilder metric2(String name, int value) => this;

  InstrumentationBuilder metric3(String name, String value) => this;

  InstrumentationBuilder metric4(String name, List<String> value) => this;

  InstrumentationBuilder record(Exception exception) => this;
}

class InstrumentationLogger_19 implements InstrumentationLogger {
  InstrumentationBuilder createBuilder(String name) => Instrumentation.nullBuilder;
}

/**
 * The interface `InstrumentationBuilder` defines the behavior of objects used to collect data
 * about an operation that has occurred and record that data through an instrumentation logger.
 *
 * For an example of using objects that implement this interface, see [Instrumentation].
 *
 * @coverage dart.engine.utilities
 */
abstract class InstrumentationBuilder {
  /**
   * Append the given data to the data being collected by this builder. The information is declared
   * to potentially contain data that is either user identifiable or contains user intellectual
   * property (but is not guaranteed to contain either).
   *
   * @param name the name used to identify the data
   * @param value the value of the data to be collected
   * @return this builder
   */
  InstrumentationBuilder data(String name, bool value);

  /**
   * Append the given data to the data being collected by this builder. The information is declared
   * to potentially contain data that is either user identifiable or contains user intellectual
   * property (but is not guaranteed to contain either).
   *
   * @param name the name used to identify the data
   * @param value the value of the data to be collected
   * @return this builder
   */
  InstrumentationBuilder data2(String name, int value);

  /**
   * Append the given data to the data being collected by this builder. The information is declared
   * to potentially contain data that is either user identifiable or contains user intellectual
   * property (but is not guaranteed to contain either).
   *
   * @param name the name used to identify the data
   * @param value the value of the data to be collected
   * @return this builder
   */
  InstrumentationBuilder data3(String name, String value);

  /**
   * Append the given data to the data being collected by this builder. The information is declared
   * to potentially contain data that is either user identifiable or contains user intellectual
   * property (but is not guaranteed to contain either).
   *
   * @param name the name used to identify the data
   * @param value the value of the data to be collected
   * @return this builder
   */
  InstrumentationBuilder data4(String name, List<String> value);

  /**
   * Answer the [InstrumentationLevel] of this `InstrumentationBuilder`.
   *
   * @return one of [InstrumentationLevel#EVERYTHING], [InstrumentationLevel#METRICS],
   *         [InstrumentationLevel#OFF]
   */
  InstrumentationLevel get instrumentationLevel;

  /**
   * Log the data that has been collected. The instrumentation builder should not be used after this
   * method is invoked. The behavior of any method defined on this interface that is used after this
   * method is invoked is undefined.
   */
  void log();

  /**
   * Log the data that has been collected. The instrumentation builder should not be used after this
   * method is invoked. The behavior of any method defined on this interface that is used after this
   * method is invoked is undefined.
   *
   * @param minTimeToLog if the total elapsed time is less than this, do not record
   */
  void log2(int minTimeToLog);

  /**
   * Append the given metric to the data being collected by this builder. The information is
   * declared to contain only metrics data (data that is not user identifiable and does not contain
   * user intellectual property).
   *
   * @param name the name used to identify the data
   * @param value the value of the data to be collected
   * @return this builder
   */
  InstrumentationBuilder metric(String name, bool value);

  /**
   * Append the given metric to the data being collected by this builder. The information is
   * declared to contain only metrics data (data that is not user identifiable and does not contain
   * user intellectual property).
   *
   * @param name the name used to identify the data
   * @param value the value of the data to be collected
   * @return this builder
   */
  InstrumentationBuilder metric2(String name, int value);

  /**
   * Append the given metric to the data being collected by this builder. The information is
   * declared to contain only metrics data (data that is not user identifiable and does not contain
   * user intellectual property).
   *
   * @param name the name used to identify the data
   * @param value the value of the data to be collected
   * @return this builder
   */
  InstrumentationBuilder metric3(String name, String value);

  /**
   * Append the given metric to the data being collected by this builder. The information is
   * declared to contain only metrics data (data that is not user identifiable and does not contain
   * user intellectual property).
   *
   * @param name the name used to identify the data
   * @param value the value of the data to be collected
   * @return this builder
   */
  InstrumentationBuilder metric4(String name, List<String> value);

  /**
   * Append the given exception to the information being collected by this builder. The exception's
   * class name is captured using [metric]. Other aspects of the exception
   * may contain either user identifiable or contains user intellectual property (but is not
   * guaranteed to contain either) and thus are captured using the various data methods such as
   * [data].
   *
   * @param exception the exception (may be `null`)
   */
  InstrumentationBuilder record(Exception exception);
}

/**
 * The instrumentation recording level representing (1) recording [EVERYTHING] recording of
 * all instrumentation data, (2) recording only [METRICS] information, or (3) recording
 * turned [OFF] in which case nothing is recorded.
 *
 * @coverage dart.engine.utilities
 */
class InstrumentationLevel extends Enum<InstrumentationLevel> {
  /** Recording all instrumented information */
  static final InstrumentationLevel EVERYTHING = new InstrumentationLevel('EVERYTHING', 0);

  /** Recording only metrics */
  static final InstrumentationLevel METRICS = new InstrumentationLevel('METRICS', 1);

  /** Nothing recorded */
  static final InstrumentationLevel OFF = new InstrumentationLevel('OFF', 2);

  static final List<InstrumentationLevel> values = [EVERYTHING, METRICS, OFF];

  static InstrumentationLevel fromString(String str) {
    if (str == "EVERYTHING") {
      return InstrumentationLevel.EVERYTHING;
    }
    if (str == "METRICS") {
      return InstrumentationLevel.METRICS;
    }
    if (str == "OFF") {
      return InstrumentationLevel.OFF;
    }
    throw new IllegalArgumentException("Unrecognised InstrumentationLevel");
  }

  InstrumentationLevel(String name, int ordinal) : super(name, ordinal);
}

/**
 * The interface `InstrumentationLogger` defines the behavior of objects that are used to log
 * instrumentation data.
 *
 * For an example of using objects that implement this interface, see [Instrumentation].
 *
 * @coverage dart.engine.utilities
 */
abstract class InstrumentationLogger {
  /**
   * Create a builder that can collect the data associated with an operation identified by the given
   * name.
   *
   * @param name the name used to uniquely identify the operation
   * @return the builder that was created
   */
  InstrumentationBuilder createBuilder(String name);
}