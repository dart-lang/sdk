// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.native_data;

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../common_elements.dart' show ElementEnvironment;
import '../elements/entities.dart';
import '../ir/annotations.dart';
import '../kernel/element_map.dart';
import '../native/behavior.dart' show NativeBehavior;
import '../serialization/serialization.dart';
import '../util/util.dart';

/// Basic information for native classes and js-interop libraries and classes.
///
/// This information is computed during loading using [NativeBasicDataBuilder].
abstract class NativeBasicData {
  /// Deserializes a [NativeBasicData] object from [source].
  factory NativeBasicData.readFromDataSource(
          DataSource source, ElementEnvironment elementEnvironment) =
      NativeBasicDataImpl.readFromDataSource;

  /// Serializes this [NativeBasicData] to [sink].
  void writeToDataSink(DataSink sink);

  /// Returns `true` if [cls] corresponds to a native JavaScript class.
  ///
  /// A class is marked as native either through the `@Native(...)` annotation
  /// allowed for internal libraries or via the typed JavaScriptInterop
  /// mechanism allowed for user libraries.
  bool isNativeClass(ClassEntity element);

  /// Returns the list of non-directive native tag words for [cls].
  List<String> getNativeTagsOfClass(ClassEntity cls);

  /// Returns `true` if [cls] has a `!nonleaf` tag word.
  bool hasNativeTagsForcedNonLeaf(ClassEntity cls);

  /// Returns `true` if [element] or any of its superclasses is native.
  bool isNativeOrExtendsNative(ClassEntity element);

  /// Returns `true` if js interop features are used.
  bool get isJsInteropUsed;

  /// Returns `true` if `allowInterop()` is invoked.
  bool get isAllowInteropUsed;

  /// Marks `allowInterop()` as used.
  ///
  /// [isAllowInteropUsed] is initially false on the closed world, and is only
  /// set during codegen enqueuing.
  void registerAllowInterop();

  /// Returns `true` if [element] is a JsInterop library.
  bool isJsInteropLibrary(LibraryEntity element);

  /// Returns `true` if [element] is a JsInterop class.
  bool isJsInteropClass(ClassEntity element);

  /// Returns `true` if [element] is a JsInterop member.
  bool isJsInteropMember(MemberEntity element);
}

/// Additional element information for native classes and methods and js-interop
/// methods.
///
/// This information is computed during resolution using [NativeDataBuilder].
abstract class NativeData extends NativeBasicData {
  /// Deserializes a [NativeData] object from [source].
  factory NativeData.readFromDataSource(
          DataSource source, ElementEnvironment elementEnvironment) =
      NativeDataImpl.readFromDataSource;

  /// Serializes this [NativeData] to [sink].
  @override
  void writeToDataSink(DataSink sink);

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

  @override
  bool isJsInteropMember(MemberEntity element);

  /// Returns the explicit js interop name for library [element].
  String getJsInteropLibraryName(LibraryEntity element);

  /// Returns `true` if [element] has an `@Anonymous` annotation.
  bool isAnonymousJsInteropClass(ClassEntity element);

  /// Returns the explicit js interop name for class [element].
  String getJsInteropClassName(ClassEntity element);

  /// Returns the explicit js interop name for member [element].
  String getJsInteropMemberName(MemberEntity element);

  /// Apply JS$ escaping scheme to convert possible escaped Dart names into
  /// JS names.
  String computeUnescapedJSInteropName(String name);
}

abstract class NativeBasicDataBuilder {
  /// Sets the native tag info for [cls].
  ///
  /// The tag info string contains comma-separated 'words' which are either
  /// dispatch tags (having JavaScript identifier syntax) and directives that
  /// begin with `!`.
  void setNativeClassTagInfo(ClassEntity cls, String tagInfo);

  /// Marks [element] as an explicit part of js interop.
  ///
  /// If [name] is provided, it sets the explicit js interop name for the
  /// library [element], other the js interop name is expected to be computed
  /// later.
  void markAsJsInteropLibrary(LibraryEntity element, {String name});

