// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.common;

import java.lang.ref.WeakReference;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.CyclicBarrier;

public class NameFactoryTest extends NameTestCase {
  private static final int NUM_RETRIES = 50;
  private static final int NUM_THREADS = 10;

  private NameFactory factory;

  @Override
  protected void tearDown() {
    factory = null;
  }

  /**
   * I'm told this can be made to work, but it's flaky for me.
   */
  public void disabledTestGc() {
    factory = new NameFactory();
    insertDefaultNames();
    System.gc();
    System.gc();
    System.gc();
    System.gc();
    factory.cleanUp();
    assertEquals(0, factory.numEntries());
  }

  public void testContention() throws Throwable {
    // Run many times to try to trip a concurreny problem.
    for (int r = 0; r < NUM_RETRIES; ++r) {
      factory = new NameFactory();
      Name[] names = new Name[NUM_INPUTS];
      for (int i = 0; i < NUM_INPUTS; ++i) {
        assertEquals(i, factory.numEntries());
        names[i] = testContentionFor(INPUTS[i]);
        assertEquals(i + 1, factory.numEntries());
      }
    }
  }

  public void testCreation() {
    factory = new NameFactory();
    Name[] names = insertDefaultNames();
    // Check that the same names come back.
    for (int i = 0; i < NUM_INPUTS; ++i) {
      assertEquals(NUM_INPUTS, factory.numEntries());
      Name newName = factory.of(INPUTS[i]);
      assertEquals(names[i], newName);
      assertSame(names[i], newName);
      assertEquals(NUM_INPUTS, factory.numEntries());
    }
  }

  public void testRemoval() {
    factory = new NameFactory();
    Name[] names = insertDefaultNames();
    // Simulate GC removal.
    for (int i = NUM_INPUTS; i > 0; --i) {
      assertEquals(i, factory.numEntries());
      WeakReference<Name> ref = factory.getRefFor(names[NUM_INPUTS - i]);
      ref.clear();
      ref.enqueue();
      factory.cleanUp();
      assertEquals(i - 1, factory.numEntries());
    }
    // Check that different names come back.
    for (int i = 0; i < NUM_INPUTS; ++i) {
      assertEquals(i, factory.numEntries());
      Name newName = factory.of(INPUTS[i]);
      assertNotSame(names[i], newName);
      assertNotEquals(names[i], newName);
      assertEquals(i + 1, factory.numEntries());
    }
  }

  private Name[] insertDefaultNames() {
    Name[] names = new Name[NUM_INPUTS];
    for (int i = 0; i < NUM_INPUTS; ++i) {
      assertEquals(i, factory.numEntries());
      names[i] = factory.of(INPUTS[i]);
      assertEquals(i + 1, factory.numEntries());
    }
    return names;
  }

  private Name testContentionFor(final char[] data) throws Throwable {
    final CyclicBarrier barrier = new CyclicBarrier(NUM_THREADS);
    final CountDownLatch countDown = new CountDownLatch(NUM_THREADS);
    final Object[] results = new Name[NUM_THREADS];
    for (int i = 0; i < NUM_THREADS; ++i) {
      final int id = i;
      new Thread() {
        public void run() {
          try {
            barrier.await();
            results[id] = factory.of(data);
          } catch (Throwable e) {
            results[id] = e;
          } finally {
            countDown.countDown();
          }
        }
      }.start();
    }
    countDown.await();
    Name expected = factory.of(data);
    for (int i = 0; i < NUM_THREADS; ++i) {
      Object result = results[i];
      if (result == null) {
        throw new NullPointerException("Missing results from " + i);
      } else if (results[i] instanceof Throwable) {
        throw (Throwable) results[i];
      } else {
        assertSame(expected, results[i]);
      }
    }
    return expected;
  }
}
