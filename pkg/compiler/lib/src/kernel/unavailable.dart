// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import "../tree/tree.dart"
    show
        AsyncModifier,
        ClassNode,
        Combinator,
        Export,
        Expression,
        GotoStatement,
        Import,
        LibraryDependency,
        LibraryName,
        LibraryTag,
        Literal,
        Loop,
        MixinApplication,
        Modifiers,
        NamedMixinApplication,
        Node,
        NodeList,
        Part,
        PartOf,
        Postfix,
        Prefix,
        Statement,
        StringInterpolationPart,
        StringNode,
        Typedef;

abstract class UnavailableVisitor {
  void visitNode(Node node) {
    throw "No RAST available for Node";
  }

  void visitAsyncModifier(AsyncModifier node) {
    throw "No RAST available for AsyncModifier";
  }

  void visitClassNode(ClassNode node) {
    throw "No RAST available for ClassNode";
  }

  void visitCombinator(Combinator node) {
    throw "No RAST available for Combinator";
  }

  void visitExport(Export node) {
    throw "No RAST available for Export";
  }

  void visitExpression(Expression node) {
    throw "No RAST available for Expression";
  }

  void visitGotoStatement(GotoStatement node) {
    throw "No RAST available for GotoStatement";
  }

  void visitImport(Import node) {
    throw "No RAST available for Import";
  }

  void visitLibraryDependency(LibraryDependency node) {
    throw "No RAST available for LibraryDependency";
  }

  void visitLibraryName(LibraryName node) {
    throw "No RAST available for LibraryName";
  }

  void visitLibraryTag(LibraryTag node) {
    throw "No RAST available for LibraryTag";
  }

  void visitLiteral(Literal node) {
    throw "No RAST available for Literal";
  }

  void visitLoop(Loop node) {
    throw "No RAST available for Loop";
  }

  void visitMixinApplication(MixinApplication node) {
    throw "No RAST available for MixinApplication";
  }

  void visitModifiers(Modifiers node) {
    throw "No RAST available for Modifiers";
  }

  void visitNamedMixinApplication(NamedMixinApplication node) {
    throw "No RAST available for NamedMixinApplication";
  }

  void visitNodeList(NodeList node) {
    throw "No RAST available for NodeList";
  }

  void visitPart(Part node) {
    throw "No RAST available for Part";
  }

  void visitPartOf(PartOf node) {
    throw "No RAST available for PartOf";
  }

  void visitPostfix(Postfix node) {
    throw "No RAST available for Postfix";
  }

  void visitPrefix(Prefix node) {
    throw "No RAST available for Prefix";
  }

  void visitStatement(Statement node) {
    throw "No RAST available for Statement";
  }

  void visitStringNode(StringNode node) {
    throw "No RAST available for StringNode";
  }

  void visitStringInterpolationPart(StringInterpolationPart node) {
    throw "No RAST available for StringInterpolationPart";
  }

  void visitTypedef(Typedef node) {
    throw "No RAST available for Typedef";
  }
}
