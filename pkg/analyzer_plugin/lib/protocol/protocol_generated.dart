// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/spec/generate_files".

import 'dart:convert' hide JsonDecoder;

import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart';
import 'package:analyzer_plugin/src/utilities/client_uri_converter.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/// AnalysisErrorFixes
///
/// {
///   "error": AnalysisError
///   "fixes": List<PrioritizedSourceChange>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisErrorFixes implements HasToJson {
  /// The error with which the fixes are associated.
  AnalysisError error;

  /// The fixes associated with the error.
  List<PrioritizedSourceChange> fixes;

  AnalysisErrorFixes(this.error, {List<PrioritizedSourceChange>? fixes})
    : fixes = fixes ?? <PrioritizedSourceChange>[];

  factory AnalysisErrorFixes.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      AnalysisError error;
      if (json.containsKey('error')) {
        error = AnalysisError.fromJson(
          jsonDecoder,
          '$jsonPath.error',
          json['error'],
          clientUriConverter: clientUriConverter,
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'error');
      }
      List<PrioritizedSourceChange> fixes;
      if (json.containsKey('fixes')) {
        fixes = jsonDecoder.decodeList(
          '$jsonPath.fixes',
          json['fixes'],
          (String jsonPath, Object? json) => PrioritizedSourceChange.fromJson(
            jsonDecoder,
            jsonPath,
            json,
            clientUriConverter: clientUriConverter,
          ),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'fixes');
      }
      return AnalysisErrorFixes(error, fixes: fixes);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'AnalysisErrorFixes', json);
    }
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['error'] = error.toJson(clientUriConverter: clientUriConverter);
    result['fixes'] =
        fixes
            .map(
              (PrioritizedSourceChange value) =>
                  value.toJson(clientUriConverter: clientUriConverter),
            )
            .toList();
    return result;
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is AnalysisErrorFixes) {
      return error == other.error &&
          listEqual(
            fixes,
            other.fixes,
            (PrioritizedSourceChange a, PrioritizedSourceChange b) => a == b,
          );
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(error, Object.hashAll(fixes));
}

