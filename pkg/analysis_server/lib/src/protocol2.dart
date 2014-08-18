// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library protocol2;

import 'dart:convert';

import 'protocol.dart';

part 'generated_protocol.dart';

/**
 * Compare the lists [listA] and [listB], using [itemEqual] to compare
 * list elements.
 */
bool _listEqual(List listA, List listB, bool itemEqual(a, b)) {
  if (listA.length != listB.length) {
    return false;
  }
  for (int i = 0; i < listA.length; i++) {
    if (!itemEqual(listA[i], listB[i])) {
      return false;
    }
  }
  return true;
}

/**
 * Compare the maps [mapA] and [mapB], using [valueEqual] to compare map
 * values.
 */
bool _mapEqual(Map mapA, Map mapB, bool valueEqual(a, b)) {
  if (mapA.length != mapB.length) {
    return false;
  }
  for (var key in mapA.keys) {
    if (!mapB.containsKey(key)) {
      return false;
    }
    if (!valueEqual(mapA[key], mapB[key])) {
      return false;
    }
  }
  return true;
}

/**
 * Translate the input [map], applying [keyCallback] to all its keys, and
 * [valueCallback] to all its values.
 */
_mapMap(Map map, {dynamic keyCallback(key), dynamic valueCallback(value)}) {
  Map result = {};
  map.forEach((key, value) {
    if (keyCallback != null) {
      key = keyCallback(key);
    }
    if (valueCallback != null) {
      value = valueCallback(value);
    }
    result[key] = value;
  });
  return result;
}

/**
 * Type of callbacks used to decode parts of JSON objects.  [jsonPath] is a
 * string describing the part of the JSON object being decoded, and [value] is
 * the part to decode.
 */
typedef Object JsonDecoderCallback(String jsonPath, Object value);


/**
 * Base class for decoding JSON objects.  The derived class must implement
 * error reporting logic.
 */
abstract class JsonDecoder {
  /**
   * Create an exception to throw if the JSON object at [jsonPath] fails to
   * match the API definition of [expected].
   */
  dynamic mismatch(String jsonPath, String expected);

  /**
   * Create an exception to throw if the JSON object at [jsonPath] is missing
   * the key [key].
   */
  dynamic missingKey(String jsonPath, String key);

  /**
   * Decode a JSON object that is expected to be a boolean.  The strings "true"
   * and "false" are also accepted.
   */
  bool _decodeBool(String jsonPath, Object json) {
    if (json is bool) {
      return json;
    } else if (json == 'true') {
      return true;
    } else if (json == 'false') {
      return false;
    }
    throw mismatch(jsonPath, 'bool');
  }

  /**
   * Decode a JSON object that is expected to be an integer.  A string
   * representation of an integer is also accepted.
   */
  int _decodeInt(String jsonPath, Object json) {
    if (json is int) {
      return json;
    } else if (json is String) {
      return int.parse(json, onError: (String value) {
        throw mismatch(jsonPath, 'int');
      });
    }
    throw mismatch(jsonPath, 'int');
  }

  /**
   * Decode a JSON object that is expected to be a List.  [decoder] is used to
   * decode the items in the list.
   */
  List _decodeList(String jsonPath, Object json, [JsonDecoderCallback decoder]) {
    if (json == null) {
      return [];
    } else if (json is List) {
      List result = [];
      for (int i = 0; i < json.length; i++) {
        result.add(decoder('$jsonPath[$i]', json[i]));
      }
      return result;
    } else {
      throw mismatch(jsonPath, 'List');
    }
  }

  /**
   * Decode a JSON object that is expected to be a Map.  [keyDecoder] is used
   * to decode the keys, and [valueDecoder] is used to decode the values.
   */
  Map _decodeMap(String jsonPath, Object json, {JsonDecoderCallback keyDecoder,
      JsonDecoderCallback valueDecoder}) {
    if (json == null) {
      return {};
    } else if (json is Map) {
      Map result = {};
      json.forEach((String key, value) {
        Object decodedKey;
        if (keyDecoder != null) {
          decodedKey = keyDecoder('$jsonPath.key', key);
        } else {
          decodedKey = key;
        }
        if (valueDecoder != null) {
          value = valueDecoder('$jsonPath[${JSON.encode(key)}]', value);
        }
        result[decodedKey] = value;
      });
      return result;
    } else {
      throw mismatch(jsonPath, 'Map');
    }
  }

  /**
   * Decode a JSON object that is expected to be a string.
   */
  String _decodeString(String jsonPath, Object json) {
    if (json is String) {
      return json;
    } else {
      throw mismatch(jsonPath, 'String');
    }
  }

  /**
   * Decode a JSON object that is expected to be one of several choices,
   * where the choices are disambiguated by the contents of the field [field].
   * [decoders] is a map from each possible string in the field to the decoder
   * that should be used to decode the JSON object.
   */
  Object _decodeUnion(String jsonPath, Map json, String field,
      Map<String, JsonDecoderCallback> decoders) {
    if (json is Map) {
      if (!json.containsKey(field)) {
        throw missingKey(jsonPath, field);
      }
      var disambiguatorPath = '$jsonPath[${JSON.encode(field)}]';
      String disambiguator = _decodeString(disambiguatorPath,
          json[field]);
      if (!decoders.containsKey(disambiguator)) {
        throw mismatch(disambiguatorPath, 'One of: ${decoders.keys.toList()}');
      }
      return decoders[disambiguator](jsonPath, json);
    } else {
      throw mismatch(jsonPath, 'Map');
    }
  }
}

/**
 * JsonDecoder for decoding requests.  Errors are reporting by throwing a
 * [RequestFailure].
 */
class RequestDecoder extends JsonDecoder {
  /**
   * The request being deserialized.
   */
  final Request _request;

  RequestDecoder(this._request);

  @override
  dynamic mismatch(String jsonPath, String expected) {
    return new RequestFailure(new Response.invalidParameter(_request, jsonPath,
        'be $expected'));
  }

  @override
  dynamic missingKey(String jsonPath, String key) {
    return new RequestFailure(new Response.invalidParameter(_request, jsonPath,
        'contain key ${JSON.encode(key)}'));
  }
}

/**
 * JsonDecoder for decoding responses from the server.  This is intended to be
 * used only for testing.  Errors are reported using bare [Exception] objects.
 */
class ResponseDecoder extends JsonDecoder {
  @override
  dynamic mismatch(String jsonPath, String expected) {
    return new Exception('Expected $expected at $jsonPath');
  }

  @override
  dynamic missingKey(String jsonPath, String key) {
    return new Exception('Missing key $key at $jsonPath');
  }
}

/**
 * Jenkins hash function, optimized for small integers.  Borrowed from
 * sdk/lib/math/jenkins_smi_hash.dart.
 *
 * TODO(paulberry): Move to somewhere that can be shared with other code.
 */
class _JenkinsSmiHash {
  static int combine(int hash, int value) {
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) <<  3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }

  static int hash2(a, b) => finish(combine(combine(0, a), b));

  static int hash4(a, b, c, d) =>
      finish(combine(combine(combine(combine(0, a), b), c), d));
}
