// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.new_js_emitter.model;

import '../dart2jslib.dart' show Compiler;
import '../js/js.dart' as js;

js.LiteralString unparse(Compiler compiler, js.Expression value) {
  String text = js.prettyPrint(value, compiler).getText();
  if (value is js.Fun) text = '($text)';
  return js.js.escapedString(text);
}

class Program {
  final js.Expression main;
  final List<Library> libraries;
  final List<Holder> holders;
  Program(this.main, this.libraries, this.holders);

  js.Expression emit(Compiler compiler) {
    js.Expression program = new js.ArrayInitializer.from(
        libraries.map((e) => e.emit(compiler)));
    return js.js(boilerplate, [emitHolders(), main, program]);
  }

  js.Block emitHolders() {
    // The top-level variables for holders must *not* be renamed by the
    // JavaScript pretty printer because a lot of code already uses the
    // non-renamed names. The generated code looks like this:
    //
    //    var H = {}, ..., G = {};
    //    var holders = [ H, ..., G ];
    //
    // and it is inserted at the top of the top-level function expression
    // that covers the entire program.

    List<js.Statement> statements = [
        new js.ExpressionStatement(
            new js.VariableDeclarationList(holders.map((e) =>
                new js.VariableInitialization(
                    new js.VariableDeclaration(e.name, allowRename: false),
                    new js.ObjectInitializer(const []))).toList())),
        js.js.statement('var holders = #', new js.ArrayInitializer.from(
            holders.map((e) => new js.VariableUse(e.name))))
    ];
    return new js.Block(statements);
  }
}

class Holder {
  final String name;
  final int index;
  Holder(this.name, this.index);
}

class Library {
  final String uri;
  final List<StaticMethod> statics;
  final List<Class> classes;
  Library(this.uri, this.statics, this.classes);

  js.Expression emit(Compiler compiler) {
    Iterable staticDescriptors = statics.expand((e) =>
        [ js.string(e.name), js.js.number(e.holder.index), e.emit(compiler) ]);
    Iterable classDescriptors = classes.expand((e) =>
        [ js.string(e.name), js.js.number(e.holder.index), e.emit(compiler) ]);

    js.Expression staticArray = new js.ArrayInitializer.from(staticDescriptors);
    js.Expression classArray = new js.ArrayInitializer.from(classDescriptors);

    return new js.ArrayInitializer.from([staticArray, classArray]);
  }
}

class Class {
  final String name;
  final Holder holder;
  Class superclass;
  final List<Method> methods;
  Class(this.name, this.holder, this.methods);

  void setSuperclass(Class superclass) {
    this.superclass = superclass;
  }

  String get superclassName
      => (superclass == null) ? "" : superclass.name;
  int get superclassHolderIndex
      => (superclass == null) ? 0 : superclass.holder.index;

  js.Expression emit(Compiler compiler) {
    List elements = [ js.string(superclassName),
                      js.js.number(superclassHolderIndex) ];
    elements.addAll(methods.expand((e) => [ js.string(e.name), e.code ]));
    return unparse(compiler, new js.ArrayInitializer.from(elements));
  }
}

class Method {
  final String name;
  final js.Expression code;
  Method(this.name, this.code);
}

class StaticMethod extends Method {
  final Holder holder;
  StaticMethod(String name, this.holder, js.Expression code)
      : super(name, code);

  js.Expression emit(Compiler compiler) {
    return unparse(compiler, code);
  }
}

final String boilerplate = r"""
!function(start, program) {

  // Initialize holder objects.
  #;

  function setupProgram() {
    for (var i = 0; i < program.length; i++) {
      setupLibrary(program[i]);
    }
  }

  function setupLibrary(library) {
    var statics = library[0];
    for (var i = 0; i < statics.length; i += 3) {
      var holderIndex = statics[i + 1];
      setupStatic(statics[i], holders[holderIndex], statics[i + 2]);
    }

    var classes = library[1];
    for (var i = 0; i < classes.length; i += 3) {
      var holderIndex = classes[i + 1];
      setupClass(classes[i], holders[holderIndex], classes[i + 2]);
    }
  }

  function setupStatic(name, holder, descriptor) {
    holder[name] = function() {
      var method = compile(descriptor);
      holder[name] = method;
      return method.apply(this, arguments);
    };
  }

  function setupClass(name, holder, descriptor) {
    var resolve = function() {
      var constructor = compileConstructor(name, descriptor);
      holder[name] = constructor;
      return constructor;
    };

    var patch = function() {
      var constructor = resolve();
      var object = new constructor();
      constructor.apply(object, arguments);
      return object;
    };

    // We store the resolve function on the patch function to make it possible
    // to resolve superclass references without constructing instances. The
    // resolve property also serves as a marker that indicates whether or not
    // a class has been resolved yet.
    patch.resolve = resolve;
    holder[name] = patch;
  }

  function compileConstructor(name, descriptor) {
    descriptor = compile(descriptor);
    var prototype = determinePrototype(descriptor);
    for (var i = 2; i < descriptor.length; i += 2) {
      prototype[descriptor[i]] = descriptor[i + 1];
    }
    var result = function() { };  // TODO(kasperl): Compile.
    result.prototype = prototype;
    return result;
  }

  function determinePrototype(descriptor) {
    var superclassName = descriptor[0];
    if (!superclassName) return { };

    // Look up the superclass constructor function in the right holder.
    var holderIndex = descriptor[1];
    var superclass = holders[holderIndex][superclassName];
    if (superclass.resolve) superclass = superclass.resolve();

    // Create a new prototype object chained to the superclass prototype.
    var intermediate = function() { };
    intermediate.prototype = superclass.prototype;
    return new intermediate();
  }

  function compile(s) {
    'use strict';
    return eval(s);
  }

  setupProgram();
  var end = Date.now();
  print('Setup: ' + (end - start) + ' ms.');

  if (true) #();

}(Date.now(), #)
""";