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

convertDartToNative_DateTime(DateTime date) {
  return new js.JsObject(js.context["Date"], [date.millisecondsSinceEpoch]);
}

/// Creates a Dart Rectangle from a Javascript object with properties
/// left, top, width and height. Used internally in Dartium.
Rectangle make_dart_rectangle(r) =>
    r == null ? null : new Rectangle(
    js.JsNative.getProperty(r, 'left'),
    js.JsNative.getProperty(r, 'top'),
    js.JsNative.getProperty(r, 'width'),
    js.JsNative.getProperty(r, 'height'));

// Converts a flat Dart map into a JavaScript object with properties this is
// is the Dartium only version it uses dart:js.
// TODO(alanknight): This could probably be unified with the dart2js conversions
// code in html_common and be more general.
convertDartToNative_Dictionary(Map dict) {
  if (dict == null) return null;
  var jsObject = new js.JsObject(js.JsNative.getProperty(js.context, 'Object'));
  dict.forEach((String key, value) {
    if (value is List) {
      var jsArray = new js.JsArray();
      value.forEach((elem) {
        jsArray.add(elem is Map ? convertDartToNative_Dictionary(elem): elem);
      });
      jsObject[key] = jsArray;
    } else {
      jsObject[key] = value;
    }
  });
  return jsObject;
}

// Conversion function place holder (currently not used in dart2js or dartium).
List convertDartToNative_StringArray(List<String> input) => input;

// Converts a Dart list into a JsArray. For the Dartium version only.
convertDartToNative_List(List input) => new js.JsArray()..addAll(input);

/// Find the underlying JS object for a dart:html Dart object.
unwrap_jso(dartClass_instance) => js.unwrap_jso(dartClass_instance);

// Flag to disable JS interop asserts.  Setting to false will speed up the
// wrap_jso calls.
bool interop_checks = false;

/// Wrap a JS object with an instance of the matching dart:html class. Used only in Dartium.
wrap_jso(jsObject) {
  try {
    if (jsObject is! js.JsObject || jsObject == null) {
      // JS Interop converted the object to a Dart class e.g., Uint8ClampedList.
      // or it's a simple type.
      return jsObject;
    }

    var wrapper = js.getDartHtmlWrapperFor(jsObject);
    // if we have a wrapper return the Dart instance.
    if (wrapper != null) {
      return wrapper;
    }

    if (jsObject is js.JsArray) {
      var wrappingList = new DartHtmlWrappingList(jsObject);
      js.setDartHtmlWrapperFor(jsObject, wrappingList);
      return wrappingList;
    }

    // Try the most general type conversions on it.
    // TODO(alanknight): We may be able to do better. This maintains identity,
    // which is useful, but expensive. And if we nest something that only
    // this conversion handles, how does that work? e.g. a list of maps of elements.
    var converted = convertNativeToDart_SerializedScriptValue(jsObject);
    if (!identical(converted, jsObject)) {
      return converted;
    }

    var constructor = js.JsNative.getProperty(jsObject, 'constructor');
    if (constructor == null) {
      // Perfectly valid case for JavaScript objects where __proto__ has
      // intentionally been set to null.
      js.setDartHtmlWrapperFor(jsObject, jsObject);
      return jsObject;
    }
    var jsTypeName = js.JsNative.getProperty(constructor, 'name');
    if (jsTypeName is! String || jsTypeName.length == 0) {
      // Not an html type.
      js.setDartHtmlWrapperFor(jsObject, jsObject);
      return jsObject;
    }

    var dartClass_instance;
    var customElementClass = null;
    var extendsTag = "";
    var custom = getCustomElementEntry(jsObject);
    if (custom != null) {
      customElementClass = custom['type'];
      extendsTag = custom['extends'];
    }

    // Only allow custom elements to be created in the html or svg default
    // namespace.
    var func;
    var defaultNS = jsObject['namespaceURI'] == 'http://www.w3.org/1999/xhtml' ||
        jsObject['namespaceURI'] ==  'http://www.w3.org/2000/svg';
    if (customElementClass != null && extendsTag == "" && defaultNS) {
      // The customElementClass is known but we can't create the real class so
      // create the HtmlElement and it will get upgraded when registerElement's
      // createdCallback is called.
      func = getHtmlCreateFunction('HTMLElement');
    } else {
      func = getHtmlCreateFunction(jsTypeName);
      if (func == null) {
        // Start walking the prototype chain looking for a JS class.
        var prototype = jsObject['__proto__'];
        var keepWalking = true;
        while (keepWalking && prototype.hasProperty('__proto__')) {
          prototype = prototype['__proto__'];
          if (prototype != null && prototype is Element &&
              prototype.blink_jsObject != null) {
            // We're a Dart class that's pointing to a JS class.
            var blinkJso = prototype.blink_jsObject;
            jsTypeName = blinkJso['constructor']['name'];
            func = getHtmlCreateFunction(jsTypeName);
            keepWalking = func == null;
          }
        }
      }
    }

    // Can we construct a Dart class?
    if (func != null) {
      dartClass_instance = func();

      // Wrap our Dart instance in both directions.
      dartClass_instance.blink_jsObject = jsObject;
      js.setDartHtmlWrapperFor(jsObject, dartClass_instance);
    }

    // TODO(jacobr): cache that this is not a dart:html JS class.
    return dartClass_instance;
  } catch(e, stacktrace){
    if (interop_checks) {
      if (e is DebugAssertException)
        window.console.log("${e.message}\n ${stacktrace}");
      else
        window.console.log("${stacktrace}");
    }
  }

  return null;
}

