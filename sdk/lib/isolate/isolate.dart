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

part "capability.dart";

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
  /** Argument to `ping`: Ask for immediate response. */
  static const int PING_ALIVE = 0;
  /** Argument to `ping`: Ask for response after control events. */
  static const int PING_CONTROL = 1;
  /** Argument to `ping`: Ask for response after normal events. */
  static const int PING_EVENT = 2;

  /**
   * Control port used to send control messages to the isolate.
   *
   * This class provides helper functions that sends control messages
   * to the control port.
   */
  final SendPort controlPort;
  /**
   * Capability granting the ability to pause the isolate.
   */
  final Capability pauseCapability;
  /**
   * Capability granting the ability to terminate the isolate.
   */
  final Capability terminateCapability;

  /**
   * Create a new [Isolate] object with a restricted set of capabilities.
   *
   * The port should be a control port for an isolate, as taken from
   * another `Isolate` object.
   *
   * The capabilities should be the subset of the capabilities that are
   * available to the original isolate.
   * Capabilities of an isolate are locked to that isolate, and have no effect
   * anywhere else, so the capabilities should come from the same isolate as
   * the control port.
   *
   * If all the available capabilities are included,
   * there is no reason to create a new object,
   * since the behavior is defined entirely
   * by the control port and capabilities.
   */
  Isolate(this.controlPort, {this.pauseCapability,
                             this.terminateCapability});

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
   * Returns a future that will complete with an [Isolate] instance if the
   * spawning succeeded. It will complete with an error otherwise.
   */
  external static Future<Isolate> spawn(void entryPoint(message), var message,
                                        { bool paused: false });

  /**
   * Creates and spawns an isolate that runs the code from the library with
   * the specified URI.
   *
   * The isolate starts executing the top-level `main` function of the library
   * with the given URI.
   *
   * The target `main` must be a subtype of one of these three signatures:
   *
   * * `main()`
   * * `main(args)`
   * * `main(args, message)`
   *
   * When present, the parameter `args` is set to the provided [args] list.
   * When present, the parameter `message` is set to the initial [message].
   *
   * Returns a future that will complete with an [Isolate] instance if the
   * spawning succeeded. It will complete with an error otherwise.
   */
  external static Future<Isolate> spawnUri(
      Uri uri, List<String> args, var message, { bool paused: false });


  /**
   * Requests the isolate to pause.
   *
   * WARNING: This method is experimental and not handled on every platform yet.
   *
   * The isolate should stop handling events by pausing its event queue.
   * The request will eventually make the isolate stop doing anything.
   * It will be handled before any other messages that are later sent to the
   * isolate from the current isolate, but no other guarantees are provided.
   *
   * The event loop may be paused before previously sent, but not yet exeuted,
   * messages have been reached.
   *
   * If [resumeCapability] is provided, it is used to identity the pause,
   * and must be used again to end the pause using [resume].
   * Otherwise a new resume capability is created and returned.
   *
   * If an isolate is paused more than once using the same capability,
   * only one resume with that capability is needed to end the pause.
   *
   * If an isolate is paused using more than one capability,
   * they must all be individully ended before the isolate resumes.
   *
   * Returns the capability that must be used to resume end the pause.
   */
  Capability pause([Capability resumeCapability]) {
    if (resumeCapability == null) resumeCapability = new Capability();
    var message = new List(3)
        ..[0] = "pause"
        ..[1] = pauseCapability
        ..[2] = resumeCapability;
    controlPort.send(message);
    return resumeCapability;
  }

  /**
   * Resumes a paused isolate.
   *
   * WARNING: This method is experimental and not handled on every platform yet.
   *
   * Sends a message to an isolate requesting that it ends a pause
   * that was requested using the [resumeCapability].
   *
   * When all active pause requests have been cancelled, the isolate
   * will continue handling normal messages.
   *
   * The capability must be one returned by a call to [pause] on this
   * isolate, otherwise the resume call does nothing.
   */
  void resume(Capability resumeCapability) {
    var message = new List(2)
        ..[0] = "resume"
        ..[1] = resumeCapability;
    controlPort.send(message);
  }

  /**
   * Asks the isolate to send a message on [responsePort] when it terminates.
   *
   * WARNING: This method is experimental and not handled on every platform yet.
   *
   * The isolate will send a `null` message on [responsePort] as the last
   * thing before it terminates. It will run no further code after the message
   * has been sent.
   *
   * If the isolate is already dead, no message will be sent.
   * TODO(lrn): Can we do better? Can the system recognize this message and
   * send a reply if the receiving isolate is dead?
   */
  void addOnExitListener(SendPort responsePort) {
    // TODO(lrn): Can we have an internal method that checks if the receiving
    // isolate of a SendPort is still alive?
    var message = new List(2)
        ..[0] = "add-ondone"
        ..[1] = responsePort;
    controlPort.send(message);
  }

  /**
   * Stop listening on exit messages from the isolate.
   *
   * WARNING: This method is experimental and not handled on every platform yet.
   *
   * If a call has previously been made to [addOnExitListener] with the same
   * send-port, this will unregister the port, and it will no longer receive
   * a message when the isolate terminates.
   * A response may still be sent until this operation is fully processed by
   * the isolate.
   */
  void removeOnExitListener(SendPort responsePort) {
    var message = new List(2)
        ..[0] = "remove-ondone"
        ..[1] = responsePort;
    controlPort.send(message);
  }

  /**
   * Set whether uncaught errors will terminate the isolate.
   *
   * WARNING: This method is experimental and not handled on every platform yet.
   *
   * If errors are fatal, any uncaught error will terminate the isolate
   * event loop and shut down the isolate.
   *
   * This call requires the [terminateCapability] for the isolate.
   * If the capability is not correct, no change is made.
   */
  void setErrorsFatal(bool errorsAreFatal) {
    var message = new List(3)
        ..[0] = "set-errors-fatal"
        ..[1] = terminateCapability
        ..[2] = errorsAreFatal;
    controlPort.send(message);
  }

  /**
   * Request that the isolate send a response on the [responsePort].
   *
   * WARNING: This method is experimental and not handled on every platform yet.
   *
   * If the isolate is alive, it will eventually send a `null` response on
   * the response port.
   *
   * The [pingType] must be one of [PING_ALIVE], [PING_CONTROL] or [PING_EVENT].
   * The response is sent at different times depending on the ping type:
   *
   * * `PING_ALIVE`: The the isolate responds as soon as possible.
   *     The response should happen no later than if sent with `PING_CONTROL`.
   *     It may be sent earlier if the system has a way to do so.
   * * `PING_CONTROL`: The response it not sent until all previously sent
   *     control messages from the current isolate to the receiving isolate
   *     have been processed. This can be used to wait for
   *     previously sent control messages.
   * * `PING_EVENT`: The response is not sent until all prevously sent
   *     non-control messages from the current isolate to the receiving isolate
   *     have been processed.
   *     The ping effectively puts the resonse into the normal event queue after
   *     previously sent messages.
   *     This can be used to wait for a another event to be processed.
   */
  void ping(SendPort responsePort, [int pingType = PING_ALIVE]) {
    var message = new List(3)
        ..[0] = "ping"
        ..[1] = responsePort
        ..[2] = pingType;
    controlPort.send(message);
  }
}

/**
 * Sends messages to its [ReceivePort]s.
 *
 * [SendPort]s are created from [ReceivePort]s. Any message sent through
 * a [SendPort] is delivered to its corresponding [ReceivePort]. There might be
 * many [SendPort]s for the same [ReceivePort].
 *
 * [SendPort]s can be transmitted to other isolates, and they preserve equality
 * when sent.
 */
abstract class SendPort implements Capability {

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
   * Returns a [SendPort] that sends to this raw receive port.
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
