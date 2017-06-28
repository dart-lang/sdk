// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

/**
 * A factory to expose DOM events as Streams.
 */
class EventStreamProvider<T extends Event> {
  final String _eventType;

  const EventStreamProvider(this._eventType);

  /**
   * Gets a [Stream] for this event type, on the specified target.
   *
   * This will always return a broadcast stream so multiple listeners can be
   * used simultaneously.
   *
   * This may be used to capture DOM events:
   *
   *     Element.keyDownEvent.forTarget(element, useCapture: true).listen(...);
   *
   *     // Alternate method:
   *     Element.keyDownEvent.forTarget(element).capture(...);
   *
   * Or for listening to an event which will bubble through the DOM tree:
   *
   *     MediaElement.pauseEvent.forTarget(document.body).listen(...);
   *
   * See also:
   *
   * [addEventListener](http://docs.webplatform.org/wiki/dom/methods/addEventListener)
   */
  Stream<T> forTarget(EventTarget e, {bool useCapture: false}) =>
      new _EventStream<T>(e, _eventType, useCapture);

  /**
   * Gets an [ElementEventStream] for this event type, on the specified element.
   *
   * This will always return a broadcast stream so multiple listeners can be
   * used simultaneously.
   *
   * This may be used to capture DOM events:
   *
   *     Element.keyDownEvent.forElement(element, useCapture: true).listen(...);
   *
   *     // Alternate method:
   *     Element.keyDownEvent.forElement(element).capture(...);
   *
   * Or for listening to an event which will bubble through the DOM tree:
   *
   *     MediaElement.pauseEvent.forElement(document.body).listen(...);
   *
   * See also:
   *
   * [addEventListener](http://docs.webplatform.org/wiki/dom/methods/addEventListener)
   */
  ElementStream<T> forElement(Element e, {bool useCapture: false}) {
    return new _ElementEventStreamImpl<T>(e, _eventType, useCapture);
  }

  /**
   * Gets an [ElementEventStream] for this event type, on the list of elements.
   *
   * This will always return a broadcast stream so multiple listeners can be
   * used simultaneously.
   *
   * This may be used to capture DOM events:
   *
   *     Element.keyDownEvent._forElementList(element, useCapture: true).listen(...);
   *
   * See also:
   *
   * [addEventListener](http://docs.webplatform.org/wiki/dom/methods/addEventListener)
   */
  ElementStream<T> _forElementList(ElementList e, {bool useCapture: false}) {
    return new _ElementListEventStreamImpl<T>(e, _eventType, useCapture);
  }

  /**
   * Gets the type of the event which this would listen for on the specified
   * event target.
   *
   * The target is necessary because some browsers may use different event names
   * for the same purpose and the target allows differentiating browser support.
   */
  String getEventType(EventTarget target) {
    return _eventType;
  }
}

/** A specialized Stream available to [Element]s to enable event delegation. */
abstract class ElementStream<T extends Event> implements Stream<T> {
  /**
   * Return a stream that only fires when the particular event fires for
   * elements matching the specified CSS selector.
   *
   * This is the Dart equivalent to jQuery's
   * [delegate](http://api.jquery.com/delegate/).
   */
  Stream<T> matches(String selector);

  /**
   * Adds a capturing subscription to this stream.
   *
   * If the target of the event is a descendant of the element from which this
   * stream derives then [onData] is called before the event propagates down to
   * the target. This is the opposite of bubbling behavior, where the event
   * is first processed for the event target and then bubbles upward.
   *
   * ## Other resources
   *
   * * [Event Capture](http://www.w3.org/TR/DOM-Level-2-Events/events.html#Events-flow-capture)
   *   from the W3C DOM Events specification.
   */
  StreamSubscription<T> capture(void onData(T event));
}

/**
 * Adapter for exposing DOM events as Dart streams.
 */
class _EventStream<T extends Event> extends Stream<T> {
  final EventTarget _target;
  final String _eventType;
  final bool _useCapture;

  _EventStream(this._target, this._eventType, this._useCapture);

  // DOM events are inherently multi-subscribers.
  Stream<T> asBroadcastStream(
          {void onListen(StreamSubscription<T> subscription),
          void onCancel(StreamSubscription<T> subscription)}) =>
      this;
  bool get isBroadcast => true;

