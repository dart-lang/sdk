// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Element;
import 'package:analysis_server/src/computer/computer_hover.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/utilities/extensions/analysis_session.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

class CompletionResolveHandler
    extends LspMessageHandler<CompletionItem, CompletionItem> {
  /// The last completion item we asked to be resolved.
  ///
  /// Used to abort previous requests in async handlers if another resolve request
  /// arrives while the previous is being processed (for clients that don't send
  /// cancel events).
  CompletionItem? _latestCompletionItem;

  CompletionResolveHandler(super.server);

  @override
  Method get handlesMessage => Method.completionItem_resolve;

  @override
  LspJsonHandler<CompletionItem> get jsonHandler => CompletionItem.jsonHandler;

  @override
  Future<ErrorOr<CompletionItem>> handle(
    CompletionItem params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    var capabilities = message.clientCapabilities;
    if (capabilities == null) {
      return serverNotInitializedError;
    }

    var resolutionInfo = params.data;

    if (resolutionInfo is DartCompletionResolutionInfo) {
      return resolveDartCompletion(capabilities, params, resolutionInfo, token);
    } else if (resolutionInfo is PubPackageCompletionItemResolutionInfo) {
      return resolvePubPackageCompletion(params, resolutionInfo, token);
    } else {
      return success(params);
    }
  }

  Future<ErrorOr<CompletionItem>> resolveDartCompletion(
    LspClientCapabilities clientCapabilities,
    CompletionItem item,
    DartCompletionResolutionInfo data,
    CancellationToken token,
  ) async {
    var file = data.file;
    var importUris = data.importUris.map(Uri.parse).toList();
    var elementLocationReference = data.ref;
    var elementLocation = elementLocationReference != null
        ? ElementLocationImpl.con2(elementLocationReference)
        : null;

    const timeout = Duration(milliseconds: 1000);
    var timer = Stopwatch()..start();
    _latestCompletionItem = item;
    while (item == _latestCompletionItem && timer.elapsed < timeout) {
      try {
        var session = await server.getAnalysisSession(file);

        // We shouldn't not get a driver/session, but if we did perhaps the file
        // was removed from the analysis set so assume the request is no longer
        // valid.
        if (session == null || token.isCancellationRequested) {
          return cancelled();
        }

        var result = await session.getResolvedUnit(file);
        if (result is! ResolvedUnitResult) {
          return cancelled();
        }

        if (token.isCancellationRequested) {
          return cancelled();
        }

        var builder = ChangeBuilder(session: session);
        await builder.addDartFileEdit(file, (builder) {
          for (var uri in importUris) {
            builder.importLibraryElement(uri);
          }
        });

        if (token.isCancellationRequested) {
          return cancelled();
        }

        var changes = builder.sourceChange;
        var thisFilesChanges =
            changes.edits.where((e) => e.file == file).toList();
        var otherFilesChanges =
            changes.edits.where((e) => e.file != file).toList();

        // If this completion involves editing other files, we'll need to build
        // a command that the client will call to apply those edits later.
        Command? command;
        if (otherFilesChanges.isNotEmpty) {
          var workspaceEdit = createPlainWorkspaceEdit(
              server, clientCapabilities, otherFilesChanges);
          command = Command(
              title: 'Add import',
              command: Commands.sendWorkspaceEdit,
              arguments: [
                {'edit': workspaceEdit}
              ]);
        }

        // Look up documentation if we can get an element for this item.
        Either2<MarkupContent, String>? documentation;
        var element = elementLocation != null
            ? await session.locateElement(elementLocation)
            : null;
        if (element != null) {
          var formats = clientCapabilities.completionDocumentationFormats;
          var dartDocInfo = server.getDartdocDirectiveInfoForSession(session);
          var dartDoc = DartUnitHoverComputer.computePreferredDocumentation(
              dartDocInfo,
              element,
              server.lspClientConfiguration.global.preferredDocumentation);
          // `dartDoc` can be both null or empty.
          documentation = dartDoc != null && dartDoc.isNotEmpty
              ? asMarkupContentOrString(formats, dartDoc)
              : null;
        }

        String? detail = item.detail;
        if (changes.edits.isNotEmpty && importUris.isNotEmpty) {
          if (importUris.length == 1) {
            var libraryUri = importUris.first;
            var autoImportDisplayUriString = getCompletionDisplayUriString(
              uriConverter: server.uriConverter,
              pathContext: server.pathContext,
              elementLibraryUri: libraryUri,
              completionFilePath: file,
            );

            detail =
                "Auto import from '$autoImportDisplayUriString'\n\n${item.detail ?? ''}"
                    .trim();
          } else {
            detail = "Auto import required URIs\n\n${item.detail ?? ''}".trim();
          }
        }

        return success(CompletionItem(
          label: item.label,
          kind: item.kind,
          tags: item.tags,
          detail: detail,
          labelDetails: item.labelDetails,
          documentation: documentation,
          deprecated: item.deprecated,
          preselect: item.preselect,
          sortText: item.sortText,
          filterText: item.filterText,
          insertTextFormat: item.insertTextFormat,
          insertTextMode: item.insertTextMode,
          textEdit: item.textEdit,
          additionalTextEdits: thisFilesChanges
              .expand((change) => sortSourceEditsForLsp(change.edits)
                  .map((edit) => toTextEdit(result.lineInfo, edit)))
              .toList(),
          commitCharacters: item.commitCharacters,
          command: command ?? item.command,
          data: item.data,
        ));
      } on InconsistentAnalysisException {
        // Loop around to try again.
      }
    }

    // Timeout or abort, send the empty response.

    return error(
      ErrorCodes.RequestCancelled,
      'Request was cancelled for taking too long or another request being received',
    );
  }

  Future<ErrorOr<CompletionItem>> resolvePubPackageCompletion(
    CompletionItem item,
    PubPackageCompletionItemResolutionInfo data,
    CancellationToken token,
  ) async {
    // Fetch details for this package. This may come from the cache or trigger
    // a real web request to the Pub API.
    var packageDetails =
        await server.pubPackageService.packageDetails(data.packageName);

    if (token.isCancellationRequested) {
      return cancelled();
    }

    var description = packageDetails?.description;
    return success(CompletionItem(
      label: item.label,
      kind: item.kind,
      tags: item.tags,
      detail: item.detail,
      documentation: description != null
          ? Either2<MarkupContent, String>.t2(description)
          : null,
      deprecated: item.deprecated,
      preselect: item.preselect,
      sortText: item.sortText,
      filterText: item.filterText,
      insertTextFormat: item.insertTextFormat,
      textEdit: item.textEdit,
      additionalTextEdits: item.additionalTextEdits,
      commitCharacters: item.commitCharacters,
      command: item.command,
      data: item.data,
    ));
  }
}
