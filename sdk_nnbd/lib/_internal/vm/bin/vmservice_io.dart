// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vmservice_io;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:_vmservice';

part 'vmservice_server.dart';

// The TCP ip/port that the HTTP server listens on.
@pragma("vm:entry-point")
int _port = 0;
@pragma("vm:entry-point")
String _ip = '';
// Should the HTTP server auto start?
@pragma("vm:entry-point")
bool _autoStart = false;
// Should the HTTP server require an auth code?
@pragma("vm:entry-point")
bool _authCodesDisabled = false;
// Should the HTTP server run in devmode?
@pragma("vm:entry-point")
bool _originCheckDisabled = false;
// Location of file to output VM service connection info.
@pragma("vm:entry-point")
String? _serviceInfoFilename;
@pragma("vm:entry-point")
bool _isWindows = false;
@pragma("vm:entry-point")
bool _isFuchsia = false;
@pragma("vm:entry-point")
var _signalWatch = null;
var _signalSubscription;

// HTTP server.
Server? server;
Future<Server>? serverFuture;

Server _lazyServerBoot() {
  if (server != null) {
    return server!;
  }
  // Lazily create service.
  var service = VMService();
  // Lazily create server.
  final _server = Server(service, _ip, _port, _originCheckDisabled,
      _authCodesDisabled, _serviceInfoFilename);
  server = _server;
  return _server;
}

Future cleanupCallback() async {
  // Cancel the sigquit subscription.
  if (_signalSubscription != null) {
    await _signalSubscription.cancel();
    _signalSubscription = null;
  }
  if (server != null) {
    try {
      await server!.cleanup(true);
    } catch (e, st) {
      print("Error in vm-service shutdown: $e\n$st\n");
    }
  }
  if (_registerSignalHandlerTimer != null) {
    _registerSignalHandlerTimer!.cancel();
    _registerSignalHandlerTimer = null;
  }
  // Call out to embedder's shutdown callback.
  _shutdown();
}

Future<Uri> createTempDirCallback(String base) async {
  Directory temp = await Directory.systemTemp.createTemp(base);
  // Underneath the temporary directory, create a directory with the
  // same name as the DevFS name [base].
  var fsUri = temp.uri.resolveUri(Uri.directory(base));
  await Directory.fromUri(fsUri).create();
  return fsUri;
}

Future deleteDirCallback(Uri path) async {
  Directory dir = Directory.fromUri(path);
  await dir.delete(recursive: true);
}

class PendingWrite {
  PendingWrite(this.uri, this.bytes);
  final Completer completer = Completer();
  final Uri uri;
  final List<int> bytes;

  Future write() async {
    var file = File.fromUri(uri);
    var parent_directory = file.parent;
    await parent_directory.create(recursive: true);
    if (await file.exists()) {
      await file.delete();
    }
    await file.writeAsBytes(bytes);
    completer.complete(null);
    WriteLimiter._writeCompleted();
  }
}

class WriteLimiter {
  static final List<PendingWrite> pendingWrites = <PendingWrite>[];

  // non-rooted Android devices have a very low limit for the number of
  // open files. Artificially cap ourselves to 16.
  static const kMaxOpenWrites = 16;
  static int openWrites = 0;

  static Future scheduleWrite(Uri path, List<int> bytes) async {
    // Create a new pending write.
    PendingWrite pw = PendingWrite(path, bytes);
    pendingWrites.add(pw);
    _maybeWriteFiles();
    return pw.completer.future;
  }

  static _maybeWriteFiles() {
    while (openWrites < kMaxOpenWrites) {
      if (pendingWrites.length > 0) {
        PendingWrite pw = pendingWrites.removeLast();
        pw.write();
        openWrites++;
      } else {
        break;
      }
    }
  }

  static _writeCompleted() {
    openWrites--;
    assert(openWrites >= 0);
    _maybeWriteFiles();
  }
}

