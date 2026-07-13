// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/test_utilities/find_element2.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:analyzer_testing/src/expected_diagnostics.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:test/test.dart';

import '../../../util/diff.dart';
import '../../../util/element_printer.dart';
import '../../summary/resolved_ast_printer.dart';
import '../analysis/result_printer.dart';
import 'dart_object_printer.dart';
import 'node_text_expectations.dart';

final isDynamicType = TypeMatcher<DynamicTypeImpl>();

final isNeverType = TypeMatcher<NeverTypeImpl>();

final isVoidType = TypeMatcher<VoidTypeImpl>();

/// Base for resolution tests.
mixin ResolutionTest implements ResourceProviderMixin {
  final ResolvedNodeTextConfiguration nodeTextConfiguration =
      ResolvedNodeTextConfiguration();

  final DartObjectPrinterConfiguration dartObjectPrinterConfiguration =
      DartObjectPrinterConfiguration();

  File get testFile;

  void addTestFile(String content) {
    newFile(testFile.path, content);
  }

  void assertDartObjectText(DartObject? object, String expected) {
    var buffer = StringBuffer();
    var sink = TreeStringSink(sink: buffer, indent: '');
    var elementPrinter = ElementPrinter(
      sink: sink,
      configuration: ElementPrinterConfiguration(),
    );
    DartObjectPrinter(
      configuration: dartObjectPrinterConfiguration,
      sink: sink,
      elementPrinter: elementPrinter,
    ).write(object as DartObjectImpl?);
    var actual = buffer.toString();
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(expected, actual);
      }
      fail('See the difference above.');
    }
  }

  void assertElement(
    Object? nodeOrElement, {
    required Element declaration,
    Map<String, String> substitution = const {},
  }) {
    Element? element;
    if (nodeOrElement is AstNode) {
      element = getNodeElement2(nodeOrElement);
    } else {
      element = nodeOrElement as Element?;
    }

    var actualDeclaration = element?.baseElement;
    expect(actualDeclaration, same(declaration));

    if (element is SubstitutedElementImpl) {
      assertSubstitution(element.substitution, substitution);
    } else if (substitution.isNotEmpty) {
      fail('Expected to be a Member: (${element.runtimeType}) $element');
    }
  }

  void assertElementNull(Element? element) {
    expect(element, isNull);
  }

  void assertElementTypes(
    List<DartType>? types,
    List<String> expected, {
    bool ordered = false,
  }) {
    if (types == null) {
      fail('Expected types, actually null.');
    }

    var typeStrList = types.map(typeString).toList();
    if (ordered) {
      expect(typeStrList, expected);
    } else {
      expect(typeStrList, unorderedEquals(expected));
    }
  }

  void assertParsedNodeText(AstNode node, String expected) {
    var buffer = StringBuffer();
    var sink = TreeStringSink(sink: buffer, indent: '');

    var elementPrinter = ElementPrinter(
      sink: sink,
      configuration: ElementPrinterConfiguration(),
    );

    ResolvedAstPrinter(
      sink: sink,
      elementPrinter: elementPrinter,
      configuration: ResolvedNodeTextConfiguration(),
      withResolution: false,
    ).writeNode(node);

    var actual = buffer.toString();
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(expected, actual);
      }
      fail('See the difference above.');
    }
  }

  void assertResolvedLibraryResultText(
    SomeResolvedLibraryResult result,
    String expected, {
    void Function(ResolvedLibraryResultPrinterConfiguration)? configure,
  }) {
    var configuration = ResolvedLibraryResultPrinterConfiguration();
    configure?.call(configuration);

    var buffer = StringBuffer();
    var sink = TreeStringSink(sink: buffer, indent: '');
    var idProvider = IdProvider();
    ResolvedLibraryResultPrinter(
      configuration: configuration,
      sink: sink,
      idProvider: idProvider,
      elementPrinter: ElementPrinter(
        sink: sink,
        configuration: ElementPrinterConfiguration(),
      ),
    ).write(result);

    var actual = buffer.toString();
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(expected, actual);
      }
      fail('See the difference above.');
    }
  }

  void assertResolvedNodeText(AstNode node, String expected) {
    var actual = _resolvedNodeText(node);
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(expected, actual);
      }
      fail('See the difference above.');
    }
  }

  void assertSubstitution(
    MapSubstitution substitution,
    Map<String, String> expected,
  ) {
    var actualMapString = Map.fromEntries(
      substitution.map.entries
          .where((entry) {
            return entry.key.enclosingElement is! ExecutableElement;
          })
          .map((entry) {
            return MapEntry(entry.key.name, typeString(entry.value));
          }),
    );
    expect(actualMapString, expected);
  }

  void assertType(Object? typeOrNode, String? expected) {
    DartType? actual;
    if (typeOrNode is DartType) {
      actual = typeOrNode;
    } else if (typeOrNode is Expression) {
      actual = typeOrNode.staticType;
    } else if (typeOrNode is GenericFunctionType) {
      actual = typeOrNode.type;
    } else if (typeOrNode is NamedType) {
      actual = typeOrNode.type;
    } else {
      fail('Unsupported node: (${typeOrNode.runtimeType}) $typeOrNode');
    }

    if (expected == null) {
      expect(actual, isNull);
    } else if (actual == null) {
      fail('Null, expected: $expected');
    } else {
      expect(typeString(actual), expected);
    }
  }

  void assertTypeDynamic(Object? typeOrExpression) {
    DartType? actual;
    if (typeOrExpression case DartType? type) {
      actual = typeOrExpression;
      expect(type, isDynamicType);
    } else {
      actual = (typeOrExpression as Expression).staticType;
    }
    expect(actual, isDynamicType);
  }

  Element? getNodeElement2(AstNode node) {
    if (node is Annotation) {
      return node.element;
    } else if (node is AssignmentExpression) {
      return node.element;
    } else if (node is BinaryExpression) {
      return node.element;
    } else if (node is ConstructorReference) {
      return node.constructorName.element;
    } else if (node is Declaration) {
      return node.declaredFragment?.element;
    } else if (node is ExtensionOverride) {
      return node.element;
    } else if (node is FormalParameter) {
      return node.declaredFragment?.element;
    } else if (node is FunctionExpressionInvocation) {
      return node.element;
    } else if (node is FunctionReference) {
      var function = node.function.unParenthesized;
      if (function is Identifier) {
        return function.element;
      } else if (function is PropertyAccess) {
        return function.propertyName.element;
      } else if (function is ConstructorReference) {
        return function.constructorName.element;
      } else {
        fail('Unsupported node: (${function.runtimeType}) $function');
      }
    } else if (node is Identifier) {
      return node.element;
    } else if (node is ImplicitCallReference) {
      return node.element;
    } else if (node is IndexExpression) {
      return node.element;
    } else if (node is InstanceCreationExpression) {
      return node.constructorName.element;
    } else if (node is MethodInvocation) {
      return node.methodName.element;
    } else if (node is PostfixExpression) {
      return node.element;
    } else if (node is PrefixExpression) {
      return node.element;
    } else if (node is PropertyAccess) {
      return node.propertyName.element;
    } else if (node is NamedType) {
      return node.element;
    } else {
      fail('Unsupported node: (${node.runtimeType}) $node');
    }
  }

  Future<ResolvedUnitResultImpl> resolveFile(File file);

  /// Resolve [file] and return a test view of it.
  Future<TestResolvedUnitResult> resolveFile2(File file) async {
    var result = await resolveFile(file);
    return TestResolvedUnitResult(result);
  }

  /// Create a new file with the [path] and [content], and resolve it.
  Future<TestResolvedUnitResult> resolveFileCode(String path, String content) {
    var file = newFile(path, content);
    return resolveFile2(file);
  }

  /// Writes all [filesToCode], resolves each file, and checks that each file's
  /// inline diagnostic markers match its diagnostics.
  ///
  /// All files are written before any file is resolved. This supports tests
  /// where resolving one file cleanly requires related files to already exist,
  /// such as a library with its parts.
  Future<Map<File, TestResolvedUnitResult>> resolveFilesWithDiagnostics(
    Map<File, String> filesToCode,
  ) async {
    var files = <({File file, String code, String cleanCode})>[];

    for (var entry in filesToCode.entries) {
      var cleanCode = removeDiagnosticExpectations(entry.value);
      modifyFile2(entry.key, cleanCode);
      files.add((file: entry.key, code: entry.value, cleanCode: cleanCode));
    }

    var results = <File, TestResolvedUnitResult>{};
    var diagnosticsByFile = <File, List<Diagnostic>>{};

    for (var file in files) {
      var result = await resolveFile2(file.file);
      results[file.file] = result;
      diagnosticsByFile[file.file] = result.diagnostics;
    }

    var actualCodeByFile = updateExpectedDiagnosticsForFiles(
      contentByFile: {for (var file in files) file.file: file.cleanCode},
      actualDiagnosticsByFile: diagnosticsByFile,
    );

    var hasMismatch = false;
    for (var index = 0; index < files.length; index++) {
      var file = files[index];
      var actual = actualCodeByFile[file.file]!;
      if (actual != file.code) {
        NodeTextExpectationsCollector.add(actual, intraInvocationId: '$index');
        if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
          print('-------- ${file.file.path} --------');
          printPrettyDiff(file.code, actual);
        }
        hasMismatch = true;
      }
    }

    if (hasMismatch) {
      fail('See the difference above.');
    }

    return results;
  }

  /// Writes [code] to [file], resolves it, and checks that its inline
  /// diagnostic markers match its diagnostics.
  Future<TestResolvedUnitResult> resolveFileWithDiagnostics(
    File file,
    String code,
  ) async {
    return await _resolveFileWithDiagnostics(file, code);
  }

  /// Put the [code] into the test file, and resolve it.
  Future<TestResolvedUnitResult> resolveTestCode(String code) {
    addTestFile(code);
    return resolveTestFile();
  }

  /// Resolves [code] and checks that its inline diagnostic markers match the
  /// diagnostics. Unmarked code is expected to have no diagnostics.
  Future<TestResolvedUnitResult> resolveTestCodeWithDiagnostics(
    String code,
  ) async {
    return await _resolveFileWithDiagnostics(testFile, code);
  }

  Future<TestResolvedUnitResult> resolveTestFile() {
    return resolveFile2(testFile);
  }

  /// Return a textual representation of the [type] that is appropriate for
  /// tests.
  String typeString(DartType type) => type.getDisplayString();

  String _resolvedNodeText(AstNode node) {
    var buffer = StringBuffer();
    var sink = TreeStringSink(sink: buffer, indent: '');
    var elementPrinter = ElementPrinter(
      sink: sink,
      configuration: ElementPrinterConfiguration()
        ..withInterfaceTypeElements =
            nodeTextConfiguration.withInterfaceTypeElements
        ..withRedirectedConstructors =
            nodeTextConfiguration.withRedirectedConstructors
        ..withSuperConstructors = nodeTextConfiguration.withSuperConstructors,
    );
    ResolvedAstPrinter(
      sink: sink,
      elementPrinter: elementPrinter,
      configuration: nodeTextConfiguration,
    ).writeNode(node);

    var unit = node.thisOrAncestorOfType<CompilationUnitImpl>();
    if (unit != null) {
      sink.writeElements('invalidNodes', unit.invalidNodes, (node) {
        var range = '[${node.offset}, ${node.end})';
        sink.writelnWithIndent('${node.runtimeType} $range');
      });
    }

    return buffer.toString();
  }

  Future<TestResolvedUnitResult> _resolveFileWithDiagnostics(
    File file,
    String code,
  ) async {
    var cleanCode = removeDiagnosticExpectations(code);
    modifyFile2(file, cleanCode);
    var result = await resolveFile2(file);

    var actual = updateExpectedDiagnostics(
      content: cleanCode,
      actualDiagnostics: result.diagnostics,
    );
    if (actual != code) {
      NodeTextExpectationsCollector.add(actual);
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(code, actual);
      }
      fail('See the difference above.');
    }

    return result;
  }
}