  /// Marks [element] as an explicit part of js interop.
  ///
  /// If [name] is provided, it sets the explicit js interop name for the
  /// class [element], other the js interop name is expected to be computed
  /// later.
  void markAsJsInteropClass(ClassEntity element,
      {String name, bool isAnonymous: false});

  /// Marks [element] as an explicit part of js interop and sets the explicit js
  /// interop [name] for the member [element].
  void markAsJsInteropMember(MemberEntity element, String name);

  /// Creates the [NativeBasicData] object for the data collected in this
  /// builder.
  NativeBasicData close(ElementEnvironment environment);
}

abstract class NativeDataBuilder {
  /// Registers the [behavior] for calling the native [method].
  void setNativeMethodBehavior(FunctionEntity method, NativeBehavior behavior);

  /// Registers the [behavior] for reading from the native [field].
  void setNativeFieldLoadBehavior(FieldEntity field, NativeBehavior behavior);

  /// Registers the [behavior] for writing to the native [field].
  void setNativeFieldStoreBehavior(FieldEntity field, NativeBehavior behavior);

  /// Sets the native [name] for the member [element].
  ///
  /// This name is used for [element] in the generated JavaScript.
  void setNativeMemberName(MemberEntity element, String name);

  /// Closes this builder and creates the resulting [NativeData] object.
  NativeData close();
}

class NativeBasicDataBuilderImpl implements NativeBasicDataBuilder {
  bool _closed = false;

  /// Tag info for native JavaScript classes names. See
  /// [setNativeClassTagInfo].
  Map<ClassEntity, NativeClassTag> nativeClassTagInfo =
      <ClassEntity, NativeClassTag>{};

  /// The JavaScript libraries implemented via typed JavaScript interop.
  Map<LibraryEntity, String> jsInteropLibraries = <LibraryEntity, String>{};

  /// The JavaScript classes implemented via typed JavaScript interop.
  Map<ClassEntity, String> jsInteropClasses = <ClassEntity, String>{};

  /// JavaScript interop classes annotated with `@anonymous`
  Set<ClassEntity> anonymousJsInteropClasses = new Set<ClassEntity>();

  /// The JavaScript members implemented via typed JavaScript interop.
  Map<MemberEntity, String> jsInteropMembers = <MemberEntity, String>{};

  @override
  void setNativeClassTagInfo(ClassEntity cls, String tagText) {
    assert(
        !_closed,
        failedAt(
            cls,
            "NativeBasicDataBuilder is closed. "
            "Trying to mark $cls as a native class."));

    // TODO(johnniwinther): Assert that this is only called once. The memory
    // compiler copies pre-processed elements into a new compiler through
    // [Compiler.onLibraryScanned] and thereby causes multiple calls to this
    // method.
    assert(
        nativeClassTagInfo[cls] == null ||
            nativeClassTagInfo[cls].text == tagText,
        failedAt(
            cls,
            "Native tag info set inconsistently on $cls: "
            "Existing tag info '${nativeClassTagInfo[cls]}', "
            "new tag info '$tagText'."));
    nativeClassTagInfo[cls] = new NativeClassTag(tagText);
  }

  @override
  void markAsJsInteropLibrary(LibraryEntity element, {String name}) {
    assert(
        !_closed,
        failedAt(
            element,
            "NativeBasicDataBuilder is closed. "
            "Trying to mark $element as a js-interop library."));
    jsInteropLibraries[element] = name;
  }

  @override
  void markAsJsInteropClass(ClassEntity element,
      {String name, bool isAnonymous: false}) {
    assert(
        !_closed,
        failedAt(
            element,
            "NativeBasicDataBuilder is closed. "
            "Trying to mark $element as a js-interop class."));
    jsInteropClasses[element] = name;
    if (isAnonymous) {
      anonymousJsInteropClasses.add(element);
    }
  }

  @override
  void markAsJsInteropMember(MemberEntity element, String name) {
    assert(
        !_closed,
        failedAt(
            element,
            "NativeBasicDataBuilder is closed. "
            "Trying to mark $element as a js-interop member."));
    jsInteropMembers[element] = name;
  }

