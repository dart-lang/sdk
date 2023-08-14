// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.crash;

import 'dart:convert' show jsonEncode;

import 'dart:io'
    show ContentType, HttpClient, HttpClientRequest, SocketException, stderr;

import 'problems.dart' show DebugAbort;
import 'uri_offset.dart';

const String defaultServerAddress = "http://127.0.0.1:59410/";

/// Tracks if there has been a crash reported through [reportCrash]. Should be
/// reset between each compilation by calling [resetCrashReporting].
bool hasCrashed = false;

/// Tracks the first source URI that has been read and is used as a fall-back
/// for [reportCrash]. Should be reset between each compilation by calling
/// [resetCrashReporting].
Uri? firstSourceUri;

class Crash {
  final Uri? uri;

  final int? charOffset;

  final Object error;

  final StackTrace? trace;

  bool _hasBeenReported = false;

  Crash(this.uri, this.charOffset, this.error, this.trace);

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    if (uri != null) {
      sb.write("Crash when compiling $uri");
      if (charOffset != null && charOffset != -1) {
        sb.write(" at character offset $charOffset:\n");
      } else {
        sb.write(":\n");
      }
    } else {
      sb.write("Crash when compiling:\n");
    }
    sb.write(error);
    sb.write("\n");
    return sb.toString();
  }
}

void resetCrashReporting() {
  firstSourceUri = null;
  hasCrashed = false;
}

Future<T> reportCrash<T>(error, StackTrace trace,
    [Uri? uri, int? charOffset]) async {
  Future<void> note(String note) async {
    stderr.write(note);
    await stderr.flush();
  }

  if (hasCrashed) return new Future<T>.error(error, trace);
  if (error is Crash) {
    trace = error.trace ?? trace;
    uri = error.uri ?? uri;
    charOffset = error.charOffset ?? charOffset;
    error._hasBeenReported = true;
    error = error.error;
  }
  uri ??= firstSourceUri;
  hasCrashed = true;
  Map<String, dynamic> data = <String, dynamic>{};
  data["type"] = "crash";
  data["client"] = "package:fasta";
  if (uri != null) data["uri"] = "$uri";
  if (charOffset != null) data["offset"] = charOffset;
  data["error"] = safeToString(error);
  data["trace"] = "$trace";
  String json = jsonEncode(data);
  HttpClient client = new HttpClient();
  try {
    Uri serverUri = Uri.parse(defaultServerAddress);
    HttpClientRequest request;
    try {
      request = await client.postUrl(serverUri);
    } on SocketException {
      // Assume the crash logger isn't running.
      client.close(force: true);
      return new Future<T>.error(
          new Crash(uri, charOffset, error, trace).._hasBeenReported = true,
          trace);
    }
    await note("\nSending crash report data");
    request.persistentConnection = false;
    request.bufferOutput = false;
    String? host = request.connectionInfo?.remoteAddress.host;
    int? port = request.connectionInfo?.remotePort;
    await note(" to $host:$port");
    await request
      ..headers.contentType = ContentType.json
      ..write(json);
    await request.close();
    await note(".");
  } catch (e, s) {
    await note("\n${safeToString(e)}\n$s\n");
    await note("\n\n\nFE::ERROR::$json\n\n\n");
  }
  client.close(force: true);
  await note("\n");
  return new Future<T>.error(error, trace);
}

String safeToString(Object object) {
  try {
    return "$object";
  } catch (e) {
    return "Error when converting ${object.runtimeType} to string.";
  }
}

Future<T> withCrashReporting<T>(
    Future<T> Function() action, UriOffset? Function() currentUriOffset) async {
  resetCrashReporting();
  try {
    return await action();
  } on DebugAbort {
    rethrow;
  } catch (e, s) {
    if (e is Crash && e._hasBeenReported) {
      rethrow;
    }
    UriOffset? uriOffset = currentUriOffset();
    return reportCrash(e, s, uriOffset?.uri, uriOffset?.fileOffset);
  }
}
