// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler;

import com.google.common.base.Objects;
import com.google.common.base.Splitter;
import com.google.common.base.Strings;
import com.google.common.collect.Iterables;
import com.google.common.collect.Maps;
import com.google.common.collect.Sets;
import com.google.dart.compiler.ast.DartUnit;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.Reader;
import java.io.Writer;
import java.net.URI;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

/**
 * Represents a library's dependencies artifact.
 */
public class LibraryDeps {
  private static final String VERSION = "v00001";

  /**
   * Each dependency record contains the library in which it was found, name of the unit in this
   * library and last-modified timestamp. Any change in the timestamp of the target dependency will
   * force a recompile of the associated compilation unit.
   */
  public static class Dependency {
    private final URI libUri;
    private final String unitName;
    private final long lastModified;

    public Dependency(URI libUri, String unitName, long lastModified) {
      this.libUri = libUri;
      this.unitName = unitName;
      this.lastModified = lastModified;
    }

    @Override
    public boolean equals(Object obj) {
      if (obj instanceof Dependency) {
        Dependency dep = (Dependency) obj;
        return Objects.equal(libUri, dep.libUri) && Objects.equal(unitName, dep.unitName);
      }
      return false;
    }

    @Override
    public int hashCode() {
      return Objects.hashCode(libUri, unitName);
    }

    public URI getLibUri() {
      return libUri;
    }

    public String getUnitName() {
      return unitName;
    }

    public long getLastModified() {
      return lastModified;
    }
  }

  public static class Source {
    private final Set<Dependency> deps = Sets.newHashSet();
    private final Set<String> topSymbols = Sets.newHashSet();
    private final Set<String> allSymbols = Sets.newHashSet();
    private final Set<String> holes = Sets.newHashSet();
    private boolean shouldRecompileOnAnyTopLevelChange = false;

    /**
     * @return the {@link Set} of {@link Dependency}s.
     */
    public Set<Dependency> getDeps() {
      return deps;
    }

    /**
     * @return the names of top-level elements, such as methods and classes.
     */
    public Set<String> getTopSymbols() {
      return topSymbols;
    }

    /**
     * @return the names of all elements in unit, such as names of local variables, fields, etc.
     */
    public Set<String> getAllSymbols() {
      return allSymbols;
    }

    /**
     * @return the names of functions, which are invoked without qualifier. So, declaration or
     *         removing function with such name on top-level should cause recompiling.
     */
    public Set<String> getHoles() {
      return holes;
    }

    /**
     * @return <code>true</code> if this unit should be recompiled on any change in the set of
     *         top-level symbols. Typically unit has compilation errors, which potentially may be
     *         fixed, so we should recompile this unit.
     */
    public boolean shouldRecompileOnAnyTopLevelChange() {
      return shouldRecompileOnAnyTopLevelChange;
    }

    /**
     * Adds new {@link Dependency}.
     */
    public void addDep(Dependency dep) {
      deps.add(dep);
    }

    /**
     * Adds symbol to the {@link Set} of top symbols.
     */
    public void addTopSymbol(String symbol) {
      if (!Strings.isNullOrEmpty(symbol)) {
        topSymbols.add(symbol);
      }
    }

    /**
     * Adds symbol to the {@link Set} of all symbols.
     */
    public void addAllSymbol(String symbol) {
      allSymbols.add(symbol);
    }

    /**
     * Adds new hole for {@link #getHoles()}.
     */
    public void addHole(String hole) {
      holes.add(hole);
    }
  }

  public static LibraryDeps fromReader(Reader reader) {
    try {
      return fromReaderEx(reader);
    } catch (Throwable e) {
      return null;
    }
  }

