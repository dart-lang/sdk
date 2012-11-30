// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

class CodeEmitterNoEvalTask extends CodeEmitterTask {
  CodeEmitterNoEvalTask(Compiler compiler,
                        Namer namer,
                        bool generateSourceMap)
      : super(compiler, namer, generateSourceMap);

  String get generateGetterSetterFunction {
    return """
function() {
  throw 'Internal Error: no dynamic generation of getters and setters allowed';
}""";
  }

  String get defineClassFunction {
    return """
function(cls, constructor, prototype) {
  constructor.prototype = prototype;
  return constructor;
}""";
  }

  String get protoSupportCheck {
    // We don't modify the prototypes in CSP mode. Therefore we can have an
    // easier prototype-check.
    return 'var $supportsProtoName = !!{}.__proto__;\n';
  }

  String get finishIsolateConstructorFunction {
    // We replace the old Isolate function with a new one that initializes
    // all its field with the initial (and often final) value of all globals.
    //
    // We also copy over old values like the prototype, and the
    // isolateProperties themselves.
    return """
function(oldIsolate) {
  var isolateProperties = oldIsolate.${namer.ISOLATE_PROPERTIES};
  function Isolate() {
    for (var staticName in isolateProperties) {
      if (Object.prototype.hasOwnProperty.call(isolateProperties, staticName)) {
        this[staticName] = isolateProperties[staticName];
      }
    }
    // Use the newly created object as prototype. In Chrome this creates a
    // hidden class for the object and makes sure it is fast to access.
    function ForceEfficientMap() {}
    ForceEfficientMap.prototype = this;
    new ForceEfficientMap;
  }
  Isolate.prototype = oldIsolate.prototype;
  Isolate.prototype.constructor = Isolate;
  Isolate.${namer.ISOLATE_PROPERTIES} = isolateProperties;
  return Isolate;
}""";
  }

  String get lazyInitializerFunction {
    return """
function(prototype, staticName, fieldName, getterName, lazyValue, getter) {
$lazyInitializerLogic
}""";
  }

  void emitLazyInitializedGetter(VariableElement element, CodeBuffer buffer) {
    String isolate = namer.CURRENT_ISOLATE;
    buffer.add(', function() { return $isolate.${namer.getName(element)}; }');
  }

  void emitBoundClosureClassHeader(String mangledName,
                                   String superName,
                                   String extraArgument,
                                   CodeBuffer buffer) {
    if (!extraArgument.isEmpty) {
      buffer.add("""
$classesCollector.$mangledName = {'': function $mangledName(
    self, $extraArgument, target) {
  this.self = self;
  this.$extraArgument = $extraArgument,
  this.target = target;
 },
 'super': '$superName',
""");
    } else {
      buffer.add("""
$classesCollector.$mangledName = {'': function $mangledName(self, target) {
  this.self = self;
  this.target = target;
 },
 'super': '$superName',
""");
    }
  }

  void emitClassConstructor(ClassElement classElement, CodeBuffer buffer) {
    // Say we have a class A with fields b, c and d, where c needs a getter and
    // d needs both a getter and a setter. Then we produce:
    // - a constructor (directly into the given [buffer]):
    //   function A(b, c, d) { this.b = b, this.c = c, this.d = d; }
    // - getters and setters (stored in the [explicitGettersSetters] list):
    //   get$c : function() { return this.c; }
    //   get$d : function() { return this.d; }
    //   set$d : function(x) { this.d = x; }
    List<String> fields = <String>[];
    visitClassFields(classElement, (Element member,
                                    String name,
                                    bool needsGetter,
                                    bool needsSetter,
                                    bool needsCheckedSetter) {
      fields.add(name);
    });

    List<String> argumentNames = fields;
    if (fields.length < ($z - $a)) {
      argumentNames = new List<String>(fields.length);
      for (int i = 0; i < fields.length; i++) {
        argumentNames[i] = new String.fromCharCodes([$a + i]);
      }
    }
    String constructorName = namer.safeName(classElement.name.slowToString());
    // Generate the constructor.
    buffer.add("'': function $constructorName(");
    buffer.add(Strings.join(argumentNames, ", "));
    buffer.add(") {\n");
    for (int i = 0; i < fields.length; i++) {
      buffer.add("  this.${fields[i]} = ${argumentNames[i]};\n");
    }
    buffer.add(' }');
  }

  void emitClassFields(ClassElement classElement,
                       CodeBuffer buffer,
                       bool emitEndingComma,
                       { String superClass: "",
                         bool isNative: false}) {
    if (emitEndingComma) buffer.add(', ');
  }

  bool getterAndSetterCanBeImplementedByFieldSpec(Element member,
                                                  String name,
                                                  bool needsGetter,
                                                  bool needsSetter) {
    return false;
  }
}