/**
 * Create Dart class that maps to the JS Type, add the JsObject as an expando
 * on the Dart class and return the created Dart class.
 */
wrap_jso_no_SerializedScriptvalue(jsObject) {
  try {
    if (jsObject is! js.JsObject || jsObject == null) {
      // JS Interop converted the object to a Dart class e.g., Uint8ClampedList.
      // or it's a simple type.
      return jsObject;
    }

    // TODO(alanknight): With upgraded custom elements this causes a failure because
    // we need a new wrapper after the type changes. We could possibly invalidate this
    // if the constructor name didn't match?
    var wrapper = js.getDartHtmlWrapperFor(jsObject);
    if (wrapper != null) {
      return wrapper;
    }

    if (jsObject is js.JsArray) {
      var wrappingList = new DartHtmlWrappingList(jsObject);
      js.setDartHtmlWrapperFor(jsObject, wrappingList);
      return wrappingList;
    }

    var constructor = js.JsNative.getProperty(jsObject, 'constructor');
    if (constructor == null) {
      // Perfectly valid case for JavaScript objects where __proto__ has
      // intentionally been set to null.
      js.setDartHtmlWrapperFor(jsObject, jsObject);
      return jsObject;
    }
    var jsTypeName = js.JsNative.getProperty(constructor, 'name');
    if (jsTypeName is! String || jsTypeName.length == 0) {
      // Not an html type.
      js.setDartHtmlWrapperFor(jsObject, jsObject);
      return jsObject;
    }

    var func = getHtmlCreateFunction(jsTypeName);
    if (func != null) {
      var dartClass_instance = func();
      dartClass_instance.blink_jsObject = jsObject;
      js.setDartHtmlWrapperFor(jsObject, dartClass_instance);
      return dartClass_instance;
    }
    return jsObject;
  } catch(e, stacktrace){
    if (interop_checks) {
      if (e is DebugAssertException)
        window.console.log("${e.message}\n ${stacktrace}");
      else
        window.console.log("${stacktrace}");
    }
  }

  return null;
}

/**
 * Create Dart class that maps to the JS Type that is the JS type being
 * extended using JS interop createCallback (we need the base type of the
 * custom element) not the Dart created constructor.
 */
wrap_jso_custom_element(jsObject) {
  try {
    if (jsObject is! js.JsObject) {
      // JS Interop converted the object to a Dart class e.g., Uint8ClampedList.
      return jsObject;
    }

    // Find out what object we're extending.
    var objectName = jsObject.toString();
    // Expect to see something like '[object HTMLElement]'.
    if (!objectName.startsWith('[object ')) {
      return jsObject;
    }

    var extendsClass = objectName.substring(8, objectName.length - 1);
    var func = getHtmlCreateFunction(extendsClass);
    if (interop_checks)
      debug_or_assert("func != null name = ${extendsClass}", func != null);
    var dartClass_instance = func();
    dartClass_instance.blink_jsObject = jsObject;
    return dartClass_instance;
  } catch(e, stacktrace){
    if (interop_checks) {
      if (e is DebugAssertException)
        window.console.log("${e.message}\n ${stacktrace}");
      else
        window.console.log("${stacktrace}");
    }

    // Problem?
    return null;
  }
}

getCustomElementEntry(element) {
  var hasAttribute = false;

  var jsObject;
  var tag = "";
  var runtimeType = element.runtimeType;
  if (runtimeType == HtmlElement) {
    tag = element.localName;
  } else if (runtimeType == TemplateElement) {
    // Data binding with a Dart class.
    tag = element.attributes['is'];
  } else if (runtimeType == js.JsObjectImpl) {
    // It's a Polymer core element (written in JS).
    // Make sure it's an element anything else we can ignore.
    if (element.hasProperty('nodeType') && element['nodeType'] == 1) {
      if (js.JsNative.callMethod(element, 'hasAttribute', ['is'])) {
        hasAttribute = true;
        // It's data binding use the is attribute.
        tag = js.JsNative.callMethod(element, 'getAttribute', ['is']);
      } else {
        // It's a custom element we want the local name.
        tag = element['localName'];
      }
    }
  } else {
    throw new UnsupportedError('Element is incorrect type. Got ${runtimeType}, expected HtmlElement/HtmlTemplate/JsObjectImpl.');
  }

  var entry = _knownCustomElements[tag];
  if (entry != null) {
    // If there's an 'is' attribute then check if the extends tag registered
    // matches the tag if so then return the entry that's registered for this
    // extendsTag or if there's no 'is' tag then return the entry found.
    if ((hasAttribute && entry['extends'] == tag) || !hasAttribute) {
      return entry;
    }
  }

  return null;
}

// List of known tagName to DartClass for custom elements, used for upgrade.
var _knownCustomElements = new Map<String, Map<Type, String>>();

void addCustomElementType(String tagName, Type dartClass, [String extendTag]) {
  _knownCustomElements[tagName] =
      {'type': dartClass, 'extends': extendTag != null ? extendTag : "" };
}

Type getCustomElementType(object) {
  var entry = getCustomElementEntry(object);
  if (entry != null) {
    return entry['type'];
  }
  return null;
}

/**
 * Wraps a JsArray and will call wrap_jso on its entries.
 */
class DartHtmlWrappingList extends ListBase implements NativeFieldWrapperClass2 {
  DartHtmlWrappingList(this.blink_jsObject);

  final js.JsArray blink_jsObject;

  operator [](int index) => wrap_jso(js.JsNative.getArrayIndex(blink_jsObject, index));

  operator []=(int index, value) => blink_jsObject[index] = value;

  int get length => blink_jsObject.length;
  int set length(int newLength) => blink_jsObject.length = newLength;
}
