// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import java.io.IOException;

/**
 * Tests for binary expression optimizations.
 */
public class JsArrayExprOptTest extends ExprOptTest {

  public void testListExprOpt() throws IOException {
    String js = compileSingleUnit(getName());
    // base case.
    {
      String write = findMarkerAtOccurrence(js, "_list0_", 2);
      assertEquals(write, "_list0_[$inlineArrayIndexCheck(_list0_, 0)] = 1");
      String read = findMarkerAtOccurrence(js, "_list0_", 3);
      assertEquals(read, "_list0_[$inlineArrayIndexCheck(_list0_, 0)]");
    }
    // Const array
    {
      String write = findMarkerAtOccurrence(js, "_list1_", 2);
      assertEquals(write, "_list1_.ASSIGN_INDEX$operator(0, tmp$0 = 1) , tmp$0");
      String read = findMarkerAtOccurrence(js, "_list1_", 3);
      assertEquals(read, "_list1_[$inlineArrayIndexCheck(_list1_, 0)]");
    }
    // custom implementation of [].
    {
      String write = findMarkerAtOccurrence(js, "_list2_", 2);
      assertEquals(write, "_list2_.ASSIGN_INDEX$operator(0, tmp$1 = 'foo') , tmp$1");
      String read = findMarkerAtOccurrence(js, "_list2_", 3);
      assertEquals(read, "_list2_.INDEX$operator(0)");
    }
    // untyped.
    {
      String write = findMarkerAtOccurrence(js, "_list3_", 2);
      assertEquals(write, "_list3_.ASSIGN_INDEX$operator(0, tmp$2 = 'foo') , tmp$2");
      String read = findMarkerAtOccurrence(js, "_list3_", 3);
      assertEquals(read, "_list3_.INDEX$operator(0)");
    }
    // index expression.
    {
      String write = findMarkerAtOccurrence(js, "_list4_", 2);
      assertEquals(write, "_list4_[$inlineArrayIndexCheck(_list4_, i_0 + j_0)] = 'foo'");
      String read = findMarkerAtOccurrence(js, "_list4_", 3);
      assertEquals(read, "_list4_[$inlineArrayIndexCheck(_list4_, i_0 - j_0)]");
    }
    // nested array - 0 dimension
    {
      String write = findMarkerAtOccurrence(js, "_list5_", 2);
      assertEquals(write, "_list5_[$inlineArrayIndexCheck(_list5_, 0)] = $Dart$Null");
      String read = findMarkerAtOccurrence(js, "_list5_", 3);
      assertEquals(read, "_list5_[$inlineArrayIndexCheck(_list5_, 0)]");
    }
    // nested array - 1 dimension
    {
      String write = findMarkerAtOccurrence(js, "_list5_", 4);
      assertEquals(write, "_list5_[$inlineArrayIndexCheck(_list5_, 0)][$inlineArrayIndexCheck("
          + "_list5_[$inlineArrayIndexCheck(_list5_, 0)], 1)] = $Dart$Null");
      String read = findMarkerAtOccurrence(js, "_list5_", 5);
      assertEquals(read, "_list5_[$inlineArrayIndexCheck(_list5_, 0)][$inlineArrayIndexCheck("
          + "_list5_[$inlineArrayIndexCheck(_list5_, 0)], 1)]");
    }
    // nested array - 2 dimension
    {
      String write = findMarkerAtOccurrence(js, "_list5_", 6);
      assertEquals(write, "_list5_[$inlineArrayIndexCheck(_list5_, 0)]"
          + "[$inlineArrayIndexCheck(_list5_[$inlineArrayIndexCheck(_list5_, 0)], 1)]"
          + "[$inlineArrayIndexCheck(_list5_[$inlineArrayIndexCheck(_list5_, 0)]"
          + "[$inlineArrayIndexCheck(_list5_[$inlineArrayIndexCheck(_list5_, 0)], 1)]"
          + ", 2)] = 1");
      String read = findMarkerAtOccurrence(js, "_list5_", 7);
      assertEquals(read, "_list5_[$inlineArrayIndexCheck(_list5_, 0)]"
          + "[$inlineArrayIndexCheck(_list5_[$inlineArrayIndexCheck(_list5_, 0)], 1)]"
          + "[$inlineArrayIndexCheck(_list5_[$inlineArrayIndexCheck(_list5_, 0)]"
          + "[$inlineArrayIndexCheck(_list5_[$inlineArrayIndexCheck(_list5_, 0)], 1)]" + ", 2)]");
    }
  }

  public void testListSubTypeExprOpt() throws IOException {
    String js = compileSingleUnit(getName());
    // Array<T> subtype.
    {
      String write = findMarkerAtOccurrence(js, "_list0_", 2);
      assertEquals(write, "_list0_.ASSIGN_INDEX$operator(0, tmp$0 = 'foo') , tmp$0");
      String read = findMarkerAtOccurrence(js, "_list0_", 3);
      assertEquals(read, "_list0_.INDEX$operator(0)");
    }
  }
}
