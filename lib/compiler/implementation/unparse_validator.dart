// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Checks result's of [Node] unparse.
 */
class UnparseValidator extends CompilerTask {
  final bool validateUnparse;

  UnparseValidator(Compiler compiler, this.validateUnparse) : super(compiler);

  void check(Element element) {
    if (!validateUnparse) return;

    // TODO(antonm): consider supporting other kinds of elements.
    if (element is! PartialFunctionElement) return;

    PartialFunctionElement originalFunction = element;
    FunctionExpression originalNode = originalFunction.parseNode(compiler);
    String unparsed = originalNode.unparse(false);

    Token newTokens = new StringScanner(unparsed).tokenize();

    // Find the getOrSet token.
    // TODO(ahe): This is to frigging complicated. Simplify it.
    Parser parser = new Parser(new Listener());
    Token getOrSet =
        parser.findGetOrSet(parser.parseModifiers(newTokens));

    // TODO(ahe): This is also too frigging complicated.
    Script originalScript = element.getCompilationUnit().script;
    SourceFile synthesizedSourceFile =
        new SourceFile(originalScript.name, unparsed);
    Script synthesizedScript =
        new Script(originalScript.uri, synthesizedSourceFile);
    LibraryElement lib = new LibraryElement(synthesizedScript);
    NodeListener listener = new NodeListener(compiler, lib);
    parser = new Parser(listener);
    // TODO(antonm): better error reporting.
    compiler.withCurrentElement(lib, () {
      parser.parseFunction(newTokens, getOrSet);
    });
    FunctionExpression newNode = listener.popNode();
    // TODO(antonm): add Node comparison.
  }
}