Future writeFileCallback(Uri path, List<int> bytes) async {
  return WriteLimiter.scheduleWrite(path, bytes);
}

Future<void> writeStreamFileCallback(Uri path, Stream<List<int>> bytes) async {
  var file = File.fromUri(path);
  var parent_directory = file.parent;
  await parent_directory.create(recursive: true);
  if (await file.exists()) {
    await file.delete();
  }
  IOSink sink = await file.openWrite();
  await sink.addStream(bytes);
  await sink.close();
}

Future<List<int>> readFileCallback(Uri path) async {
  var file = File.fromUri(path);
  return await file.readAsBytes();
}

Future<List<Map<String, dynamic>>> listFilesCallback(Uri dirPath) async {
  var dir = Directory.fromUri(dirPath);
  var dirPathStr = dirPath.path;
  var stream = dir.list(recursive: true);
  var result = <Map<String, dynamic>>[];
  await for (var fileEntity in stream) {
    var filePath = Uri.file(fileEntity.path).path;
    var stat = await fileEntity.stat();
    if (stat.type == FileSystemEntityType.file &&
        filePath.startsWith(dirPathStr)) {
      var map = <String, dynamic>{};
      map['name'] = '/' + filePath.substring(dirPathStr.length);
      map['size'] = stat.size;
      map['modified'] = stat.modified.millisecondsSinceEpoch;
      result.add(map);
    }
  }
  return result;
}

Future<Uri> serverInformationCallback() async =>
    await _lazyServerBoot().serverAddress!;

Future<Uri> webServerControlCallback(bool enable) async {
  final _server = _lazyServerBoot();
  if (_server.running != enable) {
    if (enable) {
      await _server.startup();
    } else {
      await _server.shutdown(true);
    }
  }
  return _server.serverAddress!;
}

void _clearFuture(_) {
  serverFuture = null;
}

_onSignal(ProcessSignal signal) {
  if (serverFuture != null) {
    // Still waiting.
    return;
  }
  final _server = _lazyServerBoot();
  // Toggle HTTP server.
  if (_server.running) {
    _server.shutdown(true).then(_clearFuture);
  } else {
    _server.startup().then(_clearFuture);
  }
}

Timer? _registerSignalHandlerTimer;

_registerSignalHandler() {
  _registerSignalHandlerTimer = null;
  if (_signalWatch == null) {
    // Cannot register for signals.
    return;
  }
  if (_isWindows || _isFuchsia) {
    // Cannot register for signals on Windows or Fuchsia.
    return;
  }
  _signalSubscription = _signalWatch(ProcessSignal.sigquit).listen(_onSignal);
}

@pragma("vm:entry-point", !const bool.fromEnvironment("dart.vm.product"))
main() {
  // Set embedder hooks.
  VMServiceEmbedderHooks.cleanup = cleanupCallback;
  VMServiceEmbedderHooks.createTempDir = createTempDirCallback;
  VMServiceEmbedderHooks.deleteDir = deleteDirCallback;
  VMServiceEmbedderHooks.writeFile = writeFileCallback;
  VMServiceEmbedderHooks.writeStreamFile = writeStreamFileCallback;
  VMServiceEmbedderHooks.readFile = readFileCallback;
  VMServiceEmbedderHooks.listFiles = listFilesCallback;
  VMServiceEmbedderHooks.serverInformation = serverInformationCallback;
  VMServiceEmbedderHooks.webServerControl = webServerControlCallback;
  // Always instantiate the vmservice object so that the exit message
  // can be delivered and waiting loaders can be cancelled.
  VMService();
  if (_autoStart) {
    final _server = _lazyServerBoot();
    _server.startup();
    // It's just here to push an event on the event loop so that we invoke the
    // scheduled microtasks.
    Timer.run(() {});
  }
  // Register signal handler after a small delay to avoid stalling main
  // isolate startup.
  _registerSignalHandlerTimer = Timer(shortDelay, _registerSignalHandler);
}

_shutdown() native "VMServiceIO_Shutdown";
