// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ast.DartFunctionTypeAlias;
import com.google.dart.compiler.type.FunctionAliasType;
import com.google.dart.compiler.type.FunctionType;
import com.google.dart.compiler.type.InterfaceType;

// Could be a direct subclass of AbstractElement.
public class FunctionAliasElementImplementation extends ClassElementImplementation
    implements FunctionAliasElement {

  private FunctionType functionType;
  private final DartFunctionTypeAlias node;

  FunctionAliasElementImplementation(DartFunctionTypeAlias node, String name, LibraryElement library) {
    super(null, name, null, library);
    this.node = node;
  }

  @Override
  public DartFunctionTypeAlias getNode() {
    return node;
  }

  @Override
  public ElementKind getKind() {
    return ElementKind.FUNCTION_TYPE_ALIAS;
  }

  @Override
  public FunctionAliasType getType() {
    return (FunctionAliasType) super.getType();
  }

  @Override
  public FunctionType getFunctionType() {
    return functionType;
  }

  @Override
  public void setType(InterfaceType type) {
    FunctionAliasType ftype = (FunctionAliasType) type;
    super.setType(ftype);
  }

  @Override
  public void setFunctionType(FunctionType functionType) {
    this.functionType = functionType;
  }

  public static FunctionAliasElement fromNode(DartFunctionTypeAlias node,
                                              LibraryElement library) {
    return new FunctionAliasElementImplementation(
        node, node.getName().getTargetName(), library);
  }
}
