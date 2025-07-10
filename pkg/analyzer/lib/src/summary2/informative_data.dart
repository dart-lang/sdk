// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/not_serializable_nodes.dart';
import 'package:analyzer/src/util/collection.dart';
import 'package:analyzer/src/util/comment.dart';

Uint8List writeUnitInformative(CompilationUnit unit) {
  var sink = BufferedSink();
  _InformativeDataWriter(sink).write(unit);
  return sink.takeBytes();
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
      var applier = _OffsetsApplier(_SafeListIterator(offsets));
      function.call(applier);
      // Clear the references to possible closure data.
      // TODO(scheglov): We want to null the whole `linkedData` instead.
      _offsets = null;
      _function = null;
    }
  }
}

class InformativeDataApplier {
  final LinkedElementFactory _elementFactory;
  final Map<Uri, Uint8List> _unitsInformativeBytes2;

  InformativeDataApplier(this._elementFactory, this._unitsInformativeBytes2);

  void applyTo(LibraryElementImpl libraryElement) {
    if (_elementFactory.isApplyingInformativeData) {
      throw StateError('Unexpected recursion.');
    }
    _elementFactory.isApplyingInformativeData = true;

    var unitElements = libraryElement.units;
    for (var i = 0; i < unitElements.length; i++) {
      var unitElement = unitElements[i];
      var unitInfoBytes = _getInfoUnitBytes(unitElement);
      if (unitInfoBytes != null) {
        applyToUnit(unitElement, unitInfoBytes);
      } else {
        unitElement.lineInfo = LineInfo([0]);
      }
    }

    _elementFactory.isApplyingInformativeData = false;
  }

  void applyToUnit(LibraryFragmentImpl unitElement, Uint8List unitInfoBytes) {
    var unitReader = SummaryDataReader(unitInfoBytes);
    var unitInfo = _InfoUnit(unitReader);

    var libraryElement = unitElement.library;
    if (identical(libraryElement.definingCompilationUnit, unitElement)) {
      _applyToLibrary(libraryElement, unitInfo);
    }

    unitElement.setCodeRange(unitInfo.codeOffset, unitInfo.codeLength);
    unitElement.lineInfo = LineInfo(unitInfo.lineStarts);

    _applyToImports(unitElement.libraryImports_unresolved, unitInfo);
    _applyToExports(unitElement.libraryExports_unresolved, unitInfo);

    unitElement.applyConstantOffsets = ApplyConstantOffsets(
      unitInfo.libraryConstantOffsets,
      (applier) {
        applier.applyToImports(unitElement.libraryImports);
        applier.applyToExports(unitElement.libraryExports);
        applier.applyToParts(unitElement.parts);
      },
    );

    _applyToAccessors(unitElement.getters.notSynthetic, unitInfo.getters);
    _applyToAccessors(unitElement.setters.notSynthetic, unitInfo.setters);

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
      unitElement.enums,
      unitInfo.enums,
      _applyToEnumDeclaration,
    );

    forCorrespondingPairs(
      unitElement.extensions,
      unitInfo.extensions,
      _applyToExtensionDeclaration,
    );

    forCorrespondingPairs(
      unitElement.extensionTypes,
      unitInfo.extensionTypes,
      _applyToExtensionTypeDeclaration,
    );

    forCorrespondingPairs(
      unitElement.functions,
      unitInfo.functions,
      _applyToFunctionDeclaration,
    );

    forCorrespondingPairs(
      unitElement.mixins,
      unitInfo.mixinDeclarations,
      _applyToMixinDeclaration,
    );

    forCorrespondingPairs(
      unitElement.topLevelVariables.notSynthetic,
      unitInfo.topLevelVariable,
      _applyToTopLevelVariable,
    );

    forCorrespondingPairs(
      unitElement.typeAliases
          .cast<TypeAliasFragmentImpl>()
          .where((e) => e.isFunctionTypeAliasBased)
          .toList(),
      unitInfo.functionTypeAliases,
      _applyToFunctionTypeAlias,
    );

