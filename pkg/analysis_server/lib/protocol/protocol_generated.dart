// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/spec/generate_files".

import 'dart:convert' hide JsonDecoder;

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/// analysis.analyzedFiles params
///
/// {
///   "directories": List<FilePath>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisAnalyzedFilesParams implements HasToJson {
  /// A list of the paths of the files that are being analyzed.
  List<String> directories;

  AnalysisAnalyzedFilesParams(this.directories);

  factory AnalysisAnalyzedFilesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<String> directories;
      if (json.containsKey('directories')) {
        directories = jsonDecoder.decodeList('$jsonPath.directories',
            json['directories'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'directories');
      }
      return AnalysisAnalyzedFilesParams(directories);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.analyzedFiles params', json);
    }
  }

  factory AnalysisAnalyzedFilesParams.fromNotification(
      Notification notification) {
    return AnalysisAnalyzedFilesParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['directories'] = directories;
    return result;
  }

  Notification toNotification() {
    return Notification('analysis.analyzedFiles', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisAnalyzedFilesParams) {
      return listEqual(
          directories, other.directories, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(directories);
}

/// analysis.closingLabels params
///
/// {
///   "file": FilePath
///   "labels": List<ClosingLabel>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisClosingLabelsParams implements HasToJson {
  /// The file the closing labels relate to.
  String file;

  /// Closing labels relevant to the file. Each item represents a useful label
  /// associated with some range with may be useful to display to the user
  /// within the editor at the end of the range to indicate what construct is
  /// closed at that location. Closing labels include constructor/method calls
  /// and List arguments that span multiple lines. Note that the ranges that
  /// are returned can overlap each other because they may be associated with
  /// constructs that can be nested.
  List<ClosingLabel> labels;

  AnalysisClosingLabelsParams(this.file, this.labels);

  factory AnalysisClosingLabelsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      List<ClosingLabel> labels;
      if (json.containsKey('labels')) {
        labels = jsonDecoder.decodeList(
            '$jsonPath.labels',
            json['labels'],
            (String jsonPath, Object? json) =>
                ClosingLabel.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'labels');
      }
      return AnalysisClosingLabelsParams(file, labels);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.closingLabels params', json);
    }
  }

  factory AnalysisClosingLabelsParams.fromNotification(
      Notification notification) {
    return AnalysisClosingLabelsParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['labels'] =
        labels.map((ClosingLabel value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return Notification('analysis.closingLabels', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisClosingLabelsParams) {
      return file == other.file &&
          listEqual(
              labels, other.labels, (ClosingLabel a, ClosingLabel b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        Object.hashAll(labels),
      );
}

/// AnalysisErrorFixes
///
/// {
///   "error": AnalysisError
///   "fixes": List<SourceChange>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisErrorFixes implements HasToJson {
  /// The error with which the fixes are associated.
  AnalysisError error;

  /// The fixes associated with the error.
  List<SourceChange> fixes;

  AnalysisErrorFixes(this.error, {List<SourceChange>? fixes})
      : fixes = fixes ?? <SourceChange>[];

  factory AnalysisErrorFixes.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      AnalysisError error;
      if (json.containsKey('error')) {
        error = AnalysisError.fromJson(
            jsonDecoder, '$jsonPath.error', json['error']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'error');
      }
      List<SourceChange> fixes;
      if (json.containsKey('fixes')) {
        fixes = jsonDecoder.decodeList(
            '$jsonPath.fixes',
            json['fixes'],
            (String jsonPath, Object? json) =>
                SourceChange.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'fixes');
      }
      return AnalysisErrorFixes(error, fixes: fixes);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'AnalysisErrorFixes', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['error'] = error.toJson();
    result['fixes'] =
        fixes.map((SourceChange value) => value.toJson()).toList();
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisErrorFixes) {
      return error == other.error &&
          listEqual(
              fixes, other.fixes, (SourceChange a, SourceChange b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        error,
        Object.hashAll(fixes),
      );
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
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      List<AnalysisError> errors;
      if (json.containsKey('errors')) {
        errors = jsonDecoder.decodeList(
            '$jsonPath.errors',
            json['errors'],
            (String jsonPath, Object? json) =>
                AnalysisError.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'errors');
      }
      return AnalysisErrorsParams(file, errors);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.errors params', json);
    }
  }

  factory AnalysisErrorsParams.fromNotification(Notification notification) {
    return AnalysisErrorsParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['errors'] =
        errors.map((AnalysisError value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return Notification('analysis.errors', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisErrorsParams) {
      return file == other.file &&
          listEqual(errors, other.errors,
              (AnalysisError a, AnalysisError b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        Object.hashAll(errors),
      );
}

/// analysis.flushResults params
///
/// {
///   "files": List<FilePath>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisFlushResultsParams implements HasToJson {
  /// The files that are no longer being analyzed.
  List<String> files;

  AnalysisFlushResultsParams(this.files);

  factory AnalysisFlushResultsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<String> files;
      if (json.containsKey('files')) {
        files = jsonDecoder.decodeList(
            '$jsonPath.files', json['files'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'files');
      }
      return AnalysisFlushResultsParams(files);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.flushResults params', json);
    }
  }

  factory AnalysisFlushResultsParams.fromNotification(
      Notification notification) {
    return AnalysisFlushResultsParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['files'] = files;
    return result;
  }

  Notification toNotification() {
    return Notification('analysis.flushResults', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisFlushResultsParams) {
      return listEqual(files, other.files, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(files);
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
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      List<FoldingRegion> regions;
      if (json.containsKey('regions')) {
        regions = jsonDecoder.decodeList(
            '$jsonPath.regions',
            json['regions'],
            (String jsonPath, Object? json) =>
                FoldingRegion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'regions');
      }
      return AnalysisFoldingParams(file, regions);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.folding params', json);
    }
  }

  factory AnalysisFoldingParams.fromNotification(Notification notification) {
    return AnalysisFoldingParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['regions'] =
        regions.map((FoldingRegion value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return Notification('analysis.folding', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisFoldingParams) {
      return file == other.file &&
          listEqual(regions, other.regions,
              (FoldingRegion a, FoldingRegion b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        Object.hashAll(regions),
      );
}

/// analysis.getErrors params
///
/// {
///   "file": FilePath
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetErrorsParams implements RequestParams {
  /// The file for which errors are being requested.
  String file;

  AnalysisGetErrorsParams(this.file);

  factory AnalysisGetErrorsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      return AnalysisGetErrorsParams(file);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.getErrors params', json);
    }
  }

  factory AnalysisGetErrorsParams.fromRequest(Request request) {
    return AnalysisGetErrorsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.getErrors', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetErrorsParams) {
      return file == other.file;
    }
    return false;
  }

  @override
  int get hashCode => file.hashCode;
}

/// analysis.getErrors result
///
/// {
///   "errors": List<AnalysisError>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetErrorsResult implements ResponseResult {
  /// The errors associated with the file.
  List<AnalysisError> errors;

  AnalysisGetErrorsResult(this.errors);

  factory AnalysisGetErrorsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<AnalysisError> errors;
      if (json.containsKey('errors')) {
        errors = jsonDecoder.decodeList(
            '$jsonPath.errors',
            json['errors'],
            (String jsonPath, Object? json) =>
                AnalysisError.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'errors');
      }
      return AnalysisGetErrorsResult(errors);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.getErrors result', json);
    }
  }

  factory AnalysisGetErrorsResult.fromResponse(Response response) {
    return AnalysisGetErrorsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['errors'] =
        errors.map((AnalysisError value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetErrorsResult) {
      return listEqual(
          errors, other.errors, (AnalysisError a, AnalysisError b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(errors);
}

/// analysis.getHover params
///
/// {
///   "file": FilePath
///   "offset": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetHoverParams implements RequestParams {
  /// The file in which hover information is being requested.
  String file;

  /// The offset for which hover information is being requested.
  int offset;

  AnalysisGetHoverParams(this.file, this.offset);

  factory AnalysisGetHoverParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt('$jsonPath.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      return AnalysisGetHoverParams(file, offset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.getHover params', json);
    }
  }

  factory AnalysisGetHoverParams.fromRequest(Request request) {
    return AnalysisGetHoverParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['offset'] = offset;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.getHover', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetHoverParams) {
      return file == other.file && offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        offset,
      );
}

/// analysis.getHover result
///
/// {
///   "hovers": List<HoverInformation>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetHoverResult implements ResponseResult {
  /// The hover information associated with the location. The list will be
  /// empty if no information could be determined for the location. The list
  /// can contain multiple items if the file is being analyzed in multiple
  /// contexts in conflicting ways (such as a part that is included in multiple
  /// libraries).
  List<HoverInformation> hovers;

  AnalysisGetHoverResult(this.hovers);

  factory AnalysisGetHoverResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<HoverInformation> hovers;
      if (json.containsKey('hovers')) {
        hovers = jsonDecoder.decodeList(
            '$jsonPath.hovers',
            json['hovers'],
            (String jsonPath, Object? json) =>
                HoverInformation.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'hovers');
      }
      return AnalysisGetHoverResult(hovers);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.getHover result', json);
    }
  }

  factory AnalysisGetHoverResult.fromResponse(Response response) {
    return AnalysisGetHoverResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['hovers'] =
        hovers.map((HoverInformation value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetHoverResult) {
      return listEqual(hovers, other.hovers,
          (HoverInformation a, HoverInformation b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(hovers);
}

/// analysis.getImportedElements params
///
/// {
///   "file": FilePath
///   "offset": int
///   "length": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetImportedElementsParams implements RequestParams {
  /// The file in which import information is being requested.
  String file;

  /// The offset of the region for which import information is being requested.
  int offset;

  /// The length of the region for which import information is being requested.
  int length;

  AnalysisGetImportedElementsParams(this.file, this.offset, this.length);

  factory AnalysisGetImportedElementsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
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
      return AnalysisGetImportedElementsParams(file, offset, length);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.getImportedElements params', json);
    }
  }

  factory AnalysisGetImportedElementsParams.fromRequest(Request request) {
    return AnalysisGetImportedElementsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['offset'] = offset;
    result['length'] = length;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.getImportedElements', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetImportedElementsParams) {
      return file == other.file &&
          offset == other.offset &&
          length == other.length;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        offset,
        length,
      );
}

/// analysis.getImportedElements result
///
/// {
///   "elements": List<ImportedElements>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetImportedElementsResult implements ResponseResult {
  /// The information about the elements that are referenced in the specified
  /// region of the specified file that come from imported libraries.
  List<ImportedElements> elements;

  AnalysisGetImportedElementsResult(this.elements);

  factory AnalysisGetImportedElementsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<ImportedElements> elements;
      if (json.containsKey('elements')) {
        elements = jsonDecoder.decodeList(
            '$jsonPath.elements',
            json['elements'],
            (String jsonPath, Object? json) =>
                ImportedElements.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'elements');
      }
      return AnalysisGetImportedElementsResult(elements);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.getImportedElements result', json);
    }
  }

  factory AnalysisGetImportedElementsResult.fromResponse(Response response) {
    return AnalysisGetImportedElementsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['elements'] =
        elements.map((ImportedElements value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetImportedElementsResult) {
      return listEqual(elements, other.elements,
          (ImportedElements a, ImportedElements b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(elements);
}

/// analysis.getLibraryDependencies params
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetLibraryDependenciesParams implements RequestParams {
  @override
  Map<String, Object> toJson() => {};

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.getLibraryDependencies', null);
  }

  @override
  bool operator ==(other) => other is AnalysisGetLibraryDependenciesParams;

  @override
  int get hashCode => 246577680;
}

/// analysis.getLibraryDependencies result
///
/// {
///   "libraries": List<FilePath>
///   "packageMap": Map<String, Map<String, List<FilePath>>>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetLibraryDependenciesResult implements ResponseResult {
  /// A list of the paths of library elements referenced by files in existing
  /// analysis roots.
  List<String> libraries;

  /// A mapping from context source roots to package maps which map package
  /// names to source directories for use in client-side package URI
  /// resolution.
  Map<String, Map<String, List<String>>> packageMap;

  AnalysisGetLibraryDependenciesResult(this.libraries, this.packageMap);

  factory AnalysisGetLibraryDependenciesResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<String> libraries;
      if (json.containsKey('libraries')) {
        libraries = jsonDecoder.decodeList(
            '$jsonPath.libraries', json['libraries'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'libraries');
      }
      Map<String, Map<String, List<String>>> packageMap;
      if (json.containsKey('packageMap')) {
        packageMap = jsonDecoder.decodeMap(
            '$jsonPath.packageMap', json['packageMap'],
            valueDecoder: (String jsonPath, Object? json) =>
                jsonDecoder.decodeMap(jsonPath, json,
                    valueDecoder: (String jsonPath, Object? json) => jsonDecoder
                        .decodeList(jsonPath, json, jsonDecoder.decodeString)));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'packageMap');
      }
      return AnalysisGetLibraryDependenciesResult(libraries, packageMap);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.getLibraryDependencies result', json);
    }
  }

  factory AnalysisGetLibraryDependenciesResult.fromResponse(Response response) {
    return AnalysisGetLibraryDependenciesResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['libraries'] = libraries;
    result['packageMap'] = packageMap;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetLibraryDependenciesResult) {
      return listEqual(
              libraries, other.libraries, (String a, String b) => a == b) &&
          mapEqual(
              packageMap,
              other.packageMap,
              (Map<String, List<String>> a, Map<String, List<String>> b) =>
                  mapEqual(
                      a,
                      b,
                      (List<String> a, List<String> b) =>
                          listEqual(a, b, (String a, String b) => a == b)));
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(libraries),
        Object.hashAll([...packageMap.keys, ...packageMap.values]),
      );
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
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
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
          jsonPath, 'analysis.getNavigation params', json);
    }
  }

  factory AnalysisGetNavigationParams.fromRequest(Request request) {
    return AnalysisGetNavigationParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['offset'] = offset;
    result['length'] = length;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.getNavigation', toJson());
  }

  @override
  String toString() => json.encode(toJson());

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
  int get hashCode => Object.hash(
        file,
        offset,
        length,
      );
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
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<String> files;
      if (json.containsKey('files')) {
        files = jsonDecoder.decodeList(
            '$jsonPath.files', json['files'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'files');
      }
      List<NavigationTarget> targets;
      if (json.containsKey('targets')) {
        targets = jsonDecoder.decodeList(
            '$jsonPath.targets',
            json['targets'],
            (String jsonPath, Object? json) =>
                NavigationTarget.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'targets');
      }
      List<NavigationRegion> regions;
      if (json.containsKey('regions')) {
        regions = jsonDecoder.decodeList(
            '$jsonPath.regions',
            json['regions'],
            (String jsonPath, Object? json) =>
                NavigationRegion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'regions');
      }
      return AnalysisGetNavigationResult(files, targets, regions);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.getNavigation result', json);
    }
  }

  factory AnalysisGetNavigationResult.fromResponse(Response response) {
    return AnalysisGetNavigationResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['files'] = files;
    result['targets'] =
        targets.map((NavigationTarget value) => value.toJson()).toList();
    result['regions'] =
        regions.map((NavigationRegion value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetNavigationResult) {
      return listEqual(files, other.files, (String a, String b) => a == b) &&
          listEqual(targets, other.targets,
              (NavigationTarget a, NavigationTarget b) => a == b) &&
          listEqual(regions, other.regions,
              (NavigationRegion a, NavigationRegion b) => a == b);
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

/// analysis.getReachableSources params
///
/// {
///   "file": FilePath
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetReachableSourcesParams implements RequestParams {
  /// The file for which reachable source information is being requested.
  String file;

  AnalysisGetReachableSourcesParams(this.file);

  factory AnalysisGetReachableSourcesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      return AnalysisGetReachableSourcesParams(file);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.getReachableSources params', json);
    }
  }

  factory AnalysisGetReachableSourcesParams.fromRequest(Request request) {
    return AnalysisGetReachableSourcesParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.getReachableSources', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetReachableSourcesParams) {
      return file == other.file;
    }
    return false;
  }

  @override
  int get hashCode => file.hashCode;
}

/// analysis.getReachableSources result
///
/// {
///   "sources": Map<String, List<String>>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetReachableSourcesResult implements ResponseResult {
  /// A mapping from source URIs to directly reachable source URIs. For
  /// example, a file "foo.dart" that imports "bar.dart" would have the
  /// corresponding mapping { "file:///foo.dart" : ["file:///bar.dart"] }. If
  /// "bar.dart" has further imports (or exports) there will be a mapping from
  /// the URI "file:///bar.dart" to them. To check if a specific URI is
  /// reachable from a given file, clients can check for its presence in the
  /// resulting key set.
  Map<String, List<String>> sources;

  AnalysisGetReachableSourcesResult(this.sources);

  factory AnalysisGetReachableSourcesResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      Map<String, List<String>> sources;
      if (json.containsKey('sources')) {
        sources = jsonDecoder.decodeMap('$jsonPath.sources', json['sources'],
            valueDecoder: (String jsonPath, Object? json) => jsonDecoder
                .decodeList(jsonPath, json, jsonDecoder.decodeString));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'sources');
      }
      return AnalysisGetReachableSourcesResult(sources);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.getReachableSources result', json);
    }
  }

  factory AnalysisGetReachableSourcesResult.fromResponse(Response response) {
    return AnalysisGetReachableSourcesResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['sources'] = sources;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetReachableSourcesResult) {
      return mapEqual(
          sources,
          other.sources,
          (List<String> a, List<String> b) =>
              listEqual(a, b, (String a, String b) => a == b));
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll([...sources.keys, ...sources.values]);
}

/// analysis.getSignature params
///
/// {
///   "file": FilePath
///   "offset": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetSignatureParams implements RequestParams {
  /// The file in which signature information is being requested.
  String file;

  /// The location for which signature information is being requested.
  int offset;

  AnalysisGetSignatureParams(this.file, this.offset);

  factory AnalysisGetSignatureParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt('$jsonPath.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      return AnalysisGetSignatureParams(file, offset);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.getSignature params', json);
    }
  }

  factory AnalysisGetSignatureParams.fromRequest(Request request) {
    return AnalysisGetSignatureParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['offset'] = offset;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.getSignature', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetSignatureParams) {
      return file == other.file && offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        offset,
      );
}

/// analysis.getSignature result
///
/// {
///   "name": String
///   "parameters": List<ParameterInfo>
///   "dartdoc": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetSignatureResult implements ResponseResult {
  /// The name of the function being invoked at the given offset.
  String name;

  /// A list of information about each of the parameters of the function being
  /// invoked.
  List<ParameterInfo> parameters;

  /// The dartdoc associated with the function being invoked. Other than the
  /// removal of the comment delimiters, including leading asterisks in the
  /// case of a block comment, the dartdoc is unprocessed markdown. This data
  /// is omitted if there is no referenced element, or if the element has no
  /// dartdoc.
  String? dartdoc;

  AnalysisGetSignatureResult(this.name, this.parameters, {this.dartdoc});

  factory AnalysisGetSignatureResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString('$jsonPath.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      List<ParameterInfo> parameters;
      if (json.containsKey('parameters')) {
        parameters = jsonDecoder.decodeList(
            '$jsonPath.parameters',
            json['parameters'],
            (String jsonPath, Object? json) =>
                ParameterInfo.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'parameters');
      }
      String? dartdoc;
      if (json.containsKey('dartdoc')) {
        dartdoc =
            jsonDecoder.decodeString('$jsonPath.dartdoc', json['dartdoc']);
      }
      return AnalysisGetSignatureResult(name, parameters, dartdoc: dartdoc);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.getSignature result', json);
    }
  }

  factory AnalysisGetSignatureResult.fromResponse(Response response) {
    return AnalysisGetSignatureResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['name'] = name;
    result['parameters'] =
        parameters.map((ParameterInfo value) => value.toJson()).toList();
    var dartdoc = this.dartdoc;
    if (dartdoc != null) {
      result['dartdoc'] = dartdoc;
    }
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetSignatureResult) {
      return name == other.name &&
          listEqual(parameters, other.parameters,
              (ParameterInfo a, ParameterInfo b) => a == b) &&
          dartdoc == other.dartdoc;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        name,
        Object.hashAll(parameters),
        dartdoc,
      );
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

  /// The highlight regions contained in the file. Each highlight region
  /// represents a particular syntactic or semantic meaning associated with
  /// some range. Note that the highlight regions that are returned can overlap
  /// other highlight regions if there is more than one meaning associated with
  /// a particular region.
  List<HighlightRegion> regions;

  AnalysisHighlightsParams(this.file, this.regions);

  factory AnalysisHighlightsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      List<HighlightRegion> regions;
      if (json.containsKey('regions')) {
        regions = jsonDecoder.decodeList(
            '$jsonPath.regions',
            json['regions'],
            (String jsonPath, Object? json) =>
                HighlightRegion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'regions');
      }
      return AnalysisHighlightsParams(file, regions);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.highlights params', json);
    }
  }

  factory AnalysisHighlightsParams.fromNotification(Notification notification) {
    return AnalysisHighlightsParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['regions'] =
        regions.map((HighlightRegion value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return Notification('analysis.highlights', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisHighlightsParams) {
      return file == other.file &&
          listEqual(regions, other.regions,
              (HighlightRegion a, HighlightRegion b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        Object.hashAll(regions),
      );
}

/// analysis.implemented params
///
/// {
///   "file": FilePath
///   "classes": List<ImplementedClass>
///   "members": List<ImplementedMember>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisImplementedParams implements HasToJson {
  /// The file with which the implementations are associated.
  String file;

  /// The classes defined in the file that are implemented or extended.
  List<ImplementedClass> classes;

  /// The member defined in the file that are implemented or overridden.
  List<ImplementedMember> members;

  AnalysisImplementedParams(this.file, this.classes, this.members);

  factory AnalysisImplementedParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      List<ImplementedClass> classes;
      if (json.containsKey('classes')) {
        classes = jsonDecoder.decodeList(
            '$jsonPath.classes',
            json['classes'],
            (String jsonPath, Object? json) =>
                ImplementedClass.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'classes');
      }
      List<ImplementedMember> members;
      if (json.containsKey('members')) {
        members = jsonDecoder.decodeList(
            '$jsonPath.members',
            json['members'],
            (String jsonPath, Object? json) =>
                ImplementedMember.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'members');
      }
      return AnalysisImplementedParams(file, classes, members);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.implemented params', json);
    }
  }

  factory AnalysisImplementedParams.fromNotification(
      Notification notification) {
    return AnalysisImplementedParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['classes'] =
        classes.map((ImplementedClass value) => value.toJson()).toList();
    result['members'] =
        members.map((ImplementedMember value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return Notification('analysis.implemented', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisImplementedParams) {
      return file == other.file &&
          listEqual(classes, other.classes,
              (ImplementedClass a, ImplementedClass b) => a == b) &&
          listEqual(members, other.members,
              (ImplementedMember a, ImplementedMember b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        Object.hashAll(classes),
        Object.hashAll(members),
      );
}

/// analysis.invalidate params
///
/// {
///   "file": FilePath
///   "offset": int
///   "length": int
///   "delta": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisInvalidateParams implements HasToJson {
  /// The file whose information has been invalidated.
  String file;

  /// The offset of the invalidated region.
  int offset;

  /// The length of the invalidated region.
  int length;

  /// The delta to be applied to the offsets in information that follows the
  /// invalidated region in order to update it so that it doesn't need to be
  /// re-requested.
  int delta;

  AnalysisInvalidateParams(this.file, this.offset, this.length, this.delta);

  factory AnalysisInvalidateParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
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
      int delta;
      if (json.containsKey('delta')) {
        delta = jsonDecoder.decodeInt('$jsonPath.delta', json['delta']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'delta');
      }
      return AnalysisInvalidateParams(file, offset, length, delta);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.invalidate params', json);
    }
  }

  factory AnalysisInvalidateParams.fromNotification(Notification notification) {
    return AnalysisInvalidateParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['offset'] = offset;
    result['length'] = length;
    result['delta'] = delta;
    return result;
  }

  Notification toNotification() {
    return Notification('analysis.invalidate', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisInvalidateParams) {
      return file == other.file &&
          offset == other.offset &&
          length == other.length &&
          delta == other.delta;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        offset,
        length,
        delta,
      );
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

  /// The navigation regions contained in the file. The regions are sorted by
  /// their offsets. Each navigation region represents a list of targets
  /// associated with some range. The lists will usually contain a single
  /// target, but can contain more in the case of a part that is included in
  /// multiple libraries or in Dart code that is compiled against multiple
  /// versions of a package. Note that the navigation regions that are returned
  /// do not overlap other navigation regions.
  List<NavigationRegion> regions;

  /// The navigation targets referenced in the file. They are referenced by
  /// NavigationRegions by their index in this array.
  List<NavigationTarget> targets;

  /// The files containing navigation targets referenced in the file. They are
  /// referenced by NavigationTargets by their index in this array.
  List<String> files;

  AnalysisNavigationParams(this.file, this.regions, this.targets, this.files);

  factory AnalysisNavigationParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      List<NavigationRegion> regions;
      if (json.containsKey('regions')) {
        regions = jsonDecoder.decodeList(
            '$jsonPath.regions',
            json['regions'],
            (String jsonPath, Object? json) =>
                NavigationRegion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'regions');
      }
      List<NavigationTarget> targets;
      if (json.containsKey('targets')) {
        targets = jsonDecoder.decodeList(
            '$jsonPath.targets',
            json['targets'],
            (String jsonPath, Object? json) =>
                NavigationTarget.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'targets');
      }
      List<String> files;
      if (json.containsKey('files')) {
        files = jsonDecoder.decodeList(
            '$jsonPath.files', json['files'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'files');
      }
      return AnalysisNavigationParams(file, regions, targets, files);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.navigation params', json);
    }
  }

  factory AnalysisNavigationParams.fromNotification(Notification notification) {
    return AnalysisNavigationParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['regions'] =
        regions.map((NavigationRegion value) => value.toJson()).toList();
    result['targets'] =
        targets.map((NavigationTarget value) => value.toJson()).toList();
    result['files'] = files;
    return result;
  }

  Notification toNotification() {
    return Notification('analysis.navigation', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisNavigationParams) {
      return file == other.file &&
          listEqual(regions, other.regions,
              (NavigationRegion a, NavigationRegion b) => a == b) &&
          listEqual(targets, other.targets,
              (NavigationTarget a, NavigationTarget b) => a == b) &&
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
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      List<Occurrences> occurrences;
      if (json.containsKey('occurrences')) {
        occurrences = jsonDecoder.decodeList(
            '$jsonPath.occurrences',
            json['occurrences'],
            (String jsonPath, Object? json) =>
                Occurrences.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'occurrences');
      }
      return AnalysisOccurrencesParams(file, occurrences);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.occurrences params', json);
    }
  }

  factory AnalysisOccurrencesParams.fromNotification(
      Notification notification) {
    return AnalysisOccurrencesParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['occurrences'] =
        occurrences.map((Occurrences value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return Notification('analysis.occurrences', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisOccurrencesParams) {
      return file == other.file &&
          listEqual(occurrences, other.occurrences,
              (Occurrences a, Occurrences b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        Object.hashAll(occurrences),
      );
}

/// AnalysisOptions
///
/// {
///   "enableAsync": optional bool
///   "enableDeferredLoading": optional bool
///   "enableEnums": optional bool
///   "enableNullAwareOperators": optional bool
///   "generateDart2jsHints": optional bool
///   "generateHints": optional bool
///   "generateLints": optional bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisOptions implements HasToJson {
  /// Deprecated: this feature is always enabled.
  ///
  /// True if the client wants to enable support for the proposed async
  /// feature.
  bool? enableAsync;

  /// Deprecated: this feature is always enabled.
  ///
  /// True if the client wants to enable support for the proposed deferred
  /// loading feature.
  bool? enableDeferredLoading;

  /// Deprecated: this feature is always enabled.
  ///
  /// True if the client wants to enable support for the proposed enum feature.
  bool? enableEnums;

  /// Deprecated: this feature is always enabled.
  ///
  /// True if the client wants to enable support for the proposed "null aware
  /// operators" feature.
  bool? enableNullAwareOperators;

  /// True if hints that are specific to dart2js should be generated. This
  /// option is ignored if generateHints is false.
  bool? generateDart2jsHints;

  /// True if hints should be generated as part of generating errors and
  /// warnings.
  bool? generateHints;

  /// True if lints should be generated as part of generating errors and
  /// warnings.
  bool? generateLints;

  AnalysisOptions(
      {this.enableAsync,
      this.enableDeferredLoading,
      this.enableEnums,
      this.enableNullAwareOperators,
      this.generateDart2jsHints,
      this.generateHints,
      this.generateLints});

  factory AnalysisOptions.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      bool? enableAsync;
      if (json.containsKey('enableAsync')) {
        enableAsync = jsonDecoder.decodeBool(
            '$jsonPath.enableAsync', json['enableAsync']);
      }
      bool? enableDeferredLoading;
      if (json.containsKey('enableDeferredLoading')) {
        enableDeferredLoading = jsonDecoder.decodeBool(
            '$jsonPath.enableDeferredLoading', json['enableDeferredLoading']);
      }
      bool? enableEnums;
      if (json.containsKey('enableEnums')) {
        enableEnums = jsonDecoder.decodeBool(
            '$jsonPath.enableEnums', json['enableEnums']);
      }
      bool? enableNullAwareOperators;
      if (json.containsKey('enableNullAwareOperators')) {
        enableNullAwareOperators = jsonDecoder.decodeBool(
            '$jsonPath.enableNullAwareOperators',
            json['enableNullAwareOperators']);
      }
      bool? generateDart2jsHints;
      if (json.containsKey('generateDart2jsHints')) {
        generateDart2jsHints = jsonDecoder.decodeBool(
            '$jsonPath.generateDart2jsHints', json['generateDart2jsHints']);
      }
      bool? generateHints;
      if (json.containsKey('generateHints')) {
        generateHints = jsonDecoder.decodeBool(
            '$jsonPath.generateHints', json['generateHints']);
      }
      bool? generateLints;
      if (json.containsKey('generateLints')) {
        generateLints = jsonDecoder.decodeBool(
            '$jsonPath.generateLints', json['generateLints']);
      }
      return AnalysisOptions(
          enableAsync: enableAsync,
          enableDeferredLoading: enableDeferredLoading,
          enableEnums: enableEnums,
          enableNullAwareOperators: enableNullAwareOperators,
          generateDart2jsHints: generateDart2jsHints,
          generateHints: generateHints,
          generateLints: generateLints);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'AnalysisOptions', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    var enableAsync = this.enableAsync;
    if (enableAsync != null) {
      result['enableAsync'] = enableAsync;
    }
    var enableDeferredLoading = this.enableDeferredLoading;
    if (enableDeferredLoading != null) {
      result['enableDeferredLoading'] = enableDeferredLoading;
    }
    var enableEnums = this.enableEnums;
    if (enableEnums != null) {
      result['enableEnums'] = enableEnums;
    }
    var enableNullAwareOperators = this.enableNullAwareOperators;
    if (enableNullAwareOperators != null) {
      result['enableNullAwareOperators'] = enableNullAwareOperators;
    }
    var generateDart2jsHints = this.generateDart2jsHints;
    if (generateDart2jsHints != null) {
      result['generateDart2jsHints'] = generateDart2jsHints;
    }
    var generateHints = this.generateHints;
    if (generateHints != null) {
      result['generateHints'] = generateHints;
    }
    var generateLints = this.generateLints;
    if (generateLints != null) {
      result['generateLints'] = generateLints;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisOptions) {
      return enableAsync == other.enableAsync &&
          enableDeferredLoading == other.enableDeferredLoading &&
          enableEnums == other.enableEnums &&
          enableNullAwareOperators == other.enableNullAwareOperators &&
          generateDart2jsHints == other.generateDart2jsHints &&
          generateHints == other.generateHints &&
          generateLints == other.generateLints;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        enableAsync,
        enableDeferredLoading,
        enableEnums,
        enableNullAwareOperators,
        generateDart2jsHints,
        generateHints,
        generateLints,
      );
}

/// analysis.outline params
///
/// {
///   "file": FilePath
///   "kind": FileKind
///   "libraryName": optional String
///   "outline": Outline
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisOutlineParams implements HasToJson {
  /// The file with which the outline is associated.
  String file;

  /// The kind of the file.
  FileKind kind;

  /// The name of the library defined by the file using a "library" directive,
  /// or referenced by a "part of" directive. If both "library" and "part of"
  /// directives are present, then the "library" directive takes precedence.
  /// This field will be omitted if the file has neither "library" nor "part
  /// of" directives.
  String? libraryName;

  /// The outline associated with the file.
  Outline outline;

  AnalysisOutlineParams(this.file, this.kind, this.outline, {this.libraryName});

  factory AnalysisOutlineParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      FileKind kind;
      if (json.containsKey('kind')) {
        kind = FileKind.fromJson(jsonDecoder, '$jsonPath.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      String? libraryName;
      if (json.containsKey('libraryName')) {
        libraryName = jsonDecoder.decodeString(
            '$jsonPath.libraryName', json['libraryName']);
      }
      Outline outline;
      if (json.containsKey('outline')) {
        outline =
            Outline.fromJson(jsonDecoder, '$jsonPath.outline', json['outline']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'outline');
      }
      return AnalysisOutlineParams(file, kind, outline,
          libraryName: libraryName);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.outline params', json);
    }
  }

  factory AnalysisOutlineParams.fromNotification(Notification notification) {
    return AnalysisOutlineParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['kind'] = kind.toJson();
    var libraryName = this.libraryName;
    if (libraryName != null) {
      result['libraryName'] = libraryName;
    }
    result['outline'] = outline.toJson();
    return result;
  }

  Notification toNotification() {
    return Notification('analysis.outline', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisOutlineParams) {
      return file == other.file &&
          kind == other.kind &&
          libraryName == other.libraryName &&
          outline == other.outline;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        kind,
        libraryName,
        outline,
      );
}

/// analysis.overrides params
///
/// {
///   "file": FilePath
///   "overrides": List<Override>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisOverridesParams implements HasToJson {
  /// The file with which the overrides are associated.
  String file;

  /// The overrides associated with the file.
  List<Override> overrides;

  AnalysisOverridesParams(this.file, this.overrides);

  factory AnalysisOverridesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      List<Override> overrides;
      if (json.containsKey('overrides')) {
        overrides = jsonDecoder.decodeList(
            '$jsonPath.overrides',
            json['overrides'],
            (String jsonPath, Object? json) =>
                Override.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'overrides');
      }
      return AnalysisOverridesParams(file, overrides);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.overrides params', json);
    }
  }

  factory AnalysisOverridesParams.fromNotification(Notification notification) {
    return AnalysisOverridesParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['overrides'] =
        overrides.map((Override value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return Notification('analysis.overrides', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisOverridesParams) {
      return file == other.file &&
          listEqual(
              overrides, other.overrides, (Override a, Override b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        Object.hashAll(overrides),
      );
}

/// analysis.reanalyze params
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisReanalyzeParams implements RequestParams {
  @override
  Map<String, Object> toJson() => {};

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.reanalyze', null);
  }

  @override
  bool operator ==(other) => other is AnalysisReanalyzeParams;

  @override
  int get hashCode => 613039876;
}

/// analysis.reanalyze result
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisReanalyzeResult implements ResponseResult {
  @override
  Map<String, Object> toJson() => {};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) => other is AnalysisReanalyzeResult;

  @override
  int get hashCode => 846803925;
}

/// AnalysisService
///
/// enum {
///   CLOSING_LABELS
///   FOLDING
///   HIGHLIGHTS
///   IMPLEMENTED
///   INVALIDATE
///   NAVIGATION
///   OCCURRENCES
///   OUTLINE
///   OVERRIDES
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisService implements Enum {
  static const AnalysisService CLOSING_LABELS =
      AnalysisService._('CLOSING_LABELS');

  static const AnalysisService FOLDING = AnalysisService._('FOLDING');

  static const AnalysisService HIGHLIGHTS = AnalysisService._('HIGHLIGHTS');

  static const AnalysisService IMPLEMENTED = AnalysisService._('IMPLEMENTED');

  /// This service is not currently implemented and will become a
  /// GeneralAnalysisService in a future release.
  static const AnalysisService INVALIDATE = AnalysisService._('INVALIDATE');

  static const AnalysisService NAVIGATION = AnalysisService._('NAVIGATION');

  static const AnalysisService OCCURRENCES = AnalysisService._('OCCURRENCES');

  static const AnalysisService OUTLINE = AnalysisService._('OUTLINE');

  static const AnalysisService OVERRIDES = AnalysisService._('OVERRIDES');

  /// A list containing all of the enum values that are defined.
  static const List<AnalysisService> VALUES = <AnalysisService>[
    CLOSING_LABELS,
    FOLDING,
    HIGHLIGHTS,
    IMPLEMENTED,
    INVALIDATE,
    NAVIGATION,
    OCCURRENCES,
    OUTLINE,
    OVERRIDES
  ];

  @override
  final String name;

  const AnalysisService._(this.name);

  factory AnalysisService(String name) {
    switch (name) {
      case 'CLOSING_LABELS':
        return CLOSING_LABELS;
      case 'FOLDING':
        return FOLDING;
      case 'HIGHLIGHTS':
        return HIGHLIGHTS;
      case 'IMPLEMENTED':
        return IMPLEMENTED;
      case 'INVALIDATE':
        return INVALIDATE;
      case 'NAVIGATION':
        return NAVIGATION;
      case 'OCCURRENCES':
        return OCCURRENCES;
      case 'OUTLINE':
        return OUTLINE;
      case 'OVERRIDES':
        return OVERRIDES;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory AnalysisService.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    if (json is String) {
      try {
        return AnalysisService(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'AnalysisService', json);
  }

  @override
  String toString() => 'AnalysisService.$name';

  String toJson() => name;
}

/// analysis.setAnalysisRoots params
///
/// {
///   "included": List<FilePath>
///   "excluded": List<FilePath>
///   "packageRoots": optional Map<FilePath, FilePath>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisSetAnalysisRootsParams implements RequestParams {
  /// A list of the files and directories that should be analyzed.
  List<String> included;

  /// A list of the files and directories within the included directories that
  /// should not be analyzed.
  List<String> excluded;

  /// A mapping from source directories to package roots that should override
  /// the normal package: URI resolution mechanism.
  ///
  /// If a package root is a file, then the analyzer will behave as though that
  /// file is a ".dart_tool/package_config.json" file in the source directory.
  /// The effect is the same as specifying the file as a "--packages" parameter
  /// to the Dart VM when executing any Dart file inside the source directory.
  ///
  /// Files in any directories that are not overridden by this mapping have
  /// their package: URI's resolved using the normal pubspec.yaml mechanism. If
  /// this field is absent, or the empty map is specified, that indicates that
  /// the normal pubspec.yaml mechanism should always be used.
  Map<String, String>? packageRoots;

  AnalysisSetAnalysisRootsParams(this.included, this.excluded,
      {this.packageRoots});

  factory AnalysisSetAnalysisRootsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<String> included;
      if (json.containsKey('included')) {
        included = jsonDecoder.decodeList(
            '$jsonPath.included', json['included'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'included');
      }
      List<String> excluded;
      if (json.containsKey('excluded')) {
        excluded = jsonDecoder.decodeList(
            '$jsonPath.excluded', json['excluded'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'excluded');
      }
      Map<String, String>? packageRoots;
      if (json.containsKey('packageRoots')) {
        packageRoots = jsonDecoder.decodeMap(
            '$jsonPath.packageRoots', json['packageRoots'],
            valueDecoder: jsonDecoder.decodeString);
      }
      return AnalysisSetAnalysisRootsParams(included, excluded,
          packageRoots: packageRoots);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.setAnalysisRoots params', json);
    }
  }

  factory AnalysisSetAnalysisRootsParams.fromRequest(Request request) {
    return AnalysisSetAnalysisRootsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['included'] = included;
    result['excluded'] = excluded;
    var packageRoots = this.packageRoots;
    if (packageRoots != null) {
      result['packageRoots'] = packageRoots;
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.setAnalysisRoots', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisSetAnalysisRootsParams) {
      return listEqual(
              included, other.included, (String a, String b) => a == b) &&
          listEqual(excluded, other.excluded, (String a, String b) => a == b) &&
          mapEqual(
              packageRoots, other.packageRoots, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(included),
        Object.hashAll(excluded),
        Object.hashAll([...?packageRoots?.keys, ...?packageRoots?.values]),
      );
}

/// analysis.setAnalysisRoots result
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisSetAnalysisRootsResult implements ResponseResult {
  @override
  Map<String, Object> toJson() => {};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) => other is AnalysisSetAnalysisRootsResult;

  @override
  int get hashCode => 866004753;
}

/// analysis.setGeneralSubscriptions params
///
/// {
///   "subscriptions": List<GeneralAnalysisService>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisSetGeneralSubscriptionsParams implements RequestParams {
  /// A list of the services being subscribed to.
  List<GeneralAnalysisService> subscriptions;

  AnalysisSetGeneralSubscriptionsParams(this.subscriptions);

  factory AnalysisSetGeneralSubscriptionsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<GeneralAnalysisService> subscriptions;
      if (json.containsKey('subscriptions')) {
        subscriptions = jsonDecoder.decodeList(
            '$jsonPath.subscriptions',
            json['subscriptions'],
            (String jsonPath, Object? json) =>
                GeneralAnalysisService.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'subscriptions');
      }
      return AnalysisSetGeneralSubscriptionsParams(subscriptions);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.setGeneralSubscriptions params', json);
    }
  }

  factory AnalysisSetGeneralSubscriptionsParams.fromRequest(Request request) {
    return AnalysisSetGeneralSubscriptionsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['subscriptions'] = subscriptions
        .map((GeneralAnalysisService value) => value.toJson())
        .toList();
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.setGeneralSubscriptions', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisSetGeneralSubscriptionsParams) {
      return listEqual(subscriptions, other.subscriptions,
          (GeneralAnalysisService a, GeneralAnalysisService b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(subscriptions);
}

/// analysis.setGeneralSubscriptions result
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisSetGeneralSubscriptionsResult implements ResponseResult {
  @override
  Map<String, Object> toJson() => {};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) => other is AnalysisSetGeneralSubscriptionsResult;

  @override
  int get hashCode => 386759562;
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
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<String> files;
      if (json.containsKey('files')) {
        files = jsonDecoder.decodeList(
            '$jsonPath.files', json['files'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'files');
      }
      return AnalysisSetPriorityFilesParams(files);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.setPriorityFiles params', json);
    }
  }

  factory AnalysisSetPriorityFilesParams.fromRequest(Request request) {
    return AnalysisSetPriorityFilesParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['files'] = files;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.setPriorityFiles', toJson());
  }

  @override
  String toString() => json.encode(toJson());

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
  Map<String, Object> toJson() => {};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
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
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      Map<AnalysisService, List<String>> subscriptions;
      if (json.containsKey('subscriptions')) {
        subscriptions = jsonDecoder.decodeMap(
            '$jsonPath.subscriptions', json['subscriptions'],
            keyDecoder: (String jsonPath, Object? json) =>
                AnalysisService.fromJson(jsonDecoder, jsonPath, json),
            valueDecoder: (String jsonPath, Object? json) => jsonDecoder
                .decodeList(jsonPath, json, jsonDecoder.decodeString));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'subscriptions');
      }
      return AnalysisSetSubscriptionsParams(subscriptions);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.setSubscriptions params', json);
    }
  }

  factory AnalysisSetSubscriptionsParams.fromRequest(Request request) {
    return AnalysisSetSubscriptionsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['subscriptions'] = mapMap(subscriptions,
        keyCallback: (AnalysisService value) => value.toJson());
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.setSubscriptions', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisSetSubscriptionsParams) {
      return mapEqual(
          subscriptions,
          other.subscriptions,
          (List<String> a, List<String> b) =>
              listEqual(a, b, (String a, String b) => a == b));
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
  Map<String, Object> toJson() => {};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) => other is AnalysisSetSubscriptionsResult;

  @override
  int get hashCode => 218088493;
}

/// AnalysisStatus
///
/// {
///   "isAnalyzing": bool
///   "analysisTarget": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisStatus implements HasToJson {
  /// True if analysis is currently being performed.
  bool isAnalyzing;

  /// The name of the current target of analysis. This field is omitted if
  /// analyzing is false.
  String? analysisTarget;

  AnalysisStatus(this.isAnalyzing, {this.analysisTarget});

  factory AnalysisStatus.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      bool isAnalyzing;
      if (json.containsKey('isAnalyzing')) {
        isAnalyzing = jsonDecoder.decodeBool(
            '$jsonPath.isAnalyzing', json['isAnalyzing']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'isAnalyzing');
      }
      String? analysisTarget;
      if (json.containsKey('analysisTarget')) {
        analysisTarget = jsonDecoder.decodeString(
            '$jsonPath.analysisTarget', json['analysisTarget']);
      }
      return AnalysisStatus(isAnalyzing, analysisTarget: analysisTarget);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'AnalysisStatus', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['isAnalyzing'] = isAnalyzing;
    var analysisTarget = this.analysisTarget;
    if (analysisTarget != null) {
      result['analysisTarget'] = analysisTarget;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisStatus) {
      return isAnalyzing == other.isAnalyzing &&
          analysisTarget == other.analysisTarget;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        isAnalyzing,
        analysisTarget,
      );
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
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      Map<String, Object> files;
      if (json.containsKey('files')) {
        files = jsonDecoder.decodeMap('$jsonPath.files', json['files'],
            valueDecoder: (String jsonPath, Object? json) =>
                jsonDecoder.decodeUnion(jsonPath, json, 'type', {
                  'add': (String jsonPath, Object? json) =>
                      AddContentOverlay.fromJson(jsonDecoder, jsonPath, json),
                  'change': (String jsonPath, Object? json) =>
                      ChangeContentOverlay.fromJson(
                          jsonDecoder, jsonPath, json),
                  'remove': (String jsonPath, Object? json) =>
                      RemoveContentOverlay.fromJson(jsonDecoder, jsonPath, json)
                }));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'files');
      }
      return AnalysisUpdateContentParams(files);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.updateContent params', json);
    }
  }

  factory AnalysisUpdateContentParams.fromRequest(Request request) {
    return AnalysisUpdateContentParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['files'] = mapMap(files,
        valueCallback: (Object value) => (value as dynamic).toJson());
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.updateContent', toJson());
  }

  @override
  String toString() => json.encode(toJson());

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
/// {
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisUpdateContentResult implements ResponseResult {
  AnalysisUpdateContentResult();

  factory AnalysisUpdateContentResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      return AnalysisUpdateContentResult();
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.updateContent result', json);
    }
  }

  factory AnalysisUpdateContentResult.fromResponse(Response response) {
    return AnalysisUpdateContentResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisUpdateContentResult) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode => 0;
}

/// analysis.updateOptions params
///
/// {
///   "options": AnalysisOptions
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisUpdateOptionsParams implements RequestParams {
  /// The options that are to be used to control analysis.
  AnalysisOptions options;

  AnalysisUpdateOptionsParams(this.options);

  factory AnalysisUpdateOptionsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      AnalysisOptions options;
      if (json.containsKey('options')) {
        options = AnalysisOptions.fromJson(
            jsonDecoder, '$jsonPath.options', json['options']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'options');
      }
      return AnalysisUpdateOptionsParams(options);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.updateOptions params', json);
    }
  }

  factory AnalysisUpdateOptionsParams.fromRequest(Request request) {
    return AnalysisUpdateOptionsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['options'] = options.toJson();
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.updateOptions', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisUpdateOptionsParams) {
      return options == other.options;
    }
    return false;
  }

  @override
  int get hashCode => options.hashCode;
}

