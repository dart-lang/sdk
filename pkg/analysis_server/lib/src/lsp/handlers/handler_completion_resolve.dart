// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_custom_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart' as analyzer;
import 'package:analyzer/src/util/comment.dart' as analyzer;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

class CompletionResolveHandler
    extends MessageHandler<CompletionItem, CompletionItem> {
  /// The last completion item we asked to be resolved.
  ///
  /// Used to abort previous requests in async handlers if another resolve request
  /// arrives while the previous is being processed (for clients that don't send
  /// cancel events).
  CompletionItem? _latestCompletionItem;

  CompletionResolveHandler(LspAnalysisServer server) : super(server);

  @override
  Method get handlesMessage => Method.completionItem_resolve;

  @override
  LspJsonHandler<CompletionItem> get jsonHandler => CompletionItem.jsonHandler;

  @override
  Future<ErrorOr<CompletionItem>> handle(
    CompletionItem item,
    CancellationToken token,
  ) async {
    final resolutionInfo = item.data;

    if (resolutionInfo is DartCompletionItemResolutionInfo) {
      return resolveDartCompletion(item, resolutionInfo, token);
    } else if (resolutionInfo is PubPackageCompletionItemResolutionInfo) {
      return resolvePubPackageCompletion(item, resolutionInfo, token);
    } else {
      return success(item);
    }
  }

  Future<ErrorOr<CompletionItem>> resolveDartCompletion(
    CompletionItem item,
    DartCompletionItemResolutionInfo data,
    CancellationToken token,
  ) async {
    final clientCapabilities = server.clientCapabilities;
    if (clientCapabilities == null) {
      // This should not happen unless a client misbehaves.
      return error(ErrorCodes.ServerNotInitialized,
          'Requests not before server is initilized');
    }

    final file = data.file;
    final lineInfo = server.getLineInfo(file);
    if (lineInfo == null) {
      return error(
        ErrorCodes.InternalError,
        'Line info not available for $file',
        null,
      );
    }

    // TODO(dantup): This logic is all repeated from domain_completion and needs
    // extracting (with support for the different types of responses between
    // the servers). Where is an appropriate place to put it?

    var library = server.declarationsTracker?.getLibrary(data.libId);
    if (library == null) {
      return error(
        ErrorCodes.InvalidParams,
        'Library ID is not valid: ${data.libId}',
        data.libId.toString(),
      );
    }

    // If filterText is different to the label, it's because label has parens/args
    // appended and we should take the basic label. We cannot use insertText as
    // it may include snippets, whereas filterText is always just the pure string.
    var requestedName = item.filterText ?? item.label;
    // The label might be `MyEnum.myValue`, but we import only `MyEnum`.
    if (requestedName.contains('.')) {
      requestedName = requestedName.substring(
        0,
        requestedName.indexOf('.'),
      );
    }

    const timeout = Duration(milliseconds: 1000);
    var timer = Stopwatch()..start();
    _latestCompletionItem = item;
    while (item == _latestCompletionItem && timer.elapsed < timeout) {
      try {
        final analysisDriver = server.getAnalysisDriver(file);
        final session = analysisDriver?.currentSession;

        // We shouldn't not get a driver/session, but if we did perhaps the file
        // was removed from the analysis set so assume the request is no longer
        // valid.
        if (session == null || token.isCancellationRequested) {
          return cancelled();
        }

        analyzer.LibraryElement requestedLibraryElement;
        {
          final result = await session.getLibraryByUri(library.uriStr);
          if (result is LibraryElementResult) {
            requestedLibraryElement = result.element;
          } else {
            return error(
              ErrorCodes.InvalidParams,
              'Invalid library URI: ${library.uriStr}',
              '${result.runtimeType}',
            );
          }
        }

        if (token.isCancellationRequested) {
          return cancelled();
        }

        var requestedElement =
            requestedLibraryElement.exportNamespace.get(requestedName);
        if (requestedElement == null) {
          return error(
            ErrorCodes.InvalidParams,
            'No such element: $requestedName in ${library.uriStr}',
            requestedName,
          );
        }

        var newInsertText = item.insertText ?? item.label;
        final builder = ChangeBuilder(session: session);
        await builder.addDartFileEdit(file, (builder) {
          final result = builder.importLibraryElement(library.uri);
          if (result.prefix != null) {
            newInsertText = '${result.prefix}.$newInsertText';
          }
        });

        if (token.isCancellationRequested) {
          return cancelled();
        }

        final changes = builder.sourceChange;
        final thisFilesChanges =
            changes.edits.where((e) => e.file == file).toList();
        final otherFilesChanges =
            changes.edits.where((e) => e.file != file).toList();

        // If this completion involves editing other files, we'll need to build
        // a command that the client will call to apply those edits later.
        Command? command;
        if (otherFilesChanges.isNotEmpty) {
          final workspaceEdit =
              createPlainWorkspaceEdit(server, otherFilesChanges);
          command = Command(
              title: 'Add import',
              command: Commands.sendWorkspaceEdit,
              arguments: [workspaceEdit]);
        }

        // Documentation is added on during resolve for LSP.
        final formats = clientCapabilities.completionDocumentationFormats;
        final supportsInsertReplace =
            clientCapabilities.insertReplaceCompletionRanges;
        final dartDoc =
            analyzer.getDartDocPlainText(requestedElement.documentationComment);
        final documentation =
            dartDoc != null ? asStringOrMarkupContent(formats, dartDoc) : null;

        return success(CompletionItem(
          label: item.label,
          kind: item.kind,
          tags: item.tags,
          detail: thisFilesChanges.isNotEmpty
              ? "Auto import from '${data.displayUri}'\n\n${item.detail ?? ''}"
                  .trim()
              : item.detail,
          documentation: documentation,
          deprecated: item.deprecated,
          preselect: item.preselect,
          sortText: item.sortText,
          filterText: item.filterText,
          insertText: newInsertText,
          insertTextFormat: item.insertTextFormat,
          textEdit: supportsInsertReplace && data.iLength != data.rLength
              ? Either2<TextEdit, InsertReplaceEdit>.t2(
                  InsertReplaceEdit(
                    insert: toRange(lineInfo, data.rOffset, data.iLength),
                    replace: toRange(lineInfo, data.rOffset, data.rLength),
                    newText: newInsertText,
                  ),
                )
              : Either2<TextEdit, InsertReplaceEdit>.t1(
                  TextEdit(
                    range: toRange(lineInfo, data.rOffset, data.rLength),
                    newText: newInsertText,
                  ),
                ),
          additionalTextEdits: thisFilesChanges
              .expand((change) =>
                  change.edits.map((edit) => toTextEdit(lineInfo, edit)))
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
      null,
    );
  }

  Future<ErrorOr<CompletionItem>> resolvePubPackageCompletion(
    CompletionItem item,
    PubPackageCompletionItemResolutionInfo data,
    CancellationToken token,
  ) async {
    // Fetch details for this package. This may come from the cache or trigger
    // a real web request to the Pub API.
    final packageDetails =
        await server.pubPackageService.packageDetails(data.packageName);

    if (token.isCancellationRequested) {
      return cancelled();
    }

    final description = packageDetails?.description;
    return success(CompletionItem(
      label: item.label,
      kind: item.kind,
      tags: item.tags,
      detail: item.detail,
      documentation: description != null
          ? Either2<String, MarkupContent>.t1(description)
          : null,
      deprecated: item.deprecated,
      preselect: item.preselect,
      sortText: item.sortText,
      filterText: item.filterText,
      insertText: item.insertText,
      insertTextFormat: item.insertTextFormat,
      textEdit: item.textEdit,
      additionalTextEdits: item.additionalTextEdits,
      commitCharacters: item.commitCharacters,
      command: item.command,
      data: item.data,
    ));
  }
}
