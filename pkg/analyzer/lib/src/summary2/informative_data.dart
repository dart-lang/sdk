// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/util/collection.dart';
import 'package:analyzer/src/util/comment.dart';
import 'package:collection/collection.dart';

Uint8List writeUnitInformative(CompilationUnit unit) {
  var byteSink = ByteSink();
  var sink = BufferedSink(byteSink);
  _InformativeDataWriter(sink).write(unit);
  return sink.flushAndTake();
}

/// We want to have actual offsets for tokens of various constants in the
/// element model, such as metadata and constant initializers. But we read
/// these additional pieces of resolution data later, on demand. So, these
/// offsets are different from `nameOffset` for example, which are applied
/// directly after creating corresponding elements during a library loading.
class ApplyConstantOffsets {
  Uint32List? _offsets;
  void Function(_OffsetsApplier)? _function;

  ApplyConstantOffsets(this._offsets, this._function);

  void perform() {
    var offsets = _offsets;
    var function = _function;
    if (offsets != null && function != null) {
      var applier = _OffsetsApplier(
        _SafeListIterator(offsets),
      );
      function.call(applier);
      // Clear the references to possible closure data.
      // TODO(scheglov) We want to null the whole `linkedData` instead.
      _offsets = null;
      _function = null;
    }
  }
}

class InformativeDataApplier {
  final LinkedElementFactory _elementFactory;
  final Map<Uri, Uint8List> _unitsInformativeBytes2;

  InformativeDataApplier(
    this._elementFactory,
    this._unitsInformativeBytes2,
  );

  void applyTo(LibraryElementImpl libraryElement) {
    if (_elementFactory.isApplyingInformativeData) {
      throw StateError('Unexpected recursion.');
    }
    _elementFactory.isApplyingInformativeData = true;

    var unitElements = libraryElement.units;
    for (var i = 0; i < unitElements.length; i++) {
      var unitElement = unitElements[i] as CompilationUnitElementImpl;
      var unitUri = unitElement.source.uri;
      var unitInfoBytes = _unitsInformativeBytes2[unitUri];
      if (unitInfoBytes != null) {
        var unitReader = SummaryDataReader(unitInfoBytes);
        var unitInfo = _InfoUnit(unitReader);

        if (i == 0) {
          _applyToLibrary(libraryElement, unitInfo);
        }

        unitElement.setCodeRange(unitInfo.codeOffset, unitInfo.codeLength);
        unitElement.lineInfo = LineInfo(unitInfo.lineStarts);

        _applyToAccessors(unitElement.accessors, unitInfo.accessors);

        forCorrespondingPairs(
          unitElement.classes
              .where((element) => !element.isMixinApplication)
              .toList(),
          unitInfo.classDeclarations,
          _applyToClassDeclaration,
        );

        forCorrespondingPairs(
          unitElement.classes
              .where((element) => element.isMixinApplication)
              .toList(),
          unitInfo.classTypeAliases,
          _applyToClassTypeAlias,
        );

        forCorrespondingPairs(
            unitElement.enums, unitInfo.enums, _applyToEnumDeclaration);

        forCorrespondingPairs(unitElement.extensions, unitInfo.extensions,
            _applyToExtensionDeclaration);

        forCorrespondingPairs(unitElement.functions, unitInfo.functions,
            _applyToFunctionDeclaration);

        forCorrespondingPairs(unitElement.mixins, unitInfo.mixinDeclarations,
            _applyToMixinDeclaration);

        forCorrespondingPairs(unitElement.topLevelVariables,
            unitInfo.topLevelVariable, _applyToTopLevelVariable);

        forCorrespondingPairs(
          unitElement.typeAliases
              .cast<TypeAliasElementImpl>()
              .where((e) => e.isFunctionTypeAliasBased)
              .toList(),
          unitInfo.functionTypeAliases,
          _applyToFunctionTypeAlias,
        );

        forCorrespondingPairs(
          unitElement.typeAliases
              .cast<TypeAliasElementImpl>()
              .where((e) => !e.isFunctionTypeAliasBased)
              .toList(),
          unitInfo.genericTypeAliases,
          _applyToGenericTypeAlias,
        );
      }
    }

    _elementFactory.isApplyingInformativeData = false;
  }

  void _applyToAccessors(
    List<PropertyAccessorElement> elementList,
    List<_InfoMethodDeclaration> infoList,
  ) {
    forCorrespondingPairs<PropertyAccessorElement, _InfoMethodDeclaration>(
      elementList.notSynthetic,
      infoList,
      (element, info) {
        element as PropertyAccessorElementImpl;
        element.setCodeRange(info.codeOffset, info.codeLength);
        element.nameOffset = info.nameOffset;
        element.documentationComment = info.documentationComment;
        _applyToFormalParameters(
          element.parameters_unresolved,
          info.parameters,
        );

        var linkedData = element.linkedData;
        if (linkedData is PropertyAccessorElementLinkedData) {
          linkedData.applyConstantOffsets = ApplyConstantOffsets(
            info.constantOffsets,
            (applier) {
              applier.applyToMetadata(element);
              applier.applyToTypeParameters(element.typeParameters);
            },
          );
        }
      },
    );
  }

