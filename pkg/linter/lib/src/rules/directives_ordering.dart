// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Adhere to Effective Dart Guide directives sorting conventions.';

const _docImportKeyword = '@docImport';

const _exportKeyword = 'export';

const _importKeyword = 'import';

/// Compares directives by package name, then file name in the package.
///
/// The package name is everything until the first '/'.
int compareDirectives(String a, String b) {
  if (!a.startsWith('package:') || !b.startsWith('package:')) {
    if (!a.startsWith('/') && !b.startsWith('/')) {
      return a.compareTo(b);
    }
  }
  var indexA = a.indexOf('/');
  var indexB = b.indexOf('/');
  if (indexA == -1 || indexB == -1) return a.compareTo(b);
  var result = a.substring(0, indexA).compareTo(b.substring(0, indexB));
  if (result != 0) return result;
  return a.substring(indexA + 1).compareTo(b.substring(indexB + 1));
}

bool _isAbsoluteDirective(NamespaceDirective node) {
  var uriContent = node.uri.stringValue;
  return uriContent != null && uriContent.contains(':');
}

bool _isDartDirective(NamespaceDirective node) {
  var uriContent = node.uri.stringValue;
  return uriContent != null && uriContent.startsWith('dart:');
}

bool _isExportDirective(Directive node) => node is ExportDirective;

bool _isNotDartDirective(NamespaceDirective node) => !_isDartDirective(node);

bool _isPackageDirective(NamespaceDirective node) {
  var uriContent = node.uri.stringValue;
  return uriContent != null && uriContent.startsWith('package:');
}

bool _isPartDirective(Directive node) => node is PartDirective;

bool _isRelativeDirective(NamespaceDirective node) =>
    !_isAbsoluteDirective(node);

class DirectivesOrdering extends LintRule {
  static const List<LintCode> allCodes = [
    LinterLintCode.directives_ordering_alphabetical,
    LinterLintCode.directives_ordering_dart,
    LinterLintCode.directives_ordering_exports,
    LinterLintCode.directives_ordering_package_before_relative
  ];

  DirectivesOrdering()
      : super(
          name: LintNames.directives_ordering,
          description: _desc,
        );

