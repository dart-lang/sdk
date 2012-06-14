// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Top level generator object for writing code and keeping track of
 * dependencies.
 *
 * Should have two compilation models, but only one implemented so far.
 *
 * 1. Do a top-level resolution of all types and their members.
 * 2. Start from main and walk the call-graph compiling members as needed.
 * 2a. That includes compiling overriding methods and calling methods by
 *     selector when invoked on var.
 * 3. Spit out all required code.
 */
class WorldGenerator {
  MethodMember main;
  CodeWriter writer;
  CodeWriter _mixins;

  final CallingContext mainContext;

  /**
   * Whether the app has any static fields used. Note this could still be true
   * and [globals] be empty if no static field has a default initialization.
   */
  bool hasStatics = false;

  /** Global const and static field initializations. */
  Map<String, GlobalValue> globals;
  CoreJs corejs;

  /** */
  Set<Type> typesWithDynamicDispatch;

  /**
   * For a type, which type-checks are on the prototype chain, and to they match
   * or not?  Type checks are in-predicates (x is T) and type assertions.
   */
  Map<Type, Map<String, bool>> typeEmittedTests;

  WorldGenerator(main, this.writer)
    : this.main = main,
      mainContext = new MethodGenerator(main, null),
      globals = {},
      corejs = new CoreJs();

  analyze() {
    // Walk all code and find all NewExpressions - to determine possible types
    int nlibs=0, ntypes=0, nmems=0, nnews=0;
    for (var lib in world.libraries.getValues()) {
      nlibs += 1;
      for (var type in lib.types.getValues()) {
        // TODO(jmesserly): we can't accurately track if DOM types are
        // created or not, so we need to prepare to handle them.
        // This should be fixed by tightening up the return types in DOM.
        // Until then, this 'analysis' just marks all the DOM types as used.
        // TODO(jimhug): Do we still need this?  Or do/can we handle this by
        // using return values?
        if (type.library.isDomOrHtml || type.isHiddenNativeType) {
          if (type.isClass) type.markUsed();
        }

        ntypes += 1;
        var allMembers = [];
        allMembers.addAll(type.constructors.getValues());
        allMembers.addAll(type.members.getValues());
        type.factories.forEach((f) => allMembers.add(f));
        for (var m in allMembers) {
          if (m.isAbstract || !(m.isMethod || m.isConstructor)) continue;
          m.methodData.analyze();
        }
      }
    }
  }

  run() {
    var mainTarget = new TypeValue(main.declaringType, main.span);
    var mainCall = main.invoke(mainContext, null, mainTarget, Arguments.EMPTY);
    main.declaringType.markUsed();

    if (options.compileAll) {
      markLibrariesUsed(
          [world.coreimpl, world.corelib, main.declaringType.library]);
    }

    // These are essentially always used through literals - just include them
    world.numImplType.markUsed();
    world.stringImplType.markUsed();

    if (corejs.useIndex || corejs.useSetIndex) {
      if (!options.disableBoundsChecks) {
        // These exceptions might be thrown by array bounds checks.
        markTypeUsed(world.corelib.types['IndexOutOfRangeException']);
        markTypeUsed(world.corelib.types['IllegalArgumentException']);
      }
    }

    // Only wrap the app as an isolate if the isolate library was imported.
    if (world.isolatelib != null) {
      corejs.useIsolates = true;
      MethodMember isolateMain =
        world.isolatelib.lookup('startRootIsolate', main.span);
      mainCall = isolateMain.invoke(mainContext, null,
          new TypeValue(world.isolatelib.topType, main.span),
          new Arguments(null, [main._get(mainContext, main.definition, null)]));
    }

    typeEmittedTests = new Map<Type, Map<String, bool>>();

    writeTypes(world.coreimpl);
    writeTypes(world.corelib);

    // Write the main library. This will cause all libraries to be written in
    // the topological sort order.
    writeTypes(main.declaringType.library);

    // Write out any inherited concrete members.
    // TODO(jmesserly): this won't need to come last once we are sorting types
    // correctly.
    if (_mixins != null) writer.write(_mixins.text);

    writeDynamicDispatchMetadata();

    writeGlobals();
    writer.writeln("if (typeof window != 'undefined' && typeof document != 'undefined' &&");
    writer.writeln("    window.addEventListener && document.readyState == 'loading') {");
    writer.writeln("  window.addEventListener('DOMContentLoaded', function(e) {");
    writer.writeln("    ${mainCall.code};");
    writer.writeln("  });");
    writer.writeln("} else {");
    writer.writeln("  ${mainCall.code};");
    writer.writeln("}");
  }

  void markLibrariesUsed(List<Library> libs) =>
    getAllTypes(libs).forEach(markTypeUsed);

  void markTypeUsed(Type type) {
    if (!type.isClass) return;

    type.markUsed();
    type.isTested = true;
    // (e.g. Math, console, process)
    type.isTested = !type.isTop && !(type.isNative &&
        type.members.getValues().every((m) => m.isStatic && !m.isFactory));
    final members = new List.from(type.members.getValues());
    members.addAll(type.constructors.getValues());
    type.factories.forEach((f) => members.add(f));
    for (var member in members) {
      if (member is PropertyMember) {
        if (member.getter != null) genMethod(member.getter);
        if (member.setter != null) genMethod(member.setter);
      }

      if (member is MethodMember) genMethod(member);
    }
  }

  void writeAllDynamicStubs(List<Library> libs) =>
    getAllTypes(libs).forEach((Type type) {
      if (type.isClass || type.isFunction) _writeDynamicStubs(type);
    });

  List<Type> getAllTypes(List<Library> libs) {
    List<Type> types = <Type>[];
    Set<Library> seen = new Set<Library>();
    for (var mainLib in libs) {
      Queue<Library> toCheck = new Queue.from([mainLib]);
      while (!toCheck.isEmpty()) {
        var lib = toCheck.removeFirst();
        if (seen.contains(lib)) continue;
        seen.add(lib);
        lib.imports.forEach((i) => toCheck.addLast(lib));
        lib.types.getValues().forEach((t) => types.add(t));
      }
    }
    return types;
  }

  GlobalValue globalForStaticField(FieldMember field, Value exp,
      List<Value> dependencies) {
    hasStatics = true;
    var key = "${field.declaringType.jsname}.${field.jsname}";
    var ret = globals[key];
    if (ret === null) {
      ret = new GlobalValue(exp.type, exp.code, field.isFinal, field, null,
        exp, exp.span, dependencies);
      globals[key] = ret;
    }
    return ret;
  }

  GlobalValue globalForConst(Value exp, List<Value> dependencies) {
    // Include type name to ensure unique constants - this matches
    // the code above that includes the type name for static fields.
    var key = '${exp.type.jsname}:${exp.code}';
    var ret = globals[key];
    if (ret === null) {
      // another egregious hack!!!
      var ns = globals.length.toString();
      while (ns.length < 4) ns = '0$ns';
      var name = "const\$${ns}";
      ret = new GlobalValue(exp.type, name, true, null, name, exp,
          exp.span, dependencies);
      globals[key] = ret;
    }
    assert(ret.type == exp.type);
    return ret;
  }

  writeTypes(Library lib) {
    if (lib.isWritten) return;

    // Do this first to be safe in the face of circular refs.
    lib.isWritten = true;

    // Ensure all imports have been written.
    for (var import in lib.imports) {
      writeTypes(import.library);
    }

    // Ensure that our source files have a notion of "order" so we can emit
    // types in the same order source files are imported.
    for (int i = 0; i < lib.sources.length; i++) {
      lib.sources[i].orderInLibrary = i;
    }

    writer.comment('//  ********** Library ${lib.name} **************');
    if (lib.isCore) {
      // Generates the JS natives for dart:core.
      writer.comment('//  ********** Natives dart:core **************');
      corejs.generate(writer);
    }
    for (var file in lib.natives) {
      var filename = basename(file.filename);
      writer.comment('//  ********** Natives $filename **************');
      writer.writeln(file.text);
    }
    lib.topType.markUsed(); // TODO(jimhug): EGREGIOUS HACK

    var orderedTypes = _orderValues(lib.types);

    for (var type in orderedTypes) {
      if (type.isUsed && type.isClass) {
        writeType(type);
        // TODO(jimhug): Performance is terrible if we use current
        // reified generics approach for reified generic Arrays.
        if (type.isGeneric && type !== world.listFactoryType) {
          for (var ct in _orderValues(type._concreteTypes)) {
            if (ct.isUsed) writeType(ct);
          }
        }
      } else if (type.isFunction && type.varStubs.length > 0) {
        // Emit stubs on "Function" if needed
        writer.comment('// ********** Code for ${type.jsname} **************');
        _writeDynamicStubs(type);
      }
      // Type check functions for builtin JS types
      if (type.typeCheckCode != null) {
        writer.writeln(type.typeCheckCode);
      }
    }
  }

  genMethod(MethodMember meth) {
    meth.methodData.run(meth);
  }

  String _prototypeOf(Type type, String name) {
    if (type.isSingletonNative) {
      // e.g. window.console.log$1
      return '${type.jsname}.$name';
    } else if (type.isHiddenNativeType) {
      corejs.ensureDynamicProto();
      _usedDynamicDispatchOnType(type);
      return '\$dynamic("$name").${type.definition.nativeType.name}';
    } else {
      return '${type.jsname}.prototype.$name';
    }
  }

  /**
   * Make sure the methods that we add to Array and Object are
   * non-enumerable, so that we don't mess up any other third-party JS
   * libraries we might be using.
   * We return the necessary suffix (if any) we need to complete the patching.
   */
  String _writePrototypePatch(Type type, String name, String functionBody,
      CodeWriter writer, [bool isOneLiner=true]) {
    var writeFunction = writer.writeln;
    String ending = ';';
    if (!isOneLiner) {
      writeFunction = writer.enterBlock;
      ending = '';
    }
    if (type.isObject) {
      world.counters.objectProtoMembers++;
    }
    if (type.isObject || type.genericType == world.listFactoryType) {
      // We special case these two so that by default we can use "= function()"
      // syntax for better readability of the others.
      if (isOneLiner) {
        ending = ')$ending';
      }
      corejs.ensureDefProp();
      writeFunction(
          '\$defProp(${type.jsname}.prototype, "$name", $functionBody$ending');
      if (isOneLiner) return '}';
      return '});';
    } else {
      writeFunction('${_prototypeOf(type, name)} = ${functionBody}${ending}');
      return isOneLiner? '': '}';
    }
  }

