// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/services/available_declarations.dart';
import 'package:analyzer/src/services/available_declarations.dart' as ad;

class Declaration {
  final int fileIndex;
  final LineInfo lineInfo;
  final String name;
  final DeclarationKind kind;
  final int offset;
  final int line;
  final int column;
  final int codeOffset;
  final int codeLength;
  final String className;
  final String mixinName;
  final String parameters;

  Declaration(
    this.fileIndex,
    this.lineInfo,
    this.name,
    this.kind,
    this.offset,
    this.line,
    this.column,
    this.codeOffset,
    this.codeLength,
    this.className,
    this.mixinName,
    this.parameters,
  );
}

enum DeclarationKind {
  CLASS,
  CLASS_TYPE_ALIAS,
  CONSTRUCTOR,
  ENUM,
  ENUM_CONSTANT,
  FIELD,
  FUNCTION,
  FUNCTION_TYPE_ALIAS,
  GETTER,
  METHOD,
  MIXIN,
  SETTER,
  VARIABLE
}

class WorkspaceSymbols {
  final DeclarationsTracker tracker;

  WorkspaceSymbols(this.tracker);

  List<Declaration> declarations(
      RegExp regExp, int maxResults, LinkedHashSet<String> files,
      {String onlyForFile}) {
    _doTrackerWork();

    var declarations = <Declaration>[];

    var pathToIndex = <String, int>{};

    int getPathIndex(String path) {
      var index = pathToIndex[path];
      if (index == null) {
        index = files.length;
        files.add(path);
        pathToIndex[path] = index;
      }
      return index;
    }

    if (maxResults != null && declarations.length >= maxResults) {
      throw const _MaxNumberOfDeclarationsError();
    }

    void addDeclaration(ad.Declaration declaration) {
      if (maxResults != null && declarations.length >= maxResults) {
        throw const _MaxNumberOfDeclarationsError();
      }

      var path = declaration.locationPath;
      if (onlyForFile != null && path != onlyForFile) {
        return;
      }

      declaration.children.forEach(addDeclaration);

      var name = declaration.name;
      if (name.isEmpty) {
        return;
      }
      if (name.endsWith('=')) {
        name = name.substring(0, name.length - 1);
      }
      if (regExp != null && !regExp.hasMatch(name)) {
        return;
      }

      String className;
      if (declaration.parent?.kind == ad.DeclarationKind.CLASS) {
        className = declaration.parent.name;
      }

      String mixinName;
      if (declaration.parent?.kind == ad.DeclarationKind.MIXIN) {
        mixinName = declaration.parent.name;
      }

      declarations.add(
        Declaration(
          getPathIndex(path),
          declaration.lineInfo,
          name,
          _getTopKind(declaration.kind),
          declaration.locationOffset,
          declaration.locationStartLine,
          declaration.locationStartColumn,
          declaration.codeOffset,
          declaration.codeLength,
          className,
          mixinName,
          declaration.parameters,
        ),
      );
    }

    var libraries = tracker.allLibraries;
    try {
      for (var library in libraries) {
        library.declarations.forEach(addDeclaration);
      }
    } on _MaxNumberOfDeclarationsError {
      // Uses an exception to short circuit the recursion when there are too
      // many declarations.
    }

    return declarations;
  }

  void _doTrackerWork() {
    while (tracker.hasWork) {
      tracker.doWork();
    }
  }

  static DeclarationKind _getTopKind(ad.DeclarationKind kind) {
    switch (kind) {
      case ad.DeclarationKind.CLASS:
        return DeclarationKind.CLASS;
      case ad.DeclarationKind.CLASS_TYPE_ALIAS:
        return DeclarationKind.CLASS_TYPE_ALIAS;
      case ad.DeclarationKind.CONSTRUCTOR:
        return DeclarationKind.CONSTRUCTOR;
      case ad.DeclarationKind.ENUM:
        return DeclarationKind.ENUM;
      case ad.DeclarationKind.ENUM_CONSTANT:
        return DeclarationKind.ENUM_CONSTANT;
      case ad.DeclarationKind.FIELD:
        return DeclarationKind.FIELD;
      case ad.DeclarationKind.FUNCTION_TYPE_ALIAS:
        return DeclarationKind.FUNCTION_TYPE_ALIAS;
      case ad.DeclarationKind.METHOD:
        return DeclarationKind.METHOD;
      case ad.DeclarationKind.MIXIN:
        return DeclarationKind.MIXIN;
      case ad.DeclarationKind.FUNCTION:
        return DeclarationKind.FUNCTION;
      case ad.DeclarationKind.GETTER:
        return DeclarationKind.GETTER;
      case ad.DeclarationKind.SETTER:
        return DeclarationKind.SETTER;
      case ad.DeclarationKind.VARIABLE:
        return DeclarationKind.VARIABLE;
      default:
        return null;
    }
  }
}

/// The marker class that is thrown to stop adding declarations.
class _MaxNumberOfDeclarationsError {
  const _MaxNumberOfDeclarationsError();
}
