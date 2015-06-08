// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

class ClassEmitter extends CodeEmitterHelper {

  ClassStubGenerator get _stubGenerator =>
      new ClassStubGenerator(compiler, namer, backend);

  /**
   * Documentation wanted -- johnniwinther
   */
  void emitClass(Class cls, ClassBuilder enclosingBuilder, Fragment fragment) {
    ClassElement classElement = cls.element;

    assert(invariant(classElement, classElement.isDeclaration));

    emitter.needsClassSupport = true;

    ClassElement superclass = classElement.superclass;
    String superName = "";
    if (superclass != null) {
      superName = namer.className(superclass);
    }

    if (cls.isMixinApplication) {
      MixinApplication mixinApplication = cls;
      String mixinName = mixinApplication.mixinClass.name;
      superName = '$superName+$mixinName';
      emitter.needsMixinSupport = true;
    }

    ClassBuilder builder = new ClassBuilder(classElement, namer);
    builder.superName = superName;
    emitConstructorsForCSP(cls);
    emitFields(cls, builder);
    emitCheckedClassSetters(cls, builder);
    emitClassGettersSettersForCSP(cls, builder);
    emitInstanceMembers(cls, builder);
    emitStubs(cls.callStubs, builder);
    emitStubs(cls.typeVariableReaderStubs, builder);
    emitRuntimeTypeInformation(cls, builder);
    emitNativeInfo(cls, builder);

    if (classElement == backend.closureClass) {
      // We add a special getter here to allow for tearing off a closure from
      // itself.
      jsAst.Fun function = js('function() { return this; }');
      String name = namer.getterForMember(Selector.CALL_NAME);
      builder.addProperty(name, function);
    }

    emitClassBuilderWithReflectionData(cls, builder, enclosingBuilder,
        fragment);
  }
  /**
  * Emits the precompiled constructor when in CSP mode.
  */
  void emitConstructorsForCSP(Class cls) {
    List<String> fieldNames = <String>[];

    if (!compiler.useContentSecurityPolicy) return;

    if (!cls.onlyForRti && !cls.isNative) {
      fieldNames = cls.fields.map((Field field) => field.name).toList();
    }

    ClassElement classElement = cls.element;

    jsAst.Expression constructorAst =
        _stubGenerator.generateClassConstructor(classElement, fieldNames);

    String constructorName = namer.className(classElement);
    OutputUnit outputUnit =
        compiler.deferredLoadTask.outputUnitForElement(classElement);
    emitter.assemblePrecompiledConstructor(
        outputUnit, constructorName, constructorAst, fieldNames);
  }

