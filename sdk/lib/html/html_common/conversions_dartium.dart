part of html_common;

convertDartToNative_PrepareForStructuredClone(value) =>
    new _StructuredCloneDartium().convertDartToNative_PrepareForStructuredClone(value);

convertNativeToDart_AcceptStructuredClone(object, {mustCopy: false}) =>
    new _AcceptStructuredCloneDartium().convertNativeToDart_AcceptStructuredClone(object, mustCopy: mustCopy);

class _StructuredCloneDartium extends _StructuredClone {
  newJsMap() => new js.JsObject(js.context["Object"]);
  putIntoMap(map, key, value) => map[key] = value;
  // TODO(alanknight): Don't create two extra lists to get a fixed-length JS list.
  newJsList(length) => new js.JsArray.from(new List(length));
  cloneNotRequired(e) => e is js.JsObject;
}

class _AcceptStructuredCloneDartium extends _AcceptStructuredClone {
  newDartList(length) => new List(length);

  // JsObjects won't be identical, but will be equal only if the underlying
  // Js entities are identical.
  bool identicalInJs(a, b) =>
      (a is js.JsObject) ? a == b : identical(a, b);

  void forEachJsField(jsObject, action) {
    var keys = js.context["Object"].callMethod("keys", [jsObject]);
    for (var key in keys) {
      action(key, jsObject[key]);
    }
  }
}

final _dateConstructor = js.context["Date"];
final _regexConstructor = js.context["RegExp"];

bool isJavaScriptDate(value) => value is js.JsObject && value.instanceof(_dateConstructor);
bool isJavaScriptRegExp(value) => value is js.JsObject && value.instanceof(_regexConstructor);
bool isJavaScriptArray(value) => value is js.JsArray;

final _object = js.context["Object"];
final _getPrototypeOf = _object["getPrototypeOf"];
_getProto(object) {
  return _getPrototypeOf.apply([object]);
}
final _objectProto = js.context["Object"]["prototype"];

bool isJavaScriptSimpleObject(value) {
  if (value is! js.JsObject) return false;
  var proto = _getProto(value);
  return proto == _objectProto || proto == null;
}
bool isImmutableJavaScriptArray(value) =>
    isJavaScriptArray(value) && value["immutable$list"] != null;

final _promiseConstructor = js.context['Promise'];
bool isJavaScriptPromise(value) => value is js.JsObject && value['constructor'] == _promiseConstructor;

Future convertNativePromiseToDartFuture(js.JsObject promise) {
  var completer = new Completer();
  var newPromise = promise
    .callMethod("then", [(result) => completer.complete(result)])
    .callMethod("catch", [(result) => completer.completeError(result)]);
  return completer.future;
}
