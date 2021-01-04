// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:convert' as json;
import 'dart:io';

import 'package:args/args.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/diagnostics/messages.dart';
import 'package:compiler/src/diagnostics/source_span.dart';
import 'package:compiler/src/ir/constants.dart';
import 'package:compiler/src/ir/scope.dart';
import 'package:compiler/src/ir/static_type.dart';
import 'package:compiler/src/ir/util.dart';
import 'package:compiler/src/kernel/loader.dart';
import 'package:expect/expect.dart';
import 'package:front_end/src/api_prototype/constant_evaluator.dart' as ir;
import 'package:front_end/src/api_unstable/dart2js.dart'
    show isRedirectingFactory, isRedirectingFactoryField, relativizeUri;
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/core_types.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

import '../helpers/args_helper.dart';
import '../helpers/memory_compiler.dart';

main(List<String> args) {
  ArgParser argParser = createArgParser();
  ArgResults argResults = argParser.parse(args);

  Uri entryPoint = getEntryPoint(argResults);
  if (entryPoint == null) {
    throw new ArgumentError("Missing entry point.");
  }
  Uri librariesSpecificationUri = getLibrariesSpec(argResults);
  Uri packageConfig = getPackages(argResults);
  List<String> options = getOptions(argResults);
  run(entryPoint, null,
      analyzedUrisFilter: (Uri uri) => uri.scheme != 'dart',
      librariesSpecificationUri: librariesSpecificationUri,
      packageConfig: packageConfig,
      options: options);
}

run(Uri entryPoint, String allowedListPath,
    {Map<String, String> memorySourceFiles = const {},
    Uri librariesSpecificationUri,
    Uri packageConfig,
    bool verbose = false,
    bool generate = false,
    List<String> options = const <String>[],
    bool analyzedUrisFilter(Uri uri)}) {
  asyncTest(() async {
    Compiler compiler = await compilerFor(
        memorySourceFiles: memorySourceFiles,
        librariesSpecificationUri: librariesSpecificationUri,
        packageConfig: packageConfig,
        options: options);
    KernelResult result = await compiler.kernelLoader.load(entryPoint);
    new DynamicVisitor(compiler.reporter, result.component, allowedListPath,
            analyzedUrisFilter)
        .run(verbose: verbose, generate: generate);
  });
}

class StaticTypeVisitorBase extends StaticTypeVisitor {
  @override
  VariableScopeModel variableScopeModel;

  Dart2jsConstantEvaluator _constantEvaluator;

  @override
  ir.StaticTypeContext staticTypeContext;

  StaticTypeVisitorBase(
      ir.Component component, ir.ClassHierarchy classHierarchy,
      {ir.EvaluationMode evaluationMode})
      : assert(evaluationMode != null),
        super(
            new ir.TypeEnvironment(new ir.CoreTypes(component), classHierarchy),
            classHierarchy,
            new StaticTypeCacheImpl()) {
    _constantEvaluator = new Dart2jsConstantEvaluator(
        typeEnvironment, const ir.SimpleErrorReporter().report,
        evaluationMode: evaluationMode);
  }

  @override
  bool get useAsserts => false;

  @override
  bool get inferEffectivelyFinalVariableTypes => true;

  @override
  Null visitProcedure(ir.Procedure node) {
    if (node.kind == ir.ProcedureKind.Factory && isRedirectingFactory(node)) {
      // Don't visit redirecting factories.
      return;
    }
    staticTypeContext = new ir.StaticTypeContext(node, typeEnvironment);
    variableScopeModel =
        new ScopeModel.from(node, _constantEvaluator).variableScopeModel;
    super.visitProcedure(node);
    variableScopeModel = null;
    staticTypeContext = null;
  }

  @override
  Null visitField(ir.Field node) {
    if (isRedirectingFactoryField(node)) {
      // Skip synthetic .dill members.
      return;
    }
    staticTypeContext = new ir.StaticTypeContext(node, typeEnvironment);
    variableScopeModel =
        new ScopeModel.from(node, _constantEvaluator).variableScopeModel;
    super.visitField(node);
    variableScopeModel = null;
    staticTypeContext = null;
  }

  @override
  Null visitConstructor(ir.Constructor node) {
    staticTypeContext = new ir.StaticTypeContext(node, typeEnvironment);
    variableScopeModel =
        new ScopeModel.from(node, _constantEvaluator).variableScopeModel;
    super.visitConstructor(node);
    variableScopeModel = null;
    staticTypeContext = null;
  }
}

