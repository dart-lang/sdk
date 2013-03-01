// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

class NativeEmitter {

  CodeEmitterTask emitter;
  CodeBuffer nativeBuffer;

  // Classes that participate in dynamic dispatch. These are the
  // classes that contain used members.
  Set<ClassElement> classesWithDynamicDispatch;

  // Native classes found in the application.
  Set<ClassElement> nativeClasses;

  // Caches the native subtypes of a native class.
  Map<ClassElement, List<ClassElement>> subtypes;

  // Caches the direct native subtypes of a native class.
  Map<ClassElement, List<ClassElement>> directSubtypes;

  // Caches the native methods that are overridden by a native class.
  // Note that the method that overrides does not have to be native:
  // it's the overridden method that must make sure it will dispatch
  // to its subclass if it sees an instance whose class is a subclass.
  Set<FunctionElement> overriddenMethods;

  // Caches the methods that have a native body.
  Set<FunctionElement> nativeMethods;

  // Do we need the native emitter to take care of handling
  // noSuchMethod for us? This flag is set to true in the emitter if
  // it finds any native class that needs noSuchMethod handling.
  bool handleNoSuchMethod = false;

  NativeEmitter(this.emitter)
      : classesWithDynamicDispatch = new Set<ClassElement>(),
        nativeClasses = new Set<ClassElement>(),
        subtypes = new Map<ClassElement, List<ClassElement>>(),
        directSubtypes = new Map<ClassElement, List<ClassElement>>(),
        overriddenMethods = new Set<FunctionElement>(),
        nativeMethods = new Set<FunctionElement>(),
        nativeBuffer = new CodeBuffer();

  Compiler get compiler => emitter.compiler;
  JavaScriptBackend get backend => compiler.backend;

  String get _ => emitter._;
  String get n => emitter.n;
  String get N => emitter.N;

  String get dynamicName {
    Element element = compiler.findHelper(
        const SourceString('dynamicFunction'));
    return backend.namer.isolateAccess(element);
  }

  String get dynamicSetMetadataName {
    Element element = compiler.findHelper(
        const SourceString('dynamicSetMetadata'));
    return backend.namer.isolateAccess(element);
  }

  String get typeNameOfName {
    Element element = compiler.findHelper(
        const SourceString('getTypeNameOf'));
    return backend.namer.isolateAccess(element);
  }

  String get defPropName {
    Element element = compiler.findHelper(
        const SourceString('defineProperty'));
    return backend.namer.isolateAccess(element);
  }

  String get toStringHelperName {
    Element element = compiler.findHelper(
        const SourceString('toStringForNativeObject'));
    return backend.namer.isolateAccess(element);
  }

  String get hashCodeHelperName {
    Element element = compiler.findHelper(
        const SourceString('hashCodeForNativeObject'));
    return backend.namer.isolateAccess(element);
  }

  String get defineNativeClassName
      => '${backend.namer.CURRENT_ISOLATE}.\$defineNativeClass';

  String get defineNativeClassFunction {
    return """
function(cls, desc) {
  var fields = desc[''];
  var fields_array = fields ? fields.split(',') : [];
  for (var i = 0; i < fields_array.length; i++) {
    ${emitter.currentGenerateAccessorName}(fields_array[i], desc);
  }
  var hasOwnProperty = Object.prototype.hasOwnProperty;
  for (var method in desc) {
    if (method) {
      if (hasOwnProperty.call(desc, method)) {
        $dynamicName(method)[cls] = desc[method];
      }
    }
  }
}""";
  }

  bool isNativeGlobal(String quotedName) {
    return identical(quotedName[1], '@');
  }

  String toNativeTag(ClassElement cls) {
    String quotedName = cls.nativeTagInfo.slowToString();
    if (isNativeGlobal(quotedName)) {
      // Global object, just be like the other types for now.
      return quotedName.substring(3, quotedName.length - 1);
    } else {
      return quotedName.substring(2, quotedName.length - 1);
    }
  }

  void generateNativeClass(ClassElement classElement) {
    assert(!classElement.hasBackendMembers);
    nativeClasses.add(classElement);

    ClassBuilder builder = new ClassBuilder();
    emitter.emitClassFields(classElement, builder, classIsNative: true);
    emitter.emitClassGettersSetters(classElement, builder);
    emitter.emitInstanceMembers(classElement, builder);

    // An empty native class may be omitted since the superclass methods can be
    // located via the dispatch metadata.
    if (builder.properties.isEmpty) return;

    String nativeTag = toNativeTag(classElement);
    jsAst.Expression definition =
        js[defineNativeClassName](
            [js.string(nativeTag), builder.toObjectInitializer()]);

    nativeBuffer.add(jsAst.prettyPrint(definition, compiler));
    nativeBuffer.add('$N$n');

    classesWithDynamicDispatch.add(classElement);
  }