  @override
  NativeBasicData close(ElementEnvironment environment) {
    _closed = true;
    return new NativeBasicDataImpl(
        environment,
        false,
        nativeClassTagInfo,
        jsInteropLibraries,
        jsInteropClasses,
        anonymousJsInteropClasses,
        jsInteropMembers);
  }

  void reopenForTesting() {
    _closed = false;
  }
}

class NativeBasicDataImpl implements NativeBasicData {
  /// Tag used for identifying serialized [NativeBasicData] objects in a
  /// debugging data stream.
  static const String tag = 'native-basic-data';

  final ElementEnvironment _env;

  bool _isAllowInteropUsed;

  /// Tag info for native JavaScript classes names. See
  /// [setNativeClassTagInfo].
  final Map<ClassEntity, NativeClassTag> nativeClassTagInfo;

  /// The JavaScript libraries implemented via typed JavaScript interop.
  final Map<LibraryEntity, String> jsInteropLibraries;

  /// The JavaScript classes implemented via typed JavaScript interop.
  final Map<ClassEntity, String> jsInteropClasses;

  /// JavaScript interop classes annotated with `@anonymous`
  final Set<ClassEntity> anonymousJsInteropClasses;

  /// The JavaScript members implemented via typed JavaScript interop.
  final Map<MemberEntity, String> jsInteropMembers;

  NativeBasicDataImpl(
      this._env,
      this._isAllowInteropUsed,
      this.nativeClassTagInfo,
      this.jsInteropLibraries,
      this.jsInteropClasses,
      this.anonymousJsInteropClasses,
      this.jsInteropMembers);

  factory NativeBasicDataImpl.fromIr(
      KernelToElementMap map, IrAnnotationData data) {
    ElementEnvironment env = map.elementEnvironment;
    Map<ClassEntity, NativeClassTag> nativeClassTagInfo = {};
    Map<LibraryEntity, String> jsInteropLibraries = {};
    Map<ClassEntity, String> jsInteropClasses = {};
    Set<ClassEntity> anonymousJsInteropClasses = {};
    Map<MemberEntity, String> jsInteropMembers = {};

    data.forEachNativeClass((ir.Class node, String text) {
      nativeClassTagInfo[map.getClass(node)] = new NativeClassTag(text);
    });
    data.forEachJsInteropLibrary((ir.Library node, String name) {
      jsInteropLibraries[env.lookupLibrary(node.importUri, required: true)] =
          name;
    });
    data.forEachJsInteropClass((ir.Class node, String name,
        {bool isAnonymous}) {
      ClassEntity cls = map.getClass(node);
      jsInteropClasses[cls] = name;
      if (isAnonymous) {
        anonymousJsInteropClasses.add(cls);
      }
    });
    data.forEachJsInteropMember((ir.Member node, String name) {
      if (memberIsIgnorable(node)) return;
      jsInteropMembers[map.getMember(node)] = name;
    });

    return new NativeBasicDataImpl(
        env,
        false,
        nativeClassTagInfo,
        jsInteropLibraries,
        jsInteropClasses,
        anonymousJsInteropClasses,
        jsInteropMembers);
  }

