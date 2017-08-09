// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.serialization;

import '../common/backend_api.dart' show BackendSerialization;
import '../elements/elements.dart';
import '../elements/resolution_types.dart';
import '../elements/types.dart';
import '../js/js.dart' as js;
import '../native/native.dart';
import '../resolution/resolution_strategy.dart';
import '../serialization/keys.dart';
import '../serialization/serialization.dart'
    show DeserializerPlugin, ObjectDecoder, ObjectEncoder, SerializerPlugin;
import '../universe/side_effects.dart';
import 'js_backend.dart';
import 'native_data.dart';

const String _BACKEND_DATA_TAG = 'jsBackendData';
const Key DART_TYPES_RETURNED = const Key('dartTypesReturned');
const Key THIS_TYPES_RETURNED = const Key('thisTypesReturned');
const Key SPECIAL_TYPES_RETURNED = const Key('specialTypesReturned');
const Key DART_TYPES_INSTANTIATED = const Key('dartTypesInstantiated');
const Key THIS_TYPES_INSTANTIATED = const Key('thisTypesInstantiated');
const Key SPECIAL_TYPES_INSTANTIATED = const Key('specialTypesInstantiated');
const Key CODE_TEMPLATE = const Key('codeTemplate');
const Key SIDE_EFFECTS = const Key('sideEffects');
const Key THROW_BEHAVIOR = const Key('throwBehavior');
const Key IS_ALLOCATION = const Key('isAllocation');
const Key USE_GVN = const Key('useGvn');

class JavaScriptBackendSerialization implements BackendSerialization {
  final JavaScriptBackendSerializer serializer;
  final JavaScriptBackendDeserializer deserializer;

  JavaScriptBackendSerialization(JavaScriptBackend backend)
      : serializer = new JavaScriptBackendSerializer(backend),
        deserializer = new JavaScriptBackendDeserializer(backend);
}

const Key JS_INTEROP_LIBRARY_NAME = const Key('jsInteropLibraryName');
const Key JS_INTEROP_CLASS_NAME = const Key('jsInteropClassName');
const Key JS_INTEROP_MEMBER_NAME = const Key('jsInteropMemberName');
const Key NATIVE_MEMBER_NAME = const Key('nativeMemberName');
const Key NATIVE_CLASS_TAG_INFO = const Key('nativeClassTagInfo');
const Key NATIVE_METHOD_BEHAVIOR = const Key('nativeMethodBehavior');
const Key NATIVE_FIELD_LOAD_BEHAVIOR = const Key('nativeFieldLoadBehavior');
const Key NATIVE_FIELD_STORE_BEHAVIOR = const Key('nativeFieldStoreBehavior');

class JavaScriptBackendSerializer implements SerializerPlugin {
  final JavaScriptBackend _backend;

  JavaScriptBackendSerializer(this._backend);

  NativeBasicDataImpl get nativeBasicData =>
      _backend.compiler.frontendStrategy.nativeBasicData;
  NativeDataBuilderImpl get nativeData => _backend.nativeDataBuilder;

  @override
  void onElement(Element element, ObjectEncoder createEncoder(String tag)) {
    ObjectEncoder encoder;
    ObjectEncoder getEncoder() {
      return encoder ??= createEncoder(_BACKEND_DATA_TAG);
    }

    String jsInteropLibraryName = nativeData.jsInteropLibraries[element];
    if (jsInteropLibraryName != null) {
      getEncoder().setString(JS_INTEROP_LIBRARY_NAME, jsInteropLibraryName);
    }
    String jsInteropClassName = nativeData.jsInteropClasses[element];
    if (jsInteropClassName != null) {
      getEncoder().setString(JS_INTEROP_CLASS_NAME, jsInteropClassName);
    }
    String jsInteropMemberName = nativeData.jsInteropMembers[element];
    if (jsInteropMemberName != null) {
      getEncoder().setString(JS_INTEROP_MEMBER_NAME, jsInteropMemberName);
    }
    String nativeMemberName = nativeData.nativeMemberName[element];
    if (nativeMemberName != null) {
      getEncoder().setString(NATIVE_MEMBER_NAME, nativeMemberName);
    }
    NativeClassTag nativeClassTagInfo =
        nativeBasicData.nativeClassTagInfo[element];
    if (nativeClassTagInfo != null) {
      getEncoder().setString(NATIVE_CLASS_TAG_INFO, nativeClassTagInfo.text);
    }
    NativeBehavior nativeMethodBehavior =
        nativeData.nativeMethodBehavior[element];
    if (nativeMethodBehavior != null) {
      NativeBehaviorSerialization.serializeNativeBehavior(nativeMethodBehavior,
          getEncoder().createObject(NATIVE_METHOD_BEHAVIOR));
    }
    NativeBehavior nativeFieldLoadBehavior =
        nativeData.nativeFieldLoadBehavior[element];
    if (nativeFieldLoadBehavior != null) {
      NativeBehaviorSerialization.serializeNativeBehavior(
          nativeFieldLoadBehavior,
          getEncoder().createObject(NATIVE_FIELD_LOAD_BEHAVIOR));
    }
    NativeBehavior nativeFieldStoreBehavior =
        nativeData.nativeFieldStoreBehavior[element];
    if (nativeFieldStoreBehavior != null) {
      NativeBehaviorSerialization.serializeNativeBehavior(
          nativeFieldStoreBehavior,
          getEncoder().createObject(NATIVE_FIELD_STORE_BEHAVIOR));
    }
  }

