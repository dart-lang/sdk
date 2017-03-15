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
  bool hasFixedBackendName(MemberElement element);

  /// Computes the name for [element] to use in the generated JavaScript. This
  /// is either given through a native annotation or a js interop annotation.
  String getFixedBackendName(MemberEntity element);

  /// Computes the name prefix for [element] to use in the generated JavaScript.
  ///
  /// For static and top-level members and constructors this is based on the
  /// JavaScript names for the library and/or the enclosing class.
  String getFixedBackendMethodPath(MethodElement element);

  /// Returns the list of non-directive native tag words for [cls].
  List<String> getNativeTagsOfClass(ClassElement cls);

  /// Returns `true` if [cls] has a `!nonleaf` tag word.
  bool hasNativeTagsForcedNonLeaf(ClassElement cls);

  /// Returns `true` if [element] is a JsInterop method.
  bool isJsInteropMember(MemberEntity element);

  /// Returns the explicit js interop name for library [element].
  String getJsInteropLibraryName(LibraryElement element);

  /// Returns the explicit js interop name for class [element].
  String getJsInteropClassName(ClassElement element);

  /// Returns the explicit js interop name for member [element].
  String getJsInteropMemberName(MemberElement element);

  /// Apply JS$ escaping scheme to convert possible escaped Dart names into
  /// JS names.
  String computeUnescapedJSInteropName(String name);
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

  /// Sets the explicit js interop [name] for the library [element].
  void setJsInteropLibraryName(LibraryElement element, String name);

  /// Sets the explicit js interop [name] for the class [element].
  void setJsInteropClassName(ClassElement element, String name);

  /// Sets the explicit js interop [name] for the member [element].
  void setJsInteropMemberName(MemberElement element, String name);
}