class DynamicVisitor extends StaticTypeVisitorBase {
  final DiagnosticReporter reporter;
  final ir.Component component;
  final String _allowedListPath;
  final bool Function(Uri uri) analyzedUrisFilter;

  Map _expectedJson = {};
  Map<String, Map<String, List<DiagnosticMessage>>> _actualMessages = {};

  DynamicVisitor(this.reporter, this.component, this._allowedListPath,
      this.analyzedUrisFilter)
      : super(component,
            new ir.ClassHierarchy(component, new ir.CoreTypes(component)),
            evaluationMode: ir.EvaluationMode.weak);

  void run({bool verbose = false, bool generate = false}) {
    if (!generate && _allowedListPath != null) {
      File file = new File(_allowedListPath);
      if (file.existsSync()) {
        try {
          _expectedJson = json.jsonDecode(file.readAsStringSync());
        } catch (e) {
          Expect.fail('Error reading allowed list from $_allowedListPath: $e');
        }
      }
    }
    component.accept(this);
    if (generate && _allowedListPath != null) {
      Map<String, Map<String, int>> actualJson = {};
      _actualMessages.forEach(
          (String uri, Map<String, List<DiagnosticMessage>> actualMessagesMap) {
        Map<String, int> map = {};
        actualMessagesMap
            .forEach((String message, List<DiagnosticMessage> actualMessages) {
          map[message] = actualMessages.length;
        });
        actualJson[uri] = map;
      });

      new File(_allowedListPath).writeAsStringSync(
          new json.JsonEncoder.withIndent('  ').convert(actualJson));
      return;
    }

    int errorCount = 0;
    _expectedJson.forEach((uri, expectedMessages) {
      Map<String, List<DiagnosticMessage>> actualMessagesMap =
          _actualMessages[uri];
      if (actualMessagesMap == null) {
        print("Error: Allowed-listing of uri '$uri' isn't used. "
            "Remove it from the allowed-list.");
        errorCount++;
      } else {
        expectedMessages.forEach((expectedMessage, expectedCount) {
          List<DiagnosticMessage> actualMessages =
              actualMessagesMap[expectedMessage];
          if (actualMessages == null) {
            print("Error: Allowed-listing of message '$expectedMessage' "
                "in uri '$uri' isn't used. Remove it from the allowed-list.");
            errorCount++;
          } else {
            int actualCount = actualMessages.length;
            if (actualCount != expectedCount) {
              print("Error: Unexpected count of allowed message "
                  "'$expectedMessage' in uri '$uri'. "
                  "Expected $expectedCount, actual $actualCount:");
              print(
                  '----------------------------------------------------------');
              for (DiagnosticMessage message in actualMessages) {
                reporter.reportError(message);
              }
              print(
                  '----------------------------------------------------------');
              errorCount++;
            }
          }
        });
        actualMessagesMap
            .forEach((String message, List<DiagnosticMessage> actualMessages) {
          if (!expectedMessages.containsKey(message)) {
            for (DiagnosticMessage message in actualMessages) {
              reporter.reportError(message);
              errorCount++;
            }
          }
        });
      }
    });
    _actualMessages.forEach(
        (String uri, Map<String, List<DiagnosticMessage>> actualMessagesMap) {
      if (!_expectedJson.containsKey(uri)) {
        actualMessagesMap
            .forEach((String message, List<DiagnosticMessage> actualMessages) {
          for (DiagnosticMessage message in actualMessages) {
            reporter.reportError(message);
            errorCount++;
          }
        });
      }
    });
    if (errorCount != 0) {
      print('$errorCount error(s) found.');
      print("""

********************************************************************************
*  Unexpected dynamic invocations found by test:
*
*    ${relativizeUri(Uri.base, Platform.script, Platform.isWindows)}
*
*  Please address the reported errors, or, if the errors are as expected, run
*
*    dart ${relativizeUri(Uri.base, Platform.script, Platform.isWindows)} -g
*
*  to update the expectation file.
********************************************************************************
""");
      exit(-1);
    }
    if (verbose) {
      _actualMessages.forEach(
          (String uri, Map<String, List<DiagnosticMessage>> actualMessagesMap) {
        actualMessagesMap
            .forEach((String message, List<DiagnosticMessage> actualMessages) {
          for (DiagnosticMessage message in actualMessages) {
            reporter.reportErrorMessage(message.sourceSpan, MessageKind.GENERIC,
                {'text': '${message.message} (allowed)'});
          }
        });
      });
    } else {
      int total = 0;
      _actualMessages.forEach(
          (String uri, Map<String, List<DiagnosticMessage>> actualMessagesMap) {
        int count = 0;
        actualMessagesMap
            .forEach((String message, List<DiagnosticMessage> actualMessages) {
          count += actualMessages.length;
        });

        print('${count} error(s) allowed in $uri');
        total += count;
      });
      if (total > 0) {
        print('${total} error(s) allowed in total.');
      }
    }
  }

