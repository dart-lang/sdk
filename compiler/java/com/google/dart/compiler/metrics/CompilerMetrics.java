// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.metrics;

import java.io.PrintStream;
import java.lang.management.ManagementFactory;
import java.lang.management.ThreadMXBean;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Collection of compiler metrics.
 */
public final class CompilerMetrics {
  // TODO: Consider refactoring this class so each subsystem has it own metrics class.

  private final long milliStartTime;
  private long milliEndTime = -1;

  // Parser metrics
  private AtomicLong unitsParsed = new AtomicLong();
  private AtomicLong charactersParsed = new AtomicLong();
  private AtomicLong linesParsed = new AtomicLong();
  private AtomicLong charactersParsedExcludingComments = new AtomicLong();
  private AtomicLong linesParsedExcludingComments = new AtomicLong();
  private long nanoParseWallTime = 0;
  private AtomicLong nanoTotalParseTime = new AtomicLong();

  // JavascriptBackend Data
  private long totalJsOutputCharCount;
  private long nativeLibCharCount;
  
  // Timing metrics for complete stages
  private long updateAndResolveTimeStart = 0L;
  private long compileLibrariesTimeStart = 0L;
  private long packageAppTimeStart = 0L;
  private long updateAndResolveTime = 0L;
  private long compileLibrariesTime = 0L;
  private long packageAppTime = 0L;

  public CompilerMetrics() {
    this.milliStartTime = System.currentTimeMillis();
  }

  public void done() {
    if (milliEndTime == -1) {
      milliEndTime = System.currentTimeMillis();
    }
  }

  public void unitParsed(int charactersParsed, int charactersParsedExcludingComments,
      int linesParsed, int linesParsedExcludingComments) {
    this.unitsParsed.incrementAndGet();
    this.charactersParsed.addAndGet(charactersParsed);
    this.charactersParsedExcludingComments.addAndGet(charactersParsedExcludingComments);
    this.linesParsed.addAndGet(linesParsed);
    this.linesParsedExcludingComments.addAndGet(linesParsedExcludingComments);
  }

  /**
   * Writes the metrics to the {@link PrintStream}.
   */
  public void write(PrintStream out) {
    /* This is mainly for the metrics system.  Units should be encoded in
     * the label name and end up as the benchmark names.
     */
    done();
    out.format("Compile-time-total-ms          : %1$.2f%n", getTotalCompilationTime());
    out.format("# Update-and-resolve-time-ms     : %d\n", getUpdateAndResolveTime());
    out.format("# Compile-libraries-time-ms      : %d\n", getCompileLibrariesTime());
    out.format("# Package-app-time-ms            : %d\n", getPackageAppTime());
    out.println("# Compile-time-unit-average-ms  : " + getTimeSpentPerUnit());
    out.format("# Parse-wall-time-ms             : %1$.2f%n", getParseWallTime());
    out.format("# Parse-time-ms                  : %1$.2f%n", getParseTime());
    out.println("# Parsed-units                   : " + getNumUnitsParsed());
    out.println("# Parsed-src-chars               : " + getNumCharsParsed());
    out.println("# Parsed-src-lines               : " + getNumLinesParsed());
    out.println("# Parsed-code-chars              : " + getNumNonCommentChars());
    out.println("# Parsed-code-lines              : " + getNumNonCommentLines());
    out.println("# Output-js-chars                : " + getJSOutputCharSize());
    double jsNativeLibCharSize = (getJSNativeLibCharSize() == -1) ? 0 : getJSNativeLibCharSize();
    out.println("# Output-js-native-lib-chars     : " + jsNativeLibCharSize );
    out.println("# Processed-total-lines-ms       : " + getLinesPerMS());
    out.println("# Processed-code-lines-ms        : " + getNonCommentLinesPerMS());
    out.println("# Ratio-output-intput-total      : " + getRatioOutputToInput());
    out.println("# Ratio-output-intput-code       : " + getRatioOutputToInputExcludingComments());
    out.println("# Ratio-parsing-compile-percent  : " + getPercentTimeParsing() * 100);
  }

  private static double nanoToMillis(long nanoTime) {
    return nanoTime / 1000000.0d;
  }

