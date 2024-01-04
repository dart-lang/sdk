// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.native_emitter;

import '../common/elements.dart' show JCommonElements;
import '../elements/entities.dart';
import '../js_backend/native_data.dart';
import '../js_model/js_world.dart' show JClosedWorld;
import '../native/enqueue.dart' show NativeCodegenEnqueuer;

import 'model.dart';

class NativeEmitter {
  final JClosedWorld _closedWorld;
  final NativeCodegenEnqueuer _nativeCodegenEnqueuer;

  // Whether the application contains native classes.
  bool hasNativeClasses = false;

  // Caches the native subtypes of a native class.
  Map<ClassEntity, List<ClassEntity>> subtypes = {};

  // Caches the direct native subtypes of a native class.
  Map<ClassEntity, List<ClassEntity>> directSubtypes = {};

  // Caches the methods that have a native body.
  Set<FunctionEntity> nativeMethods = {};

  // Type metadata redirections, where the key is the class type data being
  // redirected to and the value is the list of class type data being
  // redirected.
  final Map<ClassTypeData, List<ClassTypeData>> typeRedirections = {};

  NativeEmitter(this._closedWorld, this._nativeCodegenEnqueuer);

  JCommonElements get _commonElements => _closedWorld.commonElements;
  NativeData get _nativeData => _closedWorld.nativeData;

  /// Prepares native classes for emission. Returns the unneeded classes.
  ///
  /// Removes trivial classes (that can be represented by a super type) and
  /// generates properties that have to be added to classes (native or not).
  ///
  /// Updates the `nativeLeafTags`, `nativeNonLeafTags` and `nativeExtensions`
  /// fields of the given classes. This data must be emitted with the
  /// corresponding classes.
  ///
  /// The interceptors are filtered to avoid emitting trivial interceptors.  For
  /// example, if the program contains no code that can distinguish between the
  /// numerous subclasses of `Element` then we can pretend that `Element` is a
  /// leaf class, and all instances of subclasses of `Element` are instances of
  /// `Element`.
  ///
  /// There is also a performance benefit (in addition to the obvious code size
  /// benefit), due to how [getNativeInterceptor] works.  Finding the
  /// interceptor of a leaf class in the hierarchy is more efficient that a
  /// non-leaf, so it improves performance when more classes can be treated as
  /// leaves.
  ///
  /// [classes] contains native classes, mixin applications, and user subclasses
  /// of native classes.
  ///
  /// [interceptorClassesNeededByConstants] contains the interceptors that are
  /// referenced by constants.
  ///
  /// [classesModifiedByEmitRTISupport] contains the list of classes that must
  /// exist, because runtime-type support adds information to the class.
  Set<Class> prepareNativeClasses(
      List<Class> classes,
      Set<ClassEntity> interceptorClassesNeededByConstants,
      Iterable<ClassEntity> classesNeededForRti) {
    hasNativeClasses = classes.isNotEmpty;

    // Compute a pre-order traversal of the subclass forest.  We actually want a
    // post-order traversal but it is easier to compute the pre-order and use it
    // in reverse.
    List<Class> preOrder = [];
    Set<Class> seen = {};

    Class? objectClass;
    Class? jsInterceptorClass;
    Class? jsJavaScriptObjectClass;

    void walk(Class cls) {
      if (cls.element == _commonElements.objectClass) {
        objectClass = cls;
        return;
      }
      if (cls.element == _commonElements.jsInterceptorClass) {
        jsInterceptorClass = cls;
        return;
      }
      // Native classes may inherit either `Interceptor` e.g. `JSBool` or
      // `JavaScriptObject` e.g. `dart:html` classes.
      if (cls.element == _commonElements.jsJavaScriptObjectClass) {
        jsJavaScriptObjectClass = cls;
      }
      if (seen.contains(cls)) return;
      seen.add(cls);
      // Note: only the superclass of `Object` is expected to be null, but that
      // would already be handled in line 102.
      walk(cls.superclass!);
      preOrder.add(cls);
    }

    classes.forEach(walk);

    // Find which classes are needed and which are non-leaf classes.  Any class
    // that is not needed can be treated as a leaf class equivalent to some
    // needed class.
    // We may still need to include type metadata for some unneeded classes.

    Set<Class> neededClasses = {};
    Set<Class> nonLeafClasses = {};

    Map<Class, List<Class>> extensionPoints = computeExtensionPoints(preOrder);

    if (objectClass != null) neededClasses.add(objectClass!);

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
      } else if (classesNeededForRti.contains(classElement)) {
        needed = true;
      } else if (extensionPoints.containsKey(cls)) {
        needed = true;
      }
      if (_nativeData.isJsInteropClass(classElement)) {
        // @staticInterop classes don't need to be emitted as they're purely
        // static classes whose runtime type is an Interceptor type.
        if (!_nativeData.isStaticInteropClass(classElement)) {
          needed = true; // TODO(jacobr): we don't need all interop classes.
        }
      } else if (cls.isNative &&
          _nativeData.hasNativeTagsForcedNonLeaf(classElement)) {
        needed = true;
        nonLeafClasses.add(cls);
      }