  /// Pulls the static type from `getStaticType` on [node].
  ir.DartType _getStaticTypeFromExpression(ir.Expression node) {
    if (typeEnvironment == null) {
      // The class hierarchy crashes on multiple inheritance. Use `dynamic`
      // as static type.
      return const ir.DynamicType();
    }
    ir.TreeNode enclosingClass = node;
    while (enclosingClass != null && enclosingClass is! ir.Class) {
      enclosingClass = enclosingClass.parent;
    }
    try {
      return node.getStaticType(staticTypeContext);
    } catch (e) {
      // The static type computation crashes on type errors. Use `dynamic`
      // as static type.
      return const ir.DynamicType();
    }
  }

  @override
  ir.DartType visitNode(ir.Node node) {
    ir.DartType staticType = node?.accept(this);
    assert(
        node is! ir.Expression ||
            staticType is ir.NullType ||
            staticType is ir.FutureOrType ||
            typeEnvironment.isSubtypeOf(
                staticType,
                _getStaticTypeFromExpression(node),
                ir.SubtypeCheckMode.ignoringNullabilities),
        reportAssertionFailure(
            node,
            "Unexpected static type for $node (${node.runtimeType}): "
            "Found ${staticType}, expected ${_getStaticTypeFromExpression(node)}."));
    return staticType;
  }

  @override
  Null visitLibrary(ir.Library node) {
    if (analyzedUrisFilter != null) {
      if (analyzedUrisFilter(node.importUri)) {
        super.visitLibrary(node);
      }
    } else {
      super.visitLibrary(node);
    }
  }

  @override
  void handlePropertyGet(
      ir.PropertyGet node, ir.DartType receiverType, ir.DartType resultType) {
    if (receiverType is ir.DynamicType) {
      registerError(node, "Dynamic access of '${node.name}'.");
    }
  }

  @override
  void handlePropertySet(
      ir.PropertySet node, ir.DartType receiverType, ir.DartType valueType) {
    if (receiverType is ir.DynamicType) {
      registerError(node, "Dynamic update to '${node.name}'.");
    }
  }

  @override
  void handleMethodInvocation(
      ir.MethodInvocation node,
      ir.DartType receiverType,
      ArgumentTypes argumentTypes,
      ir.DartType returnType) {
    if (receiverType is ir.DynamicType) {
      registerError(node, "Dynamic invocation of '${node.name}'.");
    }
  }

  String reportAssertionFailure(ir.Node node, String message) {
    SourceSpan span = computeSourceSpanFromTreeNode(node);
    Uri uri = span.uri;
    if (uri.scheme == 'org-dartlang-sdk') {
      span = new SourceSpan(
          Uri.base.resolve(uri.path.substring(1)), span.begin, span.end);
    }
    DiagnosticMessage diagnosticMessage =
        reporter.createMessage(span, MessageKind.GENERIC, {'text': message});
    reporter.reportError(diagnosticMessage);
    return message;
  }

  void registerError(ir.Node node, String message) {
    SourceSpan span = computeSourceSpanFromTreeNode(node);
    Uri uri = span.uri;
    String uriString = relativizeUri(Uri.base, uri, Platform.isWindows);
    Map<String, List<DiagnosticMessage>> actualMap = _actualMessages
        .putIfAbsent(uriString, () => <String, List<DiagnosticMessage>>{});
    if (uri.scheme == 'org-dartlang-sdk') {
      span = new SourceSpan(
          Uri.base.resolve(uri.path.substring(1)), span.begin, span.end);
    }
    DiagnosticMessage diagnosticMessage =
        reporter.createMessage(span, MessageKind.GENERIC, {'text': message});
    actualMap
        .putIfAbsent(message, () => <DiagnosticMessage>[])
        .add(diagnosticMessage);
  }
}
