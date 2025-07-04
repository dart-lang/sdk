// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(bkonyi): autogenerate from service_extensions.md

import 'dart:collection';
import 'dart:typed_data';

import 'vm_service.dart' hide Error;

extension DartIOExtension on VmService {
  static bool _factoriesRegistered = false;
  static final Map<String, Version> _isolateVersion = {};

  Future<Version> _version(String isolateId) async {
    Version? version = _isolateVersion[isolateId];
    if (version == null) {
      version = await getDartIOVersion(isolateId);
      _isolateVersion[isolateId] = version;
    }
    return version;
  }

  /// The `getDartIOVersion` RPC returns the available version of the dart:io
  /// service protocol extensions.
  Future<Version> getDartIOVersion(String isolateId) =>
      _callHelper('ext.dart.io.getVersion', isolateId);

  /// Whether socket profiling is available for the given [isolateId].
  Future<bool> isSocketProfilingAvailable(String isolateId) async {
    final Isolate isolate = await getIsolate(isolateId);
    return (isolate.extensionRPCs ?? [])
        .contains('ext.dart.io.getSocketProfile');
  }

  /// The _socketProfilingEnabled_ RPC is used to enable/disable the socket profiler
  /// and query its current state. If `enabled` is provided, the profiler state will
  /// be updated to reflect the value of `enabled`.
  ///
  /// If the state of the socket profiler is changed, a `SocketProfilingStateChange`
  /// event will be sent on the `Extension` stream.
  Future<SocketProfilingState> socketProfilingEnabled(String isolateId,
      [bool? enabled]) async {
    assert(await isSocketProfilingAvailable(isolateId));
    return _callHelper('ext.dart.io.socketProfilingEnabled', isolateId, args: {
      if (enabled != null) 'enabled': enabled,
    });
  }

  /// Removes all statistics associated with prior and current sockets.
  Future<Success> clearSocketProfile(String isolateId) async {
    assert(await isSocketProfilingAvailable(isolateId));
    return _callHelper('ext.dart.io.clearSocketProfile', isolateId);
  }

  /// The `getSocketProfile` RPC is used to retrieve socket statistics collected
  /// by the socket profiler. Only samples collected after the initial
  /// [socketProfilingEnabled] call or the last call to [clearSocketProfile]
  /// will be reported.
  Future<SocketProfile> getSocketProfile(String isolateId) async {
    assert(await isSocketProfilingAvailable(isolateId));
    return _callHelper('ext.dart.io.getSocketProfile', isolateId);
  }

  /// Whether HTTP timeline logging is available for the given [isolateId].
  Future<bool> isHttpTimelineLoggingAvailable(String isolateId) async {
    final Isolate isolate = await getIsolate(isolateId);
    final rpcs = isolate.extensionRPCs ?? [];
    return rpcs.contains('ext.dart.io.httpEnableTimelineLogging');
  }

  /// The `httpEnableTimelineLogging` RPC is used to set and inspect the value of
  /// `HttpClient.enableTimelineLogging`, which determines if HTTP client requests
  /// should be logged to the timeline. If `enabled` is provided, the state of
  /// `HttpClient.enableTimelineLogging` will be updated to the value of `enabled`.
  ///
  /// If the value of `HttpClient.enableTimelineLogging` is changed, a
  /// `HttpTimelineLoggingStateChange` event will be sent on the `Extension` stream.
  Future<HttpTimelineLoggingState> httpEnableTimelineLogging(
    String isolateId, [
    bool? enabled,
  ]) async {
    assert(await isHttpTimelineLoggingAvailable(isolateId));
    final version = await _version(isolateId);
    // Parameter name changed in version 1.4.
    final enableKey =
        ((version.major! == 1 && version.minor! > 3) || version.major! >= 2)
            ? 'enabled'
            : 'enable';
    return _callHelper('ext.dart.io.httpEnableTimelineLogging', isolateId,
        args: {
          if (enabled != null) enableKey: enabled,
        });
  }