  factory NativeBasicDataImpl.readFromDataSource(
      DataSource source, ElementEnvironment elementEnvironment) {
    source.begin(tag);
    bool isAllowInteropUsed = source.readBool();
    Map<ClassEntity, NativeClassTag> nativeClassTagInfo =
        source.readClassMap(() {
      List<String> names = source.readStrings();
      bool isNonLeaf = source.readBool();
      return new NativeClassTag.internal(names, isNonLeaf);
    });
    Map<LibraryEntity, String> jsInteropLibraries =
        source.readLibraryMap(source.readString);
    Map<ClassEntity, String> jsInteropClasses =
        source.readClassMap(source.readString);
    Set<ClassEntity> anonymousJsInteropClasses = source.readClasses().toSet();
    Map<MemberEntity, String> jsInteropMembers =
        source.readMemberMap((MemberEntity member) => source.readString());
    source.end(tag);
    return new NativeBasicDataImpl(
        elementEnvironment,
        isAllowInteropUsed,
        nativeClassTagInfo,
        jsInteropLibraries,
        jsInteropClasses,
        anonymousJsInteropClasses,
        jsInteropMembers);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeBool(isAllowInteropUsed);
    sink.writeClassMap(nativeClassTagInfo, (NativeClassTag tag) {
      sink.writeStrings(tag.names);
      sink.writeBool(tag.isNonLeaf);
    });
    sink.writeLibraryMap(jsInteropLibraries, sink.writeString);
    sink.writeClassMap(jsInteropClasses, sink.writeString);
    sink.writeClasses(anonymousJsInteropClasses);
    sink.writeMemberMap(jsInteropMembers,
        (MemberEntity member, String name) => sink.writeString(name));
    sink.end(tag);
  }

  @override
  bool get isAllowInteropUsed => _isAllowInteropUsed;

  @override
  void registerAllowInterop() {
    _isAllowInteropUsed = true;
  }

  @override
  bool isNativeClass(ClassEntity element) {
    if (isJsInteropClass(element)) return true;
    return nativeClassTagInfo.containsKey(element);
  }

  @override
  List<String> getNativeTagsOfClass(ClassEntity cls) {
    return nativeClassTagInfo[cls].names;
  }

  @override
  bool hasNativeTagsForcedNonLeaf(ClassEntity cls) {
    return nativeClassTagInfo[cls].isNonLeaf;
  }

  @override
  bool get isJsInteropUsed =>
      jsInteropLibraries.isNotEmpty || jsInteropClasses.isNotEmpty;

  @override
  bool isJsInteropLibrary(LibraryEntity element) {
    return jsInteropLibraries.containsKey(element);
  }

  @override
  bool isJsInteropClass(ClassEntity element) {
    return jsInteropClasses.containsKey(element);
  }

  /// Returns `true` if [element] is explicitly marked as part of JsInterop.
  bool _isJsInteropMember(MemberEntity element) {
    return jsInteropMembers.containsKey(element);
  }

  @override
  bool isJsInteropMember(MemberEntity element) {
    // TODO(johnniwinther): Share this with [NativeDataImpl.isJsInteropMember].
    if (element.isFunction ||
        element.isConstructor ||
        element.isGetter ||
        element.isSetter) {
      FunctionEntity function = element;
      if (!function.isExternal) return false;

      if (_isJsInteropMember(function)) return true;
      if (function.enclosingClass != null) {
        return isJsInteropClass(function.enclosingClass);
      }
      if (function.isTopLevel) {
        return isJsInteropLibrary(function.library);
      }
      return false;
    } else {
      return _isJsInteropMember(element);
    }
  }

  @override
  bool isNativeOrExtendsNative(ClassEntity element) {
    if (element == null) return false;
    if (isNativeClass(element) || isJsInteropClass(element)) {
      return true;
    }
    return isNativeOrExtendsNative(_env.getSuperClass(element));
  }
}

class NativeDataBuilderImpl implements NativeDataBuilder {
  final NativeBasicDataImpl _nativeBasicData;

  /// The JavaScript names for native JavaScript elements implemented.
  Map<MemberEntity, String> nativeMemberName = <MemberEntity, String>{};

  /// Cache for [NativeBehavior]s for calling native methods.
  Map<FunctionEntity, NativeBehavior> nativeMethodBehavior =
      <FunctionEntity, NativeBehavior>{};

  /// Cache for [NativeBehavior]s for reading from native fields.
  Map<MemberEntity, NativeBehavior> nativeFieldLoadBehavior =
      <FieldEntity, NativeBehavior>{};

  /// Cache for [NativeBehavior]s for writing to native fields.
  Map<MemberEntity, NativeBehavior> nativeFieldStoreBehavior =
      <FieldEntity, NativeBehavior>{};

  NativeDataBuilderImpl(this._nativeBasicData);

