// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/computer/computer_call_hierarchy.dart'
    as call_hierarchy;
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source_range.dart';

/// A handler for `callHierarchy/incoming` that returns the incoming calls for
/// the target supplied by the client.
class IncomingCallHierarchyHandler extends _AbstractCallHierarchyCallsHandler<
    CallHierarchyIncomingCallsParams,
    CallHierarchyIncomingCallsResult,
    CallHierarchyIncomingCall> with _CallHierarchyUtils {
  IncomingCallHierarchyHandler(super.server);
  @override
  Method get handlesMessage => Method.callHierarchy_incomingCalls;

  @override
  LspJsonHandler<CallHierarchyIncomingCallsParams> get jsonHandler =>
      CallHierarchyIncomingCallsParams.jsonHandler;

  /// Fetches incoming calls from a [call_hierarchy.DartCallHierarchyComputer].
  ///
  /// This method is invoked by the superclass which handles similar logic for
  /// both incoming and outgoing calls.
  @override
  Future<List<call_hierarchy.CallHierarchyCalls>> getCalls(
    call_hierarchy.DartCallHierarchyComputer computer,
    call_hierarchy.CallHierarchyItem target,
  ) =>
      computer.findIncomingCalls(target, server.searchEngine);

  /// Handles the request by passing the target item to a shared implementation
  /// in the superclass.
  @override
  Future<ErrorOr<CallHierarchyIncomingCallsResult>> handle(
          CallHierarchyIncomingCallsParams params,
          MessageInfo message,
          CancellationToken token) =>
      handleCalls(params.item);

  /// Converts a server [call_hierarchy.CallHierarchyCalls] into the correct LSP
  /// type for incoming calls.
  @override
  CallHierarchyIncomingCall toCall(
    call_hierarchy.CallHierarchyCalls calls, {
    required LineInfo localLineInfo,
    required LineInfo itemLineInfo,
    required Set<SymbolKind> supportedSymbolKinds,
  }) {
    return CallHierarchyIncomingCall(
      from: toLspItem(
        calls.item,
        itemLineInfo,
        supportedSymbolKinds: supportedSymbolKinds,
      ),
      fromRanges: calls.ranges
          // For incoming calls, ranges are in the referenced item so we use
          // itemLineInfo and not localLineInfo (which is for the original
          // target we're collecting calls to).
          .map((call) => sourceRangeToRange(itemLineInfo, call))
          .toList(),
    );
  }
}

/// A handler for `callHierarchy/outgoing` that returns the outgoing calls for
/// the target supplied by the client.
class OutgoingCallHierarchyHandler extends _AbstractCallHierarchyCallsHandler<
    CallHierarchyOutgoingCallsParams,
    CallHierarchyOutgoingCallsResult,
    CallHierarchyOutgoingCall> with _CallHierarchyUtils {
  OutgoingCallHierarchyHandler(super.server);
  @override
  Method get handlesMessage => Method.callHierarchy_outgoingCalls;

  @override
  LspJsonHandler<CallHierarchyOutgoingCallsParams> get jsonHandler =>
      CallHierarchyOutgoingCallsParams.jsonHandler;

  /// Fetches outgoing calls from a [call_hierarchy.DartCallHierarchyComputer].
  ///
  /// This method is invoked by the superclass which handles similar logic for
  /// both incoming and outgoing calls.
  @override
  Future<List<call_hierarchy.CallHierarchyCalls>> getCalls(
    call_hierarchy.DartCallHierarchyComputer computer,
    call_hierarchy.CallHierarchyItem target,
  ) =>
      computer.findOutgoingCalls(target);

  /// Handles the request by passing the target item to a shared implementation
  /// in the superclass.
  @override
  Future<ErrorOr<CallHierarchyOutgoingCallsResult>> handle(
          CallHierarchyOutgoingCallsParams params,
          MessageInfo message,
          CancellationToken token) =>
      handleCalls(params.item);

  /// Converts a server [call_hierarchy.CallHierarchyCalls] into the correct LSP
  /// type for outgoing calls.
  @override
  CallHierarchyOutgoingCall toCall(
    call_hierarchy.CallHierarchyCalls calls, {
    required LineInfo localLineInfo,
    required LineInfo itemLineInfo,
    required Set<SymbolKind> supportedSymbolKinds,
  }) {
    return CallHierarchyOutgoingCall(
      to: toLspItem(
        calls.item,
        itemLineInfo,
        supportedSymbolKinds: supportedSymbolKinds,
      ),
      fromRanges: calls.ranges
          // For incoming calls, ranges are in original target so we use
          // localLineInfo and not itemLineInfo (which is for call target
          // the outbound call points to).
          .map((call) => sourceRangeToRange(localLineInfo, call))
          .toList(),
    );
  }
}

