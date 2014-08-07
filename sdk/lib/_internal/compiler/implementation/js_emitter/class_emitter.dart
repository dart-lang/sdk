// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

class ClassEmitter extends CodeEmitterHelper {
  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [classElement] must be a declaration element.
   */
  void generateClass(ClassElement classElement,
                     ClassBuilder properties,
                     Map<String, jsAst.Expression> additionalProperties) {
    final onlyForRti =
        task.typeTestEmitter.rtiNeededClasses.contains(classElement);

    assert(invariant(classElement, classElement.isDeclaration));
    assert(invariant(classElement, !classElement.isNative || onlyForRti));

    task.needsDefineClass = true;
    String className = namer.getNameOfClass(classElement);

    ClassElement superclass = classElement.superclass;
    String superName = "";
    if (superclass != null) {
      superName = namer.getNameOfClass(superclass);
    }

    if (classElement.isMixinApplication) {
      String mixinName = namer.getNameOfClass(computeMixinClass(classElement));
      superName = '$superName+$mixinName';
      task.needsMixinSupport = true;
    }

    ClassBuilder builder = new ClassBuilder(classElement, namer);
    emitClassConstructor(classElement, builder, onlyForRti: onlyForRti);
    emitFields(classElement, builder, superName, onlyForRti: onlyForRti);
    emitClassGettersSetters(classElement, builder, onlyForRti: onlyForRti);
    emitInstanceMembers(classElement, builder, onlyForRti: onlyForRti);
    task.typeTestEmitter.emitIsTests(classElement, builder);
    if (additionalProperties != null) {
      additionalProperties.forEach(builder.addProperty);
    }

    if (classElement == backend.closureClass) {
      // We add a special getter here to allow for tearing off a closure from
      // itself.
      String name = namer.getMappedInstanceName(Compiler.CALL_OPERATOR_NAME);
      jsAst.Fun function = js('function() { return this; }');
      builder.addProperty(namer.getterNameFromAccessorName(name), function);
    }

    emitTypeVariableReaders(classElement, builder);

    emitClassBuilderWithReflectionData(
        className, classElement, builder, properties);
  }

  void emitClassConstructor(ClassElement classElement,
                            ClassBuilder builder,
                            {bool onlyForRti: false}) {
    List<String> fields = <String>[];
    if (!onlyForRti && !classElement.isNative) {
      visitFields(classElement, false,
                  (Element member,
                   String name,
                   String accessorName,
                   bool needsGetter,
                   bool needsSetter,
                   bool needsCheckedSetter) {
        fields.add(name);
      });
    }
    String constructorName = namer.getNameOfClass(classElement);

    // TODO(sra): Implement placeholders in VariableDeclaration position:
    //     task.precompiledFunction.add(js.statement('function #(#) { #; }',
    //        [ constructorName, fields,
    //            fields.map(
    //                (name) => js('this.# = #', [name, name]))]));
    jsAst.Expression constructorAst = js('function(#) { #; }',
        [fields,
         fields.map((name) => js('this.# = #', [name, name]))]);
    task.emitPrecompiledConstructor(constructorName, constructorAst);
  }

