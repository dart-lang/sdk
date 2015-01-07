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

// TODO(zarah): Rename this when renaming this file.
String get parseReflectionDataName => 'parseReflectionData';

jsAst.Expression getReflectionDataParser(OldEmitter oldEmitter,
                                         JavaScriptBackend backend) {
  Namer namer = backend.namer;
  Compiler compiler = backend.compiler;
  CodeEmitterTask emitter = backend.emitter;

  String metadataField = '"${namer.metadataField}"';
  String reflectableField = namer.reflectableField;
  String reflectionInfoField = namer.reflectionInfoField;
  String reflectionNameField = namer.reflectionNameField;
  String metadataIndexField = namer.metadataIndexField;
  String defaultValuesField = namer.defaultValuesField;
  String methodsWithOptionalArgumentsField =
      namer.methodsWithOptionalArgumentsField;

  String unmangledNameIndex = backend.mustRetainMetadata
      ? ' 3 * optionalParameterCount + 2 * requiredParameterCount + 3'
      : ' 2 * optionalParameterCount + requiredParameterCount + 3';

  jsAst.Expression typeInformationAccess =
      emitter.generateEmbeddedGlobalAccess(embeddedNames.TYPE_INFORMATION);
  jsAst.Expression globalFunctionsAccess =
      emitter.generateEmbeddedGlobalAccess(embeddedNames.GLOBAL_FUNCTIONS);
  jsAst.Expression staticsAccess =
      emitter.generateEmbeddedGlobalAccess(embeddedNames.STATICS);
  jsAst.Expression interceptedNamesAccess =
      emitter.generateEmbeddedGlobalAccess(embeddedNames.INTERCEPTED_NAMES);
  jsAst.Expression mangledGlobalNamesAccess =
      emitter.generateEmbeddedGlobalAccess(embeddedNames.MANGLED_GLOBAL_NAMES);
  jsAst.Expression mangledNamesAccess =
      emitter.generateEmbeddedGlobalAccess(embeddedNames.MANGLED_NAMES);
  jsAst.Expression librariesAccess =
      emitter.generateEmbeddedGlobalAccess(embeddedNames.LIBRARIES);
  jsAst.Expression metadataAccess =
      emitter.generateEmbeddedGlobalAccess(embeddedNames.METADATA);

  jsAst.Statement processClassData = js.statement('''{
  function processClassData(cls, descriptor, processedClasses) {
    var newDesc = {};
    var previousProperty;
    for (var property in descriptor) {
      if (!hasOwnProperty.call(descriptor, property)) continue;
      var firstChar = property.substring(0, 1);
      if (property === "static") {
        processStatics(#embeddedStatics[cls] = descriptor[property], 
                       processedClasses);
      } else if (firstChar === "+") {
        mangledNames[previousProperty] = property.substring(1);
        var flag = descriptor[property];
        if (flag > 0)
          descriptor[previousProperty].$reflectableField = flag;
      } else if (firstChar === "@" && property !== "@") {
        newDesc[property.substring(1)][$metadataField] = descriptor[property];
      } else if (firstChar === "*") {
        newDesc[previousProperty].$defaultValuesField = descriptor[property];
        var optionalMethods = newDesc.$methodsWithOptionalArgumentsField;
        if (!optionalMethods) {
          newDesc.$methodsWithOptionalArgumentsField = optionalMethods={}
        }
        optionalMethods[property] = previousProperty;
      } else {
        var elem = descriptor[property];
        if (property !== "${namer.classDescriptorProperty}" &&
            elem != null &&
            elem.constructor === Array &&
            property !== "<>") {
          addStubs(newDesc, elem, property, false, descriptor, []);
        } else {
          newDesc[previousProperty = property] = elem;
        }
      }
    }

    /* The 'fields' are either a constructor function or a
     * string encoding fields, constructor and superclass. Gets the
     * superclass and fields in the format
     *   'Super;field1,field2'
     * from the CLASS_DESCRIPTOR_PROPERTY property on the descriptor.
     */
    var classData = newDesc["${namer.classDescriptorProperty}"],
        split, supr, fields = classData;

    if (#hasRetainedMetadata)
      if (typeof classData == "object" &&
          classData instanceof Array) {
        classData = fields = classData[0];
      }
    // ${ClassBuilder.fieldEncodingDescription}.
    var s = fields.split(";");
    fields = s[1] == "" ? [] : s[1].split(",");
    supr = s[0];
    // ${ClassBuilder.functionTypeEncodingDescription}.
    split = supr.split(":");
    if (split.length == 2) {
      supr = split[0];
      var functionSignature = split[1];
      if (functionSignature)
        newDesc.${namer.operatorSignature} = function(s) {
          return function() {
            return #metadata[s];
          };
        }(functionSignature);
    }

    if (supr) processedClasses.pending[cls] = supr;
    if (#notInCspMode) {
      processedClasses.combinedConstructorFunction += defineClass(cls, fields);
      processedClasses.constructorsList.push(cls);
    }
    processedClasses.collected[cls] = [globalObject, newDesc];
    classes.push(cls);
  }
}''', {'embeddedStatics': staticsAccess,
       'hasRetainedMetadata': backend.hasRetainedMetadata,
       'metadata': metadataAccess,
       'notInCspMode': !compiler.useContentSecurityPolicy});

  // TODO(zarah): Remove empty else branches in output when if(#hole) is false.
  jsAst.Statement processStatics = js.statement('''
    function processStatics(descriptor, processedClasses) {
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
            #typeInformation[previousProperty] = element;
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
          #globalFunctions[property] = element;
        } else if (element.constructor === Array) {
          if (#needsArrayInitializerSupport) {
            addStubs(globalObject, element, property,
                     true, descriptor, functions);
          }
        } else {
          // We will not enter this case if no classes are defined.
          if (#hasClasses) {
            previousProperty = property;
            processClassData(property, element, processedClasses);
          }
        }
      }
    }
''', {'typeInformation': typeInformationAccess,
      'globalFunctions': globalFunctionsAccess,
      'hasClasses': oldEmitter.needsClassSupport,
      'needsArrayInitializerSupport': oldEmitter.needsArrayInitializerSupport});


  /**
   * See [dart2js.js_emitter.ContainerBuilder.addMemberMethod] for format of
   * [array].
   */
  jsAst.Statement addStubs = js.statement('''
  function addStubs(descriptor, array, name, isStatic,
                    originalDescriptor, functions) {
    var index = $FUNCTION_INDEX, alias = array[index], f;
    if (typeof alias == "string") {
      f = array[++index];
    } else {
      f = alias;
      alias = name;
    }
    var funcs = [originalDescriptor[name] = descriptor[name] =
        descriptor[alias] = f];
    f.\$stubName = name;
    functions.push(name);
    for (; index < array.length; index += 2) {
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

    if (getterStubName) {
      f = tearOff(funcs, array, isStatic, name, isIntercepted);
      descriptor[name].\$getter = f;
      f.\$getterStub = true;
      // Used to create an isolate using spawnFunction.
      if (isStatic) #globalFunctions[name] = f;
      originalDescriptor[getterStubName] = descriptor[getterStubName] = f;
      funcs.push(f);
      if (getterStubName) functions.push(getterStubName);
      f.\$stubName = getterStubName;
      f.\$callName = null;
      if (isIntercepted) #interceptedNames[getterStubName] = true;
    }

    if (#usesMangledNames) {
      var isReflectable = array.length > unmangledNameIndex;
      if (isReflectable) {
        for (var i = 0; i < funcs.length; i++) {
          funcs[i].$reflectableField = 1;
          funcs[i].$reflectionInfoField = array;
        }
        var mangledNames = isStatic ? #mangledGlobalNames : #mangledNames;
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
  }
''', {'globalFunctions' : globalFunctionsAccess,
      'interceptedNames': interceptedNamesAccess,
      'usesMangledNames':
          compiler.mirrorsLibrary != null || compiler.enabledFunctionApply,
      'mangledGlobalNames': mangledGlobalNamesAccess,
      'mangledNames': mangledNamesAccess});

  List<jsAst.Statement> tearOffCode = buildTearOffCode(backend);

  jsAst.Statement init = js.statement('''{
  var functionCounter = 0;
  if (!#libraries) #libraries = [];
  if (!#mangledNames) #mangledNames = map();
  if (!#mangledGlobalNames) #mangledGlobalNames = map();
  if (!#statics) #statics = map();
  if (!#typeInformation) #typeInformation = map(); 
  if (!#globalFunctions) #globalFunctions = map();
  if (!#interceptedNames) #interceptedNames = map();
  var libraries = #libraries;
  var mangledNames = #mangledNames;
  var mangledGlobalNames = #mangledGlobalNames;
  var hasOwnProperty = Object.prototype.hasOwnProperty;
  var length = reflectionData.length;
  var processedClasses = Object.create(null);
  processedClasses.collected = Object.create(null);
  processedClasses.pending = Object.create(null);
  if (#notInCspMode) {
    processedClasses.constructorsList = [];
    // For every class processed [processedClasses.combinedConstructorFunction]
    // will be updated with the corresponding constructor function. 
    processedClasses.combinedConstructorFunction =
        "function \$reflectable(fn){fn.$reflectableField=1;return fn};\\n"+
        "var \$desc;\\n";
  }
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
    processStatics(descriptor, processedClasses);
    libraries.push([name, uri, classes, functions, metadata, fields, isRoot,
                    globalObject]);
  }
    if (#needsClassSupport) finishClasses(processedClasses);
}''', {'libraries': librariesAccess,
       'mangledNames': mangledNamesAccess,
       'mangledGlobalNames': mangledGlobalNamesAccess,
       'statics': staticsAccess,
       'typeInformation': typeInformationAccess,
       'globalFunctions': globalFunctionsAccess,
       'interceptedNames': interceptedNamesAccess,
       'notInCspMode': !compiler.useContentSecurityPolicy,
       'needsClassSupport': oldEmitter.needsClassSupport});

  jsAst.Expression allClassesAccess =
      emitter.generateEmbeddedGlobalAccess(embeddedNames.ALL_CLASSES);

  String specProperty = '"${namer.nativeSpecProperty}"';  // "%"

  // Class descriptions are collected in a JS object.
  // 'finishClasses' takes all collected descriptions and sets up
  // the prototype.
  // Once set up, the constructors prototype field satisfy:
  //  - it contains all (local) members.
  //  - its internal prototype (__proto__) points to the superclass'
  //    prototype field.
  //  - the prototype's constructor field points to the JavaScript
  //    constructor.
  // For engines where we have access to the '__proto__' we can manipulate
  // the object literal directly. For other engines we have to create a new
  // object and copy over the members.
  jsAst.Statement finishClasses = js.statement('''{
  function finishClasses(processedClasses) {
    if (#debugFastObjects)
      print("Number of classes: " +
            Object.getOwnPropertyNames(processedClasses.collected).length);

    var allClasses = #allClasses;

    if (#inCspMode) {
      var constructors = dart_precompiled(processedClasses.collected);
    }

    if (#notInCspMode) {
      processedClasses.combinedConstructorFunction +=
        "return [\\n" + processedClasses.constructorsList.join(",\\n  ") + 
        "\\n]";
     var constructors =
       new Function("\$collectedClasses", 
           processedClasses.combinedConstructorFunction)
               (processedClasses.collected);
      processedClasses.combinedConstructorFunction = null;
    }

    for (var i = 0; i < constructors.length; i++) {
      var constructor = constructors[i];
      var cls = constructor.name;
      var desc = processedClasses.collected[cls];
      var globalObject = \$;
      if (desc instanceof Array) {
        globalObject = desc[0] || \$;
        desc = desc[1];
      }
      if (#isTreeShakingDisabled)
        constructor["${namer.metadataField}"] = desc;
      allClasses[cls] = constructor;
      globalObject[cls] = constructor;
    }
    constructors = null;

    #finishClassFunction;

    #trivialNsmHandlers;

    for (var cls in processedClasses.pending) finishClass(cls);
  }
}''', {'allClasses': allClassesAccess,
       'debugFastObjects': DEBUG_FAST_OBJECTS,
       'isTreeShakingDisabled': backend.isTreeShakingDisabled,
       'finishClassFunction': oldEmitter.buildFinishClass(),
       'trivialNsmHandlers': oldEmitter.buildTrivialNsmHandlers(),
       'inCspMode': compiler.useContentSecurityPolicy,
       'notInCspMode': !compiler.useContentSecurityPolicy});

  List<jsAst.Statement> incrementalSupport = <jsAst.Statement>[];
  if (compiler.hasIncrementalSupport) {
    incrementalSupport.add(
        js.statement(
            r'self.$dart_unsafe_eval.addStubs = addStubs;'));
  }

  return js('''
function $parseReflectionDataName(reflectionData) {
  "use strict";
  if (#needsClassSupport) {
    #defineClass;
    #inheritFrom;
    #finishClasses;
    #processClassData;
  }
  #processStatics;
  if (#needsArrayInitializerSupport) {
    #addStubs;
    #tearOffCode;
  }
  #incrementalSupport;
  #init;
}''', {
      'defineClass': oldEmitter.defineClassFunction,
      'inheritFrom': oldEmitter.buildInheritFrom(),
      'processClassData': processClassData,
      'processStatics': processStatics,
      'incrementalSupport': incrementalSupport,
      'addStubs': addStubs,
      'tearOffCode': tearOffCode,
      'init': init,
      'finishClasses': finishClasses,
      'needsClassSupport': oldEmitter.needsClassSupport,
      'needsArrayInitializerSupport': oldEmitter.needsArrayInitializerSupport});
}


