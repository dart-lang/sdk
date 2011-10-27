// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.testing;

import com.google.dart.compiler.CompilerConfiguration;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.ErrorCode;
import com.google.dart.compiler.ErrorSeverity;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.SubSystem;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.metrics.CompilerMetrics;

import java.io.IOException;
import java.io.Reader;
import java.io.Writer;
import java.net.URI;
import java.util.ArrayList;
import java.util.Collections;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;

/**
 * Common context for test cases.
 */
public class TestCompilerContext extends DartCompilerListener implements DartCompilerContext {

  private final Set<EventKind> ignoredEvents;
  final List<ErrorCode> errors;
  private int typeErrorCount;
  private int warningCount;
  private int errorCount;

  /**
   * @param ignored list of events that will be ignored. All other events cause an AssertionError.
   */
  public TestCompilerContext(EventKind... ignored) {
    EnumSet<EventKind> set = EnumSet.noneOf(EventKind.class);
    for (EventKind kind : ignored) {
      set.add(kind);
    }
    this.ignoredEvents = Collections.unmodifiableSet(set);
    this.errors = new ArrayList<ErrorCode>();
  }

  @Override
  public LibraryUnit getApplicationUnit() {
    throw new AssertionError();
  }

  @Override
  public LibraryUnit getAppLibraryUnit() {
    throw new AssertionError();
  }

  @Override
  public LibraryUnit getLibraryUnit(LibrarySource lib) {
    throw new AssertionError(lib.getName());
  }

  @Override
  public void onError(DartCompilationError event) {
    if (event.getErrorCode().getSubSystem() == SubSystem.STATIC_TYPE) {
      typeErrorCount++;
      handleEvent(event, EventKind.TYPE_ERROR);
    } else if (event.getErrorCode().getErrorSeverity() == ErrorSeverity.ERROR) {
      errorCount++;
      handleEvent(event, EventKind.ERROR);
    } else if (event.getErrorCode().getErrorSeverity() == ErrorSeverity.WARNING) {
      warningCount++;
      handleEvent(event, EventKind.WARNING);
    }
  }

  protected void handleEvent(DartCompilationError event, EventKind kind) {
    errors.add(event.getErrorCode());
    if (!ignoredEvents.contains(kind)) {
      System.err.println("Unexpected Event: " + event + " of kind " + kind);
      throw new AssertionError(event);
    }
  }

  @Override
  public Reader getArtifactReader(Source source, String part, String extension) throws IOException {
    throw new AssertionError(source.getName() + " " + part + "." + extension);
  }

  @Override
  public URI getArtifactUri(DartSource source, String part, String extension) {
    throw new AssertionError(source.getName() + " " + part + "." + extension);
  }

  @Override
  public Writer getArtifactWriter(Source source, String part, String extension) throws IOException {
    throw new AssertionError(source.getName() + " " + part + "." + extension);
  }

  @Override
  public boolean isOutOfDate(Source source, Source base, String extension) {
    throw new AssertionError(source.getName() + " " + base.getName() + " " + extension);
  }

  @Override
  public CompilerMetrics getCompilerMetrics() {
    return null;
  }

  public int getErrorCount() {
    return errorCount;
  }

  public int getWarningCount() {
    return warningCount;
  }

  public int getTypeErrorCount() {
    return typeErrorCount;
  }

  public List<ErrorCode> getErrorCodes() {
    return errors;
  }

  @Override
  public boolean shouldWarnOnNoSuchType() {
    return false;
  }

  @Override
  public CompilerConfiguration getCompilerConfiguration() {
    return null;
  }

  public enum EventKind {
    ERROR,
    TYPE_ERROR,
    WARNING;
  }

  @Override
  public LibrarySource getSystemLibraryFor(String importSpec) {
    return null;
  }

  @Override
  public void unitCompiled(DartUnit unit) {
  }
}