  /// Returns `true` if fields added.
  bool emitFields(FieldContainer container,
                  ClassBuilder builder,
                  { bool classIsNative: false,
                    bool emitStatics: false }) {
    Iterable<Field> fields;
    if (container is Class) {
      if (emitStatics) {
        fields = container.staticFieldsForReflection;
      } else if (container.onlyForRti) {
        return false;
      } else {
        fields = container.fields;
      }
    } else {
      assert(container is Library);
      assert(emitStatics);
      fields = container.staticFieldsForReflection;
    }

    var fieldMetadata = [];
    bool hasMetadata = false;
    bool fieldsAdded = false;

    for (Field field in fields) {
      FieldElement fieldElement = field.element;
      String name = field.name;
      String accessorName = field.accessorName;
      bool needsGetter = field.needsGetter;
      bool needsSetter = field.needsUncheckedSetter;

        // Ignore needsCheckedSetter - that is handled below.
      bool needsAccessor = (needsGetter || needsSetter);
      // We need to output the fields for non-native classes so we can auto-
      // generate the constructor.  For native classes there are no
      // constructors, so we don't need the fields unless we are generating
      // accessors at runtime.
      bool needsFieldsForConstructor = !emitStatics && !classIsNative;
      if (needsFieldsForConstructor || needsAccessor) {
        var metadata =
            task.metadataCollector.buildMetadataFunction(fieldElement);
        if (metadata != null) {
          hasMetadata = true;
        } else {
          metadata = new jsAst.LiteralNull();
        }
        fieldMetadata.add(metadata);
        recordMangledField(fieldElement, accessorName,
            namer.privateName(fieldElement.memberName));
        String fieldName = name;
        String fieldCode = '';
        String reflectionMarker = '';
        if (!needsAccessor) {
          // Emit field for constructor generation.
          assert(!classIsNative);
        } else {
          // Emit (possibly renaming) field name so we can add accessors at
          // runtime.
          if (name != accessorName) {
            fieldName = '$accessorName:$name';
          }

          if (field.needsInterceptedGetter) {
            emitter.interceptorEmitter.interceptorInvocationNames.add(
                namer.getterForElement(fieldElement));
          }
          // TODO(16168): The setter creator only looks at the getter-name.
          // Even though the setter could avoid the interceptor convention we
          // currently still need to add the additional argument.
          if (field.needsInterceptedGetter || field.needsInterceptedSetter) {
            emitter.interceptorEmitter.interceptorInvocationNames.add(
                namer.setterForElement(fieldElement));
          }

          int code = field.getterFlags + (field.setterFlags << 2);
          if (code == 0) {
            compiler.internalError(fieldElement,
                'Field code is 0 ($fieldElement).');
          } else {
            fieldCode = FIELD_CODE_CHARACTERS[code - FIRST_FIELD_CODE];
          }
        }
        if (backend.isAccessibleByReflection(fieldElement)) {
          DartType type = fieldElement.type;
          reflectionMarker = '-${task.metadataCollector.reifyType(type)}';
        }
        String builtFieldname = '$fieldName$fieldCode$reflectionMarker';
        builder.addField(builtFieldname);
        // Add 1 because adding a field to the class also requires a comma
        compiler.dumpInfoTask.recordFieldNameSize(fieldElement,
            builtFieldname.length + 1);
        fieldsAdded = true;
      }
    }

    if (hasMetadata) {
      builder.fieldMetadata = fieldMetadata;
    }
    return fieldsAdded;
  }

  /// Emits checked setters for fields.
  void emitCheckedClassSetters(Class cls, ClassBuilder builder) {
    if (cls.onlyForRti) return;

    for (Field field in cls.fields) {
      if (field.needsCheckedSetter) {
        assert(!field.needsUncheckedSetter);
        compiler.withCurrentElement(field.element, () {
          generateCheckedSetter(
              field.element, field.name, field.accessorName, builder);
        });
      }
    }
  }

  /// Emits getters/setters for fields if compiling in CSP mode.
  void emitClassGettersSettersForCSP(Class cls, ClassBuilder builder) {

    if (!compiler.useContentSecurityPolicy || cls.onlyForRti) return;

    for (Field field in cls.fields) {
      Element member = field.element;
      compiler.withCurrentElement(member, () {
        if (field.needsGetter) {
          emitGetterForCSP(member, field.name, field.accessorName, builder);
        }
        if (field.needsUncheckedSetter) {
          emitSetterForCSP(member, field.name, field.accessorName, builder);
        }
      });
    }
  }

