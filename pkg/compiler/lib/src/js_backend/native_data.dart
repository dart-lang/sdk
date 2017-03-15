// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.native_data;

import '../common.dart';
import '../elements/elements.dart'
    show
        ClassElement,
        Element,
        FieldElement,
        FunctionElement,
        LibraryElement,
        MemberElement,
        MethodElement;
import '../elements/entities.dart';
import '../native/behavior.dart' show NativeBehavior;

/// Basic information for native classes and methods and js-interop
/// classes.
///
/// This information is computed during loading using [NativeClassDataBuilder].
abstract class NativeClassData {
  /// Returns `true` if [cls] corresponds to a native JavaScript class.
  ///
  /// A class is marked as native either through the `@Native(...)` annotation
  /// allowed for internal libraries or via the typed JavaScriptInterop
  /// mechanism allowed for user libraries.
  bool isNativeClass(ClassEntity element);

  /// Returns `true` if [element] or any of its superclasses is native.
  bool isNativeOrExtendsNative(ClassElement element);

  /// Returns `true` if [element] is a JsInterop library.
  bool isJsInteropLibrary(LibraryElement element);

  /// Returns `true` if [element] is a JsInterop class.
  bool isJsInteropClass(ClassElement element);
}

/// Additional element information for native classes and methods and js-interop
/// methods.
///
/// This information is computed during resolution using [NativeDataBuilder].
abstract class NativeData extends NativeClassData {
  /// Returns `true` if [element] corresponds to a native JavaScript member.
  ///
  /// A member is marked as native either through the native mechanism
  /// (`@Native(...)` or the `native` pseudo keyword) allowed for internal
  /// libraries or via the typed JavaScriptInterop mechanism allowed for user
  /// libraries.
  bool isNativeMember(MemberEntity element);

  /// Returns the [NativeBehavior] for calling the native [method].
  NativeBehavior getNativeMethodBehavior(MethodElement method);

  /// Returns the [NativeBehavior] for reading from the native [field].
  NativeBehavior getNativeFieldLoadBehavior(FieldElement field);

  /// Returns the [NativeBehavior] for writing to the native [field].
  NativeBehavior getNativeFieldStoreBehavior(FieldElement field);

  /// Returns `true` if the name of [element] is fixed for the generated
  /// JavaScript.
  bool hasFixedBackendName(Element element);

  /// Computes the name for [element] to use in the generated JavaScript. This
  /// is either given through a native annotation or a js interop annotation.
  String getFixedBackendName(Entity entity);

  /// Returns the list of non-directive native tag words for [cls].
  List<String> getNativeTagsOfClass(ClassElement cls);

  /// Returns `true` if [cls] has a `!nonleaf` tag word.
  bool hasNativeTagsForcedNonLeaf(ClassElement cls);

  /// Returns `true` if [element] is part of JsInterop.
  ///
  /// Deprecated: Use [isJsInteropLibrary], [isJsInteropClass] or
  /// [isJsInteropMember] instead.
  @deprecated
  bool isJsInterop(Element element);

  /// Returns `true` if [element] is a JsInterop method.
  bool isJsInteropMember(MethodElement element);

  /// Returns the explicit js interop name for [element].
  String getJsInteropName(Element element);

  /// Apply JS$ escaping scheme to convert possible escaped Dart names into
  /// JS names.
  String getUnescapedJSInteropName(String name);
}

abstract class NativeClassDataBuilder {
  /// Sets the native tag info for [cls].
  ///
  /// The tag info string contains comma-separated 'words' which are either
  /// dispatch tags (having JavaScript identifier syntax) and directives that
  /// begin with `!`.
  void setNativeClassTagInfo(ClassElement cls, String tagInfo);

  /// Marks [element] as an explicit part of JsInterop. The js interop name is
  /// expected to be computed later.
  void markAsJsInteropLibrary(LibraryElement element);

  /// Marks [element] as an explicit part of JsInterop. The js interop name is
  /// expected to be computed later.
  void markAsJsInteropClass(ClassElement element);
}

abstract class NativeDataBuilder {
  /// Registers the [behavior] for calling the native [method].
  void setNativeMethodBehavior(MethodElement method, NativeBehavior behavior);

  /// Registers the [behavior] for reading from the native [field].
  void setNativeFieldLoadBehavior(FieldElement field, NativeBehavior behavior);

  /// Registers the [behavior] for writing to the native [field].
  void setNativeFieldStoreBehavior(FieldElement field, NativeBehavior behavior);

  /// Returns the list of native tag words for [cls].
  List<String> getNativeTagsOfClassRaw(ClassElement cls);

  /// Returns [element] as an explicit part of JsInterop. The js interop name is
  /// expected to be computed later.
  void markAsJsInteropMember(MemberElement element);

  /// Sets the native [name] for the member [element]. This name is used for
  /// [element] in the generated JavaScript.
  void setNativeMemberName(MemberElement element, String name);

  /// Sets the explicit js interop [name] for [element].
  void setJsInteropName(Element element, String name);
}

