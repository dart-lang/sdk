// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/edit/fix/dartfix_info.dart';
import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/dartfix_registrar.dart';
import 'package:analysis_server/src/edit/fix/fix_code_task.dart';
import 'package:analysis_server/src/edit/fix/fix_error_task.dart';
import 'package:analysis_server/src/edit/fix/fix_lint_task.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart' show SourceKind;

class EditDartFix
    with FixCodeProcessor, FixErrorProcessor, FixLintProcessor
    implements DartFixRegistrar {
  final AnalysisServer server;

  final Request request;
  final pkgFolders = <Folder>[];
  final fixFolders = <Folder>[];
  final fixFiles = <File>[];

  DartFixListener listener;

  EditDartFix(this.server, this.request) {
    listener = DartFixListener(server);
  }

  Future<Response> compute() async {
    final params = EditDartfixParams.fromRequest(request);
    // Determine the fixes to be applied
    final fixInfo = <DartFixInfo>[];
    if (params.includePedanticFixes == true) {
      for (var fix in allFixes) {
        if (fix.isPedantic && !fixInfo.contains(fix)) {
          fixInfo.add(fix);
        }
      }
    }
    if (params.includedFixes != null) {
      for (var key in params.includedFixes) {
        var info = allFixes.firstWhere((i) => i.key == key, orElse: () => null);
        if (info != null) {
          fixInfo.add(info);
        } else {
          return Response.invalidParameter(
              request, 'includedFixes', 'Unknown fix: $key');
        }
      }
    }
    if (params.excludedFixes != null) {
      for (var key in params.excludedFixes) {
        var info = allFixes.firstWhere((i) => i.key == key, orElse: () => null);
        if (info != null) {
          fixInfo.remove(info);
        } else {
          return Response.invalidParameter(
              request, 'excludedFixes', 'Unknown fix: $key');
        }
      }
    }
    for (var info in fixInfo) {
      info.setup(this, listener, params);
    }

    // Validate each included file and directory.
    final resourceProvider = server.resourceProvider;
    final contextManager = server.contextManager;

    // Discard any existing analysis so that the linters set below will be
    // used to generate errors that can then be fixed.
    // TODO(danrubel): Rework to use a different approach if this command
    // will be used from within the IDE.
    contextManager.refresh(null);

    for (var filePath in params.included) {
      if (!server.isValidFilePath(filePath)) {
        return Response.invalidFilePathFormat(request, filePath);
      }
      var res = resourceProvider.getResource(filePath);
      if (!res.exists ||
          !(contextManager.includedPaths.contains(filePath) ||
              contextManager.isInAnalysisRoot(filePath))) {
        return Response.fileNotAnalyzed(request, filePath);
      }

      // Set the linters used during analysis. If this command is used from
      // within an IDE, then this will cause the lint results to change.
      // TODO(danrubel): Rework to use a different approach if this command
      // will be used from within the IDE.
      var driver = contextManager.getDriverFor(filePath);
      var analysisOptions = driver.analysisOptions as AnalysisOptionsImpl;
      analysisOptions.lint = true;
      analysisOptions.lintRules = linters;

      var contextFolder = contextManager.getContextFolderFor(filePath);
      var pkgFolder = findPkgFolder(contextFolder);
      if (pkgFolder != null && !pkgFolders.contains(pkgFolder)) {
        pkgFolders.add(pkgFolder);
      }
      if (res is Folder) {
        fixFolders.add(res);
      } else {
        fixFiles.add(res);
      }
    }

    String changedPath;
    contextManager.driverMap.values.forEach((driver) {
      // Setup a listener to remember the resource that changed during analysis
      // so it can be reported if there is an InconsistentAnalysisException.
      driver.onCurrentSessionAboutToBeDiscarded = (String path) {
        changedPath = path;
      };
    });

    bool hasErrors;
    try {
      hasErrors = await runAllTasks();
    } on InconsistentAnalysisException catch (_) {
      // If a resource changed, report the problem without suggesting fixes
      var changedMessage = changedPath != null
          ? 'resource changed during analysis: $changedPath'
          : 'multiple resources changed during analysis.';
      return EditDartfixResult(
        [DartFixSuggestion('Analysis canceled because $changedMessage')],
        listener.otherSuggestions,
        false, // We may have errors, but we do not know, and it doesn't matter.
        listener.sourceChange.edits,
        details: listener.details,
      ).toResponse(request.id);
    }

    return EditDartfixResult(
      listener.suggestions,
      listener.otherSuggestions,
      hasErrors,
      listener.sourceChange.edits,
      details: listener.details,
    ).toResponse(request.id);
  }

  Folder findPkgFolder(Folder folder) {
    while (folder != null) {
      if (folder.getChild('analysis_options.yaml').exists ||
          folder.getChild('pubspec.yaml').exists) {
        return folder;
      }
      folder = folder.parent;
    }
    return null;
  }

  Set<String> getPathsToProcess() {
    final contextManager = server.contextManager;
    final resourceProvider = server.resourceProvider;
    final resources = <Resource>[];
    for (var rootPath in contextManager.includedPaths) {
      resources.add(resourceProvider.getResource(rootPath));
    }

    var pathsToProcess = <String>{};
    while (resources.isNotEmpty) {
      var res = resources.removeLast();
      if (res is Folder) {
        for (var child in res.getChildren()) {
          if (!child.shortName.startsWith('.') &&
              contextManager.isInAnalysisRoot(child.path) &&
              !contextManager.isIgnored(child.path)) {
            resources.add(child);
          }
        }
        continue;
      }
      if (!isIncluded(res.path)) {
        continue;
      }
      pathsToProcess.add(res.path);
    }
    return pathsToProcess;
  }

  /// Return `true` if the path in within the set of `included` files
  /// or is within an `included` directory.
  bool isIncluded(String filePath) {
    if (filePath != null) {
      for (var file in fixFiles) {
        if (file.path == filePath) {
          return true;
        }
      }
      for (var folder in fixFolders) {
        if (folder.contains(filePath)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Call the supplied [process] function to process each compilation unit.
  Future processResources(
      Future<void> Function(ResolvedUnitResult result) process) async {
    final pathsToProcess = getPathsToProcess();
    var pathsProcessed = <String>{};
    for (var path in pathsToProcess) {
      if (pathsProcessed.contains(path)) continue;
      var driver = server.getAnalysisDriver(path);
      switch (await driver.getSourceKind(path)) {
        case SourceKind.PART:
          // Parts will either be found in a library, below, or if the library
          // isn't [isIncluded], will be picked up in the final loop.
          continue;
          break;
        case SourceKind.LIBRARY:
          var result = await driver.getResolvedLibrary(path);
          if (result != null) {
            for (var unit in result.units) {
              if (pathsToProcess.contains(unit.path) &&
                  !pathsProcessed.contains(unit.path)) {
                await process(unit);
                pathsProcessed.add(unit.path);
              }
            }
          }
          break;
        default:
          break;
      }
    }

    for (var path in pathsToProcess.difference(pathsProcessed)) {
      var result = await server.getResolvedUnit(path);
      if (result == null || result.unit == null) {
        continue;
      }
      await process(result);
    }
  }

  Future<bool> runAllTasks() async {
    // Process each package
    for (var pkgFolder in pkgFolders) {
      await processPackage(pkgFolder);
    }

    var hasErrors = false;

    // Process each source file.
    try {
      await processResources((ResolvedUnitResult result) async {
        if (await processErrors(result)) {
          hasErrors = true;
        }
        if (numPhases > 0) {
          await processCodeTasks(0, result);
        }
      });
      for (var phase = 1; phase < numPhases; phase++) {
        await processResources((ResolvedUnitResult result) async {
          await processCodeTasks(phase, result);
        });
      }
      await finishCodeTasks();
    } finally {
      server.contextManager.driverMap.values
          .forEach((d) => d.onCurrentSessionAboutToBeDiscarded = null);
    }

    return hasErrors;
  }
}