      if (needed || neededClasses.contains(cls)) {
        neededClasses.add(cls);
        neededClasses.add(cls.superclass!);
        nonLeafClasses.add(cls.superclass!);
      } else if (!cls.typeData.isTriviallyChecked(_commonElements) ||
          cls.typeData.namedTypeVariables.isNotEmpty) {
        // The class is not marked 'needed', but we still need it in the type
        // metadata.

        // Redirect this class type data (and all class type data which would
        // have redirected to this class type data) to its superclass. Because
        // we have a post-order visit, this eventually causes all such native
        // classes to redirect to their leaf interceptors.
        List<ClassTypeData> redirectedClasses =
            typeRedirections[cls.typeData] ?? [];
        redirectedClasses.add(cls.typeData);
        typeRedirections[cls.superclass!.typeData] = redirectedClasses;
        typeRedirections.remove(cls.typeData);
      }
    }

    // Collect all the tags that map to each native class.

    Map<Class, Set<String>> leafTags = {};
    Map<Class, Set<String>> nonleafTags = {};

    for (Class cls in classes) {
      if (!cls.isNative) continue;
      ClassEntity element = cls.element;
      if (_nativeData.isJsInteropClass(element)) continue;
      List<String> nativeTags = _nativeData.getNativeTagsOfClass(cls.element);

      if (nonLeafClasses.contains(cls) || extensionPoints.containsKey(cls)) {
        nonleafTags.putIfAbsent(cls, () => {}).addAll(nativeTags);
      } else {
        Class? sufficingInterceptor = cls;
        while (sufficingInterceptor != null &&
            !neededClasses.contains(sufficingInterceptor)) {
          sufficingInterceptor = sufficingInterceptor.superclass;
        }
        if (sufficingInterceptor == null ||
            sufficingInterceptor == objectClass) {
          sufficingInterceptor = jsInterceptorClass!;
        }
        leafTags.putIfAbsent(sufficingInterceptor, () => {}).addAll(nativeTags);
      }
    }

    void fillNativeInfo(Class cls) {
      assert(cls.nativeLeafTags == null &&
          cls.nativeNonLeafTags == null &&
          cls.nativeExtensions == null);
      if (leafTags[cls] != null) {
        cls.nativeLeafTags = leafTags[cls]!.toList(growable: false);
      }
      if (nonleafTags[cls] != null) {
        cls.nativeNonLeafTags = nonleafTags[cls]!.toList(growable: false);
      }
      cls.nativeExtensions = extensionPoints[cls];
    }

    // Add properties containing the information needed to construct maps used
    // by getNativeInterceptor and custom elements.
    if (_nativeCodegenEnqueuer.hasInstantiatedNativeClasses) {
      fillNativeInfo(jsInterceptorClass!);
      if (jsJavaScriptObjectClass != null) {
        fillNativeInfo(jsJavaScriptObjectClass!);
      }
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

  /// Computes the native classes that are extended (subclassed) by non-native
  /// classes and the set non-mative classes that extend them.  (A List is used
  /// instead of a Set for out stability).
  Map<Class, List<Class>> computeExtensionPoints(List<Class> classes) {
    Class? nativeSuperclassOf(Class? cls) {
      if (cls == null) return null;
      if (cls.isNative) return cls;
      return nativeSuperclassOf(cls.superclass);
    }

    Class? nativeAncestorOf(Class cls) {
      return nativeSuperclassOf(cls.superclass);
    }

    Map<Class, List<Class>> map = {};

    for (Class cls in classes) {
      if (cls.isNative) continue;
      Class? nativeAncestor = nativeAncestorOf(cls);
      if (nativeAncestor != null) {
        map.putIfAbsent(nativeAncestor, () => []).add(cls);
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
        !cls.superclass!.isSimpleMixinApplication &&
        !cls.fields.any(needsAccessor);
  }
}
