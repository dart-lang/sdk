// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.dart;

import com.google.common.io.CharStreams;
import com.google.common.io.Closeables;
import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.ast.DartToSourceVisitor;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.backend.common.AbstractBackend;
import com.google.dart.compiler.resolver.CoreTypeProvider;
import com.google.dart.compiler.util.DefaultTextOutput;
import com.google.dart.compiler.util.TextOutput;

import java.io.IOException;
import java.io.Reader;
import java.io.Writer;
import java.util.Collection;

/**
 * A compiler backend that produces optimized Dart.
 */
public class DartBackend extends AbstractBackend {

  public static final String EXTENSION_DART = "opt.dart";
  public static final String EXTENSION_DART_SRC_MAP = "opt.dart.map";



  private static void packageLibs(Collection<LibraryUnit> libraries,
                                  Writer w,
                                  DartCompilerContext context)
      throws IOException {
    for (LibraryUnit libUnit : libraries) {
      for (DartUnit unit : libUnit.getUnits()) {
        DartSource src = unit.getSource();
        if (src != null) {
          Reader r = context.getArtifactReader(src, "", EXTENSION_DART);
          boolean failed = true;
          try {
            CharStreams.copy(r, w);
            failed = false;
          } finally {
            Closeables.close(r, failed);
          }
        }
      }
    }
  }

  @Override
  public boolean isOutOfDate(DartSource src, DartCompilerContext context) {
    return context.isOutOfDate(src, src, EXTENSION_DART);
  }

  @Override
  public void compileUnit(DartUnit unit, DartSource src,
      DartCompilerContext context, CoreTypeProvider typeProvider) throws IOException {
    // Generate Javascript output.
    TextOutput out = new DefaultTextOutput(false);
    DartToSourceVisitor srcGenerator = new DartToSourceVisitor(out);
    // TODO(johnlenz): Determine if we want to make source maps
    // optional.
    srcGenerator.generateSourceMap(true);
    srcGenerator.accept(unit);
    Writer w = context.getArtifactWriter(src, "", EXTENSION_DART);
    boolean failed = true;
    try {
      w.write(out.toString());
      failed = false;
    } finally {
      Closeables.close(w, failed);
    }
    // Write out the source map.
    w = context.getArtifactWriter(src, "", EXTENSION_DART_SRC_MAP);
    failed = true;
    try {
      srcGenerator.writeSourceMap(w, src.getName());
      failed = false;
    } finally {
      Closeables.close(w, failed);
    }
  }

  @Override
  public void packageApp(LibrarySource app,
                         Collection<LibraryUnit> libraries,
                         DartCompilerContext context,
                         CoreTypeProvider typeProvider) throws IOException {
    Writer out = context.getArtifactWriter(app, "", EXTENSION_DART);
    boolean failed = true;
    try {
      // Emit the concatenated Javascript sources in dependency order.
      packageLibs(libraries, out, context);

      // Emit entry point call.
      // TODO: How does a dart app start?
      // out.write(app.getEntryMethod() + "();");
      failed = false;
    } finally {
      Closeables.close(out, failed);
    }
  }

  @Override
  public String getAppExtension() {
    return EXTENSION_DART;
  }

  @Override
  public String getSourceMapExtension() {
    return EXTENSION_DART_SRC_MAP;
  }
}
