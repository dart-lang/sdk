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
  constructor.builtin\$cls = cls;
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

  js.Expression buildLazyInitializedGetter(VariableElement element) {
    String isolate = namer.CURRENT_ISOLATE;
    return js.fun([],
        js.block1(
            js.return_(
                js.fieldAccess(js.use(isolate), namer.getName(element)))));
  }

  js.Expression buildConstructor(String mangledName, List<String> fieldNames) {
    return new js.NamedFunction(
        new js.VariableDeclaration(mangledName),
        new js.Fun(
            fieldNames
                .mappedBy((fieldName) => new js.Parameter(fieldName))
                .toList(),
            new js.Block(
                fieldNames.mappedBy((fieldName) =>
                    new js.ExpressionStatement(
                        new js.Assignment(
                            new js.This().dot(fieldName),
                            new js.VariableUse(fieldName))))
                    .toList())));
  }

  void emitBoundClosureClassHeader(String mangledName,
                                   String superName,
                                   List<String> fieldNames,
                                   ClassBuilder builder) {
    builder.addProperty('', buildConstructor(mangledName, fieldNames));
    builder.addProperty('super', js.string(superName));
  }

  void emitClassConstructor(ClassElement classElement, ClassBuilder builder) {
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

    builder.addProperty('', buildConstructor(constructorName, fields));
  }

  void emitSuper(String superName, ClassBuilder builder) {
    if (superName != '') {
      builder.addProperty('super', js.string(superName));
    }
  }

  void emitClassFields(ClassElement classElement,
                       ClassBuilder builder,
                       { String superClass: "",
                         bool classIsNative: false}) {
  }

  bool get getterAndSetterCanBeImplementedByFieldSpec => false;
}
