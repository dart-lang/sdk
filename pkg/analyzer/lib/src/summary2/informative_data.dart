// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/binary/binary_reader.dart';
import 'package:analyzer/src/binary/binary_writer.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/not_serializable_nodes.dart';
import 'package:analyzer/src/util/collection.dart';
import 'package:analyzer/src/util/comment.dart';

Uint8List writeUnitInformative(CompilationUnit unit) {
  var info = _InfoBuilder().build(unit);
  var sink = BufferedSink();
  info.write(sink);
  return sink.takeBytes();
}

class InformativeDataApplier {
  bool _shouldDeferApplyMembersOffsets = true;

  void applyFromNode(LibraryFragmentImpl fragment, CompilationUnit node) {
    _shouldDeferApplyMembersOffsets = false;
    var unitInfo = _InfoBuilder().build(node);
    _applyFromInfo(fragment, unitInfo);
  }

  void applyToLibrary(
    LinkedElementFactory elementFactory,
    LibraryElementImpl libraryElement,
    Map<Uri, Uint8List> unitsInformativeBytes,
  ) {
    if (elementFactory.isApplyingInformativeData) {
      throw StateError('Unexpected recursion.');
    }
    elementFactory.isApplyingInformativeData = true;

    for (var unitElement in libraryElement.internal.fragments) {
      var uri = unitElement.source.uri;
      if (unitsInformativeBytes[uri] case var infoBytes?) {
        _applyFromBytes(unitElement, infoBytes);
      }
    }

    elementFactory.isApplyingInformativeData = false;
  }

  void _applyFromBytes(LibraryFragmentImpl unitElement, Uint8List infoBytes) {
    var unitReader = SummaryDataReader(infoBytes);
    var unitInfo = _InfoUnit.read(unitReader);
    _applyFromInfo(unitElement, unitInfo);
  }

  void _applyFromInfo(LibraryFragmentImpl unitElement, _InfoUnit unitInfo) {
    var libraryElement = unitElement.library;
    if (identical(libraryElement.internal.firstFragment, unitElement)) {
      _applyToLibrary(libraryElement, unitInfo);
    }

    unitElement.setCodeRange(unitInfo.codeOffset, unitInfo.codeLength);
    unitElement.lineInfo = LineInfo(unitInfo.lineStarts);

    DeferredResolutionReadingMixin.withoutLoadingResolution(() {
      _applyToImports(unitElement.libraryImports, unitInfo);
      _applyToExports(unitElement.libraryExports, unitInfo);
      _applyToPartIncludes(unitElement.parts, unitInfo);
    });

    unitElement.deferConstantOffsets(unitInfo.libraryConstantOffsets, (
      applier,
    ) {
      applier.applyToImports(unitElement.libraryImports);
      applier.applyToExports(unitElement.libraryExports);
      applier.applyToParts(unitElement.parts);
    });

    _applyToAccessors(
      unitElement.getters.notSynthetic,
      unitInfo.topLevelGetters,
    );
    _applyToAccessors(
      unitElement.setters.notSynthetic,
      unitInfo.topLevelSetters,
    );

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
      unitInfo.topLevelFunctions,
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
    List<_InfoExecutableDeclaration> infoList,
  ) {
    forCorrespondingPairs(elementList.notSynthetic, infoList, (element, info) {
      element.setCodeRange(info.codeOffset, info.codeLength);
      element.firstTokenOffset = info.firstTokenOffset;
      element.nameOffset = info.nameOffset;
      element.documentationComment = info.documentationComment;

      DeferredResolutionReadingMixin.withoutLoadingResolution(() {
        _applyToFormalParameters(element.formalParameters, info.parameters);
      });

      element.deferConstantOffsets(info.constantOffsets, (applier) {
        applier.applyToMetadata(element.metadata);
        applier.applyToTypeParameters(element.typeParameters);
        applier.applyToFormalParameters(element.formalParameters);
      });
    });
  }

  void _applyToClassDeclaration(
    ClassFragmentImpl element,
    _InfoClassDeclaration info,
  ) {
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.firstTokenOffset = info.firstTokenOffset;
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;

    DeferredResolutionReadingMixin.withoutLoadingResolution(() {
      _applyToTypeParameters(element.typeParameters, info.typeParameters);
    });

    element.deferConstantOffsets(info.constantOffsets, (applier) {
      applier.applyToMetadata(element.metadata);
      applier.applyToTypeParameters(element.typeParameters);
    });

    _scheduleApplyMembersOffsets(element, () {
      DeferredResolutionReadingMixin.withoutLoadingResolution(() {
        _applyToConstructors(element.constructors, info.constructors);
        _applyToFields(element.fields, info.fields);
        _applyToAccessors(element.getters, info.getters);
        _applyToAccessors(element.setters, info.setters);
        _applyToMethods(element.methods, info.methods);
      });
    });
  }

  void _applyToClassTypeAlias(
    ClassFragmentImpl element,
    _InfoClassTypeAlias info,
  ) {
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.firstTokenOffset = info.firstTokenOffset;
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;

    DeferredResolutionReadingMixin.withoutLoadingResolution(() {
      _applyToTypeParameters(element.typeParameters, info.typeParameters);
    });

    element.deferConstantOffsets(info.constantOffsets, (applier) {
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
      element.nameOffset = info.nameOffset;
      element.documentationComment = info.documentationComment;

      DeferredResolutionReadingMixin.withoutLoadingResolution(() {
        _applyToFormalParameters(element.formalParameters, info.parameters);
      });

      element.deferConstantOffsets(info.constantOffsets, (applier) {
        applier.applyToMetadata(element.metadata);
        applier.applyToFormalParameters(element.formalParameters);
        applier.applyToConstructorInitializers(element);
      });
    });
  }

  void _applyToEnumDeclaration(
    EnumFragmentImpl element,
    _InfoEnumDeclaration info,
  ) {
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.firstTokenOffset = info.firstTokenOffset;
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;

    DeferredResolutionReadingMixin.withoutLoadingResolution(() {
      _applyToTypeParameters(element.typeParameters, info.typeParameters);
      _applyToConstructors(element.constructors, info.constructors);
      _applyToFields(element.fields, info.fields);
      _applyToAccessors(element.getters, info.getters);
      _applyToAccessors(element.setters, info.setters);
      _applyToMethods(element.methods, info.methods);
    });

    element.deferConstantOffsets(info.constantOffsets, (applier) {
      applier.applyToMetadata(element.metadata);
      applier.applyToTypeParameters(element.typeParameters);
    });
  }

  void _applyToExports(List<LibraryExportImpl> exports, _InfoUnit info) {
    forCorrespondingPairs(exports, info.exports, (element, info) {
      element.exportKeywordOffset = info.exportKeywordOffset;
      _applyToCombinators(element.combinators, info.combinators);
    });
  }

