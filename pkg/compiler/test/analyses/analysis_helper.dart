// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show SplayTreeMap;
import 'dart:convert' as json;
import 'dart:io';

import 'package:args/args.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/ir/constants.dart';
import 'package:compiler/src/ir/scope.dart';
import 'package:compiler/src/ir/static_type.dart';
import 'package:compiler/src/ir/util.dart';
import 'package:compiler/src/util/memory_compiler.dart';
import 'package:compiler/src/phase/load_kernel.dart' as load_kernel;
import 'package:expect/expect.dart';
import 'package:front_end/src/api_prototype/constant_evaluator.dart' as ir;
import 'package:front_end/src/api_unstable/dart2js.dart' show relativizeUri;
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/core_types.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

import '../helpers/args_helper.dart';

main(List<String> args) {
  ArgParser argParser = createArgParser();
  ArgResults argResults = argParser.parse(args);

  Uri? entryPoint = getEntryPoint(argResults);
  if (entryPoint == null) {
    throw ArgumentError("Missing entry point.");
  }
  Uri? librariesSpecificationUri = getLibrariesSpec(argResults);
  Uri? packageConfig = getPackages(argResults);
  List<String> options = getOptions(argResults);
  run(entryPoint, null,
      analyzedUrisFilter: (Uri uri) => !uri.isScheme('dart'),
      librariesSpecificationUri: librariesSpecificationUri,
      packageConfig: packageConfig,
      options: options);
}

run(Uri entryPoint, String? allowedListPath,
    {Map<String, String> memorySourceFiles = const {},
    Uri? librariesSpecificationUri,
    Uri? packageConfig,
    bool verbose = false,
    bool generate = false,
    List<String> options = const <String>[],
    bool analyzedUrisFilter(Uri uri)?}) {
  asyncTest(() async {
    Compiler compiler = await compilerFor(
        memorySourceFiles: memorySourceFiles,
        librariesSpecificationUri: librariesSpecificationUri,
        packageConfig: packageConfig,
        entryPoint: entryPoint,
        options: options);
    load_kernel.Output result = (await load_kernel.run(load_kernel.Input(
        compiler.options,
        compiler.provider,
        compiler.reporter,
        compiler.initializedCompilerState,
        false)))!;
    compiler.frontendStrategy
        .registerLoadedLibraries(result.component, result.libraries!);
    DynamicVisitor(compiler.reporter, result.component, allowedListPath,
            analyzedUrisFilter)
        .run(verbose: verbose, generate: generate);
  });
}

class StaticTypeVisitorBase extends StaticTypeVisitor {
  @override
  VariableScopeModel get variableScopeModel => _variableScopeModel!;
  VariableScopeModel? _variableScopeModel;

  late final Dart2jsConstantEvaluator _constantEvaluator;

  @override
  ir.StaticTypeContext get staticTypeContext => _staticTypeContext!;
  set staticTypeContext(ir.StaticTypeContext context) {
    _staticTypeContext = context;
  }

  ir.StaticTypeContext? _staticTypeContext;

  StaticTypeVisitorBase(
      ir.Component component, ir.ClassHierarchy classHierarchy,
      {required ir.EvaluationMode evaluationMode})
      : super(ir.TypeEnvironment(new ir.CoreTypes(component), classHierarchy),
            classHierarchy, StaticTypeCacheImpl()) {
    _constantEvaluator = Dart2jsConstantEvaluator(
        component, typeEnvironment, const ir.SimpleErrorReporter().report,
        evaluationMode: evaluationMode);
  }

  @override
  bool get useAsserts => false;

  @override
  bool get inferEffectivelyFinalVariableTypes => true;

  @override
  ir.DartType visitProcedure(ir.Procedure node) {
    if (node.kind == ir.ProcedureKind.Factory && node.isRedirectingFactory) {
      // Don't visit redirecting factories.
      return const ir.VoidType();
    }
    _staticTypeContext = ir.StaticTypeContext(node, typeEnvironment);
    _variableScopeModel =
        ScopeModel.from(node, _constantEvaluator).variableScopeModel;
    final result = super.visitProcedure(node);
    _variableScopeModel = null;
    _staticTypeContext = null;
    return result;
  }

  @override
  ir.DartType visitField(ir.Field node) {
    _staticTypeContext = ir.StaticTypeContext(node, typeEnvironment);
    _variableScopeModel =
        ScopeModel.from(node, _constantEvaluator).variableScopeModel;
    final result = super.visitField(node);
    _variableScopeModel = null;
    _staticTypeContext = null;
    return result;
  }

