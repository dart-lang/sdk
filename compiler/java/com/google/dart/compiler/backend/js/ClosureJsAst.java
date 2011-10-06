// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import com.google.dart.compiler.Source;
import com.google.dart.compiler.backend.js.ast.JsProgram;
import com.google.javascript.jscomp.AbstractCompiler;
import com.google.javascript.jscomp.SourceAst;
import com.google.javascript.jscomp.SourceFile;
import com.google.javascript.rhino.InputId;
import com.google.javascript.rhino.Node;

/**
 * Maps the DartC AST to a Closure Compiler input source.
 *
 * @author johnlenz@google.com (John Lenz)
 */
public class ClosureJsAst implements SourceAst {

  private static final long serialVersionUID = 1L;

  /*
   * Root node of internal JS Compiler AST which represents the same source.
   * In order to get the tree, getAstRoot() has to be called.
   */
  private Node root;
  private final JsProgram program;
  private final Source source;
  private final InputId inputId;

  private final boolean validate;

  public ClosureJsAst(JsProgram program, String inputName, Source source, boolean validate) {
    assert(inputName != null);
    this.program = program;
    this.source = source;
    this.inputId = new InputId(inputName);
    this.validate = validate;
  }

  @Override
  public void clearAst() {
    root = null;
  }

  @Override
  public Node getAstRoot(AbstractCompiler compiler) {
    if (root == null) {
      createAst(compiler);
    }
    return root;
  }

  @Override
  public InputId getInputId() {
    return inputId;
  }

  @Override
  public SourceFile getSourceFile() {
    return null;
  }

  @Override
  public void setSourceFile(SourceFile file) {
    throw new UnsupportedOperationException(
        "ClosureJsAst cannot be associated with a SourceFile instance.");
  }

  public String getSourceName() {
    return source.getName();
  }

  private void createAst(AbstractCompiler compiler) {
    root = new ClosureJsAstTranslator(validate).translate(program, inputId, source);
  }
}