  /// Whether HTTP profiling is available for the given [isolateId].
  Future<bool> isHttpProfilingAvailable(String isolateId) async {
    final Isolate isolate = await getIsolate(isolateId);
    return (isolate.extensionRPCs ?? []).contains('ext.dart.io.getHttpProfile');
  }

  /// The `getHttpProfile` RPC is used to retrieve HTTP profiling information
  /// for requests made via `dart:io`'s `HttpClient`.
  ///
  /// The returned [HttpProfile] will only include requests issued after
  /// `httpTimelineLogging` has been enabled or after the last
  /// `clearHttpProfile` invocation.
  ///
  /// If `updatedSince` is provided, only requests started or updated since
  /// the specified time will be reported.
  Future<HttpProfile> getHttpProfile(
    String isolateId, {
    DateTime? updatedSince,
  }) async {
    assert(await isHttpProfilingAvailable(isolateId));
    return _callHelper('ext.dart.io.getHttpProfile', isolateId, args: {
      if (updatedSince != null)
        'updatedSince': updatedSince.microsecondsSinceEpoch,
    });
  }

  /// The `getHttpProfileRequest` RPC is used to retrieve an instance of
  /// [HttpProfileRequest], which includes request and response body data.
  Future<HttpProfileRequest> getHttpProfileRequest(
    String isolateId,
    String id,
  ) async {
    assert(await isHttpProfilingAvailable(isolateId));
    return _callHelper('ext.dart.io.getHttpProfileRequest', isolateId, args: {
      'id': id,
    });
  }

  /// The `clearHttpProfile` RPC is used to clear previously recorded HTTP
  /// requests from the HTTP profiler state. Requests still in-flight after
  /// clearing the profiler state will be ignored by the profiler.
  Future<Success> clearHttpProfile(String isolateId) async {
    assert(await isHttpProfilingAvailable(isolateId));
    return _callHelper(
      'ext.dart.io.clearHttpProfile',
      isolateId,
    );
  }

  /// The `getOpenFiles` RPC is used to retrieve the list of files currently
  /// opened files by `dart:io` from a given isolate.
  Future<OpenFileList> getOpenFiles(String isolateId) => _callHelper(
        'ext.dart.io.getOpenFiles',
        isolateId,
      );

  /// The `getOpenFileById` RPC is used to retrieve information about files
  /// currently opened by `dart:io` from a given isolate.
  Future<OpenFile> getOpenFileById(String isolateId, int id) => _callHelper(
        'ext.dart.io.getOpenFileById',
        isolateId,
        args: {
          'id': id,
        },
      );

  /// The `getSpawnedProcesses` RPC is used to retrieve the list of processed opened
  /// by `dart:io` from a given isolate
  Future<SpawnedProcessList> getSpawnedProcesses(String isolateId) =>
      _callHelper(
        'ext.dart.io.getSpawnedProcesses',
        isolateId,
      );

  /// The `getSpawnedProcessById` RPC is used to retrieve information about a process
  /// spawned by `dart:io` from a given isolate.
  Future<SpawnedProcess> getSpawnedProcessById(String isolateId, int id) =>
      _callHelper(
        'ext.dart.io.getSpawnedProcessById',
        isolateId,
        args: {
          'id': id,
        },
      );

  Future<T> _callHelper<T>(String method, String? isolateId,
      {Map args = const {}}) {
    if (!_factoriesRegistered) {
      _registerFactories();
    }
    return extensionCallHelper(
      this,
      method,
      {
        if (isolateId != null) 'isolateId': isolateId,
        ...args,
      },
    );
  }

