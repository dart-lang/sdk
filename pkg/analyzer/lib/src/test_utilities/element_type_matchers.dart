// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:test/test.dart';

const isClassElement = const TypeMatcher<ClassElement>();

const isClassMemberElement = const TypeMatcher<ClassMemberElement>();

const isCompilationUnitElement = const TypeMatcher<CompilationUnitElement>();

const isConstructorElement = const TypeMatcher<ConstructorElement>();

const isElementAnnotation = const TypeMatcher<ElementAnnotation>();

const isExecutableElement = const TypeMatcher<ExecutableElement>();

const isExportElement = const TypeMatcher<ExportElement>();

const isFieldElement = const TypeMatcher<FieldElement>();

const isFieldFormalParameterElement =
    const TypeMatcher<FieldFormalParameterElement>();

const isFunctionElement = const TypeMatcher<FunctionElement>();

const isFunctionTypeAliasElement =
    const TypeMatcher<FunctionTypeAliasElement>();

const isFunctionTypedElement = const TypeMatcher<FunctionTypedElement>();

const isGenericFunctionTypeElement =
    const TypeMatcher<GenericFunctionTypeElement>();

const isGenericTypeAliasElement = const TypeMatcher<GenericTypeAliasElement>();

const isHideElementCombinator = const TypeMatcher<HideElementCombinator>();

const isImportElement = const TypeMatcher<ImportElement>();

const isLabelElement = const TypeMatcher<LabelElement>();

const isLibraryElement = const TypeMatcher<LibraryElement>();

const isLocalElement = const TypeMatcher<LocalElement>();

const isLocalVariableElement = const TypeMatcher<LocalVariableElement>();

const isMethodElement = const TypeMatcher<MethodElement>();

const isNamespaceCombinator = const TypeMatcher<NamespaceCombinator>();

const isParameterElement = const TypeMatcher<ParameterElement>();

const isPrefixElement = const TypeMatcher<PrefixElement>();

const isPropertyAccessorElement = const TypeMatcher<PropertyAccessorElement>();

const isPropertyInducingElement = const TypeMatcher<PropertyInducingElement>();

const isShowElementCombinator = const TypeMatcher<ShowElementCombinator>();

const isTopLevelVariableElement = const TypeMatcher<TopLevelVariableElement>();

const isTypeDefiningElement = const TypeMatcher<TypeDefiningElement>();

const isTypeParameterElement = const TypeMatcher<TypeParameterElement>();

const isTypeParameterizedElement =
    const TypeMatcher<TypeParameterizedElement>();

const isUriReferencedElement = const TypeMatcher<UriReferencedElement>();

const isVariableElement = const TypeMatcher<VariableElement>();
