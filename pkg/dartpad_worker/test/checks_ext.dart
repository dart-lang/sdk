// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:analyzer/file_system/file_system.dart';
import 'package:async/async.dart';
import 'package:checks/checks.dart';
import 'package:checks/context.dart';
import 'package:dartpad/src/worker_client.dart';
import 'package:dartpad_worker/src/shared.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:vm_service/vm_service.dart';

export 'package:checks/checks.dart';

extension FileChangeEventChecks on Subject<FileChangeEvent> {
  Subject<Uri> get uri => has((e) => e.uri, 'uri');
}

extension UriChecks on Subject<Uri> {
  Subject<String> get path => has((u) => u.path, 'path');
}

extension ResourceChecks on Subject<Resource> {
  void get exists => has((r) => r.exists, 'exists').isTrue;
  void get doesNotExist => has((r) => r.exists, 'exists').isFalse;
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

extension CompiledModuleChecks on Subject<CompiledModule> {
  Subject<String> get moduleName => has((m) => m.moduleName, 'moduleName');
  Subject<String> get code => has((m) => m.code, 'code');
  Subject<List<String>> get libraries => has((m) => m.libraries, 'libraries');
}

extension CompileResultChecks on Subject<CompileResult> {
  Subject<List<CompiledModule>> get modules => has((s) => s.modules, 'modules');

  Subject<String> get log => has((s) => s.log, 'log');

  /// Some bundle contains [pattern].
  void anyModuleContains(Pattern pattern) =>
      modules.any(.it()..code.contains(pattern));

  /// Compilation was successful and logs are empty (indicating no warnings)
  void successEmptyLog() {
    log.isEmpty;
    modules.isNotEmpty;
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

extension VmServiceEventChecks on Subject<Event> {
  Subject<String?> get kind => has((e) => e.kind, 'kind');
  Subject<String?> get service => has((e) => e.service, 'service');
  Subject<String?> get extensionRPC =>
      has((e) => e.extensionRPC, 'extensionRPC');
  Subject<String?> get extensionKind =>
      has((e) => e.extensionKind, 'extensionKind');
  Subject<ExtensionData?> get extensionData =>
      has((e) => e.extensionData, 'extensionData');
  Subject<IsolateRef?> get isolate => has((e) => e.isolate, 'isolate');
  Subject<LogRecord?> get logRecord => has((e) => e.logRecord, 'logRecord');
  Subject<String?> get bytes => has((e) => e.bytes, 'bytes');
  Subject<String> get decodedBytes =>
      has((e) => utf8.decode(base64Decode(e.bytes!)), 'decodedBytes');
}

extension VmServiceExtensionDataChecks on Subject<ExtensionData> {
  Subject<Map<String, dynamic>?> get data => has((d) => d.data, 'data');
}

extension VmServiceIsolateRefChecks on Subject<IsolateRef> {
  Subject<String?> get id => has((i) => i.id, 'id');
  Subject<String?> get name => has((i) => i.name, 'name');
}

extension VmServiceLogRecordChecks on Subject<LogRecord> {
  Subject<InstanceRef?> get message => has((r) => r.message, 'message');
  Subject<InstanceRef?> get loggerName =>
      has((r) => r.loggerName, 'loggerName');
  Subject<int?> get level => has((r) => r.level, 'level');
  Subject<int?> get sequenceNumber =>
      has((r) => r.sequenceNumber, 'sequenceNumber');
  Subject<InstanceRef?> get error => has((r) => r.error, 'error');
  Subject<InstanceRef?> get stackTrace =>
      has((r) => r.stackTrace, 'stackTrace');
}

extension VmServiceInstanceRefChecks on Subject<InstanceRef> {
  Subject<String?> get valueAsString =>
      has((i) => i.valueAsString, 'valueAsString');
}

extension StringCheckExt on Subject<String> {
  /// Expect that the value LIKE-matches [pattern].
  ///
  ///  * `%`, matching zero or more characters
  ///    (not newline, unless [ignoreWhitespace] is `true`).
  ///  * `_`, matches one character.
  ///
  /// When [ignoreWhitespace] is `true` all whitespace and newlines are
  /// collapsed to a single whitespace, this makes it easy to check ordering of
  /// words.
  void like(
    String pattern, {
    bool caseSensitive = true,
    bool ignoreWhitespace = false,
  }) {
    context.expect(() => ['matches LIKE-pattern `$pattern`'], (actual) {
      var value = actual;
      var pat = pattern;
      if (ignoreWhitespace) {
        value = value.replaceAll(RegExp(r'\s+'), ' ').trim();
        pat = pat.replaceAll(RegExp(r'\s+'), ' ').trim();
      }

      final p = RegExp.escape(pat).replaceAll('%', '.*').replaceAll('_', '.');
      final re = RegExp('^$p\$', caseSensitive: caseSensitive);

      if (re.hasMatch(value)) {
        return null;
      }
      return Rejection(which: ['Did not match pattern']);
    });
  }
}