  List<ClassElement> getDirectSubclasses(ClassElement cls) {
    List<ClassElement> result = directSubtypes[cls];
    return result == null ? const<ClassElement>[] : result;
  }

  void potentiallyConvertDartClosuresToJs(
      List<jsAst.Statement> statements,
      FunctionElement member,
      List<jsAst.Parameter> stubParameters) {
    FunctionSignature parameters = member.computeSignature(compiler);
    Element converter =
        compiler.findHelper(const SourceString('convertDartClosureToJS'));
    String closureConverter = backend.namer.isolateAccess(converter);
    Set<String> stubParameterNames = new Set<String>.from(
        stubParameters.map((param) => param.name));
    parameters.forEachParameter((Element parameter) {
      String name = parameter.name.slowToString();
      // If [name] is not in [stubParameters], then the parameter is an optional
      // parameter that was not provided for this stub.
      for (jsAst.Parameter stubParameter in stubParameters) {
        if (stubParameter.name == name) {
          DartType type = parameter.computeType(compiler).unalias(compiler);
          if (type is FunctionType) {
            // The parameter type is a function type either directly or through
            // typedef(s).
            int arity = type.computeArity();

            statements.add(
                new jsAst.ExpressionStatement(
                    js.assign(
                        js[name],
                        js[closureConverter](
                            [js[name],
                             new jsAst.LiteralNumber('$arity')]))));
            break;
          }
        }
      }
    });
  }

  List<jsAst.Statement> generateParameterStubStatements(
      Element member,
      String invocationName,
      List<jsAst.Parameter> stubParameters,
      List<jsAst.Expression> argumentsBuffer,
      int indexOfLastOptionalArgumentInParameters) {
    // The target JS function may check arguments.length so we need to
    // make sure not to pass any unspecified optional arguments to it.
    // For example, for the following Dart method:
    //   foo([x, y, z]);
    // The call:
    //   foo(y: 1)
    // must be turned into a JS call to:
    //   foo(null, y).

    ClassElement classElement = member.enclosingElement;
    String nativeTagInfo = classElement.nativeTagInfo.slowToString();

    List<jsAst.Statement> statements = <jsAst.Statement>[];
    potentiallyConvertDartClosuresToJs(statements, member, stubParameters);

    String target;
    List<jsAst.Expression> arguments;

    if (!nativeMethods.contains(member)) {
      // When calling a method that has a native body, we call it with our
      // calling conventions.
      target = backend.namer.getName(member);
      arguments = argumentsBuffer;
    } else {
      // When calling a JS method, we call it with the native name, and only the
      // arguments up until the last one provided.
      target = member.fixedBackendName();
      arguments = argumentsBuffer.getRange(
          0, indexOfLastOptionalArgumentInParameters + 1);
    }
    statements.add(
        new jsAst.Return(
            new jsAst.VariableUse('this')[target](arguments)));

    if (!overriddenMethods.contains(member)) {
      // Call the method directly.
      return statements;
    } else {
      return <jsAst.Statement>[
          generateMethodBodyWithPrototypeCheck(
              invocationName, new jsAst.Block(statements), stubParameters)];
    }
  }

  // If a method is overridden, we must check if the prototype of 'this' has the
  // method available. Otherwise, we may end up calling the method from the
  // super class. If the method is not available, we make a direct call to
  // Object.prototype.$methodName.  This method will patch the prototype of
  // 'this' to the real method.
  jsAst.Statement generateMethodBodyWithPrototypeCheck(
      String methodName,
      jsAst.Statement body,
      List<jsAst.Parameter> parameters) {
    return js.if_(
        js['(Object.getPrototypeOf(this)).hasOwnProperty("$methodName")'],
        body,
        js.return_(
            js['Object.prototype.$methodName.call'](
                <jsAst.Expression>[js['this']]..addAll(
                    parameters.map((param) => js[param.name])))));
  }

  jsAst.Block generateMethodBodyWithPrototypeCheckForElement(
      FunctionElement element,
      jsAst.Block body,
      List<jsAst.Parameter> parameters) {
    ElementKind kind = element.kind;
    if (kind != ElementKind.FUNCTION &&
        kind != ElementKind.GETTER &&
        kind != ElementKind.SETTER) {
      compiler.internalError("unexpected kind: '$kind'", element: element);
    }

    String methodName = backend.namer.getName(element);
    return new jsAst.Block(
        [generateMethodBodyWithPrototypeCheck(methodName, body, parameters)]);
  }