  _maybeIsTest(Type onType, Type checkType) {
    bool isSubtype = onType.isSubtypeOf(checkType);

    var onTypeMap = typeEmittedTests[onType];
    if (onTypeMap == null) typeEmittedTests[onType] = onTypeMap = {};

    Type protoParent = onType.genericType == onType
        ? onType.parent
        : onType.genericType;

    needToOverride(checkName) {
      if (protoParent != null) {
        var map = typeEmittedTests[protoParent];
        if (map != null) {
          bool protoParentIsSubtype = map[checkName];
          if (protoParentIsSubtype != null &&
              protoParentIsSubtype == isSubtype) {
            return false;
          }
        }
      }
      return true;
    }

    if (checkType.isTested) {
      String checkName = 'is\$${checkType.jsname}';
      onTypeMap[checkName] = isSubtype;
      if (needToOverride(checkName)) {
        // TODO(jmesserly): cache these functions? they just return true or
        // false.
        _writePrototypePatch(onType, checkName,
            'function(){return $isSubtype}', writer);
      }
    }

    if (checkType.isChecked) {
      String checkName = 'assert\$${checkType.jsname}';
      onTypeMap[checkName] = isSubtype;
      if (needToOverride(checkName)) {
        String body = 'return this';
        if (!isSubtype) {
          // Get the code to throw a TypeError.
          // TODO(jmesserly): it'd be nice not to duplicate this code, and
          // instead be able to refer to the JS function.
          body = world.objectType.varStubs[checkName].body;
        } else if (onType == world.stringImplType
                   || onType == world.numImplType) {
          body = 'return ${onType.nativeType.name}(this)';
        }
        _writePrototypePatch(onType, checkName, 'function(){$body}', writer);
      }
    }
  }

  writeType(Type type) {
    if (type.isWritten) return;

    type.isWritten = true;
    writeType(type.genericType);
    // Ensure parent has been written before the child. Important ordering for
    // IE when we're using $inherits, since we don't have __proto__ available.
    if (type.parent !=  null) {
      writeType(type.parent);
    }

    var typeName = type.jsname != null ? type.jsname : 'top level';
    writer.comment('// ********** Code for ${typeName} **************');
    if (type.isNative && !type.isTop && !type.isConcreteGeneric) {
      var nativeName = type.definition.nativeType.name;
      if (nativeName == '') {
        writer.writeln('function ${type.jsname}() {}');
      } else if (type.jsname != nativeName) {
        if (type.isHiddenNativeType) {
          if (_hasStaticOrFactoryMethods(type)) {
            writer.writeln('var ${type.jsname} = {};');
          }
        } else {
          writer.writeln('var ${type.jsname} = ${nativeName};');
        }
      }
    }

    // We need the $inherits call to immediately follow the standard constructor
    // declaration. In particular, it needs to be called before factory
    // constructors are declared, otherwise $inherits will clear out the
    // prototype on IE (which does not have writable __proto__).
    if (!type.isTop) {
      if (type.genericType !== type) {
        corejs.ensureInheritsHelper();
        writer.writeln('\$inherits(${type.jsname}, ${type.genericType.jsname});');
      } else if (!type.isNative) {
        if (type.parent != null && !type.parent.isObject) {
          corejs.ensureInheritsHelper();
          writer.writeln('\$inherits(${type.jsname}, ${type.parent.jsname});');
        }
      }
    }

    if (type.isTop) {
      // no preludes for top type
    } else if (type.constructors.length == 0) {
      if (!type.isNative || type.isConcreteGeneric) {
        // TODO(jimhug): More guards to guarantee staticness
        writer.writeln('function ${type.jsname}() {}');
      }
    } else {
      bool wroteStandard = false;
      for (var c in type.constructors.getValues()) {
        if (c.methodData.writeDefinition(c, writer)) {
          if (c.isConstructor && c.constructorName == '') wroteStandard = true;
        }
      }

      if (!wroteStandard && (!type.isNative || type.genericType !== type)) {
        writer.writeln('function ${type.jsname}() {}');
      }
    }

    // Concrete types (like List<String>) will have this already defined on
    // their prototype from the generic type (like List)
    if (!type.isConcreteGeneric) {
      _maybeIsTest(type, type);
    }
    if (type.genericType._concreteTypes != null) {
      for (var ct in _orderValues(type.genericType._concreteTypes)) {
        _maybeIsTest(type, ct);
      }
    }

    if (type.interfaces != null) {
      final seen = new Set();
      final worklist = [];
      worklist.addAll(type.interfaces);
      seen.addAll(type.interfaces);
      while (!worklist.isEmpty()) {
        var interface_ = worklist.removeLast();
        _maybeIsTest(type, interface_.genericType);
        if (interface_.genericType._concreteTypes != null) {
          for (var ct in _orderValues(interface_.genericType._concreteTypes)) {
            _maybeIsTest(type, ct);
          }
        }
        for (var other in interface_.interfaces) {
          if (!seen.contains(other)) {
            worklist.addLast(other);
            seen.add(other);
          }
        }
      }
    }

    type.factories.forEach(_writeMethod);

    for (var member in _orderValues(type.members)) {
      if (member is FieldMember) {
        _writeField(member);
      }

      if (member is PropertyMember) {
        _writeProperty(member);
      }

      if (member.isMethod) {
        _writeMethod(member);
      }
    }

    _writeDynamicStubs(type);
  }

  /**
   * Returns [:true:] if the hidden native type has any static or factory
   * methods.
   *
   *  class Float32Array native '*Float32Array' {
   *    factory Float32Array(int len) => _construct(len);
   *    static _construct(len) native 'return createFloat32Array(len);';
   *  }
   *
   * The factory method and static member are generated something like this:
   *    var lib_Float32Array = {};
   *    lib_Float32Array.Float32Array$factory = ... ;
   *    lib_Float32Array._construct = ... ;
   *
   * This predicate determines when we need to define lib_Float32Array.
   */
  bool _hasStaticOrFactoryMethods(Type type) {
    // TODO(jmesserly): better tracking if the methods are actually called.
    // For now we assume that if the type is used, the method is used.
    return type.members.getValues().some((m) => m.isMethod && m.isStatic)
        || !type.factories.isEmpty();
  }

  _writeDynamicStubs(Type type) {
    for (var stub in orderValuesByKeys(type.varStubs)) {
      if (!stub.isGenerated) stub.generate(writer);
    }
  }

  _writeStaticField(FieldMember field) {
    // Final static fields must be constants which will be folded and inlined.
    if (field.isFinal) return;

    var fullname = "${field.declaringType.jsname}.${field.jsname}";
    if (globals.containsKey(fullname)) {
      var value = globals[fullname];
      if (field.declaringType.isTop && !field.isNative) {
        writer.writeln('\$globals.${field.jsname} = ${value.exp.code};');
      } else {
        writer.writeln('\$globals.${field.declaringType.jsname}_${field.jsname}'
            + ' = ${value.exp.code};');
      }
    }
    // No need to write code for a static class field with no initial value.
  }

  _writeField(FieldMember field) {
    // Generate declarations for static top-level fields with no value.
    if (field.declaringType.isTop && !field.isNative && field.value == null) {
      writer.writeln('var ${field.jsname};');
    }

    // generate code for instance fields
    if (field._provideGetter &&
        !field.declaringType.isConcreteGeneric) {
      _writePrototypePatch(field.declaringType, field.jsnameOfGetter,
          'function() { return this.${field.jsname}; }', writer);
    }
    if (field._provideSetter &&
        !field.declaringType.isConcreteGeneric) {
      _writePrototypePatch(field.declaringType, field.jsnameOfSetter,
          'function(value) { return this.${field.jsname} = value; }', writer);
    }

    // TODO(jimhug): Currently choose not to initialize fields on objects, but
    //    instead to rely on uninitialized === null in our generated code.
    //    Investigate the perf pros and cons of this.
  }

  _writeProperty(PropertyMember property) {
    if (property.getter != null) _writeMethod(property.getter);
    if (property.setter != null) _writeMethod(property.setter);

    // TODO(jmesserly): make sure we don't do this on hidden native types!
    if (property.needsFieldSyntax) {
      writer.enterBlock('Object.defineProperty('
        '${property.declaringType.jsname}.prototype, "${property.jsname}", {');
      if (property.getter != null) {
        writer.write(
          'get: ${property.declaringType.jsname}.prototype.${property.getter.jsname}');
        // The shenanigan below is to make IE happy -- IE 9 doesn't like a
        // trailing comma on the last element in a list.
        writer.writeln(property.setter == null ? '' : ',');
      }
      if (property.setter != null) {
        writer.writeln(
          'set: ${property.declaringType.jsname}.prototype.${property.setter.jsname}');
      }
      writer.exitBlock('});');
    }
  }

  _writeMethod(MethodMember m) {
    m.methodData.writeDefinition(m, writer);

    if (m.isNative && m._provideGetter) {
      if (MethodGenerator._maybeGenerateBoundGetter(m, writer)) {
        world.gen.corejs.ensureBind();
      }
    }
  }

  writeGlobals() {
    if (globals.length > 0) {
      writer.comment('//  ********** Globals **************');
      var list = globals.getValues();
      list.sort((a, b) => a.compareTo(b));

      // put all static field initializations in a method
      writer.enterBlock('function \$static_init(){');
      for (var global in list) {
        if (global.field != null) {
          _writeStaticField(global.field);
        }
      }
      writer.exitBlock('}');

      // Keep const expressions shared across isolates. Note that the frog
      // isolate library needs this because we wrote it's bootstrap and
      // book-keeping directly in Dart. Specifically, that code uses
      // [HashMapImplementation] which internally uses a constant expression.
      for (var global in list) {
        if (global.field == null) {
          writer.writeln('var ${global.name} = ${global.exp.code};');
        }
      }
    }

    if (!corejs.useIsolates) {
      if (hasStatics) {
        writer.writeln('var \$globals = {};');
      }
      if (globals.length > 0) {
        writer.writeln('\$static_init();');
      }
    }
  }