  static void _registerFactories() {
    addTypeFactory('OpenFile', OpenFile.parse);
    addTypeFactory('OpenFileList', OpenFileList.parse);
    addTypeFactory('@OpenFile', OpenFileRef.parse);
    addTypeFactory('HttpTimelineLoggingState', HttpTimelineLoggingState.parse);
    addTypeFactory('SpawnedProcess', SpawnedProcess.parse);
    addTypeFactory('SpawnedProcessList', SpawnedProcessList.parse);
    addTypeFactory('@SpawnedProcess', SpawnedProcessRef.parse);
    addTypeFactory('SocketProfile', SocketProfile.parse);
    addTypeFactory('SocketStatistic', SocketStatistic.parse);
    addTypeFactory('SocketProfilingState', SocketProfilingState.parse);
    addTypeFactory('HttpProfile', HttpProfile.parse);
    addTypeFactory('HttpProfileRequest', HttpProfileRequest.parse);
    _factoriesRegistered = true;
  }
}

class SocketStatistic {
  static SocketStatistic? parse(Map<String, dynamic>? json) =>
      json == null ? null : SocketStatistic._fromJson(json);

  /// The unique ID associated with this socket.
  final String id;

  /// The time, in microseconds, that this socket was created.
  final int startTime;

  /// The time, in microseconds, that this socket was closed.
  @optional
  final int? endTime;

  /// The time, in microseconds, that this socket was last read from.
  @optional
  final int? lastReadTime;

  /// The time, in microseconds, that this socket was last written to.
  @optional
  final int? lastWriteTime;

  /// The address of the socket.
  final String address;

  /// The port of the socket.
  final int port;

  /// The type of socket. The value is either `tcp` or `udp`.
  final String socketType;

  /// The number of bytes read from this socket.
  final int readBytes;

  /// The number of bytes written to this socket.
  final int writeBytes;

  SocketStatistic._fromJson(Map<String, dynamic> json)
      : id = json['id'],
        startTime = json['startTime'],
        endTime = json['endTime'],
        lastReadTime = json['lastReadTime'],
        lastWriteTime = json['lastWriteTime'],
        address = json['address'],
        port = json['port'],
        socketType = json['socketType'],
        readBytes = json['readBytes'],
        writeBytes = json['writeBytes'];
}

/// A [SocketProfile] provides information about statistics of sockets.
class SocketProfile extends Response {
  static SocketProfile? parse(Map<String, dynamic>? json) =>
      json == null ? null : SocketProfile._fromJson(json);

  @override
  String get type => 'SocketProfile';

  /// List of socket statistics.
  final List<SocketStatistic> sockets;

  SocketProfile({required this.sockets});

  SocketProfile._fromJson(Map<String, dynamic> json)
      :
        // TODO(bkonyi): make this part of the vm_service.dart library so we can
        // call super._fromJson.
        sockets = List<SocketStatistic>.from(
            createServiceObject(json['sockets'], const ['SocketStatistic'])
                    as List? ??
                []);
}

/// A [Response] containing the enabled state of a service extension.
abstract class _State extends Response {
  _State({required this.enabled}) : _type = 'State';

  // TODO(bkonyi): make this part of the vm_service.dart library so we can
  // call super._fromJson.
  _State._fromJson(Map<String, dynamic> json)
      : enabled = json['enabled'],
        _type = json['type'];

  @override
  String get type => _type;

  final bool enabled;
  final String _type;
}

/// An [HttpTimelineLoggingState] provides information about the current state
/// of HTTP request logging for a given isolate.
class HttpTimelineLoggingState extends _State {
  static HttpTimelineLoggingState? parse(Map<String, dynamic>? json) =>
      json == null ? null : HttpTimelineLoggingState._fromJson(json);

  @override
  String get type => 'HttpTimelineLoggingState';

  HttpTimelineLoggingState({required super.enabled});

  HttpTimelineLoggingState._fromJson(super.json) : super._fromJson();
}

/// A collection of HTTP request data collected by the profiler.
class HttpProfile extends Response {
  static HttpProfile? parse(Map<String, dynamic>? json) =>
      json == null ? null : HttpProfile._fromJson(json);

