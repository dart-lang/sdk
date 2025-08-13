// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Temporary script to convert the analyzer's error message constants to
/// camelCase.
///
/// This script analyzes `pkg/analyzer` (and related packages), and renames
/// every static const error code declaration from SCREAMING_CAPS format to
/// camelCase format. It also flips the constant `_useLowerCamelCaseNames`
/// (in `messages/generate.dart`) from `false` to `true`, so that error message
/// code generation will start generating error codes in camelCase format.
///
/// This script will be run once to change the format of all the analyzer error
/// codes, and then it will be removed from the codebase.
library;

// TODO(paulberry): delete this script once it is no longer needed.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;
import 'package:analyzer_testing/package_root.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;

void main() async {
  var provider = PhysicalResourceProvider.INSTANCE;
  var packages = [
    '_fe_analyzer_shared',
    'analyzer',
    'analysis_server',
    'analysis_server_plugin',
    'analyzer_cli',
    'analyzer_plugin',
    'analyzer_testing',
    'front_end',
    'linter',
  ];
  var collection = AnalysisContextCollection(
    includedPaths: [
      for (var package in packages) path.join(packageRoot, package),
    ],
    resourceProvider: provider,
  );
  // Use `.single` to make sure that `collection` just contains a single
  // context. This ensures that `publicApi.build` will see all the files in
  // the package.
  var context = collection.contexts.single;
  var errorsLibrary =
      ((await context.currentSession.getLibraryByUri(
                'package:_fe_analyzer_shared/src/base/errors.dart',
              ))
              as LibraryElementResult)
          .element;
  var elements = _Elements(
    diagnosticCodeClass: errorsLibrary.getClass('DiagnosticCode')!,
    typeSystem: errorsLibrary.typeSystem,
  );
  var analyzedFiles = context.contextRoot.analyzedFiles().toList();
  for (var (index, file) in analyzedFiles.indexed) {
    if (!file.endsWith('.dart')) continue;
    var fileResult =
        (await context.currentSession.getResolvedUnit(file))
            as ResolvedUnitResult;
    var edits = <SourceEdit>[];
    fileResult.unit.accept(_Visitor(file, edits, elements));
    var percent = (index / analyzedFiles.length * 100).floor();
    print('$percent%: $file: ${edits.length} edits');
    if (edits.isNotEmpty) {
      File(file).writeAsStringSync(
        SourceEdit.applySequence(
          fileResult.content,
          edits..sortBy((e) => -e.offset),
        ),
      );
    }
  }
}

final _screamingCapsRegExp = RegExp(r'^[A-Z0-9_]+$');

class _Elements {
  final ClassElement diagnosticCodeClass;
  final TypeSystem typeSystem;

  _Elements({required this.diagnosticCodeClass, required this.typeSystem});
}

class _Visitor extends RecursiveAstVisitor {
  final String _file;
  final List<SourceEdit> _edits;
  final _Elements _elements;

  _Visitor(this._file, this._edits, this._elements);

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    if (_isScreamingCaps(node.name) &&
        _isDiagnosticCodeConstant(node.element)) {
      _edits.add(SourceEdit(node.offset, node.length, node.name.toCamelCase()));
    }
    return super.visitSimpleIdentifier(node);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    if (node.name.lexeme == '_useLowerCamelCaseNames' &&
        path.basename(_file) == 'generate.dart') {
      _edits.add(
        SourceEdit(node.initializer!.offset, node.initializer!.length, 'true'),
      );
    } else if (_isScreamingCaps(node.name.lexeme) &&
        _isDiagnosticCodeConstant(node.declaredFragment?.element)) {
      _edits.add(
        SourceEdit(
          node.name.offset,
          node.name.length,
          node.name.lexeme.toCamelCase(),
        ),
      );
    }
    return super.visitVariableDeclaration(node);
  }

  bool _isDiagnosticCodeConstant(Element? element) {
    if (element is GetterElement) {
      element = element.variable;
    }
    return element is FieldElement &&
        element.isStatic &&
        element.isConst &&
        _isDiagnosticSubclass(element.enclosingElement);
  }

  bool _isDiagnosticSubclass(InstanceElement class_) {
    return _elements.typeSystem.isSubtypeOf(
      class_.thisType,
      _elements.diagnosticCodeClass.thisType,
    );
  }

  bool _isScreamingCaps(String s) => _screamingCapsRegExp.hasMatch(s);
}