  private static LibraryDeps fromReaderEx(Reader reader) throws Exception {
    LibraryDeps deps = new LibraryDeps();
    BufferedReader buf = new BufferedReader(reader);
    // Check version.
    {
      String line = buf.readLine();
      if (!Objects.equal(line, VERSION)) {
        return deps;
      }
    }
    // Read units dependencies.
    String relPath;
    while (null != (relPath = buf.readLine())) {
      Source source = new Source();
      // Read flags.
      source.shouldRecompileOnAnyTopLevelChange = Boolean.parseBoolean(buf.readLine());
      // Read top symbols.
      {
        String line = buf.readLine();
        Iterable<String> topSymbols = Splitter.on(' ').omitEmptyStrings().split(line);
        Iterables.addAll(source.topSymbols, topSymbols);
      }
      // Read all symbols.
      {
        String line = buf.readLine();
        Iterable<String> allSymbols = Splitter.on(' ').omitEmptyStrings().split(line);
        Iterables.addAll(source.allSymbols, allSymbols);
      }
      // Read holes.
      {
        String line = buf.readLine();
        Iterable<String> holes = Splitter.on(' ').omitEmptyStrings().split(line);
        Iterables.addAll(source.holes, holes);
      }
      // Read dependencies.
      while (true) {
        String line = buf.readLine();
        // Blank line: next unit.
        if (line.length() == 0) {
          break;
        }
        // Parse line.
        String[] parts = line.split(" ");
        source.deps.add(new Dependency(new URI(parts[0]), parts[1], Long.parseLong(parts[2])));
      }
      // Remember dependencies for current unit.
      deps.sources.put(relPath, source);
    }
    return deps;
  }

  private final Map<String, Source> sources = Maps.newHashMap();

  public LibraryDeps() {
  }

  /**
   * @return the relative paths of all units with remembered dependencies.
   */
  public Set<String> getUnitPaths() {
    return sources.keySet();
  }

  /**
   * @return all {@link Source} descriptions for all units in this library.
   */
  public Iterable<Source> getSources() {
    return sources.values();
  }

  /**
   * @return the {@link Source} description of the unit with given path.
   */
  public Source getSource(String relPath) {
    return sources.get(relPath);
  }

  /**
   * Remembers {@link Dependency}s of the unit with given path.
   */
  public void putSource(String relPath, Source source) {
    sources.put(relPath, source);
  }

  /**
   * Update the library dependencies to reflect this unit's classes.
   */
  public void update(DartCompilerMainContext context, DartUnit unit) {
    Source source = new Source();
    DartSource unitSource = (DartSource) unit.getSourceInfo().getSource();
    String relPath = unitSource.getRelativePath();
    putSource(relPath, source);
    // Remember dependencies.
    LibraryDepsVisitor.exec(unit, source);
    // Fill Source with symbols.
    for (String name : unit.getDeclarationNames()) {
      source.addAllSymbol(name);
    }
    for (String name : unit.getTopDeclarationNames()) {
      source.addTopSymbol(name);
    }
    // Analyze errors and see if any of them should force recompilation.
    List<DartCompilationError> sourceErrors = context.getSourceErrors(unitSource);
    for (DartCompilationError error : sourceErrors) {
      if (error.getErrorCode().needsRecompilation()) {
        source.shouldRecompileOnAnyTopLevelChange = true;
        break;
      }
    }
  }

  public void write(Writer writer) throws IOException {
    // Write version.
    writer.write(VERSION);
    writer.write('\n');
    // Write entries.
    for (Entry<String, Source> entry : sources.entrySet()) {
      String relPath = entry.getKey();
      Source source = entry.getValue();
      // Unit name.
      writer.write(relPath);
      writer.write('\n');
      // Flags.
      writer.write(Boolean.toString(source.shouldRecompileOnAnyTopLevelChange));
      writer.write('\n');
      // Write top symbols.
      for (String symbol : source.topSymbols) {
        writer.write(symbol);
        writer.write(' ');
      }
      writer.write('\n');
      // Write all symbols.
      for (String symbol : source.allSymbols) {
        writer.write(symbol);
        writer.write(' ');
      }
      writer.write('\n');
      // Write holes.
      for (String hole : source.holes) {
        writer.write(hole);
        writer.write(' ');
      }
      writer.write('\n');
      // Write dependencies.
      for (Dependency dep : source.deps) {
        writer.write(dep.libUri.toString());
        writer.write(' ');
        writer.write(dep.unitName);
        writer.write(' ');
        writer.write(Long.toString(dep.lastModified));
        writer.write('\n');
      }
      // Empty line after each unit.
      writer.write('\n');
    }
  }
}