    forCorrespondingPairs(
      unitElement.typeAliases
          .cast<TypeAliasFragmentImpl>()
          .where((e) => !e.isFunctionTypeAliasBased)
          .toList(),
      unitInfo.genericTypeAliases,
      _applyToGenericTypeAlias,
    );
  }

  void _applyToAccessors(
    List<PropertyAccessorFragmentImpl> elementList,
    List<_InfoMethodDeclaration> infoList,
  ) {
    forCorrespondingPairs(elementList.notSynthetic, infoList, (element, info) {
      element.setCodeRange(info.codeOffset, info.codeLength);
      element.firstTokenOffset = info.firstTokenOffset;
      element.nameOffset2 = info.nameOffset2;
      element.documentationComment = info.documentationComment;
      _applyToFormalParameters(element.parameters_unresolved, info.parameters);

      element.applyConstantOffsets = ApplyConstantOffsets(
        info.constantOffsets,
        (applier) {
          applier.applyToMetadata(element.metadata);
          applier.applyToTypeParameters(element.typeParameters);
          applier.applyToFormalParameters(element.parameters_unresolved);
        },
      );
    });
  }

  void _applyToClassDeclaration(
    ClassFragmentImpl element,
    _InfoClassDeclaration info,
  ) {
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.firstTokenOffset = info.firstTokenOffset;
    element.nameOffset2 = info.nameOffset2;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );

    element.applyConstantOffsets = ApplyConstantOffsets(info.constantOffsets, (
      applier,
    ) {
      applier.applyToMetadata(element.metadata);
      applier.applyToTypeParameters(element.typeParameters);
    });

    element.applyMembersConstantOffsets = () {
      element.withoutLoadingResolution(() {
        _applyToConstructors(element.constructors, info.constructors);
        _applyToFields(element.fields, info.fields);
        _applyToAccessors(element.getters, info.getters);
        _applyToAccessors(element.setters, info.setters);
        _applyToMethods(element.methods, info.methods);
      });
    };
  }

  void _applyToClassTypeAlias(
    ClassFragmentImpl element,
    _InfoClassTypeAlias info,
  ) {
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.firstTokenOffset = info.firstTokenOffset;
    element.nameOffset2 = info.nameOffset2;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );

    element.applyConstantOffsets = ApplyConstantOffsets(info.constantOffsets, (
      applier,
    ) {
      applier.applyToMetadata(element.metadata);
      applier.applyToTypeParameters(element.typeParameters);
    });
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
        if (element is HideElementCombinatorImpl) {
          element.offset = info.offset;
          element.end = info.end;
        }
      },
    );
  }

  void _applyToConstructors(
    List<ConstructorFragmentImpl> elementList,
    List<_InfoConstructorDeclaration> infoList,
  ) {
    forCorrespondingPairs(elementList, infoList, (element, info) {
      element.setCodeRange(info.codeOffset, info.codeLength);
      element.typeNameOffset = info.typeNameOffset;
      element.periodOffset = info.periodOffset;
      element.firstTokenOffset = info.firstTokenOffset;
      element.nameEnd = info.nameEnd;
      element.nameOffset2 = info.nameOffset2;
      element.documentationComment = info.documentationComment;

      _applyToFormalParameters(element.parameters_unresolved, info.parameters);

      element.applyConstantOffsets = ApplyConstantOffsets(
        info.constantOffsets,
        (applier) {
          applier.applyToMetadata(element.metadata);
          applier.applyToFormalParameters(element.parameters);
          applier.applyToConstructorInitializers(element);
        },
      );
    });
  }

  void _applyToEnumDeclaration(
    EnumFragmentImpl element,
    _InfoClassDeclaration info,
  ) {
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.firstTokenOffset = info.firstTokenOffset;
    element.nameOffset2 = info.nameOffset2;
    element.documentationComment = info.documentationComment;

    // TODO(scheglov): use it everywhere
    element.withoutLoadingResolution(() {
      _applyToTypeParameters(element.typeParameters, info.typeParameters);
      _applyToConstructors(element.constructors, info.constructors);
      _applyToFields(element.fields, info.fields);
      _applyToAccessors(element.getters, info.getters);
      _applyToAccessors(element.setters, info.setters);
      _applyToMethods(element.methods, info.methods);
    });

    element.applyConstantOffsets = ApplyConstantOffsets(info.constantOffsets, (
      applier,
    ) {
      applier.applyToMetadata(element.metadata);
      applier.applyToTypeParameters(element.typeParameters);
    });
  }

  void _applyToExports(List<LibraryExportImpl> exports, _InfoUnit info) {
    forCorrespondingPairs(exports, info.exports, (element, info) {
      element.exportKeywordOffset = info.nameOffset;
      _applyToCombinators(element.combinators, info.combinators);
    });
  }

  void _applyToExtensionDeclaration(
    ExtensionFragmentImpl element,
    _InfoClassDeclaration info,
  ) {
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.firstTokenOffset = info.firstTokenOffset;
    element.nameOffset2 = info.nameOffset2;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );
    _applyToFields(element.fields, info.fields);
    _applyToAccessors(element.getters, info.getters);
    _applyToAccessors(element.setters, info.setters);
    _applyToMethods(element.methods, info.methods);

    element.applyConstantOffsets = ApplyConstantOffsets(info.constantOffsets, (
      applier,
    ) {
      applier.applyToMetadata(element.metadata);
      applier.applyToTypeParameters(element.typeParameters);
    });
  }

  void _applyToExtensionTypeDeclaration(
    ExtensionTypeFragmentImpl element,
    _InfoExtensionTypeDeclaration info,
  ) {
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.firstTokenOffset = info.firstTokenOffset;
    element.nameOffset2 = info.nameOffset2;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );

    var representationField = element.fields.first;
    var infoRep = info.representation;
    representationField.firstTokenOffset = infoRep.firstTokenOffset;
    representationField.nameOffset2 = infoRep.fieldNameOffset2;
    representationField.setCodeRange(
      infoRep.fieldCodeOffset,
      infoRep.fieldCodeLength,
    );

    representationField.applyConstantOffsets = ApplyConstantOffsets(
      infoRep.fieldConstantOffsets,
      (applier) {
        _copyOffsetsIntoSyntheticGetterSetter(representationField);
        applier.applyToMetadata(representationField.metadata);
      },
    );

    element.withoutLoadingResolution(() {
      var primaryConstructor = element.constructors.first;
      primaryConstructor.setCodeRange(
        infoRep.constructorCodeOffset,
        infoRep.constructorCodeLength,
      );
      primaryConstructor.typeNameOffset = infoRep.typeNameOffset;
      primaryConstructor.periodOffset = infoRep.constructorPeriodOffset;
      primaryConstructor.firstTokenOffset = infoRep.constructorFirstTokenOffset;
      primaryConstructor.nameEnd = infoRep.constructorNameEnd;
      primaryConstructor.nameOffset2 = infoRep.constructorNameOffset2;

      var primaryConstructorParameter =
          primaryConstructor.parameters_unresolved.first;
      primaryConstructorParameter.firstTokenOffset = infoRep.firstTokenOffset;
      primaryConstructorParameter.nameOffset2 = infoRep.fieldNameOffset2;
      primaryConstructorParameter.setCodeRange(
        infoRep.fieldCodeOffset,
        infoRep.fieldCodeLength,
      );

      var restFields = element.fields.skip(1).toList();
      _applyToFields(restFields, info.fields);

      var restConstructors = element.constructors.skip(1).toList();
      _applyToConstructors(restConstructors, info.constructors);

      _applyToAccessors(element.getters, info.getters);
      _applyToAccessors(element.setters, info.setters);
      _applyToMethods(element.methods, info.methods);
    });

    element.applyConstantOffsets = ApplyConstantOffsets(info.constantOffsets, (
      applier,
    ) {
      applier.applyToMetadata(element.metadata);
      applier.applyToTypeParameters(element.typeParameters);
    });
  }

  void _applyToFields(
    List<FieldFragmentImpl> elementList,
    List<_InfoFieldDeclaration> infoList,
  ) {
    forCorrespondingPairs(elementList.notSynthetic, infoList, (element, info) {
      element.setCodeRange(info.codeOffset, info.codeLength);
      element.firstTokenOffset = info.firstTokenOffset;
      element.nameOffset2 = info.nameOffset2;
      element.documentationComment = info.documentationComment;

      element.applyConstantOffsets = ApplyConstantOffsets(
        info.constantOffsets,
        (applier) {
          _copyOffsetsIntoSyntheticGetterSetter(element);
          applier.applyToMetadata(element.metadata);
          applier.applyToConstantInitializer(element);
        },
      );
    });
  }

  void _applyToFormalParameters(
    List<FormalParameterFragmentImpl> parameters,
    List<_InfoFormalParameter> infoList,
  ) {
    forCorrespondingPairs(parameters, infoList, (element, info) {
      element.setCodeRange(info.codeOffset, info.codeLength);
      element.firstTokenOffset = info.firstTokenOffset;
      element.nameOffset2 = info.nameOffset2;
      _applyToTypeParameters(element.typeParameters, info.typeParameters);
      _applyToFormalParameters(element.parameters, info.parameters);
    });
  }

  void _applyToFunctionDeclaration(
    TopLevelFunctionFragmentImpl element,
    _InfoFunctionDeclaration info,
  ) {
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.firstTokenOffset = info.firstTokenOffset;
    element.nameOffset2 = info.nameOffset2;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );
    _applyToFormalParameters(element.parameters_unresolved, info.parameters);

    element.applyConstantOffsets = ApplyConstantOffsets(info.constantOffsets, (
      applier,
    ) {
      applier.applyToMetadata(element.metadata);
      applier.applyToTypeParameters(element.typeParameters);
      applier.applyToFormalParameters(element.parameters);
    });
  }

  void _applyToFunctionTypeAlias(
    TypeAliasFragmentImpl element,
    _InfoFunctionTypeAlias info,
  ) {
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.firstTokenOffset = info.firstTokenOffset;
    element.nameOffset2 = info.nameOffset2;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );

    _setupApplyConstantOffsetsForTypeAlias(
      element,
      info.constantOffsets,
      aliasedFormalParameters: info.parameters,
    );
  }

  void _applyToGenericTypeAlias(
    TypeAliasFragmentImpl element,
    _InfoGenericTypeAlias info,
  ) {
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.firstTokenOffset = info.firstTokenOffset;
    element.nameOffset2 = info.nameOffset2;
    element.documentationComment = info.documentationComment;
    _applyToTypeParameters(
      element.typeParameters_unresolved,
      info.typeParameters,
    );

    _setupApplyConstantOffsetsForTypeAlias(
      element,
      info.constantOffsets,
      aliasedFormalParameters: info.aliasedFormalParameters,
      aliasedTypeParameters: info.aliasedTypeParameters,
    );
  }

  void _applyToImports(List<LibraryImportImpl> imports, _InfoUnit info) {
    forCorrespondingPairs(imports, info.imports, (element, info) {
      element.importKeywordOffset = info.nameOffset;
      if (element.prefix2 case var prefixFragment?) {
        prefixFragment.nameOffset2 = info.prefixOffset2;
        prefixFragment.offset = info.prefixOffset;
      }
      _applyToCombinators(element.combinators, info.combinators);
    });
  }

  void _applyToLibrary(LibraryElementImpl element, _InfoUnit info) {
    element.nameOffset = info.libraryName.offset;
    element.nameLength = info.libraryName.length;

    if (info.docComment.isNotEmpty) {
      element.documentationComment = info.docComment;
    }

    element.applyConstantOffsets = ApplyConstantOffsets(
      info.libraryConstantOffsets,
      (applier) {
        applier.applyToMetadata(element.metadata);
      },
    );
  }

  void _applyToMethods(
    List<MethodFragmentImpl> elementList,
    List<_InfoMethodDeclaration> infoList,
  ) {
    forCorrespondingPairs(elementList, infoList, (element, info) {
      element.setCodeRange(info.codeOffset, info.codeLength);
      element.firstTokenOffset = info.firstTokenOffset;
      element.nameOffset2 = info.nameOffset2;
      element.documentationComment = info.documentationComment;
      _applyToTypeParameters(
        element.typeParameters_unresolved,
        info.typeParameters,
      );
      _applyToFormalParameters(element.parameters_unresolved, info.parameters);

      element.applyConstantOffsets = ApplyConstantOffsets(
        info.constantOffsets,
        (applier) {
          applier.applyToMetadata(element.metadata);
          applier.applyToTypeParameters(element.typeParameters);
          applier.applyToFormalParameters(element.parameters);
        },
      );
    });
  }

  void _applyToMixinDeclaration(
    MixinFragmentImpl element,
    _InfoClassDeclaration info,
  ) {
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.firstTokenOffset = info.firstTokenOffset;
    element.nameOffset2 = info.nameOffset2;
    element.documentationComment = info.documentationComment;

    // TODO(scheglov): use it everywhere
    element.withoutLoadingResolution(() {
      _applyToTypeParameters(element.typeParameters, info.typeParameters);
      _applyToConstructors(element.constructors, info.constructors);
      _applyToFields(element.fields, info.fields);
      _applyToAccessors(element.getters, info.getters);
      _applyToAccessors(element.setters, info.setters);
      _applyToMethods(element.methods, info.methods);
    });

    element.applyConstantOffsets = ApplyConstantOffsets(info.constantOffsets, (
      applier,
    ) {
      applier.applyToMetadata(element.metadata);
      applier.applyToTypeParameters(element.typeParameters);
    });
  }

  void _applyToTopLevelVariable(
    TopLevelVariableFragmentImpl element,
    _InfoTopLevelVariable info,
  ) {
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.firstTokenOffset = info.firstTokenOffset;
    element.nameOffset2 = info.nameOffset2;
    element.documentationComment = info.documentationComment;

    element.applyConstantOffsets = ApplyConstantOffsets(info.constantOffsets, (
      applier,
    ) {
      _copyOffsetsIntoSyntheticGetterSetter(element);
      applier.applyToMetadata(element.metadata);
      applier.applyToConstantInitializer(element);
    });
  }

  void _applyToTypeParameters(
    List<TypeParameterFragmentImpl> elementList,
    List<_InfoTypeParameter> infoList,
  ) {
    forCorrespondingPairs(elementList, infoList, (element, info) {
      element.setCodeRange(info.codeOffset, info.codeLength);
      element.firstTokenOffset = info.firstTokenOffset;
      element.nameOffset2 = info.nameOffset2;
    });
  }

  void _copyOffsetsIntoSyntheticGetterSetter(
    PropertyInducingFragmentImpl element,
  ) {
    // TODO(scheglov): can we move this sooner than applying constants?
    assert(!element.isSynthetic);

    var getterFragment = element.element.getter?.firstFragment;
    if (getterFragment != null && getterFragment.isSynthetic) {
      getterFragment.firstTokenOffset = element.firstTokenOffset;
    }

    var setterFragment = element.element.setter?.firstFragment;
    if (setterFragment != null && setterFragment.isSynthetic) {
      setterFragment.firstTokenOffset = element.firstTokenOffset;
      setterFragment.valueFormalParameter?.firstTokenOffset =
          element.firstTokenOffset;
    }
  }

  Uint8List? _getInfoUnitBytes(LibraryFragmentImpl element) {
    var uri = element.source.uri;
    return _unitsInformativeBytes2[uri];
  }

  void _setupApplyConstantOffsetsForTypeAlias(
    TypeAliasFragmentImpl element,
    Uint32List constantOffsets, {
    List<_InfoFormalParameter>? aliasedFormalParameters,
    List<_InfoTypeParameter>? aliasedTypeParameters,
  }) {
    element.applyConstantOffsets = ApplyConstantOffsets(constantOffsets, (
      applier,
    ) {
      applier.applyToMetadata(element.metadata);
      applier.applyToTypeParameters(element.typeParameters);

      var aliasedElement = element.aliasedElement;
      if (aliasedElement is FunctionTypedFragmentImpl) {
        applier.applyToTypeParameters(aliasedElement.typeParameters);
        applier.applyToFormalParameters(aliasedElement.parameters);
        if (aliasedTypeParameters != null) {
          _applyToTypeParameters(
            aliasedElement.typeParameters,
            aliasedTypeParameters,
          );
        }
        if (aliasedFormalParameters != null) {
          _applyToFormalParameters(
            aliasedElement.parameters,
            aliasedFormalParameters,
          );
        }
      }
    });
  }
}

