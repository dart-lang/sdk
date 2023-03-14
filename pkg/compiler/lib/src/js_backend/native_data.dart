// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.native_data;

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../common/elements.dart' show ElementEnvironment;
import '../elements/entities.dart';
import '../ir/annotations.dart';
import '../js_model/js_to_frontend_map.dart' show identity, JsToFrontendMap;
import '../kernel/element_map.dart';
import '../native/behavior.dart' show NativeBehavior;
import '../serialization/serialization.dart';
import '../util/util.dart';

class NativeBasicDataBuilder {
  bool _closed = false;

  /// Tag info for native JavaScript classes names. See
  /// [setNativeClassTagInfo].
  final Map<ClassEntity, NativeClassTag> _nativeClassTagInfo = {};

  /// The JavaScript libraries implemented via typed JavaScript interop.
  final Map<LibraryEntity, String> _jsInteropLibraries = {};

  /// The JavaScript classes implemented via typed JavaScript interop.
  final Map<ClassEntity, String> _jsInteropClasses = {};

  /// JavaScript interop classes annotated with `@anonymous`.
  final Set<ClassEntity> _anonymousJsInteropClasses = {};

  /// JavaScript interop classes annotated with `@staticInterop`.
  final Set<ClassEntity> _staticInteropClasses = {};

  /// The JavaScript members implemented via typed JavaScript interop.
  final Map<MemberEntity, String> _jsInteropMembers = {};

  /// Sets the native tag info for [cls].
  ///
  /// The tag info string contains comma-separated 'words' which are either
  /// dispatch tags (having JavaScript identifier syntax) and directives that
  /// begin with `!`.
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
        _nativeClassTagInfo[cls] == null ||
            _nativeClassTagInfo[cls]!.text == tagText,
        failedAt(
            cls,
            "Native tag info set inconsistently on $cls: "
            "Existing tag info '${_nativeClassTagInfo[cls]}', "
            "new tag info '$tagText'."));
    _nativeClassTagInfo[cls] = NativeClassTag(tagText);
  }

  /// Marks [element] as an explicit part of js interop.
  ///
  /// If [name] is provided, it sets the explicit js interop name for the
  /// library [element], other the js interop name is expected to be computed
  /// later.
  void markAsJsInteropLibrary(LibraryEntity element, {required String name}) {
    assert(
        !_closed,
        failedAt(
            element,
            "NativeBasicDataBuilder is closed. "
            "Trying to mark $element as a js-interop library."));
    _jsInteropLibraries[element] = name;
  }

  /// Marks [element] as an explicit part of js interop.
  ///
  /// If [name] is provided, it sets the explicit js interop name for the
  /// class [element], other the js interop name is expected to be computed
  /// later.
  void markAsJsInteropClass(ClassEntity element,
      {required String name,
      required bool isAnonymous,
      required bool isStaticInterop}) {
    assert(
        !_closed,
        failedAt(
            element,
            "NativeBasicDataBuilder is closed. "
            "Trying to mark $element as a js-interop class."));
    _jsInteropClasses[element] = name;
    if (isAnonymous) {
      _anonymousJsInteropClasses.add(element);
    }
    if (isStaticInterop) {
      _staticInteropClasses.add(element);
    }
  }

  /// Marks [element] as an explicit part of js interop and sets the explicit js
  /// interop [name] for the member [element].
  void markAsJsInteropMember(MemberEntity element, String name) {
    assert(
        !_closed,
        failedAt(
            element,
            "NativeBasicDataBuilder is closed. "
            "Trying to mark $element as a js-interop member."));
    _jsInteropMembers[element] = name;
  }

  /// Creates the [NativeBasicData] object for the data collected in this
  /// builder.
  NativeBasicData close(ElementEnvironment environment) {
    _closed = true;
    return NativeBasicData(
        environment,
        false,
        _nativeClassTagInfo,
        _jsInteropLibraries,
        _jsInteropClasses,
        _anonymousJsInteropClasses,
        _staticInteropClasses,
        _jsInteropMembers);
  }

  void reopenForTesting() {
    _closed = false;
  }
}

/// Basic information for native classes and js-interop libraries and classes.
///
/// This information is computed during loading using [NativeBasicDataBuilder].
class NativeBasicData {
  /// Tag used for identifying serialized [NativeBasicData] objects in a
  /// debugging data stream.
  static const String tag = 'native-basic-data';

