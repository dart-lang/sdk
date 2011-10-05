// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.


interface SendPort extends Hashable {

  /* Sends an asynchronous message to this send port. The message is
   * copied to the receiving isolate. If the message contains any
   * receive ports, they are translated to the corresponding send port
   * before being transmitted. If specified, the replyTo port will be
   * provided to the receiver to facilitate exchanging sequences of
   * messages.
   */
  void send(var message, SendPort replyTo);

  /* Creates a new single-shot receive port, sends a message to this
   * send port with replyTo set to the opened port, and returns the
   * receive port.
   */
  ReceivePort call(var message);

  /* Tests whether [other] is a SendPort pointing to the same
   * ReceivePort as this one.
   */
   bool operator==(var other);

  /* Returns an immutable hash code for this send port that is
   * consistent with the == operator.
   */
  int hashCode();

}


interface ReceivePort factory ReceivePortFactory {

  /* Opens a long-lived port for receiving messages. The returned port
   * must be explicitly closed through [ReceivePort.close].
   */
  ReceivePort();

  /* Opens a single-shot reply port. Once a message has been received
   * on this port, it is automatically closed -- obviously without
   * throwing the message away before it can be processed. This
   * constructor is used indirectly through [SendPort.call].
   */
  ReceivePort.singleShot();

  /* Sets up a callback function for receiving pending or future
   * messages on this receive port.
   */
  void receive(void callback(var message, SendPort replyTo));

  /* Closes this receive port immediately. Pending messages will not
   * be processed and it is impossible to re-open the port. Reply
   * ports possibly created through [SendPort.call] are automatically
   * closed when the reply has been received. Multiple invocations of
   * [close] are allowed but ignored.
   */
  void close();

  /* Converts this receive port to a send port. The send port is
   * canonicalized so repeated invocations of this method are
   * guaranteed to return the same (===) send port.
   */
  SendPort toSendPort();

}


class Isolate {

  Isolate() : this.light();
  Isolate.light() : _isLight = true;
  Isolate.heavy() : _isLight = false;

  bool isLight() { return _isLight; }
  bool isHeavy() { return !_isLight; }

  Promise<SendPort> spawn() {
    return IsolateNatives.spawn(this, _isLight);
  }

  // The private run method is invoked with the receive port. Before
  // main is invoked we store the port in a field so it can be
  // accessed from subclasses of Isolate.
  void _run(ReceivePort port) {
    _port = port;
    main();
  }

  ReceivePort get port() {
    return _port;
  }

  void main() {
  }

  final bool _isLight;
  ReceivePort _port;

  // BUG(5151491): Remove this once we automatically bind functions to
  // the isolate they live in.
  static Function bind(Function f) {
    // This method just forwards to the isolate native implementation.
    return IsolateNatives.bind(f);
  }
}
