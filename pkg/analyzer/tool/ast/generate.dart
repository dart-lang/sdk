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
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:analyzer_utilities/tools.dart';
import 'package:path/path.dart';

void main() async {
  await GeneratedContent.generateAll(pkg_root.packageRoot, await allTargets);
}

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
      if (node.isConcrete) {
        var name = node.name;
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
    _writeRecursive();
    _writeSimple();
    _writeTimed();
    _writeThrowing();
    _writeUnifying();

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
      var name = node.name;
      var superNode = node.superNode;
      if (superNode == null) {
        continue;
      }
      if (node.isConcrete) {
        out.writeln('@override');
      }

      // TODO(fshcheglov): Remove special case after AST hierarchy is fixed.
      // https://github.com/dart-lang/sdk/issues/61224
      if (node.name == 'FunctionDeclaration') {
        out.writeln(r'''
R? visitFunctionDeclaration(FunctionDeclaration node) {
  if (node.parent is FunctionDeclarationStatement) {
    return visitNode(node);
  }
  return visitNamedCompilationUnitMember(node);
}''');
        continue;
      }

      if (superNode.element.isAstNodeImplExactly) {
        out.writeln('''
R? visit$name($name node) => visitNode(node);
''');
      } else {
        out.writeln('''
R? visit$name($name node) => visit${superNode.name}(node);
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
      if (node.isConcrete) {
        var name = node.name;
        out.writeln('''
  @override
  R? visit$name($name node) {
    node.visitChildren(this);
    return null;
  }
''');
      }
    }
    out.writeln('}');
  }

  void _writeSimple() {
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
    for (var node in astLibrary.nodes) {
      if (node.isConcrete) {
        var name = node.name;
        out.writeln('''
  @override
  R? visit$name($name node) => null;
''');
      }
    }
    out.writeln('}');
  }

  void _writeThrowing() {
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
    for (var node in astLibrary.nodes) {
      if (node.isConcrete) {
        var name = node.name;
        out.writeln('''
  @override
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
      if (node.isConcrete) {
        var name = node.name;
        out.writeln('''
  @override
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
      if (node.isConcrete) {
        var name = node.name;
        out.writeln('''
  @override
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
      if (node.isConcrete) {
        var name = node.name;
        out.writeln('''
  @override
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
      if (node.isConcrete) {
        var name = node.name;
        out.writeln('''
final List<_Subscription<$name>> _for$name = [];

@override
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
  final ClassElement element;
  final String name;

  _Node(this.element, this.name);

  bool get isConcrete => !element.isAbstract;

  _Node? get superNode {
    return element.supertype?.element.ifTypeOrNull<ClassElement>()?.asNode;
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
      if (node.isConcrete) {
        var name = node.name;
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
    var interfaceName = name?.removeSuffix('Impl');
    if ((isAstNodeImplSubtype || isAstNodeImplExactly) &&
        interfaceName != null) {
      return _Node(this, interfaceName);
    }
    return null;
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