  _usedDynamicDispatchOnType(Type type) {
    if (typesWithDynamicDispatch == null) typesWithDynamicDispatch = new Set();
    typesWithDynamicDispatch.add(type);
  }

  writeDynamicDispatchMetadata() {
    if (typesWithDynamicDispatch == null) return;
    writer.comment('// ${typesWithDynamicDispatch.length} dynamic types.');

    // Build a pre-order traversal over all the types and their subtypes.
    var seen = new Set();
    var types = [];
    visit(type) {
      if (seen.contains(type)) return;
      seen.add(type);
      for (final subtype in _orderCollectionValues(type.directSubtypes)) {
        visit(subtype);
      }
      types.add(type);
    }
    for (final type in _orderCollectionValues(typesWithDynamicDispatch)) {
      visit(type);
    }

    var dispatchTypes = types.filter(
        (type) => !type.directSubtypes.isEmpty() &&
                  typesWithDynamicDispatch.contains(type));

    writer.comment('// ${types.length} types');
    writer.comment(
        '// ${types.filter((t) => !t.directSubtypes.isEmpty()).length} !leaf');

    // Generate code that builds the map from type tags used in dynamic dispatch
    // to the set of type tags of types that extend (TODO: or implement) those
    // types.  The set is represented as a string of tags joined with '|'.  This
    // is easily split into an array of tags, or converted into a regexp.
    //
    // To reduce the size of the sets, subsets are CSE-ed out into variables.
    // The sets could be much smaller if we could make assumptions about the
    // type tags of other types (which are constructor names or part of the
    // result of Object.prototype.toString).  For example, if objects that are
    // Dart objects could be easily excluded, then we might be able to simplify
    // the test, replacing dozens of HTMLxxxElement types with the regexp
    // /HTML.*Element/.

    var varNames = [];  // temporary variables for common substrings.
    var varDefns = {};  // var -> expression
    var tagDefns = {};  // tag -> expression (a string or a variable)

    makeExpression(type) {
      var expressions = [];  // expression fragments for this set of type keys.
      var subtags = [type.nativeName];  // TODO: Remove if type is abstract.
      walk(type) {
        for (final subtype in _orderCollectionValues(type.directSubtypes)) {
          var tag = subtype.nativeName;
          var existing = tagDefns[tag];
          if (existing == null) {
            subtags.add(tag);
            walk(subtype);
          } else {
            if (varDefns.containsKey(existing)) {
              expressions.add(existing);
            } else {
              var varName = 'v${varNames.length}/*${tag}*/';
              varNames.add(varName);
              varDefns[varName] = existing;
              tagDefns[tag] = varName;
              expressions.add(varName);
            }
          }
        }
      }
      walk(type);
      var constantPart = "'${Strings.join(subtags, '|')}'";
      if (constantPart != "''") expressions.add(constantPart);
      var expression;
      if (expressions.length == 1) {
        expression = expressions[0];
      } else {
        expression = "[${Strings.join(expressions, ',')}].join('|')";
      }
      return expression;
    }

    for (final type in dispatchTypes) {
      tagDefns[type.nativeName] = makeExpression(type);
    }

    // Write out a thunk that builds the metadata.

    if (!tagDefns.isEmpty()) {
      corejs.ensureDynamicSetMetadata();
      writer.enterBlock('(function(){');

      for (final varName in varNames) {
        writer.writeln('var ${varName} = ${varDefns[varName]};');
      }

      writer.enterBlock('var table = [');
      writer.comment(
          '// [dynamic-dispatch-tag, '
          + 'tags of classes implementing dynamic-dispatch-tag]');
      bool needsComma = false;
      for (final type in dispatchTypes) {
        if (needsComma) {
          writer.write(', ');
        }
        writer.writeln("['${type.nativeName}', ${tagDefns[type.nativeName]}]");
        needsComma = true;
      }
      writer.exitBlock('];');
      writer.writeln('\$dynamicSetMetadata(table);');

      writer.exitBlock('})();');
    }
  }

  /** Order a list of values in a Map by SourceSpan, then by name. */
  List _orderValues(Map map) {
    // TODO(jmesserly): should we copy the list?
    // Right now, the Maps are returning a copy already.
    List values = map.getValues();
    values.sort(_compareMembers);
    return values;
  }

  /** Order a list of values in a Collection by SourceSpan, then by name. */
  List _orderCollectionValues(Collection collection) {
    List values = new List.from(collection);
    values.sort(_compareMembers);
    return values;
  }

  int _compareMembers(x, y) {
    if (x.span != null && y.span != null) {
      // First compare by source span.
      int spans = x.span.compareTo(y.span);
      if (spans != 0) return spans;
    } else {
      // With-spans before sans-spans.
      if (x.span != null) return -1;
      if (y.span != null) return 1;
    }
    // If that fails, compare by name, null comes first.
    if (x.name == y.name) return 0;
    if (x.name == null) return -1;
    if (y.name == null) return 1;
    return x.name.compareTo(y.name);
  }
}


/**
 * A naive code generator for Dart.
 */
class MethodGenerator implements TreeVisitor, CallingContext {
  Member method;
  CodeWriter writer;
  BlockScope _scope;
  MethodGenerator enclosingMethod;
  bool needsThis;
  List<String> _paramCode;

  // TODO(jmesserly): if we knew temps were always used like a stack, we could
  // reduce the overhead here.
  List<String> _freeTemps;
  Set<String> _usedTemps;

  /**
   * The set of variables that this lambda closes that need to capture
   * with Function.prototype.bind. This is any variable that lives inside a
   * reentrant block scope (e.g. loop bodies).
   *
   * This field is null if we don't need to track this.
   */
  Set<String> captures;

  CounterLog counters;

  MethodGenerator(this.method, this.enclosingMethod)
      : writer = new CodeWriter(), needsThis = false {
    if (enclosingMethod != null) {
      _scope = new BlockScope(this, enclosingMethod._scope, method.definition);
      captures = new Set();
    } else {
      _scope = new BlockScope(this, null, method.definition);
    }
    _usedTemps = new Set();
    _freeTemps = [];
    counters = world.counters;
  }

  Library get library() => method.library;

  // TODO(jimhug): Where does this really belong?
  MemberSet findMembers(String name) {
    return library._findMembers(name);
  }

  bool get needsCode() => true;
  bool get showWarnings() => false;

  bool get isClosure() => (enclosingMethod != null);

  bool get isStatic() => method.isStatic;

  Value getTemp(Value value) {
    return value.needsTemp ? forceTemp(value) : value;
  }

  VariableValue forceTemp(Value value) {
    String name;
    if (_freeTemps.length > 0) {
      name = _freeTemps.removeLast();
    } else {
      name = '\$${_usedTemps.length}';
    }
    _usedTemps.add(name);
    return new VariableValue(value.staticType, name, value.span, false, value);
  }

  Value assignTemp(Value tmp, Value v) {
    if (tmp == v) {
      return v;
    } else {
      // TODO(jmesserly): we should mark this returned value with the temp
      // somehow, so getTemp will reuse it instead of allocating a new one.
      // (we could do this now if we had a "TempValue" or something like that)
      return new Value(v.type, '(${tmp.code} = ${v.code})', v.span);
    }
  }

  void freeTemp(VariableValue value) {
    // TODO(jimhug): Need to do this right - for now we can just skip freeing.
    /*
    if (_usedTemps.remove(value.code)) {
      _freeTemps.add(value.code);
    } else {
      world.internalError(
        'tried to free unused value or non-temp "${value.code}"');
    }
    */
  }

  run() {
    // Create most generic possible call for this method.
    var thisObject;
    if (method.isConstructor) {
      thisObject = new ObjectValue(false, method.declaringType, method.span);
      thisObject.initFields();
    } else {
      thisObject = new Value(method.declaringType, 'this', null);
    }
    var values = [];
    for (var p in method.parameters) {
      values.add(new Value(p.type, p.name, null));
    }
    var args = new Arguments(null, values);

    evalBody(thisObject, args);
  }


  writeDefinition(CodeWriter defWriter, LambdaExpression lambda/*=null*/) {
    // To implement block scope: capture any variables we need to.
    var paramCode = _paramCode;
    var names = null;
    if (captures != null && captures.length > 0) {
      names = new List.from(captures);
      names.sort((x, y) => x.compareTo(y));
      // Prepend these as extra parameters. We'll bind them below.
      paramCode = new List.from(names);
      paramCode.addAll(_paramCode);
    }

    String _params = '(${Strings.join(_paramCode, ", ")})';
    String params = '(${Strings.join(paramCode, ", ")})';
    String suffix = '}';
    // TODO(jmesserly): many of these are similar, it'd be nice to clean up.
    if (method.declaringType.isTop && !isClosure) {
      defWriter.enterBlock('function ${method.jsname}$params {');
    } else if (isClosure) {
      if (method.name == '') {
        defWriter.enterBlock('(function $params {');
      } else if (names != null) {
        if (lambda == null) {
          defWriter.enterBlock('var ${method.jsname} = (function$params {');
        } else {
          defWriter.enterBlock('(function ${method.jsname}$params {');
        }
      } else {
        defWriter.enterBlock('function ${method.jsname}$params {');
      }
    } else if (method.isConstructor) {
      if (method.constructorName == '') {
        defWriter.enterBlock('function ${method.declaringType.jsname}$params {');
      } else {
        defWriter.enterBlock('${method.declaringType.jsname}.${method.constructorName}\$ctor = function$params {');
      }
    } else if (method.isFactory) {
      defWriter.enterBlock('${method.generatedFactoryName} = function$_params {');
    } else if (method.isStatic) {
      defWriter.enterBlock('${method.declaringType.jsname}.${method.jsname} = function$_params {');
    } else {
      suffix = world.gen._writePrototypePatch(method.declaringType,
          method.jsname, 'function$_params {', defWriter, false);
    }

    if (needsThis) {
      defWriter.writeln('var \$this = this;');
    }

    if (_usedTemps.length > 0 || _freeTemps.length > 0) {
      //TODO(jimhug): assert(_usedTemps.length == 0); // all temps should be freed.
      _freeTemps.addAll(_usedTemps);
      _freeTemps.sort((x, y) => x.compareTo(y));
      defWriter.writeln('var ${Strings.join(_freeTemps, ", ")};');
    }

    // TODO(jimhug): Lots of string translation here - perf bottleneck?
    defWriter.writeln(writer.text);

    bool usesBind = false;
    if (names != null) {
      usesBind = true;
      defWriter.exitBlock('}).bind(null, ${Strings.join(names, ", ")})');
    } else if (isClosure && method.name == '') {
      defWriter.exitBlock('})');
    } else {
      defWriter.exitBlock(suffix);
    }
    if (method.isConstructor && method.constructorName != '') {
      defWriter.writeln(
        '${method.declaringType.jsname}.${method.constructorName}\$ctor.prototype = '
        '${method.declaringType.jsname}.prototype;');
    }

    _provideOptionalParamInfo(defWriter);

    if (method is MethodMember) {
      if (_maybeGenerateBoundGetter(method, defWriter)) {
        usesBind = true;
      }
    }

    if (usesBind) world.gen.corejs.ensureBind();
  }

