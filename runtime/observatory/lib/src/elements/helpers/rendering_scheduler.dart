// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:observatory/src/elements/helpers/rendering_queue.dart';
export 'package:observatory/src/elements/helpers/rendering_queue.dart';

/// A generic renderable object.
abstract class Renderable {
  void render();
}

/// Event related to a Renderable rendering phase.
class RenderedEvent<T> {
  /// Renderable to which the event is related
  final T element;

  /// Is another rendering scheduled for this element.
  final bool otherRenderScheduled;

  RenderedEvent(this.element, this.otherRenderScheduled) {
    assert(element != null);
    assert(otherRenderScheduled != null);
  }
}

/// Scheduler for rendering operations.
class RenderingScheduler<T extends Renderable> implements RenderingTask {
  bool _enabled = false;
  bool _dirty = false;
  bool _renderingScheduled = false;
  bool _notificationScheduled = false;
  bool _waitForBarrier = false;

  /// Element managed by this scheduler.
  final T element;

  /// Queue used for rendering operations.
  final RenderingQueue queue;

  final List<Future> _wait = <Future>[];

  /// Does the element need a new rendering cycle.
  bool get isDirty => _dirty;

  /// Is the scheduler enabled.
  bool get isEnabled => _enabled;

  final StreamController<RenderedEvent<T>> _onRendered =
      new StreamController<RenderedEvent<T>>.broadcast();
  Stream<RenderedEvent<T>> get onRendered => _onRendered.stream;

  /// Creates a new scheduler for an element.
  /// If no queue is provided it will create a new default configured queue.
  factory RenderingScheduler(T element, {RenderingQueue queue}) {
    assert(element != null);
    if (queue == null) {
      queue = new RenderingQueue();
    }
    return new RenderingScheduler<T>._(element, queue);
  }

  RenderingScheduler._(this.element, this.queue);

  /// Enable the scheduler.
  /// New dirty or schedule request will be considered.
  void enable() {
    if (_enabled) return;
    _enabled = true;
    scheduleRendering();
  }

  /// Disable the scheduler.
  /// New dirty or schedule request will be discarded.
  /// [optional] notify: send a final RenderEvent.
  void disable({bool notify: false}) {
    assert(notify != null);
    if (!_enabled) return;
    _enabled = false;
    if (notify) scheduleNotification();
  }

  /// Set the object as dirty. A rendering will be scheduled.
  void dirty() {
    if (_dirty) return;
    _dirty = true;
    scheduleRendering();
  }

  /// Checks for modification during attribute set.
  /// If value changes a new rendering is scheduled.
  /// set attr(T v) => _attr = _r.checkAndReact(_attr, v);
  T checkAndReact<T>(T oldValue, T newValue) {
    if (oldValue != newValue)
      dirty();
    else
      scheduleNotification();
    return newValue;
  }

  /// Schedules a new rendering phase.
  void scheduleRendering() {
    if (_renderingScheduled) return;
    if (!_enabled) return;
    queue.enqueue(this, waitForBarrier: _waitForBarrier);
    _waitForBarrier = true;
    _renderingScheduled = true;
  }

  /// Renders the element (if the scheduler is enabled).
  /// It will clear the dirty flag.
  void render() {
    _renderingScheduled = false;
    if (!_enabled) return;
    _dirty = false;
    _wait.clear();
    element.render();
    scheduleNotification();
    if (_dirty) scheduleRendering();
  }

  /// Schedules a notification.
  void scheduleNotification() {
    if (_notificationScheduled) return;
    _notify();
    _notificationScheduled = true;
  }

  void waitFor(Iterable<Future> it) {
    _wait.addAll(it);
  }

  Future _notify() async {
    await Future.wait(_wait);
    _wait.clear();
    _onRendered.add(new RenderedEvent<T>(element, _dirty));
    _notificationScheduled = false;
  }
}
