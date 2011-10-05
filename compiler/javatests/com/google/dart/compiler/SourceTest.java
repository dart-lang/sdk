// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import java.net.URI;

/**
 * Testing implementation of {@link Source}.
 */
public abstract class SourceTest implements Source {

  private final String name;

  public SourceTest(String name) {
    this.name = name;
  }

  @Override
  public boolean exists() {
    return true;
  }

  @Override
  public long getLastModified() {
    return 0;
  }

  @Override
  public String getName() {
    return name;
  }

  @Override
  public URI getUri() {
    return URI.create(getName()).normalize();
  }
}
