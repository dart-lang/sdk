// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/kernel/constructor_tearoff_lowering.dart'
    show isTearOffLowering;
import 'package:kernel/kernel.dart';

import 'module_symbols.dart';

class ModuleSymbolsCollector extends RecursiveVisitor {
  /// Stack of active scopes while visiting the original Dart program.
  ///
  /// The first scope added to the stack should always be the library scope. The
  /// last element in the list represents the current scope.
  final _scopes = <ScopeSymbol>[];

  final ModuleSymbols _moduleSymbols;
  final Map<Class, String> _classJsNames;
  final Map<Member, String> _memberJsNames;
  final Map<Procedure, String> _procedureJsNames;
  final Map<VariableDeclaration, String> _variableJsNames;

  ModuleSymbolsCollector(String moduleName, this._classJsNames,
      this._memberJsNames, this._procedureJsNames, this._variableJsNames)
      : _moduleSymbols = ModuleSymbols(moduleName: moduleName);

  ModuleSymbols collectSymbolInfo(Component node) {
    node.accept(this);
    return _moduleSymbols;
  }

  /// Returns the id of the script in this module with the matching [fileUri].
  String _scriptId(Uri fileUri) => fileUri.toString();

  /// Returns the id of [type].
  // TODO(nshahan) Only nullable until we design how to identify types from
  // other modules.
  String? _typeId(DartType type) =>
      // TODO(nshahan) How to handle function types or types from other modules?
      type is InterfaceType ? _classJsNames[type.classNode] : null;

  /// Returns the symbol for the function defined by [node].
  void _createFunctionSymbol(Member node) {
    var functionSymbol = FunctionSymbol(
        name: node.name.text,
        // TODO(nshahan) typeId - probably should canonicalize but keep original
        // type argument names.
        typeId: null,
        // TODO(nshahan) Should we mark all constructors static?
        isStatic: node is Procedure ? node.isStatic : false,
        isConst: node.isConst,
        localId: _memberJsNames[node] ?? _procedureJsNames[node]!,
        scopeId: _scopes.last.id,
        location: SourceLocation(
            scriptId: _scriptId(node.location!.file),
            tokenPos: node.fileOffset,
            endTokenPos: node.fileEndOffset));

    _scopes.add(functionSymbol);
    node.visitChildren(this);
    _scopes
      ..removeLast()
      ..last.scopeIds.add(functionSymbol.id);
    _moduleSymbols.functions.add(functionSymbol);
  }

  @override
  void visitClass(Class node) {
    var classSymbol = ClassSymbol(
        name: node.name,
        isAbstract: node.isAbstract,
        isConst: node.constructors.any((constructor) => constructor.isConst),
        superClassId: _classJsNames[node.superclass],
        interfaceIds: [
          for (var type in node.implementedTypes) _classJsNames[type.classNode]!
        ],
        typeParameters: {
          for (var param in node.typeParameters)
            // TODO(nshahan) Value should be the JS name.
            param.name!: param.name!
        },
        localId: _classJsNames[node]!,
        scopeId: _scopes.last.id,
        location: SourceLocation(
            scriptId: _scriptId(node.location!.file),
            tokenPos: node.startFileOffset,
            endTokenPos: node.fileEndOffset));

    _scopes.add(classSymbol);
    node.visitChildren(this);
    _scopes
      ..removeLast()
      ..last.scopeIds.add(classSymbol.id);
    _moduleSymbols.classes.add(classSymbol);
  }

  @override
  void visitConstructor(Constructor node) => _createFunctionSymbol(node);

  @override
  void visitField(Field node) {
    var fieldSymbol = VariableSymbol(
        name: node.name.text,
        kind: node.parent is Class
            ? VariableSymbolKind.field
            : VariableSymbolKind.global,
        isConst: node.isConst,
        isFinal: node.isFinal,
        isStatic: node.isStatic,
        typeId: _typeId(node.type),
        localId: _memberJsNames[node]!,
        scopeId: _scopes.last.id,
        location: SourceLocation(
            scriptId: _scriptId(node.location!.file),
            tokenPos: node.fileOffset,
            endTokenPos: node.fileEndOffset));
    node.visitChildren(this);
    _scopes.last.variableIds.add(fieldSymbol.id);
    _moduleSymbols.variables.add(fieldSymbol);
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
              // TODO(nshahan) Need to handle prefixes.
              targetId: dep.targetLibrary.importUri.toString())
      ],
      scriptIds: [],
    );

    // TODO(nshahan) Save some space by using integers as local ids?
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

    librarySymbol.scriptIds.addAll(scripts.map((s) => s.id));
    _moduleSymbols.scripts.addAll(scripts);

    _scopes.add(librarySymbol);
    node.visitChildren(this);
    _scopes.removeLast();
    _moduleSymbols.libraries.add(librarySymbol);
  }

  @override
  void visitProcedure(Procedure node) {
    // Legacy libraries contain procedures with no bodies for all Object methods
    // in every class. We can ignore these unless they actually contain a body.
    //
    // Also avoid adding information for the static methods introduced by the
    // CFE lowering for constructor tearoffs.
    if (node.function.body == null || isTearOffLowering(node)) return;
    _createFunctionSymbol(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    var kind = node.isInitializingFormal
        ? VariableSymbolKind.formal
        : VariableSymbolKind.local;
    var variableSymbol = _createVariableSymbol(node, kind);
    node.visitChildren(this);
    _scopes.last.variableIds.add(variableSymbol.id);
    _moduleSymbols.variables.add(variableSymbol);
  }

  VariableSymbol _createVariableSymbol(
          VariableDeclaration node, VariableSymbolKind kind) =>
      VariableSymbol(
          name: node.name!,
          kind: kind,
          isConst: node.isConst,
          isFinal: node.isFinal,
          // Static fields are visited in `visitField()`.
          isStatic: false,
          typeId: _typeId(node.type),
          localId: _variableJsNames[node]!,
          scopeId: _scopes.last.id,
          location: SourceLocation(
              scriptId: _scriptId(node.location!.file),
              tokenPos: node.fileOffset));
}