/// analysis.errors params
///
/// {
///   "file": FilePath
///   "errors": List<AnalysisError>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisErrorsParams implements HasToJson {
  /// The file containing the errors.
  String file;

  /// The errors contained in the file.
  List<AnalysisError> errors;

  AnalysisErrorsParams(this.file, this.errors);

  factory AnalysisErrorsParams.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file =
            clientUriConverter?.fromClientFilePath(
              jsonDecoder.decodeString('$jsonPath.file', json['file']),
            ) ??
            jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      List<AnalysisError> errors;
      if (json.containsKey('errors')) {
        errors = jsonDecoder.decodeList(
          '$jsonPath.errors',
          json['errors'],
          (String jsonPath, Object? json) => AnalysisError.fromJson(
            jsonDecoder,
            jsonPath,
            json,
            clientUriConverter: clientUriConverter,
          ),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'errors');
      }
      return AnalysisErrorsParams(file, errors);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.errors params', json);
    }
  }

  factory AnalysisErrorsParams.fromNotification(
    Notification notification, {
    ClientUriConverter? clientUriConverter,
  }) {
    return AnalysisErrorsParams.fromJson(
      ResponseDecoder(null),
      'params',
      notification.params,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['file'] = clientUriConverter?.toClientFilePath(file) ?? file;
    result['errors'] =
        errors
            .map(
              (AnalysisError value) =>
                  value.toJson(clientUriConverter: clientUriConverter),
            )
            .toList();
    return result;
  }

  Notification toNotification({ClientUriConverter? clientUriConverter}) {
    return Notification(
      'analysis.errors',
      toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is AnalysisErrorsParams) {
      return file == other.file &&
          listEqual(
            errors,
            other.errors,
            (AnalysisError a, AnalysisError b) => a == b,
          );
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(file, Object.hashAll(errors));
}

/// analysis.folding params
///
/// {
///   "file": FilePath
///   "regions": List<FoldingRegion>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisFoldingParams implements HasToJson {
  /// The file containing the folding regions.
  String file;

  /// The folding regions contained in the file.
  List<FoldingRegion> regions;

  AnalysisFoldingParams(this.file, this.regions);

  factory AnalysisFoldingParams.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file =
            clientUriConverter?.fromClientFilePath(
              jsonDecoder.decodeString('$jsonPath.file', json['file']),
            ) ??
            jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      List<FoldingRegion> regions;
      if (json.containsKey('regions')) {
        regions = jsonDecoder.decodeList(
          '$jsonPath.regions',
          json['regions'],
          (String jsonPath, Object? json) => FoldingRegion.fromJson(
            jsonDecoder,
            jsonPath,
            json,
            clientUriConverter: clientUriConverter,
          ),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'regions');
      }
      return AnalysisFoldingParams(file, regions);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.folding params', json);
    }
  }

  factory AnalysisFoldingParams.fromNotification(
    Notification notification, {
    ClientUriConverter? clientUriConverter,
  }) {
    return AnalysisFoldingParams.fromJson(
      ResponseDecoder(null),
      'params',
      notification.params,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['file'] = clientUriConverter?.toClientFilePath(file) ?? file;
    result['regions'] =
        regions
            .map(
              (FoldingRegion value) =>
                  value.toJson(clientUriConverter: clientUriConverter),
            )
            .toList();
    return result;
  }

  Notification toNotification({ClientUriConverter? clientUriConverter}) {
    return Notification(
      'analysis.folding',
      toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is AnalysisFoldingParams) {
      return file == other.file &&
          listEqual(
            regions,
            other.regions,
            (FoldingRegion a, FoldingRegion b) => a == b,
          );
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(file, Object.hashAll(regions));
}

/// analysis.getNavigation params
///
/// {
///   "file": FilePath
///   "offset": int
///   "length": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetNavigationParams implements RequestParams {
  /// The file in which navigation information is being requested.
  String file;

  /// The offset of the region for which navigation information is being
  /// requested.
  int offset;

  /// The length of the region for which navigation information is being
  /// requested.
  int length;

  AnalysisGetNavigationParams(this.file, this.offset, this.length);

  factory AnalysisGetNavigationParams.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file =
            clientUriConverter?.fromClientFilePath(
              jsonDecoder.decodeString('$jsonPath.file', json['file']),
            ) ??
            jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt('$jsonPath.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt('$jsonPath.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      return AnalysisGetNavigationParams(file, offset, length);
    } else {
      throw jsonDecoder.mismatch(
        jsonPath,
        'analysis.getNavigation params',
        json,
      );
    }
  }

  factory AnalysisGetNavigationParams.fromRequest(
    Request request, {
    ClientUriConverter? clientUriConverter,
  }) {
    return AnalysisGetNavigationParams.fromJson(
      RequestDecoder(request),
      'params',
      request.params,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['file'] = clientUriConverter?.toClientFilePath(file) ?? file;
    result['offset'] = offset;
    result['length'] = length;
    return result;
  }

  @override
  Request toRequest(String id, {ClientUriConverter? clientUriConverter}) {
    return Request(
      id,
      'analysis.getNavigation',
      toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is AnalysisGetNavigationParams) {
      return file == other.file &&
          offset == other.offset &&
          length == other.length;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(file, offset, length);
}

/// analysis.getNavigation result
///
/// {
///   "files": List<FilePath>
///   "targets": List<NavigationTarget>
///   "regions": List<NavigationRegion>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetNavigationResult implements ResponseResult {
  /// A list of the paths of files that are referenced by the navigation
  /// targets.
  List<String> files;

  /// A list of the navigation targets that are referenced by the navigation
  /// regions.
  List<NavigationTarget> targets;

  /// A list of the navigation regions within the requested region of the file.
  List<NavigationRegion> regions;

  AnalysisGetNavigationResult(this.files, this.targets, this.regions);

  factory AnalysisGetNavigationResult.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      List<String> files;
      if (json.containsKey('files')) {
        files = jsonDecoder.decodeList(
          '$jsonPath.files',
          json['files'],
          (String jsonPath, Object? json) =>
              clientUriConverter?.fromClientFilePath(
                jsonDecoder.decodeString(jsonPath, json),
              ) ??
              jsonDecoder.decodeString(jsonPath, json),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'files');
      }
      List<NavigationTarget> targets;
      if (json.containsKey('targets')) {
        targets = jsonDecoder.decodeList(
          '$jsonPath.targets',
          json['targets'],
          (String jsonPath, Object? json) => NavigationTarget.fromJson(
            jsonDecoder,
            jsonPath,
            json,
            clientUriConverter: clientUriConverter,
          ),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'targets');
      }
      List<NavigationRegion> regions;
      if (json.containsKey('regions')) {
        regions = jsonDecoder.decodeList(
          '$jsonPath.regions',
          json['regions'],
          (String jsonPath, Object? json) => NavigationRegion.fromJson(
            jsonDecoder,
            jsonPath,
            json,
            clientUriConverter: clientUriConverter,
          ),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'regions');
      }
      return AnalysisGetNavigationResult(files, targets, regions);
    } else {
      throw jsonDecoder.mismatch(
        jsonPath,
        'analysis.getNavigation result',
        json,
      );
    }
  }

  factory AnalysisGetNavigationResult.fromResponse(
    Response response, {
    ClientUriConverter? clientUriConverter,
  }) {
    return AnalysisGetNavigationResult.fromJson(
      ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
      'result',
      response.result,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['files'] =
        files
            .map(
              (String value) =>
                  clientUriConverter?.toClientFilePath(value) ?? value,
            )
            .toList();
    result['targets'] =
        targets
            .map(
              (NavigationTarget value) =>
                  value.toJson(clientUriConverter: clientUriConverter),
            )
            .toList();
    result['regions'] =
        regions
            .map(
              (NavigationRegion value) =>
                  value.toJson(clientUriConverter: clientUriConverter),
            )
            .toList();
    return result;
  }

  @override
  Response toResponse(
    String id,
    int requestTime, {
    ClientUriConverter? clientUriConverter,
  }) {
    return Response(
      id,
      requestTime,
      result: toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is AnalysisGetNavigationResult) {
      return listEqual(files, other.files, (String a, String b) => a == b) &&
          listEqual(
            targets,
            other.targets,
            (NavigationTarget a, NavigationTarget b) => a == b,
          ) &&
          listEqual(
            regions,
            other.regions,
            (NavigationRegion a, NavigationRegion b) => a == b,
          );
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(files),
    Object.hashAll(targets),
    Object.hashAll(regions),
  );
}

/// analysis.handleWatchEvents params
///
/// {
///   "events": List<WatchEvent>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisHandleWatchEventsParams implements RequestParams {
  /// The watch events that the plugin should handle.
  List<WatchEvent> events;

  AnalysisHandleWatchEventsParams(this.events);

  factory AnalysisHandleWatchEventsParams.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      List<WatchEvent> events;
      if (json.containsKey('events')) {
        events = jsonDecoder.decodeList(
          '$jsonPath.events',
          json['events'],
          (String jsonPath, Object? json) => WatchEvent.fromJson(
            jsonDecoder,
            jsonPath,
            json,
            clientUriConverter: clientUriConverter,
          ),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'events');
      }
      return AnalysisHandleWatchEventsParams(events);
    } else {
      throw jsonDecoder.mismatch(
        jsonPath,
        'analysis.handleWatchEvents params',
        json,
      );
    }
  }

  factory AnalysisHandleWatchEventsParams.fromRequest(
    Request request, {
    ClientUriConverter? clientUriConverter,
  }) {
    return AnalysisHandleWatchEventsParams.fromJson(
      RequestDecoder(request),
      'params',
      request.params,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['events'] =
        events
            .map(
              (WatchEvent value) =>
                  value.toJson(clientUriConverter: clientUriConverter),
            )
            .toList();
    return result;
  }

  @override
  Request toRequest(String id, {ClientUriConverter? clientUriConverter}) {
    return Request(
      id,
      'analysis.handleWatchEvents',
      toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is AnalysisHandleWatchEventsParams) {
      return listEqual(
        events,
        other.events,
        (WatchEvent a, WatchEvent b) => a == b,
      );
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(events);
}

/// analysis.handleWatchEvents result
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisHandleWatchEventsResult implements ResponseResult {
  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) => {};

  @override
  Response toResponse(
    String id,
    int requestTime, {
    ClientUriConverter? clientUriConverter,
  }) {
    return Response(id, requestTime);
  }

  @override
  bool operator ==(other) => other is AnalysisHandleWatchEventsResult;

  @override
  int get hashCode => 779767607;
}

/// analysis.highlights params
///
/// {
///   "file": FilePath
///   "regions": List<HighlightRegion>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisHighlightsParams implements HasToJson {
  /// The file containing the highlight regions.
  String file;

  /// The highlight regions contained in the file.
  List<HighlightRegion> regions;

  AnalysisHighlightsParams(this.file, this.regions);

  factory AnalysisHighlightsParams.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file =
            clientUriConverter?.fromClientFilePath(
              jsonDecoder.decodeString('$jsonPath.file', json['file']),
            ) ??
            jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      List<HighlightRegion> regions;
      if (json.containsKey('regions')) {
        regions = jsonDecoder.decodeList(
          '$jsonPath.regions',
          json['regions'],
          (String jsonPath, Object? json) => HighlightRegion.fromJson(
            jsonDecoder,
            jsonPath,
            json,
            clientUriConverter: clientUriConverter,
          ),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'regions');
      }
      return AnalysisHighlightsParams(file, regions);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.highlights params', json);
    }
  }

  factory AnalysisHighlightsParams.fromNotification(
    Notification notification, {
    ClientUriConverter? clientUriConverter,
  }) {
    return AnalysisHighlightsParams.fromJson(
      ResponseDecoder(null),
      'params',
      notification.params,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['file'] = clientUriConverter?.toClientFilePath(file) ?? file;
    result['regions'] =
        regions
            .map(
              (HighlightRegion value) =>
                  value.toJson(clientUriConverter: clientUriConverter),
            )
            .toList();
    return result;
  }

  Notification toNotification({ClientUriConverter? clientUriConverter}) {
    return Notification(
      'analysis.highlights',
      toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is AnalysisHighlightsParams) {
      return file == other.file &&
          listEqual(
            regions,
            other.regions,
            (HighlightRegion a, HighlightRegion b) => a == b,
          );
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(file, Object.hashAll(regions));
}

/// analysis.navigation params
///
/// {
///   "file": FilePath
///   "regions": List<NavigationRegion>
///   "targets": List<NavigationTarget>
///   "files": List<FilePath>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisNavigationParams implements HasToJson {
  /// The file containing the navigation regions.
  String file;

  /// The navigation regions contained in the file.
  List<NavigationRegion> regions;

  /// The navigation targets referenced in the file. They are referenced by
  /// NavigationRegions by their index in this array.
  List<NavigationTarget> targets;

  /// The files containing navigation targets referenced in the file. They are
  /// referenced by NavigationTargets by their index in this array.
  List<String> files;

  AnalysisNavigationParams(this.file, this.regions, this.targets, this.files);

  factory AnalysisNavigationParams.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file =
            clientUriConverter?.fromClientFilePath(
              jsonDecoder.decodeString('$jsonPath.file', json['file']),
            ) ??
            jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      List<NavigationRegion> regions;
      if (json.containsKey('regions')) {
        regions = jsonDecoder.decodeList(
          '$jsonPath.regions',
          json['regions'],
          (String jsonPath, Object? json) => NavigationRegion.fromJson(
            jsonDecoder,
            jsonPath,
            json,
            clientUriConverter: clientUriConverter,
          ),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'regions');
      }
      List<NavigationTarget> targets;
      if (json.containsKey('targets')) {
        targets = jsonDecoder.decodeList(
          '$jsonPath.targets',
          json['targets'],
          (String jsonPath, Object? json) => NavigationTarget.fromJson(
            jsonDecoder,
            jsonPath,
            json,
            clientUriConverter: clientUriConverter,
          ),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'targets');
      }
      List<String> files;
      if (json.containsKey('files')) {
        files = jsonDecoder.decodeList(
          '$jsonPath.files',
          json['files'],
          (String jsonPath, Object? json) =>
              clientUriConverter?.fromClientFilePath(
                jsonDecoder.decodeString(jsonPath, json),
              ) ??
              jsonDecoder.decodeString(jsonPath, json),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'files');
      }
      return AnalysisNavigationParams(file, regions, targets, files);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.navigation params', json);
    }
  }

  factory AnalysisNavigationParams.fromNotification(
    Notification notification, {
    ClientUriConverter? clientUriConverter,
  }) {
    return AnalysisNavigationParams.fromJson(
      ResponseDecoder(null),
      'params',
      notification.params,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['file'] = clientUriConverter?.toClientFilePath(file) ?? file;
    result['regions'] =
        regions
            .map(
              (NavigationRegion value) =>
                  value.toJson(clientUriConverter: clientUriConverter),
            )
            .toList();
    result['targets'] =
        targets
            .map(
              (NavigationTarget value) =>
                  value.toJson(clientUriConverter: clientUriConverter),
            )
            .toList();
    result['files'] =
        files
            .map(
              (String value) =>
                  clientUriConverter?.toClientFilePath(value) ?? value,
            )
            .toList();
    return result;
  }

  Notification toNotification({ClientUriConverter? clientUriConverter}) {
    return Notification(
      'analysis.navigation',
      toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is AnalysisNavigationParams) {
      return file == other.file &&
          listEqual(
            regions,
            other.regions,
            (NavigationRegion a, NavigationRegion b) => a == b,
          ) &&
          listEqual(
            targets,
            other.targets,
            (NavigationTarget a, NavigationTarget b) => a == b,
          ) &&
          listEqual(files, other.files, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
    file,
    Object.hashAll(regions),
    Object.hashAll(targets),
    Object.hashAll(files),
  );
}

/// analysis.occurrences params
///
/// {
///   "file": FilePath
///   "occurrences": List<Occurrences>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisOccurrencesParams implements HasToJson {
  /// The file in which the references occur.
  String file;

  /// The occurrences of references to elements within the file.
  List<Occurrences> occurrences;

  AnalysisOccurrencesParams(this.file, this.occurrences);

  factory AnalysisOccurrencesParams.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file =
            clientUriConverter?.fromClientFilePath(
              jsonDecoder.decodeString('$jsonPath.file', json['file']),
            ) ??
            jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      List<Occurrences> occurrences;
      if (json.containsKey('occurrences')) {
        occurrences = jsonDecoder.decodeList(
          '$jsonPath.occurrences',
          json['occurrences'],
          (String jsonPath, Object? json) => Occurrences.fromJson(
            jsonDecoder,
            jsonPath,
            json,
            clientUriConverter: clientUriConverter,
          ),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'occurrences');
      }
      return AnalysisOccurrencesParams(file, occurrences);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.occurrences params', json);
    }
  }

  factory AnalysisOccurrencesParams.fromNotification(
    Notification notification, {
    ClientUriConverter? clientUriConverter,
  }) {
    return AnalysisOccurrencesParams.fromJson(
      ResponseDecoder(null),
      'params',
      notification.params,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['file'] = clientUriConverter?.toClientFilePath(file) ?? file;
    result['occurrences'] =
        occurrences
            .map(
              (Occurrences value) =>
                  value.toJson(clientUriConverter: clientUriConverter),
            )
            .toList();
    return result;
  }

  Notification toNotification({ClientUriConverter? clientUriConverter}) {
    return Notification(
      'analysis.occurrences',
      toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is AnalysisOccurrencesParams) {
      return file == other.file &&
          listEqual(
            occurrences,
            other.occurrences,
            (Occurrences a, Occurrences b) => a == b,
          );
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(file, Object.hashAll(occurrences));
}

/// analysis.outline params
///
/// {
///   "file": FilePath
///   "outline": List<Outline>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisOutlineParams implements HasToJson {
  /// The file with which the outline is associated.
  String file;

  /// The outline fragments associated with the file.
  List<Outline> outline;

  AnalysisOutlineParams(this.file, this.outline);

  factory AnalysisOutlineParams.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file =
            clientUriConverter?.fromClientFilePath(
              jsonDecoder.decodeString('$jsonPath.file', json['file']),
            ) ??
            jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      List<Outline> outline;
      if (json.containsKey('outline')) {
        outline = jsonDecoder.decodeList(
          '$jsonPath.outline',
          json['outline'],
          (String jsonPath, Object? json) => Outline.fromJson(
            jsonDecoder,
            jsonPath,
            json,
            clientUriConverter: clientUriConverter,
          ),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'outline');
      }
      return AnalysisOutlineParams(file, outline);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.outline params', json);
    }
  }

  factory AnalysisOutlineParams.fromNotification(
    Notification notification, {
    ClientUriConverter? clientUriConverter,
  }) {
    return AnalysisOutlineParams.fromJson(
      ResponseDecoder(null),
      'params',
      notification.params,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['file'] = clientUriConverter?.toClientFilePath(file) ?? file;
    result['outline'] =
        outline
            .map(
              (Outline value) =>
                  value.toJson(clientUriConverter: clientUriConverter),
            )
            .toList();
    return result;
  }

  Notification toNotification({ClientUriConverter? clientUriConverter}) {
    return Notification(
      'analysis.outline',
      toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is AnalysisOutlineParams) {
      return file == other.file &&
          listEqual(outline, other.outline, (Outline a, Outline b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(file, Object.hashAll(outline));
}

/// AnalysisService
///
/// enum {
///   FOLDING
///   HIGHLIGHTS
///   NAVIGATION
///   OCCURRENCES
///   OUTLINE
/// }
///
/// Clients may not extend, implement or mix-in this class.
enum AnalysisService {
  FOLDING,

  HIGHLIGHTS,

  NAVIGATION,

  OCCURRENCES,

  OUTLINE;

  factory AnalysisService.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    if (json is String) {
      try {
        return values.byName(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'AnalysisService', json);
  }

  @override
  String toString() => 'AnalysisService.$name';

  String toJson({ClientUriConverter? clientUriConverter}) => name;
}

/// analysis.setContextRoots params
///
/// {
///   "roots": List<ContextRoot>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisSetContextRootsParams implements RequestParams {
  /// A list of the context roots that should be analyzed.
  List<ContextRoot> roots;

  AnalysisSetContextRootsParams(this.roots);

  factory AnalysisSetContextRootsParams.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      List<ContextRoot> roots;
      if (json.containsKey('roots')) {
        roots = jsonDecoder.decodeList(
          '$jsonPath.roots',
          json['roots'],
          (String jsonPath, Object? json) => ContextRoot.fromJson(
            jsonDecoder,
            jsonPath,
            json,
            clientUriConverter: clientUriConverter,
          ),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'roots');
      }
      return AnalysisSetContextRootsParams(roots);
    } else {
      throw jsonDecoder.mismatch(
        jsonPath,
        'analysis.setContextRoots params',
        json,
      );
    }
  }

  factory AnalysisSetContextRootsParams.fromRequest(
    Request request, {
    ClientUriConverter? clientUriConverter,
  }) {
    return AnalysisSetContextRootsParams.fromJson(
      RequestDecoder(request),
      'params',
      request.params,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['roots'] =
        roots
            .map(
              (ContextRoot value) =>
                  value.toJson(clientUriConverter: clientUriConverter),
            )
            .toList();
    return result;
  }

  @override
  Request toRequest(String id, {ClientUriConverter? clientUriConverter}) {
    return Request(
      id,
      'analysis.setContextRoots',
      toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is AnalysisSetContextRootsParams) {
      return listEqual(
        roots,
        other.roots,
        (ContextRoot a, ContextRoot b) => a == b,
      );
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(roots);
}

/// analysis.setContextRoots result
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisSetContextRootsResult implements ResponseResult {
  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) => {};

  @override
  Response toResponse(
    String id,
    int requestTime, {
    ClientUriConverter? clientUriConverter,
  }) {
    return Response(id, requestTime);
  }

  @override
  bool operator ==(other) => other is AnalysisSetContextRootsResult;

  @override
  int get hashCode => 969645618;
}

/// analysis.setPriorityFiles params
///
/// {
///   "files": List<FilePath>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisSetPriorityFilesParams implements RequestParams {
  /// The files that are to be a priority for analysis.
  List<String> files;

  AnalysisSetPriorityFilesParams(this.files);

  factory AnalysisSetPriorityFilesParams.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      List<String> files;
      if (json.containsKey('files')) {
        files = jsonDecoder.decodeList(
          '$jsonPath.files',
          json['files'],
          (String jsonPath, Object? json) =>
              clientUriConverter?.fromClientFilePath(
                jsonDecoder.decodeString(jsonPath, json),
              ) ??
              jsonDecoder.decodeString(jsonPath, json),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'files');
      }
      return AnalysisSetPriorityFilesParams(files);
    } else {
      throw jsonDecoder.mismatch(
        jsonPath,
        'analysis.setPriorityFiles params',
        json,
      );
    }
  }

  factory AnalysisSetPriorityFilesParams.fromRequest(
    Request request, {
    ClientUriConverter? clientUriConverter,
  }) {
    return AnalysisSetPriorityFilesParams.fromJson(
      RequestDecoder(request),
      'params',
      request.params,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['files'] =
        files
            .map(
              (String value) =>
                  clientUriConverter?.toClientFilePath(value) ?? value,
            )
            .toList();
    return result;
  }

  @override
  Request toRequest(String id, {ClientUriConverter? clientUriConverter}) {
    return Request(
      id,
      'analysis.setPriorityFiles',
      toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is AnalysisSetPriorityFilesParams) {
      return listEqual(files, other.files, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(files);
}

/// analysis.setPriorityFiles result
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisSetPriorityFilesResult implements ResponseResult {
  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) => {};

  @override
  Response toResponse(
    String id,
    int requestTime, {
    ClientUriConverter? clientUriConverter,
  }) {
    return Response(id, requestTime);
  }

  @override
  bool operator ==(other) => other is AnalysisSetPriorityFilesResult;

  @override
  int get hashCode => 330050055;
}

/// analysis.setSubscriptions params
///
/// {
///   "subscriptions": Map<AnalysisService, List<FilePath>>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisSetSubscriptionsParams implements RequestParams {
  /// A table mapping services to a list of the files being subscribed to the
  /// service.
  Map<AnalysisService, List<String>> subscriptions;

  AnalysisSetSubscriptionsParams(this.subscriptions);

  factory AnalysisSetSubscriptionsParams.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      Map<AnalysisService, List<String>> subscriptions;
      if (json.containsKey('subscriptions')) {
        subscriptions = jsonDecoder.decodeMap(
          '$jsonPath.subscriptions',
          json['subscriptions'],
          keyDecoder:
              (String jsonPath, Object? json) => AnalysisService.fromJson(
                jsonDecoder,
                jsonPath,
                json,
                clientUriConverter: clientUriConverter,
              ),
          valueDecoder:
              (String jsonPath, Object? json) => jsonDecoder.decodeList(
                jsonPath,
                json,
                (String jsonPath, Object? json) =>
                    clientUriConverter?.fromClientFilePath(
                      jsonDecoder.decodeString(jsonPath, json),
                    ) ??
                    jsonDecoder.decodeString(jsonPath, json),
              ),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'subscriptions');
      }
      return AnalysisSetSubscriptionsParams(subscriptions);
    } else {
      throw jsonDecoder.mismatch(
        jsonPath,
        'analysis.setSubscriptions params',
        json,
      );
    }
  }

  factory AnalysisSetSubscriptionsParams.fromRequest(
    Request request, {
    ClientUriConverter? clientUriConverter,
  }) {
    return AnalysisSetSubscriptionsParams.fromJson(
      RequestDecoder(request),
      'params',
      request.params,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['subscriptions'] = mapMap(
      subscriptions,
      keyCallback:
          (AnalysisService value) =>
              value.toJson(clientUriConverter: clientUriConverter),
      valueCallback:
          (List<String> value) =>
              value
                  .map(
                    (String value) =>
                        clientUriConverter?.toClientFilePath(value) ?? value,
                  )
                  .toList(),
    );
    return result;
  }

  @override
  Request toRequest(String id, {ClientUriConverter? clientUriConverter}) {
    return Request(
      id,
      'analysis.setSubscriptions',
      toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is AnalysisSetSubscriptionsParams) {
      return mapEqual(
        subscriptions,
        other.subscriptions,
        (List<String> a, List<String> b) =>
            listEqual(a, b, (String a, String b) => a == b),
      );
    }
    return false;
  }

  @override
  int get hashCode =>
      Object.hashAll([...subscriptions.keys, ...subscriptions.values]);
}

/// analysis.setSubscriptions result
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisSetSubscriptionsResult implements ResponseResult {
  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) => {};

  @override
  Response toResponse(
    String id,
    int requestTime, {
    ClientUriConverter? clientUriConverter,
  }) {
    return Response(id, requestTime);
  }

  @override
  bool operator ==(other) => other is AnalysisSetSubscriptionsResult;

  @override
  int get hashCode => 218088493;
}

/// analysis.updateContent params
///
/// {
///   "files": Map<FilePath, AddContentOverlay | ChangeContentOverlay | RemoveContentOverlay>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisUpdateContentParams implements RequestParams {
  /// A table mapping the files whose content has changed to a description of
  /// the content change.
  Map<String, Object> files;

  AnalysisUpdateContentParams(this.files);

  factory AnalysisUpdateContentParams.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      Map<String, Object> files;
      if (json.containsKey('files')) {
        files = jsonDecoder.decodeMap(
          '$jsonPath.files',
          json['files'],
          keyDecoder:
              (String jsonPath, Object? json) =>
                  clientUriConverter?.fromClientFilePath(
                    jsonDecoder.decodeString(jsonPath, json),
                  ) ??
                  jsonDecoder.decodeString(jsonPath, json),
          valueDecoder:
              (String jsonPath, Object? json) =>
                  jsonDecoder.decodeUnion(jsonPath, json, 'type', {
                    'add':
                        (String jsonPath, Object? json) =>
                            AddContentOverlay.fromJson(
                              jsonDecoder,
                              jsonPath,
                              json,
                              clientUriConverter: clientUriConverter,
                            ),
                    'change':
                        (String jsonPath, Object? json) =>
                            ChangeContentOverlay.fromJson(
                              jsonDecoder,
                              jsonPath,
                              json,
                              clientUriConverter: clientUriConverter,
                            ),
                    'remove':
                        (String jsonPath, Object? json) =>
                            RemoveContentOverlay.fromJson(
                              jsonDecoder,
                              jsonPath,
                              json,
                              clientUriConverter: clientUriConverter,
                            ),
                  }),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'files');
      }
      return AnalysisUpdateContentParams(files);
    } else {
      throw jsonDecoder.mismatch(
        jsonPath,
        'analysis.updateContent params',
        json,
      );
    }
  }

  factory AnalysisUpdateContentParams.fromRequest(
    Request request, {
    ClientUriConverter? clientUriConverter,
  }) {
    return AnalysisUpdateContentParams.fromJson(
      RequestDecoder(request),
      'params',
      request.params,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['files'] = mapMap(
      files,
      keyCallback:
          (String value) =>
              clientUriConverter?.toClientFilePath(value) ?? value,
      valueCallback: (Object value) => (value as dynamic).toJson(),
    );
    return result;
  }

  @override
  Request toRequest(String id, {ClientUriConverter? clientUriConverter}) {
    return Request(
      id,
      'analysis.updateContent',
      toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is AnalysisUpdateContentParams) {
      return mapEqual(files, other.files, (Object a, Object b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll([...files.keys, ...files.values]);
}

/// analysis.updateContent result
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisUpdateContentResult implements ResponseResult {
  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) => {};

  @override
  Response toResponse(
    String id,
    int requestTime, {
    ClientUriConverter? clientUriConverter,
  }) {
    return Response(id, requestTime);
  }

  @override
  bool operator ==(other) => other is AnalysisUpdateContentResult;

  @override
  int get hashCode => 468798730;
}

/// completion.getSuggestions params
///
/// {
///   "file": FilePath
///   "offset": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionGetSuggestionsParams implements RequestParams {
  /// The file containing the point at which suggestions are to be made.
  String file;

  /// The offset within the file at which suggestions are to be made.
  int offset;

  CompletionGetSuggestionsParams(this.file, this.offset);

  factory CompletionGetSuggestionsParams.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file =
            clientUriConverter?.fromClientFilePath(
              jsonDecoder.decodeString('$jsonPath.file', json['file']),
            ) ??
            jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt('$jsonPath.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      return CompletionGetSuggestionsParams(file, offset);
    } else {
      throw jsonDecoder.mismatch(
        jsonPath,
        'completion.getSuggestions params',
        json,
      );
    }
  }

  factory CompletionGetSuggestionsParams.fromRequest(
    Request request, {
    ClientUriConverter? clientUriConverter,
  }) {
    return CompletionGetSuggestionsParams.fromJson(
      RequestDecoder(request),
      'params',
      request.params,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['file'] = clientUriConverter?.toClientFilePath(file) ?? file;
    result['offset'] = offset;
    return result;
  }

  @override
  Request toRequest(String id, {ClientUriConverter? clientUriConverter}) {
    return Request(
      id,
      'completion.getSuggestions',
      toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is CompletionGetSuggestionsParams) {
      return file == other.file && offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(file, offset);
}

/// completion.getSuggestions result
///
/// {
///   "replacementOffset": int
///   "replacementLength": int
///   "results": List<CompletionSuggestion>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionGetSuggestionsResult implements ResponseResult {
  /// The offset of the start of the text to be replaced. This will be
  /// different than the offset used to request the completion suggestions if
  /// there was a portion of an identifier before the original offset. In
  /// particular, the replacementOffset will be the offset of the beginning of
  /// said identifier.
  int replacementOffset;

  /// The length of the text to be replaced if the remainder of the identifier
  /// containing the cursor is to be replaced when the suggestion is applied
  /// (that is, the number of characters in the existing identifier).
  int replacementLength;

  /// The completion suggestions being reported. The notification contains all
  /// possible completions at the requested cursor position, even those that do
  /// not match the characters the user has already typed. This allows the
  /// client to respond to further keystrokes from the user without having to
  /// make additional requests.
  List<CompletionSuggestion> results;

  CompletionGetSuggestionsResult(
    this.replacementOffset,
    this.replacementLength,
    this.results,
  );

  factory CompletionGetSuggestionsResult.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      int replacementOffset;
      if (json.containsKey('replacementOffset')) {
        replacementOffset = jsonDecoder.decodeInt(
          '$jsonPath.replacementOffset',
          json['replacementOffset'],
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'replacementOffset');
      }
      int replacementLength;
      if (json.containsKey('replacementLength')) {
        replacementLength = jsonDecoder.decodeInt(
          '$jsonPath.replacementLength',
          json['replacementLength'],
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'replacementLength');
      }
      List<CompletionSuggestion> results;
      if (json.containsKey('results')) {
        results = jsonDecoder.decodeList(
          '$jsonPath.results',
          json['results'],
          (String jsonPath, Object? json) => CompletionSuggestion.fromJson(
            jsonDecoder,
            jsonPath,
            json,
            clientUriConverter: clientUriConverter,
          ),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'results');
      }
      return CompletionGetSuggestionsResult(
        replacementOffset,
        replacementLength,
        results,
      );
    } else {
      throw jsonDecoder.mismatch(
        jsonPath,
        'completion.getSuggestions result',
        json,
      );
    }
  }

  factory CompletionGetSuggestionsResult.fromResponse(
    Response response, {
    ClientUriConverter? clientUriConverter,
  }) {
    return CompletionGetSuggestionsResult.fromJson(
      ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
      'result',
      response.result,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['replacementOffset'] = replacementOffset;
    result['replacementLength'] = replacementLength;
    result['results'] =
        results
            .map(
              (CompletionSuggestion value) =>
                  value.toJson(clientUriConverter: clientUriConverter),
            )
            .toList();
    return result;
  }

  @override
  Response toResponse(
    String id,
    int requestTime, {
    ClientUriConverter? clientUriConverter,
  }) {
    return Response(
      id,
      requestTime,
      result: toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is CompletionGetSuggestionsResult) {
      return replacementOffset == other.replacementOffset &&
          replacementLength == other.replacementLength &&
          listEqual(
            results,
            other.results,
            (CompletionSuggestion a, CompletionSuggestion b) => a == b,
          );
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
    replacementOffset,
    replacementLength,
    Object.hashAll(results),
  );
}

/// ContextRoot
///
/// {
///   "root": FilePath
///   "exclude": List<FilePath>
///   "optionsFile": optional FilePath
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ContextRoot implements HasToJson {
  /// The absolute path of the root directory containing the files to be
  /// analyzed.
  String root;

  /// A list of the absolute paths of files and directories within the root
  /// directory that should not be analyzed.
  List<String> exclude;

  /// The absolute path of the analysis options file that should be used to
  /// control the analysis of the files in the context.
  String? optionsFile;

  ContextRoot(this.root, this.exclude, {this.optionsFile});

  factory ContextRoot.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      String root;
      if (json.containsKey('root')) {
        root =
            clientUriConverter?.fromClientFilePath(
              jsonDecoder.decodeString('$jsonPath.root', json['root']),
            ) ??
            jsonDecoder.decodeString('$jsonPath.root', json['root']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'root');
      }
      List<String> exclude;
      if (json.containsKey('exclude')) {
        exclude = jsonDecoder.decodeList(
          '$jsonPath.exclude',
          json['exclude'],
          (String jsonPath, Object? json) =>
              clientUriConverter?.fromClientFilePath(
                jsonDecoder.decodeString(jsonPath, json),
              ) ??
              jsonDecoder.decodeString(jsonPath, json),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'exclude');
      }
      String? optionsFile;
      if (json.containsKey('optionsFile')) {
        optionsFile =
            clientUriConverter?.fromClientFilePath(
              jsonDecoder.decodeString(
                '$jsonPath.optionsFile',
                json['optionsFile'],
              ),
            ) ??
            jsonDecoder.decodeString(
              '$jsonPath.optionsFile',
              json['optionsFile'],
            );
      }
      return ContextRoot(root, exclude, optionsFile: optionsFile);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ContextRoot', json);
    }
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['root'] = clientUriConverter?.toClientFilePath(root) ?? root;
    result['exclude'] =
        exclude
            .map(
              (String value) =>
                  clientUriConverter?.toClientFilePath(value) ?? value,
            )
            .toList();
    var optionsFile = this.optionsFile;
    if (optionsFile != null) {
      result['optionsFile'] =
          clientUriConverter?.toClientFilePath(optionsFile) ?? optionsFile;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is ContextRoot) {
      return root == other.root &&
          listEqual(exclude, other.exclude, (String a, String b) => a == b) &&
          optionsFile == other.optionsFile;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(root, Object.hashAll(exclude), optionsFile);
}

/// convertGetterToMethod feedback
///
/// Clients may not extend, implement or mix-in this class.
class ConvertGetterToMethodFeedback extends RefactoringFeedback
    implements HasToJson {
  @override
  bool operator ==(other) => other is ConvertGetterToMethodFeedback;

  @override
  int get hashCode => 616032599;
}

/// convertGetterToMethod options
///
/// Clients may not extend, implement or mix-in this class.
class ConvertGetterToMethodOptions extends RefactoringOptions
    implements HasToJson {
  @override
  bool operator ==(other) => other is ConvertGetterToMethodOptions;

  @override
  int get hashCode => 488848400;
}

/// convertMethodToGetter feedback
///
/// Clients may not extend, implement or mix-in this class.
class ConvertMethodToGetterFeedback extends RefactoringFeedback
    implements HasToJson {
  @override
  bool operator ==(other) => other is ConvertMethodToGetterFeedback;

  @override
  int get hashCode => 165291526;
}

/// convertMethodToGetter options
///
/// Clients may not extend, implement or mix-in this class.
class ConvertMethodToGetterOptions extends RefactoringOptions
    implements HasToJson {
  @override
  bool operator ==(other) => other is ConvertMethodToGetterOptions;

  @override
  int get hashCode => 27952290;
}

/// edit.getAssists params
///
/// {
///   "file": FilePath
///   "offset": int
///   "length": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetAssistsParams implements RequestParams {
  /// The file containing the code for which assists are being requested.
  String file;

  /// The offset of the code for which assists are being requested.
  int offset;

  /// The length of the code for which assists are being requested.
  int length;

  EditGetAssistsParams(this.file, this.offset, this.length);

  factory EditGetAssistsParams.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file =
            clientUriConverter?.fromClientFilePath(
              jsonDecoder.decodeString('$jsonPath.file', json['file']),
            ) ??
            jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt('$jsonPath.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt('$jsonPath.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      return EditGetAssistsParams(file, offset, length);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.getAssists params', json);
    }
  }

  factory EditGetAssistsParams.fromRequest(
    Request request, {
    ClientUriConverter? clientUriConverter,
  }) {
    return EditGetAssistsParams.fromJson(
      RequestDecoder(request),
      'params',
      request.params,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['file'] = clientUriConverter?.toClientFilePath(file) ?? file;
    result['offset'] = offset;
    result['length'] = length;
    return result;
  }

  @override
  Request toRequest(String id, {ClientUriConverter? clientUriConverter}) {
    return Request(
      id,
      'edit.getAssists',
      toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is EditGetAssistsParams) {
      return file == other.file &&
          offset == other.offset &&
          length == other.length;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(file, offset, length);
}

/// edit.getAssists result
///
/// {
///   "assists": List<PrioritizedSourceChange>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetAssistsResult implements ResponseResult {
  /// The assists that are available at the given location.
  List<PrioritizedSourceChange> assists;

  EditGetAssistsResult(this.assists);

  factory EditGetAssistsResult.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      List<PrioritizedSourceChange> assists;
      if (json.containsKey('assists')) {
        assists = jsonDecoder.decodeList(
          '$jsonPath.assists',
          json['assists'],
          (String jsonPath, Object? json) => PrioritizedSourceChange.fromJson(
            jsonDecoder,
            jsonPath,
            json,
            clientUriConverter: clientUriConverter,
          ),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'assists');
      }
      return EditGetAssistsResult(assists);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.getAssists result', json);
    }
  }

  factory EditGetAssistsResult.fromResponse(
    Response response, {
    ClientUriConverter? clientUriConverter,
  }) {
    return EditGetAssistsResult.fromJson(
      ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
      'result',
      response.result,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['assists'] =
        assists
            .map(
              (PrioritizedSourceChange value) =>
                  value.toJson(clientUriConverter: clientUriConverter),
            )
            .toList();
    return result;
  }

  @override
  Response toResponse(
    String id,
    int requestTime, {
    ClientUriConverter? clientUriConverter,
  }) {
    return Response(
      id,
      requestTime,
      result: toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is EditGetAssistsResult) {
      return listEqual(
        assists,
        other.assists,
        (PrioritizedSourceChange a, PrioritizedSourceChange b) => a == b,
      );
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(assists);
}

/// edit.getAvailableRefactorings params
///
/// {
///   "file": FilePath
///   "offset": int
///   "length": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetAvailableRefactoringsParams implements RequestParams {
  /// The file containing the code on which the refactoring would be based.
  String file;

  /// The offset of the code on which the refactoring would be based.
  int offset;

  /// The length of the code on which the refactoring would be based.
  int length;

  EditGetAvailableRefactoringsParams(this.file, this.offset, this.length);

  factory EditGetAvailableRefactoringsParams.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file =
            clientUriConverter?.fromClientFilePath(
              jsonDecoder.decodeString('$jsonPath.file', json['file']),
            ) ??
            jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt('$jsonPath.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt('$jsonPath.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      return EditGetAvailableRefactoringsParams(file, offset, length);
    } else {
      throw jsonDecoder.mismatch(
        jsonPath,
        'edit.getAvailableRefactorings params',
        json,
      );
    }
  }

  factory EditGetAvailableRefactoringsParams.fromRequest(
    Request request, {
    ClientUriConverter? clientUriConverter,
  }) {
    return EditGetAvailableRefactoringsParams.fromJson(
      RequestDecoder(request),
      'params',
      request.params,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['file'] = clientUriConverter?.toClientFilePath(file) ?? file;
    result['offset'] = offset;
    result['length'] = length;
    return result;
  }

  @override
  Request toRequest(String id, {ClientUriConverter? clientUriConverter}) {
    return Request(
      id,
      'edit.getAvailableRefactorings',
      toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is EditGetAvailableRefactoringsParams) {
      return file == other.file &&
          offset == other.offset &&
          length == other.length;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(file, offset, length);
}

/// edit.getAvailableRefactorings result
///
/// {
///   "kinds": List<RefactoringKind>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetAvailableRefactoringsResult implements ResponseResult {
  /// The kinds of refactorings that are valid for the given selection.
  ///
  /// The list of refactoring kinds is currently limited to those defined by
  /// the server API, preventing plugins from adding their own refactorings.
  /// However, plugins can support pre-defined refactorings, such as a rename
  /// refactoring, at locations not supported by server.
  List<RefactoringKind> kinds;

  EditGetAvailableRefactoringsResult(this.kinds);

  factory EditGetAvailableRefactoringsResult.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      List<RefactoringKind> kinds;
      if (json.containsKey('kinds')) {
        kinds = jsonDecoder.decodeList(
          '$jsonPath.kinds',
          json['kinds'],
          (String jsonPath, Object? json) => RefactoringKind.fromJson(
            jsonDecoder,
            jsonPath,
            json,
            clientUriConverter: clientUriConverter,
          ),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kinds');
      }
      return EditGetAvailableRefactoringsResult(kinds);
    } else {
      throw jsonDecoder.mismatch(
        jsonPath,
        'edit.getAvailableRefactorings result',
        json,
      );
    }
  }

  factory EditGetAvailableRefactoringsResult.fromResponse(
    Response response, {
    ClientUriConverter? clientUriConverter,
  }) {
    return EditGetAvailableRefactoringsResult.fromJson(
      ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
      'result',
      response.result,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['kinds'] =
        kinds
            .map(
              (RefactoringKind value) =>
                  value.toJson(clientUriConverter: clientUriConverter),
            )
            .toList();
    return result;
  }

  @override
  Response toResponse(
    String id,
    int requestTime, {
    ClientUriConverter? clientUriConverter,
  }) {
    return Response(
      id,
      requestTime,
      result: toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is EditGetAvailableRefactoringsResult) {
      return listEqual(
        kinds,
        other.kinds,
        (RefactoringKind a, RefactoringKind b) => a == b,
      );
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(kinds);
}

/// edit.getFixes params
///
/// {
///   "file": FilePath
///   "offset": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetFixesParams implements RequestParams {
  /// The file containing the errors for which fixes are being requested.
  String file;

  /// The offset used to select the errors for which fixes will be returned.
  int offset;

  EditGetFixesParams(this.file, this.offset);

  factory EditGetFixesParams.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file =
            clientUriConverter?.fromClientFilePath(
              jsonDecoder.decodeString('$jsonPath.file', json['file']),
            ) ??
            jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt('$jsonPath.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      return EditGetFixesParams(file, offset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.getFixes params', json);
    }
  }

  factory EditGetFixesParams.fromRequest(
    Request request, {
    ClientUriConverter? clientUriConverter,
  }) {
    return EditGetFixesParams.fromJson(
      RequestDecoder(request),
      'params',
      request.params,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['file'] = clientUriConverter?.toClientFilePath(file) ?? file;
    result['offset'] = offset;
    return result;
  }

  @override
  Request toRequest(String id, {ClientUriConverter? clientUriConverter}) {
    return Request(
      id,
      'edit.getFixes',
      toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is EditGetFixesParams) {
      return file == other.file && offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(file, offset);
}

/// edit.getFixes result
///
/// {
///   "fixes": List<AnalysisErrorFixes>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetFixesResult implements ResponseResult {
  /// The fixes that are available for the errors at the given offset.
  List<AnalysisErrorFixes> fixes;

  EditGetFixesResult(this.fixes);

  factory EditGetFixesResult.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      List<AnalysisErrorFixes> fixes;
      if (json.containsKey('fixes')) {
        fixes = jsonDecoder.decodeList(
          '$jsonPath.fixes',
          json['fixes'],
          (String jsonPath, Object? json) => AnalysisErrorFixes.fromJson(
            jsonDecoder,
            jsonPath,
            json,
            clientUriConverter: clientUriConverter,
          ),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'fixes');
      }
      return EditGetFixesResult(fixes);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.getFixes result', json);
    }
  }

  factory EditGetFixesResult.fromResponse(
    Response response, {
    ClientUriConverter? clientUriConverter,
  }) {
    return EditGetFixesResult.fromJson(
      ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
      'result',
      response.result,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['fixes'] =
        fixes
            .map(
              (AnalysisErrorFixes value) =>
                  value.toJson(clientUriConverter: clientUriConverter),
            )
            .toList();
    return result;
  }

  @override
  Response toResponse(
    String id,
    int requestTime, {
    ClientUriConverter? clientUriConverter,
  }) {
    return Response(
      id,
      requestTime,
      result: toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is EditGetFixesResult) {
      return listEqual(
        fixes,
        other.fixes,
        (AnalysisErrorFixes a, AnalysisErrorFixes b) => a == b,
      );
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(fixes);
}

/// edit.getRefactoring params
///
/// {
///   "kind": RefactoringKind
///   "file": FilePath
///   "offset": int
///   "length": int
///   "validateOnly": bool
///   "options": optional RefactoringOptions
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetRefactoringParams implements RequestParams {
  /// The kind of refactoring to be performed.
  RefactoringKind kind;

  /// The file containing the code involved in the refactoring.
  String file;

  /// The offset of the region involved in the refactoring.
  int offset;

  /// The length of the region involved in the refactoring.
  int length;

  /// True if the client is only requesting that the values of the options be
  /// validated and no change be generated.
  bool validateOnly;

  /// Data used to provide values provided by the user. The structure of the
  /// data is dependent on the kind of refactoring being performed. The data
  /// that is expected is documented in the section titled Refactorings,
  /// labeled as "Options". This field can be omitted if the refactoring does
  /// not require any options or if the values of those options are not known.
  RefactoringOptions? options;

  EditGetRefactoringParams(
    this.kind,
    this.file,
    this.offset,
    this.length,
    this.validateOnly, {
    this.options,
  });

  factory EditGetRefactoringParams.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      RefactoringKind kind;
      if (json.containsKey('kind')) {
        kind = RefactoringKind.fromJson(
          jsonDecoder,
          '$jsonPath.kind',
          json['kind'],
          clientUriConverter: clientUriConverter,
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      String file;
      if (json.containsKey('file')) {
        file =
            clientUriConverter?.fromClientFilePath(
              jsonDecoder.decodeString('$jsonPath.file', json['file']),
            ) ??
            jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt('$jsonPath.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt('$jsonPath.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      bool validateOnly;
      if (json.containsKey('validateOnly')) {
        validateOnly = jsonDecoder.decodeBool(
          '$jsonPath.validateOnly',
          json['validateOnly'],
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'validateOnly');
      }
      RefactoringOptions? options;
      if (json.containsKey('options')) {
        options = RefactoringOptions.fromJson(
          jsonDecoder,
          '$jsonPath.options',
          json['options'],
          kind,
          clientUriConverter: clientUriConverter,
        );
      }
      return EditGetRefactoringParams(
        kind,
        file,
        offset,
        length,
        validateOnly,
        options: options,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.getRefactoring params', json);
    }
  }

  factory EditGetRefactoringParams.fromRequest(
    Request request, {
    ClientUriConverter? clientUriConverter,
  }) {
    var params = EditGetRefactoringParams.fromJson(
      RequestDecoder(request),
      'params',
      request.params,
      clientUriConverter: clientUriConverter,
    );
    REQUEST_ID_REFACTORING_KINDS[request.id] = params.kind;
    return params;
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['kind'] = kind.toJson(clientUriConverter: clientUriConverter);
    result['file'] = clientUriConverter?.toClientFilePath(file) ?? file;
    result['offset'] = offset;
    result['length'] = length;
    result['validateOnly'] = validateOnly;
    var options = this.options;
    if (options != null) {
      result['options'] = options.toJson(
        clientUriConverter: clientUriConverter,
      );
    }
    return result;
  }

  @override
  Request toRequest(String id, {ClientUriConverter? clientUriConverter}) {
    return Request(
      id,
      'edit.getRefactoring',
      toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is EditGetRefactoringParams) {
      return kind == other.kind &&
          file == other.file &&
          offset == other.offset &&
          length == other.length &&
          validateOnly == other.validateOnly &&
          options == other.options;
    }
    return false;
  }

  @override
  int get hashCode =>
      Object.hash(kind, file, offset, length, validateOnly, options);
}

/// edit.getRefactoring result
///
/// {
///   "initialProblems": List<RefactoringProblem>
///   "optionsProblems": List<RefactoringProblem>
///   "finalProblems": List<RefactoringProblem>
///   "feedback": optional RefactoringFeedback
///   "change": optional SourceChange
///   "potentialEdits": optional List<String>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetRefactoringResult implements ResponseResult {
  /// The initial status of the refactoring, that is, problems related to the
  /// context in which the refactoring is requested. The list should be empty
  /// if there are no known problems.
  List<RefactoringProblem> initialProblems;

  /// The options validation status, that is, problems in the given options,
  /// such as light-weight validation of a new name, flags compatibility, etc.
  /// The list should be empty if there are no known problems.
  List<RefactoringProblem> optionsProblems;

  /// The final status of the refactoring, that is, problems identified in the
  /// result of a full, potentially expensive validation and / or change
  /// creation. The list should be empty if there are no known problems.
  List<RefactoringProblem> finalProblems;

  /// Data used to provide feedback to the user. The structure of the data is
  /// dependent on the kind of refactoring being created. The data that is
  /// returned is documented in the section titled Refactorings, labeled as
  /// "Feedback".
  RefactoringFeedback? feedback;

  /// The changes that are to be applied to affect the refactoring. This field
  /// can be omitted if there are problems that prevent a set of changes from
  /// being computed, such as having no options specified for a refactoring
  /// that requires them, or if only validation was requested.
  SourceChange? change;

  /// The ids of source edits that are not known to be valid. An edit is not
  /// known to be valid if there was insufficient type information for the
  /// plugin to be able to determine whether or not the code needs to be
  /// modified, such as when a member is being renamed and there is a reference
  /// to a member from an unknown type. This field can be omitted if the change
  /// field is omitted or if there are no potential edits for the refactoring.
  List<String>? potentialEdits;

  EditGetRefactoringResult(
    this.initialProblems,
    this.optionsProblems,
    this.finalProblems, {
    this.feedback,
    this.change,
    this.potentialEdits,
  });

  factory EditGetRefactoringResult.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      List<RefactoringProblem> initialProblems;
      if (json.containsKey('initialProblems')) {
        initialProblems = jsonDecoder.decodeList(
          '$jsonPath.initialProblems',
          json['initialProblems'],
          (String jsonPath, Object? json) => RefactoringProblem.fromJson(
            jsonDecoder,
            jsonPath,
            json,
            clientUriConverter: clientUriConverter,
          ),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'initialProblems');
      }
      List<RefactoringProblem> optionsProblems;
      if (json.containsKey('optionsProblems')) {
        optionsProblems = jsonDecoder.decodeList(
          '$jsonPath.optionsProblems',
          json['optionsProblems'],
          (String jsonPath, Object? json) => RefactoringProblem.fromJson(
            jsonDecoder,
            jsonPath,
            json,
            clientUriConverter: clientUriConverter,
          ),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'optionsProblems');
      }
      List<RefactoringProblem> finalProblems;
      if (json.containsKey('finalProblems')) {
        finalProblems = jsonDecoder.decodeList(
          '$jsonPath.finalProblems',
          json['finalProblems'],
          (String jsonPath, Object? json) => RefactoringProblem.fromJson(
            jsonDecoder,
            jsonPath,
            json,
            clientUriConverter: clientUriConverter,
          ),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'finalProblems');
      }
      RefactoringFeedback? feedback;
      if (json.containsKey('feedback')) {
        feedback = RefactoringFeedback.fromJson(
          jsonDecoder,
          '$jsonPath.feedback',
          json['feedback'],
          json,
          clientUriConverter: clientUriConverter,
        );
      }
      SourceChange? change;
      if (json.containsKey('change')) {
        change = SourceChange.fromJson(
          jsonDecoder,
          '$jsonPath.change',
          json['change'],
          clientUriConverter: clientUriConverter,
        );
      }
      List<String>? potentialEdits;
      if (json.containsKey('potentialEdits')) {
        potentialEdits = jsonDecoder.decodeList(
          '$jsonPath.potentialEdits',
          json['potentialEdits'],
          jsonDecoder.decodeString,
        );
      }
      return EditGetRefactoringResult(
        initialProblems,
        optionsProblems,
        finalProblems,
        feedback: feedback,
        change: change,
        potentialEdits: potentialEdits,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.getRefactoring result', json);
    }
  }

  factory EditGetRefactoringResult.fromResponse(
    Response response, {
    ClientUriConverter? clientUriConverter,
  }) {
    return EditGetRefactoringResult.fromJson(
      ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
      'result',
      response.result,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['initialProblems'] =
        initialProblems
            .map(
              (RefactoringProblem value) =>
                  value.toJson(clientUriConverter: clientUriConverter),
            )
            .toList();
    result['optionsProblems'] =
        optionsProblems
            .map(
              (RefactoringProblem value) =>
                  value.toJson(clientUriConverter: clientUriConverter),
            )
            .toList();
    result['finalProblems'] =
        finalProblems
            .map(
              (RefactoringProblem value) =>
                  value.toJson(clientUriConverter: clientUriConverter),
            )
            .toList();
    var feedback = this.feedback;
    if (feedback != null) {
      result['feedback'] = feedback.toJson(
        clientUriConverter: clientUriConverter,
      );
    }
    var change = this.change;
    if (change != null) {
      result['change'] = change.toJson(clientUriConverter: clientUriConverter);
    }
    var potentialEdits = this.potentialEdits;
    if (potentialEdits != null) {
      result['potentialEdits'] = potentialEdits;
    }
    return result;
  }

  @override
  Response toResponse(
    String id,
    int requestTime, {
    ClientUriConverter? clientUriConverter,
  }) {
    return Response(
      id,
      requestTime,
      result: toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is EditGetRefactoringResult) {
      return listEqual(
            initialProblems,
            other.initialProblems,
            (RefactoringProblem a, RefactoringProblem b) => a == b,
          ) &&
          listEqual(
            optionsProblems,
            other.optionsProblems,
            (RefactoringProblem a, RefactoringProblem b) => a == b,
          ) &&
          listEqual(
            finalProblems,
            other.finalProblems,
            (RefactoringProblem a, RefactoringProblem b) => a == b,
          ) &&
          feedback == other.feedback &&
          change == other.change &&
          listEqual(
            potentialEdits,
            other.potentialEdits,
            (String a, String b) => a == b,
          );
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(initialProblems),
    Object.hashAll(optionsProblems),
    Object.hashAll(finalProblems),
    feedback,
    change,
    Object.hashAll(potentialEdits ?? []),
  );
}

/// extractLocalVariable feedback
///
/// {
///   "coveringExpressionOffsets": optional List<int>
///   "coveringExpressionLengths": optional List<int>
///   "names": List<String>
///   "offsets": List<int>
///   "lengths": List<int>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExtractLocalVariableFeedback extends RefactoringFeedback {
  /// The offsets of the expressions that cover the specified selection, from
  /// the down most to the up most.
  List<int>? coveringExpressionOffsets;

  /// The lengths of the expressions that cover the specified selection, from
  /// the down most to the up most.
  List<int>? coveringExpressionLengths;

  /// The proposed names for the local variable.
  List<String> names;

  /// The offsets of the expressions that would be replaced by a reference to
  /// the variable.
  List<int> offsets;

  /// The lengths of the expressions that would be replaced by a reference to
  /// the variable. The lengths correspond to the offsets. In other words, for
  /// a given expression, if the offset of that expression is offsets[i], then
  /// the length of that expression is lengths[i].
  List<int> lengths;

  ExtractLocalVariableFeedback(
    this.names,
    this.offsets,
    this.lengths, {
    this.coveringExpressionOffsets,
    this.coveringExpressionLengths,
  });

  factory ExtractLocalVariableFeedback.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      List<int>? coveringExpressionOffsets;
      if (json.containsKey('coveringExpressionOffsets')) {
        coveringExpressionOffsets = jsonDecoder.decodeList(
          '$jsonPath.coveringExpressionOffsets',
          json['coveringExpressionOffsets'],
          jsonDecoder.decodeInt,
        );
      }
      List<int>? coveringExpressionLengths;
      if (json.containsKey('coveringExpressionLengths')) {
        coveringExpressionLengths = jsonDecoder.decodeList(
          '$jsonPath.coveringExpressionLengths',
          json['coveringExpressionLengths'],
          jsonDecoder.decodeInt,
        );
      }
      List<String> names;
      if (json.containsKey('names')) {
        names = jsonDecoder.decodeList(
          '$jsonPath.names',
          json['names'],
          jsonDecoder.decodeString,
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'names');
      }
      List<int> offsets;
      if (json.containsKey('offsets')) {
        offsets = jsonDecoder.decodeList(
          '$jsonPath.offsets',
          json['offsets'],
          jsonDecoder.decodeInt,
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offsets');
      }
      List<int> lengths;
      if (json.containsKey('lengths')) {
        lengths = jsonDecoder.decodeList(
          '$jsonPath.lengths',
          json['lengths'],
          jsonDecoder.decodeInt,
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'lengths');
      }
      return ExtractLocalVariableFeedback(
        names,
        offsets,
        lengths,
        coveringExpressionOffsets: coveringExpressionOffsets,
        coveringExpressionLengths: coveringExpressionLengths,
      );
    } else {
      throw jsonDecoder.mismatch(
        jsonPath,
        'extractLocalVariable feedback',
        json,
      );
    }
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    var coveringExpressionOffsets = this.coveringExpressionOffsets;
    if (coveringExpressionOffsets != null) {
      result['coveringExpressionOffsets'] = coveringExpressionOffsets;
    }
    var coveringExpressionLengths = this.coveringExpressionLengths;
    if (coveringExpressionLengths != null) {
      result['coveringExpressionLengths'] = coveringExpressionLengths;
    }
    result['names'] = names;
    result['offsets'] = offsets;
    result['lengths'] = lengths;
    return result;
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is ExtractLocalVariableFeedback) {
      return listEqual(
            coveringExpressionOffsets,
            other.coveringExpressionOffsets,
            (int a, int b) => a == b,
          ) &&
          listEqual(
            coveringExpressionLengths,
            other.coveringExpressionLengths,
            (int a, int b) => a == b,
          ) &&
          listEqual(names, other.names, (String a, String b) => a == b) &&
          listEqual(offsets, other.offsets, (int a, int b) => a == b) &&
          listEqual(lengths, other.lengths, (int a, int b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(coveringExpressionOffsets ?? []),
    Object.hashAll(coveringExpressionLengths ?? []),
    Object.hashAll(names),
    Object.hashAll(offsets),
    Object.hashAll(lengths),
  );
}

/// extractLocalVariable options
///
/// {
///   "name": String
///   "extractAll": bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExtractLocalVariableOptions extends RefactoringOptions {
  /// The name that the local variable should be given.
  String name;

  /// True if all occurrences of the expression within the scope in which the
  /// variable will be defined should be replaced by a reference to the local
  /// variable. The expression used to initiate the refactoring will always be
  /// replaced.
  bool extractAll;

  ExtractLocalVariableOptions(this.name, this.extractAll);

  factory ExtractLocalVariableOptions.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString('$jsonPath.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      bool extractAll;
      if (json.containsKey('extractAll')) {
        extractAll = jsonDecoder.decodeBool(
          '$jsonPath.extractAll',
          json['extractAll'],
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'extractAll');
      }
      return ExtractLocalVariableOptions(name, extractAll);
    } else {
      throw jsonDecoder.mismatch(
        jsonPath,
        'extractLocalVariable options',
        json,
      );
    }
  }

  factory ExtractLocalVariableOptions.fromRefactoringParams(
    EditGetRefactoringParams refactoringParams,
    Request request, {
    ClientUriConverter? clientUriConverter,
  }) {
    return ExtractLocalVariableOptions.fromJson(
      RequestDecoder(request),
      'options',
      refactoringParams.options,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['name'] = name;
    result['extractAll'] = extractAll;
    return result;
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is ExtractLocalVariableOptions) {
      return name == other.name && extractAll == other.extractAll;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(name, extractAll);
}

/// extractMethod feedback
///
/// {
///   "offset": int
///   "length": int
///   "returnType": String
///   "names": List<String>
///   "canCreateGetter": bool
///   "parameters": List<RefactoringMethodParameter>
///   "offsets": List<int>
///   "lengths": List<int>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExtractMethodFeedback extends RefactoringFeedback {
  /// The offset to the beginning of the expression or statements that will be
  /// extracted.
  int offset;

  /// The length of the expression or statements that will be extracted.
  int length;

  /// The proposed return type for the method. If the returned element does not
  /// have a declared return type, this field will contain an empty string.
  String returnType;

  /// The proposed names for the method.
  List<String> names;

  /// True if a getter could be created rather than a method.
  bool canCreateGetter;

  /// The proposed parameters for the method.
  List<RefactoringMethodParameter> parameters;

  /// The offsets of the expressions or statements that would be replaced by an
  /// invocation of the method.
  List<int> offsets;

  /// The lengths of the expressions or statements that would be replaced by an
  /// invocation of the method. The lengths correspond to the offsets. In other
  /// words, for a given expression (or block of statements), if the offset of
  /// that expression is offsets[i], then the length of that expression is
  /// lengths[i].
  List<int> lengths;

  ExtractMethodFeedback(
    this.offset,
    this.length,
    this.returnType,
    this.names,
    this.canCreateGetter,
    this.parameters,
    this.offsets,
    this.lengths,
  );

  factory ExtractMethodFeedback.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt('$jsonPath.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt('$jsonPath.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      String returnType;
      if (json.containsKey('returnType')) {
        returnType = jsonDecoder.decodeString(
          '$jsonPath.returnType',
          json['returnType'],
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'returnType');
      }
      List<String> names;
      if (json.containsKey('names')) {
        names = jsonDecoder.decodeList(
          '$jsonPath.names',
          json['names'],
          jsonDecoder.decodeString,
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'names');
      }
      bool canCreateGetter;
      if (json.containsKey('canCreateGetter')) {
        canCreateGetter = jsonDecoder.decodeBool(
          '$jsonPath.canCreateGetter',
          json['canCreateGetter'],
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'canCreateGetter');
      }
      List<RefactoringMethodParameter> parameters;
      if (json.containsKey('parameters')) {
        parameters = jsonDecoder.decodeList(
          '$jsonPath.parameters',
          json['parameters'],
          (String jsonPath, Object? json) =>
              RefactoringMethodParameter.fromJson(
                jsonDecoder,
                jsonPath,
                json,
                clientUriConverter: clientUriConverter,
              ),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'parameters');
      }
      List<int> offsets;
      if (json.containsKey('offsets')) {
        offsets = jsonDecoder.decodeList(
          '$jsonPath.offsets',
          json['offsets'],
          jsonDecoder.decodeInt,
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offsets');
      }
      List<int> lengths;
      if (json.containsKey('lengths')) {
        lengths = jsonDecoder.decodeList(
          '$jsonPath.lengths',
          json['lengths'],
          jsonDecoder.decodeInt,
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'lengths');
      }
      return ExtractMethodFeedback(
        offset,
        length,
        returnType,
        names,
        canCreateGetter,
        parameters,
        offsets,
        lengths,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'extractMethod feedback', json);
    }
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['offset'] = offset;
    result['length'] = length;
    result['returnType'] = returnType;
    result['names'] = names;
    result['canCreateGetter'] = canCreateGetter;
    result['parameters'] =
        parameters
            .map(
              (RefactoringMethodParameter value) =>
                  value.toJson(clientUriConverter: clientUriConverter),
            )
            .toList();
    result['offsets'] = offsets;
    result['lengths'] = lengths;
    return result;
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is ExtractMethodFeedback) {
      return offset == other.offset &&
          length == other.length &&
          returnType == other.returnType &&
          listEqual(names, other.names, (String a, String b) => a == b) &&
          canCreateGetter == other.canCreateGetter &&
          listEqual(
            parameters,
            other.parameters,
            (RefactoringMethodParameter a, RefactoringMethodParameter b) =>
                a == b,
          ) &&
          listEqual(offsets, other.offsets, (int a, int b) => a == b) &&
          listEqual(lengths, other.lengths, (int a, int b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
    offset,
    length,
    returnType,
    Object.hashAll(names),
    canCreateGetter,
    Object.hashAll(parameters),
    Object.hashAll(offsets),
    Object.hashAll(lengths),
  );
}

/// extractMethod options
///
/// {
///   "returnType": String
///   "createGetter": bool
///   "name": String
///   "parameters": List<RefactoringMethodParameter>
///   "extractAll": bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExtractMethodOptions extends RefactoringOptions {
  /// The return type that should be defined for the method.
  String returnType;

  /// True if a getter should be created rather than a method. It is an error
  /// if this field is true and the list of parameters is non-empty.
  bool createGetter;

  /// The name that the method should be given.
  String name;

  /// The parameters that should be defined for the method.
  ///
  /// It is an error if a REQUIRED or NAMED parameter follows a POSITIONAL
  /// parameter. It is an error if a REQUIRED or POSITIONAL parameter follows a
  /// NAMED parameter.
  ///
  /// - To change the order and/or update proposed parameters, add parameters
  ///   with the same identifiers as proposed.
  /// - To add new parameters, omit their identifier.
  /// - To remove some parameters, omit them in this list.
  List<RefactoringMethodParameter> parameters;

  /// True if all occurrences of the expression or statements should be
  /// replaced by an invocation of the method. The expression or statements
  /// used to initiate the refactoring will always be replaced.
  bool extractAll;

  ExtractMethodOptions(
    this.returnType,
    this.createGetter,
    this.name,
    this.parameters,
    this.extractAll,
  );

  factory ExtractMethodOptions.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      String returnType;
      if (json.containsKey('returnType')) {
        returnType = jsonDecoder.decodeString(
          '$jsonPath.returnType',
          json['returnType'],
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'returnType');
      }
      bool createGetter;
      if (json.containsKey('createGetter')) {
        createGetter = jsonDecoder.decodeBool(
          '$jsonPath.createGetter',
          json['createGetter'],
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'createGetter');
      }
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString('$jsonPath.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      List<RefactoringMethodParameter> parameters;
      if (json.containsKey('parameters')) {
        parameters = jsonDecoder.decodeList(
          '$jsonPath.parameters',
          json['parameters'],
          (String jsonPath, Object? json) =>
              RefactoringMethodParameter.fromJson(
                jsonDecoder,
                jsonPath,
                json,
                clientUriConverter: clientUriConverter,
              ),
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'parameters');
      }
      bool extractAll;
      if (json.containsKey('extractAll')) {
        extractAll = jsonDecoder.decodeBool(
          '$jsonPath.extractAll',
          json['extractAll'],
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'extractAll');
      }
      return ExtractMethodOptions(
        returnType,
        createGetter,
        name,
        parameters,
        extractAll,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'extractMethod options', json);
    }
  }

  factory ExtractMethodOptions.fromRefactoringParams(
    EditGetRefactoringParams refactoringParams,
    Request request, {
    ClientUriConverter? clientUriConverter,
  }) {
    return ExtractMethodOptions.fromJson(
      RequestDecoder(request),
      'options',
      refactoringParams.options,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['returnType'] = returnType;
    result['createGetter'] = createGetter;
    result['name'] = name;
    result['parameters'] =
        parameters
            .map(
              (RefactoringMethodParameter value) =>
                  value.toJson(clientUriConverter: clientUriConverter),
            )
            .toList();
    result['extractAll'] = extractAll;
    return result;
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is ExtractMethodOptions) {
      return returnType == other.returnType &&
          createGetter == other.createGetter &&
          name == other.name &&
          listEqual(
            parameters,
            other.parameters,
            (RefactoringMethodParameter a, RefactoringMethodParameter b) =>
                a == b,
          ) &&
          extractAll == other.extractAll;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
    returnType,
    createGetter,
    name,
    Object.hashAll(parameters),
    extractAll,
  );
}

/// inlineLocalVariable feedback
///
/// {
///   "name": String
///   "occurrences": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class InlineLocalVariableFeedback extends RefactoringFeedback {
  /// The name of the variable being inlined.
  String name;

  /// The number of times the variable occurs.
  int occurrences;

  InlineLocalVariableFeedback(this.name, this.occurrences);

  factory InlineLocalVariableFeedback.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString('$jsonPath.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      int occurrences;
      if (json.containsKey('occurrences')) {
        occurrences = jsonDecoder.decodeInt(
          '$jsonPath.occurrences',
          json['occurrences'],
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'occurrences');
      }
      return InlineLocalVariableFeedback(name, occurrences);
    } else {
      throw jsonDecoder.mismatch(
        jsonPath,
        'inlineLocalVariable feedback',
        json,
      );
    }
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['name'] = name;
    result['occurrences'] = occurrences;
    return result;
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is InlineLocalVariableFeedback) {
      return name == other.name && occurrences == other.occurrences;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(name, occurrences);
}

/// inlineLocalVariable options
///
/// Clients may not extend, implement or mix-in this class.
class InlineLocalVariableOptions extends RefactoringOptions
    implements HasToJson {
  @override
  bool operator ==(other) => other is InlineLocalVariableOptions;

  @override
  int get hashCode => 540364977;
}

/// inlineMethod feedback
///
/// {
///   "className": optional String
///   "methodName": String
///   "isDeclaration": bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class InlineMethodFeedback extends RefactoringFeedback {
  /// The name of the class enclosing the method being inlined. If not a class
  /// member is being inlined, this field will be absent.
  String? className;

  /// The name of the method (or function) being inlined.
  String methodName;

  /// True if the declaration of the method is selected and all references
  /// should be inlined.
  bool isDeclaration;

  InlineMethodFeedback(this.methodName, this.isDeclaration, {this.className});

  factory InlineMethodFeedback.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      String? className;
      if (json.containsKey('className')) {
        className = jsonDecoder.decodeString(
          '$jsonPath.className',
          json['className'],
        );
      }
      String methodName;
      if (json.containsKey('methodName')) {
        methodName = jsonDecoder.decodeString(
          '$jsonPath.methodName',
          json['methodName'],
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'methodName');
      }
      bool isDeclaration;
      if (json.containsKey('isDeclaration')) {
        isDeclaration = jsonDecoder.decodeBool(
          '$jsonPath.isDeclaration',
          json['isDeclaration'],
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'isDeclaration');
      }
      return InlineMethodFeedback(
        methodName,
        isDeclaration,
        className: className,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'inlineMethod feedback', json);
    }
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    var className = this.className;
    if (className != null) {
      result['className'] = className;
    }
    result['methodName'] = methodName;
    result['isDeclaration'] = isDeclaration;
    return result;
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is InlineMethodFeedback) {
      return className == other.className &&
          methodName == other.methodName &&
          isDeclaration == other.isDeclaration;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(className, methodName, isDeclaration);
}

/// inlineMethod options
///
/// {
///   "deleteSource": bool
///   "inlineAll": bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class InlineMethodOptions extends RefactoringOptions {
  /// True if the method being inlined should be removed. It is an error if
  /// this field is true and inlineAll is false.
  bool deleteSource;

  /// True if all invocations of the method should be inlined, or false if only
  /// the invocation site used to create this refactoring should be inlined.
  bool inlineAll;

  InlineMethodOptions(this.deleteSource, this.inlineAll);

  factory InlineMethodOptions.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      bool deleteSource;
      if (json.containsKey('deleteSource')) {
        deleteSource = jsonDecoder.decodeBool(
          '$jsonPath.deleteSource',
          json['deleteSource'],
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'deleteSource');
      }
      bool inlineAll;
      if (json.containsKey('inlineAll')) {
        inlineAll = jsonDecoder.decodeBool(
          '$jsonPath.inlineAll',
          json['inlineAll'],
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'inlineAll');
      }
      return InlineMethodOptions(deleteSource, inlineAll);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'inlineMethod options', json);
    }
  }

  factory InlineMethodOptions.fromRefactoringParams(
    EditGetRefactoringParams refactoringParams,
    Request request, {
    ClientUriConverter? clientUriConverter,
  }) {
    return InlineMethodOptions.fromJson(
      RequestDecoder(request),
      'options',
      refactoringParams.options,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['deleteSource'] = deleteSource;
    result['inlineAll'] = inlineAll;
    return result;
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is InlineMethodOptions) {
      return deleteSource == other.deleteSource && inlineAll == other.inlineAll;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(deleteSource, inlineAll);
}

/// moveFile feedback
///
/// Clients may not extend, implement or mix-in this class.
class MoveFileFeedback extends RefactoringFeedback implements HasToJson {
  @override
  bool operator ==(other) => other is MoveFileFeedback;

  @override
  int get hashCode => 438975893;
}

/// moveFile options
///
/// {
///   "newFile": FilePath
/// }
///
/// Clients may not extend, implement or mix-in this class.
class MoveFileOptions extends RefactoringOptions {
  /// The new file path to which the given file is being moved.
  String newFile;

  MoveFileOptions(this.newFile);

  factory MoveFileOptions.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      String newFile;
      if (json.containsKey('newFile')) {
        newFile =
            clientUriConverter?.fromClientFilePath(
              jsonDecoder.decodeString('$jsonPath.newFile', json['newFile']),
            ) ??
            jsonDecoder.decodeString('$jsonPath.newFile', json['newFile']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'newFile');
      }
      return MoveFileOptions(newFile);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'moveFile options', json);
    }
  }

  factory MoveFileOptions.fromRefactoringParams(
    EditGetRefactoringParams refactoringParams,
    Request request, {
    ClientUriConverter? clientUriConverter,
  }) {
    return MoveFileOptions.fromJson(
      RequestDecoder(request),
      'options',
      refactoringParams.options,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['newFile'] =
        clientUriConverter?.toClientFilePath(newFile) ?? newFile;
    return result;
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is MoveFileOptions) {
      return newFile == other.newFile;
    }
    return false;
  }

  @override
  int get hashCode => newFile.hashCode;
}

/// plugin.error params
///
/// {
///   "isFatal": bool
///   "message": String
///   "stackTrace": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class PluginErrorParams implements HasToJson {
  /// A flag indicating whether the error is a fatal error, meaning that the
  /// plugin will shutdown automatically after sending this notification. If
  /// true, the server will not expect any other responses or notifications
  /// from the plugin.
  bool isFatal;

  /// The error message indicating what kind of error was encountered.
  String message;

  /// The stack trace associated with the generation of the error, used for
  /// debugging the plugin.
  String stackTrace;

  PluginErrorParams(this.isFatal, this.message, this.stackTrace);

  factory PluginErrorParams.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      bool isFatal;
      if (json.containsKey('isFatal')) {
        isFatal = jsonDecoder.decodeBool('$jsonPath.isFatal', json['isFatal']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'isFatal');
      }
      String message;
      if (json.containsKey('message')) {
        message = jsonDecoder.decodeString(
          '$jsonPath.message',
          json['message'],
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'message');
      }
      String stackTrace;
      if (json.containsKey('stackTrace')) {
        stackTrace = jsonDecoder.decodeString(
          '$jsonPath.stackTrace',
          json['stackTrace'],
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'stackTrace');
      }
      return PluginErrorParams(isFatal, message, stackTrace);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'plugin.error params', json);
    }
  }

  factory PluginErrorParams.fromNotification(
    Notification notification, {
    ClientUriConverter? clientUriConverter,
  }) {
    return PluginErrorParams.fromJson(
      ResponseDecoder(null),
      'params',
      notification.params,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['isFatal'] = isFatal;
    result['message'] = message;
    result['stackTrace'] = stackTrace;
    return result;
  }

  Notification toNotification({ClientUriConverter? clientUriConverter}) {
    return Notification(
      'plugin.error',
      toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is PluginErrorParams) {
      return isFatal == other.isFatal &&
          message == other.message &&
          stackTrace == other.stackTrace;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(isFatal, message, stackTrace);
}

/// plugin.shutdown params
///
/// Clients may not extend, implement or mix-in this class.
class PluginShutdownParams implements RequestParams {
  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) => {};

  @override
  Request toRequest(String id, {ClientUriConverter? clientUriConverter}) {
    return Request(id, 'plugin.shutdown');
  }

  @override
  bool operator ==(other) => other is PluginShutdownParams;

  @override
  int get hashCode => 478064585;
}

/// plugin.shutdown result
///
/// Clients may not extend, implement or mix-in this class.
class PluginShutdownResult implements ResponseResult {
  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) => {};

  @override
  Response toResponse(
    String id,
    int requestTime, {
    ClientUriConverter? clientUriConverter,
  }) {
    return Response(id, requestTime);
  }

  @override
  bool operator ==(other) => other is PluginShutdownResult;

  @override
  int get hashCode => 9389109;
}

