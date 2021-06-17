// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:kernel/kernel.dart';

import 'module_symbols.dart';

class ModuleSymbolsCollector extends RecursiveVisitor {
  final scopes = <ScopeSymbol>[];

  final moduleSymbols = ModuleSymbols(
    // TODO version
    // TODO moduleName
    libraries: <LibrarySymbol>[],
    scripts: <Script>[],
    classes: <ClassSymbol>[],
    // TODO functionTypes
    // TODO functions
    // TODO scopes
    // TODO variables
  );

  final Map<Class, String> classJsNames;

  ModuleSymbolsCollector(this.classJsNames);

  ModuleSymbols collectSymbolInfo(Component node) {
    node.accept(this);
    return moduleSymbols;
  }

  /// Returns the id of the script in this module with the matching [fileUri].
  String _scriptId(Uri fileUri) => fileUri.toString();

  @override
  void visitClass(Class node) {
    var classSymbol = ClassSymbol(
        name: node.name,
        isAbstract: node.isAbstract,
        // TODO isConst - has a const constructor?
        superClassId: classJsNames[node.superclass],
        interfaceIds: [
          for (var type in node.implementedTypes) classJsNames[type.classNode]
        ],
        typeParameters: {
          for (var param in node.typeParameters)
            param.name: param.name // TODO: value should be JS name
        },
        localId: classJsNames[node],
        scopeId: scopes.last.id,
        location: SourceLocation(
            scriptId: _scriptId(node.location.file),
            tokenPos: node.startFileOffset,
            endTokenPos: node.fileEndOffset),
        // Create empty list, they are added in visitField().
        variableIds: <String>[],
        scopeIds: <String>[]);

    scopes.add(classSymbol);
    node.visitChildren(this);
    scopes
      ..removeLast()
      ..last.scopeIds.add(classSymbol.id);
    moduleSymbols.classes.add(classSymbol);
  }

  @override
  void visitLibrary(Library node) {
    var librarySymbol = LibrarySymbol(
        name: node.name,
        uri: node.importUri.toString(),
        dependencies: [
          for (var dep in node.dependencies)
            LibrarySymbolDependency(
                isImport: dep.isImport,
                isDeferred: dep.isDeferred,
                // TODO prefix
                targetId: dep.targetLibrary.importUri.toString())
        ],
        variableIds: <String>[],
        scopeIds: <String>[]);

    // TODO: Save some space by using integers as local ids?
    var scripts = [
      Script(
          uri: node.fileUri.toString(),
          localId: _scriptId(node.fileUri),
          libraryId: librarySymbol.id),
      for (var part in node.parts)
        Script(
            uri: node.fileUri.resolve(part.partUri).toString(),
            localId: _scriptId(node.fileUri.resolve(part.partUri)),
            libraryId: librarySymbol.id),
    ];

    librarySymbol.scriptIds = [for (var script in scripts) script.id];
    moduleSymbols.scripts.addAll(scripts);

    scopes.add(librarySymbol);
    node.visitChildren(this);
    scopes.removeLast();
    moduleSymbols.libraries.add(librarySymbol);
  }
}
