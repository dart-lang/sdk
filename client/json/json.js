// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// JavaScript implementation of the native methods declared in json.dart.

// The details of this code depends intimately on how DartC represents
// Dart values in JavaScript, particularly Maps and null.

function native_JSON_parse(jsonString) {
  var obj = JSON.parse(jsonString, function(key, value) {
    return convertJsToDart(value, this);
  });
  return obj == null ? $Dart$Null : obj;
}

// Shallow-converts the parsed JavaScript value into a Dart object, and
// returns the Dart object.
// Any component values have already been converted.
// When converting null, if it's an element of a containing JS array,
// returns $Dart$Null, otherwise returns null, because returning $Dart$Null ==
// undefined would signal to JSON.parse that the field should be
// *deleted*.
function convertJsToDart(obj, container) {
  // The following kinds of JS objects have the same representation in Dart:
  //   boolean, number, string, arrays
  // Dart null is JS undefined.
  // Only generic JavaScript objects need to be converted into Dart Maps.
  // This is done by creating a $Dart$MapLiteralType object, and changing
  // any JS null values into $Dart$Null.
  switch (typeof(obj)) {
    case 'boolean':
    case 'number':
    case 'string':
      return obj;

    case 'object':
      if (obj == null) {
        if (container instanceof Array) {
          return $Dart$Null;
        } else {
          // $Dart$Null is set to undefined, which will make JSON.parse
          // delete the member. We return null here, but will fix it up
          // later.
          return null;
        }
      } else if (obj instanceof Array) {
        return obj;
      } else {
        return fixupJsObjectToDartMap(obj);
      }

    default:
      throw 'unexpected kind of JSON value';
  }
}

var $Object_keys = ('keys' in Object) ?
  function (dict) { return Object.keys(dict); } :
  function (dict) {
     var out = [];
     for (var key in dict) {
       // TODO(sigmund): remove the propertyIsEnumerable check? That check
       // ensures that this function returns the same as Object.keys, but seems
       // unnecessary because this function is only used for user-defined
       // maps/sets.
       if (dict.hasOwnProperty(key) && dict.propertyIsEnumerable(key)) {
         out.push(key);
       }
     }
     return out;
  };

// Converts the parsed JavaScript Object into a Dart Map.
function fixupJsObjectToDartMap(obj) {
  var map = $Dart$MapLiteralFactory();
  var keys = $Object_keys(obj);
  for (var i = 0; i < keys.length; i++) {
    var value = obj[keys[i]];
    value = (value === null ? $Dart$Null : value);
    map.ASSIGN_INDEX$operator(keys[i], value);
  }
  return map;
}

///////////////////////////////////////////////////////////////////////////////

function UnconvertibleException() { }

// Returns whether JSON.stringify appears to fully work.
function testBrowserHasWorkingStringify() {
  // Firefox3.6's JSON.stringify is broken; the reviver function's
  // result isn't used except within arrays.  See
  // http://skysanders.net/subtext/archive/2010/02/24/confirmed-bug-in-firefox-3.6-native-json-implementation.aspx,
  // for instance.
  return JSON.parse(JSON.stringify({works:false}, function(key, value) {
        return value == false ? true : value;
      })).works;
}
var browserHasWorkingStringify = testBrowserHasWorkingStringify();

function native_JSON_stringify(obj) {
  var jsonString;
  if (browserHasWorkingStringify) {
    jsonString = JSON.stringify(obj, function(key, value) {
      return convertDartToJs(value);
    });
  } else {
    jsonString = JSON.stringify(convertDartToJs(obj));
  }
  return jsonString;
}

// Converts the Dart object into a JavaScript value, suitable for applying
// JSON.stringify to.
// If browserHasWorkingStringify, then converts only shallowly, otherwise
// converts deeply.
// Throws UnconvertibleException if the Dart value is not convertible.
function convertDartToJs(obj) {
  // The following kinds of Dart objects have the same representation in JS:
  //   boolean, number, string, arrays
  // Dart null is JS undefined.
  // Only Dart Maps need to be converted into JavaScript objects.
  if (obj == $Dart$Null) {
    return null;
  } else if (obj == null) {
    throw 'not expecting JS-null in a Dart object';
  } else {
    switch (typeof obj) {
      case 'boolean':
      case 'number':
      case 'string':
        return obj;
      case 'object':
        if (obj instanceof Array) {
          return convertDartArrayToJsArray(obj);
        } else if ($isDartMap(obj)) {
          return convertDartMapToJsObject(obj);
        } else {
          throw new UnconvertibleException();
        }
      default:
        throw 'unexpected kind of Dart value';
    }
  }
}

// Converts the Dart Array into a JavaScript array.
// If browserHasWorkingStringify, then converts only shallowly, otherwise
// converts deeply.
function convertDartArrayToJsArray(arr) {
  if (browserHasWorkingStringify) {
    // The array elements will be (or have been) converted separately.
    return arr;
  } else {
    // Need to recursively convert all the array elements.
    var len = arr.length$getter();
    var obj = new Array(len);
    for (var i = 0; i < len; i++) {
      var elemValue = arr.INDEX$operator(i);
      obj[i] = convertDartToJs(elemValue);
    }
    return obj;
  }
}

// Converts the Dart Map into a JavaScript object.
// If browserHasWorkingStringify, then converts only shallowly, otherwise
// converts deeply.
function convertDartMapToJsObject(map) {
  var valueConverter =
      browserHasWorkingStringify ? convertDartNullToJsNull : convertDartToJs;
  var obj = {};
  var propertyNames = map.getKeys$member();
  for (var i = 0, len = propertyNames.length$getter(); i < len; i++) {
    var propertyName = propertyNames.INDEX$operator(i);
    var propertyValue = map.INDEX$operator(propertyName);
    obj[propertyName] = valueConverter(propertyValue);
  }
  return obj;
}

// Converts Dart-null to JS-null, otherwise acts like the identity.
function convertDartNullToJsNull(value) {
  return value == $Dart$Null ? null : value;
}
