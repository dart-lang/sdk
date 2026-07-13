// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_client/protocol.dart';
import 'package:analysis_server_client/server.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:analyzer_utilities/tools.dart';
import 'package:path/path.dart';

void main() async {
  await GeneratedContent.generateAll(pkg_root.packageRoot, await allTargets);
}

const _astVersionPolicy = _AstVersionPolicy.v2MigrationSdk;

Future<List<GeneratedContent>> get allTargets async {
  var astLibrary = await _getAstLibrary();
  return <GeneratedContent>[
    GeneratedFile('analyzer/lib/dart/ast/visitor.g.dart', (_) async {
      var generator = _ConcreteAstVisitorGenerator(astLibrary);
      return await generator.generate();
    }),
    GeneratedFile('analyzer/lib/src/dart/ast/ast.g.dart', (_) async {
      var generator = _AstVisitorGenerator(astLibrary);
      return await generator.generate();
    }),
    GeneratedFile('analyzer/lib/src/lint/linter_visitor.g.dart', (_) async {
      var generator = _LinterVisitorGenerator(astLibrary);
      return await generator.generate();
    }),
    GeneratedFile('analyzer/lib/analysis_rule/rule_visitor_registry.g.dart', (
      _,
    ) async {
      var generator = _RuleVisitorGenerator(astLibrary);
      return await generator.generate();
    }),
  ];
}

String get _analyzerPath => normalize(join(pkg_root.packageRoot, 'analyzer'));