  void _applyToClassDeclaration(
    ClassElement element,
    _InfoClassDeclaration info,
  ) {
    element as ClassElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );

    var linkedData = element.linkedData as ClassElementLinkedData;
    linkedData.applyConstantOffsets = ApplyConstantOffsets(
      info.constantOffsets,
      (applier) {
        applier.applyToMetadata(element);
        applier.applyToTypeParameters(element.typeParameters);
      },
    );
    linkedData.applyInformativeDataToMembers = () {
      _applyToConstructors(element.constructors, info.constructors);
      _applyToFields(element.fields, info.fields);
      _applyToAccessors(element.accessors, info.accessors);
      _applyToMethods(element.methods, info.methods);
    };
  }

  void _applyToClassTypeAlias(
    ClassElement element,
    _InfoClassTypeAlias info,
  ) {
    element as ClassElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );

    var linkedData = element.linkedData as ClassElementLinkedData;
    linkedData.applyConstantOffsets = ApplyConstantOffsets(
      info.constantOffsets,
      (applier) {
        applier.applyToMetadata(element);
        applier.applyToTypeParameters(element.typeParameters);
      },
    );
  }

  void _applyToCombinators(
    List<NamespaceCombinator> elementList,
    List<_InfoCombinator> infoList,
  ) {
    forCorrespondingPairs<NamespaceCombinator, _InfoCombinator>(
      elementList,
      infoList,
      (element, info) {
        if (element is ShowElementCombinatorImpl) {
          element.offset = info.offset;
          element.end = info.end;
        }
      },
    );
  }

  void _applyToConstructors(
    List<ConstructorElement> elementList,
    List<_InfoConstructorDeclaration> infoList,
  ) {
    forCorrespondingPairs<ConstructorElement, _InfoConstructorDeclaration>(
      elementList,
      infoList,
      (element, info) {
        element as ConstructorElementImpl;
        element.setCodeRange(info.codeOffset, info.codeLength);
        element.periodOffset = info.periodOffset;
        element.nameOffset = info.nameOffset;
        element.nameEnd = info.nameEnd;
        element.documentationComment = info.documentationComment;
        _applyToFormalParameters(
          element.parameters_unresolved,
          info.parameters,
        );

        var linkedData = element.linkedData as ConstructorElementLinkedData;
        linkedData.applyConstantOffsets = ApplyConstantOffsets(
          info.constantOffsets,
          (applier) {
            applier.applyToMetadata(element);
          },
        );
      },
    );
  }

  void _applyToEnumDeclaration(
    ClassElement element,
    _InfoEnumDeclaration info,
  ) {
    element as EnumElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;

    forCorrespondingPairs<FieldElement, _InfoEnumConstantDeclaration>(
      element.constants_unresolved,
      info.constants,
      (element, info) {
        element as FieldElementImpl;
        element.setCodeRange(info.codeOffset, info.codeLength);
        element.nameOffset = info.nameOffset;
        element.documentationComment = info.documentationComment;
      },
    );

    var linkedData = element.linkedData as EnumElementLinkedData;
    linkedData.applyConstantOffsets = ApplyConstantOffsets(
      info.constantOffsets,
      (applier) {
        applier.applyToMetadata(element);
        applier.applyToEnumConstants(element.constants);
      },
    );
  }

  void _applyToExtensionDeclaration(
    ExtensionElement element,
    _InfoClassDeclaration info,
  ) {
    element as ExtensionElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );
    _applyToFields(element.fields, info.fields);
    _applyToAccessors(element.accessors, info.accessors);
    _applyToMethods(element.methods, info.methods);

    var linkedData = element.linkedData as ExtensionElementLinkedData;
    linkedData.applyConstantOffsets = ApplyConstantOffsets(
      info.constantOffsets,
      (applier) {
        applier.applyToMetadata(element);
        applier.applyToTypeParameters(element.typeParameters);
      },
    );
  }

  void _applyToFields(
    List<FieldElement> elementList,
    List<_InfoFieldDeclaration> infoList,
  ) {
    forCorrespondingPairs<FieldElement, _InfoFieldDeclaration>(
      elementList.notSynthetic,
      infoList,
      (element, info) {
        element as FieldElementImpl;
        element.setCodeRange(info.codeOffset, info.codeLength);
        element.nameOffset = info.nameOffset;
        (element.getter as PropertyAccessorElementImpl?)?.nameOffset =
            info.nameOffset;
        (element.setter as PropertyAccessorElementImpl?)?.nameOffset =
            info.nameOffset;
        element.documentationComment = info.documentationComment;

        var linkedData = element.linkedData as FieldElementLinkedData;
        linkedData.applyConstantOffsets = ApplyConstantOffsets(
          info.constantOffsets,
          (applier) {
            applier.applyToMetadata(element);
            applier.applyToConstantInitializer(element);
          },
        );
      },
    );
  }

  void _applyToFormalParameters(
    List<ParameterElement> parameters,
    List<_InfoFormalParameter> infoList,
  ) {
    forCorrespondingPairs<ParameterElement, _InfoFormalParameter>(
      parameters,
      infoList,
      (element, info) {
        element as ParameterElementImpl;
        element.setCodeRange(info.codeOffset, info.codeLength);
        element.nameOffset = info.nameOffset;
        _applyToTypeParameters(element.typeParameters, info.typeParameters);
        _applyToFormalParameters(element.parameters, info.parameters);
      },
    );
  }

  void _applyToFunctionDeclaration(
    FunctionElement element,
    _InfoFunctionDeclaration info,
  ) {
    element as FunctionElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );
    _applyToFormalParameters(
      element.parameters_unresolved,
      info.parameters,
    );

    var linkedData = element.linkedData as FunctionElementLinkedData;
    linkedData.applyConstantOffsets = ApplyConstantOffsets(
      info.constantOffsets,
      (applier) {
        applier.applyToMetadata(element);
        applier.applyToTypeParameters(element.typeParameters);
      },
    );
  }

  void _applyToFunctionTypeAlias(
    TypeAliasElement element,
    _InfoFunctionTypeAlias info,
  ) {
    element as TypeAliasElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );
  }

  void _applyToGenericTypeAlias(
    TypeAliasElement element,
    _InfoGenericTypeAlias info,
  ) {
    element as TypeAliasElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );
  }

  void _applyToLibrary(LibraryElementImpl element, _InfoUnit info) {
    element.nameOffset = info.libraryName.offset;
    element.nameLength = info.libraryName.length;

    if (info.docComment.isNotEmpty) {
      element.documentationComment = info.docComment;
    }

    forCorrespondingPairs<ImportElement, _InfoImport>(
      element.imports_unresolved,
      info.imports,
      (element, info) {
        element as ImportElementImpl;
        element.nameOffset = info.nameOffset;

        var prefix = element.prefix;
        if (prefix is PrefixElementImpl) {
          prefix.nameOffset = info.prefixOffset;
        }

        _applyToCombinators(element.combinators, info.combinators);
      },
    );

    forCorrespondingPairs<ExportElement, _InfoExport>(
      element.exports_unresolved,
      info.exports,
      (element, info) {
        element as ExportElementImpl;
        element.nameOffset = info.nameOffset;
        _applyToCombinators(element.combinators, info.combinators);
      },
    );
  }

  void _applyToMethods(
    List<MethodElement> elementList,
    List<_InfoMethodDeclaration> infoList,
  ) {
    forCorrespondingPairs<MethodElement, _InfoMethodDeclaration>(
      elementList,
      infoList,
      (element, info) {
        element as MethodElementImpl;
        element.setCodeRange(info.codeOffset, info.codeLength);
        element.nameOffset = info.nameOffset;
        element.documentationComment = info.documentationComment;
        _applyToTypeParameters(
          element.typeParameters_unresolved,
          info.typeParameters,
        );
        _applyToFormalParameters(
          element.parameters_unresolved,
          info.parameters,
        );

        var linkedData = element.linkedData as MethodElementLinkedData;
        linkedData.applyConstantOffsets = ApplyConstantOffsets(
          info.constantOffsets,
          (applier) {
            applier.applyToMetadata(element);
            applier.applyToTypeParameters(element.typeParameters);
          },
        );
      },
    );
  }

  void _applyToMixinDeclaration(
    ClassElement element,
    _InfoClassDeclaration info,
  ) {
    element as MixinElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );
    _applyToConstructors(element.constructors, info.constructors);
    _applyToFields(element.fields, info.fields);
    _applyToAccessors(element.accessors, info.accessors);
    _applyToMethods(element.methods, info.methods);

    var linkedData = element.linkedData as MixinElementLinkedData;
    linkedData.applyConstantOffsets = ApplyConstantOffsets(
      info.constantOffsets,
      (applier) {
        applier.applyToMetadata(element);
        applier.applyToTypeParameters(element.typeParameters);
      },
    );
  }

  void _applyToTopLevelVariable(
    TopLevelVariableElement element,
    _InfoTopLevelVariable info,
  ) {
    element as TopLevelVariableElementImpl;
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.nameOffset = info.nameOffset;
    (element.getter as PropertyAccessorElementImpl?)?.nameOffset =
        info.nameOffset;
    (element.setter as PropertyAccessorElementImpl?)?.nameOffset =
        info.nameOffset;
    element.documentationComment = info.documentationComment;

    var linkedData = element.linkedData as TopLevelVariableElementLinkedData;
    linkedData.applyConstantOffsets = ApplyConstantOffsets(
      info.constantOffsets,
      (applier) {
        applier.applyToMetadata(element);
        applier.applyToConstantInitializer(element);
      },
    );
  }

  void _applyToTypeParameters(
    List<TypeParameterElement> elementList,
    List<_InfoTypeParameter> infoList,
  ) {
    forCorrespondingPairs<TypeParameterElement, _InfoTypeParameter>(
      elementList,
      infoList,
      (element, info) {
        element as TypeParameterElementImpl;
        element.setCodeRange(info.codeOffset, info.codeLength);
        element.nameOffset = info.nameOffset;
      },
    );
  }
}