class _InfoClassDeclaration {
  final int codeOffset;
  final int codeLength;
  final int firstTokenOffset;
  final int? nameOffset2;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoConstructorDeclaration> constructors;
  final List<_InfoFieldDeclaration> fields;
  final List<_InfoMethodDeclaration> getters;
  final List<_InfoMethodDeclaration> setters;
  final List<_InfoMethodDeclaration> methods;
  final Uint32List constantOffsets;

  factory _InfoClassDeclaration(SummaryDataReader reader) {
    return _InfoClassDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      firstTokenOffset: reader.readUInt30(),
      nameOffset2: reader.readOptionalUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(() => _InfoTypeParameter(reader)),
      constructors: reader.readTypedList(
        () => _InfoConstructorDeclaration(reader),
      ),
      fields: reader.readTypedList(() => _InfoFieldDeclaration(reader)),
      getters: reader.readTypedList(() => _InfoMethodDeclaration(reader)),
      setters: reader.readTypedList(() => _InfoMethodDeclaration(reader)),
      methods: reader.readTypedList(() => _InfoMethodDeclaration(reader)),
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoClassDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.firstTokenOffset,
    required this.nameOffset2,
    required this.documentationComment,
    required this.typeParameters,
    required this.constructors,
    required this.fields,
    required this.getters,
    required this.setters,
    required this.methods,
    required this.constantOffsets,
  });
}

class _InfoClassTypeAlias {
  final int codeOffset;
  final int codeLength;
  final int firstTokenOffset;
  final int? nameOffset2;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;
  final Uint32List constantOffsets;

