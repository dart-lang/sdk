// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Concurrent programming using _isolates_:
 * independent workers that are similar to threads
 * but don't share memory,
 * communicating only via messages.
 */
library dart.isolate;

import "dart:async";

part "capability.dart";

/**
 * Thrown when an isolate cannot be created.
 */
class IsolateSpawnException implements Exception {
  /** Error message reported by the spawn operation. */
  final String message;
  IsolateSpawnException(this.message);
  String toString() => "IsolateSpawnException: $message";
}

/**
 * An isolated Dart execution context.
 *
 * All Dart code runs in an isolate, and code can access classes and values
 * only from the same isolate. Different isolates can communicate by sending
 * values through ports (see [ReceivePort], [SendPort]).
 *
 * An `Isolate` object is a reference to an isolate, usually different from
 * the current isolate.
 * It represents, and can be used control, the other isolate.
 *
 * When spawning a new isolate, the spawning isolate receives an `Isolate`
 * object representing the new isolate when the spawn operation succeeds.
 *
 * Isolates run code in its own event loop, and each event may run smaller tasks
 * in a nested microtask queue.
 *
 * An `Isolate` object allows other isolates to control the event loop
 * of the isolate that it represents, and to inspect the isolate,
 * for example by pausing the isolate or by getting events when the isolate
 * has an uncaught error.
 *
 * The [controlPort] gives access to controlling the isolate, and the
 * [pauseCapability] and [terminateCapability] guard access to some control
 * operations.
 * The `Isolate` object provided by a spawn operation will have the
 * control port and capabilities needed to control the isolate.
 * New isolates objects can be created without some of these capabilities
 * if necessary.
 *
 * An `Isolate` object cannot be sent over a `SendPort`, but the control port
 * and capabilities can be sent, and can be used to create a new functioning
 * `Isolate` object in the receiving port's isolate.
 */
class Isolate {
  /** Argument to `ping` and `kill`: Ask for immediate action. */
  static const int IMMEDIATE = 0;
  /** Argument to `ping` and `kill`: Ask for action before the next event. */
  static const int BEFORE_NEXT_EVENT = 1;

  /**
   * Control port used to send control messages to the isolate.
   *
   * This class provides helper functions that sends control messages
   * to the control port.
   *
   * The control port identifies the isolate.
   */
  final SendPort controlPort;

  /**
   * Capability granting the ability to pause the isolate.
   *
   * This capability is used by [pause].
   * If the capability is not the correct pause capability of the isolate,
   * including if the capability is `null`, then calls to `pause` will have no
   * effect.
   *
   * If the isolate is started in a paused state, use this capability as
   * argument to [resume] to resume the isolate.
   */
  final Capability pauseCapability;

  /**
   * Capability granting the ability to terminate the isolate.
   *
   * This capability is used by [kill] and [setErrorsFatal].
   * If the capability is not the correct termination capability of the isolate,
   * including if the capability is `null`, then calls to those methods will
   * have no effect.
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
   * Return the current [Isolate].
   *
   * The isolate gives access to the capabilities needed to inspect,
   * pause or kill the isolate, and allows granting these capabilities
   * to others.
   */
  external static Isolate get current;

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
   * If the [paused] parameter is set to `true`,
   * the isolate will start up in a paused state,
   * as if by an initial call of `isolate.pause(isolate.pauseCapability)`.
   * To resume the isolate, call `isolate.resume(isolate.pauseCapability)`.
   *
   * If the [errorAreFatal], [onExit] and/or [onError] parameters are provided,
   * the isolate will act as if, respectively, [setErrorsFatal],
   * [addOnExitListener] and [addErrorListener] were called with the
   * corresponding parameter and was processed before the isolate starts
   * running.
   *
   * You can also call the [setErrorsFatal], [addOnExitListener] and
   * [addErrorListener] methods on the returned isolate, but unless the
   * isolate was started as [paused], it may already have terminated
   * before those methods can complete.
   *
   * Returns a future that will complete with an [Isolate] instance if the
   * spawning succeeded. It will complete with an error otherwise.
   */
  external static Future<Isolate> spawn(void entryPoint(message), var message,
                                        { bool paused: false,
                                          bool errorsAreFatal,
                                          SendPort onExit,
                                          SendPort onError });