class NativeDataImpl
    implements NativeData, NativeDataBuilder, NativeClassDataBuilder {
  /// The JavaScript names for elements implemented via typed JavaScript
  /// interop.
  Map<LibraryElement, String> jsInteropLibraryNames =
      <LibraryElement, String>{};
  Map<ClassElement, String> jsInteropClassNames = <ClassElement, String>{};
  Map<MemberElement, String> jsInteropMemberNames = <MemberElement, String>{};

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
  bool _isJsInteropLibrary(LibraryElement element) {
    return jsInteropLibraryNames.containsKey(element);
  }

  /// Returns `true` if [element] is explicitly marked as part of JsInterop.
  bool _isJsInteropClass(ClassElement element) {
    return jsInteropClassNames.containsKey(element);
  }

  /// Returns `true` if [element] is explicitly marked as part of JsInterop.
  bool _isJsInteropMember(MemberElement element) {
    return jsInteropMemberNames.containsKey(element);
  }

  @override
  void markAsJsInteropLibrary(LibraryElement element) {
    jsInteropLibraryNames[element] = null;
  }

  @override
  void markAsJsInteropClass(ClassElement element) {
    jsInteropClassNames[element] = null;
  }

  @override
  void markAsJsInteropMember(MemberElement element) {
    jsInteropMemberNames[element] = null;
  }

  /// Sets the explicit js interop [name] for the library [element].
  void setJsInteropLibraryName(LibraryElement element, String name) {
    assert(invariant(element, _isJsInteropLibrary(element),
        message:
            'Library $element is not js interop but given a js interop name.'));
    jsInteropLibraryNames[element] = name;
  }

  /// Sets the explicit js interop [name] for the class [element].
  void setJsInteropClassName(ClassElement element, String name) {
    assert(invariant(element, _isJsInteropClass(element),
        message:
            'Class $element is not js interop but given a js interop name.'));
    jsInteropClassNames[element] = name;
  }

  /// Sets the explicit js interop [name] for the member [element].
  void setJsInteropMemberName(MemberElement element, String name) {
    assert(invariant(element, _isJsInteropMember(element),
        message:
            'Member $element is not js interop but given a js interop name.'));
    jsInteropMemberNames[element] = name;
  }

  /// Returns the explicit js interop name for library [element].
  String getJsInteropLibraryName(LibraryElement element) {
    return jsInteropLibraryNames[element];
  }

  /// Returns the explicit js interop name for class [element].
  String getJsInteropClassName(ClassElement element) {
    return jsInteropClassNames[element];
  }

  /// Returns the explicit js interop name for member [element].
  String getJsInteropMemberName(MemberElement element) {
    return jsInteropMemberNames[element];
  }

  /// Returns `true` if [element] is a JsInterop library.
  bool isJsInteropLibrary(LibraryElement element) =>
      _isJsInteropLibrary(element);

  /// Returns `true` if [element] is a JsInterop class.
  bool isJsInteropClass(ClassElement element) => _isJsInteropClass(element);

  /// Returns `true` if [element] is a JsInterop method.
  bool isJsInteropMember(MemberElement element) {
    if (element.isFunction || element.isConstructor || element.isAccessor) {
      MethodElement function = element;
      if (!function.isExternal) return false;

      if (_isJsInteropMember(function)) return true;
      if (function.isClassMember) {
        return _isJsInteropClass(function.enclosingClass);
      }
      if (function.isTopLevel) {
        return _isJsInteropLibrary(function.library);
      }
      return false;
    } else {
      return _isJsInteropMember(element);
    }
  }

  /// Returns `true` if the name of [element] is fixed for the generated
  /// JavaScript.
  bool hasFixedBackendName(MemberElement element) {
    return isJsInteropMember(element) ||
        nativeMemberName.containsKey(element.declaration);
  }

  /// Computes the name for [element] to use in the generated JavaScript. This
  /// is either given through a native annotation or a js interop annotation.
  String getFixedBackendName(MemberElement element) {
    String name = nativeMemberName[element.declaration];
    if (name == null && isJsInteropMember(element)) {
      // If an element isJsInterop but _isJsInterop is false that means it is
      // considered interop as the parent class is interop.
      name = element.isConstructor
          ? _jsClassNameHelper(element.enclosingClass)
          : _jsMemberNameHelper(element);
      nativeMemberName[element.declaration] = name;
    }
    return name;
  }

  String _jsLibraryNameHelper(LibraryElement element) {
    String jsInteropName = getJsInteropLibraryName(element);
    if (jsInteropName != null && jsInteropName.isNotEmpty) return jsInteropName;
    return 'self';
  }

  String _jsClassNameHelper(ClassElement element) {
    String jsInteropName = getJsInteropClassName(element);
    if (jsInteropName != null && jsInteropName.isNotEmpty) return jsInteropName;
    return computeUnescapedJSInteropName(element.name);
  }

  String _jsMemberNameHelper(MemberElement element) {
    String jsInteropName = jsInteropMemberNames[element];
    assert(invariant(element,
        !(jsInteropMemberNames.containsKey(element) && jsInteropName == null),
        message:
            'Member $element is js interop but js interop name has not yet '
            'been computed.'));
    if (jsInteropName != null && jsInteropName.isNotEmpty) {
      return jsInteropName;
    }
    return computeUnescapedJSInteropName(element.name);
  }

  /// Returns a JavaScript path specifying the context in which
  /// [element.fixedBackendName] should be evaluated. Only applicable for
  /// elements using typed JavaScript interop.
  /// For example: fixedBackendPath for the static method createMap in the
  /// Map class of the goog.map JavaScript library would have path
  /// "goog.maps.Map".
  String getFixedBackendMethodPath(MethodElement element) {
    if (!isJsInteropMember(element)) return null;
    if (element.isInstanceMember) return 'this';
    if (element.isConstructor) {
      return _fixedBackendClassPath(element.enclosingClass);
    }
    StringBuffer sb = new StringBuffer();
    sb.write(_jsLibraryNameHelper(element.library));
    if (element.enclosingClass != null) {
      sb..write('.')..write(_jsClassNameHelper(element.enclosingClass));
    }
    return sb.toString();
  }

  String _fixedBackendClassPath(ClassElement element) {
    if (!isJsInteropClass(element)) return null;
    return _jsLibraryNameHelper(element.library);
  }

  /// Returns `true` if [cls] is a native class.
  bool isNativeClass(ClassElement element) {
    if (isJsInteropClass(element)) return true;
    return nativeClassTagInfo.containsKey(element);
  }

  /// Returns `true` if [element] is a native member of a native class.
  bool isNativeMember(MemberElement element) {
    if (isJsInteropMember(element)) return true;
    return nativeMemberName.containsKey(element);
  }

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
  String computeUnescapedJSInteropName(String name) {
    return name.startsWith(_jsInteropEscapePrefix)
        ? name.substring(_jsInteropEscapePrefix.length)
        : name;
  }
}
