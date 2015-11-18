// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter.full_emitter;

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
    jsAst.Name superName;
    if (superclass != null) {
      superName = namer.className(superclass);
    }

    if (cls.isMixinApplication) {
      MixinApplication mixinApplication = cls;
      jsAst.Name mixinName = mixinApplication.mixinClass.name;
      superName =
          new CompoundName([superName, Namer.literalPlus, mixinName]);
      emitter.needsMixinSupport = true;
    }

    ClassBuilder builder = new ClassBuilder.forClass(classElement, namer);
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
      jsAst.Name name = namer.getterForMember(Names.call);
      builder.addProperty(name, function);
    }

    emitClassBuilderWithReflectionData(cls, builder, enclosingBuilder,
        fragment);
  }
  /**
  * Emits the precompiled constructor when in CSP mode.
  */
  void emitConstructorsForCSP(Class cls) {
    List<jsAst.Name> fieldNames = <jsAst.Name>[];

    if (!compiler.useContentSecurityPolicy) return;

    if (!cls.onlyForRti && !cls.isNative) {
      fieldNames = cls.fields.map((Field field) => field.name).toList();
    }

    ClassElement classElement = cls.element;

    jsAst.Expression constructorAst =
        _stubGenerator.generateClassConstructor(classElement, fieldNames);

    jsAst.Name constructorName = namer.className(classElement);
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
      jsAst.Name name = field.name;
      jsAst.Name accessorName = field.accessorName;
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
        List<jsAst.Literal> fieldNameParts = <jsAst.Literal>[];
        if (!needsAccessor) {
          // Emit field for constructor generation.
          assert(!classIsNative);
          fieldNameParts.add(name);
        } else {
          // Emit (possibly renaming) field name so we can add accessors at
          // runtime.
          if (name != accessorName) {
            fieldNameParts.add(accessorName);
            fieldNameParts.add(js.stringPart(':'));
          }
          fieldNameParts.add(name);
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
            reporter.internalError(fieldElement,
                'Field code is 0 ($fieldElement).');
          }
          fieldNameParts.add(
              js.stringPart(FIELD_CODE_CHARACTERS[code - FIRST_FIELD_CODE]));
        }
        // Fields can only be reflected if their declaring class is reflectable
        // (as they are only accessible via [ClassMirror.declarations]).
        // However, set/get operations can be performed on them, so they are
        // reflectable in some sense, which leads to [isAccessibleByReflection]
        // reporting `true`.
        if (backend.isAccessibleByReflection(fieldElement)) {
          fieldNameParts.add(new jsAst.LiteralString('-'));
          if (fieldElement.isTopLevel ||
              backend.isAccessibleByReflection(fieldElement.enclosingClass)) {
            DartType type = fieldElement.type;
            fieldNameParts.add(task.metadataCollector.reifyType(type));
          }
        }
        jsAst.Literal fieldNameAst = js.concatenateStrings(fieldNameParts);
        builder.addField(fieldNameAst);
        // Add 1 because adding a field to the class also requires a comma
        compiler.dumpInfoTask.registerElementAst(fieldElement, fieldNameAst);
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

    for (StubMethod method in cls.checkedSetters) {
      Element member = method.element;
      assert(member != null);
      jsAst.Expression code = method.code;
      jsAst.Name setterName = method.name;
      compiler.dumpInfoTask.registerElementAst(member,
          builder.addProperty(setterName, code));
      generateReflectionDataForFieldGetterOrSetter(
          member, setterName, builder, isGetter: false);
    }
  }

  /// Emits getters/setters for fields if compiling in CSP mode.
  void emitClassGettersSettersForCSP(Class cls, ClassBuilder builder) {

    if (!compiler.useContentSecurityPolicy || cls.onlyForRti) return;

    for (Field field in cls.fields) {
      Element member = field.element;
      reporter.withCurrentElement(member, () {
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
      builder.functionType = cls.functionTypeIndex;
    }

    for (Method method in cls.isChecks) {
      builder.addProperty(method.name, method.code);
    }
  }

  void emitNativeInfo(Class cls, ClassBuilder builder) {
    jsAst.Expression nativeInfo = NativeGenerator.encodeNativeInfo(cls);
    if (nativeInfo != null) {
      builder.addPropertyByName(namer.nativeSpecProperty, nativeInfo);
    }
  }

  void emitClassBuilderWithReflectionData(Class cls,
                                          ClassBuilder classBuilder,
                                          ClassBuilder enclosingBuilder,
                                          Fragment fragment) {
    ClassElement classElement = cls.element;
    jsAst.Name className = cls.name;

    var metadata = task.metadataCollector.buildMetadataFunction(classElement);
    if (metadata != null) {
      classBuilder.addPropertyByName("@", metadata);
    }

    if (backend.isAccessibleByReflection(classElement)) {
      List<DartType> typeVars = classElement.typeVariables;
      Iterable typeVariableProperties = emitter.typeVariableHandler
          .typeVariablesOf(classElement);

      ClassElement superclass = classElement.superclass;
      bool hasSuper = superclass != null;
      if ((!typeVariableProperties.isEmpty && !hasSuper) ||
          (hasSuper && !equalElements(superclass.typeVariables, typeVars))) {
        classBuilder.addPropertyByName('<>',
            new jsAst.ArrayInitializer(typeVariableProperties.toList()));
      }
    }

    List<jsAst.Property> statics = new List<jsAst.Property>();
    ClassBuilder staticsBuilder =
        new ClassBuilder.forStatics(classElement, namer);
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
      classBuilder.addPropertyByName('static',
                                     new jsAst.ObjectInitializer(statics));
    }

    // TODO(ahe): This method (generateClass) should return a jsAst.Expression.
    jsAst.ObjectInitializer propertyValue =
        classBuilder.toObjectInitializer();
    compiler.dumpInfoTask.registerElementAst(classBuilder.element, propertyValue);
    enclosingBuilder.addProperty(className, propertyValue);

    String reflectionName = emitter.getReflectionName(classElement, className);
    if (reflectionName != null) {
      if (!backend.isAccessibleByReflection(classElement) || cls.onlyForRti) {
        // TODO(herhut): Fix use of reflection name here.
        enclosingBuilder.addPropertyByName("+$reflectionName", js.number(0));
      } else {
        List<jsAst.Expression> types = <jsAst.Expression>[];
        if (classElement.supertype != null) {
          types.add(task.metadataCollector.reifyType(classElement.supertype));
        }
        for (DartType interface in classElement.interfaces) {
          types.add(task.metadataCollector.reifyType(interface));
        }
        // TODO(herhut): Fix use of reflection name here.
        enclosingBuilder.addPropertyByName("+$reflectionName",
            new jsAst.ArrayInitializer(types));
      }
    }
  }

  void recordMangledField(Element member,
                          jsAst.Name accessorName,
                          String memberName) {
    if (!backend.shouldRetainGetter(member)) return;
    String previousName;
    if (member.isInstanceMember) {
      previousName = emitter.mangledFieldNames.putIfAbsent(
          namer.deriveGetterName(accessorName),
          () => memberName);
    } else {
      previousName = emitter.mangledGlobalFieldNames.putIfAbsent(
          accessorName,
          () => memberName);
    }
    assert(invariant(member, previousName == memberName,
                     message: '$previousName != ${memberName}'));
  }

  void emitGetterForCSP(Element member, jsAst.Name fieldName,
                        jsAst.Name accessorName,
                        ClassBuilder builder) {
    jsAst.Expression function =
        _stubGenerator.generateGetter(member, fieldName);

    jsAst.Name getterName = namer.deriveGetterName(accessorName);
    ClassElement cls = member.enclosingClass;
    jsAst.Name className = namer.className(cls);
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

  void emitSetterForCSP(Element member, jsAst.Name fieldName,
                        jsAst.Name accessorName,
                        ClassBuilder builder) {
    jsAst.Expression function =
        _stubGenerator.generateSetter(member, fieldName);

    jsAst.Name setterName = namer.deriveSetterName(accessorName);
    ClassElement cls = member.enclosingClass;
    jsAst.Name className = namer.className(cls);
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
                                                    jsAst.Name name,
                                                    ClassBuilder builder,
                                                    {bool isGetter}) {
    Selector selector = isGetter
        ? new Selector.getter(
            new Name(member.name, member.library))
        : new Selector.setter(
            new Name(member.name, member.library, isSetter: true));
    String reflectionName = emitter.getReflectionName(selector, name);
    if (reflectionName != null) {
      var reflectable =
          js(backend.isAccessibleByReflection(member) ? '1' : '0');
      builder.addPropertyByName('+$reflectionName', reflectable);
    }
  }
}