  void emitStubs(Iterable<StubMethod> stubs, ClassBuilder builder) {
    for (Method method in stubs) {
      jsAst.Property property = builder.addProperty(method.name, method.code);
      compiler.dumpInfoTask.registerElementAst(method.element, property);
    }
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [classElement] must be a declaration element.
   */
  void emitInstanceMembers(Class cls,
                           ClassBuilder builder) {
    ClassElement classElement = cls.element;
    assert(invariant(classElement, classElement.isDeclaration));

    if (cls.onlyForRti || cls.isMixinApplication) return;

    // TODO(herhut): This is a no-op. Should it be removed?
    for (Field field in cls.fields) {
      emitter.containerBuilder.addMemberField(field, builder);
    }

    for (Method method in cls.methods) {
      assert(invariant(classElement, method.element.isDeclaration));
      assert(invariant(classElement, method.element.isInstanceMember));
      emitter.containerBuilder.addMemberMethod(method, builder);
    }

    if (identical(classElement, compiler.objectClass)
        && backend.enabledNoSuchMethod) {
      // Emit the noSuchMethod handlers on the Object prototype now,
      // so that the code in the dynamicFunction helper can find
      // them. Note that this helper is invoked before analyzing the
      // full JS script.
      emitter.nsmEmitter.emitNoSuchMethodHandlers(builder.addProperty);
    }
  }

  /// Emits the members from the model.
  void emitRuntimeTypeInformation(Class cls, ClassBuilder builder) {
    assert(builder.functionType == null);
    if (cls.functionTypeIndex != null) {
      builder.functionType = '${cls.functionTypeIndex}';
    }

    for (Method method in cls.isChecks) {
      builder.addProperty(method.name, method.code);
    }
  }

  void emitNativeInfo(Class cls, ClassBuilder builder) {
    if (cls.nativeInfo != null) {
      builder.addProperty(namer.nativeSpecProperty, js.string(cls.nativeInfo));
    }
  }

  void emitClassBuilderWithReflectionData(Class cls,
                                          ClassBuilder classBuilder,
                                          ClassBuilder enclosingBuilder,
                                          Fragment fragment) {
    ClassElement classElement = cls.element;
    String className = cls.name;

    var metadata = task.metadataCollector.buildMetadataFunction(classElement);
    if (metadata != null) {
      classBuilder.addProperty("@", metadata);
    }

    if (backend.isAccessibleByReflection(classElement)) {
      List<DartType> typeVars = classElement.typeVariables;
      Iterable typeVariableProperties = emitter.typeVariableHandler
          .typeVariablesOf(classElement).map(js.number);

      ClassElement superclass = classElement.superclass;
      bool hasSuper = superclass != null;
      if ((!typeVariableProperties.isEmpty && !hasSuper) ||
          (hasSuper && !equalElements(superclass.typeVariables, typeVars))) {
        classBuilder.addProperty('<>',
            new jsAst.ArrayInitializer(typeVariableProperties.toList()));
      }
    }

    List<jsAst.Property> statics = new List<jsAst.Property>();
    ClassBuilder staticsBuilder = new ClassBuilder(classElement, namer);
    if (emitFields(cls, staticsBuilder, emitStatics: true)) {
      jsAst.ObjectInitializer initializer =
        staticsBuilder.toObjectInitializer();
      compiler.dumpInfoTask.registerElementAst(classElement,
        initializer);
      jsAst.Node property = initializer.properties.single;
      compiler.dumpInfoTask.registerElementAst(classElement, property);
      statics.add(property);
    }

    // TODO(herhut): Do not grab statics out of the properties.
    ClassBuilder classProperties =
        emitter.elementDescriptors[fragment].remove(classElement);
    if (classProperties != null) {
      statics.addAll(classProperties.properties);
    }

    if (!statics.isEmpty) {
      classBuilder.addProperty('static', new jsAst.ObjectInitializer(statics));
    }

    // TODO(ahe): This method (generateClass) should return a jsAst.Expression.
    jsAst.ObjectInitializer propertyValue = classBuilder.toObjectInitializer();
    compiler.dumpInfoTask.registerElementAst(classBuilder.element, propertyValue);
    enclosingBuilder.addProperty(className, propertyValue);

    String reflectionName = emitter.getReflectionName(classElement, className);
    if (reflectionName != null) {
      if (!backend.isAccessibleByReflection(classElement)) {
        enclosingBuilder.addProperty("+$reflectionName", js.number(0));
      } else {
        List<int> types = <int>[];
        if (classElement.supertype != null) {
          types.add(task.metadataCollector.reifyType(classElement.supertype));
        }
        for (DartType interface in classElement.interfaces) {
          types.add(task.metadataCollector.reifyType(interface));
        }
        enclosingBuilder.addProperty("+$reflectionName", js.numArray(types));
      }
    }
  }

  /**
   * Invokes [f] for each of the fields of [element].
   *
   * [element] must be a [ClassElement] or a [LibraryElement].
   *
   * If [element] is a [ClassElement], the static fields of the class are
   * visited if [visitStatics] is true and the instance fields are visited if
   * [visitStatics] is false.
   *
   * If [element] is a [LibraryElement], [visitStatics] must be true.
   *
   * When visiting the instance fields of a class, the fields of its superclass
   * are also visited if the class is instantiated.
   *
   * Invariant: [element] must be a declaration element.
   */
  void visitFields(Element element, bool visitStatics, AcceptField f) {
    assert(invariant(element, element.isDeclaration));

    bool isClass = false;
    bool isLibrary = false;
    if (element.isClass) {
      isClass = true;
    } else if (element.isLibrary) {
      isLibrary = true;
      assert(invariant(element, visitStatics));
    } else {
      throw new SpannableAssertionFailure(
          element, 'Expected a ClassElement or a LibraryElement.');
    }

    // If the class is never instantiated we still need to set it up for
    // inheritance purposes, but we can simplify its JavaScript constructor.
    bool isInstantiated =
        compiler.codegenWorld.directlyInstantiatedClasses.contains(element);

    void visitField(Element holder, FieldElement field) {
      assert(invariant(element, field.isDeclaration));
      String name = field.name;

      // Keep track of whether or not we're dealing with a field mixin
      // into a native class.
      bool isMixinNativeField =
          isClass && element.isNative && holder.isMixinApplication;

      // See if we can dynamically create getters and setters.
      // We can only generate getters and setters for [element] since
      // the fields of super classes could be overwritten with getters or
      // setters.
      bool needsGetter = false;
      bool needsSetter = false;
      if (isLibrary || isMixinNativeField || holder == element) {
        needsGetter = fieldNeedsGetter(field);
        needsSetter = fieldNeedsSetter(field);
      }

      if ((isInstantiated && !holder.isNative)
          || needsGetter
          || needsSetter) {
        String accessorName = namer.fieldAccessorName(field);
        String fieldName = namer.fieldPropertyName(field);
        bool needsCheckedSetter = false;
        if (compiler.enableTypeAssertions
            && needsSetter
            && !canAvoidGeneratedCheckedSetter(field)) {
          needsCheckedSetter = true;
          needsSetter = false;
        }
        // Getters and setters with suffixes will be generated dynamically.
        f(field, fieldName, accessorName, needsGetter, needsSetter,
          needsCheckedSetter);
      }
    }

    if (isLibrary) {
      LibraryElement library = element;
      library.implementation.forEachLocalMember((Element member) {
        if (member.isField) visitField(library, member);
      });
    } else if (visitStatics) {
      ClassElement cls = element;
      cls.implementation.forEachStaticField(visitField);
    } else {
      ClassElement cls = element;
      // TODO(kasperl): We should make sure to only emit one version of
      // overridden fields. Right now, we rely on the ordering so the
      // fields pulled in from mixins are replaced with the fields from
      // the class definition.

      // If a class is not instantiated then we add the field just so we can
      // generate the field getter/setter dynamically. Since this is only
      // allowed on fields that are in [element] we don't need to visit
      // superclasses for non-instantiated classes.
      cls.implementation.forEachInstanceField(
          visitField, includeSuperAndInjectedMembers: isInstantiated);
    }
  }

  void recordMangledField(Element member,
                          String accessorName,
                          String memberName) {
    if (!backend.shouldRetainGetter(member)) return;
    String previousName;
    if (member.isInstanceMember) {
      previousName = emitter.mangledFieldNames.putIfAbsent(
          '${namer.getterPrefix}$accessorName',
          () => memberName);
    } else {
      previousName = emitter.mangledGlobalFieldNames.putIfAbsent(
          accessorName,
          () => memberName);
    }
    assert(invariant(member, previousName == memberName,
                     message: '$previousName != ${memberName}'));
  }

  bool fieldNeedsGetter(VariableElement field) {
    assert(field.isField);
    if (fieldAccessNeverThrows(field)) return false;
    return backend.shouldRetainGetter(field)
        || compiler.codegenWorld.hasInvokedGetter(field, compiler.world);
  }

  bool fieldNeedsSetter(VariableElement field) {
    assert(field.isField);
    if (fieldAccessNeverThrows(field)) return false;
    return (!field.isFinal && !field.isConst)
        && (backend.shouldRetainSetter(field)
            || compiler.codegenWorld.hasInvokedSetter(field, compiler.world));
  }

  // We never access a field in a closure (a captured variable) without knowing
  // that it is there.  Therefore we don't need to use a getter (that will throw
  // if the getter method is missing), but can always access the field directly.
  static bool fieldAccessNeverThrows(VariableElement field) {
    return field is ClosureFieldElement;
  }

  bool canAvoidGeneratedCheckedSetter(VariableElement member) {
    // We never generate accessors for top-level/static fields.
    if (!member.isInstanceMember) return true;
    DartType type = member.type;
    return type.treatAsDynamic || (type.element == compiler.objectClass);
  }

  void generateCheckedSetter(Element member,
                             String fieldName,
                             String accessorName,
                             ClassBuilder builder) {
    jsAst.Expression code = backend.generatedCode[member];
    assert(code != null);
    String setterName = namer.deriveSetterName(accessorName);
    compiler.dumpInfoTask.registerElementAst(member,
        builder.addProperty(setterName, code));
    generateReflectionDataForFieldGetterOrSetter(
        member, setterName, builder, isGetter: false);
  }

  void emitGetterForCSP(Element member, String fieldName, String accessorName,
                        ClassBuilder builder) {
    jsAst.Expression function =
        _stubGenerator.generateGetter(member, fieldName);

    String getterName = namer.deriveGetterName(accessorName);
    ClassElement cls = member.enclosingClass;
    String className = namer.className(cls);
    OutputUnit outputUnit =
        compiler.deferredLoadTask.outputUnitForElement(member);
    emitter.cspPrecompiledFunctionFor(outputUnit).add(
        js('#.prototype.# = #', [className, getterName, function]));
    if (backend.isAccessibleByReflection(member)) {
      emitter.cspPrecompiledFunctionFor(outputUnit).add(
          js('#.prototype.#.${namer.reflectableField} = 1',
              [className, getterName]));
    }
  }

  void emitSetterForCSP(Element member, String fieldName, String accessorName,
                        ClassBuilder builder) {
    jsAst.Expression function =
        _stubGenerator.generateSetter(member, fieldName);

    String setterName = namer.deriveSetterName(accessorName);
    ClassElement cls = member.enclosingClass;
    String className = namer.className(cls);
    OutputUnit outputUnit =
        compiler.deferredLoadTask.outputUnitForElement(member);
    emitter.cspPrecompiledFunctionFor(outputUnit).add(
        js('#.prototype.# = #', [className, setterName, function]));
    if (backend.isAccessibleByReflection(member)) {
      emitter.cspPrecompiledFunctionFor(outputUnit).add(
          js('#.prototype.#.${namer.reflectableField} = 1',
              [className, setterName]));
    }
  }

  void generateReflectionDataForFieldGetterOrSetter(Element member,
                                                    String name,
                                                    ClassBuilder builder,
                                                    {bool isGetter}) {
    Selector selector = isGetter
        ? new Selector.getter(member.name, member.library)
        : new Selector.setter(member.name, member.library);
    String reflectionName = emitter.getReflectionName(selector, name);
    if (reflectionName != null) {
      var reflectable =
          js(backend.isAccessibleByReflection(member) ? '1' : '0');
      builder.addProperty('+$reflectionName', reflectable);
    }
  }
}
