// Copyright 2006-2008 the V8 project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// Ported by the Dart team to Dart.

// This is a Dart implementation of the Richards benchmark from:
//
//    http://www.cl.cam.ac.uk/~mr10/Bench.html
//
// The benchmark was originally implemented in BCPL by
// Martin Richards.

// @dart=2.9

import 'package:benchmark_harness/benchmark_harness.dart';

void main() {
  const Richards().report();
}

/// Richards imulates the task dispatcher of an operating system.
class Richards extends BenchmarkBase {
  const Richards() : super('Richards');

  @override
  void run() {
    final Scheduler scheduler = Scheduler();
    scheduler.addIdleTask(ID_IDLE, 0, null, COUNT);

    Packet queue = Packet(null, ID_WORKER, KIND_WORK);
    queue = Packet(queue, ID_WORKER, KIND_WORK);
    scheduler.addWorkerTask(ID_WORKER, 1000, queue);

    queue = Packet(null, ID_DEVICE_A, KIND_DEVICE);
    queue = Packet(queue, ID_DEVICE_A, KIND_DEVICE);
    queue = Packet(queue, ID_DEVICE_A, KIND_DEVICE);
    scheduler.addHandlerTask(ID_HANDLER_A, 2000, queue);

    queue = Packet(null, ID_DEVICE_B, KIND_DEVICE);
    queue = Packet(queue, ID_DEVICE_B, KIND_DEVICE);
    queue = Packet(queue, ID_DEVICE_B, KIND_DEVICE);
    scheduler.addHandlerTask(ID_HANDLER_B, 3000, queue);

    scheduler.addDeviceTask(ID_DEVICE_A, 4000, null);

    scheduler.addDeviceTask(ID_DEVICE_B, 5000, null);

    scheduler.schedule();

    if (scheduler.queueCount != EXPECTED_QUEUE_COUNT ||
        scheduler.holdCount != EXPECTED_HOLD_COUNT) {
      print('Error during execution: queueCount = ${scheduler.queueCount}'
          ', holdCount = ${scheduler.holdCount}.');
    }
    if (EXPECTED_QUEUE_COUNT != scheduler.queueCount) {
      throw 'bad scheduler queue-count';
    }
    if (EXPECTED_HOLD_COUNT != scheduler.holdCount) {
      throw 'bad scheduler hold-count';
    }
  }

  static const int DATA_SIZE = 4;
  static const int COUNT = 1000;

  /// These two constants specify how many times a packet is queued and
  /// how many times a task is put on hold in a correct run of richards.
  /// They don't have any meaning a such but are characteristic of a
  /// correct run so if the actual queue or hold count is different from
  /// the expected there must be a bug in the implementation.
  static const int EXPECTED_QUEUE_COUNT = 2322;
  static const int EXPECTED_HOLD_COUNT = 928;

  static const int ID_IDLE = 0;
  static const int ID_WORKER = 1;
  static const int ID_HANDLER_A = 2;
  static const int ID_HANDLER_B = 3;
  static const int ID_DEVICE_A = 4;
  static const int ID_DEVICE_B = 5;
  static const int NUMBER_OF_IDS = 6;

  static const int KIND_DEVICE = 0;
  static const int KIND_WORK = 1;
}

/// A scheduler can be used to schedule a set of tasks based on their relative
/// priorities.  Scheduling is done by maintaining a list of task control blocks
/// which holds tasks and the data queue they are processing.
class Scheduler {
  int queueCount = 0;
  int holdCount = 0;
  TaskControlBlock currentTcb;
  int currentId;
  TaskControlBlock list;
  List<TaskControlBlock> blocks =
      List<TaskControlBlock>(Richards.NUMBER_OF_IDS);

  /// Add an idle task to this scheduler.
  void addIdleTask(int id, int priority, Packet queue, int count) {
    addRunningTask(id, priority, queue, IdleTask(this, 1, count));
  }

  /// Add a work task to this scheduler.
  void addWorkerTask(int id, int priority, Packet queue) {
    addTask(id, priority, queue, WorkerTask(this, Richards.ID_HANDLER_A, 0));
  }

  /// Add a handler task to this scheduler.
  void addHandlerTask(int id, int priority, Packet queue) {
    addTask(id, priority, queue, HandlerTask(this));
  }

  /// Add a handler task to this scheduler.
  void addDeviceTask(int id, int priority, Packet queue) {
    addTask(id, priority, queue, DeviceTask(this));
  }

