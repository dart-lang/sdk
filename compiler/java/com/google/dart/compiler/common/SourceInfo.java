// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.common;

import com.google.common.base.Preconditions;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.Lists;
import com.google.common.collect.MapMaker;
import com.google.dart.compiler.Source;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.Serializable;
import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * Contains {@link Source} and location information for AST nodes.
 * <p>
 * Each node in the subtree (other than the contrived nodes) carries source range(s) information
 * relating back to positions in the given source (the given source itself is not remembered with
 * the AST). The source range usually begins at the first character of the first token corresponding
 * to the node; leading whitespace and comments are <b>not</b> included. The source range usually
 * extends through the last character of the last token corresponding to the node; trailing
 * whitespace and comments are <b>not</b> included. There are a handful of exceptions (including the
 * various body declarations). Source ranges nest properly: the source range for a child is always
 * within the source range of its parent, and the source ranges of sibling nodes never overlap.
 */
public final class SourceInfo implements Serializable {

  /**
   * The unknown {@link SourceInfo}.
   */
  public static final SourceInfo UNKNOWN = new SourceInfo(null, 0, 0);

  private static final Map<Source, LinesInfo> lines = new MapMaker().weakKeys().makeMap();

  private final Source source;
  private final int offset;
  private final int length;

  public SourceInfo(Source source, int offset, int length) {
    Preconditions.checkArgument(offset != -1 && length >= 0 || offset == -1 && length == 0);
    this.source = source;
    this.offset = offset;
    this.length = length;
  }

  /**
   * @return the {@link LinesInfo}, may be empty if some {@link Exception} happens, but not
   *         <code>null</code>.
   */
  private static LinesInfo getLinesInfo(Source source) {
    LinesInfo linesInfo = lines.get(source);
    if (linesInfo == null) {
      linesInfo = createLinesInfo(source);
      lines.put(source, linesInfo);
    }
    return linesInfo;
  }

  /**
   * @return the new {@link LinesInfo}, may be empty if some {@link Exception} happens, but not
   *         <code>null</code>.
   */
  private static LinesInfo createLinesInfo(Source source) {
    BufferedReader reader = null;
    try {
      reader = new BufferedReader(source.getSourceReader());
      int offset = 0;
      List<Integer> lineOffsets = Lists.newArrayList(0);
      while (true) {
        int charValue = reader.read();
        if (charValue == -1) {
          break;
        }
        offset++;
        char c = (char) charValue;
        if (c == '\n') {
          lineOffsets.add(offset);
        }
      }
      return new LinesInfo(lineOffsets);
    } catch (Throwable e) {
      return new LinesInfo(ImmutableList.of(0));
    } finally {
      if (reader != null) {
        try {
          reader.close();
        } catch (IOException e) {
          // Ignored
        }
      }
    }
  }

  /**
   * @return the {@link Source}.
   */
  public Source getSource() {
    return source;
  }

  /**
   * @return the 0-based character index in the {@link Source}, may <code>-1</code> if no source
   *         information is recorded.
   */
  public int getOffset() {
    return offset;
  }

  /**
   * @return a (possibly 0) length of this node in the {@link Source}, may <code>0</code> if no
   *         source position information is recorded.
   */
  public int getLength() {
    return length;
  }

  /**
   * @return a 1-based line number in the {@link Source} indicating where the source fragment
   *         begins. May be <code>0</code> if line not found.
   */
  public int getLine() {
    if (source == null) {
      return 0;
    }
    return 1 + getLinesInfo(source).getLineOfOffset(offset);
  }

  /**
   * @return a 1-based column number in the {@link Source} indicating where the source fragment
   *         begins. May be <code>0</code> if column not found.
   */
  public int getColumn() {
    if (source == null) {
      return 0;
    }
    return 1 + getLinesInfo(source).getColumnOfOffset(offset);
  }

  /**
   * Container for information about lines in some {@link Source}.
   */
  private static class LinesInfo {
    private final List<Integer> lineOffsets;

    public LinesInfo(List<Integer> lineOffsets) {
      this.lineOffsets = lineOffsets;
    }

    int getLineOffset(int line) {
      return lineOffsets.get(line);
    }

    int getLineOfOffset(int offset) {
      int index = Collections.binarySearch(lineOffsets, offset);
      if (index >= 0) {
        return index;
      }
      return -(2 + index);
    }

    int getColumnOfOffset(int offset) {
      int line = getLineOfOffset(offset);
      return offset - getLineOffset(line);
    }
  }
}