  HttpProfile._fromJson(Map<String, dynamic> json)
      : timestamp = DateTime.fromMicrosecondsSinceEpoch(json['timestamp']!),
        requests = json['requests']!
            .cast<Map<String, dynamic>>()
            .map((e) => HttpProfileRequest._fromJson(e))
            .cast<HttpProfileRequest>()
            .toList();

  HttpProfile({required this.requests, required this.timestamp});

  @override
  String get type => 'HttpProfile';

  @override
  String toString() => '[HttpProfile]';

  /// The time at which this HTTP profile was built.
  final DateTime timestamp;

  /// The set of recorded HTTP requests.
  final List<HttpProfileRequest> requests;
}

/// Profiling information for a single HTTP request.
class HttpProfileRequestRef {
  static HttpProfileRequestRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : HttpProfileRequestRef._fromJson(json);

  HttpProfileRequestRef._fromJson(Map<String, dynamic> json)
      : isolateId = json['isolateId']!,
        id = json['id']!,
        method = json['method']!,
        uri = Uri.parse(json['uri']!),
        events = json['events']!
            .cast<Map<String, dynamic>>()
            .map((e) => HttpProfileRequestEvent._fromJson(e))
            .cast<HttpProfileRequestEvent>()
            .toList(),
        startTime = DateTime.fromMicrosecondsSinceEpoch(json['startTime']!),
        endTime = json['endTime'] == null
            ? null
            : DateTime.fromMicrosecondsSinceEpoch(json['endTime']),
        request = HttpProfileRequestData.parse(json['request']),
        response = HttpProfileResponseData.parse(json['response']);

  HttpProfileRequestRef({
    required this.isolateId,
    required this.id,
    required this.method,
    required this.uri,
    required this.events,
    required this.startTime,
    this.endTime,
    this.request,
    this.response,
  });

  // The ID of the isolate this request was issued from.
  final String isolateId;

  /// The ID associated with this request.
  ///
  /// If the ID does not start with the prefix 'from_package/', then there
  /// will be a corresponding timeline event with the same ID.
  final String id;

  /// The HTTP request method associated with this request.
  final String method;

  /// The URI to which this HTTP request was sent.
  final Uri uri;

  /// Events related to this HTTP request.
  final List<HttpProfileRequestEvent> events;

  /// The time at which this request was initiated.
  final DateTime startTime;

  /// The time at which this request was completed.
  ///
  /// Will be `null` if the request is still in progress.
  final DateTime? endTime;

  /// Returns `true` if the initial HTTP request has completed.
  bool get isRequestComplete => endTime != null;

  /// Returns `true` if the entirety of the response has been received.
  bool get isResponseComplete => response?.isComplete ?? false;

  /// Details about the request.
  ///
  /// Can be `null` if the request has not yet been completed.
  final HttpProfileRequestData? request;

  /// Details about the response.
  ///
  /// Can be `null` if the request has not yet been responded to.
  final HttpProfileResponseData? response;
}

/// Profiling information for a single HTTP request, including request and
/// response body data.
class HttpProfileRequest extends HttpProfileRequestRef {
  static HttpProfileRequest? parse(Map<String, dynamic>? json) =>
      json == null ? null : HttpProfileRequest._fromJson(json);

  HttpProfileRequest._fromJson(super.json)
      : requestBody =
            Uint8List.fromList(json['requestBody']?.cast<int>() ?? <int>[]),
        responseBody =
            Uint8List.fromList(json['responseBody']?.cast<int>() ?? <int>[]),
        super._fromJson();

  HttpProfileRequest({
    required super.id,
    required super.isolateId,
    required super.method,
    required super.uri,
    required super.events,
    required super.startTime,
    super.endTime,
    super.request,
    super.response,
    this.requestBody,
    this.responseBody,
  });

  /// The body sent as part of this request.
  ///
  /// Data written to a request body before encountering an error will be
  /// reported.
  final Uint8List? requestBody;

