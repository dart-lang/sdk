// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' as json;
import 'dart:io';

import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart';
import 'package:expect/expect.dart';
import 'package:front_end/src/api_prototype/front_end.dart';
import 'package:front_end/src/api_prototype/kernel_generator.dart';
import 'package:front_end/src/api_prototype/terminal_color_support.dart';
import 'package:front_end/src/api_unstable/ddc.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart';
import 'package:front_end/src/fasta/command_line_reporting.dart';
import 'package:front_end/src/fasta/fasta_codes.dart';
import 'package:front_end/src/fasta/kernel/redirecting_factory_body.dart';
import 'package:front_end/src/kernel_generator_impl.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_environment.dart';

run(Uri entryPoint, String allowedListPath,
    {bool verbose = false,
    bool generate = false,
    bool analyzedUrisFilter(Uri uri)}) async {
  CompilerOptions options = new CompilerOptions();
  options.sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);

  options.onDiagnostic = (DiagnosticMessage message) {
    printDiagnosticMessage(message, print);
  };
  InternalCompilerResult compilerResult = await kernelForProgramInternal(
      entryPoint, options,
      retainDataForTesting: true, requireMain: false);

  new DynamicVisitor(options.onDiagnostic, compilerResult.component,
          allowedListPath, analyzedUrisFilter)
      .run(verbose: verbose, generate: generate);
}

class StaticTypeVisitorBase extends RecursiveVisitor<void> {
  final TypeEnvironment typeEnvironment;

  StaticTypeContext staticTypeContext;

  StaticTypeVisitorBase(Component component, ClassHierarchy classHierarchy)
      : typeEnvironment =
            new TypeEnvironment(new CoreTypes(component), classHierarchy);

  @override
  void visitProcedure(Procedure node) {
    if (node.kind == ProcedureKind.Factory && isRedirectingFactory(node)) {
      // Don't visit redirecting factories.
      return;
    }
    staticTypeContext = new StaticTypeContext(node, typeEnvironment);
    super.visitProcedure(node);
    staticTypeContext = null;
  }

  @override
  void visitField(Field node) {
    if (isRedirectingFactoryField(node)) {
      // Skip synthetic .dill members.
      return;
    }
    staticTypeContext = new StaticTypeContext(node, typeEnvironment);
    super.visitField(node);
    staticTypeContext = null;
  }

  @override
  void visitConstructor(Constructor node) {
    staticTypeContext = new StaticTypeContext(node, typeEnvironment);
    super.visitConstructor(node);
    staticTypeContext = null;
  }
}

class DynamicVisitor extends StaticTypeVisitorBase {
  // TODO(johnniwinther): Enable this when it is less noisy.
  static const bool checkReturnTypes = false;

  final DiagnosticMessageHandler onDiagnostic;
  final Component component;
  final String _allowedListPath;
  final bool Function(Uri uri) analyzedUrisFilter;

  Map _expectedJson = {};
  Map<String, Map<String, List<FormattedMessage>>> _actualMessages = {};

