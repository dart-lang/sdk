// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.json;

/**
 * Instances of the class [HasToJson] implement [toJson] method that returns
 * a JSON presentation.
 */
abstract class HasToJson {
  /**
   * Returns a JSON presentation of the object.
   */
  Map<String, Object> toJson();
}


/**
 * Returns a JSON presention of [value].
 */
objectToJson(Object value) {
  if (value is HasToJson) {
    return value.toJson();
  }
  if (value is Iterable) {
    return value.map((item) => objectToJson(item)).toList();
  }
  return value;
}
