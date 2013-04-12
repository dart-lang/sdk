// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

class CodeEmitterNoEvalTask extends CodeEmitterTask {
  CodeEmitterNoEvalTask(Compiler compiler,
                        Namer namer,
                        bool generateSourceMap)
      : super(compiler, namer, generateSourceMap);

  bool get getterAndSetterCanBeImplementedByFieldSpec => false;
  bool get generateTrivialNsmHandlers => false;

  void emitSuper(String superName, ClassBuilder builder) {
    if (superName != '') {
      builder.addProperty('super', js.string(superName));
    }
  }

  void emitBoundClosureClassHeader(String mangledName,
                                   String superName,
                                   List<String> fieldNames,
                                   ClassBuilder builder) {
    builder.addProperty('', buildConstructor(mangledName, fieldNames));
    emitSuper(superName, builder);
  }


  bool emitClassFields(ClassElement classElement,
                       ClassBuilder builder,
                       { String superClass: "",
                         bool classIsNative: false }) {
    // Class fields are dynamically generated so they have to be
    // emitted using getters and setters instead.
    return false;
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
    if (classElement.isNative()) {
      builder.addProperty('', buildUnusedConstructor(constructorName));
    } else {
      builder.addProperty('', buildConstructor(constructorName, fields));
    }
  }

  List get defineClassFunction {
    return [new jsAst.FunctionDeclaration(
        new jsAst.VariableDeclaration('defineClass'),
        js.fun(['cls', 'constructor', 'prototype'],
               [js(r'constructor.prototype = prototype'),
                js(r'constructor.builtin$cls = cls'),
                js.return_('constructor')]))];
  }

  List buildProtoSupportCheck() {
    // We don't modify the prototypes in CSP mode. Therefore we can have an
    // easier prototype-check.
    return [js('var $supportsProtoName = !!{}.__proto__')];
  }

  jsAst.Expression buildConstructor(String mangledName,
                                    List<String> fieldNames) {
    return new jsAst.NamedFunction(
        new jsAst.VariableDeclaration(mangledName),
        js.fun(fieldNames, fieldNames.map(
            (name) => js('this.$name = $name')).toList()));
  }

  jsAst.Expression buildUnusedConstructor(String mangledName) {
    String message = 'Called unused constructor';
    return new jsAst.NamedFunction(
        new jsAst.VariableDeclaration(mangledName),
        js.fun([], new jsAst.Throw(js.string(message))));
}

  jsAst.FunctionDeclaration get generateAccessorFunction {
    String message =
        'Internal error: no dynamic generation of accessors allowed.';
    return new jsAst.FunctionDeclaration(
        new jsAst.VariableDeclaration('generateAccessor'),
        js.fun([], new jsAst.Throw(js.string(message))));
  }

  jsAst.Expression buildLazyInitializedGetter(VariableElement element) {
    String isolate = namer.CURRENT_ISOLATE;
    String name = namer.getName(element);
    return js.fun([], js.return_(js('$isolate.$name')));
  }

  jsAst.Fun get lazyInitializerFunction {
    // function(prototype, staticName, fieldName,
    //          getterName, lazyValue, getter) {
    var parameters = <String>['prototype', 'staticName', 'fieldName',
                              'getterName', 'lazyValue', 'getter'];
    return js.fun(parameters, addLazyInitializerLogic());
  }

  jsAst.Fun get finishIsolateConstructorFunction {
    // We replace the old Isolate function with a new one that initializes
    // all its fields with the initial (and often final) value of all globals.
    //
    // We also copy over old values like the prototype, and the
    // isolateProperties themselves.
    return js.fun('oldIsolate', [
      js('var isolateProperties = oldIsolate.${namer.isolatePropertiesName}'),
      new jsAst.FunctionDeclaration(
        new jsAst.VariableDeclaration('Isolate'),
          js.fun([], [
            js('var hasOwnProperty = Object.prototype.hasOwnProperty'),
            js.forIn('staticName', 'isolateProperties',
              js.if_('hasOwnProperty.call(isolateProperties, staticName)',
                js('this[staticName] = isolateProperties[staticName]'))),
            // Use the newly created object as prototype. In Chrome,
            // this creates a hidden class for the object and makes
            // sure it is fast to access.
            new jsAst.FunctionDeclaration(
              new jsAst.VariableDeclaration('ForceEfficientMap'),
              js.fun([], [])),
            js('ForceEfficientMap.prototype = this'),
            js('new ForceEfficientMap()')])),
      js('Isolate.prototype = oldIsolate.prototype'),
      js('Isolate.prototype.constructor = Isolate'),
      js('Isolate.${namer.isolatePropertiesName} = isolateProperties'),
      js.return_('Isolate')]);
  }
}
