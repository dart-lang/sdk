// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ast.LibraryUnit;

import java.util.List;

public interface LibraryElement extends EnclosingElement {
  Scope getImportScope();

  Scope getScope();
  
  List<Element> getExportedElements();

  LibraryUnit getLibraryUnit();

  void setEntryPoint(MethodElement element);

  MethodElement getEntryPoint();
}
