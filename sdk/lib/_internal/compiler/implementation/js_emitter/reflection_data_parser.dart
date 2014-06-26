// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

// TODO(ahe): Share these with js_helper.dart.
const FUNCTION_INDEX = 0;
const NAME_INDEX = 1;
const CALL_NAME_INDEX = 2;
const REQUIRED_PARAMETER_INDEX = 3;
const OPTIONAL_PARAMETER_INDEX = 4;
const DEFAULT_ARGUMENTS_INDEX = 5;

const bool VALIDATE_DATA = false;

// TODO(ahe): This code should be integrated in CodeEmitterTask.finishClasses.
jsAst.Expression getReflectionDataParser(String classesCollector,
                                        JavaScriptBackend backend) {
  Namer namer = backend.namer;
  Compiler compiler = backend.compiler;

  String metadataField = '"${namer.metadataField}"';
  String reflectableField = namer.reflectableField;

  // TODO(ahe): Move this string constants to namer.
  String reflectionInfoField = r'$reflectionInfo';
  String reflectionNameField = r'$reflectionName';
  String metadataIndexField = r'$metadataIndex';

  String defaultValuesField = namer.defaultValuesField;
  String methodsWithOptionalArgumentsField =
      namer.methodsWithOptionalArgumentsField;

  String unmangledNameIndex = backend.mustRetainMetadata
      ? ' 3 * optionalParameterCount + 2 * requiredParameterCount + 3'
      : ' 2 * optionalParameterCount + requiredParameterCount + 3';


  String header = '''
// [map] returns an object literal that V8 shouldn not try to optimize with a
// hidden class. This prevents a potential performance problem where V8 tries
// to build a hidden class for an object used as a hashMap.

  function map(x){x={x:x};delete x.x;return x}
''';

  String processStatics = '''
    function processStatics(descriptor) {
      for (var property in descriptor) {
        if (!hasOwnProperty.call(descriptor, property)) continue;
        if (property === "${namer.classDescriptorProperty}") continue;
        var element = descriptor[property];
        var firstChar = property.substring(0, 1);
        var previousProperty;
        if (firstChar === "+") {
          mangledGlobalNames[previousProperty] = property.substring(1);
          var flag = descriptor[property];
          if (flag > 0)
            descriptor[previousProperty].$reflectableField = flag;
          if (element && element.length)
            init.typeInformation[previousProperty] = element;
        } else if (firstChar === "@") {
          property = property.substring(1);
          ${namer.currentIsolate}[property][$metadataField] = element;
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
        } else if (element.constructor === Array) {
          addStubs(globalObject, element, property,
                   true, descriptor, functions);
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
              var flag = element[prop];
              if (flag > 0)
                element[previousProp].$reflectableField = flag;
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
              var elem = element[prop];
              if (prop !== "${namer.classDescriptorProperty}" &&
                  elem != null &&
                  elem.constructor === Array &&
                  prop !== "<>") {
                addStubs(newDesc, elem, prop, false, element, []);
              } else {
                newDesc[previousProp = prop] = elem;
              }
            }
          }
          $classesCollector[property] = [globalObject, newDesc];
          classes.push(property);
        }
      }
    }
''';


  /**
   * See [dart2js.js_emitter.ContainerBuilder.addMemberMethod] for format of
   * [array].
   */
  String addStubs = '''
  function addStubs(descriptor, array, name, isStatic,
                    originalDescriptor, functions) {
    var f, funcs =
        [originalDescriptor[name] =
        descriptor[name] = f = ${readFunction("array", "$FUNCTION_INDEX")}];
    f.\$stubName = name;
    functions.push(name);
    for (var index = $FUNCTION_INDEX; index < array.length; index += 2) {
      f = array[index + 1];
      if (typeof f != "function") break;
      f.\$stubName = ${readString("array", "index + 2")};
      funcs.push(f);
      if (f.\$stubName) {
        originalDescriptor[f.\$stubName] = descriptor[f.\$stubName] = f;
        functions.push(f.\$stubName);
      }
    }
    for (var i = 0; i < funcs.length; index++, i++) {
      funcs[i].\$callName = ${readString("array", "index + 1")};
    }
    var getterStubName = ${readString("array", "++index")};
    array = array.slice(++index);
    var requiredParameterInfo = ${readInt("array", "0")};
    var requiredParameterCount = requiredParameterInfo >> 1;
    var isAccessor = (requiredParameterInfo & 1) === 1;
    var isSetter = requiredParameterInfo === 3;
    var isGetter = requiredParameterInfo === 1;
    var optionalParameterInfo = ${readInt("array", "1")};
    var optionalParameterCount = optionalParameterInfo >> 1;
    var optionalParametersAreNamed = (optionalParameterInfo & 1) === 1;
    var isIntercepted =
           requiredParameterCount + optionalParameterCount != funcs[0].length;
    var functionTypeIndex = ${readFunctionType("array", "2")};
    var unmangledNameIndex = $unmangledNameIndex;
    var isReflectable = array.length > unmangledNameIndex;

    if (getterStubName) {
      f = tearOff(funcs, array, isStatic, name, isIntercepted);
      descriptor[name].\$getter = f;
      f.\$getterStub = true;
      // Used to create an isolate using spawnFunction.
      if (isStatic) init.globalFunctions[name] = f;
      originalDescriptor[getterStubName] = descriptor[getterStubName] = f;
      funcs.push(f);
      if (getterStubName) functions.push(getterStubName);
      f.\$stubName = getterStubName;
      f.\$callName = null;
      if (isIntercepted) init.interceptedNames[getterStubName] = true;
    }
    if (isReflectable) {
      for (var i = 0; i < funcs.length; i++) {
        funcs[i].$reflectableField = 1;
        funcs[i].$reflectionInfoField = array;
      }
      var mangledNames = isStatic ? init.mangledGlobalNames : init.mangledNames;
      var unmangledName = ${readString("array", "unmangledNameIndex")};
      // The function is either a getter, a setter, or a method.
      // If it is a method, it might also have a tear-off closure.
      // The unmangledName is the same as the getter-name.
      var reflectionName = unmangledName;
      if (getterStubName) mangledNames[getterStubName] = reflectionName;
      if (isSetter) {
        reflectionName += "=";
      } else if (!isGetter) {
        reflectionName += ":" + requiredParameterCount +
          ":" + optionalParameterCount;
      }
      mangledNames[name] = reflectionName;
      funcs[0].$reflectionNameField = reflectionName;
      funcs[0].$metadataIndexField = unmangledNameIndex + 1;
      if (optionalParameterCount) descriptor[unmangledName + "*"] = funcs[0];
    }
  }
''';

  List<jsAst.Statement> tearOffCode = buildTearOffCode(backend);

  String init = '''
  var functionCounter = 0;
  var tearOffGetter = (typeof dart_precompiled == "function")
      ? tearOffGetterCsp : tearOffGetterNoCsp;
  if (!init.libraries) init.libraries = [];
  if (!init.mangledNames) init.mangledNames = map();
  if (!init.mangledGlobalNames) init.mangledGlobalNames = map();
  if (!init.statics) init.statics = map();
  if (!init.typeInformation) init.typeInformation = map();
  if (!init.globalFunctions) init.globalFunctions = map();
  if (!init.interceptedNames) init.interceptedNames = map();
  var libraries = init.libraries;
  var mangledNames = init.mangledNames;
  var mangledGlobalNames = init.mangledGlobalNames;
  var hasOwnProperty = Object.prototype.hasOwnProperty;
  var length = reflectionData.length;
  for (var i = 0; i < length; i++) {
    var data = reflectionData[i];

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

    var name = data[0];
    var uri = data[1];
    var metadata = data[2];
    var globalObject = data[3];
    var descriptor = data[4];
    var isRoot = !!data[5];
    var fields = descriptor && descriptor["${namer.classDescriptorProperty}"];
    if (fields instanceof Array) fields = fields[0];
    var classes = [];
    var functions = [];
    processStatics(descriptor);
    libraries.push([name, uri, classes, functions, metadata, fields, isRoot,
                    globalObject]);
  }
''';

  return js('''
(function (reflectionData) {
  "use strict";
  $header
  $processStatics
  $addStubs
  #; // tearOffCode
  $init
})'''  , [tearOffCode]);
}