  final ElementEnvironment _env;

  bool _isAllowInteropUsed;

  /// Tag info for native JavaScript classes names. See
  /// [setNativeClassTagInfo].
  final Map<ClassEntity, NativeClassTag> _nativeClassTagInfo;

  /// The JavaScript libraries implemented via typed JavaScript interop.
  final Map<LibraryEntity, String> _jsInteropLibraries;

  /// The JavaScript classes implemented via typed JavaScript interop.
  final Map<ClassEntity, String> _jsInteropClasses;

  /// JavaScript interop classes annotated with `@anonymous`
  final Set<ClassEntity> _anonymousJsInteropClasses;

  /// JavaScript interop classes annotated with `@staticInterop`
  final Set<ClassEntity> _staticInteropClasses;

  /// The JavaScript members implemented via typed JavaScript interop.
  final Map<MemberEntity, String?> _jsInteropMembers;

  NativeBasicData(
      this._env,
      this._isAllowInteropUsed,
      this._nativeClassTagInfo,
      this._jsInteropLibraries,
      this._jsInteropClasses,
      this._anonymousJsInteropClasses,
      this._staticInteropClasses,
      this._jsInteropMembers);

  factory NativeBasicData.fromIr(
      KernelToElementMap map, IrAnnotationData data) {
    ElementEnvironment env = map.elementEnvironment;
    Map<ClassEntity, NativeClassTag> nativeClassTagInfo = {};
    Map<LibraryEntity, String> jsInteropLibraries = {};
    Map<ClassEntity, String> jsInteropClasses = {};
    Set<ClassEntity> anonymousJsInteropClasses = {};
    Set<ClassEntity> staticInteropClasses = {};
    Map<MemberEntity, String?> jsInteropMembers = {};

    data.forEachNativeClass((ir.Class node, String text) {
      nativeClassTagInfo[map.getClass(node)] = NativeClassTag(text);
    });
    data.forEachJsInteropLibrary((ir.Library node, String name) {
      jsInteropLibraries[env.lookupLibrary(node.importUri, required: true)!] =
          name;
    });
    data.forEachJsInteropClass((ir.Class node, String name,
        {required bool isAnonymous, required bool isStaticInterop}) {
      ClassEntity cls = map.getClass(node);
      jsInteropClasses[cls] = name;
      if (isAnonymous) {
        anonymousJsInteropClasses.add(cls);
      }
      if (isStaticInterop) {
        staticInteropClasses.add(cls);
      }
    });
    data.forEachJsInteropMember((ir.Member node, String? name) {
      // TODO(49428): Are there other members that we should ignore here?
      //  There are non-external and unannotated members because the source code
      //  doesn't contain them. (e.g. default constructor) Does it make sense to
      //  consider these valid JS members?
      if (memberIsIgnorable(node)) return;
      jsInteropMembers[map.getMember(node)] = name;
    });

    return NativeBasicData(
        env,
        false,
        nativeClassTagInfo,
        jsInteropLibraries,
        jsInteropClasses,
        anonymousJsInteropClasses,
        staticInteropClasses,
        jsInteropMembers);
  }

  /// Deserializes a [NativeBasicData] object from [source].
  factory NativeBasicData.readFromDataSource(
      DataSourceReader source, ElementEnvironment elementEnvironment) {
    source.begin(tag);
    bool isAllowInteropUsed = source.readBool();
    Map<ClassEntity, NativeClassTag> nativeClassTagInfo =
        source.readClassMap(() {
      final names = source.readStrings()!;
      bool isNonLeaf = source.readBool();
      return NativeClassTag.internal(names, isNonLeaf);
    });
    Map<LibraryEntity, String> jsInteropLibraries =
        source.readLibraryMap(source.readString);
    Map<ClassEntity, String> jsInteropClasses =
        source.readClassMap(source.readString);
    Set<ClassEntity> anonymousJsInteropClasses = source.readClasses().toSet();
    Set<ClassEntity> staticInteropClasses = source.readClasses().toSet();
    Map<MemberEntity, String?> jsInteropMembers = source
        .readMemberMap((MemberEntity member) => source.readStringOrNull());
    source.end(tag);
    return NativeBasicData(
        elementEnvironment,
        isAllowInteropUsed,
        nativeClassTagInfo,
        jsInteropLibraries,
        jsInteropClasses,
        anonymousJsInteropClasses,
        staticInteropClasses,
        jsInteropMembers);
  }