List<jsAst.Statement> buildTearOffCode(JavaScriptBackend backend) {
  Namer namer = backend.namer;
  Compiler compiler = backend.compiler;

  Element closureFromTearOff = backend.findHelper('closureFromTearOff');
  String tearOffAccessText;
  jsAst.Expression tearOffAccessExpression;
  String tearOffGlobalObjectName;
  String tearOffGlobalObject;
  if (closureFromTearOff != null) {
    // We need both the AST that references [closureFromTearOff] and a string
    // for the NoCsp version that constructs a function.
    tearOffAccessExpression =
        backend.emitter.staticFunctionAccess(closureFromTearOff);
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

  jsAst.Statement tearOffGetter;
  if (!compiler.useContentSecurityPolicy) {
    // This template is uncached because it is constructed from code fragments
    // that can change from compilation to compilation.  Some of these could be
    // avoided, except for the string literals that contain the compiled access
    // path to 'closureFromTearOff'.
    tearOffGetter = js.uncachedStatementTemplate('''
        function tearOffGetter(funcs, reflectionInfo, name, isIntercepted) {
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
  } else {
    tearOffGetter = js.statement('''
        function tearOffGetter(funcs, reflectionInfo, name, isIntercepted) {
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
  }

  jsAst.Statement tearOff = js.statement('''
    function tearOff(funcs, reflectionInfo, isStatic, name, isIntercepted) {
      var cache;
      return isStatic
          ? function() {
              if (cache === void 0) cache = #tearOff(
                  this, funcs, reflectionInfo, true, [], name).prototype;
              return cache;
            }
          : tearOffGetter(funcs, reflectionInfo, name, isIntercepted);
    }''',  {'tearOff': tearOffAccessExpression});

  return <jsAst.Statement>[tearOffGetter, tearOff];
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