class _InfoClassDeclaration {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoConstructorDeclaration> constructors;
  final List<_InfoFieldDeclaration> fields;
  final List<_InfoMethodDeclaration> accessors;
  final List<_InfoMethodDeclaration> methods;
  final Uint32List constantOffsets;

  factory _InfoClassDeclaration(SummaryDataReader reader,
      {int nameOffsetDelta = 0}) {
    return _InfoClassDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30() - nameOffsetDelta,
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(
        () => _InfoTypeParameter(reader),
      ),
      constructors: reader.readTypedList(
        () => _InfoConstructorDeclaration(reader),
      ),
      fields: reader.readTypedList(
        () => _InfoFieldDeclaration(reader),
      ),
      accessors: reader.readTypedList(
        () => _InfoMethodDeclaration(reader),
      ),
      methods: reader.readTypedList(
        () => _InfoMethodDeclaration(reader),
      ),
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoClassDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.typeParameters,
    required this.constructors,
    required this.fields,
    required this.accessors,
    required this.methods,
    required this.constantOffsets,
  });
}

class _InfoClassTypeAlias {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;
  final Uint32List constantOffsets;

  factory _InfoClassTypeAlias(SummaryDataReader reader) {
    return _InfoClassTypeAlias._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(
        () => _InfoTypeParameter(reader),
      ),
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoClassTypeAlias._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.typeParameters,
    required this.constantOffsets,
  });
}