  factory _InfoClassTypeAlias(SummaryDataReader reader) {
    return _InfoClassTypeAlias._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      firstTokenOffset: reader.readUInt30(),
      nameOffset2: reader.readOptionalUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(() => _InfoTypeParameter(reader)),
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoClassTypeAlias._({
    required this.codeOffset,
    required this.codeLength,
    required this.firstTokenOffset,
    required this.nameOffset2,
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

  _InfoCombinator._({required this.offset, required this.end});
}

class _InfoConstructorDeclaration {
  final int codeOffset;
  final int codeLength;
  final int? typeNameOffset;
  final int? periodOffset;
  final int firstTokenOffset;
  final int? nameEnd;
  final int? nameOffset2;
  final String? documentationComment;
  final List<_InfoFormalParameter> parameters;
  final Uint32List constantOffsets;

  factory _InfoConstructorDeclaration(SummaryDataReader reader) {
    return _InfoConstructorDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      typeNameOffset: reader.readUInt30(),
      periodOffset: reader.readOptionalUInt30(),
      firstTokenOffset: reader.readUInt30(),
      nameEnd: reader.readOptionalUInt30(),
      nameOffset2: reader.readOptionalUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      parameters: reader.readTypedList(() => _InfoFormalParameter(reader)),
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoConstructorDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.typeNameOffset,
    required this.periodOffset,
    required this.firstTokenOffset,
    required this.nameEnd,
    required this.nameOffset2,
    required this.documentationComment,
    required this.parameters,
    required this.constantOffsets,
  });
}

class _InfoExport {
  final int nameOffset;
  final List<_InfoCombinator> combinators;

  factory _InfoExport(SummaryDataReader reader) {
    return _InfoExport._(
      nameOffset: reader.readUInt30(),
      combinators: reader.readTypedList(() => _InfoCombinator(reader)),
    );
  }

  _InfoExport._({required this.nameOffset, required this.combinators});
}

class _InfoExtensionTypeDeclaration {
  final int codeOffset;
  final int codeLength;
  final int firstTokenOffset;
  final int? nameOffset2;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;
  final _InfoExtensionTypeRepresentation representation;
  final List<_InfoConstructorDeclaration> constructors;
  final List<_InfoFieldDeclaration> fields;
  final List<_InfoMethodDeclaration> getters;
  final List<_InfoMethodDeclaration> setters;
  final List<_InfoMethodDeclaration> methods;
  final Uint32List constantOffsets;

  factory _InfoExtensionTypeDeclaration(SummaryDataReader reader) {
    return _InfoExtensionTypeDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      firstTokenOffset: reader.readUInt30(),
      nameOffset2: reader.readOptionalUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(() => _InfoTypeParameter(reader)),
      representation: _InfoExtensionTypeRepresentation(reader),
      constructors: reader.readTypedList(
        () => _InfoConstructorDeclaration(reader),
      ),
      fields: reader.readTypedList(() => _InfoFieldDeclaration(reader)),
      getters: reader.readTypedList(() => _InfoMethodDeclaration(reader)),
      setters: reader.readTypedList(() => _InfoMethodDeclaration(reader)),
      methods: reader.readTypedList(() => _InfoMethodDeclaration(reader)),
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoExtensionTypeDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.firstTokenOffset,
    required this.nameOffset2,
    required this.documentationComment,
    required this.typeParameters,
    required this.representation,
    required this.constructors,
    required this.fields,
    required this.getters,
    required this.setters,
    required this.methods,
    required this.constantOffsets,
  });
}

class _InfoExtensionTypeRepresentation {
  final int constructorCodeOffset;
  final int constructorCodeLength;
  final int? typeNameOffset;
  final int? constructorPeriodOffset;
  final int constructorFirstTokenOffset;
  final int? constructorNameEnd;
  final int? constructorNameOffset2;
  final int fieldCodeOffset;
  final int fieldCodeLength;
  final int firstTokenOffset;
  final int? fieldNameOffset2;
  final Uint32List fieldConstantOffsets;

  factory _InfoExtensionTypeRepresentation(SummaryDataReader reader) {
    return _InfoExtensionTypeRepresentation._(
      constructorCodeOffset: reader.readUInt30(),
      constructorCodeLength: reader.readUInt30(),
      typeNameOffset: reader.readOptionalUInt30(),
      constructorPeriodOffset: reader.readOptionalUInt30(),
      constructorFirstTokenOffset: reader.readUInt30(),
      constructorNameEnd: reader.readOptionalUInt30(),
      constructorNameOffset2: reader.readOptionalUInt30(),
      fieldCodeOffset: reader.readUInt30(),
      fieldCodeLength: reader.readUInt30(),
      firstTokenOffset: reader.readUInt30(),
      fieldNameOffset2: reader.readOptionalUInt30(),
      fieldConstantOffsets: reader.readUInt30List(),
    );
  }

  _InfoExtensionTypeRepresentation._({
    required this.constructorCodeOffset,
    required this.constructorCodeLength,
    required this.typeNameOffset,
    required this.constructorPeriodOffset,
    required this.constructorFirstTokenOffset,
    required this.constructorNameEnd,
    required this.constructorNameOffset2,
    required this.fieldCodeOffset,
    required this.fieldCodeLength,
    required this.firstTokenOffset,
    required this.fieldNameOffset2,
    required this.fieldConstantOffsets,
  });
}

class _InfoFieldDeclaration {
  final int codeOffset;
  final int codeLength;
  final int firstTokenOffset;
  final int? nameOffset2;
  final String? documentationComment;
  final Uint32List constantOffsets;

  factory _InfoFieldDeclaration(SummaryDataReader reader) {
    return _InfoFieldDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      firstTokenOffset: reader.readUInt30(),
      nameOffset2: reader.readOptionalUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoFieldDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.firstTokenOffset,
    required this.nameOffset2,
    required this.documentationComment,
    required this.constantOffsets,
  });
}

class _InfoFormalParameter {
  final int codeOffset;
  final int codeLength;
  final int firstTokenOffset;
  final int? nameOffset2;
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoFormalParameter> parameters;

  factory _InfoFormalParameter(SummaryDataReader reader) {
    return _InfoFormalParameter._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      firstTokenOffset: reader.readUInt30() - 1,
      nameOffset2: reader.readOptionalUInt30(),
      typeParameters: reader.readTypedList(() => _InfoTypeParameter(reader)),
      parameters: reader.readTypedList(() => _InfoFormalParameter(reader)),
    );
  }

  _InfoFormalParameter._({
    required this.codeOffset,
    required this.codeLength,
    required this.firstTokenOffset,
    required this.nameOffset2,
    required this.typeParameters,
    required this.parameters,
  });
}

class _InfoFunctionDeclaration {
  final int codeOffset;
  final int codeLength;
  final int firstTokenOffset;
  final int? nameOffset2;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoFormalParameter> parameters;
  final Uint32List constantOffsets;

  factory _InfoFunctionDeclaration(SummaryDataReader reader) {
    return _InfoFunctionDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      firstTokenOffset: reader.readUInt30(),
      nameOffset2: reader.readOptionalUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(() => _InfoTypeParameter(reader)),
      parameters: reader.readTypedList(() => _InfoFormalParameter(reader)),
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoFunctionDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.firstTokenOffset,
    required this.nameOffset2,
    required this.documentationComment,
    required this.typeParameters,
    required this.parameters,
    required this.constantOffsets,
  });
}

class _InfoFunctionTypeAlias {
  final int codeOffset;
  final int codeLength;
  final int firstTokenOffset;
  final int? nameOffset2;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoFormalParameter> parameters;
  final Uint32List constantOffsets;

  factory _InfoFunctionTypeAlias(SummaryDataReader reader) {
    return _InfoFunctionTypeAlias._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      firstTokenOffset: reader.readUInt30(),
      nameOffset2: reader.readOptionalUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(() => _InfoTypeParameter(reader)),
      parameters: reader.readTypedList(() => _InfoFormalParameter(reader)),
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoFunctionTypeAlias._({
    required this.codeOffset,
    required this.codeLength,
    required this.firstTokenOffset,
    required this.nameOffset2,
    required this.documentationComment,
    required this.typeParameters,
    required this.parameters,
    required this.constantOffsets,
  });
}

class _InfoGenericTypeAlias {
  final int codeOffset;
  final int codeLength;
  final int firstTokenOffset;
  final int? nameOffset2;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoTypeParameter> aliasedTypeParameters;
  final List<_InfoFormalParameter> aliasedFormalParameters;
  final Uint32List constantOffsets;

  factory _InfoGenericTypeAlias(SummaryDataReader reader) {
    return _InfoGenericTypeAlias._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      firstTokenOffset: reader.readUInt30(),
      nameOffset2: reader.readOptionalUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(() => _InfoTypeParameter(reader)),
      aliasedTypeParameters: reader.readTypedList(
        () => _InfoTypeParameter(reader),
      ),
      aliasedFormalParameters: reader.readTypedList(
        () => _InfoFormalParameter(reader),
      ),
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoGenericTypeAlias._({
    required this.codeOffset,
    required this.codeLength,
    required this.firstTokenOffset,
    required this.nameOffset2,
    required this.documentationComment,
    required this.typeParameters,
    required this.aliasedTypeParameters,
    required this.aliasedFormalParameters,
    required this.constantOffsets,
  });
}

class _InfoImport {
  final int nameOffset;
  final int prefixOffset;
  final int? prefixOffset2;
  final List<_InfoCombinator> combinators;

  factory _InfoImport(SummaryDataReader reader) {
    return _InfoImport._(
      nameOffset: reader.readUInt30(),
      prefixOffset: reader.readUInt30() - 1,
      prefixOffset2: reader.readOptionalUInt30(),
      combinators: reader.readTypedList(() => _InfoCombinator(reader)),
    );
  }

