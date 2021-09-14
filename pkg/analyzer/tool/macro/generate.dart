// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;

void main(List<String> arguments) async {
  if (arguments.length != 1) {
    _printUsage();
    io.exit(1);
  }

  var resourceProvider = PhysicalResourceProvider.INSTANCE;
  var pathContext = resourceProvider.pathContext;

  // The directory must exist.
  var packagePath = arguments[0];
  var packageFolder = resourceProvider.getFolder(packagePath);
  if (!packageFolder.exists) {
    print('Error: $packagePath does not exist.');
    io.exit(1);
  }

  // The directory must be a Pub package.
  var pubspecYamlFile = packageFolder.getChildAssumingFile(
    file_paths.pubspecYaml,
  );
  if (!pubspecYamlFile.exists) {
    print('Error: ${pubspecYamlFile.path} does not exist.');
    io.exit(1);
  }

  var collection = AnalysisContextCollection(
    includedPaths: [packagePath],
  );
  for (var analysisContext in collection.contexts) {
    var analyzedPaths = analysisContext.contextRoot.analyzedFiles();
    for (var path in analyzedPaths) {
      if (file_paths.isDart(pathContext, path)) {
        var session = analysisContext.currentSession;
        var unitElementResult = await session.getUnitElement(path);
        if (unitElementResult is UnitElementResult) {
          var unitElement =
              unitElementResult.element as CompilationUnitElementImpl;
          // If has macro-generated content, write it.
          var macroGeneratedContent = unitElement.macroGeneratedContent;
          if (macroGeneratedContent != null) {
            var relativePath = pathContext.relative(path, from: packagePath);
            var combinedPath = pathContext.join(
                packagePath, '.dart_tool', 'analyzer', 'macro', relativePath);
            resourceProvider.getFile(combinedPath)
              ..parent2.create()
              ..writeAsStringSync(macroGeneratedContent);
          }
        }
      }
    }
  }
}

void _printUsage() {
  print('''
Usage: dart generate.dart path-to-pub-package
Write combined code of files that have macro-generated declarations.
''');
}
