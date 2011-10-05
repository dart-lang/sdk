// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.fling;

import java.io.IOException;
import java.nio.channels.ClosedChannelException;
import java.nio.channels.SelectableChannel;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.Map;
import java.util.PriorityQueue;
import java.util.concurrent.ConcurrentLinkedQueue;

public class MessageLoop {
  private static final ThreadLocal<MessageLoop> instance = new ThreadLocal<MessageLoop>();

  public static MessageLoop get() {
    return instance.get();
  }

  public static MessageLoop create() throws IOException {
    assert get() == null;
    final MessageLoop loop = new MessageLoop();
    instance.set(loop);
    return loop;
  }

  private static class PendingTask implements Comparable<PendingTask> {
    private final Runnable task;
    private final long expiresAt;

    PendingTask(Runnable task, long expiresAt) {
      this.task = task;
      this.expiresAt = expiresAt;
    }

    @Override public int compareTo(PendingTask other) {
      return (int)(this.expiresAt - other.expiresAt);
    }

    void run() {
      task.run();
    }

    boolean hasExpiredBy(long now) {
      return expiresAt < now;
    }
  }

  public interface IoObserver {
    void channelIsAcceptable(SelectionKey key);

    void channelIsConnectable(SelectionKey key);

    void channelIsReadable(SelectionKey key);

    void channelIsWritable(SelectionKey key);
  }

  private final Map<SelectableChannel, IoObserver> observers = new HashMap<SelectableChannel, IoObserver>();

  private final PriorityQueue<PendingTask> pendingTasks = new PriorityQueue<PendingTask>();

  private final ConcurrentLinkedQueue<PendingTask> newTasks = new ConcurrentLinkedQueue<PendingTask>();

  private final Selector selector;

  private boolean active;

  private MessageLoop() throws IOException {
    selector = Selector.open();
  }

  private void handleOrWaitForIoEvents(long timeout) throws IOException {
    if (selector.select(timeout) == 0) {
      return;
    }

    final Iterator<SelectionKey> iter = selector.selectedKeys().iterator();
    while (iter.hasNext()) {
      final SelectionKey key = iter.next();
      final IoObserver observer = observers.get(key.channel());
      if (key.isAcceptable()) {
        observer.channelIsAcceptable(key);
      }
      if (key.isConnectable()) {
        observer.channelIsConnectable(key);
      }
      if (key.isValid() && key.isReadable()) {
        observer.channelIsReadable(key);
      }
      if (key.isValid() && key.isWritable()) {
        observer.channelIsWritable(key);
      }
      iter.remove();
    }
  }

  private long handleTasks() {
    final long now = System.currentTimeMillis();

    // When tasks run they will enqueue new tasks which can easily lead to I/O
    // starvation. So we collect all tasks that need to run before executing any
    // of them.
    final LinkedList<PendingTask> tasksToRun = new LinkedList<PendingTask>();

    // Collect any pending tasks.
    for (PendingTask nextTask = pendingTasks.peek(); nextTask != null && nextTask.hasExpiredBy(now); nextTask = pendingTasks.peek()) {
      tasksToRun.add(pendingTasks.poll());
    }

    // Process all newly arrived tasks by running the expired ones and putting
    // others
    // in the pending queue.
    for (final Iterator<PendingTask> iter = newTasks.iterator(); iter.hasNext();) {
      final PendingTask task = iter.next();
      if (task.hasExpiredBy(now)) {
        tasksToRun.add(task);
      } else {
        pendingTasks.add(task);
      }
      iter.remove();
    }

    for (PendingTask task : tasksToRun) {
      task.run();
    }

    // Determine the approximate amount of time until the next task runs. The
    // first task could actually be overdue already, in which case, we return
    // 0ms.
    final PendingTask next = pendingTasks.peek();
    return next == null ? Long.MAX_VALUE : Math.max(1, next.expiresAt - System.currentTimeMillis());
  }

  // TODO(knorton): I'm not sure I need to reutrn the SelectionKey.
  public SelectionKey addIoObserver(SelectableChannel channel, IoObserver observer, int ops, Object attachment) throws ClosedChannelException {
    final SelectionKey key = channel.register(selector, ops, attachment);
    observers.put(channel, observer);
    return key;
  }

  public void removeIoObserver(IoObserver observer) {
    observers.remove(observer);
  }

  public void postTask(Runnable task, int delay) {
    assert delay >= 0;
    // TODO(knorton): Use a pipe to signal a task arrival.
    newTasks.add(new PendingTask(task, System.currentTimeMillis() + delay));
  }

  public void postTask(Runnable task) {
    postTask(task, 0);
  }

  public void run() throws IOException {
    active = true;
    long timeout = 100;
    while (active) {
      // 1. Check for I/O.
      handleOrWaitForIoEvents(timeout);

      // 2. Check for pending tasks.
      timeout = Math.min(100L, handleTasks());
    }
  }

  public void stop() {
    // Must be called from the MessageLoop's thread.
    active = false;
  }
}
