// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';

import 'package:analysis_server/src/status/tree_writer.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/src/dart/element/element.dart';

/**
 * A visitor that will produce an HTML representation of an element structure.
 */
class ElementWriter extends GeneralizingElementVisitor with TreeWriter {
  /**
   * Initialize a newly created element writer to write the HTML representation
   * of visited elements on the given [buffer].
   */
  ElementWriter(StringBuffer buffer) {
    this.buffer = buffer;
  }

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

  /**
   * Write a representation of the properties of the given [node] to the buffer.
   */
  Map<String, Object> _computeProperties(Element element) {
    Map<String, Object> properties = new HashMap<String, Object>();

    properties['metadata'] = element.metadata;
    properties['nameOffset'] = element.nameOffset;
    if (element is ClassElement) {
      properties['hasNonFinalField'] = element.hasNonFinalField;
      properties['hasReferenceToSuper'] = element.hasReferenceToSuper;
      properties['hasStaticMember'] = element.hasStaticMember;
      properties['interfaces'] = element.interfaces;
      properties['isAbstract'] = element.isAbstract;
      properties['isEnum'] = element.isEnum;
      properties['isMixinApplication'] = element.isMixinApplication;
      properties['isOrInheritsProxy'] = element.isOrInheritsProxy;
      properties['isProxy'] = element.isProxy;
      properties['isValidMixin'] = element.isValidMixin;
      properties['mixins'] = element.mixins;
      properties['supertype'] = element.supertype;
    }
    if (element is ClassMemberElement) {
      properties['isStatic'] = element.isStatic;
    }
    if (element is CompilationUnitElement) {
      properties['hasLoadLibraryFunction'] = element.hasLoadLibraryFunction;
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
      properties['returnType'] = element.returnType;
      properties['type'] = element.type;
    }
    if (element is ExportElement) {
      properties['combinators'] = element.combinators;
      properties['library'] = element.library;
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
      properties['returnType'] = element.returnType;
      properties['type'] = element.type;
    }
    if (element is ImportElement) {
      properties['combinators'] = element.combinators;
      properties['isDeferred'] = element.isDeferred;
      properties['library'] = element.library;
    }
    if (element is LibraryElement) {
      properties['definingCompilationUnit'] = element.definingCompilationUnit;
      properties['entryPoint'] = element.entryPoint;
      properties['hasExtUri'] = element.hasExtUri;
      properties['hasLoadLibraryFunction'] = element.hasLoadLibraryFunction;
      properties['isBrowserApplication'] = element.isBrowserApplication;
      properties['isDartAsync'] = element.isDartAsync;
      properties['isDartCore'] = element.isDartCore;
      properties['isInSdk'] = element.isInSdk;
    }
    if (element is LocalElement) {
      properties['visibleRange'] = element.visibleRange;
    }
    if (element is ParameterElement) {
      properties['defaultValueCode'] = element.defaultValueCode;
      properties['isInitializingFormal'] = element.isInitializingFormal;
      if (element.isNotOptional) {
        properties['parameterKind'] = 'required';
      } else if (element.isOptionalPositional) {
        properties['parameterKind'] = 'positional';
      } else if (element.isNamed) {
        properties['parameterKind'] = 'named';
      }
    }
    if (element is PropertyAccessorElement) {
      properties['isGetter'] = element.isGetter;
      properties['isSetter'] = element.isSetter;
    }
    if (element is PropertyInducingElement) {
      properties['isStatic'] = element.isStatic;
      properties['propagatedType'] = element.propagatedType;
    }
    if (element is TypeDefiningElement) {
      properties['type'] = element.type;
    }
    if (element is TypeParameterElement) {
      properties['bound'] = element.bound;
    }
    if (element is TypeParameterizedElement) {
      properties['typeParameters'] = element.typeParameters;
    }
    if (element is VariableElement) {
      properties['constantValue'] = element.constantValue;
      properties['hasImplicitType'] = element.hasImplicitType;
      properties['isConst'] = element.isConst;
      properties['isFinal'] = element.isFinal;
      properties['isStatic'] = element.isStatic;
      properties['type'] = element.type;
    }

    return properties;
  }

  /**
   * Write a representation of the given [node] to the buffer.
   */
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
