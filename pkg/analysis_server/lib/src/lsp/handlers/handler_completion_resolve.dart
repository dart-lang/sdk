// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Element;
import 'package:analysis_server/src/computer/computer_hover.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

class CompletionResolveHandler
    extends MessageHandler<CompletionItem, CompletionItem> {
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
    final resolutionInfo = params.data;

    if (resolutionInfo is DartNotImportedCompletionResolutionInfo) {
      return resolveDartNotImportedCompletion(params, resolutionInfo, token);
    } else if (resolutionInfo is PubPackageCompletionItemResolutionInfo) {
      return resolvePubPackageCompletion(params, resolutionInfo, token);
    } else {
      return success(params);
    }
  }

  Future<ErrorOr<CompletionItem>> resolveDartCompletion(
    CompletionItem item,
    LspClientCapabilities clientCapabilities,
    CancellationToken token, {
    required String file,
    required Uri libraryUri,
  }) async {
    const timeout = Duration(milliseconds: 1000);
    var timer = Stopwatch()..start();
    _latestCompletionItem = item;
    while (item == _latestCompletionItem && timer.elapsed < timeout) {
      try {
        final session = await server.getAnalysisSession(file);

        // We shouldn't not get a driver/session, but if we did perhaps the file
        // was removed from the analysis set so assume the request is no longer
        // valid.
        if (session == null || token.isCancellationRequested) {
          return cancelled();
        }

        final result = await session.getResolvedUnit(file);
        if (result is! ResolvedUnitResult) {
          return cancelled();
        }

        if (token.isCancellationRequested) {
          return cancelled();
        }

        final builder = ChangeBuilder(session: session);
        await builder.addDartFileEdit(file, (builder) {
          builder.importLibraryElement(libraryUri);
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
              arguments: [
                {'edit': workspaceEdit}
              ]);
        }

        // Look up documentation if we can get an element for this item.
        Either2<MarkupContent, String>? documentation;
        final element = await _getElement(session, libraryUri, item);
        if (element != null) {
          final formats = clientCapabilities.completionDocumentationFormats;
          final dartDocInfo = server.getDartdocDirectiveInfoForSession(session);
          final dartDocData =
              DartUnitHoverComputer.computeDocumentation(dartDocInfo, element);
          final dartDoc = dartDocData?.full;
          // `dartDoc` can be both null or empty.
          documentation = dartDoc != null && dartDoc.isNotEmpty
              ? asMarkupContentOrString(formats, dartDoc)
              : null;
        }

        // If the only URI we have is a file:// URI, display it as relative to
        // the file we're importing into, rather than the full URI.
        final pathContext = server.resourceProvider.pathContext;
        final autoImportDisplayUri = libraryUri.isScheme('file')
            // Compute the relative path and then put into a URI so the display
            // always uses forward slashes (as a URI) regardless of platform.
            ? Uri.file(pathContext.relative(
                libraryUri.toFilePath(),
                from: pathContext.dirname(file),
              ))
            : libraryUri;

        return success(CompletionItem(
          label: item.label,
          kind: item.kind,
          tags: item.tags,
          detail: changes.edits.isNotEmpty
              ? "Auto import from '$autoImportDisplayUri'\n\n${item.detail ?? ''}"
                  .trim()
              : item.detail,
          documentation: documentation,
          deprecated: item.deprecated,
          preselect: item.preselect,
          sortText: item.sortText,
          filterText: item.filterText,
          insertTextFormat: item.insertTextFormat,
          insertTextMode: item.insertTextMode,
          textEdit: item.textEdit,
          additionalTextEdits: thisFilesChanges
              .expand((change) =>
                  change.edits.map((edit) => toTextEdit(result.lineInfo, edit)))
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

  Future<ErrorOr<CompletionItem>> resolveDartNotImportedCompletion(
    CompletionItem item,
    DartNotImportedCompletionResolutionInfo data,
    CancellationToken token,
  ) async {
    final clientCapabilities = server.clientCapabilities;
    if (clientCapabilities == null) {
      // This should not happen unless a client misbehaves.
      return error(ErrorCodes.ServerNotInitialized,
          'Requests not before server is initilized');
    }

    return resolveDartCompletion(
      item,
      clientCapabilities,
      token,
      file: data.file,
      libraryUri: Uri.parse(data.libraryUri),
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

  /// Gets the [Element] for the completion item [item] in [libraryUri].
  Future<Element?> _getElement(
    AnalysisSession session,
    Uri libraryUri,
    CompletionItem item,
  ) async {
    // If filterText is different to the label, it's because label has
    // parens/args appended so we should take the filterText to get the
    // elements name without. We cannot use insertText as it may include
    // snippets, whereas filterText is always just the pure string.
    var name = item.filterText ?? item.label;

    // The label might be `MyEnum.myValue`, but we need to find `MyEnum`.
    if (name.contains('.')) {
      name = name.substring(0, name.indexOf('.'));
    }

    // TODO(dantup): This is not handling default constructors or enums
    //  correctly, so they will both show dart docs from the class/enum and not
    //  the constructor/enum member. Extension members are not found at all and
    //  will provide no docs.

    final result = await session.getLibraryByUri(libraryUri.toString());
    return result is LibraryElementResult
        ? result.element.exportNamespace.get(name)
        : null;
  }
}