/// A test-facing view of a resolved unit, with utilities derived from it.
final class TestResolvedUnitResult {
  final ResolvedUnitResultImpl analysisResult;

  late final FindElement2 findElement = FindElement2(unit);

  late final FindNode findNode = FindNode(content, unit);

  TestResolvedUnitResult(this.analysisResult);

  String get content => analysisResult.content;

  List<Diagnostic> get diagnostics => analysisResult.diagnostics;

  List<Diagnostic> get errors => analysisResult.errors;

  bool get exists => analysisResult.exists;

  File get file => analysisResult.file;

  InheritanceManager3 get inheritanceManager {
    return libraryElement.session.inheritanceManager;
  }

  bool get isLibrary => analysisResult.isLibrary;

  bool get isPart => analysisResult.isPart;

  LibraryElementImpl get libraryElement => analysisResult.libraryElement;

  LibraryFragmentImpl get libraryFragment => analysisResult.libraryFragment;

  String get path => analysisResult.path;

  AnalysisSession get session => analysisResult.session;

  TypeProviderImpl get typeProvider => analysisResult.typeProvider;

  TypeSystemImpl get typeSystem => analysisResult.typeSystem;

  CompilationUnitImpl get unit => analysisResult.unit;

  Uri get uri => analysisResult.uri;

  String get uriStr => '$uri';
}

extension ResolvedUnitResultExtension on ResolvedUnitResult {
  FindElement2 get findElement2 {
    return FindElement2(unit);
  }

  FindNode get findNode {
    return FindNode(content, unit);
  }

  InheritanceManager3 get inheritanceManager {
    var library = libraryElement as LibraryElementImpl;
    return library.session.inheritanceManager;
  }

  String get uriStr => '$uri';
}