  /**
   * Creates and spawns an isolate that runs the code from the library with
   * the specified URI.
   *
   * The isolate starts executing the top-level `main` function of the library
   * with the given URI.
   *
   * The target `main` must be callable with zero, one or two arguments.
   * Examples:
   *
   * * `main()`
   * * `main(args)`
   * * `main(args, message)`
   *
   * When present, the parameter `args` is set to the provided [args] list.
   * When present, the parameter `message` is set to the initial [message].
   *
   * If the [paused] parameter is set to `true`,
   * the isolate will start up in a paused state,
   * as if by an initial call of `isolate.pause(isolate.pauseCapability)`.
   * To resume the isolate, call `isolate.resume(isolate.pauseCapability)`.
   *
   * If the [errorAreFatal], [onExit] and/or [onError] parameters are provided,
   * the isolate will act as if, respectively, [setErrorsFatal],
   * [addOnExitListener] and [addErrorListener] were called with the
   * corresponding parameter and was processed before the isolate starts
   * running.
   *
   * You can also call the [setErrorsFatal], [addOnExitListener] and
   * [addErrorListener] methods on the returned isolate, but unless the
   * isolate was started as [paused], it may already have terminated
   * before those methods can complete.
   *
   * If the [checked] parameter is set to `true` or `false`,
   * the new isolate will run code in checked mode,
   * respectively in production mode, if possible.
   * If the parameter is omitted, the new isolate will inherit the
   * value from the current isolate.
   *
   * It may not always be possible to honor the `checked` parameter.
   * If the isolate code was pre-compiled, it may not be possible to change
   * the checked mode setting dynamically.
   * In that case, the `checked` parameter is ignored.
   *
   * WARNING: The [checked] parameter is not implemented on all platforms yet.
   *
   * If the [packageRoot] parameter is provided, it is used to find the location
   * of package sources in the spawned isolate.
   *
   * The `packageRoot` URI must be a "file" or "http"/"https" URI that specifies
   * a directory. If it doesn't end in a slash, one will be added before
   * using the URI, and any query or fragment parts are ignored.
   * Package imports (like `"package:foo/bar.dart"`) in the new isolate are
   * resolved against this location, as by
   * `packageRoot.resolve("foo/bar.dart")`.
   *
   * The [environment] is a mapping from strings to strings which the
   * spawned isolate uses when looking up [String.fromEnvironment] values.
   * The system may add its own entries to environment as well.
   * If `environment` is omitted, the spawned isolate has the same environment
   * declarations as the spawning isolate.
   *
   * WARNING: The [environment] parameter is not implemented on all
   * platforms yet.
   *
   * Returns a future that will complete with an [Isolate] instance if the
   * spawning succeeded. It will complete with an error otherwise.
   */
  external static Future<Isolate> spawnUri(
      Uri uri,
      List<String> args,
      var message,
      {bool paused: false,
       SendPort onExit,
       SendPort onError,
       bool errorsAreFatal,
       bool checked,
       Map<String, String> environment,
       Uri packageRoot});

  /**
   * Requests the isolate to pause.
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
    _pause(resumeCapability);
    return resumeCapability;
  }

  /** Internal implementation of [pause]. */
  external void _pause(Capability resumeCapability);

  /**
   * Resumes a paused isolate.
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
  external void resume(Capability resumeCapability);

  /**
   * Asks the isolate to send [response] on [responsePort] when it terminates.
   *
   * The isolate will send a `response` message on `responsePort` as the last
   * thing before it terminates. It will run no further code after the message
   * has been sent.
   *
   * Adding the same port more than once will only cause it to receive one
   * message, using the last response value that was added.
   *
   * If the isolate is already dead, no message will be sent.
   * If `response` cannot be sent to the isolate, then the request is ignored.
   * It is recommended to only use simple values that can be sent to all
   * isolates, like `null`, booleans, numbers or strings.
   *
   * Since isolates run concurrently, it's possible for it to exit before the
   * exit listener is established, and in that case no response will be
   * sent on [responsePort].
   * To avoid this, either use the corresponding parameter to the spawn
   * function, or start the isolate paused, add the listener and
   * then resume the isolate.
   */
  /* TODO(lrn): Can we do better? Can the system recognize this message and
   * send a reply if the receiving isolate is dead?
   */
  external void addOnExitListener(SendPort responsePort, {Object response});

  /**
   * Stop listening on exit messages from the isolate.
   *
   * If a call has previously been made to [addOnExitListener] with the same
   * send-port, this will unregister the port, and it will no longer receive
   * a message when the isolate terminates.
   * A response may still be sent until this operation is fully processed by
   * the isolate.
   */
  external void removeOnExitListener(SendPort responsePort);

  /**
   * Set whether uncaught errors will terminate the isolate.
   *
   * If errors are fatal, any uncaught error will terminate the isolate
   * event loop and shut down the isolate.
   *
   * This call requires the [terminateCapability] for the isolate.
   * If the capability is not correct, no change is made.
   *
   * Since isolates run concurrently, it's possible for it to exit due to an
   * error before errors are set non-fatal.
   * To avoid this, either use the corresponding parameter to the spawn
   * function, or start the isolate paused, set errors non-fatal and
   * then resume the isolate.
   */
  external void setErrorsFatal(bool errorsAreFatal);

