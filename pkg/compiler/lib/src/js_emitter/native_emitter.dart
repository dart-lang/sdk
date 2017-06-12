// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.native_emitter;

import '../common.dart';
import '../common_elements.dart' show CommonElements;
import '../elements/types.dart' show DartType, FunctionType;
import '../elements/entities.dart';
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js_backend/interceptor_data.dart';
import '../js_backend/native_data.dart';
import '../native/enqueue.dart' show NativeCodegenEnqueuer;
import '../universe/world_builder.dart' show CodegenWorldBuilder;
import '../world.dart' show ClosedWorld;

import 'code_emitter_task.dart' show CodeEmitterTask;
import 'model.dart';

class NativeEmitter {
  final CodeEmitterTask _emitterTask;
  final ClosedWorld _closedWorld;
  final CodegenWorldBuilder _worldBuilder;
  final NativeCodegenEnqueuer _nativeCodegenEnqueuer;

  // Whether the application contains native classes.
  bool hasNativeClasses = false;

  // Caches the native subtypes of a native class.
  Map<ClassEntity, List<ClassEntity>> subtypes =
      <ClassEntity, List<ClassEntity>>{};

  // Caches the direct native subtypes of a native class.
  Map<ClassEntity, List<ClassEntity>> directSubtypes =
      <ClassEntity, List<ClassEntity>>{};

  // Caches the methods that have a native body.
  Set<FunctionEntity> nativeMethods = new Set<FunctionEntity>();

  NativeEmitter(this._emitterTask, this._closedWorld, this._worldBuilder,
      this._nativeCodegenEnqueuer);

  CommonElements get _commonElements => _closedWorld.commonElements;
  NativeData get _nativeData => _closedWorld.nativeData;
  InterceptorData get _interceptorData => _closedWorld.interceptorData;