  static bool _maybeGenerateBoundGetter(MethodMember m, CodeWriter defWriter) {
    if (m._provideGetter) {
      String suffix = world.gen._writePrototypePatch(m.declaringType,
          m.jsnameOfGetter, 'function() {', defWriter, false);
      if (m.parameters.some((p) => p.isOptional)) {
        defWriter.writeln('var f = this.${m.jsname}.bind(this);');
        defWriter.writeln('f.\$optional = this.${m.jsname}.\$optional;');
        defWriter.writeln('return f;');
      } else {
        defWriter.writeln('return this.${m.jsname}.bind(this);');
      }
      defWriter.exitBlock(suffix);
      return true;
    }
    return false;
  }

  /**
   * Generates information about the default/named arguments into the JS code.
   * Only methods that are passed as bound methods to "var" need this. It is
   * generated to support run time stub creation.
   */
  _provideOptionalParamInfo(CodeWriter defWriter) {
    if (method is MethodMember) {
      MethodMember meth = method;
      if (meth._provideOptionalParamInfo) {
        var optNames = [];
        var optValues = [];
        meth.genParameterValues(this);
        for (var param in meth.parameters) {
          if (param.isOptional) {
            optNames.add(param.name);
            // TODO(jimhug): Remove this last usage of escapeString.
            optValues.add(_escapeString(param.value.code));
          }
        }
        if (optNames.length > 0) {
          // TODO(jmesserly): the logic for how to refer to
          // static/instance/top-level members is duplicated all over the place.
          // Badly needs cleanup.
          var start = '';
          if (meth.isStatic) {
            if (!meth.declaringType.isTop) {
              start = meth.declaringType.jsname + '.';
            }
          } else {
            start = meth.declaringType.jsname + '.prototype.';
          }

          optNames.addAll(optValues);
          var optional = "['${Strings.join(optNames, "', '")}']";
          defWriter.writeln('${start}${meth.jsname}.\$optional = $optional');
        }
      }
    }
  }

  _initField(ObjectValue newObject, String name, Value value, SourceSpan span) {
    var field = method.declaringType.getMember(name);
    if (field == null) {
      world.error('bad initializer - no matching field', span);
    }
    if (!field.isField) {
      world.error('"this.${name}" does not refer to a field', span);
    }
    return newObject.setField(field, value, duringInit: true);
  }

  evalBody(Value newObject, Arguments args) {
    bool fieldsSet = false;
    if (method.isNative && method.isConstructor && newObject is ObjectValue) {
      newObject.dynamic.seenNativeInitializer = true;
    }
    // Collects parameters for writing signature in the future.
    _paramCode = [];
    for (int i = 0; i < method.parameters.length; i++) {
      var p = method.parameters[i];
      Value currentArg = null;
      if (i < args.bareCount) {
        currentArg = args.values[i];
      } else {
        // Handle named or missing arguments
        currentArg = args.getValue(p.name);
        if (currentArg === null) {
          // Ensure default value for param has been generated
          p.genValue(method, this);
          currentArg = p.value;
          if (currentArg == null) {
            // Not enough arguments, we'll get an error later.
            return;
          }
        }
      }

      if (p.isInitializer) {
        _paramCode.add(p.name);
        fieldsSet = true;
        _initField(newObject, p.name, currentArg, p.definition.span);
      } else {
        var paramValue = _scope.declareParameter(p);
        _paramCode.add(paramValue.code);
        if (newObject != null && newObject.isConst) {
          _scope.assign(p.name, currentArg.convertTo(this, p.type));
        }
      }
    }

    var initializerCall = null;
    final declaredInitializers = method.definition.dynamic.initializers;
    if (declaredInitializers != null) {
      for (var init in declaredInitializers) {
        if (init is CallExpression) {
          if (initializerCall != null) {
            world.error('only one initializer redirecting call is allowed',
                init.span);
          }
          initializerCall = init;
        } else if (init is BinaryExpression
            && TokenKind.kindFromAssign(init.op.kind) == 0) {
          var left = init.x;
          if (!(left is DotExpression && left.self is ThisExpression
              || left is VarExpression)) {
            world.error('invalid left side of initializer', left.span);
            continue;
          }
          // TODO(jmesserly): eval right side of initializers in static
          // context, so "this." is not in scope
          var initValue = visitValue(init.y);
          fieldsSet = true;
          _initField(newObject, left.name.name, initValue, left.span);
        } else {
          world.error('invalid initializer', init.span);
        }
      }
    }

    if (method.isConstructor && initializerCall == null && !method.isNative) {
      var parentType = method.declaringType.parent;
      if (parentType != null && !parentType.isObject) {
        // TODO(jmesserly): we could omit this if all supertypes are using
        // default constructors.
        initializerCall = new CallExpression(
            new SuperExpression(method.span), [], method.span);
      }
    }

    if (method.isConstructor && newObject is ObjectValue) {
      var fields = newObject.dynamic.fields;
      for (var field in newObject.dynamic.fieldsInInitOrder) {
        if (field !== null) {
          var value = fields[field];
          if (value !== null) {
            writer.writeln('this.${field.jsname} = ${value.code};');
          }
        }
      }
    }

    // TODO(jimhug): Doing this call last does not match spec.
    if (initializerCall != null) {
      evalInitializerCall(newObject, initializerCall, fieldsSet);
    }

    if (method.isConstructor && newObject !== null && newObject.isConst) {
      newObject.validateInitialized(method.span);
    } else if (method.isConstructor) {
      var fields = newObject.dynamic.fields;
      for (var field in fields.getKeys()) {
        var value = fields[field];
        if (value === null && field.isFinal &&
            field.declaringType == method.declaringType &&
            !newObject.dynamic.seenNativeInitializer) {
          world.error('uninitialized final field "${field.name}"',
            field.span, method.span);
        }
      }
    }

    var body = method.definition.dynamic.body;

    if (body === null) {
      // TODO(jimhug): Move check into resolve on method.
      if (!method.isConstructor && !method.isNative) {
        world.error('unexpected empty body for ${method.name}',
          method.definition.span);
      }
    } else {
      visitStatementsInBlock(body);
    }
  }

  evalInitializerCall(ObjectValue newObject, CallExpression node,
      [bool fieldsSet = false]) {
    String contructorName = '';
    var targetExp = node.target;
    if (targetExp is DotExpression) {
      DotExpression dot = targetExp;
      targetExp = dot.self;
      contructorName = dot.name.name;
    }

    Type targetType = null;
    var target = null;
    if (targetExp is SuperExpression) {
      targetType = method.declaringType.parent;
      target = _makeSuperValue(targetExp);
    } else if (targetExp is ThisExpression) {
      targetType = method.declaringType;
      target = _makeThisValue(targetExp);
      if (fieldsSet) {
        world.error('no initialization allowed with redirecting constructor',
          node.span);
      }
    } else {
      world.error('bad call in initializers', node.span);
    }

    var m = targetType.getConstructor(contructorName);
    if (m == null) {
      world.error('no matching constructor for ${targetType.name}', node.span);
    }

    // TODO(jimhug): Replace with more generic recursion detection
    method.initDelegate = m;
    // check no cycles in in initialization:
    var other = m;
    while (other != null) {
      if (other == method) {
        world.error('initialization cycle', node.span);
        break;
      }
      other = other.initDelegate;
    }

    var newArgs = _makeArgs(node.arguments);
    // ???? wacky stuff ????
    world.gen.genMethod(m);

    m._evalConstConstructor(newObject, newArgs);

    if (!newObject.isConst) {
      var value = m.invoke(this, node, target, newArgs);
      if (target.type != world.objectType) {
        // No need to actually call Object's empty super constructor.
        writer.writeln('${value.code};');
      }
    }
  }

  _makeArgs(List<ArgumentNode> arguments) {
    var args = [];
    bool seenLabel = false;
    for (var arg in arguments) {
      if (arg.label != null) {
        seenLabel = true;
      } else if (seenLabel) {
        // TODO(jimhug): Move this into parser?
        world.error('bare argument cannot follow named arguments', arg.span);
      }
      args.add(visitValue(arg.value));
    }

    return new Arguments(arguments, args);
  }

  /** Invoke a top-level corelib native method. */
  Value _invokeNative(String name, List<Value> arguments) {
    var args = Arguments.EMPTY;
    if (arguments.length > 0) {
      args = new Arguments(null, arguments);
    }

    var method = world.corelib.topType.members[name];
    return method.invoke(this, method.definition,
        new Value(world.corelib.topType, null, null), args);
  }

