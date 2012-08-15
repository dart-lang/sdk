// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.common.base.Objects;
import com.google.common.collect.Sets;

import java.util.List;
import java.util.Set;

/**
 * Information about import - prefix and {@link LibraryUnit}.
 */
public class LibraryImport {
  private final LibraryUnit library;
  private final String prefix;
  private final Set<String> showNames;
  private final Set<String> hideNames;
  private final boolean exported;

  public LibraryImport(LibraryUnit library, String prefix, List<ImportCombinator> combinators,
      boolean exported) {
    this.library = library;
    this.prefix = prefix;
    this.showNames = createCombinatorsSet(combinators, true);
    this.hideNames = createCombinatorsSet(combinators, false);
    this.exported = exported;
  }

  @Override
  public int hashCode() {
    return Objects.hashCode(prefix, library);
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof LibraryImport) {
      LibraryImport other = (LibraryImport) obj;
      return Objects.equal(library, other.library) && Objects.equal(prefix, other.prefix)
          && Objects.equal(showNames, other.showNames) && Objects.equal(hideNames, other.hideNames)
          && exported == other.exported;
    }
    return false;
  }

  public LibraryUnit getLibrary() {
    return library;
  }

  public String getPrefix() {
    return prefix;
  }
  
  public boolean isVisible(String name) {
    if (hideNames.contains(name)) {
      return false;
    }
    if (!showNames.isEmpty()) {
      return showNames.contains(name);
    }
    return true;
  }

  public boolean isExported() {
    return exported;
  }

  private static Set<String> createCombinatorsSet(List<ImportCombinator> combinators, boolean show) {
    Set<String> result = Sets.newHashSet();
    for (ImportCombinator combinator : combinators) {
      // show
      if (show && combinator instanceof ImportShowCombinator) {
        ImportShowCombinator showCombinator = (ImportShowCombinator) combinator;
        for (DartIdentifier showName : showCombinator.getShownNames()) {
          if (showName != null) {
            result.add(showName.getName());
          }
        }
      }
      // hide
      if (!show && combinator instanceof ImportHideCombinator) {
        ImportHideCombinator hideCombinator = (ImportHideCombinator) combinator;
        for (DartIdentifier hideName : hideCombinator.getHiddenNames()) {
          if (hideName != null) {
            result.add(hideName.getName());
          }
        }
      }
    }
    return result;
  }
}
