// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.native_data;

import '../common.dart';
import '../elements/elements.dart' show ClassElement;
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
  bool isNativeOrExtendsNative(ClassEntity element);

  /// Returns `true` if [element] is a JsInterop library.
  bool isJsInteropLibrary(LibraryEntity element);

  /// Returns `true` if [element] is a JsInterop class.
  bool isJsInteropClass(ClassEntity element);
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
  NativeBehavior getNativeMethodBehavior(FunctionEntity method);

  /// Returns the [NativeBehavior] for reading from the native [field].
  NativeBehavior getNativeFieldLoadBehavior(FieldEntity field);

  /// Returns the [NativeBehavior] for writing to the native [field].
  NativeBehavior getNativeFieldStoreBehavior(FieldEntity field);

  /// Returns `true` if the name of [element] is fixed for the generated
  /// JavaScript.
  bool hasFixedBackendName(MemberEntity element);

  /// Computes the name for [element] to use in the generated JavaScript. This
  /// is either given through a native annotation or a js interop annotation.
  String getFixedBackendName(MemberEntity element);

  /// Computes the name prefix for [element] to use in the generated JavaScript.
  ///
  /// For static and top-level members and constructors this is based on the
  /// JavaScript names for the library and/or the enclosing class.
  String getFixedBackendMethodPath(FunctionEntity element);

  /// Returns the list of non-directive native tag words for [cls].
  List<String> getNativeTagsOfClass(ClassEntity cls);

  /// Returns `true` if [cls] has a `!nonleaf` tag word.
  bool hasNativeTagsForcedNonLeaf(ClassEntity cls);

  /// Returns `true` if [element] is a JsInterop method.
  bool isJsInteropMember(MemberEntity element);

  /// Returns the explicit js interop name for library [element].
  String getJsInteropLibraryName(LibraryEntity element);

  /// Returns the explicit js interop name for class [element].
  String getJsInteropClassName(ClassEntity element);

  /// Returns the explicit js interop name for member [element].
  String getJsInteropMemberName(MemberEntity element);

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
  void setNativeClassTagInfo(ClassEntity cls, String tagInfo);

  /// Marks [element] as an explicit part of JsInterop. The js interop name is
  /// expected to be computed later.
  void markAsJsInteropLibrary(LibraryEntity element);

  /// Marks [element] as an explicit part of JsInterop. The js interop name is
  /// expected to be computed later.
  void markAsJsInteropClass(ClassEntity element);
}

abstract class NativeDataBuilder {
  /// Registers the [behavior] for calling the native [method].
  void setNativeMethodBehavior(FunctionEntity method, NativeBehavior behavior);

  /// Registers the [behavior] for reading from the native [field].
  void setNativeFieldLoadBehavior(FieldEntity field, NativeBehavior behavior);

  /// Registers the [behavior] for writing to the native [field].
  void setNativeFieldStoreBehavior(FieldEntity field, NativeBehavior behavior);

  /// Returns the list of native tag words for [cls].
  List<String> getNativeTagsOfClassRaw(ClassEntity cls);

  /// Returns [element] as an explicit part of JsInterop. The js interop name is
  /// expected to be computed later.
  void markAsJsInteropMember(MemberEntity element);

  /// Sets the native [name] for the member [element]. This name is used for
  /// [element] in the generated JavaScript.
  void setNativeMemberName(MemberEntity element, String name);

  /// Sets the explicit js interop [name] for the library [element].
  void setJsInteropLibraryName(LibraryEntity element, String name);

  /// Sets the explicit js interop [name] for the class [element].
  void setJsInteropClassName(ClassEntity element, String name);

  /// Sets the explicit js interop [name] for the member [element].
  void setJsInteropMemberName(MemberEntity element, String name);
}

