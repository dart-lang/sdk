// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

class _SupercedeEntry<T> {
  final _SupercedeStream stream;
  Stream<T> source;
  StreamSubscription subscription = null;
  _SupercedeEntry next;

  _SupercedeEntry(this.stream, this.source, this.next);

  // Whether the source stream is complete.
  bool get isDone => source == null;

  void onData(T data) {
    // Stop all lower-priority sources.
    stream._setData(this, data);
  }

  void onError(AsyncError error) {
    stream._signalError(error);
  }

  void onDone() {
    subscription = null;
    source = null;
    stream._setDone(this);
  }

  void start() {
    assert(subscription == null);
    if (!isDone) {
      subscription =
          source.listen(onData, onError: onError, onDone: onDone);
    }
  }

  void stop() {
    if (!isDone) {
      subscription.cancel();
      subscription = null;
    }
  }

  void pause() {
    if (!isDone) subscription.pause();
  }

  void resume() {
    if (!isDone) subscription.resume();
  }
}

/**
 * [Stream] that forwards data from its active source with greatest priority.
 *
 * The [_SupercedeStream] gets data from some source [Stream]s which
 * are ordered in order of increasing priority.
 * When a higher priority stream provides data, all lower priority streams
 * are dropped.
 *
 * Errors from all (undropped) streams are forwarded.
 */
class _SupercedeStream<T> extends _MultiStreamImpl<T> {
  _SupercedeEntry _entries = null;

  /**
   * Create [_SupercedeStream] from the given [sources].
   *
   * The [sources] are iterated in order of increasing priority.
   */
  _SupercedeStream(Iterable<Stream<T>> sources) {
    // Set up linked list of sources in decreasing priority order.
    // The order allows us to drop all lower priority streams when a higher
    // priority stream provides a value.
    for (Stream<T> stream in sources) {
      _entries = new _SupercedeEntry(this, stream, _entries);
    }
  }

  void _onSubscriptionStateChange() {
    if (_hasSubscribers) {
      for (_SupercedeEntry entry = _entries;
           entry != null;
           entry = entry.next) {
        entry.start();
      }
    } else {
      for (_SupercedeEntry entry = _entries;
           entry != null;
           entry = entry.next) {
        entry.stop();
      }
    }
  }

  void _onPauseStateChange() {
    if (_isPaused) {
      for (_SupercedeEntry entry = _entries;
           entry != null;
           entry = entry.next) {
        entry.pause();
      }
    } else {
      for (_SupercedeEntry entry = _entries;
           entry != null;
           entry = entry.next) {
        entry.resume();
      }
    }
  }

  void _setData(_SupercedeEntry entry, T data) {
    while (entry.next != null)  {
      _SupercedeEntry nextEntry = entry.next;
      entry.next = null;
      nextEntry.stop();
      entry = nextEntry;
    }
    _add(data);
  }

  void _setDone(_SupercedeEntry entry) {
    if (identical(_entries, entry)) {
      // Remove the leading completed streams. These are streams
      // the completed without ever providing data.
      while (_entries.isDone) {
        _entries = _entries.next;
        if (_entries == null) {
          _close();
          return;
        }
      }
    }
    // Otherwise we leave the completed entry in the list and
    // remove it when a higher priority stream provides data or
    // all higher priority streams have completed.
  }
}

/**
 * Helper class for [_CyclicScheduleStream].
 *
 * Used to maintain a list of source streams which are activated in cyclic
 * order.
 *
 * The stream is either unsubscribed, paused or active. Only one stream
 * will be active at a time. A source is not subscribed until it's first
 * activated.
 *
 * If the source completes, the entry is removed from [stream].
 */
class _CycleEntry<T> {
  final _CyclicScheduleStream stream;
  /** A single source stream for the [_CyclicScheduleStream]. */
  Stream source;
  /** The active subscription, if any. */
  StreamSubscription subscription = null;
  /** Next entry in a linked list of entries. */
  _CycleEntry next;

  _CycleEntry(this.stream, this.source);

  void cancel() {
    // This method may be called event if this entry has never been activated.
    if (subscription != null) {
      subscription.cancel();
      subscription = null;
    }
  }

  void pause() {
    ensureSubscribed();
    if (!subscription.isPaused) {
      subscription.pause();
    }
  }

  void activate() {
    ensureSubscribed();
    if (subscription.isPaused) {
      subscription.resume();
    }
  }

  void ensureSubscribed() {
    if (subscription == null) {
      subscription =
          source.listen(stream._onData,
                        onError: stream._signalError,
                        onDone: stream._onDone);
    }
  }
}

/**
 * [Stream] that schedules events from multiple sources in cyclic order.
 *
 * The source streams are activated and paused so that only one data event
 * is generated at a time, and those data events are output on this stream.
 *
 * Error events from the currently active stream are forwarded without
 * changing the schedule. When a source stream ends, it is removed from
 * the schedule.
 */
class _CyclicScheduleStream<T> extends _MultiStreamImpl<T> {
  _CycleEntry _currentEntry = null;
  _CycleEntry _lastEntry = null;

  /**
   * Create a [Stream] that provides data from [sources] one event at a time.
   *
   * The data are provided as one event from each stream in the order they are
   * given by the [Iterable], and then cycling as long as there are data.
   */
  _CyclicScheduleStream(Iterable<Stream<T>> sources) {
    _CycleEntry entry = null;
    for (Stream<T> source in sources) {
      _CycleEntry newEntry = new _CycleEntry(this, source);
      if (_lastEntry == null) {
        _currentEntry = _lastEntry = newEntry;
      } else {
        _lastEntry = _lastEntry.next = newEntry;
      }
    }
    if (_currentEntry == null) {
      _close();
    }
  }

  void _onSubscriptionStateChange() {
    if (_hasSubscribers) {
      _currentEntry.activate();
      for (_CycleEntry entry = _currentEntry.next;
           entry != null;
           entry = entry.next) {
        entry.pause();
      }
      return;
    }
    for (_CycleEntry entry = _currentEntry; entry != null; entry = entry.next) {
      entry.cancel();
    }
  }

  void _onPauseStateChange() {
    if (_isPaused) {
      _currentEntry.pause();
    } else {
      _currentEntry.activate();
    }
  }

  void _onData(T data) {
    if (_currentEntry.next != null) {
      _currentEntry.pause();
      _add(data);
      // Move the current entry to the end of the list.
      _lastEntry = _lastEntry.next = _currentEntry;
      _currentEntry = _currentEntry.next;
      _lastEntry.next = null;
      _currentEntry.activate();
    } else {
      // No pausing with only one entry left.
      _add(data);
    }
  }

  void _onDone() {
    if (_currentEntry.next == null) {
      _close();
      _currentEntry = _lastEntry = null;
    } else {
      // Remove the current entry from the list now that it's complete.
      _currentEntry = _currentEntry.next;
      _currentEntry.activate();
    }
  }
}