  @override
  void setNativeMemberName(MemberEntity element, String name) {
    // TODO(johnniwinther): Avoid setting this more than once. The enqueuer
    // might enqueue [element] several times (before processing it) and computes
    // name on each call to `internalAddToWorkList`.
    assert(
        nativeMemberName[element] == null || nativeMemberName[element] == name,
        failedAt(
            element,
            "Native member name set inconsistently on $element: "
            "Existing name '${nativeMemberName[element]}', "
            "new name '$name'."));
    nativeMemberName[element] = name;
  }

  @override
  void setNativeMethodBehavior(FunctionEntity method, NativeBehavior behavior) {
    nativeMethodBehavior[method] = behavior;
  }

  @override
  void setNativeFieldLoadBehavior(FieldEntity field, NativeBehavior behavior) {
    nativeFieldLoadBehavior[field] = behavior;
  }

  @override
  void setNativeFieldStoreBehavior(FieldEntity field, NativeBehavior behavior) {
    nativeFieldStoreBehavior[field] = behavior;
  }

  @override
  NativeData close() => new NativeDataImpl(_nativeBasicData, nativeMemberName,
      nativeMethodBehavior, nativeFieldLoadBehavior, nativeFieldStoreBehavior);
}

// TODO(johnniwinther): Remove fields that overlap with [NativeBasicData], like
// [anonymousJsInteropClasses].
class NativeDataImpl implements NativeData, NativeBasicDataImpl {
  /// Tag used for identifying serialized [NativeData] objects in a
  /// debugging data stream.
  static const String tag = 'native-data';

  /// Prefix used to escape JS names that are not valid Dart names
  /// when using JSInterop.
  static const String _jsInteropEscapePrefix = r'JS$';

  final NativeBasicDataImpl _nativeBasicData;

  /// The JavaScript names for native JavaScript elements implemented.
  final Map<MemberEntity, String> nativeMemberName;

  /// Cache for [NativeBehavior]s for calling native methods.
  final Map<FunctionEntity, NativeBehavior> nativeMethodBehavior;

  /// Cache for [NativeBehavior]s for reading from native fields.
  final Map<MemberEntity, NativeBehavior> nativeFieldLoadBehavior;

  /// Cache for [NativeBehavior]s for writing to native fields.
  final Map<MemberEntity, NativeBehavior> nativeFieldStoreBehavior;

  NativeDataImpl(
      this._nativeBasicData,
      this.nativeMemberName,
      this.nativeMethodBehavior,
      this.nativeFieldLoadBehavior,
      this.nativeFieldStoreBehavior);

  factory NativeDataImpl.fromIr(KernelToElementMap map, IrAnnotationData data) {
    NativeBasicDataImpl nativeBasicData =
        new NativeBasicDataImpl.fromIr(map, data);
    Map<MemberEntity, String> nativeMemberName = {};
    Map<FunctionEntity, NativeBehavior> nativeMethodBehavior = {};
    Map<MemberEntity, NativeBehavior> nativeFieldLoadBehavior = {};
    Map<MemberEntity, NativeBehavior> nativeFieldStoreBehavior = {};

    data.forEachNativeMethodData((ir.Member node,
        String name,
        Iterable<String> createsAnnotations,
        Iterable<String> returnsAnnotations) {
      MemberEntity member = map.getMember(node);
      nativeMemberName[member] = name;
      bool isJsInterop = nativeBasicData.isJsInteropMember(member);
      nativeMethodBehavior[member] = map.getNativeBehaviorForMethod(
          node, createsAnnotations, returnsAnnotations,
          isJsInterop: isJsInterop);
    });

    data.forEachNativeFieldData((ir.Member node,
        String name,
        Iterable<String> createsAnnotations,
        Iterable<String> returnsAnnotations) {
      FieldEntity field = map.getMember(node);
      nativeMemberName[field] = name;
      bool isJsInterop = nativeBasicData.isJsInteropMember(field);
      nativeFieldLoadBehavior[field] = map.getNativeBehaviorForFieldLoad(
          node, createsAnnotations, returnsAnnotations,
          isJsInterop: isJsInterop);
      nativeFieldStoreBehavior[field] =
          map.getNativeBehaviorForFieldStore(node);
    });

    return new NativeDataImpl(
        nativeBasicData,
        nativeMemberName,
        nativeMethodBehavior,
        nativeFieldLoadBehavior,
        nativeFieldStoreBehavior);
  }

