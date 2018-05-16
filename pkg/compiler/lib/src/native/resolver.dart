// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../common_elements.dart' show CommonElements, ElementEnvironment;
import '../constants/values.dart';
import '../elements/entities.dart';
import '../js_backend/native_data.dart';
import 'behavior.dart';

/// Interface for computing native members.
abstract class NativeMemberResolver {
  /// Computes whether [element] is native or JsInterop.
  void resolveNativeMember(MemberEntity element);
}

abstract class NativeMemberResolverBase implements NativeMemberResolver {
  static final RegExp _identifier = new RegExp(r'^[a-zA-Z_$][a-zA-Z0-9_$]*$');

  ElementEnvironment get elementEnvironment;
  CommonElements get commonElements;
  NativeBasicData get nativeBasicData;
  NativeDataBuilder get nativeDataBuilder;

  bool isJsInteropMember(covariant MemberEntity element);
  bool isNativeMethod(covariant FunctionEntity element);

  NativeBehavior computeNativeMethodBehavior(covariant FunctionEntity function,
      {bool isJsInterop});
  NativeBehavior computeNativeFieldLoadBehavior(covariant FieldEntity field,
      {bool isJsInterop});
  NativeBehavior computeNativeFieldStoreBehavior(covariant FieldEntity field);

  @override
  void resolveNativeMember(MemberEntity element) {
    bool isJsInterop = isJsInteropMember(element);
    if (element.isFunction ||
        element.isConstructor ||
        element.isGetter ||
        element.isSetter) {
      FunctionEntity method = element;
      bool isNative = _processMethodAnnotations(method);
      if (isNative || isJsInterop) {
        NativeBehavior behavior =
            computeNativeMethodBehavior(method, isJsInterop: isJsInterop);
        nativeDataBuilder.setNativeMethodBehavior(method, behavior);
      }
    } else if (element.isField) {
      FieldEntity field = element;
      bool isNative = _processFieldAnnotations(field);
      if (isNative || isJsInterop) {
        NativeBehavior fieldLoadBehavior =
            computeNativeFieldLoadBehavior(field, isJsInterop: isJsInterop);
        NativeBehavior fieldStoreBehavior =
            computeNativeFieldStoreBehavior(field);
        nativeDataBuilder.setNativeFieldLoadBehavior(field, fieldLoadBehavior);
        nativeDataBuilder.setNativeFieldStoreBehavior(
            field, fieldStoreBehavior);
      }
    }
  }

  /// Process the potentially native [field]. Adds information from metadata
  /// attributes. Returns `true` of [method] is native.
  bool _processFieldAnnotations(covariant FieldEntity element) {
    if (element.isInstanceMember &&
        nativeBasicData.isNativeClass(element.enclosingClass)) {
      // Exclude non-instance (static) fields - they are not really native and
      // are compiled as isolate globals.  Access of a property of a constructor
      // function or a non-method property in the prototype chain, must be coded
      // using a JS-call.
      _setNativeName(element);
      return true;
    }
    return false;
  }

  /// Process the potentially native [method]. Adds information from metadata
  /// attributes. Returns `true` of [method] is native.
  bool _processMethodAnnotations(covariant FunctionEntity method) {
    if (isNativeMethod(method)) {
      if (method.isStatic) {
        _setNativeNameForStaticMethod(method);
      } else {
        _setNativeName(method);
      }
      return true;
    }
    return false;
  }

  /// Sets the native name of [element], either from an annotation, or
  /// defaulting to the Dart name.
  void _setNativeName(MemberEntity element) {
    String name = _findJsNameFromAnnotation(element);
    if (name == null) name = element.name;
    nativeDataBuilder.setNativeMemberName(element, name);
  }

  /// Sets the native name of the static native method [element], using the
  /// following rules:
  /// 1. If [element] has a @JSName annotation that is an identifier, qualify
  ///    that identifier to the @Native name of the enclosing class
  /// 2. If [element] has a @JSName annotation that is not an identifier,
  ///    use the declared @JSName as the expression
  /// 3. If [element] does not have a @JSName annotation, qualify the name of
  ///    the method with the @Native name of the enclosing class.
  void _setNativeNameForStaticMethod(FunctionEntity element) {
    String name = _findJsNameFromAnnotation(element);
    if (name == null) name = element.name;
    if (_isIdentifier(name)) {
      List<String> nativeNames =
          nativeBasicData.getNativeTagsOfClass(element.enclosingClass);
      if (nativeNames.length != 1) {
        failedAt(
            element,
            'Unable to determine a native name for the enclosing class, '
            'options: $nativeNames');
      }
      nativeDataBuilder.setNativeMemberName(element, '${nativeNames[0]}.$name');
    } else {
      nativeDataBuilder.setNativeMemberName(element, name);
    }
  }

  bool _isIdentifier(String s) => _identifier.hasMatch(s);

  /// Returns the JSName annotation string or `null` if no JSName annotation is
  /// present.
  String _findJsNameFromAnnotation(MemberEntity element) {
    String jsName = null;
    for (ConstantValue value in elementEnvironment.getMemberMetadata(element)) {
      String name = readAnnotationName(
          element, value, commonElements.annotationJSNameClass);
      if (jsName == null) {
        jsName = name;
      } else if (name != null) {
        failedAt(element, 'Too many JSName annotations: ${value.toDartText()}');
      }
    }
    return jsName;
  }
}

/// Determines all native classes in a set of libraries.
abstract class NativeClassFinder {
  /// Returns the set of all native classes declared in [libraries].
  Iterable<ClassEntity> computeNativeClasses(Iterable<LibraryEntity> libraries);
}