/// analysis.updateOptions result
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisUpdateOptionsResult implements ResponseResult {
  @override
  Map<String, Object> toJson() => {};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) => other is AnalysisUpdateOptionsResult;

  @override
  int get hashCode => 179689467;
}

/// analytics.enable params
///
/// {
///   "value": bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalyticsEnableParams implements RequestParams {
  /// Enable or disable analytics.
  bool value;

  AnalyticsEnableParams(this.value);

  factory AnalyticsEnableParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      bool value;
      if (json.containsKey('value')) {
        value = jsonDecoder.decodeBool('$jsonPath.value', json['value']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'value');
      }
      return AnalyticsEnableParams(value);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analytics.enable params', json);
    }
  }

  factory AnalyticsEnableParams.fromRequest(Request request) {
    return AnalyticsEnableParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['value'] = value;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analytics.enable', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalyticsEnableParams) {
      return value == other.value;
    }
    return false;
  }

  @override
  int get hashCode => value.hashCode;
}

/// analytics.enable result
///
/// Clients may not extend, implement or mix-in this class.
class AnalyticsEnableResult implements ResponseResult {
  @override
  Map<String, Object> toJson() => {};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) => other is AnalyticsEnableResult;

  @override
  int get hashCode => 237990792;
}

/// analytics.isEnabled params
///
/// Clients may not extend, implement or mix-in this class.
class AnalyticsIsEnabledParams implements RequestParams {
  @override
  Map<String, Object> toJson() => {};

  @override
  Request toRequest(String id) {
    return Request(id, 'analytics.isEnabled', null);
  }

  @override
  bool operator ==(other) => other is AnalyticsIsEnabledParams;

  @override
  int get hashCode => 57215544;
}

/// analytics.isEnabled result
///
/// {
///   "enabled": bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalyticsIsEnabledResult implements ResponseResult {
  /// Whether sending analytics is enabled or not.
  bool enabled;

  AnalyticsIsEnabledResult(this.enabled);

  factory AnalyticsIsEnabledResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      bool enabled;
      if (json.containsKey('enabled')) {
        enabled = jsonDecoder.decodeBool('$jsonPath.enabled', json['enabled']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'enabled');
      }
      return AnalyticsIsEnabledResult(enabled);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analytics.isEnabled result', json);
    }
  }

  factory AnalyticsIsEnabledResult.fromResponse(Response response) {
    return AnalyticsIsEnabledResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['enabled'] = enabled;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalyticsIsEnabledResult) {
      return enabled == other.enabled;
    }
    return false;
  }

  @override
  int get hashCode => enabled.hashCode;
}

/// analytics.sendEvent params
///
/// {
///   "action": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalyticsSendEventParams implements RequestParams {
  /// The value used to indicate which action was performed.
  String action;

  AnalyticsSendEventParams(this.action);

  factory AnalyticsSendEventParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String action;
      if (json.containsKey('action')) {
        action = jsonDecoder.decodeString('$jsonPath.action', json['action']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'action');
      }
      return AnalyticsSendEventParams(action);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analytics.sendEvent params', json);
    }
  }

  factory AnalyticsSendEventParams.fromRequest(Request request) {
    return AnalyticsSendEventParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['action'] = action;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analytics.sendEvent', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalyticsSendEventParams) {
      return action == other.action;
    }
    return false;
  }

  @override
  int get hashCode => action.hashCode;
}

/// analytics.sendEvent result
///
/// Clients may not extend, implement or mix-in this class.
class AnalyticsSendEventResult implements ResponseResult {
  @override
  Map<String, Object> toJson() => {};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) => other is AnalyticsSendEventResult;

  @override
  int get hashCode => 227063188;
}

/// analytics.sendTiming params
///
/// {
///   "event": String
///   "millis": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalyticsSendTimingParams implements RequestParams {
  /// The name of the event.
  String event;

  /// The duration of the event in milliseconds.
  int millis;

  AnalyticsSendTimingParams(this.event, this.millis);

  factory AnalyticsSendTimingParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String event;
      if (json.containsKey('event')) {
        event = jsonDecoder.decodeString('$jsonPath.event', json['event']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'event');
      }
      int millis;
      if (json.containsKey('millis')) {
        millis = jsonDecoder.decodeInt('$jsonPath.millis', json['millis']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'millis');
      }
      return AnalyticsSendTimingParams(event, millis);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analytics.sendTiming params', json);
    }
  }

  factory AnalyticsSendTimingParams.fromRequest(Request request) {
    return AnalyticsSendTimingParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['event'] = event;
    result['millis'] = millis;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analytics.sendTiming', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalyticsSendTimingParams) {
      return event == other.event && millis == other.millis;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        event,
        millis,
      );
}

/// analytics.sendTiming result
///
/// Clients may not extend, implement or mix-in this class.
class AnalyticsSendTimingResult implements ResponseResult {
  @override
  Map<String, Object> toJson() => {};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) => other is AnalyticsSendTimingResult;

  @override
  int get hashCode => 875010924;
}

/// AvailableSuggestion
///
/// {
///   "label": String
///   "declaringLibraryUri": String
///   "element": Element
///   "defaultArgumentListString": optional String
///   "defaultArgumentListTextRanges": optional List<int>
///   "parameterNames": optional List<String>
///   "parameterTypes": optional List<String>
///   "relevanceTags": optional List<AvailableSuggestionRelevanceTag>
///   "requiredParameterCount": optional int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AvailableSuggestion implements HasToJson {
  /// The identifier to present to the user for code completion.
  String label;

  /// The URI of the library that declares the element being suggested, not the
  /// URI of the library associated with the enclosing AvailableSuggestionSet.
  String declaringLibraryUri;

  /// Information about the element reference being suggested.
  Element element;

  /// A default String for use in generating argument list source contents on
  /// the client side.
  String? defaultArgumentListString;

  /// Pairs of offsets and lengths describing 'defaultArgumentListString' text
  /// ranges suitable for use by clients to set up linked edits of default
  /// argument source contents. For example, given an argument list string 'x,
  /// y', the corresponding text range [0, 1, 3, 1], indicates two text ranges
  /// of length 1, starting at offsets 0 and 3. Clients can use these ranges to
  /// treat the 'x' and 'y' values specially for linked edits.
  List<int>? defaultArgumentListTextRanges;

  /// If the element is an executable, the names of the formal parameters of
  /// all kinds - required, optional positional, and optional named. The names
  /// of positional parameters are empty strings. Omitted if the element is not
  /// an executable.
  List<String>? parameterNames;

  /// If the element is an executable, the declared types of the formal
  /// parameters of all kinds - required, optional positional, and optional
  /// named. Omitted if the element is not an executable.
  List<String>? parameterTypes;

  /// This field is set if the relevance of this suggestion might be changed
  /// depending on where completion is requested.
  List<String>? relevanceTags;

  int? requiredParameterCount;

  AvailableSuggestion(this.label, this.declaringLibraryUri, this.element,
      {this.defaultArgumentListString,
      this.defaultArgumentListTextRanges,
      this.parameterNames,
      this.parameterTypes,
      this.relevanceTags,
      this.requiredParameterCount});

  factory AvailableSuggestion.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String label;
      if (json.containsKey('label')) {
        label = jsonDecoder.decodeString('$jsonPath.label', json['label']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'label');
      }
      String declaringLibraryUri;
      if (json.containsKey('declaringLibraryUri')) {
        declaringLibraryUri = jsonDecoder.decodeString(
            '$jsonPath.declaringLibraryUri', json['declaringLibraryUri']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'declaringLibraryUri');
      }
      Element element;
      if (json.containsKey('element')) {
        element =
            Element.fromJson(jsonDecoder, '$jsonPath.element', json['element']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'element');
      }
      String? defaultArgumentListString;
      if (json.containsKey('defaultArgumentListString')) {
        defaultArgumentListString = jsonDecoder.decodeString(
            '$jsonPath.defaultArgumentListString',
            json['defaultArgumentListString']);
      }
      List<int>? defaultArgumentListTextRanges;
      if (json.containsKey('defaultArgumentListTextRanges')) {
        defaultArgumentListTextRanges = jsonDecoder.decodeList(
            '$jsonPath.defaultArgumentListTextRanges',
            json['defaultArgumentListTextRanges'],
            jsonDecoder.decodeInt);
      }
      List<String>? parameterNames;
      if (json.containsKey('parameterNames')) {
        parameterNames = jsonDecoder.decodeList('$jsonPath.parameterNames',
            json['parameterNames'], jsonDecoder.decodeString);
      }
      List<String>? parameterTypes;
      if (json.containsKey('parameterTypes')) {
        parameterTypes = jsonDecoder.decodeList('$jsonPath.parameterTypes',
            json['parameterTypes'], jsonDecoder.decodeString);
      }
      List<String>? relevanceTags;
      if (json.containsKey('relevanceTags')) {
        relevanceTags = jsonDecoder.decodeList('$jsonPath.relevanceTags',
            json['relevanceTags'], jsonDecoder.decodeString);
      }
      int? requiredParameterCount;
      if (json.containsKey('requiredParameterCount')) {
        requiredParameterCount = jsonDecoder.decodeInt(
            '$jsonPath.requiredParameterCount', json['requiredParameterCount']);
      }
      return AvailableSuggestion(label, declaringLibraryUri, element,
          defaultArgumentListString: defaultArgumentListString,
          defaultArgumentListTextRanges: defaultArgumentListTextRanges,
          parameterNames: parameterNames,
          parameterTypes: parameterTypes,
          relevanceTags: relevanceTags,
          requiredParameterCount: requiredParameterCount);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'AvailableSuggestion', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['label'] = label;
    result['declaringLibraryUri'] = declaringLibraryUri;
    result['element'] = element.toJson();
    var defaultArgumentListString = this.defaultArgumentListString;
    if (defaultArgumentListString != null) {
      result['defaultArgumentListString'] = defaultArgumentListString;
    }
    var defaultArgumentListTextRanges = this.defaultArgumentListTextRanges;
    if (defaultArgumentListTextRanges != null) {
      result['defaultArgumentListTextRanges'] = defaultArgumentListTextRanges;
    }
    var parameterNames = this.parameterNames;
    if (parameterNames != null) {
      result['parameterNames'] = parameterNames;
    }
    var parameterTypes = this.parameterTypes;
    if (parameterTypes != null) {
      result['parameterTypes'] = parameterTypes;
    }
    var relevanceTags = this.relevanceTags;
    if (relevanceTags != null) {
      result['relevanceTags'] = relevanceTags;
    }
    var requiredParameterCount = this.requiredParameterCount;
    if (requiredParameterCount != null) {
      result['requiredParameterCount'] = requiredParameterCount;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AvailableSuggestion) {
      return label == other.label &&
          declaringLibraryUri == other.declaringLibraryUri &&
          element == other.element &&
          defaultArgumentListString == other.defaultArgumentListString &&
          listEqual(defaultArgumentListTextRanges,
              other.defaultArgumentListTextRanges, (int a, int b) => a == b) &&
          listEqual(parameterNames, other.parameterNames,
              (String a, String b) => a == b) &&
          listEqual(parameterTypes, other.parameterTypes,
              (String a, String b) => a == b) &&
          listEqual(relevanceTags, other.relevanceTags,
              (String a, String b) => a == b) &&
          requiredParameterCount == other.requiredParameterCount;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        label,
        declaringLibraryUri,
        element,
        defaultArgumentListString,
        Object.hashAll(defaultArgumentListTextRanges ?? []),
        Object.hashAll(parameterNames ?? []),
        Object.hashAll(parameterTypes ?? []),
        Object.hashAll(relevanceTags ?? []),
        requiredParameterCount,
      );
}

/// AvailableSuggestionSet
///
/// {
///   "id": int
///   "uri": String
///   "items": List<AvailableSuggestion>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AvailableSuggestionSet implements HasToJson {
  /// The id associated with the library.
  int id;

  /// The URI of the library.
  String uri;

  List<AvailableSuggestion> items;

  AvailableSuggestionSet(this.id, this.uri, this.items);

  factory AvailableSuggestionSet.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      int id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeInt('$jsonPath.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      String uri;
      if (json.containsKey('uri')) {
        uri = jsonDecoder.decodeString('$jsonPath.uri', json['uri']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'uri');
      }
      List<AvailableSuggestion> items;
      if (json.containsKey('items')) {
        items = jsonDecoder.decodeList(
            '$jsonPath.items',
            json['items'],
            (String jsonPath, Object? json) =>
                AvailableSuggestion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'items');
      }
      return AvailableSuggestionSet(id, uri, items);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'AvailableSuggestionSet', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['id'] = id;
    result['uri'] = uri;
    result['items'] =
        items.map((AvailableSuggestion value) => value.toJson()).toList();
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AvailableSuggestionSet) {
      return id == other.id &&
          uri == other.uri &&
          listEqual(items, other.items,
              (AvailableSuggestion a, AvailableSuggestion b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        id,
        uri,
        Object.hashAll(items),
      );
}

/// BulkFix
///
/// {
///   "path": FilePath
///   "fixes": List<BulkFixDetail>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class BulkFix implements HasToJson {
  /// The path of the library.
  String path;

  /// A list of bulk fix details.
  List<BulkFixDetail> fixes;

  BulkFix(this.path, this.fixes);

  factory BulkFix.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String path;
      if (json.containsKey('path')) {
        path = jsonDecoder.decodeString('$jsonPath.path', json['path']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'path');
      }
      List<BulkFixDetail> fixes;
      if (json.containsKey('fixes')) {
        fixes = jsonDecoder.decodeList(
            '$jsonPath.fixes',
            json['fixes'],
            (String jsonPath, Object? json) =>
                BulkFixDetail.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'fixes');
      }
      return BulkFix(path, fixes);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'BulkFix', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['path'] = path;
    result['fixes'] =
        fixes.map((BulkFixDetail value) => value.toJson()).toList();
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is BulkFix) {
      return path == other.path &&
          listEqual(
              fixes, other.fixes, (BulkFixDetail a, BulkFixDetail b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        path,
        Object.hashAll(fixes),
      );
}

/// BulkFixDetail
///
/// {
///   "code": String
///   "occurrences": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class BulkFixDetail implements HasToJson {
  /// The code of the diagnostic associated with the fix.
  String code;

  /// The number times the associated diagnostic was fixed in the associated
  /// source edit.
  int occurrences;

  BulkFixDetail(this.code, this.occurrences);

  factory BulkFixDetail.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String code;
      if (json.containsKey('code')) {
        code = jsonDecoder.decodeString('$jsonPath.code', json['code']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'code');
      }
      int occurrences;
      if (json.containsKey('occurrences')) {
        occurrences =
            jsonDecoder.decodeInt('$jsonPath.occurrences', json['occurrences']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'occurrences');
      }
      return BulkFixDetail(code, occurrences);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'BulkFixDetail', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['code'] = code;
    result['occurrences'] = occurrences;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is BulkFixDetail) {
      return code == other.code && occurrences == other.occurrences;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        code,
        occurrences,
      );
}

/// ClosingLabel
///
/// {
///   "offset": int
///   "length": int
///   "label": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ClosingLabel implements HasToJson {
  /// The offset of the construct being labelled.
  int offset;

  /// The length of the whole construct to be labelled.
  int length;

  /// The label associated with this range that should be displayed to the
  /// user.
  String label;

  ClosingLabel(this.offset, this.length, this.label);

  factory ClosingLabel.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
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
      String label;
      if (json.containsKey('label')) {
        label = jsonDecoder.decodeString('$jsonPath.label', json['label']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'label');
      }
      return ClosingLabel(offset, length, label);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ClosingLabel', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['offset'] = offset;
    result['length'] = length;
    result['label'] = label;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ClosingLabel) {
      return offset == other.offset &&
          length == other.length &&
          label == other.label;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        offset,
        length,
        label,
      );
}

/// completion.availableSuggestions params
///
/// {
///   "changedLibraries": optional List<AvailableSuggestionSet>
///   "removedLibraries": optional List<int>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionAvailableSuggestionsParams implements HasToJson {
  /// A list of pre-computed, potential completions coming from this set of
  /// completion suggestions.
  List<AvailableSuggestionSet>? changedLibraries;

  /// A list of library ids that no longer apply.
  List<int>? removedLibraries;

  CompletionAvailableSuggestionsParams(
      {this.changedLibraries, this.removedLibraries});

  factory CompletionAvailableSuggestionsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<AvailableSuggestionSet>? changedLibraries;
      if (json.containsKey('changedLibraries')) {
        changedLibraries = jsonDecoder.decodeList(
            '$jsonPath.changedLibraries',
            json['changedLibraries'],
            (String jsonPath, Object? json) =>
                AvailableSuggestionSet.fromJson(jsonDecoder, jsonPath, json));
      }
      List<int>? removedLibraries;
      if (json.containsKey('removedLibraries')) {
        removedLibraries = jsonDecoder.decodeList('$jsonPath.removedLibraries',
            json['removedLibraries'], jsonDecoder.decodeInt);
      }
      return CompletionAvailableSuggestionsParams(
          changedLibraries: changedLibraries,
          removedLibraries: removedLibraries);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'completion.availableSuggestions params', json);
    }
  }

  factory CompletionAvailableSuggestionsParams.fromNotification(
      Notification notification) {
    return CompletionAvailableSuggestionsParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    var changedLibraries = this.changedLibraries;
    if (changedLibraries != null) {
      result['changedLibraries'] = changedLibraries
          .map((AvailableSuggestionSet value) => value.toJson())
          .toList();
    }
    var removedLibraries = this.removedLibraries;
    if (removedLibraries != null) {
      result['removedLibraries'] = removedLibraries;
    }
    return result;
  }

  Notification toNotification() {
    return Notification('completion.availableSuggestions', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionAvailableSuggestionsParams) {
      return listEqual(changedLibraries, other.changedLibraries,
              (AvailableSuggestionSet a, AvailableSuggestionSet b) => a == b) &&
          listEqual(removedLibraries, other.removedLibraries,
              (int a, int b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(changedLibraries ?? []),
        Object.hashAll(removedLibraries ?? []),
      );
}

/// CompletionCaseMatchingMode
///
/// enum {
///   FIRST_CHAR
///   ALL_CHARS
///   NONE
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionCaseMatchingMode implements Enum {
  /// Match the first character case only when filtering completions, the
  /// default for this enumeration.
  static const CompletionCaseMatchingMode FIRST_CHAR =
      CompletionCaseMatchingMode._('FIRST_CHAR');

  /// Match all character cases when filtering completion lists.
  static const CompletionCaseMatchingMode ALL_CHARS =
      CompletionCaseMatchingMode._('ALL_CHARS');

  /// Do not match character cases when filtering completion lists.
  static const CompletionCaseMatchingMode NONE =
      CompletionCaseMatchingMode._('NONE');

  /// A list containing all of the enum values that are defined.
  static const List<CompletionCaseMatchingMode> VALUES =
      <CompletionCaseMatchingMode>[FIRST_CHAR, ALL_CHARS, NONE];

  @override
  final String name;

  const CompletionCaseMatchingMode._(this.name);

  factory CompletionCaseMatchingMode(String name) {
    switch (name) {
      case 'FIRST_CHAR':
        return FIRST_CHAR;
      case 'ALL_CHARS':
        return ALL_CHARS;
      case 'NONE':
        return NONE;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory CompletionCaseMatchingMode.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    if (json is String) {
      try {
        return CompletionCaseMatchingMode(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'CompletionCaseMatchingMode', json);
  }

  @override
  String toString() => 'CompletionCaseMatchingMode.$name';

  String toJson() => name;
}

/// completion.existingImports params
///
/// {
///   "file": FilePath
///   "imports": ExistingImports
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionExistingImportsParams implements HasToJson {
  /// The defining file of the library.
  String file;

  /// The existing imports in the library.
  ExistingImports imports;

  CompletionExistingImportsParams(this.file, this.imports);

  factory CompletionExistingImportsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      ExistingImports imports;
      if (json.containsKey('imports')) {
        imports = ExistingImports.fromJson(
            jsonDecoder, '$jsonPath.imports', json['imports']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'imports');
      }
      return CompletionExistingImportsParams(file, imports);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'completion.existingImports params', json);
    }
  }

  factory CompletionExistingImportsParams.fromNotification(
      Notification notification) {
    return CompletionExistingImportsParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['imports'] = imports.toJson();
    return result;
  }

  Notification toNotification() {
    return Notification('completion.existingImports', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionExistingImportsParams) {
      return file == other.file && imports == other.imports;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        imports,
      );
}

/// completion.getSuggestionDetails2 params
///
/// {
///   "file": FilePath
///   "offset": int
///   "completion": String
///   "libraryUri": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionGetSuggestionDetails2Params implements RequestParams {
  /// The path of the file into which this completion is being inserted.
  String file;

  /// The offset in the file where the completion will be inserted.
  int offset;

  /// The completion from the selected CompletionSuggestion. It could be a name
  /// of a class, or a name of a constructor in form
  /// "typeName.constructorName()", or an enumeration constant in form
  /// "enumName.constantName", etc.
  String completion;

  /// The URI of the library to import, so that the element referenced in the
  /// completion becomes accessible.
  String libraryUri;

  CompletionGetSuggestionDetails2Params(
      this.file, this.offset, this.completion, this.libraryUri);

  factory CompletionGetSuggestionDetails2Params.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt('$jsonPath.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      String completion;
      if (json.containsKey('completion')) {
        completion = jsonDecoder.decodeString(
            '$jsonPath.completion', json['completion']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'completion');
      }
      String libraryUri;
      if (json.containsKey('libraryUri')) {
        libraryUri = jsonDecoder.decodeString(
            '$jsonPath.libraryUri', json['libraryUri']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'libraryUri');
      }
      return CompletionGetSuggestionDetails2Params(
          file, offset, completion, libraryUri);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'completion.getSuggestionDetails2 params', json);
    }
  }

  factory CompletionGetSuggestionDetails2Params.fromRequest(Request request) {
    return CompletionGetSuggestionDetails2Params.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['offset'] = offset;
    result['completion'] = completion;
    result['libraryUri'] = libraryUri;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'completion.getSuggestionDetails2', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionGetSuggestionDetails2Params) {
      return file == other.file &&
          offset == other.offset &&
          completion == other.completion &&
          libraryUri == other.libraryUri;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        offset,
        completion,
        libraryUri,
      );
}

/// completion.getSuggestionDetails2 result
///
/// {
///   "completion": String
///   "change": SourceChange
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionGetSuggestionDetails2Result implements ResponseResult {
  /// The full text to insert, which possibly includes now an import prefix.
  /// The client should insert this text, not the completion from the selected
  /// CompletionSuggestion.
  String completion;

  /// A change for the client to apply to make the accepted completion
  /// suggestion available. In most cases the change is to add a new import
  /// directive to the file.
  SourceChange change;

  CompletionGetSuggestionDetails2Result(this.completion, this.change);

  factory CompletionGetSuggestionDetails2Result.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String completion;
      if (json.containsKey('completion')) {
        completion = jsonDecoder.decodeString(
            '$jsonPath.completion', json['completion']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'completion');
      }
      SourceChange change;
      if (json.containsKey('change')) {
        change = SourceChange.fromJson(
            jsonDecoder, '$jsonPath.change', json['change']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'change');
      }
      return CompletionGetSuggestionDetails2Result(completion, change);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'completion.getSuggestionDetails2 result', json);
    }
  }

  factory CompletionGetSuggestionDetails2Result.fromResponse(
      Response response) {
    return CompletionGetSuggestionDetails2Result.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['completion'] = completion;
    result['change'] = change.toJson();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionGetSuggestionDetails2Result) {
      return completion == other.completion && change == other.change;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        completion,
        change,
      );
}

/// completion.getSuggestionDetails params
///
/// {
///   "file": FilePath
///   "id": int
///   "label": String
///   "offset": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionGetSuggestionDetailsParams implements RequestParams {
  /// The path of the file into which this completion is being inserted.
  String file;

  /// The identifier of the AvailableSuggestionSet containing the selected
  /// label.
  int id;

  /// The label from the AvailableSuggestionSet with the `id` for which
  /// insertion information is requested.
  String label;

  /// The offset in the file where the completion will be inserted.
  int offset;

  CompletionGetSuggestionDetailsParams(
      this.file, this.id, this.label, this.offset);

  factory CompletionGetSuggestionDetailsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeInt('$jsonPath.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      String label;
      if (json.containsKey('label')) {
        label = jsonDecoder.decodeString('$jsonPath.label', json['label']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'label');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt('$jsonPath.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      return CompletionGetSuggestionDetailsParams(file, id, label, offset);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'completion.getSuggestionDetails params', json);
    }
  }

  factory CompletionGetSuggestionDetailsParams.fromRequest(Request request) {
    return CompletionGetSuggestionDetailsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['id'] = id;
    result['label'] = label;
    result['offset'] = offset;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'completion.getSuggestionDetails', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionGetSuggestionDetailsParams) {
      return file == other.file &&
          id == other.id &&
          label == other.label &&
          offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        id,
        label,
        offset,
      );
}

/// completion.getSuggestionDetails result
///
/// {
///   "completion": String
///   "change": optional SourceChange
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionGetSuggestionDetailsResult implements ResponseResult {
  /// The full text to insert, including any optional import prefix.
  String completion;

  /// A change for the client to apply in case the library containing the
  /// accepted completion suggestion needs to be imported. The field will be
  /// omitted if there are no additional changes that need to be made.
  SourceChange? change;

  CompletionGetSuggestionDetailsResult(this.completion, {this.change});

  factory CompletionGetSuggestionDetailsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String completion;
      if (json.containsKey('completion')) {
        completion = jsonDecoder.decodeString(
            '$jsonPath.completion', json['completion']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'completion');
      }
      SourceChange? change;
      if (json.containsKey('change')) {
        change = SourceChange.fromJson(
            jsonDecoder, '$jsonPath.change', json['change']);
      }
      return CompletionGetSuggestionDetailsResult(completion, change: change);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'completion.getSuggestionDetails result', json);
    }
  }

  factory CompletionGetSuggestionDetailsResult.fromResponse(Response response) {
    return CompletionGetSuggestionDetailsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['completion'] = completion;
    var change = this.change;
    if (change != null) {
      result['change'] = change.toJson();
    }
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionGetSuggestionDetailsResult) {
      return completion == other.completion && change == other.change;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        completion,
        change,
      );
}

