// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ValidatorListener implements DiagnosticListener {
  final SourceFile sourceFile;

  ValidatorListener(this.sourceFile);

  void cancel([String reason, node, token, instruction, element]) {
    assert(token !== null);
    SourceSpan.withOffsets(token, token, (beginOffset, endOffset) {
        String errorMessage =
            sourceFile.getLocationMessage(reason, beginOffset, endOffset, true);
        print(errorMessage);
    });
    throw new CompilerCancelledException(reason);
  }

  void log(message) {}
}

/**
 * Checks result's of [Node] unparse.
 */
class UnparseValidator extends CompilerTask {
  final bool validateUnparse;

  String get name() => "Unparse validator";

  UnparseValidator(Compiler compiler, this.validateUnparse) : super(compiler);

  void check(Element element) {
    if (!validateUnparse) return;

    // TODO(antonm): consider supporting other kinds of elements.
    if (element is! PartialFunctionElement) return;

    PartialFunctionElement originalFunction = element;
    FunctionExpression originalNode = originalFunction.parseNode(compiler);
    String unparsed = originalNode.unparse();

    Token newTokens = new StringScanner(unparsed).tokenize();

    // Find the getOrSet token.
    // TODO(ahe): This is to frigging complicated. Simplify it.
    Parser parser = new Parser(new Listener());
    Token getOrSet =
        parser.findGetOrSet(parser.parseModifiers(newTokens));

    // TODO(ahe): This is also too frigging complicated.
    Script originalScript = element.getCompilationUnit().script;
    String name = SourceSpan.withOffsets(
        originalFunction.beginToken, originalFunction.endToken,
        (beginOffset, endOffset) =>
            'synthesized:${originalScript.name}#$beginOffset:$endOffset');
    SourceFile synthesizedSourceFile = new SourceFile(name, unparsed);
    Script synthesizedScript =
        new Script(originalScript.uri, synthesizedSourceFile);
    LibraryElement lib = new LibraryElement(synthesizedScript);
    NodeListener listener =
        new NodeListener(new ValidatorListener(synthesizedSourceFile), lib);
    parser = new Parser(listener);
    parser.parseFunction(newTokens, getOrSet);
    FunctionExpression newNode = listener.popNode();
    // TODO(antonm): add Node comparison.
  }
}