  /// Returns `true` if fields added.
  bool emitFields(Element element,
                  ClassBuilder builder,
                  String superName,
                  { bool classIsNative: false,
                    bool emitStatics: false,
                    bool onlyForRti: false }) {
    assert(!emitStatics || !onlyForRti);
    if (element.isLibrary) {
      assert(invariant(element, emitStatics));
    } else if (!element.isClass) {
      throw new SpannableAssertionFailure(
          element, 'Must be a ClassElement or a LibraryElement');
    }
    if (emitStatics) {
      assert(invariant(element, superName == null, message: superName));
    } else {
      assert(invariant(element, superName != null));
      builder.superName = superName;
    }
    var fieldMetadata = [];
    bool hasMetadata = false;
    bool fieldsAdded = false;

    if (!onlyForRti) {
      visitFields(element, emitStatics,
                  (VariableElement field,
                   String name,
                   String accessorName,
                   bool needsGetter,
                   bool needsSetter,
                   bool needsCheckedSetter) {
        // Ignore needsCheckedSetter - that is handled below.
        bool needsAccessor = (needsGetter || needsSetter);
        // We need to output the fields for non-native classes so we can auto-
        // generate the constructor.  For native classes there are no
        // constructors, so we don't need the fields unless we are generating
        // accessors at runtime.
        if (!classIsNative || needsAccessor) {
          var metadata = task.metadataEmitter.buildMetadataFunction(field);
          if (metadata != null) {
            hasMetadata = true;
          } else {
            metadata = new jsAst.LiteralNull();
          }
          fieldMetadata.add(metadata);
          recordMangledField(field, accessorName,
              namer.privateName(field.library, field.name));
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

            int getterCode = 0;
            if (needsAccessor && backend.fieldHasInterceptedGetter(field)) {
              task.interceptorEmitter.interceptorInvocationNames.add(
                  namer.getterName(field));
            }
            if (needsAccessor && backend.fieldHasInterceptedGetter(field)) {
              task.interceptorEmitter.interceptorInvocationNames.add(
                  namer.setterName(field));
            }
            if (needsGetter) {
              if (field.isInstanceMember) {
                // 01:  function() { return this.field; }
                // 10:  function(receiver) { return receiver.field; }
                // 11:  function(receiver) { return this.field; }
                bool isIntercepted = backend.fieldHasInterceptedGetter(field);
                getterCode += isIntercepted ? 2 : 0;
                getterCode += backend.isInterceptorClass(element) ? 0 : 1;
                // TODO(sra): 'isInterceptorClass' might not be the correct test
                // for methods forced to use the interceptor convention because
                // the method's class was elsewhere mixed-in to an interceptor.
                assert(!field.isInstanceMember || getterCode != 0);
                if (isIntercepted) {
                  task.interceptorEmitter.interceptorInvocationNames.add(
                      namer.getterName(field));
                }
              } else {
                getterCode = 1;
              }
            }
            int setterCode = 0;
            if (needsSetter) {
              if (field.isInstanceMember) {
                // 01:  function(value) { this.field = value; }
                // 10:  function(receiver, value) { receiver.field = value; }
                // 11:  function(receiver, value) { this.field = value; }
                bool isIntercepted = backend.fieldHasInterceptedSetter(field);
                setterCode += isIntercepted ? 2 : 0;
                setterCode += backend.isInterceptorClass(element) ? 0 : 1;
                assert(!field.isInstanceMember || setterCode != 0);
                if (isIntercepted) {
                  task.interceptorEmitter.interceptorInvocationNames.add(
                      namer.setterName(field));
                }
              } else {
                setterCode = 1;
              }
            }
            int code = getterCode + (setterCode << 2);
            if (code == 0) {
              compiler.internalError(field,
                  'Field code is 0 ($element/$field).');
            } else {
              fieldCode = FIELD_CODE_CHARACTERS[code - FIRST_FIELD_CODE];
            }
          }
          if (backend.isAccessibleByReflection(field)) {
            DartType type = field.type;
            reflectionMarker = '-${task.metadataEmitter.reifyType(type)}';
          }
          String builtFieldname = '$fieldName$fieldCode$reflectionMarker';
          builder.addField(builtFieldname);
          // Add 1 because adding a field to the class also requires a comma
          compiler.dumpInfoTask.recordFieldNameSize(field,
              builtFieldname.length + 1);
          fieldsAdded = true;
        }
      });
    }

