// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.dart.compiler.util.DartSourceString;
import com.google.dart.compiler.util.Lists;
import com.google.dart.compiler.util.Paths;

import java.io.File;
import java.io.PrintWriter;
import java.io.Reader;
import java.io.StringReader;
import java.io.StringWriter;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Create a default app library specification when compiling a single dart file.
 *
 * @author johnlenz@google.com (John Lenz)
 */
public class DefaultLibrarySource extends UrlSource implements LibrarySource {
  private static final String WRAPPED_NAME_PREFIX = "_DefaultLibrarySource.wrapper.";
  private final File sourceFile;
  private final Map<String, DartSource> sources;
  private final Map<String, LibrarySource> imports;
  private String source;
  private String wrappedName;

  // TODO: Deprecated
  public DefaultLibrarySource(List<String> sources, String entryPoint) {
    this(sources.get(0), Paths.toFiles(sources),  entryPoint);
  }

  // TODO: Deprecated
  public DefaultLibrarySource(List<String> sources, List<String> imports, String entryPoint) {
    this(sources.get(0), Paths.toFiles(sources), Paths.toFiles(imports), entryPoint);
  }

  // TODO: Deprecated
  public DefaultLibrarySource(File sourceFile, String entryPoint) {
    this(sourceFile.getName(), Lists.<File> create(sourceFile),
         Lists.<File> create(), entryPoint);
  }

  public DefaultLibrarySource(String appName, List<File> sourceFiles, String entryPoint) {
    this(appName, sourceFiles, Lists.<File> create(), entryPoint);
  }

  /**
   * Answer a new instance representing a {@link LibrarySource} with the
   * specified name and that contains the specified imports and source files.
   *
   * @param appName the application name (not <code>null</code>, not empty)
   * @param sourceFiles the source files to be included in the application (not
   *          <code>null</code>, and must contain at least one file)
   * @param importFiles libraries to be imported into the application (e.g. from
   *          #import directives)
   * @param entryPoint The name of the static method to call to invoke the
   *          library. A synthetic main() method will be generated which wraps a call to
   *          this method. Pass <code>null</code> to use the default main() method
   *          lookup.
   */
  public DefaultLibrarySource(String appName, List<File> sourceFiles, List<File> importFiles,
      String entryPoint) {
    this(sourceFiles.get(0));

    for (File file : sourceFiles) {
      String relPath = Paths.relativePathFor(sourceFile, file);
      this.sources.put(relPath, new UrlDartSource(file, this));
    }
    for (File file : importFiles) {
      String relPath = Paths.relativePathFor(sourceFile, file);
      this.imports.put(relPath, new UrlLibrarySource(file));
    }
    wrappedName = WRAPPED_NAME_PREFIX + appName;
    source = generateSource(wrappedName, sourceFile, importFiles, sourceFiles, entryPoint);
    this.sources.put(wrappedName, new DartSourceString(wrappedName, source));
  }

  private DefaultLibrarySource(File sourceFile) {
    super(sourceFile);

    this.sourceFile = sourceFile;
    this.sources = new HashMap<String, DartSource>();
    this.imports = new HashMap<String, LibrarySource>();
  }

  /**
   * Generate source declaring a library. An app library will specify a
   * non-<code>null</code> entryPoint.
   *
   * @param name the name of the application or library
   * @param imports a collection of relative paths indicating the libraries
   *          imported by this application or library
   * @param sources a collection of relative paths indicating the dart sources
   *          included in this application or library
   * @param entryPoint The name of the static method to call to invoke the
   *          library. A synthetic main() method will be generated which wraps a call to
   *          this method. Pass <code>null</code> to use the default main() method
   *          lookup.
   * @return the source (not <code>null</code>)
   */
  public static String generateSource(String name, List<String> imports,
      List<String> sources, String entryPoint) {
    return generateSource(name, new File(name), Paths.toFiles(imports),
        Paths.toFiles(sources), entryPoint);
  }

  /**
   * Generate source declaring a library. If an entryPoint is provided a main()
   * method will be synthesized which wraps a call to the provided entryPoint
   * method.
   *
   * @param name the name of the application or library
   * @param baseFile the application or library file that will contain this
   *        source or any file in that same directory (not <code>null</code>,
   *        but does not need to exist)
   * @param importFiles a collection of library files imported by this
   *        application or library
   * @param sourceFiles a collection of dart source files included in this
   *        application or library
  * @param entryPoint The name of the static method to call to invoke the
   *          library. A synthetic main() method will be generated which wraps a call to
   *          this method. Pass <code>null</code> to use the default main() method
   *          lookup.
   * @return the source (not <code>null</code>)
   */
  public static String generateSource(String name, File baseFile, List<File> importFiles,
      List<File> sourceFiles, String entryPoint) {
    StringWriter sw = new StringWriter(200);
    PrintWriter pw = new PrintWriter(sw);
    pw.println("library " + name + ";");
    if (importFiles != null) {
      for (File file : importFiles) {
        String relPath = file.getPath();
        if (!relPath.startsWith("dart:")) {
          relPath = Paths.relativePathFor(baseFile, file);
        }
        if (relPath != null) {
          pw.println("import '" + relPath + "';");
        }
      }
    }
    if (sourceFiles != null) {
      for (File file : sourceFiles) {
        String relPath = Paths.relativePathFor(baseFile, file);
        if (relPath != null) {
          pw.println("part '" + relPath + "';");
        }
      }
    }
    if (entryPoint != null) {
      // synthesize a main method, which wraps the entryPoint method call
      pw.println();
      pw.println(DartCompiler.MAIN_ENTRY_POINT_NAME + "() {");
      pw.println("  " + entryPoint + "();");
      pw.println("}");
    }
    return sw.toString();
  }

  @Override
  public Reader getSourceReader() {
    return new StringReader(source);
  }

  @Override
  public String getUniqueIdentifier() {
    return "string://" + wrappedName;
  }

  @Override
  public URI getUri() {
    try {
      // A bogus uri (but which ends with our wrappedName)
      return new URI("string://" + wrappedName);
    } catch (URISyntaxException e) {
      throw new AssertionError(e);
    }
  }

  @Override
  public String getName() {
    return wrappedName;
  }

  @Override
  public LibrarySource getImportFor(String relPath) {
    return imports.get(relPath);
  }

  @Override
  public DartSource getSourceFor(String relPath) {
    return sources.get(relPath);
  }
}