  /// Serializes this [NativeBasicData] to [sink].
  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeBool(isAllowInteropUsed);
    sink.writeClassMap(_nativeClassTagInfo, (NativeClassTag tag) {
      sink.writeStrings(tag.names);
      sink.writeBool(tag.isNonLeaf);
    });
    sink.writeLibraryMap(_jsInteropLibraries, sink.writeString);
    sink.writeClassMap(_jsInteropClasses, sink.writeString);
    sink.writeClasses(_anonymousJsInteropClasses);
    sink.writeClasses(_staticInteropClasses);
    sink.writeMemberMap(_jsInteropMembers,
        (MemberEntity member, String? name) => sink.writeStringOrNull(name));
    sink.end(tag);
  }

  /// Returns `true` if `allowInterop()` is invoked.
  bool get isAllowInteropUsed => _isAllowInteropUsed;

  /// Marks `allowInterop()` as used.
  ///
  /// [isAllowInteropUsed] is initially false on the closed world, and is only
  /// set during codegen enqueuing.
  void registerAllowInterop() {
    _isAllowInteropUsed = true;
  }

  /// Returns `true` if [cls] corresponds to a native JavaScript class.
  ///
  /// A class is marked as native either through the `@Native(...)` annotation
  /// allowed for internal libraries or via the typed JavaScriptInterop
  /// mechanism allowed for user libraries.
  bool isNativeClass(ClassEntity element) {
    if (isJsInteropClass(element)) return true;
    return _nativeClassTagInfo.containsKey(element);
  }

  /// Returns the list of non-directive native tag words for [cls].
  List<String> getNativeTagsOfClass(ClassEntity cls) {
    return _nativeClassTagInfo[cls]!.names;
  }

  /// Returns `true` if [cls] has a `!nonleaf` tag word.
  bool hasNativeTagsForcedNonLeaf(ClassEntity cls) {
    return _nativeClassTagInfo[cls]!.isNonLeaf;
  }

  /// Returns `true` if js interop features are used.
  bool get isJsInteropUsed =>
      _jsInteropLibraries.isNotEmpty || _jsInteropClasses.isNotEmpty;

  /// Returns `true` if [element] is a JsInterop library.
  bool isJsInteropLibrary(LibraryEntity element) {
    return _jsInteropLibraries.containsKey(element);
  }

  /// Returns `true` if [element] is a JsInterop class.
  bool isJsInteropClass(ClassEntity element) {
    return _jsInteropClasses.containsKey(element);
  }

  /// Returns `true` if [element] is explicitly marked as part of JsInterop.
  bool _isJsInteropMember(MemberEntity element) {
    return _jsInteropMembers.containsKey(element);
  }

  /// Returns `true` if [element] is a JsInterop member.
  bool isJsInteropMember(MemberEntity element) {
    // TODO(johnniwinther): Share this with [NativeData.isJsInteropMember].
    if (element.isFunction ||
        element is ConstructorEntity ||
        element.isGetter ||
        element.isSetter) {
      final function = element as FunctionEntity;
      if (!function.isExternal) return false;

      if (_isJsInteropMember(function)) return true;
      if (function.enclosingClass != null) {
        return isJsInteropClass(function.enclosingClass!);
      }
      if (function.isTopLevel) {
        return isJsInteropLibrary(function.library);
      }
      return false;
    } else {
      return _isJsInteropMember(element);
    }
  }

  /// Returns `true` if [element] or any of its superclasses is native. Supports
  /// nullable element for checks on nonexistent enclosing class of top-level
  /// functions.
  bool isNativeOrExtendsNative(ClassEntity? element) {
    if (element == null) return false;
    if (isNativeClass(element) || isJsInteropClass(element)) {
      return true;
    }
    return isNativeOrExtendsNative(_env.getSuperClass(element));
  }

  NativeBasicData convert(JsToFrontendMap map, ElementEnvironment environment) {
    Map<ClassEntity, NativeClassTag> nativeClassTagInfo =
        <ClassEntity, NativeClassTag>{};
    _nativeClassTagInfo.forEach((ClassEntity cls, NativeClassTag tag) {
      ClassEntity? backendClass = map.toBackendClass(cls);
      if (backendClass != null) {
        nativeClassTagInfo[backendClass] = tag;
      }
    });
    Map<LibraryEntity, String> jsInteropLibraries =
        map.toBackendLibraryMap(_jsInteropLibraries, identity);
    Map<ClassEntity, String> jsInteropClasses =
        map.toBackendClassMap(_jsInteropClasses, identity);
    Set<ClassEntity> anonymousJsInteropClasses =
        map.toBackendClassSet(_anonymousJsInteropClasses);
    Set<ClassEntity> staticInteropClasses =
        map.toBackendClassSet(_staticInteropClasses);
    Map<MemberEntity, String?> jsInteropMembers =
        map.toBackendMemberMap(_jsInteropMembers, identity);
    return NativeBasicData(
        environment,
        isAllowInteropUsed,
        nativeClassTagInfo,
        jsInteropLibraries,
        jsInteropClasses,
        anonymousJsInteropClasses,
        staticInteropClasses,
        jsInteropMembers);
  }
}