  @override
  void onData(covariant NativeBehavior behavior, ObjectEncoder encoder) {
    NativeBehaviorSerialization.serializeNativeBehavior(behavior, encoder);
  }
}

class JavaScriptBackendDeserializer implements DeserializerPlugin {
  final JavaScriptBackend _backend;

  JavaScriptBackendDeserializer(this._backend);

  NativeBasicDataBuilderImpl get nativeBasicData {
    ResolutionFrontEndStrategy frontendStrategy =
        _backend.compiler.frontendStrategy;
    return frontendStrategy.nativeBasicDataBuilder;
  }

  NativeDataBuilderImpl get nativeData => _backend.nativeDataBuilder;

  @override
  void onElement(Element element, ObjectDecoder getDecoder(String tag)) {
    ObjectDecoder decoder = getDecoder(_BACKEND_DATA_TAG);
    if (decoder != null) {
      if (element is LibraryElement) {
        String jsInteropLibraryName =
            decoder.getString(JS_INTEROP_LIBRARY_NAME, isOptional: true);
        if (jsInteropLibraryName != null) {
          nativeData.jsInteropLibraries[element] = jsInteropLibraryName;
        }
      } else if (element is ClassElement) {
        String jsInteropClassName =
            decoder.getString(JS_INTEROP_CLASS_NAME, isOptional: true);
        if (jsInteropClassName != null) {
          nativeData.jsInteropClasses[element] = jsInteropClassName;
        }
        String nativeClassTagInfo =
            decoder.getString(NATIVE_CLASS_TAG_INFO, isOptional: true);
        if (nativeClassTagInfo != null) {
          nativeBasicData.nativeClassTagInfo[element] =
              new NativeClassTag(nativeClassTagInfo);
        }
      } else if (element is MemberElement) {
        String jsInteropMemberName =
            decoder.getString(JS_INTEROP_MEMBER_NAME, isOptional: true);
        if (jsInteropMemberName != null) {
          nativeData.jsInteropMembers[element] = jsInteropMemberName;
        }
        String nativeMemberName =
            decoder.getString(NATIVE_MEMBER_NAME, isOptional: true);
        if (nativeMemberName != null) {
          nativeData.nativeMemberName[element] = nativeMemberName;
        }

        if (element is MethodElement) {
          ObjectDecoder nativeMethodBehavior =
              decoder.getObject(NATIVE_METHOD_BEHAVIOR, isOptional: true);
          if (nativeMethodBehavior != null) {
            nativeData.nativeMethodBehavior[element] =
                NativeBehaviorSerialization
                    .deserializeNativeBehavior(nativeMethodBehavior);
          }
        } else if (element is FieldElement) {
          ObjectDecoder nativeFieldLoadBehavior =
              decoder.getObject(NATIVE_FIELD_LOAD_BEHAVIOR, isOptional: true);
          if (nativeFieldLoadBehavior != null) {
            nativeData.nativeFieldLoadBehavior[element] =
                NativeBehaviorSerialization
                    .deserializeNativeBehavior(nativeFieldLoadBehavior);
          }
          ObjectDecoder nativeFieldStoreBehavior =
              decoder.getObject(NATIVE_FIELD_STORE_BEHAVIOR, isOptional: true);
          if (nativeFieldStoreBehavior != null) {
            nativeData.nativeFieldStoreBehavior[element] =
                NativeBehaviorSerialization
                    .deserializeNativeBehavior(nativeFieldStoreBehavior);
          }
        }
      }
    }
  }

  @override
  NativeBehavior onData(ObjectDecoder decoder) {
    return NativeBehaviorSerialization.deserializeNativeBehavior(decoder);
  }
}