  StreamSubscription<T> listen(void onData(T event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return new _EventStreamSubscription<T>(
        this._target, this._eventType, onData, this._useCapture);
  }
}

bool _matchesWithAncestors(Event event, String selector) {
  var target = event.target;
  return target is Element ? target.matchesWithAncestors(selector) : false;
}

/**
 * Adapter for exposing DOM Element events as streams, while also allowing
 * event delegation.
 */
class _ElementEventStreamImpl<T extends Event> extends _EventStream<T>
    implements ElementStream<T> {
  _ElementEventStreamImpl(target, eventType, useCapture)
      : super(target, eventType, useCapture);

  Stream<T> matches(String selector) =>
      this.where((event) => _matchesWithAncestors(event, selector)).map((e) {
        e._selector = selector;
        return e;
      });

  StreamSubscription<T> capture(void onData(T event)) =>
      new _EventStreamSubscription<T>(
          this._target, this._eventType, onData, true);
}

/**
 * Adapter for exposing events on a collection of DOM Elements as streams,
 * while also allowing event delegation.
 */
class _ElementListEventStreamImpl<T extends Event> extends Stream<T>
    implements ElementStream<T> {
  final Iterable<Element> _targetList;
  final bool _useCapture;
  final String _eventType;

  _ElementListEventStreamImpl(
      this._targetList, this._eventType, this._useCapture);

  Stream<T> matches(String selector) =>
      this.where((event) => _matchesWithAncestors(event, selector)).map((e) {
        e._selector = selector;
        return e;
      });

  // Delegate all regular Stream behavior to a wrapped Stream.
  StreamSubscription<T> listen(void onData(T event),
      {Function onError, void onDone(), bool cancelOnError}) {
    var pool = new _StreamPool<T>.broadcast();
    for (var target in _targetList) {
      pool.add(new _EventStream<T>(target, _eventType, _useCapture));
    }
    return pool.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  StreamSubscription<T> capture(void onData(T event)) {
    var pool = new _StreamPool<T>.broadcast();
    for (var target in _targetList) {
      pool.add(new _EventStream<T>(target, _eventType, true));
    }
    return pool.stream.listen(onData);
  }

  Stream<T> asBroadcastStream(
          {void onListen(StreamSubscription<T> subscription),
          void onCancel(StreamSubscription<T> subscription)}) =>
      this;
  bool get isBroadcast => true;
}

// We would like this to just be EventListener<T> but that typdef cannot
// use generics until dartbug/26276 is fixed.
typedef _EventListener<T extends Event>(T event);

class _EventStreamSubscription<T extends Event> extends StreamSubscription<T> {
  int _pauseCount = 0;
  EventTarget _target;
  final String _eventType;
  EventListener _onData;
  final bool _useCapture;

  // TODO(leafp): It would be better to write this as
  // _onData = onData == null ? null :
  //   onData is void Function(Event)
  //     ? _wrapZone<Event>(onData)
  //     : _wrapZone<Event>((e) => onData(e as T))
  // In order to support existing tests which pass the wrong type of events but
  // use a more general listener, without causing as much slowdown for things
  // which are typed correctly.  But this currently runs afoul of restrictions
  // on is checks for compatibility with the VM.
  _EventStreamSubscription(
      this._target, this._eventType, void onData(T event), this._useCapture)
      : _onData = onData == null
            ? null
            : _wrapZone<Event>((e) => (onData as dynamic)(e)) {
    _tryResume();
  }

  Future cancel() {
    if (_canceled) return null;

    _unlisten();
    // Clear out the target to indicate this is complete.
    _target = null;
    _onData = null;
    return null;
  }

  bool get _canceled => _target == null;

  void onData(void handleData(T event)) {
    if (_canceled) {
      throw new StateError("Subscription has been canceled.");
    }
    // Remove current event listener.
    _unlisten();
    _onData = _wrapZone<Event>(handleData);
    _tryResume();
  }

  /// Has no effect.
  void onError(Function handleError) {}

  /// Has no effect.
  void onDone(void handleDone()) {}

  void pause([Future resumeSignal]) {
    if (_canceled) return;
    ++_pauseCount;
    _unlisten();

    if (resumeSignal != null) {
      resumeSignal.whenComplete(resume);
    }
  }

  bool get isPaused => _pauseCount > 0;

  void resume() {
    if (_canceled || !isPaused) return;
    --_pauseCount;
    _tryResume();
  }

  void _tryResume() {
    if (_onData != null && !isPaused) {
      _target.addEventListener(_eventType, _onData, _useCapture);
    }
  }

  void _unlisten() {
    if (_onData != null) {
      _target.removeEventListener(_eventType, _onData, _useCapture);
    }
  }

  Future<E> asFuture<E>([E futureValue]) {
    // We just need a future that will never succeed or fail.
    var completer = new Completer<E>();
    return completer.future;
  }
}

/**
 * A stream of custom events, which enables the user to "fire" (add) their own
 * custom events to a stream.
 */
abstract class CustomStream<T extends Event> implements Stream<T> {
  /**
   * Add the following custom event to the stream for dispatching to interested
   * listeners.
   */
  void add(T event);
}

class _CustomEventStreamImpl<T extends Event> extends Stream<T>
    implements CustomStream<T> {
  StreamController<T> _streamController;
  /** The type of event this stream is providing (e.g. "keydown"). */
  String _type;

  _CustomEventStreamImpl(String type) {
    _type = type;
    _streamController = new StreamController.broadcast(sync: true);
  }

  // Delegate all regular Stream behavior to our wrapped Stream.
  StreamSubscription<T> listen(void onData(T event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _streamController.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  Stream<T> asBroadcastStream(
          {void onListen(StreamSubscription<T> subscription),
          void onCancel(StreamSubscription<T> subscription)}) =>
      _streamController.stream;

  bool get isBroadcast => true;

  void add(T event) {
    if (event.type == _type) _streamController.add(event);
  }
}

class _CustomKeyEventStreamImpl extends _CustomEventStreamImpl<KeyEvent>
    implements CustomStream<KeyEvent> {
  _CustomKeyEventStreamImpl(String type) : super(type);

  void add(KeyEvent event) {
    if (event.type == _type) {
      event.currentTarget.dispatchEvent(event._parent);
      _streamController.add(event);
    }
  }
}

/**
 * A pool of streams whose events are unified and emitted through a central
 * stream.
 */
// TODO (efortuna): Remove this when Issue 12218 is addressed.
class _StreamPool<T> {
  StreamController<T> _controller;

  /// Subscriptions to the streams that make up the pool.
  var _subscriptions = new Map<Stream<T>, StreamSubscription<T>>();

  /**
   * Creates a new stream pool where [stream] can be listened to more than
   * once.
   *
   * Any events from buffered streams in the pool will be emitted immediately,
   * regardless of whether [stream] has any subscribers.
   */
  _StreamPool.broadcast() {
    _controller =
        new StreamController<T>.broadcast(sync: true, onCancel: close);
  }

  /**
   * The stream through which all events from streams in the pool are emitted.
   */
  Stream<T> get stream => _controller.stream;

  /**
   * Adds [stream] as a member of this pool.
   *
   * Any events from [stream] will be emitted through [this.stream]. If
   * [stream] is sync, they'll be emitted synchronously; if [stream] is async,
   * they'll be emitted asynchronously.
   */
  void add(Stream<T> stream) {
    if (_subscriptions.containsKey(stream)) return;
    _subscriptions[stream] = stream.listen(_controller.add,
        onError: _controller.addError, onDone: () => remove(stream));
  }

  /** Removes [stream] as a member of this pool. */
  void remove(Stream<T> stream) {
    var subscription = _subscriptions.remove(stream);
    if (subscription != null) subscription.cancel();
  }

  /** Removes all streams from this pool and closes [stream]. */
  void close() {
    for (var subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _controller.close();
  }
}

/**
 * A factory to expose DOM events as streams, where the DOM event name has to
 * be determined on the fly (for example, mouse wheel events).
 */
class _CustomEventStreamProvider<T extends Event>
    implements EventStreamProvider<T> {
  final _eventTypeGetter;
  const _CustomEventStreamProvider(this._eventTypeGetter);

  Stream<T> forTarget(EventTarget e, {bool useCapture: false}) {
    return new _EventStream<T>(e, _eventTypeGetter(e), useCapture);
  }

  ElementStream<T> forElement(Element e, {bool useCapture: false}) {
    return new _ElementEventStreamImpl<T>(e, _eventTypeGetter(e), useCapture);
  }

  ElementStream<T> _forElementList(ElementList e, {bool useCapture: false}) {
    return new _ElementListEventStreamImpl<T>(
        e, _eventTypeGetter(e), useCapture);
  }

  String getEventType(EventTarget target) {
    return _eventTypeGetter(target);
  }

  String get _eventType =>
      throw new UnsupportedError('Access type through getEventType method.');
}