  void _applyToExtensionDeclaration(
    ExtensionFragmentImpl element,
    _InfoExtensionDeclaration info,
  ) {
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.firstTokenOffset = info.firstTokenOffset;
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;

    DeferredResolutionReadingMixin.withoutLoadingResolution(() {
      _applyToTypeParameters(element.typeParameters, info.typeParameters);
    });

    _applyToFields(element.fields, info.fields);
    _applyToAccessors(element.getters, info.getters);
    _applyToAccessors(element.setters, info.setters);
    _applyToMethods(element.methods, info.methods);

    element.deferConstantOffsets(info.constantOffsets, (applier) {
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
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;

    DeferredResolutionReadingMixin.withoutLoadingResolution(() {
      _applyToTypeParameters(element.typeParameters, info.typeParameters);
    });

    var representationField = element.fields.first;
    var infoRep = info.representation;
    representationField.firstTokenOffset = infoRep.firstTokenOffset;
    representationField.nameOffset = infoRep.fieldNameOffset;
    representationField.setCodeRange(infoRep.codeOffset, infoRep.codeLength);

    representationField.deferConstantOffsets(infoRep.fieldConstantOffsets, (
      applier,
    ) {
      applier.applyToMetadata(representationField.metadata);
    });

    DeferredResolutionReadingMixin.withoutLoadingResolution(() {
      var primaryConstructor = element.constructors.first;
      primaryConstructor.setCodeRange(infoRep.codeOffset, infoRep.codeLength);
      primaryConstructor.typeNameOffset = info.nameOffset;
      primaryConstructor.periodOffset = infoRep.constructorPeriodOffset;
      primaryConstructor.firstTokenOffset = infoRep.firstTokenOffset;
      primaryConstructor.nameOffset = infoRep.constructorNameOffset;
      primaryConstructor.nameEnd = infoRep.constructorNameEnd;

      DeferredResolutionReadingMixin.withoutLoadingResolution(() {
        var representation = primaryConstructor.formalParameters.first;
        representation.firstTokenOffset = infoRep.firstTokenOffset;
        representation.nameOffset = infoRep.fieldNameOffset;
        representation.setCodeRange(infoRep.codeOffset, infoRep.codeLength);
      });

      var restFields = element.fields.skip(1).toList();
      _applyToFields(restFields, info.fields);

      var restConstructors = element.constructors.skip(1).toList();
      _applyToConstructors(restConstructors, info.constructors);

      _applyToAccessors(element.getters, info.getters);
      _applyToAccessors(element.setters, info.setters);
      _applyToMethods(element.methods, info.methods);
    });

    element.deferConstantOffsets(info.constantOffsets, (applier) {
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
      element.nameOffset = info.nameOffset;
      element.documentationComment = info.documentationComment;

      element.deferConstantOffsets(info.constantOffsets, (applier) {
        applier.applyToMetadata(element.metadata);
        applier.applyToConstantInitializer(element);
      });
    });
  }

  void _applyToFormalParameters(
    List<FormalParameterFragmentImpl> parameters,
    List<_InfoFormalParameter> infoList,
  ) {
    parameters = parameters.where((p) => !p.isSynthetic).toList();
    forCorrespondingPairs(parameters, infoList, (element, info) {
      element.setCodeRange(info.codeOffset, info.codeLength);
      element.firstTokenOffset = info.firstTokenOffset;
      element.nameOffset = info.nameOffset;
      _applyToTypeParameters(element.typeParameters, info.typeParameters);
      _applyToFormalParameters(element.formalParameters, info.parameters);
    });
  }

  void _applyToFunctionDeclaration(
    TopLevelFunctionFragmentImpl element,
    _InfoExecutableDeclaration info,
  ) {
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.firstTokenOffset = info.firstTokenOffset;
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;

    DeferredResolutionReadingMixin.withoutLoadingResolution(() {
      _applyToTypeParameters(element.typeParameters, info.typeParameters);
      _applyToFormalParameters(element.formalParameters, info.parameters);
    });

    element.deferConstantOffsets(info.constantOffsets, (applier) {
      applier.applyToMetadata(element.metadata);
      applier.applyToTypeParameters(element.typeParameters);
      applier.applyToFormalParameters(element.formalParameters);
    });
  }

  void _applyToFunctionTypeAlias(
    TypeAliasFragmentImpl element,
    _InfoFunctionTypeAlias info,
  ) {
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.firstTokenOffset = info.firstTokenOffset;
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;

    DeferredResolutionReadingMixin.withoutLoadingResolution(() {
      _applyToTypeParameters(element.typeParameters, info.typeParameters);
      if (element.aliasedElement case GenericFunctionTypeFragmentImpl aliased) {
        _applyToFormalParameters(aliased.formalParameters, info.parameters);
      }
    });

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
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;

    DeferredResolutionReadingMixin.withoutLoadingResolution(() {
      _applyToTypeParameters(element.typeParameters, info.typeParameters);
      if (element.aliasedElement case GenericFunctionTypeFragmentImpl aliased) {
        _applyToTypeParameters(
          aliased.typeParameters,
          info.aliasedTypeParameters,
        );
        _applyToFormalParameters(
          aliased.formalParameters,
          info.aliasedFormalParameters,
        );
      }
    });

    _setupApplyConstantOffsetsForTypeAlias(
      element,
      info.constantOffsets,
      aliasedFormalParameters: info.aliasedFormalParameters,
      aliasedTypeParameters: info.aliasedTypeParameters,
    );
  }

  void _applyToImports(List<LibraryImportImpl> imports, _InfoUnit info) {
    forCorrespondingPairs(imports, info.imports, (element, info) {
      element.importKeywordOffset = info.importKeywordOffset;
      if (element.prefix case var prefixFragment?) {
        prefixFragment.nameOffset = info.prefixOffset;
        prefixFragment.offset = info.prefixOffset ?? info.importKeywordOffset;
      }
      _applyToCombinators(element.combinators, info.combinators);
    });
  }

  void _applyToLibrary(LibraryElementImpl element, _InfoUnit info) {
    element.nameOffset = info.libraryName.offset;
    element.nameLength = info.libraryName.length;
    element.documentationComment = info.docComment;

    element.deferConstantOffsets(info.libraryConstantOffsets, (applier) {
      applier.applyToMetadata(element.metadata);
    });
  }

  void _applyToMethods(
    List<MethodFragmentImpl> elementList,
    List<_InfoExecutableDeclaration> infoList,
  ) {
    forCorrespondingPairs(elementList, infoList, (element, info) {
      element.setCodeRange(info.codeOffset, info.codeLength);
      element.firstTokenOffset = info.firstTokenOffset;
      element.nameOffset = info.nameOffset;
      element.documentationComment = info.documentationComment;

      DeferredResolutionReadingMixin.withoutLoadingResolution(() {
        _applyToTypeParameters(element.typeParameters, info.typeParameters);
        _applyToFormalParameters(element.formalParameters, info.parameters);
      });

      element.deferConstantOffsets(info.constantOffsets, (applier) {
        applier.applyToMetadata(element.metadata);
        applier.applyToTypeParameters(element.typeParameters);
        applier.applyToFormalParameters(element.formalParameters);
      });
    });
  }

  void _applyToMixinDeclaration(
    MixinFragmentImpl element,
    _InfoMixinDeclaration info,
  ) {
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.firstTokenOffset = info.firstTokenOffset;
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;

    DeferredResolutionReadingMixin.withoutLoadingResolution(() {
      _applyToTypeParameters(element.typeParameters, info.typeParameters);
      _applyToConstructors(element.constructors, info.constructors);
      _applyToFields(element.fields, info.fields);
      _applyToAccessors(element.getters, info.getters);
      _applyToAccessors(element.setters, info.setters);
      _applyToMethods(element.methods, info.methods);
    });

    element.deferConstantOffsets(info.constantOffsets, (applier) {
      applier.applyToMetadata(element.metadata);
      applier.applyToTypeParameters(element.typeParameters);
    });
  }

  void _applyToPartIncludes(List<PartIncludeImpl> imports, _InfoUnit info) {
    forCorrespondingPairs(imports, info.parts, (element, info) {
      element.partKeywordOffset = info.partKeywordOffset;
    });
  }

  void _applyToTopLevelVariable(
    TopLevelVariableFragmentImpl element,
    _InfoTopLevelVariable info,
  ) {
    element.setCodeRange(info.codeOffset, info.codeLength);
    element.firstTokenOffset = info.firstTokenOffset;
    element.nameOffset = info.nameOffset;
    element.documentationComment = info.documentationComment;

    element.deferConstantOffsets(info.constantOffsets, (applier) {
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
      element.nameOffset = info.nameOffset;
    });
  }

  /// Either defer, or eagerly invoke [callback].
  void _scheduleApplyMembersOffsets(
    InstanceFragmentImpl fragment,
    void Function() callback,
  ) {
    if (_shouldDeferApplyMembersOffsets) {
      fragment.deferApplyMembersOffsets(callback);
    } else {
      callback();
    }
  }

  void _setupApplyConstantOffsetsForTypeAlias(
    TypeAliasFragmentImpl element,
    Uint32List constantOffsets, {
    List<_InfoFormalParameter>? aliasedFormalParameters,
    List<_InfoTypeParameter>? aliasedTypeParameters,
  }) {
    element.deferConstantOffsets(constantOffsets, (applier) {
      applier.applyToMetadata(element.metadata);
      applier.applyToTypeParameters(element.typeParameters);

      var aliasedElement = element.aliasedElement;
      if (aliasedElement is FunctionTypedFragmentImpl) {
        applier.applyToTypeParameters(aliasedElement.typeParameters);
        applier.applyToFormalParameters(aliasedElement.formalParameters);
        if (aliasedTypeParameters != null) {
          _applyToTypeParameters(
            aliasedElement.typeParameters,
            aliasedTypeParameters,
          );
        }
        if (aliasedFormalParameters != null) {
          _applyToFormalParameters(
            aliasedElement.formalParameters,
            aliasedFormalParameters,
          );
        }
      }
    });
  }
}

class _InfoBuilder {
  _InfoUnit build(CompilationUnit unit) {
    return _InfoUnit(
      codeOffset: unit.offset,
      codeLength: unit.length,
      lineStarts: unit.lineInfo.lineStarts,
      libraryName: _buildLibraryName(unit),
      libraryConstantOffsets: _buildLibraryConstantOffsets(unit),
      docComment: _getDocumentationComment(unit.directives.firstOrNull),
      imports: _buildImports(unit),
      exports: _buildExports(unit),
      parts: _buildParts(unit),
      classDeclarations: _buildClasses(unit),
      classTypeAliases: _buildClassTypeAliases(unit),
      enums: _buildEnums(unit),
      extensions: _buildExtensions(unit),
      extensionTypes: _buildExtensionTypes(unit),
      functionTypeAliases: _buildFunctionTypeAliases(unit),
      genericTypeAliases: _buildGenericTypeAliases(unit),
      mixinDeclarations: _buildMixins(unit),
      topLevelFunctions: _buildTopLevelFunctions(unit),
      topLevelGetters: _buildTopLevelGetters(unit),
      topLevelSetters: _buildTopLevelSetters(unit),
      topLevelVariable: _buildTopLevelVariables(unit),
    );
  }

  _InfoClassDeclaration _buildClass(ClassDeclaration node) {
    return _InfoClassDeclaration(
      data: _buildInterfaceData(
        node,
        name: node.name,
        typeParameters: node.typeParameters,
        members: node.members,
      ),
    );
  }

  List<_InfoClassDeclaration> _buildClasses(CompilationUnit unit) {
    return unit.declarations
        .whereType<ClassDeclaration>()
        .map(_buildClass)
        .toList();
  }

  _InfoClassTypeAlias _buildClassTypeAlias(ClassTypeAlias node) {
    return _InfoClassTypeAlias(
      firstTokenOffset: node.offset,
      codeOffset: node.offset,
      codeLength: node.length,
      nameOffset: node.name.offsetIfNotEmpty,
      documentationComment: _getDocumentationComment(node),
      typeParameters: _buildTypeParameters(node.typeParameters),
      constantOffsets: _buildConstantOffsets(
        metadata: node.metadata,
        typeParameters: node.typeParameters,
      ),
    );
  }

  List<_InfoClassTypeAlias> _buildClassTypeAliases(CompilationUnit unit) {
    return unit.declarations
        .whereType<ClassTypeAlias>()
        .map(_buildClassTypeAlias)
        .toList();
  }

  _InfoCombinator _buildCombinator(Combinator node) {
    return _InfoCombinator(offset: node.offset, end: node.end);
  }

  List<_InfoCombinator> _buildCombinators(List<Combinator> combinators) {
    return combinators.map(_buildCombinator).toList();
  }

  Uint32List _buildConstantOffsets({
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
    return Uint32List.fromList(collector.offsets);
  }

  _InfoConstructorDeclaration _buildConstructor(ConstructorDeclaration node) {
    return _InfoConstructorDeclaration(
      firstTokenOffset: node.offset,
      codeOffset: node.offset,
      codeLength: node.length,
      nameOffset: node.name?.offsetIfNotEmpty,
      documentationComment: _getDocumentationComment(node),
      typeParameters: const [],
      parameters: _buildFormalParameters(node.parameters),
      constantOffsets: _buildConstantOffsets(
        metadata: node.metadata,
        formalParameters: node.parameters,
        constructorInitializers: node.initializers,
      ),
      typeNameOffset: node.returnType.offset,
      periodOffset: node.period?.offset,
      nameEnd: (node.name ?? node.returnType).end,
    );
  }

  _InfoEnumDeclaration _buildEnum(EnumDeclaration node) {
    return _InfoEnumDeclaration(
      data: _buildInterfaceData(
        node,
        name: node.name,
        typeParameters: node.typeParameters,
        members: node.members,
        fields: [
          ...node.constants.map(_buildEnumConstant),
          ...node.members
              .whereType<FieldDeclaration>()
              .expand((node) => node.fields.variables)
              .map((node) => _buildField(node)),
        ],
      ),
    );
  }

  _InfoFieldDeclaration _buildEnumConstant(EnumConstantDeclaration node) {
    var codeOffset = node.offset;
    return _InfoFieldDeclaration(
      firstTokenOffset: node.offset,
      codeOffset: codeOffset,
      codeLength: node.end - codeOffset,
      nameOffset: node.name.offsetIfNotEmpty,
      documentationComment: _getDocumentationComment(node),
      constantOffsets: _buildConstantOffsets(
        metadata: node.metadata,
        enumConstantArguments: node.arguments,
      ),
    );
  }

  List<_InfoEnumDeclaration> _buildEnums(CompilationUnit unit) {
    return unit.declarations
        .whereType<EnumDeclaration>()
        .map(_buildEnum)
        .toList();
  }

  _InfoExport _buildExport(ExportDirective node) {
    return _InfoExport(
      exportKeywordOffset: node.exportKeyword.offset,
      combinators: _buildCombinators(node.combinators),
    );
  }

  List<_InfoExport> _buildExports(CompilationUnit unit) {
    return unit.directives
        .whereType<ExportDirective>()
        .map(_buildExport)
        .toList();
  }

  _InfoExtensionDeclaration _buildExtension(ExtensionDeclaration node) {
    return _InfoExtensionDeclaration(
      data: _buildInstanceData(
        node,
        name: node.name,
        typeParameters: node.typeParameters,
        members: node.members,
      ),
    );
  }

  List<_InfoExtensionDeclaration> _buildExtensions(CompilationUnit unit) {
    return unit.declarations
        .whereType<ExtensionDeclaration>()
        .map(_buildExtension)
        .toList();
  }

  _InfoExtensionTypeDeclaration _buildExtensionType(
    ExtensionTypeDeclaration node,
  ) {
    return _InfoExtensionTypeDeclaration(
      data: _buildInterfaceData(
        node,
        name: node.name,
        typeParameters: node.typeParameters,
        members: node.members,
      ),
      representation: _buildRepresentation(node.representation),
    );
  }

  List<_InfoExtensionTypeDeclaration> _buildExtensionTypes(
    CompilationUnit unit,
  ) {
    return unit.declarations
        .whereType<ExtensionTypeDeclaration>()
        .map(_buildExtensionType)
        .toList();
  }

  _InfoFieldDeclaration _buildField(VariableDeclaration node) {
    var codeOffset = _codeOffsetForVariable(node);
    var declaration = node.parent!.parent as FieldDeclaration;
    return _InfoFieldDeclaration(
      firstTokenOffset: node.offset,
      codeOffset: codeOffset,
      codeLength: node.end - codeOffset,
      nameOffset: node.name.offsetIfNotEmpty,
      documentationComment: _getDocumentationComment(node),
      constantOffsets: _buildConstantOffsets(
        metadata: declaration.metadata,
        constantInitializer: node.initializer,
      ),
    );
  }

  _InfoFormalParameter _buildFormalParameter(FormalParameter node) {
    var notDefault = node.notDefault;

    var (typeParameters, parameters) = switch (notDefault) {
      FunctionTypedFormalParameter p => (p.typeParameters, p.parameters),
      FieldFormalParameter p => (p.typeParameters, p.parameters),
      SuperFormalParameter p => (p.typeParameters, p.parameters),
      _ => (null, null),
    };

    return _InfoFormalParameter(
      firstTokenOffset: node.offset,
      codeOffset: node.offset,
      codeLength: node.length,
      nameOffset: node.name?.offsetIfNotEmpty,
      typeParameters: _buildTypeParameters(typeParameters),
      parameters: _buildFormalParameters(parameters),
    );
  }

  List<_InfoFormalParameter> _buildFormalParameters(FormalParameterList? node) {
    if (node == null) {
      return [];
    }
    return node.parameters.map(_buildFormalParameter).toList();
  }

  _InfoFunctionTypeAlias _buildFunctionTypeAlias(FunctionTypeAlias node) {
    return _InfoFunctionTypeAlias(
      firstTokenOffset: node.offset,
      codeOffset: node.offset,
      codeLength: node.length,
      nameOffset: node.name.offsetIfNotEmpty,
      documentationComment: _getDocumentationComment(node),
      typeParameters: _buildTypeParameters(node.typeParameters),
      parameters: _buildFormalParameters(node.parameters),
      constantOffsets: _buildConstantOffsets(
        metadata: node.metadata,
        typeParameters: node.typeParameters,
        formalParameters: node.parameters,
      ),
    );
  }

  List<_InfoFunctionTypeAlias> _buildFunctionTypeAliases(CompilationUnit unit) {
    return unit.declarations
        .whereType<FunctionTypeAlias>()
        .map(_buildFunctionTypeAlias)
        .toList();
  }

  _InfoGenericTypeAlias _buildGenericTypeAlias(GenericTypeAlias node) {
    var aliasedType = node.type;
    return _InfoGenericTypeAlias(
      firstTokenOffset: node.offset,
      codeOffset: node.offset,
      codeLength: node.length,
      nameOffset: node.name.offsetIfNotEmpty,
      documentationComment: _getDocumentationComment(node),
      typeParameters: _buildTypeParameters(node.typeParameters),
      aliasedTypeParameters: aliasedType is GenericFunctionType
          ? _buildTypeParameters(aliasedType.typeParameters)
          : [],
      aliasedFormalParameters: aliasedType is GenericFunctionType
          ? _buildFormalParameters(aliasedType.parameters)
          : [],
      constantOffsets: _buildConstantOffsets(
        metadata: node.metadata,
        typeParameters: node.typeParameters,
        aliasedType: node.type,
      ),
    );
  }

  List<_InfoGenericTypeAlias> _buildGenericTypeAliases(CompilationUnit unit) {
    return unit.declarations
        .whereType<GenericTypeAlias>()
        .map(_buildGenericTypeAlias)
        .toList();
  }

  _InfoImport _buildImport(ImportDirective node) {
    return _InfoImport(
      importKeywordOffset: node.importKeyword.offset,
      prefixOffset: node.prefix?.token.offsetIfNotEmpty,
      combinators: _buildCombinators(node.combinators),
    );
  }

  List<_InfoImport> _buildImports(CompilationUnit unit) {
    return unit.directives
        .whereType<ImportDirective>()
        .map(_buildImport)
        .toList();
  }

  _InstanceData _buildInstanceData(
    Declaration node, {
    required Token? name,
    required TypeParameterList? typeParameters,
    required List<ClassMember> members,
    List<_InfoFieldDeclaration>? fields,
  }) {
    var annotatedNode = node as AnnotatedNode;
    return _InstanceData(
      firstTokenOffset: node.offset,
      codeOffset: node.offset,
      codeLength: node.length,
      nameOffset: name?.offsetIfNotEmpty,
      documentationComment: _getDocumentationComment(annotatedNode),
      typeParameters: _buildTypeParameters(typeParameters),
      fields:
          fields ??
          members
              .whereType<FieldDeclaration>()
              .expand((declaration) => declaration.fields.variables)
              .map((node) => _buildField(node))
              .toList(),
      getters: members
          .whereType<MethodDeclaration>()
          .where((node) => node.isGetter)
          .map(_buildMethodDeclaration)
          .toList(),
      setters: members
          .whereType<MethodDeclaration>()
          .where((node) => node.isSetter)
          .map(_buildMethodDeclaration)
          .toList(),
      methods: members
          .whereType<MethodDeclaration>()
          .where((node) => !node.isGetter && !node.isSetter)
          .map(_buildMethodDeclaration)
          .toList(),
      constantOffsets: _buildConstantOffsets(
        metadata: annotatedNode.metadata,
        typeParameters: typeParameters,
      ),
    );
  }

  _InterfaceData _buildInterfaceData(
    Declaration node, {
    required Token? name,
    required TypeParameterList? typeParameters,
    required List<ClassMember> members,
    List<_InfoFieldDeclaration>? fields,
  }) {
    var instanceData = _buildInstanceData(
      node,
      name: name,
      typeParameters: typeParameters,
      members: members,
      fields: fields,
    );
    return _InterfaceData(
      instanceData: instanceData,
      constructors: members
          .whereType<ConstructorDeclaration>()
          .map((node) => _buildConstructor(node))
          .toList(),
    );
  }

  Uint32List _buildLibraryConstantOffsets(CompilationUnit unit) {
    Directive? firstDirective;
    for (var directive in unit.directives) {
      firstDirective ??= directive;
      if (directive is LibraryDirective) {
        break;
      }
    }
    return _buildConstantOffsets(
      metadata: firstDirective?.metadata,
      importDirectives: unit.directives.whereType<ImportDirective>(),
      exportDirectives: unit.directives.whereType<ExportDirective>(),
      partDirectives: unit.directives.whereType<PartDirective>(),
    );
  }

  _InfoLibraryName _buildLibraryName(CompilationUnit unit) {
    var nameOffset = -1;
    var nameLength = 0;
    for (var directive in unit.directives) {
      if (directive is LibraryDirective) {
        var libraryName = directive.name;
        if (libraryName != null) {
          nameOffset = libraryName.offset;
          nameLength = libraryName.length;
        }
        break;
      }
    }
    return _InfoLibraryName(offset: nameOffset, length: nameLength);
  }

  _InfoExecutableDeclaration _buildMethodDeclaration(MethodDeclaration node) {
    return _InfoExecutableDeclaration(
      firstTokenOffset: node.offset,
      codeOffset: node.offset,
      codeLength: node.length,
      nameOffset: node.name.offsetIfNotEmpty,
      documentationComment: _getDocumentationComment(node),
      typeParameters: _buildTypeParameters(node.typeParameters),
      parameters: _buildFormalParameters(node.parameters),
      constantOffsets: _buildConstantOffsets(
        metadata: node.metadata,
        typeParameters: node.typeParameters,
        formalParameters: node.parameters,
      ),
    );
  }

  _InfoMixinDeclaration _buildMixin(MixinDeclaration node) {
    return _InfoMixinDeclaration(
      data: _buildInterfaceData(
        node,
        name: node.name,
        typeParameters: node.typeParameters,
        members: node.members,
      ),
    );
  }

  List<_InfoMixinDeclaration> _buildMixins(CompilationUnit unit) {
    return unit.declarations
        .whereType<MixinDeclaration>()
        .map(_buildMixin)
        .toList();
  }

  _InfoPart _buildPart(PartDirective node) {
    return _InfoPart(partKeywordOffset: node.partKeyword.offset);
  }

  List<_InfoPart> _buildParts(CompilationUnit unit) {
    return unit.directives.whereType<PartDirective>().map(_buildPart).toList();
  }

  _InfoExtensionTypeRepresentation _buildRepresentation(
    RepresentationDeclaration node,
  ) {
    var constructorName = node.constructorName;
    return _InfoExtensionTypeRepresentation(
      firstTokenOffset: node.offset,
      codeOffset: node.offset,
      codeLength: node.length,
      constructorPeriodOffset: constructorName?.period.offset,
      constructorNameOffset: constructorName?.name.offsetIfNotEmpty,
      constructorNameEnd: node.leftParenthesis.offset,
      fieldNameOffset: node.fieldName.offsetIfNotEmpty,
      fieldConstantOffsets: _buildConstantOffsets(metadata: node.fieldMetadata),
    );
  }

  _InfoExecutableDeclaration _buildTopLevelFunction(FunctionDeclaration node) {
    return _InfoExecutableDeclaration(
      firstTokenOffset: node.offset,
      codeOffset: node.offset,
      codeLength: node.length,
      nameOffset: node.name.offsetIfNotEmpty,
      documentationComment: _getDocumentationComment(node),
      typeParameters: _buildTypeParameters(
        node.functionExpression.typeParameters,
      ),
      parameters: _buildFormalParameters(node.functionExpression.parameters),
      constantOffsets: _buildConstantOffsets(
        metadata: node.metadata,
        typeParameters: node.functionExpression.typeParameters,
        formalParameters: node.functionExpression.parameters,
      ),
    );
  }

  List<_InfoExecutableDeclaration> _buildTopLevelFunctions(
    CompilationUnit unit,
  ) {
    return unit.declarations
        .whereType<FunctionDeclaration>()
        .where((node) => !(node.isGetter || node.isSetter))
        .map(_buildTopLevelFunction)
        .toList();
  }

  List<_InfoExecutableDeclaration> _buildTopLevelGetters(CompilationUnit unit) {
    return unit.declarations
        .whereType<FunctionDeclaration>()
        .where((node) => node.isGetter)
        .map(_buildTopLevelFunction)
        .toList();
  }

  List<_InfoExecutableDeclaration> _buildTopLevelSetters(CompilationUnit unit) {
    return unit.declarations
        .whereType<FunctionDeclaration>()
        .where((node) => node.isSetter)
        .map(_buildTopLevelFunction)
        .toList();
  }

  _InfoTopLevelVariable _buildTopLevelVariable(VariableDeclaration node) {
    var codeOffset = _codeOffsetForVariable(node);
    var declaration = node.parent!.parent as TopLevelVariableDeclaration;
    return _InfoTopLevelVariable(
      firstTokenOffset: node.offset,
      codeOffset: codeOffset,
      codeLength: node.end - codeOffset,
      nameOffset: node.name.offsetIfNotEmpty,
      documentationComment: _getDocumentationComment(node),
      constantOffsets: _buildConstantOffsets(
        metadata: declaration.metadata,
        constantInitializer: node.initializer,
      ),
    );
  }

  List<_InfoTopLevelVariable> _buildTopLevelVariables(CompilationUnit unit) {
    return unit.declarations
        .whereType<TopLevelVariableDeclaration>()
        .expand((declaration) => declaration.variables.variables)
        .map(_buildTopLevelVariable)
        .toList();
  }

  _InfoTypeParameter _buildTypeParameter(TypeParameter node) {
    return _InfoTypeParameter(
      firstTokenOffset: node.offset,
      codeOffset: node.offset,
      codeLength: node.length,
      nameOffset: node.name.offsetIfNotEmpty,
    );
  }

  List<_InfoTypeParameter> _buildTypeParameters(TypeParameterList? node) {
    if (node == null) {
      return [];
    }
    return node.typeParameters.map(_buildTypeParameter).toList();
  }

  int _codeOffsetForVariable(VariableDeclaration node) {
    var codeOffset = node.offset;
    var variableList = node.parent as VariableDeclarationList;
    if (variableList.variables[0] == node) {
      codeOffset = variableList.parent!.offset;
    }
    return codeOffset;
  }

  String? _getDocumentationComment(AnnotatedNode? node) {
    var comment = node?.documentationComment;
    return getCommentNodeRawText(comment);
  }
}

class _InfoClassDeclaration extends _InfoInterfaceDeclaration {
  _InfoClassDeclaration({required super.data});

  _InfoClassDeclaration.read(super.reader) : super.read();
}

class _InfoClassTypeAlias extends _InfoNode {
  final List<_InfoTypeParameter> typeParameters;
  final Uint32List constantOffsets;

  _InfoClassTypeAlias({
    required super.firstTokenOffset,
    required super.codeOffset,
    required super.codeLength,
    required super.nameOffset,
    required super.documentationComment,
    required this.typeParameters,
    required this.constantOffsets,
  }) : super();

  _InfoClassTypeAlias.read(super.reader)
    : typeParameters = reader.readList(_InfoTypeParameter.read),
      constantOffsets = reader.readUint30List(),
      super.read();

  @override
  void write(BufferedSink sink) {
    sink.writeList(typeParameters, (v) => v.write(sink));
    sink.writeUint30List(constantOffsets);
    super.write(sink);
  }
}

class _InfoCombinator {
  final int offset;
  final int end;

  _InfoCombinator({required this.offset, required this.end});

  factory _InfoCombinator.read(SummaryDataReader reader) {
    return _InfoCombinator(
      offset: reader.readUint30(),
      end: reader.readUint30(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeUint30(offset);
    sink.writeUint30(end);
  }
}

class _InfoConstructorDeclaration extends _InfoExecutableDeclaration {
  final int typeNameOffset;
  final int? periodOffset;
  final int? nameEnd;

  _InfoConstructorDeclaration({
    required super.firstTokenOffset,
    required super.codeOffset,
    required super.codeLength,
    required super.nameOffset,
    required super.documentationComment,
    required super.typeParameters,
    required super.parameters,
    required super.constantOffsets,
    required this.typeNameOffset,
    required this.periodOffset,
    required this.nameEnd,
  });

  _InfoConstructorDeclaration.read(super.reader)
    : typeNameOffset = reader.readUint30(),
      periodOffset = reader.readOptionalUint30(),
      nameEnd = reader.readOptionalUint30(),
      super.read();

  @override
  void write(BufferedSink sink) {
    sink.writeUint30(typeNameOffset);
    sink.writeOptionalUint30(periodOffset);
    sink.writeOptionalUint30(nameEnd);
    super.write(sink);
  }
}

class _InfoEnumDeclaration extends _InfoInterfaceDeclaration {
  _InfoEnumDeclaration({required super.data});

  _InfoEnumDeclaration.read(super.reader) : super.read();
}

class _InfoExecutableDeclaration extends _InfoNode {
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoFormalParameter> parameters;
  final Uint32List constantOffsets;

  _InfoExecutableDeclaration({
    required super.firstTokenOffset,
    required super.codeOffset,
    required super.codeLength,
    required super.nameOffset,
    required super.documentationComment,
    required this.typeParameters,
    required this.parameters,
    required this.constantOffsets,
  }) : super();

  _InfoExecutableDeclaration.read(super.reader)
    : typeParameters = reader.readList(_InfoTypeParameter.read),
      parameters = reader.readList(_InfoFormalParameter.read),
      constantOffsets = reader.readUint30List(),
      super.read();

  @override
  void write(BufferedSink sink) {
    sink.writeList(typeParameters, (v) => v.write(sink));
    sink.writeList(parameters, (v) => v.write(sink));
    sink.writeUint30List(constantOffsets);
    super.write(sink);
  }
}

class _InfoExport {
  final int exportKeywordOffset;
  final List<_InfoCombinator> combinators;

  _InfoExport({required this.exportKeywordOffset, required this.combinators});

  factory _InfoExport.read(SummaryDataReader reader) {
    return _InfoExport(
      exportKeywordOffset: reader.readUint30(),
      combinators: reader.readList(_InfoCombinator.read),
    );
  }

  void write(BufferedSink sink) {
    sink.writeUint30(exportKeywordOffset);
    sink.writeList(combinators, (v) => v.write(sink));
  }
}

class _InfoExtensionDeclaration extends _InfoInstanceDeclaration {
  _InfoExtensionDeclaration({required super.data});

  _InfoExtensionDeclaration.read(super.reader) : super.read();
}

class _InfoExtensionTypeDeclaration extends _InfoInterfaceDeclaration {
  final _InfoExtensionTypeRepresentation representation;

  _InfoExtensionTypeDeclaration({
    required super.data,
    required this.representation,
  });

  _InfoExtensionTypeDeclaration.read(super.reader)
    : representation = _InfoExtensionTypeRepresentation.read(reader),
      super.read();

  @override
  void write(BufferedSink sink) {
    representation.write(sink);
    super.write(sink);
  }
}

class _InfoExtensionTypeRepresentation {
  final int firstTokenOffset;
  final int codeOffset;
  final int codeLength;
  final int? constructorPeriodOffset;
  final int? constructorNameOffset;
  final int? constructorNameEnd;
  final int? fieldNameOffset;
  final Uint32List fieldConstantOffsets;

  _InfoExtensionTypeRepresentation({
    required this.firstTokenOffset,
    required this.codeOffset,
    required this.codeLength,
    required this.constructorPeriodOffset,
    required this.constructorNameOffset,
    required this.constructorNameEnd,
    required this.fieldNameOffset,
    required this.fieldConstantOffsets,
  });

  factory _InfoExtensionTypeRepresentation.read(SummaryDataReader reader) {
    return _InfoExtensionTypeRepresentation(
      firstTokenOffset: reader.readUint30(),
      codeOffset: reader.readUint30(),
      codeLength: reader.readUint30(),
      constructorPeriodOffset: reader.readOptionalUint30(),
      constructorNameOffset: reader.readOptionalUint30(),
      constructorNameEnd: reader.readOptionalUint30(),
      fieldNameOffset: reader.readOptionalUint30(),
      fieldConstantOffsets: reader.readUint30List(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeUint30(firstTokenOffset);
    sink.writeUint30(codeOffset);
    sink.writeUint30(codeLength);
    sink.writeOptionalUint30(constructorPeriodOffset);
    sink.writeOptionalUint30(constructorNameOffset);
    sink.writeOptionalUint30(constructorNameEnd);
    sink.writeOptionalUint30(fieldNameOffset);
    sink.writeUint30List(fieldConstantOffsets);
  }
}

class _InfoFieldDeclaration extends _InfoNode {
  final Uint32List constantOffsets;

  _InfoFieldDeclaration({
    required super.firstTokenOffset,
    required super.codeOffset,
    required super.codeLength,
    required super.nameOffset,
    required super.documentationComment,
    required this.constantOffsets,
  }) : super();

  _InfoFieldDeclaration.read(super.reader)
    : constantOffsets = reader.readUint30List(),
      super.read();

  @override
  void write(BufferedSink sink) {
    sink.writeUint30List(constantOffsets);
    super.write(sink);
  }
}

class _InfoFormalParameter extends _InfoNode {
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoFormalParameter> parameters;

  _InfoFormalParameter({
    required super.firstTokenOffset,
    required super.codeOffset,
    required super.codeLength,
    required super.nameOffset,
    required this.typeParameters,
    required this.parameters,
  }) : super(documentationComment: null);

  _InfoFormalParameter.read(super.reader)
    : typeParameters = reader.readList(_InfoTypeParameter.read),
      parameters = reader.readList(_InfoFormalParameter.read),
      super.read();

  @override
  void write(BufferedSink sink) {
    sink.writeList(typeParameters, (v) => v.write(sink));
    sink.writeList(parameters, (v) => v.write(sink));
    super.write(sink);
  }
}

class _InfoFunctionTypeAlias extends _InfoNode {
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoFormalParameter> parameters;
  final Uint32List constantOffsets;

  _InfoFunctionTypeAlias({
    required super.firstTokenOffset,
    required super.codeOffset,
    required super.codeLength,
    required super.nameOffset,
    required super.documentationComment,
    required this.typeParameters,
    required this.parameters,
    required this.constantOffsets,
  }) : super();

  _InfoFunctionTypeAlias.read(super.reader)
    : typeParameters = reader.readList(_InfoTypeParameter.read),
      parameters = reader.readList(_InfoFormalParameter.read),
      constantOffsets = reader.readUint30List(),
      super.read();

  @override
  void write(BufferedSink sink) {
    sink.writeList(typeParameters, (v) => v.write(sink));
    sink.writeList(parameters, (v) => v.write(sink));
    sink.writeUint30List(constantOffsets);
    super.write(sink);
  }
}

class _InfoGenericTypeAlias extends _InfoNode {
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoTypeParameter> aliasedTypeParameters;
  final List<_InfoFormalParameter> aliasedFormalParameters;
  final Uint32List constantOffsets;

  _InfoGenericTypeAlias({
    required super.firstTokenOffset,
    required super.codeOffset,
    required super.codeLength,
    required super.nameOffset,
    required super.documentationComment,
    required this.typeParameters,
    required this.aliasedTypeParameters,
    required this.aliasedFormalParameters,
    required this.constantOffsets,
  }) : super();

  _InfoGenericTypeAlias.read(super.reader)
    : typeParameters = reader.readList(_InfoTypeParameter.read),
      aliasedTypeParameters = reader.readList(_InfoTypeParameter.read),
      aliasedFormalParameters = reader.readList(_InfoFormalParameter.read),
      constantOffsets = reader.readUint30List(),
      super.read();

  @override
  void write(BufferedSink sink) {
    sink.writeList(typeParameters, (v) => v.write(sink));
    sink.writeList(aliasedTypeParameters, (v) => v.write(sink));
    sink.writeList(aliasedFormalParameters, (v) => v.write(sink));
    sink.writeUint30List(constantOffsets);
    super.write(sink);
  }
}

class _InfoImport {
  final int importKeywordOffset;
  final int? prefixOffset;
  final List<_InfoCombinator> combinators;

  _InfoImport({
    required this.importKeywordOffset,
    required this.prefixOffset,
    required this.combinators,
  });

  factory _InfoImport.read(SummaryDataReader reader) {
    return _InfoImport(
      importKeywordOffset: reader.readUint30(),
      prefixOffset: reader.readOptionalUint30(),
      combinators: reader.readList(_InfoCombinator.read),
    );
  }

  void write(BufferedSink sink) {
    sink.writeUint30(importKeywordOffset);
    sink.writeOptionalUint30(prefixOffset);
    sink.writeList(combinators, (v) => v.write(sink));
  }
}

abstract class _InfoInstanceDeclaration extends _InfoNode {
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoFieldDeclaration> fields;
  final List<_InfoExecutableDeclaration> getters;
  final List<_InfoExecutableDeclaration> setters;
  final List<_InfoExecutableDeclaration> methods;
  final Uint32List constantOffsets;

  _InfoInstanceDeclaration({required _InstanceData data})
    : typeParameters = data.typeParameters,
      fields = data.fields,
      getters = data.getters,
      setters = data.setters,
      methods = data.methods,
      constantOffsets = data.constantOffsets,
      super(
        codeOffset: data.codeOffset,
        codeLength: data.codeLength,
        firstTokenOffset: data.firstTokenOffset,
        nameOffset: data.nameOffset,
        documentationComment: data.documentationComment,
      );

  _InfoInstanceDeclaration.read(super.reader)
    : typeParameters = reader.readList(_InfoTypeParameter.read),
      fields = reader.readList(_InfoFieldDeclaration.read),
      getters = reader.readList(_InfoExecutableDeclaration.read),
      setters = reader.readList(_InfoExecutableDeclaration.read),
      methods = reader.readList(_InfoExecutableDeclaration.read),
      constantOffsets = reader.readUint30List(),
      super.read();

  @override
  void write(BufferedSink sink) {
    sink.writeList(typeParameters, (v) => v.write(sink));
    sink.writeList(fields, (v) => v.write(sink));
    sink.writeList(getters, (v) => v.write(sink));
    sink.writeList(setters, (v) => v.write(sink));
    sink.writeList(methods, (v) => v.write(sink));
    sink.writeUint30List(constantOffsets);
    super.write(sink);
  }
}

abstract class _InfoInterfaceDeclaration extends _InfoInstanceDeclaration {
  final List<_InfoConstructorDeclaration> constructors;

  _InfoInterfaceDeclaration({required _InterfaceData data})
    : constructors = data.constructors,
      super(data: data.instanceData);

  _InfoInterfaceDeclaration.read(super.reader)
    : constructors = reader.readList(_InfoConstructorDeclaration.read),
      super.read();

  @override
  void write(BufferedSink sink) {
    sink.writeList(constructors, (v) => v.write(sink));
    super.write(sink);
  }
}

class _InfoLibraryName {
  final int offset;
  final int length;

  _InfoLibraryName({required this.offset, required this.length});

  factory _InfoLibraryName.read(SummaryDataReader reader) {
    return _InfoLibraryName(
      offset: reader.readUint30() - 1,
      length: reader.readUint30(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeUint30(offset + 1);
    sink.writeUint30(length);
  }
}

class _InfoMixinDeclaration extends _InfoInterfaceDeclaration {
  _InfoMixinDeclaration({required super.data});

  _InfoMixinDeclaration.read(super.reader) : super.read();
}

abstract class _InfoNode {
  final int firstTokenOffset;
  final int codeOffset;
  final int codeLength;
  final int? nameOffset;
  final String? documentationComment;

  _InfoNode({
    required this.firstTokenOffset,
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
  });

  _InfoNode.read(SummaryDataReader reader)
    : firstTokenOffset = reader.readUint30(),
      codeOffset = reader.readUint30(),
      codeLength = reader.readUint30(),
      nameOffset = reader.readOptionalUint30(),
      documentationComment = reader.readStringUtf8().nullIfEmpty;

  void write(BufferedSink sink) {
    sink.writeUint30(firstTokenOffset);
    sink.writeUint30(codeOffset);
    sink.writeUint30(codeLength);
    sink.writeOptionalUint30(nameOffset);
    sink.writeStringUtf8(documentationComment ?? '');
  }
}

class _InfoPart {
  final int partKeywordOffset;

  _InfoPart({required this.partKeywordOffset});

  factory _InfoPart.read(SummaryDataReader reader) {
    return _InfoPart(partKeywordOffset: reader.readUint30());
  }

  void write(BufferedSink sink) {
    sink.writeUint30(partKeywordOffset);
  }
}

class _InfoTopLevelVariable extends _InfoNode {
  final Uint32List constantOffsets;

  _InfoTopLevelVariable({
    required super.firstTokenOffset,
    required super.codeOffset,
    required super.codeLength,
    required super.nameOffset,
    required super.documentationComment,
    required this.constantOffsets,
  }) : super();

  _InfoTopLevelVariable.read(super.reader)
    : constantOffsets = reader.readUint30List(),
      super.read();

  @override
  void write(BufferedSink sink) {
    sink.writeUint30List(constantOffsets);
    super.write(sink);
  }
}

class _InfoTypeParameter extends _InfoNode {
  _InfoTypeParameter({
    required super.firstTokenOffset,
    required super.codeOffset,
    required super.codeLength,
    required super.nameOffset,
  }) : super(documentationComment: null);

  _InfoTypeParameter.read(super.reader) : super.read();
}

class _InfoUnit {
  final int codeOffset;
  final int codeLength;
  final List<int> lineStarts;
  final _InfoLibraryName libraryName;
  final Uint32List libraryConstantOffsets;
  final String? docComment;
  final List<_InfoImport> imports;
  final List<_InfoExport> exports;
  final List<_InfoPart> parts;
  final List<_InfoClassDeclaration> classDeclarations;
  final List<_InfoClassTypeAlias> classTypeAliases;
  final List<_InfoEnumDeclaration> enums;
  final List<_InfoExtensionDeclaration> extensions;
  final List<_InfoExtensionTypeDeclaration> extensionTypes;
  final List<_InfoFunctionTypeAlias> functionTypeAliases;
  final List<_InfoGenericTypeAlias> genericTypeAliases;
  final List<_InfoMixinDeclaration> mixinDeclarations;
  final List<_InfoExecutableDeclaration> topLevelFunctions;
  final List<_InfoExecutableDeclaration> topLevelGetters;
  final List<_InfoExecutableDeclaration> topLevelSetters;
  final List<_InfoTopLevelVariable> topLevelVariable;

  _InfoUnit({
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
    required this.functionTypeAliases,
    required this.genericTypeAliases,
    required this.mixinDeclarations,
    required this.topLevelFunctions,
    required this.topLevelGetters,
    required this.topLevelSetters,
    required this.topLevelVariable,
  });

  _InfoUnit.read(SummaryDataReader reader)
    : codeOffset = reader.readUint30(),
      codeLength = reader.readUint30(),
      lineStarts = reader.readUint30List(),
      libraryName = _InfoLibraryName.read(reader),
      libraryConstantOffsets = reader.readUint30List(),
      docComment = reader.readOptionalStringUtf8(),
      imports = reader.readList(_InfoImport.read),
      exports = reader.readList(_InfoExport.read),
      parts = reader.readList(_InfoPart.read),
      classDeclarations = reader.readList(_InfoClassDeclaration.read),
      classTypeAliases = reader.readList(_InfoClassTypeAlias.read),
      enums = reader.readList(_InfoEnumDeclaration.read),
      extensions = reader.readList(_InfoExtensionDeclaration.read),
      extensionTypes = reader.readList(_InfoExtensionTypeDeclaration.read),
      functionTypeAliases = reader.readList(_InfoFunctionTypeAlias.read),
      genericTypeAliases = reader.readList(_InfoGenericTypeAlias.read),
      mixinDeclarations = reader.readList(_InfoMixinDeclaration.read),
      topLevelFunctions = reader.readList(_InfoExecutableDeclaration.read),
      topLevelGetters = reader.readList(_InfoExecutableDeclaration.read),
      topLevelSetters = reader.readList(_InfoExecutableDeclaration.read),
      topLevelVariable = reader.readList(_InfoTopLevelVariable.read);

  void write(BufferedSink sink) {
    sink.writeUint30(codeOffset);
    sink.writeUint30(codeLength);
    sink.writeUint30List(lineStarts);
    libraryName.write(sink);
    sink.writeUint30List(libraryConstantOffsets);
    sink.writeOptionalStringUtf8(docComment);
    sink.writeList(imports, (v) => v.write(sink));
    sink.writeList(exports, (v) => v.write(sink));
    sink.writeList(parts, (v) => v.write(sink));
    sink.writeList(classDeclarations, (v) => v.write(sink));
    sink.writeList(classTypeAliases, (v) => v.write(sink));
    sink.writeList(enums, (v) => v.write(sink));
    sink.writeList(extensions, (v) => v.write(sink));
    sink.writeList(extensionTypes, (v) => v.write(sink));
    sink.writeList(functionTypeAliases, (v) => v.write(sink));
    sink.writeList(genericTypeAliases, (v) => v.write(sink));
    sink.writeList(mixinDeclarations, (v) => v.write(sink));
    sink.writeList(topLevelFunctions, (v) => v.write(sink));
    sink.writeList(topLevelGetters, (v) => v.write(sink));
    sink.writeList(topLevelSetters, (v) => v.write(sink));
    sink.writeList(topLevelVariable, (v) => v.write(sink));
  }
}

class _InstanceData {
  final int firstTokenOffset;
  final int codeOffset;
  final int codeLength;
  final int? nameOffset;
  final String? documentationComment;
  final List<_InfoTypeParameter> typeParameters;
  final List<_InfoFieldDeclaration> fields;
  final List<_InfoExecutableDeclaration> getters;
  final List<_InfoExecutableDeclaration> setters;
  final List<_InfoExecutableDeclaration> methods;
  final Uint32List constantOffsets;

  _InstanceData({
    required this.firstTokenOffset,
    required this.codeOffset,
    required this.codeLength,
    required this.nameOffset,
    required this.documentationComment,
    required this.typeParameters,
    required this.fields,
    required this.getters,
    required this.setters,
    required this.methods,
    required this.constantOffsets,
  });
}

class _InterfaceData {
  final _InstanceData instanceData;
  final List<_InfoConstructorDeclaration> constructors;

  _InterfaceData({required this.instanceData, required this.constructors});
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
    for (var formalParameters in formalParameters) {
      applyToMetadata(formalParameters.metadata);
      applyToFormalParameters(formalParameters.formalParameters);
      applyToConstantInitializer(formalParameters);
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
      fragment.nameOffset = identifier.offsetIfNotEmpty;
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

extension on SummaryDataReader {
  List<T> readList<T>(T Function(SummaryDataReader) read) {
    return readTypedList(() => read(this));
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

extension on DeferredResolutionReadingMixin {
  /// We want to have actual offsets for tokens of various constants in the
  /// element model, such as metadata and constant initializers. But we read
  /// these additional pieces of resolution data later, on demand. So, these
  /// offsets are different from `nameOffset` for example, which are applied
  /// directly after creating corresponding elements during a library loading.
  void deferConstantOffsets(
    Uint32List constantOffsets,
    void Function(_OffsetsApplier applier) callback,
  ) {
    deferResolutionConstantOffsets(() {
      var applier = _OffsetsApplier(_SafeListIterator(constantOffsets));
      callback(applier);
    });
  }
}

extension _ListOfElement<T extends FragmentImpl> on List<T> {
  List<T> get notSynthetic {
    return where((e) => !e.isSynthetic).toList();
  }
}