class _InfoCombinator {
  final int offset;
  final int end;

  factory _InfoCombinator(SummaryDataReader reader) {
    return _InfoCombinator._(
      offset: reader.readUInt30(),
      end: reader.readUInt30(),
    );
  }

  _InfoCombinator._({
    required this.offset,
    required this.end,
  });
}

class _InfoConstructorDeclaration {
  final int codeOffset;
  final int codeLength;
  final int? periodOffset;
  final int nameOffset;
  final int nameEnd;
  final String? documentationComment;
  final List<_InfoFormalParameter> parameters;
  final Uint32List constantOffsets;

  factory _InfoConstructorDeclaration(SummaryDataReader reader) {
    return _InfoConstructorDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      periodOffset: reader.readOptionalUInt30(),
      nameOffset: reader.readUInt30(),
      nameEnd: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      parameters: reader.readTypedList(
        () => _InfoFormalParameter(reader),
      ),
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoConstructorDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.periodOffset,
    required this.nameOffset,
    required this.nameEnd,
    required this.documentationComment,
    required this.parameters,
    required this.constantOffsets,
  });
}

class _InfoEnumConstantDeclaration {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;

  factory _InfoEnumConstantDeclaration(SummaryDataReader reader) {
    return _InfoEnumConstantDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
    );
  }

  _InfoEnumConstantDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
  });
}

class _InfoEnumDeclaration {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;
  final List<_InfoEnumConstantDeclaration> constants;
  final Uint32List constantOffsets;

  factory _InfoEnumDeclaration(SummaryDataReader reader) {
    return _InfoEnumDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      constants: reader.readTypedList(
        () => _InfoEnumConstantDeclaration(reader),
      ),
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoEnumDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.constants,
    required this.constantOffsets,
  });
}

class _InfoExport {
  final int nameOffset;
  final List<_InfoCombinator> combinators;

  factory _InfoExport(SummaryDataReader reader) {
    return _InfoExport._(
      nameOffset: reader.readUInt30(),
      combinators: reader.readTypedList(
        () => _InfoCombinator(reader),
      ),
    );
  }

  _InfoExport._({
    required this.nameOffset,
    required this.combinators,
  });
}

class _InfoFieldDeclaration {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;
  final Uint32List constantOffsets;

  factory _InfoFieldDeclaration(SummaryDataReader reader) {
    return _InfoFieldDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoFieldDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.constantOffsets,
  });
}

class _InfoFormalParameter {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoFormalParameter> parameters;

