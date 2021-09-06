// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:io' show File, HttpStatus;

import 'package:http/http.dart' as http;

Future<String> readGcloudAuthToken(String path) async {
  String token = await File(path).readAsString();
  return token.split("\n").first;
}

/// Helper class to access the Firestore REST API.
///
/// This class is not a complete implementation of the Firestore REST protocol
/// and is only meant to support the operations required by scripts in
/// tools/bots.
class FirestoreDatabase {
  final http.Client _client = http.Client();
  final Map<String, String> _headers;
  final Uri _documentsUrl;
  final Uri _queryUrl;
  final Uri _beginTransactionUrl;
  final Uri _commitUrl;

  /// The current transaction ID in base64 (or `null`)
  String _currentTransaction;

  /// Returns the current transaction escaped to be useable as part of a URI.
  String get _escapedCurrentTransaction {
    return Uri.encodeFull(_currentTransaction)
        // The Firestore API does not accept '+' in URIs
        .replaceAll("+", "%2B");
  }

  FirestoreDatabase._(this._headers, this._documentsUrl, this._queryUrl,
      this._beginTransactionUrl, this._commitUrl);

  factory FirestoreDatabase(String project, String authToken) {
    var databasePath = 'projects/$project/databases/(default)';
    var databaseUrl = _apiUrl.resolve('$databasePath/');
    var documentsUrl = databaseUrl.resolve('documents/');
    var queryUrl = _apiUrl.resolve('$databasePath/documents:runQuery');
    var beginTransactionUrl =
        _apiUrl.resolve('$databasePath/documents:beginTransaction');
    var commitUrl = _apiUrl.resolve('$databasePath/documents:commit');
    var headers = {
      'Authorization': 'Bearer $authToken',
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    };
    return FirestoreDatabase._(
        headers, documentsUrl, queryUrl, beginTransactionUrl, commitUrl);
  }

  static final _apiUrl = Uri.https('firestore.googleapis.com', 'v1/');

  Future<List /*!*/ > runQuery(Query query) async {
    var body = jsonEncode(query.data);
    var response = await _client.post(_queryUrl, headers: _headers, body: body);
    if (response.statusCode == HttpStatus.ok) {
      return jsonDecode(response.body);
    } else {
      throw _error(response);
    }
  }

  Future<Map> getDocument(String collectionName, String documentName) async {
    var url = _documentsUrl.resolveUri(Uri(
        path: '$collectionName/$documentName',
        query: _currentTransaction == null
            ? null
            : 'transaction=${_escapedCurrentTransaction}'));
    var response = await _client.get(url, headers: _headers);
    if (response.statusCode == HttpStatus.ok) {
      var document = jsonDecode(response.body);
      if (document is! Map) {
        throw _error(response, message: 'Expected a Map');
      }
      return document;
    } else {
      throw _error(response);
    }
  }

  Future<Object> updateField(Map document, String field) async {
    var url =
        _apiUrl.resolve('${document["name"]}?updateMask.fieldPaths=$field');
    var response =
        await _client.patch(url, headers: _headers, body: jsonEncode(document));
    if (response.statusCode == HttpStatus.ok) {
      return jsonDecode(response.body);
    } else {
      throw _error(response);
    }
  }

  void beginTransaction() async {
    if (_currentTransaction != null) {
      throw Exception('Error: nested transactions');
    }
    var body = '{"options": {}}';
    var response =
        await _client.post(_beginTransactionUrl, headers: _headers, body: body);
    if (response.statusCode == HttpStatus.ok) {
      var result = jsonDecode(response.body);
      _currentTransaction = result['transaction'] as String;
      if (_currentTransaction == null) {
        throw Exception("Call returned no transaction identifier");
      }
    } else {
      throw _error(response, message: 'Could not start transaction:');
    }
  }

  Future<bool> commit([List<Write> writes]) async {
    if (_currentTransaction == null) {
      throw Exception('"commit" called without transaction');
    }
    var body = jsonEncode({
      "writes": writes.map((write) => write.data).toList(),
      "transaction": "$_currentTransaction"
    });
    var response =
        await _client.post(_commitUrl, headers: _headers, body: body);
    _currentTransaction = null;
    if (response.statusCode == HttpStatus.conflict) {
      // This HTTP status code corresponds to the ABORTED error code, see
      // https://cloud.google.com/datastore/docs/concepts/errors and
      // https://github.com/googleapis/googleapis/blob/master/google/rpc/code.proto#L137
      return false;
    }
    if (response.statusCode != HttpStatus.ok) {
      throw _error(response);
    }
    return true;
  }

  Exception _error(http.Response response, {String message: 'Error'}) {
    throw Exception('$message: ${response.statusCode}: '
        '${response.reasonPhrase}:\n${response.body}');
  }

  /// Closes the underlying HTTP client.
  void closeClient() => _client.close();
}

abstract class Write {
  Map get data;
}

class Update implements Write {
  final Map data;
  Update(List<String> updateMask, Map document, {String updateTime})
      : data = {
          if (updateTime != null) "currentDocument": {"updateTime": updateTime},
          "updateMask": {"fieldPaths": updateMask},
          "update": document
        };
}

class Query {
  final Map data;
  Query(String collection, Filter filter, {int limit})
      : data = {
          'structuredQuery': {
            'from': [
              {'collectionId': collection}
            ],
            if (limit != null) 'limit': limit,
            'where': filter.data,
          }
        };
}

class Filter {
  final Map data;
  Filter(this.data);
}

class FieldFilter extends Filter {
  FieldFilter(String field, String op, String type, Object value)
      : super({
          'fieldFilter': {
            'field': {'fieldPath': field},
            'op': op,
            'value': {'$type': value},
          }
        });
}

class Field {
  final String name;
  Field(this.name);
  FieldFilter equals(Value value) {
    return FieldFilter(name, 'EQUAL', value.type, value.value);
  }

  FieldFilter greaterOrEqual(Value value) {
    return FieldFilter(name, 'GREATER_THAN_OR_EQUAL', value.type, value.value);
  }

  FieldFilter lessOrEqual(Value value) {
    return FieldFilter(name, 'LESS_THAN_OR_EQUAL', value.type, value.value);
  }

  FieldFilter contains(Value value) {
    return FieldFilter(name, 'ARRAY_CONTAINS', value.type, value.value);
  }
}

class Value {
  final String type;
  final Object value;
  Value.boolean(bool this.value) : type = 'booleanValue';
  Value.string(String this.value) : type = 'stringValue';
  Value.integer(int this.value) : type = 'integerValue';
}

class CompositeFilter extends Filter {
  CompositeFilter(String op, List<Filter> parts)
      : super({
          'compositeFilter': {
            'op': op,
            'filters': parts.map((part) => part.data).toList(),
          }
        });
}
