// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.errors;

import 'dart:async' show
    Future;

import 'dart:convert' show
    JSON;

import 'dart:io' show
    ContentType,
    HttpClient,
    HttpClientRequest,
    SocketException,
    stderr;

import 'colors.dart' show
    red;

const String defaultServerAddress = "http://127.0.0.1:59410/";

/// Tracks if there has been a crash reported through [reportCrash]. Should be
/// reset between each compilation by calling [resetCrashReporting].
bool hasCrashed = false;

/// Tracks the first source URI that has been read and is used as a fall-back
/// for [reportCrash]. Should be reset between each compilation by calling
/// [resetCrashReporting].
Uri firstSourceUri;

dynamic internalError(Object error) {
  throw error;
}

dynamic inputError(Uri uri, int charOffset, Object error) {
  throw new InputError(uri, charOffset, error);
}

class InputError {
  final Uri uri;

  final int charOffset;

  final Object error;

  InputError(this.uri, int charOffset, this.error)
      : this.charOffset = charOffset ?? -1;

  toString() => "InputError: $error";

  String format() {
    // TODO(ahe): Colors need to be optional. Doesn't work well in Emacs or on
    // Windows.
    String message = red("Error: ${safeToString(error)}");
    if (uri != null) {
      String uri = "${this.uri}";
      String base = "${Uri.base}";
      if (uri.startsWith(base)) {
        uri = uri.substring(base.length);
      }
      String position = charOffset == -1 ? "" : "$charOffset:";
      return "${uri}:$position $message";
    } else {
      return message;
    }
  }
}

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

Future reportCrash(error, StackTrace trace, [Uri uri, int charOffset]) async {
  note(String note) async {
    stderr.write(note);
    await stderr.flush();
  }
  if (hasCrashed) return new Future.error(error, trace);
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
  String json = JSON.encode(data);
  HttpClient client = new HttpClient();
  try {
    Uri uri = Uri.parse(defaultServerAddress);
    HttpClientRequest request;
    try {
      request = await client.postUrl(uri);
    } on SocketException {
      // Assume the crash logger isn't running.
      await client.close(force: true);
      return new Future.error(error, trace);
    }
    if (request != null) {
      await note("\nSending crash report data");
      request.persistentConnection = false;
      request.bufferOutput = false;
      String host = request?.connectionInfo?.remoteAddress?.host;
      int port = request?.connectionInfo?.remotePort;
      await note(" to $host:$port");
      await request
          ..headers.contentType = ContentType.JSON
          ..write(json);
      await request.close();
      await note(".");
    }
  } catch (e, s) {
    await note("\n${safeToString(e)}\n$s\n");
    await note("\n\n\nFE::ERROR::$json\n\n\n");
  }
  await client.close(force: true);
  await note("\n");
  return new Future.error(error, trace);
}

String safeToString(Object object) {
  try {
    return "$object";
  } catch (e) {
    return "Error when converting ${object.runtimeType} to string.";
  }
}
