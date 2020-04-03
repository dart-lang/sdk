// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Library for spawning cquery process and communicating with it.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

/// Helper class encapsulating communication with the cquery process.
///
/// cquery communicates using jsonrpc via stdin/stdout streams.
class CqueryDriver {
  final Process _cquery;

  final _pendingRequests = <int, Completer<dynamic>>{};
  var _requestId = 1;

  final _progressStreamController = StreamController<int>.broadcast();

  CqueryDriver._(this._cquery) {
    _cquery.stdout
        .transform(utf8.decoder)
        .transform(_JsonRpcParser.transformer)
        .listen(_handleMessage);
    _cquery.stderr
        .transform(utf8.decoder)
        .listen((data) => print('stderr: ${data}'));
  }

  static Future<CqueryDriver> start(String cqueryBinary) async {
    final cquery = await Process.start(cqueryBinary, ['--language-server']);
    return CqueryDriver._(cquery);
  }

  /// Stream of progress notifications from cquery. Indicate how many files
  /// are currently pending indexing.
  Stream<int> get progress => _progressStreamController.stream;

  Future<int> get exitCode => _cquery.exitCode;

  /// Send the given message to the cquery process.
  void _sendMessage(Map<String, dynamic> data) {
    data['jsonrpc'] = '2.0';

    final rq = jsonEncode(data);
    _cquery.stdin.write('Content-Length: ${rq.length}\r\n\r\n${rq}');
  }

  /// Send a notification message to the cquery process.
  void notify(String method, {Map<String, dynamic> params}) {
    final rq = <String, dynamic>{'method': method};
    if (params != null) rq['params'] = params;
    _sendMessage(rq);
  }

  /// Send a request message to the cquery process.
  Future<dynamic> request(String method, {Map<String, dynamic> params}) {
    final rq = <String, dynamic>{'method': method, 'id': _requestId++};
    _pendingRequests[rq['id']] = Completer();
    if (params != null) rq['params'] = params;
    _sendMessage(rq);
    return _pendingRequests[rq['id']].future;
  }

  /// Handle message received from cquery process.
  void _handleMessage(Map<String, dynamic> data) {
    final method = data['method'];

    // If it is a progress notification issue progress event.
    if (method == r'$cquery/progress') {
      _progressStreamController.add(data['params']['indexRequestCount']);
    }

    // Otherwise check if it is a response to one of our requests and complete
    // corresponding future if it is.
    if (data.containsKey('id') && data.containsKey('result')) {
      final id = data['id'];
      final result = data['result'];
      _pendingRequests[id].complete(result);
      _pendingRequests[id] = null;
      return;
    }
  }
}

/// Simple parser for jsonrpc protocol over arbitrary chunked stream.
class _JsonRpcParser {
  /// Accumulator for the message content.
  final StringBuffer content = StringBuffer();

  /// Number of bytes left to read in the current message.
  int pendingContentLength = 0;

  /// Auxiliary variable to store various state between invocations of
  /// [state] callback.
  int index = 0;

  /// Position inside incomming chunk of data.
  int pos = 0;

  /// Current parser state.
  Function state = _JsonRpcParser.readHeader;

  /// Callback to invoke when we finish parsing complete message.
  void Function(Map<String, dynamic>) onMessage;

  _JsonRpcParser({this.onMessage});

  /// StreamTransformer wrapping _JsonRpcParser.
  static StreamTransformer<String, Map<String, dynamic>> get transformer =>
      StreamTransformer.fromBind((Stream<String> s) {
        final output = StreamController<Map<String, dynamic>>();
        final p = _JsonRpcParser(onMessage: output.add);
        s.listen(p.addChunk);
        return output.stream;
      });

  /// Parse the chunk of data.
  void addChunk(String data) {
    pos = 0;
    while (pos < data.length) {
      state = state(this, data);
    }
  }

  /// Parsing state: waiting for 'Content-Length' header.
  static Function readHeader(_JsonRpcParser p, String data) {
    final codeUnit = data.codeUnitAt(p.pos++);

    if (HEADER.codeUnitAt(p.index) != codeUnit) {
      throw 'Unexpected codeUnit: ${String.fromCharCode(codeUnit)} expected ${HEADER[p.index]}';
    }

    p.index++;
    if (p.index == HEADER.length) {
      p.index = 0;
      return _JsonRpcParser.readLength;
    }
    return _JsonRpcParser.readHeader;
  }

  /// Parsing state: parsing content length value.
  static Function readLength(_JsonRpcParser p, String data) {
    final codeUnit = data.codeUnitAt(p.pos++);

    if (codeUnit == CR) {
      p.pendingContentLength = p.index;
      p.index = 0;
      return _JsonRpcParser.readHeaderEnd;
    }
    if (codeUnit < CH0 || codeUnit > CH9) {
      throw 'Unexpected codeUnit: ${String.fromCharCode(codeUnit)} expected 0 to 9';
    }
    p.index = p.index * 10 + (codeUnit - CH0);
    return _JsonRpcParser.readLength;
  }

  /// Parsing state: content length was read, skipping line breaks before
  /// content start.
  static Function readHeaderEnd(_JsonRpcParser p, String data) {
    final codeUnit = data.codeUnitAt(p.pos++);

    if (HEADER_END.codeUnitAt(p.index) != codeUnit) {
      throw 'Unexpected codeUnit: ${String.fromCharCode(codeUnit)} expected ${HEADER_END[p.index]}';
    }

    p.index++;
    if (p.index == HEADER_END.length) {
      return _JsonRpcParser.readContent;
    }
    return _JsonRpcParser.readHeaderEnd;
  }

  /// Parsing state: reading message content.
  static Function readContent(_JsonRpcParser p, String data) {
    final availableBytes = data.length - p.pos;
    final bytesToRead = math.min(availableBytes, p.pendingContentLength);
    p.content.write(data.substring(p.pos, p.pos + bytesToRead));
    p.pendingContentLength -= bytesToRead;
    p.pos += bytesToRead;
    if (p.pendingContentLength == 0) {
      p.onMessage(jsonDecode(p.content.toString()));
      p.content.clear();
      p.index = 0;
      return _JsonRpcParser.readHeader;
    } else {
      return _JsonRpcParser.readContent;
    }
  }

  static const HEADER = 'Content-Length: ';
  static const HEADER_END = '\n\r\n';
  static const CH0 = 48;
  static const CH9 = 57;
  static const CR = 13;
  static const LF = 10;
}