class NativeBehaviorSerialization {
  static const int NORMAL_TYPE = 0;
  static const int THIS_TYPE = 1;
  static const int SPECIAL_TYPE = 2;

  static int getTypeKind(var type) {
    if (type is DartType) {
      // TODO(johnniwinther): Remove this when annotation are no longer resolved
      // to this-types.
      if (type is InterfaceType &&
          type.typeArguments.isNotEmpty &&
          type.typeArguments.first is TypeVariableType) {
        return THIS_TYPE;
      }
      return NORMAL_TYPE;
    }
    return SPECIAL_TYPE;
  }

  /// Returns a list of the non-this-type [ResolutionDartType]s in [types].
  static List<ResolutionDartType> filterDartTypes(List types) {
    return types.where((type) => getTypeKind(type) == NORMAL_TYPE).toList();
  }

  // TODO(johnniwinther): Remove this when annotation are no longer resolved
  // to this-types.
  /// Returns a list of the classes of this-types in [types].
  static List<Element> filterThisTypes(List types) {
    return types
        .where((type) => getTypeKind(type) == THIS_TYPE)
        .map((type) => type.element)
        .toList();
  }

  /// Returns a list of the names of the [SpecialType]s in [types].
  static List<String> filterSpecialTypes(List types) {
    return types
        .where((type) => getTypeKind(type) == SPECIAL_TYPE)
        .map((SpecialType type) => type.name)
        .toList();
  }

  static void serializeNativeBehavior(
      NativeBehavior behavior, ObjectEncoder encoder) {
    encoder.setTypes(
        DART_TYPES_RETURNED, filterDartTypes(behavior.typesReturned));
    encoder.setElements(
        THIS_TYPES_RETURNED, filterThisTypes(behavior.typesReturned));
    encoder.setStrings(
        SPECIAL_TYPES_RETURNED, filterSpecialTypes(behavior.typesReturned));

    encoder.setTypes(
        DART_TYPES_INSTANTIATED, filterDartTypes(behavior.typesInstantiated));
    encoder.setElements(
        THIS_TYPES_INSTANTIATED, filterThisTypes(behavior.typesInstantiated));
    encoder.setStrings(SPECIAL_TYPES_INSTANTIATED,
        filterSpecialTypes(behavior.typesInstantiated));

    if (behavior.codeTemplateText != null) {
      encoder.setString(CODE_TEMPLATE, behavior.codeTemplateText);
    }

    encoder.setInt(SIDE_EFFECTS, behavior.sideEffects.flags);
    encoder.setEnum(THROW_BEHAVIOR, behavior.throwBehavior);
    encoder.setBool(IS_ALLOCATION, behavior.isAllocation);
    encoder.setBool(USE_GVN, behavior.useGvn);
  }

  static NativeBehavior deserializeNativeBehavior(ObjectDecoder decoder) {
    SideEffects sideEffects =
        new SideEffects.fromFlags(decoder.getInt(SIDE_EFFECTS));
    NativeBehavior behavior = new NativeBehavior.internal(sideEffects);

    behavior.typesReturned
        .addAll(decoder.getTypes(DART_TYPES_RETURNED, isOptional: true));
    behavior.typesReturned.addAll(decoder
        .getElements(THIS_TYPES_RETURNED, isOptional: true)
        .map((dynamic element) => element.thisType)
        .toList());
    behavior.typesReturned.addAll(decoder
        .getStrings(SPECIAL_TYPES_RETURNED, isOptional: true)
        .map(SpecialType.fromName));

    behavior.typesInstantiated
        .addAll(decoder.getTypes(DART_TYPES_INSTANTIATED, isOptional: true));
    behavior.typesInstantiated.addAll(decoder
        .getElements(THIS_TYPES_INSTANTIATED, isOptional: true)
        .map((dynamic element) => element.thisType)
        .toList());
    behavior.typesInstantiated.addAll(decoder
        .getStrings(SPECIAL_TYPES_INSTANTIATED, isOptional: true)
        .map(SpecialType.fromName));

    behavior.codeTemplateText =
        decoder.getString(CODE_TEMPLATE, isOptional: true);
    if (behavior.codeTemplateText != null) {
      behavior.codeTemplate = js.js.parseForeignJS(behavior.codeTemplateText);
    }

    behavior.throwBehavior =
        decoder.getEnum(THROW_BEHAVIOR, NativeThrowBehavior.values);
    behavior.isAllocation = decoder.getBool(IS_ALLOCATION);
    behavior.useGvn = decoder.getBool(USE_GVN);
    return behavior;
  }
}