class NativeDataImpl
    implements NativeData, NativeDataBuilder, NativeClassDataBuilder {
  /// The JavaScript names for elements implemented via typed JavaScript
  /// interop.
  Map<Element, String> jsInteropNames = <Element, String>{};

  /// The JavaScript names for native JavaScript elements implemented.
  Map<Element, String> nativeMemberName = <Element, String>{};

  /// Tag info for native JavaScript classes names. See
  /// [setNativeClassTagInfo].
  Map<ClassElement, String> nativeClassTagInfo = <ClassElement, String>{};

  /// Cache for [NativeBehavior]s for calling native methods.
  Map<MethodElement, NativeBehavior> nativeMethodBehavior =
      <MethodElement, NativeBehavior>{};

  /// Cache for [NativeBehavior]s for reading from native fields.
  Map<MemberElement, NativeBehavior> nativeFieldLoadBehavior =
      <FieldElement, NativeBehavior>{};

  /// Cache for [NativeBehavior]s for writing to native fields.
  Map<MemberElement, NativeBehavior> nativeFieldStoreBehavior =
      <FieldElement, NativeBehavior>{};

  /// Prefix used to escape JS names that are not valid Dart names
  /// when using JSInterop.
  static const String _jsInteropEscapePrefix = r'JS$';

  /// Returns `true` if [element] is explicitly marked as part of JsInterop.
  bool _isJsInterop(Element element) {
    return jsInteropNames.containsKey(element.declaration);
  }

  /// Marks [element] as an explicit part of JsInterop. The js interop name is
  /// expected to be computed later.
  void markAsJsInterop(Element element) {
    jsInteropNames[element.declaration] = null;
  }

  @override
  void markAsJsInteropLibrary(LibraryElement element) {
    markAsJsInterop(element);
  }

  @override
  void markAsJsInteropClass(ClassElement element) {
    markAsJsInterop(element);
  }

  @override
  void markAsJsInteropMember(MemberElement element) {
    markAsJsInterop(element);
  }

  /// Sets the explicit js interop [name] for [element].
  void setJsInteropName(Element element, String name) {
    assert(invariant(element, isJsInterop(element),
        message:
            'Element $element is not js interop but given a js interop name.'));
    jsInteropNames[element.declaration] = name;
  }

  /// Returns the explicit js interop name for [element].
  String getJsInteropName(Element element) {
    return jsInteropNames[element.declaration];
  }

  /// Returns `true` if [element] is part of JsInterop.
  bool isJsInterop(Element element) {
    // An function is part of JsInterop in the following cases:
    // * It has a jsInteropName annotation
    // * It is external member of a class or library tagged as JsInterop.
    if (element.isFunction || element.isConstructor || element.isAccessor) {
      FunctionElement function = element;
      if (!function.isExternal) return false;

      if (_isJsInterop(function)) return true;
      if (function.isClassMember) return isJsInterop(function.contextClass);
      if (function.isTopLevel) return isJsInterop(function.library);
      return false;
    } else {
      return _isJsInterop(element);
    }
  }

  /// Returns `true` if [element] is a JsInterop library.
  bool isJsInteropLibrary(LibraryElement element) => isJsInterop(element);

  /// Returns `true` if [element] is a JsInterop class.
  bool isJsInteropClass(ClassElement element) => isJsInterop(element);

  /// Returns `true` if [element] is a JsInterop method.
  bool isJsInteropMember(MethodElement element) => isJsInterop(element);

  /// Returns `true` if the name of [element] is fixed for the generated
  /// JavaScript.
  bool hasFixedBackendName(Element element) {
    return isJsInterop(element) ||
        nativeMemberName.containsKey(element.declaration);
  }

  String _jsNameHelper(Element element) {
    String jsInteropName = jsInteropNames[element.declaration];
    assert(invariant(element, !(_isJsInterop(element) && jsInteropName == null),
        message:
            'Element $element is js interop but js interop name has not yet '
            'been computed.'));
    if (jsInteropName != null && jsInteropName.isNotEmpty) {
      return jsInteropName;
    }
    return element.isLibrary ? 'self' : getUnescapedJSInteropName(element.name);
  }

  /// Computes the name for [element] to use in the generated JavaScript. This
  /// is either given through a native annotation or a js interop annotation.
  String getFixedBackendName(Entity entity) {
    // TODO(johnniwinther): Remove this assignment from [Entity] to [Element]
    // when `.declaration` is no longer needed.
    Element element = entity;
    String name = nativeMemberName[element.declaration];
    if (name == null && isJsInterop(element)) {
      // If an element isJsInterop but _isJsInterop is false that means it is
      // considered interop as the parent class is interop.
      name = _jsNameHelper(
          element.isConstructor ? element.enclosingClass : element);
      nativeMemberName[element.declaration] = name;
    }
    return name;
  }

  /// Whether [element] corresponds to a native JavaScript construct either
  /// through the native mechanism (`@Native(...)` or the `native` pseudo
  /// keyword) which is only allowed for internal libraries or via the typed
  /// JavaScriptInterop mechanism which is allowed for user libraries.
  bool isNative(Element element) {
    if (isJsInterop(element)) return true;
    if (element.isClass) {
      return nativeClassTagInfo.containsKey(element.declaration);
    } else {
      return nativeMemberName.containsKey(element.declaration);
    }
  }

  /// Returns `true` if [cls] is a native class.
  bool isNativeClass(ClassElement element) => isNative(element);

  /// Returns `true` if [element] is a native member of a native class.
  bool isNativeMember(MemberElement element) => isNative(element);

  /// Returns `true` if [element] or any of its superclasses is native.
  bool isNativeOrExtendsNative(ClassElement element) {
    if (element == null) return false;
    if (isNativeClass(element) || isJsInteropClass(element)) {
      return true;
    }
    assert(element.isResolved);
    return isNativeOrExtendsNative(element.superclass);
  }

  /// Sets the native [name] for the member [element]. This name is used for
  /// [element] in the generated JavaScript.
  void setNativeMemberName(MemberElement element, String name) {
    // TODO(johnniwinther): Avoid setting this more than once. The enqueuer
    // might enqueue [element] several times (before processing it) and computes
    // name on each call to `internalAddToWorkList`.
    assert(invariant(
        element,
        nativeMemberName[element.declaration] == null ||
            nativeMemberName[element.declaration] == name,
        message: "Native member name set inconsistently on $element: "
            "Existing name '${nativeMemberName[element.declaration]}', "
            "new name '$name'."));
    nativeMemberName[element.declaration] = name;
  }

  /// Sets the native tag info for [cls].
  ///
  /// The tag info string contains comma-separated 'words' which are either
  /// dispatch tags (having JavaScript identifier syntax) and directives that
  /// begin with `!`.
  void setNativeClassTagInfo(ClassElement cls, String tagInfo) {
    // TODO(johnniwinther): Assert that this is only called once. The memory
    // compiler copies pre-processed elements into a new compiler through
    // [Compiler.onLibraryScanned] and thereby causes multiple calls to this
    // method.
    assert(invariant(
        cls,
        nativeClassTagInfo[cls.declaration] == null ||
            nativeClassTagInfo[cls.declaration] == tagInfo,
        message: "Native tag info set inconsistently on $cls: "
            "Existing tag info '${nativeClassTagInfo[cls.declaration]}', "
            "new tag info '$tagInfo'."));
    nativeClassTagInfo[cls.declaration] = tagInfo;
  }

  /// Returns the list of native tag words for [cls].
  List<String> getNativeTagsOfClassRaw(ClassElement cls) {
    String quotedName = nativeClassTagInfo[cls.declaration];
    return quotedName.substring(1, quotedName.length - 1).split(',');
  }

  /// Returns the list of non-directive native tag words for [cls].
  List<String> getNativeTagsOfClass(ClassElement cls) {
    return getNativeTagsOfClassRaw(cls)
        .where((s) => !s.startsWith('!'))
        .toList();
  }

  /// Returns `true` if [cls] has a `!nonleaf` tag word.
  bool hasNativeTagsForcedNonLeaf(ClassElement cls) {
    return getNativeTagsOfClassRaw(cls).contains('!nonleaf');
  }

  /// Returns the [NativeBehavior] for calling the native [method].
  NativeBehavior getNativeMethodBehavior(MethodElement method) {
    assert(invariant(method, nativeMethodBehavior.containsKey(method),
        message: "No native method behavior has been computed for $method."));
    return nativeMethodBehavior[method];
  }

  /// Returns the [NativeBehavior] for reading from the native [field].
  NativeBehavior getNativeFieldLoadBehavior(FieldElement field) {
    assert(invariant(field, nativeFieldLoadBehavior.containsKey(field),
        message: "No native field load behavior has been "
            "computed for $field."));
    return nativeFieldLoadBehavior[field];
  }

  /// Returns the [NativeBehavior] for writing to the native [field].
  NativeBehavior getNativeFieldStoreBehavior(FieldElement field) {
    assert(invariant(field, nativeFieldStoreBehavior.containsKey(field),
        message: "No native field store behavior has been "
            "computed for $field."));
    return nativeFieldStoreBehavior[field];
  }

  /// Registers the [behavior] for calling the native [method].
  void setNativeMethodBehavior(MethodElement method, NativeBehavior behavior) {
    nativeMethodBehavior[method] = behavior;
  }

  /// Registers the [behavior] for reading from the native [field].
  void setNativeFieldLoadBehavior(FieldElement field, NativeBehavior behavior) {
    nativeFieldLoadBehavior[field] = behavior;
  }

  /// Registers the [behavior] for writing to the native [field].
  void setNativeFieldStoreBehavior(
      FieldElement field, NativeBehavior behavior) {
    nativeFieldStoreBehavior[field] = behavior;
  }

  /// Apply JS$ escaping scheme to convert possible escaped Dart names into
  /// JS names.
  String getUnescapedJSInteropName(String name) {
    return name.startsWith(_jsInteropEscapePrefix)
        ? name.substring(_jsInteropEscapePrefix.length)
        : name;
  }
}