Future<String> _formatSortCode(String path, String code) async {
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

Future<LibraryElement> _getAstLibrary() async {
  var collection = AnalysisContextCollection(includedPaths: [_analyzerPath]);
  var analysisContext = collection.contextFor(_analyzerPath);
  var analysisSession = analysisContext.currentSession;

  var libraryResult = await analysisSession.getLibraryByUri(
    'package:analyzer/src/dart/ast/ast.dart',
  );
  libraryResult as LibraryElementResult;
  return libraryResult.element;
}

void _writeV2ExperimentalAnnotation(StringBuffer out) {
  if (_astVersionPolicy.v2ApiIsExperimental) {
    out.write('@experimental\n');
  }
}

enum _AstNodeApi { v1, v2, shared }

enum _AstVersionPolicy {
  /// Generates only the canonical, unsuffixed V1 AST API, with no V2 tree view
  /// or V1 compatibility projection.
  v1Only,

  /// Generates the dual tree views used while migrating SDK code: V2 is the
  /// experimental implementation view, and V1 projection APIs are deprecated
  /// so that their remaining SDK uses are reported.
  v2MigrationSdk,

  /// Generates the dual tree views for publication while V2 is experimental;
  /// V1 projection APIs are marked `@ToBeDeprecated` rather than directing
  /// clients to experimental replacements.
  v2MigrationPublishExperimental,

  /// Generates the dual tree views once V2 is stable: V2 is the public
  /// replacement view, and V1 projection APIs are deprecated.
  v2MigrationPublishStable,

  /// Generates the canonical, unsuffixed V1 tree after rebaseline; any
  /// retained V2 APIs are aliases to that tree, not a separate tree view.
  v2AliasesOnly;

  bool get hasV2TreeApi {
    return switch (this) {
      v1Only => false,
      v2MigrationSdk => true,
      v2MigrationPublishExperimental => true,
      v2MigrationPublishStable => true,
      v2AliasesOnly => false,
    };
  }

  bool get v2ApiIsExperimental {
    return switch (this) {
      v1Only => false,
      v2MigrationSdk => true,
      v2MigrationPublishExperimental => true,
      v2MigrationPublishStable => false,
      v2AliasesOnly => false,
    };
  }
}

class _AstVisitorGenerator {
  final LibraryElement astLibrary;

  final StringBuffer out = StringBuffer('''
// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Run 'dart pkg/analyzer/tool/ast/generate.dart' to update.

part of 'ast.dart';
''');

  _AstVisitorGenerator(this.astLibrary);

  Future<String> generate() async {
    _writeAstVisitor();
    _writeAstVisitor2();

    var resultPath = normalize(
      join(_analyzerPath, 'lib', 'src', 'dart', 'ast', 'ast.g.dart'),
    );
    return _formatSortCode(resultPath, out.toString());
  }

  void _writeAstVisitor() {
    out.write('''
/// An object that can be used to visit an AST structure.
///
/// Clients may not extend, implement or mix-in this class. There are classes
/// that implement this interface that provide useful default behaviors in
/// `package:analyzer/dart/ast/visitor.dart`. A couple of the most useful
/// include
/// - SimpleAstVisitor which implements every visit method by doing nothing,
/// - RecursiveAstVisitor which causes every node in a structure to be visited,
///   and
/// - ThrowingAstVisitor which implements every visit method by throwing an
///   exception.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract class AstVisitor<R> {
''');
    for (var node in astLibrary.nodes) {
      if (node.isConcrete && node.isV1ViewNode) {
        var name = node.apiElementName;
        if (node.isExperimental) {
          out.writeln('  @experimental');
        }
        if (node.isDeprecated) {
          out.writeln('  // ignore: deprecated_member_use_from_same_package');
        }
        out.writeln('''
  R? visit$name($name node);
''');
      }
    }
    out.writeln('}');
  }

  void _writeAstVisitor2() {
    if (!_astVersionPolicy.hasV2TreeApi) {
      return;
    }
    out.write('''
/// An object that can be used to visit an AST structure.
///
/// Clients may not extend, implement or mix-in this class. There are classes
/// that implement this interface that provide useful default behaviors in
/// `package:analyzer/dart/ast/visitor.dart`. A couple of the most useful
/// include
/// - SimpleAstVisitor2 which implements every visit method by doing nothing,
/// - RecursiveAstVisitor2 which causes every node in a structure to be visited,
///   and
/// - ThrowingAstVisitor2 which implements every visit method by throwing an
///   exception.
''');
    _writeV2ExperimentalAnnotation(out);
    out.write('''
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract class AstVisitor2<R> {
''');
    for (var node in astLibrary.nodes) {
      if (node.isConcrete && node.isV2ViewNode) {
        var name = node.apiElementName;
        if (node.isExperimental) {
          out.writeln('  @experimental');
        }
        if (node.isDeprecated) {
          out.writeln('  // ignore: deprecated_member_use_from_same_package');
        }
        out.writeln('''
  R? visit$name($name node);
''');
      }
    }
    out.writeln('}');
  }
}

class _ConcreteAstVisitorGenerator {
  final LibraryElement astLibrary;

  final StringBuffer out = StringBuffer('''
// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Run 'dart pkg/analyzer/tool/ast/generate.dart' to update.

part of 'visitor.dart';
''');

  _ConcreteAstVisitorGenerator(this.astLibrary);

  Future<String> generate() async {
    _writeGeneralizing();
    _writeGeneralizing2();
    _writeRecursive();
    _writeRecursive2();
    _writeSimple();
    _writeSimple2();
    _writeTimed();
    _writeTimed2();
    _writeThrowing();
    _writeThrowing2();
    _writeUnifying();
    _writeUnifying2();

    var resultPath = normalize(
      join(_analyzerPath, 'lib', 'dart', 'ast', 'visitor.g.dart'),
    );
    return _formatSortCode(resultPath, out.toString());
  }

  void _writeGeneralizing() {
    out.write('''
/// An AST visitor that will recursively visit all of the nodes in an AST
/// structure (like instances of the class [RecursiveAstVisitor]). In addition,
/// when a node of a specific type is visited not only will the visit method for
/// that specific type of node be invoked, but additional methods for the
/// superclasses of that node will also be invoked. For example, using an
/// instance of this class to visit a [Block] will cause the method [visitBlock]
/// to be invoked but will also cause the methods [visitStatement] and
/// [visitNode] to be subsequently invoked. This allows visitors to be written
/// that visit all statements without needing to override the visit method for
/// each of the specific subclasses of [Statement].
///
/// Subclasses that override a visit method must either invoke the overridden
/// visit method or explicitly invoke the more general visit method. Failure to
/// do so will cause the visit methods for superclasses of the node to not be
/// invoked and will cause the children of the visited node to not be visited.
///
/// Clients may extend this class.
class GeneralizingAstVisitor<R> implements AstVisitor<R> {
  /// Initialize a newly created visitor.
  const GeneralizingAstVisitor();

  R? visitNode(AstNode node) {
    node.visitChildren(this);
    return null;
  }
''');
    for (var node in astLibrary.nodes) {
      if (!node.isV1ViewNode) {
        continue;
      }
      var name = node.apiElementName;
      var superNode = node.superNode;
      if (superNode == null) {
        continue;
      }
      if (node.isExperimental) {
        out.writeln('@experimental');
      }
      if (node.isConcrete) {
        out.writeln('@override');
      }

      if (node.isDeprecated) {
        out.writeln('  // ignore: deprecated_member_use_from_same_package');
      }

      // TODO(fshcheglov): Remove special case after AST hierarchy is fixed.
      // https://github.com/dart-lang/sdk/issues/61224
      if (node.apiElementName == 'FunctionDeclaration') {
        out.writeln(r'''
R? visitFunctionDeclaration(FunctionDeclaration node) {
  if (node.parent is FunctionDeclarationStatement) {
    return visitNode(node);
  }
  return visitCompilationUnitMember(node);
}''');
        continue;
      }

      if (superNode.implElement.isAstNodeImplExactly) {
        out.writeln('''
R? visit$name($name node) => visitNode(node);
''');
      } else {
        out.writeln('''
R? visit$name($name node) => visit${superNode.apiElementName}(node);
''');
      }
    }
    out.writeln('}');
  }

  void _writeGeneralizing2() {
    if (!_astVersionPolicy.hasV2TreeApi) {
      return;
    }
    out.write('''
/// An AST visitor that will recursively visit all of the nodes in an AST
/// structure (like instances of the class [RecursiveAstVisitor2]). In addition,
/// when a node of a specific type is visited not only will the visit method for
/// that specific type of node be invoked, but additional methods for the
/// superclasses of that node will also be invoked. For example, using an
/// instance of this class to visit a [Block] will cause the method [visitBlock]
/// to be invoked but will also cause the methods [visitStatement] and
/// [visitNode] to be subsequently invoked. This allows visitors to be written
/// that visit all statements without needing to override the visit method for
/// each of the specific subclasses of [Statement].
///
/// Subclasses that override a visit method must either invoke the overridden
/// visit method or explicitly invoke the more general visit method. Failure to
/// do so will cause the visit methods for superclasses of the node to not be
/// invoked and will cause the children of the visited node to not be visited.
///
/// Clients may extend this class.
''');
    _writeV2ExperimentalAnnotation(out);
    out.write('''
class GeneralizingAstVisitor2<R> implements AstVisitor2<R> {
  /// Initialize a newly created visitor.
  const GeneralizingAstVisitor2();

  R? visitNode(AstNode node) {
    node.visitChildren2(this);
    return null;
  }
''');
    for (var node in astLibrary.nodes) {
      if (!node.isV2ViewNode) {
        continue;
      }
      var name = node.apiElementName;
      var superNode = node.superNode;
      if (superNode == null) {
        continue;
      }
      if (node.isExperimental) {
        out.writeln('@experimental');
      }
      if (node.isConcrete) {
        out.writeln('@override');
      }

      if (node.isDeprecated) {
        out.writeln('  // ignore: deprecated_member_use_from_same_package');
      }

      // TODO(fshcheglov): Remove special case after AST hierarchy is fixed.
      // https://github.com/dart-lang/sdk/issues/61224
      if (node.apiElementName == 'FunctionDeclaration') {
        out.writeln(r'''
R? visitFunctionDeclaration(FunctionDeclaration node) {
  if (node.parent2 is FunctionDeclarationStatement) {
    return visitNode(node);
  }
  return visitCompilationUnitMember(node);
}''');
        continue;
      }

      if (superNode.implElement.isAstNodeImplExactly) {
        out.writeln('''
R? visit$name($name node) => visitNode(node);
''');
      } else {
        out.writeln('''
R? visit$name($name node) => visit${superNode.apiElementName}(node);
''');
      }
    }
    out.writeln('}');
  }

  void _writeRecursive() {
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
    for (var node in astLibrary.nodes) {
      if (node.isConcrete && node.isV1ViewNode) {
        var name = node.apiElementName;
        if (node.isExperimental) {
          out.writeln('  @experimental');
        }
        out.writeln('  @override');
        if (node.isDeprecated) {
          out.writeln('  // ignore: deprecated_member_use_from_same_package');
        }
        out.writeln('''
  R? visit$name($name node) {
    node.visitChildren(this);
    return null;
  }
''');
      }
    }
    out.writeln('}');
  }

  void _writeRecursive2() {
    if (!_astVersionPolicy.hasV2TreeApi) {
      return;
    }
    out.write(r'''
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
''');
    _writeV2ExperimentalAnnotation(out);
    out.writeln(r'''
class RecursiveAstVisitor2<R> implements AstVisitor2<R> {
  /// Initialize a newly created visitor.
  const RecursiveAstVisitor2();
''');
    for (var node in astLibrary.nodes) {
      if (node.isConcrete && node.isV2ViewNode) {
        var name = node.apiElementName;
        if (node.isExperimental) {
          out.writeln('  @experimental');
        }
        out.writeln('  @override');
        if (node.isDeprecated) {
          out.writeln('  // ignore: deprecated_member_use_from_same_package');
        }
        out.writeln('''
  R? visit$name($name node) {
    node.visitChildren2(this);
    return null;
  }
''');
      }
    }
    out.writeln('}');
  }

  void _writeSimple() {
    out.writeln('''
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
    for (var node in astLibrary.nodes) {
      if (node.isConcrete && node.isV1ViewNode) {
        var name = node.apiElementName;
        if (node.isExperimental) {
          out.writeln('  @experimental');
        }
        out.writeln('  @override');
        if (node.isDeprecated) {
          out.writeln('  // ignore: deprecated_member_use_from_same_package');
        }
        out.writeln('''
  R? visit$name($name node) => null;
''');
      }
    }
    out.writeln('}');
  }

  void _writeSimple2() {
    if (!_astVersionPolicy.hasV2TreeApi) {
      return;
    }
    out.write('''
/// An AST visitor that will do nothing when visiting an AST node. It is
/// intended to be a superclass for classes that use the visitor pattern
/// primarily as a dispatch mechanism (and hence don't need to recursively visit
/// a whole structure) and that only need to visit a small number of node types.
///
/// Clients may extend this class.
    ''');
    _writeV2ExperimentalAnnotation(out);
    out.writeln('''
class SimpleAstVisitor2<R> implements AstVisitor2<R> {
  /// Initialize a newly created visitor.
  const SimpleAstVisitor2();
''');
    for (var node in astLibrary.nodes) {
      if (node.isConcrete && node.isV2ViewNode) {
        var name = node.apiElementName;
        if (node.isExperimental) {
          out.writeln('  @experimental');
        }
        out.writeln('  @override');
        if (node.isDeprecated) {
          out.writeln('  // ignore: deprecated_member_use_from_same_package');
        }
        out.writeln('''
  R? visit$name($name node) => null;
''');
      }
    }
    out.writeln('}');
  }

  void _writeThrowing() {
    out.write(r'''
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
    for (var node in astLibrary.nodes) {
      if (node.isConcrete && node.isV1ViewNode) {
        var name = node.apiElementName;
        if (node.isExperimental) {
          out.writeln('  @experimental');
        }
        out.writeln('  @override');
        if (node.isDeprecated) {
          out.writeln('  // ignore: deprecated_member_use_from_same_package');
        }
        out.writeln('''
  R? visit$name($name node) => _throw(node);
''');
      }
    }
    out.writeln('}');
  }

  void _writeThrowing2() {
    if (!_astVersionPolicy.hasV2TreeApi) {
      return;
    }
    out.write(r'''
/// An AST visitor that will throw an exception if any of the visit methods that
/// are invoked have not been overridden. It is intended to be a superclass for
/// classes that implement the visitor pattern and need to (a) override all of
/// the visit methods or (b) need to override a subset of the visit method and
/// want to catch when any other visit methods have been invoked.
///
/// Clients may extend this class.
''');
    _writeV2ExperimentalAnnotation(out);
    out.writeln(r'''
class ThrowingAstVisitor2<R> implements AstVisitor2<R> {
  /// Initialize a newly created visitor.
  const ThrowingAstVisitor2();

  Never _throw(AstNode node) {
    var typeName = node.runtimeType.toString();
    if (typeName.endsWith('Impl')) {
      typeName = typeName.substring(0, typeName.length - 4);
    }
    throw Exception('Missing implementation of visit$typeName');
  }
''');
    for (var node in astLibrary.nodes) {
      if (node.isConcrete && node.isV2ViewNode) {
        var name = node.apiElementName;
        if (node.isExperimental) {
          out.writeln('  @experimental');
        }
        out.writeln('  @override');
        if (node.isDeprecated) {
          out.writeln('  // ignore: deprecated_member_use_from_same_package');
        }
        out.writeln('''
  R? visit$name($name node) => _throw(node);
''');
      }
    }
    out.writeln('}');
  }

  void _writeTimed() {
    out.writeln(r'''
/// An AST visitor that captures visit call timings.
///
/// Clients may not extend, implement or mix-in this class.
class TimedAstVisitor<T> implements AstVisitor<T> {
  /// The base visitor whose visit methods will be timed.
  final AstVisitor<T> _baseVisitor;

  /// Collects elapsed time for visit calls.
  final Stopwatch stopwatch;

  /// Initialize a newly created visitor to time calls to the given base
  /// visitor's visits.
  TimedAstVisitor(this._baseVisitor, [Stopwatch? watch])
    : stopwatch = watch ?? Stopwatch();
''');
    for (var node in astLibrary.nodes) {
      if (node.isConcrete && node.isV1ViewNode) {
        var name = node.apiElementName;
        if (node.isExperimental) {
          out.writeln('  @experimental');
        }
        out.writeln('  @override');
        if (node.isDeprecated) {
          out.writeln('  // ignore: deprecated_member_use_from_same_package');
        }
        out.writeln('''
  T? visit$name($name node) {
    stopwatch.start();
    T? result = _baseVisitor.visit$name(node);
    stopwatch.stop();
    return result;
  }
''');
      }
    }
    out.writeln('}');
  }

  void _writeTimed2() {
    if (!_astVersionPolicy.hasV2TreeApi) {
      return;
    }
    out.write(r'''
/// An AST visitor that captures visit call timings.
///
/// Clients may not extend, implement or mix-in this class.
''');
    _writeV2ExperimentalAnnotation(out);
    out.writeln(r'''
class TimedAstVisitor2<T> implements AstVisitor2<T> {
  /// The base visitor whose visit methods will be timed.
  final AstVisitor2<T> _baseVisitor;

  /// Collects elapsed time for visit calls.
  final Stopwatch stopwatch;

  /// Initialize a newly created visitor to time calls to the given base
  /// visitor's visits.
  TimedAstVisitor2(this._baseVisitor, [Stopwatch? watch])
    : stopwatch = watch ?? Stopwatch();
''');
    for (var node in astLibrary.nodes) {
      if (node.isConcrete && node.isV2ViewNode) {
        var name = node.apiElementName;
        if (node.isExperimental) {
          out.writeln('  @experimental');
        }
        out.writeln('  @override');
        if (node.isDeprecated) {
          out.writeln('  // ignore: deprecated_member_use_from_same_package');
        }
        out.writeln('''
  T? visit$name($name node) {
    stopwatch.start();
    T? result = _baseVisitor.visit$name(node);
    stopwatch.stop();
    return result;
  }
''');
      }
    }
    out.writeln('}');
  }

  void _writeUnifying() {
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
    for (var node in astLibrary.nodes) {
      if (node.isConcrete && node.isV1ViewNode) {
        var name = node.apiElementName;
        if (node.isExperimental) {
          out.writeln('  @experimental');
        }
        out.writeln('  @override');
        if (node.isDeprecated) {
          out.writeln('  // ignore: deprecated_member_use_from_same_package');
        }
        out.writeln('''
  R? visit$name($name node) => visitNode(node);
''');
      }
    }
    out.writeln('}');
  }

  void _writeUnifying2() {
    if (!_astVersionPolicy.hasV2TreeApi) {
      return;
    }
    out.write(r'''
/// An AST visitor that will recursively visit all of the nodes in an AST
/// structure (like instances of the class [RecursiveAstVisitor2]). In addition,
/// every node will also be visited by using a single unified [visitNode]
/// method.
///
/// Subclasses that override a visit method must either invoke the overridden
/// visit method or explicitly invoke the more general [visitNode] method.
/// Failure to do so will cause the children of the visited node to not be
/// visited.
///
/// Clients may extend this class.
''');
    _writeV2ExperimentalAnnotation(out);
    out.writeln(r'''
class UnifyingAstVisitor2<R> implements AstVisitor2<R> {
  /// Initialize a newly created visitor.
  const UnifyingAstVisitor2();

  R? visitNode(AstNode node) {
    node.visitChildren2(this);
    return null;
  }
''');
    for (var node in astLibrary.nodes) {
      if (node.isConcrete && node.isV2ViewNode) {
        var name = node.apiElementName;
        if (node.isExperimental) {
          out.writeln('  @experimental');
        }
        out.writeln('  @override');
        if (node.isDeprecated) {
          out.writeln('  // ignore: deprecated_member_use_from_same_package');
        }
        out.writeln('''
  R? visit$name($name node) => visitNode(node);
''');
      }
    }
    out.writeln('}');
  }
}

class _LinterVisitorGenerator {
  final LibraryElement astLibrary;

  final StringBuffer out = StringBuffer('''
// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Run 'dart pkg/analyzer/tool/ast/generate.dart' to update.

part of 'linter_visitor.dart';
''');

  _LinterVisitorGenerator(this.astLibrary);

  Future<String> generate() async {
    _writeLinterVisitor();
    _writeRuleVisitorRegistryImpl();

    var resultPath = normalize(
      join(_analyzerPath, 'lib', 'src', 'lint', 'linter_visitor.g.dart'),
    );
    return _formatSortCode(resultPath, out.toString());
  }

  void _writeLinterVisitor() {
    out.write('''
/// The AST visitor that runs handlers for nodes from the [_registry].
class AnalysisRuleVisitor implements AstVisitor<void> {
  final RuleVisitorRegistryImpl _registry;

  /// Whether exceptions should be propagated (by rethrowing them).
  final bool _shouldPropagateExceptions;

  AnalysisRuleVisitor(this._registry, {bool shouldPropagateExceptions = false})
      : _shouldPropagateExceptions = shouldPropagateExceptions;

  void afterLibrary() {
    _runAfterLibrarySubscriptions(_registry._afterLibrary);
  }

  void _runAfterLibrarySubscriptions(
    List<_AfterLibrarySubscription> subscriptions,
  ) {
    for (var subscription in subscriptions) {
      var timer = subscription.timer;
      timer?.start();
      subscription.callback();
      timer?.stop();
    }
  }

  void _runSubscriptions<T extends AstNode>(
    T node,
    List<_Subscription<T>> subscriptions,
  ) {
    for (var subscription in subscriptions) {
      var timer = subscription.timer;
      timer?.start();
      try {
        node.accept(subscription.visitor);
      } catch (exception, stackTrace) {
        _logException(node, subscription.rule, exception, stackTrace);
        if (_shouldPropagateExceptions) {
          rethrow;
        }
      }
      timer?.stop();
    }
  }

  /// Handles exceptions that occur during the execution of an [AnalysisRule].
  void _logException(
    AstNode node,
    AbstractAnalysisRule visitor,
    Object exception,
    StackTrace stackTrace,
  ) {
    var buffer = StringBuffer();
    buffer.write('Exception while using a \${visitor.runtimeType} to visit a ');
    AstNode? currentNode = node;
    var first = true;
    while (currentNode != null) {
      if (first) {
        first = false;
      } else {
        buffer.write(' in ');
      }
      buffer.write(currentNode.runtimeType);
      currentNode = currentNode.parent;
    }
    // TODO(39284): should this exception be silent?
    AnalysisEngine.instance.instrumentationService.logException(
      SilentException(buffer.toString(), exception, stackTrace),
    );
  }
''');
    for (var node in astLibrary.nodes) {
      if (node.isConcrete && node.isV1ViewNode) {
        var name = node.apiElementName;
        if (node.isExperimental) {
          out.writeln('  @experimental');
        }
        out.writeln('  @override');
        if (node.isDeprecated) {
          out.writeln('  // ignore: deprecated_member_use_from_same_package');
        }
        out.writeln('''
  void visit$name($name node) {
    _runSubscriptions(node, _registry._for$name);
    node.visitChildren(this);
  }
''');
      }
    }
    out.writeln('}');
  }

  void _writeRuleVisitorRegistryImpl() {
    out.write('''
class RuleVisitorRegistryImpl implements RuleVisitorRegistry {
  final bool _enableTiming;
  final List<_AfterLibrarySubscription> _afterLibrary = [];

  RuleVisitorRegistryImpl({required bool enableTiming})
  : _enableTiming = enableTiming;

  /// Get the timer associated with the given [rule].
  Stopwatch? _getTimer(AbstractAnalysisRule rule) {
    if (_enableTiming) {
      return analysisRuleTimers.getTimer(rule);
    } else {
      return null;
    }
  }

  @override
  void afterLibrary(AbstractAnalysisRule rule, void Function() callback) {
    _afterLibrary.add(
      _AfterLibrarySubscription(rule, callback, _getTimer(rule)),
    );
  }
''');
    for (var node in astLibrary.nodes) {
      if (node.isConcrete && node.isV1ViewNode) {
        var name = node.apiElementName;
        if (node.isDeprecated) {
          out.writeln('  // ignore: deprecated_member_use_from_same_package');
        }
        out.writeln('  final List<_Subscription<$name>> _for$name = [];');

        out.writeln();

        out.writeln('  @override');
        if (node.isDeprecated) {
          out.writeln('  // ignore: deprecated_member_use_from_same_package');
        }
        out.writeln('''
  void add$name(AbstractAnalysisRule rule, AstVisitor visitor) {
    _for$name.add(_Subscription(rule, visitor, _getTimer(rule)));
  }
''');
      }
    }
    out.writeln('}');
  }
}

class _Node {
  final ClassElement implElement;
  final ClassElement apiElement;
  final _AstNodeApi api;
  final String apiElementName;

  _Node({
    required this.implElement,
    required this.apiElement,
    required this.api,
    required this.apiElementName,
  });

  bool get isConcrete => !implElement.isAbstract;

  bool get isDeprecated {
    return apiElement.metadata.hasDeprecated;
  }

  bool get isExperimental {
    return apiElement.metadata.hasExperimental;
  }

  bool get isV1ViewNode => api != _AstNodeApi.v2;

  bool get isV2ViewNode {
    return _astVersionPolicy.hasV2TreeApi && api != _AstNodeApi.v1;
  }

  _Node? get superNode {
    var superElement = implElement.supertype?.element;
    return superElement.tryCast<ClassElement>()?.asNode;
  }
}

class _RuleVisitorGenerator {
  final LibraryElement astLibrary;

  final StringBuffer out = StringBuffer('''
// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Run 'dart pkg/analyzer/tool/ast/generate.dart' to update.

part of 'rule_visitor_registry.dart';
''');

  _RuleVisitorGenerator(this.astLibrary);

  Future<String> generate() async {
    _writeRuleVisitor();

    var resultPath = normalize(
      join(
        _analyzerPath,
        'lib',
        'analysis_rule',
        'rule_visitor_registry.g.dart',
      ),
    );
    return _formatSortCode(resultPath, out.toString());
  }

  void _writeRuleVisitor() {
    out.write('''
/// The container to register visitors for separate AST node types.
///
/// Source files are visited by the Dart analysis server recursively. Only the
/// visitors that are registered to visit a given node type will visit such
/// nodes. Each analysis rule overrides
/// [AbstractAnalysisRule.registerNodeProcessors] and calls `add*` for each of
/// the node types it needs to visit with an [AstVisitor], which registers that
/// visitor.
abstract class RuleVisitorRegistry {
  void afterLibrary(AbstractAnalysisRule rule, void Function() callback);
''');
    for (var node in astLibrary.nodes) {
      if (node.isConcrete && node.isV1ViewNode) {
        var name = node.apiElementName;
        if (node.isExperimental) {
          out.writeln('@experimental');
        }
        if (node.isDeprecated) {
          out.writeln("@Deprecated('See ${node.apiElementName} for details')");
        }
        out.writeln('''
void add$name(AbstractAnalysisRule rule, AstVisitor visitor);
''');
      }
    }
    out.writeln('}');
  }
}

extension on InterfaceElement {
  /// Whether the class is [AstNodeImpl].
  bool get isAstNodeImplExactly => name == 'AstNodeImpl';
}

extension on ClassElement {
  _Node? get asNode {
    if (isAstNodeImplSubtype || isAstNodeImplExactly) {
      var apiElement = interfaces.lastOrNull?.element;
      if (apiElement is ClassElement) {
        var apiElementName = apiElement.name!;
        if ('${apiElementName}Impl' == name) {
          return _Node(
            implElement: this,
            apiElement: apiElement,
            api: generateNodeApi,
            apiElementName: apiElementName,
          );
        }
      }
    }
    return null;
  }

  _AstNodeApi get generateNodeApi {
    for (var annotation in metadata.annotations) {
      var value = annotation.computeConstantValue();
      if (value?.type?.element?.name == 'GenerateNodeImpl') {
        return _AstNodeApi.values.byName(
          value!.getField('api')!.variable!.name!,
        );
      }
    }
    return _AstNodeApi.shared;
  }

  /// Whether the class is a subtype of [AstNodeImpl].
  bool get isAstNodeImplSubtype {
    // Not a real AST node.
    if (name == 'ConstantContextForExpressionImpl') {
      return false;
    }
    return allSupertypes.any((type) => type.element.isAstNodeImplExactly);
  }
}

extension on LibraryElement {
  List<_Node> get nodes {
    return classes.map((element) => element.asNode).nonNulls.toList();
  }
}