/// plugin.versionCheck params
///
/// {
///   "byteStorePath": FilePath
///   "sdkPath": FilePath
///   "version": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class PluginVersionCheckParams implements RequestParams {
  /// The path to the directory containing the on-disk byte store that is to be
  /// used by any analysis drivers that are created.
  String byteStorePath;

  /// The path to the directory containing the SDK that is to be used by any
  /// analysis drivers that are created.
  String sdkPath;

  /// The version number of the plugin spec supported by the analysis server
  /// that is executing the plugin.
  String version;

  PluginVersionCheckParams(this.byteStorePath, this.sdkPath, this.version);

  factory PluginVersionCheckParams.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      String byteStorePath;
      if (json.containsKey('byteStorePath')) {
        byteStorePath =
            clientUriConverter?.fromClientFilePath(
              jsonDecoder.decodeString(
                '$jsonPath.byteStorePath',
                json['byteStorePath'],
              ),
            ) ??
            jsonDecoder.decodeString(
              '$jsonPath.byteStorePath',
              json['byteStorePath'],
            );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'byteStorePath');
      }
      String sdkPath;
      if (json.containsKey('sdkPath')) {
        sdkPath =
            clientUriConverter?.fromClientFilePath(
              jsonDecoder.decodeString('$jsonPath.sdkPath', json['sdkPath']),
            ) ??
            jsonDecoder.decodeString('$jsonPath.sdkPath', json['sdkPath']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'sdkPath');
      }
      String version;
      if (json.containsKey('version')) {
        version = jsonDecoder.decodeString(
          '$jsonPath.version',
          json['version'],
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'version');
      }
      return PluginVersionCheckParams(byteStorePath, sdkPath, version);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'plugin.versionCheck params', json);
    }
  }

  factory PluginVersionCheckParams.fromRequest(
    Request request, {
    ClientUriConverter? clientUriConverter,
  }) {
    return PluginVersionCheckParams.fromJson(
      RequestDecoder(request),
      'params',
      request.params,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['byteStorePath'] =
        clientUriConverter?.toClientFilePath(byteStorePath) ?? byteStorePath;
    result['sdkPath'] =
        clientUriConverter?.toClientFilePath(sdkPath) ?? sdkPath;
    result['version'] = version;
    return result;
  }

  @override
  Request toRequest(String id, {ClientUriConverter? clientUriConverter}) {
    return Request(
      id,
      'plugin.versionCheck',
      toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is PluginVersionCheckParams) {
      return byteStorePath == other.byteStorePath &&
          sdkPath == other.sdkPath &&
          version == other.version;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(byteStorePath, sdkPath, version);
}

/// plugin.versionCheck result
///
/// {
///   "isCompatible": bool
///   "name": String
///   "version": String
///   "contactInfo": optional String
///   "interestingFiles": List<String>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class PluginVersionCheckResult implements ResponseResult {
  /// A flag indicating whether the plugin supports the same version of the
  /// plugin spec as the analysis server. If the value is false, then the
  /// plugin is expected to shutdown after returning the response.
  bool isCompatible;

  /// The name of the plugin. This value is only used when the server needs to
  /// identify the plugin, either to the user or for debugging purposes.
  String name;

  /// The version of the plugin. This value is only used when the server needs
  /// to identify the plugin, either to the user or for debugging purposes.
  String version;

  /// Information that the user can use to use to contact the maintainers of
  /// the plugin when there is a problem.
  String? contactInfo;

  /// The glob patterns of the files for which the plugin will provide
  /// information. This value is ignored if the isCompatible field is false.
  /// Otherwise, it will be used to identify the files for which the plugin
  /// should be notified of changes.
  List<String> interestingFiles;

  PluginVersionCheckResult(
    this.isCompatible,
    this.name,
    this.version,
    this.interestingFiles, {
    this.contactInfo,
  });

  factory PluginVersionCheckResult.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      bool isCompatible;
      if (json.containsKey('isCompatible')) {
        isCompatible = jsonDecoder.decodeBool(
          '$jsonPath.isCompatible',
          json['isCompatible'],
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'isCompatible');
      }
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString('$jsonPath.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      String version;
      if (json.containsKey('version')) {
        version = jsonDecoder.decodeString(
          '$jsonPath.version',
          json['version'],
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'version');
      }
      String? contactInfo;
      if (json.containsKey('contactInfo')) {
        contactInfo = jsonDecoder.decodeString(
          '$jsonPath.contactInfo',
          json['contactInfo'],
        );
      }
      List<String> interestingFiles;
      if (json.containsKey('interestingFiles')) {
        interestingFiles = jsonDecoder.decodeList(
          '$jsonPath.interestingFiles',
          json['interestingFiles'],
          jsonDecoder.decodeString,
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'interestingFiles');
      }
      return PluginVersionCheckResult(
        isCompatible,
        name,
        version,
        interestingFiles,
        contactInfo: contactInfo,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'plugin.versionCheck result', json);
    }
  }

  factory PluginVersionCheckResult.fromResponse(
    Response response, {
    ClientUriConverter? clientUriConverter,
  }) {
    return PluginVersionCheckResult.fromJson(
      ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
      'result',
      response.result,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['isCompatible'] = isCompatible;
    result['name'] = name;
    result['version'] = version;
    var contactInfo = this.contactInfo;
    if (contactInfo != null) {
      result['contactInfo'] = contactInfo;
    }
    result['interestingFiles'] = interestingFiles;
    return result;
  }

  @override
  Response toResponse(
    String id,
    int requestTime, {
    ClientUriConverter? clientUriConverter,
  }) {
    return Response(
      id,
      requestTime,
      result: toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is PluginVersionCheckResult) {
      return isCompatible == other.isCompatible &&
          name == other.name &&
          version == other.version &&
          contactInfo == other.contactInfo &&
          listEqual(
            interestingFiles,
            other.interestingFiles,
            (String a, String b) => a == b,
          );
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
    isCompatible,
    name,
    version,
    contactInfo,
    Object.hashAll(interestingFiles),
  );
}

/// PrioritizedSourceChange
///
/// {
///   "priority": int
///   "change": SourceChange
/// }
///
/// Clients may not extend, implement or mix-in this class.
class PrioritizedSourceChange implements HasToJson {
  /// The priority of the change. The value is expected to be non-negative, and
  /// zero (0) is the lowest priority.
  int priority;

  /// The change with which the relevance is associated.
  SourceChange change;

  PrioritizedSourceChange(this.priority, this.change);

  factory PrioritizedSourceChange.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      int priority;
      if (json.containsKey('priority')) {
        priority = jsonDecoder.decodeInt(
          '$jsonPath.priority',
          json['priority'],
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'priority');
      }
      SourceChange change;
      if (json.containsKey('change')) {
        change = SourceChange.fromJson(
          jsonDecoder,
          '$jsonPath.change',
          json['change'],
          clientUriConverter: clientUriConverter,
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'change');
      }
      return PrioritizedSourceChange(priority, change);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'PrioritizedSourceChange', json);
    }
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['priority'] = priority;
    result['change'] = change.toJson(clientUriConverter: clientUriConverter);
    return result;
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is PrioritizedSourceChange) {
      return priority == other.priority && change == other.change;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(priority, change);
}

