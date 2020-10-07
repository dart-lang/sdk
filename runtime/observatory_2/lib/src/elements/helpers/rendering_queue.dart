// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:collection';
import 'dart:async';

/// A generic rendering task that can be scheduled.
abstract class RenderingTask {
  /// Rendering synchronous callback.
  void render();
}

/// A generic synchronization system for rendering operations.
abstract class RenderingBarrier {
  /// Future to the next synchronization barrier (ms from application start).
  Future<num> get next;
}

/// Synchronization system based on the AnimationFrame.
class NextAnimationFrameBarrier implements RenderingBarrier {
  Future<num> get next => window.animationFrame;
}

/// MOCK synchronization system for manual barrier triggering.
class RenderingBarrierMock implements RenderingBarrier {
  final StreamController<num> _stream = new StreamController<num>.broadcast();
  num _ms = 0;

  Future<num> get next => _stream.stream.first;

  /// Trigger the next barrier with an optional numer of ms elapsed.
  void triggerRenderingBarrier({num step: 20}) {
    assert(step != null);
    _stream.add(_ms += step);
  }
}

/// RenderingTask queuing and synchronization system.
class RenderingQueue {
  final RenderingBarrier _barrier;
  final Queue<RenderingTask> _queue = new Queue<RenderingTask>();

  bool get isEmpty => _queue.isEmpty;
  bool get isNotEmpty => _queue.isNotEmpty;

  /// Creates a RenderingQueue with the default synchronization barrier.
  RenderingQueue() : this.fromBarrier(new NextAnimationFrameBarrier());

  /// Creates a RenderingQueue with a custom synchronization barrier.
  RenderingQueue.fromBarrier(this._barrier) {
    assert(this._barrier != null);
  }

  /// Add a task to the queue.
  /// If the current rendering phase is running it will be executed during this
  /// rendering cycle, otherwise it will be queued for the next one.
  void enqueue(RenderingTask r, {bool waitForBarrier: true}) {
    assert(r != null);
    final wasEmpty = _queue.isEmpty;
    _queue.addLast(r);
    // If no task are in the queue there is no rendering phase scheduled.
    if (wasEmpty) {
      if (waitForBarrier) {
        _render();
      } else {
        // We schedule the _renderLoop as a microtask to allow the
        // scheduleRendering method to terminate, due to the fact that it is
        // generally invoked from inside a HtmlElement.attached method
        scheduleMicrotask(_renderLoop);
      }
    }
  }

  Future _render() async {
    await _barrier.next;
    _renderLoop();
  }

  void _renderLoop() {
    while (_queue.isNotEmpty) {
      _queue.first.render();
      _queue.removeFirst();
    }
  }
}
