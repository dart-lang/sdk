part of "dart:html_common";

convertDartToNative_PrepareForStructuredClone(value) =>
    new _StructuredCloneDartium()
        .convertDartToNative_PrepareForStructuredClone(value);

convertNativeToDart_AcceptStructuredClone(object, {mustCopy: false}) =>
    new _AcceptStructuredCloneDartium()
        .convertNativeToDart_AcceptStructuredClone(object, mustCopy: mustCopy);

class _StructuredCloneDartium extends _StructuredClone {
  newJsMap() => js.JsNative.newObject();
  putIntoMap(map, key, value) => js.JsNative.setProperty(map, key, value);
  newJsList(length) => js.JsNative.newArray()..length = length;
  cloneNotRequired(e) => e is js.JSObject || e is TypedData || e is ByteBuffer;
}

/// A version of _AcceptStructuredClone, but using a different algorithm
/// so we can take advantage of an identity HashMap on Dartium without
/// the bad side-effect of modifying the JS source objects if we do the same in
/// dart2js.
///
/// This no longer inherits anything from _AcceptStructuredClone
/// and is never used polymorphically with it, so it doesn't inherit.
class _AcceptStructuredCloneDartium {
  newDartList(length) => new List(length);

  // As long as we stick to JSObject instead of intermingling legacy JsObject,
  // we can simply use identical.
  bool identicalInJs(a, b) => identical(a, b);

  void forEachJsField(jsObject, action) {
    var keys = js.JsNative.callMethod(_object, "keys", [jsObject]);
    for (var key in keys) {
      action(key, js.JsNative.getProperty(jsObject, key));
    }
  }

  // Keep track of the clones, keyed by the original object. If we're
  // not copying, these may be the same.
  var clones = new HashMap.identity();
  bool mustCopy = false;

  Object findSlot(value) {
    return clones.putIfAbsent(value, () => null);
  }

  writeSlot(original, x) {
    clones[original] = x;
  }

  walk(e) {
    if (e == null) return e;
    if (e is bool) return e;
    if (e is num) return e;
    if (e is String) return e;
    if (e is DateTime) return e;

    if (isJavaScriptRegExp(e)) {
      // TODO(sra).
      throw new UnimplementedError('structured clone of RegExp');
    }

    if (isJavaScriptPromise(e)) {
      return convertNativePromiseToDartFuture(e);
    }

    if (isJavaScriptSimpleObject(e)) {
      // TODO(sra): If mustCopy is false, swizzle the prototype for one of a Map
      // implementation that uses the properies as storage.
      var copy = findSlot(e);
      if (copy != null) return copy;
      copy = {};

      writeSlot(e, copy);
      forEachJsField(e, (key, value) => copy[key] = walk(value));
      return copy;
    }

    if (isJavaScriptArray(e)) {
      var copy = findSlot(e);
      if (copy != null) return copy;

      int length = e.length;
      // Since a JavaScript Array is an instance of Dart List, we can modify it
      // in-place unless we must copy.
      copy = mustCopy ? newDartList(length) : e;
      writeSlot(e, copy);

      for (int i = 0; i < length; i++) {
        copy[i] = walk(e[i]);
      }
      return copy;
    }

    // Assume anything else is already a valid Dart object, either by having
    // already been processed, or e.g. a clonable native class.
    return e;
  }

  convertNativeToDart_AcceptStructuredClone(object, {mustCopy: false}) {
    this.mustCopy = mustCopy;
    var copy = walk(object);
    return copy;
  }
}

final _dateConstructor = js.JsNative.getProperty(window, "Date");
final _regexConstructor = js.JsNative.getProperty(window, "RegExp");

bool isJavaScriptDate(value) =>
    value is js.JSObject && js.JsNative.instanceof(value, _dateConstructor);
bool isJavaScriptRegExp(value) =>
    value is js.JSObject && js.JsNative.instanceof(value, _regexConstructor);
bool isJavaScriptArray(value) => value is js.JSArray;

final _object = js.JsNative.getProperty(window, "Object");
final _getPrototypeOf = js.JsNative.getProperty(_object, "getPrototypeOf");
_getProto(object) {
  return _getPrototypeOf(object);
}

final _objectProto = js.JsNative.getProperty(_object, "prototype");

bool isJavaScriptSimpleObject(value) {
  if (value is! js.JSObject) return false;
  var proto = _getProto(value);
  return proto == _objectProto || proto == null;
}

// TODO(jacobr): this makes little sense unless we are doing something
// ambitious to make Dartium and Dart2Js interop well with each other.
bool isImmutableJavaScriptArray(value) =>
    isJavaScriptArray(value) &&
    js.JsNative.getProperty(value, "immutable$list") != null;

final _promiseConstructor = js.JsNative.getProperty(window, 'Promise');
bool isJavaScriptPromise(value) =>
    value is js.JSObject &&
    identical(
        js.JsNative.getProperty(value, 'constructor'), _promiseConstructor);

Future convertNativePromiseToDartFuture(js.JSObject promise) {
  var completer = new Completer();
  var newPromise = js.JsNative.callMethod(
      js.JsNative.callMethod(promise, "then",
          [js.allowInterop((result) => completer.complete(result))]),
      "catch",
      [js.allowInterop((result) => completer.completeError(result))]);
  return completer.future;
}