/// completion.getSuggestions2 params
///
/// {
///   "file": FilePath
///   "offset": int
///   "maxResults": int
///   "completionCaseMatchingMode": optional CompletionCaseMatchingMode
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionGetSuggestions2Params implements RequestParams {
  /// The file containing the point at which suggestions are to be made.
  String file;

  /// The offset within the file at which suggestions are to be made.
  int offset;

  /// The maximum number of suggestions to return. If the number of suggestions
  /// after filtering is greater than the maxResults, then isIncomplete is set
  /// to true.
  int maxResults;

  /// The mode of code completion being invoked. If no value is provided,
  /// MATCH_FIRST_CHAR will be assumed.
  CompletionCaseMatchingMode? completionCaseMatchingMode;

  /// The mode of code completion being invoked. If no value is provided, BASIC
  /// will be assumed. BASIC is also the only currently supported.
  CompletionMode? completionMode;

  /// The number of times that the user has invoked code completion at the same
  /// code location, counting from 1. If no value is provided, 1 will be
  /// assumed.
  int? invocationCount;

  /// The approximate time in milliseconds that the server should spend. The
  /// server will perform some steps anyway, even if it takes longer than the
  /// specified timeout. This field is intended to be used for benchmarking,
  /// and usually should not be provided, so that the default timeout is used.
  int? timeout;

  CompletionGetSuggestions2Params(this.file, this.offset, this.maxResults,
      {this.completionCaseMatchingMode,
      this.completionMode,
      this.invocationCount,
      this.timeout});

  factory CompletionGetSuggestions2Params.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt('$jsonPath.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int maxResults;
      if (json.containsKey('maxResults')) {
        maxResults =
            jsonDecoder.decodeInt('$jsonPath.maxResults', json['maxResults']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'maxResults');
      }
      CompletionCaseMatchingMode? completionCaseMatchingMode;
      if (json.containsKey('completionCaseMatchingMode')) {
        completionCaseMatchingMode = CompletionCaseMatchingMode.fromJson(
            jsonDecoder,
            '$jsonPath.completionCaseMatchingMode',
            json['completionCaseMatchingMode']);
      }
      CompletionMode? completionMode;
      if (json.containsKey('completionMode')) {
        completionMode = CompletionMode.fromJson(
            jsonDecoder, '$jsonPath.completionMode', json['completionMode']);
      }
      int? invocationCount;
      if (json.containsKey('invocationCount')) {
        invocationCount = jsonDecoder.decodeInt(
            '$jsonPath.invocationCount', json['invocationCount']);
      }
      int? timeout;
      if (json.containsKey('timeout')) {
        timeout = jsonDecoder.decodeInt('$jsonPath.timeout', json['timeout']);
      }
      return CompletionGetSuggestions2Params(file, offset, maxResults,
          completionCaseMatchingMode: completionCaseMatchingMode,
          completionMode: completionMode,
          invocationCount: invocationCount,
          timeout: timeout);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'completion.getSuggestions2 params', json);
    }
  }

  factory CompletionGetSuggestions2Params.fromRequest(Request request) {
    return CompletionGetSuggestions2Params.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['offset'] = offset;
    result['maxResults'] = maxResults;
    var completionCaseMatchingMode = this.completionCaseMatchingMode;
    if (completionCaseMatchingMode != null) {
      result['completionCaseMatchingMode'] =
          completionCaseMatchingMode.toJson();
    }
    var completionMode = this.completionMode;
    if (completionMode != null) {
      result['completionMode'] = completionMode.toJson();
    }
    var invocationCount = this.invocationCount;
    if (invocationCount != null) {
      result['invocationCount'] = invocationCount;
    }
    var timeout = this.timeout;
    if (timeout != null) {
      result['timeout'] = timeout;
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'completion.getSuggestions2', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionGetSuggestions2Params) {
      return file == other.file &&
          offset == other.offset &&
          maxResults == other.maxResults &&
          completionCaseMatchingMode == other.completionCaseMatchingMode &&
          completionMode == other.completionMode &&
          invocationCount == other.invocationCount &&
          timeout == other.timeout;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        offset,
        maxResults,
        completionCaseMatchingMode,
        completionMode,
        invocationCount,
        timeout,
      );
}

/// completion.getSuggestions2 result
///
/// {
///   "replacementOffset": int
///   "replacementLength": int
///   "suggestions": List<CompletionSuggestion>
///   "isIncomplete": bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionGetSuggestions2Result implements ResponseResult {
  /// The offset of the start of the text to be replaced. This will be
  /// different from the offset used to request the completion suggestions if
  /// there was a portion of an identifier before the original offset. In
  /// particular, the replacementOffset will be the offset of the beginning of
  /// said identifier.
  int replacementOffset;

  /// The length of the text to be replaced if the remainder of the identifier
  /// containing the cursor is to be replaced when the suggestion is applied
  /// (that is, the number of characters in the existing identifier).
  int replacementLength;

  /// The completion suggestions being reported. This list is filtered by the
  /// already existing prefix, and sorted first by relevance, and (if the same)
  /// by the suggestion text. The list will have at most maxResults items. If
  /// the user types a new keystroke, the client is expected to either do local
  /// filtering (when the returned list was complete), or ask the server again
  /// (if isIncomplete was true).
  ///
  /// This list contains suggestions from both imported, and not yet imported
  /// libraries. Items from not yet imported libraries will have isNotImported
  /// set to true.
  List<CompletionSuggestion> suggestions;

  /// True if the number of suggestions after filtering was greater than the
  /// requested maxResults.
  bool isIncomplete;

  CompletionGetSuggestions2Result(this.replacementOffset,
      this.replacementLength, this.suggestions, this.isIncomplete);

  factory CompletionGetSuggestions2Result.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      int replacementOffset;
      if (json.containsKey('replacementOffset')) {
        replacementOffset = jsonDecoder.decodeInt(
            '$jsonPath.replacementOffset', json['replacementOffset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'replacementOffset');
      }
      int replacementLength;
      if (json.containsKey('replacementLength')) {
        replacementLength = jsonDecoder.decodeInt(
            '$jsonPath.replacementLength', json['replacementLength']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'replacementLength');
      }
      List<CompletionSuggestion> suggestions;
      if (json.containsKey('suggestions')) {
        suggestions = jsonDecoder.decodeList(
            '$jsonPath.suggestions',
            json['suggestions'],
            (String jsonPath, Object? json) =>
                CompletionSuggestion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'suggestions');
      }
      bool isIncomplete;
      if (json.containsKey('isIncomplete')) {
        isIncomplete = jsonDecoder.decodeBool(
            '$jsonPath.isIncomplete', json['isIncomplete']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'isIncomplete');
      }
      return CompletionGetSuggestions2Result(
          replacementOffset, replacementLength, suggestions, isIncomplete);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'completion.getSuggestions2 result', json);
    }
  }

  factory CompletionGetSuggestions2Result.fromResponse(Response response) {
    return CompletionGetSuggestions2Result.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['replacementOffset'] = replacementOffset;
    result['replacementLength'] = replacementLength;
    result['suggestions'] = suggestions
        .map((CompletionSuggestion value) => value.toJson())
        .toList();
    result['isIncomplete'] = isIncomplete;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionGetSuggestions2Result) {
      return replacementOffset == other.replacementOffset &&
          replacementLength == other.replacementLength &&
          listEqual(suggestions, other.suggestions,
              (CompletionSuggestion a, CompletionSuggestion b) => a == b) &&
          isIncomplete == other.isIncomplete;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        replacementOffset,
        replacementLength,
        Object.hashAll(suggestions),
        isIncomplete,
      );
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
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
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
          jsonPath, 'completion.getSuggestions params', json);
    }
  }

  factory CompletionGetSuggestionsParams.fromRequest(Request request) {
    return CompletionGetSuggestionsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['offset'] = offset;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'completion.getSuggestions', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionGetSuggestionsParams) {
      return file == other.file && offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        offset,
      );
}

/// completion.getSuggestions result
///
/// {
///   "id": CompletionId
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionGetSuggestionsResult implements ResponseResult {
  /// The identifier used to associate results with this completion request.
  String id;

  CompletionGetSuggestionsResult(this.id);

  factory CompletionGetSuggestionsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeString('$jsonPath.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      return CompletionGetSuggestionsResult(id);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'completion.getSuggestions result', json);
    }
  }

  factory CompletionGetSuggestionsResult.fromResponse(Response response) {
    return CompletionGetSuggestionsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['id'] = id;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionGetSuggestionsResult) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode => id.hashCode;
}

/// CompletionMode
///
/// enum {
///   BASIC
///   SMART
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionMode implements Enum {
  /// Basic code completion invocation type, and the default for this
  /// enumeration.
  static const CompletionMode BASIC = CompletionMode._('BASIC');

  /// Smart code completion, currently not implemented.
  static const CompletionMode SMART = CompletionMode._('SMART');

  /// A list containing all of the enum values that are defined.
  static const List<CompletionMode> VALUES = <CompletionMode>[BASIC, SMART];

  @override
  final String name;

  const CompletionMode._(this.name);

  factory CompletionMode(String name) {
    switch (name) {
      case 'BASIC':
        return BASIC;
      case 'SMART':
        return SMART;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory CompletionMode.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    if (json is String) {
      try {
        return CompletionMode(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'CompletionMode', json);
  }

  @override
  String toString() => 'CompletionMode.$name';

  String toJson() => name;
}

/// completion.registerLibraryPaths params
///
/// {
///   "paths": List<LibraryPathSet>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionRegisterLibraryPathsParams implements RequestParams {
  /// A list of objects each containing a path and the additional libraries
  /// from which the client is interested in receiving completion suggestions.
  /// If one configured path is beneath another, the descendant will override
  /// the ancestors' configured libraries of interest.
  List<LibraryPathSet> paths;

  CompletionRegisterLibraryPathsParams(this.paths);

  factory CompletionRegisterLibraryPathsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<LibraryPathSet> paths;
      if (json.containsKey('paths')) {
        paths = jsonDecoder.decodeList(
            '$jsonPath.paths',
            json['paths'],
            (String jsonPath, Object? json) =>
                LibraryPathSet.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'paths');
      }
      return CompletionRegisterLibraryPathsParams(paths);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'completion.registerLibraryPaths params', json);
    }
  }

  factory CompletionRegisterLibraryPathsParams.fromRequest(Request request) {
    return CompletionRegisterLibraryPathsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['paths'] =
        paths.map((LibraryPathSet value) => value.toJson()).toList();
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'completion.registerLibraryPaths', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionRegisterLibraryPathsParams) {
      return listEqual(
          paths, other.paths, (LibraryPathSet a, LibraryPathSet b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(paths);
}

/// completion.registerLibraryPaths result
///
/// Clients may not extend, implement or mix-in this class.
class CompletionRegisterLibraryPathsResult implements ResponseResult {
  @override
  Map<String, Object> toJson() => {};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) => other is CompletionRegisterLibraryPathsResult;

  @override
  int get hashCode => 104675661;
}

/// completion.results params
///
/// {
///   "id": CompletionId
///   "replacementOffset": int
///   "replacementLength": int
///   "results": List<CompletionSuggestion>
///   "isLast": bool
///   "libraryFile": optional FilePath
///   "includedSuggestionSets": optional List<IncludedSuggestionSet>
///   "includedElementKinds": optional List<ElementKind>
///   "includedSuggestionRelevanceTags": optional List<IncludedSuggestionRelevanceTag>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionResultsParams implements HasToJson {
  /// The id associated with the completion.
  String id;

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

  /// True if this is that last set of results that will be returned for the
  /// indicated completion.
  bool isLast;

  /// The library file that contains the file where completion was requested.
  /// The client might use it for example together with the existingImports
  /// notification to filter out available suggestions. If there were changes
  /// to existing imports in the library, the corresponding existingImports
  /// notification will be sent before the completion notification.
  String? libraryFile;

  /// References to AvailableSuggestionSet objects previously sent to the
  /// client. The client can include applicable names from the referenced
  /// library in code completion suggestions.
  List<IncludedSuggestionSet>? includedSuggestionSets;

  /// The client is expected to check this list against the ElementKind sent in
  /// IncludedSuggestionSet to decide whether or not these symbols should be
  /// presented to the user.
  List<ElementKind>? includedElementKinds;

  /// The client is expected to check this list against the values of the field
  /// relevanceTags of AvailableSuggestion to decide if the suggestion should
  /// be given a different relevance than the IncludedSuggestionSet that
  /// contains it. This might be used for example to give higher relevance to
  /// suggestions of matching types.
  ///
  /// If an AvailableSuggestion has relevance tags that match more than one
  /// IncludedSuggestionRelevanceTag, the maximum relevance boost is used.
  List<IncludedSuggestionRelevanceTag>? includedSuggestionRelevanceTags;

  CompletionResultsParams(this.id, this.replacementOffset,
      this.replacementLength, this.results, this.isLast,
      {this.libraryFile,
      this.includedSuggestionSets,
      this.includedElementKinds,
      this.includedSuggestionRelevanceTags});

  factory CompletionResultsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeString('$jsonPath.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      int replacementOffset;
      if (json.containsKey('replacementOffset')) {
        replacementOffset = jsonDecoder.decodeInt(
            '$jsonPath.replacementOffset', json['replacementOffset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'replacementOffset');
      }
      int replacementLength;
      if (json.containsKey('replacementLength')) {
        replacementLength = jsonDecoder.decodeInt(
            '$jsonPath.replacementLength', json['replacementLength']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'replacementLength');
      }
      List<CompletionSuggestion> results;
      if (json.containsKey('results')) {
        results = jsonDecoder.decodeList(
            '$jsonPath.results',
            json['results'],
            (String jsonPath, Object? json) =>
                CompletionSuggestion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'results');
      }
      bool isLast;
      if (json.containsKey('isLast')) {
        isLast = jsonDecoder.decodeBool('$jsonPath.isLast', json['isLast']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'isLast');
      }
      String? libraryFile;
      if (json.containsKey('libraryFile')) {
        libraryFile = jsonDecoder.decodeString(
            '$jsonPath.libraryFile', json['libraryFile']);
      }
      List<IncludedSuggestionSet>? includedSuggestionSets;
      if (json.containsKey('includedSuggestionSets')) {
        includedSuggestionSets = jsonDecoder.decodeList(
            '$jsonPath.includedSuggestionSets',
            json['includedSuggestionSets'],
            (String jsonPath, Object? json) =>
                IncludedSuggestionSet.fromJson(jsonDecoder, jsonPath, json));
      }
      List<ElementKind>? includedElementKinds;
      if (json.containsKey('includedElementKinds')) {
        includedElementKinds = jsonDecoder.decodeList(
            '$jsonPath.includedElementKinds',
            json['includedElementKinds'],
            (String jsonPath, Object? json) =>
                ElementKind.fromJson(jsonDecoder, jsonPath, json));
      }
      List<IncludedSuggestionRelevanceTag>? includedSuggestionRelevanceTags;
      if (json.containsKey('includedSuggestionRelevanceTags')) {
        includedSuggestionRelevanceTags = jsonDecoder.decodeList(
            '$jsonPath.includedSuggestionRelevanceTags',
            json['includedSuggestionRelevanceTags'],
            (String jsonPath, Object? json) =>
                IncludedSuggestionRelevanceTag.fromJson(
                    jsonDecoder, jsonPath, json));
      }
      return CompletionResultsParams(
          id, replacementOffset, replacementLength, results, isLast,
          libraryFile: libraryFile,
          includedSuggestionSets: includedSuggestionSets,
          includedElementKinds: includedElementKinds,
          includedSuggestionRelevanceTags: includedSuggestionRelevanceTags);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'completion.results params', json);
    }
  }

  factory CompletionResultsParams.fromNotification(Notification notification) {
    return CompletionResultsParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['id'] = id;
    result['replacementOffset'] = replacementOffset;
    result['replacementLength'] = replacementLength;
    result['results'] =
        results.map((CompletionSuggestion value) => value.toJson()).toList();
    result['isLast'] = isLast;
    var libraryFile = this.libraryFile;
    if (libraryFile != null) {
      result['libraryFile'] = libraryFile;
    }
    var includedSuggestionSets = this.includedSuggestionSets;
    if (includedSuggestionSets != null) {
      result['includedSuggestionSets'] = includedSuggestionSets
          .map((IncludedSuggestionSet value) => value.toJson())
          .toList();
    }
    var includedElementKinds = this.includedElementKinds;
    if (includedElementKinds != null) {
      result['includedElementKinds'] = includedElementKinds
          .map((ElementKind value) => value.toJson())
          .toList();
    }
    var includedSuggestionRelevanceTags = this.includedSuggestionRelevanceTags;
    if (includedSuggestionRelevanceTags != null) {
      result['includedSuggestionRelevanceTags'] =
          includedSuggestionRelevanceTags
              .map((IncludedSuggestionRelevanceTag value) => value.toJson())
              .toList();
    }
    return result;
  }

  Notification toNotification() {
    return Notification('completion.results', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionResultsParams) {
      return id == other.id &&
          replacementOffset == other.replacementOffset &&
          replacementLength == other.replacementLength &&
          listEqual(results, other.results,
              (CompletionSuggestion a, CompletionSuggestion b) => a == b) &&
          isLast == other.isLast &&
          libraryFile == other.libraryFile &&
          listEqual(includedSuggestionSets, other.includedSuggestionSets,
              (IncludedSuggestionSet a, IncludedSuggestionSet b) => a == b) &&
          listEqual(includedElementKinds, other.includedElementKinds,
              (ElementKind a, ElementKind b) => a == b) &&
          listEqual(
              includedSuggestionRelevanceTags,
              other.includedSuggestionRelevanceTags,
              (IncludedSuggestionRelevanceTag a,
                      IncludedSuggestionRelevanceTag b) =>
                  a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        id,
        replacementOffset,
        replacementLength,
        Object.hashAll(results),
        isLast,
        libraryFile,
        Object.hashAll(includedSuggestionSets ?? []),
        Object.hashAll(includedElementKinds ?? []),
        Object.hashAll(includedSuggestionRelevanceTags ?? []),
      );
}

/// CompletionService
///
/// enum {
///   AVAILABLE_SUGGESTION_SETS
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionService implements Enum {
  /// The client will receive availableSuggestions notifications once
  /// subscribed with completion suggestion sets from the libraries of
  /// interest. The client should keep an up-to-date record of these in memory
  /// so that it will be able to union these candidates with other completion
  /// suggestions when applicable at completion time.
  ///
  /// The client will also receive existingImports notifications.
  static const CompletionService AVAILABLE_SUGGESTION_SETS =
      CompletionService._('AVAILABLE_SUGGESTION_SETS');

  /// A list containing all of the enum values that are defined.
  static const List<CompletionService> VALUES = <CompletionService>[
    AVAILABLE_SUGGESTION_SETS
  ];

  @override
  final String name;

  const CompletionService._(this.name);

  factory CompletionService(String name) {
    switch (name) {
      case 'AVAILABLE_SUGGESTION_SETS':
        return AVAILABLE_SUGGESTION_SETS;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory CompletionService.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    if (json is String) {
      try {
        return CompletionService(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'CompletionService', json);
  }

  @override
  String toString() => 'CompletionService.$name';

  String toJson() => name;
}

/// completion.setSubscriptions params
///
/// {
///   "subscriptions": List<CompletionService>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionSetSubscriptionsParams implements RequestParams {
  /// A list of the services being subscribed to.
  List<CompletionService> subscriptions;

  CompletionSetSubscriptionsParams(this.subscriptions);

  factory CompletionSetSubscriptionsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<CompletionService> subscriptions;
      if (json.containsKey('subscriptions')) {
        subscriptions = jsonDecoder.decodeList(
            '$jsonPath.subscriptions',
            json['subscriptions'],
            (String jsonPath, Object? json) =>
                CompletionService.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'subscriptions');
      }
      return CompletionSetSubscriptionsParams(subscriptions);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'completion.setSubscriptions params', json);
    }
  }

  factory CompletionSetSubscriptionsParams.fromRequest(Request request) {
    return CompletionSetSubscriptionsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['subscriptions'] =
        subscriptions.map((CompletionService value) => value.toJson()).toList();
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'completion.setSubscriptions', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionSetSubscriptionsParams) {
      return listEqual(subscriptions, other.subscriptions,
          (CompletionService a, CompletionService b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(subscriptions);
}

/// completion.setSubscriptions result
///
/// Clients may not extend, implement or mix-in this class.
class CompletionSetSubscriptionsResult implements ResponseResult {
  @override
  Map<String, Object> toJson() => {};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) => other is CompletionSetSubscriptionsResult;

  @override
  int get hashCode => 2482770;
}

/// ContextData
///
/// {
///   "name": String
///   "explicitFileCount": int
///   "implicitFileCount": int
///   "workItemQueueLength": int
///   "cacheEntryExceptions": List<String>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ContextData implements HasToJson {
  /// The name of the context.
  String name;

  /// Explicitly analyzed files.
  int explicitFileCount;

  /// Implicitly analyzed files.
  int implicitFileCount;

  /// The number of work items in the queue.
  int workItemQueueLength;

  /// Exceptions associated with cache entries.
  List<String> cacheEntryExceptions;

  ContextData(this.name, this.explicitFileCount, this.implicitFileCount,
      this.workItemQueueLength, this.cacheEntryExceptions);

  factory ContextData.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString('$jsonPath.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      int explicitFileCount;
      if (json.containsKey('explicitFileCount')) {
        explicitFileCount = jsonDecoder.decodeInt(
            '$jsonPath.explicitFileCount', json['explicitFileCount']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'explicitFileCount');
      }
      int implicitFileCount;
      if (json.containsKey('implicitFileCount')) {
        implicitFileCount = jsonDecoder.decodeInt(
            '$jsonPath.implicitFileCount', json['implicitFileCount']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'implicitFileCount');
      }
      int workItemQueueLength;
      if (json.containsKey('workItemQueueLength')) {
        workItemQueueLength = jsonDecoder.decodeInt(
            '$jsonPath.workItemQueueLength', json['workItemQueueLength']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'workItemQueueLength');
      }
      List<String> cacheEntryExceptions;
      if (json.containsKey('cacheEntryExceptions')) {
        cacheEntryExceptions = jsonDecoder.decodeList(
            '$jsonPath.cacheEntryExceptions',
            json['cacheEntryExceptions'],
            jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'cacheEntryExceptions');
      }
      return ContextData(name, explicitFileCount, implicitFileCount,
          workItemQueueLength, cacheEntryExceptions);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ContextData', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['name'] = name;
    result['explicitFileCount'] = explicitFileCount;
    result['implicitFileCount'] = implicitFileCount;
    result['workItemQueueLength'] = workItemQueueLength;
    result['cacheEntryExceptions'] = cacheEntryExceptions;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ContextData) {
      return name == other.name &&
          explicitFileCount == other.explicitFileCount &&
          implicitFileCount == other.implicitFileCount &&
          workItemQueueLength == other.workItemQueueLength &&
          listEqual(cacheEntryExceptions, other.cacheEntryExceptions,
              (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        name,
        explicitFileCount,
        implicitFileCount,
        workItemQueueLength,
        Object.hashAll(cacheEntryExceptions),
      );
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

/// diagnostic.getDiagnostics params
///
/// Clients may not extend, implement or mix-in this class.
class DiagnosticGetDiagnosticsParams implements RequestParams {
  @override
  Map<String, Object> toJson() => {};

  @override
  Request toRequest(String id) {
    return Request(id, 'diagnostic.getDiagnostics', null);
  }

  @override
  bool operator ==(other) => other is DiagnosticGetDiagnosticsParams;

  @override
  int get hashCode => 587526202;
}

/// diagnostic.getDiagnostics result
///
/// {
///   "contexts": List<ContextData>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class DiagnosticGetDiagnosticsResult implements ResponseResult {
  /// The list of analysis contexts.
  List<ContextData> contexts;

  DiagnosticGetDiagnosticsResult(this.contexts);

  factory DiagnosticGetDiagnosticsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<ContextData> contexts;
      if (json.containsKey('contexts')) {
        contexts = jsonDecoder.decodeList(
            '$jsonPath.contexts',
            json['contexts'],
            (String jsonPath, Object? json) =>
                ContextData.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'contexts');
      }
      return DiagnosticGetDiagnosticsResult(contexts);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'diagnostic.getDiagnostics result', json);
    }
  }

  factory DiagnosticGetDiagnosticsResult.fromResponse(Response response) {
    return DiagnosticGetDiagnosticsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['contexts'] =
        contexts.map((ContextData value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is DiagnosticGetDiagnosticsResult) {
      return listEqual(
          contexts, other.contexts, (ContextData a, ContextData b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(contexts);
}

/// diagnostic.getServerPort params
///
/// Clients may not extend, implement or mix-in this class.
class DiagnosticGetServerPortParams implements RequestParams {
  @override
  Map<String, Object> toJson() => {};

  @override
  Request toRequest(String id) {
    return Request(id, 'diagnostic.getServerPort', null);
  }

  @override
  bool operator ==(other) => other is DiagnosticGetServerPortParams;

  @override
  int get hashCode => 367508704;
}

/// diagnostic.getServerPort result
///
/// {
///   "port": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class DiagnosticGetServerPortResult implements ResponseResult {
  /// The diagnostic server port.
  int port;

  DiagnosticGetServerPortResult(this.port);

  factory DiagnosticGetServerPortResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      int port;
      if (json.containsKey('port')) {
        port = jsonDecoder.decodeInt('$jsonPath.port', json['port']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'port');
      }
      return DiagnosticGetServerPortResult(port);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'diagnostic.getServerPort result', json);
    }
  }

  factory DiagnosticGetServerPortResult.fromResponse(Response response) {
    return DiagnosticGetServerPortResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['port'] = port;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is DiagnosticGetServerPortResult) {
      return port == other.port;
    }
    return false;
  }

  @override
  int get hashCode => port.hashCode;
}

/// edit.bulkFixes params
///
/// {
///   "included": List<FilePath>
///   "inTestMode": optional bool
///   "codes": optional List<String>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditBulkFixesParams implements RequestParams {
  /// A list of the files and directories for which edits should be suggested.
  ///
  /// If a request is made with a path that is invalid, e.g. is not absolute
  /// and normalized, an error of type INVALID_FILE_PATH_FORMAT will be
  /// generated. If a request is made for a file which does not exist, or which
  /// is not currently subject to analysis (e.g. because it is not associated
  /// with any analysis root specified to analysis.setAnalysisRoots), an error
  /// of type FILE_NOT_ANALYZED will be generated.
  List<String> included;

  /// A flag indicating whether the bulk fixes are being run in test mode. The
  /// only difference is that in test mode the fix processor will look for a
  /// configuration file that can modify the content of the data file used to
  /// compute the fixes when data-driven fixes are being considered.
  ///
  /// If this field is omitted the flag defaults to false.
  bool? inTestMode;

  /// A list of diagnostic codes to be fixed.
  List<String>? codes;

  EditBulkFixesParams(this.included, {this.inTestMode, this.codes});

  factory EditBulkFixesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<String> included;
      if (json.containsKey('included')) {
        included = jsonDecoder.decodeList(
            '$jsonPath.included', json['included'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'included');
      }
      bool? inTestMode;
      if (json.containsKey('inTestMode')) {
        inTestMode =
            jsonDecoder.decodeBool('$jsonPath.inTestMode', json['inTestMode']);
      }
      List<String>? codes;
      if (json.containsKey('codes')) {
        codes = jsonDecoder.decodeList(
            '$jsonPath.codes', json['codes'], jsonDecoder.decodeString);
      }
      return EditBulkFixesParams(included,
          inTestMode: inTestMode, codes: codes);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.bulkFixes params', json);
    }
  }

  factory EditBulkFixesParams.fromRequest(Request request) {
    return EditBulkFixesParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['included'] = included;
    var inTestMode = this.inTestMode;
    if (inTestMode != null) {
      result['inTestMode'] = inTestMode;
    }
    var codes = this.codes;
    if (codes != null) {
      result['codes'] = codes;
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.bulkFixes', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditBulkFixesParams) {
      return listEqual(
              included, other.included, (String a, String b) => a == b) &&
          inTestMode == other.inTestMode &&
          listEqual(codes, other.codes, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(included),
        inTestMode,
        Object.hashAll(codes ?? []),
      );
}

/// edit.bulkFixes result
///
/// {
///   "message": String
///   "edits": List<SourceFileEdit>
///   "details": List<BulkFix>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditBulkFixesResult implements ResponseResult {
  /// An optional message explaining unapplied fixes.
  String message;

  /// A list of source edits to apply the recommended changes.
  List<SourceFileEdit> edits;

  /// Details that summarize the fixes associated with the recommended changes.
  List<BulkFix> details;

  EditBulkFixesResult(this.message, this.edits, this.details);

  factory EditBulkFixesResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String message;
      if (json.containsKey('message')) {
        message =
            jsonDecoder.decodeString('$jsonPath.message', json['message']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'message');
      }
      List<SourceFileEdit> edits;
      if (json.containsKey('edits')) {
        edits = jsonDecoder.decodeList(
            '$jsonPath.edits',
            json['edits'],
            (String jsonPath, Object? json) =>
                SourceFileEdit.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'edits');
      }
      List<BulkFix> details;
      if (json.containsKey('details')) {
        details = jsonDecoder.decodeList(
            '$jsonPath.details',
            json['details'],
            (String jsonPath, Object? json) =>
                BulkFix.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'details');
      }
      return EditBulkFixesResult(message, edits, details);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.bulkFixes result', json);
    }
  }

  factory EditBulkFixesResult.fromResponse(Response response) {
    return EditBulkFixesResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['message'] = message;
    result['edits'] =
        edits.map((SourceFileEdit value) => value.toJson()).toList();
    result['details'] = details.map((BulkFix value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditBulkFixesResult) {
      return message == other.message &&
          listEqual(edits, other.edits,
              (SourceFileEdit a, SourceFileEdit b) => a == b) &&
          listEqual(details, other.details, (BulkFix a, BulkFix b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        message,
        Object.hashAll(edits),
        Object.hashAll(details),
      );
}

/// edit.formatIfEnabled params
///
/// {
///   "directories": List<FilePath>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditFormatIfEnabledParams implements RequestParams {
  /// The paths of the directories containing the code to be formatted.
  List<String> directories;

  EditFormatIfEnabledParams(this.directories);

  factory EditFormatIfEnabledParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<String> directories;
      if (json.containsKey('directories')) {
        directories = jsonDecoder.decodeList('$jsonPath.directories',
            json['directories'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'directories');
      }
      return EditFormatIfEnabledParams(directories);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.formatIfEnabled params', json);
    }
  }

  factory EditFormatIfEnabledParams.fromRequest(Request request) {
    return EditFormatIfEnabledParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['directories'] = directories;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.formatIfEnabled', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditFormatIfEnabledParams) {
      return listEqual(
          directories, other.directories, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(directories);
}

/// edit.formatIfEnabled result
///
/// {
///   "edits": List<SourceFileEdit>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditFormatIfEnabledResult implements ResponseResult {
  /// The edit(s) to be applied in order to format the code. The list will be
  /// empty if none of the files were formatted, whether because they were not
  /// eligible to be formatted or because they were already formatted.
  List<SourceFileEdit> edits;

  EditFormatIfEnabledResult(this.edits);

  factory EditFormatIfEnabledResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<SourceFileEdit> edits;
      if (json.containsKey('edits')) {
        edits = jsonDecoder.decodeList(
            '$jsonPath.edits',
            json['edits'],
            (String jsonPath, Object? json) =>
                SourceFileEdit.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'edits');
      }
      return EditFormatIfEnabledResult(edits);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.formatIfEnabled result', json);
    }
  }

  factory EditFormatIfEnabledResult.fromResponse(Response response) {
    return EditFormatIfEnabledResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['edits'] =
        edits.map((SourceFileEdit value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditFormatIfEnabledResult) {
      return listEqual(
          edits, other.edits, (SourceFileEdit a, SourceFileEdit b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(edits);
}

/// edit.format params
///
/// {
///   "file": FilePath
///   "selectionOffset": int
///   "selectionLength": int
///   "lineLength": optional int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditFormatParams implements RequestParams {
  /// The file containing the code to be formatted.
  String file;

  /// The offset of the current selection in the file.
  int selectionOffset;

  /// The length of the current selection in the file.
  int selectionLength;

  /// The line length to be used by the formatter.
  int? lineLength;

  EditFormatParams(this.file, this.selectionOffset, this.selectionLength,
      {this.lineLength});

  factory EditFormatParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int selectionOffset;
      if (json.containsKey('selectionOffset')) {
        selectionOffset = jsonDecoder.decodeInt(
            '$jsonPath.selectionOffset', json['selectionOffset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'selectionOffset');
      }
      int selectionLength;
      if (json.containsKey('selectionLength')) {
        selectionLength = jsonDecoder.decodeInt(
            '$jsonPath.selectionLength', json['selectionLength']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'selectionLength');
      }
      int? lineLength;
      if (json.containsKey('lineLength')) {
        lineLength =
            jsonDecoder.decodeInt('$jsonPath.lineLength', json['lineLength']);
      }
      return EditFormatParams(file, selectionOffset, selectionLength,
          lineLength: lineLength);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.format params', json);
    }
  }

  factory EditFormatParams.fromRequest(Request request) {
    return EditFormatParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['selectionOffset'] = selectionOffset;
    result['selectionLength'] = selectionLength;
    var lineLength = this.lineLength;
    if (lineLength != null) {
      result['lineLength'] = lineLength;
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.format', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditFormatParams) {
      return file == other.file &&
          selectionOffset == other.selectionOffset &&
          selectionLength == other.selectionLength &&
          lineLength == other.lineLength;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        selectionOffset,
        selectionLength,
        lineLength,
      );
}

/// edit.format result
///
/// {
///   "edits": List<SourceEdit>
///   "selectionOffset": int
///   "selectionLength": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditFormatResult implements ResponseResult {
  /// The edit(s) to be applied in order to format the code. The list will be
  /// empty if the code was already formatted (there are no changes).
  List<SourceEdit> edits;

  /// The offset of the selection after formatting the code.
  int selectionOffset;

  /// The length of the selection after formatting the code.
  int selectionLength;

  EditFormatResult(this.edits, this.selectionOffset, this.selectionLength);

  factory EditFormatResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<SourceEdit> edits;
      if (json.containsKey('edits')) {
        edits = jsonDecoder.decodeList(
            '$jsonPath.edits',
            json['edits'],
            (String jsonPath, Object? json) =>
                SourceEdit.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'edits');
      }
      int selectionOffset;
      if (json.containsKey('selectionOffset')) {
        selectionOffset = jsonDecoder.decodeInt(
            '$jsonPath.selectionOffset', json['selectionOffset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'selectionOffset');
      }
      int selectionLength;
      if (json.containsKey('selectionLength')) {
        selectionLength = jsonDecoder.decodeInt(
            '$jsonPath.selectionLength', json['selectionLength']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'selectionLength');
      }
      return EditFormatResult(edits, selectionOffset, selectionLength);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.format result', json);
    }
  }

  factory EditFormatResult.fromResponse(Response response) {
    return EditFormatResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['edits'] = edits.map((SourceEdit value) => value.toJson()).toList();
    result['selectionOffset'] = selectionOffset;
    result['selectionLength'] = selectionLength;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditFormatResult) {
      return listEqual(
              edits, other.edits, (SourceEdit a, SourceEdit b) => a == b) &&
          selectionOffset == other.selectionOffset &&
          selectionLength == other.selectionLength;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(edits),
        selectionOffset,
        selectionLength,
      );
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
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
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

  factory EditGetAssistsParams.fromRequest(Request request) {
    return EditGetAssistsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['offset'] = offset;
    result['length'] = length;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.getAssists', toJson());
  }

  @override
  String toString() => json.encode(toJson());

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
  int get hashCode => Object.hash(
        file,
        offset,
        length,
      );
}

/// edit.getAssists result
///
/// {
///   "assists": List<SourceChange>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetAssistsResult implements ResponseResult {
  /// The assists that are available at the given location.
  List<SourceChange> assists;

  EditGetAssistsResult(this.assists);

  factory EditGetAssistsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<SourceChange> assists;
      if (json.containsKey('assists')) {
        assists = jsonDecoder.decodeList(
            '$jsonPath.assists',
            json['assists'],
            (String jsonPath, Object? json) =>
                SourceChange.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'assists');
      }
      return EditGetAssistsResult(assists);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.getAssists result', json);
    }
  }

  factory EditGetAssistsResult.fromResponse(Response response) {
    return EditGetAssistsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['assists'] =
        assists.map((SourceChange value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetAssistsResult) {
      return listEqual(
          assists, other.assists, (SourceChange a, SourceChange b) => a == b);
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
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
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
          jsonPath, 'edit.getAvailableRefactorings params', json);
    }
  }

  factory EditGetAvailableRefactoringsParams.fromRequest(Request request) {
    return EditGetAvailableRefactoringsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['offset'] = offset;
    result['length'] = length;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.getAvailableRefactorings', toJson());
  }

  @override
  String toString() => json.encode(toJson());

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
  int get hashCode => Object.hash(
        file,
        offset,
        length,
      );
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
  List<RefactoringKind> kinds;

  EditGetAvailableRefactoringsResult(this.kinds);

  factory EditGetAvailableRefactoringsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<RefactoringKind> kinds;
      if (json.containsKey('kinds')) {
        kinds = jsonDecoder.decodeList(
            '$jsonPath.kinds',
            json['kinds'],
            (String jsonPath, Object? json) =>
                RefactoringKind.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kinds');
      }
      return EditGetAvailableRefactoringsResult(kinds);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'edit.getAvailableRefactorings result', json);
    }
  }

  factory EditGetAvailableRefactoringsResult.fromResponse(Response response) {
    return EditGetAvailableRefactoringsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['kinds'] =
        kinds.map((RefactoringKind value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetAvailableRefactoringsResult) {
      return listEqual(
          kinds, other.kinds, (RefactoringKind a, RefactoringKind b) => a == b);
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
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
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

  factory EditGetFixesParams.fromRequest(Request request) {
    return EditGetFixesParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['offset'] = offset;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.getFixes', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetFixesParams) {
      return file == other.file && offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        offset,
      );
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
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<AnalysisErrorFixes> fixes;
      if (json.containsKey('fixes')) {
        fixes = jsonDecoder.decodeList(
            '$jsonPath.fixes',
            json['fixes'],
            (String jsonPath, Object? json) =>
                AnalysisErrorFixes.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'fixes');
      }
      return EditGetFixesResult(fixes);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.getFixes result', json);
    }
  }

  factory EditGetFixesResult.fromResponse(Response response) {
    return EditGetFixesResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['fixes'] =
        fixes.map((AnalysisErrorFixes value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetFixesResult) {
      return listEqual(fixes, other.fixes,
          (AnalysisErrorFixes a, AnalysisErrorFixes b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(fixes);
}

/// edit.getPostfixCompletion params
///
/// {
///   "file": FilePath
///   "key": String
///   "offset": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetPostfixCompletionParams implements RequestParams {
  /// The file containing the postfix template to be expanded.
  String file;

  /// The unique name that identifies the template in use.
  String key;

  /// The offset used to identify the code to which the template will be
  /// applied.
  int offset;

  EditGetPostfixCompletionParams(this.file, this.key, this.offset);

  factory EditGetPostfixCompletionParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      String key;
      if (json.containsKey('key')) {
        key = jsonDecoder.decodeString('$jsonPath.key', json['key']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'key');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt('$jsonPath.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      return EditGetPostfixCompletionParams(file, key, offset);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'edit.getPostfixCompletion params', json);
    }
  }

  factory EditGetPostfixCompletionParams.fromRequest(Request request) {
    return EditGetPostfixCompletionParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['key'] = key;
    result['offset'] = offset;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.getPostfixCompletion', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetPostfixCompletionParams) {
      return file == other.file && key == other.key && offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        key,
        offset,
      );
}

/// edit.getPostfixCompletion result
///
/// {
///   "change": SourceChange
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetPostfixCompletionResult implements ResponseResult {
  /// The change to be applied in order to complete the statement.
  SourceChange change;

  EditGetPostfixCompletionResult(this.change);

  factory EditGetPostfixCompletionResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      SourceChange change;
      if (json.containsKey('change')) {
        change = SourceChange.fromJson(
            jsonDecoder, '$jsonPath.change', json['change']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'change');
      }
      return EditGetPostfixCompletionResult(change);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'edit.getPostfixCompletion result', json);
    }
  }

  factory EditGetPostfixCompletionResult.fromResponse(Response response) {
    return EditGetPostfixCompletionResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['change'] = change.toJson();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetPostfixCompletionResult) {
      return change == other.change;
    }
    return false;
  }

  @override
  int get hashCode => change.hashCode;
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
      this.kind, this.file, this.offset, this.length, this.validateOnly,
      {this.options});

  factory EditGetRefactoringParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      RefactoringKind kind;
      if (json.containsKey('kind')) {
        kind = RefactoringKind.fromJson(
            jsonDecoder, '$jsonPath.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
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
            '$jsonPath.validateOnly', json['validateOnly']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'validateOnly');
      }
      RefactoringOptions? options;
      if (json.containsKey('options')) {
        options = RefactoringOptions.fromJson(
            jsonDecoder, '$jsonPath.options', json['options'], kind);
      }
      return EditGetRefactoringParams(kind, file, offset, length, validateOnly,
          options: options);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.getRefactoring params', json);
    }
  }

  factory EditGetRefactoringParams.fromRequest(Request request) {
    var params = EditGetRefactoringParams.fromJson(
        RequestDecoder(request), 'params', request.params);
    REQUEST_ID_REFACTORING_KINDS[request.id] = params.kind;
    return params;
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['kind'] = kind.toJson();
    result['file'] = file;
    result['offset'] = offset;
    result['length'] = length;
    result['validateOnly'] = validateOnly;
    var options = this.options;
    if (options != null) {
      result['options'] = options.toJson();
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.getRefactoring', toJson());
  }

  @override
  String toString() => json.encode(toJson());

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
  int get hashCode => Object.hash(
        kind,
        file,
        offset,
        length,
        validateOnly,
        options,
      );
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
  /// The initial status of the refactoring, i.e. problems related to the
  /// context in which the refactoring is requested. The array will be empty if
  /// there are no known problems.
  List<RefactoringProblem> initialProblems;

  /// The options validation status, i.e. problems in the given options, such
  /// as light-weight validation of a new name, flags compatibility, etc. The
  /// array will be empty if there are no known problems.
  List<RefactoringProblem> optionsProblems;

  /// The final status of the refactoring, i.e. problems identified in the
  /// result of a full, potentially expensive validation and / or change
  /// creation. The array will be empty if there are no known problems.
  List<RefactoringProblem> finalProblems;

  /// Data used to provide feedback to the user. The structure of the data is
  /// dependent on the kind of refactoring being created. The data that is
  /// returned is documented in the section titled Refactorings, labeled as
  /// "Feedback".
  RefactoringFeedback? feedback;

  /// The changes that are to be applied to affect the refactoring. This field
  /// will be omitted if there are problems that prevent a set of changes from
  /// being computed, such as having no options specified for a refactoring
  /// that requires them, or if only validation was requested.
  SourceChange? change;

  /// The ids of source edits that are not known to be valid. An edit is not
  /// known to be valid if there was insufficient type information for the
  /// server to be able to determine whether or not the code needs to be
  /// modified, such as when a member is being renamed and there is a reference
  /// to a member from an unknown type. This field will be omitted if the
  /// change field is omitted or if there are no potential edits for the
  /// refactoring.
  List<String>? potentialEdits;

  EditGetRefactoringResult(
      this.initialProblems, this.optionsProblems, this.finalProblems,
      {this.feedback, this.change, this.potentialEdits});

  factory EditGetRefactoringResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<RefactoringProblem> initialProblems;
      if (json.containsKey('initialProblems')) {
        initialProblems = jsonDecoder.decodeList(
            '$jsonPath.initialProblems',
            json['initialProblems'],
            (String jsonPath, Object? json) =>
                RefactoringProblem.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'initialProblems');
      }
      List<RefactoringProblem> optionsProblems;
      if (json.containsKey('optionsProblems')) {
        optionsProblems = jsonDecoder.decodeList(
            '$jsonPath.optionsProblems',
            json['optionsProblems'],
            (String jsonPath, Object? json) =>
                RefactoringProblem.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'optionsProblems');
      }
      List<RefactoringProblem> finalProblems;
      if (json.containsKey('finalProblems')) {
        finalProblems = jsonDecoder.decodeList(
            '$jsonPath.finalProblems',
            json['finalProblems'],
            (String jsonPath, Object? json) =>
                RefactoringProblem.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'finalProblems');
      }
      RefactoringFeedback? feedback;
      if (json.containsKey('feedback')) {
        feedback = RefactoringFeedback.fromJson(
            jsonDecoder, '$jsonPath.feedback', json['feedback'], json);
      }
      SourceChange? change;
      if (json.containsKey('change')) {
        change = SourceChange.fromJson(
            jsonDecoder, '$jsonPath.change', json['change']);
      }
      List<String>? potentialEdits;
      if (json.containsKey('potentialEdits')) {
        potentialEdits = jsonDecoder.decodeList('$jsonPath.potentialEdits',
            json['potentialEdits'], jsonDecoder.decodeString);
      }
      return EditGetRefactoringResult(
          initialProblems, optionsProblems, finalProblems,
          feedback: feedback, change: change, potentialEdits: potentialEdits);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.getRefactoring result', json);
    }
  }

  factory EditGetRefactoringResult.fromResponse(Response response) {
    return EditGetRefactoringResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['initialProblems'] = initialProblems
        .map((RefactoringProblem value) => value.toJson())
        .toList();
    result['optionsProblems'] = optionsProblems
        .map((RefactoringProblem value) => value.toJson())
        .toList();
    result['finalProblems'] = finalProblems
        .map((RefactoringProblem value) => value.toJson())
        .toList();
    var feedback = this.feedback;
    if (feedback != null) {
      result['feedback'] = feedback.toJson();
    }
    var change = this.change;
    if (change != null) {
      result['change'] = change.toJson();
    }
    var potentialEdits = this.potentialEdits;
    if (potentialEdits != null) {
      result['potentialEdits'] = potentialEdits;
    }
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetRefactoringResult) {
      return listEqual(initialProblems, other.initialProblems,
              (RefactoringProblem a, RefactoringProblem b) => a == b) &&
          listEqual(optionsProblems, other.optionsProblems,
              (RefactoringProblem a, RefactoringProblem b) => a == b) &&
          listEqual(finalProblems, other.finalProblems,
              (RefactoringProblem a, RefactoringProblem b) => a == b) &&
          feedback == other.feedback &&
          change == other.change &&
          listEqual(potentialEdits, other.potentialEdits,
              (String a, String b) => a == b);
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

/// edit.getStatementCompletion params
///
/// {
///   "file": FilePath
///   "offset": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetStatementCompletionParams implements RequestParams {
  /// The file containing the statement to be completed.
  String file;

  /// The offset used to identify the statement to be completed.
  int offset;

  EditGetStatementCompletionParams(this.file, this.offset);

  factory EditGetStatementCompletionParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt('$jsonPath.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      return EditGetStatementCompletionParams(file, offset);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'edit.getStatementCompletion params', json);
    }
  }

  factory EditGetStatementCompletionParams.fromRequest(Request request) {
    return EditGetStatementCompletionParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['offset'] = offset;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.getStatementCompletion', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetStatementCompletionParams) {
      return file == other.file && offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        offset,
      );
}