class NativeDataBuilder {
  final NativeBasicData _nativeBasicData;

  /// The JavaScript names for native JavaScript elements implemented.
  final Map<MemberEntity, String> _nativeMemberName = {};

  /// Cache for [NativeBehavior]s for calling native methods.
  final Map<FunctionEntity, NativeBehavior> _nativeMethodBehavior = {};

  /// Cache for [NativeBehavior]s for reading from native fields.
  final Map<MemberEntity, NativeBehavior> _nativeFieldLoadBehavior = {};

  /// Cache for [NativeBehavior]s for writing to native fields.
  final Map<MemberEntity, NativeBehavior> _nativeFieldStoreBehavior = {};

  NativeDataBuilder(this._nativeBasicData);

  /// Sets the native [name] for the member [element].
  ///
  /// This name is used for [element] in the generated JavaScript.
  void setNativeMemberName(MemberEntity element, String name) {
    // TODO(johnniwinther): Avoid setting this more than once. The enqueuer
    // might enqueue [element] several times (before processing it) and computes
    // name on each call to `internalAddToWorkList`.
    assert(
        _nativeMemberName[element] == null ||
            _nativeMemberName[element] == name,
        failedAt(
            element,
            "Native member name set inconsistently on $element: "
            "Existing name '${_nativeMemberName[element]}', "
            "new name '$name'."));
    _nativeMemberName[element] = name;
  }

  /// Registers the [behavior] for calling the native [method].
  void setNativeMethodBehavior(FunctionEntity method, NativeBehavior behavior) {
    _nativeMethodBehavior[method] = behavior;
  }

  /// Registers the [behavior] for reading from the native [field].
  void setNativeFieldLoadBehavior(FieldEntity field, NativeBehavior behavior) {
    _nativeFieldLoadBehavior[field] = behavior;
  }

  /// Registers the [behavior] for writing to the native [field].
  void setNativeFieldStoreBehavior(FieldEntity field, NativeBehavior behavior) {
    _nativeFieldStoreBehavior[field] = behavior;
  }

  /// Closes this builder and creates the resulting [NativeData] object.
  NativeData close() => NativeData(
      _nativeBasicData,
      _nativeMemberName,
      _nativeMethodBehavior,
      _nativeFieldLoadBehavior,
      _nativeFieldStoreBehavior);
}

/// Additional element information for native classes and methods and js-interop
/// methods.
///
/// This information is computed during resolution using [NativeDataBuilder].
// TODO(johnniwinther): Remove fields that overlap with [NativeBasicData], like
// [anonymousJsInteropClasses].
class NativeData implements NativeBasicData {
  /// Tag used for identifying serialized [NativeData] objects in a
  /// debugging data stream.
  static const String tag = 'native-data';

  /// Prefix used to escape JS names that are not valid Dart names
  /// when using JSInterop.
  static const String _jsInteropEscapePrefix = r'JS$';

  final NativeBasicData _nativeBasicData;

  /// The JavaScript names for native JavaScript elements implemented.
  final Map<MemberEntity, String> _nativeMemberName;

  /// Cache for [NativeBehavior]s for calling native methods.
  final Map<FunctionEntity, NativeBehavior> _nativeMethodBehavior;

  /// Cache for [NativeBehavior]s for reading from native fields.
  final Map<MemberEntity, NativeBehavior> _nativeFieldLoadBehavior;

  /// Cache for [NativeBehavior]s for writing to native fields.
  final Map<MemberEntity, NativeBehavior> _nativeFieldStoreBehavior;