  /**
   * Escapes a string so it can be inserted into JS code as a double-quoted
   * JS string.
   */
  static String _escapeString(String text) {
    // TODO(jimhug): Use a regex for performance here.
    return text.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll(
        '\n', '\\n').replaceAll('\r', '\\r');
  }

  /** Visits [body] without creating a new block for a [BlockStatement]. */
  bool visitStatementsInBlock(Statement body) {
    if (body is BlockStatement) {
      BlockStatement block = body;
      for (var stmt in block.body) {
        stmt.visit(this);
      }
    } else {
      if (body != null) body.visit(this);
    }
    return false;
  }

  _pushBlock(Node node, [bool reentrant = false]) {
    _scope = new BlockScope(this, _scope, node, reentrant);
  }

  _popBlock(Node node) {
    if (_scope.node !== node) {
      spanOf(n) => n != null ? n.span : null;
      world.internalError('scope mismatch. Trying to pop "${node}" but found '
        + ' "${_scope.node}"', spanOf(node), spanOf(_scope.node));
    }
    _scope = _scope.parent;
  }

  /** Visits a loop body and handles fixed point for type inference. */
  _visitLoop(Node node, void visitBody()) {
    if (_scope.inferTypes) {
      _loopFixedPoint(node, visitBody);
    } else {
      _pushBlock(node, reentrant:true);
      visitBody();
      _popBlock(node);
    }
  }

  // TODO(jmesserly): we're evaluating the body multiple times, how do we
  // prevent duplicate warnings/errors?
  // We either need a way to collect them before printing, or a check that
  // prevents multiple identical errors at the same source location.
  _loopFixedPoint(Node node, void visitBody()) {

    // TODO(jmesserly): should we move the writer/counters into the scope?
    // Also should we save the scope on the node, like how we save
    // MethodGenerator? That would reduce the required work for nested loops.
    var savedCounters = counters;
    var savedWriter = writer;
    int tries = 0;
    var startScope = _scope.snapshot();
    var s = startScope;
    while (true) {
      // Create a nested writer so we can easily discard it.
      // TODO(jmesserly): does this belong on BlockScope?
      writer = new CodeWriter();
      counters = new CounterLog();

      _pushBlock(node, reentrant:true);

      // If we've tried too many times and haven't converged, disable inference
      if (tries++ >= options.maxInferenceIterations) {
        // TODO(jmesserly): needs more information to actually be useful
        _scope.inferTypes = false;
      }

      visitBody();
      _popBlock(node);

      if (!_scope.inferTypes || !_scope.unionWith(s)) {
        // We've converged!
        break;
      }

      s = _scope.snapshot();
    }

    // We're done! Write the final code.
    savedWriter.write(writer.text);
    writer = savedWriter;
    savedCounters.add(counters);
    counters = savedCounters;
  }

  MethodMember _makeLambdaMethod(String name, FunctionDefinition func) {
    var meth = new MethodMember.lambda(name, method.declaringType, func);
    meth.enclosingElement = method;
    meth._methodData = new MethodData(meth, this);
    meth.resolve();
    return meth;
  }

  visitBool(Expression node) {
    // Boolean conversions in if/while/do/for/conditions require non-null bool.

    // TODO(jmesserly): why do we have this rule? It seems inconsistent with
    // the rest of the type system, and just causes bogus asserts unless all
    // bools are initialized to false.
    return visitValue(node).convertTo(this, world.nonNullBool);
  }

  visitValue(Expression node) {
    if (node == null) return null;

    var value = node.visit(this);
    value.checkFirstClass(node.span);
    return value;
  }

  /**
   * Visit [node] and ensure statically or with an runtime check that it has the
   * expected type (if specified).
   */
  visitTypedValue(Expression node, Type expectedType) {
    final val = visitValue(node);
    return expectedType == null ? val : val.convertTo(this, expectedType);
  }

  visitVoid(Expression node) {
    // TODO(jmesserly): should we generalize this?
    if (node is PostfixExpression) {
      var value = visitPostfixExpression(node, isVoid: true);
      value.checkFirstClass(node.span);
      return value;
    } else if (node is BinaryExpression) {
      var value = visitBinaryExpression(node, isVoid: true);
      value.checkFirstClass(node.span);
      return value;
    }
    // TODO(jimhug): Some level of warnings for non-void things here?
    return visitValue(node);
  }

  // ******************* Statements *******************

  bool visitDietStatement(DietStatement node) {
    var parser = new Parser(node.span.file, startOffset: node.span.start);
    visitStatementsInBlock(parser.block());
    return false;
  }

  bool visitVariableDefinition(VariableDefinition node) {
    var isFinal = false;
    // TODO(jimhug): Clean this up and share modifier parsing somewhere.
    if (node.modifiers != null && node.modifiers[0].kind == TokenKind.FINAL) {
      isFinal = true;
    }
    writer.write('var ');
    var type = method.resolveType(node.type, false, true);
    for (int i=0; i < node.names.length; i++) {
      if (i > 0) {
        writer.write(', ');
      }
      final name = node.names[i].name;
      var value = visitValue(node.values[i]);
      if (isFinal && value == null) {
        world.error('no value specified for final variable', node.span);
      }

      var val = _scope.create(name, type, node.names[i].span, isFinal);

      if (value == null) {
        if (_scope.reentrant) {
          // To preserve block scoping, we need to ensure the variable is
          // reinitialized each time the block is entered.
          writer.write('${val.code} = null');
        } else {
          writer.write('${val.code}');
        }
      } else {
        value = value.convertTo(this, type);
        _scope.inferAssign(name, value);
        writer.write('${val.code} = ${value.code}');
      }
    }
    writer.writeln(';');
    return false;

  }

  bool visitFunctionDefinition(FunctionDefinition node) {
    var meth = _makeLambdaMethod(node.name.name, node);
    var funcValue = _scope.create(meth.name, meth.functionType,
        method.definition.span, isFinal:true);

    meth.methodData.createFunction(writer);
    return false;
  }

  /**
   * Returns true indicating that normal control-flow is interrupted by
   * this statement. (This could be a return, break, throw, or continue.)
   */
  bool visitReturnStatement(ReturnStatement node) {
    if (node.value == null) {
      // This is essentially "return null".
      // It can't issue a warning because every type is nullable.
      writer.writeln('return;');
    } else {
      if (method.isConstructor) {
        world.error('return of value not allowed from constructor', node.span);
      }
      var value = visitTypedValue(node.value, method.returnType);
      writer.writeln('return ${value.code};');
    }
    return true;
  }

  bool visitThrowStatement(ThrowStatement node) {
    // Dart allows throwing anything, just like JS
    if (node.value != null) {
      var value = visitValue(node.value);
      // Ensure that we generate a toString() method for things that we throw
      value.invoke(this, 'toString', node, Arguments.EMPTY);
      writer.writeln('\$throw(${value.code});');
      world.gen.corejs.useThrow = true;
    } else {
      var rethrow = _scope.getRethrow();
      if (rethrow == null) {
        world.error('rethrow outside of catch', node.span);
      } else {
        // Use a normal throw instead of $throw so we don't capture a new stack
        writer.writeln('throw ${rethrow};');
      }
    }
    return true;
  }

  bool visitAssertStatement(AssertStatement node) {
    // be sure to walk test for static checking even is asserts disabled
    var test = visitValue(node.test); // TODO(jimhug): check bool or callable.
    if (options.enableAsserts) {
      var span = node.test.span;

      // TODO(jmesserly): do we need to include path/line/column here?
      // It should be captured in the stack trace.
      var line = span.file.getLine(span.start) + 1;
      var column = span.file.getColumn(line - 1, span.start) + 1;

      // TODO(jimhug): Simplify code for creating const values.
      var args = [
        test,
        Value.fromString(span.text, node.span),
        Value.fromString(span.file.filename, node.span),
        Value.fromInt(line, node.span),
        Value.fromInt(column, node.span)
      ];

      var tp = world.corelib.topType;
      Member f = tp.getMember('_assert');
      var value = f.invoke(this, node, new TypeValue(tp, null),
        new Arguments(null, args));
      writer.writeln('${value.code};');
    }
    return false;
  }

  bool visitBreakStatement(BreakStatement node) {
    // TODO(jimhug): Lots of flow error checking here and below.
    if (node.label == null) {
      writer.writeln('break;');
    } else {
      writer.writeln('break ${node.label.name};');
    }
    return true;
  }

  bool visitContinueStatement(ContinueStatement node) {
    if (node.label == null) {
      writer.writeln('continue;');
    } else {
      writer.writeln('continue ${node.label.name};');
    }
    return true;
  }

  bool visitIfStatement(IfStatement node) {
    var test = visitBool(node.test);
    writer.write('if (${test.code}) ');
    var exit1 = node.trueBranch.visit(this);
    if (node.falseBranch != null) {
      writer.write('else ');
      if (node.falseBranch.visit(this) && exit1) {
        return true;
      }
    }
    return false;
  }

  bool visitWhileStatement(WhileStatement node) {
    var test = visitBool(node.test);
    writer.write('while (${test.code}) ');
    _visitLoop(node, () {
      node.body.visit(this);
    });
    return false;
  }

  bool visitDoStatement(DoStatement node) {
    writer.write('do ');
    _visitLoop(node, () {
      node.body.visit(this);
    });
    var test = visitBool(node.test);
    writer.writeln('while (${test.code})');
    return false;
  }

  bool visitForStatement(ForStatement node) {
    _pushBlock(node);
    writer.write('for (');
    if (node.init != null) {
      node.init.visit(this);
    } else {
      writer.write(';');
    }

    _visitLoop(node, () {
      if (node.test != null) {
        var test = visitBool(node.test);
        writer.write(' ${test.code}; ');
      } else {
        writer.write('; ');
      }

      bool needsComma = false;
      for (var s in node.step) {
        if (needsComma) writer.write(', ');
        var sv = visitVoid(s);
        writer.write(sv.code);
        needsComma = true;
      }
      writer.write(') ');

      _pushBlock(node.body);
      node.body.visit(this);
      _popBlock(node.body);
    });
    _popBlock(node);
    return false;
  }