/// edit.getStatementCompletion result
///
/// {
///   "change": SourceChange
///   "whitespaceOnly": bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetStatementCompletionResult implements ResponseResult {
  /// The change to be applied in order to complete the statement.
  SourceChange change;

  /// Will be true if the change contains nothing but whitespace characters, or
  /// is empty.
  bool whitespaceOnly;

  EditGetStatementCompletionResult(this.change, this.whitespaceOnly);

  factory EditGetStatementCompletionResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      SourceChange change;
      if (json.containsKey('change')) {
        change = SourceChange.fromJson(
            jsonDecoder, '$jsonPath.change', json['change']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'change');
      }
      bool whitespaceOnly;
      if (json.containsKey('whitespaceOnly')) {
        whitespaceOnly = jsonDecoder.decodeBool(
            '$jsonPath.whitespaceOnly', json['whitespaceOnly']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'whitespaceOnly');
      }
      return EditGetStatementCompletionResult(change, whitespaceOnly);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'edit.getStatementCompletion result', json);
    }
  }

  factory EditGetStatementCompletionResult.fromResponse(Response response) {
    return EditGetStatementCompletionResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['change'] = change.toJson();
    result['whitespaceOnly'] = whitespaceOnly;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetStatementCompletionResult) {
      return change == other.change && whitespaceOnly == other.whitespaceOnly;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        change,
        whitespaceOnly,
      );
}

/// edit.importElements params
///
/// {
///   "file": FilePath
///   "elements": List<ImportedElements>
///   "offset": optional int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditImportElementsParams implements RequestParams {
  /// The file in which the specified elements are to be made accessible.
  String file;

  /// The elements to be made accessible in the specified file.
  List<ImportedElements> elements;

  /// The offset at which the specified elements need to be made accessible. If
  /// provided, this is used to guard against adding imports for text that
  /// would be inserted into a comment, string literal, or other location where
  /// the imports would not be necessary.
  int? offset;

  EditImportElementsParams(this.file, this.elements, {this.offset});

  factory EditImportElementsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      List<ImportedElements> elements;
      if (json.containsKey('elements')) {
        elements = jsonDecoder.decodeList(
            '$jsonPath.elements',
            json['elements'],
            (String jsonPath, Object? json) =>
                ImportedElements.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'elements');
      }
      int? offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt('$jsonPath.offset', json['offset']);
      }
      return EditImportElementsParams(file, elements, offset: offset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.importElements params', json);
    }
  }

  factory EditImportElementsParams.fromRequest(Request request) {
    return EditImportElementsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['elements'] =
        elements.map((ImportedElements value) => value.toJson()).toList();
    var offset = this.offset;
    if (offset != null) {
      result['offset'] = offset;
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.importElements', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditImportElementsParams) {
      return file == other.file &&
          listEqual(elements, other.elements,
              (ImportedElements a, ImportedElements b) => a == b) &&
          offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        Object.hashAll(elements),
        offset,
      );
}

/// edit.importElements result
///
/// {
///   "edit": optional SourceFileEdit
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditImportElementsResult implements ResponseResult {
  /// The edits to be applied in order to make the specified elements
  /// accessible. The file to be edited will be the defining compilation unit
  /// of the library containing the file specified in the request, which can be
  /// different than the file specified in the request if the specified file is
  /// a part file. This field will be omitted if there are no edits that need
  /// to be applied.
  SourceFileEdit? edit;

  EditImportElementsResult({this.edit});

  factory EditImportElementsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      SourceFileEdit? edit;
      if (json.containsKey('edit')) {
        edit = SourceFileEdit.fromJson(
            jsonDecoder, '$jsonPath.edit', json['edit']);
      }
      return EditImportElementsResult(edit: edit);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.importElements result', json);
    }
  }

  factory EditImportElementsResult.fromResponse(Response response) {
    return EditImportElementsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    var edit = this.edit;
    if (edit != null) {
      result['edit'] = edit.toJson();
    }
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditImportElementsResult) {
      return edit == other.edit;
    }
    return false;
  }

  @override
  int get hashCode => edit.hashCode;
}

/// edit.isPostfixCompletionApplicable params
///
/// {
///   "file": FilePath
///   "key": String
///   "offset": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditIsPostfixCompletionApplicableParams implements RequestParams {
  /// The file containing the postfix template to be expanded.
  String file;

  /// The unique name that identifies the template in use.
  String key;

  /// The offset used to identify the code to which the template will be
  /// applied.
  int offset;

  EditIsPostfixCompletionApplicableParams(this.file, this.key, this.offset);

  factory EditIsPostfixCompletionApplicableParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      String key;
      if (json.containsKey('key')) {
        key = jsonDecoder.decodeString('$jsonPath.key', json['key']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'key');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt('$jsonPath.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      return EditIsPostfixCompletionApplicableParams(file, key, offset);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'edit.isPostfixCompletionApplicable params', json);
    }
  }

  factory EditIsPostfixCompletionApplicableParams.fromRequest(Request request) {
    return EditIsPostfixCompletionApplicableParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['key'] = key;
    result['offset'] = offset;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.isPostfixCompletionApplicable', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditIsPostfixCompletionApplicableParams) {
      return file == other.file && key == other.key && offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        key,
        offset,
      );
}

/// edit.isPostfixCompletionApplicable result
///
/// {
///   "value": bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditIsPostfixCompletionApplicableResult implements ResponseResult {
  /// True if the template can be expanded at the given location.
  bool value;

  EditIsPostfixCompletionApplicableResult(this.value);

  factory EditIsPostfixCompletionApplicableResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      bool value;
      if (json.containsKey('value')) {
        value = jsonDecoder.decodeBool('$jsonPath.value', json['value']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'value');
      }
      return EditIsPostfixCompletionApplicableResult(value);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'edit.isPostfixCompletionApplicable result', json);
    }
  }

  factory EditIsPostfixCompletionApplicableResult.fromResponse(
      Response response) {
    return EditIsPostfixCompletionApplicableResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['value'] = value;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditIsPostfixCompletionApplicableResult) {
      return value == other.value;
    }
    return false;
  }

  @override
  int get hashCode => value.hashCode;
}

/// edit.listPostfixCompletionTemplates params
///
/// Clients may not extend, implement or mix-in this class.
class EditListPostfixCompletionTemplatesParams implements RequestParams {
  @override
  Map<String, Object> toJson() => {};

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.listPostfixCompletionTemplates', null);
  }

  @override
  bool operator ==(other) => other is EditListPostfixCompletionTemplatesParams;

  @override
  int get hashCode => 690713107;
}

/// edit.listPostfixCompletionTemplates result
///
/// {
///   "templates": List<PostfixTemplateDescriptor>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditListPostfixCompletionTemplatesResult implements ResponseResult {
  /// The list of available templates.
  List<PostfixTemplateDescriptor> templates;

  EditListPostfixCompletionTemplatesResult(this.templates);

  factory EditListPostfixCompletionTemplatesResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<PostfixTemplateDescriptor> templates;
      if (json.containsKey('templates')) {
        templates = jsonDecoder.decodeList(
            '$jsonPath.templates',
            json['templates'],
            (String jsonPath, Object? json) =>
                PostfixTemplateDescriptor.fromJson(
                    jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'templates');
      }
      return EditListPostfixCompletionTemplatesResult(templates);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'edit.listPostfixCompletionTemplates result', json);
    }
  }

  factory EditListPostfixCompletionTemplatesResult.fromResponse(
      Response response) {
    return EditListPostfixCompletionTemplatesResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['templates'] = templates
        .map((PostfixTemplateDescriptor value) => value.toJson())
        .toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditListPostfixCompletionTemplatesResult) {
      return listEqual(templates, other.templates,
          (PostfixTemplateDescriptor a, PostfixTemplateDescriptor b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(templates);
}

/// edit.organizeDirectives params
///
/// {
///   "file": FilePath
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditOrganizeDirectivesParams implements RequestParams {
  /// The Dart file to organize directives in.
  String file;

  EditOrganizeDirectivesParams(this.file);

  factory EditOrganizeDirectivesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      return EditOrganizeDirectivesParams(file);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'edit.organizeDirectives params', json);
    }
  }

  factory EditOrganizeDirectivesParams.fromRequest(Request request) {
    return EditOrganizeDirectivesParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.organizeDirectives', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditOrganizeDirectivesParams) {
      return file == other.file;
    }
    return false;
  }

  @override
  int get hashCode => file.hashCode;
}

/// edit.organizeDirectives result
///
/// {
///   "edit": SourceFileEdit
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditOrganizeDirectivesResult implements ResponseResult {
  /// The file edit that is to be applied to the given file to effect the
  /// organizing.
  SourceFileEdit edit;

  EditOrganizeDirectivesResult(this.edit);

  factory EditOrganizeDirectivesResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      SourceFileEdit edit;
      if (json.containsKey('edit')) {
        edit = SourceFileEdit.fromJson(
            jsonDecoder, '$jsonPath.edit', json['edit']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'edit');
      }
      return EditOrganizeDirectivesResult(edit);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'edit.organizeDirectives result', json);
    }
  }

  factory EditOrganizeDirectivesResult.fromResponse(Response response) {
    return EditOrganizeDirectivesResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['edit'] = edit.toJson();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditOrganizeDirectivesResult) {
      return edit == other.edit;
    }
    return false;
  }

  @override
  int get hashCode => edit.hashCode;
}

/// edit.sortMembers params
///
/// {
///   "file": FilePath
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditSortMembersParams implements RequestParams {
  /// The Dart file to sort.
  String file;

  EditSortMembersParams(this.file);

  factory EditSortMembersParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      return EditSortMembersParams(file);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.sortMembers params', json);
    }
  }

  factory EditSortMembersParams.fromRequest(Request request) {
    return EditSortMembersParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.sortMembers', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditSortMembersParams) {
      return file == other.file;
    }
    return false;
  }

  @override
  int get hashCode => file.hashCode;
}

/// edit.sortMembers result
///
/// {
///   "edit": SourceFileEdit
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditSortMembersResult implements ResponseResult {
  /// The file edit that is to be applied to the given file to effect the
  /// sorting.
  SourceFileEdit edit;

  EditSortMembersResult(this.edit);

  factory EditSortMembersResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      SourceFileEdit edit;
      if (json.containsKey('edit')) {
        edit = SourceFileEdit.fromJson(
            jsonDecoder, '$jsonPath.edit', json['edit']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'edit');
      }
      return EditSortMembersResult(edit);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.sortMembers result', json);
    }
  }

  factory EditSortMembersResult.fromResponse(Response response) {
    return EditSortMembersResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['edit'] = edit.toJson();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditSortMembersResult) {
      return edit == other.edit;
    }
    return false;
  }

  @override
  int get hashCode => edit.hashCode;
}

/// ElementDeclaration
///
/// {
///   "name": String
///   "kind": ElementKind
///   "fileIndex": int
///   "offset": int
///   "line": int
///   "column": int
///   "codeOffset": int
///   "codeLength": int
///   "className": optional String
///   "mixinName": optional String
///   "parameters": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ElementDeclaration implements HasToJson {
  /// The name of the declaration.
  String name;

  /// The kind of the element that corresponds to the declaration.
  ElementKind kind;

  /// The index of the file (in the enclosing response).
  int fileIndex;

  /// The offset of the declaration name in the file.
  int offset;

  /// The one-based index of the line containing the declaration name.
  int line;

  /// The one-based index of the column containing the declaration name.
  int column;

  /// The offset of the first character of the declaration code in the file.
  int codeOffset;

  /// The length of the declaration code in the file.
  int codeLength;

  /// The name of the class enclosing this declaration. If the declaration is
  /// not a class member, this field will be absent.
  String? className;

  /// The name of the mixin enclosing this declaration. If the declaration is
  /// not a mixin member, this field will be absent.
  String? mixinName;

  /// The parameter list for the element. If the element is not a method or
  /// function this field will not be defined. If the element doesn't have
  /// parameters (e.g. getter), this field will not be defined. If the element
  /// has zero parameters, this field will have a value of "()". The value
  /// should not be treated as exact presentation of parameters, it is just
  /// approximation of parameters to give the user general idea.
  String? parameters;

  ElementDeclaration(this.name, this.kind, this.fileIndex, this.offset,
      this.line, this.column, this.codeOffset, this.codeLength,
      {this.className, this.mixinName, this.parameters});

  factory ElementDeclaration.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString('$jsonPath.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      ElementKind kind;
      if (json.containsKey('kind')) {
        kind =
            ElementKind.fromJson(jsonDecoder, '$jsonPath.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      int fileIndex;
      if (json.containsKey('fileIndex')) {
        fileIndex =
            jsonDecoder.decodeInt('$jsonPath.fileIndex', json['fileIndex']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'fileIndex');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt('$jsonPath.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int line;
      if (json.containsKey('line')) {
        line = jsonDecoder.decodeInt('$jsonPath.line', json['line']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'line');
      }
      int column;
      if (json.containsKey('column')) {
        column = jsonDecoder.decodeInt('$jsonPath.column', json['column']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'column');
      }
      int codeOffset;
      if (json.containsKey('codeOffset')) {
        codeOffset =
            jsonDecoder.decodeInt('$jsonPath.codeOffset', json['codeOffset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'codeOffset');
      }
      int codeLength;
      if (json.containsKey('codeLength')) {
        codeLength =
            jsonDecoder.decodeInt('$jsonPath.codeLength', json['codeLength']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'codeLength');
      }
      String? className;
      if (json.containsKey('className')) {
        className =
            jsonDecoder.decodeString('$jsonPath.className', json['className']);
      }
      String? mixinName;
      if (json.containsKey('mixinName')) {
        mixinName =
            jsonDecoder.decodeString('$jsonPath.mixinName', json['mixinName']);
      }
      String? parameters;
      if (json.containsKey('parameters')) {
        parameters = jsonDecoder.decodeString(
            '$jsonPath.parameters', json['parameters']);
      }
      return ElementDeclaration(
          name, kind, fileIndex, offset, line, column, codeOffset, codeLength,
          className: className, mixinName: mixinName, parameters: parameters);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ElementDeclaration', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['name'] = name;
    result['kind'] = kind.toJson();
    result['fileIndex'] = fileIndex;
    result['offset'] = offset;
    result['line'] = line;
    result['column'] = column;
    result['codeOffset'] = codeOffset;
    result['codeLength'] = codeLength;
    var className = this.className;
    if (className != null) {
      result['className'] = className;
    }
    var mixinName = this.mixinName;
    if (mixinName != null) {
      result['mixinName'] = mixinName;
    }
    var parameters = this.parameters;
    if (parameters != null) {
      result['parameters'] = parameters;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ElementDeclaration) {
      return name == other.name &&
          kind == other.kind &&
          fileIndex == other.fileIndex &&
          offset == other.offset &&
          line == other.line &&
          column == other.column &&
          codeOffset == other.codeOffset &&
          codeLength == other.codeLength &&
          className == other.className &&
          mixinName == other.mixinName &&
          parameters == other.parameters;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        name,
        kind,
        fileIndex,
        offset,
        line,
        column,
        codeOffset,
        codeLength,
        className,
        mixinName,
        parameters,
      );
}

/// ExecutableFile
///
/// {
///   "file": FilePath
///   "kind": ExecutableKind
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExecutableFile implements HasToJson {
  /// The path of the executable file.
  String file;

  /// The kind of the executable file.
  ExecutableKind kind;

  ExecutableFile(this.file, this.kind);

  factory ExecutableFile.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      ExecutableKind kind;
      if (json.containsKey('kind')) {
        kind = ExecutableKind.fromJson(
            jsonDecoder, '$jsonPath.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      return ExecutableFile(file, kind);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ExecutableFile', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['kind'] = kind.toJson();
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutableFile) {
      return file == other.file && kind == other.kind;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        kind,
      );
}

/// ExecutableKind
///
/// enum {
///   CLIENT
///   EITHER
///   NOT_EXECUTABLE
///   SERVER
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExecutableKind implements Enum {
  static const ExecutableKind CLIENT = ExecutableKind._('CLIENT');

  static const ExecutableKind EITHER = ExecutableKind._('EITHER');

  static const ExecutableKind NOT_EXECUTABLE =
      ExecutableKind._('NOT_EXECUTABLE');

  static const ExecutableKind SERVER = ExecutableKind._('SERVER');

  /// A list containing all of the enum values that are defined.
  static const List<ExecutableKind> VALUES = <ExecutableKind>[
    CLIENT,
    EITHER,
    NOT_EXECUTABLE,
    SERVER
  ];

  @override
  final String name;

  const ExecutableKind._(this.name);

  factory ExecutableKind(String name) {
    switch (name) {
      case 'CLIENT':
        return CLIENT;
      case 'EITHER':
        return EITHER;
      case 'NOT_EXECUTABLE':
        return NOT_EXECUTABLE;
      case 'SERVER':
        return SERVER;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory ExecutableKind.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    if (json is String) {
      try {
        return ExecutableKind(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'ExecutableKind', json);
  }

  @override
  String toString() => 'ExecutableKind.$name';

  String toJson() => name;
}

/// execution.createContext params
///
/// {
///   "contextRoot": FilePath
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExecutionCreateContextParams implements RequestParams {
  /// The path of the Dart or HTML file that will be launched, or the path of
  /// the directory containing the file.
  String contextRoot;

  ExecutionCreateContextParams(this.contextRoot);

  factory ExecutionCreateContextParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String contextRoot;
      if (json.containsKey('contextRoot')) {
        contextRoot = jsonDecoder.decodeString(
            '$jsonPath.contextRoot', json['contextRoot']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'contextRoot');
      }
      return ExecutionCreateContextParams(contextRoot);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'execution.createContext params', json);
    }
  }

  factory ExecutionCreateContextParams.fromRequest(Request request) {
    return ExecutionCreateContextParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['contextRoot'] = contextRoot;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'execution.createContext', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutionCreateContextParams) {
      return contextRoot == other.contextRoot;
    }
    return false;
  }

  @override
  int get hashCode => contextRoot.hashCode;
}

/// execution.createContext result
///
/// {
///   "id": ExecutionContextId
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExecutionCreateContextResult implements ResponseResult {
  /// The identifier used to refer to the execution context that was created.
  String id;

  ExecutionCreateContextResult(this.id);

  factory ExecutionCreateContextResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeString('$jsonPath.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      return ExecutionCreateContextResult(id);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'execution.createContext result', json);
    }
  }

  factory ExecutionCreateContextResult.fromResponse(Response response) {
    return ExecutionCreateContextResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['id'] = id;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutionCreateContextResult) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode => id.hashCode;
}

/// execution.deleteContext params
///
/// {
///   "id": ExecutionContextId
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExecutionDeleteContextParams implements RequestParams {
  /// The identifier of the execution context that is to be deleted.
  String id;

  ExecutionDeleteContextParams(this.id);

  factory ExecutionDeleteContextParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeString('$jsonPath.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      return ExecutionDeleteContextParams(id);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'execution.deleteContext params', json);
    }
  }

  factory ExecutionDeleteContextParams.fromRequest(Request request) {
    return ExecutionDeleteContextParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['id'] = id;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'execution.deleteContext', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutionDeleteContextParams) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode => id.hashCode;
}

/// execution.deleteContext result
///
/// Clients may not extend, implement or mix-in this class.
class ExecutionDeleteContextResult implements ResponseResult {
  @override
  Map<String, Object> toJson() => {};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) => other is ExecutionDeleteContextResult;

  @override
  int get hashCode => 479954425;
}

/// execution.getSuggestions params
///
/// {
///   "code": String
///   "offset": int
///   "contextFile": FilePath
///   "contextOffset": int
///   "variables": List<RuntimeCompletionVariable>
///   "expressions": optional List<RuntimeCompletionExpression>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExecutionGetSuggestionsParams implements RequestParams {
  /// The code to get suggestions in.
  String code;

  /// The offset within the code to get suggestions at.
  int offset;

  /// The path of the context file, e.g. the file of the current debugger
  /// frame. The combination of the context file and context offset can be used
  /// to ensure that all variables of the context are available for completion
  /// (with their static types).
  String contextFile;

  /// The offset in the context file, e.g. the line offset in the current
  /// debugger frame.
  int contextOffset;

  /// The runtime context variables that are potentially referenced in the
  /// code.
  List<RuntimeCompletionVariable> variables;

  /// The list of sub-expressions in the code for which the client wants to
  /// provide runtime types. It does not have to be the full list of
  /// expressions requested by the server, for missing expressions their static
  /// types will be used.
  ///
  /// When this field is omitted, the server will return completion suggestions
  /// only when there are no interesting sub-expressions in the given code. The
  /// client may provide an empty list, in this case the server will return
  /// completion suggestions.
  List<RuntimeCompletionExpression>? expressions;

  ExecutionGetSuggestionsParams(this.code, this.offset, this.contextFile,
      this.contextOffset, this.variables,
      {this.expressions});

  factory ExecutionGetSuggestionsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String code;
      if (json.containsKey('code')) {
        code = jsonDecoder.decodeString('$jsonPath.code', json['code']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'code');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt('$jsonPath.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      String contextFile;
      if (json.containsKey('contextFile')) {
        contextFile = jsonDecoder.decodeString(
            '$jsonPath.contextFile', json['contextFile']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'contextFile');
      }
      int contextOffset;
      if (json.containsKey('contextOffset')) {
        contextOffset = jsonDecoder.decodeInt(
            '$jsonPath.contextOffset', json['contextOffset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'contextOffset');
      }
      List<RuntimeCompletionVariable> variables;
      if (json.containsKey('variables')) {
        variables = jsonDecoder.decodeList(
            '$jsonPath.variables',
            json['variables'],
            (String jsonPath, Object? json) =>
                RuntimeCompletionVariable.fromJson(
                    jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'variables');
      }
      List<RuntimeCompletionExpression>? expressions;
      if (json.containsKey('expressions')) {
        expressions = jsonDecoder.decodeList(
            '$jsonPath.expressions',
            json['expressions'],
            (String jsonPath, Object? json) =>
                RuntimeCompletionExpression.fromJson(
                    jsonDecoder, jsonPath, json));
      }
      return ExecutionGetSuggestionsParams(
          code, offset, contextFile, contextOffset, variables,
          expressions: expressions);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'execution.getSuggestions params', json);
    }
  }

  factory ExecutionGetSuggestionsParams.fromRequest(Request request) {
    return ExecutionGetSuggestionsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['code'] = code;
    result['offset'] = offset;
    result['contextFile'] = contextFile;
    result['contextOffset'] = contextOffset;
    result['variables'] = variables
        .map((RuntimeCompletionVariable value) => value.toJson())
        .toList();
    var expressions = this.expressions;
    if (expressions != null) {
      result['expressions'] = expressions
          .map((RuntimeCompletionExpression value) => value.toJson())
          .toList();
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'execution.getSuggestions', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutionGetSuggestionsParams) {
      return code == other.code &&
          offset == other.offset &&
          contextFile == other.contextFile &&
          contextOffset == other.contextOffset &&
          listEqual(
              variables,
              other.variables,
              (RuntimeCompletionVariable a, RuntimeCompletionVariable b) =>
                  a == b) &&
          listEqual(
              expressions,
              other.expressions,
              (RuntimeCompletionExpression a, RuntimeCompletionExpression b) =>
                  a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        code,
        offset,
        contextFile,
        contextOffset,
        Object.hashAll(variables),
        Object.hashAll(expressions ?? []),
      );
}

/// execution.getSuggestions result
///
/// {
///   "suggestions": optional List<CompletionSuggestion>
///   "expressions": optional List<RuntimeCompletionExpression>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExecutionGetSuggestionsResult implements ResponseResult {
  /// The completion suggestions. In contrast to usual completion request,
  /// suggestions for private elements also will be provided.
  ///
  /// If there are sub-expressions that can have different runtime types, and
  /// are considered to be safe to evaluate at runtime (e.g. getters), so using
  /// their actual runtime types can improve completion results, the server
  /// omits this field in the response, and instead will return the
  /// "expressions" field.
  List<CompletionSuggestion>? suggestions;

  /// The list of sub-expressions in the code for which the server would like
  /// to know runtime types to provide better completion suggestions.
  ///
  /// This field is omitted the field "suggestions" is returned.
  List<RuntimeCompletionExpression>? expressions;

  ExecutionGetSuggestionsResult({this.suggestions, this.expressions});

  factory ExecutionGetSuggestionsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<CompletionSuggestion>? suggestions;
      if (json.containsKey('suggestions')) {
        suggestions = jsonDecoder.decodeList(
            '$jsonPath.suggestions',
            json['suggestions'],
            (String jsonPath, Object? json) =>
                CompletionSuggestion.fromJson(jsonDecoder, jsonPath, json));
      }
      List<RuntimeCompletionExpression>? expressions;
      if (json.containsKey('expressions')) {
        expressions = jsonDecoder.decodeList(
            '$jsonPath.expressions',
            json['expressions'],
            (String jsonPath, Object? json) =>
                RuntimeCompletionExpression.fromJson(
                    jsonDecoder, jsonPath, json));
      }
      return ExecutionGetSuggestionsResult(
          suggestions: suggestions, expressions: expressions);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'execution.getSuggestions result', json);
    }
  }

  factory ExecutionGetSuggestionsResult.fromResponse(Response response) {
    return ExecutionGetSuggestionsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    var suggestions = this.suggestions;
    if (suggestions != null) {
      result['suggestions'] = suggestions
          .map((CompletionSuggestion value) => value.toJson())
          .toList();
    }
    var expressions = this.expressions;
    if (expressions != null) {
      result['expressions'] = expressions
          .map((RuntimeCompletionExpression value) => value.toJson())
          .toList();
    }
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutionGetSuggestionsResult) {
      return listEqual(suggestions, other.suggestions,
              (CompletionSuggestion a, CompletionSuggestion b) => a == b) &&
          listEqual(
              expressions,
              other.expressions,
              (RuntimeCompletionExpression a, RuntimeCompletionExpression b) =>
                  a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(suggestions ?? []),
        Object.hashAll(expressions ?? []),
      );
}

/// execution.launchData params
///
/// {
///   "file": FilePath
///   "kind": optional ExecutableKind
///   "referencedFiles": optional List<FilePath>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExecutionLaunchDataParams implements HasToJson {
  /// The file for which launch data is being provided. This will either be a
  /// Dart library or an HTML file.
  String file;

  /// The kind of the executable file. This field is omitted if the file is not
  /// a Dart file.
  ExecutableKind? kind;

  /// A list of the Dart files that are referenced by the file. This field is
  /// omitted if the file is not an HTML file.
  List<String>? referencedFiles;

  ExecutionLaunchDataParams(this.file, {this.kind, this.referencedFiles});

  factory ExecutionLaunchDataParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      ExecutableKind? kind;
      if (json.containsKey('kind')) {
        kind = ExecutableKind.fromJson(
            jsonDecoder, '$jsonPath.kind', json['kind']);
      }
      List<String>? referencedFiles;
      if (json.containsKey('referencedFiles')) {
        referencedFiles = jsonDecoder.decodeList('$jsonPath.referencedFiles',
            json['referencedFiles'], jsonDecoder.decodeString);
      }
      return ExecutionLaunchDataParams(file,
          kind: kind, referencedFiles: referencedFiles);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'execution.launchData params', json);
    }
  }

  factory ExecutionLaunchDataParams.fromNotification(
      Notification notification) {
    return ExecutionLaunchDataParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    var kind = this.kind;
    if (kind != null) {
      result['kind'] = kind.toJson();
    }
    var referencedFiles = this.referencedFiles;
    if (referencedFiles != null) {
      result['referencedFiles'] = referencedFiles;
    }
    return result;
  }

  Notification toNotification() {
    return Notification('execution.launchData', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutionLaunchDataParams) {
      return file == other.file &&
          kind == other.kind &&
          listEqual(referencedFiles, other.referencedFiles,
              (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        kind,
        Object.hashAll(referencedFiles ?? []),
      );
}

/// execution.mapUri params
///
/// {
///   "id": ExecutionContextId
///   "file": optional FilePath
///   "uri": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExecutionMapUriParams implements RequestParams {
  /// The identifier of the execution context in which the URI is to be mapped.
  String id;

  /// The path of the file to be mapped into a URI.
  String? file;

  /// The URI to be mapped into a file path.
  String? uri;

  ExecutionMapUriParams(this.id, {this.file, this.uri});

  factory ExecutionMapUriParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeString('$jsonPath.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      String? file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      }
      String? uri;
      if (json.containsKey('uri')) {
        uri = jsonDecoder.decodeString('$jsonPath.uri', json['uri']);
      }
      return ExecutionMapUriParams(id, file: file, uri: uri);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'execution.mapUri params', json);
    }
  }

  factory ExecutionMapUriParams.fromRequest(Request request) {
    return ExecutionMapUriParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['id'] = id;
    var file = this.file;
    if (file != null) {
      result['file'] = file;
    }
    var uri = this.uri;
    if (uri != null) {
      result['uri'] = uri;
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'execution.mapUri', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutionMapUriParams) {
      return id == other.id && file == other.file && uri == other.uri;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        id,
        file,
        uri,
      );
}

