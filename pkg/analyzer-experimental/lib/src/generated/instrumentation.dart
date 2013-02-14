// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.instrumentation;

import 'java_core.dart';

/**
 * The interface {@code OperationBuilder} defines the behavior of objects used to collect data about
 * an operation that has occurred and record that data through an instrumentation logger.
 * <p>
 * For an example of using objects that implement this interface, see {@link Instrumentation}.
 */
abstract class OperationBuilder {
  /**
   * Log the data that has been collected. The operation builder should not be used after this
   * method is invoked. The behavior of any method defined on this interface that is used after this
   * method is invoked is undefined.
   */
  void log();
  /**
   * Lazily compute and append the given data to the data being collected by this builder.
   * @param name the name used to identify the data
   * @param a function that will be executed in the background to return the value of the data to be
   * collected
   * @return this builder
   */
  OperationBuilder with2(String name, AsyncValue valueGenerator);
  /**
   * Append the given data to the data being collected by this builder.
   * @param name the name used to identify the data
   * @param value the value of the data to be collected
   * @return this builder
   */
  OperationBuilder with3(String name, int value);
  /**
   * Append the given data to the data being collected by this builder.
   * @param name the name used to identify the data
   * @param value the value of the data to be collected
   * @return this builder
   */
  OperationBuilder with4(String name, String value);
  /**
   * Append the given data to the data being collected by this builder.
   * @param name the name used to identify the data
   * @param value the value of the data to be collected
   * @return this builder
   */
  OperationBuilder with5(String name, List<String> value);
}
/**
 * The interface {@code InstrumentationLogger} defines the behavior of objects that are used to log
 * instrumentation data.
 * <p>
 * For an example of using objects that implement this interface, see {@link Instrumentation}.
 */
abstract class InstrumentationLogger {
  /**
   * Create an operation builder that can collect the data associated with an operation. The
   * operation is identified by the given name, is declared to contain only metrics data (data that
   * is not user identifiable and does not contain user intellectual property), and took the given
   * amount of time to complete.
   * @param name the name used to uniquely identify the operation
   * @param time the number of milliseconds required to perform the operation, or {@code -1} if the
   * time is not available or not applicable to this kind of operation
   * @return the operation builder that was created
   */
  OperationBuilder createMetric(String name, int time);
  /**
   * Create an operation builder that can collect the data associated with an operation. The
   * operation is identified by the given name, is declared to potentially contain data that is
   * either user identifiable or contains user intellectual property (but is not guaranteed to
   * contain either), and took the given amount of time to complete.
   * @param name the name used to uniquely identify the operation
   * @param time the number of milliseconds required to perform the operation, or {@code -1} if the
   * time is not available or not applicable to this kind of operation
   * @return the operation builder that was created
   */
  OperationBuilder createOperation(String name, int time);
}
abstract class AsyncValue {
  /**
   * Returns a String to be logged This would typically be used with an anonymous implementation
   * closing over some variables with an expensive operation to be performed in the background
   * @return The data to be logged
   */
  String compute();
}
/**
 * The class {@code Instrumentation} implements support for logging instrumentation information.
 * <p>
 * Instrumentation information consists of information about specific operations. Those operations
 * can range from user-facing operations, such as saving the changes to a file, to internal
 * operations, such as tokenizing source code. The information to be logged is gathered by an{@link OperationBuilder operation builder}, created by one of the static methods on this class.
 * <p>
 * Note, however, that until an instrumentation logger is installed using the method{@link #setLogger(InstrumentationLogger)}, all instrumentation data will be lost.
 * <p>
 * <b>Example</b>
 * <p>
 * To collect metrics about how long it took to save a file, you would write something like the
 * following:
 * <pre>
 * long startTime = System.currentTimeMillis();
 * // save the file
 * long endTime = System.currentTimeMillis();
 * metric("Save", endTime - startTime).with("chars", fileLength).log();
 * </pre>
 * The {@code metric} method creates an operation builder for an operation named {@code "Save"} that
 * took {@code endTime - startTime} milliseconds to run. The {@code with} method attaches additional
 * data to the operation; in this case recording that the file was {@code fileLength} characters
 * long. The {@code log} method tells the builder that all of the data has been collected and that
 * the resulting information should be logged.
 */
class Instrumentation {
  /**
   * An instrumentation logger that can be used when no other instrumentation logger has been
   * configured. This logger will silently ignore all data and logging requests.
   */
  static InstrumentationLogger _NULL_LOGGER = new InstrumentationLogger_5();
  /**
   * The current instrumentation logger.
   */
  static InstrumentationLogger _CURRENT_LOGGER = _NULL_LOGGER;
  /**
   * Create an operation builder that can collect the data associated with an operation. The
   * operation is identified by the given name and is declared to contain only metrics data (data
   * that is not user identifiable and does not contain user intellectual property).
   * @param name the name used to uniquely identify the operation
   * @return the operation builder that was created
   */
  static OperationBuilder metric(String name) => _CURRENT_LOGGER.createMetric(name, -1);
  /**
   * Create an operation builder that can collect the data associated with an operation. The
   * operation is identified by the given name, is declared to contain only metrics data (data that
   * is not user identifiable and does not contain user intellectual property), and took the given
   * amount of time to complete.
   * @param name the name used to uniquely identify the operation
   * @param time the number of milliseconds required to perform the operation
   * @return the operation builder that was created
   */
  static OperationBuilder metric2(String name, int time) => _CURRENT_LOGGER.createMetric(name, time);
  /**
   * Create an operation builder that can collect the data associated with an operation. The
   * operation is identified by the given name and is declared to potentially contain data that is
   * either user identifiable or contains user intellectual property (but is not guaranteed to
   * contain either).
   * @param name the name used to uniquely identify the operation
   * @return the operation builder that was created
   */
  static OperationBuilder operation(String name) => _CURRENT_LOGGER.createOperation(name, -1);
  /**
   * Create an operation builder that can collect the data associated with an operation. The
   * operation is identified by the given name, is declared to potentially contain data that is
   * either user identifiable or contains user intellectual property (but is not guaranteed to
   * contain either), and took the given amount of time to complete.
   * @param name the name used to uniquely identify the operation
   * @param time the number of milliseconds required to perform the operation
   * @return the operation builder that was created
   */
  static OperationBuilder operation2(String name, int time) => _CURRENT_LOGGER.createOperation(name, time);
  /**
   * Set the logger that should receive instrumentation information to the given logger.
   * @param logger the logger that should receive instrumentation information
   */
  static void set logger(InstrumentationLogger logger3) {
    _CURRENT_LOGGER = logger3 == null ? _NULL_LOGGER : logger3;
  }
  /**
   * Prevent the creation of instances of this class
   */
  Instrumentation() {
  }
}
class InstrumentationLogger_5 implements InstrumentationLogger {
  /**
   * An operation builder that will silently ignore all data and logging requests.
   */
  OperationBuilder _NULL_BUILDER = new OperationBuilder_6();
  OperationBuilder createMetric(String name, int time) => _NULL_BUILDER;
  OperationBuilder createOperation(String name, int time) => _NULL_BUILDER;
}
class OperationBuilder_6 implements OperationBuilder {
  void log() {
  }
  OperationBuilder with2(String name, AsyncValue valueGenerator) => this;
  OperationBuilder with3(String name, int value) => this;
  OperationBuilder with4(String name, String value) => this;
  OperationBuilder with5(String name, List<String> value) => this;
}