  NativeData(
      this._nativeBasicData,
      this._nativeMemberName,
      this._nativeMethodBehavior,
      this._nativeFieldLoadBehavior,
      this._nativeFieldStoreBehavior);

  factory NativeData.fromIr(KernelToElementMap map, IrAnnotationData data) {
    NativeBasicData nativeBasicData = NativeBasicData.fromIr(map, data);
    Map<MemberEntity, String> nativeMemberName = {};
    Map<FunctionEntity, NativeBehavior> nativeMethodBehavior = {};
    Map<MemberEntity, NativeBehavior> nativeFieldLoadBehavior = {};
    Map<MemberEntity, NativeBehavior> nativeFieldStoreBehavior = {};

    data.forEachNativeMethodData((ir.Member node,
        String name,
        Iterable<String> createsAnnotations,
        Iterable<String> returnsAnnotations) {
      final member = map.getMember(node) as FunctionEntity;
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
      final field = map.getMember(node) as FieldEntity;
      nativeMemberName[field] = name;
      bool isJsInterop = nativeBasicData.isJsInteropMember(field);
      node as ir.Field;
      nativeFieldLoadBehavior[field] = map.getNativeBehaviorForFieldLoad(
          node, createsAnnotations, returnsAnnotations,
          isJsInterop: isJsInterop);
      nativeFieldStoreBehavior[field] =
          map.getNativeBehaviorForFieldStore(node);
    });

    return NativeData(nativeBasicData, nativeMemberName, nativeMethodBehavior,
        nativeFieldLoadBehavior, nativeFieldStoreBehavior);
  }

  /// Deserializes a [NativeData] object from [source].
  factory NativeData.readFromDataSource(
      DataSourceReader source, ElementEnvironment elementEnvironment) {
    source.begin(tag);
    NativeBasicData nativeBasicData =
        NativeBasicData.readFromDataSource(source, elementEnvironment);
    Map<MemberEntity, String> nativeMemberName =
        source.readMemberMap((MemberEntity member) => source.readString());
    Map<FunctionEntity, NativeBehavior> nativeMethodBehavior =
        source.readMemberMap(
            (MemberEntity member) => NativeBehavior.readFromDataSource(source));
    Map<MemberEntity, NativeBehavior> nativeFieldLoadBehavior =
        source.readMemberMap(
            (MemberEntity member) => NativeBehavior.readFromDataSource(source));
    Map<MemberEntity, NativeBehavior> nativeFieldStoreBehavior =
        source.readMemberMap(
            (MemberEntity member) => NativeBehavior.readFromDataSource(source));
    source.end(tag);
    return NativeData(nativeBasicData, nativeMemberName, nativeMethodBehavior,
        nativeFieldLoadBehavior, nativeFieldStoreBehavior);
  }

  /// Serializes this [NativeData] to [sink].
  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    _nativeBasicData.writeToDataSink(sink);

    sink.writeMemberMap(_nativeMemberName,
        (MemberEntity member, String name) => sink.writeString(name));

    sink.writeMemberMap(_nativeMethodBehavior,
        (MemberEntity member, NativeBehavior behavior) {
      behavior.writeToDataSink(sink);
    });