  factory _InfoFormalParameter(SummaryDataReader reader) {
    return _InfoFormalParameter._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30() - 1,
      typeParameters: reader.readTypedList(
        () => _InfoTypeParameter(reader),
      ),
      parameters: reader.readTypedList(
        () => _InfoFormalParameter(reader),
      ),
    );
  }

  _InfoFormalParameter._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.typeParameters,
    required this.parameters,
  });
}

class _InfoFunctionDeclaration {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoFormalParameter> parameters;
  final Uint32List constantOffsets;

  factory _InfoFunctionDeclaration(SummaryDataReader reader) {
    return _InfoFunctionDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(
        () => _InfoTypeParameter(reader),
      ),
      parameters: reader.readTypedList(
        () => _InfoFormalParameter(reader),
      ),
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoFunctionDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.typeParameters,
    required this.parameters,
    required this.constantOffsets,
  });
}

class _InfoFunctionTypeAlias {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoFormalParameter> parameters;

  factory _InfoFunctionTypeAlias(SummaryDataReader reader) {
    return _InfoFunctionTypeAlias._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(
        () => _InfoTypeParameter(reader),
      ),
      parameters: reader.readTypedList(
        () => _InfoFormalParameter(reader),
      ),
    );
  }

  _InfoFunctionTypeAlias._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.typeParameters,
    required this.parameters,
  });
}

class _InfoGenericTypeAlias {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;

  factory _InfoGenericTypeAlias(SummaryDataReader reader) {
    return _InfoGenericTypeAlias._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(
        () => _InfoTypeParameter(reader),
      ),
    );
  }

  _InfoGenericTypeAlias._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.typeParameters,
  });
}

class _InfoImport {
  final int nameOffset;
  final int prefixOffset;
  final List<_InfoCombinator> combinators;

  factory _InfoImport(SummaryDataReader reader) {
    return _InfoImport._(
      nameOffset: reader.readUInt30(),
      prefixOffset: reader.readUInt30() - 1,
      combinators: reader.readTypedList(
        () => _InfoCombinator(reader),
      ),
    );
  }

  _InfoImport._({
    required this.nameOffset,
    required this.prefixOffset,
    required this.combinators,
  });
}

class _InfoLibraryName {
  final int offset;
  final int length;

  factory _InfoLibraryName(SummaryDataReader reader) {
    return _InfoLibraryName._(
      offset: reader.readUInt30() - 1,
      length: reader.readUInt30(),
    );
  }

  _InfoLibraryName._({
    required this.offset,
    required this.length,
  });
}

class _InfoMethodDeclaration {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoFormalParameter> parameters;
  final Uint32List constantOffsets;

  factory _InfoMethodDeclaration(SummaryDataReader reader) {
    return _InfoMethodDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(
        () => _InfoTypeParameter(reader),
      ),
      parameters: reader.readTypedList(
        () => _InfoFormalParameter(reader),
      ),
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoMethodDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.typeParameters,
    required this.parameters,
    required this.constantOffsets,
  });
}

class _InformativeDataWriter {
  final BufferedSink sink;

  _InformativeDataWriter(this.sink);

