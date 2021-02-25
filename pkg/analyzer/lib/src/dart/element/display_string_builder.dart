// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:analyzer/src/generated/element_type_provider.dart';
import 'package:meta/meta.dart';

class ElementDisplayStringBuilder {
  final StringBuffer _buffer = StringBuffer();

  final bool skipAllDynamicArguments;
  final bool withNullability;

  ElementDisplayStringBuilder({
    @required this.skipAllDynamicArguments,
    @required this.withNullability,
  });

  @override
  String toString() {
    return _buffer.toString();
  }

  void writeAbstractElement(ElementImpl element) {
    if (element.name != null) {
      _write(element.name);
    } else {
      _write('<unnamed $runtimeType>');
    }
  }

  void writeClassElement(ClassElementImpl element) {
    if (element.isAbstract) {
      _write('abstract ');
    }

    _write('class ');
    _write(element.displayName);

    _writeTypeParameters(element.typeParameters);

    _writeTypeIfNotObject(' extends ', element.supertype);
    _writeTypesIfNotEmpty(' with ', element.mixins);
    _writeTypesIfNotEmpty(' implements ', element.interfaces);
  }

  void writeCompilationUnitElement(CompilationUnitElementImpl element) {
    var path = element.source?.fullName;
    _write(path ?? '{compilation unit}');
  }

  void writeConstructorElement(ConstructorElement element) {
    _writeType(element.returnType);
    _write(' ');

    _write(element.enclosingElement.displayName);
    if (element.displayName.isNotEmpty) {
      _write('.');
      _write(element.displayName);
    }

    _writeFormalParameters(element.parameters, forElement: true);
  }

  void writeDynamicType() {
    _write('dynamic');
  }

  void writeEnumElement(EnumElementImpl element) {
    _write('enum ');
    _write(element.displayName);
  }

  void writeExecutableElement(ExecutableElement element, String name) {
    _writeType(element.returnType);
    _write(' ');

    _write(name);

    if (element.kind != ElementKind.GETTER) {
      _writeTypeParameters(element.typeParameters);
      _writeFormalParameters(element.parameters, forElement: true);
    }
  }

  void writeExportElement(ExportElementImpl element) {
    _write('export ');
    (element.exportedLibrary as LibraryElementImpl).appendTo(this);
  }

  void writeExtensionElement(ExtensionElementImpl element) {
    _write('extension ');
    _write(element.displayName ?? '(unnamed)');
    _writeTypeParameters(element.typeParameters);
    _writeTypeIfNotNull(' on ', element.extendedType);
  }

  void writeFormalParameter(ParameterElement element) {
    if (element.isRequiredPositional) {
      _writeWithoutDelimiters(element, forElement: true);
    } else if (element.isOptionalPositional) {
      _write('[');
      _writeWithoutDelimiters(element, forElement: true);
      _write(']');
    } else if (element.isNamed) {
      _write('{');
      _writeWithoutDelimiters(element, forElement: true);
      _write('}');
    }
  }

  void writeFunctionType(FunctionType type) {
    type = _uniqueTypeParameters(type);

    _writeType(type.returnType);
    _write(' Function');
    _writeTypeParameters(type.typeFormals);
    _writeFormalParameters(type.parameters, forElement: false);
    _writeNullability(type.nullabilitySuffix);
  }

  void writeGenericFunctionTypeElement(GenericFunctionTypeElementImpl element) {
    _writeType(element.returnType);
    _write(' Function');
    _writeTypeParameters(element.typeParameters);
    _writeFormalParameters(element.parameters, forElement: true);
  }

  void writeImportElement(ImportElementImpl element) {
    _write('import ');
    (element.importedLibrary as LibraryElementImpl).appendTo(this);
  }

  void writeInterfaceType(InterfaceType type) {
    _write(type.element.name);
    _writeTypeArguments(type.typeArguments);
    _writeNullability(type.nullabilitySuffix);
  }

  void writeMixinElement(MixinElementImpl element) {
    _write('mixin ');
    _write(element.displayName);
    _writeTypeParameters(element.typeParameters);
    _writeTypesIfNotEmpty(' on ', element.superclassConstraints);
    _writeTypesIfNotEmpty(' implements ', element.interfaces);
  }

  void writeNeverType(NeverTypeImpl type) {
    _write('Never');
    _writeNullability(type.nullabilitySuffix);
  }

  void writePrefixElement(PrefixElementImpl element) {
    _write('as ');
    _write(element.displayName);
  }

  void writeTypeAliasElement(TypeAliasElementImpl element) {
    _write('typedef ');
    _write(element.displayName);
    _writeTypeParameters(element.typeParameters);
    _write(' = ');

    var aliasedElement = element.aliasedElement;
    if (aliasedElement != null) {
      aliasedElement.appendTo(this);
    } else {
      _writeType(element.aliasedType);
    }
  }

  void writeTypeParameter(TypeParameterElement element) {
    if (element is TypeParameterElementImpl) {
      var variance = element.variance;
      if (!element.isLegacyCovariant && variance != Variance.unrelated) {
        _write(variance.toKeywordString());
        _write(' ');
      }
    }

    _write(element.displayName);

    if (element.bound != null) {
      _write(' extends ');
      _writeType(element.bound);
    }
  }

  void writeTypeParameterType(TypeParameterTypeImpl type) {
    _write(type.element.displayName);
    _writeNullability(type.nullabilitySuffix);

    if (type.promotedBound != null) {
      _write(' & ');
      _writeType(type.promotedBound);
    }
  }

  void writeUnknownInferredType() {
    _write('_');
  }