  factory NativeDataImpl.readFromDataSource(
      DataSource source, ElementEnvironment elementEnvironment) {
    source.begin(tag);
    NativeBasicData nativeBasicData =
        new NativeBasicData.readFromDataSource(source, elementEnvironment);
    Map<MemberEntity, String> nativeMemberName =
        source.readMemberMap((MemberEntity member) => source.readString());
    Map<FunctionEntity, NativeBehavior> nativeMethodBehavior =
        source.readMemberMap((MemberEntity member) =>
            new NativeBehavior.readFromDataSource(source));
    Map<MemberEntity, NativeBehavior> nativeFieldLoadBehavior =
        source.readMemberMap((MemberEntity member) =>
            new NativeBehavior.readFromDataSource(source));
    Map<MemberEntity, NativeBehavior> nativeFieldStoreBehavior =
        source.readMemberMap((MemberEntity member) =>
            new NativeBehavior.readFromDataSource(source));
    source.end(tag);
    return new NativeDataImpl(
        nativeBasicData,
        nativeMemberName,
        nativeMethodBehavior,
        nativeFieldLoadBehavior,
        nativeFieldStoreBehavior);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    _nativeBasicData.writeToDataSink(sink);

    sink.writeMemberMap(nativeMemberName,
        (MemberEntity member, String name) => sink.writeString(name));

    sink.writeMemberMap(nativeMethodBehavior,
        (MemberEntity member, NativeBehavior behavior) {
      behavior.writeToDataSink(sink);
    });

    sink.writeMemberMap(nativeFieldLoadBehavior,
        (MemberEntity member, NativeBehavior behavior) {
      behavior.writeToDataSink(sink);
    });
    sink.writeMemberMap(nativeFieldStoreBehavior,
        (MemberEntity member, NativeBehavior behavior) {
      behavior.writeToDataSink(sink);
    });

    sink.end(tag);
  }

  @override
  bool get _isAllowInteropUsed => _nativeBasicData._isAllowInteropUsed;

  @override
  set _isAllowInteropUsed(bool value) =>
      _nativeBasicData._isAllowInteropUsed = value;

  @override
  bool get isAllowInteropUsed => _nativeBasicData.isAllowInteropUsed;

  @override
  void registerAllowInterop() => _nativeBasicData.registerAllowInterop();

  @override
  Map<LibraryEntity, String> get jsInteropLibraries =>
      _nativeBasicData.jsInteropLibraries;

  @override
  Set<ClassEntity> get anonymousJsInteropClasses =>
      _nativeBasicData.anonymousJsInteropClasses;

  @override
  Map<ClassEntity, String> get jsInteropClasses =>
      _nativeBasicData.jsInteropClasses;

  @override
  Map<MemberEntity, String> get jsInteropMembers =>
      _nativeBasicData.jsInteropMembers;

  @override
  bool isAnonymousJsInteropClass(ClassEntity element) {
    return anonymousJsInteropClasses.contains(element);
  }

  @override
  bool isNativeClass(ClassEntity element) =>
      _nativeBasicData.isNativeClass(element);

  @override
  List<String> getNativeTagsOfClass(ClassEntity cls) =>
      _nativeBasicData.getNativeTagsOfClass(cls);

  @override
  bool hasNativeTagsForcedNonLeaf(ClassEntity cls) =>
      _nativeBasicData.hasNativeTagsForcedNonLeaf(cls);

  @override
  bool get isJsInteropUsed => _nativeBasicData.isJsInteropUsed;

  @override
  bool isJsInteropLibrary(LibraryEntity element) =>
      _nativeBasicData.isJsInteropLibrary(element);