/// RefactoringFeedback
///
/// {
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RefactoringFeedback implements HasToJson {
  RefactoringFeedback();

  factory RefactoringFeedback.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
    Map<Object?, Object?> responseJson, {
    ClientUriConverter? clientUriConverter,
  }) {
    return refactoringFeedbackFromJson(
      jsonDecoder,
      jsonPath,
      json,
      responseJson,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    return result;
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is RefactoringFeedback) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode => 0;
}

/// RefactoringOptions
///
/// {
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RefactoringOptions implements HasToJson {
  RefactoringOptions();

  factory RefactoringOptions.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
    RefactoringKind kind, {
    ClientUriConverter? clientUriConverter,
  }) {
    return refactoringOptionsFromJson(
      jsonDecoder,
      jsonPath,
      json,
      kind,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    return result;
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is RefactoringOptions) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode => 0;
}

/// rename feedback
///
/// {
///   "offset": int
///   "length": int
///   "elementKindName": String
///   "oldName": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RenameFeedback extends RefactoringFeedback {
  /// The offset to the beginning of the name selected to be renamed.
  int offset;

  /// The length of the name selected to be renamed.
  int length;

  /// The human-readable description of the kind of element being renamed (such
  /// as “class” or “function type alias”).
  String elementKindName;

  /// The old name of the element before the refactoring.
  String oldName;

  RenameFeedback(this.offset, this.length, this.elementKindName, this.oldName);

  factory RenameFeedback.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt('$jsonPath.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt('$jsonPath.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      String elementKindName;
      if (json.containsKey('elementKindName')) {
        elementKindName = jsonDecoder.decodeString(
          '$jsonPath.elementKindName',
          json['elementKindName'],
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'elementKindName');
      }
      String oldName;
      if (json.containsKey('oldName')) {
        oldName = jsonDecoder.decodeString(
          '$jsonPath.oldName',
          json['oldName'],
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'oldName');
      }
      return RenameFeedback(offset, length, elementKindName, oldName);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'rename feedback', json);
    }
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['offset'] = offset;
    result['length'] = length;
    result['elementKindName'] = elementKindName;
    result['oldName'] = oldName;
    return result;
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is RenameFeedback) {
      return offset == other.offset &&
          length == other.length &&
          elementKindName == other.elementKindName &&
          oldName == other.oldName;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(offset, length, elementKindName, oldName);
}

