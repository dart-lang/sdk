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
///     {
///       "error": AnalysisError
///       "fixes": List<PrioritizedSourceChange>
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'AnalysisErrorFixes'", json);
    }
    AnalysisError error;
    if (json case {'error': var encodedError}) {
      error = AnalysisError.fromJson(
        jsonDecoder,
        '$jsonPath.error',
        encodedError,
        clientUriConverter: clientUriConverter,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'error'", json);
    }
    List<PrioritizedSourceChange> fixes;
    if (json case {'fixes': var encodedFixes}) {
      fixes = jsonDecoder.decodeList(
        '$jsonPath.fixes',
        encodedFixes,
        (String jsonPath, Object? json) => PrioritizedSourceChange.fromJson(
          jsonDecoder,
          jsonPath,
          json,
          clientUriConverter: clientUriConverter,
        ),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'fixes'", json);
    }
    return AnalysisErrorFixes(error, fixes: fixes);
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['error'] = error.toJson(clientUriConverter: clientUriConverter);
    result['fixes'] = fixes
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
///     {
///       "file": FilePath
///       "errors": List<AnalysisError>
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'analysis.errors params'", json);
    }
    String file;
    if (json case {'file': var encodedFile}) {
      file =
          clientUriConverter?.fromClientFilePath(
            jsonDecoder.decodeString('$jsonPath.file', encodedFile),
          ) ??
          jsonDecoder.decodeString('$jsonPath.file', encodedFile);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'file'", json);
    }
    List<AnalysisError> errors;
    if (json case {'errors': var encodedErrors}) {
      errors = jsonDecoder.decodeList(
        '$jsonPath.errors',
        encodedErrors,
        (String jsonPath, Object? json) => AnalysisError.fromJson(
          jsonDecoder,
          jsonPath,
          json,
          clientUriConverter: clientUriConverter,
        ),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'errors'", json);
    }
    return AnalysisErrorsParams(file, errors);
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
    result['errors'] = errors
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
///     {
///       "file": FilePath
///       "regions": List<FoldingRegion>
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'analysis.folding params'", json);
    }
    String file;
    if (json case {'file': var encodedFile}) {
      file =
          clientUriConverter?.fromClientFilePath(
            jsonDecoder.decodeString('$jsonPath.file', encodedFile),
          ) ??
          jsonDecoder.decodeString('$jsonPath.file', encodedFile);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'file'", json);
    }
    List<FoldingRegion> regions;
    if (json case {'regions': var encodedRegions}) {
      regions = jsonDecoder.decodeList(
        '$jsonPath.regions',
        encodedRegions,
        (String jsonPath, Object? json) => FoldingRegion.fromJson(
          jsonDecoder,
          jsonPath,
          json,
          clientUriConverter: clientUriConverter,
        ),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'regions'", json);
    }
    return AnalysisFoldingParams(file, regions);
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
    result['regions'] = regions
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
///     {
///       "file": FilePath
///       "offset": int
///       "length": int
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(
        jsonPath,
        "'analysis.getNavigation params'",
        json,
      );
    }
    String file;
    if (json case {'file': var encodedFile}) {
      file =
          clientUriConverter?.fromClientFilePath(
            jsonDecoder.decodeString('$jsonPath.file', encodedFile),
          ) ??
          jsonDecoder.decodeString('$jsonPath.file', encodedFile);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'file'", json);
    }
    int offset;
    if (json case {'offset': var encodedOffset}) {
      offset = jsonDecoder.decodeInt('$jsonPath.offset', encodedOffset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'offset'", json);
    }
    int length;
    if (json case {'length': var encodedLength}) {
      length = jsonDecoder.decodeInt('$jsonPath.length', encodedLength);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'length'", json);
    }
    return AnalysisGetNavigationParams(file, offset, length);
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
///     {
///       "files": List<FilePath>
///       "targets": List<NavigationTarget>
///       "regions": List<NavigationRegion>
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(
        jsonPath,
        "'analysis.getNavigation result'",
        json,
      );
    }
    List<String> files;
    if (json case {'files': var encodedFiles}) {
      files = jsonDecoder.decodeList(
        '$jsonPath.files',
        encodedFiles,
        (String jsonPath, Object? json) =>
            clientUriConverter?.fromClientFilePath(
              jsonDecoder.decodeString(jsonPath, json),
            ) ??
            jsonDecoder.decodeString(jsonPath, json),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'files'", json);
    }
    List<NavigationTarget> targets;
    if (json case {'targets': var encodedTargets}) {
      targets = jsonDecoder.decodeList(
        '$jsonPath.targets',
        encodedTargets,
        (String jsonPath, Object? json) => NavigationTarget.fromJson(
          jsonDecoder,
          jsonPath,
          json,
          clientUriConverter: clientUriConverter,
        ),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'targets'", json);
    }
    List<NavigationRegion> regions;
    if (json case {'regions': var encodedRegions}) {
      regions = jsonDecoder.decodeList(
        '$jsonPath.regions',
        encodedRegions,
        (String jsonPath, Object? json) => NavigationRegion.fromJson(
          jsonDecoder,
          jsonPath,
          json,
          clientUriConverter: clientUriConverter,
        ),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'regions'", json);
    }
    return AnalysisGetNavigationResult(files, targets, regions);
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
    result['files'] = files
        .map(
          (String value) =>
              clientUriConverter?.toClientFilePath(value) ?? value,
        )
        .toList();
    result['targets'] = targets
        .map(
          (NavigationTarget value) =>
              value.toJson(clientUriConverter: clientUriConverter),
        )
        .toList();
    result['regions'] = regions
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
///     {
///       "events": List<WatchEvent>
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(
        jsonPath,
        "'analysis.handleWatchEvents params'",
        json,
      );
    }
    List<WatchEvent> events;
    if (json case {'events': var encodedEvents}) {
      events = jsonDecoder.decodeList(
        '$jsonPath.events',
        encodedEvents,
        (String jsonPath, Object? json) => WatchEvent.fromJson(
          jsonDecoder,
          jsonPath,
          json,
          clientUriConverter: clientUriConverter,
        ),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'events'", json);
    }
    return AnalysisHandleWatchEventsParams(events);
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
    result['events'] = events
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
///     {
///       "file": FilePath
///       "regions": List<HighlightRegion>
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(
        jsonPath,
        "'analysis.highlights params'",
        json,
      );
    }
    String file;
    if (json case {'file': var encodedFile}) {
      file =
          clientUriConverter?.fromClientFilePath(
            jsonDecoder.decodeString('$jsonPath.file', encodedFile),
          ) ??
          jsonDecoder.decodeString('$jsonPath.file', encodedFile);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'file'", json);
    }
    List<HighlightRegion> regions;
    if (json case {'regions': var encodedRegions}) {
      regions = jsonDecoder.decodeList(
        '$jsonPath.regions',
        encodedRegions,
        (String jsonPath, Object? json) => HighlightRegion.fromJson(
          jsonDecoder,
          jsonPath,
          json,
          clientUriConverter: clientUriConverter,
        ),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'regions'", json);
    }
    return AnalysisHighlightsParams(file, regions);
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
    result['regions'] = regions
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
///     {
///       "file": FilePath
///       "regions": List<NavigationRegion>
///       "targets": List<NavigationTarget>
///       "files": List<FilePath>
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(
        jsonPath,
        "'analysis.navigation params'",
        json,
      );
    }
    String file;
    if (json case {'file': var encodedFile}) {
      file =
          clientUriConverter?.fromClientFilePath(
            jsonDecoder.decodeString('$jsonPath.file', encodedFile),
          ) ??
          jsonDecoder.decodeString('$jsonPath.file', encodedFile);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'file'", json);
    }
    List<NavigationRegion> regions;
    if (json case {'regions': var encodedRegions}) {
      regions = jsonDecoder.decodeList(
        '$jsonPath.regions',
        encodedRegions,
        (String jsonPath, Object? json) => NavigationRegion.fromJson(
          jsonDecoder,
          jsonPath,
          json,
          clientUriConverter: clientUriConverter,
        ),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'regions'", json);
    }
    List<NavigationTarget> targets;
    if (json case {'targets': var encodedTargets}) {
      targets = jsonDecoder.decodeList(
        '$jsonPath.targets',
        encodedTargets,
        (String jsonPath, Object? json) => NavigationTarget.fromJson(
          jsonDecoder,
          jsonPath,
          json,
          clientUriConverter: clientUriConverter,
        ),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'targets'", json);
    }
    List<String> files;
    if (json case {'files': var encodedFiles}) {
      files = jsonDecoder.decodeList(
        '$jsonPath.files',
        encodedFiles,
        (String jsonPath, Object? json) =>
            clientUriConverter?.fromClientFilePath(
              jsonDecoder.decodeString(jsonPath, json),
            ) ??
            jsonDecoder.decodeString(jsonPath, json),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'files'", json);
    }
    return AnalysisNavigationParams(file, regions, targets, files);
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
    result['regions'] = regions
        .map(
          (NavigationRegion value) =>
              value.toJson(clientUriConverter: clientUriConverter),
        )
        .toList();
    result['targets'] = targets
        .map(
          (NavigationTarget value) =>
              value.toJson(clientUriConverter: clientUriConverter),
        )
        .toList();
    result['files'] = files
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
///     {
///       "file": FilePath
///       "occurrences": List<Occurrences>
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(
        jsonPath,
        "'analysis.occurrences params'",
        json,
      );
    }
    String file;
    if (json case {'file': var encodedFile}) {
      file =
          clientUriConverter?.fromClientFilePath(
            jsonDecoder.decodeString('$jsonPath.file', encodedFile),
          ) ??
          jsonDecoder.decodeString('$jsonPath.file', encodedFile);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'file'", json);
    }
    List<Occurrences> occurrences;
    if (json case {'occurrences': var encodedOccurrences}) {
      occurrences = jsonDecoder.decodeList(
        '$jsonPath.occurrences',
        encodedOccurrences,
        (String jsonPath, Object? json) => Occurrences.fromJson(
          jsonDecoder,
          jsonPath,
          json,
          clientUriConverter: clientUriConverter,
        ),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'occurrences'", json);
    }
    return AnalysisOccurrencesParams(file, occurrences);
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
    result['occurrences'] = occurrences
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
///     {
///       "file": FilePath
///       "outline": List<Outline>
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'analysis.outline params'", json);
    }
    String file;
    if (json case {'file': var encodedFile}) {
      file =
          clientUriConverter?.fromClientFilePath(
            jsonDecoder.decodeString('$jsonPath.file', encodedFile),
          ) ??
          jsonDecoder.decodeString('$jsonPath.file', encodedFile);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'file'", json);
    }
    List<Outline> outline;
    if (json case {'outline': var encodedOutline}) {
      outline = jsonDecoder.decodeList(
        '$jsonPath.outline',
        encodedOutline,
        (String jsonPath, Object? json) => Outline.fromJson(
          jsonDecoder,
          jsonPath,
          json,
          clientUriConverter: clientUriConverter,
        ),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'outline'", json);
    }
    return AnalysisOutlineParams(file, outline);
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
    result['outline'] = outline
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
///     enum {
///       FOLDING
///       HIGHLIGHTS
///       NAVIGATION
///       OCCURRENCES
///       OUTLINE
///     }
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
    throw jsonDecoder.mismatch(jsonPath, "'AnalysisService'", json);
  }

  @override
  String toString() => 'AnalysisService.$name';

  String toJson({ClientUriConverter? clientUriConverter}) => name;
}

/// analysis.setContextRoots params
///
///     {
///       "roots": List<ContextRoot>
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(
        jsonPath,
        "'analysis.setContextRoots params'",
        json,
      );
    }
    List<ContextRoot> roots;
    if (json case {'roots': var encodedRoots}) {
      roots = jsonDecoder.decodeList(
        '$jsonPath.roots',
        encodedRoots,
        (String jsonPath, Object? json) => ContextRoot.fromJson(
          jsonDecoder,
          jsonPath,
          json,
          clientUriConverter: clientUriConverter,
        ),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'roots'", json);
    }
    return AnalysisSetContextRootsParams(roots);
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
    result['roots'] = roots
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
///     {
///       "files": List<FilePath>
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(
        jsonPath,
        "'analysis.setPriorityFiles params'",
        json,
      );
    }
    List<String> files;
    if (json case {'files': var encodedFiles}) {
      files = jsonDecoder.decodeList(
        '$jsonPath.files',
        encodedFiles,
        (String jsonPath, Object? json) =>
            clientUriConverter?.fromClientFilePath(
              jsonDecoder.decodeString(jsonPath, json),
            ) ??
            jsonDecoder.decodeString(jsonPath, json),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'files'", json);
    }
    return AnalysisSetPriorityFilesParams(files);
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
    result['files'] = files
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
///     {
///       "subscriptions": Map<AnalysisService, List<FilePath>>
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(
        jsonPath,
        "'analysis.setSubscriptions params'",
        json,
      );
    }
    Map<AnalysisService, List<String>> subscriptions;
    if (json case {'subscriptions': var encodedSubscriptions}) {
      subscriptions = jsonDecoder.decodeMap(
        '$jsonPath.subscriptions',
        encodedSubscriptions,
        keyDecoder: (String jsonPath, Object? json) => AnalysisService.fromJson(
          jsonDecoder,
          jsonPath,
          json,
          clientUriConverter: clientUriConverter,
        ),
        valueDecoder: (String jsonPath, Object? json) => jsonDecoder.decodeList(
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
      throw jsonDecoder.mismatch(jsonPath, "'subscriptions'", json);
    }
    return AnalysisSetSubscriptionsParams(subscriptions);
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
      keyCallback: (AnalysisService value) =>
          value.toJson(clientUriConverter: clientUriConverter),
      valueCallback: (List<String> value) => value
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

/// AnalysisStatus
///
///     {
///       "isAnalyzing": bool
///     }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisStatus implements HasToJson {
  /// True if analysis is currently being performed.
  bool isAnalyzing;

  AnalysisStatus(this.isAnalyzing);

  factory AnalysisStatus.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'AnalysisStatus'", json);
    }
    bool isAnalyzing;
    if (json case {'isAnalyzing': var encodedIsAnalyzing}) {
      isAnalyzing = jsonDecoder.decodeBool(
        '$jsonPath.isAnalyzing',
        encodedIsAnalyzing,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'isAnalyzing'", json);
    }
    return AnalysisStatus(isAnalyzing);
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['isAnalyzing'] = isAnalyzing;
    return result;
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is AnalysisStatus) {
      return isAnalyzing == other.isAnalyzing;
    }
    return false;
  }

  @override
  int get hashCode => isAnalyzing.hashCode;
}

/// analysis.updateContent params
///
///     {
///       "files": Map<FilePath, AddContentOverlay | ChangeContentOverlay | RemoveContentOverlay>
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(
        jsonPath,
        "'analysis.updateContent params'",
        json,
      );
    }
    Map<String, Object> files;
    if (json case {'files': var encodedFiles}) {
      files = jsonDecoder.decodeMap(
        '$jsonPath.files',
        encodedFiles,
        keyDecoder: (String jsonPath, Object? json) =>
            clientUriConverter?.fromClientFilePath(
              jsonDecoder.decodeString(jsonPath, json),
            ) ??
            jsonDecoder.decodeString(jsonPath, json),
        valueDecoder: (String jsonPath, Object? json) =>
            jsonDecoder.decodeUnion(jsonPath, json, 'type', {
              'add': (String jsonPath, Object? json) =>
                  AddContentOverlay.fromJson(
                    jsonDecoder,
                    jsonPath,
                    json,
                    clientUriConverter: clientUriConverter,
                  ),
              'change': (String jsonPath, Object? json) =>
                  ChangeContentOverlay.fromJson(
                    jsonDecoder,
                    jsonPath,
                    json,
                    clientUriConverter: clientUriConverter,
                  ),
              'remove': (String jsonPath, Object? json) =>
                  RemoveContentOverlay.fromJson(
                    jsonDecoder,
                    jsonPath,
                    json,
                    clientUriConverter: clientUriConverter,
                  ),
            }),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'files'", json);
    }
    return AnalysisUpdateContentParams(files);
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
      keyCallback: (String value) =>
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
///     {
///       "file": FilePath
///       "offset": int
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(
        jsonPath,
        "'completion.getSuggestions params'",
        json,
      );
    }
    String file;
    if (json case {'file': var encodedFile}) {
      file =
          clientUriConverter?.fromClientFilePath(
            jsonDecoder.decodeString('$jsonPath.file', encodedFile),
          ) ??
          jsonDecoder.decodeString('$jsonPath.file', encodedFile);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'file'", json);
    }
    int offset;
    if (json case {'offset': var encodedOffset}) {
      offset = jsonDecoder.decodeInt('$jsonPath.offset', encodedOffset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'offset'", json);
    }
    return CompletionGetSuggestionsParams(file, offset);
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
///     {
///       "replacementOffset": int
///       "replacementLength": int
///       "results": List<CompletionSuggestion>
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(
        jsonPath,
        "'completion.getSuggestions result'",
        json,
      );
    }
    int replacementOffset;
    if (json case {'replacementOffset': var encodedReplacementOffset}) {
      replacementOffset = jsonDecoder.decodeInt(
        '$jsonPath.replacementOffset',
        encodedReplacementOffset,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'replacementOffset'", json);
    }
    int replacementLength;
    if (json case {'replacementLength': var encodedReplacementLength}) {
      replacementLength = jsonDecoder.decodeInt(
        '$jsonPath.replacementLength',
        encodedReplacementLength,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'replacementLength'", json);
    }
    List<CompletionSuggestion> results;
    if (json case {'results': var encodedResults}) {
      results = jsonDecoder.decodeList(
        '$jsonPath.results',
        encodedResults,
        (String jsonPath, Object? json) => CompletionSuggestion.fromJson(
          jsonDecoder,
          jsonPath,
          json,
          clientUriConverter: clientUriConverter,
        ),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'results'", json);
    }
    return CompletionGetSuggestionsResult(
      replacementOffset,
      replacementLength,
      results,
    );
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
    result['results'] = results
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
///     {
///       "root": FilePath
///       "exclude": List<FilePath>
///       "optionsFile": optional FilePath
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'ContextRoot'", json);
    }
    String root;
    if (json case {'root': var encodedRoot}) {
      root =
          clientUriConverter?.fromClientFilePath(
            jsonDecoder.decodeString('$jsonPath.root', encodedRoot),
          ) ??
          jsonDecoder.decodeString('$jsonPath.root', encodedRoot);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'root'", json);
    }
    List<String> exclude;
    if (json case {'exclude': var encodedExclude}) {
      exclude = jsonDecoder.decodeList(
        '$jsonPath.exclude',
        encodedExclude,
        (String jsonPath, Object? json) =>
            clientUriConverter?.fromClientFilePath(
              jsonDecoder.decodeString(jsonPath, json),
            ) ??
            jsonDecoder.decodeString(jsonPath, json),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'exclude'", json);
    }
    String? optionsFile;
    if (json case {'optionsFile': var encodedOptionsFile}) {
      optionsFile =
          clientUriConverter?.fromClientFilePath(
            jsonDecoder.decodeString(
              '$jsonPath.optionsFile',
              encodedOptionsFile,
            ),
          ) ??
          jsonDecoder.decodeString('$jsonPath.optionsFile', encodedOptionsFile);
    }
    return ContextRoot(root, exclude, optionsFile: optionsFile);
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['root'] = clientUriConverter?.toClientFilePath(root) ?? root;
    result['exclude'] = exclude
        .map(
          (String value) =>
              clientUriConverter?.toClientFilePath(value) ?? value,
        )
        .toList();
    if (optionsFile case var optionsFile?) {
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
///     {
///       "file": FilePath
///       "offset": int
///       "length": int
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'edit.getAssists params'", json);
    }
    String file;
    if (json case {'file': var encodedFile}) {
      file =
          clientUriConverter?.fromClientFilePath(
            jsonDecoder.decodeString('$jsonPath.file', encodedFile),
          ) ??
          jsonDecoder.decodeString('$jsonPath.file', encodedFile);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'file'", json);
    }
    int offset;
    if (json case {'offset': var encodedOffset}) {
      offset = jsonDecoder.decodeInt('$jsonPath.offset', encodedOffset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'offset'", json);
    }
    int length;
    if (json case {'length': var encodedLength}) {
      length = jsonDecoder.decodeInt('$jsonPath.length', encodedLength);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'length'", json);
    }
    return EditGetAssistsParams(file, offset, length);
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
///     {
///       "assists": List<PrioritizedSourceChange>
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'edit.getAssists result'", json);
    }
    List<PrioritizedSourceChange> assists;
    if (json case {'assists': var encodedAssists}) {
      assists = jsonDecoder.decodeList(
        '$jsonPath.assists',
        encodedAssists,
        (String jsonPath, Object? json) => PrioritizedSourceChange.fromJson(
          jsonDecoder,
          jsonPath,
          json,
          clientUriConverter: clientUriConverter,
        ),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'assists'", json);
    }
    return EditGetAssistsResult(assists);
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
    result['assists'] = assists
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
///     {
///       "file": FilePath
///       "offset": int
///       "length": int
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(
        jsonPath,
        "'edit.getAvailableRefactorings params'",
        json,
      );
    }
    String file;
    if (json case {'file': var encodedFile}) {
      file =
          clientUriConverter?.fromClientFilePath(
            jsonDecoder.decodeString('$jsonPath.file', encodedFile),
          ) ??
          jsonDecoder.decodeString('$jsonPath.file', encodedFile);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'file'", json);
    }
    int offset;
    if (json case {'offset': var encodedOffset}) {
      offset = jsonDecoder.decodeInt('$jsonPath.offset', encodedOffset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'offset'", json);
    }
    int length;
    if (json case {'length': var encodedLength}) {
      length = jsonDecoder.decodeInt('$jsonPath.length', encodedLength);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'length'", json);
    }
    return EditGetAvailableRefactoringsParams(file, offset, length);
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
///     {
///       "kinds": List<RefactoringKind>
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(
        jsonPath,
        "'edit.getAvailableRefactorings result'",
        json,
      );
    }
    List<RefactoringKind> kinds;
    if (json case {'kinds': var encodedKinds}) {
      kinds = jsonDecoder.decodeList(
        '$jsonPath.kinds',
        encodedKinds,
        (String jsonPath, Object? json) => RefactoringKind.fromJson(
          jsonDecoder,
          jsonPath,
          json,
          clientUriConverter: clientUriConverter,
        ),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'kinds'", json);
    }
    return EditGetAvailableRefactoringsResult(kinds);
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
    result['kinds'] = kinds
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
///     {
///       "file": FilePath
///       "offset": int
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'edit.getFixes params'", json);
    }
    String file;
    if (json case {'file': var encodedFile}) {
      file =
          clientUriConverter?.fromClientFilePath(
            jsonDecoder.decodeString('$jsonPath.file', encodedFile),
          ) ??
          jsonDecoder.decodeString('$jsonPath.file', encodedFile);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'file'", json);
    }
    int offset;
    if (json case {'offset': var encodedOffset}) {
      offset = jsonDecoder.decodeInt('$jsonPath.offset', encodedOffset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'offset'", json);
    }
    return EditGetFixesParams(file, offset);
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
///     {
///       "fixes": List<AnalysisErrorFixes>
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'edit.getFixes result'", json);
    }
    List<AnalysisErrorFixes> fixes;
    if (json case {'fixes': var encodedFixes}) {
      fixes = jsonDecoder.decodeList(
        '$jsonPath.fixes',
        encodedFixes,
        (String jsonPath, Object? json) => AnalysisErrorFixes.fromJson(
          jsonDecoder,
          jsonPath,
          json,
          clientUriConverter: clientUriConverter,
        ),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'fixes'", json);
    }
    return EditGetFixesResult(fixes);
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
    result['fixes'] = fixes
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
///     {
///       "kind": RefactoringKind
///       "file": FilePath
///       "offset": int
///       "length": int
///       "validateOnly": bool
///       "options": optional RefactoringOptions
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(
        jsonPath,
        "'edit.getRefactoring params'",
        json,
      );
    }
    RefactoringKind kind;
    if (json case {'kind': var encodedKind}) {
      kind = RefactoringKind.fromJson(
        jsonDecoder,
        '$jsonPath.kind',
        encodedKind,
        clientUriConverter: clientUriConverter,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'kind'", json);
    }
    String file;
    if (json case {'file': var encodedFile}) {
      file =
          clientUriConverter?.fromClientFilePath(
            jsonDecoder.decodeString('$jsonPath.file', encodedFile),
          ) ??
          jsonDecoder.decodeString('$jsonPath.file', encodedFile);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'file'", json);
    }
    int offset;
    if (json case {'offset': var encodedOffset}) {
      offset = jsonDecoder.decodeInt('$jsonPath.offset', encodedOffset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'offset'", json);
    }
    int length;
    if (json case {'length': var encodedLength}) {
      length = jsonDecoder.decodeInt('$jsonPath.length', encodedLength);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'length'", json);
    }
    bool validateOnly;
    if (json case {'validateOnly': var encodedValidateOnly}) {
      validateOnly = jsonDecoder.decodeBool(
        '$jsonPath.validateOnly',
        encodedValidateOnly,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'validateOnly'", json);
    }
    RefactoringOptions? options;
    if (json case {'options': var encodedOptions}) {
      options = RefactoringOptions.fromJson(
        jsonDecoder,
        '$jsonPath.options',
        encodedOptions,
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
    if (options case var options?) {
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
///     {
///       "initialProblems": List<RefactoringProblem>
///       "optionsProblems": List<RefactoringProblem>
///       "finalProblems": List<RefactoringProblem>
///       "feedback": optional RefactoringFeedback
///       "change": optional SourceChange
///       "potentialEdits": optional List<String>
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(
        jsonPath,
        "'edit.getRefactoring result'",
        json,
      );
    }
    List<RefactoringProblem> initialProblems;
    if (json case {'initialProblems': var encodedInitialProblems}) {
      initialProblems = jsonDecoder.decodeList(
        '$jsonPath.initialProblems',
        encodedInitialProblems,
        (String jsonPath, Object? json) => RefactoringProblem.fromJson(
          jsonDecoder,
          jsonPath,
          json,
          clientUriConverter: clientUriConverter,
        ),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'initialProblems'", json);
    }
    List<RefactoringProblem> optionsProblems;
    if (json case {'optionsProblems': var encodedOptionsProblems}) {
      optionsProblems = jsonDecoder.decodeList(
        '$jsonPath.optionsProblems',
        encodedOptionsProblems,
        (String jsonPath, Object? json) => RefactoringProblem.fromJson(
          jsonDecoder,
          jsonPath,
          json,
          clientUriConverter: clientUriConverter,
        ),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'optionsProblems'", json);
    }
    List<RefactoringProblem> finalProblems;
    if (json case {'finalProblems': var encodedFinalProblems}) {
      finalProblems = jsonDecoder.decodeList(
        '$jsonPath.finalProblems',
        encodedFinalProblems,
        (String jsonPath, Object? json) => RefactoringProblem.fromJson(
          jsonDecoder,
          jsonPath,
          json,
          clientUriConverter: clientUriConverter,
        ),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'finalProblems'", json);
    }
    RefactoringFeedback? feedback;
    if (json case {'feedback': var encodedFeedback}) {
      feedback = RefactoringFeedback.fromJson(
        jsonDecoder,
        '$jsonPath.feedback',
        encodedFeedback,
        json,
        clientUriConverter: clientUriConverter,
      );
    }
    SourceChange? change;
    if (json case {'change': var encodedChange}) {
      change = SourceChange.fromJson(
        jsonDecoder,
        '$jsonPath.change',
        encodedChange,
        clientUriConverter: clientUriConverter,
      );
    }
    List<String>? potentialEdits;
    if (json case {'potentialEdits': var encodedPotentialEdits}) {
      potentialEdits = jsonDecoder.decodeList(
        '$jsonPath.potentialEdits',
        encodedPotentialEdits,
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
    result['initialProblems'] = initialProblems
        .map(
          (RefactoringProblem value) =>
              value.toJson(clientUriConverter: clientUriConverter),
        )
        .toList();
    result['optionsProblems'] = optionsProblems
        .map(
          (RefactoringProblem value) =>
              value.toJson(clientUriConverter: clientUriConverter),
        )
        .toList();
    result['finalProblems'] = finalProblems
        .map(
          (RefactoringProblem value) =>
              value.toJson(clientUriConverter: clientUriConverter),
        )
        .toList();
    if (feedback case var feedback?) {
      result['feedback'] = feedback.toJson(
        clientUriConverter: clientUriConverter,
      );
    }
    if (change case var change?) {
      result['change'] = change.toJson(clientUriConverter: clientUriConverter);
    }
    if (potentialEdits case var potentialEdits?) {
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
///     {
///       "coveringExpressionOffsets": optional List<int>
///       "coveringExpressionLengths": optional List<int>
///       "names": List<String>
///       "offsets": List<int>
///       "lengths": List<int>
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(
        jsonPath,
        "'extractLocalVariable feedback'",
        json,
      );
    }
    List<int>? coveringExpressionOffsets;
    if (json case {
      'coveringExpressionOffsets': var encodedCoveringExpressionOffsets,
    }) {
      coveringExpressionOffsets = jsonDecoder.decodeList(
        '$jsonPath.coveringExpressionOffsets',
        encodedCoveringExpressionOffsets,
        jsonDecoder.decodeInt,
      );
    }
    List<int>? coveringExpressionLengths;
    if (json case {
      'coveringExpressionLengths': var encodedCoveringExpressionLengths,
    }) {
      coveringExpressionLengths = jsonDecoder.decodeList(
        '$jsonPath.coveringExpressionLengths',
        encodedCoveringExpressionLengths,
        jsonDecoder.decodeInt,
      );
    }
    List<String> names;
    if (json case {'names': var encodedNames}) {
      names = jsonDecoder.decodeList(
        '$jsonPath.names',
        encodedNames,
        jsonDecoder.decodeString,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'names'", json);
    }
    List<int> offsets;
    if (json case {'offsets': var encodedOffsets}) {
      offsets = jsonDecoder.decodeList(
        '$jsonPath.offsets',
        encodedOffsets,
        jsonDecoder.decodeInt,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'offsets'", json);
    }
    List<int> lengths;
    if (json case {'lengths': var encodedLengths}) {
      lengths = jsonDecoder.decodeList(
        '$jsonPath.lengths',
        encodedLengths,
        jsonDecoder.decodeInt,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'lengths'", json);
    }
    return ExtractLocalVariableFeedback(
      names,
      offsets,
      lengths,
      coveringExpressionOffsets: coveringExpressionOffsets,
      coveringExpressionLengths: coveringExpressionLengths,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    if (coveringExpressionOffsets case var coveringExpressionOffsets?) {
      result['coveringExpressionOffsets'] = coveringExpressionOffsets;
    }
    if (coveringExpressionLengths case var coveringExpressionLengths?) {
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
///     {
///       "name": String
///       "extractAll": bool
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(
        jsonPath,
        "'extractLocalVariable options'",
        json,
      );
    }
    String name;
    if (json case {'name': var encodedName}) {
      name = jsonDecoder.decodeString('$jsonPath.name', encodedName);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'name'", json);
    }
    bool extractAll;
    if (json case {'extractAll': var encodedExtractAll}) {
      extractAll = jsonDecoder.decodeBool(
        '$jsonPath.extractAll',
        encodedExtractAll,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'extractAll'", json);
    }
    return ExtractLocalVariableOptions(name, extractAll);
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
///     {
///       "offset": int
///       "length": int
///       "returnType": String
///       "names": List<String>
///       "canCreateGetter": bool
///       "parameters": List<RefactoringMethodParameter>
///       "offsets": List<int>
///       "lengths": List<int>
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'extractMethod feedback'", json);
    }
    int offset;
    if (json case {'offset': var encodedOffset}) {
      offset = jsonDecoder.decodeInt('$jsonPath.offset', encodedOffset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'offset'", json);
    }
    int length;
    if (json case {'length': var encodedLength}) {
      length = jsonDecoder.decodeInt('$jsonPath.length', encodedLength);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'length'", json);
    }
    String returnType;
    if (json case {'returnType': var encodedReturnType}) {
      returnType = jsonDecoder.decodeString(
        '$jsonPath.returnType',
        encodedReturnType,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'returnType'", json);
    }
    List<String> names;
    if (json case {'names': var encodedNames}) {
      names = jsonDecoder.decodeList(
        '$jsonPath.names',
        encodedNames,
        jsonDecoder.decodeString,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'names'", json);
    }
    bool canCreateGetter;
    if (json case {'canCreateGetter': var encodedCanCreateGetter}) {
      canCreateGetter = jsonDecoder.decodeBool(
        '$jsonPath.canCreateGetter',
        encodedCanCreateGetter,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'canCreateGetter'", json);
    }
    List<RefactoringMethodParameter> parameters;
    if (json case {'parameters': var encodedParameters}) {
      parameters = jsonDecoder.decodeList(
        '$jsonPath.parameters',
        encodedParameters,
        (String jsonPath, Object? json) => RefactoringMethodParameter.fromJson(
          jsonDecoder,
          jsonPath,
          json,
          clientUriConverter: clientUriConverter,
        ),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'parameters'", json);
    }
    List<int> offsets;
    if (json case {'offsets': var encodedOffsets}) {
      offsets = jsonDecoder.decodeList(
        '$jsonPath.offsets',
        encodedOffsets,
        jsonDecoder.decodeInt,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'offsets'", json);
    }
    List<int> lengths;
    if (json case {'lengths': var encodedLengths}) {
      lengths = jsonDecoder.decodeList(
        '$jsonPath.lengths',
        encodedLengths,
        jsonDecoder.decodeInt,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'lengths'", json);
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
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['offset'] = offset;
    result['length'] = length;
    result['returnType'] = returnType;
    result['names'] = names;
    result['canCreateGetter'] = canCreateGetter;
    result['parameters'] = parameters
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
///     {
///       "returnType": String
///       "createGetter": bool
///       "name": String
///       "parameters": List<RefactoringMethodParameter>
///       "extractAll": bool
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'extractMethod options'", json);
    }
    String returnType;
    if (json case {'returnType': var encodedReturnType}) {
      returnType = jsonDecoder.decodeString(
        '$jsonPath.returnType',
        encodedReturnType,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'returnType'", json);
    }
    bool createGetter;
    if (json case {'createGetter': var encodedCreateGetter}) {
      createGetter = jsonDecoder.decodeBool(
        '$jsonPath.createGetter',
        encodedCreateGetter,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'createGetter'", json);
    }
    String name;
    if (json case {'name': var encodedName}) {
      name = jsonDecoder.decodeString('$jsonPath.name', encodedName);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'name'", json);
    }
    List<RefactoringMethodParameter> parameters;
    if (json case {'parameters': var encodedParameters}) {
      parameters = jsonDecoder.decodeList(
        '$jsonPath.parameters',
        encodedParameters,
        (String jsonPath, Object? json) => RefactoringMethodParameter.fromJson(
          jsonDecoder,
          jsonPath,
          json,
          clientUriConverter: clientUriConverter,
        ),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'parameters'", json);
    }
    bool extractAll;
    if (json case {'extractAll': var encodedExtractAll}) {
      extractAll = jsonDecoder.decodeBool(
        '$jsonPath.extractAll',
        encodedExtractAll,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'extractAll'", json);
    }
    return ExtractMethodOptions(
      returnType,
      createGetter,
      name,
      parameters,
      extractAll,
    );
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
    result['parameters'] = parameters
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
///     {
///       "name": String
///       "occurrences": int
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(
        jsonPath,
        "'inlineLocalVariable feedback'",
        json,
      );
    }
    String name;
    if (json case {'name': var encodedName}) {
      name = jsonDecoder.decodeString('$jsonPath.name', encodedName);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'name'", json);
    }
    int occurrences;
    if (json case {'occurrences': var encodedOccurrences}) {
      occurrences = jsonDecoder.decodeInt(
        '$jsonPath.occurrences',
        encodedOccurrences,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'occurrences'", json);
    }
    return InlineLocalVariableFeedback(name, occurrences);
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
///     {
///       "className": optional String
///       "methodName": String
///       "isDeclaration": bool
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'inlineMethod feedback'", json);
    }
    String? className;
    if (json case {'className': var encodedClassName}) {
      className = jsonDecoder.decodeString(
        '$jsonPath.className',
        encodedClassName,
      );
    }
    String methodName;
    if (json case {'methodName': var encodedMethodName}) {
      methodName = jsonDecoder.decodeString(
        '$jsonPath.methodName',
        encodedMethodName,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'methodName'", json);
    }
    bool isDeclaration;
    if (json case {'isDeclaration': var encodedIsDeclaration}) {
      isDeclaration = jsonDecoder.decodeBool(
        '$jsonPath.isDeclaration',
        encodedIsDeclaration,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'isDeclaration'", json);
    }
    return InlineMethodFeedback(
      methodName,
      isDeclaration,
      className: className,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    if (className case var className?) {
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
///     {
///       "deleteSource": bool
///       "inlineAll": bool
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'inlineMethod options'", json);
    }
    bool deleteSource;
    if (json case {'deleteSource': var encodedDeleteSource}) {
      deleteSource = jsonDecoder.decodeBool(
        '$jsonPath.deleteSource',
        encodedDeleteSource,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'deleteSource'", json);
    }
    bool inlineAll;
    if (json case {'inlineAll': var encodedInlineAll}) {
      inlineAll = jsonDecoder.decodeBool(
        '$jsonPath.inlineAll',
        encodedInlineAll,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'inlineAll'", json);
    }
    return InlineMethodOptions(deleteSource, inlineAll);
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
///     {
///       "newFile": FilePath
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'moveFile options'", json);
    }
    String newFile;
    if (json case {'newFile': var encodedNewFile}) {
      newFile =
          clientUriConverter?.fromClientFilePath(
            jsonDecoder.decodeString('$jsonPath.newFile', encodedNewFile),
          ) ??
          jsonDecoder.decodeString('$jsonPath.newFile', encodedNewFile);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'newFile'", json);
    }
    return MoveFileOptions(newFile);
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

/// plugin.details params
///
/// Clients may not extend, implement or mix-in this class.
class PluginDetailsParams implements RequestParams {
  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) => {};

  @override
  Request toRequest(String id, {ClientUriConverter? clientUriConverter}) {
    return Request(id, 'plugin.details');
  }

  @override
  bool operator ==(other) => other is PluginDetailsParams;

  @override
  int get hashCode => 808994897;
}

/// plugin.details result
///
///     {
///       "plugins": List<PluginDetails>
///     }
///
/// Clients may not extend, implement or mix-in this class.
class PluginDetailsResult implements ResponseResult {
  /// A list of the details of all registered plugins.
  List<PluginDetails> plugins;

  PluginDetailsResult(this.plugins);

  factory PluginDetailsResult.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'plugin.details result'", json);
    }
    List<PluginDetails> plugins;
    if (json case {'plugins': var encodedPlugins}) {
      plugins = jsonDecoder.decodeList(
        '$jsonPath.plugins',
        encodedPlugins,
        (String jsonPath, Object? json) => PluginDetails.fromJson(
          jsonDecoder,
          jsonPath,
          json,
          clientUriConverter: clientUriConverter,
        ),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'plugins'", json);
    }
    return PluginDetailsResult(plugins);
  }

  factory PluginDetailsResult.fromResponse(
    Response response, {
    ClientUriConverter? clientUriConverter,
  }) {
    return PluginDetailsResult.fromJson(
      ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
      'result',
      response.result,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['plugins'] = plugins
        .map(
          (PluginDetails value) =>
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
    if (other is PluginDetailsResult) {
      return listEqual(
        plugins,
        other.plugins,
        (PluginDetails a, PluginDetails b) => a == b,
      );
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(plugins);
}

/// plugin.error params
///
///     {
///       "isFatal": bool
///       "message": String
///       "stackTrace": String
///     }
///
/// Clients may not extend, implement or mix-in this class.
class PluginErrorParams implements HasToJson {
  /// A flag indicating whether the error is a fatal error, meaning that the
  /// plugin will shutdown automatically after sending this notification. If
  /// `true`, the server will not expect any other responses or notifications
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'plugin.error params'", json);
    }
    bool isFatal;
    if (json case {'isFatal': var encodedIsFatal}) {
      isFatal = jsonDecoder.decodeBool('$jsonPath.isFatal', encodedIsFatal);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'isFatal'", json);
    }
    String message;
    if (json case {'message': var encodedMessage}) {
      message = jsonDecoder.decodeString('$jsonPath.message', encodedMessage);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'message'", json);
    }
    String stackTrace;
    if (json case {'stackTrace': var encodedStackTrace}) {
      stackTrace = jsonDecoder.decodeString(
        '$jsonPath.stackTrace',
        encodedStackTrace,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'stackTrace'", json);
    }
    return PluginErrorParams(isFatal, message, stackTrace);
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

/// plugin.print params
///
///     {
///       "pluginPrint": PluginPrint
///     }
///
/// Clients may not extend, implement or mix-in this class.
class PluginPrintParams implements HasToJson {
  /// Information about the message being printed.
  PluginPrint pluginPrint;

  PluginPrintParams(this.pluginPrint);

  factory PluginPrintParams.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'plugin.print params'", json);
    }
    PluginPrint pluginPrint;
    if (json case {'pluginPrint': var encodedPluginPrint}) {
      pluginPrint = PluginPrint.fromJson(
        jsonDecoder,
        '$jsonPath.pluginPrint',
        encodedPluginPrint,
        clientUriConverter: clientUriConverter,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'pluginPrint'", json);
    }
    return PluginPrintParams(pluginPrint);
  }

  factory PluginPrintParams.fromNotification(
    Notification notification, {
    ClientUriConverter? clientUriConverter,
  }) {
    return PluginPrintParams.fromJson(
      ResponseDecoder(null),
      'params',
      notification.params,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['pluginPrint'] = pluginPrint.toJson(
      clientUriConverter: clientUriConverter,
    );
    return result;
  }

  Notification toNotification({ClientUriConverter? clientUriConverter}) {
    return Notification(
      'plugin.print',
      toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is PluginPrintParams) {
      return pluginPrint == other.pluginPrint;
    }
    return false;
  }

  @override
  int get hashCode => pluginPrint.hashCode;
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

/// plugin.status params
///
///     {
///       "analysis": optional AnalysisStatus
///     }
///
/// Clients may not extend, implement or mix-in this class.
class PluginStatusParams implements HasToJson {
  /// The current status of analysis (whether analysis is being performed).
  AnalysisStatus? analysis;

  PluginStatusParams({this.analysis});

  factory PluginStatusParams.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json, {
    ClientUriConverter? clientUriConverter,
  }) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'plugin.status params'", json);
    }
    AnalysisStatus? analysis;
    if (json case {'analysis': var encodedAnalysis}) {
      analysis = AnalysisStatus.fromJson(
        jsonDecoder,
        '$jsonPath.analysis',
        encodedAnalysis,
        clientUriConverter: clientUriConverter,
      );
    }
    return PluginStatusParams(analysis: analysis);
  }

  factory PluginStatusParams.fromNotification(
    Notification notification, {
    ClientUriConverter? clientUriConverter,
  }) {
    return PluginStatusParams.fromJson(
      ResponseDecoder(null),
      'params',
      notification.params,
      clientUriConverter: clientUriConverter,
    );
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    if (analysis case var analysis?) {
      result['analysis'] = analysis.toJson(
        clientUriConverter: clientUriConverter,
      );
    }
    return result;
  }

  Notification toNotification({ClientUriConverter? clientUriConverter}) {
    return Notification(
      'plugin.status',
      toJson(clientUriConverter: clientUriConverter),
    );
  }

  @override
  String toString() => json.encode(toJson(clientUriConverter: null));

  @override
  bool operator ==(other) {
    if (other is PluginStatusParams) {
      return analysis == other.analysis;
    }
    return false;
  }

  @override
  int get hashCode => analysis.hashCode;
}

/// plugin.versionCheck params
///
///     {
///       "byteStorePath": FilePath
///       "sdkPath": FilePath
///       "version": String
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(
        jsonPath,
        "'plugin.versionCheck params'",
        json,
      );
    }
    String byteStorePath;
    if (json case {'byteStorePath': var encodedByteStorePath}) {
      byteStorePath =
          clientUriConverter?.fromClientFilePath(
            jsonDecoder.decodeString(
              '$jsonPath.byteStorePath',
              encodedByteStorePath,
            ),
          ) ??
          jsonDecoder.decodeString(
            '$jsonPath.byteStorePath',
            encodedByteStorePath,
          );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'byteStorePath'", json);
    }
    String sdkPath;
    if (json case {'sdkPath': var encodedSdkPath}) {
      sdkPath =
          clientUriConverter?.fromClientFilePath(
            jsonDecoder.decodeString('$jsonPath.sdkPath', encodedSdkPath),
          ) ??
          jsonDecoder.decodeString('$jsonPath.sdkPath', encodedSdkPath);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'sdkPath'", json);
    }
    String version;
    if (json case {'version': var encodedVersion}) {
      version = jsonDecoder.decodeString('$jsonPath.version', encodedVersion);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'version'", json);
    }
    return PluginVersionCheckParams(byteStorePath, sdkPath, version);
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
///     {
///       "isCompatible": bool
///       "name": String
///       "version": String
///       "contactInfo": optional String
///       "interestingFiles": List<String>
///     }
///
/// Clients may not extend, implement or mix-in this class.
class PluginVersionCheckResult implements ResponseResult {
  /// A flag indicating whether the plugin supports the same version of the
  /// plugin spec as the analysis server. If the value is `false`, then the
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
  /// information. This value is ignored if the `isCompatible` field is
  /// `false`. Otherwise, it will be used to identify the files for which the
  /// plugin should be notified of changes.
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(
        jsonPath,
        "'plugin.versionCheck result'",
        json,
      );
    }
    bool isCompatible;
    if (json case {'isCompatible': var encodedIsCompatible}) {
      isCompatible = jsonDecoder.decodeBool(
        '$jsonPath.isCompatible',
        encodedIsCompatible,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'isCompatible'", json);
    }
    String name;
    if (json case {'name': var encodedName}) {
      name = jsonDecoder.decodeString('$jsonPath.name', encodedName);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'name'", json);
    }
    String version;
    if (json case {'version': var encodedVersion}) {
      version = jsonDecoder.decodeString('$jsonPath.version', encodedVersion);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'version'", json);
    }
    String? contactInfo;
    if (json case {'contactInfo': var encodedContactInfo}) {
      contactInfo = jsonDecoder.decodeString(
        '$jsonPath.contactInfo',
        encodedContactInfo,
      );
    }
    List<String> interestingFiles;
    if (json case {'interestingFiles': var encodedInterestingFiles}) {
      interestingFiles = jsonDecoder.decodeList(
        '$jsonPath.interestingFiles',
        encodedInterestingFiles,
        jsonDecoder.decodeString,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'interestingFiles'", json);
    }
    return PluginVersionCheckResult(
      isCompatible,
      name,
      version,
      interestingFiles,
      contactInfo: contactInfo,
    );
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
    if (contactInfo case var contactInfo?) {
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
///     {
///       "priority": int
///       "change": SourceChange
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'PrioritizedSourceChange'", json);
    }
    int priority;
    if (json case {'priority': var encodedPriority}) {
      priority = jsonDecoder.decodeInt('$jsonPath.priority', encodedPriority);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'priority'", json);
    }
    SourceChange change;
    if (json case {'change': var encodedChange}) {
      change = SourceChange.fromJson(
        jsonDecoder,
        '$jsonPath.change',
        encodedChange,
        clientUriConverter: clientUriConverter,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'change'", json);
    }
    return PrioritizedSourceChange(priority, change);
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
///     {
///     }
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
///     {
///     }
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
///     {
///       "offset": int
///       "length": int
///       "elementKindName": String
///       "oldName": String
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'rename feedback'", json);
    }
    int offset;
    if (json case {'offset': var encodedOffset}) {
      offset = jsonDecoder.decodeInt('$jsonPath.offset', encodedOffset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'offset'", json);
    }
    int length;
    if (json case {'length': var encodedLength}) {
      length = jsonDecoder.decodeInt('$jsonPath.length', encodedLength);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'length'", json);
    }
    String elementKindName;
    if (json case {'elementKindName': var encodedElementKindName}) {
      elementKindName = jsonDecoder.decodeString(
        '$jsonPath.elementKindName',
        encodedElementKindName,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'elementKindName'", json);
    }
    String oldName;
    if (json case {'oldName': var encodedOldName}) {
      oldName = jsonDecoder.decodeString('$jsonPath.oldName', encodedOldName);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'oldName'", json);
    }
    return RenameFeedback(offset, length, elementKindName, oldName);
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
///     {
///       "newName": String
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'rename options'", json);
    }
    String newName;
    if (json case {'newName': var encodedNewName}) {
      newName = jsonDecoder.decodeString('$jsonPath.newName', encodedNewName);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'newName'", json);
    }
    return RenameOptions(newName);
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
///     {
///       "code": RequestErrorCode
///       "message": String
///       "stackTrace": optional String
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'RequestError'", json);
    }
    RequestErrorCode code;
    if (json case {'code': var encodedCode}) {
      code = RequestErrorCode.fromJson(
        jsonDecoder,
        '$jsonPath.code',
        encodedCode,
        clientUriConverter: clientUriConverter,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'code'", json);
    }
    String message;
    if (json case {'message': var encodedMessage}) {
      message = jsonDecoder.decodeString('$jsonPath.message', encodedMessage);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'message'", json);
    }
    String? stackTrace;
    if (json case {'stackTrace': var encodedStackTrace}) {
      stackTrace = jsonDecoder.decodeString(
        '$jsonPath.stackTrace',
        encodedStackTrace,
      );
    }
    return RequestError(code, message, stackTrace: stackTrace);
  }

  @override
  Map<String, Object> toJson({ClientUriConverter? clientUriConverter}) {
    var result = <String, Object>{};
    result['code'] = code.toJson(clientUriConverter: clientUriConverter);
    result['message'] = message;
    if (stackTrace case var stackTrace?) {
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
///     enum {
///       INVALID_OVERLAY_CHANGE
///       INVALID_PARAMETER
///       PLUGIN_ERROR
///       UNKNOWN_REQUEST
///     }
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
    throw jsonDecoder.mismatch(jsonPath, "'RequestErrorCode'", json);
  }

  @override
  String toString() => 'RequestErrorCode.$name';

  String toJson({ClientUriConverter? clientUriConverter}) => name;
}

/// WatchEvent
///
///     {
///       "type": WatchEventType
///       "path": FilePath
///     }
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
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'WatchEvent'", json);
    }
    WatchEventType type;
    if (json case {'type': var encodedType}) {
      type = WatchEventType.fromJson(
        jsonDecoder,
        '$jsonPath.type',
        encodedType,
        clientUriConverter: clientUriConverter,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'type'", json);
    }
    String path;
    if (json case {'path': var encodedPath}) {
      path =
          clientUriConverter?.fromClientFilePath(
            jsonDecoder.decodeString('$jsonPath.path', encodedPath),
          ) ??
          jsonDecoder.decodeString('$jsonPath.path', encodedPath);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'path'", json);
    }
    return WatchEvent(type, path);
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
///     enum {
///       ADD
///       MODIFY
///       REMOVE
///     }
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
    throw jsonDecoder.mismatch(jsonPath, "'WatchEventType'", json);
  }

  @override
  String toString() => 'WatchEventType.$name';

  String toJson({ClientUriConverter? clientUriConverter}) => name;
}
