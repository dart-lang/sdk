// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library visitor;

import 'elements.dart';
import '../closure.dart'
    show BoxFieldElement,
         ClosureClassElement,
         ClosureFieldElement;

abstract class ElementVisitor<R, A> {
  const ElementVisitor();

  R visit(Element e, A arg) => e.accept(this, arg);

  R visitErroneousElement(ErroneousElement e, A arg) => null;
  R visitWarnOnUseElement(WarnOnUseElement e, A arg) => null;
  R visitAmbiguousElement(AmbiguousElement e, A arg) => null;
  R visitCompilationUnitElement(CompilationUnitElement e, A arg) => null;
  R visitLibraryElement(LibraryElement e, A arg) => null;
  R visitImportElement(ImportElement e, A arg) => null;
  R visitExportElement(ExportElement e, A arg) => null;
  R visitPrefixElement(PrefixElement e, A arg) => null;
  R visitTypedefElement(TypedefElement e, A arg) => null;
  R visitVariableElement(VariableElement e, A arg) => null;
  R visitParameterElement(ParameterElement e, A arg) => null;
  R visitFormalElement(FormalElement e, A arg) => null;
  R visitFieldElement(FieldElement e, A arg) => null;
  R visitFieldParameterElement(InitializingFormalElement e, A arg) => null;
  R visitAbstractFieldElement(AbstractFieldElement e, A arg) => null;
  R visitFunctionElement(FunctionElement e, A arg) => null;
  R visitConstructorElement(ConstructorElement e, A arg) => null;
  R visitConstructorBodyElement(ConstructorBodyElement e, A arg) => null;
  R visitClassElement(ClassElement e, A arg) => null;
  R visitMixinApplicationElement(MixinApplicationElement e, A arg) => null;
  R visitEnumClassElement(EnumClassElement e, A arg) => null;
  R visitTypeVariableElement(TypeVariableElement e, A arg) => null;
  R visitBoxFieldElement(BoxFieldElement e, A arg) => null;
  R visitClosureClassElement(ClosureClassElement e, A arg) => null;
  R visitClosureFieldElement(ClosureFieldElement e, A arg) => null;
}


abstract class BaseElementVisitor<R, A> extends ElementVisitor<R, A> {
  const BaseElementVisitor();

  R visitElement(Element e, A arg);

  @override
  R visitErroneousElement(ErroneousElement e, A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitWarnOnUseElement(WarnOnUseElement e, A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitAmbiguousElement(AmbiguousElement e, A arg) {
    return visitElement(e, arg);
  }

  R visitScopeContainerElement(ScopeContainerElement e, A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitCompilationUnitElement(CompilationUnitElement e, A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitLibraryElement(LibraryElement e, A arg) {
    return visitScopeContainerElement(e, arg);
  }

  @override
  R visitImportElement(ImportElement e, A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitExportElement(ExportElement e, A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitPrefixElement(PrefixElement e, A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitTypedefElement(TypedefElement e, A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitVariableElement(VariableElement e, A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitParameterElement(ParameterElement e, A arg) {
    return visitVariableElement(e, arg);
  }

  @override
  R visitFormalElement(FormalElement e, A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitFieldElement(FieldElement e, A arg) {
    return visitVariableElement(e, arg);
  }

  @override
  R visitFieldParameterElement(InitializingFormalElement e, A arg) {
    return visitParameterElement(e, arg);
  }

  @override
  R visitAbstractFieldElement(AbstractFieldElement e, A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitFunctionElement(FunctionElement e, A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitConstructorElement(ConstructorElement e, A arg) {
    return visitFunctionElement(e, arg);
  }

  @override
  R visitConstructorBodyElement(ConstructorBodyElement e, A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitClassElement(ClassElement e, A arg) {
    return visitScopeContainerElement(e, arg);
  }

  R visitTypeDeclarationElement(TypeDeclarationElement e, A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitMixinApplicationElement(MixinApplicationElement e, A arg) {
    return visitClassElement(e, arg);
  }

  @override
  R visitEnumClassElement(EnumClassElement e, A arg) {
    return visitClassElement(e, arg);
  }

  @override
  R visitTypeVariableElement(TypeVariableElement e, A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitBoxFieldElement(BoxFieldElement e, A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitClosureClassElement(ClosureClassElement e, A arg) {
    return visitClassElement(e, arg);
  }

  @override
  R visitClosureFieldElement(ClosureFieldElement e, A arg) {
    return visitVariableElement(e, arg);
  }
}