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
  /// be checked. Use [checkFutureAndStream] to access this field.
  bool _checkFutureAndStream;

  /// A cached flag indicating whether references to set literals need to
  /// be checked. Use [checkSetLiterals] to access this field.
  bool _checkSetLiterals;

  /// A flag indicating whether we are visiting code inside a set literal. Used
  /// to prevent over-reporting uses of set literals.
  bool _inSetLiteral = false;

  /// A cached flag indicating whether references to the ui-as-code features
  /// need to be checked. Use [checkUiAsCode] to access this field.
  bool _checkUiAsCode;

  /// A flag indicating whether we are visiting code inside one of the
  /// ui-as-code features. Used to prevent over-reporting uses of these
  /// features.
  bool _inUiAsCode = false;

  /// Initialize a newly created verifier to use the given [_errorReporter] to
  /// report errors.
  SdkConstraintVerifier(this._errorReporter, this._containingLibrary,
      this._typeProvider, this._versionConstraint);

  /// Return a range covering every version up to, but not including, 2.1.0.
  VersionRange get before_2_1_0 =>
      new VersionRange(max: Version.parse('2.1.0'), includeMax: false);

  /// Return a range covering every version up to, but not including, 2.2.0.
  VersionRange get before_2_2_0 =>
      new VersionRange(max: Version.parse('2.2.0'), includeMax: false);

  /// Return a range covering every version up to, but not including, 2.2.2.
  VersionRange get before_2_2_2 =>
      new VersionRange(max: Version.parse('2.2.2'), includeMax: false);

  /// Return `true` if references to Future and Stream need to be checked.
  bool get checkFutureAndStream => _checkFutureAndStream ??=
      !before_2_1_0.intersect(_versionConstraint).isEmpty;

  /// Return `true` if references to set literals need to be checked.
  bool get checkSetLiterals =>
      _checkSetLiterals ??= !before_2_2_0.intersect(_versionConstraint).isEmpty;

  /// Return `true` if references to the ui-as-code features (control flow and
  /// spread collections) need to be checked.
  bool get checkUiAsCode =>
      _checkUiAsCode ??= !before_2_2_2.intersect(_versionConstraint).isEmpty;

  @override
  void visitForElement(ForElement node) {
    _validateUiAsCode(node);
    bool wasInUiAsCode = _inUiAsCode;
    _inUiAsCode = true;
    super.visitForElement(node);
    _inUiAsCode = wasInUiAsCode;
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    // Don't flag references to either `Future` or `Stream` within a combinator.
  }

  @override
  void visitIfElement(IfElement node) {
    _validateUiAsCode(node);
    bool wasInUiAsCode = _inUiAsCode;
    _inUiAsCode = true;
    super.visitIfElement(node);
    _inUiAsCode = wasInUiAsCode;
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    if (node.isSet && checkSetLiterals && !_inSetLiteral) {
      _errorReporter.reportErrorForNode(HintCode.SDK_VERSION_SET_LITERAL, node);
    }
    bool wasInSetLiteral = _inSetLiteral;
    _inSetLiteral = true;
    super.visitSetOrMapLiteral(node);
    _inSetLiteral = wasInSetLiteral;
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

  @override
  void visitSpreadElement(SpreadElement node) {
    _validateUiAsCode(node);
    bool wasInUiAsCode = _inUiAsCode;
    _inUiAsCode = true;
    super.visitSpreadElement(node);
    _inUiAsCode = wasInUiAsCode;
  }

  /// Given that the [node] is only valid when the ui-as-code feature is
  /// enabled, check that the code will not be executed with a version of the
  /// SDK that does not support the feature.
  void _validateUiAsCode(AstNode node) {
    if (checkUiAsCode && !_inUiAsCode) {
      _errorReporter.reportErrorForNode(HintCode.SDK_VERSION_UI_AS_CODE, node);
    }
  }
}
