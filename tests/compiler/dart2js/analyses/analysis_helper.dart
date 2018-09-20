// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' as json;
import 'dart:io';

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/diagnostics/messages.dart';
import 'package:compiler/src/diagnostics/source_span.dart';
import 'package:compiler/src/library_loader.dart';
import 'package:compiler/src/ir/util.dart';
import 'package:compiler/src/util/uri_extras.dart';
import 'package:expect/expect.dart';
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/core_types.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

import '../helpers/memory_compiler.dart';

run(Uri entryPoint, String allowedListPath,
    {Map<String, String> memorySourceFiles = const {},
    bool verbose = false,
    bool generate = false}) {
  asyncTest(() async {
    Compiler compiler = await compilerFor(memorySourceFiles: memorySourceFiles);
    LoadedLibraries loadedLibraries =
        await compiler.libraryLoader.loadLibraries(entryPoint);
    new DynamicVisitor(
            compiler.reporter, loadedLibraries.component, allowedListPath)
        .run(verbose: verbose, generate: generate);
  });
}

// TODO(johnniwinther): Add improved type promotion to handle negative
// reasoning.
// TODO(johnniwinther): Use this visitor in kernel impact computation.
abstract class StaticTypeVisitor extends ir.Visitor<ir.DartType> {
  ir.Component get component;
  ir.TypeEnvironment _typeEnvironment;
  bool _isStaticTypePrepared = false;

  @override
  ir.DartType defaultNode(ir.Node node) {
    node.visitChildren(this);
    return null;
  }

  @override
  ir.DartType defaultExpression(ir.Expression node) {
    defaultNode(node);
    return getStaticType(node);
  }

  ir.DartType getStaticType(ir.Expression node) {
    if (!_isStaticTypePrepared) {
      _isStaticTypePrepared = true;
      try {
        _typeEnvironment ??= new ir.TypeEnvironment(
            new ir.CoreTypes(component), new ir.ClassHierarchy(component));
      } catch (e) {}
    }
    if (_typeEnvironment == null) {
      // The class hierarchy crashes on multiple inheritance. Use `dynamic`
      // as static type.
      return const ir.DynamicType();
    }
    ir.TreeNode enclosingClass = node;
    while (enclosingClass != null && enclosingClass is! ir.Class) {
      enclosingClass = enclosingClass.parent;
    }
    try {
      _typeEnvironment.thisType =
          enclosingClass is ir.Class ? enclosingClass.thisType : null;
      return node.getStaticType(_typeEnvironment);
    } catch (e) {
      // The static type computation crashes on type errors. Use `dynamic`
      // as static type.
      return const ir.DynamicType();
    }
  }
}

// TODO(johnniwinther): Handle dynamic access of Object properties/methods
// separately.
class DynamicVisitor extends StaticTypeVisitor {
  final DiagnosticReporter reporter;
  final ir.Component component;
  final String _allowedListPath;

  Map _expectedJson = {};
  Map<String, Map<String, List<DiagnosticMessage>>> _actualMessages = {};

  DynamicVisitor(this.reporter, this.component, this._allowedListPath);

  void run({bool verbose = false, bool generate = false}) {
    if (!generate) {
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
    if (generate) {
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
        _actualMessages.forEach((String uri,
            Map<String, List<DiagnosticMessage>> actualMessagesMap) {
          if (!_expectedJson.containsKey(uri)) {
            actualMessagesMap.forEach(
                (String message, List<DiagnosticMessage> actualMessages) {
              if (!expectedMessages.containsKey(message)) {
                for (DiagnosticMessage message in actualMessages) {
                  reporter.reportError(message);
                  errorCount++;
                }
              }
            });
          }
        });
      }
    });
    if (errorCount != 0) {
      print('$errorCount error(s) found.');
      print("""

********************************************************************************
  Unexpected dynamic invocations found by test:

    ${relativize(Uri.base, Platform.script, Platform.isWindows)}

  Please address the reported errors, or, if the errors are as expected, run

    dart ${relativize(Uri.base, Platform.script, Platform.isWindows)} -g

  to update the expectation file.
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

  @override
  ir.DartType visitPropertyGet(ir.PropertyGet node) {
    ir.DartType result = super.visitPropertyGet(node);
    ir.DartType type = node.receiver.accept(this);
    if (type is ir.DynamicType) {
      reportError(node, "Dynamic access of '${node.name}'.");
    }
    return result;
  }

  @override
  ir.DartType visitPropertySet(ir.PropertySet node) {
    ir.DartType result = super.visitPropertySet(node);
    ir.DartType type = node.receiver.accept(this);
    if (type is ir.DynamicType) {
      reportError(node, "Dynamic update to '${node.name}'.");
    }
    return result;
  }

  @override
  ir.DartType visitMethodInvocation(ir.MethodInvocation node) {
    ir.DartType result = super.visitMethodInvocation(node);
    if (node.name.name == '==' &&
        node.arguments.positional.single is ir.NullLiteral) {
      return result;
    }
    ir.DartType type = node.receiver.accept(this);
    if (type is ir.DynamicType) {
      reportError(node, "Dynamic invocation of '${node.name}'.");
    }
    return result;
  }

  void reportError(ir.Node node, String message) {
    SourceSpan span = computeSourceSpanFromTreeNode(node);
    Uri uri = span.uri;
    String uriString = relativize(Uri.base, uri, Platform.isWindows);
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