convertDartToNative_DateTime(DateTime date) {
  return date;
}

/// Creates a Dart Rectangle from a Javascript object with properties
/// left, top, width and height or a 4 element array of integers. Used internally in Dartium.
Rectangle make_dart_rectangle(r) {
  if (r == null) return null;
  if (r is List) {
    return new Rectangle(r[0], r[1], r[2], r[3]);
  }

  return new Rectangle(
      js.JsNative.getProperty(r, 'left'),
      js.JsNative.getProperty(r, 'top'),
      js.JsNative.getProperty(r, 'width'),
      js.JsNative.getProperty(r, 'height'));
}

// Converts a flat Dart map into a JavaScript object with properties this is
// is the Dartium only version it uses dart:js.
// TODO(alanknight): This could probably be unified with the dart2js conversions
// code in html_common and be more general.
convertDartToNative_Dictionary(Map dict) {
  if (dict == null) return null;
  var jsObject = js.JsNative.newObject();
  dict.forEach((String key, value) {
    if (value is List) {
      var jsArray = js.JsNative.newArray();
      value.forEach((elem) {
        jsArray.add(elem is Map ? convertDartToNative_Dictionary(elem) : elem);
      });
      js.JsNative.setProperty(jsObject, key, jsArray);
    } else {
      js.JsNative.setProperty(jsObject, key, value);
    }
  });
  return jsObject;
}

// Creates a Dart class to allow members of the Map to be fetched (as if getters exist).
// TODO(terry): Need to use package:js but that's a problem in dart:html. Talk to
//              Jacob about how to do this properly using dart:js.
class _ReturnedDictionary {
  Map _values;

  noSuchMethod(Invocation invocation) {
    var key = MirrorSystem.getName(invocation.memberName);
    if (invocation.isGetter) {
      return _values[key];
    } else if (invocation.isSetter && key.endsWith('=')) {
      key = key.substring(0, key.length - 1);
      _values[key] = invocation.positionalArguments[0];
    }
  }

  Map get toMap => _values;

  _ReturnedDictionary(Map value) : _values = value != null ? value : {};
}

// Helper function to wrapped a returned dictionary from blink to a Dart looking
// class.
convertNativeDictionaryToDartDictionary(values) {
  if (values is! Map) {
    // TODO(jacobr): wish wwe didn't have to do this.
    values = convertNativeToDart_SerializedScriptValue(values);
  }
  return values != null ? new _ReturnedDictionary(values) : null;
}

convertNativeToDart_Dictionary(values) =>
    convertNativeToDart_SerializedScriptValue(values);

// Conversion function place holder (currently not used in dart2js or dartium).
List convertDartToNative_StringArray(List<String> input) => input;

// Converts a Dart list into a JsArray. For the Dartium version only.
convertDartToNative_List(List input) => new js.JsArray()..addAll(input);

// Incredibly slow implementation to lookup the runtime type for an object.
// Fortunately, performance doesn't matter much as the results are cached
// as long as the object being looked up has a valid prototype.
// TODO(jacobr): we should track the # of lookups to ensure that things aren't
// going off the rails due to objects with null prototypes, etc.
// Note: unlike all other methods in this class, here we intentionally use
// the old JsObject types to bootstrap the new typed bindings.
Type lookupType(js.JsObject jsObject, bool isElement) {
  try {
    // TODO(jacobr): add static methods that return the runtime type of the patch
    // class so that this code works as expected.
    if (jsObject is js.JsArray) {
      return js.JSArray.instanceRuntimeType;
    }
    if (jsObject is js.JsFunction) {
      return js.JSFunction.instanceRuntimeType;
    }

    var constructor = js.JsNative.getProperty(jsObject, 'constructor');
    if (constructor == null) {
      // Perfectly valid case for JavaScript objects where __proto__ has
      // intentionally been set to null.
      // We should track and warn about this case as peformance will be poor.
      return js.JSObject.instanceRuntimeType;
    }
    var jsTypeName = js.JsNative.getProperty(constructor, 'name');
    if (jsTypeName is! String || jsTypeName.length == 0) {
      // Not an html type.
      return js.JSObject.instanceRuntimeType;
    }

    var dartClass_instance;
    var customElementClass = null;
    var extendsTag = "";

    Type type = getHtmlCreateType(jsTypeName);
    if (type != null) return type;

    // Start walking the prototype chain looking for a JS class.
    var prototype = js.JsNative.getProperty(jsObject, '__proto__');
    while (prototype != null) {
      // We're a Dart class that's pointing to a JS class.
      var constructor = js.JsNative.getProperty(prototype, 'constructor');
      if (constructor != null) {
        jsTypeName = js.JsNative.getProperty(constructor, 'name');
        type = getHtmlCreateType(jsTypeName);
        if (type != null) return type;
      }
      prototype = js.JsNative.getProperty(prototype, '__proto__');
    }
  } catch (e) {
    // This case can happen for cross frame objects.
    if (js.JsNative.hasProperty(e, "postMessage")) {
      // assume this is a Window. To match Dart2JS, separate conversion code
      // in dart:html will switch the wrapper to a cross frame window as
      // required.
      // TODO(jacobr): we could consider removing this code completely.
      return Window.instanceRuntimeType;
    }
  }
  return js.JSObject.instanceRuntimeType;
}