  _InfoImport._({
    required this.nameOffset,
    required this.prefixOffset,
    required this.prefixOffset2,
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

  _InfoLibraryName._({required this.offset, required this.length});
}

class _InfoMethodDeclaration {
  final int codeOffset;
  final int codeLength;
  final int firstTokenOffset;
  final int? nameOffset2;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoFormalParameter> parameters;
  final Uint32List constantOffsets;

  factory _InfoMethodDeclaration(SummaryDataReader reader) {
    return _InfoMethodDeclaration._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      firstTokenOffset: reader.readUInt30(),
      nameOffset2: reader.readOptionalUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      typeParameters: reader.readTypedList(() => _InfoTypeParameter(reader)),
      parameters: reader.readTypedList(() => _InfoFormalParameter(reader)),
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoMethodDeclaration._({
    required this.codeOffset,
    required this.codeLength,
    required this.firstTokenOffset,
    required this.nameOffset2,
    required this.documentationComment,
    required this.typeParameters,
    required this.parameters,
    required this.constantOffsets,
  });
}

class _InfoPart {
  final int nameOffset;

  factory _InfoPart(SummaryDataReader reader) {
    return _InfoPart._(nameOffset: reader.readUInt30());
  }

  _InfoPart._({required this.nameOffset});
}

class _InformativeDataWriter {
  final BufferedSink sink;

  _InformativeDataWriter(this.sink);

  void write(CompilationUnit unit) {
    sink.writeUInt30(unit.offset);
    sink.writeUInt30(unit.length);

    sink.writeUint30List(unit.lineInfo.lineStarts);

    _writeLibraryName(unit);

    var firstDirective = unit.directives.firstOrNull;
    _writeDocumentationCommentNode(firstDirective?.documentationComment);

    sink.writeList2<ImportDirective>(unit.directives, (directive) {
      sink.writeUInt30(directive.importKeyword.offset);
      sink.writeUInt30(1 + (directive.prefix?.offset ?? -1));
      sink.writeOptionalUInt30(directive.prefix?.token.offsetIfNotEmpty);
      _writeCombinators(directive.combinators);
    });

    sink.writeList2<ExportDirective>(unit.directives, (directive) {
      sink.writeUInt30(directive.exportKeyword.offset);
      _writeCombinators(directive.combinators);
    });

    sink.writeList2<PartDirective>(unit.directives, (directive) {
      sink.writeUInt30(directive.partKeyword.offset);
    });

    sink.writeList2<ClassDeclaration>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.offset);
      sink.writeOptionalUInt30(node.name.offsetIfNotEmpty);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
      _writeConstructors(node.members);
      _writeFields(node.members);
      _writeGettersSettersMethods(node.members);
      _writeOffsets(
        metadata: node.metadata,
        typeParameters: node.typeParameters,
      );
    });

    sink.writeList2<ClassTypeAlias>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.offset);
      sink.writeOptionalUInt30(node.name.offsetIfNotEmpty);
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
      sink.writeUInt30(node.offset);
      sink.writeOptionalUInt30(node.name.offsetIfNotEmpty);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
      _writeConstructors(node.members);
      _writeEnumFields(node.constants, node.members);
      _writeGettersSettersMethods(node.members);
      _writeOffsets(
        metadata: node.metadata,
        enumConstants: node.constants,
        typeParameters: node.typeParameters,
      );
    });