  /// The body received in response to the request.
  final Uint8List? responseBody;
}

/// Information sent as part of the initial HTTP request.
class HttpProfileRequestData {
  static HttpProfileRequestData? parse(Map<String, dynamic>? json) =>
      json == null ? null : HttpProfileRequestData._fromJson(json);

  HttpProfileRequestData._fromJson(Map<String, dynamic> json)
      : _headers = UnmodifiableMapView(json['headers'] ?? {}),
        _connectionInfo = UnmodifiableMapView(json['connectionInfo'] ?? {}),
        _contentLength = json['contentLength'],
        _cookies = UnmodifiableListView(json['cookies']?.cast<String>() ?? []),
        _followRedirects = json['followRedirects'] ?? false,
        _maxRedirects = json['maxRedirects'] ?? 0,
        _persistentConnection = json['persistentConnection'] ?? false,
        _proxyDetails = HttpProfileProxyData.parse(json['proxyDetails']),
        error = json['error'];

  HttpProfileRequestData.buildSuccessfulRequest({
    Map<String, dynamic>? headers,
    Map<String, dynamic>? connectionInfo,
    int? contentLength,
    required List<String> cookies,
    bool? followRedirects,
    int? maxRedirects,
    bool? persistentConnection,
    HttpProfileProxyData? proxyDetails,
  })  : _headers = headers,
        _connectionInfo = connectionInfo,
        _contentLength = contentLength,
        _cookies = cookies,
        _followRedirects = followRedirects,
        _maxRedirects = maxRedirects,
        _persistentConnection = persistentConnection,
        _proxyDetails = proxyDetails,
        error = null;

  HttpProfileRequestData.buildErrorRequest({
    required this.error,
  })  : _connectionInfo = null,
        _contentLength = null,
        _cookies = null,
        _followRedirects = null,
        _headers = null,
        _maxRedirects = null,
        _persistentConnection = null,
        _proxyDetails = null;

  /// Returns `true` if an error has occurred while issuing the request.
  ///
  /// If `true`, attempting to access some fields will throw an
  /// [HttpProfileRequestError].
  bool get hasError => error != null;

  /// Information about the client connection.
  ///
  /// Throws [HttpProfileRequestError] if `hasError` is `true`.
  Map<String, dynamic>? get connectionInfo => _returnIfNoError(_connectionInfo);
  final Map<String, dynamic>? _connectionInfo;

  /// The content length of the request, in bytes.
  ///
  /// Throws [HttpProfileRequestError] if `hasError` is `true`.
  int? get contentLength => _returnIfNoError(_contentLength);
  final int? _contentLength;

  /// Cookies presented to the server (in the 'cookie' header).
  ///
  /// Throws [HttpProfileRequestError] if `hasError` is `true`.
  List<String>? get cookies => _returnIfNoError(_cookies);
  final List<String>? _cookies;

  /// The error associated with the failed request.
  final String? error;

  /// Whether automatic redirect following was enabled for the request.
  ///
  /// Throws [HttpProfileRequestError] if `hasError` is `true`.
  bool? get followRedirects => _returnIfNoError(_followRedirects);
  final bool? _followRedirects;

  /// The client request headers.
  ///
  /// Throws [HttpProfileRequestError] if `hasError` is `true`.
  Map<String, dynamic>? get headers => _returnIfNoError(_headers);
  final Map<String, dynamic>? _headers;

  /// The maximum number of redirects allowed during the request.
  ///
  /// Throws [HttpProfileRequestError] if `hasError` is `true`.
  int? get maxRedirects => _returnIfNoError(_maxRedirects);
  final int? _maxRedirects;

  /// The requested persistent connection state.
  ///
  /// Throws [HttpProfileRequestError] if `hasError` is `true`.
  bool? get persistentConnection => _returnIfNoError(_persistentConnection);
  final bool? _persistentConnection;

