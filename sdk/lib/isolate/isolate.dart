// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Concurrent programming using _isolates_:
 * independent workers that are similar to threads
 * but don't share memory,
 * communicating only via messages.
 *
 * See also:
 * [dart:isolate - Concurrency with Isolates](https://www.dartlang.org/docs/dart-up-and-running/contents/ch03.html#ch03-dartisolate---concurrency-with-isolates)
 * in the library tour.
 */
library dart.isolate;

import "dart:async";

/**
 * Thrown when an isolate cannot be created.
 */
class IsolateSpawnException implements Exception {
  // TODO(floitsch): clean up spawn exception.
  const IsolateSpawnException(String this._s);
  String toString() => "IsolateSpawnException: '$_s'";
  final String _s;
}

class Isolate {

  final SendPort _controlPort;

  Isolate._fromControlPort(SendPort controlPort)
      : this._controlPort = controlPort;

  /**
   * Creates and spawns an isolate that shares the same code as the current
   * isolate.
   *
   * The argument [entryPoint] specifies the entry point of the spawned
   * isolate. It must be a top-level function or a static method that
   * takes one argument - that is, one-parameter functions that can be
   * compile-time constant function values.
   * It is not allowed to pass the value of function expressions or an instance
   * method extracted from an object.
   *
   * The entry-point function is invoked with the initial [message].
   * Usually the initial [message] contains a [SendPort] so
   * that the spawner and spawnee can communicate with each other.
   *
   * Returns a future that will complete with an [Isolate] instance. The
   * isolate instance can be used to control the spawned isolate.
   */
  external static Future<Isolate> spawn(void entryPoint(message), var message);

  /**
   * Creates and spawns an isolate that runs the code from the library with
   * the specified URI.
   *
   * The isolate starts executing the top-level `main` function of the library
   * with the given URI.
   *
   * The target `main` may have one of three signatures:
   *
   * * `main()`
   * * `main(args)`
   * * `main(args, message)`
   *
   * When present, the parameter `args` is set to the provided [args] list.
   * When present, the parameter `message` is set to the initial [message].
   *
   * Returns a future that will complete with an [Isolate] instance. The
   * isolate instance can be used to control the spawned isolate.
   */
  external static Future<Isolate> spawnUri(
      Uri uri, List<String> args, var message);
}

/**
 * Sends messages to its [ReceivePort]s.
 *
 * [SendPort]s are created from [ReceivePort]s. Any message sent through
 * a [SendPort] is delivered to its corresponding [ReceivePort]. There might be
 * many [SendPort]s for the same [ReceivePort].
 *
 * [SendPort]s can be transmitted to other isolates.
 */
abstract class SendPort {

  /**
   * Sends an asynchronous [message] through this send port, to its
   * corresponding `ReceivePort`.
   *
   * The content of [message] can be: primitive values (null, num, bool, double,
   * String), instances of [SendPort], and lists and maps whose elements are any
   * of these. List and maps are also allowed to be cyclic.
   *
   * In the special circumstances when two isolates share the same code and are
   * running in the same process (e.g. isolates created via [Isolate.spawn]), it
   * is also possible to send object instances (which would be copied in the
   * process). This is currently only supported by the dartvm.  For now, the
   * dart2js compiler only supports the restricted messages described above.
   */
  void send(var message);

  /**
   * Tests whether [other] is a [SendPort] pointing to the same
   * [ReceivePort] as this one.
   */
  bool operator==(var other);

  /**
   * Returns an immutable hash code for this send port that is
   * consistent with the == operator.
   */
  int get hashCode;
}

/**
 * Together with [SendPort], the only means of communication between isolates.
 *
 * [ReceivePort]s have a `sendPort` getter which returns a [SendPort].
 * Any message that is sent through this [SendPort]
 * is delivered to the [ReceivePort] it has been created from. There, the
 * message is dispatched to the `ReceivePort`'s listener.
 *
 * A [ReceivePort] is a non-broadcast stream. This means that it buffers
 * incoming messages until a listener is registered. Only one listener can
 * receive messages. See [Stream.asBroadcastStream] for transforming the port
 * to a broadcast stream.
 *
 * A [ReceivePort] may have many [SendPort]s.
 */
abstract class ReceivePort implements Stream {

  /**
   * Opens a long-lived port for receiving messages.
   *
   * A [ReceivePort] is a non-broadcast stream. This means that it buffers
   * incoming messages until a listener is registered. Only one listener can
   * receive messages. See [Stream.asBroadcastStream] for transforming the port
   * to a broadcast stream.
   *
   * A receive port is closed by canceling its subscription.
   */
  external factory ReceivePort();

  /**
   * Creates a [ReceivePort] from a [RawReceivePort].
   *
   * The handler of the given [rawPort] is overwritten during the construction
   * of the result.
   */
  external factory ReceivePort.fromRawReceivePort(RawReceivePort rawPort);

  /**
   * Inherited from [Stream].
   *
   * Note that [onError] and [cancelOnError] are ignored since a ReceivePort
   * will never receive an error.
   *
   * The [onDone] handler will be called when the stream closes.
   * The stream closes when [close] is called.
   */
  StreamSubscription listen(void onData(var message),
                            { Function onError,
                              void onDone(),
                              bool cancelOnError });

  /**
   * Closes `this`.
   *
   * If the stream has not been canceled yet, adds a close-event to the event
   * queue and discards any further incoming messages.
   *
   * If the stream has already been canceled this method has no effect.
   */
  void close();

  /**
   * Returns a [SendPort] that sends to this receive port.
   */
  SendPort get sendPort;
}

abstract class RawReceivePort {
  /**
   * Opens a long-lived port for receiving messages.
   *
   * A [RawReceivePort] is low level and does not work with [Zone]s. It
   * can not be paused. The data-handler must be set before the first
   * event is received.
   */
  external factory RawReceivePort([void handler(event)]);

  /**
   * Sets the handler that is invoked for every incoming message.
   *
   * The handler is invoked in the root-zone ([Zone.ROOT]).
   */
  void set handler(Function newHandler);

  /**
   * Closes the port.
   *
   * After a call to this method any incoming message is silently dropped.
   */
  void close();

  /**
   * Returns a [SendPort] that sends to this receive port.
   */
  SendPort get sendPort;
}

/**
 * Wraps unhandled exceptions thrown during isolate execution. It is
 * used to show both the error message and the stack trace for unhandled
 * exceptions.
 */
// TODO(floitsch): probably going to remove and replace with something else.
class _IsolateUnhandledException implements Exception {
  /** Message being handled when exception occurred. */
  final message;

  /** Wrapped exception. */
  final source;

  /** Trace for the wrapped exception. */
  final StackTrace stackTrace;

  const _IsolateUnhandledException(this.message, this.source, this.stackTrace);

  String toString() {
    return 'IsolateUnhandledException: exception while handling message: '
        '${message} \n  '
        '${source.toString().replaceAll("\n", "\n  ")}\n'
        'original stack trace:\n  '
        '${stackTrace.toString().replaceAll("\n","\n  ")}';
  }
}
