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
  var isolateProperties = oldIsolate.${namer.isolatePropertiesName};
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
  Isolate.${namer.isolatePropertiesName} = isolateProperties;
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

  js.Expression buildConstructor(String mangledName, List<String> fieldNames) {
    return new js.NamedFunction(
        new js.VariableDeclaration(mangledName),
        new js.Fun(
            fieldNames.map((fieldName) => new js.Parameter(fieldName)),
            new js.Block(
                fieldNames.map((fieldName) =>
                    new js.ExpressionStatement(
                        new js.Assignment(
                            new js.This().dot(fieldName),
                            new js.VariableUse(fieldName)))))));
  }

  void emitBoundClosureClassHeader(String mangledName,
                                   String superName,
                                   List<String> fieldNames,
                                   CodeBuffer buffer) {
    buffer.add("$classesCollector.$mangledName = {'': ");
    buffer.add(
        js.prettyPrint(buildConstructor(mangledName, fieldNames), compiler));
    buffer.add(",\n 'super': '$superName',\n");
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
                                    String accessorName,
                                    bool needsGetter,
                                    bool needsSetter,
                                    bool needsCheckedSetter) {
      fields.add(name);
    });
    String constructorName = namer.safeName(classElement.name.slowToString());
    buffer.add("'': ");
    buffer.add(
        js.prettyPrint(buildConstructor(constructorName, fields), compiler));
  }

  void emitSuper(String superName, CodeBuffer buffer) {
    if (superName != '') {
      buffer.add(",\n 'super': '$superName'");
    }
  }

  void emitClassFields(ClassElement classElement,
                       CodeBuffer buffer,
                       bool emitEndingComma,
                       { String superClass: "",
                         bool classIsNative: false}) {
    if (emitEndingComma) buffer.add(', ');
  }

  bool getterAndSetterCanBeImplementedByFieldSpec(Element member,
                                                  String name,
                                                  bool needsGetter,
                                                  bool needsSetter) {
    return false;
  }
}