  /// Proxy authentication details for this request.
  ///
  /// Throws [HttpProfileRequestError] if `hasError` is `true`.
  HttpProfileProxyData? get proxyDetails => _returnIfNoError(_proxyDetails);
  final HttpProfileProxyData? _proxyDetails;

  T? _returnIfNoError<T>(T? field) {
    if (hasError) {
      throw HttpProfileRequestError(error!);
    }
    return field;
  }
}

/// An [Error] thrown when attempting to inspect fields in a
/// [HttpProfileRequestData] instance when `hasError` is `true`.
class HttpProfileRequestError implements Error {
  HttpProfileRequestError(this.error);

  final String error;

  @override
  final StackTrace stackTrace = StackTrace.current;

  @override
  String toString() => 'HttpProfileRequestError: $error.';
}

/// Describes proxy authentication details associated with an
/// [HttpProfileRequest].
class HttpProfileProxyData {
  static HttpProfileProxyData? parse(Map<String, dynamic>? json) =>
      json == null ? null : HttpProfileProxyData._fromJson(json);

  HttpProfileProxyData._fromJson(Map<String, dynamic> json)
      : host = json['host'],
        username = json['username'],
        isDirect = json['isDirect'],
        port = json['port'];

  HttpProfileProxyData({
    this.host,
    this.username,
    this.isDirect,
    this.port,
  });

  /// The URI of the proxy server.
  final String? host;

  /// The username used to authenticate with the proxy server.
  final String? username;

  final bool? isDirect;

  /// The port the proxy server is listening on.
  final int? port;
}

/// Describes an event related to an HTTP request.
class HttpProfileRequestEvent {
  static HttpProfileRequestEvent? parse(Map<String, dynamic>? json) =>
      json == null ? null : HttpProfileRequestEvent._fromJson(json);

  HttpProfileRequestEvent._fromJson(Map<String, dynamic> json)
      : timestamp = DateTime.fromMicrosecondsSinceEpoch(json['timestamp']!),
        event = json['event']!,
        arguments = json['arguments'];

  HttpProfileRequestEvent({
    required this.event,
    required this.timestamp,
    this.arguments,
  });

  /// The title of the recorded event.
  final String event;

  /// The time at which the event occurred.
  final DateTime timestamp;

  final Map<String, dynamic>? arguments;
}

/// Information received in response to an initial HTTP request.
class HttpProfileResponseData {
  static HttpProfileResponseData? parse(Map<String, dynamic>? json) =>
      json == null ? null : HttpProfileResponseData._fromJson(json);

  HttpProfileResponseData._fromJson(Map<String, dynamic> json)
      : startTime = json['startTime'] == null
            ? null
            : DateTime.fromMicrosecondsSinceEpoch(json['startTime']),
        endTime = json['endTime'] == null
            ? null
            : DateTime.fromMicrosecondsSinceEpoch(json['endTime']),
        headers = json['headers'],
        connectionInfo = json['connectionInfo'],
        contentLength = json['contentLength'],
        compressionState = json['compressionState'],
        cookies = UnmodifiableListView(json['cookies']?.cast<String>() ?? []),
        error = json['error'],
        isRedirect = json['isRedirect'],
        persistentConnection = json['persistentConnection'],
        reasonPhrase = json['reasonPhrase'],
        redirects = UnmodifiableListView(
            json['redirects']!.cast<Map<String, dynamic>>()),
        statusCode = json['statusCode'];

  HttpProfileResponseData({
    this.startTime,
    this.endTime,
    this.headers,
    this.compressionState,
    this.connectionInfo,
    this.contentLength,
    this.cookies,
    this.isRedirect,
    this.persistentConnection,
    this.reasonPhrase,
    required this.redirects,
    this.statusCode,
    this.error,
  });

  bool get isComplete => endTime != null;
  bool get hasError => error != null;