/// A handler for the initial "prepare" request for starting navigation with
/// Call Hierarchy.
///
/// This handler returns the initial target based on the offset where the
/// feature is invoked. Invocations at call sites will resolve to the respective
/// declarations.
///
/// The target returned by this handler will be sent back to the server for
/// incoming/outgoing calls as the user navigates the call hierarchy in the
/// client.
class PrepareCallHierarchyHandler extends SharedMessageHandler<
    CallHierarchyPrepareParams,
    TextDocumentPrepareCallHierarchyResult> with _CallHierarchyUtils {
  PrepareCallHierarchyHandler(super.server);
  @override
  Method get handlesMessage => Method.textDocument_prepareCallHierarchy;

  @override
  LspJsonHandler<CallHierarchyPrepareParams> get jsonHandler =>
      CallHierarchyPrepareParams.jsonHandler;

  @override
  Future<ErrorOr<TextDocumentPrepareCallHierarchyResult>> handle(
      CallHierarchyPrepareParams params,
      MessageInfo message,
      CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(const []);
    }

    final clientCapabilities = server.lspClientCapabilities;
    if (clientCapabilities == null) {
      // This should not happen unless a client misbehaves.
      return serverNotInitializedError;
    }

    final pos = params.position;
    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireResolvedUnit);
    final offset = await unit.mapResult((unit) => toOffset(unit.lineInfo, pos));
    return offset.mapResult((offset) {
      final supportedSymbolKinds = clientCapabilities.documentSymbolKinds;
      final computer = call_hierarchy.DartCallHierarchyComputer(unit.result);
      final target = computer.findTarget(offset);
      if (target == null) {
        return success(null);
      }

      return _convertTarget(
        unit.result.session,
        target,
        supportedSymbolKinds,
      );
    });
  }

  /// Converts a server [call_hierarchy.CallHierarchyItem] to the LSP protocol
  /// equivalent.
  Future<ErrorOr<TextDocumentPrepareCallHierarchyResult>> _convertTarget(
    AnalysisSession session,
    call_hierarchy.CallHierarchyItem target,
    Set<SymbolKind> supportedSymbolKinds,
  ) async {
    // Since the target might be in a different file (for example if invoked at
    // a call site), we need to get a consistent LineInfo for the target file
    // for this session.
    final targetFile = session.getFile(target.file);
    if (targetFile is! FileResult) {
      return error(
        ErrorCodes.InternalError,
        'Call Hierarchy target was in an unavailable file: '
        '${target.displayName} in ${target.file}',
      );
    }
    final targetLineInfo = targetFile.lineInfo;

    final item = toLspItem(
      target,
      targetLineInfo,
      supportedSymbolKinds: supportedSymbolKinds,
    );
    return success([item]);
  }
}

/// An abstract base class for incoming and outgoing CallHierarchy handlers
/// which perform largely the same task using different LSP classes.
abstract class _AbstractCallHierarchyCallsHandler<P, R, C>
    extends SharedMessageHandler<P, R> with _CallHierarchyUtils {
  _AbstractCallHierarchyCallsHandler(super.server);

  /// Gets the appropriate types of calls for this handler.
  Future<List<call_hierarchy.CallHierarchyCalls>> getCalls(
      call_hierarchy.DartCallHierarchyComputer computer,
      call_hierarchy.CallHierarchyItem target);

  /// Handles a request for incoming or outgoing calls (handled by the concrete
  /// implementation) by delegating fetching and converting calls to the
  /// subclass.
  Future<ErrorOr<List<C>?>> handleCalls(CallHierarchyItem item) async {
    if (!isDartUri(item.uri)) {
      return success(const []);
    }

    final clientCapabilities = server.lspClientCapabilities;
    if (clientCapabilities == null) {
      // This should not happen unless a client misbehaves.
      return failure(serverNotInitializedError);
    }

    final path = pathOfUri(item.uri);
    final unit = await path.mapResult(requireResolvedUnit);
    final supportedSymbolKinds = clientCapabilities.documentSymbolKinds;
    final computer = call_hierarchy.DartCallHierarchyComputer(unit.result);

    // Convert the clients item back to one in the servers format so that we
    // can use it to get incoming/outgoing calls.
    final target = toServerItem(
      item,
      unit.result.lineInfo,
      supportedSymbolKinds: supportedSymbolKinds,
    );

    if (target == null) {
      return error(
        ErrorCodes.ContentModified,
        'Content was modified since Call Hierarchy node was produced',
      );
    }

    final calls = await getCalls(computer, target);
    final results = _convertCalls(
      unit.result,
      calls,
      supportedSymbolKinds,
    );
    return success(results);
  }

  /// Converts a server [call_hierarchy.CallHierarchyCalls] to the appropriate
  /// LSP type [C].
  C toCall(
    call_hierarchy.CallHierarchyCalls calls, {
    required LineInfo localLineInfo,
    required LineInfo itemLineInfo,
    required Set<SymbolKind> supportedSymbolKinds,
  });

  C? _convertCall(
    AnalysisSession session,
    LineInfo localLineInfo,
    Map<String, LineInfo?> lineInfoCache,
    call_hierarchy.CallHierarchyCalls calls,
    Set<SymbolKind> supportedSymbolKinds,
  ) {
    final filePath = calls.item.file;
    final itemLineInfo = lineInfoCache.putIfAbsent(filePath, () {
      final file = session.getFile(filePath);
      return file is FileResult ? file.lineInfo : null;
    });
    if (itemLineInfo == null) {
      return null;
    }

    return toCall(
      calls,
      localLineInfo: localLineInfo,
      itemLineInfo: itemLineInfo,
      supportedSymbolKinds: supportedSymbolKinds,
    );
  }

  List<C> _convertCalls(
    ResolvedUnitResult unit,
    List<call_hierarchy.CallHierarchyCalls> calls,
    Set<SymbolKind> supportedSymbolKinds,
  ) {
    final session = unit.session;
    final lineInfoCache = <String, LineInfo?>{};
    final results = convert(
      calls,
      (call_hierarchy.CallHierarchyCalls call) => _convertCall(
        session,
        unit.lineInfo,
        lineInfoCache,
        call,
        supportedSymbolKinds,
      ),
    );
    return results.toList();
  }
}

