// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Concurrent programming using _isolates_:
 * independent workers that are similar to threads
 * but don't share memory,
 * communicating only via messages.
 *
 * To use this library in your code:
 *
 *     import 'dart:isolate';
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
 * The [controlPort] identifies and gives access to controlling the isolate,
 * and the [pauseCapability] and [terminateCapability] guard access
 * to some control operations.
 * For example, calling [pause] on an `Isolate` object created without a
 * [pauseCapability], has no effect.
 *
 * The `Isolate` object provided by a spawn operation will have the
 * control port and capabilities needed to control the isolate.
 * New isolate objects can be created without some of these capabilities
 * if necessary, using the [Isolate.Isolate] constructor.
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
   * The control port identifies the isolate.
   *
   * An `Isolate` object allows sending control messages
   * through the control port.
   *
   * Some control messages require a specific capability to be passed along
   * with the message (see [pauseCapability] and [terminateCapability]),
   * otherwise the message is ignored by the isolate.
   */
  final SendPort controlPort;

  /**
   * Capability granting the ability to pause the isolate.
   *
   * This capability is required by [pause].
   * If the capability is `null`, or if it is not the correct pause capability
   * of the isolate identified by [controlPort],
   * then calls to [pause] will have no effect.
   *
   * If the isolate is spawned in a paused state, use this capability as
   * argument to the [resume] method in order to resume the paused isolate.
   */
  final Capability pauseCapability;

  /**
   * Capability granting the ability to terminate the isolate.
   *
   * This capability is required by [kill] and [setErrorsFatal].
   * If the capability is `null`, or if it is not the correct termination
   * capability of the isolate identified by [controlPort],
   * then calls to those methods will have no effect.
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
   * Can also be used to create an [Isolate] object from a control port, and
   * any available capabilities, that have been sent through a [SendPort].
   *
   * Example:
   * ```dart
   * Isolate isolate = findSomeIsolate();
   * Isolate restrictedIsolate = new Isolate(isolate.controlPort);
   * untrustedCode(restrictedIsolate);
   * ```
   * This example creates a new `Isolate` object that cannot be used to
   * pause or terminate the isolate. All the untrusted code can do is to
   * inspect the isolate and see uncaught errors or when it terminates.
   */
  Isolate(this.controlPort, {this.pauseCapability, this.terminateCapability});

  /**
   * Return an [Isolate] object representing the current isolate.
   *
   * The current isolate for code using [current]
   * is the isolate running the code.
   *
   * The isolate object provides the capabilities required to inspect,
   * pause or kill the isolate, and allows granting these capabilities
   * to others.
   *
   * It is possible to pause the current isolate, but doing so *without*
   * first passing the ability to resume it again to another isolate,
   * is a sure way to hang your program.
   */
  external static Isolate get current;

  /**
   * Returns the package root of the current isolate, if any.
   *
   * If the isolate is using a [packageConfig] or the isolate has not been
   * setup for package resolution, this getter returns `null`, otherwise it
   * returns the package root - a directory that package URIs are resolved
   * against.
   */
  external static Future<Uri> get packageRoot;

  /**
   * Returns the package root of the current isolate, if any.
   *
   * If the isolate is using a [packageRoot] or the isolate has not been
   * setup for package resolution, this getter returns `null`, otherwise it
   * returns the package config URI.
   */
  external static Future<Uri> get packageConfig;

  /**
   * Maps a package: URI to a non-package Uri.
   *
   * If there is no valid mapping from the package: URI in the current
   * isolate, then this call returns `null`. Non-package: URIs are
   * returned unmodified.
   */
  external static Future<Uri> resolvePackageUri(Uri packageUri);

  /**
   * Creates and spawns an isolate that shares the same code as the current
   * isolate.
   *
   * The argument [entryPoint] specifies the initial function to call
   * in the spawned isolate.
   * The entry-point function is invoked in the new isolate with [message]
   * as the only argument.
   *
   * The function must be a top-level function or a static method
   * that can be called with a single argument,
   * that is, a compile-time constant function value
   * which accepts at least one positional parameter
   * and has at most one required positional parameter.
   * The function may accept any number of optional parameters,
   * as long as it *can* be called with just a single argument.
   * The function must not be the value of a function expression
   * or an instance method tear-off.
   *
   * Usually the initial [message] contains a [SendPort] so
   * that the spawner and spawnee can communicate with each other.
   *
   * If the [paused] parameter is set to `true`,
   * the isolate will start up in a paused state,
   * just before calling the [entryPoint] function with the [message],
   * as if by an initial call of `isolate.pause(isolate.pauseCapability)`.
   * To resume the isolate, call `isolate.resume(isolate.pauseCapability)`.
   *
   * If the [errorsAreFatal], [onExit] and/or [onError] parameters are provided,
   * the isolate will act as if, respectively, [setErrorsFatal],
   * [addOnExitListener] and [addErrorListener] were called with the
   * corresponding parameter and was processed before the isolate starts
   * running.
   *
   * If [errorsAreFatal] is omitted, the platform may choose a default behavior
   * or inherit the current isolate's behavior.
   *
   * You can also call the [setErrorsFatal], [addOnExitListener] and
   * [addErrorListener] methods on the returned isolate, but unless the
   * isolate was started as [paused], it may already have terminated
   * before those methods can complete.
   *
   * Returns a future which will complete with an [Isolate] instance if the
   * spawning succeeded. It will complete with an error otherwise.
   */
  external static Future<Isolate> spawn(void entryPoint(message), var message,
      {bool paused: false,
      bool errorsAreFatal,
      SendPort onExit,
      SendPort onError});

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
   * If the [errorsAreFatal], [onExit] and/or [onError] parameters are provided,
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
   * If the [packageConfig] parameter is provided, then it is used to find the
   * location of a package resolution configuration file for the spawned
   * isolate.
   *
   * If the [automaticPackageResolution] parameter is provided, then the
   * location of the package sources in the spawned isolate is automatically
   * determined.
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
      Uri uri, List<String> args, var message,
      {bool paused: false,
      SendPort onExit,
      SendPort onError,
      bool errorsAreFatal,
      bool checked,
      Map<String, String> environment,
      Uri packageRoot,
      Uri packageConfig,
      bool automaticPackageResolution: false});

  /**
   * Requests the isolate to pause.
   *
   * When the isolate receives the pause command, it stops
   * processing events from the event loop queue.
   * It may still add new events to the queue in response to, e.g., timers
   * or receive-port messages. When the isolate is resumed,
   * it starts handling the already enqueued events.
   *
   * The pause request is sent through the isolate's command port,
   * which bypasses the receiving isolate's event loop.
   * The pause takes effect when it is received, pausing the event loop
   * as it is at that time.
   *
   * The [resumeCapability] is used to identity the pause,
   * and must be used again to end the pause using [resume].
   * If [resumeCapability] is omitted, a new capability object is created
   * and used instead.
   *
   * If an isolate is paused more than once using the same capability,
   * only one resume with that capability is needed to end the pause.
   *
   * If an isolate is paused using more than one capability,
   * each pause must be individually ended before the isolate resumes.
   *
   * Returns the capability that must be used to end the pause.
   * This is either [resumeCapability], or a new capability when
   * [resumeCapability] is omitted.
   *
   * If [pauseCapability] is `null`, or it's not the pause capability
   * of the isolate identified by [controlPort],
   * the pause request is ignored by the receiving isolate.
   */
  Capability pause([Capability resumeCapability]) {
    resumeCapability ??= new Capability();
    _pause(resumeCapability);
    return resumeCapability;
  }

  /** Internal implementation of [pause]. */
  external void _pause(Capability resumeCapability);

  /**
   * Resumes a paused isolate.
   *
   * Sends a message to an isolate requesting that it ends a pause
   * that was previously requested.
   *
   * When all active pause requests have been cancelled, the isolate
   * will continue processing events and handling normal messages.
   *
   * If the [resumeCapability] is not one that has previously been used
   * to pause the isolate, or it has already been used to resume from
   * that pause, the resume call has no effect.
   */
  external void resume(Capability resumeCapability);

  /**
   * Requests an exist message on [responsePort] when the isolate terminates.
   *
   * The isolate will send [response] as a message on [responsePort] as the last
   * thing before it terminates. It will run no further code after the message
   * has been sent.
   *
   * Adding the same port more than once will only cause it to receive one exit
   * message, using the last response value that was added,
   * and it only needs to be removed once using [removeOnExitListener].
   *
   * If the isolate has terminated before it can receive this request,
   * no exit message will be sent.
   *
   * The [response] object must follow the same restrictions as enforced by
   * [SendPort.send].
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
   * Stops listening for exit messages from the isolate.
   *
   * Requests for the isolate to not send exit messages on [responsePort].
   * If the isolate isn't expecting to send exit messages on [responsePort],
   * because the port hasn't been added using [addOnExitListener],
   * or because it has already been removed, the request is ignored.
   *
   * If the same port has been passed via [addOnExitListener] more than once,
   * only one call to `removeOnExitListener` is needed to stop it from receiving
   * exit messages.
   *
   * Closing the receive port that is associated with the [responsePort] does
   * not stop the isolate from sending uncaught errors, they are just going to
   * be lost.
   *
   * An exit message may still be sent if the isolate terminates
   * before this request is received and processed.
   */
  external void removeOnExitListener(SendPort responsePort);

  /**
   * Sets whether uncaught errors will terminate the isolate.
   *
   * If errors are fatal, any uncaught error will terminate the isolate
   * event loop and shut down the isolate.
   *
   * This call requires the [terminateCapability] for the isolate.
   * If the capability is absent or incorrect, no change is made.
   *
   * Since isolates run concurrently, it's possible for the receiving isolate
   * to exit due to an error, before a request, using this method, has been
   * received and processed.
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
   * The [priority], when provided, must be one of [IMMEDIATE] or
   * [BEFORE_NEXT_EVENT] (the default).
   * The shutdown is performed at different times depending on the priority:
   *
   * * `IMMEDIATE`: The isolate shuts down as soon as possible.
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
   *
   * If [terminateCapability] is `null`, or it's not the terminate capability
   * of the isolate identified by [controlPort],
   * the kill request is ignored by the receiving isolate.
   */
  external void kill({int priority: BEFORE_NEXT_EVENT});

  /**
   * Requests that the isolate send [response] on the [responsePort].
   *
   * The [response] object must follow the same restrictions as enforced by
   * [SendPort.send].
   * It is recommended to only use simple values that can be sent to all
   * isolates, like `null`, booleans, numbers or strings.
   *
   * If the isolate is alive, it will eventually send `response`
   * (defaulting to `null`) on the response port.
   *
   * The [priority] must be one of [IMMEDIATE] or [BEFORE_NEXT_EVENT].
   * The response is sent at different times depending on the ping type:
   *
   * * `IMMEDIATE`: The isolate responds as soon as it receives the
   *     control message. This is after any previous control message
   *     from the same isolate has been received and processed,
   *     but may be during execution of another event.
   * * `BEFORE_NEXT_EVENT`: The response is scheduled for the next time
   *     control returns to the event loop of the receiving isolate,
   *     after the current event, and any already scheduled control events,
   *     are completed.
   */
  external void ping(SendPort responsePort,
      {Object response, int priority: IMMEDIATE});

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
   * Listening using the same port more than once does nothing.
   * A port will only receive each error once,
   * and will only need to be removed once using [removeErrorListener].

   * Closing the receive port that is associated with the port does not stop
   * the isolate from sending uncaught errors, they are just going to be lost.
   * Instead use [removeErrorListener] to stop receiving errors on [port].
   *
   * Since isolates run concurrently, it's possible for it to exit before the
   * error listener is established. To avoid this, start the isolate paused,
   * add the listener and then resume the isolate.
   */
  external void addErrorListener(SendPort port);

  /**
   * Stops listening for uncaught errors from the isolate.
   *
   * Requests for the isolate to not send uncaught errors on [port].
   * If the isolate isn't expecting to send uncaught errors on [port],
   * because the port hasn't been added using [addErrorListener],
   * or because it has already been removed, the request is ignored.
   *
   * If the same port has been passed via [addErrorListener] more than once,
   * only one call to `removeErrorListener` is needed to stop it from receiving
   * uncaught errors.
   *
   * Uncaught errors message may still be sent by the isolate
   * until this request is received and processed.
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
  bool operator ==(var other);

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
      {Function onError, void onDone(), bool cancelOnError});

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