  bool _isFinal(typeRef) {
    if (typeRef is GenericTypeReference) {
      typeRef = typeRef.baseType;
    } else if (typeRef is SimpleTypeReference) {
      return false;
    }
    return typeRef != null && typeRef.isFinal;
  }

  bool visitForInStatement(ForInStatement node) {
    // TODO(jimhug): visitValue and other cleanups here.
    var itemType = method.resolveType(node.item.type, false, true);
    var list = node.list.visit(this);
    _visitLoop(node, () {
      _visitForInBody(node, itemType, list);
    });
    return false;
  }

  void _visitForInBody(ForInStatement node, Type itemType, Value list) {
    // TODO(jimhug): Check that itemType matches list members...
    bool isFinal = node.item.isFinal;
    var itemName = node.item.name.name;
    var item = _scope.create(itemName, itemType, node.item.name.span, isFinal);
    if (list.needsTemp) {
      var listVar = _scope.create('\$list', list.type, null);
      writer.writeln('var ${listVar.code} = ${list.code};');
      list = listVar;
    }

    // Special path for concrete Arrays for readability and perf optimization.
    if (list.type.genericType == world.listFactoryType) {
      var tmpi = _scope.create('\$i', world.numType, null);
      var listLength = list.get_(this, 'length', node.list);
      writer.enterBlock('for (var ${tmpi.code} = 0;'
          '${tmpi.code} < ${listLength.code}; ${tmpi.code}++) {');
      var value = list.invoke(this, ':index', node.list,
          new Arguments(null, [tmpi]));
      writer.writeln('var ${item.code} = ${value.code};');
    } else {
      var iterator = list.invoke(this, 'iterator', node.list, Arguments.EMPTY);
      var tmpi = _scope.create('\$i', iterator.type, null);

      var hasNext = tmpi.invoke(this, 'hasNext', node.list, Arguments.EMPTY);
      var next = tmpi.invoke(this, 'next', node.list, Arguments.EMPTY);

      writer.enterBlock(
        'for (var ${tmpi.code} = ${iterator.code}; ${hasNext.code}; ) {');
      writer.writeln('var ${item.code} = ${next.code};');
    }

    visitStatementsInBlock(node.body);
    writer.exitBlock('}');
  }

  void _genToDartException(Value ex) {
    var result = _invokeNative("_toDartException", [ex]);
    writer.writeln('${ex.code} = ${result.code};');
  }

  void _genStackTraceOf(Value trace, Value ex) {
    var result = _invokeNative("_stackTraceOf", [ex]);
    writer.writeln('var ${trace.code} = ${result.code};');
  }

  bool visitTryStatement(TryStatement node) {
    writer.enterBlock('try {');
    _pushBlock(node.body);
    visitStatementsInBlock(node.body);
    _popBlock(node.body);

    if (node.catches.length == 1) {
      // Handle a single catch. We can generate simple code here compared to the
      // multiple catch, such as no extra temp or if-else-if chain.
      var catch_ = node.catches[0];
      _pushBlock(catch_);
      var exType = method.resolveType(catch_.exception.type, false, true);
      var ex = _scope.declare(catch_.exception);
      _scope.rethrow = ex.code;
      writer.nextBlock('} catch (${ex.code}) {');
      if (catch_.trace != null) {
        var trace = _scope.declare(catch_.trace);
        _genStackTraceOf(trace, ex);
      }
      _genToDartException(ex);

      if (!exType.isVarOrObject) {
        var test = ex.instanceOf(this, exType, catch_.exception.span,
            isTrue:false, forceCheck:true);
        writer.writeln('if (${test.code}) throw ${ex.code};');
      }
      visitStatementsInBlock(node.catches[0].body);
      _popBlock(catch_);
    } else if (node.catches.length > 0) {
      // Handle more than one catch
      _pushBlock(node);
      var ex = _scope.create('\$ex', world.varType, null);
      _scope.rethrow = ex.code;
      writer.nextBlock('} catch (${ex.code}) {');
      var trace = null;
      if (node.catches.some((c) => c.trace != null)) {
        trace = _scope.create('\$trace', world.varType, null);
        _genStackTraceOf(trace, ex);
      }
      _genToDartException(ex);

      // We need a rethrow unless we encounter a "var" or "Object" catch
      bool needsRethrow = true;

      for (int i = 0; i < node.catches.length; i++) {
        var catch_ = node.catches[i];

        _pushBlock(catch_);
        var tmpType = method.resolveType(catch_.exception.type, false, true);
        var tmp = _scope.declare(catch_.exception);
        if (!tmpType.isVarOrObject) {
          var test = ex.instanceOf(this, tmpType, catch_.exception.span,
              isTrue:true, forceCheck:true);
          if (i == 0) {
            writer.enterBlock('if (${test.code}) {');
          } else {
            writer.nextBlock('} else if (${test.code}) {');
          }
        } else if (i > 0) {
          writer.nextBlock('} else {');
        }

        writer.writeln('var ${tmp.code} = ${ex.code};');
        if (catch_.trace != null) {
          // TODO(jmesserly): ensure this is the right type
          var tmptrace = _scope.declare(catch_.trace);
          writer.writeln('var ${tmptrace.code} = ${trace.code};');
        }

        visitStatementsInBlock(catch_.body);
        _popBlock(catch_);

        if (tmpType.isVarOrObject) {
          // We matched this for sure; no need to keep going
          if (i + 1 < node.catches.length) {
            world.error('Unreachable catch clause', node.catches[i + 1].span);
          }
          if (i > 0) {
            // Close the else block
            writer.exitBlock('}');
          }
          needsRethrow = false;
          break;
        }
      }

      if (needsRethrow) {
        // If we didn't have a "catch (var e)", generate a rethrow
        writer.nextBlock('} else {');
        writer.writeln('throw ${ex.code};');
        writer.exitBlock('}');
      }

      _popBlock(node);
    }

    if (node.finallyBlock != null) {
      writer.nextBlock('} finally {');
      _pushBlock(node.finallyBlock);
      visitStatementsInBlock(node.finallyBlock);
      _popBlock(node.finallyBlock);
    }

    // Close the try-catch-finally
    writer.exitBlock('}');
    // TODO(efortuna): This could be more precise by combining all the different
    // paths here.  -i.e. if there is a finally block with a return at the end
    // then this can return true, similarly if all blocks have a return at the
    // end then the same holds.
    return false;
  }

  bool visitSwitchStatement(SwitchStatement node) {
    var test = visitValue(node.test);
    writer.enterBlock('switch (${test.code}) {');
    for (var case_ in node.cases) {
      if (case_.label != null) {
        world.error('unimplemented: labeled case statement', case_.span);
      }
      _pushBlock(case_);
      for (int i=0; i < case_.cases.length; i++) {
        var expr = case_.cases[i];
        if (expr == null) {
          // Default can only be the last case.
          if (i < case_.cases.length - 1) {
            world.error('default clause must be the last case', case_.span);
          }
          writer.writeln('default:');
        } else {
          var value = visitValue(expr);
          writer.writeln('case ${value.code}:');
        }
      }
      writer.enterBlock('');
      bool caseExits = _visitAllStatements(case_.statements, false);

      if (case_ != node.cases[node.cases.length - 1] && !caseExits) {
        var span = case_.statements[case_.statements.length - 1].span;
        writer.writeln('\$throw(new FallThroughError());');
        world.gen.corejs.useThrow = true;
      }
      writer.exitBlock('');
      _popBlock(case_);
    }
    writer.exitBlock('}');
    // TODO(efortuna): When we are passing more information back about
    // control flow by returning something other than bool, return true for the
    // cases where every branch of the switch statement ends with a return
    // statement.
    return false;
  }

  bool _visitAllStatements(statementList, exits) {
    for (int i = 0; i < statementList.length; i++) {
      var stmt = statementList[i];
      exits = stmt.visit(this);
      //TODO(efortuna): fix this so you only get one error if you have "return;
      //a; b; c;"
      if (stmt != statementList[statementList.length - 1] && exits) {
        world.warning('unreachable code', statementList[i + 1].span);
      }
    }
    return exits;
  }

  bool visitBlockStatement(BlockStatement node) {
    _pushBlock(node);
    writer.enterBlock('{');
    var exits = _visitAllStatements(node.body, false);
    writer.exitBlock('}');
    _popBlock(node);
    return exits;
  }

  bool visitLabeledStatement(LabeledStatement node) {
    writer.writeln('${node.name.name}:');
    node.body.visit(this);
    return false;
  }

  bool visitExpressionStatement(ExpressionStatement node) {
    if (node.body is VarExpression || node.body is ThisExpression) {
      // TODO(jmesserly): this is a "warning" but not a "type warning",
      // Is that okay? We have a similar issue around unreachable code warnings.
      world.warning('variable used as statement', node.span);
    }
    var value = visitVoid(node.body);
    writer.writeln('${value.code};');
    return false;
  }

  bool visitEmptyStatement(EmptyStatement node) {
    writer.writeln(';');
    return false;
  }

  _checkNonStatic(Node node) {
    if (isStatic) {
      world.warning('not allowed in static method', node.span);
    }
  }

  _makeSuperValue(Node node) {
    var parentType = method.declaringType.parent;
    _checkNonStatic(node);
    if (parentType == null) {
      world.error('no super class', node.span);
    }
    return new SuperValue(parentType, node.span);
  }

  _getOutermostMethod() {
    var result = this;
    while (result.enclosingMethod != null) {
      result = result.enclosingMethod;
    }
    return result;
  }


  // TODO(jimhug): Share code better with _makeThisValue.
  String _makeThisCode() {
    if (enclosingMethod != null) {
      _getOutermostMethod().needsThis = true;
      return '\$this';
    } else {
      return 'this';
    }
  }

  /**
   * Creates a reference to the enclosing type ('this') that can be used within
   * closures.
   */
  Value _makeThisValue(Node node) {
    if (enclosingMethod != null) {
      var outermostMethod = _getOutermostMethod();
      outermostMethod._checkNonStatic(node);
      outermostMethod.needsThis = true;
      return new ThisValue(outermostMethod.method.declaringType, '\$this',
          node != null ? node.span : null);
    } else {
      _checkNonStatic(node);
      return new ThisValue(method.declaringType, 'this',
          node != null ? node.span : null);
    }
  }

