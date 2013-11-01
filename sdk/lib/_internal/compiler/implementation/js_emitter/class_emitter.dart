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
                     CodeBuffer buffer,
                     Map<String, jsAst.Expression> additionalProperties) {
    final onlyForRti =
        task.typeTestEmitter.rtiNeededClasses.contains(classElement);

    assert(invariant(classElement, classElement.isDeclaration));
    assert(invariant(classElement, !classElement.isNative() || onlyForRti));

    task.needsDefineClass = true;
    String className = namer.getNameOfClass(classElement);

    ClassElement superclass = classElement.superclass;
    String superName = "";
    if (superclass != null) {
      superName = namer.getNameOfClass(superclass);
    }
    String runtimeName =
        namer.getPrimitiveInterceptorRuntimeName(classElement);

    if (classElement.isMixinApplication) {
      String mixinName = namer.getNameOfClass(computeMixinClass(classElement));
      superName = '$superName+$mixinName';
      task.needsMixinSupport = true;
    }

    ClassBuilder builder = new ClassBuilder();
    emitClassConstructor(classElement, builder, runtimeName,
                         onlyForRti: onlyForRti);
    emitFields(classElement, builder, superName, onlyForRti: onlyForRti);
    emitClassGettersSetters(classElement, builder, onlyForRti: onlyForRti);
    emitInstanceMembers(classElement, builder, onlyForRti: onlyForRti);
    task.typeTestEmitter.emitIsTests(classElement, builder);
    if (additionalProperties != null) {
      additionalProperties.forEach(builder.addProperty);
    }

    emitClassBuilderWithReflectionData(
        className, classElement, builder, buffer);
  }

  void emitClassConstructor(ClassElement classElement,
                            ClassBuilder builder,
                            String runtimeName,
                            {bool onlyForRti: false}) {
    List<String> fields = <String>[];
    if (!onlyForRti && !classElement.isNative()) {
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
    task.precompiledFunction.add(new jsAst.FunctionDeclaration(
        new jsAst.VariableDeclaration(constructorName),
        js.fun(fields, fields.map(
            (name) => js('this.$name = $name')).toList())));
    if (runtimeName == null) {
      runtimeName = constructorName;
    }
    task.precompiledFunction.addAll([
        js('$constructorName.builtin\$cls = "$runtimeName"'),
        js.if_('!"name" in $constructorName',
              js('$constructorName.name = "$constructorName"')),
        js('\$desc=\$collectedClasses.$constructorName'),
        js.if_('\$desc instanceof Array', js('\$desc = \$desc[1]')),
        js('$constructorName.prototype = \$desc'),
    ]);

    task.precompiledConstructorNames.add(js(constructorName));
  }

  /// Returns `true` if fields added.
  bool emitFields(Element element,
                  ClassBuilder builder,
                  String superName,
                  { bool classIsNative: false,
                    bool emitStatics: false,
                    bool onlyForRti: false }) {
    assert(!emitStatics || !onlyForRti);
    bool isClass = false;
    bool isLibrary = false;
    if (element.isClass()) {
      isClass = true;
    } else if (element.isLibrary()) {
      isLibrary = false;
      assert(invariant(element, emitStatics));
    } else {
      throw new SpannableAssertionFailure(
          element, 'Must be a ClassElement or a LibraryElement');
    }
    StringBuffer buffer = new StringBuffer();
    if (emitStatics) {
      assert(invariant(element, superName == null, message: superName));
    } else {
      assert(invariant(element, superName != null));
      String nativeName =
          namer.getPrimitiveInterceptorRuntimeName(element);
      if (nativeName != null) {
        buffer.write('$nativeName/');
      }
      buffer.write('$superName;');
    }
    int bufferClassLength = buffer.length;

    String separator = '';

    var fieldMetadata = [];
    bool hasMetadata = false;

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
          buffer.write(separator);
          separator = ',';
          var metadata = task.metadataEmitter.buildMetadataFunction(field);
          if (metadata != null) {
            hasMetadata = true;
          } else {
            metadata = new jsAst.LiteralNull();
          }
          fieldMetadata.add(metadata);
          recordMangledField(field, accessorName, field.name);
          if (!needsAccessor) {
            // Emit field for constructor generation.
            assert(!classIsNative);
            buffer.write(name);
          } else {
            // Emit (possibly renaming) field name so we can add accessors at
            // runtime.
            buffer.write(accessorName);
            if (name != accessorName) {
              buffer.write(':$name');
              // Only the native classes can have renaming accessors.
              assert(classIsNative);
            }

            int getterCode = 0;
            if (needsGetter) {
              if (field.isInstanceMember()) {
                // 01:  function() { return this.field; }
                // 10:  function(receiver) { return receiver.field; }
                // 11:  function(receiver) { return this.field; }
                bool isIntercepted = backend.fieldHasInterceptedGetter(field);
                getterCode += isIntercepted ? 2 : 0;
                getterCode += backend.isInterceptorClass(element) ? 0 : 1;
                // TODO(sra): 'isInterceptorClass' might not be the correct test
                // for methods forced to use the interceptor convention because
                // the method's class was elsewhere mixed-in to an interceptor.
                assert(!field.isInstanceMember() || getterCode != 0);
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
              if (field.isInstanceMember()) {
                // 01:  function(value) { this.field = value; }
                // 10:  function(receiver, value) { receiver.field = value; }
                // 11:  function(receiver, value) { this.field = value; }
                bool isIntercepted = backend.fieldHasInterceptedSetter(field);
                setterCode += isIntercepted ? 2 : 0;
                setterCode += backend.isInterceptorClass(element) ? 0 : 1;
                assert(!field.isInstanceMember() || setterCode != 0);
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
              compiler.reportInternalError(
                  field, 'Internal error: code is 0 ($element/$field)');
            } else {
              buffer.write(FIELD_CODE_CHARACTERS[code - FIRST_FIELD_CODE]);
            }
          }
          if (backend.isAccessibleByReflection(field)) {
            buffer.write(new String.fromCharCode(REFLECTION_MARKER));
          }
        }
      });
    }

    bool fieldsAdded = buffer.length > bufferClassLength;
    String compactClassData = buffer.toString();
    jsAst.Expression classDataNode = js.string(compactClassData);
    if (hasMetadata) {
      fieldMetadata.insert(0, classDataNode);
      classDataNode = new jsAst.ArrayInitializer.from(fieldMetadata);
    }
    builder.addProperty('', classDataNode);
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
      if (member.isInstanceMember()) {
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
                                          ClassBuilder builder,
                                          CodeBuffer buffer) {
    var metadata = task.metadataEmitter.buildMetadataFunction(classElement);
    if (metadata != null) {
      builder.addProperty("@", metadata);
    }

    if (backend.isNeededForReflection(classElement)) {
      Link typeVars = classElement.typeVariables;
      Iterable properties = [];
      if (task.typeVariableHandler.typeVariablesOf(classElement) != null) {
        properties = task.typeVariableHandler.typeVariablesOf(classElement)
            .map(js.toExpression);
      }

      ClassElement superclass = classElement.superclass;
      bool hasSuper = superclass != null;
      if ((!properties.isEmpty && !hasSuper) ||
          (hasSuper && superclass.typeVariables != typeVars)) {
        builder.addProperty('<>', new jsAst.ArrayInitializer.from(properties));
      }
    }
    List<CodeBuffer> classBuffers = task.elementBuffers[classElement];
    if (classBuffers == null) {
      classBuffers = [];
    } else {
      task.elementBuffers.remove(classElement);
    }
    CodeBuffer statics = new CodeBuffer();
    statics.write('{$n');
    bool hasStatics = false;
    ClassBuilder staticsBuilder = new ClassBuilder();
    if (emitFields(classElement, staticsBuilder, null, emitStatics: true)) {
      hasStatics = true;
      statics.write('"":$_');
      statics.write(
          jsAst.prettyPrint(staticsBuilder.properties.single.value, compiler));
      statics.write(',$n');
    }
    for (CodeBuffer classBuffer in classBuffers) {
      // TODO(ahe): What about deferred?
      if (classBuffer != null) {
        hasStatics = true;
        statics.addBuffer(classBuffer);
      }
    }
    statics.write('}$n');
    if (hasStatics) {
      builder.addProperty('static', new jsAst.Blob(statics));
    }

    // TODO(ahe): This method (generateClass) should return a jsAst.Expression.
    if (!buffer.isEmpty) {
      buffer.write(',$n$n');
    }
    buffer.write('$className:$_');
    buffer.write(jsAst.prettyPrint(builder.toObjectInitializer(), compiler));
    String reflectionName = task.getReflectionName(classElement, className);
    if (reflectionName != null) {
      if (!backend.isNeededForReflection(classElement)) {
        buffer.write(',$n$n"+$reflectionName": 0');
      } else {
        List<int> types = <int>[];
        if (classElement.supertype != null) {
          types.add(
              task.metadataEmitter.reifyType(classElement.supertype));
        }
        for (DartType interface in classElement.interfaces) {
          types.add(task.metadataEmitter.reifyType(interface));
        }
        buffer.write(',$n$n"+$reflectionName": $types');
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
    if (element.isClass()) {
      isClass = true;
    } else if (element.isLibrary()) {
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
          isClass && element.isNative() && holder.isMixinApplication;

      // See if we can dynamically create getters and setters.
      // We can only generate getters and setters for [element] since
      // the fields of super classes could be overwritten with getters or
      // setters.
      bool needsGetter = false;
      bool needsSetter = false;
      // We need to name shadowed fields differently, so they don't clash with
      // the non-shadowed field.
      bool isShadowed = false;
      if (isLibrary || isMixinNativeField || holder == element) {
        needsGetter = fieldNeedsGetter(field);
        needsSetter = fieldNeedsSetter(field);
      } else {
        ClassElement cls = element;
        isShadowed = cls.isShadowedByField(field);
      }

      if ((isInstantiated && !holder.isNative())
          || needsGetter
          || needsSetter) {
        String accessorName = isShadowed
            ? namer.shadowedFieldName(field)
            : namer.getNameOfField(field);
        String fieldName = field.hasFixedBackendName()
            ? field.fixedBackendName()
            : (isMixinNativeField ? name : accessorName);
        bool needsCheckedSetter = false;
        if (compiler.enableTypeAssertions
            && needsSetter
            && canGenerateCheckedSetter(field)) {
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
        if (member.isField()) visitField(library, member);
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
    if (member.isInstanceMember()) {
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
    assert(field.isField());
    if (fieldAccessNeverThrows(field)) return false;
    return backend.shouldRetainGetter(field)
        || compiler.codegenWorld.hasInvokedGetter(field, compiler);
  }

  bool fieldNeedsSetter(VariableElement field) {
    assert(field.isField());
    if (fieldAccessNeverThrows(field)) return false;
    return (!field.modifiers.isFinalOrConst())
        && (backend.shouldRetainSetter(field)
            || compiler.codegenWorld.hasInvokedSetter(field, compiler));
  }

  // We never access a field in a closure (a captured variable) without knowing
  // that it is there.  Therefore we don't need to use a getter (that will throw
  // if the getter method is missing), but can always access the field directly.
  static bool fieldAccessNeverThrows(VariableElement field) {
    return field is ClosureFieldElement;
  }

  bool canGenerateCheckedSetter(VariableElement field) {
    // We never generate accessors for top-level/static fields.
    if (!field.isInstanceMember()) return false;
    DartType type = field.computeType(compiler).unalias(compiler);
    if (type.element.isTypeVariable() ||
        (type is FunctionType && type.containsTypeVariables) ||
        type.treatAsDynamic ||
        type.element == compiler.objectClass) {
      // TODO(ngeoffray): Support type checks on type parameters.
      return false;
    }
    return true;
  }

  void generateCheckedSetter(Element member,
                             String fieldName,
                             String accessorName,
                             ClassBuilder builder) {
    assert(canGenerateCheckedSetter(member));
    DartType type = member.computeType(compiler);
    // TODO(ahe): Generate a dynamic type error here.
    if (type.element.isErroneous()) return;
    type = type.unalias(compiler);
    // TODO(11273): Support complex subtype checks.
    type = type.asRaw();
    CheckedModeHelper helper =
        backend.getCheckedModeHelper(type, typeCast: false);
    FunctionElement helperElement = helper.getElement(compiler);
    String helperName = namer.isolateAccess(helperElement);
    List<jsAst.Expression> arguments = <jsAst.Expression>[js('v')];
    if (helperElement.computeSignature(compiler).parameterCount != 1) {
      arguments.add(js.string(namer.operatorIsType(type)));
    }

    String setterName = namer.setterNameFromAccessorName(accessorName);
    String receiver = backend.isInterceptorClass(member.getEnclosingClass())
        ? 'receiver' : 'this';
    List<String> args = backend.isInterceptedMethod(member)
        ? ['receiver', 'v']
        : ['v'];
    builder.addProperty(setterName,
        js.fun(args,
            js('$receiver.$fieldName = #', js(helperName)(arguments))));
    generateReflectionDataForFieldGetterOrSetter(
        member, setterName, builder, isGetter: false);
  }

  void generateGetter(Element member, String fieldName, String accessorName,
                      ClassBuilder builder) {
    String getterName = namer.getterNameFromAccessorName(accessorName);
    ClassElement cls = member.getEnclosingClass();
    String className = namer.getNameOfClass(cls);
    String receiver = backend.isInterceptorClass(cls) ? 'receiver' : 'this';
    List<String> args = backend.isInterceptedMethod(member) ? ['receiver'] : [];
    task.precompiledFunction.add(
        js('$className.prototype.$getterName = #',
           js.fun(args, js.return_(js('$receiver.$fieldName')))));
    if (backend.isNeededForReflection(member)) {
      task.precompiledFunction.add(
          js('$className.prototype.$getterName.${namer.reflectableField} = 1'));
    }
  }

  void generateSetter(Element member, String fieldName, String accessorName,
                      ClassBuilder builder) {
    String setterName = namer.setterNameFromAccessorName(accessorName);
    ClassElement cls = member.getEnclosingClass();
    String className = namer.getNameOfClass(cls);
    String receiver = backend.isInterceptorClass(cls) ? 'receiver' : 'this';
    List<String> args =
        backend.isInterceptedMethod(member) ? ['receiver', 'v'] : ['v'];
    task.precompiledFunction.add(
        js('$className.prototype.$setterName = #',
           js.fun(args, js.return_(js('$receiver.$fieldName = v')))));
    if (backend.isNeededForReflection(member)) {
      task.precompiledFunction.add(
          js('$className.prototype.$setterName.${namer.reflectableField} = 1'));
    }
  }

  void generateReflectionDataForFieldGetterOrSetter(Element member,
                                                    String name,
                                                    ClassBuilder builder,
                                                    {bool isGetter}) {
    Selector selector = isGetter
        ? new Selector.getter(member.name, member.getLibrary())
        : new Selector.setter(member.name, member.getLibrary());
    String reflectionName = task.getReflectionName(selector, name);
    if (reflectionName != null) {
      var reflectable =
          js(backend.isAccessibleByReflection(member) ? '1' : '0');
      builder.addProperty('+$reflectionName', reflectable);
    }
  }
}
