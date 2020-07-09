// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart' as analyzer;
import 'package:analyzer/src/util/comment.dart' as analyzer;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';

class CompletionResolveHandler
    extends MessageHandler<CompletionItem, CompletionItem> {
  ///
  /// The latest completion item we were asked to resolve. We use it to abort
  /// previous requests.
  ///
  CompletionItem _latestCompletionItem;

  CompletionResolveHandler(LspAnalysisServer server) : super(server);

  @override
  Method get handlesMessage => Method.completionItem_resolve;

  @override
  LspJsonHandler<CompletionItem> get jsonHandler => CompletionItem.jsonHandler;

  @override
  Future<ErrorOr<CompletionItem>> handle(
      CompletionItem item, CancellationToken token) async {
    // If this isn't an item with resolution data, return the same item back.
    if (item.data == null) {
      return success(item);
    }

    final data = item.data;
    final lineInfo = server.getLineInfo(data.file);
    if (lineInfo == null) {
      return error(
        ErrorCodes.InternalError,
        'Line info not available for ${data.file}',
        null,
      );
    }

    // TODO(dantup): This logic is all repeated from domain_completion and needs
    // extracting (with support for the different types of responses between
    // the servers). Where is an appropriate place to put it?

    var library = server.declarationsTracker.getLibrary(data.libId);
    if (library == null) {
      return error(
        ErrorCodes.InvalidParams,
        'Library ID is not valid: ${data.libId}',
        data.libId.toString(),
      );
    }

    // The label might be `MyEnum.myValue`, but we import only `MyEnum`.
    var requestedName = item.insertText ?? item.label;
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
        var analysisDriver = server.getAnalysisDriver(data.file);
        var session = analysisDriver.currentSession;

        if (token.isCancellationRequested) {
          return cancelled();
        }

        analyzer.LibraryElement requestedLibraryElement;
        try {
          requestedLibraryElement = await session.getLibraryByUri(
            library.uriStr,
          );
        } on ArgumentError catch (e) {
          return error(
            ErrorCodes.InvalidParams,
            'Invalid library URI: ${library.uriStr}',
            '$e',
          );
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
        final builder = DartChangeBuilder(session);
        await builder.addFileEdit(data.file, (builder) {
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
            changes.edits.where((e) => e.file == data.file).toList();
        final otherFilesChanges =
            changes.edits.where((e) => e.file != data.file).toList();

        // If this completion involves editing other files, we'll need to build
        // a command that the client will call to apply those edits later.
        Command command;
        if (otherFilesChanges.isNotEmpty) {
          final workspaceEdit = createWorkspaceEdit(server, otherFilesChanges);
          command = Command(
              title: 'Add import',
              command: Commands.sendWorkspaceEdit,
              arguments: [workspaceEdit]);
        }

        // Documentation is added on during resolve for LSP.
        final formats = server.clientCapabilities?.textDocument?.completion
            ?.completionItem?.documentationFormat;
        final dartDoc =
            analyzer.getDartDocPlainText(requestedElement.documentationComment);
        final documentation = asStringOrMarkupContent(formats, dartDoc);

        return success(CompletionItem(
          label: item.label,
          kind: item.kind,
          tags: null, // TODO(dantup): CompletionItemTags (eg. deprecated)
          detail: data.displayUri != null && thisFilesChanges.isNotEmpty
              ? "Auto import from '${data.displayUri}'\n\n${item.detail ?? ''}"
                  .trim()
              : item.detail,
          documentation: documentation,
          // The deprecated field is deprecated, but we should still supply it
          // for clients that have not adopted CompletionItemTags.
          // ignore: deprecated_member_use_from_same_package
          deprecated: item.deprecated,
          preselect: item.preselect,
          sortText: item.sortText,
          filterText: item.filterText,
          insertText: newInsertText,
          insertTextFormat: item.insertTextFormat,
          textEdit: TextEdit(
            // TODO(dantup): If `clientSupportsSnippets == true` then we should map
            // `selection` in to a snippet (see how Dart Code does this).
            range: toRange(lineInfo, item.data.rOffset, item.data.rLength),
            newText: newInsertText,
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
}