  @override
  ir.DartType visitConstructor(ir.Constructor node) {
    _staticTypeContext = ir.StaticTypeContext(node, typeEnvironment);
    _variableScopeModel =
        ScopeModel.from(node, _constantEvaluator).variableScopeModel;
    final result = super.visitConstructor(node);
    _variableScopeModel = null;
    _staticTypeContext = null;
    return result;
  }
}

class DynamicVisitor extends StaticTypeVisitorBase {
  final DiagnosticReporter reporter;
  final ir.Component component;
  final String? _allowedListPath;
  final bool Function(Uri uri)? analyzedUrisFilter;

  Map _expectedJson = {};
  final Map<String, Map<String, List<DiagnosticMessage>>> _actualMessages = {};

  DynamicVisitor(this.reporter, this.component, this._allowedListPath,
      this.analyzedUrisFilter)
      : super(component, ir.ClassHierarchy(component, ir.CoreTypes(component)),
            evaluationMode: ir.EvaluationMode.weak);

  void run({bool verbose = false, bool generate = false}) {
    if (!generate && _allowedListPath != null) {
      File file = File(_allowedListPath!);
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
      Map<String, Map<String, int>> actualJson = SplayTreeMap();
      _actualMessages.forEach(
          (String uri, Map<String, List<DiagnosticMessage>> actualMessagesMap) {
        Map<String, int> map = SplayTreeMap();
        actualMessagesMap
            .forEach((String message, List<DiagnosticMessage> actualMessages) {
          map[message] = actualMessages.length;
        });
        actualJson[uri] = map;
      });

      File(_allowedListPath!).writeAsStringSync(
          json.JsonEncoder.withIndent('  ').convert(actualJson));
      return;
    }

    int errorCount = 0;
    _expectedJson.forEach((uri, expectedMessages) {
      Map<String, List<DiagnosticMessage>>? actualMessagesMap =
          _actualMessages[uri];
      if (actualMessagesMap == null) {
        print("Error: Allowed-listing of uri '$uri' isn't used. "
            "Remove it from the allowed-list.");
        errorCount++;
      } else {
        expectedMessages.forEach((expectedMessage, expectedCount) {
          List<DiagnosticMessage>? actualMessages =
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
    ir.TreeNode? enclosingClass = node;
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
  ir.DartType visitNode(ir.TreeNode node) {
    ir.DartType staticType = node.accept(this);
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
  ir.DartType visitLibrary(ir.Library node) {
    if (analyzedUrisFilter != null) {
      if (analyzedUrisFilter!(node.importUri)) {
        return super.visitLibrary(node);
      }
      return const ir.VoidType();
    } else {
      return super.visitLibrary(node);
    }
  }

  @override
  void handleDynamicGet(ir.Expression node, ir.DartType receiverType,
      ir.Name name, ir.DartType resultType) {
    if (receiverType is ir.DynamicType) {
      registerError(node, "Dynamic access of '${name}'.");
    }
  }

  @override
  void handleDynamicSet(ir.Expression node, ir.DartType receiverType,
      ir.Name name, ir.DartType valueType) {
    if (receiverType is ir.DynamicType) {
      registerError(node, "Dynamic update to '${name}'.");
    }
  }

  @override
  void handleDynamicInvocation(
      ir.InvocationExpression node,
      ir.DartType receiverType,
      ArgumentTypes argumentTypes,
      ir.DartType returnType) {
    if (receiverType is ir.DynamicType) {
      registerError(node, "Dynamic invocation of '${node.name}'.");
    }
  }

  String reportAssertionFailure(ir.TreeNode node, String message) {
    SourceSpan span = computeSourceSpanFromTreeNode(node);
    Uri uri = span.uri;
    if (uri.isScheme('org-dartlang-sdk')) {
      span = SourceSpan(
          Uri.base.resolve(uri.path.substring(1)), span.begin, span.end);
    }
    DiagnosticMessage diagnosticMessage =
        reporter.createMessage(span, MessageKind.GENERIC, {'text': message});
    reporter.reportError(diagnosticMessage);
    return message;
  }

  void registerError(ir.TreeNode node, String message) {
    SourceSpan span = computeSourceSpanFromTreeNode(node);
    Uri uri = span.uri;
    String uriString = relativizeUri(Uri.base, uri, Platform.isWindows);
    Map<String, List<DiagnosticMessage>> actualMap = _actualMessages
        .putIfAbsent(uriString, () => <String, List<DiagnosticMessage>>{});
    if (uri.isScheme('org-dartlang-sdk')) {
      span = SourceSpan(
          Uri.base.resolve(uri.path.substring(1)), span.begin, span.end);
    }
    DiagnosticMessage diagnosticMessage =
        reporter.createMessage(span, MessageKind.GENERIC, {'text': message});
    actualMap
        .putIfAbsent(message, () => <DiagnosticMessage>[])
        .add(diagnosticMessage);
  }
}
