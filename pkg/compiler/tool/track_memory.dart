// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: avoid_dynamic_calls

/// A script to track the high water-mark of memory usage of an application.
/// To monitor how much memory dart2js is using, run dart2js as follows:
///
///     DART_VM_OPTIONS=--observe dart2js ...
///
/// and run this script immediately after.
library;

import 'dart:math' show max;
import 'dart:io';
import 'dart:async';

import 'dart:convert';

/// Socket to connect to the VM service.
late WebSocket socket;

Future<void> main(List<String> args) async {
  _printHeader();
  _showProgress(0, 0, 0, 0);
  try {
    var port = args.isNotEmpty ? int.parse(args[0]) : 8181;
    socket = await WebSocket.connect('ws://localhost:$port/ws');
    socket.listen(_handleResponse);
    await _resumeMainIsolateIfPaused();
    _streamListen('GC');
    _streamListen('Isolate');
    _streamListen('Debug');
  } catch (e) {
    // TODO(sigmund): add better error messages, maybe option to retry.
    print('\n${_red}error$_none: $e');
    print(
      'usage:\n'
      '  Start a Dart process with the --observe flag (and optionally '
      'the --pause_isolates_on_start flag), then invoke:\n'
      '      dart tool/track_memory.dart [<port>]\n'
      '  by default port is 8181',
    );
  }
}

/// Internal counter for request ids.
int _requestId = 0;
Map<int, Completer<dynamic>> _pendingResponses = {};

/// Subscribe to listen to a vm service data stream.
Future<void> _streamListen(String streamId) =>
    _sendMessage('streamListen', {'streamId': streamId});

/// Tell the vm service to resume a specific isolate.
Future<void> _resumeIsolate(String isolateId) =>
    _sendMessage('resume', {'isolateId': isolateId});

/// Resumes the main isolate if it was paused on start.
Future<void> _resumeMainIsolateIfPaused() async {
  var vm = await _sendMessage('getVM');
  var isolateId = vm['isolates'][0]['id'];
  var isolate = await _sendMessage('getIsolate', {'isolateId': isolateId});
  bool isPaused = isolate['pauseEvent']['kind'] == 'PauseStart';
  if (isPaused) _resumeIsolate(isolateId);
}

/// Send a message to the vm service.
Future<dynamic> _sendMessage(
  String method, [
  Map<String, dynamic> args = const {},
]) {
  var id = _requestId++;
  final completer = Completer<dynamic>();
  _pendingResponses[id] = completer;
  socket.add(
    jsonEncode({
      'jsonrpc': '2.0',
      'id': '$id',
      'method': method,
      'params': args,
    }),
  );
  return completer.future;
}

/// Handle all responses
void _handleResponse(Object? s) {
  var json = jsonDecode(s as String);
  if (json['method'] != 'streamNotify') {
    var id = json['id'];
    if (id is String) id = int.parse(id);
    if (id == null || !_pendingResponses.containsKey(id)) return;
    _pendingResponses.remove(id)!.complete(json['result']);
    return;
  }

  // isolate pauses on exit automatically. We detect this to stop and exit.
  if (json['params']['streamId'] == 'Debug') {
    _handleDebug(json);
  } else if (json['params']['streamId'] == 'Isolate') {
    _handleIsolate(json);
  } else if (json['params']['streamId'] == 'GC') {
    _handleGC(json);
  }
}

/// Handle a `Debug` notification.
void _handleDebug(Map<String, dynamic> json) {
  var isolateId = json['params']['event']['isolate']['id'];
  if (json['params']['event']['kind'] == 'PauseStart') {
    _resumeIsolate(isolateId);
  }
  if (json['params']['event']['kind'] == 'PauseExit') {
    _resumeIsolate(isolateId);
  }
}

/// Handle a `Isolate` notification.
void _handleIsolate(Map<String, dynamic> json) {
  if (json['params']['event']['kind'] == 'IsolateExit') {
    print('');
    socket.close();
  }
}

/// Handle a `GC` notification.
void _handleGC(Map<String, dynamic> json) {
  // print(new JsonEncoder.withIndent(' ').convert(json));
  var event = json['params']['event'];
  var newUsed = event['new']['used'];
  var newCapacity = event['new']['capacity'];
  var oldUsed = event['old']['used'];
  var oldCapacity = event['old']['capacity'];
  _showProgress(newUsed, newCapacity, oldUsed, oldCapacity);
}

int lastNewUsed = 0;
int lastOldUsed = 0;
int lastMaxUsed = 0;
int lastNewCapacity = 0;
int lastOldCapacity = 0;
int lastMaxCapacity = 0;

/// Shows a status line with use/capacity numbers for new/old/total/max,
/// highlighting in red when capacity increases, and in green when it decreases.
void _showProgress(int newUsed, int newCapacity, int oldUsed, int oldCapacity) {
  var sb = StringBuffer();
  sb.write('\r '); // replace the status-line in place
  _writeNumber(sb, lastNewUsed, newUsed);
  _writeNumber(sb, lastNewCapacity, newCapacity, color: true);

  sb.write(' | ');
  _writeNumber(sb, lastOldUsed, oldUsed);
  _writeNumber(sb, lastOldCapacity, oldCapacity, color: true);

  sb.write(' | ');
  _writeNumber(sb, lastNewUsed + lastOldUsed, newUsed + oldUsed);
  _writeNumber(
    sb,
    lastNewCapacity + lastOldCapacity,
    newCapacity + oldCapacity,
    color: true,
  );

  sb.write(' | ');
  int maxUsed = max(lastMaxUsed, newUsed + oldUsed);
  int maxCapacity = max(lastMaxCapacity, newCapacity + oldCapacity);
  _writeNumber(sb, lastMaxUsed, maxUsed);
  _writeNumber(sb, lastMaxCapacity, maxCapacity, color: true);
  stdout.write('$sb');

  lastNewUsed = newUsed;
  lastOldUsed = oldUsed;
  lastMaxUsed = maxUsed;
  lastNewCapacity = newCapacity;
  lastOldCapacity = oldCapacity;
  lastMaxCapacity = maxCapacity;
}

const mega = 1024 * 1024;
bool _writeNumber(StringBuffer sb, int before, int now, {bool color = false}) {
  if (color) {
    sb.write(
      before < now
          ? _red
          : before > now
          ? _green
          : '',
    );
  }
  String string;
  if (now < 1024) {
    string = ' ${now}b';
  } else if (now < mega) {
    string = ' ${(now / 1024).toStringAsFixed(0)}K';
  } else {
    string = ' ${(now / mega).toStringAsFixed(1)}M';
  }
  if (string.length < 10) string = '${' ' * (8 - string.length)}$string';
  sb.write(string);
  if (color) sb.write(before != now ? _none : '');
  return before > now;
}

void _printHeader() {
  print('''
Memory usage:
 new generation   | old generation   | total            | max
  in-use/capacity |  in-use/capacity |  in-use/capacity |  in-use/capacity ''');
}

const _red = '\x1b[31m';
const _green = '\x1b[32m';
const _none = '\x1b[0m';
