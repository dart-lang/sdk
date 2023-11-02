// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analysis_server/src/lsp/handlers/handler_states.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../../tool/lsp_spec/meta_model_reader.dart';

void main() {
  final serverPkgPath = _getAnalysisServerPkgPath();
  final readmeFile = File(path.join(serverPkgPath, 'tool/lsp_spec/README.md'));
  final metaModelJsonFile = File(path.join(serverPkgPath,
      '../../third_party/pkg/language_server_protocol/lsp_meta_model.json'));

  group('LSP readme', () {
    test('contains all methods', () {
      final readmeContent = readmeFile.readAsStringSync();
      final model = LspMetaModelReader().readFile(metaModelJsonFile);

      final missingMethods = StringBuffer();
      for (final method in model.methods) {
        // Handle `foo/*` in the readme as well as `foo/bar`.
        final methodWildcard = method.replaceAll(RegExp(r'\/[^\/]+$'), '/*');
        if (!readmeContent.contains(' $method ') &&
            !readmeContent.contains(' $methodWildcard ')) {
          missingMethods.writeln(method);
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
      final readmeContent = readmeFile.readAsStringSync();

      final handlerGenerators = [
        ...InitializedLspStateMessageHandler.lspHandlerGenerators,
        ...InitializedStateMessageHandler.sharedHandlerGenerators,
      ];

      final missingMethods = StringBuffer();
      for (final generator in handlerGenerators) {
        final handler = generator(_MockServer());
        final method = handler.handlesMessage.toString();

        if (method.startsWith('dart')) {
          // Dart methods are included under their own heading.
          final expectedHeading = '### $method Method';
          if (!readmeContent.contains(expectedHeading)) {
            missingMethods.writeln('$method does not have a section');
          }
        } else {
          // Standard methods should be listed in the table and ticked.
          final escapedMethod = RegExp.escape(method);
          final expectedMarkdown = RegExp(' $escapedMethod .*\\| ✅ \\|');
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
  final script = Platform.script.toFilePath();
  final components = path.split(script);
  final index = components.indexOf('analysis_server');
  return path.joinAll(components.sublist(0, index + 1));
}

class _MockServer implements LspAnalysisServer {
  @override
  final initializationOptions = LspInitializationOptions(null);

  @override
  bool get onlyAnalyzeProjectsWithOpenFiles => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
