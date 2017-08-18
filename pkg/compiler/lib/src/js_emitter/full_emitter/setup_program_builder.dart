// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter.full_emitter;

// TODO(ahe): Share these with js_helper.dart.
const FUNCTION_INDEX = 0;
const NAME_INDEX = 1;
const CALL_NAME_INDEX = 2;
const REQUIRED_PARAMETER_INDEX = 3;
const OPTIONAL_PARAMETER_INDEX = 4;
const DEFAULT_ARGUMENTS_INDEX = 5;

const bool VALIDATE_DATA = false;

const RANGE1_SIZE = RANGE1_LAST - RANGE1_FIRST + 1;
const RANGE2_SIZE = RANGE2_LAST - RANGE2_FIRST + 1;
const RANGE1_ADJUST = -(FIRST_FIELD_CODE - RANGE1_FIRST);
const RANGE2_ADJUST = -(FIRST_FIELD_CODE + RANGE1_SIZE - RANGE2_FIRST);
const RANGE3_ADJUST =
    -(FIRST_FIELD_CODE + RANGE1_SIZE + RANGE2_SIZE - RANGE3_FIRST);

const String setupProgramName = 'setupProgram';
// TODO(floitsch): make sure this property can't clash with anything. It's
//   unlikely since it lives on types, but still.
const String typeNameProperty = r'builtin$cls';