  /**
   * Requests the isolate to shut down.
   *
   * The isolate is requested to terminate itself.
   * The [priority] argument specifies when this must happen.
   *
   * The [priority] must be one of [IMMEDIATE] or [BEFORE_NEXT_EVENT].
   * The shutdown is performed at different times depending on the priority:
   *
   * * `IMMEDIATE`: The the isolate shuts down as soon as possible.
   *     Control messages are handled in order, so all previously sent control
   *     events from this isolate will all have been processed.
   *     The shutdown should happen no later than if sent with
   *     `BEFORE_NEXT_EVENT`.
   *     It may happen earlier if the system has a way to shut down cleanly
   *     at an earlier time, even during the execution of another event.
   * * `BEFORE_NEXT_EVENT`: The shutdown is scheduled for the next time
   *     control returns to the event loop of the receiving isolate,
   *     after the current event, and any already scheduled control events,
   *     are completed.
   */
  external void kill({int priority: BEFORE_NEXT_EVENT});

  /**
   * Request that the isolate send [response] on the [responsePort].
   *
   * If the isolate is alive, it will eventually send `response`
   * (defaulting to `null`) on the response port.
   *
   * The [priority] must be one of [IMMEDIATE] or [BEFORE_NEXT_EVENT].
   * The response is sent at different times depending on the ping type:
   *
   * * `IMMEDIATE`: The the isolate responds as soon as it receives the
   *     control message. This is after any previous control message
   *     from the same isolate has been received, but may be during
   *     execution of another event.
   * * `BEFORE_NEXT_EVENT`: The response is scheduled for the next time
   *     control returns to the event loop of the receiving isolate,
   *     after the current event, and any already scheduled control events,
   *     are completed.
   *
   * If `response` cannot be sent to the isolate, then the request is ignored.
   * It is recommended to only use simple values that can be sent to all
   * isolates, like `null`, booleans, numbers or strings.
   */
  external void ping(SendPort responsePort, {Object response,
                                             int priority: IMMEDIATE});

  /**
   * Requests that uncaught errors of the isolate are sent back to [port].
   *
   * The errors are sent back as two elements lists.
   * The first element is a `String` representation of the error, usually
   * created by calling `toString` on the error.
   * The second element is a `String` representation of an accompanying
   * stack trace, or `null` if no stack trace was provided.
   * To convert this back to a [StackTrace] object, use [StackTrace.fromString].
   *
   * Listening using the same port more than once does nothing. It will only
   * get each error once.
   *
   * Since isolates run concurrently, it's possible for it to exit before the
   * error listener is established. To avoid this, start the isolate paused,
   * add the listener and then resume the isolate.
   */
  external void addErrorListener(SendPort port);

  /**
   * Stop listening for uncaught errors through [port].
   *
   * The `port` should be a port that is listening for errors through
   * [addErrorListener]. This call requests that the isolate stops sending
   * errors on the port.
   *
   * If the same port has been passed via `addErrorListener` more than once,
   * only one call to `removeErrorListener` is needed to stop it from receiving
   * errors.
   *
   * Closing the receive port at the end of the send port will not stop the
   * isolate from sending errors, they are just going to be lost.
   */
  external void removeErrorListener(SendPort port);

  /**
   * Returns a broadcast stream of uncaught errors from the isolate.
   *
   * Each error is provided as an error event on the stream.
   *
   * The actual error object and stackTraces will not necessarily
   * be the same object types as in the actual isolate, but they will
   * always have the same [Object.toString] result.
   *
   * This stream is based on [addErrorListener] and [removeErrorListener].
   */
  Stream get errors {
    StreamController controller;
    RawReceivePort port;
    void handleError(message) {
      String errorDescription = message[0];
      String stackDescription = message[1];
      var error = new RemoteError(errorDescription, stackDescription);
      controller.addError(error, error.stackTrace);
    }
    controller = new StreamController.broadcast(
        sync: true,
        onListen: () {
          port = new RawReceivePort(handleError);
          this.addErrorListener(port.sendPort);
        },
        onCancel: () {
          this.removeErrorListener(port.sendPort);
          port.close();
          port = null;
        });
    return controller.stream;
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
   *
   * The send happens immediately and doesn't block.  The corresponding receive
   * port can receive the message as soon as its isolate's event loop is ready
   * to deliver it, independently of what the sending isolate is doing.
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
 * Description of an error from another isolate.
 *
 * This error has the same `toString()` and `stackTrace.toString()` behavior
 * as the original error, but has no other features of the original error.
 */
class RemoteError implements Error {
  final String _description;
  final StackTrace stackTrace;
  RemoteError(String description, String stackDescription)
      : _description = description,
        stackTrace = new StackTrace.fromString(stackDescription);
  String toString() => _description;
}
