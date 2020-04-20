// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../common_elements.dart' show KElementEnvironment;
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../ir/annotations.dart';
import '../js_backend/native_data.dart';

/// Interface for computing native members.
abstract class NativeMemberResolver {
  /// Computes whether [node] is native or JsInterop.
  void resolveNativeMember(ir.Member node, IrAnnotationData annotationData);
}

/// Determines all native classes in a set of libraries.
abstract class NativeClassFinder {
  /// Returns the set of all native classes declared in [libraries].
  Iterable<ClassEntity> computeNativeClasses(Iterable<Uri> libraries);
}

class BaseNativeClassFinder implements NativeClassFinder {
  final KElementEnvironment _elementEnvironment;
  final NativeBasicData _nativeBasicData;

  Map<String, ClassEntity> _tagOwner = new Map<String, ClassEntity>();

  BaseNativeClassFinder(this._elementEnvironment, this._nativeBasicData);

  @override
  Iterable<ClassEntity> computeNativeClasses(Iterable<Uri> libraries) {
    Set<ClassEntity> nativeClasses = new Set<ClassEntity>();
    libraries.forEach((uri) => _processNativeClassesInLibrary(
        _elementEnvironment.lookupLibrary(uri), nativeClasses));
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
      Iterable<Uri> libraries, Set<ClassEntity> nativeClasses) {
    Set<ClassEntity> nativeClassesAndSubclasses = new Set<ClassEntity>();
    // Collect potential subclasses, e.g.
    //
    //     class B extends foo.A {}
    //
    // String "A" has a potential subclass B.

    Map<String, Set<ClassEntity>> potentialExtends =
        <String, Set<ClassEntity>>{};

    libraries.forEach((Uri uri) {
      LibraryEntity library = _elementEnvironment.lookupLibrary(uri);
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
String readAnnotationName(DartTypes dartTypes, Spannable spannable,
    ConstantValue value, ClassEntity annotationClass,
    {String defaultValue}) {
  if (!value.isConstructedObject) return null;
  ConstructedConstantValue constructedObject = value;
  if (constructedObject.type.element != annotationClass) return null;

  Iterable<ConstantValue> fields = constructedObject.fields.values;
  // TODO(sra): Better validation of the constant.
  if (fields.length != 1) {
    failedAt(spannable,
        'Annotations needs one string: ${value.toStructuredText(dartTypes)}');
    return null;
  } else if (fields.single is StringConstantValue) {
    StringConstantValue specStringConstant = fields.single;
    return specStringConstant.stringValue;
  } else if (defaultValue != null && fields.single is NullConstantValue) {
    return defaultValue;
  } else {
    failedAt(spannable,
        'Annotations needs one string: ${value.toStructuredText(dartTypes)}');
    return null;
  }
}
