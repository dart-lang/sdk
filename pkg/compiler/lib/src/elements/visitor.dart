// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library visitor;

import '../closure.dart'
    show BoxFieldElement, ClosureClassElement, ClosureFieldElement;
import 'elements.dart';

abstract class ElementVisitor<R, A> {
  const ElementVisitor();

  R visit(covariant Element e, covariant A arg) => e.accept(this, arg);

  R visitErroneousElement(covariant ErroneousElement e, covariant A arg) =>
      null;
  R visitWarnOnUseElement(covariant WarnOnUseElement e, covariant A arg) =>
      null;
  R visitAmbiguousElement(covariant AmbiguousElement e, covariant A arg) =>
      null;
  R visitCompilationUnitElement(
          covariant CompilationUnitElement e, covariant A arg) =>
      null;
  R visitLibraryElement(covariant LibraryElement e, covariant A arg) => null;
  R visitImportElement(covariant ImportElement e, covariant A arg) => null;
  R visitExportElement(covariant ExportElement e, covariant A arg) => null;
  R visitPrefixElement(covariant PrefixElement e, covariant A arg) => null;
  R visitTypedefElement(covariant TypedefElement e, covariant A arg) => null;
  R visitLocalVariableElement(
          covariant LocalVariableElement e, covariant A arg) =>
      null;
  R visitParameterElement(covariant ParameterElement e, covariant A arg) =>
      null;
  R visitFormalElement(covariant FormalElement e, covariant A arg) => null;
  R visitFieldElement(covariant FieldElement e, covariant A arg) => null;
  R visitFieldParameterElement(
          covariant InitializingFormalElement e, covariant A arg) =>
      null;
  R visitAbstractFieldElement(
          covariant AbstractFieldElement e, covariant A arg) =>
      null;
  R visitMethodElement(covariant MethodElement e, covariant A arg) => null;
  R visitGetterElement(covariant GetterElement e, covariant A arg) => null;
  R visitSetterElement(covariant SetterElement e, covariant A arg) => null;
  R visitLocalFunctionElement(
          covariant LocalFunctionElement e, covariant A arg) =>
      null;
  R visitConstructorElement(covariant ConstructorElement e, covariant A arg) =>
      null;
  R visitConstructorBodyElement(
          covariant ConstructorBodyElement e, covariant A arg) =>
      null;
  R visitClassElement(covariant ClassElement e, covariant A arg) => null;
  R visitMixinApplicationElement(
          covariant MixinApplicationElement e, covariant A arg) =>
      null;
  R visitEnumClassElement(covariant EnumClassElement e, covariant A arg) =>
      null;
  R visitTypeVariableElement(
          covariant TypeVariableElement e, covariant A arg) =>
      null;
  R visitBoxFieldElement(covariant BoxFieldElement e, covariant A arg) => null;
  R visitClosureClassElement(
          covariant ClosureClassElement e, covariant A arg) =>
      null;
  R visitClosureFieldElement(
          covariant ClosureFieldElement e, covariant A arg) =>
      null;
}

abstract class BaseElementVisitor<R, A> extends ElementVisitor<R, A> {
  const BaseElementVisitor();

  R visitElement(covariant Element e, covariant A arg);

  @override
  R visitErroneousElement(covariant ErroneousElement e, covariant A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitWarnOnUseElement(covariant WarnOnUseElement e, covariant A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitAmbiguousElement(covariant AmbiguousElement e, covariant A arg) {
    return visitElement(e, arg);
  }

  R visitScopeContainerElement(
      covariant ScopeContainerElement e, covariant A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitCompilationUnitElement(
      covariant CompilationUnitElement e, covariant A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitLibraryElement(covariant LibraryElement e, covariant A arg) {
    return visitScopeContainerElement(e, arg);
  }

  @override
  R visitImportElement(covariant ImportElement e, covariant A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitExportElement(covariant ExportElement e, covariant A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitPrefixElement(covariant PrefixElement e, covariant A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitTypedefElement(covariant TypedefElement e, covariant A arg) {
    return visitElement(e, arg);
  }

  R visitVariableElement(covariant VariableElement e, covariant A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitLocalVariableElement(
      covariant LocalVariableElement e, covariant A arg) {
    return visitVariableElement(e, arg);
  }

  @override
  R visitParameterElement(covariant ParameterElement e, covariant A arg) {
    return visitVariableElement(e, arg);
  }

  @override
  R visitFormalElement(covariant FormalElement e, covariant A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitFieldElement(covariant FieldElement e, covariant A arg) {
    return visitVariableElement(e, arg);
  }

  @override
  R visitFieldParameterElement(
      covariant InitializingFormalElement e, covariant A arg) {
    return visitParameterElement(e, arg);
  }

  @override
  R visitAbstractFieldElement(
      covariant AbstractFieldElement e, covariant A arg) {
    return visitElement(e, arg);
  }

  R visitFunctionElement(covariant FunctionElement e, covariant A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitMethodElement(covariant MethodElement e, covariant A arg) {
    return visitFunctionElement(e, arg);
  }

  @override
  R visitGetterElement(covariant GetterElement e, covariant A arg) {
    return visitFunctionElement(e, arg);
  }

  @override
  R visitSetterElement(covariant SetterElement e, covariant A arg) {
    return visitFunctionElement(e, arg);
  }

  @override
  R visitLocalFunctionElement(
      covariant LocalFunctionElement e, covariant A arg) {
    return visitFunctionElement(e, arg);
  }

  @override
  R visitConstructorElement(covariant ConstructorElement e, covariant A arg) {
    return visitFunctionElement(e, arg);
  }

  @override
  R visitConstructorBodyElement(
      covariant ConstructorBodyElement e, covariant A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitClassElement(covariant ClassElement e, covariant A arg) {
    return visitScopeContainerElement(e, arg);
  }

  R visitTypeDeclarationElement(
      covariant TypeDeclarationElement e, covariant A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitMixinApplicationElement(
      covariant MixinApplicationElement e, covariant A arg) {
    return visitClassElement(e, arg);
  }

  @override
  R visitEnumClassElement(covariant EnumClassElement e, covariant A arg) {
    return visitClassElement(e, arg);
  }

  @override
  R visitTypeVariableElement(covariant TypeVariableElement e, covariant A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitBoxFieldElement(covariant BoxFieldElement e, covariant A arg) {
    return visitElement(e, arg);
  }

  @override
  R visitClosureClassElement(covariant ClosureClassElement e, covariant A arg) {
    return visitClassElement(e, arg);
  }

  @override
  R visitClosureFieldElement(covariant ClosureFieldElement e, covariant A arg) {
    return visitVariableElement(e, arg);
  }
}