  /// Add the specified task and mark it as running.
  void addRunningTask(int id, int priority, Packet queue, Task task) {
    addTask(id, priority, queue, task);
    currentTcb.setRunning();
  }

  /// Add the specified task to this scheduler.
  void addTask(int id, int priority, Packet queue, Task task) {
    currentTcb = TaskControlBlock(list, id, priority, queue, task);
    list = currentTcb;
    blocks[id] = currentTcb;
  }

  /// Execute the tasks managed by this scheduler.
  void schedule() {
    currentTcb = list;
    while (currentTcb != null) {
      if (currentTcb.isHeldOrSuspended()) {
        currentTcb = currentTcb.link;
      } else {
        currentId = currentTcb.id;
        currentTcb = currentTcb.run();
      }
    }
  }

  /// Release a task that is currently blocked and return the next block to run.
  TaskControlBlock release(int id) {
    final TaskControlBlock tcb = blocks[id];
    if (tcb == null) return tcb;
    tcb.markAsNotHeld();
    if (tcb.priority > currentTcb.priority) return tcb;
    return currentTcb;
  }

  /// Block the currently executing task and return the next task control block
  /// to run.  The blocked task will not be made runnable until it is explicitly
  /// released, even if new work is added to it.
  TaskControlBlock holdCurrent() {
    holdCount++;
    currentTcb.markAsHeld();
    return currentTcb.link;
  }

  /// Suspend the currently executing task and return the next task
  /// control block to run.
  /// If new work is added to the suspended task it will be made runnable.
  TaskControlBlock suspendCurrent() {
    currentTcb.markAsSuspended();
    return currentTcb;
  }

  /// Add the specified packet to the end of the worklist used by the task
  /// associated with the packet and make the task runnable if it is currently
  /// suspended.
  TaskControlBlock queue(Packet packet) {
    final TaskControlBlock t = blocks[packet.id];
    if (t == null) return t;
    queueCount++;
    packet.link = null;
    packet.id = currentId;
    return t.checkPriorityAdd(currentTcb, packet);
  }
}

/// A task control block manages a task and the queue of work packages
/// associated with it.
class TaskControlBlock {
  TaskControlBlock link;
  int id; // The id of this block.
  int priority; // The priority of this block.
  Packet queue; // The queue of packages to be processed by the task.
  Task task;
  int state;

  TaskControlBlock(this.link, this.id, this.priority, this.queue, this.task) {
    state = queue == null ? STATE_SUSPENDED : STATE_SUSPENDED_RUNNABLE;
  }

  /// The task is running and is currently scheduled.
  static const int STATE_RUNNING = 0;

  /// The task has packets left to process.
  static const int STATE_RUNNABLE = 1;

  /// The task is not currently running. The task is not blocked as such and may
  /// be started by the scheduler.
  static const int STATE_SUSPENDED = 2;

  /// The task is blocked and cannot be run until it is explicitly released.
  static const int STATE_HELD = 4;

  static const int STATE_SUSPENDED_RUNNABLE = STATE_SUSPENDED | STATE_RUNNABLE;
  static const int STATE_NOT_HELD = ~STATE_HELD;

  void setRunning() {
    state = STATE_RUNNING;
  }

  void markAsNotHeld() {
    state = state & STATE_NOT_HELD;
  }

  void markAsHeld() {
    state = state | STATE_HELD;
  }

  bool isHeldOrSuspended() {
    return (state & STATE_HELD) != 0 || (state == STATE_SUSPENDED);
  }

  void markAsSuspended() {
    state = state | STATE_SUSPENDED;
  }

  void markAsRunnable() {
    state = state | STATE_RUNNABLE;
  }

  /// Runs this task, if it is ready to be run, and returns the next
  /// task to run.
  TaskControlBlock run() {
    Packet packet;
    if (state == STATE_SUSPENDED_RUNNABLE) {
      packet = queue;
      queue = packet.link;
      state = queue == null ? STATE_RUNNING : STATE_RUNNABLE;
    } else {
      packet = null;
    }
    return task.run(packet);
  }

  /// Adds a packet to the worklist of this block's task, marks this as
  /// runnable if necessary, and returns the next runnable object to run
  /// (the one with the highest priority).
  TaskControlBlock checkPriorityAdd(TaskControlBlock task, Packet packet) {
    if (queue == null) {
      queue = packet;
      markAsRunnable();
      if (priority > task.priority) return this;
    } else {
      queue = packet.addTo(queue);
    }
    return task;
  }

