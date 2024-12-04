// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/src/status/tree_writer.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/element/element.dart';

/// A visitor that will produce an HTML representation of an element structure.
class ElementWriter with TreeWriter {
  @override
  final StringBuffer buffer;

  /// Initialize a newly created element writer to write the HTML representation
  /// of visited elements on the given [buffer].
  ElementWriter(this.buffer);

  void write(Element2 element) {
    _writeElement(element);
    writeProperties(_computeProperties(element));
    _writeFragments(element);
    indentLevel++;
    try {
      for (var child in element.children2) {
        write(child);
      }
    } finally {
      indentLevel--;
    }
  }

  /// Write a representation of the properties of the given [node] to the
  /// buffer.
  Map<String, Object?> _computeProperties(Element2 element) {
    var properties = <String, Object?>{};

    if (element case Annotatable element) {
      properties['annotations'] = element.metadata2.annotations;
    }
    if (element is InterfaceElement2) {
      properties['interfaces'] = element.interfaces;
      properties['isEnum'] = element is EnumElement2;
      properties['mixins'] = element.mixins;
      properties['supertype'] = element.supertype;
      if (element is ClassElement2) {
        properties['hasNonFinalField'] = element.hasNonFinalField;
        properties['isAbstract'] = element.isAbstract;
        properties['isMixinApplication'] = element.isMixinApplication;
        properties['isValidMixin'] = element.isValidMixin;
      }
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
    if (element is ConstructorElement2) {
      properties['isConst'] = element.isConst;
      properties['isDefaultConstructor'] = element.isDefaultConstructor;
      properties['isFactory'] = element.isFactory;
      properties['redirectedConstructor'] = element.redirectedConstructor2;
    }
    if (element is ExecutableElement2) {
      properties['hasImplicitReturnType'] = element.hasImplicitReturnType;
      properties['isAbstract'] = element.isAbstract;
      properties['isExternal'] = element.isExternal;
      if (element is MethodElement2) {
        properties['isOperator'] = element.isOperator;
      }
      properties['isStatic'] = element.isStatic;
      properties['returnType'] = element.returnType;
      properties['type'] = element.type;
    }
    if (element is FieldElement2) {
      properties['isEnumConstant'] = element.isEnumConstant;
    }
    if (element is FieldFormalParameterElement2) {
      properties['field'] = element.field2;
    }
    if (element is TopLevelFunctionElement) {
      properties['isEntryPoint'] = element.isEntryPoint;
    }
    if (element is FunctionTypedElement2) {
      properties['returnType'] = element.returnType;
      properties['type'] = element.type;
    }
    if (element is LibraryElement2) {
      properties['entryPoint'] = element.entryPoint2;
      properties['isDartAsync'] = element.isDartAsync;
      properties['isDartCore'] = element.isDartCore;
      properties['isInSdk'] = element.isInSdk;
    }
    if (element is FormalParameterElement) {
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
    if (element is PropertyInducingElement2) {
      properties['isStatic'] = element.isStatic;
    }
    if (element is TypeParameterElement2) {
      properties['bound'] = element.bound;
    }
    if (element is TypeParameterizedElement2) {
      properties['typeParameters'] = element.typeParameters2;
    }
    if (element is VariableElement2) {
      properties['hasImplicitType'] = element.hasImplicitType;
      properties['isConst'] = element.isConst;
      properties['isFinal'] = element.isFinal;
      properties['isStatic'] = element.isStatic;
      properties['type'] = element.type;
    }

    return properties;
  }

  /// Write a representation of the given [element] to the buffer.
  void _writeElement(Element2 element) {
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

  /// Write a representation of the given [fragment] to the buffer.
  void _writeFragment(Fragment fragment, int index) {
    indent();
    buffer.write('fragments[$index]: ');
    buffer.write(fragment.name2);
    buffer.write(' <span style="color:gray">(');
    buffer.write(fragment.runtimeType);
    buffer.write(')</span>');
    buffer.write('<br>');
    var properties = <String, Object?>{};
    if (fragment is LibraryFragment) {
      properties['source'] = fragment.source;
      properties['imports'] = {
        for (var import in fragment.libraryImports2)
          {
            // ignore: analyzer_use_new_elements
            'combinators': import.combinators,
            if (import.prefix2 != null) 'prefix': import.prefix2?.name2,
            'isDeferred': import.prefix2?.isDeferred ?? false,
            'library': import.importedLibrary2,
          },
      };
      properties['imports'] = {
        for (var export in fragment.libraryExports2)
          {
            // ignore: analyzer_use_new_elements
            'combinators': export.combinators,
            'library': export.exportedLibrary2,
          },
      };
    }
    properties['nameOffset'] = fragment.nameOffset2;
    if (fragment is ExecutableFragment) {
      properties['isAsynchronous'] = fragment.isAsynchronous;
      properties['isGenerator'] = fragment.isGenerator;
      properties['isSynchronous'] = fragment.isSynchronous;
    }
    writeProperties(properties);
  }

  void _writeFragments(Element2 element) {
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
