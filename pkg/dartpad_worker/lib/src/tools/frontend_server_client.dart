// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;

import 'package:analyzer/file_system/file_system.dart';
import 'package:async/async.dart';
import 'package:frontend_server/starter.dart';

import '../resource_provider/resource_provider_io_overrides.dart';
import '../util/string_sink_ext.dart';

/// Parsed output frame from a `frontend_server` `compile` or `recompile`
/// command.
typedef FrontendServerOutput = ({
  /// Path to the emitted `.dill`, e.g. `app.dill.incremental.dill`.
  String dillPath,
  int errorCount,

  /// Formatted compiler diagnostics emitted during the compilation.
  String diagnostics,

  /// Source file URIs added (`+<uri>`) since the previous compilation.
  List<Uri> addedSources,

  /// Source file URIs removed (`-<uri>`) since the previous compilation.
  List<Uri> removedSources,
});

/// In-process client for `pkg/frontend_server` driven via [starter] and its
/// standard stdin/stdout boundary-key protocol.
///
/// All `dart:io` file system operations performed by `frontend_server` are
/// redirected to the provided [ResourceProvider] via
/// [runWithResourceProviderIO].
///
/// Lifecycle:
/// 1. Start an incremental compiler session with [FrontendServerClient.start].
/// 2. Run the initial compilation with [compile], then call [accept] on
///    success (or [quit] on fatal failure).
/// 3. Run subsequent incremental compilations with [recompile], calling
///    [accept] when `errorCount == 0` or [reject] when `errorCount > 0`.
/// 4. Terminate the session and release stream resources with [quit].
///
/// The protocol has no request identifiers: each instruction is answered by the
/// next frame written to the output. Hence a client must not have more than one
/// outstanding instruction, and callers must not call the methods below
/// concurrently.
final class FrontendServerClient {
  static final _random = Random();

  final ResourceProvider _resourceProvider;
  final StreamController<List<int>> _input;
  final StreamController<String> _output;
  final StreamQueue<String> _lines;

  /// Completes with an error as soon as `frontend_server` stops, whether it
  /// crashed or exited in response to [quit].
  ///
  /// See [_nextLine] for why this is necessary.
  final Completer<Never> _stopped = Completer();

  late final Future<int> _serverFuture;

  FrontendServerClient._(
    this._resourceProvider,
    this._input,
    this._output,
    this._lines,
  ) {
    // Only read when something is waiting for output, so keep stopping from
    // surfacing as an unhandled asynchronous error.
    _stopped.future.ignore();
  }

  /// Starts `frontend_server` in interactive mode with [args] (which must
  /// include `--incremental` and no positional entrypoint argument),
  /// redirecting `dart:io` access to [resourceProvider].
  static FrontendServerClient start(
    ResourceProvider resourceProvider,
    List<String> args,
  ) => runWithResourceProviderIO(resourceProvider, () {
    final input = StreamController<List<int>>();
    final output = StreamController<String>();
    final client = FrontendServerClient._(
      resourceProvider,
      input,
      output,
      StreamQueue(output.stream.transform(const LineSplitter())),
    );
    // `listenAndCompile` handles instructions in an `async` listener callback
    // with no error handling, so a throw while compiling lands here as an
    // uncaught asynchronous error. The `!` is safe because an `async` body
    // never throws synchronously.
    client._serverFuture = runZonedGuarded(
      () async => await starter(
        args,
        input: input.stream,
        output: output.sink.asStringSink(),
      ),
      client._stop,
    )!;
    // `starter()` only completes its future once it has been sent `quit`; any
    // other completion means the server stopped without answering.
    client._serverFuture.then(
      (exitCode) => client._stop(
        StateError('frontend_server exited with code $exitCode'),
        StackTrace.empty,
      ),
      onError: client._stop,
    );
    return client;
  });

  /// Sends a `compile <entrypoint>` instruction for the initial compilation and
  /// returns the parsed [FrontendServerOutput].
  Future<FrontendServerOutput> compile(String entrypoint) =>
      runWithResourceProviderIO(_resourceProvider, () {
        _send('compile $entrypoint');
        return _readCompileOutput();
      });

  /// Sends a `recompile` (or `recompile-restart` when [restart] is `true`)
  /// instruction with [invalidatedUris] and returns the parsed
  /// [FrontendServerOutput].
  ///
  /// Every entry in [invalidatedUris] should be a full URI with a scheme
  /// (e.g. `file:///...` or `workspace:///...`) so `Uri.base.resolve` inside
  /// `frontend_server` preserves it when running in a Web Worker.
  Future<FrontendServerOutput> recompile(
    String entrypoint,
    List<String> invalidatedUris, {
    required bool restart,
  }) => runWithResourceProviderIO(_resourceProvider, () {
    final instruction = restart ? 'recompile-restart' : 'recompile';
    final boundaryKey = _boundaryKey();
    _send(
      [
        '$instruction $entrypoint $boundaryKey',
        ...invalidatedUris,
        boundaryKey,
      ].join('\n'),
    );
    return _readCompileOutput();
  });

