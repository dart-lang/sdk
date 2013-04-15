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

  external MessageBox.oneShot();
  external MessageBox();
}

external bool _isCloseToken(var object);

/**
 * [IsolateStream]s, together with [IsolateSink]s, are the only means of
 * communication between isolates. Each IsolateStream has a corresponding
 * [IsolateSink]. Any message written into that sink will be delivered to
 * the stream and then dispatched to the stream's subscribers.
 */
class IsolateStream extends Stream<dynamic> {
  bool _isClosed = false;
  final ReceivePort _port;
  StreamController _controller = new StreamController();

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
    if (_isCloseToken(message)) {
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
                            { void onError(error),
                              void onDone(),
                              bool cancelOnError}) {
      return _controller.stream.listen(onData,
                                       onError: onError,
                                       onDone: onDone,
                                       cancelOnError: cancelOnError);
  }
}

/**
 * [IsolateSink]s represent the feed for [IsolateStream]s. Any message written
 * to [this] is delivered to its respective [IsolateStream]. [IsolateSink]s are
 * created by [MessageBox]es.
 *
 * [IsolateSink]s can be transmitted to other isolates.
 */
abstract class IsolateSink extends EventSink<dynamic> {
  // TODO(floitsch): Actually it should be a StreamSink (being able to flow-
  // control).

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
  void add(dynamic message);

  void addError(errorEvent);

  /** Closing multiple times is allowed. */
  void close();

  /**
   * Tests whether [other] is an [IsolateSink] feeding into the same
   * [IsolateStream] as this one.
   */
  bool operator==(var other);
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
 * The optional [unhandledExceptionCallback] argument is invoked whenever an
 * exception inside the isolate is unhandled. It can be seen as a big
 * `try/catch` around everything that is executed inside the isolate. The
 * callback should return `true` when it was able to handled the exception.
 */
external IsolateSink streamSpawnFunction(
    void topLevelFunction(),
    [bool unhandledExceptionCallback(IsolateUnhandledException e)]);