  // ******************* Expressions *******************
  visitLambdaExpression(LambdaExpression node) {
    var name = (node.func.name != null) ? node.func.name.name : '';

    MethodMember meth = _makeLambdaMethod(name, node.func);
    return meth.methodData.createLambda(node, this);
  }

  visitCallExpression(CallExpression node) {
    var target;
    var position = node.target;
    var name = ':call';
    if (node.target is DotExpression) {
      DotExpression dot = node.target;
      target = dot.self.visit(this);
      name = dot.name.name;
      position = dot.name;
    } else if (node.target is VarExpression) {
      VarExpression varExpr = node.target;
      name = varExpr.name.name;
      // First check in block scopes.
      target = _scope.lookup(name);
      if (target != null) {
        return target.invoke(this, ':call', node, _makeArgs(node.arguments));
      }

      target = _makeThisOrType(varExpr.span);
      return target.invoke(this, name, node, _makeArgs(node.arguments));
    } else {
      target = node.target.visit(this);
    }

    return target.invoke(this, name, position, _makeArgs(node.arguments));
  }

  visitIndexExpression(IndexExpression node) {
    var target = visitValue(node.target);
    var index = visitValue(node.index);
    return target.invoke(this, ':index', node, new Arguments(null, [index]));
  }

  bool _expressionNeedsParens(Expression e) {
    return (e is BinaryExpression || e is ConditionalExpression
            || e is PostfixExpression || _isUnaryIncrement(e));
  }

  visitBinaryExpression(BinaryExpression node, [bool isVoid = false]) {
    final kind = node.op.kind;
    // TODO(jimhug): Ensure these have same semantics as JS!
    if (kind == TokenKind.AND || kind == TokenKind.OR) {
      var x = visitTypedValue(node.x, world.nonNullBool);
      var y = visitTypedValue(node.y, world.nonNullBool);
      return x.binop(kind, y, this, node);
    } else if (kind == TokenKind.EQ_STRICT || kind == TokenKind.NE_STRICT) {
      var x = visitValue(node.x);
      var y = visitValue(node.y);
      return x.binop(kind, y, this, node);
    }

    final assignKind = TokenKind.kindFromAssign(node.op.kind);
    if (assignKind == -1) {
      final x = visitValue(node.x);
      final y = visitValue(node.y);
      return x.binop(kind, y, this, node);
    } else if ((assignKind != 0) && _expressionNeedsParens(node.y)) {
      return _visitAssign(assignKind, node.x,
          new ParenExpression(node.y, node.y.span), node,
            isVoid ? ReturnKind.IGNORE : ReturnKind.POST);
    } else {
      return _visitAssign(assignKind, node.x, node.y, node,
          isVoid ? ReturnKind.IGNORE : ReturnKind.POST);
    }
  }

  /**
   * Visits an assignment expression.
   */
  _visitAssign(int kind, Expression xn, Expression yn, Node position,
      int returnKind) {
    // TODO(jimhug): The usual battle with making assign impl not look ugly.
    if (xn is VarExpression) {
      return _visitVarAssign(kind, xn, yn, position, returnKind);
    } else if (xn is IndexExpression) {
      return _visitIndexAssign(kind, xn, yn, position, returnKind);
    } else if (xn is DotExpression) {
      return _visitDotAssign(kind, xn, yn, position, returnKind);
    } else {
      world.error('illegal lhs', xn.span);
    }
  }

  // TODO(jmesserly): it'd be nice if we didn't have to deal directly with
  // MemberSets here and in visitVarExpression.
  _visitVarAssign(int kind, VarExpression xn, Expression yn, Node position,
      int returnKind) {
    final name = xn.name.name;

    // First check in block scopes.
    var x = _scope.lookup(name);
    var y = visitValue(yn);

    if (x != null) {
      y = y.convertTo(this, x.staticType);
      // Update the inferred value
      // Note: for now we aren't very flow sensitive, so this is a "union"
      // rather than simply setting it to "y"
      _scope.inferAssign(name, Value.union(x, y));

      // TODO(jimhug): This is "legacy" and should be cleaned ASAP
      if (x.isFinal) {
        world.error('final variable "${x.code}" is not assignable',
            position.span);
      }

      // Handle different ReturnKind values here...
      if (kind == 0) {
        return new Value(y.type, '${x.code} = ${y.code}', position.span);
      } else if (x.type.isNum && y.type.isNum && (kind != TokenKind.TRUNCDIV)) {
        // Process everything but ~/ , which has no equivalent JS operator
        // Very localized optimization for numbers!
        if (returnKind == ReturnKind.PRE) {
          world.internalError('should not be here', position.span);
        }
        final op = TokenKind.kindToString(kind);
        return new Value(y.type, '${x.code} $op= ${y.code}', position.span);
      } else {
        var right = x;
        y = right.binop(kind, y, this, position);
        if (returnKind == ReturnKind.PRE) {
          var tmp = forceTemp(x);
          var ret = new Value(x.type,
            '(${tmp.code} = ${x.code}, ${x.code} = ${y.code}, ${tmp.code})',
            position.span);
          freeTemp(tmp);
          return ret;
        } else {
          return new Value(x.type, '${x.code} = ${y.code}', position.span);
        }
      }
    } else {
      x = _makeThisOrType(position.span);
      return x.set_(this, name, position, y, kind: kind,
        returnKind: returnKind);
    }
  }

  _visitIndexAssign(int kind, IndexExpression xn, Expression yn,
      Node position, int returnKind) {
    var target = visitValue(xn.target);
    var index = visitValue(xn.index);
    var y = visitValue(yn);

    return target.setIndex(this, index, position, y, kind: kind,
      returnKind: returnKind);
  }

  _visitDotAssign(int kind, DotExpression xn, Expression yn, Node position,
      int returnKind) {
    // This is not visitValue because types members are assignable.
    var target = xn.self.visit(this);
    var y = visitValue(yn);

    return target.set_(this, xn.name.name, xn.name, y, kind: kind,
      returnKind: returnKind);
  }

  visitUnaryExpression(UnaryExpression node) {
    var value = visitValue(node.self);
    switch (node.op.kind) {
      case TokenKind.INCR:
      case TokenKind.DECR:
        // TODO(jimhug): Hackish optimization not always correct
        if (value.type.isNum && !value.isFinal && node.self is VarExpression) {
          return new Value(value.type, '${node.op}${value.code}', node.span);
        } else {
          // ++x becomes x += 1
          // --x becomes x -= 1
          var kind = (TokenKind.INCR == node.op.kind ?
              TokenKind.ADD : TokenKind.SUB);
          // TODO(jimhug): Shouldn't need a full-expression here.
          var operand = new LiteralExpression(Value.fromInt(1, node.span),
            node.span);

          var assignValue = _visitAssign(kind, node.self, operand, node,
              ReturnKind.POST);
          return new Value(assignValue.type, '(${assignValue.code})',
              node.span);
        }
    }
    return value.unop(node.op.kind, this, node);
  }

  visitDeclaredIdentifier(DeclaredIdentifier node) {
    world.error('Expected expression', node.span);
  }

  visitAwaitExpression(AwaitExpression node) {
    world.internalError(
        'Await expressions should have been eliminated before code generation',
        node.span);
  }

  visitPostfixExpression(PostfixExpression node, [bool isVoid = false]) {
    // TODO(jimhug): Hackish optimization here to revisit in many ways...
    var value = visitValue(node.body);
    if (value.type.isNum && !value.isFinal && node.body is VarExpression) {
      // Would like to also do on "pure" fields - check to see if possible...
      return new Value(value.type, '${value.code}${node.op}', node.span);
    }

    // x++ is equivalent to (t = x, x = t + 1, t), where we capture all temps
    // needed to evaluate x so we're not evaluating multiple times. Likewise,
    // x-- is equivalent to (t = x, x = t - 1, t).
    var kind = (TokenKind.INCR == node.op.kind) ?
      TokenKind.ADD : TokenKind.SUB;
    // TODO(jimhug): Shouldn't need a full-expression here.
    var operand = new LiteralExpression(Value.fromInt(1, node.span),
      node.span);
    var ret = _visitAssign(kind, node.body, operand, node,
      isVoid ? ReturnKind.IGNORE : ReturnKind.PRE);
    return ret;
  }

  visitNewExpression(NewExpression node) {
    var typeRef = node.type;

    var constructorName = '';
    if (node.name != null) {
      constructorName = node.name.name;
    }

    // Named constructors and library prefixes, oh my!
    // At last, we can collapse the ambiguous wave function...
    if (constructorName == '' && typeRef is NameTypeReference &&
        typeRef.names != null) {

      // Pull off the last name from the type, guess it's the constructor name.
      var names = new List.from(typeRef.names);
      constructorName = names.removeLast().name;
      if (names.length == 0) names = null;

      typeRef = new NameTypeReference(
          typeRef.isFinal, typeRef.name, names, typeRef.span);
    }

    var type = method.resolveType(typeRef, true, true);
    if (type.isTop) {
      type = type.library.findTypeByName(constructorName);
      constructorName = '';
    }

    if (type is ParameterType) {
      world.error('cannot instantiate a type parameter', node.span);
      return _makeMissingValue(constructorName);
    }

    var m = type.getConstructor(constructorName);
    if (m == null) {
      var name = type.jsname;
      if (type.isVar) {
        name = typeRef.name.name;
      }
      world.error('no matching constructor for $name', node.span);
      return _makeMissingValue(name);
    }

    if (node.isConst) {
      if (!m.isConst) {
        world.error('can\'t use const on a non-const constructor', node.span);
      }
      for (var arg in node.arguments) {
        if (!visitValue(arg.value).isConst) {
          world.error('const constructor expects const arguments', arg.span);
        }
      }
    }

    // Call the constructor on the type we want to construct.
    // NOTE: this is important for correct type checking of factories.
    // If the user calls "new Interface()" we want the result type to be the
    // interface, not the class.
    var target = new TypeValue(type, typeRef.span);
    return m.invoke(this, node, target, _makeArgs(node.arguments));
  }

