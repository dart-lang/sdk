// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.codec;

final JSON = new JsonCodec();

/**
 * A [JsonCodec] encodes JSON objects to strings and decodes strings to
 * JSON objects.
 */
class JsonCodec extends Codec<Object, String> {
  const JsonCodec();

  /**
   * Creates a `JsonCodec` with the given reviver.
   *
   * The [reviver] function is called once for each object or list property
   * that has been parsed during decoding. The `key` argument is either the
   * integer list index for a list property, the map string for object
   * properties, or `null` for the final result.
   */
  factory JsonCodec.withReviver(reviver(var key, var value)) =
      _ReviverJsonCodec;

  /**
   * Parses the string and returns the resulting Json object.
   *
   * The optional [reviver] function, if provided, is called once for each
   * object or list property parsed.
   */
  Object decode(String str, {reviver(var key, var value)}) {
    return new JsonDecoder(reviver).convert(str);
  }

  JsonEncoder get encoder => new JsonEncoder();
  JsonDecoder get decoder => new JsonDecoder(null);
}

class _ReviverJsonCodec extends JsonCodec {
  final Function _reviver;
  _ReviverJsonCodec(this._reviver);

  Object decode(String str, {reviver(var key, var value)}) {
    if (reviver == null) reviver = _reviver;
    return new JsonDecoder(reviver).convert(str);
  }

  JsonDecoder get decoder => new JsonDecoder(_reviver);
}
