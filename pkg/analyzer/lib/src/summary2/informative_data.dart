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
import 'package:analyzer/src/utilities/extensions/object.dart';

Uint8List writeUnitInformative(CompilationUnit unit) {
  var info = _InfoBuilder().build(unit);
  var writer = BinaryWriter();
  info.write(writer);
  return writer.takeBytes();
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

    for (var libraryFragment in libraryElement.internal.fragments) {
      var uri = libraryFragment.source.uri;
      if (unitsInformativeBytes[uri] case var infoBytes?) {
        _applyFromBytes(libraryFragment, infoBytes);
      }
    }

    elementFactory.isApplyingInformativeData = false;
  }

  void _applyFromBytes(
    LibraryFragmentImpl libraryFragment,
    Uint8List infoBytes,
  ) {
    var unitReader = BinaryReader(infoBytes);
    var unitInfo = _InfoUnit.read(unitReader);
    _applyFromInfo(libraryFragment, unitInfo);
  }

  void _applyFromInfo(LibraryFragmentImpl libraryFragment, _InfoUnit unitInfo) {
    var libraryElement = libraryFragment.library;
    if (identical(libraryElement.internal.firstFragment, libraryFragment)) {
      _applyToLibrary(libraryElement, unitInfo);
    }

    libraryFragment.setCodeRange(unitInfo.codeOffset, unitInfo.codeLength);
    libraryFragment.lineInfo = LineInfo(unitInfo.lineStarts);

    DeferredResolutionReadingHelper.withoutLoadingResolution(() {
      _applyToImports(libraryFragment.libraryImports, unitInfo);
      _applyToExports(libraryFragment.libraryExports, unitInfo);
      _applyToPartIncludes(libraryFragment.parts, unitInfo);
    });

    libraryFragment.deferConstantOffsets(unitInfo.libraryConstantOffsets, (
      applier,
    ) {
      applier.applyToImports(libraryFragment.libraryImports);
      applier.applyToExports(libraryFragment.libraryExports);
      applier.applyToParts(libraryFragment.parts);
    });

    _applyToAccessors(libraryFragment.getters, unitInfo.topLevelGetters);
    _applyToAccessors(libraryFragment.setters, unitInfo.topLevelSetters);

    forCorrespondingPairs(
      libraryFragment.classes.where((fragment) => !fragment.isMixinApplication),
      unitInfo.classDeclarations,
      _applyToClassDeclaration,
    );

    forCorrespondingPairs(
      libraryFragment.classes.where((fragment) => fragment.isMixinApplication),
      unitInfo.classTypeAliases,
      _applyToClassTypeAlias,
    );

    forCorrespondingPairs(
      libraryFragment.enums,
      unitInfo.enums,
      _applyToEnumDeclaration,
    );

    forCorrespondingPairs(
      libraryFragment.extensions,
      unitInfo.extensions,
      _applyToExtensionDeclaration,
    );

    forCorrespondingPairs(
      libraryFragment.extensionTypes,
      unitInfo.extensionTypes,
      _applyToExtensionTypeDeclaration,
    );

    forCorrespondingPairs(
      libraryFragment.functions,
      unitInfo.topLevelFunctions,
      _applyToFunctionDeclaration,
    );

    forCorrespondingPairs(
      libraryFragment.mixins,
      unitInfo.mixinDeclarations,
      _applyToMixinDeclaration,
    );

    forCorrespondingPairs(
      libraryFragment.topLevelVariables.withOriginDeclaration,
      unitInfo.topLevelVariable,
      _applyToTopLevelVariable,
    );

    forCorrespondingPairs(
      libraryFragment.typeAliases,
      unitInfo.typeAliases,
      _applyToTypeAlias,
    );
  }

  /// This calls `withOriginDeclaration` on [fragmentList].
  void _applyToAccessors(
    List<PropertyAccessorFragmentImpl> fragmentList,
    List<_InfoExecutableDeclaration> infoList,
  ) {
    forCorrespondingPairs(fragmentList.withOriginDeclaration, infoList, (
      fragment,
      info,
    ) {
      fragment.setCodeRange(info.codeOffset, info.codeLength);
      fragment.firstTokenOffset = info.firstTokenOffset;
      fragment.nameOffset = info.nameOffset;
      fragment.documentationComment = info.documentationComment;

      DeferredResolutionReadingHelper.withoutLoadingResolution(() {
        _applyToFormalParameters(fragment.formalParameters, info.parameters);
      });

      fragment.deferConstantOffsets(info.constantOffsets, (applier) {
        applier.applyToMetadata(fragment.metadata);
        applier.applyToTypeParameters(fragment.typeParameters);
        applier.applyToFormalParameters(fragment.formalParameters);
      });
    });
  }

  void _applyToClassDeclaration(
    ClassFragmentImpl fragment,
    _InfoClassDeclaration info,
  ) {
    fragment.setCodeRange(info.codeOffset, info.codeLength);
    fragment.firstTokenOffset = info.firstTokenOffset;
    fragment.nameOffset = info.nameOffset;
    fragment.documentationComment = info.documentationComment;

    DeferredResolutionReadingHelper.withoutLoadingResolution(() {
      _applyToTypeParameters(fragment.typeParameters, info.typeParameters);
    });

    fragment.deferConstantOffsets(info.constantOffsets, (applier) {
      applier.applyToMetadata(fragment.metadata);
      applier.applyToTypeParameters(fragment.typeParameters);
    });

    _scheduleApplyMembersOffsets(fragment, () {
      DeferredResolutionReadingHelper.withoutLoadingResolution(() {
        _applyToConstructors(fragment.constructors, info.constructors);
        _applyToFields(fragment.fields, info.fields);
        _applyToAccessors(fragment.getters, info.getters);
        _applyToAccessors(fragment.setters, info.setters);
        _applyToMethods(fragment.methods, info.methods);
      });
    });
  }

  void _applyToClassTypeAlias(
    ClassFragmentImpl fragment,
    _InfoClassTypeAlias info,
  ) {
    fragment.setCodeRange(info.codeOffset, info.codeLength);
    fragment.firstTokenOffset = info.firstTokenOffset;
    fragment.nameOffset = info.nameOffset;
    fragment.documentationComment = info.documentationComment;

    DeferredResolutionReadingHelper.withoutLoadingResolution(() {
      _applyToTypeParameters(fragment.typeParameters, info.typeParameters);
    });

    fragment.deferConstantOffsets(info.constantOffsets, (applier) {
      applier.applyToMetadata(fragment.metadata);
      applier.applyToTypeParameters(fragment.typeParameters);
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
    List<ConstructorFragmentImpl> fragmentList,
    List<_InfoConstructorDeclaration> infoList,
  ) {
    forCorrespondingPairs(fragmentList, infoList, (fragment, info) {
      fragment.setCodeRange(info.codeOffset, info.codeLength);
      fragment.newKeywordOffset = info.newKeywordOffset;
      fragment.factoryKeywordOffset = info.factoryKeywordOffset;
      fragment.typeNameOffset = info.typeNameOffset;
      fragment.periodOffset = info.periodOffset;
      fragment.firstTokenOffset = info.firstTokenOffset;
      fragment.nameEnd = info.nameEnd;
      fragment.nameOffset = info.nameOffset;
      fragment.thisKeywordOffset = info.thisKeywordOffset;
      fragment.documentationComment = info.documentationComment;

      DeferredResolutionReadingHelper.withoutLoadingResolution(() {
        _applyToFormalParameters(fragment.formalParameters, info.parameters);
      });

      fragment.deferConstantOffsets(info.constantOffsets, (applier) {
        applier.applyToMetadata(fragment.metadata);
        applier.applyToFormalParameters(fragment.formalParameters);
        applier.applyToConstructorInitializers(fragment);
      });
    });
  }

  void _applyToEnumDeclaration(
    EnumFragmentImpl fragment,
    _InfoEnumDeclaration info,
  ) {
    fragment.setCodeRange(info.codeOffset, info.codeLength);
    fragment.firstTokenOffset = info.firstTokenOffset;
    fragment.nameOffset = info.nameOffset;
    fragment.documentationComment = info.documentationComment;

    DeferredResolutionReadingHelper.withoutLoadingResolution(() {
      _applyToTypeParameters(fragment.typeParameters, info.typeParameters);
    });

    _scheduleApplyMembersOffsets(fragment, () {
      DeferredResolutionReadingHelper.withoutLoadingResolution(() {
        _applyToConstructors(fragment.constructors, info.constructors);
        _applyToFields(fragment.fields, info.fields);
        _applyToAccessors(fragment.getters, info.getters);
        _applyToAccessors(fragment.setters, info.setters);
        _applyToMethods(fragment.methods, info.methods);
      });
    });

    fragment.deferConstantOffsets(info.constantOffsets, (applier) {
      applier.applyToMetadata(fragment.metadata);
      applier.applyToTypeParameters(fragment.typeParameters);
    });
  }

  void _applyToExports(List<LibraryExportImpl> exports, _InfoUnit info) {
    forCorrespondingPairs(exports, info.exports, (element, info) {
      element.exportKeywordOffset = info.exportKeywordOffset;
      _applyToCombinators(element.combinators, info.combinators);
    });
  }

  void _applyToExtensionDeclaration(
    ExtensionFragmentImpl fragment,
    _InfoExtensionDeclaration info,
  ) {
    fragment.setCodeRange(info.codeOffset, info.codeLength);
    fragment.firstTokenOffset = info.firstTokenOffset;
    fragment.nameOffset = info.nameOffset;
    fragment.documentationComment = info.documentationComment;

    DeferredResolutionReadingHelper.withoutLoadingResolution(() {
      _applyToTypeParameters(fragment.typeParameters, info.typeParameters);
    });

    _scheduleApplyMembersOffsets(fragment, () {
      DeferredResolutionReadingHelper.withoutLoadingResolution(() {
        _applyToFields(fragment.fields, info.fields);
        _applyToAccessors(fragment.getters, info.getters);
        _applyToAccessors(fragment.setters, info.setters);
        _applyToMethods(fragment.methods, info.methods);
      });
    });

    fragment.deferConstantOffsets(info.constantOffsets, (applier) {
      applier.applyToMetadata(fragment.metadata);
      applier.applyToTypeParameters(fragment.typeParameters);
    });
  }

  void _applyToExtensionTypeDeclaration(
    ExtensionTypeFragmentImpl fragment,
    _InfoExtensionTypeDeclaration info,
  ) {
    fragment.setCodeRange(info.codeOffset, info.codeLength);
    fragment.firstTokenOffset = info.firstTokenOffset;
    fragment.nameOffset = info.nameOffset;
    fragment.documentationComment = info.documentationComment;

    DeferredResolutionReadingHelper.withoutLoadingResolution(() {
      _applyToTypeParameters(fragment.typeParameters, info.typeParameters);
    });

    _scheduleApplyMembersOffsets(fragment, () {
      DeferredResolutionReadingHelper.withoutLoadingResolution(() {
        _applyToFields(fragment.fields, info.fields);
        _applyToConstructors(fragment.constructors, info.constructors);
        _applyToAccessors(fragment.getters, info.getters);
        _applyToAccessors(fragment.setters, info.setters);
        _applyToMethods(fragment.methods, info.methods);
      });
    });

    fragment.deferConstantOffsets(info.constantOffsets, (applier) {
      applier.applyToMetadata(fragment.metadata);
      applier.applyToTypeParameters(fragment.typeParameters);
    });
  }

  void _applyToFields(
    List<FieldFragmentImpl> fragmentList,
    List<_InfoFieldDeclaration> infoList,
  ) {
    forCorrespondingPairs(fragmentList.withOriginDeclaration, infoList, (
      fragment,
      info,
    ) {
      fragment.setCodeRange(info.codeOffset, info.codeLength);
      fragment.firstTokenOffset = info.firstTokenOffset;
      fragment.nameOffset = info.nameOffset;
      fragment.documentationComment = info.documentationComment;

      fragment.deferConstantOffsets(info.constantOffsets, (applier) {
        applier.applyToMetadata(fragment.metadata);
        applier.applyToConstantInitializer(fragment);
      });
    });
  }

  void _applyToFormalParameters(
    List<FormalParameterFragmentImpl> parameters,
    List<_InfoFormalParameter> infoList,
  ) {
    forCorrespondingPairs(
      parameters.where((p) => p.isOriginDeclaration),
      infoList,
      (fragment, info) {
        fragment.setCodeRange(info.codeOffset, info.codeLength);
        fragment.firstTokenOffset = info.firstTokenOffset;
        fragment.nameOffset = info.nameOffset;
        fragment.documentationComment = info.documentationComment;
        _applyToTypeParameters(fragment.typeParameters, info.typeParameters);
        _applyToFormalParameters(fragment.formalParameters, info.parameters);
      },
    );
  }

  void _applyToFunctionDeclaration(
    TopLevelFunctionFragmentImpl fragment,
    _InfoExecutableDeclaration info,
  ) {
    fragment.setCodeRange(info.codeOffset, info.codeLength);
    fragment.firstTokenOffset = info.firstTokenOffset;
    fragment.nameOffset = info.nameOffset;
    fragment.documentationComment = info.documentationComment;

    DeferredResolutionReadingHelper.withoutLoadingResolution(() {
      _applyToTypeParameters(fragment.typeParameters, info.typeParameters);
      _applyToFormalParameters(fragment.formalParameters, info.parameters);
    });

    fragment.deferConstantOffsets(info.constantOffsets, (applier) {
      applier.applyToMetadata(fragment.metadata);
      applier.applyToTypeParameters(fragment.typeParameters);
      applier.applyToFormalParameters(fragment.formalParameters);
    });
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
    List<MethodFragmentImpl> fragmentList,
    List<_InfoExecutableDeclaration> infoList,
  ) {
    forCorrespondingPairs(fragmentList, infoList, (fragment, info) {
      fragment.setCodeRange(info.codeOffset, info.codeLength);
      fragment.firstTokenOffset = info.firstTokenOffset;
      fragment.nameOffset = info.nameOffset;
      fragment.documentationComment = info.documentationComment;

      DeferredResolutionReadingHelper.withoutLoadingResolution(() {
        _applyToTypeParameters(fragment.typeParameters, info.typeParameters);
        _applyToFormalParameters(fragment.formalParameters, info.parameters);
      });

      fragment.deferConstantOffsets(info.constantOffsets, (applier) {
        applier.applyToMetadata(fragment.metadata);
        applier.applyToTypeParameters(fragment.typeParameters);
        applier.applyToFormalParameters(fragment.formalParameters);
      });
    });
  }

  void _applyToMixinDeclaration(
    MixinFragmentImpl fragment,
    _InfoMixinDeclaration info,
  ) {
    fragment.setCodeRange(info.codeOffset, info.codeLength);
    fragment.firstTokenOffset = info.firstTokenOffset;
    fragment.nameOffset = info.nameOffset;
    fragment.documentationComment = info.documentationComment;

    DeferredResolutionReadingHelper.withoutLoadingResolution(() {
      _applyToTypeParameters(fragment.typeParameters, info.typeParameters);
    });

    _scheduleApplyMembersOffsets(fragment, () {
      DeferredResolutionReadingHelper.withoutLoadingResolution(() {
        _applyToConstructors(fragment.constructors, info.constructors);
        _applyToFields(fragment.fields, info.fields);
        _applyToAccessors(fragment.getters, info.getters);
        _applyToAccessors(fragment.setters, info.setters);
        _applyToMethods(fragment.methods, info.methods);
      });
    });

    fragment.deferConstantOffsets(info.constantOffsets, (applier) {
      applier.applyToMetadata(fragment.metadata);
      applier.applyToTypeParameters(fragment.typeParameters);
    });
  }

  void _applyToPartIncludes(List<PartIncludeImpl> imports, _InfoUnit info) {
    forCorrespondingPairs(imports, info.parts, (element, info) {
      element.partKeywordOffset = info.partKeywordOffset;
    });
  }

  void _applyToTopLevelVariable(
    TopLevelVariableFragmentImpl fragment,
    _InfoTopLevelVariable info,
  ) {
    fragment.setCodeRange(info.codeOffset, info.codeLength);
    fragment.firstTokenOffset = info.firstTokenOffset;
    fragment.nameOffset = info.nameOffset;
    fragment.documentationComment = info.documentationComment;

    fragment.deferConstantOffsets(info.constantOffsets, (applier) {
      applier.applyToMetadata(fragment.metadata);
      applier.applyToConstantInitializer(fragment);
    });
  }

  void _applyToTypeAlias(TypeAliasFragmentImpl fragment, _InfoTypeAlias info) {
    fragment.setCodeRange(info.codeOffset, info.codeLength);
    fragment.firstTokenOffset = info.firstTokenOffset;
    fragment.nameOffset = info.nameOffset;
    fragment.documentationComment = info.documentationComment;

    DeferredResolutionReadingHelper.withoutLoadingResolution(() {
      _applyToTypeParameters(fragment.typeParameters, info.typeParameters);
    });

    _setupApplyConstantOffsetsForTypeAlias(fragment, info.constantOffsets);
  }

  void _applyToTypeParameters(
    List<TypeParameterFragmentImpl> fragmentList,
    List<_InfoTypeParameter> infoList,
  ) {
    forCorrespondingPairs(fragmentList, infoList, (fragment, info) {
      fragment.setCodeRange(info.codeOffset, info.codeLength);
      fragment.firstTokenOffset = info.firstTokenOffset;
      fragment.nameOffset = info.nameOffset;
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
    TypeAliasFragmentImpl fragment,
    Uint32List constantOffsets,
  ) {
    fragment.deferConstantOffsets(constantOffsets, (applier) {
      applier.applyToMetadata(fragment.metadata);
      applier.applyToTypeParameters(fragment.typeParameters);
    });
  }
}

class _InfoBuilder {
  _InfoUnit build(CompilationUnit unit) {
    // Build all needed lists from `unit.declarations` with a single iteration
    // the list.
    var classDeclarations = <_InfoClassDeclaration>[];
    var classTypeAliases = <_InfoClassTypeAlias>[];
    var enums = <_InfoEnumDeclaration>[];
    var extensions = <_InfoExtensionDeclaration>[];
    var extensionTypes = <_InfoExtensionTypeDeclaration>[];
    var mixinDeclarations = <_InfoMixinDeclaration>[];
    var topLevelFunctions = <_InfoExecutableDeclaration>[];
    var topLevelGetters = <_InfoExecutableDeclaration>[];
    var topLevelSetters = <_InfoExecutableDeclaration>[];
    var topLevelVariable = <_InfoTopLevelVariable>[];
    var typeAliases = <_InfoTypeAlias>[];
    for (var declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        classDeclarations.add(_buildClass(declaration));
      } else if (declaration is ClassTypeAlias) {
        classTypeAliases.add(_buildClassTypeAlias(declaration));
      } else if (declaration is EnumDeclaration) {
        enums.add(_buildEnum(declaration));
      } else if (declaration is ExtensionDeclaration) {
        extensions.add(_buildExtension(declaration));
      } else if (declaration is ExtensionTypeDeclaration) {
        extensionTypes.add(_buildExtensionType(declaration));
      } else if (declaration is MixinDeclaration) {
        mixinDeclarations.add(_buildMixin(declaration));
      } else if (declaration is FunctionDeclaration) {
        if (declaration.isGetter) {
          topLevelGetters.add(_buildTopLevelFunction(declaration));
        } else if (declaration.isSetter) {
          topLevelSetters.add(_buildTopLevelFunction(declaration));
        } else {
          topLevelFunctions.add(_buildTopLevelFunction(declaration));
        }
      } else if (declaration is TopLevelVariableDeclaration) {
        for (var variable in declaration.variables.variables) {
          topLevelVariable.add(_buildTopLevelVariable(variable));
        }
      } else if (declaration is FunctionTypeAlias) {
        typeAliases.add(_buildFunctionTypeAlias(declaration));
      } else if (declaration is GenericTypeAlias) {
        typeAliases.add(_buildGenericTypeAlias(declaration));
      }
    }

    // Build all needed lists from `unit.directives` with a single iteration
    // the list.
    var imports = <_InfoImport>[];
    var exports = <_InfoExport>[];
    var parts = <_InfoPart>[];
    var rawImports = <ImportDirective>[];
    var rawExports = <ExportDirective>[];
    var rawParts = <PartDirective>[];
    LibraryDirective? firstLibraryDirective;
    for (var directive in unit.directives) {
      if (directive is ImportDirective) {
        rawImports.add(directive);
        imports.add(_buildImport(directive));
      } else if (directive is ExportDirective) {
        rawExports.add(directive);
        exports.add(_buildExport(directive));
      } else if (directive is PartDirective) {
        rawParts.add(directive);
        parts.add(_buildPart(directive));
      } else if (directive is LibraryDirective) {
        firstLibraryDirective ??= directive;
      }
    }

    return _InfoUnit(
      codeOffset: unit.offset,
      codeLength: unit.length,
      lineStarts: unit.lineInfo.lineStarts,
      libraryName: _buildLibraryName(firstLibraryDirective),
      libraryConstantOffsets: _buildLibraryConstantOffsets(
        unit.directives.firstOrNull,
        rawImports,
        rawExports,
        rawParts,
      ),
      docComment: _getDocumentationComment(unit.directives.firstOrNull),
      imports: imports,
      exports: exports,
      parts: parts,
      classDeclarations: classDeclarations,
      classTypeAliases: classTypeAliases,
      enums: enums,
      extensions: extensions,
      extensionTypes: extensionTypes,
      mixinDeclarations: mixinDeclarations,
      topLevelFunctions: topLevelFunctions,
      topLevelGetters: topLevelGetters,
      topLevelSetters: topLevelSetters,
      topLevelVariable: topLevelVariable,
      typeAliases: typeAliases,
    );
  }

  _InfoClassDeclaration _buildClass(ClassDeclaration node) {
    return _InfoClassDeclaration(
      data: _buildInterfaceData(
        node,
        name: node.namePart.typeName,
        typeParameters: node.namePart.typeParameters,
        primaryConstructor: node.namePart.tryCast(),
        members: node.body.tryCast<BlockClassBody>()?.members ?? [],
      ),
    );
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
      newKeywordOffset: node.newKeyword?.offset,
      factoryKeywordOffset: node.factoryKeyword?.offset,
      typeNameOffset: node.typeName?.offset,
      periodOffset: node.period?.offset,
      nameEnd: (node.name ?? node.typeName)?.end,
      thisKeywordOffset: null,
    );
  }

  _InfoEnumDeclaration _buildEnum(EnumDeclaration node) {
    return _InfoEnumDeclaration(
      data: _buildInterfaceData(
        node,
        name: node.namePart.typeName,
        typeParameters: node.namePart.typeParameters,
        primaryConstructor: node.namePart.tryCast(),
        members: node.body.members,
        fields: [
          ...node.body.constants.map(_buildEnumConstant),
          ...node.body.members
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

  _InfoExport _buildExport(ExportDirective node) {
    return _InfoExport(
      exportKeywordOffset: node.exportKeyword.offset,
      combinators: _buildCombinators(node.combinators),
    );
  }

  _InfoExtensionDeclaration _buildExtension(ExtensionDeclaration node) {
    return _InfoExtensionDeclaration(
      data: _buildInstanceData(
        node,
        name: node.name,
        typeParameters: node.typeParameters,
        members: node.body.members,
      ),
    );
  }

  _InfoExtensionTypeDeclaration _buildExtensionType(
    ExtensionTypeDeclaration node,
  ) {
    return _InfoExtensionTypeDeclaration(
      data: _buildInterfaceData(
        node,
        name: node.primaryConstructor.typeName,
        typeParameters: node.primaryConstructor.typeParameters,
        primaryConstructor: node.primaryConstructor,
        members: node.body.tryCast<BlockClassBody>()?.members ?? [],
      ),
    );
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
      documentationComment: _getDocumentationComment(notDefault),
      typeParameters: _buildTypeParameters(typeParameters),
      parameters: _buildFormalParameters(parameters),
    );
  }

  List<_InfoFormalParameter> _buildFormalParameters(FormalParameterList? node) {
    if (node == null) {
      return [];
    }
    var parameters = node.parameters;
    return List.generate(
      parameters.length,
      (index) => _buildFormalParameter(parameters[index]),
    );
  }

  _InfoTypeAlias _buildFunctionTypeAlias(FunctionTypeAlias node) {
    return _InfoTypeAlias(
      firstTokenOffset: node.offset,
      codeOffset: node.offset,
      codeLength: node.length,
      nameOffset: node.name.offsetIfNotEmpty,
      documentationComment: _getDocumentationComment(node),
      typeParameters: _buildTypeParameters(node.typeParameters),
      constantOffsets: _buildConstantOffsets(
        metadata: node.metadata,
        typeParameters: node.typeParameters,
        aliasedType: node.returnType,
      ),
    );
  }

  _InfoTypeAlias _buildGenericTypeAlias(GenericTypeAlias node) {
    return _InfoTypeAlias(
      firstTokenOffset: node.offset,
      codeOffset: node.offset,
      codeLength: node.length,
      nameOffset: node.name.offsetIfNotEmpty,
      documentationComment: _getDocumentationComment(node),
      typeParameters: _buildTypeParameters(node.typeParameters),
      constantOffsets: _buildConstantOffsets(
        metadata: node.metadata,
        typeParameters: node.typeParameters,
        aliasedType: node.type,
      ),
    );
  }

  _InfoImport _buildImport(ImportDirective node) {
    return _InfoImport(
      importKeywordOffset: node.importKeyword.offset,
      prefixOffset: node.prefix?.token.offsetIfNotEmpty,
      combinators: _buildCombinators(node.combinators),
    );
  }

  _InstanceData _buildInstanceData(
    Declaration node, {
    required Token? name,
    required TypeParameterList? typeParameters,
    required List<ClassMember> members,
    List<_InfoFieldDeclaration>? fields,
  }) {
    // Build all needed lists based on `members` with a single iteration the list.
    var getters = <_InfoExecutableDeclaration>[];
    var setters = <_InfoExecutableDeclaration>[];
    var methods = <_InfoExecutableDeclaration>[];
    bool processFields = fields == null;
    fields ??= <_InfoFieldDeclaration>[];
    for (var member in members) {
      if (member is MethodDeclaration) {
        if (member.isGetter) {
          getters.add(_buildMethodDeclaration(member));
        } else if (member.isSetter) {
          setters.add(_buildMethodDeclaration(member));
        } else {
          methods.add(_buildMethodDeclaration(member));
        }
      } else if (processFields && member is FieldDeclaration) {
        for (var variable in member.fields.variables) {
          fields.add(_buildField(variable));
        }
      }
    }

    var annotatedNode = node as AnnotatedNode;
    return _InstanceData(
      firstTokenOffset: node.offset,
      codeOffset: node.offset,
      codeLength: node.length,
      nameOffset: name?.offsetIfNotEmpty,
      documentationComment: _getDocumentationComment(annotatedNode),
      typeParameters: _buildTypeParameters(typeParameters),
      fields: fields,
      getters: getters,
      setters: setters,
      methods: methods,
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
    PrimaryConstructorDeclaration? primaryConstructor,
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

    var primaryConstructorBody = members
        .whereType<PrimaryConstructorBody>()
        .firstOrNull;

    return _InterfaceData(
      instanceData: instanceData,
      constructors: [
        if (primaryConstructor != null)
          _buildPrimaryConstructor(
            primaryConstructor,
            body: primaryConstructorBody,
          ),
        ...members.whereType<ConstructorDeclaration>().map(_buildConstructor),
      ],
    );
  }

  Uint32List _buildLibraryConstantOffsets(
    Directive? firstDirective,
    List<ImportDirective> imports,
    List<ExportDirective> exports,
    List<PartDirective> parts,
  ) {
    return _buildConstantOffsets(
      metadata: firstDirective?.metadata,
      importDirectives: imports,
      exportDirectives: exports,
      partDirectives: parts,
    );
  }

  _InfoLibraryName _buildLibraryName(LibraryDirective? firstLibraryDirective) {
    var nameOffset = -1;
    var nameLength = 0;
    var libraryName = firstLibraryDirective?.name;
    if (libraryName != null) {
      nameOffset = libraryName.offset;
      nameLength = libraryName.length;
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
        members: node.body.members,
      ),
    );
  }

  _InfoPart _buildPart(PartDirective node) {
    return _InfoPart(partKeywordOffset: node.partKeyword.offset);
  }

  _InfoConstructorDeclaration _buildPrimaryConstructor(
    PrimaryConstructorDeclaration node, {
    required PrimaryConstructorBody? body,
  }) {
    return _InfoConstructorDeclaration(
      firstTokenOffset: node.offset,
      codeOffset: node.offset,
      codeLength: node.length,
      nameOffset: node.constructorName?.name.offsetIfNotEmpty,
      documentationComment: _getDocumentationComment(body),
      typeParameters: const [],
      parameters: _buildFormalParameters(node.formalParameters),
      constantOffsets: _buildConstantOffsets(
        metadata: body?.metadata,
        formalParameters: node.formalParameters,
        constructorInitializers: body?.initializers,
      ),
      newKeywordOffset: null,
      factoryKeywordOffset: null,
      typeNameOffset: node.typeName.offset,
      periodOffset: node.constructorName?.period.offset,
      nameEnd: (node.constructorName?.name ?? node.typeName).end,
      thisKeywordOffset: body?.thisKeyword.offset,
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
    var typeParameters = node.typeParameters;
    return List.generate(
      typeParameters.length,
      (index) => _buildTypeParameter(typeParameters[index]),
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
  void write(BinaryWriter writer) {
    writer.writeList(typeParameters, (v) => v.write(writer));
    writer.writeUint30List(constantOffsets);
    super.write(writer);
  }
}

class _InfoCombinator {
  final int offset;
  final int end;

  _InfoCombinator({required this.offset, required this.end});

  factory _InfoCombinator.read(BinaryReader reader) {
    return _InfoCombinator(
      offset: reader.readUint30(),
      end: reader.readUint30(),
    );
  }

  void write(BinaryWriter writer) {
    writer.writeUint30(offset);
    writer.writeUint30(end);
  }
}

class _InfoConstructorDeclaration extends _InfoExecutableDeclaration {
  final int? newKeywordOffset;
  final int? factoryKeywordOffset;
  final int? typeNameOffset;
  final int? periodOffset;
  final int? nameEnd;
  final int? thisKeywordOffset;

  _InfoConstructorDeclaration({
    required super.firstTokenOffset,
    required super.codeOffset,
    required super.codeLength,
    required super.nameOffset,
    required super.documentationComment,
    required super.typeParameters,
    required super.parameters,
    required super.constantOffsets,
    required this.newKeywordOffset,
    required this.factoryKeywordOffset,
    required this.typeNameOffset,
    required this.periodOffset,
    required this.nameEnd,
    required this.thisKeywordOffset,
  });

  _InfoConstructorDeclaration.read(super.reader)
    : newKeywordOffset = reader.readOptionalUint30(),
      factoryKeywordOffset = reader.readOptionalUint30(),
      typeNameOffset = reader.readOptionalUint30(),
      periodOffset = reader.readOptionalUint30(),
      nameEnd = reader.readOptionalUint30(),
      thisKeywordOffset = reader.readOptionalUint30(),
      super.read();

  @override
  void write(BinaryWriter writer) {
    writer.writeOptionalUint30(newKeywordOffset);
    writer.writeOptionalUint30(factoryKeywordOffset);
    writer.writeOptionalUint30(typeNameOffset);
    writer.writeOptionalUint30(periodOffset);
    writer.writeOptionalUint30(nameEnd);
    writer.writeOptionalUint30(thisKeywordOffset);
    super.write(writer);
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
  void write(BinaryWriter writer) {
    writer.writeList(typeParameters, (v) => v.write(writer));
    writer.writeList(parameters, (v) => v.write(writer));
    writer.writeUint30List(constantOffsets);
    super.write(writer);
  }
}

class _InfoExport {
  final int exportKeywordOffset;
  final List<_InfoCombinator> combinators;

  _InfoExport({required this.exportKeywordOffset, required this.combinators});

  factory _InfoExport.read(BinaryReader reader) {
    return _InfoExport(
      exportKeywordOffset: reader.readUint30(),
      combinators: reader.readList(_InfoCombinator.read),
    );
  }

  void write(BinaryWriter writer) {
    writer.writeUint30(exportKeywordOffset);
    writer.writeList(combinators, (v) => v.write(writer));
  }
}

class _InfoExtensionDeclaration extends _InfoInstanceDeclaration {
  _InfoExtensionDeclaration({required super.data});

  _InfoExtensionDeclaration.read(super.reader) : super.read();
}

class _InfoExtensionTypeDeclaration extends _InfoInterfaceDeclaration {
  _InfoExtensionTypeDeclaration({required super.data});

  _InfoExtensionTypeDeclaration.read(super.reader) : super.read();
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
  void write(BinaryWriter writer) {
    writer.writeUint30List(constantOffsets);
    super.write(writer);
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
    required super.documentationComment,
    required this.typeParameters,
    required this.parameters,
  });

  _InfoFormalParameter.read(super.reader)
    : typeParameters = reader.readList(_InfoTypeParameter.read),
      parameters = reader.readList(_InfoFormalParameter.read),
      super.read();

  @override
  void write(BinaryWriter writer) {
    writer.writeList(typeParameters, (v) => v.write(writer));
    writer.writeList(parameters, (v) => v.write(writer));
    super.write(writer);
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

  factory _InfoImport.read(BinaryReader reader) {
    return _InfoImport(
      importKeywordOffset: reader.readUint30(),
      prefixOffset: reader.readOptionalUint30(),
      combinators: reader.readList(_InfoCombinator.read),
    );
  }

  void write(BinaryWriter writer) {
    writer.writeUint30(importKeywordOffset);
    writer.writeOptionalUint30(prefixOffset);
    writer.writeList(combinators, (v) => v.write(writer));
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
  void write(BinaryWriter writer) {
    writer.writeList(typeParameters, (v) => v.write(writer));
    writer.writeList(fields, (v) => v.write(writer));
    writer.writeList(getters, (v) => v.write(writer));
    writer.writeList(setters, (v) => v.write(writer));
    writer.writeList(methods, (v) => v.write(writer));
    writer.writeUint30List(constantOffsets);
    super.write(writer);
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
  void write(BinaryWriter writer) {
    writer.writeList(constructors, (v) => v.write(writer));
    super.write(writer);
  }
}

class _InfoLibraryName {
  final int offset;
  final int length;

  _InfoLibraryName({required this.offset, required this.length});

  factory _InfoLibraryName.read(BinaryReader reader) {
    return _InfoLibraryName(
      offset: reader.readUint30() - 1,
      length: reader.readUint30(),
    );
  }

  void write(BinaryWriter writer) {
    writer.writeUint30(offset + 1);
    writer.writeUint30(length);
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

  _InfoNode.read(BinaryReader reader)
    : firstTokenOffset = reader.readUint30(),
      codeOffset = reader.readUint30(),
      codeLength = reader.readUint30(),
      nameOffset = reader.readOptionalUint30(),
      documentationComment = reader.readStringUtf8().nullIfEmpty;

  void write(BinaryWriter writer) {
    writer.writeUint30(firstTokenOffset);
    writer.writeUint30(codeOffset);
    writer.writeUint30(codeLength);
    writer.writeOptionalUint30(nameOffset);
    writer.writeStringUtf8(documentationComment ?? '');
  }
}

class _InfoPart {
  final int partKeywordOffset;

  _InfoPart({required this.partKeywordOffset});

  factory _InfoPart.read(BinaryReader reader) {
    return _InfoPart(partKeywordOffset: reader.readUint30());
  }

  void write(BinaryWriter writer) {
    writer.writeUint30(partKeywordOffset);
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
  void write(BinaryWriter writer) {
    writer.writeUint30List(constantOffsets);
    super.write(writer);
  }
}

class _InfoTypeAlias extends _InfoNode {
  final List<_InfoTypeParameter> typeParameters;
  final Uint32List constantOffsets;

  _InfoTypeAlias({
    required super.firstTokenOffset,
    required super.codeOffset,
    required super.codeLength,
    required super.nameOffset,
    required super.documentationComment,
    required this.typeParameters,
    required this.constantOffsets,
  }) : super();

  _InfoTypeAlias.read(super.reader)
    : typeParameters = reader.readList(_InfoTypeParameter.read),
      constantOffsets = reader.readUint30List(),
      super.read();

  @override
  void write(BinaryWriter writer) {
    writer.writeList(typeParameters, (v) => v.write(writer));
    writer.writeUint30List(constantOffsets);
    super.write(writer);
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
  final List<_InfoMixinDeclaration> mixinDeclarations;
  final List<_InfoExecutableDeclaration> topLevelFunctions;
  final List<_InfoExecutableDeclaration> topLevelGetters;
  final List<_InfoExecutableDeclaration> topLevelSetters;
  final List<_InfoTopLevelVariable> topLevelVariable;
  final List<_InfoTypeAlias> typeAliases;

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
    required this.mixinDeclarations,
    required this.topLevelFunctions,
    required this.topLevelGetters,
    required this.topLevelSetters,
    required this.topLevelVariable,
    required this.typeAliases,
  });

  _InfoUnit.read(BinaryReader reader)
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
      mixinDeclarations = reader.readList(_InfoMixinDeclaration.read),
      topLevelFunctions = reader.readList(_InfoExecutableDeclaration.read),
      topLevelGetters = reader.readList(_InfoExecutableDeclaration.read),
      topLevelSetters = reader.readList(_InfoExecutableDeclaration.read),
      topLevelVariable = reader.readList(_InfoTopLevelVariable.read),
      typeAliases = reader.readList(_InfoTypeAlias.read);

  void write(BinaryWriter writer) {
    writer.writeUint30(codeOffset);
    writer.writeUint30(codeLength);
    writer.writeUint30List(lineStarts);
    libraryName.write(writer);
    writer.writeUint30List(libraryConstantOffsets);
    writer.writeOptionalStringUtf8(docComment);
    writer.writeList(imports, (v) => v.write(writer));
    writer.writeList(exports, (v) => v.write(writer));
    writer.writeList(parts, (v) => v.write(writer));
    writer.writeList(classDeclarations, (v) => v.write(writer));
    writer.writeList(classTypeAliases, (v) => v.write(writer));
    writer.writeList(enums, (v) => v.write(writer));
    writer.writeList(extensions, (v) => v.write(writer));
    writer.writeList(extensionTypes, (v) => v.write(writer));
    writer.writeList(mixinDeclarations, (v) => v.write(writer));
    writer.writeList(topLevelFunctions, (v) => v.write(writer));
    writer.writeList(topLevelGetters, (v) => v.write(writer));
    writer.writeList(topLevelSetters, (v) => v.write(writer));
    writer.writeList(topLevelVariable, (v) => v.write(writer));
    writer.writeList(typeAliases, (v) => v.write(writer));
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

  void applyToConstantInitializer(FragmentImpl fragment) {
    if (fragment is FieldFragmentImpl && fragment.isEnumConstant) {
      _applyToEnumConstantInitializer(fragment);
    } else if (fragment is VariableFragmentImpl) {
      fragment.constantInitializer?.accept(this);
    }
  }

  void applyToConstructorInitializers(ConstructorFragmentImpl fragment) {
    for (var initializer in fragment.constantInitializers) {
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

  void _applyToEnumConstantInitializer(FieldFragmentImpl fragment) {
    var initializer = fragment.constantInitializer;
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

extension on BinaryReader {
  List<T> readList<T>(T Function(BinaryReader) read) {
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

extension _ListOfPropertyAccessorFragment<
  T extends PropertyAccessorFragmentImpl
>
    on List<T> {
  Iterable<T> get withOriginDeclaration {
    return where((e) => e.isOriginDeclaration);
  }
}

extension _ListOfPropertyInducingFragment<
  T extends PropertyInducingFragmentImpl
>
    on List<T> {
  Iterable<T> get withOriginDeclaration {
    return where((e) => e.isOriginDeclaration);
  }
}