    sink.writeList2<ExtensionDeclaration>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.offset);
      sink.writeOptionalUInt30(node.name?.offsetIfNotEmpty);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
      _writeConstructors(node.members);
      _writeFields(node.members);
      _writeGettersSettersMethods(node.members);
      _writeOffsets(
        metadata: node.metadata,
        typeParameters: node.typeParameters,
      );
    });

    sink.writeList2<ExtensionTypeDeclaration>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.offset);
      sink.writeOptionalUInt30(node.name.offsetIfNotEmpty);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
      _writeRepresentation(node, node.representation);
      _writeConstructors(node.members);
      _writeFields(node.members);
      _writeGettersSettersMethods(node.members);
      _writeOffsets(
        metadata: node.metadata,
        typeParameters: node.typeParameters,
      );
    });

    sink.writeList2<FunctionDeclaration>(
      unit.declarations
          .whereType<FunctionDeclaration>()
          .where((e) => e.isGetter)
          .toList(),
      (node) {
        sink.writeUInt30(node.offset);
        sink.writeUInt30(node.length);
        sink.writeUInt30(node.offset);
        sink.writeOptionalUInt30(node.name.offsetIfNotEmpty);
        _writeDocumentationComment(node);
        _writeTypeParameters(node.functionExpression.typeParameters);
        _writeFormalParameters(node.functionExpression.parameters);
        _writeOffsets(
          metadata: node.metadata,
          typeParameters: node.functionExpression.typeParameters,
          formalParameters: node.functionExpression.parameters,
        );
      },
    );

    sink.writeList2<FunctionDeclaration>(
      unit.declarations
          .whereType<FunctionDeclaration>()
          .where((e) => e.isSetter)
          .toList(),
      (node) {
        sink.writeUInt30(node.offset);
        sink.writeUInt30(node.length);
        sink.writeUInt30(node.offset);
        sink.writeOptionalUInt30(node.name.offsetIfNotEmpty);
        _writeDocumentationComment(node);
        _writeTypeParameters(node.functionExpression.typeParameters);
        _writeFormalParameters(node.functionExpression.parameters);
        _writeOffsets(
          metadata: node.metadata,
          typeParameters: node.functionExpression.typeParameters,
          formalParameters: node.functionExpression.parameters,
        );
      },
    );

    sink.writeList2<FunctionDeclaration>(
      unit.declarations
          .whereType<FunctionDeclaration>()
          .where((e) => !(e.isGetter || e.isSetter))
          .toList(),
      (node) {
        sink.writeUInt30(node.offset);
        sink.writeUInt30(node.length);
        sink.writeUInt30(node.offset);
        sink.writeOptionalUInt30(node.name.offsetIfNotEmpty);
        _writeDocumentationComment(node);
        _writeTypeParameters(node.functionExpression.typeParameters);
        _writeFormalParameters(node.functionExpression.parameters);
        _writeOffsets(
          metadata: node.metadata,
          typeParameters: node.functionExpression.typeParameters,
          formalParameters: node.functionExpression.parameters,
        );
      },
    );

    sink.writeList2<FunctionTypeAlias>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.offset);
      sink.writeOptionalUInt30(node.name.offsetIfNotEmpty);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
      _writeFormalParameters(node.parameters);
      _writeOffsets(
        metadata: node.metadata,
        typeParameters: node.typeParameters,
        formalParameters: node.parameters,
      );
    });

    sink.writeList2<GenericTypeAlias>(unit.declarations, (node) {
      var aliasedType = node.type;
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.offset);
      sink.writeOptionalUInt30(node.name.offsetIfNotEmpty);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
      if (aliasedType is GenericFunctionType) {
        _writeTypeParameters(aliasedType.typeParameters);
        _writeFormalParameters(aliasedType.parameters);
      } else {
        _writeTypeParameters(null);
        _writeFormalParameters(null);
      }
      _writeOffsets(
        metadata: node.metadata,
        typeParameters: node.typeParameters,
        aliasedType: node.type,
      );
    });

    sink.writeList2<MixinDeclaration>(unit.declarations, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.offset);
      sink.writeOptionalUInt30(node.name.offsetIfNotEmpty);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
      _writeConstructors(node.members);
      _writeFields(node.members);
      _writeGettersSettersMethods(node.members);
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
      sink.writeUInt30(node.returnType.offset);
      sink.writeOptionalUInt30(node.period?.offset);
      var nameNode = node.name ?? node.returnType;
      sink.writeUInt30(nameNode.offset);
      sink.writeOptionalUInt30(nameNode.end);
      sink.writeOptionalUInt30(node.name?.offsetIfNotEmpty);

      _writeDocumentationComment(node);
      _writeFormalParameters(node.parameters);
      _writeOffsets(
        metadata: node.metadata,
        formalParameters: node.parameters,
        constructorInitializers: node.initializers,
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

  void _writeEnumFields(
    List<EnumConstantDeclaration> constants,
    List<ClassMember> members,
  ) {
    var fields =
        members
            .whereType<FieldDeclaration>()
            .expand((declaration) => declaration.fields.variables)
            .toList();

    sink.writeUInt30(constants.length + fields.length);

    // Write constants in the same format as fields.
    for (var node in constants) {
      var codeOffset = node.offset;
      sink.writeUInt30(codeOffset);
      sink.writeUInt30(node.end - codeOffset);
      sink.writeUInt30(node.name.offset);
      sink.writeOptionalUInt30(node.name.offsetIfNotEmpty);
      _writeDocumentationComment(node);
      _writeOffsets(
        metadata: node.metadata,
        enumConstantArguments: node.arguments,
      );
    }

    for (var field in fields) {
      _writeField(field);
    }
  }

  void _writeField(VariableDeclaration node) {
    var codeOffset = _codeOffsetForVariable(node);
    sink.writeUInt30(codeOffset);
    sink.writeUInt30(node.end - codeOffset);
    sink.writeUInt30(node.name.offset);
    sink.writeOptionalUInt30(node.name.offsetIfNotEmpty);
    _writeDocumentationComment(node);

    // TODO(scheglov): Replace with some kind of double-iterating list.
    var declaration = node.parent!.parent as FieldDeclaration;

    _writeOffsets(
      metadata: declaration.metadata,
      constantInitializer: node.initializer,
    );
  }

  void _writeFields(List<ClassMember> members) {
    sink.writeList<VariableDeclaration>(
      members
          .whereType<FieldDeclaration>()
          .expand((declaration) => declaration.fields.variables)
          .toList(),
      _writeField,
    );
  }

  void _writeFormalParameters(FormalParameterList? parameterList) {
    var parameters = parameterList?.parameters ?? <FormalParameter>[];
    sink.writeList<FormalParameter>(parameters, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(1 + (node.name?.offset ?? -1));
      sink.writeOptionalUInt30(node.name?.offsetIfNotEmpty);
      var notDefault = node.notDefault;
      if (notDefault is FieldFormalParameter) {
        _writeTypeParameters(notDefault.typeParameters);
        _writeFormalParameters(notDefault.parameters);
      } else if (notDefault is FunctionTypedFormalParameter) {
        _writeTypeParameters(notDefault.typeParameters);
        _writeFormalParameters(notDefault.parameters);
      } else if (notDefault is SuperFormalParameter) {
        _writeTypeParameters(notDefault.typeParameters);
        _writeFormalParameters(notDefault.parameters);
      } else {
        _writeTypeParameters(null);
        _writeFormalParameters(null);
      }
    });
  }

  void _writeGettersSettersMethods(List<ClassMember> members) {
    var getters = <MethodDeclaration>[];
    var setters = <MethodDeclaration>[];
    var methods = <MethodDeclaration>[];
    for (var method in members.whereType<MethodDeclaration>()) {
      if (method.isGetter) {
        getters.add(method);
      } else if (method.isSetter) {
        setters.add(method);
      } else {
        methods.add(method);
      }
    }

    void writeMethodAny(MethodDeclaration node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
      sink.writeOptionalUInt30(node.name.offsetIfNotEmpty);
      _writeDocumentationComment(node);
      _writeTypeParameters(node.typeParameters);
      _writeFormalParameters(node.parameters);
      _writeOffsets(
        metadata: node.metadata,
        typeParameters: node.typeParameters,
        formalParameters: node.parameters,
      );
    }

    sink.writeList(getters, writeMethodAny);
    sink.writeList(setters, writeMethodAny);
    sink.writeList(methods, writeMethodAny);
  }

  void _writeLibraryName(CompilationUnit unit) {
    Directive? firstDirective;
    var nameOffset = -1;
    var nameLength = 0;
    for (var directive in unit.directives) {
      firstDirective ??= directive;
      if (directive is LibraryDirective) {
        var libraryName = directive.name;
        if (libraryName != null) {
          nameOffset = libraryName.offset;
          nameLength = libraryName.length;
        }
        break;
      }
    }
    sink.writeUInt30(1 + nameOffset);
    sink.writeUInt30(nameLength);
    _writeOffsets(
      metadata: firstDirective?.metadata,
      importDirectives: unit.directives.whereType<ImportDirective>(),
      exportDirectives: unit.directives.whereType<ExportDirective>(),
      partDirectives: unit.directives.whereType<PartDirective>(),
    );
  }

  void _writeOffsets({
    NodeList<Annotation>? metadata,
    Iterable<ImportDirective>? importDirectives,
    Iterable<ExportDirective>? exportDirectives,
    Iterable<PartDirective>? partDirectives,
    TypeParameterList? typeParameters,
    FormalParameterList? formalParameters,
    Expression? constantInitializer,
    NodeList<ConstructorInitializer>? constructorInitializers,
    NodeList<EnumConstantDeclaration>? enumConstants,
    TypeAnnotation? aliasedType,
    EnumConstantArguments? enumConstantArguments,
  }) {
    var collector = _OffsetsCollector();

    void addDirectives(Iterable<Directive>? directives) {
      if (directives != null) {
        for (var directive in directives) {
          directive.metadata.accept(collector);
        }
      }
    }

    void addTypeParameters(TypeParameterList? typeParameters) {
      if (typeParameters != null) {
        for (var typeParameter in typeParameters.typeParameters) {
          typeParameter.metadata.accept(collector);
        }
      }
    }

    void addFormalParameters(FormalParameterList? formalParameters) {
      if (formalParameters != null) {
        for (var parameter in formalParameters.parameters) {
          parameter.metadata.accept(collector);
          addFormalParameters(
            parameter is FunctionTypedFormalParameter
                ? parameter.parameters
                : null,
          );
          if (parameter is DefaultFormalParameter) {
            parameter.defaultValue?.accept(collector);
          }
        }
      }
    }

    metadata?.accept(collector);
    addDirectives(importDirectives);
    addDirectives(exportDirectives);
    addDirectives(partDirectives);
    addTypeParameters(typeParameters);
    addFormalParameters(formalParameters);
    constantInitializer?.accept(collector);
    constructorInitializers?.accept(collector);
    if (enumConstants != null) {
      for (var enumConstant in enumConstants) {
        enumConstant.metadata.accept(collector);
      }
    }
    if (aliasedType is GenericFunctionType) {
      addTypeParameters(aliasedType.typeParameters);
      addFormalParameters(aliasedType.parameters);
    }
    enumConstantArguments?.typeArguments?.accept(collector);
    enumConstantArguments?.argumentList.accept(collector);
    sink.writeUint30List(collector.offsets);
  }

  void _writeRepresentation(
    ExtensionTypeDeclaration declaration,
    RepresentationDeclaration node,
  ) {
    // Constructor code range.
    sink.writeUInt30(node.offset);
    sink.writeUInt30(node.length);
    sink.writeOptionalUInt30(declaration.name.offsetIfNotEmpty);

    var constructorName = node.constructorName;
    if (constructorName != null) {
      sink.writeOptionalUInt30(constructorName.period.offset);
      sink.writeUInt30(constructorName.name.offset);
      sink.writeOptionalUInt30(constructorName.name.end);
      sink.writeOptionalUInt30(constructorName.name.offsetIfNotEmpty);
    } else {
      sink.writeOptionalUInt30(null);
      sink.writeUInt30(declaration.name.offset);
      sink.writeOptionalUInt30(declaration.name.end);
      sink.writeOptionalUInt30(null);
    }

    var fieldBeginToken = node.fieldMetadata.beginToken ?? node.fieldType;
    var codeOffset = fieldBeginToken.offset;
    var codeEnd = node.fieldName.end;
    sink.writeUInt30(codeOffset);
    sink.writeUInt30(codeEnd - codeOffset);
    sink.writeUInt30(node.offset);
    sink.writeOptionalUInt30(node.fieldName.offsetIfNotEmpty);

    _writeOffsets(metadata: node.fieldMetadata);
  }

  void _writeTopLevelVariable(VariableDeclaration node) {
    var codeOffset = _codeOffsetForVariable(node);
    sink.writeUInt30(codeOffset);
    sink.writeUInt30(node.end - codeOffset);
    sink.writeUInt30(node.offset);
    sink.writeOptionalUInt30(node.name.offsetIfNotEmpty);
    _writeDocumentationComment(node);

    // TODO(scheglov): Replace with some kind of double-iterating list.
    var declaration = node.parent!.parent as TopLevelVariableDeclaration;

    _writeOffsets(
      metadata: declaration.metadata,
      constantInitializer: node.initializer,
    );
  }

  void _writeTypeParameters(TypeParameterList? parameterList) {
    var parameters = parameterList?.typeParameters ?? <TypeParameter>[];
    sink.writeList<TypeParameter>(parameters, (node) {
      sink.writeUInt30(node.offset);
      sink.writeUInt30(node.length);
      sink.writeUInt30(node.name.offset);
      sink.writeOptionalUInt30(node.name.offsetIfNotEmpty);
    });
  }
}