/// execution.mapUri result
///
/// {
///   "file": optional FilePath
///   "uri": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExecutionMapUriResult implements ResponseResult {
  /// The file to which the URI was mapped. This field is omitted if the uri
  /// field was not given in the request.
  String? file;

  /// The URI to which the file path was mapped. This field is omitted if the
  /// file field was not given in the request.
  String? uri;

  ExecutionMapUriResult({this.file, this.uri});

  factory ExecutionMapUriResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String? file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      }
      String? uri;
      if (json.containsKey('uri')) {
        uri = jsonDecoder.decodeString('$jsonPath.uri', json['uri']);
      }
      return ExecutionMapUriResult(file: file, uri: uri);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'execution.mapUri result', json);
    }
  }

  factory ExecutionMapUriResult.fromResponse(Response response) {
    return ExecutionMapUriResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    var file = this.file;
    if (file != null) {
      result['file'] = file;
    }
    var uri = this.uri;
    if (uri != null) {
      result['uri'] = uri;
    }
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutionMapUriResult) {
      return file == other.file && uri == other.uri;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        uri,
      );
}

/// ExecutionService
///
/// enum {
///   LAUNCH_DATA
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExecutionService implements Enum {
  static const ExecutionService LAUNCH_DATA = ExecutionService._('LAUNCH_DATA');

  /// A list containing all of the enum values that are defined.
  static const List<ExecutionService> VALUES = <ExecutionService>[LAUNCH_DATA];

  @override
  final String name;

  const ExecutionService._(this.name);

  factory ExecutionService(String name) {
    switch (name) {
      case 'LAUNCH_DATA':
        return LAUNCH_DATA;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory ExecutionService.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    if (json is String) {
      try {
        return ExecutionService(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'ExecutionService', json);
  }

  @override
  String toString() => 'ExecutionService.$name';

  String toJson() => name;
}

/// execution.setSubscriptions params
///
/// {
///   "subscriptions": List<ExecutionService>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExecutionSetSubscriptionsParams implements RequestParams {
  /// A list of the services being subscribed to.
  List<ExecutionService> subscriptions;

  ExecutionSetSubscriptionsParams(this.subscriptions);

  factory ExecutionSetSubscriptionsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<ExecutionService> subscriptions;
      if (json.containsKey('subscriptions')) {
        subscriptions = jsonDecoder.decodeList(
            '$jsonPath.subscriptions',
            json['subscriptions'],
            (String jsonPath, Object? json) =>
                ExecutionService.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'subscriptions');
      }
      return ExecutionSetSubscriptionsParams(subscriptions);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'execution.setSubscriptions params', json);
    }
  }

  factory ExecutionSetSubscriptionsParams.fromRequest(Request request) {
    return ExecutionSetSubscriptionsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['subscriptions'] =
        subscriptions.map((ExecutionService value) => value.toJson()).toList();
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'execution.setSubscriptions', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutionSetSubscriptionsParams) {
      return listEqual(subscriptions, other.subscriptions,
          (ExecutionService a, ExecutionService b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(subscriptions);
}

/// execution.setSubscriptions result
///
/// Clients may not extend, implement or mix-in this class.
class ExecutionSetSubscriptionsResult implements ResponseResult {
  @override
  Map<String, Object> toJson() => {};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) => other is ExecutionSetSubscriptionsResult;

  @override
  int get hashCode => 287678780;
}

/// ExistingImport
///
/// {
///   "uri": int
///   "elements": List<int>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExistingImport implements HasToJson {
  /// The URI of the imported library. It is an index in the strings field, in
  /// the enclosing ExistingImports and its ImportedElementSet object.
  int uri;

  /// The list of indexes of elements, in the enclosing ExistingImports object.
  List<int> elements;

  ExistingImport(this.uri, this.elements);

  factory ExistingImport.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      int uri;
      if (json.containsKey('uri')) {
        uri = jsonDecoder.decodeInt('$jsonPath.uri', json['uri']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'uri');
      }
      List<int> elements;
      if (json.containsKey('elements')) {
        elements = jsonDecoder.decodeList(
            '$jsonPath.elements', json['elements'], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'elements');
      }
      return ExistingImport(uri, elements);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ExistingImport', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['uri'] = uri;
    result['elements'] = elements;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExistingImport) {
      return uri == other.uri &&
          listEqual(elements, other.elements, (int a, int b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        uri,
        Object.hashAll(elements),
      );
}

/// ExistingImports
///
/// {
///   "elements": ImportedElementSet
///   "imports": List<ExistingImport>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExistingImports implements HasToJson {
  /// The set of all unique imported elements for all imports.
  ImportedElementSet elements;

  /// The list of imports in the library.
  List<ExistingImport> imports;

  ExistingImports(this.elements, this.imports);

  factory ExistingImports.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      ImportedElementSet elements;
      if (json.containsKey('elements')) {
        elements = ImportedElementSet.fromJson(
            jsonDecoder, '$jsonPath.elements', json['elements']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'elements');
      }
      List<ExistingImport> imports;
      if (json.containsKey('imports')) {
        imports = jsonDecoder.decodeList(
            '$jsonPath.imports',
            json['imports'],
            (String jsonPath, Object? json) =>
                ExistingImport.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'imports');
      }
      return ExistingImports(elements, imports);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ExistingImports', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['elements'] = elements.toJson();
    result['imports'] =
        imports.map((ExistingImport value) => value.toJson()).toList();
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExistingImports) {
      return elements == other.elements &&
          listEqual(imports, other.imports,
              (ExistingImport a, ExistingImport b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        elements,
        Object.hashAll(imports),
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

  ExtractLocalVariableFeedback(this.names, this.offsets, this.lengths,
      {this.coveringExpressionOffsets, this.coveringExpressionLengths});

  factory ExtractLocalVariableFeedback.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<int>? coveringExpressionOffsets;
      if (json.containsKey('coveringExpressionOffsets')) {
        coveringExpressionOffsets = jsonDecoder.decodeList(
            '$jsonPath.coveringExpressionOffsets',
            json['coveringExpressionOffsets'],
            jsonDecoder.decodeInt);
      }
      List<int>? coveringExpressionLengths;
      if (json.containsKey('coveringExpressionLengths')) {
        coveringExpressionLengths = jsonDecoder.decodeList(
            '$jsonPath.coveringExpressionLengths',
            json['coveringExpressionLengths'],
            jsonDecoder.decodeInt);
      }
      List<String> names;
      if (json.containsKey('names')) {
        names = jsonDecoder.decodeList(
            '$jsonPath.names', json['names'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'names');
      }
      List<int> offsets;
      if (json.containsKey('offsets')) {
        offsets = jsonDecoder.decodeList(
            '$jsonPath.offsets', json['offsets'], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offsets');
      }
      List<int> lengths;
      if (json.containsKey('lengths')) {
        lengths = jsonDecoder.decodeList(
            '$jsonPath.lengths', json['lengths'], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'lengths');
      }
      return ExtractLocalVariableFeedback(names, offsets, lengths,
          coveringExpressionOffsets: coveringExpressionOffsets,
          coveringExpressionLengths: coveringExpressionLengths);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'extractLocalVariable feedback', json);
    }
  }

  @override
  Map<String, Object> toJson() {
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
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExtractLocalVariableFeedback) {
      return listEqual(coveringExpressionOffsets,
              other.coveringExpressionOffsets, (int a, int b) => a == b) &&
          listEqual(coveringExpressionLengths, other.coveringExpressionLengths,
              (int a, int b) => a == b) &&
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
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
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
        extractAll =
            jsonDecoder.decodeBool('$jsonPath.extractAll', json['extractAll']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'extractAll');
      }
      return ExtractLocalVariableOptions(name, extractAll);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'extractLocalVariable options', json);
    }
  }

  factory ExtractLocalVariableOptions.fromRefactoringParams(
      EditGetRefactoringParams refactoringParams, Request request) {
    return ExtractLocalVariableOptions.fromJson(
        RequestDecoder(request), 'options', refactoringParams.options);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['name'] = name;
    result['extractAll'] = extractAll;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExtractLocalVariableOptions) {
      return name == other.name && extractAll == other.extractAll;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        name,
        extractAll,
      );
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

  ExtractMethodFeedback(this.offset, this.length, this.returnType, this.names,
      this.canCreateGetter, this.parameters, this.offsets, this.lengths);

  factory ExtractMethodFeedback.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
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
            '$jsonPath.returnType', json['returnType']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'returnType');
      }
      List<String> names;
      if (json.containsKey('names')) {
        names = jsonDecoder.decodeList(
            '$jsonPath.names', json['names'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'names');
      }
      bool canCreateGetter;
      if (json.containsKey('canCreateGetter')) {
        canCreateGetter = jsonDecoder.decodeBool(
            '$jsonPath.canCreateGetter', json['canCreateGetter']);
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
                    jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'parameters');
      }
      List<int> offsets;
      if (json.containsKey('offsets')) {
        offsets = jsonDecoder.decodeList(
            '$jsonPath.offsets', json['offsets'], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offsets');
      }
      List<int> lengths;
      if (json.containsKey('lengths')) {
        lengths = jsonDecoder.decodeList(
            '$jsonPath.lengths', json['lengths'], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'lengths');
      }
      return ExtractMethodFeedback(offset, length, returnType, names,
          canCreateGetter, parameters, offsets, lengths);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'extractMethod feedback', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['offset'] = offset;
    result['length'] = length;
    result['returnType'] = returnType;
    result['names'] = names;
    result['canCreateGetter'] = canCreateGetter;
    result['parameters'] = parameters
        .map((RefactoringMethodParameter value) => value.toJson())
        .toList();
    result['offsets'] = offsets;
    result['lengths'] = lengths;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

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
                  a == b) &&
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

  ExtractMethodOptions(this.returnType, this.createGetter, this.name,
      this.parameters, this.extractAll);

  factory ExtractMethodOptions.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String returnType;
      if (json.containsKey('returnType')) {
        returnType = jsonDecoder.decodeString(
            '$jsonPath.returnType', json['returnType']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'returnType');
      }
      bool createGetter;
      if (json.containsKey('createGetter')) {
        createGetter = jsonDecoder.decodeBool(
            '$jsonPath.createGetter', json['createGetter']);
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
                    jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'parameters');
      }
      bool extractAll;
      if (json.containsKey('extractAll')) {
        extractAll =
            jsonDecoder.decodeBool('$jsonPath.extractAll', json['extractAll']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'extractAll');
      }
      return ExtractMethodOptions(
          returnType, createGetter, name, parameters, extractAll);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'extractMethod options', json);
    }
  }

  factory ExtractMethodOptions.fromRefactoringParams(
      EditGetRefactoringParams refactoringParams, Request request) {
    return ExtractMethodOptions.fromJson(
        RequestDecoder(request), 'options', refactoringParams.options);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['returnType'] = returnType;
    result['createGetter'] = createGetter;
    result['name'] = name;
    result['parameters'] = parameters
        .map((RefactoringMethodParameter value) => value.toJson())
        .toList();
    result['extractAll'] = extractAll;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

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
                  a == b) &&
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

/// extractWidget feedback
///
/// {
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExtractWidgetFeedback extends RefactoringFeedback {
  ExtractWidgetFeedback();

  factory ExtractWidgetFeedback.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      return ExtractWidgetFeedback();
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'extractWidget feedback', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExtractWidgetFeedback) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode => 0;
}

/// extractWidget options
///
/// {
///   "name": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExtractWidgetOptions extends RefactoringOptions {
  /// The name that the widget class should be given.
  String name;

  ExtractWidgetOptions(this.name);

  factory ExtractWidgetOptions.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString('$jsonPath.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      return ExtractWidgetOptions(name);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'extractWidget options', json);
    }
  }

  factory ExtractWidgetOptions.fromRefactoringParams(
      EditGetRefactoringParams refactoringParams, Request request) {
    return ExtractWidgetOptions.fromJson(
        RequestDecoder(request), 'options', refactoringParams.options);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['name'] = name;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExtractWidgetOptions) {
      return name == other.name;
    }
    return false;
  }

  @override
  int get hashCode => name.hashCode;
}

/// FileKind
///
/// enum {
///   LIBRARY
///   PART
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FileKind implements Enum {
  static const FileKind LIBRARY = FileKind._('LIBRARY');

  static const FileKind PART = FileKind._('PART');

  /// A list containing all of the enum values that are defined.
  static const List<FileKind> VALUES = <FileKind>[LIBRARY, PART];

  @override
  final String name;

  const FileKind._(this.name);

  factory FileKind(String name) {
    switch (name) {
      case 'LIBRARY':
        return LIBRARY;
      case 'PART':
        return PART;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory FileKind.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    if (json is String) {
      try {
        return FileKind(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'FileKind', json);
  }

  @override
  String toString() => 'FileKind.$name';

  String toJson() => name;
}

/// flutter.getWidgetDescription params
///
/// {
///   "file": FilePath
///   "offset": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterGetWidgetDescriptionParams implements RequestParams {
  /// The file where the widget instance is created.
  String file;

  /// The offset in the file where the widget instance is created.
  int offset;

  FlutterGetWidgetDescriptionParams(this.file, this.offset);

  factory FlutterGetWidgetDescriptionParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt('$jsonPath.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      return FlutterGetWidgetDescriptionParams(file, offset);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'flutter.getWidgetDescription params', json);
    }
  }

  factory FlutterGetWidgetDescriptionParams.fromRequest(Request request) {
    return FlutterGetWidgetDescriptionParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['offset'] = offset;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'flutter.getWidgetDescription', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FlutterGetWidgetDescriptionParams) {
      return file == other.file && offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        offset,
      );
}

/// flutter.getWidgetDescription result
///
/// {
///   "properties": List<FlutterWidgetProperty>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterGetWidgetDescriptionResult implements ResponseResult {
  /// The list of properties of the widget. Some of the properties might be
  /// read only, when their editor is not set. This might be because they have
  /// type that we don't know how to edit, or for compound properties that work
  /// as containers for sub-properties.
  List<FlutterWidgetProperty> properties;

  FlutterGetWidgetDescriptionResult(this.properties);

  factory FlutterGetWidgetDescriptionResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<FlutterWidgetProperty> properties;
      if (json.containsKey('properties')) {
        properties = jsonDecoder.decodeList(
            '$jsonPath.properties',
            json['properties'],
            (String jsonPath, Object? json) =>
                FlutterWidgetProperty.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'properties');
      }
      return FlutterGetWidgetDescriptionResult(properties);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'flutter.getWidgetDescription result', json);
    }
  }

  factory FlutterGetWidgetDescriptionResult.fromResponse(Response response) {
    return FlutterGetWidgetDescriptionResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['properties'] = properties
        .map((FlutterWidgetProperty value) => value.toJson())
        .toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FlutterGetWidgetDescriptionResult) {
      return listEqual(properties, other.properties,
          (FlutterWidgetProperty a, FlutterWidgetProperty b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(properties);
}

/// FlutterOutline
///
/// {
///   "kind": FlutterOutlineKind
///   "offset": int
///   "length": int
///   "codeOffset": int
///   "codeLength": int
///   "label": optional String
///   "dartElement": optional Element
///   "attributes": optional List<FlutterOutlineAttribute>
///   "className": optional String
///   "parentAssociationLabel": optional String
///   "variableName": optional String
///   "children": optional List<FlutterOutline>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterOutline implements HasToJson {
  /// The kind of the node.
  FlutterOutlineKind kind;

  /// The offset of the first character of the element. This is different than
  /// the offset in the Element, which is the offset of the name of the
  /// element. It can be used, for example, to map locations in the file back
  /// to an outline.
  int offset;

  /// The length of the element.
  int length;

  /// The offset of the first character of the element code, which is neither
  /// documentation, nor annotation.
  int codeOffset;

  /// The length of the element code.
  int codeLength;

  /// The text label of the node children of the node. It is provided for any
  /// FlutterOutlineKind.GENERIC node, where better information is not
  /// available.
  String? label;

  /// If this node is a Dart element, the description of it; omitted otherwise.
  Element? dartElement;

  /// Additional attributes for this node, which might be interesting to
  /// display on the client. These attributes are usually arguments for the
  /// instance creation or the invocation that created the widget.
  List<FlutterOutlineAttribute>? attributes;

  /// If the node creates a new class instance, or a reference to an instance,
  /// this field has the name of the class.
  String? className;

  /// A short text description how this node is associated with the parent
  /// node. For example "appBar" or "body" in Scaffold.
  String? parentAssociationLabel;

  /// If FlutterOutlineKind.VARIABLE, the name of the variable.
  String? variableName;

  /// The children of the node. The field will be omitted if the node has no
  /// children.
  List<FlutterOutline>? children;

  FlutterOutline(
      this.kind, this.offset, this.length, this.codeOffset, this.codeLength,
      {this.label,
      this.dartElement,
      this.attributes,
      this.className,
      this.parentAssociationLabel,
      this.variableName,
      this.children});

  factory FlutterOutline.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      FlutterOutlineKind kind;
      if (json.containsKey('kind')) {
        kind = FlutterOutlineKind.fromJson(
            jsonDecoder, '$jsonPath.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
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
      int codeOffset;
      if (json.containsKey('codeOffset')) {
        codeOffset =
            jsonDecoder.decodeInt('$jsonPath.codeOffset', json['codeOffset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'codeOffset');
      }
      int codeLength;
      if (json.containsKey('codeLength')) {
        codeLength =
            jsonDecoder.decodeInt('$jsonPath.codeLength', json['codeLength']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'codeLength');
      }
      String? label;
      if (json.containsKey('label')) {
        label = jsonDecoder.decodeString('$jsonPath.label', json['label']);
      }
      Element? dartElement;
      if (json.containsKey('dartElement')) {
        dartElement = Element.fromJson(
            jsonDecoder, '$jsonPath.dartElement', json['dartElement']);
      }
      List<FlutterOutlineAttribute>? attributes;
      if (json.containsKey('attributes')) {
        attributes = jsonDecoder.decodeList(
            '$jsonPath.attributes',
            json['attributes'],
            (String jsonPath, Object? json) =>
                FlutterOutlineAttribute.fromJson(jsonDecoder, jsonPath, json));
      }
      String? className;
      if (json.containsKey('className')) {
        className =
            jsonDecoder.decodeString('$jsonPath.className', json['className']);
      }
      String? parentAssociationLabel;
      if (json.containsKey('parentAssociationLabel')) {
        parentAssociationLabel = jsonDecoder.decodeString(
            '$jsonPath.parentAssociationLabel', json['parentAssociationLabel']);
      }
      String? variableName;
      if (json.containsKey('variableName')) {
        variableName = jsonDecoder.decodeString(
            '$jsonPath.variableName', json['variableName']);
      }
      List<FlutterOutline>? children;
      if (json.containsKey('children')) {
        children = jsonDecoder.decodeList(
            '$jsonPath.children',
            json['children'],
            (String jsonPath, Object? json) =>
                FlutterOutline.fromJson(jsonDecoder, jsonPath, json));
      }
      return FlutterOutline(kind, offset, length, codeOffset, codeLength,
          label: label,
          dartElement: dartElement,
          attributes: attributes,
          className: className,
          parentAssociationLabel: parentAssociationLabel,
          variableName: variableName,
          children: children);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'FlutterOutline', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['kind'] = kind.toJson();
    result['offset'] = offset;
    result['length'] = length;
    result['codeOffset'] = codeOffset;
    result['codeLength'] = codeLength;
    var label = this.label;
    if (label != null) {
      result['label'] = label;
    }
    var dartElement = this.dartElement;
    if (dartElement != null) {
      result['dartElement'] = dartElement.toJson();
    }
    var attributes = this.attributes;
    if (attributes != null) {
      result['attributes'] = attributes
          .map((FlutterOutlineAttribute value) => value.toJson())
          .toList();
    }
    var className = this.className;
    if (className != null) {
      result['className'] = className;
    }
    var parentAssociationLabel = this.parentAssociationLabel;
    if (parentAssociationLabel != null) {
      result['parentAssociationLabel'] = parentAssociationLabel;
    }
    var variableName = this.variableName;
    if (variableName != null) {
      result['variableName'] = variableName;
    }
    var children = this.children;
    if (children != null) {
      result['children'] =
          children.map((FlutterOutline value) => value.toJson()).toList();
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FlutterOutline) {
      return kind == other.kind &&
          offset == other.offset &&
          length == other.length &&
          codeOffset == other.codeOffset &&
          codeLength == other.codeLength &&
          label == other.label &&
          dartElement == other.dartElement &&
          listEqual(
              attributes,
              other.attributes,
              (FlutterOutlineAttribute a, FlutterOutlineAttribute b) =>
                  a == b) &&
          className == other.className &&
          parentAssociationLabel == other.parentAssociationLabel &&
          variableName == other.variableName &&
          listEqual(children, other.children,
              (FlutterOutline a, FlutterOutline b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        kind,
        offset,
        length,
        codeOffset,
        codeLength,
        label,
        dartElement,
        Object.hashAll(attributes ?? []),
        className,
        parentAssociationLabel,
        variableName,
        Object.hashAll(children ?? []),
      );
}

/// FlutterOutlineAttribute
///
/// {
///   "name": String
///   "label": String
///   "literalValueBoolean": optional bool
///   "literalValueInteger": optional int
///   "literalValueString": optional String
///   "nameLocation": optional Location
///   "valueLocation": optional Location
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterOutlineAttribute implements HasToJson {
  /// The name of the attribute.
  String name;

  /// The label of the attribute value, usually the Dart code. It might be
  /// quite long, the client should abbreviate as needed.
  String label;

  /// The boolean literal value of the attribute. This field is absent if the
  /// value is not a boolean literal.
  bool? literalValueBoolean;

  /// The integer literal value of the attribute. This field is absent if the
  /// value is not an integer literal.
  int? literalValueInteger;

  /// The string literal value of the attribute. This field is absent if the
  /// value is not a string literal.
  String? literalValueString;

  /// If the attribute is a named argument, the location of the name, without
  /// the colon.
  Location? nameLocation;

  /// The location of the value.
  ///
  /// This field is always available, but marked optional for backward
  /// compatibility between new clients with older servers.
  Location? valueLocation;

  FlutterOutlineAttribute(this.name, this.label,
      {this.literalValueBoolean,
      this.literalValueInteger,
      this.literalValueString,
      this.nameLocation,
      this.valueLocation});

  factory FlutterOutlineAttribute.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString('$jsonPath.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      String label;
      if (json.containsKey('label')) {
        label = jsonDecoder.decodeString('$jsonPath.label', json['label']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'label');
      }
      bool? literalValueBoolean;
      if (json.containsKey('literalValueBoolean')) {
        literalValueBoolean = jsonDecoder.decodeBool(
            '$jsonPath.literalValueBoolean', json['literalValueBoolean']);
      }
      int? literalValueInteger;
      if (json.containsKey('literalValueInteger')) {
        literalValueInteger = jsonDecoder.decodeInt(
            '$jsonPath.literalValueInteger', json['literalValueInteger']);
      }
      String? literalValueString;
      if (json.containsKey('literalValueString')) {
        literalValueString = jsonDecoder.decodeString(
            '$jsonPath.literalValueString', json['literalValueString']);
      }
      Location? nameLocation;
      if (json.containsKey('nameLocation')) {
        nameLocation = Location.fromJson(
            jsonDecoder, '$jsonPath.nameLocation', json['nameLocation']);
      }
      Location? valueLocation;
      if (json.containsKey('valueLocation')) {
        valueLocation = Location.fromJson(
            jsonDecoder, '$jsonPath.valueLocation', json['valueLocation']);
      }
      return FlutterOutlineAttribute(name, label,
          literalValueBoolean: literalValueBoolean,
          literalValueInteger: literalValueInteger,
          literalValueString: literalValueString,
          nameLocation: nameLocation,
          valueLocation: valueLocation);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'FlutterOutlineAttribute', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['name'] = name;
    result['label'] = label;
    var literalValueBoolean = this.literalValueBoolean;
    if (literalValueBoolean != null) {
      result['literalValueBoolean'] = literalValueBoolean;
    }
    var literalValueInteger = this.literalValueInteger;
    if (literalValueInteger != null) {
      result['literalValueInteger'] = literalValueInteger;
    }
    var literalValueString = this.literalValueString;
    if (literalValueString != null) {
      result['literalValueString'] = literalValueString;
    }
    var nameLocation = this.nameLocation;
    if (nameLocation != null) {
      result['nameLocation'] = nameLocation.toJson();
    }
    var valueLocation = this.valueLocation;
    if (valueLocation != null) {
      result['valueLocation'] = valueLocation.toJson();
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FlutterOutlineAttribute) {
      return name == other.name &&
          label == other.label &&
          literalValueBoolean == other.literalValueBoolean &&
          literalValueInteger == other.literalValueInteger &&
          literalValueString == other.literalValueString &&
          nameLocation == other.nameLocation &&
          valueLocation == other.valueLocation;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        name,
        label,
        literalValueBoolean,
        literalValueInteger,
        literalValueString,
        nameLocation,
        valueLocation,
      );
}

/// FlutterOutlineKind
///
/// enum {
///   DART_ELEMENT
///   GENERIC
///   NEW_INSTANCE
///   INVOCATION
///   VARIABLE
///   PLACEHOLDER
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterOutlineKind implements Enum {
  /// A dart element declaration.
  static const FlutterOutlineKind DART_ELEMENT =
      FlutterOutlineKind._('DART_ELEMENT');

  /// A generic Flutter element, without additional information.
  static const FlutterOutlineKind GENERIC = FlutterOutlineKind._('GENERIC');

  /// A new instance creation.
  static const FlutterOutlineKind NEW_INSTANCE =
      FlutterOutlineKind._('NEW_INSTANCE');

  /// An invocation of a method, a top-level function, a function expression,
  /// etc.
  static const FlutterOutlineKind INVOCATION =
      FlutterOutlineKind._('INVOCATION');

  /// A reference to a local variable, or a field.
  static const FlutterOutlineKind VARIABLE = FlutterOutlineKind._('VARIABLE');

  /// The parent node has a required Widget. The node works as a placeholder
  /// child to drop a new Widget to.
  static const FlutterOutlineKind PLACEHOLDER =
      FlutterOutlineKind._('PLACEHOLDER');

  /// A list containing all of the enum values that are defined.
  static const List<FlutterOutlineKind> VALUES = <FlutterOutlineKind>[
    DART_ELEMENT,
    GENERIC,
    NEW_INSTANCE,
    INVOCATION,
    VARIABLE,
    PLACEHOLDER
  ];

  @override
  final String name;

  const FlutterOutlineKind._(this.name);

  factory FlutterOutlineKind(String name) {
    switch (name) {
      case 'DART_ELEMENT':
        return DART_ELEMENT;
      case 'GENERIC':
        return GENERIC;
      case 'NEW_INSTANCE':
        return NEW_INSTANCE;
      case 'INVOCATION':
        return INVOCATION;
      case 'VARIABLE':
        return VARIABLE;
      case 'PLACEHOLDER':
        return PLACEHOLDER;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory FlutterOutlineKind.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    if (json is String) {
      try {
        return FlutterOutlineKind(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'FlutterOutlineKind', json);
  }

  @override
  String toString() => 'FlutterOutlineKind.$name';

  String toJson() => name;
}

/// flutter.outline params
///
/// {
///   "file": FilePath
///   "outline": FlutterOutline
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterOutlineParams implements HasToJson {
  /// The file with which the outline is associated.
  String file;

  /// The outline associated with the file.
  FlutterOutline outline;

  FlutterOutlineParams(this.file, this.outline);

  factory FlutterOutlineParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      FlutterOutline outline;
      if (json.containsKey('outline')) {
        outline = FlutterOutline.fromJson(
            jsonDecoder, '$jsonPath.outline', json['outline']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'outline');
      }
      return FlutterOutlineParams(file, outline);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'flutter.outline params', json);
    }
  }

  factory FlutterOutlineParams.fromNotification(Notification notification) {
    return FlutterOutlineParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['outline'] = outline.toJson();
    return result;
  }

  Notification toNotification() {
    return Notification('flutter.outline', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FlutterOutlineParams) {
      return file == other.file && outline == other.outline;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        outline,
      );
}

/// FlutterService
///
/// enum {
///   OUTLINE
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterService implements Enum {
  static const FlutterService OUTLINE = FlutterService._('OUTLINE');

  /// A list containing all of the enum values that are defined.
  static const List<FlutterService> VALUES = <FlutterService>[OUTLINE];

  @override
  final String name;

  const FlutterService._(this.name);

  factory FlutterService(String name) {
    switch (name) {
      case 'OUTLINE':
        return OUTLINE;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory FlutterService.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    if (json is String) {
      try {
        return FlutterService(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'FlutterService', json);
  }

  @override
  String toString() => 'FlutterService.$name';

  String toJson() => name;
}

/// flutter.setSubscriptions params
///
/// {
///   "subscriptions": Map<FlutterService, List<FilePath>>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterSetSubscriptionsParams implements RequestParams {
  /// A table mapping services to a list of the files being subscribed to the
  /// service.
  Map<FlutterService, List<String>> subscriptions;

  FlutterSetSubscriptionsParams(this.subscriptions);

  factory FlutterSetSubscriptionsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      Map<FlutterService, List<String>> subscriptions;
      if (json.containsKey('subscriptions')) {
        subscriptions = jsonDecoder.decodeMap(
            '$jsonPath.subscriptions', json['subscriptions'],
            keyDecoder: (String jsonPath, Object? json) =>
                FlutterService.fromJson(jsonDecoder, jsonPath, json),
            valueDecoder: (String jsonPath, Object? json) => jsonDecoder
                .decodeList(jsonPath, json, jsonDecoder.decodeString));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'subscriptions');
      }
      return FlutterSetSubscriptionsParams(subscriptions);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'flutter.setSubscriptions params', json);
    }
  }

  factory FlutterSetSubscriptionsParams.fromRequest(Request request) {
    return FlutterSetSubscriptionsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['subscriptions'] = mapMap(subscriptions,
        keyCallback: (FlutterService value) => value.toJson());
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'flutter.setSubscriptions', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FlutterSetSubscriptionsParams) {
      return mapEqual(
          subscriptions,
          other.subscriptions,
          (List<String> a, List<String> b) =>
              listEqual(a, b, (String a, String b) => a == b));
    }
    return false;
  }

  @override
  int get hashCode =>
      Object.hashAll([...subscriptions.keys, ...subscriptions.values]);
}

/// flutter.setSubscriptions result
///
/// Clients may not extend, implement or mix-in this class.
class FlutterSetSubscriptionsResult implements ResponseResult {
  @override
  Map<String, Object> toJson() => {};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) => other is FlutterSetSubscriptionsResult;

  @override
  int get hashCode => 628296315;
}

/// flutter.setWidgetPropertyValue params
///
/// {
///   "id": int
///   "value": optional FlutterWidgetPropertyValue
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterSetWidgetPropertyValueParams implements RequestParams {
  /// The identifier of the property, previously returned as a part of a
  /// FlutterWidgetProperty.
  ///
  /// An error of type FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_ID is
  /// generated if the identifier is not valid.
  int id;

  /// The new value to set for the property.
  ///
  /// If absent, indicates that the property should be removed. If the property
  /// corresponds to an optional parameter, the corresponding named argument is
  /// removed. If the property isRequired is true,
  /// FLUTTER_SET_WIDGET_PROPERTY_VALUE_IS_REQUIRED error is generated.
  ///
  /// If the expression is not a syntactically valid Dart code, then
  /// FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_EXPRESSION is reported.
  FlutterWidgetPropertyValue? value;

  FlutterSetWidgetPropertyValueParams(this.id, {this.value});

  factory FlutterSetWidgetPropertyValueParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      int id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeInt('$jsonPath.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      FlutterWidgetPropertyValue? value;
      if (json.containsKey('value')) {
        value = FlutterWidgetPropertyValue.fromJson(
            jsonDecoder, '$jsonPath.value', json['value']);
      }
      return FlutterSetWidgetPropertyValueParams(id, value: value);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'flutter.setWidgetPropertyValue params', json);
    }
  }

  factory FlutterSetWidgetPropertyValueParams.fromRequest(Request request) {
    return FlutterSetWidgetPropertyValueParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['id'] = id;
    var value = this.value;
    if (value != null) {
      result['value'] = value.toJson();
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'flutter.setWidgetPropertyValue', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FlutterSetWidgetPropertyValueParams) {
      return id == other.id && value == other.value;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        id,
        value,
      );
}

/// flutter.setWidgetPropertyValue result
///
/// {
///   "change": SourceChange
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterSetWidgetPropertyValueResult implements ResponseResult {
  /// The change that should be applied.
  SourceChange change;

  FlutterSetWidgetPropertyValueResult(this.change);

  factory FlutterSetWidgetPropertyValueResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      SourceChange change;
      if (json.containsKey('change')) {
        change = SourceChange.fromJson(
            jsonDecoder, '$jsonPath.change', json['change']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'change');
      }
      return FlutterSetWidgetPropertyValueResult(change);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'flutter.setWidgetPropertyValue result', json);
    }
  }

  factory FlutterSetWidgetPropertyValueResult.fromResponse(Response response) {
    return FlutterSetWidgetPropertyValueResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['change'] = change.toJson();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FlutterSetWidgetPropertyValueResult) {
      return change == other.change;
    }
    return false;
  }

  @override
  int get hashCode => change.hashCode;
}

