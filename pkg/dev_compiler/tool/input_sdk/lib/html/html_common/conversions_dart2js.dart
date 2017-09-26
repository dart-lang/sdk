part of html_common;

/// Converts a JavaScript object with properties into a Dart Map.
/// Not suitable for nested objects.
Map convertNativeToDart_Dictionary(object) {
  if (object == null) return null;
  var dict = {};
  var keys = JS('JSExtendableArray', 'Object.getOwnPropertyNames(#)', object);
  for (final key in keys) {
    dict[key] = JS('var', '#[#]', object, key);
  }
  return dict;
}

/// Converts a flat Dart map into a JavaScript object with properties.
convertDartToNative_Dictionary(Map dict, [void postCreate(Object f)]) {
  if (dict == null) return null;
  var object = JS('var', '{}');
  if (postCreate != null) {
    postCreate(object);
  }
  dict.forEach((key, value) {
    JS('void', '#[#] = #', object, key, value);
  });
  return object;
}

/**
 * Ensures that the input is a JavaScript Array.
 *
 * Creates a new JavaScript array if necessary, otherwise returns the original.
 */
List convertDartToNative_StringArray(List<String> input) {
  // TODO(sra).  Implement this.
  return input;
}

DateTime convertNativeToDart_DateTime(date) {
  var millisSinceEpoch = JS('int', '#.getTime()', date);
  return new DateTime.fromMillisecondsSinceEpoch(millisSinceEpoch, isUtc: true);
}

convertDartToNative_DateTime(DateTime date) {
  return JS('', 'new Date(#)', date.millisecondsSinceEpoch);
}

convertDartToNative_PrepareForStructuredClone(value) =>
    new _StructuredCloneDart2Js()
        .convertDartToNative_PrepareForStructuredClone(value);

convertNativeToDart_AcceptStructuredClone(object, {mustCopy: false}) =>
    new _AcceptStructuredCloneDart2Js()
        .convertNativeToDart_AcceptStructuredClone(object, mustCopy: mustCopy);

class _StructuredCloneDart2Js extends _StructuredClone {
  newJsMap() => JS('var', '{}');
  putIntoMap(map, key, value) => JS('void', '#[#] = #', map, key, value);
  newJsList(length) => JS('JSExtendableArray', 'new Array(#)', length);
  cloneNotRequired(e) => (e is NativeByteBuffer || e is NativeTypedData);
}

class _AcceptStructuredCloneDart2Js extends _AcceptStructuredClone {
  List newJsList(length) => JS('JSExtendableArray', 'new Array(#)', length);
  List newDartList(length) => newJsList(length);
  bool identicalInJs(a, b) => identical(a, b);

  void forEachJsField(object, action(key, value)) {
    for (final key in JS('JSExtendableArray', 'Object.keys(#)', object)) {
      action(key, JS('var', '#[#]', object, key));
    }
  }
}

bool isJavaScriptDate(value) => JS('bool', '# instanceof Date', value);
bool isJavaScriptRegExp(value) => JS('bool', '# instanceof RegExp', value);
bool isJavaScriptArray(value) => JS('bool', '# instanceof Array', value);
bool isJavaScriptSimpleObject(value) {
  var proto = JS('', 'Object.getPrototypeOf(#)', value);
  return JS('bool', '# === Object.prototype', proto) ||
      JS('bool', '# === null', proto);
}

bool isImmutableJavaScriptArray(value) =>
    JS('bool', r'!!(#.immutable$list)', value);
bool isJavaScriptPromise(value) =>
    JS('bool', r'typeof Promise != "undefined" && # instanceof Promise', value);

Future convertNativePromiseToDartFuture(promise) {
  var completer = new Completer();
  var then = convertDartClosureToJS((result) => completer.complete(result), 1);
  var error =
      convertDartClosureToJS((result) => completer.completeError(result), 1);
  var newPromise = JS('', '#.then(#)["catch"](#)', promise, then, error);
  return completer.future;
}
