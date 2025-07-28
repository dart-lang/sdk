// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_client/protocol.dart';
import 'package:analysis_server_client/server.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:analyzer_utilities/tools.dart';
import 'package:path/path.dart';

void main() async {
  await GeneratedContent.generateAll(pkg_root.packageRoot, allTargets);
}

List<GeneratedContent> get allTargets {
  return <GeneratedContent>[
    GeneratedFile('analyzer/lib/dart/ast/visitor.g.dart', (pkgRoot) async {
      var generator = _VisitorGenerator();
      return await generator.generate();
    }),
  ];
}

class _VisitorGenerator {
  final out = StringBuffer('''
// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Run 'dart pkg/analyzer/tool/ast/generate.dart' to update.

part of 'visitor.dart';
''');

  String get analyzerPath => normalize(join(pkg_root.packageRoot, 'analyzer'));

  Future<String> generate() async {
    var astLibrary = await _getAstLibrary();

    _writeRecursive(astLibrary);
    _writeSimple(astLibrary);
    _writeThrowing(astLibrary);
    _writeUnifying(astLibrary);

    var resultPath = normalize(
      join(analyzerPath, 'lib', 'dart', 'ast', 'visitor.g.dart'),
    );
    return _formatSortCode(resultPath, out.toString());
  }

  Future<LibraryElement> _getAstLibrary() async {
    var collection = AnalysisContextCollection(includedPaths: [analyzerPath]);
    var analysisContext = collection.contextFor(analyzerPath);
    var analysisSession = analysisContext.currentSession;

    var libraryResult = await analysisSession.getLibraryByUri(
      'package:analyzer/src/dart/ast/ast.dart',
    );
    libraryResult as LibraryElementResult;
    return libraryResult.element;
  }

  void _writeRecursive(LibraryElement astLibrary) {
    out.writeln(r'''
/// An AST visitor that will recursively visit all of the nodes in an AST
/// structure. For example, using an instance of this class to visit a [Block]
/// will also cause all of the statements in the block to be visited.
///
/// Subclasses that override a visit method must either invoke the overridden
/// visit method or must explicitly ask the visited node to visit its children.
/// Failure to do so will cause the children of the visited node to not be
/// visited.
///
/// Clients may extend this class.
class RecursiveAstVisitor<R> implements AstVisitor<R> {
  /// Initialize a newly created visitor.
  const RecursiveAstVisitor();
''');
    for (var classElement in astLibrary.classes) {
      if (classElement.isAstNodeImpl && !classElement.isAbstract) {
        var interfaceName = classElement.name!.removeSuffix('Impl');
        out.writeln('''
  @override
  R? visit$interfaceName($interfaceName node) {
    node.visitChildren(this);
    return null;
  }
''');
      }
    }
    out.writeln('}');
  }

  void _writeSimple(LibraryElement astLibrary) {
    out.write('''
/// An AST visitor that will do nothing when visiting an AST node. It is
/// intended to be a superclass for classes that use the visitor pattern
/// primarily as a dispatch mechanism (and hence don't need to recursively visit
/// a whole structure) and that only need to visit a small number of node types.
///
/// Clients may extend this class.
class SimpleAstVisitor<R> implements AstVisitor<R> {
  /// Initialize a newly created visitor.
  const SimpleAstVisitor();
''');
    for (var classElement in astLibrary.classes) {
      if (classElement.isAstNodeImpl && !classElement.isAbstract) {
        var interfaceName = classElement.name!.removeSuffix('Impl');
        out.writeln('''
  @override
  R? visit$interfaceName($interfaceName node) => null;
''');
      }
    }
    out.writeln('}');
  }

  void _writeThrowing(LibraryElement astLibrary) {
    out.writeln(r'''
/// An AST visitor that will throw an exception if any of the visit methods that
/// are invoked have not been overridden. It is intended to be a superclass for
/// classes that implement the visitor pattern and need to (a) override all of
/// the visit methods or (b) need to override a subset of the visit method and
/// want to catch when any other visit methods have been invoked.
///
/// Clients may extend this class.
class ThrowingAstVisitor<R> implements AstVisitor<R> {
  /// Initialize a newly created visitor.
  const ThrowingAstVisitor();

  Never _throw(AstNode node) {
    var typeName = node.runtimeType.toString();
    if (typeName.endsWith('Impl')) {
      typeName = typeName.substring(0, typeName.length - 4);
    }
    throw Exception('Missing implementation of visit$typeName');
  }
''');
    for (var classElement in astLibrary.classes) {
      if (classElement.isAstNodeImpl && !classElement.isAbstract) {
        var interfaceName = classElement.name!.removeSuffix('Impl');
        out.writeln('''
  @override
  R? visit$interfaceName($interfaceName node) => _throw(node);
''');
      }
    }
    out.writeln('}');
  }

  void _writeUnifying(LibraryElement astLibrary) {
    out.writeln(r'''
/// An AST visitor that will recursively visit all of the nodes in an AST
/// structure (like instances of the class [RecursiveAstVisitor]). In addition,
/// every node will also be visited by using a single unified [visitNode]
/// method.
///
/// Subclasses that override a visit method must either invoke the overridden
/// visit method or explicitly invoke the more general [visitNode] method.
/// Failure to do so will cause the children of the visited node to not be
/// visited.
///
/// Clients may extend this class.
class UnifyingAstVisitor<R> implements AstVisitor<R> {
  /// Initialize a newly created visitor.
  const UnifyingAstVisitor();

  R? visitNode(AstNode node) {
    node.visitChildren(this);
    return null;
  }
''');
    for (var classElement in astLibrary.classes) {
      if (classElement.isAstNodeImpl && !classElement.isAbstract) {
        var interfaceName = classElement.name!.removeSuffix('Impl');
        out.writeln('''
  @override
  R? visit$interfaceName($interfaceName node) => visitNode(node);
''');
      }
    }
    out.writeln('}');
  }

  static Future<String> _formatSortCode(String path, String code) async {
    var server = Server();
    await server.start();
    server.listenToOutput();

    await server.send('analysis.setAnalysisRoots', {
      'included': [path],
      'excluded': [],
    });

    Future<void> updateContent() async {
      await server.send('analysis.updateContent', {
        'files': {
          path: {'type': 'add', 'content': code},
        },
      });
    }

    await updateContent();
    var formatResponse = await server.send('edit.format', {
      'file': path,
      'selectionOffset': 0,
      'selectionLength': code.length,
    });
    var formatResult = EditFormatResult.fromJson(
      ResponseDecoder(null),
      'result',
      formatResponse,
    );
    code = SourceEdit.applySequence(code, formatResult.edits);

    await updateContent();
    var sortResponse = await server.send('edit.sortMembers', {'file': path});
    var sortResult = EditSortMembersResult.fromJson(
      ResponseDecoder(null),
      'result',
      sortResponse,
    );
    code = SourceEdit.applySequence(code, sortResult.edit.edits);

    await server.kill();
    return code;
  }
}

extension on ClassElement {
  bool get isAstNodeImpl {
    // Not a real AST node.
    if (name == 'ConstantContextForExpressionImpl') {
      return false;
    }
    return allSupertypes.any((type) => type.element.name == 'AstNodeImpl');
  }
}
