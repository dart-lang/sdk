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
  var fields = desc[''] || [];
  var generateGetterSetter = ${emitter.generateGetterSetterFunction};
  for (var i = 0; i < fields.length; i++) {
    generateGetterSetter(fields[i], desc);
  }
  var hasOwnProperty = Object.prototype.hasOwnProperty;
  for (var method in desc) {
    if (method !== '') {
      if (hasOwnProperty.call(desc, method)) {
        $dynamicName(method)[cls] = desc[method];
      }
    }
  }
}""";
  }

  void generateNativeLiteral(ClassElement classElement) {
    String quotedNative = classElement.nativeTagInfo.slowToString();
    String nativeCode = quotedNative.substring(2, quotedNative.length - 1);
    String className = backend.namer.getName(classElement);
    nativeBuffer.add(className);
    nativeBuffer.add(' = ');
    nativeBuffer.add(nativeCode);
    nativeBuffer.add(';\n');

    void defineInstanceMember(String name, CodeBuffer value) {
      nativeBuffer.add("$className.$name = $value;\n");
    }

    classElement.implementation.forEachMember((_, Element member) {
      if (member.isInstanceMember()) {
        emitter.addInstanceMember(member, defineInstanceMember);
      }
    });
  }

  bool isNativeLiteral(String quotedName) {
    return identical(quotedName[1], '=');
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
    nativeClasses.add(classElement);

    assert(classElement.backendMembers.isEmpty);
    String quotedName = classElement.nativeTagInfo.slowToString();
    if (isNativeLiteral(quotedName)) {
      generateNativeLiteral(classElement);
      // The native literal kind needs to be dealt with specially when
      // generating code for it.
      return;
    }

    CodeBuffer fieldBuffer = new CodeBuffer();
    CodeBuffer getterSetterBuffer = new CodeBuffer();
    CodeBuffer methodBuffer = new CodeBuffer();

    emitter.emitClassFields(classElement, fieldBuffer, false);
    emitter.emitClassGettersSetters(classElement, getterSetterBuffer, false);
    emitter.emitInstanceMembers(classElement, methodBuffer, false);

    if (methodBuffer.isEmpty
        && fieldBuffer.isEmpty
        && getterSetterBuffer.isEmpty) {
      return;
    }

    String nativeTag = toNativeTag(classElement);
    nativeBuffer.add("$defineNativeClassName('$nativeTag', ");
    nativeBuffer.add('{');
    bool firstInMap = true;
    if (!fieldBuffer.isEmpty) {
      firstInMap = false;
      nativeBuffer.add(fieldBuffer);
    }
    if (!getterSetterBuffer.isEmpty) {
      if (!firstInMap) nativeBuffer.add(",");
      firstInMap = false;
      nativeBuffer.add("\n ");
      nativeBuffer.add(getterSetterBuffer);
    }
    if (!methodBuffer.isEmpty) {
      if (!firstInMap) nativeBuffer.add(",");
      nativeBuffer.add(methodBuffer);
    }
    nativeBuffer.add('\n});\n\n');

    classesWithDynamicDispatch.add(classElement);
  }

  List<ClassElement> getDirectSubclasses(ClassElement cls) {
    List<ClassElement> result = directSubtypes[cls];
    return result == null ? const<ClassElement>[] : result;
  }

  void potentiallyConvertDartClosuresToJs(CodeBuffer code,
                                          FunctionElement member,
                                          List<String> argumentsBuffer) {
    FunctionSignature parameters = member.computeSignature(compiler);
    Element converter =
        compiler.findHelper(const SourceString('convertDartClosureToJS'));
    String closureConverter = backend.namer.isolateAccess(converter);
    parameters.forEachParameter((Element parameter) {
      String name = parameter.name.slowToString();
      // If [name] is not in [argumentsBuffer], then the parameter is
      // an optional parameter that was not provided for that stub.
      if (argumentsBuffer.indexOf(name) == -1) return;
      DartType type = parameter.computeType(compiler).unalias(compiler);
      if (type is FunctionType) {
        // The parameter type is a function type either directly or through
        // typedef(s).
        int arity = type.computeArity();
        code.add('  $name = $closureConverter($name, $arity);\n');
      }
    });
  }

  String generateParameterStub(Element member,
                               String invocationName,
                               String stubParameters,
                               List<String> argumentsBuffer,
                               int indexOfLastOptionalArgumentInParameters,
                               CodeBuffer buffer) {
    // The target JS function may check arguments.length so we need to
    // make sure not to pass any unspecified optional arguments to it.
    // For example, for the following Dart method:
    //   foo([x, y, z]);
    // The call:
    //   foo(y: 1)
    // must be turned into a JS call to:
    //   foo(null, y).

    List<String> nativeArgumentsBuffer = argumentsBuffer.getRange(
        0, indexOfLastOptionalArgumentInParameters + 1);

    ClassElement classElement = member.enclosingElement;
    String nativeTagInfo = classElement.nativeTagInfo.slowToString();
    String nativeArguments = Strings.join(nativeArgumentsBuffer, ",");

    CodeBuffer code = new CodeBuffer();
    potentiallyConvertDartClosuresToJs(code, member, argumentsBuffer);

    if (!nativeMethods.contains(member)) {
      // When calling a method that has a native body, we call it
      // with our calling conventions.
      String arguments = Strings.join(argumentsBuffer, ",");
      code.add('  return this.${backend.namer.getName(member)}($arguments)');
    } else {
      // When calling a JS method, we call it with the native name.
      String name = member.nativeName();
      code.add('  return this.$name($nativeArguments);');
    }

    if (isNativeLiteral(nativeTagInfo) || !overriddenMethods.contains(member)) {
      // Call the method directly.
      buffer.add(code.toString());
    } else {
      native.generateMethodWithPrototypeCheck(
          compiler, buffer, invocationName, code.toString(), stubParameters);
    }
  }

  void emitDynamicDispatchMetadata() {
    if (classesWithDynamicDispatch.isEmpty) return;
    int length = classesWithDynamicDispatch.length;
    nativeBuffer.add('// $length dynamic classes.\n');

    // Build a pre-order traversal over all the classes and their subclasses.
    Set<ClassElement> seen = new Set<ClassElement>();
    List<ClassElement> classes = <ClassElement>[];
    void visit(ClassElement cls) {
      if (seen.contains(cls)) return;
      seen.add(cls);
      getDirectSubclasses(cls).forEach(visit);
      classes.add(cls);
    }
    classesWithDynamicDispatch.forEach(visit);

    Collection<ClassElement> preorderDispatchClasses = classes.filter(
        (cls) => !getDirectSubclasses(cls).isEmpty &&
                  classesWithDynamicDispatch.contains(cls));

    nativeBuffer.add('// ${classes.length} classes\n');
    Collection<ClassElement> classesThatHaveSubclasses = classes.filter(
        (ClassElement t) => !getDirectSubclasses(t).isEmpty);
    nativeBuffer.add('// ${classesThatHaveSubclasses.length} !leaf\n');

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
    Map<String, js.Expression> varDefns = new Map<String, js.Expression>();

    // Expression to compute tags string for a class.  The expression will
    // initially be a string or expression building a string, but may be
    // replaced with a variable reference to the common substring.
    Map<ClassElement, js.Expression> tagDefns =
        new Map<ClassElement, js.Expression>();

    js.Expression makeExpression(ClassElement classElement) {
      // Expression fragments for this set of cls keys.
      List<js.Expression> expressions = <js.Expression>[];
      // TODO: Remove if cls is abstract.
      List<String> subtags = [toNativeTag(classElement)];
      void walk(ClassElement cls) {
        for (final ClassElement subclass in getDirectSubclasses(cls)) {
          ClassElement tag = subclass;
          js.Expression existing = tagDefns[tag];
          if (existing == null) {
            // [subclass] is still within the subtree between dispatch classes.
            subtags.add(toNativeTag(tag));
            walk(subclass);
          } else {
            // [subclass] is one of the preorderDispatchClasses, so CSE this
            // reference with the previous reference.
            if (existing is js.VariableUse &&
                varDefns.containsKey(existing.name)) {
              // We end up here if the subclasses have a DAG structure.  We
              // don't have DAGs yet, but if the dispatch is used for mixins
              // that will be a possibility.
              // Re-use the previously created temporary variable.
              expressions.add(new js.VariableUse(existing.name));
            } else {
              String varName = 'v${varNames.length}_${tag.name.slowToString()}';
              varNames.add(varName);
              varDefns[varName] = existing;
              tagDefns[tag] = new js.VariableUse(varName);
              expressions.add(new js.VariableUse(varName));
            }
          }
        }
      }
      walk(classElement);

      if (!subtags.isEmpty) {
        expressions.add(
            new js.LiteralString("'${Strings.join(subtags, '|')}'"));
      }
      js.Expression expression;
      if (expressions.length == 1) {
        expression = expressions[0];
      } else {
        js.Expression array = new js.ArrayInitializer.from(expressions);
        expression = new js.Call(
            new js.PropertyAccess.field(array, 'join'),
            [new js.LiteralString("'|'")]);
      }
      return expression;
    }

    for (final ClassElement classElement in preorderDispatchClasses) {
      tagDefns[classElement] = makeExpression(classElement);
    }

    // Write out a thunk that builds the metadata.
    if (!tagDefns.isEmpty) {
      List<js.Statement> statements = <js.Statement>[];

      List<js.VariableInitialization> initializations =
          <js.VariableInitialization>[];
      for (final String varName in varNames) {
        initializations.add(
            new js.VariableInitialization(
                new js.VariableDeclaration(varName),
                varDefns[varName]));
      }
      if (!initializations.isEmpty) {
        statements.add(
            new js.ExpressionStatement(
                new js.VariableDeclarationList(initializations)));
      }

      // [table] is a list of lists, each inner list of the form:
      //   [dynamic-dispatch-tag, tags-of-classes-implementing-dispatch-tag]
      // E.g.
      //   [['Node', 'Text|HTMLElement|HTMLDivElement|...'], ...]
      js.Expression table =
          new js.ArrayInitializer.from(
              preorderDispatchClasses.map((cls) =>
                  new js.ArrayInitializer.from([
                      new js.LiteralString("'${toNativeTag(cls)}'"),
                      tagDefns[cls]])));

      //  $.dynamicSetMetadata(table);
      statements.add(
          new js.ExpressionStatement(
              new js.Call(
                  new js.VariableUse(dynamicSetMetadataName),
                  [table])));

      //  (function(){statements})();
      nativeBuffer.add(
          js.prettyPrint(
              new js.ExpressionStatement(
                  new js.Call(new js.Fun([], new js.Block(statements)), [])),
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

  void emitIsChecks(Map<String, String> objectProperties) {
    for (Element element in emitter.checkedClasses) {
      if (!requiresNativeIsCheck(element)) continue;
      if (element.isObject(compiler)) continue;
      String name = backend.namer.operatorIs(element);
      objectProperties[name] = 'function() { return false; }';
    }
  }

  void assembleCode(CodeBuffer targetBuffer) {
    if (nativeClasses.isEmpty) return;
    emitDynamicDispatchMetadata();
    targetBuffer.add('$defineNativeClassName = '
                     '$defineNativeClassFunction;\n\n');

    // Because of native classes, we have to generate some is checks
    // by calling a method, instead of accessing a property. So we
    // attach to the JS Object prototype these methods that return
    // false, and will be overridden by subclasses when they have to
    // return true.
    Map<String, String> objectProperties = new Map<String, String>();
    emitIsChecks(objectProperties);

    // In order to have the toString method on every native class,
    // we must patch the JS Object prototype with a helper method.
    String toStringName = backend.namer.publicInstanceMethodNameByArity(
        const SourceString('toString'), 0);
    objectProperties[toStringName] =
        'function() { return $toStringHelperName(this); }';

    // Same as above, but for hashCode.
    String hashCodeName = backend.namer.publicGetterName(
        const SourceString('hashCode'));
    objectProperties[hashCodeName] =
        'function() { return $hashCodeHelperName(this); }';

    // If the native emitter has been asked to take care of the
    // noSuchMethod handlers, we do that now.
    if (handleNoSuchMethod) {
      emitter.emitNoSuchMethodHandlers((String name, CodeBuffer buffer) {
        objectProperties[name] = buffer.toString();
      });
    }

    // If we have any properties to add to Object.prototype, we run
    // through them and add them using defineProperty.
    if (!objectProperties.isEmpty) {
      targetBuffer.add("(function(table) {\n"
                       "  for (var key in table) {\n"
                       "    $defPropName(Object.prototype, key, table[key]);\n"
                       "  }\n"
                       "})({\n");
      bool first = true;
      objectProperties.forEach((String name, String function) {
        if (!first) targetBuffer.add(",\n");
        targetBuffer.add(" $name: $function");
        first = false;
      });
      targetBuffer.add("\n});\n\n");
    }
    targetBuffer.add(nativeBuffer);
    targetBuffer.add('\n');
  }
}