  void emitDynamicDispatchMetadata() {
    if (classesWithDynamicDispatch.isEmpty) return;
    int length = classesWithDynamicDispatch.length;
    if (!compiler.enableMinification) {
      nativeBuffer.add('// $length dynamic classes.\n');
    }

    // Build a pre-order traversal over all the classes and their subclasses.
    Set<ClassElement> seen = new Set<ClassElement>();
    List<ClassElement> classes = <ClassElement>[];
    void visit(ClassElement cls) {
      if (seen.contains(cls)) return;
      seen.add(cls);
      getDirectSubclasses(cls).forEach(visit);
      classes.add(cls);
    }
    Elements.sortedByPosition(classesWithDynamicDispatch).forEach(visit);

    List<ClassElement> preorderDispatchClasses = classes.where(
        (cls) => !getDirectSubclasses(cls).isEmpty &&
                  classesWithDynamicDispatch.contains(cls)).toList();

    if (!compiler.enableMinification) {
      nativeBuffer.add('// ${classes.length} classes\n');
    }
    Iterable<ClassElement> classesThatHaveSubclasses = classes.where(
        (ClassElement t) => !getDirectSubclasses(t).isEmpty);
    if (!compiler.enableMinification) {
      nativeBuffer.add('// ${classesThatHaveSubclasses.length} !leaf\n');
    }

    // Generate code that builds the map from cls tags used in dynamic dispatch
    // to the set of cls tags of classes that extend (TODO: or implement) those
    // classes.  The set is represented as a string of tags joined with '|'.
    // This is easily split into an array of tags, or converted into a regexp.
    //
    // To reduce the size of the sets, subsets are CSE-ed out into variables.
    // The sets could be much smaller if we could make assumptions about the
    // cls tags of other classes (which are constructor names or part of the
    // result of Object.protocls.toString).  For example, if objects that are
    // Dart objects could be easily excluded, then we might be able to simplify
    // the test, replacing dozens of HTMLxxxElement classes with the regexp
    // /HTML.*Element/.

    // Temporary variables for common substrings.
    List<String> varNames = <String>[];
    // Values of temporary variables.
    Map<String, jsAst.Expression> varDefns = new Map<String, jsAst.Expression>();

    // Expression to compute tags string for a class.  The expression will
    // initially be a string or expression building a string, but may be
    // replaced with a variable reference to the common substring.
    Map<ClassElement, jsAst.Expression> tagDefns =
        new Map<ClassElement, jsAst.Expression>();

    jsAst.Expression makeExpression(ClassElement classElement) {
      // Expression fragments for this set of cls keys.
      List<jsAst.Expression> expressions = <jsAst.Expression>[];
      // TODO: Remove if cls is abstract.
      List<String> subtags = [toNativeTag(classElement)];
      void walk(ClassElement cls) {
        for (final ClassElement subclass in getDirectSubclasses(cls)) {
          ClassElement tag = subclass;
          jsAst.Expression existing = tagDefns[tag];
          if (existing == null) {
            // [subclass] is still within the subtree between dispatch classes.
            subtags.add(toNativeTag(tag));
            walk(subclass);
          } else {
            // [subclass] is one of the preorderDispatchClasses, so CSE this
            // reference with the previous reference.
            jsAst.VariableUse use = existing.asVariableUse();
            if (use != null && varDefns.containsKey(use.name)) {
              // We end up here if the subclasses have a DAG structure.  We
              // don't have DAGs yet, but if the dispatch is used for mixins
              // that will be a possibility.
              // Re-use the previously created temporary variable.
              expressions.add(new jsAst.VariableUse(use.name));
            } else {
              String varName = 'v${varNames.length}_${tag.name.slowToString()}';
              varNames.add(varName);
              varDefns[varName] = existing;
              tagDefns[tag] = new jsAst.VariableUse(varName);
              expressions.add(new jsAst.VariableUse(varName));
            }
          }
        }
      }
      walk(classElement);

      if (!subtags.isEmpty) {
        expressions.add(js.string(subtags.join('|')));
      }
      jsAst.Expression expression;
      if (expressions.length == 1) {
        expression = expressions[0];
      } else {
        jsAst.Expression array = new jsAst.ArrayInitializer.from(expressions);
        expression = array['join']([js.string('|')]);
      }
      return expression;
    }

    for (final ClassElement classElement in preorderDispatchClasses) {
      tagDefns[classElement] = makeExpression(classElement);
    }

    // Write out a thunk that builds the metadata.
    if (!tagDefns.isEmpty) {
      List<jsAst.Statement> statements = <jsAst.Statement>[];

      List<jsAst.VariableInitialization> initializations =
          <jsAst.VariableInitialization>[];
      for (final String varName in varNames) {
        initializations.add(
            new jsAst.VariableInitialization(
                new jsAst.VariableDeclaration(varName),
                varDefns[varName]));
      }
      if (!initializations.isEmpty) {
        statements.add(
            new jsAst.ExpressionStatement(
                new jsAst.VariableDeclarationList(initializations)));
      }

      // [table] is a list of lists, each inner list of the form:
      //   [dynamic-dispatch-tag, tags-of-classes-implementing-dispatch-tag]
      // E.g.
      //   [['Node', 'Text|HTMLElement|HTMLDivElement|...'], ...]
      jsAst.Expression table =
          new jsAst.ArrayInitializer.from(
              preorderDispatchClasses.map((cls) =>
                  new jsAst.ArrayInitializer.from([
                      js.string(toNativeTag(cls)),
                      tagDefns[cls]])));

      //  $.dynamicSetMetadata(table);
      statements.add(
          new jsAst.ExpressionStatement(
              new jsAst.Call(
                  new jsAst.VariableUse(dynamicSetMetadataName),
                  [table])));

      //  (function(){statements})();
      if (emitter.compiler.enableMinification) nativeBuffer.add(';');
      nativeBuffer.add(
          jsAst.prettyPrint(
              new jsAst.ExpressionStatement(
                  new jsAst.Call(new jsAst.Fun([], new jsAst.Block(statements)),
                                 [])),
              compiler));
    }
  }