  /**
   * Prepares native classes for emission. Returns the unneeded classes.
   *
   * Removes trivial classes (that can be represented by a super type) and
   * generates properties that have to be added to classes (native or not).
   *
   * Updates the `nativeLeafTags`, `nativeNonLeafTags` and `nativeExtensions`
   * fields of the given classes. This data must be emitted with the
   * corresponding classes.
   *
   * The interceptors are filtered to avoid emitting trivial interceptors.  For
   * example, if the program contains no code that can distinguish between the
   * numerous subclasses of `Element` then we can pretend that `Element` is a
   * leaf class, and all instances of subclasses of `Element` are instances of
   * `Element`.
   *
   * There is also a performance benefit (in addition to the obvious code size
   * benefit), due to how [getNativeInterceptor] works.  Finding the interceptor
   * of a leaf class in the hierarchy is more efficient that a non-leaf, so it
   * improves performance when more classes can be treated as leaves.
   *
   * [classes] contains native classes, mixin applications, and user subclasses
   * of native classes.
   *
   * [interceptorClassesNeededByConstants] contains the interceptors that are
   * referenced by constants.
   *
   * [classesModifiedByEmitRTISupport] contains the list of classes that must
   * exist, because runtime-type support adds information to the class.
   */
  Set<Class> prepareNativeClasses(
      List<Class> classes,
      Set<ClassEntity> interceptorClassesNeededByConstants,
      Set<ClassEntity> classesModifiedByEmitRTISupport) {
    assert(classes.every((Class cls) => cls != null));

    hasNativeClasses = classes.isNotEmpty;

    // Compute a pre-order traversal of the subclass forest.  We actually want a
    // post-order traversal but it is easier to compute the pre-order and use it
    // in reverse.
    List<Class> preOrder = <Class>[];
    Set<Class> seen = new Set<Class>();

    Class objectClass = null;
    Class jsInterceptorClass = null;

    void walk(Class cls) {
      if (cls.element == _commonElements.objectClass) {
        objectClass = cls;
        return;
      }
      if (cls.element == _commonElements.jsInterceptorClass) {
        jsInterceptorClass = cls;
        return;
      }
      if (seen.contains(cls)) return;
      seen.add(cls);
      walk(cls.superclass);
      preOrder.add(cls);
    }

    classes.forEach(walk);

    // Find which classes are needed and which are non-leaf classes.  Any class
    // that is not needed can be treated as a leaf class equivalent to some
    // needed class.

    Set<Class> neededClasses = new Set<Class>();
    Set<Class> nonLeafClasses = new Set<Class>();

    Map<Class, List<Class>> extensionPoints = computeExtensionPoints(preOrder);

    neededClasses.add(objectClass);

    for (Class cls in preOrder.reversed) {
      ClassEntity classElement = cls.element;
      // Post-order traversal ensures we visit the subclasses before their
      // superclass.  This makes it easy to tell if a class is needed because a
      // subclass is needed.
      bool needed = false;
      if (!cls.isNative) {
        // Mixin applications (native+mixin) are non-native, so [classElement]
        // has already been emitted as a regular class.  Mark [classElement] as
        // 'needed' to ensure the native superclass is needed.
        needed = true;
      } else if (!isTrivialClass(cls)) {
        needed = true;
      } else if (interceptorClassesNeededByConstants.contains(classElement)) {
        needed = true;
      } else if (classesModifiedByEmitRTISupport.contains(classElement)) {
        // TODO(9556): Remove this test when [emitRuntimeTypeSupport] no longer
        // adds information to a class prototype or constructor.
        needed = true;
      } else if (extensionPoints.containsKey(cls)) {
        needed = true;
      }
      if (_nativeData.isJsInteropClass(classElement)) {
        needed = true; // TODO(jacobr): we don't need all interop classes.
      } else if (cls.isNative &&
          _nativeData.hasNativeTagsForcedNonLeaf(classElement)) {
        needed = true;
        nonLeafClasses.add(cls);
      }

      if (needed || neededClasses.contains(cls)) {
        neededClasses.add(cls);
        neededClasses.add(cls.superclass);
        nonLeafClasses.add(cls.superclass);
      }
    }

    // Collect all the tags that map to each native class.

    Map<Class, Set<String>> leafTags = new Map<Class, Set<String>>();
    Map<Class, Set<String>> nonleafTags = new Map<Class, Set<String>>();

    for (Class cls in classes) {
      if (!cls.isNative) continue;
      ClassEntity element = cls.element;
      if (_nativeData.isJsInteropClass(element)) continue;
      List<String> nativeTags = _nativeData.getNativeTagsOfClass(cls.element);

      if (nonLeafClasses.contains(cls) || extensionPoints.containsKey(cls)) {
        nonleafTags
            .putIfAbsent(cls, () => new Set<String>())
            .addAll(nativeTags);
      } else {
        Class sufficingInterceptor = cls;
        while (!neededClasses.contains(sufficingInterceptor)) {
          sufficingInterceptor = sufficingInterceptor.superclass;
        }
        if (sufficingInterceptor == objectClass) {
          sufficingInterceptor = jsInterceptorClass;
        }
        leafTags
            .putIfAbsent(sufficingInterceptor, () => new Set<String>())
            .addAll(nativeTags);
      }
    }

    void fillNativeInfo(Class cls) {
      assert(cls.nativeLeafTags == null &&
          cls.nativeNonLeafTags == null &&
          cls.nativeExtensions == null);
      if (leafTags[cls] != null) {
        cls.nativeLeafTags = leafTags[cls].toList(growable: false);
      }
      if (nonleafTags[cls] != null) {
        cls.nativeNonLeafTags = nonleafTags[cls].toList(growable: false);
      }
      cls.nativeExtensions = extensionPoints[cls];
    }

    // Add properties containing the information needed to construct maps used
    // by getNativeInterceptor and custom elements.
    if (_nativeCodegenEnqueuer.hasInstantiatedNativeClasses) {
      fillNativeInfo(jsInterceptorClass);
      for (Class cls in classes) {
        if (!cls.isNative || neededClasses.contains(cls)) {
          fillNativeInfo(cls);
        }
      }
    }

    // TODO(sra): Issue #13731- this is commented out as part of custom
    // element constructor work.
    // (floitsch: was run on every native class.)
    //assert(!classElement.hasBackendMembers);

    return classes
        .where((Class cls) => cls.isNative && !neededClasses.contains(cls))
        .toSet();
  }

  /**
   * Computes the native classes that are extended (subclassed) by non-native
   * classes and the set non-mative classes that extend them.  (A List is used
   * instead of a Set for out stability).
   */
  Map<Class, List<Class>> computeExtensionPoints(List<Class> classes) {
    Class nativeSuperclassOf(Class cls) {
      if (cls == null) return null;
      if (cls.isNative) return cls;
      return nativeSuperclassOf(cls.superclass);
    }

    Class nativeAncestorOf(Class cls) {
      return nativeSuperclassOf(cls.superclass);
    }

    Map<Class, List<Class>> map = new Map<Class, List<Class>>();

    for (Class cls in classes) {
      if (cls.isNative) continue;
      Class nativeAncestor = nativeAncestorOf(cls);
      if (nativeAncestor != null) {
        map.putIfAbsent(nativeAncestor, () => <Class>[]).add(cls);
      }
    }
    return map;
  }

