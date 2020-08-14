// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/context_manager.dart'
    show ContextManagerImpl;
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:path/path.dart' show dirname, join;

/// Finds the nearest ancestor to [filePath] that contains a pubspec/.packages/build file.
String _findProjectFolder(ResourceProvider resourceProvider, String filePath) {
  // TODO(dantup): Is there something we can reuse for this?
  var folder = dirname(filePath);
  while (folder != dirname(folder)) {
    final pubspec =
        resourceProvider.getFile(join(folder, ContextManagerImpl.PUBSPEC_NAME));
    final packages = resourceProvider
        .getFile(join(folder, ContextManagerImpl.PACKAGE_SPEC_NAME));
    final build = resourceProvider.getFile(join(folder, 'BUILD'));

    if (pubspec.exists || packages.exists || build.exists) {
      return folder;
    }
    folder = dirname(folder);
  }
  return null;
}

class TextDocumentChangeHandler
    extends MessageHandler<DidChangeTextDocumentParams, void> {
  TextDocumentChangeHandler(LspAnalysisServer server) : super(server);
  @override
  Method get handlesMessage => Method.textDocument_didChange;

  @override
  LspJsonHandler<DidChangeTextDocumentParams> get jsonHandler =>
      DidChangeTextDocumentParams.jsonHandler;

  @override
  ErrorOr<void> handle(
      DidChangeTextDocumentParams params, CancellationToken token) {
    final path = pathOfDoc(params.textDocument);
    return path.mapResult((path) => _changeFile(path, params));
  }

  ErrorOr<void> _changeFile(String path, DidChangeTextDocumentParams params) {
    String oldContents;
    if (server.resourceProvider.hasOverlay(path)) {
      oldContents = server.resourceProvider.getFile(path).readAsStringSync();
    }
    // If we didn't have the file contents, the server and client are out of sync
    // and this is a serious failure.
    if (oldContents == null) {
      return error(
        ServerErrorCodes.ClientServerInconsistentState,
        'Unable to edit document because the file was not previously opened: $path',
        null,
      );
    }
    final newContents = applyAndConvertEditsToServer(
        oldContents, params.contentChanges,
        failureIsCritical: true);
    return newContents.mapResult((result) {
      server.documentVersions[path] = params.textDocument;
      server.onOverlayUpdated(path, result.last, newContent: result.first);
      return success();
    });
  }
}

class TextDocumentCloseHandler
    extends MessageHandler<DidCloseTextDocumentParams, void> {
  /// Whether analysis roots are based on open files and should be updated.
  bool updateAnalysisRoots;

  TextDocumentCloseHandler(LspAnalysisServer server, this.updateAnalysisRoots)
      : super(server);

  @override
  Method get handlesMessage => Method.textDocument_didClose;

  @override
  LspJsonHandler<DidCloseTextDocumentParams> get jsonHandler =>
      DidCloseTextDocumentParams.jsonHandler;

  @override
  ErrorOr<void> handle(
      DidCloseTextDocumentParams params, CancellationToken token) {
    final path = pathOfDoc(params.textDocument);
    return path.mapResult((path) {
      server.removePriorityFile(path);
      server.documentVersions.remove(path);
      server.onOverlayDestroyed(path);

      if (updateAnalysisRoots) {
        // If there are no other open files in this context, we can remove it
        // from the analysis roots.
        final contextFolder = server.contextManager.getContextFolderFor(path);
        var hasOtherFilesInContext = false;
        for (var otherDocPath in server.documentVersions.keys) {
          if (server.contextManager.getContextFolderFor(otherDocPath) ==
              contextFolder) {
            hasOtherFilesInContext = true;
            break;
          }
        }
        if (!hasOtherFilesInContext) {
          final projectFolder =
              _findProjectFolder(server.resourceProvider, path);
          server.updateAnalysisRoots([], [projectFolder]);
        }
      }

      return success();
    });
  }
}

class TextDocumentOpenHandler
    extends MessageHandler<DidOpenTextDocumentParams, void> {
  /// Whether analysis roots are based on open files and should be updated.
  bool updateAnalysisRoots;

  DateTime lastSentAnalyzeOpenFilesWarnings;

  TextDocumentOpenHandler(LspAnalysisServer server, this.updateAnalysisRoots)
      : super(server);

  @override
  Method get handlesMessage => Method.textDocument_didOpen;

  @override
  LspJsonHandler<DidOpenTextDocumentParams> get jsonHandler =>
      DidOpenTextDocumentParams.jsonHandler;

  @override
  ErrorOr<void> handle(
      DidOpenTextDocumentParams params, CancellationToken token) {
    final doc = params.textDocument;
    final path = pathOfDocItem(doc);
    return path.mapResult((path) {
      // We don't get a VersionedTextDocumentIdentifier with a didOpen but we
      // do get the necessary info to create one.
      server.documentVersions[path] = VersionedTextDocumentIdentifier(
        version: params.textDocument.version,
        uri: params.textDocument.uri,
      );
      server.onOverlayCreated(path, doc.text);

      final driver = server.contextManager.getDriverFor(path);
      // If the file did not exist, and is "overlay only", it still should be
      // analyzed. Add it to driver to which it should have been added.

      driver?.addFile(path);

      // If there was no current driver for this file, then we may need to add
      // its project folder as an analysis root.
      if (updateAnalysisRoots && driver == null) {
        final projectFolder = _findProjectFolder(server.resourceProvider, path);
        if (projectFolder != null) {
          server.updateAnalysisRoots([projectFolder], []);
        } else {
          // There was no pubspec - ideally we should add just the file
          // here but we don't currently support that.
          // https://github.com/dart-lang/sdk/issues/32256

          // Send a warning to the user, but only if we haven't already in the
          // last 60 seconds.
          if (lastSentAnalyzeOpenFilesWarnings == null ||
              (DateTime.now()
                      .difference(lastSentAnalyzeOpenFilesWarnings)
                      .inSeconds >
                  60)) {
            lastSentAnalyzeOpenFilesWarnings = DateTime.now();
            server.showMessageToUser(
                MessageType.Warning,
                'When using onlyAnalyzeProjectsWithOpenFiles, files opened that '
                'are not contained within project folders containing pubspec.yaml, '
                '.packages or BUILD files will not be analyzed.');
          }
        }
      }

      server.addPriorityFile(path);

      return success();
    });
  }
}
