// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart'
    show Variance;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';

/// A class that builds a "display string" for [Element]s and [DartType]s.
class ElementDisplayStringBuilder {
  final StringBuffer _buffer = StringBuffer();

  /// Whether to include the nullability ('?' characters) in a display string.
  final bool _withNullability;

  /// Whether to allow a display string to be written in multiple lines.
  final bool _multiline;

  /// Whether to write instantiated type alias when available.
  final bool preferTypeAlias;

  ElementDisplayStringBuilder({
    @Deprecated('Only non-nullable by default mode is supported')
    bool withNullability = true,
    bool multiline = false,
    required this.preferTypeAlias,
  })  : _withNullability = withNullability,
        _multiline = multiline;

  @override
  String toString() => _buffer.toString();

  void writeAbstractElement(ElementImpl element) {
    _write(element.name ?? '<unnamed $runtimeType>');
  }

  void writeClassElement(ClassElementImpl element) {
    if (element.isAugmentation) {
      _write('augment ');
    }

    if (element.isSealed) {
      _write('sealed ');
    } else if (element.isAbstract) {
      _write('abstract ');
    }
    if (element.isBase) {
      _write('base ');
    } else if (element.isInterface) {
      _write('interface ');
    } else if (element.isFinal) {
      _write('final ');
    }
    if (element.isMixinClass) {
      _write('mixin ');
    }

    _write('class ');
    _write(element.displayName);

    _writeTypeParameters(element.typeParameters);

    _writeTypeIfNotObject(' extends ', element.supertype);
    _writeTypesIfNotEmpty(' with ', element.mixins);
    _writeTypesIfNotEmpty(' implements ', element.interfaces);
  }

  void writeCompilationUnitElement(CompilationUnitElementImpl element) {
    var path = element.source.fullName;
    _write(path);
  }

  void writeConstructorElement(ConstructorElement element) {
    if (element.isAugmentation) {
      _write('augment ');
    }

    _writeType(element.returnType);
    _write(' ');

    _write(element.displayName);

    _writeFormalParameters(
      element.parameters,
      forElement: true,
      allowMultiline: true,
    );
  }

  void writeDynamicType() {
    _write('dynamic');
  }

  void writeEnumElement(EnumElement element) {
    if (element.isAugmentation) {
      _write('augment ');
    }

    _write('enum ');
    _write(element.displayName);
    _writeTypeParameters(element.typeParameters);
    _writeTypesIfNotEmpty(' with ', element.mixins);
    _writeTypesIfNotEmpty(' implements ', element.interfaces);
  }

  void writeExecutableElement(ExecutableElement element, String name) {
    if (element.isAugmentation) {
      _write('augment ');
    }

    if (element.kind != ElementKind.SETTER) {
      _writeType(element.returnType);
      _write(' ');
    }

    _write(name);

    if (element.kind != ElementKind.GETTER) {
      _writeTypeParameters(element.typeParameters);
      _writeFormalParameters(
        element.parameters,
        forElement: true,
        allowMultiline: true,
      );
    }
  }

  void writeExportElement(LibraryExportElementImpl element) {
    _write('export ');
    _writeDirectiveUri(element.uri);
  }

  void writeExtensionElement(ExtensionElement element) {
    if (element.isAugmentation) {
      _write('augment ');
    }

    _write('extension');
    if (element.displayName.isNotEmpty) {
      _write(' ');
      _write(element.displayName);
      _writeTypeParameters(element.typeParameters);
    }
    _write(' on ');
    _writeType(element.extendedType);
  }

