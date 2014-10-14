// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.request;

import 'dart:async';

import 'package:http_parser/http_parser.dart';

import 'hijack_exception.dart';
import 'message.dart';
import 'util.dart';

/// A callback provided by a Shelf handler that's passed to [Request.hijack].
typedef void HijackCallback(
    Stream<List<int>> stream, StreamSink<List<int>> sink);

/// A callback provided by a Shelf adapter that's used by [Request.hijack] to
/// provide a [HijackCallback] with a socket.
typedef void OnHijackCallback(HijackCallback callback);

/// Represents an HTTP request to be processed by a Shelf application.
class Request extends Message {
  /// The remainder of the [requestedUri] path and query designating the virtual
  /// "location" of the request's target within the handler.
  ///
  /// [url] may be an empty, if [requestedUri]targets the handler
  /// root and does not have a trailing slash.
  ///
  /// [url] is never null. If it is not empty, it will start with `/`.
  ///
  /// [scriptName] and [url] combine to create a valid path that should
  /// correspond to the [requestedUri] path.
  final Uri url;

  /// The HTTP request method, such as "GET" or "POST".
  final String method;

  /// The initial portion of the [requestedUri] path that corresponds to the
  /// handler.
  ///
  /// [scriptName] allows a handler to know its virtual "location".
  ///
  /// If the handler corresponds to the "root" of a server, it will be an
  /// empty string, otherwise it will start with a `/`
  ///
  /// [scriptName] and [url] combine to create a valid path that should
  /// correspond to the [requestedUri] path.
  final String scriptName;

  /// The HTTP protocol version used in the request, either "1.0" or "1.1".
  final String protocolVersion;

  /// The original [Uri] for the request.
  final Uri requestedUri;

  /// The callback wrapper for hijacking this request.
  ///
  /// This will be `null` if this request can't be hijacked.
  final _OnHijack _onHijack;

  /// Whether this request can be hijacked.
  ///
  /// This will be `false` either if the adapter doesn't support hijacking, or
  /// if the request has already been hijacked.
  bool get canHijack => _onHijack != null && !_onHijack.called;

  /// If this is non-`null` and the requested resource hasn't been modified
  /// since this date and time, the server should return a 304 Not Modified
  /// response.
  ///
  /// This is parsed from the If-Modified-Since header in [headers]. If
  /// [headers] doesn't have an If-Modified-Since header, this will be `null`.
  DateTime get ifModifiedSince {
    if (_ifModifiedSinceCache != null) return _ifModifiedSinceCache;
    if (!headers.containsKey('if-modified-since')) return null;
    _ifModifiedSinceCache = parseHttpDate(headers['if-modified-since']);
    return _ifModifiedSinceCache;
  }
  DateTime _ifModifiedSinceCache;

  /// Creates a new [Request].
  ///
  /// If [url] and [scriptName] are omitted, they are inferred from
  /// [requestedUri].
  ///
  /// Setting one of [url] or [scriptName] and not the other will throw an
  /// [ArgumentError].
  ///
  /// The default value for [protocolVersion] is '1.1'.
  ///
  /// ## `onHijack`
  ///
  /// [onHijack] allows handlers to take control of the underlying socket for
  /// the request. It should be passed by adapters that can provide access to
  /// the bidirectional socket underlying the HTTP connection stream.
  ///
  /// The [onHijack] callback will only be called once per request. It will be
  /// passed another callback which takes a byte stream and a byte sink.
  /// [onHijack] must pass the stream and sink for the connection stream to this
  /// callback, although it may do so asynchronously. Both parameters may be the
  /// same object. If the user closes the sink, the adapter should ensure that
  /// the stream is closed as well.
  ///
  /// If a request is hijacked, the adapter should expect to receive a
  /// [HijackException] from the handler. This is a special exception used to
  /// indicate that hijacking has occurred. The adapter should avoid either
  /// sending a response or notifying the user of an error if a
  /// [HijackException] is caught.
  ///
  /// An adapter can check whether a request was hijacked using [canHijack],
  /// which will be `false` for a hijacked request. The adapter may throw an
  /// error if a [HijackException] is received for a non-hijacked request, or if
  /// no [HijackException] is received for a hijacked request.
  ///
  /// See also [hijack].
  // TODO(kevmoo) finish documenting the rest of the arguments.
  Request(String method, Uri requestedUri, {String protocolVersion,
      Map<String, String> headers, Uri url, String scriptName,
      Stream<List<int>> body, Map<String, Object> context,
      OnHijackCallback onHijack})
        : this._(method, requestedUri, protocolVersion: protocolVersion,
            headers: headers, url: url, scriptName: scriptName,
            body: body, context: context,
            onHijack: onHijack == null ? null : new _OnHijack(onHijack));