  /// The series of redirects this connection has been through.
  ///
  /// The list will be empty if no redirects were followed. Redirects will be
  /// updated both in the case of an automatic and a manual redirect.
  final List<Map<String, dynamic>> redirects;

  /// Cookies set by the server (from the 'set-cookie' header).
  final List<String>? cookies;

  /// Information about the client connection.
  final Map<String, dynamic>? connectionInfo;

  /// The client response headers.
  final Map<String, dynamic>? headers;

  /// The compression state of the response.
  ///
  /// This specifies whether the response bytes were compressed when they were
  /// received across the wire and whether callers will receive compressed or
  /// uncompressed bytes when they listed to this response's byte stream.
  ///
  /// See [HttpClientResponseCompressionState](https://api.dart.dev/dart-io/HttpClientResponseCompressionState-class.html) for possible values.
  final String? compressionState;

  /// The reason phrase associated with the status code.
  final String? reasonPhrase;

  /// Whether the status code is one of the normal redirect codes.
  final bool? isRedirect;

  /// The persistent connection state returned by the server.
  final bool? persistentConnection;

  /// The content length of the response body, in bytes.
  ///
  /// Returns -1 if the size of the response body is not known in advance.
  final int? contentLength;

  /// The status code.
  final int? statusCode;

  /// The time at which the initial response was received.
  final DateTime? startTime;

  /// The time at which the response was completed.
  ///
  /// Will be `null` if response data is still being received.
  final DateTime? endTime;

  /// The error associated with the failed response.
  final String? error;
}

/// A [SocketProfilingState] provides information about the current state of
/// socket profiling for a given isolate.
class SocketProfilingState extends _State {
  static SocketProfilingState? parse(Map<String, dynamic>? json) =>
      json == null ? null : SocketProfilingState._fromJson(json);

  SocketProfilingState({required super.enabled});

  SocketProfilingState._fromJson(super.json) : super._fromJson();
}

/// A [SpawnedProcessRef] contains identifying information about a spawned
/// process.
class SpawnedProcessRef {
  static SpawnedProcessRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : SpawnedProcessRef._fromJson(json);

  SpawnedProcessRef({
    required this.id,
    required this.name,
  });

  SpawnedProcessRef._fromJson(Map<String, dynamic> json)
      :
        // TODO(bkonyi): make this part of the vm_service.dart library so we can
        // call super._fromJson.
        id = json['id'],
        name = json['name'];

  static const String type = 'SpawnedProcessRef';

  /// The unique ID associated with this process.
  final int id;

  /// The name of the executable.
  final String name;
}

/// A [SpawnedProcess] contains startup information of a spawned process.
class SpawnedProcess extends Response implements SpawnedProcessRef {
  static SpawnedProcess? parse(Map<String, dynamic>? json) =>
      json == null ? null : SpawnedProcess._fromJson(json);

  SpawnedProcess({
    required this.id,
    required this.name,
    required this.pid,
    required this.startedAt,
    required List<String> arguments,
    required this.workingDirectory,
  }) : _arguments = arguments;

  SpawnedProcess._fromJson(Map<String, dynamic> json)
      :
        // TODO(bkonyi): make this part of the vm_service.dart library so we can
        // call super._fromJson.
        id = json['id'],
        name = json['name'],
        pid = json['pid'],
        startedAt = json['startedAt'],
        _arguments = List<String>.from(
            createServiceObject(json['arguments'], const ['String']) as List),
        workingDirectory = json['workingDirectory'];

  @override
  String get type => 'SpawnedProcess';

  /// The unique ID associated with this process.
  @override
  final int id;

  /// The name of the executable.
  @override
  final String name;

  /// The process ID associated with the process.
  final int pid;

  /// The time the process was started in milliseconds since epoch.
  final int startedAt;

  /// The list of arguments provided to the process at launch.
  List<String> get arguments => UnmodifiableListView(_arguments);
  final List<String> _arguments;

