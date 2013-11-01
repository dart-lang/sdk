// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

// TODO(ahe): This code should be integrated in CodeEmitterTask.finishClasses.
String getReflectionDataParser(String classesCollector, Namer namer) {
  String metadataField = '"${namer.metadataField}"';
  String reflectableField = namer.reflectableField;
  String defaultValuesField = namer.defaultValuesField;
  String methodsWithOptionalArgumentsField =
      namer.methodsWithOptionalArgumentsField;
  return '''
(function (reflectionData) {
'''
// [map] returns an object literal that V8 shouldn't try to optimize with a
// hidden class. This prevents a potential performance problem where V8 tries
// to build a hidden class for an object used as a hashMap.
'''
  function map(x){x={x:x};delete x.x;return x}
  if (!init.libraries) init.libraries = [];
  if (!init.mangledNames) init.mangledNames = map();
  if (!init.mangledGlobalNames) init.mangledGlobalNames = map();
  if (!init.statics) init.statics = map();
  if (!init.typeInformation) init.typeInformation = map();
  if (!init.globalFunctions) init.globalFunctions = map();
  var libraries = init.libraries;
  var mangledNames = init.mangledNames;
  var mangledGlobalNames = init.mangledGlobalNames;
  var hasOwnProperty = Object.prototype.hasOwnProperty;
  var length = reflectionData.length;
  for (var i = 0; i < length; i++) {
    var data = reflectionData[i];
'''
// [data] contains these elements:
// 0. The library name (not unique).
// 1. The library URI (unique).
// 2. A function returning the metadata associated with this library.
// 3. The global object to use for this library.
// 4. An object literal listing the members of the library.
// 5. This element is optional and if present it is true and signals that this
// library is the root library (see dart:mirrors IsolateMirror.rootLibrary).
//
// The entries of [data] are built in [assembleProgram] above.
'''
    var name = data[0];
    var uri = data[1];
    var metadata = data[2];
    var globalObject = data[3];
    var descriptor = data[4];
    var isRoot = !!data[5];
    var fields = descriptor && descriptor[""];
    var classes = [];
    var functions = [];
    function processStatics(descriptor) {
      for (var property in descriptor) {
        if (!hasOwnProperty.call(descriptor, property)) continue;
        if (property === "") continue;
        var element = descriptor[property];
        var firstChar = property.substring(0, 1);
        var previousProperty;
        if (firstChar === "+") {
          mangledGlobalNames[previousProperty] = property.substring(1);
          if (descriptor[property] == 1) ''' // Break long line.
'''descriptor[previousProperty].$reflectableField = 1;
          if (element && element.length) ''' // Break long line.
'''init.typeInformation[previousProperty] = element;
        } else if (firstChar === "@") {
          property = property.substring(1);
          ${namer.CURRENT_ISOLATE}[property][$metadataField] = element;
        } else if (firstChar === "*") {
          globalObject[previousProperty].$defaultValuesField = element;
          var optionalMethods = descriptor.$methodsWithOptionalArgumentsField;
          if (!optionalMethods) {
            descriptor.$methodsWithOptionalArgumentsField = optionalMethods = {}
          }
          optionalMethods[property] = previousProperty;
        } else if (typeof element === "function") {
          globalObject[previousProperty = property] = element;
          functions.push(property);
          init.globalFunctions[property] = element;
        } else {
          previousProperty = property;
          var newDesc = {};
          var previousProp;
          for (var prop in element) {
            if (!hasOwnProperty.call(element, prop)) continue;
            firstChar = prop.substring(0, 1);
            if (prop === "static") {
              processStatics(init.statics[property] = element[prop]);
            } else if (firstChar === "+") {
              mangledNames[previousProp] = prop.substring(1);
              if (element[prop] == 1) ''' // Break long line.
'''element[previousProp].$reflectableField = 1;
            } else if (firstChar === "@" && prop !== "@") {
              newDesc[prop.substring(1)][$metadataField] = element[prop];
            } else if (firstChar === "*") {
              newDesc[previousProp].$defaultValuesField = element[prop];
              var optionalMethods = newDesc.$methodsWithOptionalArgumentsField;
              if (!optionalMethods) {
                newDesc.$methodsWithOptionalArgumentsField = optionalMethods={}
              }
              optionalMethods[prop] = previousProp;
            } else {
              newDesc[previousProp = prop] = element[prop];
            }
          }
          $classesCollector[property] = [globalObject, newDesc];
          classes.push(property);
        }
      }
    }
    processStatics(descriptor);
    libraries.push([name, uri, classes, functions, metadata, fields, isRoot,
                    globalObject]);
  }
})''';
}
