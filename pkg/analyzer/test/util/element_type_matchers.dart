// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:test/test.dart';

const isClassElement = TypeMatcher<ClassElement>();

const isClassElement2 = TypeMatcher<ClassElement2>();

const isCompilationUnitElement = TypeMatcher<CompilationUnitElement>();

const isConstructorElement = TypeMatcher<ConstructorElement>();

const isConstructorElement2 = TypeMatcher<ConstructorElement2>();

const isElementAnnotation = TypeMatcher<ElementAnnotation>();

const isExecutableElement = TypeMatcher<ExecutableElement>();

const isExportElement = TypeMatcher<LibraryExportElement>();

const isFieldElement = TypeMatcher<FieldElement>();

const isFieldElement2 = TypeMatcher<FieldElement2>();

const isFieldFormalParameterElement =
    TypeMatcher<FieldFormalParameterElement>();

const isFunctionElement = TypeMatcher<FunctionElement>();

const isFunctionTypedElement = TypeMatcher<FunctionTypedElement>();

const isGenericFunctionTypeElement = TypeMatcher<GenericFunctionTypeElement>();

const isGetterElement = TypeMatcher<GetterElement>();

const isHideElementCombinator = TypeMatcher<HideElementCombinator>();

const isImportElement = TypeMatcher<LibraryImportElement>();

const isLabelElement = TypeMatcher<LabelElement>();

const isLibraryElement = TypeMatcher<LibraryElement>();

const isLibraryElement2 = TypeMatcher<LibraryElement2>();

const isLocalElement = TypeMatcher<LocalElement>();

const isLocalFunctionElement = TypeMatcher<LocalFunctionElement>();

const isLocalVariableElement = TypeMatcher<LocalVariableElement>();

const isLocalVariableElement2 = TypeMatcher<LocalVariableElement2>();

const isMethodElement = TypeMatcher<MethodElement>();

const isMethodElement2 = TypeMatcher<MethodElement2>();

const isNamespaceCombinator = TypeMatcher<NamespaceCombinator>();

const isParameterElement = TypeMatcher<ParameterElement>();

const isPrefixElement = TypeMatcher<PrefixElement>();

const isPrefixElement2 = TypeMatcher<PrefixElement2>();

const isPropertyAccessorElement = TypeMatcher<PropertyAccessorElement>();

const isPropertyInducingElement = TypeMatcher<PropertyInducingElement>();

const isShowElementCombinator = TypeMatcher<ShowElementCombinator>();

const isTopLevelFunctionElement = TypeMatcher<TopLevelFunctionElement>();

const isTopLevelVariableElement = TypeMatcher<TopLevelVariableElement>();

const isTopLevelVariableElement2 = TypeMatcher<TopLevelVariableElement2>();

const isTypeDefiningElement = TypeMatcher<TypeDefiningElement>();

const isTypeParameterElement = TypeMatcher<TypeParameterElement>();

const isTypeParameterizedElement = TypeMatcher<TypeParameterizedElement>();

const isUriReferencedElement = TypeMatcher<UriReferencedElement>();

const isVariableElement = TypeMatcher<VariableElement>();