class BaseNativeClassFinder implements NativeClassFinder {
  final ElementEnvironment _elementEnvironment;
  final NativeBasicData _nativeBasicData;

  Map<String, ClassEntity> _tagOwner = new Map<String, ClassEntity>();

  BaseNativeClassFinder(this._elementEnvironment, this._nativeBasicData);

  Iterable<ClassEntity> computeNativeClasses(
      Iterable<LibraryEntity> libraries) {
    Set<ClassEntity> nativeClasses = new Set<ClassEntity>();
    libraries.forEach((l) => _processNativeClassesInLibrary(l, nativeClasses));
    _processSubclassesOfNativeClasses(libraries, nativeClasses);
    return nativeClasses;
  }

  /// Adds all directly native classes declared in [library] to [nativeClasses].
  void _processNativeClassesInLibrary(
      LibraryEntity library, Set<ClassEntity> nativeClasses) {
    _elementEnvironment.forEachClass(library, (ClassEntity cls) {
      if (_nativeBasicData.isNativeClass(cls)) {
        _processNativeClass(cls, nativeClasses);
      }
    });
  }

  /// Adds [cls] to [nativeClasses] and performs further processing of [cls],
  /// if necessary.
  void _processNativeClass(
      covariant ClassEntity cls, Set<ClassEntity> nativeClasses) {
    nativeClasses.add(cls);
    // Js Interop interfaces do not have tags.
    if (_nativeBasicData.isJsInteropClass(cls)) return;
    // Since we map from dispatch tags to classes, a dispatch tag must be used
    // on only one native class.
    for (String tag in _nativeBasicData.getNativeTagsOfClass(cls)) {
      ClassEntity owner = _tagOwner[tag];
      if (owner != null) {
        if (owner != cls) {
          failedAt(cls, "Tag '$tag' already in use by '${owner.name}'");
        }
      } else {
        _tagOwner[tag] = cls;
      }
    }
  }

  /// Returns the name of the super class of [cls] or `null` of [cls] has
  /// no explicit superclass.
  String _findExtendsNameOfClass(covariant ClassEntity cls) {
    return _elementEnvironment
        .getSuperClass(cls, skipUnnamedMixinApplications: true)
        ?.name;
  }

  /// Adds all subclasses of [nativeClasses] found in [libraries] to
  /// [nativeClasses].
  void _processSubclassesOfNativeClasses(
      Iterable<LibraryEntity> libraries, Set<ClassEntity> nativeClasses) {
    Set<ClassEntity> nativeClassesAndSubclasses = new Set<ClassEntity>();
    // Collect potential subclasses, e.g.
    //
    //     class B extends foo.A {}
    //
    // String "A" has a potential subclass B.

    Map<String, Set<ClassEntity>> potentialExtends =
        <String, Set<ClassEntity>>{};

    libraries.forEach((LibraryEntity library) {
      _elementEnvironment.forEachClass(library, (ClassEntity cls) {
        String extendsName = _findExtendsNameOfClass(cls);
        if (extendsName != null) {
          Set<ClassEntity> potentialSubclasses = potentialExtends.putIfAbsent(
              extendsName, () => new Set<ClassEntity>());
          potentialSubclasses.add(cls);
        }
      });
    });

    // Resolve all the native classes and any classes that might extend them in
    // [potentialExtends], and then check that the properly resolved class is in
    // fact a subclass of a native class.

    ClassEntity nativeSuperclassOf(ClassEntity cls) {
      if (_nativeBasicData.isNativeClass(cls)) return cls;
      ClassEntity superclass = _elementEnvironment.getSuperClass(cls);
      if (superclass == null) return null;
      return nativeSuperclassOf(superclass);
    }

    void walkPotentialSubclasses(ClassEntity element) {
      if (nativeClassesAndSubclasses.contains(element)) return;
      ClassEntity nativeSuperclass = nativeSuperclassOf(element);
      if (nativeSuperclass != null) {
        nativeClassesAndSubclasses.add(element);
        Set<ClassEntity> potentialSubclasses = potentialExtends[element.name];
        if (potentialSubclasses != null) {
          potentialSubclasses.forEach(walkPotentialSubclasses);
        }
      }
    }

    nativeClasses.forEach(walkPotentialSubclasses);
    nativeClasses.addAll(nativeClassesAndSubclasses);
  }
}

/// Returns `true` if [value] is named annotation based on [annotationClass].
bool isAnnotation(
    Spannable spannable, ConstantValue value, ClassEntity annotationClass) {
  if (!value.isConstructedObject) return null;
  ConstructedConstantValue constructedObject = value;
  return constructedObject.type.element == annotationClass;
}

/// Extracts the name if [value] is a named annotation based on
/// [annotationClass], otherwise returns `null`.
String readAnnotationName(
    Spannable spannable, ConstantValue value, ClassEntity annotationClass,
    {String defaultValue}) {
  if (!value.isConstructedObject) return null;
  ConstructedConstantValue constructedObject = value;
  if (constructedObject.type.element != annotationClass) return null;

  Iterable<ConstantValue> fields = constructedObject.fields.values;
  // TODO(sra): Better validation of the constant.
  if (fields.length != 1) {
    failedAt(
        spannable, 'Annotations needs one string: ${value.toStructuredText()}');
    return null;
  } else if (fields.single is StringConstantValue) {
    StringConstantValue specStringConstant = fields.single;
    return specStringConstant.stringValue;
  } else if (defaultValue != null && fields.single is NullConstantValue) {
    return defaultValue;
  } else {
    failedAt(
        spannable, 'Annotations needs one string: ${value.toStructuredText()}');
    return null;
  }
}