  void write(CompilationUnit unit) {
    sink.writeUInt30(unit.offset);
    sink.writeUInt30(unit.length);

    sink.writeUint30List(unit.lineInfo?.lineStarts ?? [0]);

    _writeLibraryName(unit);

    var firstDirective = unit.directives.firstOrNull;
    _writeDocumentationCommentNode(firstDirective?.documentationComment);

    sink.writeList2<ImportDirective>(unit.directives, (directive) {
      sink.writeUInt30(directive.keyword.offset);
      sink.writeUInt30(1 + (directive.prefix?.offset ?? -1));
      _writeCombinators(directive.combinators);
    });

    sink.writeList2<ExportDirective>(unit.directives, (directive) {
      sink.writeUInt30(directive.keyword.offset);
      _writeCombinators(directive.combinators);
    });

    sink.writeList2<ClassDeclaration>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
      _writeConstructors(node.members);
      _writeFields(node.members);
      _writeGettersSetters(node.members);
      _writeMethods(node.members);
      _writeOffsets(
        metadata: node.metadata,
        typeParameters: node.typeParameters,
      );
    });

    sink.writeList2<ClassTypeAlias>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
      _writeOffsets(
        metadata: node.metadata,
        typeParameters: node.typeParameters,
      );
    });

    sink.writeList2<EnumDeclaration>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
      _writeDocumentationComment(node);
      sink.writeList2<EnumConstantDeclaration>(node.constants, (node) {
        sink.writeUInt30(node.offset);
        sink.writeUInt30(node.length);
        sink.writeUInt30(node.name.offset);
        _writeDocumentationComment(node);
      });
      _writeOffsets(
        metadata: node.metadata,
        enumConstants: node.constants,
      );
    });

    sink.writeList2<ExtensionDeclaration>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(1 + (node.name?.offset ?? -1));
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
      _writeConstructors(node.members);
      _writeFields(node.members);
      _writeGettersSetters(node.members);
      _writeMethods(node.members);
      _writeOffsets(
        metadata: node.metadata,
        typeParameters: node.typeParameters,
      );
    });

    sink.writeList2<FunctionDeclaration>(
      unit.declarations
          .whereType<FunctionDeclaration>()
          .where((e) => e.isGetter || e.isSetter)
          .toList(),
      (node) {
        sink.writeUInt30(node.offset);
        sink.writeUInt30(node.length);
        sink.writeUInt30(node.name.offset);
        _writeDocumentationComment(node);
        _writeTypeParameters(node.functionExpression.typeParameters);
        _writeFormalParameters(node.functionExpression.parameters);
        _writeOffsets(
          metadata: node.metadata,
          typeParameters: node.functionExpression.typeParameters,
        );
      },
    );

    sink.writeList2<FunctionDeclaration>(
        unit.declarations
            .whereType<FunctionDeclaration>()
            .where((e) => !(e.isGetter || e.isSetter))
            .toList(), (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.functionExpression.typeParameters);
      _writeFormalParameters(node.functionExpression.parameters);
      _writeOffsets(
        metadata: node.metadata,
        typeParameters: node.functionExpression.typeParameters,
      );
    });

    sink.writeList2<FunctionTypeAlias>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
      _writeFormalParameters(node.parameters);
    });

    sink.writeList2<GenericTypeAlias>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
    });

    sink.writeList2<MixinDeclaration>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
      _writeConstructors(node.members);
      _writeFields(node.members);
      _writeGettersSetters(node.members);
      _writeMethods(node.members);
      _writeOffsets(
        metadata: node.metadata,
        typeParameters: node.typeParameters,
      );
    });

    sink.writeList<VariableDeclaration>(
      unit.declarations
          .whereType<TopLevelVariableDeclaration>()
          .expand((declaration) => declaration.variables.variables)
          .toList(),
      _writeTopLevelVariable,
    );
  }

  int _codeOffsetForVariable(VariableDeclaration node) {
    var codeOffset = node.offset;
    var variableList = node.parent as VariableDeclarationList;
    if (variableList.variables[0] == node) {
      codeOffset = variableList.parent!.offset;
    }
    return codeOffset;
  }

  void _writeCombinators(List<Combinator> combinators) {
    sink.writeList<Combinator>(combinators, (combinator) {
      sink.writeUInt30(combinator.offset);
      sink.writeUInt30(combinator.end);
    });
  }

  void _writeConstructors(List<ClassMember> members) {
    sink.writeList2<ConstructorDeclaration>(members, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeOptionalUInt30(node.period?.offset);
      var nameNode = node.name ?? node.returnType;
      sink.writeUInt30(nameNode.offset);
      sink.writeUInt30(nameNode.end);
      _writeDocumentationComment(node);
      _writeFormalParameters(node.parameters);
      _writeOffsets(
        metadata: node.metadata,
      );
    });
  }

  void _writeDocumentationComment(AnnotatedNode node) {
    _writeDocumentationCommentNode(node.documentationComment);
  }

  void _writeDocumentationCommentNode(Comment? commentNode) {
    var commentText = getCommentNodeRawText(commentNode);
    sink.writeStringUtf8(commentText ?? '');
  }

  void _writeFields(List<ClassMember> members) {
    sink.writeList<VariableDeclaration>(
      members
          .whereType<FieldDeclaration>()
          .expand((declaration) => declaration.fields.variables)
          .toList(),
      (node) {
        var codeOffset = _codeOffsetForVariable(node);
        sink.writeUInt30(codeOffset);
        sink.writeUInt30(node.end - codeOffset);
        sink.writeUInt30(node.name.offset);
        _writeDocumentationComment(node);

        // TODO(scheglov) Replace with some kind of double-iterating list.
        var declaration = node.parent!.parent as FieldDeclaration;

        var collector = _OffsetsCollector();
        declaration.metadata.accept(collector);
        node.initializer?.accept(collector);
        sink.writeUint30List(collector.offsets);
      },
    );
  }

  void _writeFormalParameters(FormalParameterList? parameterList) {
    var parameters = parameterList?.parameters ?? <FormalParameter>[];
    sink.writeList<FormalParameter>(parameters, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(1 + (node.identifier?.offset ?? -1));

      var notDefault = node.notDefault;
      if (notDefault is FunctionTypedFormalParameter) {
        _writeTypeParameters(notDefault.typeParameters);
        _writeFormalParameters(notDefault.parameters);
      } else {
        _writeTypeParameters(null);
        _writeFormalParameters(null);
      }
    });
  }

  void _writeGettersSetters(List<ClassMember> members) {
    sink.writeList<MethodDeclaration>(
      members
          .whereType<MethodDeclaration>()
          .where((e) => e.isGetter || e.isSetter)
          .toList(),
      (node) {
        sink.writeUInt30(node.offset);
        sink.writeUInt30(node.length);
        sink.writeUInt30(node.name.offset);
        _writeDocumentationComment(node);
        _writeTypeParameters(node.typeParameters);
        _writeFormalParameters(node.parameters);
        _writeOffsets(
          metadata: node.metadata,
          typeParameters: node.typeParameters,
        );
      },
    );
  }

  void _writeLibraryName(CompilationUnit unit) {
    var nameOffset = -1;
    var nameLength = 0;
    for (var directive in unit.directives) {
      if (directive is LibraryDirective) {
        nameOffset = directive.name.offset;
        nameLength = directive.name.length;
        break;
      }
    }
    sink.writeUInt30(1 + nameOffset);
    sink.writeUInt30(nameLength);
  }

  void _writeMethods(List<ClassMember> members) {
    sink.writeList<MethodDeclaration>(
      members
          .whereType<MethodDeclaration>()
          .where((e) => !(e.isGetter || e.isSetter))
          .toList(),
      (node) {
        sink.writeUInt30(node.offset);
        sink.writeUInt30(node.length);
        sink.writeUInt30(node.name.offset);
        _writeDocumentationComment(node);
        _writeTypeParameters(node.typeParameters);
        _writeFormalParameters(node.parameters);
        _writeOffsets(
          metadata: node.metadata,
          typeParameters: node.typeParameters,
        );
      },
    );
  }

  void _writeOffsets({
    NodeList<Annotation>? metadata,
    TypeParameterList? typeParameters,
    List<EnumConstantDeclaration>? enumConstants,
  }) {
    var collector = _OffsetsCollector();
    metadata?.accept(collector);
    typeParameters?.typeParameters.accept(collector);
    if (enumConstants != null) {
      for (var enumConstant in enumConstants) {
        enumConstant.metadata.accept(collector);
      }
    }
    sink.writeUint30List(collector.offsets);
  }

  void _writeTopLevelVariable(VariableDeclaration node) {
    var codeOffset = _codeOffsetForVariable(node);
    sink.writeUInt30(codeOffset);
    sink.writeUInt30(node.end - codeOffset);
    sink.writeUInt30(node.name.offset);
    _writeDocumentationComment(node);

    // TODO(scheglov) Replace with some kind of double-iterating list.
    var declaration = node.parent!.parent as TopLevelVariableDeclaration;

    var collector = _OffsetsCollector();
    declaration.metadata.accept(collector);
    node.initializer?.accept(collector);
    sink.writeUint30List(collector.offsets);
  }

  void _writeTypeParameters(TypeParameterList? parameterList) {
    var parameters = parameterList?.typeParameters ?? <TypeParameter>[];
    sink.writeList<TypeParameter>(parameters, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
    });
  }
}