  @override
  List<LintCode> get lintCodes => allCodes;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }

  void _reportLintWithDartDirectiveGoFirstMessage(AstNode node, String type) {
    reportLint(node,
        errorCode: LinterLintCode.directives_ordering_dart, arguments: [type]);
  }

  void _reportLintWithDirectiveSectionOrderedAlphabeticallyMessage(
      AstNode node) {
    reportLint(node,
        errorCode: LinterLintCode.directives_ordering_alphabetical);
  }

  void _reportLintWithExportDirectiveAfterImportDirectiveMessage(AstNode node) {
    reportLint(node, errorCode: LinterLintCode.directives_ordering_exports);
  }

  void _reportLintWithPackageDirectiveBeforeRelativeMessage(
      AstNode node, String type) {
    reportLint(node,
        errorCode: LinterLintCode.directives_ordering_package_before_relative,
        arguments: [type]);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final DirectivesOrdering rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    var lintedNodes = <AstNode>{};
    _checkDartDirectiveGoFirst(lintedNodes, node);
    _checkPackageDirectiveBeforeRelative(lintedNodes, node);
    _checkExportDirectiveAfterImportDirective(lintedNodes, node);
    _checkDirectiveSectionOrderedAlphabetically(lintedNodes, node);
  }

  void _checkDartDirectiveGoFirst(
      Set<AstNode> lintedNodes, CompilationUnit node) {
    for (var import in node.importDirectives.withDartUrisSkippingTheFirstSet) {
      if (lintedNodes.add(import)) {
        rule._reportLintWithDartDirectiveGoFirstMessage(import, _importKeyword);
      }
    }

    for (var export in node.exportDirectives.withDartUrisSkippingTheFirstSet) {
      if (lintedNodes.add(export)) {
        rule._reportLintWithDartDirectiveGoFirstMessage(export, _exportKeyword);
      }
    }

    for (var import
        in node.docImportDirectives.withDartUrisSkippingTheFirstSet) {
      if (lintedNodes.add(import)) {
        rule._reportLintWithDartDirectiveGoFirstMessage(
            import, _docImportKeyword);
      }
    }
  }

  void _checkDirectiveSectionOrderedAlphabetically(
      Set<AstNode> lintedNodes, CompilationUnit node) {
    var dartImports = node.importDirectives.where(_isDartDirective);
    var dartExports = node.exportDirectives.where(_isDartDirective);
    var dartDocImports = node.docImportDirectives.where(_isDartDirective);

    _checkSectionInOrder(lintedNodes, dartImports);
    _checkSectionInOrder(lintedNodes, dartExports);
    _checkSectionInOrder(lintedNodes, dartDocImports);

    var relativeImports = node.importDirectives.where(_isRelativeDirective);
    var relativeExports = node.exportDirectives.where(_isRelativeDirective);
    var relativeDocImports =
        node.docImportDirectives.where(_isRelativeDirective);

    _checkSectionInOrder(lintedNodes, relativeImports);
    _checkSectionInOrder(lintedNodes, relativeExports);
    _checkSectionInOrder(lintedNodes, relativeDocImports);

    // See: https://github.com/dart-lang/linter/issues/3395
    // (`DartProject` removal)
    // The rub is that *all* projects are being treated as "not pub"
    // packages.  We'll want to be careful when fixing this since it
    // will have ecosystem impact.

    // Not a pub package. Package directives should be sorted in one block.
    var packageImports = node.importDirectives.where(_isPackageDirective);
    var packageExports = node.exportDirectives.where(_isPackageDirective);
    var packageDocImports = node.docImportDirectives.where(_isPackageDirective);

    _checkSectionInOrder(lintedNodes, packageImports);
    _checkSectionInOrder(lintedNodes, packageExports);
    _checkSectionInOrder(lintedNodes, packageDocImports);

    // The following is relying on projectName which is meant to come from
    // a `DartProject` instance (but was not since the project was always null)
    // else {
    //   var packageBox = _PackageBox(projectName);
    //
    //   var thirdPartyPackageImports =
    //       importDirectives.where(packageBox._isNotOwnPackageDirective);
    //   var thirdPartyPackageExports =
    //       exportDirectives.where(packageBox._isNotOwnPackageDirective);
    //
    //   var ownPackageImports =
    //       importDirectives.where(packageBox._isOwnPackageDirective);
    //   var ownPackageExports =
    //       exportDirectives.where(packageBox._isOwnPackageDirective);
    //
    //   _checkSectionInOrder(lintedNodes, thirdPartyPackageImports);
    //   _checkSectionInOrder(lintedNodes, thirdPartyPackageExports);
    //
    //   _checkSectionInOrder(lintedNodes, ownPackageImports);
    //   _checkSectionInOrder(lintedNodes, ownPackageExports);
    // }
  }

  void _checkExportDirectiveAfterImportDirective(
      Set<AstNode> lintedNodes, CompilationUnit node) {
    for (var directive in node.directives.reversed
        .skipWhile(_isPartDirective)
        .skipWhile(_isExportDirective)
        .where(_isExportDirective)) {
      if (lintedNodes.add(directive)) {
        rule._reportLintWithExportDirectiveAfterImportDirectiveMessage(
            directive);
      }
    }
  }

  void _checkPackageDirectiveBeforeRelative(
      Set<AstNode> lintedNodes, CompilationUnit node) {
    for (var import
        in node.importDirectives.withPackageUrisSkippingAbsoluteUris) {
      if (lintedNodes.add(import)) {
        rule._reportLintWithPackageDirectiveBeforeRelativeMessage(
            import, _importKeyword);
      }
    }

    for (var export
        in node.exportDirectives.withPackageUrisSkippingAbsoluteUris) {
      if (lintedNodes.add(export)) {
        rule._reportLintWithPackageDirectiveBeforeRelativeMessage(
            export, _exportKeyword);
      }
    }

    for (var import
        in node.docImportDirectives.withPackageUrisSkippingAbsoluteUris) {
      if (lintedNodes.add(import)) {
        rule._reportLintWithPackageDirectiveBeforeRelativeMessage(
            import, _docImportKeyword);
      }
    }
  }

  void _checkSectionInOrder(
      Set<AstNode> lintedNodes, Iterable<UriBasedDirective> nodes) {
    if (nodes.isEmpty) return;

    var previousUri = nodes.first.uri.stringValue;
    for (var directive in nodes.skip(1)) {
      var directiveUri = directive.uri.stringValue;
      if (previousUri != null &&
          directiveUri != null &&
          compareDirectives(previousUri, directiveUri) > 0) {
        if (lintedNodes.add(directive)) {
          rule._reportLintWithDirectiveSectionOrderedAlphabeticallyMessage(
              directive);
        }
      }
      previousUri = directive.uri.stringValue;
    }
  }
}

extension on CompilationUnit {
  Iterable<ImportDirective> get docImportDirectives {
    var libraryDirective = directives.whereType<LibraryDirective>().firstOrNull;
    if (libraryDirective == null) return const [];
    var docComment = libraryDirective.documentationComment;
    if (docComment == null) return const [];
    return docComment.docImports.map((e) => e.import);
  }

  Iterable<ExportDirective> get exportDirectives =>
      directives.whereType<ExportDirective>();

  Iterable<ImportDirective> get importDirectives =>
      directives.whereType<ImportDirective>();
}

extension on Iterable<NamespaceDirective> {
  /// The directives with 'dart:' URIs, skipping the first such set of
  /// directives.
  Iterable<NamespaceDirective> get withDartUrisSkippingTheFirstSet =>
      skipWhile(_isDartDirective).where(_isDartDirective);

  /// The directives with 'package:' URIs, after the first set of directives
  /// with absolute URIs.
  Iterable<NamespaceDirective> get withPackageUrisSkippingAbsoluteUris =>
      where(_isNotDartDirective)
          .skipWhile(_isAbsoluteDirective)
          .where(_isPackageDirective);
}
