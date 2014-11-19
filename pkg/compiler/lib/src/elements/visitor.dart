// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library visitor;

import 'elements.dart';
import '../closure.dart'
    show BoxFieldElement,
         ClosureClassElement,
         ClosureFieldElement;

abstract class ElementVisitor<R> {
  R visit(Element e) => e.accept(this);

  R visitElement(Element e);
  R visitErroneousElement(ErroneousElement e) => visitFunctionElement(e);
  R visitWarnOnUseElement(WarnOnUseElement e) => visitElement(e);
  R visitAmbiguousElement(AmbiguousElement e) => visitElement(e);
  R visitScopeContainerElement(ScopeContainerElement e) => visitElement(e);
  R visitCompilationUnitElement(CompilationUnitElement e) => visitElement(e);
  R visitLibraryElement(LibraryElement e) => visitScopeContainerElement(e);
  R visitPrefixElement(PrefixElement e) => visitElement(e);
  R visitTypedefElement(TypedefElement e) => visitElement(e);
  R visitVariableElement(VariableElement e) => visitElement(e);
  R visitParameterElement(ParameterElement e) => visitVariableElement(e);
  R visitFormalElement(FormalElement e) => visitElement(e);
  R visitFieldElement(FieldElement e) => visitVariableElement(e);
  R visitFieldParameterElement(InitializingFormalElement e) =>
      visitParameterElement(e);
  R visitAbstractFieldElement(AbstractFieldElement e) => visitElement(e);
  R visitFunctionElement(FunctionElement e) => visitElement(e);
  R visitConstructorBodyElement(ConstructorBodyElement e) => visitElement(e);
  R visitClassElement(ClassElement e) => visitScopeContainerElement(e);
  R visitTypeDeclarationElement(TypeDeclarationElement e) => visitElement(e);
  R visitMixinApplicationElement(MixinApplicationElement e) {
    return visitClassElement(e);
  }
  R visitEnumClassElement(EnumClassElement e) => visitClassElement(e);
  R visitTypeVariableElement(TypeVariableElement e) => visitElement(e);
  R visitBoxFieldElement(BoxFieldElement e) => visitElement(e);
  R visitClosureClassElement(ClosureClassElement e) => visitClassElement(e);
  R visitClosureFieldElement(ClosureFieldElement e) => visitVariableElement(e);
}