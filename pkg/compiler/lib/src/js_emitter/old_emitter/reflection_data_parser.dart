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

jsAst.Statement getReflectionDataParser(OldEmitter oldEmitter,
                                        JavaScriptBackend backend,
                                        bool needsNativeSupport) {
  Namer namer = backend.namer;
  Compiler compiler = backend.compiler;
  CodeEmitterTask emitter = backend.emitter;

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
  jsAst.Expression typesAccess =
      emitter.generateEmbeddedGlobalAccess(embeddedNames.TYPES);


  jsAst.Statement processClassData = js.statement('''{
  // For convenience, this method can be called with a prototype as argument
  // or, if it was bound to an object, by invoking it as a method. Therefore, 
  // if prototype is undefined, this is used as prototype.
  function finishAddStubsHelper(prototype) {
    var prototype = prototype || this;
    var object;
    while (prototype.#deferredAction != #markerFun) {
      if (prototype.hasOwnProperty(#deferredActionString)) {
        delete prototype.#deferredAction; // Intended to make it slow, too.
        var properties = Object.keys(prototype);
        for (var index = 0; index < properties.length; index++) {
          var property = properties[index];
          var firstChar = property.charCodeAt(0);
          var elem;
          // We have to filter out some special properties that are used for
          // metadata in descriptors. Currently, we filter everything that 
          // starts with + or *. This has to stay in sync with the special
          // properties that are used by processClassData below.
          if (property !== "${namer.classDescriptorProperty}" &&
              property !== "$reflectableField" &&
              firstChar !== 43 && // 43 is aka "+".
              firstChar !== 42 && // 42 is aka "*"
              (elem = prototype[property]) != null &&
              elem.constructor === Array &&
              property !== "<>") {
            addStubs(prototype, elem, property, false, []);
          }
        }
        convertToFastObject(prototype);
      }
      prototype = prototype.__proto__;
    }
  }

  function processClassData(cls, descriptor, processedClasses) {
    descriptor = convertToSlowObject(descriptor); // Use a slow object.
    var previousProperty;
    var properties = Object.keys(descriptor);
    var hasDeferredWork = false;
    var shouldDeferWork = supportsDirectProtoAccess && cls != #objectClassName;
    for (var i = 0; i < properties.length; i++) {
      var property = properties[i];
      var firstChar = property.charCodeAt(0);
      if (property === "static") {
        processStatics(#embeddedStatics[cls] = descriptor.static,
                       processedClasses);
        delete descriptor.static;
      } else if (firstChar === 43) { // 43 is "+".
        mangledNames[previousProperty] = property.substring(1);
        var flag = descriptor[property];
        if (flag > 0)
          descriptor[previousProperty].$reflectableField = flag;
      } else if (firstChar === 42) { // 42 is "*"
        descriptor[previousProperty].$defaultValuesField = descriptor[property];
        var optionalMethods = descriptor.$methodsWithOptionalArgumentsField;
        if (!optionalMethods) {
          descriptor.$methodsWithOptionalArgumentsField = optionalMethods={}
        }
        optionalMethods[property] = previousProperty;
      } else {
        var elem = descriptor[property];
        if (property !== "${namer.classDescriptorProperty}" &&
            elem != null &&
            elem.constructor === Array &&
            property !== "<>") {
          if (shouldDeferWork) {
            hasDeferredWork = true;
          } else {
            addStubs(descriptor, elem, property, false, []);
          }
        } else {
          previousProperty = property;
        }
      }
    }
    
    if (hasDeferredWork)
      descriptor.#deferredAction = finishAddStubsHelper;

    /* The 'fields' are either a constructor function or a
     * string encoding fields, constructor and superclass. Gets the
     * superclass and fields in the format
     *   'Super;field1,field2'
     * from the CLASS_DESCRIPTOR_PROPERTY property on the descriptor.
     */
    var classData = descriptor["${namer.classDescriptorProperty}"],
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
        descriptor.${namer.operatorSignature} = function(s) {
          return function() {
            return #types[s];
          };
        }(functionSignature);
    }

    if (supr) processedClasses.pending[cls] = supr;
    if (#notInCspMode) {
      processedClasses.combinedConstructorFunction += defineClass(cls, fields);
      processedClasses.constructorsList.push(cls);
    }
    processedClasses.collected[cls] = [globalObject, descriptor];
    classes.push(cls);
  }
}''', {'deferredAction': namer.deferredAction,
       'deferredActionString': js.string(namer.deferredAction),
       'embeddedStatics': staticsAccess,
       'hasRetainedMetadata': backend.hasRetainedMetadata,
       'markerFun': oldEmitter.markerFun,
       'types': typesAccess,
       'notInCspMode': !compiler.useContentSecurityPolicy,
       'objectClassName':
         js.string(namer.runtimeTypeName(compiler.objectClass))});

  // TODO(zarah): Remove empty else branches in output when if(#hole) is false.
  jsAst.Statement processStatics = js.statement('''
    function processStatics(descriptor, processedClasses) {
      var properties = Object.keys(descriptor);
      for (var i = 0; i < properties.length; i++) {
        var property = properties[i];
        if (property === "${namer.classDescriptorProperty}") continue;
        var element = descriptor[property];
        var firstChar = property.charCodeAt(0);
        var previousProperty;
        if (firstChar === 43) { // 43 is "+".
          mangledGlobalNames[previousProperty] = property.substring(1);
          var flag = descriptor[property];
          if (flag > 0)
            descriptor[previousProperty].$reflectableField = flag;
          if (element && element.length)
            #typeInformation[previousProperty] = element;
        } else if (firstChar === 42) { // 42 is "*"
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
          if (#needsStructuredMemberInfo) {
            addStubs(globalObject, element, property, true, functions);
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
      'needsStructuredMemberInfo': oldEmitter.needsStructuredMemberInfo});


  /**
   * See [dart2js.js_emitter.ContainerBuilder.addMemberMethod] for format of
   * [array].
   */
  jsAst.Statement addStubs = js.statement('''
  // Processes the stub declaration given by [array] and stores the results
  // in the corresponding [prototype]. [name] is the property name in
  // [prototype] that the stub declaration belongs to.
  // If [isStatic] is true, the property being processed belongs to a static 
  // function and thus is stored as a global. In that case we also add all
  // generated functions to the [functions] array, which is used by the mirrors
  // system to enumerate all static functions of a library. For non-static
  // functions we might still add some functions to [functions] but the
  // information is thrown away at the call site. This is to avoid conditionals. 
  function addStubs(prototype, array, name, isStatic, functions) {
    var index = $FUNCTION_INDEX, alias = array[index], f;
    if (typeof alias == "string") {
      f = array[++index];
    } else {
      f = alias;
      alias = name;
    }
    var funcs = [prototype[name] = prototype[alias] = f];
    f.\$stubName = name;
    functions.push(name);
    for (; index < array.length; index += 2) {
      f = array[index + 1];
      if (typeof f != "function") break;
      f.\$stubName = ${readString("array", "index + 2")};
      funcs.push(f);
      if (f.\$stubName) {
        prototype[f.\$stubName] = f;
        functions.push(f.\$stubName);
      }
    }
    index++;
    for (var i = 0; i < funcs.length; index++, i++) {
      funcs[i].\$callName = ${readString("array", "index")};
    }
    var getterStubName = ${readString("array", "index")};
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
      prototype[name].\$getter = f;
      f.\$getterStub = true;
      // Used to create an isolate using spawnFunction.
      if (isStatic) {
        #globalFunctions[name] = f;
        functions.push(getterStubName);
      }
      prototype[getterStubName] = f;
      funcs.push(f);
      f.\$stubName = getterStubName;
      f.\$callName = null;
      // Update the interceptedNames map (which only exists if `invokeOn` was
      // enabled).
      if (#enabledInvokeOn)
        if (isIntercepted) #interceptedNames[getterStubName] = 1;
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
        if (optionalParameterCount) prototype[unmangledName + "*"] = funcs[0];
      }
    }
  }
''', {'globalFunctions': globalFunctionsAccess,
      'enabledInvokeOn': compiler.enabledInvokeOn,
      'interceptedNames': interceptedNamesAccess,
      'usesMangledNames':
          compiler.mirrorsLibrary != null || compiler.enabledFunctionApply,
      'mangledGlobalNames': mangledGlobalNamesAccess,
      'mangledNames': mangledNamesAccess});

  List<jsAst.Statement> tearOffCode = buildTearOffCode(backend);

  jsAst.ObjectInitializer interceptedNamesSet =
      oldEmitter.interceptorEmitter.generateInterceptedNamesSet();

  jsAst.Statement init = js.statement('''{
  var functionCounter = 0;
  if (!#libraries) #libraries = [];
  if (!#mangledNames) #mangledNames = map();
  if (!#mangledGlobalNames) #mangledGlobalNames = map();
  if (!#statics) #statics = map();
  if (!#typeInformation) #typeInformation = map(); 
  if (!#globalFunctions) #globalFunctions = map();
  if (#enabledInvokeOn)
    if (!#interceptedNames) #interceptedNames = #interceptedNamesSet;
  var libraries = #libraries;
  var mangledNames = #mangledNames;
  var mangledGlobalNames = #mangledGlobalNames;
  var hasOwnProperty = Object.prototype.hasOwnProperty;
  var length = reflectionData.length;
  var processedClasses = map();
  processedClasses.collected = map();
  processedClasses.pending = map();
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
       'enabledInvokeOn': compiler.enabledInvokeOn,
       'interceptedNames': interceptedNamesAccess,
       'interceptedNamesSet': interceptedNamesSet,
       'notInCspMode': !compiler.useContentSecurityPolicy,
       'needsClassSupport': oldEmitter.needsClassSupport});

  jsAst.Expression allClassesAccess =
      emitter.generateEmbeddedGlobalAccess(embeddedNames.ALL_CLASSES);

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
      var constructors = #precompiled(processedClasses.collected);
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

    var properties = Object.keys(processedClasses.pending);
    for (var i = 0; i < properties.length; i++) finishClass(properties[i]);
  }
}''', {'allClasses': allClassesAccess,
       'debugFastObjects': DEBUG_FAST_OBJECTS,
       'isTreeShakingDisabled': backend.isTreeShakingDisabled,
       'finishClassFunction': oldEmitter.buildFinishClass(needsNativeSupport),
       'trivialNsmHandlers': oldEmitter.buildTrivialNsmHandlers(),
       'inCspMode': compiler.useContentSecurityPolicy,
       'notInCspMode': !compiler.useContentSecurityPolicy,
       'precompiled': oldEmitter
           .generateEmbeddedGlobalAccess(embeddedNames.PRECOMPILED)});

  List<jsAst.Statement> incrementalSupport = <jsAst.Statement>[];
  if (compiler.hasIncrementalSupport) {
    incrementalSupport.add(
        js.statement(
            '#.addStubs = addStubs;', [namer.accessIncrementalHelper]));
  }

  return js.statement('''
function $parseReflectionDataName(reflectionData) {
  "use strict";
  if (#needsClassSupport) {
    #defineClass;
    #inheritFrom;
    #finishClasses;
    #processClassData;
  }
  #processStatics;
  if (#needsStructuredMemberInfo) {
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
      'needsStructuredMemberInfo': oldEmitter.needsStructuredMemberInfo});
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
