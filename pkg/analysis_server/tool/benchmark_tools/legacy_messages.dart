// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String _uriToStringWithoutEndingSlash(Uri uri) {
  String result = uri.toString();
  if (result.endsWith('/')) return result.substring(0, result.length - 1);
  return result;
}

class LegacyMessages {
  static Map<String, dynamic> getAssists(
    int id,
    Uri file,
    int offset, {
    int length = 0,
  }) {
    return {
      'id': '$id',
      'method': 'edit.getAssists',
      'params': {'file': '$file', 'offset': offset, 'length': length},
      'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> getFixes(int id, Uri file, int offset) {
    return {
      'id': '$id',
      'method': 'edit.getFixes',
      'params': {'file': '$file', 'offset': offset},
      'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> getHover(int id, Uri file, int offset) {
    return {
      'id': '$id',
      'method': 'analysis.getHover',
      'params': {'file': '$file', 'offset': offset},
      'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> getSuggestions2(int id, Uri file, int offset) {
    return {
      'id': '$id',
      'method': 'completion.getSuggestions2',
      'params': {
        'file': '$file',
        'offset': offset,
        'maxResults': 100,
        'completionCaseMatchingMode': 'FIRST_CHAR',
        'completionMode': 'BASIC',
        'invocationCount': 1,
      },
      'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> getVersion(int id) {
    return {
      'id': '$id',
      'method': 'server.getVersion',
      'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> setAnalysisRoots(int id, List<Uri> includes) {
    return {
      'id': '$id',
      'method': 'analysis.setAnalysisRoots',
      'params': {
        'included': [...includes.map(_uriToStringWithoutEndingSlash)],
        'excluded': [],
      },
      'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> setClientCapabilities(int id) {
    return {
      'id': '$id',
      'method': 'server.setClientCapabilities',
      'params': {
        'requests': ['openUrlRequest', 'showMessageRequest'],
        'supportsUris': true,
      },
      'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> setPriorityFiles(int id, List<Uri> files) {
    return {
      'id': '$id',
      'method': 'analysis.setPriorityFiles',
      'params': {
        'files': [...files.map(_uriToStringWithoutEndingSlash)],
      },
      'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> setSubscriptionsStatus(int id) {
    return {
      'id': '$id',
      'method': 'server.setSubscriptions',
      'params': {
        'subscriptions': ['STATUS'],
      },
      'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> updateContent(
    int id,
    Uri file,
    String newContent,
  ) {
    return {
      'id': '$id',
      'method': 'analysis.updateContent',
      'params': {
        'files': {
          '$file': {'type': 'add', 'content': newContent},
        },
      },
      'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> updateOptions(int id) {
    return {
      'id': '$id',
      'method': 'analysis.updateOptions',
      'params': {
        'options': {
          'enableAsync': true,
          'enableDeferredLoading': true,
          'enableEnums': true,
          'enableNullAwareOperators': true,
          'generateDart2jsHints': false,
          'generateHints': true,
          'generateLints': false,
        },
      },
      'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