/// Utility methods used by all Call Hierarchy handlers.
mixin _CallHierarchyUtils on HandlerHelperMixin<AnalysisServer> {
  /// A mapping from server kinds to LSP [SymbolKind]s.
  static const toSymbolKindMapping = {
    call_hierarchy.CallHierarchyKind.class_: SymbolKind.Class,
    call_hierarchy.CallHierarchyKind.constructor: SymbolKind.Constructor,
    call_hierarchy.CallHierarchyKind.extension: SymbolKind.Class,
    call_hierarchy.CallHierarchyKind.file: SymbolKind.File,
    call_hierarchy.CallHierarchyKind.function: SymbolKind.Function,
    call_hierarchy.CallHierarchyKind.method: SymbolKind.Method,
    call_hierarchy.CallHierarchyKind.mixin: SymbolKind.Class,
    call_hierarchy.CallHierarchyKind.property: SymbolKind.Property,
  };

  /// A mapping from LSP [SymbolKind]s to server kinds.
  static final fromSymbolKindMapping = {
    for (final entry in toSymbolKindMapping.entries) entry.value: entry.key,
  };

  /// Converts a [SymbolKind] passed back from the client over LSP to a server
  /// [call_hierarchy.CallHierarchyKind].
  call_hierarchy.CallHierarchyKind fromSymbolKind(SymbolKind kind) {
    var result = fromSymbolKindMapping[kind];
    assert(result != null);

    return result ?? call_hierarchy.CallHierarchyKind.unknown;
  }

  /// Converts a server [SourceRange] to an LSP [Range].
  Range sourceRangeToRange(LineInfo lineInfo, SourceRange range) =>
      toRange(lineInfo, range.offset, range.length);

  /// Converts a server [call_hierarchy.CallHierarchyItem] to an LSP
  /// [CallHierarchyItem].
  CallHierarchyItem toLspItem(
    call_hierarchy.CallHierarchyItem item,
    LineInfo lineInfo, {
    required Set<SymbolKind> supportedSymbolKinds,
  }) {
    return CallHierarchyItem(
      name: item.displayName,
      detail: item.containerName,
      kind: toSymbolKind(supportedSymbolKinds, item.kind),
      uri: pathContext.toUri(item.file),
      range: sourceRangeToRange(lineInfo, item.codeRange),
      selectionRange: sourceRangeToRange(lineInfo, item.nameRange),
    );
  }

  /// Converts an LSP [CallHierarchyItem] supplied by the client back to a
  /// server [call_hierarchy.CallHierarchyItem] to use to look up calls.
  ///
  /// Returns `null` if the supplied item is no longer valid (for example its
  /// ranges are no longer valid in the current state of the document).
  call_hierarchy.CallHierarchyItem? toServerItem(
    CallHierarchyItem item,
    LineInfo lineInfo, {
    required Set<SymbolKind> supportedSymbolKinds,
  }) {
    final nameRange = toSourceRange(lineInfo, item.selectionRange);
    final codeRange = toSourceRange(lineInfo, item.range);
    if (nameRange.isError || codeRange.isError) {
      return null;
    }

    return call_hierarchy.CallHierarchyItem(
      displayName: item.name,
      containerName: item.detail,
      kind: fromSymbolKind(item.kind),
      file: item.uri.toFilePath(),
      nameRange: nameRange.result,
      codeRange: codeRange.result,
    );
  }

  /// Converts a server [call_hierarchy.CallHierarchyKind] to a [SymbolKind]
  /// used in the LSP Protocol.
  SymbolKind toSymbolKind(Set<SymbolKind> supportedSymbolKinds,
      call_hierarchy.CallHierarchyKind kind) {
    var result = toSymbolKindMapping[kind];
    assert(result != null);

    // Handle fallbacks and not-supported kinds.
    if (!supportedSymbolKinds.contains(result)) {
      if (result == SymbolKind.File) {
        result = SymbolKind.Module;
      } else {
        result = null;
      }
    }

    return result ?? SymbolKind.Obj;
  }
}
