// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/element/element.dart'; // ignore: implementation_imports
import 'package:analyzer/src/dart/element/type_visitor.dart'; // ignore: implementation_imports

import '../analyzer.dart';

const _desc = r'Use new element model in opted-in files.';

bool _isOldModelElement(Element2? element) {
  var firstFragment = element?.firstFragment;
  if (firstFragment != null) {
    var libraryFragment = firstFragment.libraryFragment;
    var uriStr = libraryFragment.source.uri.toString();
    if (uriStr == 'package:analyzer/dart/element/element.dart') {
      // Skip classes that don't required migration.
      if (const {
        'DirectiveUri',
        'DirectiveUriWithRelativeUri',
        'DirectiveUriWithRelativeUriString',
        'DirectiveUriWithSource',
        'ElementAnnotation',
        'ElementKind',
        'ElementLocation',
      }.contains(firstFragment.name)) {
        return false;
      }
      return true;
    }
  }
  return false;
}

bool _isOldModelType(DartType? type) {
  var visitor = _TypeVisitor();
  type?.accept(visitor);
  return visitor.result;
}

/// The lint must be enabled for a Pub package.
///
/// The lint rule reads once the file `analyzer_use_new_elements.txt`
/// from the root of the package (next to `pubspec.yaml`). Then it uses
/// the content of the file until DAS is restarted.
///
/// The file should have path prefixes from the root of the package.
/// For example `lib/src/services/correction/dart/add_async.dart` as a line.
/// It could be also the whole directory: `lib/src/services/correction/dart/`.
/// These are just path prefixes, not regular expressions.
///
/// When you start migrating a Dart file, add it to the opt-in file, restart
/// DAS, and open the file in your IDE.
class AnalyzerUseNewElements extends LintRule {
  static const LintCode code = LintCode(
    'analyzer_use_new_elements',
    'This code uses the old analyzer element model.',
    correctionMessage: 'Try using the new elements.',
  );

  /// Whether to use or bypass the opt-in file.
  bool useOptInFile;

  AnalyzerUseNewElements({
    this.useOptInFile = true,
  }) : super(
          name: code.name,
          description: _desc,
          state: State.internal(),
        );

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    if (!_isEnabledForFile(context)) {
      return;
    }

    var visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
    registry.addNamedType(this, visitor);
    registry.addSimpleIdentifier(this, visitor);
  }

  bool _isEnabledForFile(LinterContext context) {
    if (!useOptInFile) {
      return true;
    }

    if (context.package case PubPackage pubPackage) {
      if (_FilesRegistry.get(pubPackage) case var filesRegistry?) {
        var file = context.definingUnit.file;
        return filesRegistry.isEnabled(file);
      }
    }
    return false;
  }

  static void resetCaches() {
    _FilesRegistry._registry.clear();
  }
}

class _FilesRegistry {
  static final Map<Folder, _FilesRegistry?> _registry = {};

  final Folder rootFolder;
  final List<String> prefixes;
  final Map<File, bool> _fileResults = {};

  _FilesRegistry({
    required this.rootFolder,
    required this.prefixes,
  });

  bool isEnabled(File file) => _fileResults[file] ??= _computeEnabled(file);

  bool _computeEnabled(File file) {
    var rootPath = rootFolder.path;
    if (!file.path.startsWith(rootPath)) {
      return false;
    }

    var relativePath = file.path.substring(rootPath.length + 1);
    return _fileResults[file] ??=
        prefixes.any((prefix) => relativePath.startsWith(prefix));
  }

  /// Note, we cache statically, to reload restart the server.
  static _FilesRegistry? get(PubPackage pubPackage) {
    var rootFolder = pubPackage.pubspecFile.parent;
    var separator = rootFolder.provider.pathContext.separator;

    if (_registry.containsKey(rootFolder)) {
      return _registry[rootFolder];
    }

    try {
      // TODO(scheglov): include this file into the results signature.
      var lines = rootFolder
          .getChildAssumingFile('analyzer_use_new_elements.txt')
          .readAsStringSync()
          .trim()
          .split('\n')
          // The file always uses forward slashes, so convert to the correct
          // slash for this platform.
          .map((line) => line.trim().replaceAll('/', separator))
          .toList();
      var result = _FilesRegistry(
        rootFolder: rootFolder,
        prefixes: lines,
      );
      return _registry[rootFolder] = result;
    } on FileSystemException {
      return null;
    }
  }
}

class _TypeVisitor extends RecursiveTypeVisitor {
  bool result = false;

  @override
  bool visitInterfaceType(InterfaceType type) {
    result |= _isOldModelElement(type.element3);
    return super.visitInterfaceType(type);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  visitMethodInvocation(MethodInvocation node) {
    if (_isOldModelType(node.staticType)) {
      rule.reportLint(node.methodName);
    }
  }

  @override
  visitNamedType(NamedType node) {
    if (_isOldModelElement(node.element2)) {
      rule.reportLintForToken(node.name2);
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.parent case MethodInvocation invocation) {
      if (invocation.methodName == node) {
        return;
      }
    }

    if (_isOldModelType(node.staticType)) {
      rule.reportLint(node);
    }
  }
}

extension on Element2 {
  Fragment? get firstFragment {
    switch (this) {
      case FragmentedElementMixin fragmented:
        return fragmented.firstFragment;
      case AugmentedInstanceElement fragmented:
        return fragmented.declaration as Fragment;
    }
    return null;
  }
}
