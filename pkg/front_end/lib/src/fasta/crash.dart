// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.crash;

import 'dart:async' show Future;

import 'dart:convert' show jsonEncode;

import 'dart:io'
    show ContentType, HttpClient, HttpClientRequest, SocketException, stderr;

import 'problems.dart' show DebugAbort;

const String defaultServerAddress = "http://127.0.0.1:59410/";

/// Tracks if there has been a crash reported through [reportCrash]. Should be
/// reset between each compilation by calling [resetCrashReporting].
bool hasCrashed = false;

/// Tracks the first source URI that has been read and is used as a fall-back
/// for [reportCrash]. Should be reset between each compilation by calling
/// [resetCrashReporting].
Uri firstSourceUri;

class Crash {
  final Uri uri;

  final int charOffset;

  final Object error;

  final StackTrace trace;

  Crash(this.uri, this.charOffset, this.error, this.trace);

  String toString() {
    return """
Crash when compiling $uri,
at character offset $charOffset:
$error${trace == null ? '' : '\n$trace'}
""";
  }
}

void resetCrashReporting() {
  firstSourceUri = null;
  hasCrashed = false;
}

Future<T> reportCrash<T>(error, StackTrace trace,
    [Uri uri, int charOffset]) async {
  note(String note) async {
    stderr.write(note);
    await stderr.flush();
  }

  if (hasCrashed) return new Future<T>.error(error, trace);
  if (error is Crash) {
    trace = error.trace ?? trace;
    uri = error.uri ?? uri;
    charOffset = error.charOffset ?? charOffset;
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
          new Crash(uri, charOffset, error, trace), trace);
    }
    if (request != null) {
      await note("\nSending crash report data");
      request.persistentConnection = false;
      request.bufferOutput = false;
      String host = request?.connectionInfo?.remoteAddress?.host;
      int port = request?.connectionInfo?.remotePort;
      await note(" to $host:$port");
      await request
        ..headers.contentType = ContentType.json
        ..write(json);
      await request.close();
      await note(".");
    }
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
    Future<T> Function() action, Uri Function() currentUri) async {
  resetCrashReporting();
  try {
    return await action();
  } on Crash {
    rethrow;
  } on DebugAbort {
    rethrow;
  } catch (e, s) {
    return reportCrash(e, s, currentUri());
  }
}