    sink.writeMemberMap(_nativeFieldLoadBehavior,
        (MemberEntity member, NativeBehavior behavior) {
      behavior.writeToDataSink(sink);
    });
    sink.writeMemberMap(_nativeFieldStoreBehavior,
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
  Map<LibraryEntity, String> get _jsInteropLibraries =>
      _nativeBasicData._jsInteropLibraries;

  @override
  Set<ClassEntity> get _anonymousJsInteropClasses =>
      _nativeBasicData._anonymousJsInteropClasses;

  @override
  Set<ClassEntity> get _staticInteropClasses =>
      _nativeBasicData._staticInteropClasses;

  @override
  Map<ClassEntity, String> get _jsInteropClasses =>
      _nativeBasicData._jsInteropClasses;

  @override
  Map<MemberEntity, String?> get _jsInteropMembers =>
      _nativeBasicData._jsInteropMembers;

  /// Returns `true` if [element] has an `@Anonymous` annotation.
  bool isAnonymousJsInteropClass(ClassEntity element) {
    return _anonymousJsInteropClasses.contains(element);
  }

  /// Returns `true` if [element] has an `@staticInterop` annotation.
  bool isStaticInteropClass(ClassEntity element) {
    return _staticInteropClasses.contains(element);
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
  bool isNativeOrExtendsNative(ClassEntity? element) =>
      _nativeBasicData.isNativeOrExtendsNative(element);

  /// Returns the explicit js interop name for library [element].
  String? getJsInteropLibraryName(LibraryEntity element) {
    return _jsInteropLibraries[element];
  }

  /// Returns the explicit js interop name for class [element].
  String? getJsInteropClassName(ClassEntity element) {
    return _jsInteropClasses[element];
  }

  /// Returns the explicit js interop name for member [element].
  String? getJsInteropMemberName(MemberEntity element) {
    return _jsInteropMembers[element];
  }

  @override
  bool _isJsInteropMember(MemberEntity element) {
    return _jsInteropMembers.containsKey(element);
  }

  @override
  bool isJsInteropMember(MemberEntity element) {
    if (element.isFunction ||
        element is ConstructorEntity ||
        element.isGetter ||
        element.isSetter) {
      final function = element as FunctionEntity;
      if (!function.isExternal) return false;

      if (_isJsInteropMember(function)) return true;
      if (function.enclosingClass != null) {
        return isJsInteropClass(function.enclosingClass!);
      }
      if (function.isTopLevel) {
        return isJsInteropLibrary(function.library);
      }
      return false;
    } else {
      return _isJsInteropMember(element);
    }
  }

  /// Returns `true` if the name of [element] is fixed for the generated
  /// JavaScript.
  bool hasFixedBackendName(MemberEntity element) {
    return isJsInteropMember(element) || _nativeMemberName.containsKey(element);
  }

  /// Computes the name for [element] to use in the generated JavaScript. This
  /// is either given through a native annotation or a js interop annotation.
  String? getFixedBackendName(MemberEntity element) {
    String? name = _nativeMemberName[element];
    if (name == null && isJsInteropMember(element)) {
      if (element is ConstructorEntity) {
        name = _jsClassNameHelper(element.enclosingClass);
      } else {
        name = _jsMemberNameHelper(element);
        // Top-level static JS interop members can be associated with a dotted
        // name, if so, fixedBackendName is the last segment.
        if (element.isTopLevel && name.contains('.')) {
          name = name.substring(name.lastIndexOf('.') + 1);
        }
      }
      _nativeMemberName[element] = name;
    }
    return name;
  }

  String _jsLibraryNameHelper(LibraryEntity element) {
    String? jsInteropName = getJsInteropLibraryName(element);
    if (jsInteropName != null && jsInteropName.isNotEmpty) return jsInteropName;
    return 'self';
  }

  String _jsClassNameHelper(ClassEntity element) {
    String? jsInteropName = getJsInteropClassName(element);
    if (jsInteropName != null && jsInteropName.isNotEmpty) return jsInteropName;
    return computeUnescapedJSInteropName(element.name);
  }

  String _jsMemberNameHelper(MemberEntity element) {
    String? jsInteropName = _jsInteropMembers[element];
    assert(
        !(_jsInteropMembers.containsKey(element) && jsInteropName == null),
        failedAt(
            element,
            'Member $element is js interop but js interop name has not yet '
            'been computed.'));
    if (jsInteropName != null && jsInteropName.isNotEmpty) {
      return jsInteropName;
    }
    return computeUnescapedJSInteropName(element.name!);
  }

  /// Returns a JavaScript path specifying the context in which
  /// [element.fixedBackendName] should be evaluated. Only applicable for
  /// elements using typed JavaScript interop.
  /// For example: fixedBackendPath for the static method createMap in the
  /// Map class of the goog.map JavaScript library would have path
  /// "goog.maps.Map".
  String? getFixedBackendMethodPath(FunctionEntity element) {
    if (!isJsInteropMember(element)) return null;
    if (element.isInstanceMember) return 'this';
    if (element is ConstructorEntity) {
      return _fixedBackendClassPath(element.enclosingClass);
    }
    StringBuffer sb = StringBuffer();
    sb.write(_jsLibraryNameHelper(element.library));
    if (element.enclosingClass != null) {
      sb
        ..write('.')
        ..write(_jsClassNameHelper(element.enclosingClass!));
    }

    // Top-level static JS interop members can be associated with a dotted
    // name, if so, fixedBackendPath includes all but the last segment.
    final name = _jsMemberNameHelper(element);
    if (element.isTopLevel && name.contains('.')) {
      sb
        ..write('.')
        ..write(name.substring(0, name.lastIndexOf('.')));
    }
    return sb.toString();
  }

  String? _fixedBackendClassPath(ClassEntity element) {
    if (!isJsInteropClass(element)) return null;
    return _jsLibraryNameHelper(element.library);
  }

  /// Returns `true` if [element] corresponds to a native JavaScript member.
  ///
  /// A member is marked as native either through the native mechanism
  /// (`@Native(...)` or the `native` pseudo keyword) allowed for internal
  /// libraries or via the typed JavaScriptInterop mechanism allowed for user
  /// libraries.
  bool isNativeMember(MemberEntity element) {
    if (isJsInteropMember(element)) return true;
    return _nativeMemberName.containsKey(element);
  }

  /// Returns the [NativeBehavior] for calling the native [method].
  NativeBehavior getNativeMethodBehavior(FunctionEntity method) {
    assert(
        _nativeMethodBehavior.containsKey(method),
        failedAt(method,
            "No native method behavior has been computed for $method."));
    return _nativeMethodBehavior[method]!;
  }

  /// Returns the [NativeBehavior] for reading from the native [field].
  NativeBehavior getNativeFieldLoadBehavior(FieldEntity field) {
    assert(
        _nativeFieldLoadBehavior.containsKey(field),
        failedAt(
            field,
            "No native field load behavior has been "
            "computed for $field."));
    return _nativeFieldLoadBehavior[field]!;
  }

  /// Returns the [NativeBehavior] for writing to the native [field].
  NativeBehavior getNativeFieldStoreBehavior(FieldEntity field) {
    assert(
        _nativeFieldStoreBehavior.containsKey(field),
        failedAt(field,
            "No native field store behavior has been computed for $field."));
    return _nativeFieldStoreBehavior[field]!;
  }

  /// Apply JS$ escaping scheme to convert possible escaped Dart names into
  /// JS names.
  String computeUnescapedJSInteropName(String name) {
    return name.startsWith(_jsInteropEscapePrefix)
        ? name.substring(_jsInteropEscapePrefix.length)
        : name;
  }

  @override
  Map<ClassEntity, NativeClassTag> get _nativeClassTagInfo =>
      _nativeBasicData._nativeClassTagInfo;

  @override
  ElementEnvironment get _env => _nativeBasicData._env;

  @override
  NativeData convert(JsToFrontendMap map, ElementEnvironment environment) {
    NativeBasicData nativeBasicData =
        _nativeBasicData.convert(map, environment);
    Map<MemberEntity, String> nativeMemberName =
        map.toBackendMemberMap(_nativeMemberName, identity);
    final nativeMethodBehavior = <FunctionEntity, NativeBehavior>{};
    _nativeMethodBehavior
        .forEach((FunctionEntity method, NativeBehavior behavior) {
      final backendMethod = map.toBackendMember(method) as FunctionEntity?;
      if (backendMethod != null) {
        // If [method] isn't used it doesn't have a corresponding backend
        // method.
        nativeMethodBehavior[backendMethod] = behavior.convert(map);
      }
    });
    NativeBehavior _convertNativeBehavior(NativeBehavior behavior) =>
        behavior.convert(map);
    Map<MemberEntity, NativeBehavior> nativeFieldLoadBehavior = map
        .toBackendMemberMap(_nativeFieldLoadBehavior, _convertNativeBehavior);
    Map<MemberEntity, NativeBehavior> nativeFieldStoreBehavior = map
        .toBackendMemberMap(_nativeFieldStoreBehavior, _convertNativeBehavior);
    return NativeData(nativeBasicData, nativeMemberName, nativeMethodBehavior,
        nativeFieldLoadBehavior, nativeFieldStoreBehavior);
  }
}

class NativeClassTag {
  final List<String> names;
  final bool isNonLeaf;

  factory NativeClassTag(String tagText) {
    List<String> tags = tagText.split(',');
    List<String> names = tags.where((s) => !s.startsWith('!')).toList();
    bool isNonLeaf = tags.contains('!nonleaf');
    return NativeClassTag.internal(names, isNonLeaf);
  }

  NativeClassTag.internal(this.names, this.isNonLeaf);

  String get text {
    StringBuffer sb = StringBuffer();
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
