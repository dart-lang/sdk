// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.Reader;
import java.io.Writer;
import java.net.URI;
import java.net.URISyntaxException;

/**
 * A default implementation of {@link DartArtifactProvider} specifying
 * generated files be placed in the same directory as source files.
 */
public class DefaultDartArtifactProvider extends DartArtifactProvider {

  private final File outputDirectory;

  public DefaultDartArtifactProvider() {
    this(new File("out"));
  }

  public DefaultDartArtifactProvider(File outputDirectory) {
    this.outputDirectory = outputDirectory;
  }

  @Override
  public Reader getArtifactReader(Source source, String part, String extension)
      throws IOException {
    if (PackageLibraryManager.isDartUri(source.getUri())) {
      DartSource bundledSource = getBundledArtifact(source, source, part, extension);
      if (bundledSource != null) {
        Reader reader = null;
        try {
          reader = bundledSource.getSourceReader();
        } catch (FileNotFoundException e) {
          /* thrown if file doesn't exist, which is fine */
        }
        if (reader != null) {
          return new BufferedReader(reader);
        }
      }
    }
    File file = getArtifactFile(source, part, extension);
    if (!file.exists()) {
      return null;
    }
    return new BufferedReader(new FileReader(file));
  }

  @Override
  public URI getArtifactUri(Source source, String part, String extension) {
    try {
      return new URI("file", getArtifactFile(source, part, extension).getPath(), null);
    } catch (URISyntaxException e) {
      throw new IllegalArgumentException(e);
    }
  }

  @Override
  public Writer getArtifactWriter(Source source, String part, String extension) throws IOException {
    return new BufferedWriter(new FileWriter(makeDirectories(getArtifactFile(source, part,
        extension))));
  }

  @Override
  public boolean isOutOfDate(Source source, Source base, String extension) {
    if (PackageLibraryManager.isDartUri(base.getUri())) {
      Source bundledSource = getBundledArtifact(source, base, "", extension);
      if (bundledSource != null && bundledSource.exists()) {
        // Note: Artifacts bundled with sources are always up to date
        return false;
      }
    }
    File artifactFile = getArtifactFile(base, "", extension);
    return !artifactFile.exists() || artifactFile.lastModified() < source.getLastModified();
  }

  // TODO(jbrosenberg): remove 'source' argument from this method, it's not used
  protected DartSource getBundledArtifact(Source source, Source base, String part, String extension) {
    LibrarySource library;
    URI relativeUri;
    if (base instanceof LibrarySource) {
      library = (LibrarySource) base;
      relativeUri = library.getUri().resolve(".").normalize().relativize(base.getUri());
    } else if (base instanceof DartSource){
      library = ((DartSource) base).getLibrary();
      String name = base.getName();
      URI nameUri = URI.create(name).normalize();
      relativeUri = library.getUri().resolve(".").normalize().relativize(nameUri);
    } else {
      throw new AssertionError(base.getClass().getName());
    }

    DartSource bundledSource;
    if (!relativeUri.isAbsolute()) {
      bundledSource = library.getSourceFor(fullname(relativeUri.getPath(), part, extension));
    } else {
      bundledSource = null;
    }
    return bundledSource;
  }

  /**
   * Answer the artifact file associated with the specified source. Only one
   * artifact may be associated with the given extension.
   *
   * @param source the source file (not <code>null</code>)
   * @param part a component of the source file to get a reader for (may be empty).
   * @param extension the file extension for this artifact (not
   *          <code>null</code>, not empty)
   * @return the artifact file (not <code>null</code>)
   */
  protected File getArtifactFile(Source source, String part, String extension) {
    String name = source.getName();
    name = URI.create(name).normalize().toString();
    name = normalizeArtifactName(name);
    File file = new File(outputDirectory, fullname(name, part, extension));
    return file;
  }
  
  /*
   * Removes extraneous punctuation and file path syntax.
   */
  private String normalizeArtifactName(String name) {
    /**
     * For efficiency, String operations are replaced with a single pass over
     * the character array data.
     * 
     * Note: This is a refactor of a previous version which used repeated calls
     * to String.replace(), which turns out to be unnecessarily expensive. This
     * particular method has been identified as being called a large number of
     * times, thus the need for the micro-optimization here.
     * 
     * This is the original logic being implemented here:
     * 
     * <code>
     * name = name.replace("//", File.separator);
     * name = name.replace(":", "");
     * name = name.replace("!", "");
     * name = name.replace("..", "_");
     * </code>
     * 
     * Please update the above if the logic being implemented ever changes.
     * 
     * TODO(jbrosenberg): Figure out a better way such that this normalization
     * is no longer needed in the first place. Source objects could be built
     * from pre-normalized prefixes, etc. Or if it can be called less often,
     * then use pre-compiled Patterns and Matchers instead.
     */
    boolean lastCharWasSlash = false;
    boolean lastCharWasPeriod = false;
    boolean madeChanges = false;
    int nameLen = name.length();
    char[] newName = new char[nameLen];
    int idx = 0;
    for (char ch : name.toCharArray()) {
      if (lastCharWasPeriod && ch != '.') {
        // didn't get a second period, so append the one we did get
        newName[idx++] = '.';
        lastCharWasPeriod = false;
      } else if (lastCharWasSlash && ch != '/') {
        // didn't get a second slash, so append the one we did get
        newName[idx++] = '/';
        lastCharWasSlash = false;
      }

      switch (ch) {
        case ':':
        case '!':
            // replace ':'s and '!'s with empty string
            madeChanges = true;
            break;
        case '/':
            if (lastCharWasSlash) {
              // got a second slash, replace with File.separatorChar
              madeChanges = true;
              newName[idx++] = File.separatorChar;
              lastCharWasSlash = false;
            } else {
              lastCharWasSlash = true;
            }
            break;
        case '.':
            if (lastCharWasPeriod) {
              // got a second period, replace with a '_'
              madeChanges = true;
              newName[idx++] = ('_');
              lastCharWasPeriod = false;
            } else {
              lastCharWasPeriod = true;
            }
            break;
        default:
            newName[idx++] = ch;
            lastCharWasSlash = false;
            lastCharWasPeriod = false;
      }
    }
    if (lastCharWasPeriod) {
      // didn't get a final second period, so append the one we did get
      newName[idx++] = '.';
    } else if (lastCharWasSlash) {
      // didn't get a final second slash, so append the one we did get
      newName[idx++] = '/';
    }

    if (madeChanges) {
      name = new String(newName, 0, idx);
    }

    return name;
  }
  
  private File makeDirectories(File file) {
    file.getParentFile().mkdirs();
    return file;
  }

  private String fullname(String name, String part, String extension) {
    if (part.isEmpty()) {
      return name + "." + extension;
    } else {
      return name + "$" + part + "." + extension;
    }
  }
}