    if (hasMetadata) {
      builder.fieldMetadata = fieldMetadata;
    }
    return fieldsAdded;
  }

  void emitClassGettersSetters(ClassElement classElement,
                               ClassBuilder builder,
                               {bool onlyForRti: false}) {
    if (onlyForRti) return;

    visitFields(classElement, false,
                (VariableElement member,
                 String name,
                 String accessorName,
                 bool needsGetter,
                 bool needsSetter,
                 bool needsCheckedSetter) {
      compiler.withCurrentElement(member, () {
        if (needsCheckedSetter) {
          assert(!needsSetter);
          generateCheckedSetter(member, name, accessorName, builder);
        }
        if (needsGetter) {
          generateGetter(member, name, accessorName, builder);
        }
        if (needsSetter) {
          generateSetter(member, name, accessorName, builder);
        }
      });
    });
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [classElement] must be a declaration element.
   */
  void emitInstanceMembers(ClassElement classElement,
                           ClassBuilder builder,
                           {bool onlyForRti: false}) {
    assert(invariant(classElement, classElement.isDeclaration));

    if (onlyForRti || classElement.isMixinApplication) return;

    void visitMember(ClassElement enclosing, Element member) {
      assert(invariant(classElement, member.isDeclaration));
      if (member.isInstanceMember) {
        task.containerBuilder.addMember(member, builder);
      }
    }

    classElement.implementation.forEachMember(
        visitMember,
        includeBackendMembers: true);

    if (identical(classElement, compiler.objectClass)
        && compiler.enabledNoSuchMethod) {
      // Emit the noSuchMethod handlers on the Object prototype now,
      // so that the code in the dynamicFunction helper can find
      // them. Note that this helper is invoked before analyzing the
      // full JS script.
      if (!task.nativeEmitter.handleNoSuchMethod) {
        task.nsmEmitter.emitNoSuchMethodHandlers(builder.addProperty);
      }
    }
  }

  void emitClassBuilderWithReflectionData(String className,
                                          ClassElement classElement,
                                          ClassBuilder classBuilder,
                                          ClassBuilder enclosingBuilder) {
    var metadata = task.metadataEmitter.buildMetadataFunction(classElement);
    if (metadata != null) {
      classBuilder.addProperty("@", metadata);
    }

    if (backend.isAccessibleByReflection(classElement)) {
      List<DartType> typeVars = classElement.typeVariables;
      Iterable typeVariableProperties = task.typeVariableHandler
          .typeVariablesOf(classElement).map(js.number);

      ClassElement superclass = classElement.superclass;
      bool hasSuper = superclass != null;
      if ((!typeVariableProperties.isEmpty && !hasSuper) ||
          (hasSuper && !equalElements(superclass.typeVariables, typeVars))) {
        classBuilder.addProperty('<>',
            new jsAst.ArrayInitializer.from(typeVariableProperties));
      }
    }

    List<jsAst.Property> statics = new List<jsAst.Property>();
    ClassBuilder staticsBuilder = new ClassBuilder(classElement, namer);
    if (emitFields(classElement, staticsBuilder, null, emitStatics: true)) {
      jsAst.ObjectInitializer initializer =
        staticsBuilder.toObjectInitializer();
      compiler.dumpInfoTask.registerElementAst(classElement,
        initializer);
      jsAst.Node property = initializer.properties.single;
      compiler.dumpInfoTask.registerElementAst(classElement, property);
      statics.add(property);
    }

    Map<OutputUnit, ClassBuilder> classPropertyLists =
        task.elementDescriptors.remove(classElement);
    if (classPropertyLists != null) {
      for (ClassBuilder classProperties in classPropertyLists.values) {
        // TODO(sigurdm): What about deferred?
        if (classProperties != null) {
          statics.addAll(classProperties.properties);
        }
      }
    }

    if (!statics.isEmpty) {
      classBuilder.addProperty('static', new jsAst.ObjectInitializer(statics));
    }

    // TODO(ahe): This method (generateClass) should return a jsAst.Expression.
    jsAst.ObjectInitializer propertyValue = classBuilder.toObjectInitializer();
    compiler.dumpInfoTask.registerElementAst(classBuilder.element, propertyValue);
    enclosingBuilder.addProperty(className, propertyValue);

    String reflectionName = task.getReflectionName(classElement, className);
    if (reflectionName != null) {
      if (!backend.isAccessibleByReflection(classElement)) {
        enclosingBuilder.addProperty("+$reflectionName", js.number(0));
      } else {
        List<int> types = <int>[];
        if (classElement.supertype != null) {
          types.add(task.metadataEmitter.reifyType(classElement.supertype));
        }
        for (DartType interface in classElement.interfaces) {
          types.add(task.metadataEmitter.reifyType(interface));
        }
        enclosingBuilder.addProperty("+$reflectionName",
            new jsAst.ArrayInitializer.from(types.map(js.number)));
      }
    }
  }

  /**
   * Calls [addField] for each of the fields of [element].
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
        compiler.codegenWorld.instantiatedClasses.contains(element);

    void visitField(Element holder, VariableElement field) {
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
      previousName = task.mangledFieldNames.putIfAbsent(
          '${namer.getterPrefix}$accessorName',
          () => memberName);
    } else {
      previousName = task.mangledGlobalFieldNames.putIfAbsent(
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
        || compiler.codegenWorld.hasInvokedGetter(field, compiler);
  }

  bool fieldNeedsSetter(VariableElement field) {
    assert(field.isField);
    if (fieldAccessNeverThrows(field)) return false;
    return (!field.isFinal && !field.isConst)
        && (backend.shouldRetainSetter(field)
            || compiler.codegenWorld.hasInvokedSetter(field, compiler));
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
    String setterName = namer.setterNameFromAccessorName(accessorName);
    compiler.dumpInfoTask.registerElementAst(member,
        builder.addProperty(setterName, code));
    generateReflectionDataForFieldGetterOrSetter(
        member, setterName, builder, isGetter: false);
  }

  void generateGetter(Element member, String fieldName, String accessorName,
                      ClassBuilder builder) {
    String getterName = namer.getterNameFromAccessorName(accessorName);
    ClassElement cls = member.enclosingClass;
    String className = namer.getNameOfClass(cls);
    String receiver = backend.isInterceptorClass(cls) ? 'receiver' : 'this';
    List<String> args = backend.isInterceptedMethod(member) ? ['receiver'] : [];
    task.precompiledFunction.add(
        js('#.prototype.# = function(#) { return #.# }',
           [className, getterName, args, receiver, fieldName]));
    if (backend.isAccessibleByReflection(member)) {
      task.precompiledFunction.add(
          js('#.prototype.#.${namer.reflectableField} = 1',
              [className, getterName]));
    }
  }

  void generateSetter(Element member, String fieldName, String accessorName,
                      ClassBuilder builder) {
    String setterName = namer.setterNameFromAccessorName(accessorName);
    ClassElement cls = member.enclosingClass;
    String className = namer.getNameOfClass(cls);
    String receiver = backend.isInterceptorClass(cls) ? 'receiver' : 'this';
    List<String> args = backend.isInterceptedMethod(member) ? ['receiver'] : [];
    task.precompiledFunction.add(
        // TODO: remove 'return'?
        js('#.prototype.# = function(#, v) { return #.# = v; }',
            [className, setterName, args, receiver, fieldName]));
    if (backend.isAccessibleByReflection(member)) {
      task.precompiledFunction.add(
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
    String reflectionName = task.getReflectionName(selector, name);
    if (reflectionName != null) {
      var reflectable =
          js(backend.isAccessibleByReflection(member) ? '1' : '0');
      builder.addProperty('+$reflectionName', reflectable);
    }
  }

  void emitTypeVariableReaders(ClassElement cls, ClassBuilder builder) {
    List typeVariables = [];
    ClassElement superclass = cls;
    while (superclass != null) {
      for (TypeVariableType parameter in superclass.typeVariables) {
        if (task.readTypeVariables.contains(parameter.element)) {
          emitTypeVariableReader(cls, builder, parameter.element);
        }
      }
      superclass = superclass.superclass;
    }
  }

  void emitTypeVariableReader(ClassElement cls,
                              ClassBuilder builder,
                              TypeVariableElement element) {
    String name = namer.readTypeVariableName(element);
    jsAst.Expression index =
        js.number(RuntimeTypes.getTypeVariableIndex(element));
    jsAst.Expression computeTypeVariable;

    Substitution substitution =
        backend.rti.computeSubstitution(
            cls, element.typeDeclaration, alwaysGenerateFunction: true);
    if (substitution != null) {
      jsAst.Expression typeArguments =
          js(r'#.apply(null, this.$builtinTypeInfo)',
              substitution.getCode(backend.rti, true));
      computeTypeVariable = js('#[#]', [typeArguments, index]);
    } else {
      // TODO(ahe): These can be generated dynamically.
      computeTypeVariable =
          js(r'this.$builtinTypeInfo && this.$builtinTypeInfo[#]', index);
    }
    jsAst.Expression convertRtiToRuntimeType =
        namer.elementAccess(backend.findHelper('convertRtiToRuntimeType'));
    compiler.dumpInfoTask.registerElementAst(element,
        builder.addProperty(name,
            js('function () { return #(#) }',
                [convertRtiToRuntimeType, computeTypeVariable])));
  }
}
