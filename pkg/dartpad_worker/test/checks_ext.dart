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
  Subject<String> get path => has2('path', (e) => e.path);
}

extension ResourceChecks on Subject<Resource> {
  void get exists => has2('exists', (r) => r.exists).isTrue;
  void get doesNotExist => has2('exists', (r) => r.exists).isFalse;
}

extension FolderChecks on Subject<Folder> {
  Subject<File> file(String path) =>
      has2('file ($path)', (f) => f.getFile(path));

  Subject<Folder> folder(String path) =>
      has2('folder ($path)', (f) => f.getFolder(path));
}

extension FileChecks on Subject<File> {
  Subject<String> get contents => has2('contents', (f) => f.readAsStringSync());
}

extension DartPadExceptionChecks on Subject<DartPadException> {
  Subject<String> get message => has2('message', (e) => e.message);
}

extension CompiledModuleChecks on Subject<CompiledModule> {
  Subject<String> get moduleName => has2('moduleName', (m) => m.moduleName);
  Subject<String> get code => has2('code', (m) => m.code);
  Subject<List<String>> get libraries => has2('libraries', (m) => m.libraries);
}

extension CompileResultChecks on Subject<CompileResult> {
  Subject<List<CompiledModule>> get modules =>
      has2('modules', (s) => s.modules);

  Subject<String> get log => has2('log', (s) => s.log);

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
  Subject<String?> get kind => has2('kind', (e) => e.kind);
  Subject<String?> get service => has2('service', (e) => e.service);
  Subject<String?> get extensionRPC =>
      has2('extensionRPC', (e) => e.extensionRPC);
  Subject<String?> get extensionKind =>
      has2('extensionKind', (e) => e.extensionKind);
  Subject<ExtensionData?> get extensionData =>
      has2('extensionData', (e) => e.extensionData);
  Subject<IsolateRef?> get isolate => has2('isolate', (e) => e.isolate);
  Subject<LogRecord?> get logRecord => has2('logRecord', (e) => e.logRecord);
  Subject<String?> get bytes => has2('bytes', (e) => e.bytes);
  Subject<String> get decodedBytes =>
      has2('decodedBytes', (e) => utf8.decode(base64Decode(e.bytes!)));
}

extension VmServiceExtensionDataChecks on Subject<ExtensionData> {
  Subject<Map<String, dynamic>?> get data => has2('data', (d) => d.data);
}

extension VmServiceIsolateRefChecks on Subject<IsolateRef> {
  Subject<String?> get id => has2('id', (i) => i.id);
  Subject<String?> get name => has2('name', (i) => i.name);
}

extension VmServiceLogRecordChecks on Subject<LogRecord> {
  Subject<InstanceRef?> get message => has2('message', (r) => r.message);
  Subject<InstanceRef?> get loggerName =>
      has2('loggerName', (r) => r.loggerName);
  Subject<int?> get level => has2('level', (r) => r.level);
  Subject<int?> get sequenceNumber =>
      has2('sequenceNumber', (r) => r.sequenceNumber);
  Subject<InstanceRef?> get error => has2('error', (r) => r.error);
  Subject<InstanceRef?> get stackTrace =>
      has2('stackTrace', (r) => r.stackTrace);
}

extension VmServiceInstanceRefChecks on Subject<InstanceRef> {
  Subject<String?> get valueAsString =>
      has2('valueAsString', (i) => i.valueAsString);
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
