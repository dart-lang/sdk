// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.common;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.PrintStream;
import java.io.StringWriter;
import java.io.UnsupportedEncodingException;

/**
 * Tests for {@link Name}.
 */
public class NameTest extends NameTestCase {
  private static final Name AM = Name.of(_AM);
  private static final Name EMPTY = Name.of(_EMPTY);
  private static final Name HIGHCHARS = Name.of(_HIGHCHARS);
  private static final Name NAME = Name.of(_NAME);

  private static final Name[] NAMES = {AM, EMPTY, HIGHCHARS, NAME};

  public void testEquals() {
    for (int i = 0; i < NUM_INPUTS; ++i) {
      for (int j = 0; j < NUM_INPUTS; ++j) {
        if (i == j) {
          assertEquals(NAMES[j], NAMES[i]);
          assertEquals(Name.of(INPUTS[j]), NAMES[i]);
        } else {
          assertNotEquals(NAMES[j], NAMES[i]);
          assertNotEquals(Name.of(INPUTS[j]), NAMES[i]);
        }
        assertNotEquals(null, NAMES[i]);
        assertNotEquals(NAMES[i], null);
        assertNotEquals(NAMES[i].toString(), NAMES[i]);
        assertNotEquals(NAMES[i], NAMES[i].toString());
      }
    }
  }

  public void testFailureModes() {
    try {
      Name.of(null);
      fail("Expected NullPointerException");
    } catch (NullPointerException expected) {
    }
    try {
      Name.of(_NAME, -1, 3);
      fail("Expected IndexOutOfBoundsException");
    } catch (IndexOutOfBoundsException expected) {
    }
    try {
      Name.of(_NAME, 2, 3);
      fail("Expected IndexOutOfBoundsException");
    } catch (IndexOutOfBoundsException expected) {
    }
  }

  public void testHashCode() {
    for (int i = 0; i < NUM_INPUTS; ++i) {
      assertEquals(computeHashCode(INPUTS[i]), NAMES[i].hashCode());
    }
  }

  public void testIdentity() {
    for (int i = 0; i < NUM_INPUTS; ++i) {
      for (int j = 0; j < NUM_INPUTS; ++j) {
        if (i == j) {
          assertSame(NAMES[j], NAMES[i]);
          assertSame(Name.of(INPUTS[j]), NAMES[i]);
        } else {
          assertNotSame(NAMES[j], NAMES[i]);
          assertNotSame(Name.of(INPUTS[j]), NAMES[i]);
        }
        assertNotSame(null, NAMES[i]);
        assertNotSame(NAMES[i], null);
        assertNotSame(NAMES[i].toString(), NAMES[i]);
        assertNotSame(NAMES[i], NAMES[i].toString());
      }
    }
  }

  public void testSerialization() throws Exception {
    ByteArrayOutputStream baos = new ByteArrayOutputStream();
    ObjectOutputStream oos = new ObjectOutputStream(baos);
    for (int i = 0; i < NUM_INPUTS; ++i) {
      oos.writeObject(NAMES[i]);
    }
    oos.close();

    ObjectInputStream ois = new ObjectInputStream(new ByteArrayInputStream(
        baos.toByteArray()));
    for (int i = 0; i < NUM_INPUTS; ++i) {
      assertSame(NAMES[i], ois.readObject());
    }
  }

  public void testSubsequence() {
    assertEquals(Name.of("name".toCharArray(), 1, 2), AM);
    assertSame(Name.of("name".toCharArray(), 1, 2), AM);
  }

  public void testToString() {
    for (int i = 0; i < NUM_INPUTS; ++i) {
      assertEquals(String.valueOf(INPUTS[i]), NAMES[i].toString());
    }
  }

  public void testWriteTo() throws Exception {
    for (int i = 0; i < NUM_INPUTS; ++i) {
      assertEquals(String.valueOf(INPUTS[i]), writeToOutputStream(NAMES[i]));
      assertEquals(String.valueOf(INPUTS[i]), writeToPrintStream(NAMES[i]));
      assertEquals(String.valueOf(INPUTS[i]), writeToWriter(NAMES[i]));
    }
  }

  private int computeHashCode(char[] data) {
    return Name.computeHashCode(data, 0, data.length);
  }

  private String writeToOutputStream(Name name) throws IOException {
    ByteArrayOutputStream baos = new ByteArrayOutputStream();
    name.writeBytesTo(baos);
    return new String(baos.toByteArray(), Name.CHARSET);
  }

  private String writeToPrintStream(Name name) throws UnsupportedEncodingException {
    ByteArrayOutputStream baos = new ByteArrayOutputStream();
    PrintStream ps = new PrintStream(baos, false, Name.CHARSET.name());
    name.writeCharsTo(ps);
    ps.close();
    assertFalse(ps.checkError());
    return new String(baos.toByteArray(), Name.CHARSET);
  }

  private String writeToWriter(Name name) throws IOException {
    StringWriter writer = new StringWriter();
    name.writeCharsTo(writer);
    return writer.toString();
  }
}
