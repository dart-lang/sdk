// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import com.google.common.collect.Lists;
import com.google.common.io.CharStreams;
import com.google.common.io.Closeables;
import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.ast.LibraryNode;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.backend.js.analysis.TreeShaker;
import com.google.dart.compiler.common.GenerateSourceMap;
import com.google.dart.compiler.metrics.CompilerMetrics;
import com.google.dart.compiler.resolver.CoreTypeProvider;
import com.google.debugging.sourcemap.FilePosition;
import com.google.debugging.sourcemap.SourceMapSection;

import java.io.IOException;
import java.io.Reader;
import java.io.Writer;
import java.util.Collection;
import java.util.List;

/**
 * A compiler backend that produces raw Javascript.
 */
public class JavascriptBackend extends AbstractJsBackend  {

  public static final String EXTENSION_APP_JS_COMPLETE = EXTENSION_APP_JS + ".complete";

  /**
   * Wraps an Appendable and keeps track of the current offset as line/columns.
   */
  static class CountingAppendable implements Appendable {

    private int line = 0;
    private int column = 0;
    private Appendable out;
    private long charCount = 0;
    
    FilePosition getOffset() {
      return new FilePosition(line, column);
    }

    CountingAppendable(Appendable out) {
      this.out = out;
    }

    @Override
    public Appendable append(CharSequence csq) throws IOException {
      incCount(csq, 0, csq.length());
      return out.append(csq);
    }

    @Override
    public Appendable append(char c) throws IOException {
      incCount(c);
      return out.append(c);
    }

    @Override
    public Appendable append(CharSequence csq, int start, int end)
        throws IOException {
      incCount(csq, start, end);
      return out.append(csq, start, end);
    }

    private void incCount(CharSequence cs, int start, int end) {
      for (int i = 0; i < cs.length(); i++) {
        incCount(cs.charAt(i));
      }
    }

    private void incCount(char c) {
      ++charCount;
      if (c == '\n') {
        line++;
        column = 0;
      } else {
        column++;
      }
    }
  }

  private static class DepsWritingCallback implements DepsCallback {
    private final DartCompilerContext context;
    private CountingAppendable out;
    private final List<SourceMapSection> appSections;
    DepsWritingCallback(
        DartCompilerContext context,
        CountingAppendable out,
        List<SourceMapSection> appSections) {
      this.out = out;
      this.context = context;
      this.appSections = appSections;
    }

    @Override
    public void visitNative(LibraryUnit libUnit, LibraryNode node)
        throws IOException {
      DartSource nativeSrc = libUnit.getSource().getSourceFor(node.getText());
      Reader r = nativeSrc.getSourceReader();
      long charsWrittenForFile = CharStreams.copy(r, out);
    }

    @Override
    public void visitPart(Part part) throws IOException {
      DartSource src = part.unit.getSource();
      assert(src != null);
      Reader r = context.getArtifactReader(src, part.part, EXTENSION_JS);
      if (r == null) {
        return;
      }
      FilePosition offset = out.getOffset();
      assert(src != null);

      long partSize = 0;
      boolean failed = true;
      try {
        partSize = CharStreams.copy(r, out);
        failed = false;
      } finally {
        Closeables.close(r, failed);
      }

      if (partSize > 0) {
        String mapUrl = context.getArtifactUri(src, part.part, EXTENSION_JS_SRC_MAP).toString();
        SourceMapSection sourceMapSection =
            SourceMapSection.forURL(mapUrl, offset.getLine(), offset.getColumn());
        appSections.add(sourceMapSection);
      }
    }

    public long getCharsWritten() {
      return out.charCount;
    }
  }

  private static long packageLibs(Writer w,
                                  List<SourceMapSection> appSections,
                                  DartCompilerContext context) throws IOException {
    final CountingAppendable out = new CountingAppendable(w);

    DepsWritingCallback callback = new DepsWritingCallback(context, out, appSections);
    DependencyBuilder.build(context.getAppLibraryUnit(), callback);
    return callback.getCharsWritten();
  }

  @Override
  public void packageApp(LibrarySource app,
                         Collection<LibraryUnit> libraries,
                         DartCompilerContext context,
                         CoreTypeProvider typeProvider)
      throws IOException {
    
    LibraryUnit appLibraryUnit = context.getAppLibraryUnit();
    boolean hasEntryPoint = appLibraryUnit.getElement().getEntryPoint() != null;
    
    List<SourceMapSection> appSections = Lists.newArrayList();
    String completeArtifactName = EXTENSION_APP_JS;
    if (hasEntryPoint) {
      // Apps with entry points will be reduced so we write into a different file name
      completeArtifactName = EXTENSION_APP_JS_COMPLETE;
    }
    
    Writer out = context.getArtifactWriter(app, "", completeArtifactName);
    long outputFileSize = 0;
    boolean failed = true;
    try {
      // Emit the concatenated Javascript sources in dependency order.
      outputFileSize = packageLibs(out, appSections, context);
      outputFileSize += writeEntryPointCall(getMangledEntryPoint(context), out);
      failed = false;
    } finally {
      Closeables.close(out, failed);
    }
    
    
    if (hasEntryPoint) {
      Writer artifactWriter = context.getArtifactWriter(app, "", EXTENSION_APP_JS);
      try {
        failed = true;
        outputFileSize = TreeShaker.reduce(app, context, completeArtifactName, artifactWriter);
        failed = false;  
      } finally {
        Closeables.close(artifactWriter, failed);
      }
    }
    
    CompilerMetrics compilerMetrics = context.getCompilerMetrics();
    if (compilerMetrics != null) {
      compilerMetrics.packagedJsApplication(outputFileSize, -1);
    }

    Writer srcMapOut = context.getArtifactWriter(app, "", EXTENSION_APP_JS_SRC_MAP);
    failed = true;
    try {
      // TODO(johnlenz): settle how we want to get a reference to the app
      // output.  Do we want this to be a filename, a URL, both?
      new GenerateSourceMap().appendIndexMapTo(srcMapOut, app.getName() + "."
          + EXTENSION_JS, appSections);
      failed = false;
    } finally {
      Closeables.close(srcMapOut, failed);
    }
  }

  @Override
  public String getAppExtension() {
    return EXTENSION_APP_JS;
  }

  @Override
  public String getSourceMapExtension() {
    return EXTENSION_APP_JS_SRC_MAP;
  }

  @Override
  protected boolean shouldOptimize() {
    return false;
  }
}
