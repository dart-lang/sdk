// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/util/file_paths.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/// The handler for the `edit.getAvailableRefactorings` request.
class EditGetAvailableRefactoringsHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  EditGetAvailableRefactoringsHandler(
      super.server, super.request, super.cancellationToken, super.performance);

  @override
  Future<void> handle() async {
    var params = EditGetAvailableRefactoringsParams.fromRequest(request,
        clientUriConverter: server.uriConverter);
    var file = params.file;
    var offset = params.offset;
    var length = params.length;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }
    if (isMacroGenerated(file)) {
      sendResult(EditGetAvailableRefactoringsResult([]));
      return;
    }

    // add refactoring kinds
    var kinds = <RefactoringKind>[];
    // Check nodes.
    var searchEngine = server.searchEngine;
    {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        // Try EXTRACT_LOCAL_VARIABLE.
        if (ExtractLocalRefactoring(resolvedUnit, offset, length)
            .isAvailable()) {
          kinds.add(RefactoringKind.EXTRACT_LOCAL_VARIABLE);
        }
        // Try EXTRACT_METHOD.
        if (ExtractMethodRefactoring(searchEngine, resolvedUnit, offset, length)
            .isAvailable()) {
          kinds.add(RefactoringKind.EXTRACT_METHOD);
        }
        // Try EXTRACT_WIDGETS.
        if (ExtractWidgetRefactoring(searchEngine, resolvedUnit, offset, length)
            .isAvailable()) {
          kinds.add(RefactoringKind.EXTRACT_WIDGET);
        }
      }
    }
    // check elements
    var resolvedUnit = await server.getResolvedUnit(file);
    if (resolvedUnit != null) {
      var node = NodeLocator(offset).searchWithin(resolvedUnit.unit);
      var element = server.getElementOfNode(node);
      if (element != null) {
        var refactoringWorkspace = server.refactoringWorkspace;
        // try CONVERT_METHOD_TO_GETTER
        if (element is ExecutableElement) {
          if (ConvertMethodToGetterRefactoring(
                  refactoringWorkspace, resolvedUnit.session, element)
              .isAvailable()) {
            kinds.add(RefactoringKind.CONVERT_METHOD_TO_GETTER);
          }
        }
        // try RENAME
        var renameRefactoring = RenameRefactoring.create(
            refactoringWorkspace, resolvedUnit, element);
        if (renameRefactoring != null) {
          kinds.add(RefactoringKind.RENAME);
        }
      }
    }
    // respond
    sendResult(EditGetAvailableRefactoringsResult(kinds));
  }
}
