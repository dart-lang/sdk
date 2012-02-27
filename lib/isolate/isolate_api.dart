// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * [SendPort]s are created from [ReceivePort]s. Any message sent through
 * a [SendPort] is delivered to its respective [ReceivePort]. There might be
 * many [SendPort]s for the same [ReceivePort].
 *
 * [SendPort]s can be transmitted to other isolates.
 */
interface SendPort extends Hashable {

  /**
   * Sends an asynchronous [message] to this send port. The message is
   * copied to the receiving isolate. If the message contains any
   * receive ports, they are translated to the corresponding send port
   * before being transmitted. If specified, the [replyTo] port will be
   * provided to the receiver to facilitate exchanging sequences of
   * messages.
   */
  void send(var message, [SendPort replyTo]);

  /**
   * Creates a new single-shot receive port, sends a message to this
   * send port with replyTo set to the opened port, and returns the
   * receive port.
   */
  ReceivePort call(var message);

  /**
   * Tests whether [other] is a [SendPort] pointing to the same
   * [ReceivePort] as this one.
   */
   bool operator==(var other);

  /**
   * Returns an immutable hash code for this send port that is
   * consistent with the == operator.
   */
  int hashCode();

}


/**
 * [ReceivePort]s, together with [SendPort]s, are the only means of
 * communication between isolates. [ReceivePort]s have a [:toSendPort:] method
 * which returns a [SendPort]. Any message that is sent through this [SendPort]
 * is delivered to the [ReceivePort] it has been created from. There, they are
 * dispatched to the callback that has been registered on the receive port.
 *
 * A [ReceivePort] may have many [SendPort]s.
 */
interface ReceivePort default _ReceivePortFactory {

  /**
   * Opens a long-lived port for receiving messages. The returned port
   * must be explicitly closed through [ReceivePort.close].
   */
  ReceivePort();

  /**
   * Opens a single-shot reply port. Once a message has been received
   * on this port, it is automatically closed -- obviously without
   * throwing the message away before it can be processed. This
   * constructor is used indirectly through [SendPort.call].
   */
  ReceivePort.singleShot();

  /**
   * Sets up a callback function for receiving pending or future
   * messages on this receive port.
   */
  void receive(void callback(var message, SendPort replyTo));

  /**
   * Closes this receive port immediately. Pending messages will not
   * be processed and it is impossible to re-open the port. Single-shot
   * reply ports, such as those created through [SendPort.call], are
   * automatically closed when the reply has been received. Multiple
   * invocations of [close] are allowed but ignored.
   */
  void close();

  /**
   * Creates a new send port that sends to this receive port. It is legal to
   * create several [SendPort]s from the same [ReceivePort].
   */
  SendPort toSendPort();

}

/**
 * The [Isolate] class serves two purposes: (1) as template for spawning a new
 * isolate, and (2) as entry-point for the newly spawned isolate.
 *
 * New isolates are spawned by sub-classing [Isolate] and then invoking
 * [:spawn:] on the instance. This will spawn a new isolate, which creates a
 * new instance of the class, initializes the instance's [port] field
 * and invokes the instance method [main].
 *
 * The new instance is created by invoking the default constructor of the
 * class that served as template for spawning the new isolate. This means, that
 * sub-classes must have a default constructor (i.e. no-argument constructor).
 *
 * Isolates may be "heavy" or "light". Heavy isolates live in their own thread,
 * whereas "light" isolates live in the same thread as the isolate which spawned
 * them.
 */
// TODO(sigmund): delete once we implement the new isolates in the vm
class Isolate {

  /**
   * Redirects to [Isolate.light].
   */
  Isolate() : this.light();

  /**
   * Creates a new isolate-template for a light isolate.
   */
  Isolate.light() : _isLight = true;

  /**
   * Creates a new isolate-template for a heavy isolate.
   */
  Isolate.heavy() : _isLight = false;

  /**
   * Spawns a new isolate, using this instance as template.
   *
   * The new isolate lives in a new thread (for heavy templates)
   * or in the same thread as the current isolate (for light templates), if
   * possible.
   *
   * During the initialization of the new isolate a [ReceivePort] is created
   * inside the new isolate and stored in the read-only field [port].
   *  A corresponding [SendPort] is sent to the isolate that invoked [spawn].
   * Since spawning an isolate is an asynchronous operation this method returns
   * a [Future] of this [SendPort].
   *
   * A common pattern to instantiate new isolates is to enqueue the instructions
   * using [Future.then].
   * [:myIsolate.spawn().then((SendPort port) { port.send('hi there'); });:]
   */
  Future<SendPort> spawn() {
    return _IsolateNatives.spawn(this, _isLight);
  }

  // The private run method is invoked with the receive port. Before
  // main is invoked we store the port in a field so it can be
  // accessed from subclasses of Isolate.
  void _run(ReceivePort port) {
    _port = port;
    main();
  }

  /**
   * When [Isolate]s are used as entry-points, the [port] field contains a
   * [ReceivePort]. The isolate that initiated the spawn holds a corresponding
   * [SendPort].
   *
   * Note that isolates should generally close their [ReceivePort]s when they
   * are done, including this port.
   */
  ReceivePort get port() {
    return _port;
  }

  /**
   * When isolates are created, an instance of the template's class is
   * instantiated in the new isolate. After the [port] has been set up, this
   * [main] method is invoked on the instance.
   */
  abstract void main();

  final bool _isLight;
  ReceivePort _port;
}

/**
 * [Isolate2] provides APIs to spawn, communicate, and stop an isolate. An
 * isolate can be spawned by simply creating a new instance of [Isolate2]. The
 * [Isolate2] instance exposes a port to communicate with the isolate and
 * methods to control its behavior remotely.
 */
 // TODO(sigmund): rename to Isolate once we delete the old implementation
interface Isolate2 default _IsolateFactory {

  /**
   * Create and spawn an isolate that shares the same code as the current
   * isolate, but that starts from [topLevelFunction]. The [topLevelFunction]
   * argument must be a static method closure that takes exactly one
   * argument of type [ReceivePort]. It is illegal to pass a function closure
   * that captures values in scope.
   *
   * When an child isolate is spawned, a new [ReceivePort] is created for it.
   * This port is passed to [topLevelFunction]. A [SendPort] derived from
   * such port is sent to the spawner isolate, which is accessible in
   * [Isolate2.sendPort] field of this instance.
   */
  Isolate2.fromCode(Function topLevelFunction);

  /**
   * Create and spawn an isolate whose code is available at [uri].
   * The code in [uri] must have an method called [: isolateMain :], which takes
   * exactly one argument of type [ReceivePort].
   * Like with [Isolate2.fromCode], a [ReceivePort] is created in the child
   * isolate, and a [SendPort] to it is stored in [Isolate2.sendPort].
   */
  Isolate2.fromUri(String uri);

  /** Port used to communicate with this isolate. */
  SendPort sendPort;
}