/// rename options
///
/// {
///   "newName": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RenameOptions extends RefactoringOptions {
  /// The name that the element should have after the refactoring.
  String newName;

  RenameOptions(this.newName);

  factory RenameOptions.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      String newName;
      if (json.containsKey('newName')) {
        newName = jsonDecoder.decodeString(
          '$jsonPath.newName',
          json['newName'],
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'newName');
      }
      return RenameOptions(newName);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'rename options', json);
    }
  }

  factory RenameOptions.fromRefactoringParams(
    EditGetRefactoringParams refactoringParams,
    Request request, {
    ClientUriConverter? clientUriConverter,
  }) {
    return RenameOptions.fromJson(
      RequestDecoder(request),
      'options',
      refactoringParams.options,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['newName'] = newName;
    return result;
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is RenameOptions) {
      return newName == other.newName;
    }
    return false;
  }

  @override
  int get hashCode => newName.hashCode;
}

/// RequestError
///
/// {
///   "code": RequestErrorCode
///   "message": String
///   "stackTrace": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RequestError implements HasToJson {
  /// A code that uniquely identifies the error that occurred.
  RequestErrorCode code;

  /// A short description of the error.
  String message;

  /// The stack trace associated with processing the request, used for
  /// debugging the plugin.
  String? stackTrace;

  RequestError(this.code, this.message, {this.stackTrace});

  factory RequestError.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      RequestErrorCode code;
      if (json.containsKey('code')) {
        code = RequestErrorCode.fromJson(
          jsonDecoder,
          '$jsonPath.code',
          json['code'],
          clientUriConverter: clientUriConverter,
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'code');
      }
      String message;
      if (json.containsKey('message')) {
        message = jsonDecoder.decodeString(
          '$jsonPath.message',
          json['message'],
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'message');
      }
      String? stackTrace;
      if (json.containsKey('stackTrace')) {
        stackTrace = jsonDecoder.decodeString(
          '$jsonPath.stackTrace',
          json['stackTrace'],
        );
      }
      return RequestError(code, message, stackTrace: stackTrace);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'RequestError', json);
    }
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['code'] = code.toJson(clientUriConverter: clientUriConverter);
    result['message'] = message;
    var stackTrace = this.stackTrace;
    if (stackTrace != null) {
      result['stackTrace'] = stackTrace;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is RequestError) {
      return code == other.code &&
          message == other.message &&
          stackTrace == other.stackTrace;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(code, message, stackTrace);
}

