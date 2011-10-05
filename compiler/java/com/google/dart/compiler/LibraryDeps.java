// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.dart.compiler.ast.DartUnit;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.Reader;
import java.io.StringWriter;
import java.io.Writer;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Represents a library's dependencies artifact.
 */
public class LibraryDeps {

  /**
   * Each dependency record contains the library in which it was found, along with a hash of its
   * structure. Any change in the hash of the target dependency will force a recompile of the
   * associated compilation unit.
   */
  public static class Dependency {
    private final URI libUri;
    private final String hash;

    public Dependency(URI libUri, String hash) {
      this.libUri = libUri;
      this.hash = hash;
    }

    public String getHash() {
      return hash;
    }

    public URI getLibUri() {
      return libUri;
    }
  }

  /**
   * Each source is a map from class names to its associated {@link Dependency}.
   * 
   * A special dependency entry, called a 'hole', represents a name that, if
   * newly-defined in the library scope, will force a recompile of the unit.
   * This is represented by the static constant {@link Source#HOLE}.
   */
  public static class Source {
    private final Map<String, Dependency> deps = new ConcurrentHashMap<String, Dependency>();
    private final static Dependency HOLE = new Dependency(null, null);

    /**
     * Gets the node names of all dependencies for this source.
     */
    public Iterable<String> getNodeNames() {
      return deps.keySet();
    }

    public void putDependency(String nodeName, Dependency dep) {
      deps.put(nodeName, dep);
    }

    public Dependency getDependency(String nodeName) {
      return deps.get(nodeName);
    }

    public void putHole(String nodeName) {
      deps.put(nodeName, HOLE);
    }

    public boolean isHole(String nodeName) {
      return deps.containsKey(nodeName) && (deps.get(nodeName) == HOLE);
    }
  }

  public static LibraryDeps fromReader(Reader reader) throws IOException {
    LibraryDeps deps = new LibraryDeps();
    BufferedReader buf = new BufferedReader(reader);
    String srcName;
    while (null != (srcName = buf.readLine())) {
      Source src = new Source();

      String line;
      while (null != (line = buf.readLine())) {
        // Blank line: next source.
        if (line.length() == 0) {
          break;
        }

        String[] parts = line.split(" ");
        switch (parts.length) {
          case 3:
            // Full dependency.
            try {
              src.deps.put(parts[0], new Dependency(new URI(parts[1]), parts[2]));
            } catch (URISyntaxException e) {
              return null;
            }
            break;
          case 1:
            // Name only: hole.
            src.deps.put(parts[0], Source.HOLE);
            break;
          default:
            return null;
        }
      }

      deps.sources.put(srcName, src);
    }

    return deps;
  }

  private final Map<String, Source> sources = new ConcurrentHashMap<String, Source>();

  public LibraryDeps() {
  }

  public Source getSource(String sourceName) {
    return sources.get(sourceName);
  }

  public Iterable<String> getSourceNames() {
    return sources.keySet();
  }

  public void setSource(String sourceName, Source source) {
    sources.put(sourceName, source);
  }

  @Override
  public String toString() {
    try {
      StringWriter writer = new StringWriter();
      write(writer);
      return writer.toString();
    } catch (IOException e) {
      throw new AssertionError();
    }
  }

  public void update(DartUnit unit, DartCompilerContext context) {
    // Update the library deps to reflect this unit's classes.
    LibraryDepsVisitor.exec(unit, this);
  }

  public void write(Writer writer) throws IOException {
    // For stability from run to run, this output needs to be sorted
    ArrayList<String> sortedSourceNames = new ArrayList<String>(sources.size());
    sortedSourceNames.addAll(sources.keySet());
    Collections.sort(sortedSourceNames);
    
    for (String srcName : sortedSourceNames) {
      writer.write(srcName);
      writer.write('\n');
      Source src = sources.get(srcName);
      
      // sort the types per source name
      ArrayList<String> sortedTypes = new ArrayList<String>(src.deps.size());
      sortedTypes.addAll(src.deps.keySet());
      Collections.sort(sortedTypes);
      
      for (String type : sortedTypes) {
        writer.write(type);

        Dependency dep = src.getDependency(type);
        if (dep != Source.HOLE) {
          writer.write(' ');
          writer.write(dep.libUri.toString());
          writer.write(' ');
          writer.write(dep.hash);
        }

        writer.write('\n');
      }

      writer.write('\n');
    }
  }
}