class _InfoTopLevelVariable {
  final int codeOffset;
  final int codeLength;
  final int firstTokenOffset;
  final int? nameOffset2;
  final String? documentationComment;
  final Uint32List constantOffsets;

  factory _InfoTopLevelVariable(SummaryDataReader reader) {
    return _InfoTopLevelVariable._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      firstTokenOffset: reader.readUInt30(),
      nameOffset2: reader.readOptionalUInt30(),
      documentationComment: reader.readStringUtf8().nullIfEmpty,
      constantOffsets: reader.readUInt30List(),
    );
  }

  _InfoTopLevelVariable._({
    required this.codeOffset,
    required this.codeLength,
    required this.firstTokenOffset,
    required this.nameOffset2,
    required this.documentationComment,
    required this.constantOffsets,
  });
}

class _InfoTypeParameter {
  final int codeOffset;
  final int codeLength;
  final int firstTokenOffset;
  final int? nameOffset2;

  factory _InfoTypeParameter(SummaryDataReader reader) {
    return _InfoTypeParameter._(
      codeOffset: reader.readUInt30(),
      codeLength: reader.readUInt30(),
      firstTokenOffset: reader.readUInt30(),
      nameOffset2: reader.readOptionalUInt30(),
    );
  }

  _InfoTypeParameter._({
    required this.codeOffset,
    required this.codeLength,
    required this.firstTokenOffset,
    required this.nameOffset2,
  });
}

class _InfoUnit {
  final int codeOffset;
  final int codeLength;
  final List<int> lineStarts;
  final _InfoLibraryName libraryName;
  final Uint32List libraryConstantOffsets;
  final String docComment;
  final List<_InfoImport> imports;
  final List<_InfoExport> exports;
  final List<_InfoPart> parts;
  final List<_InfoClassDeclaration> classDeclarations;
  final List<_InfoClassTypeAlias> classTypeAliases;
  final List<_InfoClassDeclaration> enums;
  final List<_InfoClassDeclaration> extensions;
  final List<_InfoExtensionTypeDeclaration> extensionTypes;
  final List<_InfoMethodDeclaration> getters;
  final List<_InfoMethodDeclaration> setters;
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
      libraryConstantOffsets: reader.readUInt30List(),
      docComment: reader.readStringUtf8(),
      imports: reader.readTypedList(() => _InfoImport(reader)),
      exports: reader.readTypedList(() => _InfoExport(reader)),
      parts: reader.readTypedList(() => _InfoPart(reader)),
      classDeclarations: reader.readTypedList(
        () => _InfoClassDeclaration(reader),
      ),
      classTypeAliases: reader.readTypedList(() => _InfoClassTypeAlias(reader)),
      enums: reader.readTypedList(() => _InfoClassDeclaration(reader)),
      extensions: reader.readTypedList(() => _InfoClassDeclaration(reader)),
      extensionTypes: reader.readTypedList(
        () => _InfoExtensionTypeDeclaration(reader),
      ),
      getters: reader.readTypedList(() => _InfoMethodDeclaration(reader)),
      setters: reader.readTypedList(() => _InfoMethodDeclaration(reader)),
      functions: reader.readTypedList(() => _InfoFunctionDeclaration(reader)),
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
    required this.libraryConstantOffsets,
    required this.docComment,
    required this.imports,
    required this.exports,
    required this.parts,
    required this.classDeclarations,
    required this.classTypeAliases,
    required this.enums,
    required this.extensions,
    required this.extensionTypes,
    required this.getters,
    required this.setters,
    required this.functions,
    required this.functionTypeAliases,
    required this.genericTypeAliases,
    required this.mixinDeclarations,
    required this.topLevelVariable,
  });
}

class _OffsetsApplier extends _OffsetsAstVisitor {
  final _SafeListIterator<int> _iterator;

  _OffsetsApplier(this._iterator);

  void applyToConstantInitializer(FragmentImpl element) {
    if (element is FieldFragmentImpl && element.isEnumConstant) {
      _applyToEnumConstantInitializer(element);
    } else if (element is VariableFragmentImpl) {
      element.constantInitializer?.accept(this);
    }
  }

  void applyToConstructorInitializers(ConstructorFragmentImpl element) {
    for (var initializer in element.constantInitializers) {
      initializer.accept(this);
    }
  }

  void applyToEnumConstants(List<FieldFragmentImpl> constants) {
    for (var constant in constants) {
      applyToMetadata(constant.metadata);
    }
  }

  void applyToExports(List<LibraryExportImpl> elements) {
    for (var element in elements) {
      applyToMetadata(element.metadata);
    }
  }

  void applyToFormalParameters(
    List<FormalParameterFragmentImpl> formalParameters,
  ) {
    for (var parameter in formalParameters) {
      applyToMetadata(parameter.metadata);
      applyToFormalParameters(parameter.parameters);
      applyToConstantInitializer(parameter);
    }
  }

  void applyToImports(List<LibraryImportImpl> elements) {
    for (var element in elements) {
      applyToMetadata(element.metadata);
    }
  }

  void applyToMetadata(MetadataImpl metadata) {
    for (var annotation in metadata.annotations) {
      var node = annotation.annotationAst;
      node.accept(this);
    }
  }

  void applyToParts(List<PartIncludeImpl> elements) {
    for (var element in elements) {
      applyToMetadata(element.metadata);
    }
  }

  void applyToTypeParameters(List<TypeParameterFragmentImpl> typeParameters) {
    for (var typeParameter in typeParameters) {
      applyToMetadata(typeParameter.metadata);
    }
  }