/// FlutterWidgetProperty
///
/// {
///   "documentation": optional String
///   "expression": optional String
///   "id": int
///   "isRequired": bool
///   "isSafeToUpdate": bool
///   "name": String
///   "children": optional List<FlutterWidgetProperty>
///   "editor": optional FlutterWidgetPropertyEditor
///   "value": optional FlutterWidgetPropertyValue
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterWidgetProperty implements HasToJson {
  /// The documentation of the property to show to the user. Omitted if the
  /// server does not know the documentation, e.g. because the corresponding
  /// field is not documented.
  String? documentation;

  /// If the value of this property is set, the Dart code of the expression of
  /// this property.
  String? expression;

  /// The unique identifier of the property, must be passed back to the server
  /// when updating the property value. Identifiers become invalid on any
  /// source code change.
  int id;

  /// True if the property is required, e.g. because it corresponds to a
  /// required parameter of a constructor.
  bool isRequired;

  /// If the property expression is a concrete value (e.g. a literal, or an
  /// enum constant), then it is safe to replace the expression with another
  /// concrete value. In this case this field is true. Otherwise, for example
  /// when the expression is a reference to a field, so that its value is
  /// provided from outside, this field is false.
  bool isSafeToUpdate;

  /// The name of the property to display to the user.
  String name;

  /// The list of children properties, if any. For example any property of type
  /// EdgeInsets will have four children properties of type double - left / top
  /// / right / bottom.
  List<FlutterWidgetProperty>? children;

  /// The editor that should be used by the client. This field is omitted if
  /// the server does not know the editor for this property, for example
  /// because it does not have one of the supported types.
  FlutterWidgetPropertyEditor? editor;

  /// If the expression is set, and the server knows the value of the
  /// expression, this field is set.
  FlutterWidgetPropertyValue? value;

  FlutterWidgetProperty(
      this.id, this.isRequired, this.isSafeToUpdate, this.name,
      {this.documentation,
      this.expression,
      this.children,
      this.editor,
      this.value});

  factory FlutterWidgetProperty.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String? documentation;
      if (json.containsKey('documentation')) {
        documentation = jsonDecoder.decodeString(
            '$jsonPath.documentation', json['documentation']);
      }
      String? expression;
      if (json.containsKey('expression')) {
        expression = jsonDecoder.decodeString(
            '$jsonPath.expression', json['expression']);
      }
      int id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeInt('$jsonPath.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      bool isRequired;
      if (json.containsKey('isRequired')) {
        isRequired =
            jsonDecoder.decodeBool('$jsonPath.isRequired', json['isRequired']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'isRequired');
      }
      bool isSafeToUpdate;
      if (json.containsKey('isSafeToUpdate')) {
        isSafeToUpdate = jsonDecoder.decodeBool(
            '$jsonPath.isSafeToUpdate', json['isSafeToUpdate']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'isSafeToUpdate');
      }
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString('$jsonPath.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      List<FlutterWidgetProperty>? children;
      if (json.containsKey('children')) {
        children = jsonDecoder.decodeList(
            '$jsonPath.children',
            json['children'],
            (String jsonPath, Object? json) =>
                FlutterWidgetProperty.fromJson(jsonDecoder, jsonPath, json));
      }
      FlutterWidgetPropertyEditor? editor;
      if (json.containsKey('editor')) {
        editor = FlutterWidgetPropertyEditor.fromJson(
            jsonDecoder, '$jsonPath.editor', json['editor']);
      }
      FlutterWidgetPropertyValue? value;
      if (json.containsKey('value')) {
        value = FlutterWidgetPropertyValue.fromJson(
            jsonDecoder, '$jsonPath.value', json['value']);
      }
      return FlutterWidgetProperty(id, isRequired, isSafeToUpdate, name,
          documentation: documentation,
          expression: expression,
          children: children,
          editor: editor,
          value: value);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'FlutterWidgetProperty', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    var documentation = this.documentation;
    if (documentation != null) {
      result['documentation'] = documentation;
    }
    var expression = this.expression;
    if (expression != null) {
      result['expression'] = expression;
    }
    result['id'] = id;
    result['isRequired'] = isRequired;
    result['isSafeToUpdate'] = isSafeToUpdate;
    result['name'] = name;
    var children = this.children;
    if (children != null) {
      result['children'] = children
          .map((FlutterWidgetProperty value) => value.toJson())
          .toList();
    }
    var editor = this.editor;
    if (editor != null) {
      result['editor'] = editor.toJson();
    }
    var value = this.value;
    if (value != null) {
      result['value'] = value.toJson();
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FlutterWidgetProperty) {
      return documentation == other.documentation &&
          expression == other.expression &&
          id == other.id &&
          isRequired == other.isRequired &&
          isSafeToUpdate == other.isSafeToUpdate &&
          name == other.name &&
          listEqual(children, other.children,
              (FlutterWidgetProperty a, FlutterWidgetProperty b) => a == b) &&
          editor == other.editor &&
          value == other.value;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        documentation,
        expression,
        id,
        isRequired,
        isSafeToUpdate,
        name,
        Object.hashAll(children ?? []),
        editor,
        value,
      );
}

/// FlutterWidgetPropertyEditor
///
/// {
///   "kind": FlutterWidgetPropertyEditorKind
///   "enumItems": optional List<FlutterWidgetPropertyValueEnumItem>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterWidgetPropertyEditor implements HasToJson {
  FlutterWidgetPropertyEditorKind kind;

  List<FlutterWidgetPropertyValueEnumItem>? enumItems;

  FlutterWidgetPropertyEditor(this.kind, {this.enumItems});

  factory FlutterWidgetPropertyEditor.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      FlutterWidgetPropertyEditorKind kind;
      if (json.containsKey('kind')) {
        kind = FlutterWidgetPropertyEditorKind.fromJson(
            jsonDecoder, '$jsonPath.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      List<FlutterWidgetPropertyValueEnumItem>? enumItems;
      if (json.containsKey('enumItems')) {
        enumItems = jsonDecoder.decodeList(
            '$jsonPath.enumItems',
            json['enumItems'],
            (String jsonPath, Object? json) =>
                FlutterWidgetPropertyValueEnumItem.fromJson(
                    jsonDecoder, jsonPath, json));
      }
      return FlutterWidgetPropertyEditor(kind, enumItems: enumItems);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'FlutterWidgetPropertyEditor', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['kind'] = kind.toJson();
    var enumItems = this.enumItems;
    if (enumItems != null) {
      result['enumItems'] = enumItems
          .map((FlutterWidgetPropertyValueEnumItem value) => value.toJson())
          .toList();
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FlutterWidgetPropertyEditor) {
      return kind == other.kind &&
          listEqual(
              enumItems,
              other.enumItems,
              (FlutterWidgetPropertyValueEnumItem a,
                      FlutterWidgetPropertyValueEnumItem b) =>
                  a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        kind,
        Object.hashAll(enumItems ?? []),
      );
}

/// FlutterWidgetPropertyEditorKind
///
/// enum {
///   BOOL
///   DOUBLE
///   ENUM
///   ENUM_LIKE
///   INT
///   STRING
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterWidgetPropertyEditorKind implements Enum {
  /// The editor for a property of type bool.
  static const FlutterWidgetPropertyEditorKind BOOL =
      FlutterWidgetPropertyEditorKind._('BOOL');

  /// The editor for a property of the type double.
  static const FlutterWidgetPropertyEditorKind DOUBLE =
      FlutterWidgetPropertyEditorKind._('DOUBLE');

  /// The editor for choosing an item of an enumeration, see the enumItems
  /// field of FlutterWidgetPropertyEditor.
  static const FlutterWidgetPropertyEditorKind ENUM =
      FlutterWidgetPropertyEditorKind._('ENUM');

  /// The editor for either choosing a pre-defined item from a list of provided
  /// static field references (like ENUM), or specifying a free-form
  /// expression.
  static const FlutterWidgetPropertyEditorKind ENUM_LIKE =
      FlutterWidgetPropertyEditorKind._('ENUM_LIKE');

  /// The editor for a property of type int.
  static const FlutterWidgetPropertyEditorKind INT =
      FlutterWidgetPropertyEditorKind._('INT');

  /// The editor for a property of the type String.
  static const FlutterWidgetPropertyEditorKind STRING =
      FlutterWidgetPropertyEditorKind._('STRING');

  /// A list containing all of the enum values that are defined.
  static const List<FlutterWidgetPropertyEditorKind> VALUES =
      <FlutterWidgetPropertyEditorKind>[
    BOOL,
    DOUBLE,
    ENUM,
    ENUM_LIKE,
    INT,
    STRING
  ];

  @override
  final String name;

  const FlutterWidgetPropertyEditorKind._(this.name);

  factory FlutterWidgetPropertyEditorKind(String name) {
    switch (name) {
      case 'BOOL':
        return BOOL;
      case 'DOUBLE':
        return DOUBLE;
      case 'ENUM':
        return ENUM;
      case 'ENUM_LIKE':
        return ENUM_LIKE;
      case 'INT':
        return INT;
      case 'STRING':
        return STRING;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory FlutterWidgetPropertyEditorKind.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    if (json is String) {
      try {
        return FlutterWidgetPropertyEditorKind(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(
        jsonPath, 'FlutterWidgetPropertyEditorKind', json);
  }

  @override
  String toString() => 'FlutterWidgetPropertyEditorKind.$name';

  String toJson() => name;
}

/// FlutterWidgetPropertyValue
///
/// {
///   "boolValue": optional bool
///   "doubleValue": optional double
///   "intValue": optional int
///   "stringValue": optional String
///   "enumValue": optional FlutterWidgetPropertyValueEnumItem
///   "expression": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterWidgetPropertyValue implements HasToJson {
  bool? boolValue;

  double? doubleValue;

  int? intValue;

  String? stringValue;

  FlutterWidgetPropertyValueEnumItem? enumValue;

  /// A free-form expression, which will be used as the value as is.
  String? expression;

  FlutterWidgetPropertyValue(
      {this.boolValue,
      this.doubleValue,
      this.intValue,
      this.stringValue,
      this.enumValue,
      this.expression});

  factory FlutterWidgetPropertyValue.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      bool? boolValue;
      if (json.containsKey('boolValue')) {
        boolValue =
            jsonDecoder.decodeBool('$jsonPath.boolValue', json['boolValue']);
      }
      double? doubleValue;
      if (json.containsKey('doubleValue')) {
        doubleValue = jsonDecoder.decodeDouble(
            '$jsonPath.doubleValue', json['doubleValue'] as Object);
      }
      int? intValue;
      if (json.containsKey('intValue')) {
        intValue =
            jsonDecoder.decodeInt('$jsonPath.intValue', json['intValue']);
      }
      String? stringValue;
      if (json.containsKey('stringValue')) {
        stringValue = jsonDecoder.decodeString(
            '$jsonPath.stringValue', json['stringValue']);
      }
      FlutterWidgetPropertyValueEnumItem? enumValue;
      if (json.containsKey('enumValue')) {
        enumValue = FlutterWidgetPropertyValueEnumItem.fromJson(
            jsonDecoder, '$jsonPath.enumValue', json['enumValue']);
      }
      String? expression;
      if (json.containsKey('expression')) {
        expression = jsonDecoder.decodeString(
            '$jsonPath.expression', json['expression']);
      }
      return FlutterWidgetPropertyValue(
          boolValue: boolValue,
          doubleValue: doubleValue,
          intValue: intValue,
          stringValue: stringValue,
          enumValue: enumValue,
          expression: expression);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'FlutterWidgetPropertyValue', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    var boolValue = this.boolValue;
    if (boolValue != null) {
      result['boolValue'] = boolValue;
    }
    var doubleValue = this.doubleValue;
    if (doubleValue != null) {
      result['doubleValue'] = doubleValue;
    }
    var intValue = this.intValue;
    if (intValue != null) {
      result['intValue'] = intValue;
    }
    var stringValue = this.stringValue;
    if (stringValue != null) {
      result['stringValue'] = stringValue;
    }
    var enumValue = this.enumValue;
    if (enumValue != null) {
      result['enumValue'] = enumValue.toJson();
    }
    var expression = this.expression;
    if (expression != null) {
      result['expression'] = expression;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FlutterWidgetPropertyValue) {
      return boolValue == other.boolValue &&
          doubleValue == other.doubleValue &&
          intValue == other.intValue &&
          stringValue == other.stringValue &&
          enumValue == other.enumValue &&
          expression == other.expression;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        boolValue,
        doubleValue,
        intValue,
        stringValue,
        enumValue,
        expression,
      );
}

/// FlutterWidgetPropertyValueEnumItem
///
/// {
///   "libraryUri": String
///   "className": String
///   "name": String
///   "documentation": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterWidgetPropertyValueEnumItem implements HasToJson {
  /// The URI of the library containing the className. When the enum item is
  /// passed back, this will allow the server to import the corresponding
  /// library if necessary.
  String libraryUri;

  /// The name of the class or enum.
  String className;

  /// The name of the field in the enumeration, or the static field in the
  /// class.
  String name;

  /// The documentation to show to the user. Omitted if the server does not
  /// know the documentation, e.g. because the corresponding field is not
  /// documented.
  String? documentation;

  FlutterWidgetPropertyValueEnumItem(this.libraryUri, this.className, this.name,
      {this.documentation});

  factory FlutterWidgetPropertyValueEnumItem.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String libraryUri;
      if (json.containsKey('libraryUri')) {
        libraryUri = jsonDecoder.decodeString(
            '$jsonPath.libraryUri', json['libraryUri']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'libraryUri');
      }
      String className;
      if (json.containsKey('className')) {
        className =
            jsonDecoder.decodeString('$jsonPath.className', json['className']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'className');
      }
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString('$jsonPath.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      String? documentation;
      if (json.containsKey('documentation')) {
        documentation = jsonDecoder.decodeString(
            '$jsonPath.documentation', json['documentation']);
      }
      return FlutterWidgetPropertyValueEnumItem(libraryUri, className, name,
          documentation: documentation);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'FlutterWidgetPropertyValueEnumItem', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['libraryUri'] = libraryUri;
    result['className'] = className;
    result['name'] = name;
    var documentation = this.documentation;
    if (documentation != null) {
      result['documentation'] = documentation;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FlutterWidgetPropertyValueEnumItem) {
      return libraryUri == other.libraryUri &&
          className == other.className &&
          name == other.name &&
          documentation == other.documentation;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        libraryUri,
        className,
        name,
        documentation,
      );
}

/// GeneralAnalysisService
///
/// enum {
///   ANALYZED_FILES
/// }
///
/// Clients may not extend, implement or mix-in this class.
class GeneralAnalysisService implements Enum {
  static const GeneralAnalysisService ANALYZED_FILES =
      GeneralAnalysisService._('ANALYZED_FILES');

  /// A list containing all of the enum values that are defined.
  static const List<GeneralAnalysisService> VALUES = <GeneralAnalysisService>[
    ANALYZED_FILES
  ];

  @override
  final String name;

  const GeneralAnalysisService._(this.name);

  factory GeneralAnalysisService(String name) {
    switch (name) {
      case 'ANALYZED_FILES':
        return ANALYZED_FILES;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory GeneralAnalysisService.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    if (json is String) {
      try {
        return GeneralAnalysisService(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'GeneralAnalysisService', json);
  }

  @override
  String toString() => 'GeneralAnalysisService.$name';

  String toJson() => name;
}

/// HoverInformation
///
/// {
///   "offset": int
///   "length": int
///   "containingLibraryPath": optional String
///   "containingLibraryName": optional String
///   "containingClassDescription": optional String
///   "dartdoc": optional String
///   "elementDescription": optional String
///   "elementKind": optional String
///   "isDeprecated": optional bool
///   "parameter": optional String
///   "propagatedType": optional String
///   "staticType": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class HoverInformation implements HasToJson {
  /// The offset of the range of characters that encompasses the cursor
  /// position and has the same hover information as the cursor position.
  int offset;

  /// The length of the range of characters that encompasses the cursor
  /// position and has the same hover information as the cursor position.
  int length;

  /// The path to the defining compilation unit of the library in which the
  /// referenced element is declared. This data is omitted if there is no
  /// referenced element, or if the element is declared inside an HTML file.
  String? containingLibraryPath;

  /// The URI of the containing library, examples here include "dart:core",
  /// "package:.." and file uris represented by the path on disk, "/..". The
  /// data is omitted if the element is declared inside an HTML file.
  String? containingLibraryName;

  /// A human-readable description of the class declaring the element being
  /// referenced. This data is omitted if there is no referenced element, or if
  /// the element is not a class member.
  String? containingClassDescription;

  /// The dartdoc associated with the referenced element. Other than the
  /// removal of the comment delimiters, including leading asterisks in the
  /// case of a block comment, the dartdoc is unprocessed markdown. This data
  /// is omitted if there is no referenced element, or if the element has no
  /// dartdoc.
  String? dartdoc;

  /// A human-readable description of the element being referenced. This data
  /// is omitted if there is no referenced element.
  String? elementDescription;

  /// A human-readable description of the kind of element being referenced
  /// (such as "class" or "function type alias"). This data is omitted if there
  /// is no referenced element.
  String? elementKind;

  /// True if the referenced element is deprecated.
  bool? isDeprecated;

  /// A human-readable description of the parameter corresponding to the
  /// expression being hovered over. This data is omitted if the location is
  /// not in an argument to a function.
  String? parameter;

  /// The name of the propagated type of the expression. This data is omitted
  /// if the location does not correspond to an expression or if there is no
  /// propagated type information.
  String? propagatedType;

  /// The name of the static type of the expression. This data is omitted if
  /// the location does not correspond to an expression.
  String? staticType;

  HoverInformation(this.offset, this.length,
      {this.containingLibraryPath,
      this.containingLibraryName,
      this.containingClassDescription,
      this.dartdoc,
      this.elementDescription,
      this.elementKind,
      this.isDeprecated,
      this.parameter,
      this.propagatedType,
      this.staticType});

  factory HoverInformation.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
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
      String? containingLibraryPath;
      if (json.containsKey('containingLibraryPath')) {
        containingLibraryPath = jsonDecoder.decodeString(
            '$jsonPath.containingLibraryPath', json['containingLibraryPath']);
      }
      String? containingLibraryName;
      if (json.containsKey('containingLibraryName')) {
        containingLibraryName = jsonDecoder.decodeString(
            '$jsonPath.containingLibraryName', json['containingLibraryName']);
      }
      String? containingClassDescription;
      if (json.containsKey('containingClassDescription')) {
        containingClassDescription = jsonDecoder.decodeString(
            '$jsonPath.containingClassDescription',
            json['containingClassDescription']);
      }
      String? dartdoc;
      if (json.containsKey('dartdoc')) {
        dartdoc =
            jsonDecoder.decodeString('$jsonPath.dartdoc', json['dartdoc']);
      }
      String? elementDescription;
      if (json.containsKey('elementDescription')) {
        elementDescription = jsonDecoder.decodeString(
            '$jsonPath.elementDescription', json['elementDescription']);
      }
      String? elementKind;
      if (json.containsKey('elementKind')) {
        elementKind = jsonDecoder.decodeString(
            '$jsonPath.elementKind', json['elementKind']);
      }
      bool? isDeprecated;
      if (json.containsKey('isDeprecated')) {
        isDeprecated = jsonDecoder.decodeBool(
            '$jsonPath.isDeprecated', json['isDeprecated']);
      }
      String? parameter;
      if (json.containsKey('parameter')) {
        parameter =
            jsonDecoder.decodeString('$jsonPath.parameter', json['parameter']);
      }
      String? propagatedType;
      if (json.containsKey('propagatedType')) {
        propagatedType = jsonDecoder.decodeString(
            '$jsonPath.propagatedType', json['propagatedType']);
      }
      String? staticType;
      if (json.containsKey('staticType')) {
        staticType = jsonDecoder.decodeString(
            '$jsonPath.staticType', json['staticType']);
      }
      return HoverInformation(offset, length,
          containingLibraryPath: containingLibraryPath,
          containingLibraryName: containingLibraryName,
          containingClassDescription: containingClassDescription,
          dartdoc: dartdoc,
          elementDescription: elementDescription,
          elementKind: elementKind,
          isDeprecated: isDeprecated,
          parameter: parameter,
          propagatedType: propagatedType,
          staticType: staticType);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'HoverInformation', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['offset'] = offset;
    result['length'] = length;
    var containingLibraryPath = this.containingLibraryPath;
    if (containingLibraryPath != null) {
      result['containingLibraryPath'] = containingLibraryPath;
    }
    var containingLibraryName = this.containingLibraryName;
    if (containingLibraryName != null) {
      result['containingLibraryName'] = containingLibraryName;
    }
    var containingClassDescription = this.containingClassDescription;
    if (containingClassDescription != null) {
      result['containingClassDescription'] = containingClassDescription;
    }
    var dartdoc = this.dartdoc;
    if (dartdoc != null) {
      result['dartdoc'] = dartdoc;
    }
    var elementDescription = this.elementDescription;
    if (elementDescription != null) {
      result['elementDescription'] = elementDescription;
    }
    var elementKind = this.elementKind;
    if (elementKind != null) {
      result['elementKind'] = elementKind;
    }
    var isDeprecated = this.isDeprecated;
    if (isDeprecated != null) {
      result['isDeprecated'] = isDeprecated;
    }
    var parameter = this.parameter;
    if (parameter != null) {
      result['parameter'] = parameter;
    }
    var propagatedType = this.propagatedType;
    if (propagatedType != null) {
      result['propagatedType'] = propagatedType;
    }
    var staticType = this.staticType;
    if (staticType != null) {
      result['staticType'] = staticType;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is HoverInformation) {
      return offset == other.offset &&
          length == other.length &&
          containingLibraryPath == other.containingLibraryPath &&
          containingLibraryName == other.containingLibraryName &&
          containingClassDescription == other.containingClassDescription &&
          dartdoc == other.dartdoc &&
          elementDescription == other.elementDescription &&
          elementKind == other.elementKind &&
          isDeprecated == other.isDeprecated &&
          parameter == other.parameter &&
          propagatedType == other.propagatedType &&
          staticType == other.staticType;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        offset,
        length,
        containingLibraryPath,
        containingLibraryName,
        containingClassDescription,
        dartdoc,
        elementDescription,
        elementKind,
        isDeprecated,
        parameter,
        propagatedType,
        staticType,
      );
}

/// ImplementedClass
///
/// {
///   "offset": int
///   "length": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ImplementedClass implements HasToJson {
  /// The offset of the name of the implemented class.
  int offset;

  /// The length of the name of the implemented class.
  int length;

  ImplementedClass(this.offset, this.length);

  factory ImplementedClass.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
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
      return ImplementedClass(offset, length);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ImplementedClass', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['offset'] = offset;
    result['length'] = length;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ImplementedClass) {
      return offset == other.offset && length == other.length;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        offset,
        length,
      );
}

/// ImplementedMember
///
/// {
///   "offset": int
///   "length": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ImplementedMember implements HasToJson {
  /// The offset of the name of the implemented member.
  int offset;

  /// The length of the name of the implemented member.
  int length;

  ImplementedMember(this.offset, this.length);

  factory ImplementedMember.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
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
      return ImplementedMember(offset, length);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ImplementedMember', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['offset'] = offset;
    result['length'] = length;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ImplementedMember) {
      return offset == other.offset && length == other.length;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        offset,
        length,
      );
}

/// ImportedElementSet
///
/// {
///   "strings": List<String>
///   "uris": List<int>
///   "names": List<int>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ImportedElementSet implements HasToJson {
  /// The list of unique strings in this object.
  List<String> strings;

  /// The library URI part of the element. It is an index in the strings field.
  List<int> uris;

  /// The name part of a the element. It is an index in the strings field.
  List<int> names;

  ImportedElementSet(this.strings, this.uris, this.names);

  factory ImportedElementSet.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<String> strings;
      if (json.containsKey('strings')) {
        strings = jsonDecoder.decodeList(
            '$jsonPath.strings', json['strings'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'strings');
      }
      List<int> uris;
      if (json.containsKey('uris')) {
        uris = jsonDecoder.decodeList(
            '$jsonPath.uris', json['uris'], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'uris');
      }
      List<int> names;
      if (json.containsKey('names')) {
        names = jsonDecoder.decodeList(
            '$jsonPath.names', json['names'], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'names');
      }
      return ImportedElementSet(strings, uris, names);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ImportedElementSet', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['strings'] = strings;
    result['uris'] = uris;
    result['names'] = names;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ImportedElementSet) {
      return listEqual(
              strings, other.strings, (String a, String b) => a == b) &&
          listEqual(uris, other.uris, (int a, int b) => a == b) &&
          listEqual(names, other.names, (int a, int b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(strings),
        Object.hashAll(uris),
        Object.hashAll(names),
      );
}

/// ImportedElements
///
/// {
///   "path": FilePath
///   "prefix": String
///   "elements": List<String>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ImportedElements implements HasToJson {
  /// The absolute and normalized path of the file containing the library.
  String path;

  /// The prefix that was used when importing the library into the original
  /// source.
  String prefix;

  /// The names of the elements imported from the library.
  List<String> elements;

  ImportedElements(this.path, this.prefix, this.elements);

  factory ImportedElements.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String path;
      if (json.containsKey('path')) {
        path = jsonDecoder.decodeString('$jsonPath.path', json['path']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'path');
      }
      String prefix;
      if (json.containsKey('prefix')) {
        prefix = jsonDecoder.decodeString('$jsonPath.prefix', json['prefix']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'prefix');
      }
      List<String> elements;
      if (json.containsKey('elements')) {
        elements = jsonDecoder.decodeList(
            '$jsonPath.elements', json['elements'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'elements');
      }
      return ImportedElements(path, prefix, elements);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ImportedElements', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['path'] = path;
    result['prefix'] = prefix;
    result['elements'] = elements;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ImportedElements) {
      return path == other.path &&
          prefix == other.prefix &&
          listEqual(elements, other.elements, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        path,
        prefix,
        Object.hashAll(elements),
      );
}

/// IncludedSuggestionRelevanceTag
///
/// {
///   "tag": AvailableSuggestionRelevanceTag
///   "relevanceBoost": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class IncludedSuggestionRelevanceTag implements HasToJson {
  /// The opaque value of the tag.
  String tag;

  /// The boost to the relevance of the completion suggestions that match this
  /// tag, which is added to the relevance of the containing
  /// IncludedSuggestionSet.
  int relevanceBoost;

  IncludedSuggestionRelevanceTag(this.tag, this.relevanceBoost);

  factory IncludedSuggestionRelevanceTag.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String tag;
      if (json.containsKey('tag')) {
        tag = jsonDecoder.decodeString('$jsonPath.tag', json['tag']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'tag');
      }
      int relevanceBoost;
      if (json.containsKey('relevanceBoost')) {
        relevanceBoost = jsonDecoder.decodeInt(
            '$jsonPath.relevanceBoost', json['relevanceBoost']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'relevanceBoost');
      }
      return IncludedSuggestionRelevanceTag(tag, relevanceBoost);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'IncludedSuggestionRelevanceTag', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['tag'] = tag;
    result['relevanceBoost'] = relevanceBoost;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is IncludedSuggestionRelevanceTag) {
      return tag == other.tag && relevanceBoost == other.relevanceBoost;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        tag,
        relevanceBoost,
      );
}

/// IncludedSuggestionSet
///
/// {
///   "id": int
///   "relevance": int
///   "displayUri": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class IncludedSuggestionSet implements HasToJson {
  /// Clients should use it to access the set of precomputed completions to be
  /// displayed to the user.
  int id;

  /// The relevance of completion suggestions from this library where a higher
  /// number indicates a higher relevance.
  int relevance;

  /// The optional string that should be displayed instead of the uri of the
  /// referenced AvailableSuggestionSet.
  ///
  /// For example libraries in the "test" directory of a package have only
  /// "file://" URIs, so are usually long, and don't look nice, but actual
  /// import directives will use relative URIs, which are short, so we probably
  /// want to display such relative URIs to the user.
  String? displayUri;

  IncludedSuggestionSet(this.id, this.relevance, {this.displayUri});

  factory IncludedSuggestionSet.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      int id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeInt('$jsonPath.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      int relevance;
      if (json.containsKey('relevance')) {
        relevance =
            jsonDecoder.decodeInt('$jsonPath.relevance', json['relevance']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'relevance');
      }
      String? displayUri;
      if (json.containsKey('displayUri')) {
        displayUri = jsonDecoder.decodeString(
            '$jsonPath.displayUri', json['displayUri']);
      }
      return IncludedSuggestionSet(id, relevance, displayUri: displayUri);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'IncludedSuggestionSet', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['id'] = id;
    result['relevance'] = relevance;
    var displayUri = this.displayUri;
    if (displayUri != null) {
      result['displayUri'] = displayUri;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is IncludedSuggestionSet) {
      return id == other.id &&
          relevance == other.relevance &&
          displayUri == other.displayUri;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        id,
        relevance,
        displayUri,
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
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
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
        occurrences =
            jsonDecoder.decodeInt('$jsonPath.occurrences', json['occurrences']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'occurrences');
      }
      return InlineLocalVariableFeedback(name, occurrences);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'inlineLocalVariable feedback', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['name'] = name;
    result['occurrences'] = occurrences;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is InlineLocalVariableFeedback) {
      return name == other.name && occurrences == other.occurrences;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        name,
        occurrences,
      );
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

  /// True if the declaration of the method is selected. So all references
  /// should be inlined.
  bool isDeclaration;

  InlineMethodFeedback(this.methodName, this.isDeclaration, {this.className});

  factory InlineMethodFeedback.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String? className;
      if (json.containsKey('className')) {
        className =
            jsonDecoder.decodeString('$jsonPath.className', json['className']);
      }
      String methodName;
      if (json.containsKey('methodName')) {
        methodName = jsonDecoder.decodeString(
            '$jsonPath.methodName', json['methodName']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'methodName');
      }
      bool isDeclaration;
      if (json.containsKey('isDeclaration')) {
        isDeclaration = jsonDecoder.decodeBool(
            '$jsonPath.isDeclaration', json['isDeclaration']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'isDeclaration');
      }
      return InlineMethodFeedback(methodName, isDeclaration,
          className: className);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'inlineMethod feedback', json);
    }
  }

  @override
  Map<String, Object> toJson() {
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
  String toString() => json.encode(toJson());

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
  int get hashCode => Object.hash(
        className,
        methodName,
        isDeclaration,
      );
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
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      bool deleteSource;
      if (json.containsKey('deleteSource')) {
        deleteSource = jsonDecoder.decodeBool(
            '$jsonPath.deleteSource', json['deleteSource']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'deleteSource');
      }
      bool inlineAll;
      if (json.containsKey('inlineAll')) {
        inlineAll =
            jsonDecoder.decodeBool('$jsonPath.inlineAll', json['inlineAll']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'inlineAll');
      }
      return InlineMethodOptions(deleteSource, inlineAll);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'inlineMethod options', json);
    }
  }

  factory InlineMethodOptions.fromRefactoringParams(
      EditGetRefactoringParams refactoringParams, Request request) {
    return InlineMethodOptions.fromJson(
        RequestDecoder(request), 'options', refactoringParams.options);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['deleteSource'] = deleteSource;
    result['inlineAll'] = inlineAll;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is InlineMethodOptions) {
      return deleteSource == other.deleteSource && inlineAll == other.inlineAll;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        deleteSource,
        inlineAll,
      );
}

/// LibraryPathSet
///
/// {
///   "scope": FilePath
///   "libraryPaths": List<FilePath>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class LibraryPathSet implements HasToJson {
  /// The filepath for which this request's libraries should be active in
  /// completion suggestions. This object associates filesystem regions to
  /// libraries and library directories of interest to the client.
  String scope;

  /// The paths of the libraries of interest to the client for completion
  /// suggestions.
  List<String> libraryPaths;

  LibraryPathSet(this.scope, this.libraryPaths);

  factory LibraryPathSet.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String scope;
      if (json.containsKey('scope')) {
        scope = jsonDecoder.decodeString('$jsonPath.scope', json['scope']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'scope');
      }
      List<String> libraryPaths;
      if (json.containsKey('libraryPaths')) {
        libraryPaths = jsonDecoder.decodeList('$jsonPath.libraryPaths',
            json['libraryPaths'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'libraryPaths');
      }
      return LibraryPathSet(scope, libraryPaths);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'LibraryPathSet', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['scope'] = scope;
    result['libraryPaths'] = libraryPaths;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is LibraryPathSet) {
      return scope == other.scope &&
          listEqual(
              libraryPaths, other.libraryPaths, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        scope,
        Object.hashAll(libraryPaths),
      );
}

/// lsp.handle params
///
/// {
///   "lspMessage": object
/// }
///
/// Clients may not extend, implement or mix-in this class.
class LspHandleParams implements RequestParams {
  /// The LSP RequestMessage.
  Object lspMessage;

  LspHandleParams(this.lspMessage);

  factory LspHandleParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      Object lspMessage;
      if (json.containsKey('lspMessage')) {
        lspMessage = json['lspMessage'] as Object;
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'lspMessage');
      }
      return LspHandleParams(lspMessage);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'lsp.handle params', json);
    }
  }

  factory LspHandleParams.fromRequest(Request request) {
    return LspHandleParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['lspMessage'] = lspMessage;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'lsp.handle', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is LspHandleParams) {
      return lspMessage == other.lspMessage;
    }
    return false;
  }

  @override
  int get hashCode => lspMessage.hashCode;
}

/// lsp.handle result
///
/// {
///   "lspResponse": object
/// }
///
/// Clients may not extend, implement or mix-in this class.
class LspHandleResult implements ResponseResult {
  /// The LSP ResponseMessage returned by the handler.
  Object lspResponse;

  LspHandleResult(this.lspResponse);

  factory LspHandleResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      Object lspResponse;
      if (json.containsKey('lspResponse')) {
        lspResponse = json['lspResponse'] as Object;
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'lspResponse');
      }
      return LspHandleResult(lspResponse);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'lsp.handle result', json);
    }
  }

  factory LspHandleResult.fromResponse(Response response) {
    return LspHandleResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['lspResponse'] = lspResponse;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is LspHandleResult) {
      return lspResponse == other.lspResponse;
    }
    return false;
  }

  @override
  int get hashCode => lspResponse.hashCode;
}

/// MessageAction
///
/// {
///   "label": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class MessageAction implements HasToJson {
  /// The label of the button to be displayed, and the value to be returned to
  /// the server if the button is clicked.
  String label;

  MessageAction(this.label);

  factory MessageAction.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String label;
      if (json.containsKey('label')) {
        label = jsonDecoder.decodeString('$jsonPath.label', json['label']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'label');
      }
      return MessageAction(label);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'MessageAction', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['label'] = label;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is MessageAction) {
      return label == other.label;
    }
    return false;
  }

  @override
  int get hashCode => label.hashCode;
}

/// MessageType
///
/// enum {
///   ERROR
///   WARNING
///   INFO
///   LOG
/// }
///
/// Clients may not extend, implement or mix-in this class.
class MessageType implements Enum {
  /// The message is an error message.
  static const MessageType ERROR = MessageType._('ERROR');

  /// The message is a warning message.
  static const MessageType WARNING = MessageType._('WARNING');

  /// The message is an informational message.
  static const MessageType INFO = MessageType._('INFO');

  /// The message is a log message.
  static const MessageType LOG = MessageType._('LOG');

  /// A list containing all of the enum values that are defined.
  static const List<MessageType> VALUES = <MessageType>[
    ERROR,
    WARNING,
    INFO,
    LOG
  ];

  @override
  final String name;

  const MessageType._(this.name);