/// RequestErrorCode
///
/// enum {
///   INVALID_OVERLAY_CHANGE
///   INVALID_PARAMETER
///   PLUGIN_ERROR
///   UNKNOWN_REQUEST
/// }
///
/// Clients may not extend, implement or mix-in this class.
enum RequestErrorCode {
  /// An "analysis.updateContent" request contained a ChangeContentOverlay
  /// object that can't be applied. This can happen for two reasons:
  ///
  /// - there was no preceding AddContentOverlay and hence no content to which
  ///   the edits could be applied, or
  /// - one or more of the specified edits have an offset or length that is out
  ///   of range.
  INVALID_OVERLAY_CHANGE,

  /// One of the method parameters was invalid.
  INVALID_PARAMETER,

  /// An internal error occurred in the plugin while attempting to respond to a
  /// request. Also see the plugin.error notification for errors that occur
  /// outside of handling a request.
  PLUGIN_ERROR,

  /// A request was received that the plugin does not recognize, or cannot
  /// handle in its current configuration.
  UNKNOWN_REQUEST;

  factory RequestErrorCode.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    if (json is String) {
      try {
        return values.byName(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'RequestErrorCode', json);
  }

  @override
  String toString() => 'RequestErrorCode.$name';

  String toJson({ClientUriConverter? clientUriConverter}) => name;
}

/// WatchEvent
///
/// {
///   "type": WatchEventType
///   "path": FilePath
/// }
///
/// Clients may not extend, implement or mix-in this class.
class WatchEvent implements HasToJson {
  /// The type of change represented by this event.
  WatchEventType type;