  /// This constructor has the same signature as [new Request] except that
  /// accepts [onHijack] as [_OnHijack].
  ///
  /// Any [Request] created by calling [change] will pass [_onHijack] from the
  /// source [Request] to ensure that [hijack] can only be called once, even
  /// from a changed [Request].
  Request._(this.method, Uri requestedUri, {String protocolVersion,
    Map<String, String> headers, Uri url, String scriptName,
    Stream<List<int>> body, Map<String, Object> context,
    _OnHijack onHijack})
      : this.requestedUri = requestedUri,
        this.protocolVersion = protocolVersion == null ?
            '1.1' : protocolVersion,
        this.url = _computeUrl(requestedUri, url, scriptName),
        this.scriptName = _computeScriptName(requestedUri, url, scriptName),
        this._onHijack = onHijack,
        super(body == null ? new Stream.fromIterable([]) : body,
            headers: headers, context: context) {
    if (method.isEmpty) throw new ArgumentError('method cannot be empty.');

    if (!requestedUri.isAbsolute) {
      throw new ArgumentError('requstedUri must be an absolute URI.');
    }

    // TODO(kevmoo) if defined, check that scriptName is a fully-encoded, valid
    // path component
    if (this.scriptName.isNotEmpty && !this.scriptName.startsWith('/')) {
      throw new ArgumentError('scriptName must be empty or start with "/".');
    }

    if (this.scriptName == '/') {
      throw new ArgumentError(
          'scriptName can never be "/". It should be empty instead.');
    }

    if (this.scriptName.endsWith('/')) {
      throw new ArgumentError('scriptName must not end with "/".');
    }

    if (this.url.path.isNotEmpty && !this.url.path.startsWith('/')) {
      throw new ArgumentError('url must be empty or start with "/".');
    }

    if (this.scriptName.isEmpty && this.url.path.isEmpty) {
      throw new ArgumentError('scriptName and url cannot both be empty.');
    }
  }

  /// Creates a new [Request] by copying existing values and applying specified
  /// changes.
  ///
  /// New key-value pairs in [context] and [headers] will be added to the copied
  /// [Request].
  ///
  /// If [context] or [headers] includes a key that already exists, the
  /// key-value pair will replace the corresponding entry in the copied
  /// [Request].
  ///
  /// All other context and header values from the [Request] will be included
  /// in the copied [Request] unchanged.
  ///
  /// If [scriptName] is provided and [url] is not, [scriptName] must be a
  /// prefix of [this.url]. [url] will default to [this.url] with this prefix
  /// removed. Useful for routing middleware that sends requests to an inner
  /// [Handler].
  Request change({Map<String, String> headers, Map<String, Object> context,
    String scriptName, Uri url}) {
    headers = updateMap(this.headers, headers);
    context = updateMap(this.context, context);

    if (scriptName != null && url == null) {
      var path = this.url.path;
      if (path.startsWith(scriptName)) {
        path = path.substring(scriptName.length);
        url = new Uri(path: path, query: this.url.query);
      } else {
        throw new ArgumentError('If scriptName is provided without url, it must'
            ' be a prefix of the existing url path.');
      }
    }

    if (url == null) url = this.url;
    if (scriptName == null) scriptName = this.scriptName;

    return new Request._(this.method, this.requestedUri,
        protocolVersion: this.protocolVersion, headers: headers, url: url,
        scriptName: scriptName, body: this.read(), context: context,
        onHijack: _onHijack);
  }

  /// Takes control of the underlying request socket.
  ///
  /// Synchronously, this throws a [HijackException] that indicates to the
  /// adapter that it shouldn't emit a response itself. Asynchronously,
  /// [callback] is called with a [Stream<List<int>>] and
  /// [StreamSink<List<int>>], respectively, that provide access to the
  /// underlying request socket.
  ///
  /// If the sink is closed, the stream will be closed as well. The stream and
  /// sink may be the same object, as in the case of a `dart:io` `Socket`
  /// object.
  ///
  /// This may only be called when using a Shelf adapter that supports
  /// hijacking, such as the `dart:io` adapter. In addition, a given request may
  /// only be hijacked once. [canHijack] can be used to detect whether this
  /// request can be hijacked.
  void hijack(HijackCallback callback) {
    if (_onHijack == null) {
      throw new StateError("This request can't be hijacked.");
    }

    _onHijack.run(callback);
    throw const HijackException();
  }
}

/// A class containing a callback for [Request.hijack] that also tracks whether
/// the callback has been called.
class _OnHijack {
  /// The callback.
  final OnHijackCallback _callback;

  /// Whether [this] has been called.
  bool called = false;

  _OnHijack(this._callback);

  /// Calls [this].
  ///
  /// Throws a [StateError] if [this] has already been called.
  void run(HijackCallback callback) {
    if (called) throw new StateError("This request has already been hijacked.");
    called = true;
    newFuture(() => _callback(callback));
  }
}

/// Computes `url` from the provided [Request] constructor arguments.
///
/// If [url] and [scriptName] are `null`, infer value from [requestedUrl],
/// otherwise return [url].
///
/// If [url] is provided, but [scriptName] is omitted, throws an
/// [ArgumentError].
Uri _computeUrl(Uri requestedUri, Uri url, String scriptName) {
  if (url == null && scriptName == null) {
    return new Uri(path: requestedUri.path, query: requestedUri.query);
  }

  if (url != null && scriptName != null) {
    if (url.scheme.isNotEmpty) throw new ArgumentError('url must be relative.');
    return url;
  }

  throw new ArgumentError(
      'url and scriptName must both be null or both be set.');
}

/// Computes `scriptName` from the provided [Request] constructor arguments.
///
/// If [url] and [scriptName] are `null` it returns an empty string, otherwise
/// [scriptName] is returned.
///
/// If [script] is provided, but [url] is omitted, throws an
/// [ArgumentError].
String _computeScriptName(Uri requstedUri, Uri url, String scriptName) {
  if (url == null && scriptName == null) {
    return '';
  }

  if (url != null && scriptName != null) {
    return scriptName;
  }

  throw new ArgumentError(
      'url and scriptName must both be null or both be set.');
}
