// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: deprecated_member_use
import 'dart:cli' as cli;

import 'package:_fe_analyzer_shared/src/macros/api.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart'
    as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/remote_instance.dart'
    as macro;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/macro.dart';

class LibraryMacroApplier {
  final LibraryBuilder libraryBuilder;

  final Map<ClassDeclaration, macro.ClassDeclaration> _classDeclarations = {};

  LibraryMacroApplier(this.libraryBuilder);

  /// TODO(scheglov) check `shouldExecute`.
  /// TODO(scheglov) check `supportsDeclarationKind`.
  String? executeMacroTypesPhase() {
    var macroResults = <macro.MacroExecutionResult>[];
    for (var unitElement in libraryBuilder.element.units) {
      for (var classElement in unitElement.classes) {
        var classNode = libraryBuilder.linker.elementNodes[classElement];
        // TODO(scheglov) support other declarations
        if (classNode is ClassDeclaration) {
          for (var annotation in classNode.metadata) {
            var annotationNameNode = annotation.name;
            if (annotationNameNode is SimpleIdentifier &&
                annotation.arguments != null) {
              // TODO(scheglov) Create a Scope.
              for (var import in libraryBuilder.element.imports) {
                var importedLibrary = import.importedLibrary;
                if (importedLibrary is LibraryElementImpl) {
                  var importedUri = importedLibrary.source.uri;
                  if (!libraryBuilder.linker.builders
                      .containsKey(importedUri)) {
                    var lookupResult = importedLibrary.scope.lookup(
                      annotationNameNode.name,
                    );
                    var getter = lookupResult.getter;
                    if (getter is ClassElementImpl && getter.isMacro) {
                      var macroExecutor = importedLibrary.bundleMacroExecutor;
                      if (macroExecutor != null) {
                        // TODO(scheglov) For now we convert async into sync.
                        // ignore: deprecated_member_use
                        var macroResult = cli.waitFor(
                          _runSingleMacro(
                            macroExecutor,
                            getClassDeclaration(classNode),
                            getter,
                          ),
                        );
                        if (macroResult.isNotEmpty) {
                          macroResults.add(macroResult);
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    var macroExecutor = libraryBuilder.linker.macroExecutor;
    if (macroExecutor != null && macroResults.isNotEmpty) {
      return macroExecutor
          .buildAugmentationLibrary(
            macroResults,
            _resolveIdentifier,
            _inferOmittedType,
          )
          .trim();
    }
    return null;
  }

  macro.ClassDeclaration getClassDeclaration(ClassDeclaration node) {
    return _classDeclarations[node] ??= _createClassDeclaration(node);
  }

  macro.ClassDeclaration _createClassDeclaration(ClassDeclaration node) {
    return macro.ClassDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: _IdentifierImpl(
        id: macro.RemoteInstance.uniqueId,
        name: node.name.name,
      ),
      // TODO(scheglov): Support typeParameters
      typeParameters: [],
      // TODO(scheglov): Support interfaces
      interfaces: [],
      isAbstract: node.abstractKeyword != null,
      isExternal: false,
      // TODO(scheglov): Support mixins
      mixins: [],
      // TODO(scheglov): Support superclass
      superclass: null,
    );
  }

  macro.TypeAnnotation _inferOmittedType(
    macro.OmittedTypeAnnotation omittedType,
  ) {
    throw UnimplementedError();
  }

  macro.ResolvedIdentifier _resolveIdentifier(macro.Identifier identifier) {
    throw UnimplementedError();
  }

  Future<macro.MacroExecutionResult> _runSingleMacro(
    BundleMacroExecutor macroExecutor,
    macro.Declaration declaration,
    ClassElementImpl classElement,
  ) async {
    var macroIdentifier = classElement.macroIdentifier;
    if (macroIdentifier == null) {
      macroIdentifier = await macroExecutor.forClass(
        libraryUri: classElement.librarySource.uri,
        className: classElement.name,
      );
      classElement.macroIdentifier = macroIdentifier;
    }
    var macroInstance = await macroIdentifier.instantiate(
      _FakeIdentifierResolver(),
      declaration,
      '', // TODO
      Arguments([], {}),
    );
    return await macroInstance.executeTypesPhase();
  }
}

class _FakeIdentifierResolver extends macro.IdentifierResolver {
  @override
  Future<macro.Identifier> resolveIdentifier(Uri library, String name) {
    // TODO: implement resolveIdentifier
    throw UnimplementedError();
  }
}

class _IdentifierImpl extends macro.IdentifierImpl {
  _IdentifierImpl({required int id, required String name})
      : super(id: id, name: name);
}

extension on macro.MacroExecutionResult {
  bool get isNotEmpty =>
      libraryAugmentations.isNotEmpty || classAugmentations.isNotEmpty;
}
