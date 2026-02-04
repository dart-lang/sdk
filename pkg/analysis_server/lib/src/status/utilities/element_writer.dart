// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/src/status/utilities/tree_writer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';

/// A visitor that will produce an HTML representation of an element structure.
class ElementWriter with TreeWriter {
  @override
  final StringBuffer buffer;

  /// Initialize a newly created element writer to write the HTML representation
  /// of visited elements on the given [buffer].
  ElementWriter(this.buffer);

  void write(Element element) {
    _writeElement(element);
    writeProperties(_computeProperties(element));
    _writeFragments(element);
    indentLevel++;
    try {
      for (var child in element.children) {
        write(child);
      }
    } finally {
      indentLevel--;
    }
  }

  /// Returns a representation Map of the properties of the given [element].
  Map<String, Object> _computeProperties(Element element) {
    return {
      'annotations': element.metadata.annotations,
      if (element is InterfaceElement) ...{
        'interfaces': element.interfaces,
        'isEnum': element is EnumElement,
        'mixins': element.mixins,
        'supertype': ?element.supertype,
        if (element is ClassElement) ...{
          'hasNonFinalField': element.hasNonFinalField,
          'isAbstract': element.isAbstract,
          'isMixinApplication': element.isMixinApplication,
          'isValidMixin': element.isValidMixin,
        },
      },
      'evaluationResult': ?switch (element) {
        FieldElementImpl() => element.evaluationResult,
        LocalVariableElementImpl(constantInitializer: Expression()) =>
          element.evaluationResult,
        TopLevelVariableElementImpl() => element.evaluationResult,
        _ => null,
      },
      if (element is ConstructorElement) ...{
        'isConst': element.isConst,
        'isDefaultConstructor': element.isDefaultConstructor,
        'isFactory': element.isFactory,
        'redirectedConstructor': ?element.redirectedConstructor,
      },
      if (element is ExecutableElement) ...{
        'hasImplicitReturnType': element.hasImplicitReturnType,
        'isAbstract': element.isAbstract,
        'isExternal': element.isExternal,
        if (element is MethodElement) 'isOperator': element.isOperator,
        'isStatic': element.isStatic,
        'returnType': element.returnType,
        'type': element.type,
      },
      if (element is FieldElement) 'isEnumConstant': element.isEnumConstant,
      if (element is FieldFormalParameterElement) 'field': ?element.field,
      if (element is TopLevelFunctionElement)
        'isEntryPoint': element.isEntryPoint,
      if (element is FunctionTypedElement) ...{
        'returnType': element.returnType,
        'type': element.type,
      },
      if (element is LibraryElement) ...{
        'entryPoint': ?element.entryPoint,
        'isDartAsync': element.isDartAsync,
        'isDartCore': element.isDartCore,
        'isInSdk': element.isInSdk,
      },
      if (element is FormalParameterElement) ...{
        'defaultValueCode': ?element.defaultValueCode,
        'isInitializingFormal': element.isInitializingFormal,
        if (element.isRequiredPositional)
          'parameterKind': 'required-positional'
        else if (element.isRequiredNamed)
          'parameterKind': 'required-named'
        else if (element.isOptionalPositional)
          'parameterKind': 'optional-positional'
        else if (element.isOptionalNamed)
          'parameterKind': 'optional-named'
        else
          'parameterKind': 'unknown kind',
      },
      if (element is PropertyInducingElement) 'isStatic': element.isStatic,
      if (element is TypeParameterElement) 'bound': ?element.bound,
      if (element is TypeParameterizedElement)
        'typeParameters': element.typeParameters,
      if (element is VariableElement) ...{
        'hasImplicitType': element.hasImplicitType,
        'isConst': element.isConst,
        'isFinal': element.isFinal,
        'isStatic': element.isStatic,
        'type': element.type,
      },
    };
  }

  /// Write a representation of the given [element] to the buffer.
  void _writeElement(Element element) {
    indent();

    var showItalic = switch (element) {
      ConstructorElement() => !element.isOriginDeclaration,
      PropertyAccessorElement() => !element.isOriginDeclaration,
      PropertyInducingElement() => !element.isOriginDeclaration,
      _ => false,
    };

    if (showItalic) {
      buffer.write('<i>');
    }
    buffer.write(htmlEscape.convert(element.toString()));
    if (showItalic) {
      buffer.write('</i>');
    }
    buffer.write(' <span style="color:gray">(');
    buffer.write(element.runtimeType);
    buffer.write(')</span>');
    buffer.write('<br>');
  }

  /// Write a representation of the given [fragment] to the buffer.
  void _writeFragment(Fragment fragment, int index) {
    indent();
    buffer.write('fragments[$index]: ');
    buffer.write(fragment.name);
    buffer.write(' <span style="color:gray">(');
    buffer.write(fragment.runtimeType);
    buffer.write(')</span>');
    buffer.write('<br>');
    var properties = {
      if (fragment is LibraryFragment) ...{
        'source': fragment.source,
        'imports': {
          for (var import in fragment.libraryImports)
            {
              'combinators': import.combinators,
              if (import.prefix != null) 'prefix': import.prefix?.name,
              'isDeferred': import.prefix?.isDeferred ?? false,
              'library': import.importedLibrary,
            },
          for (var export in fragment.libraryExports)
            {
              'combinators': export.combinators,
              'library': export.exportedLibrary,
            },
        },
      },
      'nameOffset': ?fragment.nameOffset,
      if (fragment is ExecutableFragment) ...{
        'isAsynchronous': fragment.isAsynchronous,
        'isGenerator': fragment.isGenerator,
        'isSynchronous': fragment.isSynchronous,
      },
    };
    writeProperties(properties);
  }

  void _writeFragments(Element element) {
    indentLevel++;
    try {
      var index = 0;
      Fragment? fragment = element.firstFragment;
      while (fragment != null) {
        _writeFragment(fragment, index++);
        fragment = fragment.nextFragment;
      }
    } finally {
      indentLevel--;
    }
  }
}
