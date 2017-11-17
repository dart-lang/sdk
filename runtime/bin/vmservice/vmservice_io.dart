// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vmservice_io;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:_vmservice';

part 'loader.dart';
part 'server.dart';

// The TCP ip/port that the HTTP server listens on.
int _port;
String _ip;
// Should the HTTP server auto start?
bool _autoStart;
// Should the HTTP server run in devmode?
bool _originCheckDisabled;
bool _isWindows = false;
bool _isFuchsia = false;
var _signalWatch;
var _signalSubscription;

// HTTP server.
Server server;
Future<Server> serverFuture;

_lazyServerBoot() {
  if (server != null) {
    return;
  }
  // Lazily create service.
  var service = new VMService();
  // Lazily create server.
  server = new Server(service, _ip, _port, _originCheckDisabled);
}

Future cleanupCallback() async {
  shutdownLoaders();
  // Cancel the sigquit subscription.
  if (_signalSubscription != null) {
    await _signalSubscription.cancel();
    _signalSubscription = null;
  }
  if (server != null) {
    try {
      await server.cleanup(true);
    } catch (e, st) {
      print("Error in vm-service shutdown: $e\n$st\n");
    }
  }
  if (_registerSignalHandlerTimer != null) {
    _registerSignalHandlerTimer.cancel();
    _registerSignalHandlerTimer = null;
  }
  // Call out to embedder's shutdown callback.
  _shutdown();
}

Future<Uri> createTempDirCallback(String base) async {
  Directory temp = await Directory.systemTemp.createTemp(base);
  // Underneath the temporary directory, create a directory with the
  // same name as the DevFS name [base].
  var fsUri = temp.uri.resolveUri(new Uri.directory(base));
  await new Directory.fromUri(fsUri).create();
  return fsUri;
}

Future deleteDirCallback(Uri path) async {
  Directory dir = new Directory.fromUri(path);
  await dir.delete(recursive: true);
}

class PendingWrite {
  PendingWrite(this.uri, this.bytes);
  final Completer completer = new Completer();
  final Uri uri;
  final List<int> bytes;

  Future write() async {
    var file = new File.fromUri(uri);
    var parent_directory = file.parent;
    await parent_directory.create(recursive: true);
    var result = await file.writeAsBytes(bytes);
    completer.complete(null);
    WriteLimiter._writeCompleted();
  }
}

class WriteLimiter {
  static final List<PendingWrite> pendingWrites = new List<PendingWrite>();

  // non-rooted Android devices have a very low limit for the number of
  // open files. Artificially cap ourselves to 16.
  static const kMaxOpenWrites = 16;
  static int openWrites = 0;

  static Future scheduleWrite(Uri path, List<int> bytes) async {
    // Create a new pending write.
    PendingWrite pw = new PendingWrite(path, bytes);
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

Future writeStreamFileCallback(Uri path, Stream<List<int>> bytes) async {
  var file = new File.fromUri(path);
  var parent_directory = file.parent;
  await parent_directory.create(recursive: true);
  IOSink sink = await file.openWrite();
  await sink.addStream(bytes);
  await sink.close();
}

Future<List<int>> readFileCallback(Uri path) async {
  var file = new File.fromUri(path);
  return await file.readAsBytes();
}

Future<List<Map<String, String>>> listFilesCallback(Uri dirPath) async {
  var dir = new Directory.fromUri(dirPath);
  var dirPathStr = dirPath.path;
  var stream = dir.list(recursive: true);
  var result = <Map<String, String>>[];
  await for (var fileEntity in stream) {
    var filePath = new Uri.file(fileEntity.path).path;
    var stat = await fileEntity.stat();
    if (stat.type == FileSystemEntityType.FILE &&
        filePath.startsWith(dirPathStr)) {
      var map = {};
      map['name'] = '/' + filePath.substring(dirPathStr.length);
      map['size'] = stat.size;
      map['modified'] = stat.modified.millisecondsSinceEpoch;
      result.add(map);
    }
  }
  return result;
}

Future<Uri> serverInformationCallback() async {
  _lazyServerBoot();
  return server.serverAddress;
}

Future<Uri> webServerControlCallback(bool enable) async {
  _lazyServerBoot();
  if (server.running == enable) {
    // No change.
    return server.serverAddress;
  }

  if (enable) {
    await server.startup();
    return server.serverAddress;
  } else {
    await server.shutdown(true);
    return server.serverAddress;
  }
}

_clearFuture(_) {
  serverFuture = null;
}

_onSignal(ProcessSignal signal) {
  if (serverFuture != null) {
    // Still waiting.
    return;
  }
  _lazyServerBoot();
  // Toggle HTTP server.
  if (server.running) {
    serverFuture = server.shutdown(true).then(_clearFuture);
  } else {
    serverFuture = server.startup().then(_clearFuture);
  }
}

Timer _registerSignalHandlerTimer;

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
  _signalSubscription = _signalWatch(ProcessSignal.SIGQUIT).listen(_onSignal);
}

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
  new VMService();
  if (_autoStart) {
    _lazyServerBoot();
    server.startup();
    // It's just here to push an event on the event loop so that we invoke the
    // scheduled microtasks.
    Timer.run(() {});
  }
  scriptLoadPort.handler = _processLoadRequest;
  // Register signal handler after a small delay to avoid stalling main
  // isolate startup.
  _registerSignalHandlerTimer = new Timer(shortDelay, _registerSignalHandler);
  return scriptLoadPort;
}

_shutdown() native "VMServiceIO_Shutdown";