  void writeExtensionTypeElement(ExtensionTypeElementImpl element) {
    if (element.isAugmentation) {
      _write('augment ');
    }

    _write('extension type ');
    _write(element.displayName);

    _writeTypeParameters(element.typeParameters);
    _write('(');
    _writeType(element.representation.type);
    _write(' ');
    _write(element.representation.name);
    _write(')');

    _writeTypesIfNotEmpty(' implements ', element.interfaces);
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
    if (_maybeWriteTypeAlias(type)) {
      return;
    }

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

  void writeImportElement(LibraryImportElementImpl element) {
    _write('import ');
    _writeDirectiveUri(element.uri);
  }

  void writeInterfaceType(InterfaceType type) {
    if (_maybeWriteTypeAlias(type)) {
      return;
    }

    _write(type.element.name);
    _writeTypeArguments(type.typeArguments);
    _writeNullability(type.nullabilitySuffix);
  }

  void writeInvalidType() {
    _write('InvalidType');
  }

  void writeLibraryElement(LibraryElementImpl element) {
    _write('library ');
    _write('${element.source.uri}');
  }

  void writeMixinElement(MixinElementImpl element) {
    if (element.isAugmentation) {
      _write('augment ');
    }
    if (element.isBase) {
      _write('base ');
    }
    _write('mixin ');
    _write(element.displayName);
    _writeTypeParameters(element.typeParameters);
    _writeTypesIfNotEmpty(' on ', element.superclassConstraints);
    _writeTypesIfNotEmpty(' implements ', element.interfaces);
  }

  void writeNeverType(NeverType type) {
    _write('Never');
    _writeNullability(type.nullabilitySuffix);
  }

  void writePartElement(PartElementImpl element) {
    _write('part ');
    _writeDirectiveUri(element.uri);
  }

  void writePrefixElement(PrefixElementImpl element) {
    _write('as ');
    _write(element.displayName);
  }

  void writePrefixElement2(PrefixElementImpl2 element) {
    _write('as ');
    _write(element.displayName);
  }

  void writeRecordType(RecordType type) {
    if (_maybeWriteTypeAlias(type)) {
      return;
    }

    var positionalFields = type.positionalFields;
    var namedFields = type.namedFields;
    var fieldCount = positionalFields.length + namedFields.length;
    _write('(');

    var index = 0;
    for (var field in positionalFields) {
      _writeType(field.type);
      if (index++ < fieldCount - 1) {
        _write(', ');
      }
    }

    if (namedFields.isNotEmpty) {
      _write('{');
      for (var field in namedFields) {
        _writeType(field.type);
        _write(' ');
        _write(field.name);
        if (index++ < fieldCount - 1) {
          _write(', ');
        }
      }
      _write('}');
    }

    // Add trailing comma for record types with only one position field.
    if (positionalFields.length == 1 && namedFields.isEmpty) {
      _write(',');
    }

    _write(')');
    _writeNullability(type.nullabilitySuffix);
  }

  void writeTypeAliasElement(TypeAliasElementImpl element) {
    if (element.isAugmentation) {
      _write('augment ');
    }

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
        _write(variance.keyword);
        _write(' ');
      }
    }

    _write(element.displayName);

