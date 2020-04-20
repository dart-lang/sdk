// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';

import 'utils/package_root.dart' as package_root;

main() async {
  SnippetTester tester = SnippetTester();
  await tester.verify();
  if (tester.output.isNotEmpty) {
    fail(tester.output.toString());
  }
}

class SnippetTester {
  OverlayResourceProvider provider;
  Folder docFolder;
  String snippetDirPath;
  String snippetPath;

  StringBuffer output = StringBuffer();

  SnippetTester() {
    provider = OverlayResourceProvider(PhysicalResourceProvider.INSTANCE);
    String packageRoot =
        provider.pathContext.normalize(package_root.packageRoot);
    String analyzerPath = provider.pathContext.join(packageRoot, 'analyzer');
    String docPath = provider.pathContext.join(analyzerPath, 'doc');
    docFolder = provider.getFolder(docPath);
    snippetDirPath =
        provider.pathContext.join(analyzerPath, 'test', 'snippets');
    snippetPath = provider.pathContext.join(snippetDirPath, 'snippet.dart');
  }

  void verify() async {
    await verifyFolder(docFolder);
  }

  void verifyFile(File file) async {
    String content = file.readAsStringSync();
    List<String> lines = const LineSplitter().convert(content);
    List<String> codeLines = [];
    bool inCode = false;
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      if (line == '```dart') {
        if (inCode) {
          // TODO(brianwilkerson) Report this.
        }
        inCode = true;
      } else if (line == '```') {
        if (!inCode) {
          // TODO(brianwilkerson) Report this.
        }
        await verifySnippet(file, codeLines.join('\n'));
        codeLines.clear();
        inCode = false;
      } else if (inCode) {
        codeLines.add(line);
      }
    }
  }

  void verifyFolder(Folder folder) async {
    for (Resource child in folder.getChildren()) {
      if (child is File) {
        if (child.shortName.endsWith('.md')) {
          await verifyFile(child);
        }
      } else if (child is Folder) {
        await verifyFolder(child);
      }
    }
  }

  void verifySnippet(File file, String snippet) async {
    // TODO(brianwilkerson) When the files outside of 'src' contain only public
    //  API, write code to compute the list of imports so that new public API
    //  will automatically be allowed.
    String imports = '''
import 'dart:math' as math;

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';

''';
    provider.setOverlay(snippetPath,
        content: '''
$imports
$snippet
''',
        modificationStamp: 1);
    try {
      AnalysisContextCollection collection = AnalysisContextCollection(
          includedPaths: <String>[snippetDirPath], resourceProvider: provider);
      List<AnalysisContext> contexts = collection.contexts;
      if (contexts.length != 1) {
        fail('The snippets directory contains multiple analysis contexts.');
      }
      ErrorsResult results =
          await contexts[0].currentSession.getErrors(snippetPath);
      Iterable<AnalysisError> errors = results.errors.where((error) {
        ErrorCode errorCode = error.errorCode;
        return errorCode != HintCode.UNUSED_IMPORT &&
            errorCode != HintCode.UNUSED_LOCAL_VARIABLE;
      });
      if (errors.isNotEmpty) {
        String filePath =
            provider.pathContext.relative(file.path, from: docFolder.path);
        if (output.isNotEmpty) {
          output.writeln();
        }
        output.writeln('Errors in snippet in "$filePath":');
        output.writeln();
        output.writeln(snippet);
        output.writeln();
        int importsLength = imports.length + 1; // account for the '\n'.
        for (var error in errors) {
          writeError(error, importsLength);
        }
      }
    } catch (exception, stackTrace) {
      if (output.isNotEmpty) {
        output.writeln();
      }
      output.writeln('Exception while analyzing "$snippet"');
      output.writeln();
      output.writeln(exception);
      output.writeln(stackTrace);
    } finally {
      provider.removeOverlay(snippetPath);
    }
  }

  void writeError(AnalysisError error, int prefixLength) {
    output.write(error.errorCode);
    output.write(' (');
    output.write(error.offset - prefixLength);
    output.write(', ');
    output.write(error.length);
    output.write(') ');
    output.writeln(error.message);
  }
}