class _InfoTopLevelVariable {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;
  final String? documentationComment;
  final Uint32List constantOffsets;

  factory _InfoTopLevelVariable(SummaryDataReader reader) {
    return _InfoTopLevelVariable._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoTopLevelVariable._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.constantOffsets,
  });
}

class _InfoTypeParameter {
  final int codeOffset;
  final int codeLength;
  final int nameOffset;

  factory _InfoTypeParameter(SummaryDataReader reader) {
    return _InfoTypeParameter._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      nameOffset: reader.readUInt30(),
    );
  }

  _InfoTypeParameter._({
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
  });
}

class _InfoUnit {
  final int codeOffset;
  final int codeLength;
  final List<int> lineStarts;
  final _InfoLibraryName libraryName;
  final String docComment;
  final List<_InfoImport> imports;
  final List<_InfoExport> exports;
  final List<_InfoClassDeclaration> classDeclarations;
  final List<_InfoClassTypeAlias> classTypeAliases;
  final List<_InfoEnumDeclaration> enums;
  final List<_InfoClassDeclaration> extensions;
  final List<_InfoMethodDeclaration> accessors;
  final List<_InfoFunctionDeclaration> functions;
  final List<_InfoFunctionTypeAlias> functionTypeAliases;
  final List<_InfoGenericTypeAlias> genericTypeAliases;
  final List<_InfoClassDeclaration> mixinDeclarations;
  final List<_InfoTopLevelVariable> topLevelVariable;

