// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import java.io.Reader;
import java.io.StringReader;
import java.io.StringWriter;
import java.io.Writer;
import java.net.URI;
import java.util.Date;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Testing implementation of {@link DartArtifactProvider}.
 */
public class MockArtifactProvider extends DartArtifactProvider {

  private static class Artifact {
    StringWriter writer = new StringWriter();
    long lastModified;
  }

  private final Map<String, Artifact> artifacts = new ConcurrentHashMap<String, Artifact>();

  public MockArtifactProvider() {
  }

  @Override
  public Reader getArtifactReader(Source source, String part, String ext) {
    Artifact artifact = artifacts.get(keyFor(source, part, ext));
    if (artifact == null) {
      return null;
    }
    return new StringReader(artifact.writer.toString());
  }

  @Override
  public URI getArtifactUri(Source source, String part, String ext) {
    return URI.create("file:" + keyFor(source, part, ext));
  }

  @Override
  public Writer getArtifactWriter(Source source, String part, String ext) {
    Artifact artifact = new Artifact();
    artifacts.put(keyFor(source, part, ext), artifact);
    artifact.lastModified = new Date().getTime();
    return artifact.writer;
  }

  @Override
  public boolean isOutOfDate(Source source, Source base, String ext) {
    Artifact artifact = artifacts.get(keyFor(base, "", ext));
    if (artifact == null) {
      return true;
    }

    return source.getLastModified() > artifact.lastModified;
  }

  /**
   * Quick way to get an artifact without going through the reader.
   */
  public String getArtifactString(Source source, String part, String ext) {
    Artifact artifact = artifacts.get(keyFor(source, part, ext));
    if (artifact == null) {
      return null;
    }

    return artifact.writer.toString();
  }

  /**
   * Removes the given artifact, by name.
   */
  public void removeArtifact(String name, String part, String ext) {
    artifacts.remove(keyFor(name, part, ext));
  }

  private String keyFor(Source source, String part, String ext) {
    return keyFor(source.getName(), part, ext);
  }

  private String keyFor(String sourceName, String part, String ext) {
    if (!part.isEmpty()) {
      part = "$" + part;
    }
    return sourceName + part + "/" + ext;
  }
}
