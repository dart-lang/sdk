// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Base class for all RpcProxy's
 *
 * RpcProxy objects run in the "client" isolate and have a SendPort which
 * they use to send messages to RpcReceiver objects running in a "service"
 * isolate.
 */

class RpcProxy {
  final Future<SendPort> futurePort;
  RpcProxy(Future<SendPort> this.futurePort) {}

  /**
    * Called by derived classes to send a command through a SendPort to
    * an RpcReceiver.
    *
    * parameters:
    *   command - String identifying what command to execute
    *   args - optional list of arguments to the command (this may contain other
    *      RpcProxy objects to refer to other target objects in the service
    *      isolate).
    *
    * returns:
    *   a Future object that will be set to the value that was
    *     received as a reply to the SendPort call.
    */
  Future sendCommand(String command, List args, adjustReply(Object value)) {
    Completer completer = new Completer();
    futurePort.then((SendPort port) {
        args = _filterArgs(args);
        port.call({"command" : command, "args" : args}).receive(
            (value, ignoreReplyTo) {
          assert(ignoreReplyTo === null);
          value = _filterException(value);
          if (adjustReply != null) {
            // give derived proxy class a chance to transate SendPort to
            // RpcProxy
            value = adjustReply(value);
          }
          if (value is Exception) {
            completer.completeException(value);
          } else {
            completer.complete(value);
          }
        }
      );
    });
    return completer.future;
  }

  /** Convert RpcProxy objects to SendPorts. */
  static List _filterArgs(List args) {
    if (args == null) {
      return null;
    }
    List filtered = new List();
    for (Object arg in args) {
      if (arg is RpcProxy) {
        RpcProxy proxy = arg;
        // TODO - need to figure out if/how to wait for proxy's
        // port to be ready
        filtered.add(proxy.futurePort.value);
      } else {
        filtered.add(arg);
      }
    }
    return filtered;
  }

  // TODO (mattsh) hack, remove once we have serializable exceptions
  Object _filterException(Object value) {
    // Check if value is a serialized exception.
    Exception e = RpcException.parse(value);
    if (e != null) {
      return e;
    } else {
      return value;
    }
  }
}



/**
 * Base class for all Receivers
 *
 * RpcReceiver objects have a ReceivePort, where they receive commands (from
 * RpcProxy objects) that they interpret and translate into method
 * calls on a "target" object.
 *
 * All RpcReceiver derived classes must implement the [receiveCommand] abstract
 * method (where they actually command messages and call
 * appropriate methods on the target object).
 *
 * type parameters:
 *   T - the type of the target object that this a receiver for
 */
class RpcReceiver<T> {

   // static map of containing all receivers in this isolate.  This is used
   // to be able to find a receiver and target, given a SendPort.
  static Map<SendPort, RpcReceiver> _receivers;
  static _register(RpcReceiver receiver) {
    if (_receivers == null) {
      _receivers = new Map<SendPort, RpcReceiver>();
    }
    _receivers[receiver._receivePort.toSendPort()] = receiver;
  }

  static void closeAll() {
    for (RpcReceiver receiver in _receivers.getValues()) {
      receiver._receivePort.close();
    }
  }

  /** the port that this receiver will listen on */
  final ReceivePort _receivePort;

  /** the "target" object that this RpcReceiver will be calling
   * to actually do some work.
   */
  final T target;

  RpcReceiver(T this.target, ReceivePort this._receivePort) {
    // place this receiver in the receiver registry
    _register(this);

    // start listening on the receive port for command messages
    _receivePort.receive((var message, SendPort replyTo) {
      String command = message["command"];

      // filter incoming arguments (looking for SendPorts
      // that we need to translate to RpcReceiver objects)
      List args = _filterIncomingArgs(message["args"]);

      // Call the derived RpcReceiver to execute the command
      // (if the command throws an exception, then catch the
      // exception, serialize it, and send as the reply)
      Object reply;
      try {
        reply = receiveCommand(message["command"], args);
      } catch (Object e) {
        reply = RpcException.format(e);
      }

      reply = _filterReply(reply);

      // send reply back to the proxy
      replyTo.send(reply, null);
    });
  }

  /**
  * Translate any ReceivePort objects in the arguments to
  * the corresponding target object.
  */
  static List _filterIncomingArgs(List originalArgs) {
    List args = new List();
    var i = 0;
    if (originalArgs != null) {
      for (var arg in originalArgs) {
        if (arg is SendPort) {
          if (_receivers[arg] == null) {
            throw "can't find receiver for SendPort";
          }
          arg = _receivers[arg].target;
          if (arg == null) {
            throw "receiver is missing target";
          }
        }
        args.add(arg);
        i++;
      }
    }
    return args;
  }

  /**
   * Walk over the reply that this receiver is about to send
   * back, and translate RpcReceiver objects in the reply to the
   * corresponding ReceivePort.
   */
   // TODO(mattsh) need to walk deeply
  static _filterReply(Object reply) {
    if (reply is RpcReceiver) {
      RpcReceiver receiver = reply;
      reply = receiver._receivePort.toSendPort();
    }
    return reply;
  }

  /**
   * (implemented by derived classes).
   *
   * parameters -
   *  command - String identifying what command to execute
   *    on the target object
   *  args - list of arguments to the command (if any arguments
   *    were ReceivePorts, these have been translated to the
   *    corresponding target objects, so this List79 will not
   *    contain any ReceivePorts)
   */
  abstract Object receiveCommand(String command, List args);
}

// TODO - need better way to serialize exceptions.  For now
// we take the message, and prefix with a recognizable string.
class RpcException implements Exception {

  static final String prefix = "RpcException:";

  final String message;
  const RpcException(String this.message);

  String toString() {
    return message;
  }

  static String format(Object e) {
    return prefix + e.toString();
  }

  static RpcException parse(Object object) {
    if (object === null || !(object is String)) {
      return null;
    }
    String s = object;
    if (!s.startsWith(prefix)) {
      return null;
    }
    return new RpcException(s.substring(prefix.length, s.length));
  }
}
