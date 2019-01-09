// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:pub_semver/pub_semver.dart';

/// A visitor that finds code that assumes a later version of the SDK than the
/// minimum version required by the SDK constraints in `pubspec.yaml`.
class SdkConstraintVerifier extends RecursiveAstVisitor<void> {
  /// The error reporter to be used to report errors.
  final ErrorReporter _errorReporter;

  /// The element representing the library containing the unit to be verified.
  final LibraryElement _containingLibrary;

  /// The typ provider used to access SDK types.
  final TypeProvider _typeProvider;

  /// The version constraint for the SDK.
  final VersionConstraint _versionConstraint;

  /// A cached flag indicating whether references to Future and Stream need to
  /// be checked. Use [] to access this field.
  bool _checkFutureAndStream;

  /// Initialize a newly created verifier to use the given [_errorReporter] to
  /// report errors.
  SdkConstraintVerifier(this._errorReporter, this._containingLibrary,
      this._typeProvider, this._versionConstraint);

  /// Return a range covering every version up to, but not including, 2.1.0.
  VersionRange get before_2_1_0 =>
      new VersionRange(max: Version.parse('2.1.0'), includeMax: false);

  /// Return `true` if references to Future and Stream need to be checked.
  bool get checkFutureAndStream => _checkFutureAndStream ??=
      !before_2_1_0.intersect(_versionConstraint).isEmpty;

  @override
  void visitHideCombinator(HideCombinator node) {
    // Don't flag references to either `Future` or `Stream` within a combinator.
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    // Don't flag references to either `Future` or `Stream` within a combinator.
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      return;
    }
    Element element = node.staticElement;
    if (checkFutureAndStream &&
        (element == _typeProvider.futureType.element ||
            element == _typeProvider.streamType.element)) {
      for (LibraryElement importedLibrary
          in _containingLibrary.importedLibraries) {
        if (!importedLibrary.isDartCore) {
          Namespace namespace = importedLibrary.exportNamespace;
          if (namespace != null && namespace.get(element.name) != null) {
            return;
          }
        }
      }
      _errorReporter.reportErrorForNode(
          HintCode.SDK_VERSION_ASYNC_EXPORTED_FROM_CORE, node, [element.name]);
    }
  }
}