  /// Accepts the last compilation delta (`accept`).
  ///
  /// `frontend_server` writes no output in response; the next instruction is
  /// what orders this against subsequent compilations.
  void accept() =>
      runWithResourceProviderIO(_resourceProvider, () => _send('accept'));

  /// Rejects the last compilation delta (`reject`) and waits for
  /// `frontend_server` to acknowledge and roll back to the last accepted state.
  Future<void> reject() =>
      runWithResourceProviderIO(_resourceProvider, () async {
        _send('reject');
        final boundaryKey = await _readBoundaryKey();
        while (await _nextLine != boundaryKey) {}
      });

  /// Sends `quit` to `frontend_server`, waits for [starter] to exit, and closes
  /// the underlying input/output streams.
  ///
  /// Also used to clean up after a crashed server, in which case there is
  /// nobody left to answer `quit`.
  Future<void> quit() => runWithResourceProviderIO(_resourceProvider, () async {
    if (!_stopped.isCompleted) {
      _send('quit');
      // Racing [_stopped] for the reason given on [_nextLine]: a throw while
      // handling `quit` leaves [_serverFuture] pending forever.
      await Future.any<void>([
        _serverFuture,
        _stopped.future,
      ]).onError((_, _) {});
    }

    await _input.close();
    // Immediate, because a read abandoned by [_nextLine] is still queued: a
    // queued cancel would wait behind it for output that never arrives.
    await _lines.cancel(immediate: true);
    await _output.close();
  });

  void _send(String command) {
    _input.add(utf8.encode('$command\n'));
  }

  /// Signals that `frontend_server` will not write any more output.
  void _stop(Object error, StackTrace stackTrace) {
    if (!_stopped.isCompleted) {
      _stopped.completeError(error, stackTrace);
    }
  }

  /// The next line of output from `frontend_server`, or an error if the server
  /// stopped before writing it.
  ///
  /// Racing [_stopped] is what keeps a crash inside `frontend_server` from
  /// hanging the caller forever: such a crash writes no output _and_ never
  /// completes the future returned by [starter], which only ever completes in
  /// response to `quit`.
  ///
  /// The abandoned read stays queued in [_lines], so a client that has stopped
  /// must be discarded rather than reused.
  Future<String> get _nextLine => Future.any([_lines.next, _stopped.future]);

  /// Reads the `result <boundary-key>` line that opens every output frame.
  Future<String> _readBoundaryKey() async {
    final line = await _nextLine;
    if (!line.startsWith('result ')) {
      throw _protocolError('a `result <boundary-key>` line', line);
    }
    return line.substring('result '.length);
  }

  Future<FrontendServerOutput> _readCompileOutput() async {
    final boundaryKey = await _readBoundaryKey();

    final diagnostics = <String>[];
    while (true) {
      final line = await _nextLine;
      if (line == boundaryKey) break;
      diagnostics.add(line);
    }

    final addedSources = <Uri>[];
    final removedSources = <Uri>[];
    while (true) {
      final line = await _nextLine;
      if (line.startsWith('$boundaryKey ')) {
        // '<boundary-key> <dill-path> <error-count>', where only the error
        // count is guaranteed not to contain spaces.
        final rest = line.substring(boundaryKey.length + 1);
        final splitIndex = rest.lastIndexOf(' ');
        final errorCount = splitIndex < 0
            ? null
            : int.tryParse(rest.substring(splitIndex + 1));
        if (errorCount == null) {
          throw _protocolError(
            'a `<boundary-key> <dill-path> <error-count>` line',
            line,
          );
        }
        return (
          dillPath: rest.substring(0, splitIndex),
          errorCount: errorCount,
          diagnostics: diagnostics.isEmpty ? '' : '${diagnostics.join('\n')}\n',
          addedSources: addedSources,
          removedSources: removedSources,
        );
      } else if (line.startsWith('+')) {
        addedSources.add(Uri.parse(line.substring(1)));
      } else if (line.startsWith('-')) {
        removedSources.add(Uri.parse(line.substring(1)));
      }
    }
  }

  StateError _protocolError(String expected, String line) => StateError(
    'Unexpected frontend_server output, expected $expected, got: "$line"',
  );

  /// A key for framing a `recompile` instruction and the output it produces.
  ///
  /// Only needs to be free of spaces and unlikely to occur in the invalidated
  /// URIs or the diagnostics it delimits.
  static String _boundaryKey() =>
      'dartpad-boundary-${_random.nextInt(1 << 32).toRadixString(16)}';
}