  factory MessageType(String name) {
    switch (name) {
      case 'ERROR':
        return ERROR;
      case 'WARNING':
        return WARNING;
      case 'INFO':
        return INFO;
      case 'LOG':
        return LOG;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory MessageType.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    if (json is String) {
      try {
        return MessageType(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'MessageType', json);
  }

  @override
  String toString() => 'MessageType.$name';

  String toJson() => name;
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
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String newFile;
      if (json.containsKey('newFile')) {
        newFile =
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
      EditGetRefactoringParams refactoringParams, Request request) {
    return MoveFileOptions.fromJson(
        RequestDecoder(request), 'options', refactoringParams.options);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['newFile'] = newFile;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

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

/// OverriddenMember
///
/// {
///   "element": Element
///   "className": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class OverriddenMember implements HasToJson {
  /// The element that is being overridden.
  Element element;

  /// The name of the class in which the member is defined.
  String className;

  OverriddenMember(this.element, this.className);

  factory OverriddenMember.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      Element element;
      if (json.containsKey('element')) {
        element =
            Element.fromJson(jsonDecoder, '$jsonPath.element', json['element']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'element');
      }
      String className;
      if (json.containsKey('className')) {
        className =
            jsonDecoder.decodeString('$jsonPath.className', json['className']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'className');
      }
      return OverriddenMember(element, className);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'OverriddenMember', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['element'] = element.toJson();
    result['className'] = className;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is OverriddenMember) {
      return element == other.element && className == other.className;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        element,
        className,
      );
}

/// Override
///
/// {
///   "offset": int
///   "length": int
///   "superclassMember": optional OverriddenMember
///   "interfaceMembers": optional List<OverriddenMember>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class Override implements HasToJson {
  /// The offset of the name of the overriding member.
  int offset;

  /// The length of the name of the overriding member.
  int length;

  /// The member inherited from a superclass that is overridden by the
  /// overriding member. The field is omitted if there is no superclass member,
  /// in which case there must be at least one interface member.
  OverriddenMember? superclassMember;

  /// The members inherited from interfaces that are overridden by the
  /// overriding member. The field is omitted if there are no interface
  /// members, in which case there must be a superclass member.
  List<OverriddenMember>? interfaceMembers;

  Override(this.offset, this.length,
      {this.superclassMember, this.interfaceMembers});

  factory Override.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
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
      OverriddenMember? superclassMember;
      if (json.containsKey('superclassMember')) {
        superclassMember = OverriddenMember.fromJson(jsonDecoder,
            '$jsonPath.superclassMember', json['superclassMember']);
      }
      List<OverriddenMember>? interfaceMembers;
      if (json.containsKey('interfaceMembers')) {
        interfaceMembers = jsonDecoder.decodeList(
            '$jsonPath.interfaceMembers',
            json['interfaceMembers'],
            (String jsonPath, Object? json) =>
                OverriddenMember.fromJson(jsonDecoder, jsonPath, json));
      }
      return Override(offset, length,
          superclassMember: superclassMember,
          interfaceMembers: interfaceMembers);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'Override', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['offset'] = offset;
    result['length'] = length;
    var superclassMember = this.superclassMember;
    if (superclassMember != null) {
      result['superclassMember'] = superclassMember.toJson();
    }
    var interfaceMembers = this.interfaceMembers;
    if (interfaceMembers != null) {
      result['interfaceMembers'] = interfaceMembers
          .map((OverriddenMember value) => value.toJson())
          .toList();
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is Override) {
      return offset == other.offset &&
          length == other.length &&
          superclassMember == other.superclassMember &&
          listEqual(interfaceMembers, other.interfaceMembers,
              (OverriddenMember a, OverriddenMember b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        offset,
        length,
        superclassMember,
        Object.hashAll(interfaceMembers ?? []),
      );
}

/// PostfixTemplateDescriptor
///
/// {
///   "name": String
///   "key": String
///   "example": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class PostfixTemplateDescriptor implements HasToJson {
  /// The template name, shown in the UI.
  String name;

  /// The unique template key, not shown in the UI.
  String key;

  /// A short example of the transformation performed when the template is
  /// applied.
  String example;

  PostfixTemplateDescriptor(this.name, this.key, this.example);

  factory PostfixTemplateDescriptor.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString('$jsonPath.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      String key;
      if (json.containsKey('key')) {
        key = jsonDecoder.decodeString('$jsonPath.key', json['key']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'key');
      }
      String example;
      if (json.containsKey('example')) {
        example =
            jsonDecoder.decodeString('$jsonPath.example', json['example']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'example');
      }
      return PostfixTemplateDescriptor(name, key, example);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'PostfixTemplateDescriptor', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['name'] = name;
    result['key'] = key;
    result['example'] = example;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is PostfixTemplateDescriptor) {
      return name == other.name && key == other.key && example == other.example;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        name,
        key,
        example,
      );
}

/// PubStatus
///
/// {
///   "isListingPackageDirs": bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class PubStatus implements HasToJson {
  /// True if the server is currently running pub to produce a list of package
  /// directories.
  bool isListingPackageDirs;

  PubStatus(this.isListingPackageDirs);

  factory PubStatus.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      bool isListingPackageDirs;
      if (json.containsKey('isListingPackageDirs')) {
        isListingPackageDirs = jsonDecoder.decodeBool(
            '$jsonPath.isListingPackageDirs', json['isListingPackageDirs']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'isListingPackageDirs');
      }
      return PubStatus(isListingPackageDirs);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'PubStatus', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['isListingPackageDirs'] = isListingPackageDirs;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is PubStatus) {
      return isListingPackageDirs == other.isListingPackageDirs;
    }
    return false;
  }

  @override
  int get hashCode => isListingPackageDirs.hashCode;
}

/// RefactoringFeedback
///
/// {
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RefactoringFeedback implements HasToJson {
  RefactoringFeedback();

  static RefactoringFeedback? fromJson(JsonDecoder jsonDecoder, String jsonPath,
      Object? json, Map<Object?, Object?> responseJson) {
    return refactoringFeedbackFromJson(
        jsonDecoder, jsonPath, json, responseJson);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    return result;
  }

  @override
  String toString() => json.encode(toJson());

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

  static RefactoringOptions? fromJson(JsonDecoder jsonDecoder, String jsonPath,
      Object? json, RefactoringKind kind) {
    return refactoringOptionsFromJson(jsonDecoder, jsonPath, json, kind);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    return result;
  }

  @override
  String toString() => json.encode(toJson());

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
  /// The offset to the beginning of the name selected to be renamed, or -1 if
  /// the name does not exist yet.
  int offset;

  /// The length of the name selected to be renamed.
  int length;

  /// The human-readable description of the kind of element being renamed (such
  /// as "class" or "function type alias").
  String elementKindName;

  /// The old name of the element before the refactoring.
  String oldName;

  RenameFeedback(this.offset, this.length, this.elementKindName, this.oldName);

  factory RenameFeedback.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
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
            '$jsonPath.elementKindName', json['elementKindName']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'elementKindName');
      }
      String oldName;
      if (json.containsKey('oldName')) {
        oldName =
            jsonDecoder.decodeString('$jsonPath.oldName', json['oldName']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'oldName');
      }
      return RenameFeedback(offset, length, elementKindName, oldName);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'rename feedback', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['offset'] = offset;
    result['length'] = length;
    result['elementKindName'] = elementKindName;
    result['oldName'] = oldName;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

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
  int get hashCode => Object.hash(
        offset,
        length,
        elementKindName,
        oldName,
      );
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
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String newName;
      if (json.containsKey('newName')) {
        newName =
            jsonDecoder.decodeString('$jsonPath.newName', json['newName']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'newName');
      }
      return RenameOptions(newName);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'rename options', json);
    }
  }

  factory RenameOptions.fromRefactoringParams(
      EditGetRefactoringParams refactoringParams, Request request) {
    return RenameOptions.fromJson(
        RequestDecoder(request), 'options', refactoringParams.options);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['newName'] = newName;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

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
  /// debugging the server.
  String? stackTrace;

  RequestError(this.code, this.message, {this.stackTrace});

  factory RequestError.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      RequestErrorCode code;
      if (json.containsKey('code')) {
        code = RequestErrorCode.fromJson(
            jsonDecoder, '$jsonPath.code', json['code']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'code');
      }
      String message;
      if (json.containsKey('message')) {
        message =
            jsonDecoder.decodeString('$jsonPath.message', json['message']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'message');
      }
      String? stackTrace;
      if (json.containsKey('stackTrace')) {
        stackTrace = jsonDecoder.decodeString(
            '$jsonPath.stackTrace', json['stackTrace']);
      }
      return RequestError(code, message, stackTrace: stackTrace);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'RequestError', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['code'] = code.toJson();
    result['message'] = message;
    var stackTrace = this.stackTrace;
    if (stackTrace != null) {
      result['stackTrace'] = stackTrace;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

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
  int get hashCode => Object.hash(
        code,
        message,
        stackTrace,
      );
}

/// RequestErrorCode
///
/// enum {
///   CONTENT_MODIFIED
///   DEBUG_PORT_COULD_NOT_BE_OPENED
///   FILE_NOT_ANALYZED
///   FLUTTER_GET_WIDGET_DESCRIPTION_CONTENT_MODIFIED
///   FLUTTER_GET_WIDGET_DESCRIPTION_NO_WIDGET
///   FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_EXPRESSION
///   FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_ID
///   FLUTTER_SET_WIDGET_PROPERTY_VALUE_IS_REQUIRED
///   FORMAT_INVALID_FILE
///   FORMAT_WITH_ERRORS
///   GET_ERRORS_INVALID_FILE
///   GET_FIXES_INVALID_FILE
///   GET_IMPORTED_ELEMENTS_INVALID_FILE
///   GET_NAVIGATION_INVALID_FILE
///   GET_REACHABLE_SOURCES_INVALID_FILE
///   GET_SIGNATURE_INVALID_FILE
///   GET_SIGNATURE_INVALID_OFFSET
///   GET_SIGNATURE_UNKNOWN_FUNCTION
///   IMPORT_ELEMENTS_INVALID_FILE
///   INVALID_ANALYSIS_ROOT
///   INVALID_EXECUTION_CONTEXT
///   INVALID_FILE_PATH_FORMAT
///   INVALID_OVERLAY_CHANGE
///   INVALID_PARAMETER
///   INVALID_REQUEST
///   ORGANIZE_DIRECTIVES_ERROR
///   REFACTORING_REQUEST_CANCELLED
///   SERVER_ALREADY_STARTED
///   SERVER_ERROR
///   SORT_MEMBERS_INVALID_FILE
///   SORT_MEMBERS_PARSE_ERRORS
///   UNKNOWN_REQUEST
///   UNSUPPORTED_FEATURE
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RequestErrorCode implements Enum {
  /// An "analysis.getErrors" or "analysis.getNavigation" request could not be
  /// satisfied because the content of the file changed before the requested
  /// results could be computed.
  static const RequestErrorCode CONTENT_MODIFIED =
      RequestErrorCode._('CONTENT_MODIFIED');

  /// The server was unable to open a port for the diagnostic server.
  static const RequestErrorCode DEBUG_PORT_COULD_NOT_BE_OPENED =
      RequestErrorCode._('DEBUG_PORT_COULD_NOT_BE_OPENED');

  /// A request specified a FilePath which does not match a file in an analysis
  /// root, or the requested operation is not available for the file.
  static const RequestErrorCode FILE_NOT_ANALYZED =
      RequestErrorCode._('FILE_NOT_ANALYZED');

  /// A file was change while widget descriptions were being computed.
  static const RequestErrorCode
      FLUTTER_GET_WIDGET_DESCRIPTION_CONTENT_MODIFIED =
      RequestErrorCode._('FLUTTER_GET_WIDGET_DESCRIPTION_CONTENT_MODIFIED');

  /// The given location does not have a supported widget.
  static const RequestErrorCode FLUTTER_GET_WIDGET_DESCRIPTION_NO_WIDGET =
      RequestErrorCode._('FLUTTER_GET_WIDGET_DESCRIPTION_NO_WIDGET');

  /// The given property expression is invalid, e.g. has a syntax error.
  static const RequestErrorCode
      FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_EXPRESSION = RequestErrorCode._(
          'FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_EXPRESSION');

  /// The given property identifier is not valid. It might have never been
  /// valid, or a change to code invalidated it, or its TTL was exceeded.
  static const RequestErrorCode FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_ID =
      RequestErrorCode._('FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_ID');

  /// The value of the property cannot be removed, for example because the
  /// corresponding constructor argument is required, and the server does not
  /// know what default value to use.
  static const RequestErrorCode FLUTTER_SET_WIDGET_PROPERTY_VALUE_IS_REQUIRED =
      RequestErrorCode._('FLUTTER_SET_WIDGET_PROPERTY_VALUE_IS_REQUIRED');

  /// An "edit.format" request specified a FilePath which does not match a Dart
  /// file in an analysis root.
  static const RequestErrorCode FORMAT_INVALID_FILE =
      RequestErrorCode._('FORMAT_INVALID_FILE');

  /// An "edit.format" request specified a file that contains syntax errors.
  static const RequestErrorCode FORMAT_WITH_ERRORS =
      RequestErrorCode._('FORMAT_WITH_ERRORS');

  /// An "analysis.getErrors" request specified a FilePath which does not match
  /// a file currently subject to analysis.
  static const RequestErrorCode GET_ERRORS_INVALID_FILE =
      RequestErrorCode._('GET_ERRORS_INVALID_FILE');

  /// An "edit.getFixes" request specified a FilePath which does not match a
  /// file currently subject to analysis.
  static const RequestErrorCode GET_FIXES_INVALID_FILE =
      RequestErrorCode._('GET_FIXES_INVALID_FILE');

  /// An "analysis.getImportedElements" request specified a FilePath that does
  /// not match a file currently subject to analysis.
  static const RequestErrorCode GET_IMPORTED_ELEMENTS_INVALID_FILE =
      RequestErrorCode._('GET_IMPORTED_ELEMENTS_INVALID_FILE');

  /// An "analysis.getNavigation" request specified a FilePath which does not
  /// match a file currently subject to analysis.
  static const RequestErrorCode GET_NAVIGATION_INVALID_FILE =
      RequestErrorCode._('GET_NAVIGATION_INVALID_FILE');

  /// An "analysis.getReachableSources" request specified a FilePath which does
  /// not match a file currently subject to analysis.
  static const RequestErrorCode GET_REACHABLE_SOURCES_INVALID_FILE =
      RequestErrorCode._('GET_REACHABLE_SOURCES_INVALID_FILE');

  /// An "analysis.getSignature" request specified a FilePath which does not
  /// match a file currently subject to analysis.
  static const RequestErrorCode GET_SIGNATURE_INVALID_FILE =
      RequestErrorCode._('GET_SIGNATURE_INVALID_FILE');

  /// An "analysis.getSignature" request specified an offset which is not a
  /// valid location within for the contents of the file specified FilePath.
  static const RequestErrorCode GET_SIGNATURE_INVALID_OFFSET =
      RequestErrorCode._('GET_SIGNATURE_INVALID_OFFSET');

  /// An "analysis.getSignature" request specified an offset that could not be
  /// matched to a function call.
  static const RequestErrorCode GET_SIGNATURE_UNKNOWN_FUNCTION =
      RequestErrorCode._('GET_SIGNATURE_UNKNOWN_FUNCTION');

  /// An "edit.importElements" request specified a FilePath that does not match
  /// a file currently subject to analysis.
  static const RequestErrorCode IMPORT_ELEMENTS_INVALID_FILE =
      RequestErrorCode._('IMPORT_ELEMENTS_INVALID_FILE');

  /// A path passed as an argument to a request (such as analysis.reanalyze) is
  /// required to be an analysis root, but isn't.
  static const RequestErrorCode INVALID_ANALYSIS_ROOT =
      RequestErrorCode._('INVALID_ANALYSIS_ROOT');

  /// The context root used to create an execution context does not exist.
  static const RequestErrorCode INVALID_EXECUTION_CONTEXT =
      RequestErrorCode._('INVALID_EXECUTION_CONTEXT');

  /// The format of the given file path is invalid, e.g. is not absolute and
  /// normalized.
  static const RequestErrorCode INVALID_FILE_PATH_FORMAT =
      RequestErrorCode._('INVALID_FILE_PATH_FORMAT');

  /// An "analysis.updateContent" request contained a ChangeContentOverlay
  /// object which can't be applied, due to an edit having an offset or length
  /// that is out of range.
  static const RequestErrorCode INVALID_OVERLAY_CHANGE =
      RequestErrorCode._('INVALID_OVERLAY_CHANGE');

  /// One of the method parameters was invalid.
  static const RequestErrorCode INVALID_PARAMETER =
      RequestErrorCode._('INVALID_PARAMETER');

  /// A malformed request was received.
  static const RequestErrorCode INVALID_REQUEST =
      RequestErrorCode._('INVALID_REQUEST');

  /// An "edit.organizeDirectives" request specified a Dart file that cannot be
  /// analyzed. The reason is described in the message.
  static const RequestErrorCode ORGANIZE_DIRECTIVES_ERROR =
      RequestErrorCode._('ORGANIZE_DIRECTIVES_ERROR');

  /// Another refactoring request was received during processing of this one.
  static const RequestErrorCode REFACTORING_REQUEST_CANCELLED =
      RequestErrorCode._('REFACTORING_REQUEST_CANCELLED');

  /// The analysis server has already been started (and hence won't accept new
  /// connections).
  ///
  /// This error is included for future expansion; at present the analysis
  /// server can only speak to one client at a time so this error will never
  /// occur.
  static const RequestErrorCode SERVER_ALREADY_STARTED =
      RequestErrorCode._('SERVER_ALREADY_STARTED');

  /// An internal error occurred in the analysis server. Also see the
  /// server.error notification.
  static const RequestErrorCode SERVER_ERROR =
      RequestErrorCode._('SERVER_ERROR');

  /// An "edit.sortMembers" request specified a FilePath which does not match a
  /// Dart file in an analysis root.
  static const RequestErrorCode SORT_MEMBERS_INVALID_FILE =
      RequestErrorCode._('SORT_MEMBERS_INVALID_FILE');

  /// An "edit.sortMembers" request specified a Dart file that has scan or
  /// parse errors.
  static const RequestErrorCode SORT_MEMBERS_PARSE_ERRORS =
      RequestErrorCode._('SORT_MEMBERS_PARSE_ERRORS');

  /// A request was received which the analysis server does not recognize, or
  /// cannot handle in its current configuration.
  static const RequestErrorCode UNKNOWN_REQUEST =
      RequestErrorCode._('UNKNOWN_REQUEST');

  /// The analysis server was requested to perform an action which is not
  /// supported.
  ///
  /// This is a legacy error; it will be removed before the API reaches version
  /// 1.0.
  static const RequestErrorCode UNSUPPORTED_FEATURE =
      RequestErrorCode._('UNSUPPORTED_FEATURE');

  /// A list containing all of the enum values that are defined.
  static const List<RequestErrorCode> VALUES = <RequestErrorCode>[
    CONTENT_MODIFIED,
    DEBUG_PORT_COULD_NOT_BE_OPENED,
    FILE_NOT_ANALYZED,
    FLUTTER_GET_WIDGET_DESCRIPTION_CONTENT_MODIFIED,
    FLUTTER_GET_WIDGET_DESCRIPTION_NO_WIDGET,
    FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_EXPRESSION,
    FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_ID,
    FLUTTER_SET_WIDGET_PROPERTY_VALUE_IS_REQUIRED,
    FORMAT_INVALID_FILE,
    FORMAT_WITH_ERRORS,
    GET_ERRORS_INVALID_FILE,
    GET_FIXES_INVALID_FILE,
    GET_IMPORTED_ELEMENTS_INVALID_FILE,
    GET_NAVIGATION_INVALID_FILE,
    GET_REACHABLE_SOURCES_INVALID_FILE,
    GET_SIGNATURE_INVALID_FILE,
    GET_SIGNATURE_INVALID_OFFSET,
    GET_SIGNATURE_UNKNOWN_FUNCTION,
    IMPORT_ELEMENTS_INVALID_FILE,
    INVALID_ANALYSIS_ROOT,
    INVALID_EXECUTION_CONTEXT,
    INVALID_FILE_PATH_FORMAT,
    INVALID_OVERLAY_CHANGE,
    INVALID_PARAMETER,
    INVALID_REQUEST,
    ORGANIZE_DIRECTIVES_ERROR,
    REFACTORING_REQUEST_CANCELLED,
    SERVER_ALREADY_STARTED,
    SERVER_ERROR,
    SORT_MEMBERS_INVALID_FILE,
    SORT_MEMBERS_PARSE_ERRORS,
    UNKNOWN_REQUEST,
    UNSUPPORTED_FEATURE
  ];

  @override
  final String name;

  const RequestErrorCode._(this.name);

  factory RequestErrorCode(String name) {
    switch (name) {
      case 'CONTENT_MODIFIED':
        return CONTENT_MODIFIED;
      case 'DEBUG_PORT_COULD_NOT_BE_OPENED':
        return DEBUG_PORT_COULD_NOT_BE_OPENED;
      case 'FILE_NOT_ANALYZED':
        return FILE_NOT_ANALYZED;
      case 'FLUTTER_GET_WIDGET_DESCRIPTION_CONTENT_MODIFIED':
        return FLUTTER_GET_WIDGET_DESCRIPTION_CONTENT_MODIFIED;
      case 'FLUTTER_GET_WIDGET_DESCRIPTION_NO_WIDGET':
        return FLUTTER_GET_WIDGET_DESCRIPTION_NO_WIDGET;
      case 'FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_EXPRESSION':
        return FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_EXPRESSION;
      case 'FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_ID':
        return FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_ID;
      case 'FLUTTER_SET_WIDGET_PROPERTY_VALUE_IS_REQUIRED':
        return FLUTTER_SET_WIDGET_PROPERTY_VALUE_IS_REQUIRED;
      case 'FORMAT_INVALID_FILE':
        return FORMAT_INVALID_FILE;
      case 'FORMAT_WITH_ERRORS':
        return FORMAT_WITH_ERRORS;
      case 'GET_ERRORS_INVALID_FILE':
        return GET_ERRORS_INVALID_FILE;
      case 'GET_FIXES_INVALID_FILE':
        return GET_FIXES_INVALID_FILE;
      case 'GET_IMPORTED_ELEMENTS_INVALID_FILE':
        return GET_IMPORTED_ELEMENTS_INVALID_FILE;
      case 'GET_NAVIGATION_INVALID_FILE':
        return GET_NAVIGATION_INVALID_FILE;
      case 'GET_REACHABLE_SOURCES_INVALID_FILE':
        return GET_REACHABLE_SOURCES_INVALID_FILE;
      case 'GET_SIGNATURE_INVALID_FILE':
        return GET_SIGNATURE_INVALID_FILE;
      case 'GET_SIGNATURE_INVALID_OFFSET':
        return GET_SIGNATURE_INVALID_OFFSET;
      case 'GET_SIGNATURE_UNKNOWN_FUNCTION':
        return GET_SIGNATURE_UNKNOWN_FUNCTION;
      case 'IMPORT_ELEMENTS_INVALID_FILE':
        return IMPORT_ELEMENTS_INVALID_FILE;
      case 'INVALID_ANALYSIS_ROOT':
        return INVALID_ANALYSIS_ROOT;
      case 'INVALID_EXECUTION_CONTEXT':
        return INVALID_EXECUTION_CONTEXT;
      case 'INVALID_FILE_PATH_FORMAT':
        return INVALID_FILE_PATH_FORMAT;
      case 'INVALID_OVERLAY_CHANGE':
        return INVALID_OVERLAY_CHANGE;
      case 'INVALID_PARAMETER':
        return INVALID_PARAMETER;
      case 'INVALID_REQUEST':
        return INVALID_REQUEST;
      case 'ORGANIZE_DIRECTIVES_ERROR':
        return ORGANIZE_DIRECTIVES_ERROR;
      case 'REFACTORING_REQUEST_CANCELLED':
        return REFACTORING_REQUEST_CANCELLED;
      case 'SERVER_ALREADY_STARTED':
        return SERVER_ALREADY_STARTED;
      case 'SERVER_ERROR':
        return SERVER_ERROR;
      case 'SORT_MEMBERS_INVALID_FILE':
        return SORT_MEMBERS_INVALID_FILE;
      case 'SORT_MEMBERS_PARSE_ERRORS':
        return SORT_MEMBERS_PARSE_ERRORS;
      case 'UNKNOWN_REQUEST':
        return UNKNOWN_REQUEST;
      case 'UNSUPPORTED_FEATURE':
        return UNSUPPORTED_FEATURE;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory RequestErrorCode.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    if (json is String) {
      try {
        return RequestErrorCode(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'RequestErrorCode', json);
  }

  @override
  String toString() => 'RequestErrorCode.$name';

  String toJson() => name;
}

/// RuntimeCompletionExpression
///
/// {
///   "offset": int
///   "length": int
///   "type": optional RuntimeCompletionExpressionType
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RuntimeCompletionExpression implements HasToJson {
  /// The offset of the expression in the code for completion.
  int offset;

  /// The length of the expression in the code for completion.
  int length;

  /// When the expression is sent from the server to the client, the type is
  /// omitted. The client should fill the type when it sends the request to the
  /// server again.
  RuntimeCompletionExpressionType? type;

  RuntimeCompletionExpression(this.offset, this.length, {this.type});

  factory RuntimeCompletionExpression.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
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
      RuntimeCompletionExpressionType? type;
      if (json.containsKey('type')) {
        type = RuntimeCompletionExpressionType.fromJson(
            jsonDecoder, '$jsonPath.type', json['type']);
      }
      return RuntimeCompletionExpression(offset, length, type: type);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'RuntimeCompletionExpression', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['offset'] = offset;
    result['length'] = length;
    var type = this.type;
    if (type != null) {
      result['type'] = type.toJson();
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is RuntimeCompletionExpression) {
      return offset == other.offset &&
          length == other.length &&
          type == other.type;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        offset,
        length,
        type,
      );
}

/// RuntimeCompletionExpressionType
///
/// {
///   "libraryPath": optional FilePath
///   "kind": RuntimeCompletionExpressionTypeKind
///   "name": optional String
///   "typeArguments": optional List<RuntimeCompletionExpressionType>
///   "returnType": optional RuntimeCompletionExpressionType
///   "parameterTypes": optional List<RuntimeCompletionExpressionType>
///   "parameterNames": optional List<String>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RuntimeCompletionExpressionType implements HasToJson {
  /// The path of the library that has this type. Omitted if the type is not
  /// declared in any library, e.g. "dynamic", or "void".
  String? libraryPath;

  /// The kind of the type.
  RuntimeCompletionExpressionTypeKind kind;

  /// The name of the type. Omitted if the type does not have a name, e.g. an
  /// inline function type.
  String? name;

  /// The type arguments of the type. Omitted if the type does not have type
  /// parameters.
  List<RuntimeCompletionExpressionType>? typeArguments;

  /// If the type is a function type, the return type of the function. Omitted
  /// if the type is not a function type.
  RuntimeCompletionExpressionType? returnType;

  /// If the type is a function type, the types of the function parameters of
  /// all kinds - required, optional positional, and optional named. Omitted if
  /// the type is not a function type.
  List<RuntimeCompletionExpressionType>? parameterTypes;

  /// If the type is a function type, the names of the function parameters of
  /// all kinds - required, optional positional, and optional named. The names
  /// of positional parameters are empty strings. Omitted if the type is not a
  /// function type.
  List<String>? parameterNames;

  RuntimeCompletionExpressionType(this.kind,
      {this.libraryPath,
      this.name,
      this.typeArguments,
      this.returnType,
      this.parameterTypes,
      this.parameterNames});

  factory RuntimeCompletionExpressionType.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String? libraryPath;
      if (json.containsKey('libraryPath')) {
        libraryPath = jsonDecoder.decodeString(
            '$jsonPath.libraryPath', json['libraryPath']);
      }
      RuntimeCompletionExpressionTypeKind kind;
      if (json.containsKey('kind')) {
        kind = RuntimeCompletionExpressionTypeKind.fromJson(
            jsonDecoder, '$jsonPath.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      String? name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString('$jsonPath.name', json['name']);
      }
      List<RuntimeCompletionExpressionType>? typeArguments;
      if (json.containsKey('typeArguments')) {
        typeArguments = jsonDecoder.decodeList(
            '$jsonPath.typeArguments',
            json['typeArguments'],
            (String jsonPath, Object? json) =>
                RuntimeCompletionExpressionType.fromJson(
                    jsonDecoder, jsonPath, json));
      }
      RuntimeCompletionExpressionType? returnType;
      if (json.containsKey('returnType')) {
        returnType = RuntimeCompletionExpressionType.fromJson(
            jsonDecoder, '$jsonPath.returnType', json['returnType']);
      }
      List<RuntimeCompletionExpressionType>? parameterTypes;
      if (json.containsKey('parameterTypes')) {
        parameterTypes = jsonDecoder.decodeList(
            '$jsonPath.parameterTypes',
            json['parameterTypes'],
            (String jsonPath, Object? json) =>
                RuntimeCompletionExpressionType.fromJson(
                    jsonDecoder, jsonPath, json));
      }
      List<String>? parameterNames;
      if (json.containsKey('parameterNames')) {
        parameterNames = jsonDecoder.decodeList('$jsonPath.parameterNames',
            json['parameterNames'], jsonDecoder.decodeString);
      }
      return RuntimeCompletionExpressionType(kind,
          libraryPath: libraryPath,
          name: name,
          typeArguments: typeArguments,
          returnType: returnType,
          parameterTypes: parameterTypes,
          parameterNames: parameterNames);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'RuntimeCompletionExpressionType', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    var libraryPath = this.libraryPath;
    if (libraryPath != null) {
      result['libraryPath'] = libraryPath;
    }
    result['kind'] = kind.toJson();
    var name = this.name;
    if (name != null) {
      result['name'] = name;
    }
    var typeArguments = this.typeArguments;
    if (typeArguments != null) {
      result['typeArguments'] = typeArguments
          .map((RuntimeCompletionExpressionType value) => value.toJson())
          .toList();
    }
    var returnType = this.returnType;
    if (returnType != null) {
      result['returnType'] = returnType.toJson();
    }
    var parameterTypes = this.parameterTypes;
    if (parameterTypes != null) {
      result['parameterTypes'] = parameterTypes
          .map((RuntimeCompletionExpressionType value) => value.toJson())
          .toList();
    }
    var parameterNames = this.parameterNames;
    if (parameterNames != null) {
      result['parameterNames'] = parameterNames;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is RuntimeCompletionExpressionType) {
      return libraryPath == other.libraryPath &&
          kind == other.kind &&
          name == other.name &&
          listEqual(
              typeArguments,
              other.typeArguments,
              (RuntimeCompletionExpressionType a,
                      RuntimeCompletionExpressionType b) =>
                  a == b) &&
          returnType == other.returnType &&
          listEqual(
              parameterTypes,
              other.parameterTypes,
              (RuntimeCompletionExpressionType a,
                      RuntimeCompletionExpressionType b) =>
                  a == b) &&
          listEqual(parameterNames, other.parameterNames,
              (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        libraryPath,
        kind,
        name,
        Object.hashAll(typeArguments ?? []),
        returnType,
        Object.hashAll(parameterTypes ?? []),
        Object.hashAll(parameterNames ?? []),
      );
}

/// RuntimeCompletionExpressionTypeKind
///
/// enum {
///   DYNAMIC
///   FUNCTION
///   INTERFACE
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RuntimeCompletionExpressionTypeKind implements Enum {
  static const RuntimeCompletionExpressionTypeKind DYNAMIC =
      RuntimeCompletionExpressionTypeKind._('DYNAMIC');

  static const RuntimeCompletionExpressionTypeKind FUNCTION =
      RuntimeCompletionExpressionTypeKind._('FUNCTION');

  static const RuntimeCompletionExpressionTypeKind INTERFACE =
      RuntimeCompletionExpressionTypeKind._('INTERFACE');

  /// A list containing all of the enum values that are defined.
  static const List<RuntimeCompletionExpressionTypeKind> VALUES =
      <RuntimeCompletionExpressionTypeKind>[DYNAMIC, FUNCTION, INTERFACE];

  @override
  final String name;

  const RuntimeCompletionExpressionTypeKind._(this.name);

  factory RuntimeCompletionExpressionTypeKind(String name) {
    switch (name) {
      case 'DYNAMIC':
        return DYNAMIC;
      case 'FUNCTION':
        return FUNCTION;
      case 'INTERFACE':
        return INTERFACE;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory RuntimeCompletionExpressionTypeKind.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    if (json is String) {
      try {
        return RuntimeCompletionExpressionTypeKind(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(
        jsonPath, 'RuntimeCompletionExpressionTypeKind', json);
  }

  @override
  String toString() => 'RuntimeCompletionExpressionTypeKind.$name';

  String toJson() => name;
}

/// RuntimeCompletionVariable
///
/// {
///   "name": String
///   "type": RuntimeCompletionExpressionType
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RuntimeCompletionVariable implements HasToJson {
  /// The name of the variable. The name "this" has a special meaning and is
  /// used as an implicit target for runtime completion, and in explicit "this"
  /// references.
  String name;

  /// The type of the variable.
  RuntimeCompletionExpressionType type;

  RuntimeCompletionVariable(this.name, this.type);

  factory RuntimeCompletionVariable.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString('$jsonPath.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      RuntimeCompletionExpressionType type;
      if (json.containsKey('type')) {
        type = RuntimeCompletionExpressionType.fromJson(
            jsonDecoder, '$jsonPath.type', json['type']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'type');
      }
      return RuntimeCompletionVariable(name, type);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'RuntimeCompletionVariable', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['name'] = name;
    result['type'] = type.toJson();
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is RuntimeCompletionVariable) {
      return name == other.name && type == other.type;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        name,
        type,
      );
}

/// search.findElementReferences params
///
/// {
///   "file": FilePath
///   "offset": int
///   "includePotential": bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchFindElementReferencesParams implements RequestParams {
  /// The file containing the declaration of or reference to the element used
  /// to define the search.
  String file;

  /// The offset within the file of the declaration of or reference to the
  /// element.
  int offset;

  /// True if potential matches are to be included in the results.
  bool includePotential;

  SearchFindElementReferencesParams(
      this.file, this.offset, this.includePotential);

  factory SearchFindElementReferencesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt('$jsonPath.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      bool includePotential;
      if (json.containsKey('includePotential')) {
        includePotential = jsonDecoder.decodeBool(
            '$jsonPath.includePotential', json['includePotential']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'includePotential');
      }
      return SearchFindElementReferencesParams(file, offset, includePotential);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'search.findElementReferences params', json);
    }
  }

  factory SearchFindElementReferencesParams.fromRequest(Request request) {
    return SearchFindElementReferencesParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['offset'] = offset;
    result['includePotential'] = includePotential;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'search.findElementReferences', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchFindElementReferencesParams) {
      return file == other.file &&
          offset == other.offset &&
          includePotential == other.includePotential;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        offset,
        includePotential,
      );
}

/// search.findElementReferences result
///
/// {
///   "id": optional SearchId
///   "element": optional Element
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchFindElementReferencesResult implements ResponseResult {
  /// The identifier used to associate results with this search request.
  ///
  /// If no element was found at the given location, this field will be absent,
  /// and no results will be reported via the search.results notification.
  String? id;

  /// The element referenced or defined at the given offset and whose
  /// references will be returned in the search results.
  ///
  /// If no element was found at the given location, this field will be absent.
  Element? element;

  SearchFindElementReferencesResult({this.id, this.element});

  factory SearchFindElementReferencesResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String? id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeString('$jsonPath.id', json['id']);
      }
      Element? element;
      if (json.containsKey('element')) {
        element =
            Element.fromJson(jsonDecoder, '$jsonPath.element', json['element']);
      }
      return SearchFindElementReferencesResult(id: id, element: element);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'search.findElementReferences result', json);
    }
  }

  factory SearchFindElementReferencesResult.fromResponse(Response response) {
    return SearchFindElementReferencesResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    var id = this.id;
    if (id != null) {
      result['id'] = id;
    }
    var element = this.element;
    if (element != null) {
      result['element'] = element.toJson();
    }
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchFindElementReferencesResult) {
      return id == other.id && element == other.element;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        id,
        element,
      );
}

/// search.findMemberDeclarations params
///
/// {
///   "name": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchFindMemberDeclarationsParams implements RequestParams {
  /// The name of the declarations to be found.
  String name;

  SearchFindMemberDeclarationsParams(this.name);

  factory SearchFindMemberDeclarationsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString('$jsonPath.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      return SearchFindMemberDeclarationsParams(name);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'search.findMemberDeclarations params', json);
    }
  }

  factory SearchFindMemberDeclarationsParams.fromRequest(Request request) {
    return SearchFindMemberDeclarationsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['name'] = name;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'search.findMemberDeclarations', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchFindMemberDeclarationsParams) {
      return name == other.name;
    }
    return false;
  }

  @override
  int get hashCode => name.hashCode;
}

/// search.findMemberDeclarations result
///
/// {
///   "id": SearchId
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchFindMemberDeclarationsResult implements ResponseResult {
  /// The identifier used to associate results with this search request.
  String id;

  SearchFindMemberDeclarationsResult(this.id);

  factory SearchFindMemberDeclarationsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeString('$jsonPath.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      return SearchFindMemberDeclarationsResult(id);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'search.findMemberDeclarations result', json);
    }
  }

  factory SearchFindMemberDeclarationsResult.fromResponse(Response response) {
    return SearchFindMemberDeclarationsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['id'] = id;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchFindMemberDeclarationsResult) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode => id.hashCode;
}

/// search.findMemberReferences params
///
/// {
///   "name": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchFindMemberReferencesParams implements RequestParams {
  /// The name of the references to be found.
  String name;

  SearchFindMemberReferencesParams(this.name);

  factory SearchFindMemberReferencesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString('$jsonPath.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      return SearchFindMemberReferencesParams(name);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'search.findMemberReferences params', json);
    }
  }

  factory SearchFindMemberReferencesParams.fromRequest(Request request) {
    return SearchFindMemberReferencesParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['name'] = name;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'search.findMemberReferences', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchFindMemberReferencesParams) {
      return name == other.name;
    }
    return false;
  }

  @override
  int get hashCode => name.hashCode;
}