  /// The working directory of the process at launch.
  final String workingDirectory;
}

class SpawnedProcessList extends Response {
  static SpawnedProcessList? parse(Map<String, dynamic>? json) =>
      json == null ? null : SpawnedProcessList._fromJson(json);

  SpawnedProcessList({required List<SpawnedProcessRef> processes})
      : _processes = processes;

  SpawnedProcessList._fromJson(Map<String, dynamic> json)
      :
        // TODO(bkonyi): make this part of the vm_service.dart library so we can
        // call super._fromJson.
        _processes = List<SpawnedProcessRef>.from(
            createServiceObject(json['processes'], const ['SpawnedProcessRef'])
                as List);

  @override
  String get type => 'SpawnedProcessList';

  /// A list of processes spawned through dart:io on a given isolate.
  List<SpawnedProcessRef> get processes => UnmodifiableListView(_processes);
  final List<SpawnedProcessRef> _processes;
}

/// An [OpenFileRef] contains identifying information about a currently opened
/// file.
class OpenFileRef {
  static OpenFileRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : OpenFileRef._fromJson(json);

  OpenFileRef({
    required this.id,
    required this.name,
  });

  OpenFileRef._fromJson(Map<String, dynamic> json)
      :
        // TODO(bkonyi): make this part of the vm_service.dart library so we can
        // call super._fromJson.
        id = json['id'],
        name = json['name'];

  static const String type = 'OpenFileRef';

  /// The unique ID associated with this file.
  final int id;

  /// The path of the file.
  final String name;
}

/// Contains information about reads and writes to a currently opened file.
class OpenFile extends Response implements OpenFileRef {
  static OpenFile? parse(Map<String, dynamic>? json) =>
      json == null ? null : OpenFile._fromJson(json);

  OpenFile({
    required this.id,
    required this.name,
    required this.readBytes,
    required this.writeBytes,
    required this.readCount,
    required this.writeCount,
    required this.lastReadTime,
    required this.lastWriteTime,
  });

  OpenFile._fromJson(Map<String, dynamic> json)
      :
        // TODO(bkonyi): make this part of the vm_service.dart library so we can
        // call super._fromJson.
        id = json['id'],
        name = json['name'],
        readBytes = json['readBytes'],
        writeBytes = json['writeBytes'],
        readCount = json['readCount'],
        writeCount = json['writeCount'],
        lastReadTime =
            DateTime.fromMillisecondsSinceEpoch(json['lastReadTime']),
        lastWriteTime =
            DateTime.fromMillisecondsSinceEpoch(json['lastWriteTime']);

  @override
  String get type => 'OpenFile';

  /// The unique ID associated with this file.
  @override
  final int id;

  /// The path of the file.
  @override
  final String name;

  /// The total number of bytes read from this file.
  final int readBytes;

  /// The total number of bytes written to this file.
  final int writeBytes;

  /// The number of reads made from this file.
  final int readCount;

  /// The number of writes made to this file.
  final int writeCount;

  /// The time at which this file was last read by this process.
  final DateTime lastReadTime;

  /// The time at which this file was last written to by this process.
  final DateTime lastWriteTime;
}

class OpenFileList extends Response {
  static OpenFileList? parse(Map<String, dynamic>? json) =>
      json == null ? null : OpenFileList._fromJson(json);

  OpenFileList({required List<OpenFileRef> files}) : _files = files;

  OpenFileList._fromJson(Map<String, dynamic> json)
      :
        // TODO(bkonyi): make this part of the vm_service.dart library so we can
        // call super._fromJson.
        _files = List<OpenFileRef>.from(
            createServiceObject(json['files'], const ['OpenFileRef']) as List);

  @override
  String get type => 'OpenFileList';

  /// A list of all files opened through dart:io on a given isolate.
  List<OpenFileRef> get files => UnmodifiableListView(_files);
  final List<OpenFileRef> _files;
}