  @override
  bool isJsInteropClass(ClassEntity element) =>
      _nativeBasicData.isJsInteropClass(element);

  @override
  bool isNativeOrExtendsNative(ClassEntity element) =>
      _nativeBasicData.isNativeOrExtendsNative(element);

  @override
  String getJsInteropLibraryName(LibraryEntity element) {
    return jsInteropLibraries[element];
  }

  @override
  String getJsInteropClassName(ClassEntity element) {
    return jsInteropClasses[element];
  }

  @override
  String getJsInteropMemberName(MemberEntity element) {
    return jsInteropMembers[element];
  }

  @override
  bool _isJsInteropMember(MemberEntity element) {
    return jsInteropMembers.containsKey(element);
  }

  @override
  bool isJsInteropMember(MemberEntity element) {
    if (element.isFunction ||
        element.isConstructor ||
        element.isGetter ||
        element.isSetter) {
      FunctionEntity function = element;
      if (!function.isExternal) return false;

      if (_isJsInteropMember(function)) return true;
      if (function.enclosingClass != null) {
        return isJsInteropClass(function.enclosingClass);
      }
      if (function.isTopLevel) {
        return isJsInteropLibrary(function.library);
      }
      return false;
    } else {
      return _isJsInteropMember(element);
    }
  }

  @override
  bool hasFixedBackendName(MemberEntity element) {
    return isJsInteropMember(element) || nativeMemberName.containsKey(element);
  }

  @override
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
    String jsInteropName = jsInteropMembers[element];
    assert(
        !(jsInteropMembers.containsKey(element) && jsInteropName == null),
        failedAt(
            element,
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
  @override
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

  @override
  bool isNativeMember(MemberEntity element) {
    if (isJsInteropMember(element)) return true;
    return nativeMemberName.containsKey(element);
  }

  @override
  NativeBehavior getNativeMethodBehavior(FunctionEntity method) {
    assert(
        nativeMethodBehavior.containsKey(method),
        failedAt(method,
            "No native method behavior has been computed for $method."));
    return nativeMethodBehavior[method];
  }

  @override
  NativeBehavior getNativeFieldLoadBehavior(FieldEntity field) {
    assert(
        nativeFieldLoadBehavior.containsKey(field),
        failedAt(
            field,
            "No native field load behavior has been "
            "computed for $field."));
    return nativeFieldLoadBehavior[field];
  }

  @override
  NativeBehavior getNativeFieldStoreBehavior(FieldEntity field) {
    assert(
        nativeFieldStoreBehavior.containsKey(field),
        failedAt(field,
            "No native field store behavior has been computed for $field."));
    return nativeFieldStoreBehavior[field];
  }

  @override
  String computeUnescapedJSInteropName(String name) {
    return name.startsWith(_jsInteropEscapePrefix)
        ? name.substring(_jsInteropEscapePrefix.length)
        : name;
  }

  @override
  Map<ClassEntity, NativeClassTag> get nativeClassTagInfo =>
      _nativeBasicData.nativeClassTagInfo;

  @override
  ElementEnvironment get _env => _nativeBasicData._env;
}

class NativeClassTag {
  final List<String> names;
  final bool isNonLeaf;

  factory NativeClassTag(String tagText) {
    List<String> tags = tagText.split(',');
    List<String> names = tags.where((s) => !s.startsWith('!')).toList();
    bool isNonLeaf = tags.contains('!nonleaf');
    return new NativeClassTag.internal(names, isNonLeaf);
  }

  NativeClassTag.internal(this.names, this.isNonLeaf);

  String get text {
    StringBuffer sb = new StringBuffer();
    sb.write(names.join(','));
    if (isNonLeaf) {
      if (names.isNotEmpty) {
        sb.write(',');
      }
      sb.write('!nonleaf');
    }
    return sb.toString();
  }

  @override
  int get hashCode => Hashing.listHash(names, isNonLeaf.hashCode);

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! NativeClassTag) return false;
    return equalElements(names, other.names) && isNonLeaf == other.isNonLeaf;
  }

  @override
  String toString() => text;
}
