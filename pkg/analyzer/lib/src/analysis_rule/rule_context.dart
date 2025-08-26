// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/workspace/workspace.dart';

export 'package:analyzer/analysis_rule/analysis_rule.dart';

/// Returns whether [filePath] is in the top-level `lib` directory in [package].
bool _isInLibDir(String? filePath, WorkspacePackage? package) {
  if (package == null) return false;
  if (filePath == null) return false;
  var libDir = package.root.getChildAssumingFolder('lib');
  return libDir.contains(filePath);
}

/// A [RuleContext] for a library, parsed into [ParsedUnitResult]s.
///
/// This is available for analysis rules that can operate on parsed,
/// unresolved syntax trees.
final class RuleContextWithParsedResults implements RuleContext {
  @override
  final List<RuleContextUnit> allUnits;

  @override
  final RuleContextUnit definingUnit;

  @override
  RuleContextUnit? currentUnit;

  RuleContextWithParsedResults(this.allUnits, this.definingUnit);

  @override
  bool get isInLibDir =>
      _isInLibDir(definingUnit.unit.declaredFragment?.source.fullName, package);

  @override
  bool get isInTestDirectory => false;

  @override
  LibraryElement get libraryElement => throw UnsupportedError(
    'RuleContext with parsed results does not include a LibraryElement',
  );

  @override
  WorkspacePackage? get package => null;

  @override
  TypeProvider get typeProvider => throw UnsupportedError(
    'RuleContext with parsed results does not include a TypeProvider',
  );

  @override
  TypeSystem get typeSystem => throw UnsupportedError(
    'RuleContext with parsed results does not include a TypeSystem',
  );

  @override
  bool isFeatureEnabled(Feature feature) => throw UnsupportedError(
    'RuleContext with parsed results does not include a LibraryElement',
  );
}

/// A [RuleContext] for a library, resolved into [ResolvedUnitResult]s.
final class RuleContextWithResolvedResults implements RuleContext {
  @override
  final List<RuleContextUnit> allUnits;

  @override
  final RuleContextUnit definingUnit;

  @override
  RuleContextUnit? currentUnit;

  @override
  final WorkspacePackage? package;

  @override
  final TypeProvider typeProvider;

  @override
  final TypeSystem typeSystem;

  RuleContextWithResolvedResults(
    this.allUnits,
    this.definingUnit,
    this.typeProvider,
    this.typeSystem,
    this.package,
  );

  @override
  bool get isInLibDir =>
      _isInLibDir(definingUnit.unit.declaredFragment?.source.fullName, package);

  @override
  bool get isInTestDirectory {
    if (package case var package?) {
      var file = definingUnit.file;
      return package.isInTestDirectory(file);
    }
    return false;
  }

  @override
  LibraryElement get libraryElement =>
      definingUnit.unit.declaredFragment!.element;

  @override
  bool isFeatureEnabled(Feature feature) =>
      libraryElement.featureSet.isEnabled(feature);
}