  @override
  void handleToken(Token token) {
    var offset = _iterator.take();
    if (offset != null) {
      token.offset = offset;
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // We store FunctionExpression(s) as empty stubs: `() {}`.
    // We just need it to have right code range, so we apply 2 offsets.
    node.parameters?.leftParenthesis.offset = _iterator.take() ?? 0;

    var body = node.body;
    if (body is BlockFunctionBody) {
      body.block.rightBracket.offset = _iterator.take() ?? 0;
    }
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    super.visitSimpleFormalParameter(node);

    var fragment = node.declaredFragment;
    var identifier = node.name;
    if (fragment is FormalParameterFragmentImpl && identifier != null) {
      fragment.firstTokenOffset = identifier.offset;
      fragment.nameOffset2 = identifier.offsetIfNotEmpty;
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (isNotSerializableMarker(node)) {
      return;
    }

    super.visitSimpleIdentifier(node);
  }

  void _applyToEnumConstantInitializer(FieldFragmentImpl element) {
    var initializer = element.constantInitializer;
    if (initializer is InstanceCreationExpressionImpl) {
      initializer.constructorName.type.typeArguments?.accept(this);
      initializer.argumentList.accept(this);
    }
  }
}

abstract class _OffsetsAstVisitor extends RecursiveAstVisitor<void> {
  void handleToken(Token token);

  @override
  void visitAnnotation(Annotation node) {
    _tokenOrNull(node.atSign);
    _tokenOrNull(node.period);
    super.visitAnnotation(node);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    _tokenOrNull(node.leftParenthesis);
    _tokenOrNull(node.rightParenthesis);
    super.visitArgumentList(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    _tokenOrNull(node.asOperator);
    super.visitAsExpression(node);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _tokenOrNull(node.assertKeyword);
    _tokenOrNull(node.leftParenthesis);
    _tokenOrNull(node.comma);
    _tokenOrNull(node.rightParenthesis);
    super.visitAssertInitializer(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _tokenOrNull(node.operator);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _tokenOrNull(node.operator);
    super.visitBinaryExpression(node);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _tokenOrNull(node.literal);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _tokenOrNull(node.question);
    _tokenOrNull(node.colon);
    super.visitConditionalExpression(node);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _tokenOrNull(node.thisKeyword);
    _tokenOrNull(node.equals);
    super.visitConstructorFieldInitializer(node);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    node.type.accept(this);
    _tokenOrNull(node.period);
    node.name?.accept(this);
  }

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    _tokenOrNull(node.constKeyword);
    _tokenOrNull(node.period);
    node.constructorName.accept(this);
    node.argumentList.accept(this);
  }

  /// When we read from bytes, [DotShorthandInvocation]s are not rewritten to
  /// [DotShorthandConstructorInvocation]s when they're resolved to be
  /// constructor invocations. However, since the tokens happen to be the same
  /// between the two in this case, we have the same offsets.
  @override
  void visitDotShorthandInvocation(DotShorthandInvocation node) {
    _tokenOrNull(node.period);
    node.memberName.accept(this);
    node.typeArguments?.accept(this);
    node.argumentList.accept(this);
  }

  @override
  void visitDotShorthandPropertyAccess(DotShorthandPropertyAccess node) {
    _tokenOrNull(node.period);
    node.propertyName.accept(this);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    _tokenOrNull(node.literal);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _tokenOrNull(node.leftParenthesis);
    _tokenOrNull(node.leftDelimiter);
    _tokenOrNull(node.rightDelimiter);
    _tokenOrNull(node.rightParenthesis);
    super.visitFormalParameterList(node);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    _tokenOrNull(node.functionKeyword);
    super.visitGenericFunctionType(node);
  }

  @override
  void visitIfElement(IfElement node) {
    _tokenOrNull(node.ifKeyword);
    _tokenOrNull(node.leftParenthesis);
    _tokenOrNull(node.rightParenthesis);
    _tokenOrNull(node.elseKeyword);
    super.visitIfElement(node);
  }

  @override
  void visitImportPrefixReference(ImportPrefixReference node) {
    _tokenOrNull(node.name);
    _tokenOrNull(node.period);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _tokenOrNull(node.leftBracket);
    _tokenOrNull(node.rightBracket);
    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _tokenOrNull(node.keyword);
    node.constructorName.accept(this);
    node.argumentList.accept(this);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    _tokenOrNull(node.literal);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    _tokenOrNull(node.leftBracket);
    _tokenOrNull(node.rightBracket);
    super.visitInterpolationExpression(node);
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    _tokenOrNull(node.contents);
  }

  @override
  void visitIsExpression(IsExpression node) {
    _tokenOrNull(node.isOperator);
    super.visitIsExpression(node);
  }

  @override
  void visitLabel(Label node) {
    _tokenOrNull(node.colon);
    super.visitLabel(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _tokenOrNull(node.constKeyword);
    _tokenOrNull(node.leftBracket);
    _tokenOrNull(node.rightBracket);
    super.visitListLiteral(node);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    _tokenOrNull(node.separator);
    super.visitMapLiteralEntry(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    node.target?.accept(this);
    _tokenOrNull(node.operator);
    node.methodName.accept(this);
    node.typeArguments?.accept(this);
    node.argumentList.accept(this);
  }

  @override
  void visitNamedType(NamedType node) {
    node.importPrefix?.accept(this);
    _tokenOrNull(node.name);
    node.typeArguments?.accept(this);
    _tokenOrNull(node.question);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    _tokenOrNull(node.literal);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    _tokenOrNull(node.leftParenthesis);
    _tokenOrNull(node.rightParenthesis);
    super.visitParenthesizedExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _tokenOrNull(node.operator);
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    node.prefix.accept(this);
    _tokenOrNull(node.period);
    node.identifier.accept(this);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _tokenOrNull(node.operator);
    super.visitPrefixExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    node.target?.accept(this);
    _tokenOrNull(node.operator);
    node.propertyName.accept(this);
  }

  @override
  void visitRecordLiteral(RecordLiteral node) {
    _tokenOrNull(node.constKeyword);
    _tokenOrNull(node.leftParenthesis);
    _tokenOrNull(node.rightParenthesis);
    super.visitRecordLiteral(node);
  }

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    _tokenOrNull(node.leftParenthesis);
    _tokenOrNull(node.rightParenthesis);
    _tokenOrNull(node.question);
    super.visitRecordTypeAnnotation(node);
  }

  @override
  void visitRecordTypeAnnotationNamedField(
    RecordTypeAnnotationNamedField node,
  ) {
    _tokenOrNull(node.name);
    super.visitRecordTypeAnnotationNamedField(node);
  }

  @override
  void visitRecordTypeAnnotationNamedFields(
    RecordTypeAnnotationNamedFields node,
  ) {
    _tokenOrNull(node.leftBracket);
    _tokenOrNull(node.rightBracket);
    super.visitRecordTypeAnnotationNamedFields(node);
  }

  @override
  void visitRecordTypeAnnotationPositionalField(
    RecordTypeAnnotationPositionalField node,
  ) {
    _tokenOrNull(node.name);
    super.visitRecordTypeAnnotationPositionalField(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
    _tokenOrNull(node.thisKeyword);
    _tokenOrNull(node.period);
    super.visitRedirectingConstructorInvocation(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _tokenOrNull(node.constKeyword);
    _tokenOrNull(node.leftBracket);
    _tokenOrNull(node.rightBracket);
    super.visitSetOrMapLiteral(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _tokenOrNull(node.requiredKeyword);
    _tokenOrNull(node.name);
    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _tokenOrNull(node.token);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _tokenOrNull(node.literal);
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    _tokenOrNull(node.spreadOperator);
    super.visitSpreadElement(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _tokenOrNull(node.superKeyword);
    _tokenOrNull(node.period);
    super.visitSuperConstructorInvocation(node);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    _tokenOrNull(node.superKeyword);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    _tokenOrNull(node.poundSign);
    node.components.forEach(_tokenOrNull);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _tokenOrNull(node.thisKeyword);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _tokenOrNull(node.throwKeyword);
    super.visitThrowExpression(node);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    _tokenOrNull(node.leftBracket);
    _tokenOrNull(node.rightBracket);
    super.visitTypeArgumentList(node);
  }

  void _tokenOrNull(Token? token) {
    if (token != null) {
      handleToken(token);
    }
  }
}

class _OffsetsCollector extends _OffsetsAstVisitor {
  final List<int> offsets = [];

  @override
  void handleToken(Token token) {
    offsets.add(token.offset);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    offsets.add(node.offset);
    offsets.add(node.end - 1);
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

extension on Token {
  int? get offsetIfNotEmpty {
    return lexeme.isNotEmpty ? offset : null;
  }
}

extension on String {
  String? get nullIfEmpty {
    return isNotEmpty ? this : null;
  }
}

extension _ListOfElement<T extends FragmentImpl> on List<T> {
  List<T> get notSynthetic {
    return where((e) => !e.isSynthetic).toList();
  }
}