  DynamicVisitor(this.onDiagnostic, this.component, this._allowedListPath,
      this.analyzedUrisFilter)
      : super(
            component, new ClassHierarchy(component, new CoreTypes(component)));

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
          (String uri, Map<String, List<FormattedMessage>> actualMessagesMap) {
        Map<String, int> map = {};
        actualMessagesMap
            .forEach((String message, List<FormattedMessage> actualMessages) {
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
      Map<String, List<FormattedMessage>> actualMessagesMap =
          _actualMessages[uri];
      if (actualMessagesMap == null) {
        print("Error: Allowed-listing of uri '$uri' isn't used. "
            "Remove it from the allowed-list.");
        errorCount++;
      } else {
        expectedMessages.forEach((expectedMessage, expectedCount) {
          List<FormattedMessage> actualMessages =
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
              for (FormattedMessage message in actualMessages) {
                onDiagnostic(message);
              }
              print(
                  '----------------------------------------------------------');
              errorCount++;
            }
          }
        });
        actualMessagesMap
            .forEach((String message, List<FormattedMessage> actualMessages) {
          if (!expectedMessages.containsKey(message)) {
            for (FormattedMessage message in actualMessages) {
              onDiagnostic(message);
              errorCount++;
            }
          }
        });
      }
    });
    _actualMessages.forEach(
        (String uri, Map<String, List<FormattedMessage>> actualMessagesMap) {
      if (!_expectedJson.containsKey(uri)) {
        actualMessagesMap
            .forEach((String message, List<FormattedMessage> actualMessages) {
          for (FormattedMessage message in actualMessages) {
            onDiagnostic(message);
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
*    ${relativizeUri(Platform.script)}
*
*  Please address the reported errors, or, if the errors are as expected, run
*
*    dart ${relativizeUri(Platform.script)} -g
*
*  to update the expectation file.
********************************************************************************
""");
      exit(-1);
    }
    if (verbose) {
      _actualMessages.forEach(
          (String uri, Map<String, List<FormattedMessage>> actualMessagesMap) {
        actualMessagesMap
            .forEach((String message, List<FormattedMessage> actualMessages) {
          for (FormattedMessage message in actualMessages) {
            // TODO(johnniwinther): It is unnecessarily complicated to just
            // add ' (allowed)' to an existing message!
            LocatedMessage locatedMessage = message.locatedMessage;
            String newMessageText =
                '${locatedMessage.messageObject.message} (allowed)';
            message = locatedMessage.withFormatting(
                format(
                    new LocatedMessage(
                        locatedMessage.uri,
                        locatedMessage.charOffset,
                        locatedMessage.length,
                        new Message(locatedMessage.messageObject.code,
                            message: newMessageText,
                            tip: locatedMessage.messageObject.tip,
                            arguments: locatedMessage.messageObject.arguments)),
                    Severity.warning,
                    location:
                        new Location(message.uri, message.line, message.column),
                    uriToSource: component.uriToSource),
                message.line,
                message.column,
                Severity.warning,
                []);
            onDiagnostic(message);
          }
        });
      });
    } else {
      int total = 0;
      _actualMessages.forEach(
          (String uri, Map<String, List<FormattedMessage>> actualMessagesMap) {
        int count = 0;
        actualMessagesMap
            .forEach((String message, List<FormattedMessage> actualMessages) {
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
  void visitLibrary(Library node) {
    if (analyzedUrisFilter != null) {
      if (analyzedUrisFilter(node.importUri)) {
        super.visitLibrary(node);
      }
    } else {
      super.visitLibrary(node);
    }
  }

  @override
  void visitDynamicGet(DynamicGet node) {
    registerError(node, "Dynamic access of '${node.name}'.");
    super.visitDynamicGet(node);
  }

  @override
  void visitDynamicSet(DynamicSet node) {
    registerError(node, "Dynamic update to '${node.name}'.");
    super.visitDynamicSet(node);
  }

  @override
  void visitDynamicInvocation(DynamicInvocation node) {
    registerError(node, "Dynamic invocation of '${node.name}'.");
    super.visitDynamicInvocation(node);
  }

  @override
  void visitPropertyGet(PropertyGet node) {
    DartType receiverType = node.receiver.getStaticType(staticTypeContext);
    if (receiverType is DynamicType && node.interfaceTarget == null) {
      registerError(node, "Dynamic access of '${node.name}'.");
    }
    super.visitPropertyGet(node);
  }

  @override
  void visitPropertySet(PropertySet node) {
    DartType receiverType = node.receiver.getStaticType(staticTypeContext);
    if (receiverType is DynamicType) {
      registerError(node, "Dynamic update to '${node.name}'.");
    }
    super.visitPropertySet(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    DartType receiverType = node.receiver.getStaticType(staticTypeContext);
    if (receiverType is DynamicType && node.interfaceTarget == null) {
      registerError(node, "Dynamic invocation of '${node.name}'.");
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (checkReturnTypes && node.function.returnType is DynamicType) {
      registerError(node, "Dynamic return type");
    }
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (checkReturnTypes && node.function.returnType is DynamicType) {
      registerError(node, "Dynamic return type");
    }
    super.visitFunctionExpression(node);
  }

  @override
  void visitProcedure(Procedure node) {
    if (checkReturnTypes &&
        node.function.returnType is DynamicType &&
        node.name.text != 'noSuchMethod') {
      registerError(node, "Dynamic return type on $node");
    }
    super.visitProcedure(node);
  }

  void registerError(TreeNode node, String message) {
    Location location = node.location;
    Uri uri = location.file;
    String uriString = relativizeUri(uri);
    Map<String, List<FormattedMessage>> actualMap = _actualMessages.putIfAbsent(
        uriString, () => <String, List<FormattedMessage>>{});
    if (uri.scheme == 'org-dartlang-sdk') {
      location = new Location(Uri.base.resolve(uri.path.substring(1)),
          location.line, location.column);
    }
    LocatedMessage locatedMessage = templateUnspecified
        .withArguments(message)
        .withLocation(uri, node.fileOffset, noLength);
    FormattedMessage diagnosticMessage = locatedMessage.withFormatting(
        format(locatedMessage, Severity.warning,
            location: location, uriToSource: component.uriToSource),
        location.line,
        location.column,
        Severity.warning,
        []);
    actualMap
        .putIfAbsent(message, () => <FormattedMessage>[])
        .add(diagnosticMessage);
  }
}