jsAst.Statement buildSetupProgram(
    Program program,
    Compiler compiler,
    JavaScriptBackend backend,
    Namer namer,
    Emitter emitter,
    ClosedWorld closedWorld) {
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
  jsAst.Expression createNewIsolateFunctionAccess =
      emitter.generateEmbeddedGlobalAccess(embeddedNames.CREATE_NEW_ISOLATE);
  jsAst.Expression classIdExtractorAccess =
      emitter.generateEmbeddedGlobalAccess(embeddedNames.CLASS_ID_EXTRACTOR);
  jsAst.Expression allClassesAccess =
      emitter.generateEmbeddedGlobalAccess(embeddedNames.ALL_CLASSES);
  jsAst.Expression precompiledAccess =
      emitter.generateEmbeddedGlobalAccess(embeddedNames.PRECOMPILED);
  jsAst.Expression finishedClassesAccess =
      emitter.generateEmbeddedGlobalAccess(embeddedNames.FINISHED_CLASSES);
  jsAst.Expression interceptorsByTagAccess =
      emitter.generateEmbeddedGlobalAccess(embeddedNames.INTERCEPTORS_BY_TAG);
  jsAst.Expression leafTagsAccess =
      emitter.generateEmbeddedGlobalAccess(embeddedNames.LEAF_TAGS);
  jsAst.Expression initializeEmptyInstanceAccess = emitter
      .generateEmbeddedGlobalAccess(embeddedNames.INITIALIZE_EMPTY_INSTANCE);
  jsAst.Expression classFieldsExtractorAccess = emitter
      .generateEmbeddedGlobalAccess(embeddedNames.CLASS_FIELDS_EXTRACTOR);
  jsAst.Expression instanceFromClassIdAccess = emitter
      .generateEmbeddedGlobalAccess(embeddedNames.INSTANCE_FROM_CLASS_ID);

  String reflectableField = namer.reflectableField;
  String reflectionInfoField = namer.reflectionInfoField;
  String reflectionNameField = namer.reflectionNameField;
  String metadataIndexField = namer.metadataIndexField;
  String defaultValuesField = namer.defaultValuesField;
  String methodsWithOptionalArgumentsField =
      namer.methodsWithOptionalArgumentsField;
  String unmangledNameIndex = backend.mirrorsData.mustRetainMetadata
      ? ' 3 * optionalParameterCount + 2 * requiredParameterCount + 3'
      : ' 2 * optionalParameterCount + requiredParameterCount + 3';
  String receiverParamName =
      compiler.options.enableMinification ? "r" : "receiver";
  String valueParamName = compiler.options.enableMinification ? "v" : "value";
  String space = compiler.options.enableMinification ? "" : " ";
  String _ = space;

  String specProperty = '"${namer.nativeSpecProperty}"'; // "%"
  jsAst.Expression nativeInfoAccess = js('prototype[$specProperty]', []);
  jsAst.Expression constructorAccess = js('constructor', []);
  Function subclassReadGenerator =
      (jsAst.Expression subclass) => js('allClasses[#]', subclass);
  jsAst.Statement nativeInfoHandler = emitter.buildNativeInfoHandler(
      nativeInfoAccess,
      constructorAccess,
      subclassReadGenerator,
      interceptorsByTagAccess,
      leafTagsAccess);

  Map<String, dynamic> holes = {
    'needsClassSupport': emitter.needsClassSupport,
    'libraries': librariesAccess,
    'mangledNames': mangledNamesAccess,
    'mangledGlobalNames': mangledGlobalNamesAccess,
    'statics': staticsAccess,
    'staticsPropertyName': namer.staticsPropertyName,
    'staticsPropertyNameString': js.quoteName(namer.staticsPropertyName),
    'typeInformation': typeInformationAccess,
    'globalFunctions': globalFunctionsAccess,
    'enabledInvokeOn': closedWorld.backendUsage.isInvokeOnUsed,
    'interceptedNames': interceptedNamesAccess,
    'interceptedNamesSet': emitter.generateInterceptedNamesSet(),
    'notInCspMode': !compiler.options.useContentSecurityPolicy,
    'inCspMode': compiler.options.useContentSecurityPolicy,
    'deferredAction': namer.deferredAction,
    'hasIsolateSupport': program.hasIsolateSupport,
    'fieldNamesProperty': js.string(Emitter.FIELD_NAMES_PROPERTY_NAME),
    'createNewIsolateFunction': createNewIsolateFunctionAccess,
    'isolateName': namer.isolateName,
    'classIdExtractor': classIdExtractorAccess,
    'classFieldsExtractor': classFieldsExtractorAccess,
    'instanceFromClassId': instanceFromClassIdAccess,
    'initializeEmptyInstance': initializeEmptyInstanceAccess,
    'allClasses': allClassesAccess,
    'debugFastObjects': DEBUG_FAST_OBJECTS,
    'isTreeShakingDisabled': backend.mirrorsData.isTreeShakingDisabled,
    'precompiled': precompiledAccess,
    'finishedClassesAccess': finishedClassesAccess,
    'needsMixinSupport': emitter.needsMixinSupport,
    'needsNativeSupport': program.needsNativeSupport,
    'enabledJsInterop': closedWorld.nativeData.isJsInteropUsed,
    'jsInteropBoostrap': backend.jsInteropAnalysis.buildJsInteropBootstrap(),
    'isInterceptorClass':
        namer.operatorIs(closedWorld.commonElements.jsInterceptorClass),
    'isObject': namer.operatorIs(closedWorld.commonElements.objectClass),
    'specProperty': js.string(namer.nativeSpecProperty),
    'trivialNsmHandlers': emitter.buildTrivialNsmHandlers(),
    'hasRetainedMetadata': backend.mirrorsData.hasRetainedMetadata,
    'types': typesAccess,
    'objectClassName': js.quoteName(
        namer.runtimeTypeName(closedWorld.commonElements.objectClass)),
    'needsStructuredMemberInfo': emitter.needsStructuredMemberInfo,
    'usesMangledNames': closedWorld.backendUsage.isMirrorsUsed ||
        closedWorld.backendUsage.isFunctionApplyUsed,
    'tearOffCode': buildTearOffCode(
        compiler.options, emitter, namer, closedWorld.commonElements),
    'nativeInfoHandler': nativeInfoHandler,
    'operatorIsPrefix': js.string(namer.operatorIsPrefix),
    'deferredActionString': js.string(namer.deferredAction)
  };
  String skeleton = '''
function $setupProgramName(programData, typesOffset) {
  "use strict";
  if (#needsClassSupport) {

    function generateAccessor(fieldDescriptor, accessors, cls) {
      var fieldInformation = fieldDescriptor.split("-");
      var field = fieldInformation[0];
      var len = field.length;
      var code = field.charCodeAt(len - 1);
      var reflectable;
      if (fieldInformation.length > 1) reflectable = true;
           else reflectable = false;
      code = ((code >= $RANGE1_FIRST) && (code <= $RANGE1_LAST))
            ? code - $RANGE1_ADJUST
            : ((code >= $RANGE2_FIRST) && (code <= $RANGE2_LAST))
              ? code - $RANGE2_ADJUST
              : ((code >= $RANGE3_FIRST) && (code <= $RANGE3_LAST))
                ? code - $RANGE3_ADJUST
                : $NO_FIELD_CODE;

      if (code) {  // needsAccessor
        var getterCode = code & 3;
        var setterCode = code >> 2;
        var accessorName = field = field.substring(0, len - 1);

        var divider = field.indexOf(":");
        if (divider > 0) { // Colon never in first position.
          accessorName = field.substring(0, divider);
          field = field.substring(divider + 1);
        }

        if (getterCode) {  // needsGetter
          var args = (getterCode & 2) ? "$receiverParamName" : "";
          var receiver = (getterCode & 1) ? "this" : "$receiverParamName";
          var body = "return " + receiver + "." + field;
          var property =
              cls + ".prototype.${namer.getterPrefix}" + accessorName + "=";
          var fn = "function(" + args + "){" + body + "}";
          if (reflectable)
            accessors.push(property + "\$reflectable(" + fn + ");\\n");
          else
            accessors.push(property + fn + ";\\n");
        }

        if (setterCode) {  // needsSetter
          var args = (setterCode & 2)
              ? "$receiverParamName,${_}$valueParamName"
              : "$valueParamName";
          var receiver = (setterCode & 1) ? "this" : "$receiverParamName";
          var body = receiver + "." + field + "$_=$_$valueParamName";
          var property =
              cls + ".prototype.${namer.setterPrefix}" + accessorName + "=";
          var fn = "function(" + args + "){" + body + "}";
          if (reflectable)
            accessors.push(property + "\$reflectable(" + fn + ");\\n");
          else
            accessors.push(property + fn + ";\\n");
        }
      }

      return field;
    }

    // First the class name, then the field names in an array and the members
    // (inside an Object literal).
    // The caller can also pass in the constructor as a function if needed.
    //
    // Example:
    // defineClass("A", ["x", "y"], {
    //  foo\$1: function(y) {
    //   print(this.x + y);
    //  },
    //  bar\$2: function(t, v) {
    //   this.x = t - v;
    //  },
    // });
    function defineClass(name, fields) {
      var accessors = [];

      var str = "function " + name + "(";
      var body = "";
      if (#hasIsolateSupport) { var fieldNames = ""; }

      for (var i = 0; i < fields.length; i++) {
        if(i != 0) str += ", ";

        var field = generateAccessor(fields[i], accessors, name);
        if (#hasIsolateSupport) { fieldNames += "'" + field + "',"; }
        var parameter = "p_" + field;
        str += parameter;
        body += ("this." + field + " = " + parameter + ";\\n");
      }
      if (supportsDirectProtoAccess) {
        body += "this." + #deferredActionString + "();";
      }
      str += ") {\\n" + body + "}\\n";
      str += name + ".$typeNameProperty=\\"" + name + "\\";\\n";
      str += "\$desc=\$collectedClasses." + name + "[1];\\n";
      str += name + ".prototype = \$desc;\\n";
      if (typeof defineClass.name != "string") {
        str += name + ".name=\\"" + name + "\\";\\n";
      }
      if (#hasIsolateSupport) {
        str += name + "." + #fieldNamesProperty + "=[" + fieldNames
               + "];\\n";
      }
      str += accessors.join("");

      return str;
    }

    if (#hasIsolateSupport) {
      #createNewIsolateFunction = function() { return new #isolateName(); };

      #classIdExtractor = function(o) { return o.constructor.name; };

      #classFieldsExtractor = function(o) {
        var fieldNames = o.constructor.#fieldNamesProperty;
        if (!fieldNames) return [];  // TODO(floitsch): do something else here.
        var result = [];
        result.length = fieldNames.length;
        for (var i = 0; i < fieldNames.length; i++) {
          result[i] = o[fieldNames[i]];
        }
        return result;
      };

      #instanceFromClassId = function(name) { return new #allClasses[name](); };

      #initializeEmptyInstance = function(name, o, fields) {
        #allClasses[name].apply(o, fields);
        return o;
      }
    }

    // If the browser supports changing the prototype via __proto__, we make
    // use of that feature. Otherwise, we copy the properties into a new
    // constructor.
    var inheritFrom = supportsDirectProtoAccess ?
      function(constructor, superConstructor) {
        var prototype = constructor.prototype;
        prototype.__proto__ = superConstructor.prototype;
        // Use a function for `true` here, as functions are stored in the
        // hidden class and not as properties in the object.
        prototype.constructor = constructor;
        prototype[#operatorIsPrefix + constructor.name] = constructor;
        return convertToFastObject(prototype);
      } :
      function() {
        function tmp() {}
        return function (constructor, superConstructor) {
          tmp.prototype = superConstructor.prototype;
          var object = new tmp();
          convertToSlowObject(object);
          var properties = constructor.prototype;
          var members = Object.keys(properties);
          for (var i = 0; i < members.length; i++) {
            var member = members[i];
            object[member] = properties[member];
          }
          // Use a function for `true` here, as functions are stored in the
          // hidden class and not as properties in the object.
          object[#operatorIsPrefix + constructor.name] = constructor;
          object.constructor = constructor;
          constructor.prototype = object;
          return object;
        };
      }();

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
        var globalObject = desc[0];
        desc = desc[1];
        if (#isTreeShakingDisabled)
          constructor["${namer.metadataField}"] = desc;
        allClasses[cls] = constructor;
        globalObject[cls] = constructor;
      }
      constructors = null;

      var finishedClasses = #finishedClassesAccess;

      function finishClass(cls) {

        if (finishedClasses[cls]) return;
        finishedClasses[cls] = true;

        var superclass = processedClasses.pending[cls];

        if (#needsMixinSupport) {
          if (superclass && superclass.indexOf("+") > 0) {
            var s = superclass.split("+");
            superclass = s[0];
            var mixinClass = s[1];
            finishClass(mixinClass);
            var mixin = allClasses[mixinClass];
            var mixinPrototype = mixin.prototype;
            var clsPrototype = allClasses[cls].prototype;

            var properties = Object.keys(mixinPrototype);
            for (var i = 0; i < properties.length; i++) {
              var d = properties[i];
              if (!hasOwnProperty.call(clsPrototype, d))
                clsPrototype[d] = mixinPrototype[d];
            }
          }
        }

        // The superclass is only false (empty string) for the Dart Object
        // class.  The minifier together with noSuchMethod can put methods on
        // the Object.prototype object, and they show through here, so we check
        // that we have a string.
        if (!superclass || typeof superclass != "string") {
          // Inlined special case of InheritFrom here for performance reasons.
          // Fix up the Dart Object class' prototype.
          var constructor = allClasses[cls];
          var prototype = constructor.prototype;
          prototype.constructor = constructor;
          prototype.#isObject = constructor;
          prototype.#deferredAction = function() {};
          return;
        }
        finishClass(superclass);
        var superConstructor = allClasses[superclass];

        if (!superConstructor) {
          superConstructor = existingIsolateProperties[superclass];
        }

        var constructor = allClasses[cls];
        var prototype = inheritFrom(constructor, superConstructor);

        if (#needsMixinSupport) {
          if (mixinPrototype) {
            prototype.#deferredAction
              = mixinDeferredActionHelper(mixinPrototype, prototype);
          }
        }

        if (#needsNativeSupport) {
          if (Object.prototype.hasOwnProperty.call(prototype, #specProperty)) {
            #nativeInfoHandler;
            // As native classes can come into existence without a constructor
            // call, we have to ensure that the class has been fully
            // initialized.
            prototype.#deferredAction();
          }
        }
        // Interceptors (or rather their prototypes) are also used without
        // first instantiating them first.
        if (prototype.#isInterceptorClass) {
          prototype.#deferredAction();
        }
      }

      #trivialNsmHandlers;

      var properties = Object.keys(processedClasses.pending);
      for (var i = 0; i < properties.length; i++) finishClass(properties[i]);
    }

    // Generic handler for deferred class setup. The handler updates the
    // prototype that it is installed on (it traverses the prototype chain
    // of [this] to find itself) and then removes itself. It recurses by
    // calling deferred handling again, which terminates on Object due to
    // the final handler.
    function finishAddStubsHelper() {
      var prototype = this;
      // Find the actual prototype that this handler is installed on.
      while (!prototype.hasOwnProperty(#deferredActionString)) {
        prototype = prototype.__proto__;
      }
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
      prototype = prototype.__proto__;
      // Call other handlers.
      prototype.#deferredAction();
    }

    if (#needsMixinSupport) {
      // Returns a deferred class setup handler that first invokes the
      // handler on [mixinPrototype] and then resumes handling on
      // [targetPrototype]. If [targetPrototype] already has a handler
      // installed, the handler is preserved in the generated closure and
      // thus can be safely overwritten.
      function mixinDeferredActionHelper(mixinPrototype, targetPrototype) {
        var chain;
        if (targetPrototype.hasOwnProperty(#deferredActionString)) {
          chain = targetPrototype.#deferredAction;
        }
        return function foo() {
          if (!supportsDirectProtoAccess) return;
          var prototype = this;
          // Find the actual prototype that this handler is installed on.
          while (!prototype.hasOwnProperty(#deferredActionString)) {
            prototype = prototype.__proto__;
          }
          if (chain) {
            prototype.#deferredAction = chain;
          } else {
            delete prototype.#deferredAction;
            convertToFastObject(prototype);
          }
          mixinPrototype.#deferredAction();
          prototype.#deferredAction();
        }
      }
    }

    function processClassData(cls, descriptor, processedClasses) {
      descriptor = convertToSlowObject(descriptor); // Use a slow object.
      var previousProperty;
      var properties = Object.keys(descriptor);
      var hasDeferredWork = false;
      var shouldDeferWork =
          supportsDirectProtoAccess && cls != #objectClassName;
      for (var i = 0; i < properties.length; i++) {
        var property = properties[i];
        var firstChar = property.charCodeAt(0);
        if (property === #staticsPropertyNameString) {
          processStatics(#statics[cls] = descriptor.#staticsPropertyName,
                         processedClasses);
          delete descriptor.#staticsPropertyName;
        } else if (firstChar === 43) { // 43 is "+".
          mangledNames[previousProperty] = property.substring(1);
          var flag = descriptor[property];
          if (flag > 0)
            descriptor[previousProperty].$reflectableField = flag;
        } else if (firstChar === 42) { // 42 is "*"
          descriptor[previousProperty].$defaultValuesField =
              descriptor[property];
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
      fields = s[1] ? s[1].split(",") : [];
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
        processedClasses.combinedConstructorFunction +=
            defineClass(cls, fields);
        processedClasses.constructorsList.push(cls);
      }
      processedClasses.collected[cls] = [globalObject, descriptor];
      classes.push(cls);
    }
  }

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
        if (#needsClassSupport) {
          previousProperty = property;
          processClassData(property, element, processedClasses);
        }
      }
    }
  }

  if (#needsStructuredMemberInfo) {

    // See [dart2js.js_emitter.ContainerBuilder.addMemberMethod] for format of
    // [array].

    // Processes the stub declaration given by [array] and stores the results
    // in the corresponding [prototype]. [name] is the property name in
    // [prototype] that the stub declaration belongs to.
    // If [isStatic] is true, the property being processed belongs to a static
    // function and thus is stored as a global. In that case we also add all
    // generated functions to the [functions] array, which is used by the
    // mirrors system to enumerate all static functions of a library. For
    // non-static functions we might still add some functions to [functions] but
    // the information is thrown away at the call site. This is to avoid
    // conditionals.
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
      for (index++; index < array.length; index++) {
        f = array[index];
        if (typeof f != "function") break;
        if (!isStatic) {
          f.\$stubName = ${readString("array", "++index")};
        }
        funcs.push(f);
        if (f.\$stubName) {
          prototype[f.\$stubName] = f;
          functions.push(f.\$stubName);
        }
      }

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
      if (typeof functionTypeIndex == "number")
        ${readFunctionType("array", "2")} = functionTypeIndex + typesOffset;
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
          funcs[0].$reflectableField = 1;
          funcs[0].$reflectionInfoField = array;
          for (var i = 1; i < funcs.length; i++) {
            funcs[i].$reflectableField = 2;
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
            reflectionName += ":" +
                (requiredParameterCount + optionalParameterCount);
          }
          mangledNames[name] = reflectionName;
          funcs[0].$reflectionNameField = reflectionName;
          funcs[0].$metadataIndexField = unmangledNameIndex + 1;
          // The following line installs the [${JsGetName.CALL_CATCH_ALL}]
          // property for closures.
          if (optionalParameterCount) prototype[unmangledName + "*"] = funcs[0];
        }
      }
    }

    if (#enabledJsInterop) {
      #jsInteropBoostrap
    }
    #tearOffCode;
  }

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
  var length = programData.length;
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
    var data = programData[i];

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
}''';

  // TODO(zarah): Remove empty else branches in output when if(#hole) is false.
  return js.statement(skeleton, holes);
}

String readString(String array, String index) {
  return readChecked(
      array, index, 'result != null && typeof result != "string"', 'string');
}

String readInt(String array, String index) {
  return readChecked(
      array,
      index,
      'result != null && (typeof result != "number" || (result|0) !== result)',
      'int');
}

String readFunctionType(String array, String index) {
  return readChecked(
      array,
      index,
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
