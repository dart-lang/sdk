// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/edit/fix/dartfix_info.dart';
import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/dartfix_registrar.dart';
import 'package:analysis_server/src/edit/fix/fix_error_task.dart';
import 'package:analysis_server/src/edit/fix/fix_lint_task.dart';
import 'package:analysis_server/src/edit/fix/non_nullable_fix.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/services/lint.dart';

// TODO(danrubel): Replace these consts with DartFixInfo
const nonNullable = 'non-nullable';

class EditDartFix
    with FixErrorProcessor, FixLintProcessor
    implements DartFixRegistrar {
  final AnalysisServer server;

  final Request request;
  final fixFolders = <Folder>[];
  final fixFiles = <File>[];
  // TODO(danrubel): replace with is a list of DartFixInfo
  final namesOfFixesToApply = new Set<String>();

  DartFixListener listener;

  EditDartFix(this.server, this.request) {
    listener = new DartFixListener(server);
  }

  Future<Response> compute() async {
    final params = new EditDartfixParams.fromRequest(request);

    // Determine the fixes to be applied
    final fixInfo = <DartFixInfo>[];
    if (params.includeRequiredFixes == true) {
      fixInfo.addAll(allFixes.where((i) => i.isRequired));
    }
    if (params.includedFixes != null) {
      for (String key in params.includedFixes) {
        var info = allFixes.firstWhere((i) => i.key == key, orElse: () => null);
        if (info != null) {
          fixInfo.add(info);
        } else {
          // TODO(danrubel): Report unknown fix to the user
        }
      }
    }
    if (fixInfo.isEmpty) {
      fixInfo.addAll(allFixes.where((i) => i.isDefault));
    }
    if (params.excludedFixes != null) {
      for (String key in params.excludedFixes) {
        var info = allFixes.firstWhere((i) => i.key == key, orElse: () => null);
        if (info != null) {
          fixInfo.remove(info);
        } else {
          // TODO(danrubel): Report unknown fix to the user
        }
      }
    }
    for (DartFixInfo info in fixInfo) {
      String key = info.setup(this, listener);
      if (key != null) {
        // TODO(danrubel) replace returned strings with task registration.
        namesOfFixesToApply.add(key);
      }
    }

    // Validate each included file and directory.
    final resourceProvider = server.resourceProvider;
    final contextManager = server.contextManager;
    for (String filePath in params.included) {
      if (!server.isValidFilePath(filePath)) {
        return new Response.invalidFilePathFormat(request, filePath);
      }
      Resource res = resourceProvider.getResource(filePath);
      if (!res.exists ||
          !(contextManager.includedPaths.contains(filePath) ||
              contextManager.isInAnalysisRoot(filePath))) {
        return new Response.fileNotAnalyzed(request, filePath);
      }
      if (res is Folder) {
        fixFolders.add(res);
      } else {
        fixFiles.add(res);
      }
    }

    final nonNullableFix = namesOfFixesToApply.contains(nonNullable)
        ? new NonNullableFix(listener)
        : null;

    // TODO(danrubel): Determine if a lint is configured to run as part of
    // standard analysis and use those results if available instead of
    // running the lint again.

    // Analyze each source file.
    final resources = <Resource>[];
    for (String rootPath in contextManager.includedPaths) {
      resources.add(resourceProvider.getResource(rootPath));
    }
    bool hasErrors = false;
    while (resources.isNotEmpty) {
      Resource res = resources.removeLast();
      if (res is Folder) {
        for (Resource child in res.getChildren()) {
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
      ResolvedUnitResult result = await server.getResolvedUnit(res.path);
      if (result == null || result.unit == null) {
        continue;
      }

      if (await processErrors(result)) {
        hasErrors = true;
      }
      await processLints(result);

      nonNullableFix?.applyLocalFixes(result);
    }

    // Cleanup
    for (Linter linter in linters) {
      if (linter != null) {
        linter.reporter.source = null;
        linter.reporter = null;
      }
    }

    // Apply distributed fixes
    for (FixLintTask fix in fixes) {
      await fix.applyRemainingFixes();
    }
    nonNullableFix?.applyRemainingFixes();

    return new EditDartfixResult(
      listener.suggestions,
      listener.otherSuggestions,
      hasErrors,
      listener.sourceChange.edits,
    ).toResponse(request.id);
  }

  /// Return `true` if the path in within the set of `included` files
  /// or is within an `included` directory.
  bool isIncluded(String filePath) {
    if (filePath != null) {
      for (File file in fixFiles) {
        if (file.path == filePath) {
          return true;
        }
      }
      for (Folder folder in fixFolders) {
        if (folder.contains(filePath)) {
          return true;
        }
      }
    }
    return false;
  }
}