  factory _InfoUnit(SummaryDataReader reader) {
    return _InfoUnit._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      lineStarts: reader.readUInt30List(),
      libraryName: _InfoLibraryName(reader),
      docComment: reader.readStringUtf8(),
      imports: reader.readTypedList(
        () => _InfoImport(reader),
      ),
      exports: reader.readTypedList(
        () => _InfoExport(reader),
      ),
      classDeclarations: reader.readTypedList(
        () => _InfoClassDeclaration(reader),
      ),
      classTypeAliases: reader.readTypedList(
        () => _InfoClassTypeAlias(reader),
      ),
      enums: reader.readTypedList(
        () => _InfoEnumDeclaration(reader),
      ),
      extensions: reader.readTypedList(
        () => _InfoClassDeclaration(reader, nameOffsetDelta: 1),
      ),
      accessors: reader.readTypedList(
        () => _InfoMethodDeclaration(reader),
      ),
      functions: reader.readTypedList(
        () => _InfoFunctionDeclaration(reader),
      ),
      functionTypeAliases: reader.readTypedList(
        () => _InfoFunctionTypeAlias(reader),
      ),
      genericTypeAliases: reader.readTypedList(
        () => _InfoGenericTypeAlias(reader),
      ),
      mixinDeclarations: reader.readTypedList(
        () => _InfoClassDeclaration(reader),
      ),
      topLevelVariable: reader.readTypedList(
        () => _InfoTopLevelVariable(reader),
      ),
    );
  }

  _InfoUnit._({
    required this.codeOffset,
    required this.codeLength,
    required this.lineStarts,
    required this.libraryName,
    required this.docComment,
    required this.imports,
    required this.exports,
    required this.classDeclarations,
    required this.classTypeAliases,
    required this.enums,
    required this.extensions,
    required this.accessors,
    required this.functions,
    required this.functionTypeAliases,
    required this.genericTypeAliases,
    required this.mixinDeclarations,
    required this.topLevelVariable,
  });
}

class _OffsetsApplier extends RecursiveAstVisitor<void> {
  final _SafeListIterator<int> _iterator;

  _OffsetsApplier(this._iterator);

  void applyToConstantInitializer(Element element) {
    if (element is ConstVariableElement) {
      var initializer = element.constantInitializer;
      if (initializer != null) {
        initializer.accept(this);
      }
    }
  }

  void applyToEnumConstants(List<FieldElement> constants) {
    for (var constant in constants) {
      applyToMetadata(constant);
    }
  }

  void applyToMetadata(Element element) {
    for (var annotation in element.metadata) {
      var node = (annotation as ElementAnnotationImpl).annotationAst;
      node.accept(this);
    }
  }

  void applyToTypeParameters(List<TypeParameterElement> typeParameters) {
    for (var typeParameter in typeParameters) {
      applyToMetadata(typeParameter);
    }
  }

  @override
  void visitAnnotation(Annotation node) {
    _applyToToken(node.atSign);
    super.visitAnnotation(node);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    _applyToToken(node.leftParenthesis);
    _applyToToken(node.rightParenthesis);
    super.visitArgumentList(node);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _applyToToken(node.literal);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    _applyToToken(node.literal);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _applyToToken(node.leftBracket);
    _applyToToken(node.rightBracket);
    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _applyToToken(node.keyword);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    _applyToToken(node.literal);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    _applyToToken(node.leftParenthesis);
    _applyToToken(node.rightParenthesis);
    super.visitParenthesizedExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _applyToToken(node.operator);
    super.visitPrefixExpression(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _applyToToken(node.token);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _applyToToken(node.literal);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _applyToToken(node.throwKeyword);
    super.visitThrowExpression(node);
  }

  void _applyToToken(Token? token) {
    if (token != null) {
      var offset = _iterator.take();
      if (offset != null) {
        token.offset = offset;
      }
    }
  }
}

class _OffsetsCollector extends RecursiveAstVisitor<void> {
  final List<int> offsets = [];

  @override
  void visitAnnotation(Annotation node) {
    _addToken(node.atSign);
    super.visitAnnotation(node);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    _addToken(node.leftParenthesis);
    _addToken(node.rightParenthesis);
    super.visitArgumentList(node);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _addToken(node.literal);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    _addToken(node.literal);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _addToken(node.leftBracket);
    _addToken(node.rightBracket);
    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _addToken(node.keyword);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    _addToken(node.literal);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    _addToken(node.leftParenthesis);
    _addToken(node.rightParenthesis);
    super.visitParenthesizedExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _addToken(node.operator);
    super.visitPrefixExpression(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _addToken(node.token);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _addToken(node.literal);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _addToken(node.throwKeyword);
    super.visitThrowExpression(node);
  }

  void _addToken(Token? token) {
    if (token != null) {
      offsets.add(token.offset);
    }
  }
}

class _SafeListIterator<T> {
  final List<T> _elements;
  int _index = 0;

  _SafeListIterator(this._elements);

  bool get hasNext {
    return _index < _elements.length;
  }

  T? take() {
    if (hasNext) {
      return _elements[_index++];
    } else {
      return null;
    }
  }
}

extension on String {
  String? get nullIfEmpty {
    return isNotEmpty ? this : null;
  }
}

extension _ListOfElement<T extends Element> on List<T> {
  List<T> get notSynthetic {
    return where((e) => !e.isSynthetic).toList();
  }
}
