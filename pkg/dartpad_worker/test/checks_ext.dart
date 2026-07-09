// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
import 'package:async/async.dart';
import 'package:checks/checks.dart';
import 'package:checks/context.dart';
import 'package:dartpad/src/worker_client.dart';
import 'package:dartpad_worker/src/shared.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as rpc;

export 'package:checks/checks.dart';

extension FileChangeEventChecks on Subject<FileChangeEvent> {
  Subject<Uri> get uri => has((e) => e.uri, 'uri');
}

extension UriChecks on Subject<Uri> {
  Subject<String> get path => has((u) => u.path, 'path');
}

extension ResourceChecks on Subject<Resource> {
  void get exists => has((r) => r.exists, 'exists').isTrue();
  void get doesNotExist => has((r) => r.exists, 'exists').isFalse();
}

extension FolderChecks on Subject<Folder> {
  Subject<File> file(String path) =>
      has((f) => f.getFile(path), 'file ($path)');

  Subject<Folder> folder(String path) =>
      has((f) => f.getFolder(path), 'folder ($path)');
}

extension FileChecks on Subject<File> {
  Subject<String> get contents => has((f) => f.readAsStringSync(), 'contents');
}

extension DartPadExceptionChecks on Subject<DartPadException> {
  Subject<String> get message => has((e) => e.message, 'message');
}

extension CompileResultChecks on Subject<CompileResult> {
  Subject<String?> get code => has((s) => s.code, 'code');

  Subject<String> get log => has((s) => s.log, 'log');

  Subject<List<String>> get compiledLibraryUris =>
      has((s) => s.compiledLibraryUris, 'compiledLibraryUris');

  void codeContains(Pattern pattern) => code.isNotNull().contains(pattern);

  /// Compilation was successful and logs are empty (indicating no warnings)
  void successEmptyLog() {
    log.isEmpty();
    code.isNotNull();
  }
}

extension RpcServerChecks on Subject<rpc.Server> {
  /// Check JSON-RPC 2.0 notifications with a stream queue.
  Subject<StreamQueue<Object?>> withNotificationQueue(String name) =>
      context.nest(() => ['has \'$name\' notification'], (server) {
        final c = StreamController<Object?>.broadcast();
        server.registerMethod(
          name,
          (rpc.Parameters params) => c.add(params.value),
        );
        return Extracted.value(StreamQueue(c.stream));
      });
}
