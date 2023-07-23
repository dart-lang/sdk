// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/src/status/tree_writer.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/src/dart/element/element.dart';

/// A visitor that will produce an HTML representation of an element structure.
class ElementWriter extends GeneralizingElementVisitor<void> with TreeWriter {
  @override
  final StringBuffer buffer;

  /// Initialize a newly created element writer to write the HTML representation
  /// of visited elements on the given [buffer].
  ElementWriter(this.buffer);

  @override
  void visitElement(Element element) {
    _writeElement(element);
    writeProperties(_computeProperties(element));
    indentLevel++;
    try {
      element.visitChildren(this);
    } finally {
      indentLevel--;
    }
  }

  /// Write a representation of the properties of the given [node] to the
  /// buffer.
  Map<String, Object?> _computeProperties(Element element) {
    var properties = <String, Object?>{};

    properties['metadata'] = element.metadata;
    properties['nameOffset'] = element.nameOffset;
    if (element is InterfaceElement) {
      properties['interfaces'] = element.interfaces;
      properties['isEnum'] = element is EnumElement;
      properties['mixins'] = element.mixins;
      properties['supertype'] = element.supertype;
      if (element is ClassElement) {
        properties['hasNonFinalField'] = element.hasNonFinalField;
        properties['isAbstract'] = element.isAbstract;
        properties['isMixinApplication'] = element.isMixinApplication;
        properties['isValidMixin'] = element.isValidMixin;
      }
    }
    if (element is ClassMemberElement) {
      properties['isStatic'] = element.isStatic;
    }
    if (element is CompilationUnitElement) {
      properties['source'] = element.source;
    }
    if (element is ConstFieldElementImpl) {
      properties['evaluationResult'] = element.evaluationResult;
    }
    if (element is ConstLocalVariableElementImpl) {
      properties['evaluationResult'] = element.evaluationResult;
    }
    if (element is ConstTopLevelVariableElementImpl) {
      properties['evaluationResult'] = element.evaluationResult;
    }
    if (element is ConstructorElement) {
      properties['isConst'] = element.isConst;
      properties['isDefaultConstructor'] = element.isDefaultConstructor;
      properties['isFactory'] = element.isFactory;
      properties['redirectedConstructor'] = element.redirectedConstructor;
    }
    if (element is ExecutableElement) {
      properties['hasImplicitReturnType'] = element.hasImplicitReturnType;
      properties['isAbstract'] = element.isAbstract;
      properties['isAsynchronous'] = element.isAsynchronous;
      properties['isExternal'] = element.isExternal;
      properties['isGenerator'] = element.isGenerator;
      properties['isOperator'] = element.isOperator;
      properties['isStatic'] = element.isStatic;
      properties['isSynchronous'] = element.isSynchronous;
      properties['returnType'] = element.returnType2;
      properties['type'] = element.type;
    }
    if (element is LibraryExportElement) {
      properties['combinators'] = element.combinators;
      properties['library'] = element.exportedLibrary;
    }
    if (element is FieldElement) {
      properties['isEnumConstant'] = element.isEnumConstant;
    }
    if (element is FieldFormalParameterElement) {
      properties['field'] = element.field;
    }
    if (element is FunctionElement) {
      properties['isEntryPoint'] = element.isEntryPoint;
    }
    if (element is FunctionTypedElement) {
      properties['returnType'] = element.returnType2;
      properties['type'] = element.type;
    }
    if (element is LibraryImportElement) {
      properties['combinators'] = element.combinators;
      properties['isDeferred'] = element.prefix is DeferredImportElementPrefix;
      properties['library'] = element.importedLibrary;
    }
    if (element is LibraryElement) {
      properties['definingCompilationUnit'] = element.definingCompilationUnit;
      properties['entryPoint'] = element.entryPoint;
      properties['isBrowserApplication'] = element.isBrowserApplication;
      properties['isDartAsync'] = element.isDartAsync;
      properties['isDartCore'] = element.isDartCore;
      properties['isInSdk'] = element.isInSdk;
    }
    if (element is ParameterElement) {
      properties['defaultValueCode'] = element.defaultValueCode;
      properties['isInitializingFormal'] = element.isInitializingFormal;
      if (element.isRequiredPositional) {
        properties['parameterKind'] = 'required-positional';
      } else if (element.isRequiredNamed) {
        properties['parameterKind'] = 'required-named';
      } else if (element.isOptionalPositional) {
        properties['parameterKind'] = 'optional-positional';
      } else if (element.isOptionalNamed) {
        properties['parameterKind'] = 'optional-named';
      } else {
        properties['parameterKind'] = 'unknown kind';
      }
    }
    if (element is PropertyAccessorElement) {
      properties['isGetter'] = element.isGetter;
      properties['isSetter'] = element.isSetter;
    }
    if (element is PropertyInducingElement) {
      properties['isStatic'] = element.isStatic;
    }
    if (element is TypeParameterElement) {
      properties['bound'] = element.bound;
    }
    if (element is TypeParameterizedElement) {
      properties['typeParameters'] = element.typeParameters;
    }
    if (element is VariableElement) {
      properties['hasImplicitType'] = element.hasImplicitType;
      properties['isConst'] = element.isConst;
      properties['isFinal'] = element.isFinal;
      properties['isStatic'] = element.isStatic;
      properties['type'] = element.type;
    }

    return properties;
  }

  /// Write a representation of the given [node] to the buffer.
  void _writeElement(Element element) {
    indent();
    if (element.isSynthetic) {
      buffer.write('<i>');
    }
    buffer.write(htmlEscape.convert(element.toString()));
    if (element.isSynthetic) {
      buffer.write('</i>');
    }
    buffer.write(' <span style="color:gray">(');
    buffer.write(element.runtimeType);
    buffer.write(')</span>');
    buffer.write('<br>');
  }
}
