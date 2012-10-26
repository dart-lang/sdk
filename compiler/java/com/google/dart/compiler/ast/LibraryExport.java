// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.common.collect.Sets;

import java.util.List;
import java.util.Set;

/**
 * Information about export - {@link LibraryUnit} and show/hide names.
 */
public class LibraryExport {
  private final LibraryUnit library;
  private final Set<String> showNames;
  private final Set<String> hideNames;

  public LibraryExport(LibraryUnit library, List<ImportCombinator> combinators) {
    this.library = library;
    this.showNames = createCombinatorsSet(combinators, true);
    this.hideNames = createCombinatorsSet(combinators, false);
  }

  public LibraryUnit getLibrary() {
    return library;
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