class NativeDataImpl
    implements NativeData, NativeDataBuilder, NativeClassDataBuilder {
  /// The JavaScript names for elements implemented via typed JavaScript
  /// interop.
  Map<LibraryEntity, String> jsInteropLibraryNames = <LibraryEntity, String>{};
  Map<ClassEntity, String> jsInteropClassNames = <ClassEntity, String>{};
  Map<MemberEntity, String> jsInteropMemberNames = <MemberEntity, String>{};

  /// The JavaScript names for native JavaScript elements implemented.
  Map<MemberEntity, String> nativeMemberName = <MemberEntity, String>{};

  /// Tag info for native JavaScript classes names. See
  /// [setNativeClassTagInfo].
  Map<ClassEntity, String> nativeClassTagInfo = <ClassEntity, String>{};

  /// Cache for [NativeBehavior]s for calling native methods.
  Map<FunctionEntity, NativeBehavior> nativeMethodBehavior =
      <FunctionEntity, NativeBehavior>{};

  /// Cache for [NativeBehavior]s for reading from native fields.
  Map<MemberEntity, NativeBehavior> nativeFieldLoadBehavior =
      <FieldEntity, NativeBehavior>{};

  /// Cache for [NativeBehavior]s for writing to native fields.
  Map<MemberEntity, NativeBehavior> nativeFieldStoreBehavior =
      <FieldEntity, NativeBehavior>{};

  /// Prefix used to escape JS names that are not valid Dart names
  /// when using JSInterop.
  static const String _jsInteropEscapePrefix = r'JS$';

  /// Returns `true` if [element] is explicitly marked as part of JsInterop.
  bool _isJsInteropLibrary(LibraryEntity element) {
    return jsInteropLibraryNames.containsKey(element);
  }

  /// Returns `true` if [element] is explicitly marked as part of JsInterop.
  bool _isJsInteropClass(ClassEntity element) {
    return jsInteropClassNames.containsKey(element);
  }

  /// Returns `true` if [element] is explicitly marked as part of JsInterop.
  bool _isJsInteropMember(MemberEntity element) {
    return jsInteropMemberNames.containsKey(element);
  }

  @override
  void markAsJsInteropLibrary(LibraryEntity element) {
    jsInteropLibraryNames[element] = null;
  }

  @override
  void markAsJsInteropClass(ClassEntity element) {
    jsInteropClassNames[element] = null;
  }

  @override
  void markAsJsInteropMember(MemberEntity element) {
    jsInteropMemberNames[element] = null;
  }

  /// Sets the explicit js interop [name] for the library [element].
  void setJsInteropLibraryName(LibraryEntity element, String name) {
    assert(invariant(element, _isJsInteropLibrary(element),
        message:
            'Library $element is not js interop but given a js interop name.'));
    jsInteropLibraryNames[element] = name;
  }

  /// Sets the explicit js interop [name] for the class [element].
  void setJsInteropClassName(ClassEntity element, String name) {
    assert(invariant(element, _isJsInteropClass(element),
        message:
            'Class $element is not js interop but given a js interop name.'));
    jsInteropClassNames[element] = name;
  }

  /// Sets the explicit js interop [name] for the member [element].
  void setJsInteropMemberName(MemberEntity element, String name) {
    assert(invariant(element, _isJsInteropMember(element),
        message:
            'Member $element is not js interop but given a js interop name.'));
    jsInteropMemberNames[element] = name;
  }

  /// Returns the explicit js interop name for library [element].
  String getJsInteropLibraryName(LibraryEntity element) {
    return jsInteropLibraryNames[element];
  }

  /// Returns the explicit js interop name for class [element].
  String getJsInteropClassName(ClassEntity element) {
    return jsInteropClassNames[element];
  }

  /// Returns the explicit js interop name for member [element].
  String getJsInteropMemberName(MemberEntity element) {
    return jsInteropMemberNames[element];
  }

  /// Returns `true` if [element] is a JsInterop library.
  bool isJsInteropLibrary(LibraryEntity element) =>
      _isJsInteropLibrary(element);

  /// Returns `true` if [element] is a JsInterop class.
  bool isJsInteropClass(ClassEntity element) => _isJsInteropClass(element);

  /// Returns `true` if [element] is a JsInterop method.
  bool isJsInteropMember(MemberEntity element) {
    if (element.isFunction ||
        element.isConstructor ||
        element.isGetter ||
        element.isSetter) {
      FunctionEntity function = element;
      if (!function.isExternal) return false;

      if (_isJsInteropMember(function)) return true;
      if (function.enclosingClass != null) {
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
  bool hasFixedBackendName(MemberEntity element) {
    return isJsInteropMember(element) || nativeMemberName.containsKey(element);
  }

  /// Computes the name for [element] to use in the generated JavaScript. This
  /// is either given through a native annotation or a js interop annotation.
  String getFixedBackendName(MemberEntity element) {
    String name = nativeMemberName[element];
    if (name == null && isJsInteropMember(element)) {
      // If an element isJsInterop but _isJsInterop is false that means it is
      // considered interop as the parent class is interop.
      name = element.isConstructor
          ? _jsClassNameHelper(element.enclosingClass)
          : _jsMemberNameHelper(element);
      nativeMemberName[element] = name;
    }
    return name;
  }

  String _jsLibraryNameHelper(LibraryEntity element) {
    String jsInteropName = getJsInteropLibraryName(element);
    if (jsInteropName != null && jsInteropName.isNotEmpty) return jsInteropName;
    return 'self';
  }

  String _jsClassNameHelper(ClassEntity element) {
    String jsInteropName = getJsInteropClassName(element);
    if (jsInteropName != null && jsInteropName.isNotEmpty) return jsInteropName;
    return computeUnescapedJSInteropName(element.name);
  }

  String _jsMemberNameHelper(MemberEntity element) {
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
  String getFixedBackendMethodPath(FunctionEntity element) {
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

  String _fixedBackendClassPath(ClassEntity element) {
    if (!isJsInteropClass(element)) return null;
    return _jsLibraryNameHelper(element.library);
  }

  /// Returns `true` if [cls] is a native class.
  bool isNativeClass(ClassEntity element) {
    if (isJsInteropClass(element)) return true;
    return nativeClassTagInfo.containsKey(element);
  }

  /// Returns `true` if [element] is a native member of a native class.
  bool isNativeMember(MemberEntity element) {
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
  void setNativeMemberName(MemberEntity element, String name) {
    // TODO(johnniwinther): Avoid setting this more than once. The enqueuer
    // might enqueue [element] several times (before processing it) and computes
    // name on each call to `internalAddToWorkList`.
    assert(invariant(element,
        nativeMemberName[element] == null || nativeMemberName[element] == name,
        message: "Native member name set inconsistently on $element: "
            "Existing name '${nativeMemberName[element]}', "
            "new name '$name'."));
    nativeMemberName[element] = name;
  }

  /// Sets the native tag info for [cls].
  ///
  /// The tag info string contains comma-separated 'words' which are either
  /// dispatch tags (having JavaScript identifier syntax) and directives that
  /// begin with `!`.
  void setNativeClassTagInfo(ClassEntity cls, String tagInfo) {
    // TODO(johnniwinther): Assert that this is only called once. The memory
    // compiler copies pre-processed elements into a new compiler through
    // [Compiler.onLibraryScanned] and thereby causes multiple calls to this
    // method.
    assert(invariant(cls,
        nativeClassTagInfo[cls] == null || nativeClassTagInfo[cls] == tagInfo,
        message: "Native tag info set inconsistently on $cls: "
            "Existing tag info '${nativeClassTagInfo[cls]}', "
            "new tag info '$tagInfo'."));
    nativeClassTagInfo[cls] = tagInfo;
  }

  /// Returns the list of native tag words for [cls].
  List<String> getNativeTagsOfClassRaw(ClassEntity cls) {
    String quotedName = nativeClassTagInfo[cls];
    return quotedName.substring(1, quotedName.length - 1).split(',');
  }

  /// Returns the list of non-directive native tag words for [cls].
  List<String> getNativeTagsOfClass(ClassEntity cls) {
    return getNativeTagsOfClassRaw(cls)
        .where((s) => !s.startsWith('!'))
        .toList();
  }

  /// Returns `true` if [cls] has a `!nonleaf` tag word.
  bool hasNativeTagsForcedNonLeaf(ClassEntity cls) {
    return getNativeTagsOfClassRaw(cls).contains('!nonleaf');
  }

  /// Returns the [NativeBehavior] for calling the native [method].
  NativeBehavior getNativeMethodBehavior(FunctionEntity method) {
    assert(invariant(method, nativeMethodBehavior.containsKey(method),
        message: "No native method behavior has been computed for $method."));
    return nativeMethodBehavior[method];
  }

  /// Returns the [NativeBehavior] for reading from the native [field].
  NativeBehavior getNativeFieldLoadBehavior(FieldEntity field) {
    assert(invariant(field, nativeFieldLoadBehavior.containsKey(field),
        message: "No native field load behavior has been "
            "computed for $field."));
    return nativeFieldLoadBehavior[field];
  }

  /// Returns the [NativeBehavior] for writing to the native [field].
  NativeBehavior getNativeFieldStoreBehavior(FieldEntity field) {
    assert(invariant(field, nativeFieldStoreBehavior.containsKey(field),
        message: "No native field store behavior has been "
            "computed for $field."));
    return nativeFieldStoreBehavior[field];
  }

  /// Registers the [behavior] for calling the native [method].
  void setNativeMethodBehavior(FunctionEntity method, NativeBehavior behavior) {
    nativeMethodBehavior[method] = behavior;
  }

  /// Registers the [behavior] for reading from the native [field].
  void setNativeFieldLoadBehavior(FieldEntity field, NativeBehavior behavior) {
    nativeFieldLoadBehavior[field] = behavior;
  }

  /// Registers the [behavior] for writing to the native [field].
  void setNativeFieldStoreBehavior(FieldEntity field, NativeBehavior behavior) {
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