  bool isTrivialClass(Class cls) {
    bool needsAccessor(Field field) {
      return field.needsGetter ||
          field.needsUncheckedSetter ||
          field.needsCheckedSetter;
    }

    return cls.methods.isEmpty &&
        cls.isChecks.isEmpty &&
        cls.callStubs.isEmpty &&
        !cls.superclass.isMixinApplication &&
        !cls.fields.any(needsAccessor);
  }

  void potentiallyConvertDartClosuresToJs(List<jsAst.Statement> statements,
      FunctionEntity member, List<jsAst.Parameter> stubParameters) {
    FunctionEntity converter = _commonElements.closureConverter;
    jsAst.Expression closureConverter =
        _emitterTask.staticFunctionAccess(converter);
    _worldBuilder.forEachParameter(member, (DartType type, String name) {
      // If [name] is not in [stubParameters], then the parameter is an optional
      // parameter that was not provided for this stub.
      for (jsAst.Parameter stubParameter in stubParameters) {
        if (stubParameter.name == name) {
          type = type.unaliased;
          if (type.isFunctionType) {
            // The parameter type is a function type either directly or through
            // typedef(s).
            FunctionType functionType = type;
            int arity = functionType.parameterTypes.length;
            statements.add(js
                .statement('# = #(#, $arity)', [name, closureConverter, name]));
            break;
          }
        }
      }
    });
  }

  List<jsAst.Statement> generateParameterStubStatements(
      FunctionEntity member,
      bool isInterceptedMethod,
      jsAst.Name invocationName,
      List<jsAst.Parameter> stubParameters,
      List<jsAst.Expression> argumentsBuffer,
      int indexOfLastOptionalArgumentInParameters) {
    // The target JS function may check arguments.length so we need to
    // make sure not to pass any unspecified optional arguments to it.
    // For example, for the following Dart method:
    //   foo({x, y, z});
    // The call:
    //   foo(y: 1)
    // must be turned into a JS call to:
    //   foo(null, y).

    List<jsAst.Statement> statements = <jsAst.Statement>[];
    potentiallyConvertDartClosuresToJs(statements, member, stubParameters);

    String target;
    jsAst.Expression receiver;
    List<jsAst.Expression> arguments;

    assert(nativeMethods.contains(member), failedAt(member));
    // When calling a JS method, we call it with the native name, and only the
    // arguments up until the last one provided.
    target = _nativeData.getFixedBackendName(member);

    if (isInterceptedMethod) {
      receiver = argumentsBuffer[0];
      arguments = argumentsBuffer.sublist(
          1, indexOfLastOptionalArgumentInParameters + 1);
    } else {
      // Native methods that are not intercepted must be static.
      assert(member.isStatic, failedAt(member));
      arguments = argumentsBuffer.sublist(
          0, indexOfLastOptionalArgumentInParameters + 1);
      if (_nativeData.isJsInteropMember(member)) {
        // fixedBackendPath is allowed to have the form foo.bar.baz for
        // interop. This template is uncached to avoid possibly running out of
        // memory when Dart2Js is run in server mode. In reality the risk of
        // caching these templates causing an issue  is very low as each class
        // and library that uses typed JavaScript interop will create only 1
        // unique template.
        receiver = js
            .uncachedExpressionTemplate(
                _nativeData.getFixedBackendMethodPath(member))
            .instantiate([]);
      } else {
        receiver = js('this');
      }
    }
    statements
        .add(js.statement('return #.#(#)', [receiver, target, arguments]));

    return statements;
  }

  bool isSupertypeOfNativeClass(ClassEntity element) {
    if (_interceptorData.isMixedIntoInterceptedClass(element)) {
      return true;
    }

    return subtypes[element] != null;
  }

  bool requiresNativeIsCheck(ClassEntity element) {
    // TODO(sra): Remove this function.  It determines if a native type may
    // satisfy a check against [element], in which case an interceptor must be
    // used.  We should also use an interceptor if the check can't be satisfied
    // by a native class in case we get a native instance that tries to spoof
    // the type info.  i.e the criteria for whether or not to use an interceptor
    // is whether the receiver can be native, not the type of the test.
    ClassEntity cls = element;
    if (_nativeData.isNativeOrExtendsNative(cls)) return true;
    return isSupertypeOfNativeClass(element);
  }
}