    var bound = element.bound;
    if (bound != null) {
      _write(' extends ');
      _writeType(bound);
    }
  }

  void writeTypeParameterType(TypeParameterTypeImpl type) {
    var promotedBound = type.promotedBound;
    if (promotedBound != null) {
      var hasSuffix = type.nullabilitySuffix != NullabilitySuffix.none;
      if (hasSuffix) {
        _write('(');
      }
      _write(type.element.displayName);
      _write(' & ');
      _writeType(promotedBound);
      if (hasSuffix) {
        _write(')');
      }
    } else {
      _write(type.element.displayName);
    }
    _writeNullability(type.nullabilitySuffix);
  }

  void writeUnknownInferredType() {
    _write('_');
  }

  void writeVariableElement(VariableElement element) {
    switch (element) {
      case FieldElement(isAugmentation: true):
      case TopLevelVariableElement(isAugmentation: true):
        _write('augment ');
    }

    _writeType(element.type);
    _write(' ');
    _write(element.displayName);
  }

  void writeVoidType() {
    _write('void');
  }

  bool _maybeWriteTypeAlias(DartType type) {
    if (preferTypeAlias) {
      if (type.alias case var alias?) {
        _write(alias.element.name);
        _writeTypeArguments(alias.typeArguments);
        _writeNullability(type.nullabilitySuffix);
        return true;
      }
    }
    return false;
  }

  void _write(String str) {
    _buffer.write(str);
  }

  void _writeDirectiveUri(DirectiveUri uri) {
    if (uri is DirectiveUriWithUnitImpl) {
      _write('unit ${uri.unit.source.uri}');
    } else if (uri is DirectiveUriWithSourceImpl) {
      _write('source ${uri.source}');
    } else {
      _write('<unknown>');
    }
  }

  void _writeFormalParameters(
    List<ParameterElement> parameters, {
    required bool forElement,
    bool allowMultiline = false,
  }) {
    // Assume the display string looks better wrapped when there are at least
    // three parameters. This avoids having to pre-compute the single-line
    // version and know the length of the function name/return type.
    var multiline = allowMultiline && _multiline && parameters.length >= 3;

    // The prefix for open groups is included in separator for single-line but
    // not for multiline so must be added explicitly.
    var openGroupPrefix = multiline ? ' ' : '';
    var separator = multiline ? ',' : ', ';
    var trailingComma = multiline ? ',\n' : '';
    var parameterPrefix = multiline ? '\n  ' : '';

    _write('(');

    _WriteFormalParameterKind? lastKind;
    var lastClose = '';

    void openGroup(_WriteFormalParameterKind kind, String open, String close) {
      if (lastKind != kind) {
        _write(lastClose);
        if (lastKind != null) {
          // We only need to include the space before the open group if there
          // was a previous parameter, otherwise it goes immediately after the
          // open paren.
          _write(openGroupPrefix);
        }
        _write(open);
        lastKind = kind;
        lastClose = close;
      }
    }

    for (var i = 0; i < parameters.length; i++) {
      if (i != 0) {
        _write(separator);
      }

      var parameter = parameters[i];
      if (parameter.isRequiredPositional) {
        openGroup(_WriteFormalParameterKind.requiredPositional, '', '');
      } else if (parameter.isOptionalPositional) {
        openGroup(_WriteFormalParameterKind.optionalPositional, '[', ']');
      } else if (parameter.isNamed) {
        openGroup(_WriteFormalParameterKind.named, '{', '}');
      }
      _write(parameterPrefix);
      _writeWithoutDelimiters(parameter, forElement: forElement);
    }

    _write(trailingComma);
    _write(lastClose);
    _write(')');
  }

  void _writeNullability(NullabilitySuffix nullabilitySuffix) {
    if (_withNullability) {
      switch (nullabilitySuffix) {
        case NullabilitySuffix.question:
          _write('?');
        case NullabilitySuffix.star:
          _write('*');
        case NullabilitySuffix.none:
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

    _write('<');
    for (var i = 0; i < typeArguments.length; i++) {
      if (i != 0) {
        _write(', ');
      }
      (typeArguments[i] as TypeImpl).appendTo(this);
    }
    _write('>');
  }

  void _writeTypeIfNotObject(String prefix, DartType? type) {
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
    required bool forElement,
  }) {
    if (element.isRequiredNamed) {
      _write('required ');
    }

    _writeType(element.type);

    if (forElement || element.isNamed) {
      _write(' ');
      _write(element.displayName);
    }

    if (forElement) {
      var defaultValueCode = element.defaultValueCode;
      if (defaultValueCode != null) {
        _write(' = ');
        _write(defaultValueCode);
      }
    }
  }

  static FunctionType _uniqueTypeParameters(FunctionType type) {
    if (type.typeFormals.isEmpty) {
      return type;
    }

    var referencedTypeParameters = <TypeParameterElement>{};

    void collectTypeParameters(DartType? type) {
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
    }

    return replaceTypeParameters(type as FunctionTypeImpl, newTypeParameters);
  }
}

enum _WriteFormalParameterKind { requiredPositional, optionalPositional, named }
