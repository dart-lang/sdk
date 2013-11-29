// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library visitor;

import 'elements.dart';
import 'modelx.dart';
import '../scanner/scannerlib.dart'
    show PartialClassElement;
import '../ssa/ssa.dart'
    show InterceptedElement;
import '../closure.dart'
    show ThisElement,
         CheckVariableElement,
         BoxElement,
         BoxFieldElement,
         ClosureClassElement,
         ClosureFieldElement;

abstract class ElementVisitor<R> {
  R visit(Element e) => e.accept(this);

  R visitElement(Element e);
  R visitElementX(ElementX e) => visitElement(e);
  R visitErroneousElement(ErroneousElement e) => visitFunctionElement(e);
  R visitWarnOnUseElement(WarnOnUseElement e) => visitElement(e);
  R visitAmbiguousElement(AmbiguousElement e) => visitElement(e);
  R visitScopeContainerElement(ScopeContainerElement e) => visitElement(e);
  R visitCompilationUnitElement(CompilationUnitElement e) => visitElement(e);
  R visitLibraryElement(LibraryElement e) => visitScopeContainerElement(e);
  R visitPrefixElement(PrefixElement e) => visitElement(e);
  R visitTypedefElement(TypedefElement e) => visitElement(e);
  R visitVariableElement(VariableElement e) => visitElement(e);
  R visitFieldParameterElement(FieldParameterElement e) => visitElement(e);
  R visitVariableListElement(VariableListElement e) => visitElement(e);
  R visitAbstractFieldElement(AbstractFieldElement e) => visitElement(e);
  R visitFunctionElement(FunctionElement e) => visitElement(e);
  R visitConstructorBodyElement(ConstructorBodyElement e) => visitElement(e);
  R visitClassElement(ClassElement e) => visitScopeContainerElement(e);
  R visitTypeDeclarationElement(TypeDeclarationElement e) => visitElement(e);
  R visitBaseClassElementX(BaseClassElementX e) => visitClassElement(e);
  R visitClassElementX(ClassElementX e) => visitBaseClassElementX(e);
  R visitMixinApplicationElement(MixinApplicationElement e) {
    visitClassElement(e);
  }
  R visitLabelElement(LabelElement e) => visitElement(e);
  R visitTargetElement(TargetElement e) => visitElement(e);
  R visitTypeVariableElement(TypeVariableElement e) => visitElement(e);
  R visitErroneousElementX(ErroneousElementX e) => visitErroneousElement(e);
  R visitWarnOnUseElementX(WarnOnUseElementX e) => visitWarnOnUseElement(e);
  R visitAmbiguousElementX(AmbiguousElementX e) => visitAmbiguousElement(e);
  R visitLibraryElementX(LibraryElementX e) => visitLibraryElement(e);
  R visitPrefixElementX(PrefixElementX e) => visitPrefixElement(e);
  R visitTypedefElementX(TypedefElementX e) => visitTypedefElement(e);
  R visitVariableElementX(VariableElementX e) => visitVariableElement(e);
  R visitFieldParameterElementX(FieldParameterElementX e) {
    return visitFieldParameterElement(e);
  }
  R visitVariableListElementX(VariableListElementX e) {
    return visitVariableListElement(e);
  }
  R visitAbstractFieldElementX(AbstractFieldElementX e) {
    return visitAbstractFieldElement(e);
  }
  R visitFunctionElementX(FunctionElementX e) => visitFunctionElement(e);
  R visitConstructorBodyElementX(ConstructorBodyElementX e) {
    return visitFunctionElementX(e);
  }
  R visitSynthesizedConstructorElementX(SynthesizedConstructorElementX e) {
    return visitFunctionElementX(e);
  }
  R visitVoidElementX(VoidElementX e) => visitElementX(e);
  R visitLabelElementX(LabelElementX e) => visitLabelElement(e);
  R visitTargetElementX(TargetElementX e) => visitTargetElement(e);
  R visitTypeVariableElementX(TypeVariableElementX e) {
    visitTypeVariableElement(e);
  }
  R visitPartialClassElement(PartialClassElement e) {
    return visitClassElementX(e);
  }
  R visitInterceptedElement(InterceptedElement e) => visitElementX(e);
  R visitThisElement(ThisElement e) => visitElementX(e);
  R visitCheckVariableElement(CheckVariableElement e ) => visitElementX(e);
  R visitBoxElement(BoxElement e) => visitElementX(e);
  R visitBoxFieldElement(BoxFieldElement e) => visitElementX(e);
  R visitClosureClassElement(ClosureClassElement e) => visitClassElementX(e);
  R visitClosureFieldElement(ClosureFieldElement e) => visitVariableElement(e);
}