  /// The absolute path of the file or directory that changed.
  String path;

  WatchEvent(this.type, this.path);

  factory WatchEvent.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is Map) {
      WatchEventType type;
      if (json.containsKey('type')) {
        type = WatchEventType.fromJson(
          jsonDecoder,
          '$jsonPath.type',
          json['type'],
          clientUriConverter: clientUriConverter,
        );
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'type');
      }
      String path;
      if (json.containsKey('path')) {
        path =
            clientUriConverter?.fromClientFilePath(
              jsonDecoder.decodeString('$jsonPath.path', json['path']),
            ) ??
            jsonDecoder.decodeString('$jsonPath.path', json['path']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'path');
      }
      return WatchEvent(type, path);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'WatchEvent', json);
    }
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['type'] = type.toJson(clientUriConverter: clientUriConverter);
    result['path'] = clientUriConverter?.toClientFilePath(path) ?? path;
    return result;
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is WatchEvent) {
      return type == other.type && path == other.path;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(type, path);
}

/// WatchEventType
///
/// enum {
///   ADD
///   MODIFY
///   REMOVE
/// }
///
/// Clients may not extend, implement or mix-in this class.
enum WatchEventType {
  /// An indication that the file or directory was added.
  ADD,

  /// An indication that the file was modified.
  MODIFY,

  /// An indication that the file or directory was removed.
  REMOVE;

  factory WatchEventType.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    if (json is String) {
      try {
        return values.byName(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'WatchEventType', json);
  }

  @override
  String toString() => 'WatchEventType.$name';

  String toJson({ClientUriConverter? clientUriConverter}) => name;
}