List<jsAst.Statement> buildTearOffCode(JavaScriptBackend backend) {
  Namer namer = backend.namer;
  Compiler compiler = backend.compiler;

  Element closureFromTearOff = compiler.findHelper('closureFromTearOff');
  String tearOffAccessText;
  jsAst.Expression tearOffAccessExpression;
  String tearOffGlobalObjectName;
  String tearOffGlobalObject;
  if (closureFromTearOff != null) {
    // We need both the AST that references [closureFromTearOff] and a string
    // for the NoCsp version that constructs a function.
    tearOffAccessExpression = namer.elementAccess(closureFromTearOff);
    tearOffAccessText =
        jsAst.prettyPrint(tearOffAccessExpression, compiler).getText();
    tearOffGlobalObjectName = tearOffGlobalObject =
        namer.globalObjectFor(closureFromTearOff);
  } else {
    // Default values for mocked-up test libraries.
    tearOffAccessText =
        r'''function() { throw 'Helper \'closureFromTearOff\' missing.' }''';
    tearOffAccessExpression = js(tearOffAccessText);
    tearOffGlobalObjectName = 'MissingHelperFunction';
    tearOffGlobalObject = '($tearOffAccessText())';
  }

  // This template is uncached because it is constructed from code fragments
  // that can change from compilation to compilation.  Some of these could be
  // avoided, except for the string literals that contain the compiled access
  // path to 'closureFromTearOff'.
  jsAst.Statement tearOffGetterNoCsp = js.uncachedStatementTemplate('''
    function tearOffGetterNoCsp(funcs, reflectionInfo, name, isIntercepted) {
      return isIntercepted
          ? new Function("funcs", "reflectionInfo", "name",
                         "$tearOffGlobalObjectName", "c",
              "return function tearOff_" + name + (functionCounter++)+ "(x) {" +
                "if (c === null) c = $tearOffAccessText(" +
                    "this, funcs, reflectionInfo, false, [x], name);" +
                "return new c(this, funcs[0], x, name);" +
              "}")(funcs, reflectionInfo, name, $tearOffGlobalObject, null)
          : new Function("funcs", "reflectionInfo", "name",
                         "$tearOffGlobalObjectName", "c",
              "return function tearOff_" + name + (functionCounter++)+ "() {" +
                "if (c === null) c = $tearOffAccessText(" +
                    "this, funcs, reflectionInfo, false, [], name);" +
                "return new c(this, funcs[0], null, name);" +
              "}")(funcs, reflectionInfo, name, $tearOffGlobalObject, null);
    }''').instantiate([]);

  jsAst.Statement tearOffGetterCsp = js.statement('''
    function tearOffGetterCsp(funcs, reflectionInfo, name, isIntercepted) {
      var cache = null;
      return isIntercepted
          ? function(x) {
              if (cache === null) cache = #(
                  this, funcs, reflectionInfo, false, [x], name);
              return new cache(this, funcs[0], x, name);
            }
          : function() {
              if (cache === null) cache = #(
                  this, funcs, reflectionInfo, false, [], name);
              return new cache(this, funcs[0], null, name);
            };
    }''', [tearOffAccessExpression, tearOffAccessExpression]);

  jsAst.Statement tearOff = js.statement('''
    function tearOff(funcs, reflectionInfo, isStatic, name, isIntercepted) {
      var cache;
      return isStatic
          ? function() {
              if (cache === void 0) cache = #(
                  this, funcs, reflectionInfo, true, [], name).prototype;
              return cache;
            }
          : tearOffGetter(funcs, reflectionInfo, name, isIntercepted);
    }''', tearOffAccessExpression);

  return <jsAst.Statement>[tearOffGetterNoCsp, tearOffGetterCsp, tearOff];
}


String readString(String array, String index) {
  return readChecked(
      array, index, 'result != null && typeof result != "string"', 'string');
}

String readInt(String array, String index) {
  return readChecked(
      array, index,
      'result != null && (typeof result != "number" || (result|0) !== result)',
      'int');
}

String readFunction(String array, String index) {
  return readChecked(
      array, index, 'result != null && typeof result != "function"',
      'function');
}

String readFunctionType(String array, String index) {
  return readChecked(
      array, index,
      'result != null && '
      '(typeof result != "number" || (result|0) !== result) && '
      'typeof result != "function"',
      'function or int');
}

String readChecked(String array, String index, String check, String type) {
  if (!VALIDATE_DATA) return '$array[$index]';
  return '''
(function() {
  var result = $array[$index];
  if ($check) {
    throw new Error(
        name + ": expected value of type \'$type\' at index " + ($index) +
        " but got " + (typeof result));
  }
  return result;
})()''';
}
