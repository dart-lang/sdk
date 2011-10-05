// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.fling;

import com.google.dart.fling.MessageLoop;

import junit.framework.Assert;

import org.junit.Test;

import java.io.IOException;


public class MessageLoopTest {
  private static void stopIn(final MessageLoop loop, int millis) {
    loop.postTask(new Runnable() {
      @Override public void run() {
        loop.stop();
      }
    }, millis);
  }

  private static class TestTask implements Runnable {
    private int runCount;

    @Override public void run() {
      runCount++;
    }

    public boolean didRun() {
      return runCount > 0;
    }
  }

  @Test public void willItRunImmediateTasks() throws IOException {
    final TestTask a = new TestTask();
    final TestTask b = new TestTask();

    final MessageLoop loop = MessageLoop.create();
    loop.postTask(a);
    loop.postTask(b);
    stopIn(loop, 0);
    loop.run();
    Assert.assertTrue(a.didRun());
    Assert.assertTrue(b.didRun());
  }
}
