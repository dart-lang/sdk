// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.isolate;

/**
 * The initial [IsolateStream] available by default for this isolate. This
 * [IsolateStream] is created automatically and it is commonly used to establish
 * the first communication between isolates (see [streamSpawnFunction] and
 * [streamSpawnUri]).
 */
final IsolateStream stream = new IsolateStream._fromOriginalReceivePort(port);

/**
 * A [MessageBox] creates an [IsolateStream], [stream], and an [IsolateSink],
 * [sink].
 *
 * Any message that is written into the [sink] (independent of the isolate) is
 * sent to the [stream] where its subscribers can react to the messages.
 */
class MessageBox {
  final IsolateStream stream;
  final IsolateSink sink;

  MessageBox.oneShot() : this._oneShot(new ReceivePort());
  MessageBox._oneShot(ReceivePort receivePort)
      : stream = new IsolateStream._fromOriginalReceivePortOneShot(receivePort),
        sink = new IsolateSink._fromPort(receivePort.toSendPort());

  MessageBox() : this._(new ReceivePort());
  MessageBox._(ReceivePort receivePort)
      : stream = new IsolateStream._fromOriginalReceivePort(receivePort),
        sink = new IsolateSink._fromPort(receivePort.toSendPort());
}

// Used for mangling.
const int _ISOLATE_STREAM_TOKEN = 132421119;

class _CloseToken {
  /// This token is sent from [IsolateSink]s to [IsolateStream]s to ask them to
  /// close themselves.
  const _CloseToken();
}

/**
 * [IsolateStream]s, together with [IsolateSink]s, are the only means of
 * communication between isolates. Each IsolateStream has a corresponding
 * [IsolateSink]. Any message written into that sink will be delivered to
 * the stream and then dispatched to the stream's subscribers.
 */
class IsolateStream extends Stream<dynamic> {
  bool _isClosed = false;
  final ReceivePort _port;
  StreamController _controller = new StreamController.broadcast();

  IsolateStream._fromOriginalReceivePort(this._port) {
    _port.receive((message, replyTo) {
      assert(replyTo == null);
      _add(message);
    });
  }

  IsolateStream._fromOriginalReceivePortOneShot(this._port) {
    _port.receive((message, replyTo) {
      assert(replyTo == null);
      _add(message);
      close();
    });
  }

  void _add(var message) {
    message = _unmangleMessage(message);
    if (identical(message, const _CloseToken())) {
      close();
    } else {
      _controller.sink.add(message);
    }
  }

  /**
   * Close the stream from the receiving end.
   *
   * Closing an already closed port has no effect.
   */
  void close() {
    if (!_isClosed) {
      _isClosed = true;
      _port.close();
      _controller.close();
    }
  }

  StreamSubscription listen(void onData(event),
                            { void onError(AsyncError error),
                              void onDone(),
                              bool unsubscribeOnError}) {
      return _controller.stream.listen(onData,
                                       onError: onError,
                                       onDone: onDone,
                                       unsubscribeOnError: unsubscribeOnError);
  }

  dynamic _unmangleMessage(var message) {
    _IsolateDecoder decoder = new _IsolateDecoder(
        _ISOLATE_STREAM_TOKEN,
        (data) {
          if (data is! List) return data;
          if (data.length == 2 && data[0] == "Sink" && data[1] is SendPort) {
            return new IsolateSink._fromPort(data[1]);
          }
          if (data.length == 1 && data[0] == "Close") {
            return const _CloseToken();
          }
          return data;
        });
    return decoder.decode(message);
  }
}

/**
 * [IsolateSink]s represent the feed for [IsolateStream]s. Any message written
 * to [this] is delivered to its respective [IsolateStream]. [IsolateSink]s are
 * created by [MessageBox]es.
 *
 * [IsolateSink]s can be transmitted to other isolates.
 */
class IsolateSink extends StreamSink<dynamic> {
  bool _isClosed = false;
  final SendPort _port;
  IsolateSink._fromPort(this._port);

  /**
   * Sends an asynchronous [message] to the linked [IsolateStream]. The message
   * is copied to the receiving isolate.
   *
   * The content of [message] can be: primitive values (null, num, bool, double,
   * String), instances of [IsolateSink]s, and lists and maps whose elements are
   * any of these. List and maps are also allowed to be cyclic.
   *
   * In the special circumstances when two isolates share the same code and are
   * running in the same process (e.g. isolates created via [spawnFunction]), it
   * is also possible to send object instances (which would be copied in the
   * process). This is currently only supported by the dartvm.  For now, the
   * dart2js compiler only supports the restricted messages described above.
   */
  void add(dynamic message) {
    var mangled = _mangleMessage(message);
    _port.send(mangled);
  }

  void signalError(AsyncError errorEvent) {
    throw new UnimplementedError("signalError on isolate streams");
  }

  dynamic _mangleMessage(var message) {
    _IsolateEncoder encoder = new _IsolateEncoder(
        _ISOLATE_STREAM_TOKEN,
        (data) {
          if (data is IsolateSink) return ["Sink", data._port];
          if (identical(data, const _CloseToken())) return ["Close"];
          return data;
        });
    return encoder.encode(message);
  }

  void close() {
    if (_isClosed) throw new StateError("Sending on closed stream");
    add(const _CloseToken());
    _isClosed = true;
  }

  /**
   * Tests whether [other] is an [IsolateSink] feeding into the same
   * [IsolateStream] as this one.
   */
  bool operator==(var other) {
    return other is IsolateSink && _port == other._port;
  }

  int get hashCode => _port.hashCode + 499;
}


/**
 * Creates and spawns an isolate that shares the same code as the current
 * isolate, but that starts from [topLevelFunction]. The [topLevelFunction]
 * argument must be a static top-level function or a static method that takes no
 * arguments.
 *
 * When any isolate starts (even the main script of the application), a default
 * [IsolateStream] is created for it. This sink is available from the top-level
 * getter [stream] defined in this library.
 *
 * [spawnFunction] returns an [IsolateSink] feeding into the child isolate's
 * default stream.
 *
 * See comments at the top of this library for more details.
 */
IsolateSink streamSpawnFunction(void topLevelFunction()) {
  SendPort sendPort = spawnFunction(topLevelFunction);
  return new IsolateSink._fromPort(sendPort);
}

/**
 * Creates and spawns an isolate whose code is available at [uri].  Like with
 * [streamSpawnFunction], the child isolate will have a default [IsolateStream],
 * and a this function returns an [IsolateSink] feeding into it.
 *
 * See comments at the top of this library for more details.
 */
IsolateSink streamSpawnUri(String uri) {
  SendPort sendPort = spawnUri(uri);
  return new IsolateSink._fromPort(sendPort);
}