  void writeVariableElement(VariableElement element) {
    _writeType(element.type);
    _write(' ');
    _write(element.displayName);
  }

  void writeVoidType() {
    _write('void');
  }

  void _write(String str) {
    _buffer.write(str);
  }

  void _writeFormalParameters(
    List<ParameterElement> parameters, {
    @required bool forElement,
  }) {
    _write('(');

    var lastKind = _WriteFormalParameterKind.requiredPositional;
    var lastClose = '';

    void openGroup(_WriteFormalParameterKind kind, String open, String close) {
      if (lastKind != kind) {
        _write(lastClose);
        _write(open);
        lastKind = kind;
        lastClose = close;
      }
    }

    for (var i = 0; i < parameters.length; i++) {
      if (i != 0) {
        _write(', ');
      }

      var parameter = parameters[i];
      if (parameter.isRequiredPositional) {
        openGroup(_WriteFormalParameterKind.requiredPositional, '', '');
      } else if (parameter.isOptionalPositional) {
        openGroup(_WriteFormalParameterKind.optionalPositional, '[', ']');
      } else if (parameter.isNamed) {
        openGroup(_WriteFormalParameterKind.named, '{', '}');
      }
      _writeWithoutDelimiters(parameter, forElement: forElement);
    }

    _write(lastClose);
    _write(')');
  }

  void _writeNullability(NullabilitySuffix nullabilitySuffix) {
    if (withNullability) {
      switch (nullabilitySuffix) {
        case NullabilitySuffix.question:
          _write('?');
          break;
        case NullabilitySuffix.star:
          _write('*');
          break;
        case NullabilitySuffix.none:
          break;
      }
    }
  }

  void _writeType(DartType type) {
    (type as TypeImpl).appendTo(this);
  }

  void _writeTypeArguments(List<DartType> typeArguments) {
    if (typeArguments.isEmpty) {
      return;
    }

    if (skipAllDynamicArguments) {
      if (typeArguments.every((t) => t.isDynamic)) {
        return;
      }
    }

    _write('<');
    for (var i = 0; i < typeArguments.length; i++) {
      if (i != 0) {
        _write(', ');
      }
      (typeArguments[i] as TypeImpl).appendTo(this);
    }
    _write('>');
  }

  void _writeTypeIfNotNull(String prefix, DartType type) {
    if (type != null) {
      _write(prefix);
      _writeType(type);
    }
  }

  void _writeTypeIfNotObject(String prefix, DartType type) {
    if (type != null && !type.isDartCoreObject) {
      _write(prefix);
      _writeType(type);
    }
  }

  void _writeTypeParameters(List<TypeParameterElement> elements) {
    if (elements.isEmpty) return;

    _write('<');
    for (var i = 0; i < elements.length; i++) {
      if (i != 0) {
        _write(', ');
      }
      (elements[i] as TypeParameterElementImpl).appendTo(this);
    }
    _write('>');
  }

  void _writeTypes(List<DartType> types) {
    for (var i = 0; i < types.length; i++) {
      if (i != 0) {
        _write(', ');
      }
      _writeType(types[i]);
    }
  }

  void _writeTypesIfNotEmpty(String prefix, List<DartType> types) {
    if (types.isNotEmpty) {
      _write(prefix);
      _writeTypes(types);
    }
  }

  void _writeWithoutDelimiters(
    ParameterElement element, {
    @required bool forElement,
  }) {
    if (element.isRequiredNamed) {
      _write('required ');
    }

    _writeType(element.type);

    if (forElement || element.isNamed) {
      _write(' ');
      _write(element.displayName);
    }

    if (forElement && element.defaultValueCode != null) {
      _write(' = ');
      _write(element.defaultValueCode);
    }
  }

  static FunctionType _uniqueTypeParameters(FunctionType type) {
    if (type.typeFormals.isEmpty) {
      return type;
    }

    var referencedTypeParameters = <TypeParameterElement>{};

    void collectTypeParameters(DartType type) {
      if (type is TypeParameterType) {
        referencedTypeParameters.add(type.element);
      } else if (type is FunctionType) {
        for (var typeParameter in type.typeFormals) {
          collectTypeParameters(typeParameter.bound);
        }
        for (var parameter in type.parameters) {
          collectTypeParameters(parameter.type);
        }
        collectTypeParameters(type.returnType);
      } else if (type is InterfaceType) {
        for (var typeArgument in type.typeArguments) {
          collectTypeParameters(typeArgument);
        }
      }
    }

    collectTypeParameters(type);
    referencedTypeParameters.removeAll(type.typeFormals);

    var namesToAvoid = <String>{};
    for (var typeParameter in referencedTypeParameters) {
      namesToAvoid.add(typeParameter.displayName);
    }

    var newTypeParameters = <TypeParameterElement>[];
    for (var typeParameter in type.typeFormals) {
      var name = typeParameter.name;
      for (var counter = 0; !namesToAvoid.add(name); counter++) {
        const unicodeSubscriptZero = 0x2080;
        const unicodeZero = 0x30;

        var subscript = String.fromCharCodes('$counter'.codeUnits.map((n) {
          return unicodeSubscriptZero + (n - unicodeZero);
        }));

        name = typeParameter.name + subscript;
      }

      var newTypeParameter = TypeParameterElementImpl(name, -1);
      newTypeParameter.bound = typeParameter.bound;
      newTypeParameters.add(newTypeParameter);
      ElementTypeProvider.current
          .freshTypeParameterCreated(newTypeParameter, typeParameter);
    }

    return replaceTypeParameters(type, newTypeParameters);
  }
}

enum _WriteFormalParameterKind { requiredPositional, optionalPositional, named }