  bool isSupertypeOfNativeClass(Element element) {
    if (element.isTypeVariable()) {
      compiler.cancel("Is check for type variable", element: element);
      return false;
    }
    if (element.computeType(compiler).unalias(compiler) is FunctionType) {
      // The element type is a function type either directly or through
      // typedef(s).
      return false;
    }

    if (!element.isClass()) {
      compiler.cancel("Is check does not handle element", element: element);
      return false;
    }

    return subtypes[element] != null;
  }

  bool requiresNativeIsCheck(Element element) {
    if (!element.isClass()) return false;
    ClassElement cls = element;
    if (cls.isNative()) return true;
    return isSupertypeOfNativeClass(element);
  }

  void assembleCode(CodeBuffer targetBuffer) {
    if (nativeClasses.isEmpty) return;
    emitDynamicDispatchMetadata();
    targetBuffer.add('$defineNativeClassName = '
                     '$defineNativeClassFunction$N$n');

    List<jsAst.Property> objectProperties = <jsAst.Property>[];

    void addProperty(String name, jsAst.Expression value) {
      objectProperties.add(new jsAst.Property(js.string(name), value));
    }

    // Because of native classes, we have to generate some is checks
    // by calling a method, instead of accessing a property. So we
    // attach to the JS Object prototype these methods that return
    // false, and will be overridden by subclasses when they have to
    // return true.
    void emitIsChecks() {
      for (ClassElement element in
               Elements.sortedByPosition(emitter.checkedClasses)) {
        if (!requiresNativeIsCheck(element)) continue;
        if (element.isObject(compiler)) continue;
        String name = backend.namer.operatorIs(element);
        addProperty(name,
            js.fun([], js.return_(js['false'])));
      }
    }
    emitIsChecks();

    jsAst.Expression makeCallOnThis(String functionName) {
      // Because we know the function is intercepted, we need an extra
      // parameter.
      return js.fun(['_'], js.return_(js['$functionName(this)']));
    }

    // In order to have the toString method on every native class,
    // we must patch the JS Object prototype with a helper method.
    String toStringName = backend.namer.publicInstanceMethodNameByArity(
        const SourceString('toString'), 0);
    addProperty(toStringName, makeCallOnThis(toStringHelperName));

    // Same as above, but for hashCode.
    String hashCodeName =
        backend.namer.publicGetterName(const SourceString('hashCode'));
    addProperty(hashCodeName, makeCallOnThis(hashCodeHelperName));

    // Same as above, but for operator==.
    String equalsName = backend.namer.publicInstanceMethodNameByArity(
        const SourceString('=='), 1);
    // Because we know the function is intercepted, we need an extra
    // parameter.
    addProperty(equalsName, js.fun(['_', 'a'],
        js.return_(js['this === a'])));

    // If the native emitter has been asked to take care of the
    // noSuchMethod handlers, we do that now.
    if (handleNoSuchMethod) {
      emitter.emitNoSuchMethodHandlers(addProperty);
    }

    // If we have any properties to add to Object.prototype, we run
    // through them and add them using defineProperty.
    if (!objectProperties.isEmpty) {
      jsAst.Expression init =
          js.fun(['table'],
              new jsAst.ForIn(
                  new jsAst.VariableDeclarationList(
                      [new jsAst.VariableInitialization(
                          new jsAst.VariableDeclaration('key'),
                          null)]),
                  js['table'],
                  new jsAst.ExpressionStatement(
                      js['$defPropName(Object.prototype, key, table[key])'])))(
              new jsAst.ObjectInitializer(objectProperties));

      if (emitter.compiler.enableMinification) targetBuffer.add(';');
      targetBuffer.add(jsAst.prettyPrint(
          new jsAst.ExpressionStatement(init), compiler));
      targetBuffer.add('\n');
    }

    targetBuffer.add(nativeBuffer);
    targetBuffer.add('\n');
  }
}