/// search.findMemberReferences result
///
/// {
///   "id": SearchId
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchFindMemberReferencesResult implements ResponseResult {
  /// The identifier used to associate results with this search request.
  String id;

  SearchFindMemberReferencesResult(this.id);

  factory SearchFindMemberReferencesResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeString('$jsonPath.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      return SearchFindMemberReferencesResult(id);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'search.findMemberReferences result', json);
    }
  }

  factory SearchFindMemberReferencesResult.fromResponse(Response response) {
    return SearchFindMemberReferencesResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['id'] = id;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchFindMemberReferencesResult) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode => id.hashCode;
}

/// search.findTopLevelDeclarations params
///
/// {
///   "pattern": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchFindTopLevelDeclarationsParams implements RequestParams {
  /// The regular expression used to match the names of the declarations to be
  /// found.
  String pattern;

  SearchFindTopLevelDeclarationsParams(this.pattern);

  factory SearchFindTopLevelDeclarationsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String pattern;
      if (json.containsKey('pattern')) {
        pattern =
            jsonDecoder.decodeString('$jsonPath.pattern', json['pattern']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'pattern');
      }
      return SearchFindTopLevelDeclarationsParams(pattern);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'search.findTopLevelDeclarations params', json);
    }
  }

  factory SearchFindTopLevelDeclarationsParams.fromRequest(Request request) {
    return SearchFindTopLevelDeclarationsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['pattern'] = pattern;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'search.findTopLevelDeclarations', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchFindTopLevelDeclarationsParams) {
      return pattern == other.pattern;
    }
    return false;
  }

  @override
  int get hashCode => pattern.hashCode;
}

/// search.findTopLevelDeclarations result
///
/// {
///   "id": SearchId
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchFindTopLevelDeclarationsResult implements ResponseResult {
  /// The identifier used to associate results with this search request.
  String id;

  SearchFindTopLevelDeclarationsResult(this.id);

  factory SearchFindTopLevelDeclarationsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeString('$jsonPath.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      return SearchFindTopLevelDeclarationsResult(id);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'search.findTopLevelDeclarations result', json);
    }
  }

  factory SearchFindTopLevelDeclarationsResult.fromResponse(Response response) {
    return SearchFindTopLevelDeclarationsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['id'] = id;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchFindTopLevelDeclarationsResult) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode => id.hashCode;
}

/// search.getElementDeclarations params
///
/// {
///   "file": optional FilePath
///   "pattern": optional String
///   "maxResults": optional int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchGetElementDeclarationsParams implements RequestParams {
  /// If this field is provided, return only declarations in this file. If this
  /// field is missing, return declarations in all files.
  String? file;

  /// The regular expression used to match the names of declarations. If this
  /// field is missing, return all declarations.
  String? pattern;

  /// The maximum number of declarations to return. If this field is missing,
  /// return all matching declarations.
  int? maxResults;

  SearchGetElementDeclarationsParams(
      {this.file, this.pattern, this.maxResults});

  factory SearchGetElementDeclarationsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String? file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      }
      String? pattern;
      if (json.containsKey('pattern')) {
        pattern =
            jsonDecoder.decodeString('$jsonPath.pattern', json['pattern']);
      }
      int? maxResults;
      if (json.containsKey('maxResults')) {
        maxResults =
            jsonDecoder.decodeInt('$jsonPath.maxResults', json['maxResults']);
      }
      return SearchGetElementDeclarationsParams(
          file: file, pattern: pattern, maxResults: maxResults);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'search.getElementDeclarations params', json);
    }
  }

  factory SearchGetElementDeclarationsParams.fromRequest(Request request) {
    return SearchGetElementDeclarationsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    var file = this.file;
    if (file != null) {
      result['file'] = file;
    }
    var pattern = this.pattern;
    if (pattern != null) {
      result['pattern'] = pattern;
    }
    var maxResults = this.maxResults;
    if (maxResults != null) {
      result['maxResults'] = maxResults;
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'search.getElementDeclarations', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchGetElementDeclarationsParams) {
      return file == other.file &&
          pattern == other.pattern &&
          maxResults == other.maxResults;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        pattern,
        maxResults,
      );
}

/// search.getElementDeclarations result
///
/// {
///   "declarations": List<ElementDeclaration>
///   "files": List<FilePath>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchGetElementDeclarationsResult implements ResponseResult {
  /// The list of declarations.
  List<ElementDeclaration> declarations;

  /// The list of the paths of files with declarations.
  List<String> files;

  SearchGetElementDeclarationsResult(this.declarations, this.files);

  factory SearchGetElementDeclarationsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<ElementDeclaration> declarations;
      if (json.containsKey('declarations')) {
        declarations = jsonDecoder.decodeList(
            '$jsonPath.declarations',
            json['declarations'],
            (String jsonPath, Object? json) =>
                ElementDeclaration.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'declarations');
      }
      List<String> files;
      if (json.containsKey('files')) {
        files = jsonDecoder.decodeList(
            '$jsonPath.files', json['files'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'files');
      }
      return SearchGetElementDeclarationsResult(declarations, files);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'search.getElementDeclarations result', json);
    }
  }

  factory SearchGetElementDeclarationsResult.fromResponse(Response response) {
    return SearchGetElementDeclarationsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['declarations'] =
        declarations.map((ElementDeclaration value) => value.toJson()).toList();
    result['files'] = files;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchGetElementDeclarationsResult) {
      return listEqual(declarations, other.declarations,
              (ElementDeclaration a, ElementDeclaration b) => a == b) &&
          listEqual(files, other.files, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(declarations),
        Object.hashAll(files),
      );
}

/// search.getTypeHierarchy params
///
/// {
///   "file": FilePath
///   "offset": int
///   "superOnly": optional bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchGetTypeHierarchyParams implements RequestParams {
  /// The file containing the declaration or reference to the type for which a
  /// hierarchy is being requested.
  String file;

  /// The offset of the name of the type within the file.
  int offset;

  /// True if the client is only requesting superclasses and interfaces
  /// hierarchy.
  bool? superOnly;

  SearchGetTypeHierarchyParams(this.file, this.offset, {this.superOnly});

  factory SearchGetTypeHierarchyParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString('$jsonPath.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt('$jsonPath.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      bool? superOnly;
      if (json.containsKey('superOnly')) {
        superOnly =
            jsonDecoder.decodeBool('$jsonPath.superOnly', json['superOnly']);
      }
      return SearchGetTypeHierarchyParams(file, offset, superOnly: superOnly);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'search.getTypeHierarchy params', json);
    }
  }

  factory SearchGetTypeHierarchyParams.fromRequest(Request request) {
    return SearchGetTypeHierarchyParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['offset'] = offset;
    var superOnly = this.superOnly;
    if (superOnly != null) {
      result['superOnly'] = superOnly;
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'search.getTypeHierarchy', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchGetTypeHierarchyParams) {
      return file == other.file &&
          offset == other.offset &&
          superOnly == other.superOnly;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        file,
        offset,
        superOnly,
      );
}

/// search.getTypeHierarchy result
///
/// {
///   "hierarchyItems": optional List<TypeHierarchyItem>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchGetTypeHierarchyResult implements ResponseResult {
  /// A list of the types in the requested hierarchy. The first element of the
  /// list is the item representing the type for which the hierarchy was
  /// requested. The index of other elements of the list is unspecified, but
  /// correspond to the integers used to reference supertype and subtype items
  /// within the items.
  ///
  /// This field will be absent if the code at the given file and offset does
  /// not represent a type, or if the file has not been sufficiently analyzed
  /// to allow a type hierarchy to be produced.
  List<TypeHierarchyItem>? hierarchyItems;

  SearchGetTypeHierarchyResult({this.hierarchyItems});

  factory SearchGetTypeHierarchyResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<TypeHierarchyItem>? hierarchyItems;
      if (json.containsKey('hierarchyItems')) {
        hierarchyItems = jsonDecoder.decodeList(
            '$jsonPath.hierarchyItems',
            json['hierarchyItems'],
            (String jsonPath, Object? json) =>
                TypeHierarchyItem.fromJson(jsonDecoder, jsonPath, json));
      }
      return SearchGetTypeHierarchyResult(hierarchyItems: hierarchyItems);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'search.getTypeHierarchy result', json);
    }
  }

  factory SearchGetTypeHierarchyResult.fromResponse(Response response) {
    return SearchGetTypeHierarchyResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    var hierarchyItems = this.hierarchyItems;
    if (hierarchyItems != null) {
      result['hierarchyItems'] = hierarchyItems
          .map((TypeHierarchyItem value) => value.toJson())
          .toList();
    }
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchGetTypeHierarchyResult) {
      return listEqual(hierarchyItems, other.hierarchyItems,
          (TypeHierarchyItem a, TypeHierarchyItem b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(hierarchyItems ?? []);
}

/// SearchResult
///
/// {
///   "location": Location
///   "kind": SearchResultKind
///   "isPotential": bool
///   "path": List<Element>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchResult implements HasToJson {
  /// The location of the code that matched the search criteria.
  Location location;

  /// The kind of element that was found or the kind of reference that was
  /// found.
  SearchResultKind kind;

  /// True if the result is a potential match but cannot be confirmed to be a
  /// match. For example, if all references to a method m defined in some class
  /// were requested, and a reference to a method m from an unknown class were
  /// found, it would be marked as being a potential match.
  bool isPotential;

  /// The elements that contain the result, starting with the most immediately
  /// enclosing ancestor and ending with the library.
  List<Element> path;

  SearchResult(this.location, this.kind, this.isPotential, this.path);

  factory SearchResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      Location location;
      if (json.containsKey('location')) {
        location = Location.fromJson(
            jsonDecoder, '$jsonPath.location', json['location']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'location');
      }
      SearchResultKind kind;
      if (json.containsKey('kind')) {
        kind = SearchResultKind.fromJson(
            jsonDecoder, '$jsonPath.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      bool isPotential;
      if (json.containsKey('isPotential')) {
        isPotential = jsonDecoder.decodeBool(
            '$jsonPath.isPotential', json['isPotential']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'isPotential');
      }
      List<Element> path;
      if (json.containsKey('path')) {
        path = jsonDecoder.decodeList(
            '$jsonPath.path',
            json['path'],
            (String jsonPath, Object? json) =>
                Element.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'path');
      }
      return SearchResult(location, kind, isPotential, path);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'SearchResult', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['location'] = location.toJson();
    result['kind'] = kind.toJson();
    result['isPotential'] = isPotential;
    result['path'] = path.map((Element value) => value.toJson()).toList();
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchResult) {
      return location == other.location &&
          kind == other.kind &&
          isPotential == other.isPotential &&
          listEqual(path, other.path, (Element a, Element b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        location,
        kind,
        isPotential,
        Object.hashAll(path),
      );
}

/// SearchResultKind
///
/// enum {
///   DECLARATION
///   INVOCATION
///   READ
///   READ_WRITE
///   REFERENCE
///   UNKNOWN
///   WRITE
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchResultKind implements Enum {
  /// The declaration of an element.
  static const SearchResultKind DECLARATION = SearchResultKind._('DECLARATION');

  /// The invocation of a function or method.
  static const SearchResultKind INVOCATION = SearchResultKind._('INVOCATION');

  /// A reference to a field, parameter or variable where it is being read.
  static const SearchResultKind READ = SearchResultKind._('READ');

  /// A reference to a field, parameter or variable where it is being read and
  /// written.
  static const SearchResultKind READ_WRITE = SearchResultKind._('READ_WRITE');

  /// A reference to an element.
  static const SearchResultKind REFERENCE = SearchResultKind._('REFERENCE');

  /// Some other kind of search result.
  static const SearchResultKind UNKNOWN = SearchResultKind._('UNKNOWN');

  /// A reference to a field, parameter or variable where it is being written.
  static const SearchResultKind WRITE = SearchResultKind._('WRITE');

  /// A list containing all of the enum values that are defined.
  static const List<SearchResultKind> VALUES = <SearchResultKind>[
    DECLARATION,
    INVOCATION,
    READ,
    READ_WRITE,
    REFERENCE,
    UNKNOWN,
    WRITE
  ];

  @override
  final String name;

  const SearchResultKind._(this.name);

  factory SearchResultKind(String name) {
    switch (name) {
      case 'DECLARATION':
        return DECLARATION;
      case 'INVOCATION':
        return INVOCATION;
      case 'READ':
        return READ;
      case 'READ_WRITE':
        return READ_WRITE;
      case 'REFERENCE':
        return REFERENCE;
      case 'UNKNOWN':
        return UNKNOWN;
      case 'WRITE':
        return WRITE;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory SearchResultKind.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    if (json is String) {
      try {
        return SearchResultKind(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'SearchResultKind', json);
  }

  @override
  String toString() => 'SearchResultKind.$name';

  String toJson() => name;
}

/// search.results params
///
/// {
///   "id": SearchId
///   "results": List<SearchResult>
///   "isLast": bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchResultsParams implements HasToJson {
  /// The id associated with the search.
  String id;

  /// The search results being reported.
  List<SearchResult> results;

  /// True if this is that last set of results that will be returned for the
  /// indicated search.
  bool isLast;

  SearchResultsParams(this.id, this.results, this.isLast);

  factory SearchResultsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeString('$jsonPath.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      List<SearchResult> results;
      if (json.containsKey('results')) {
        results = jsonDecoder.decodeList(
            '$jsonPath.results',
            json['results'],
            (String jsonPath, Object? json) =>
                SearchResult.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'results');
      }
      bool isLast;
      if (json.containsKey('isLast')) {
        isLast = jsonDecoder.decodeBool('$jsonPath.isLast', json['isLast']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'isLast');
      }
      return SearchResultsParams(id, results, isLast);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'search.results params', json);
    }
  }

  factory SearchResultsParams.fromNotification(Notification notification) {
    return SearchResultsParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['id'] = id;
    result['results'] =
        results.map((SearchResult value) => value.toJson()).toList();
    result['isLast'] = isLast;
    return result;
  }

  Notification toNotification() {
    return Notification('search.results', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchResultsParams) {
      return id == other.id &&
          listEqual(results, other.results,
              (SearchResult a, SearchResult b) => a == b) &&
          isLast == other.isLast;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        id,
        Object.hashAll(results),
        isLast,
      );
}

/// server.cancelRequest params
///
/// {
///   "id": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ServerCancelRequestParams implements RequestParams {
  /// The id of the request that should be cancelled.
  String id;

  ServerCancelRequestParams(this.id);

  factory ServerCancelRequestParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeString('$jsonPath.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      return ServerCancelRequestParams(id);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'server.cancelRequest params', json);
    }
  }

  factory ServerCancelRequestParams.fromRequest(Request request) {
    return ServerCancelRequestParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['id'] = id;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'server.cancelRequest', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ServerCancelRequestParams) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode => id.hashCode;
}

/// server.cancelRequest result
///
/// Clients may not extend, implement or mix-in this class.
class ServerCancelRequestResult implements ResponseResult {
  @override
  Map<String, Object> toJson() => {};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) => other is ServerCancelRequestResult;

  @override
  int get hashCode => 183255719;
}

/// server.connected params
///
/// {
///   "version": String
///   "pid": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ServerConnectedParams implements HasToJson {
  /// The version number of the analysis server.
  String version;

  /// The process id of the analysis server process.
  int pid;

  ServerConnectedParams(this.version, this.pid);

  factory ServerConnectedParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String version;
      if (json.containsKey('version')) {
        version =
            jsonDecoder.decodeString('$jsonPath.version', json['version']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'version');
      }
      int pid;
      if (json.containsKey('pid')) {
        pid = jsonDecoder.decodeInt('$jsonPath.pid', json['pid']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'pid');
      }
      return ServerConnectedParams(version, pid);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'server.connected params', json);
    }
  }

  factory ServerConnectedParams.fromNotification(Notification notification) {
    return ServerConnectedParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['version'] = version;
    result['pid'] = pid;
    return result;
  }

  Notification toNotification() {
    return Notification('server.connected', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ServerConnectedParams) {
      return version == other.version && pid == other.pid;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        version,
        pid,
      );
}

/// server.error params
///
/// {
///   "isFatal": bool
///   "message": String
///   "stackTrace": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ServerErrorParams implements HasToJson {
  /// True if the error is a fatal error, meaning that the server will shutdown
  /// automatically after sending this notification.
  bool isFatal;

  /// The error message indicating what kind of error was encountered.
  String message;

  /// The stack trace associated with the generation of the error, used for
  /// debugging the server.
  String stackTrace;

  ServerErrorParams(this.isFatal, this.message, this.stackTrace);

  factory ServerErrorParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
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
        message =
            jsonDecoder.decodeString('$jsonPath.message', json['message']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'message');
      }
      String stackTrace;
      if (json.containsKey('stackTrace')) {
        stackTrace = jsonDecoder.decodeString(
            '$jsonPath.stackTrace', json['stackTrace']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'stackTrace');
      }
      return ServerErrorParams(isFatal, message, stackTrace);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'server.error params', json);
    }
  }

  factory ServerErrorParams.fromNotification(Notification notification) {
    return ServerErrorParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['isFatal'] = isFatal;
    result['message'] = message;
    result['stackTrace'] = stackTrace;
    return result;
  }

  Notification toNotification() {
    return Notification('server.error', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ServerErrorParams) {
      return isFatal == other.isFatal &&
          message == other.message &&
          stackTrace == other.stackTrace;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        isFatal,
        message,
        stackTrace,
      );
}

/// server.getVersion params
///
/// Clients may not extend, implement or mix-in this class.
class ServerGetVersionParams implements RequestParams {
  @override
  Map<String, Object> toJson() => {};

  @override
  Request toRequest(String id) {
    return Request(id, 'server.getVersion', null);
  }

  @override
  bool operator ==(other) => other is ServerGetVersionParams;

  @override
  int get hashCode => 55877452;
}

/// server.getVersion result
///
/// {
///   "version": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ServerGetVersionResult implements ResponseResult {
  /// The version number of the analysis server.
  String version;

  ServerGetVersionResult(this.version);

  factory ServerGetVersionResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String version;
      if (json.containsKey('version')) {
        version =
            jsonDecoder.decodeString('$jsonPath.version', json['version']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'version');
      }
      return ServerGetVersionResult(version);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'server.getVersion result', json);
    }
  }

  factory ServerGetVersionResult.fromResponse(Response response) {
    return ServerGetVersionResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['version'] = version;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ServerGetVersionResult) {
      return version == other.version;
    }
    return false;
  }

  @override
  int get hashCode => version.hashCode;
}

/// ServerLogEntry
///
/// {
///   "time": int
///   "kind": ServerLogEntryKind
///   "data": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ServerLogEntry implements HasToJson {
  /// The time (milliseconds since epoch) at which the server created this log
  /// entry.
  int time;

  /// The kind of the entry, used to determine how to interpret the "data"
  /// field.
  ServerLogEntryKind kind;

  /// The payload of the entry, the actual format is determined by the "kind"
  /// field.
  String data;

  ServerLogEntry(this.time, this.kind, this.data);

  factory ServerLogEntry.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      int time;
      if (json.containsKey('time')) {
        time = jsonDecoder.decodeInt('$jsonPath.time', json['time']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'time');
      }
      ServerLogEntryKind kind;
      if (json.containsKey('kind')) {
        kind = ServerLogEntryKind.fromJson(
            jsonDecoder, '$jsonPath.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      String data;
      if (json.containsKey('data')) {
        data = jsonDecoder.decodeString('$jsonPath.data', json['data']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'data');
      }
      return ServerLogEntry(time, kind, data);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ServerLogEntry', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['time'] = time;
    result['kind'] = kind.toJson();
    result['data'] = data;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ServerLogEntry) {
      return time == other.time && kind == other.kind && data == other.data;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        time,
        kind,
        data,
      );
}

/// ServerLogEntryKind
///
/// enum {
///   NOTIFICATION
///   RAW
///   REQUEST
///   RESPONSE
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ServerLogEntryKind implements Enum {
  /// A notification from the server, such as "analysis.highlights". The "data"
  /// field contains a JSON object with abbreviated notification.
  static const ServerLogEntryKind NOTIFICATION =
      ServerLogEntryKind._('NOTIFICATION');

  /// Arbitrary string, describing some event that happened in the server, e.g.
  /// starting a file analysis, and details which files were accessed. These
  /// entries are not structured, but provide context information about
  /// requests and notification, and can be related by "time" for further
  /// manual analysis.
  static const ServerLogEntryKind RAW = ServerLogEntryKind._('RAW');

  /// A request from the client, as the server views it, e.g.
  /// "edit.getAssists". The "data" field contains a JSON object with
  /// abbreviated request.
  static const ServerLogEntryKind REQUEST = ServerLogEntryKind._('REQUEST');

  /// Various counters and measurements related to execution of a request. The
  /// "data" field contains a JSON object with following fields:
  ///
  /// - "id" - the id of the request - copied from the request.
  /// - "method" - the method of the request, e.g. "edit.getAssists".
  /// - "clientRequestTime" - the time (milliseconds since epoch) at which the
  ///   client made the request - copied from the request.
  /// - "serverRequestTime" - the time (milliseconds since epoch) at which the
  ///   server received and decoded the JSON request.
  /// - "responseTime" - the time (milliseconds since epoch) at which the
  ///   server created the response to be encoded into JSON and sent to the
  ///   client.
  static const ServerLogEntryKind RESPONSE = ServerLogEntryKind._('RESPONSE');

  /// A list containing all of the enum values that are defined.
  static const List<ServerLogEntryKind> VALUES = <ServerLogEntryKind>[
    NOTIFICATION,
    RAW,
    REQUEST,
    RESPONSE
  ];

  @override
  final String name;

  const ServerLogEntryKind._(this.name);

  factory ServerLogEntryKind(String name) {
    switch (name) {
      case 'NOTIFICATION':
        return NOTIFICATION;
      case 'RAW':
        return RAW;
      case 'REQUEST':
        return REQUEST;
      case 'RESPONSE':
        return RESPONSE;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory ServerLogEntryKind.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    if (json is String) {
      try {
        return ServerLogEntryKind(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'ServerLogEntryKind', json);
  }

  @override
  String toString() => 'ServerLogEntryKind.$name';

  String toJson() => name;
}

/// server.log params
///
/// {
///   "entry": ServerLogEntry
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ServerLogParams implements HasToJson {
  ServerLogEntry entry;

  ServerLogParams(this.entry);

  factory ServerLogParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      ServerLogEntry entry;
      if (json.containsKey('entry')) {
        entry = ServerLogEntry.fromJson(
            jsonDecoder, '$jsonPath.entry', json['entry']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'entry');
      }
      return ServerLogParams(entry);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'server.log params', json);
    }
  }

  factory ServerLogParams.fromNotification(Notification notification) {
    return ServerLogParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['entry'] = entry.toJson();
    return result;
  }

  Notification toNotification() {
    return Notification('server.log', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ServerLogParams) {
      return entry == other.entry;
    }
    return false;
  }

  @override
  int get hashCode => entry.hashCode;
}

/// server.openUrlRequest params
///
/// {
///   "url": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ServerOpenUrlRequestParams implements RequestParams {
  /// The URL to be opened.
  String url;

  ServerOpenUrlRequestParams(this.url);

  factory ServerOpenUrlRequestParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String url;
      if (json.containsKey('url')) {
        url = jsonDecoder.decodeString('$jsonPath.url', json['url']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'url');
      }
      return ServerOpenUrlRequestParams(url);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'server.openUrlRequest params', json);
    }
  }

  factory ServerOpenUrlRequestParams.fromRequest(Request request) {
    return ServerOpenUrlRequestParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['url'] = url;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'server.openUrlRequest', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ServerOpenUrlRequestParams) {
      return url == other.url;
    }
    return false;
  }

  @override
  int get hashCode => url.hashCode;
}

/// server.openUrlRequest result
///
/// Clients may not extend, implement or mix-in this class.
class ServerOpenUrlRequestResult implements ResponseResult {
  @override
  Map<String, Object> toJson() => {};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) => other is ServerOpenUrlRequestResult;

  @override
  int get hashCode => 561630021;
}

/// ServerService
///
/// enum {
///   LOG
///   STATUS
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ServerService implements Enum {
  static const ServerService LOG = ServerService._('LOG');

  static const ServerService STATUS = ServerService._('STATUS');

  /// A list containing all of the enum values that are defined.
  static const List<ServerService> VALUES = <ServerService>[LOG, STATUS];

  @override
  final String name;

  const ServerService._(this.name);

  factory ServerService(String name) {
    switch (name) {
      case 'LOG':
        return LOG;
      case 'STATUS':
        return STATUS;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory ServerService.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    if (json is String) {
      try {
        return ServerService(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'ServerService', json);
  }

  @override
  String toString() => 'ServerService.$name';

  String toJson() => name;
}

/// server.setClientCapabilities params
///
/// {
///   "requests": List<String>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ServerSetClientCapabilitiesParams implements RequestParams {
  /// The names of the requests that the server can safely send to the client.
  /// Only requests whose name is in the list will be sent.
  ///
  /// A request should only be included in the list if the client will
  /// unconditionally honor the request.
  ///
  /// The default, used before this request is received, is an empty list.
  ///
  /// The following is a list of the names of the requests that can be
  /// specified:
  ///
  /// - openUrlRequest
  /// - showMessageRequest
  List<String> requests;

  ServerSetClientCapabilitiesParams(this.requests);

  factory ServerSetClientCapabilitiesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<String> requests;
      if (json.containsKey('requests')) {
        requests = jsonDecoder.decodeList(
            '$jsonPath.requests', json['requests'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'requests');
      }
      return ServerSetClientCapabilitiesParams(requests);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'server.setClientCapabilities params', json);
    }
  }

  factory ServerSetClientCapabilitiesParams.fromRequest(Request request) {
    return ServerSetClientCapabilitiesParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['requests'] = requests;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'server.setClientCapabilities', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ServerSetClientCapabilitiesParams) {
      return listEqual(
          requests, other.requests, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(requests);
}

/// server.setClientCapabilities result
///
/// Clients may not extend, implement or mix-in this class.
class ServerSetClientCapabilitiesResult implements ResponseResult {
  @override
  Map<String, Object> toJson() => {};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) => other is ServerSetClientCapabilitiesResult;

  @override
  int get hashCode => 806805916;
}

/// server.setSubscriptions params
///
/// {
///   "subscriptions": List<ServerService>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ServerSetSubscriptionsParams implements RequestParams {
  /// A list of the services being subscribed to.
  List<ServerService> subscriptions;

  ServerSetSubscriptionsParams(this.subscriptions);

  factory ServerSetSubscriptionsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      List<ServerService> subscriptions;
      if (json.containsKey('subscriptions')) {
        subscriptions = jsonDecoder.decodeList(
            '$jsonPath.subscriptions',
            json['subscriptions'],
            (String jsonPath, Object? json) =>
                ServerService.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'subscriptions');
      }
      return ServerSetSubscriptionsParams(subscriptions);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'server.setSubscriptions params', json);
    }
  }

  factory ServerSetSubscriptionsParams.fromRequest(Request request) {
    return ServerSetSubscriptionsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['subscriptions'] =
        subscriptions.map((ServerService value) => value.toJson()).toList();
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'server.setSubscriptions', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ServerSetSubscriptionsParams) {
      return listEqual(subscriptions, other.subscriptions,
          (ServerService a, ServerService b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(subscriptions);
}

/// server.setSubscriptions result
///
/// Clients may not extend, implement or mix-in this class.
class ServerSetSubscriptionsResult implements ResponseResult {
  @override
  Map<String, Object> toJson() => {};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) => other is ServerSetSubscriptionsResult;

  @override
  int get hashCode => 748820900;
}

/// server.showMessageRequest params
///
/// {
///   "type": MessageType
///   "message": String
///   "actions": List<MessageAction>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ServerShowMessageRequestParams implements RequestParams {
  /// The type of the message.
  MessageType type;

  /// The message to be displayed.
  String message;

  /// The labels of the buttons by which the user can dismiss the message.
  List<MessageAction> actions;

  ServerShowMessageRequestParams(this.type, this.message, this.actions);

  factory ServerShowMessageRequestParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      MessageType type;
      if (json.containsKey('type')) {
        type =
            MessageType.fromJson(jsonDecoder, '$jsonPath.type', json['type']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'type');
      }
      String message;
      if (json.containsKey('message')) {
        message =
            jsonDecoder.decodeString('$jsonPath.message', json['message']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'message');
      }
      List<MessageAction> actions;
      if (json.containsKey('actions')) {
        actions = jsonDecoder.decodeList(
            '$jsonPath.actions',
            json['actions'],
            (String jsonPath, Object? json) =>
                MessageAction.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'actions');
      }
      return ServerShowMessageRequestParams(type, message, actions);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'server.showMessageRequest params', json);
    }
  }

  factory ServerShowMessageRequestParams.fromRequest(Request request) {
    return ServerShowMessageRequestParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['type'] = type.toJson();
    result['message'] = message;
    result['actions'] =
        actions.map((MessageAction value) => value.toJson()).toList();
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'server.showMessageRequest', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ServerShowMessageRequestParams) {
      return type == other.type &&
          message == other.message &&
          listEqual(actions, other.actions,
              (MessageAction a, MessageAction b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        type,
        message,
        Object.hashAll(actions),
      );
}

/// server.showMessageRequest result
///
/// {
///   "action": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ServerShowMessageRequestResult implements ResponseResult {
  /// The label of the action that was selected by the user. May be omitted or
  /// `null` if the user dismissed the message without clicking an action
  /// button.
  String? action;

  ServerShowMessageRequestResult({this.action});

  factory ServerShowMessageRequestResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      String? action;
      if (json.containsKey('action')) {
        action = jsonDecoder.decodeString('$jsonPath.action', json['action']);
      }
      return ServerShowMessageRequestResult(action: action);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'server.showMessageRequest result', json);
    }
  }

  factory ServerShowMessageRequestResult.fromResponse(Response response) {
    return ServerShowMessageRequestResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    var action = this.action;
    if (action != null) {
      result['action'] = action;
    }
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ServerShowMessageRequestResult) {
      return action == other.action;
    }
    return false;
  }

  @override
  int get hashCode => action.hashCode;
}

/// server.shutdown params
///
/// Clients may not extend, implement or mix-in this class.
class ServerShutdownParams implements RequestParams {
  @override
  Map<String, Object> toJson() => {};

  @override
  Request toRequest(String id) {
    return Request(id, 'server.shutdown', null);
  }

  @override
  bool operator ==(other) => other is ServerShutdownParams;

  @override
  int get hashCode => 366630911;
}

/// server.shutdown result
///
/// Clients may not extend, implement or mix-in this class.
class ServerShutdownResult implements ResponseResult {
  @override
  Map<String, Object> toJson() => {};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) => other is ServerShutdownResult;

  @override
  int get hashCode => 193626532;
}

/// server.status params
///
/// {
///   "analysis": optional AnalysisStatus
///   "pub": optional PubStatus
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ServerStatusParams implements HasToJson {
  /// The current status of analysis, including whether analysis is being
  /// performed and if so what is being analyzed.
  AnalysisStatus? analysis;

  /// The current status of pub execution, indicating whether we are currently
  /// running pub.
  ///
  /// Note: this status type is deprecated, and is no longer sent by the
  /// server.
  PubStatus? pub;

  ServerStatusParams({this.analysis, this.pub});

  factory ServerStatusParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      AnalysisStatus? analysis;
      if (json.containsKey('analysis')) {
        analysis = AnalysisStatus.fromJson(
            jsonDecoder, '$jsonPath.analysis', json['analysis']);
      }
      PubStatus? pub;
      if (json.containsKey('pub')) {
        pub = PubStatus.fromJson(jsonDecoder, '$jsonPath.pub', json['pub']);
      }
      return ServerStatusParams(analysis: analysis, pub: pub);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'server.status params', json);
    }
  }

  factory ServerStatusParams.fromNotification(Notification notification) {
    return ServerStatusParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    var analysis = this.analysis;
    if (analysis != null) {
      result['analysis'] = analysis.toJson();
    }
    var pub = this.pub;
    if (pub != null) {
      result['pub'] = pub.toJson();
    }
    return result;
  }

  Notification toNotification() {
    return Notification('server.status', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ServerStatusParams) {
      return analysis == other.analysis && pub == other.pub;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        analysis,
        pub,
      );
}

/// TypeHierarchyItem
///
/// {
///   "classElement": Element
///   "displayName": optional String
///   "memberElement": optional Element
///   "superclass": optional int
///   "interfaces": List<int>
///   "mixins": List<int>
///   "subclasses": List<int>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class TypeHierarchyItem implements HasToJson {
  /// The class element represented by this item.
  Element classElement;

  /// The name to be displayed for the class. This field will be omitted if the
  /// display name is the same as the name of the element. The display name is
  /// different if there is additional type information to be displayed, such
  /// as type arguments.
  String? displayName;

  /// The member in the class corresponding to the member on which the
  /// hierarchy was requested. This field will be omitted if the hierarchy was
  /// not requested for a member or if the class does not have a corresponding
  /// member.
  Element? memberElement;

  /// The index of the item representing the superclass of this class. This
  /// field will be omitted if this item represents the class Object.
  int? superclass;

  /// The indexes of the items representing the interfaces implemented by this
  /// class. The list will be empty if there are no implemented interfaces.
  List<int> interfaces;

  /// The indexes of the items representing the mixins referenced by this
  /// class. The list will be empty if there are no classes mixed into this
  /// class.
  List<int> mixins;

  /// The indexes of the items representing the subtypes of this class. The
  /// list will be empty if there are no subtypes or if this item represents a
  /// supertype of the pivot type.
  List<int> subclasses;

  TypeHierarchyItem(this.classElement,
      {this.displayName,
      this.memberElement,
      this.superclass,
      List<int>? interfaces,
      List<int>? mixins,
      List<int>? subclasses})
      : interfaces = interfaces ?? <int>[],
        mixins = mixins ?? <int>[],
        subclasses = subclasses ?? <int>[];

  factory TypeHierarchyItem.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object? json) {
    json ??= {};
    if (json is Map) {
      Element classElement;
      if (json.containsKey('classElement')) {
        classElement = Element.fromJson(
            jsonDecoder, '$jsonPath.classElement', json['classElement']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'classElement');
      }
      String? displayName;
      if (json.containsKey('displayName')) {
        displayName = jsonDecoder.decodeString(
            '$jsonPath.displayName', json['displayName']);
      }
      Element? memberElement;
      if (json.containsKey('memberElement')) {
        memberElement = Element.fromJson(
            jsonDecoder, '$jsonPath.memberElement', json['memberElement']);
      }
      int? superclass;
      if (json.containsKey('superclass')) {
        superclass =
            jsonDecoder.decodeInt('$jsonPath.superclass', json['superclass']);
      }
      List<int> interfaces;
      if (json.containsKey('interfaces')) {
        interfaces = jsonDecoder.decodeList(
            '$jsonPath.interfaces', json['interfaces'], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'interfaces');
      }
      List<int> mixins;
      if (json.containsKey('mixins')) {
        mixins = jsonDecoder.decodeList(
            '$jsonPath.mixins', json['mixins'], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'mixins');
      }
      List<int> subclasses;
      if (json.containsKey('subclasses')) {
        subclasses = jsonDecoder.decodeList(
            '$jsonPath.subclasses', json['subclasses'], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'subclasses');
      }
      return TypeHierarchyItem(classElement,
          displayName: displayName,
          memberElement: memberElement,
          superclass: superclass,
          interfaces: interfaces,
          mixins: mixins,
          subclasses: subclasses);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'TypeHierarchyItem', json);
    }
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['classElement'] = classElement.toJson();
    var displayName = this.displayName;
    if (displayName != null) {
      result['displayName'] = displayName;
    }
    var memberElement = this.memberElement;
    if (memberElement != null) {
      result['memberElement'] = memberElement.toJson();
    }
    var superclass = this.superclass;
    if (superclass != null) {
      result['superclass'] = superclass;
    }
    result['interfaces'] = interfaces;
    result['mixins'] = mixins;
    result['subclasses'] = subclasses;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is TypeHierarchyItem) {
      return classElement == other.classElement &&
          displayName == other.displayName &&
          memberElement == other.memberElement &&
          superclass == other.superclass &&
          listEqual(interfaces, other.interfaces, (int a, int b) => a == b) &&
          listEqual(mixins, other.mixins, (int a, int b) => a == b) &&
          listEqual(subclasses, other.subclasses, (int a, int b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        classElement,
        displayName,
        memberElement,
        superclass,
        Object.hashAll(interfaces),
        Object.hashAll(mixins),
        Object.hashAll(subclasses),
      );
}