  visitListExpression(ListExpression node) {
    var argValues = [];
    var listType = world.listType;
    var type = world.varType;
    if (node.itemType != null) {
      type = method.resolveType(node.itemType, true, !node.isConst);
      if (node.isConst && (type is ParameterType || type.hasTypeParams)) {
        world.error('type parameter cannot be used in const list literals');
      }
      listType = listType.getOrMakeConcreteType([type]);
    }
    for (var item in node.values) {
      var arg = visitTypedValue(item, type);
      argValues.add(arg);
      if (node.isConst && !arg.isConst) {
        world.error('const list can only contain const values', arg.span);
      }
    }

    world.listFactoryType.markUsed();

    var ret = new ListValue(argValues, node.isConst, listType, node.span);
    if (ret.isConst) return ret.getGlobalValue();
    return ret;
  }


  visitMapExpression(MapExpression node) {
    // Special case the empty non-const map.
    if (node.items.length == 0 && !node.isConst) {
      return world.mapType.getConstructor('').invoke(this, node,
        new TypeValue(world.mapType, node.span), Arguments.EMPTY);
    }

    var values = <Value>[];
    var valueType = world.varType, keyType = world.stringType;
    var mapType = world.mapType; // TODO(jimhug): immutable type?
    if (node.valueType !== null) {
      if (node.keyType !== null) {
        keyType = method.resolveType(node.keyType, true, !node.isConst);
        // TODO(jimhug): Would be nice to allow arbitrary keys here (this is
        // currently not allowed by the spec).
        if (!keyType.isString) {
          world.error('the key type of a map literal must be "String"',
              keyType.span);
        }
        if (node.isConst &&
            (keyType is ParameterType || keyType.hasTypeParams)) {
          world.error('type parameter cannot be used in const map literals');
        }
      }

      valueType = method.resolveType(node.valueType, true, !node.isConst);
      if (node.isConst &&
          (valueType is ParameterType || valueType.hasTypeParams)) {
        world.error('type parameter cannot be used in const map literals');
      }

      mapType = mapType.getOrMakeConcreteType([keyType, valueType]);
    }

    for (int i = 0; i < node.items.length; i += 2) {
      var key = visitTypedValue(node.items[i], keyType);
      if (node.isConst && !key.isConst) {
        world.error('const map can only contain const keys', key.span);
      }
      values.add(key);

      var value = visitTypedValue(node.items[i + 1], valueType);
      if (node.isConst && !value.isConst) {
        world.error('const map can only contain const values', value.span);
      }
      values.add(value);
    }

    var ret = new MapValue(values, node.isConst, mapType, node.span);
    if (ret.isConst) return ret.getGlobalValue();
    return ret;
  }

  visitConditionalExpression(ConditionalExpression node) {
    var test = visitBool(node.test);
    var trueBranch = visitValue(node.trueBranch);
    var falseBranch = visitValue(node.falseBranch);

    // TODO(jmesserly): is there a way to use Value.union here, even though
    // we need different code?
    return new Value(Type.union(trueBranch.type, falseBranch.type),
        '${test.code} ? ${trueBranch.code} : ${falseBranch.code}', node.span);
  }

  visitIsExpression(IsExpression node) {
    var value = visitValue(node.x);
    var type = method.resolveType(node.type, true, true);
    if (type.isVar) {
      return Value.comma(value, Value.fromBool(true, node.span));
    }

    return value.instanceOf(this, type, node.span, node.isTrue);
  }

  visitParenExpression(ParenExpression node) {
    var body = visitValue(node.body);
    // Assumption implicit here that const values never need parens...
    if (body.isConst) return body;
    return new Value(body.type, '(${body.code})', node.span);
  }

  visitDotExpression(DotExpression node) {
    // Types are legal targets of .
    var target = node.self.visit(this);
    return target.get_(this, node.name.name, node.name);
  }

  visitVarExpression(VarExpression node) {
    final name = node.name.name;

    // First check in block scopes.
    var ret = _scope.lookup(name);
    if (ret != null) return ret;

    return _makeThisOrType(node.span).get_(this, name, node);
  }

  _makeMissingValue(String name) {
    // TODO(jimhug): Probably goes away to be fully replaced by noSuchMethod
    return new Value(world.varType, '$name()/*NotFound*/', null);
  }

  _makeThisOrType(SourceSpan span) {
    return new BareValue(this, _getOutermostMethod(), span);
  }

  visitThisExpression(ThisExpression node) {
    return _makeThisValue(node);
  }

  visitSuperExpression(SuperExpression node) {
    return _makeSuperValue(node);
  }

  visitLiteralExpression(LiteralExpression node) {
    return node.value;
  }

  _isUnaryIncrement(Expression item) {
    if (item is UnaryExpression) {
      UnaryExpression u = item;
      return u.op.kind == TokenKind.INCR || u.op.kind == TokenKind.DECR;
    } else {
      return false;
    }
  }

  String foldStrings(List<StringValue> strings) {
    StringBuffer buffer = new StringBuffer();
    for (var part in strings) buffer.add(part.constValue.actualValue);
    return buffer.toString();
  }

  visitStringConcatExpression(StringConcatExpression node) {
    var items = [];
    var itemsConst = [];
    for (var item in node.strings) {
      Value val = visitValue(item);
      assert(val.type.isString);
      if (val.isConst) itemsConst.add(val);
      items.add(val.code);
    }
    if (items.length == itemsConst.length) {
      return new StringValue(foldStrings(itemsConst), true, node.span);
    } else {
      String code = '(${Strings.join(items, " + ")})';
      return new Value(world.stringType, code, node.span);
    }
  }

  visitStringInterpExpression(StringInterpExpression node) {
    var items = [];
    var itemsConst = [];
    for (var item in node.pieces) {
      var val = visitValue(item);
      bool isConst = val.isConst && val.type.isString;
      if (!isConst) {
        val.invoke(this, 'toString', item, Arguments.EMPTY);
      }
      // TODO(jimhug): Ensure this solves all precedence problems.
      // TODO(jmesserly): We could be smarter about prefix/postfix, but we'd
      // need to know if it will compile to a ++ or to some sort of += form.
      var code = val.code;
      if (_expressionNeedsParens(item)) {
        code = '(${code})';
      }
      // No need to concat empty strings except the first.
      if (items.length == 0 || (code != "''" && code != '""')) {
        items.add(code);
        if (isConst) itemsConst.add(val);
      }
    }
    if (items.length == itemsConst.length) {
      return new StringValue(foldStrings(itemsConst), true, node.span);
    } else {
      String code = '(${Strings.join(items, " + ")})';
      return new Value(world.stringType, code, node.span);
    }
  }
}


// TODO(jmesserly): move this into its own file?
class Arguments {
  static Arguments _empty;
  static Arguments get EMPTY() {
    if (_empty == null) {
      _empty = new Arguments(null, []);
    }
    return _empty;
  }

  List<Value> values;
  List<ArgumentNode> nodes;
  int _bareCount;

  Arguments(this.nodes, this.values);

  /** Constructs a bare list of arguments. */
  factory Arguments.bare(int arity) {
    var values = [];
    for (int i = 0; i < arity; i++) {
      // TODO(jimhug): Need a firm rule about null SourceSpans are allowed.
      values.add(new VariableValue(world.varType, '\$$i', null));
    }
    return new Arguments(null, values);
  }

  int get nameCount() => length - bareCount;
  bool get hasNames() => bareCount < length;

  int get length() => values.length;

  String getName(int i) => nodes[i].label.name;

  int getIndexOfName(String name) {
    for (int i = bareCount; i < length; i++) {
      if (getName(i) == name) {
        return i;
      }
    }
    return -1;
  }

  Value getValue(String name) {
    int i = getIndexOfName(name);
    return i >= 0 ? values[i] : null;
  }

  int get bareCount() {
    if (_bareCount == null) {
      _bareCount = length;
      if (nodes != null) {
        for (int i = 0; i < nodes.length; i++) {
          if (nodes[i].label != null) {
            _bareCount = i;
            break;
          }
        }
      }
    }
    return _bareCount;
  }

  String getCode() {
    var argsCode = [];
    for (int i = 0; i < length; i++) {
      argsCode.add(values[i].code);
    }
    removeTrailingNulls(argsCode);
    return Strings.join(argsCode, ", ");
  }

  List<String> getBareCodes() {
    var result = [];
    for (int i = 0; i < bareCount; i++) {
      result.add(values[i].code);
    }
    return result;
  }

  List<String> getNamedCodes() {
    var result = [];
    for (int i = bareCount; i < length; i++) {
      result.add(values[i].code);
    }
    return result;
  }

  static removeTrailingNulls(List<Value> argsCode) {
    // We simplify calls with null defaults by relying on JS and our
    // choice to make undefined === null for Dart generated code. This helps
    // and ensures correct defaults values for native calls.
    while (argsCode.length > 0 && argsCode.last() == 'null') {
      argsCode.removeLast();
    }
  }

  /** Gets the named arguments. */
  List<String> getNames() {
    var names = [];
    for (int i = bareCount; i < length; i++) {
      names.add(getName(i));
    }
    return names;
  }

  /** Gets the argument names used in a call stub; uses $0 $1 for bare args. */
  Arguments toCallStubArgs() {
    var result = [];
    for (int i = 0; i < bareCount; i++) {
      result.add(new VariableValue(world.varType, '\$$i', null));
    }
    for (int i = bareCount; i < length; i++) {
      var name = getName(i);
      if (name == null) name = '\$$i';
      result.add(new VariableValue(world.varType, name, null));
    }
    return new Arguments(nodes, result);
  }

  bool matches(Arguments other) {
    if (length != other.length) return false;
    if (bareCount != other.bareCount) return false;

    for (int i = 0; i < bareCount; i++) {
      if (values[i].type != other.values[i].type) return false;
    }
    // TODO(jimhug): Needs to check that named args also match!
    return true;
  }

}

class ReturnKind {
  static final int IGNORE = 1;
  static final int POST = 2;
  static final int PRE = 3;
}
