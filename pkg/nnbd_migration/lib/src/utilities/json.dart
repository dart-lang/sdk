/// Utilities for handling parsed JSON.
///
/// It is recommended to import this library with a prefix.

/// Expects [map] to contain [key], a String key.
///
/// If [map] has key [key], return the value paired with [key]; otherwise throw
/// a FormatException.
dynamic expectKey(Map<Object, Object> map, String key) {
  if (map.containsKey(key)) {
    return map[key];
  }
  throw FormatException(
      'Unexpected `pub outdated` JSON output: missing key ($key)', map);
}

/// Expects [object] to be of type [T].
///
/// If [object] is of type [T], return it; otherwise throw a FormatException
/// with [errorKey] in the message.
T expectType<T>(Object object, String errorKey) {
  if (object is T) {
    return object;
  }
  throw FormatException(
      'Unexpected `pub outdated` JSON output: expected a '
      '$T at "$errorKey", but got a ${object.runtimeType}',
      object);
}
