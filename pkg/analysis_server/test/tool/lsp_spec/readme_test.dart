// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analysis_server/src/lsp/handlers/handler_execute_command.dart';
import 'package:analysis_server/src/lsp/handlers/handler_states.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../../tool/lsp_spec/meta_model.dart';

void main() {
  var serverPkgPath = _getAnalysisServerPkgPath();
  var readmeFile = File(path.join(serverPkgPath, 'tool/lsp_spec/README.md'));
  var metaModelJsonFile = File(
    path.join(
      serverPkgPath,
      '../../third_party/pkg/language_server_protocol/lsp_meta_model.json',
    ),
  );

  group('LSP readme', () {
    test('contains all methods', () {
      var readmeContent = readmeFile.readAsStringSync();
      var model = LspMetaModelReader().readFile(metaModelJsonFile);
      model = LspMetaModelCleaner().cleanModel(model);

      var missingMethods = StringBuffer();
      for (var method in model.methods) {
        // Handle `foo/*` in the readme as well as `foo/bar`.
        var methodName = method.value;
        var methodWildcard = methodName.replaceAll(RegExp(r'\/[^\/]+$'), '/*');
        if (!readmeContent.contains(' $methodName ') &&
            !readmeContent.contains(' $methodWildcard ')) {
          missingMethods.writeln(methodName);
        }
      }

      if (missingMethods.isNotEmpty) {
        fail(
          'The following Methods are not listed in the README.md file:\n\n'
          '$missingMethods',
        );
      }
    });

    test('has implemented methods ticked', () {
      var readmeContent = readmeFile.readAsStringSync();

      var handlerGenerators = [
        ...InitializedLspStateMessageHandler.lspHandlerGenerators,
        ...InitializedStateMessageHandler.sharedHandlerGenerators,
      ];

      var missingMethods = StringBuffer();
      for (var generator in handlerGenerators) {
        var handler = generator(_MockServer());
        var method = handler.handlesMessage.toString();

        if (method.startsWith('experimental/')) {
          // Experimental handlers may change frequently, exclude them.
        } else if (method.startsWith('dart')) {
          // Dart methods are included under their own heading.
          var expectedHeading = '### $method Method';
          if (!readmeContent.contains(expectedHeading)) {
            missingMethods.writeln('$method does not have a section');
          }
        } else {
          // Standard methods should be listed in the table and ticked.
          var escapedMethod = RegExp.escape(method);
          var expectedMarkdown = RegExp(' $escapedMethod .*\\| ✅ \\|');
          if (!readmeContent.contains(expectedMarkdown)) {
            missingMethods.writeln('$method is not listed/ticked in the table');
          }
        }
      }

      if (missingMethods.isNotEmpty) {
        fail(
          'The following are not listed correctly in the README.md file:\n\n'
          '$missingMethods',
        );
      }
    });
  });
}

String _getAnalysisServerPkgPath() {
  var script = Platform.script.toFilePath();
  var components = path.split(script);
  var index = components.indexOf('analysis_server');
  return path.joinAll(components.sublist(0, index + 1));
}

class _MockServer implements LspAnalysisServer {
  @override
  final initializationOptions = LspInitializationOptions(null);

  @override
  ExecuteCommandHandler? executeCommandHandler;

  @override
  bool get onlyAnalyzeProjectsWithOpenFiles => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