  @override
  String toString() => 'tcb { $task@$state }';
}

///  Abstract task that manipulates work packets.
abstract class Task {
  Scheduler scheduler; // The scheduler that manages this task.

  Task(this.scheduler);

  TaskControlBlock run(Packet packet);
}

/// An idle task doesn't do any work itself but cycles control between the two
/// device tasks.
class IdleTask extends Task {
  int v1; // A seed value that controls how the device tasks are scheduled.
  int count; // The number of times this task should be scheduled.

  IdleTask(Scheduler scheduler, this.v1, this.count) : super(scheduler);

  @override
  TaskControlBlock run(Packet packet) {
    count--;
    if (count == 0) return scheduler.holdCurrent();
    if ((v1 & 1) == 0) {
      v1 = v1 >> 1;
      return scheduler.release(Richards.ID_DEVICE_A);
    }
    v1 = (v1 >> 1) ^ 0xD008;
    return scheduler.release(Richards.ID_DEVICE_B);
  }

  @override
  String toString() => 'IdleTask';
}

/// A task that suspends itself after each time it has been run to simulate
/// waiting for data from an external device.
class DeviceTask extends Task {
  Packet v1;

  DeviceTask(Scheduler scheduler) : super(scheduler);

  @override
  TaskControlBlock run(Packet packet) {
    if (packet == null) {
      if (v1 == null) return scheduler.suspendCurrent();
      final Packet v = v1;
      v1 = null;
      return scheduler.queue(v);
    }
    v1 = packet;
    return scheduler.holdCurrent();
  }

  @override
  String toString() => 'DeviceTask';
}

/// A task that manipulates work packets.
class WorkerTask extends Task {
  int v1; // A seed used to specify how work packets are manipulated.
  int v2; // Another seed used to specify how work packets are manipulated.

  WorkerTask(Scheduler scheduler, this.v1, this.v2) : super(scheduler);

  @override
  TaskControlBlock run(Packet packet) {
    if (packet == null) {
      return scheduler.suspendCurrent();
    }
    if (v1 == Richards.ID_HANDLER_A) {
      v1 = Richards.ID_HANDLER_B;
    } else {
      v1 = Richards.ID_HANDLER_A;
    }
    packet.id = v1;
    packet.a1 = 0;
    for (int i = 0; i < Richards.DATA_SIZE; i++) {
      v2++;
      if (v2 > 26) v2 = 1;
      packet.a2[i] = v2;
    }
    return scheduler.queue(packet);
  }

  @override
  String toString() => 'WorkerTask';
}

/// A task that manipulates work packets and then suspends itself.
class HandlerTask extends Task {
  Packet v1;
  Packet v2;

  HandlerTask(Scheduler scheduler) : super(scheduler);

  @override
  TaskControlBlock run(Packet packet) {
    if (packet != null) {
      if (packet.kind == Richards.KIND_WORK) {
        v1 = packet.addTo(v1);
      } else {
        v2 = packet.addTo(v2);
      }
    }
    if (v1 != null) {
      final int count = v1.a1;
      Packet v;
      if (count < Richards.DATA_SIZE) {
        if (v2 != null) {
          v = v2;
          v2 = v2.link;
          v.a1 = v1.a2[count];
          v1.a1 = count + 1;
          return scheduler.queue(v);
        }
      } else {
        v = v1;
        v1 = v1.link;
        return scheduler.queue(v);
      }
    }
    return scheduler.suspendCurrent();
  }

  @override
  String toString() => 'HandlerTask';
}

/// A simple package of data that is manipulated by the tasks.  The exact layout
/// of the payload data carried by a packet is not importaint, and neither is
/// the nature of the work performed on packets by the tasks. Besides carrying
/// data, packets form linked lists and are hence used both as data and
/// worklists.
class Packet {
  Packet link; // The tail of the linked list of packets.
  int id; // An ID for this packet.
  int kind; // The type of this packet.
  int a1 = 0;

  List<int> a2 = List(Richards.DATA_SIZE);

  Packet(this.link, this.id, this.kind);

  /// Add this packet to the end of a worklist, and return the worklist.
  Packet addTo(Packet queue) {
    link = null;
    if (queue == null) return this;
    Packet peek, next = queue;
    while ((peek = next.link) != null) {
      next = peek;
    }
    next.link = this;
    return queue;
  }

  @override
  String toString() => 'Packet';
}