  /**
   * Records that the application was packaged to JS.
   *
   * @param totalJsOutputCharSize number of characts of JS output produced
   * @param nativeLibCharCount number of characters of JS output consumed by native JS libs or -1 if
   *          the backend did not record this information
   */
  public void packagedJsApplication(long totalJsOutputCharSize, long nativeLibCharCount) {
    this.totalJsOutputCharCount = totalJsOutputCharSize;
    this.nativeLibCharCount = nativeLibCharCount;
  }

  /**
   * Accumulate more parsing time. TODO: Once the parser gets cleaned up we should be able to
   * integrate this with unit parsed.
   */
  public void addParseTimeNano(long nanoTotalParseTime) {
    this.nanoTotalParseTime.addAndGet(nanoTotalParseTime);
  }

  public void addParseWallTimeNano( long nanoWallParseTime) {
    this.nanoParseWallTime = nanoWallParseTime;
  }

  /**
   * Returns the current thread's CPU time or -1 if this is not supported.
   */
  public static long getThreadTime() {
    ThreadMXBean threadMXBean = ManagementFactory.getThreadMXBean();
    if (threadMXBean.isThreadCpuTimeSupported()) {
      return threadMXBean.getCurrentThreadCpuTime();
    }

    return -1;
  }

  public static long getCPUTime() {
    return System.currentTimeMillis() * 1000000;
  }

  public double getTotalCompilationTime() {
    return milliEndTime - milliStartTime;
  }

  public double getParseTime() {
    return nanoToMillis(nanoTotalParseTime.get());
  }

  public double getParseWallTime() {
    return nanoToMillis(nanoParseWallTime);
  }

  public double getNumUnitsParsed() {
    return unitsParsed.get();
  }

  public double getNumCharsParsed() {
    return charactersParsed.get();
  }

  public double getNumLinesParsed() {
    return linesParsed.get();
  }

  public double getNumNonCommentChars() {
    return charactersParsedExcludingComments.get();
  }

  public double getNumNonCommentLines() {
    return linesParsedExcludingComments.get();
  }

  public double getJSOutputCharSize() {
    return totalJsOutputCharCount;
  }

  public double getJSNativeLibCharSize() {
    return nativeLibCharCount;
  }

  public double getPercentCharsConsumedByNativeLibraries() {
    return (getJSNativeLibCharSize() / getNumCharsParsed()) * 100d;
  }

  public double getPercentTimeParsing() {
    return getParseTime() / getTotalCompilationTime();
  }

  public double getTimeSpentPerUnit() {
    if (getNumUnitsParsed() == 0) {
      return 0;
    }
    return getTotalCompilationTime() / getNumUnitsParsed();
  }

  public double getLinesPerMS() {
    return getNumLinesParsed() / getTotalCompilationTime();
  }

  public double getNonCommentLinesPerMS() {
    return getNumNonCommentLines() / getTotalCompilationTime();
  }

  public double getRatioOutputToInput() {
    if (getNumCharsParsed() == 0) {
      return 0;
    }
    return getJSOutputCharSize() / getNumCharsParsed();
  }

  public double getRatioOutputToInputExcludingComments() {
    if (getNumNonCommentChars() == 0) {
      return 0;
    }
    return getJSOutputCharSize() / getNumNonCommentChars();
  }
  
  public long getUpdateAndResolveTime() {
    return updateAndResolveTime;
  }
  
  public long getCompileLibrariesTime() {
    return compileLibrariesTime;
  }
  
  public long getPackageAppTime() {
    return packageAppTime;
  }
  
  public void startUpdateAndResolveTime() {
    updateAndResolveTimeStart = System.currentTimeMillis();
  }
  
  public void startCompileLibrariesTime() {
    compileLibrariesTimeStart = System.currentTimeMillis();
  }
  
  public void startPackageAppTime() {
    packageAppTimeStart = System.currentTimeMillis();
  }
  
  public void endUpdateAndResolveTime() {
    updateAndResolveTime = System.currentTimeMillis() - updateAndResolveTimeStart;
  }
  
  public void endCompileLibrariesTime() {
    compileLibrariesTime = System.currentTimeMillis() - compileLibrariesTimeStart;
  }
  
  public void endPackageAppTime() {
    packageAppTime = System.currentTimeMillis() - packageAppTimeStart;
  }
}
