// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:test/test.dart';

const isClassElement = const TypeMatcher<ClassElement>();

const isCompilationUnitElement = const TypeMatcher<CompilationUnitElement>();

const isConstructorElement = const TypeMatcher<ConstructorElement>();

const isExportElement = const TypeMatcher<ExportElement>();

const isFieldElement = const TypeMatcher<FieldElement>();

const isFunctionElement = const TypeMatcher<FunctionElement>();

const isImportElement = const TypeMatcher<ImportElement>();

const isLibraryElement = const TypeMatcher<LibraryElement>();

const isMethodElement = const TypeMatcher<MethodElement>();

const isPropertyAccessorElement = const TypeMatcher<PropertyAccessorElement>();

const isPropertyInducingElement = const TypeMatcher<PropertyInducingElement>();

const isTopLevelVariableElement = const TypeMatcher<TopLevelVariableElement>();
