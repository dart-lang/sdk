// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/binary/binary_reader.dart';
import 'package:analyzer/src/binary/binary_writer.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/inference_error.dart';
import 'package:analyzer/src/fine/lookup_name.dart';
import 'package:analyzer/src/fine/manifest_ast.dart';
import 'package:analyzer/src/fine/manifest_context.dart';
import 'package:analyzer/src/fine/manifest_id.dart';
import 'package:analyzer/src/fine/manifest_type.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

class ClassItem extends InterfaceItem<ClassElementImpl> {
  ClassItem({
    required super.id,
    required _ClassItemFlags super.flags,
    required super.metadata,
    required super.typeParameters,
    required super.declaredConflicts,
    required super.declaredFields,
    required super.declaredGetters,
    required super.declaredSetters,
    required super.declaredMethods,
    required super.declaredConstructors,
    required super.inheritedConstructors,
    required super.hasNonFinalField,
    required super.supertype,
    required super.mixins,
    required super.interfaces,
    required super.interface,
  });

  factory ClassItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required ClassElementImpl element,
  }) {
    return context.withTypeParameters(element.typeParameters, (typeParameters) {
      return ClassItem(
        id: id,
        flags: _ClassItemFlags.encode(element),
        metadata: ManifestMetadata.encode(context, element.metadata),
        typeParameters: typeParameters,
        declaredConflicts: {},
        declaredFields: {},
        declaredGetters: {},
        declaredSetters: {},
        declaredMethods: {},
        declaredConstructors: {},
        inheritedConstructors: {},
        hasNonFinalField: element.hasNonFinalField,
        supertype: element.supertype?.encode(context),
        mixins: element.mixins.encode(context),
        interfaces: element.interfaces.encode(context),
        interface: ManifestInterface.empty(),
      );
    });
  }

  factory ClassItem.read(SummaryDataReader reader) {
    return ClassItem(
      id: ManifestItemId.read(reader),
      flags: _ClassItemFlags.read(reader),
      metadata: ManifestMetadata.read(reader),
      typeParameters: ManifestTypeParameter.readList(reader),
      declaredConflicts: reader.readLookupNameToIdMap(),
      declaredFields: FieldItem.readMap(reader),
      declaredGetters: GetterItem.readMap(reader),
      declaredSetters: SetterItem.readMap(reader),
      declaredMethods: MethodItem.readMap(reader),
      declaredConstructors: ConstructorItem.readMap(reader),
      inheritedConstructors: reader.readLookupNameToIdMap(),
      hasNonFinalField: reader.readBool(),
      supertype: ManifestType.readOptional(reader),
      mixins: ManifestType.readList(reader),
      interfaces: ManifestType.readList(reader),
      interface: ManifestInterface.read(reader),
    );
  }

  @override
  _ClassItemFlags get flags => super.flags as _ClassItemFlags;

  @override
  bool match(MatchContext context, ClassElementImpl element) {
    return super.match(context, element) &&
        flags.isAbstract == element.isAbstract &&
        flags.isBase == element.isBase &&
        flags.isFinal == element.isFinal &&
        flags.isInterface == element.isInterface &&
        flags.isMixinApplication == element.isMixinApplication &&
        flags.isMixinClass == element.isMixinClass &&
        flags.isSealed == element.isSealed;
  }
}

class ConstructorItem extends ExecutableItem<ConstructorElementImpl> {
  final List<ManifestNode> constantInitializers;
  final ManifestElement? redirectedConstructor;
  final ManifestElement? superConstructor;

  ConstructorItem({
    required super.id,
    required _ConstructorItemFlags super.flags,
    required super.metadata,
    required super.functionType,
    required this.constantInitializers,
    required this.redirectedConstructor,
    required this.superConstructor,
  });

  factory ConstructorItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required ConstructorElementImpl element,
  }) {
    return context.withFormalParameters(element.formalParameters, () {
      return ConstructorItem(
        id: id,
        flags: _ConstructorItemFlags.encode(element),
        metadata: ManifestMetadata.encode(context, element.metadata),
        functionType: element.type.encode(context),
        constantInitializers: element.constantInitializers
            .map((initializer) => ManifestNode.encode(context, initializer))
            .toFixedList(),
        redirectedConstructor: ManifestElement.encodeOptional(
          context,
          element.redirectedConstructor,
        ),
        superConstructor: ManifestElement.encodeOptional(
          context,
          element.superConstructor,
        ),
      );
    });
  }

  factory ConstructorItem.read(SummaryDataReader reader) {
    return ConstructorItem(
      id: ManifestItemId.read(reader),
      flags: _ConstructorItemFlags.read(reader),
      metadata: ManifestMetadata.read(reader),
      functionType: ManifestFunctionType.read(reader),
      constantInitializers: ManifestNode.readList(reader),
      redirectedConstructor: ManifestElement.readOptional(reader),
      superConstructor: ManifestElement.readOptional(reader),
    );
  }

  @override
  _ConstructorItemFlags get flags => super.flags as _ConstructorItemFlags;

  @override
  bool match(MatchContext context, ConstructorElementImpl element) {
    return context.withFormalParameters(element.formalParameters, () {
      return super.match(context, element) &&
          flags.isConst == element.isConst &&
          flags.isFactory == element.isFactory &&
          constantInitializers.match(context, element.constantInitializers) &&
          redirectedConstructor.match(context, element.redirectedConstructor) &&
          superConstructor.match(context, element.superConstructor);
    });
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    constantInitializers.writeList(sink);
    redirectedConstructor.writeOptional(sink);
    superConstructor.writeOptional(sink);
  }

  static Map<LookupName, ConstructorItem> readMap(SummaryDataReader reader) {
    return reader.readMap(
      readKey: () => LookupName.read(reader),
      readValue: () => ConstructorItem.read(reader),
    );
  }
}

class EnumItem extends InterfaceItem<EnumElementImpl> {
  EnumItem({
    required super.id,
    required super.flags,
    required super.metadata,
    required super.typeParameters,
    required super.declaredConflicts,
    required super.declaredFields,
    required super.declaredGetters,
    required super.declaredSetters,
    required super.declaredMethods,
    required super.declaredConstructors,
    required super.inheritedConstructors,
    required super.hasNonFinalField,
    required super.interface,
    required super.supertype,
    required super.mixins,
    required super.interfaces,
  });

  factory EnumItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required EnumElementImpl element,
  }) {
    return context.withTypeParameters(element.typeParameters, (typeParameters) {
      return EnumItem(
        id: id,
        flags: _InterfaceItemFlags.encode(element),
        metadata: ManifestMetadata.encode(context, element.metadata),
        typeParameters: typeParameters,
        declaredConflicts: {},
        declaredFields: {},
        declaredGetters: {},
        declaredSetters: {},
        declaredMethods: {},
        declaredConstructors: {},
        inheritedConstructors: {},
        hasNonFinalField: element.hasNonFinalField,
        interface: ManifestInterface.empty(),
        supertype: element.supertype?.encode(context),
        mixins: element.mixins.encode(context),
        interfaces: element.interfaces.encode(context),
      );
    });
  }

  factory EnumItem.read(SummaryDataReader reader) {
    return EnumItem(
      id: ManifestItemId.read(reader),
      flags: _InterfaceItemFlags.read(reader),
      metadata: ManifestMetadata.read(reader),
      typeParameters: ManifestTypeParameter.readList(reader),
      declaredConflicts: reader.readLookupNameToIdMap(),
      declaredFields: FieldItem.readMap(reader),
      declaredGetters: GetterItem.readMap(reader),
      declaredSetters: SetterItem.readMap(reader),
      declaredMethods: MethodItem.readMap(reader),
      declaredConstructors: ConstructorItem.readMap(reader),
      inheritedConstructors: reader.readLookupNameToIdMap(),
      hasNonFinalField: reader.readBool(),
      supertype: ManifestType.readOptional(reader),
      mixins: ManifestType.readList(reader),
      interfaces: ManifestType.readList(reader),
      interface: ManifestInterface.read(reader),
    );
  }
}

sealed class ExecutableItem<E extends ExecutableElementImpl>
    extends ManifestItem<E> {
  final ManifestFunctionType functionType;

  ExecutableItem({
    required super.id,
    required _ExecutableItemFlags super.flags,
    required super.metadata,
    required this.functionType,
  });

  @override
  _ExecutableItemFlags get flags => super.flags as _ExecutableItemFlags;

  @override
  bool match(MatchContext context, E element) {
    return super.match(context, element) &&
        flags.hasEnclosingTypeParameterReference ==
            element.hasEnclosingTypeParameterReference &&
        flags.hasImplicitReturnType == element.hasImplicitReturnType &&
        flags.invokesSuperSelf == element.invokesSuperSelf &&
        flags.isAbstract == element.isAbstract &&
        flags.isExtensionTypeMember == element.isExtensionTypeMember &&
        flags.isExternal == element.isExternal &&
        flags.isSimplyBounded == element.isSimplyBounded &&
        flags.isStatic == element.isStatic &&
        functionType.match(context, element.type);
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    functionType.writeNoTag(sink);
  }
}

/// The item for [ExtensionElementImpl].
class ExtensionItem<E extends ExtensionElementImpl> extends InstanceItem<E> {
  final ManifestType extendedType;

  ExtensionItem({
    required super.id,
    required super.flags,
    required super.metadata,
    required super.typeParameters,
    required super.declaredConflicts,
    required super.declaredFields,
    required super.declaredGetters,
    required super.declaredSetters,
    required super.declaredMethods,
    required super.declaredConstructors,
    required super.inheritedConstructors,
    required this.extendedType,
  });

  factory ExtensionItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required ExtensionElementImpl element,
  }) {
    return context.withTypeParameters(element.typeParameters, (typeParameters) {
      return ExtensionItem(
        id: id,
        flags: _InstanceItemFlags.encode(element),
        metadata: ManifestMetadata.encode(context, element.metadata),
        typeParameters: typeParameters,
        declaredConflicts: {},
        declaredFields: {},
        declaredGetters: {},
        declaredSetters: {},
        declaredMethods: {},
        declaredConstructors: {},
        inheritedConstructors: {},
        extendedType: element.extendedType.encode(context),
      );
    });
  }

  factory ExtensionItem.read(SummaryDataReader reader) {
    return ExtensionItem(
      id: ManifestItemId.read(reader),
      flags: _InstanceItemFlags.read(reader),
      metadata: ManifestMetadata.read(reader),
      typeParameters: ManifestTypeParameter.readList(reader),
      declaredConflicts: reader.readLookupNameToIdMap(),
      declaredFields: FieldItem.readMap(reader),
      declaredGetters: GetterItem.readMap(reader),
      declaredSetters: SetterItem.readMap(reader),
      declaredMethods: MethodItem.readMap(reader),
      declaredConstructors: ConstructorItem.readMap(reader),
      inheritedConstructors: reader.readLookupNameToIdMap(),
      extendedType: ManifestType.read(reader),
    );
  }

  @override
  bool match(MatchContext context, E element) {
    return super.match(context, element) &&
        extendedType.match(context, element.extendedType);
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    extendedType.write(sink);
  }
}

class ExtensionTypeItem extends InterfaceItem<ExtensionTypeElementImpl> {
  final ManifestType representationType;
  final ManifestType typeErasure;

  ExtensionTypeItem({
    required super.id,
    required _ExtensionTypeItemFlags super.flags,
    required super.metadata,
    required super.typeParameters,
    required super.declaredConflicts,
    required super.declaredFields,
    required super.declaredGetters,
    required super.declaredSetters,
    required super.declaredMethods,
    required super.declaredConstructors,
    required super.inheritedConstructors,
    required super.hasNonFinalField,
    required super.interface,
    required super.supertype,
    required super.mixins,
    required super.interfaces,
    required this.representationType,
    required this.typeErasure,
  });

  factory ExtensionTypeItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required ExtensionTypeElementImpl element,
  }) {
    return context.withTypeParameters(element.typeParameters, (typeParameters) {
      return ExtensionTypeItem(
        id: id,
        flags: _ExtensionTypeItemFlags.encode(element),
        metadata: ManifestMetadata.encode(context, element.metadata),
        typeParameters: typeParameters,
        declaredConflicts: {},
        declaredFields: {},
        declaredGetters: {},
        declaredSetters: {},
        declaredMethods: {},
        declaredConstructors: {},
        inheritedConstructors: {},
        hasNonFinalField: element.hasNonFinalField,
        interface: ManifestInterface.empty(),
        supertype: element.supertype?.encode(context),
        mixins: element.mixins.encode(context),
        interfaces: element.interfaces.encode(context),
        representationType: element.representation.type.encode(context),
        typeErasure: element.typeErasure.encode(context),
      );
    });
  }

  factory ExtensionTypeItem.read(SummaryDataReader reader) {
    return ExtensionTypeItem(
      id: ManifestItemId.read(reader),
      flags: _ExtensionTypeItemFlags.read(reader),
      metadata: ManifestMetadata.read(reader),
      typeParameters: ManifestTypeParameter.readList(reader),
      declaredConflicts: reader.readLookupNameToIdMap(),
      declaredFields: FieldItem.readMap(reader),
      declaredGetters: GetterItem.readMap(reader),
      declaredSetters: SetterItem.readMap(reader),
      declaredMethods: MethodItem.readMap(reader),
      declaredConstructors: ConstructorItem.readMap(reader),
      inheritedConstructors: reader.readLookupNameToIdMap(),
      hasNonFinalField: reader.readBool(),
      supertype: ManifestType.readOptional(reader),
      mixins: ManifestType.readList(reader),
      interfaces: ManifestType.readList(reader),
      interface: ManifestInterface.read(reader),
      representationType: ManifestType.read(reader),
      typeErasure: ManifestType.read(reader),
    );
  }

  @override
  _ExtensionTypeItemFlags get flags => super.flags as _ExtensionTypeItemFlags;

  @override
  bool match(MatchContext context, ExtensionTypeElementImpl element) {
    return super.match(context, element) &&
        flags.hasImplementsSelfReference ==
            element.hasImplementsSelfReference &&
        flags.hasRepresentationSelfReference ==
            element.hasRepresentationSelfReference &&
        representationType.match(context, element.representation.type) &&
        typeErasure.match(context, element.typeErasure);
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    representationType.write(sink);
    typeErasure.write(sink);
  }
}

class FieldItem extends VariableItem<FieldElementImpl> {
  FieldItem({
    required super.id,
    required _FieldItemFlags super.flags,
    required super.metadata,
    required super.type,
    required super.constInitializer,
  });

  factory FieldItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required FieldElementImpl element,
  }) {
    return FieldItem(
      id: id,
      flags: _FieldItemFlags.encode(element),
      metadata: ManifestMetadata.encode(context, element.metadata),
      type: element.type.encode(context),
      constInitializer: element.constantInitializer?.encode(context),
    );
  }

  factory FieldItem.read(SummaryDataReader reader) {
    return FieldItem(
      id: ManifestItemId.read(reader),
      flags: _FieldItemFlags.read(reader),
      metadata: ManifestMetadata.read(reader),
      type: ManifestType.read(reader),
      constInitializer: ManifestNode.readOptional(reader),
    );
  }

  @override
  _FieldItemFlags get flags => super.flags as _FieldItemFlags;

  @override
  bool match(MatchContext context, FieldElementImpl element) {
    return super.match(context, element) &&
        flags.hasEnclosingTypeParameterReference ==
            element.hasEnclosingTypeParameterReference &&
        flags.isAbstract == element.isAbstract &&
        flags.isCovariant == element.isCovariant &&
        flags.isEnumConstant == element.isEnumConstant &&
        flags.isExternal == element.isExternal &&
        flags.isPromotable == element.isPromotable;
  }

  static Map<LookupName, FieldItem> readMap(SummaryDataReader reader) {
    return reader.readMap(
      readKey: () => LookupName.read(reader),
      readValue: () => FieldItem.read(reader),
    );
  }
}

class GetterItem extends ExecutableItem<GetterElementImpl> {
  GetterItem({
    required super.id,
    required super.flags,
    required super.metadata,
    required super.functionType,
  });

  factory GetterItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required GetterElementImpl element,
  }) {
    return GetterItem(
      id: id,
      flags: _ExecutableItemFlags.encode(element),
      metadata: ManifestMetadata.encode(
        context,
        element.thisOrVariableMetadata,
      ),
      functionType: element.type.encode(context),
    );
  }

  factory GetterItem.read(SummaryDataReader reader) {
    return GetterItem(
      id: ManifestItemId.read(reader),
      flags: _ExecutableItemFlags.read(reader),
      metadata: ManifestMetadata.read(reader),
      functionType: ManifestFunctionType.read(reader),
    );
  }

  static Map<LookupName, GetterItem> readMap(SummaryDataReader reader) {
    return reader.readMap(
      readKey: () => LookupName.read(reader),
      readValue: () => GetterItem.read(reader),
    );
  }
}

/// The item for [InstanceElementImpl].
sealed class InstanceItem<E extends InstanceElementImpl>
    extends ManifestItem<E> {
  final List<ManifestTypeParameter> typeParameters;

  /// The names of duplicate or otherwise conflicting members.
  /// Such names will not be added to `declaredXyz` maps.
  Map<LookupName, ManifestItemId> declaredConflicts;

  Map<LookupName, FieldItem> declaredFields;
  Map<LookupName, GetterItem> declaredGetters;
  Map<LookupName, SetterItem> declaredSetters;
  Map<LookupName, MethodItem> declaredMethods;
  Map<LookupName, ConstructorItem> declaredConstructors;
  Map<LookupName, ManifestItemId> inheritedConstructors;

  InstanceItem({
    required super.id,
    required _InstanceItemFlags super.flags,
    required super.metadata,
    required this.typeParameters,
    required this.declaredConflicts,
    required this.declaredFields,
    required this.declaredGetters,
    required this.declaredSetters,
    required this.declaredMethods,
    required this.declaredConstructors,
    required this.inheritedConstructors,
  });

  @override
  _InstanceItemFlags get flags => super.flags as _InstanceItemFlags;

  void addDeclaredConstructor(LookupName lookupName, ConstructorItem item) {
    if (declaredConflicts.containsKey(lookupName)) {
      return;
    }

    var hasConflict = () {
      // Constructors conflict with constructors.
      if (declaredConstructors.containsKey(lookupName)) {
        return true;
      }
      // Constructors conflict with static properties and methods.
      return declaredGetters[lookupName]?.flags.isStatic ??
          declaredSetters[lookupName]?.flags.isStatic ??
          declaredMethods[lookupName]?.flags.isStatic ??
          false;
    }();
    if (hasConflict) {
      _makeNameConflict(lookupName);
      return;
    }

    declaredConstructors[lookupName] = item;
  }

  void addDeclaredGetter(LookupName lookupName, GetterItem item) {
    if (declaredConflicts.containsKey(lookupName)) {
      return;
    }

    var hasConflict = () {
      // Getters conflict with methods and getters.
      if (declaredGetters.containsKey(lookupName) ||
          declaredMethods.containsKey(lookupName)) {
        return true;
      }
      // Static getters conflict with constructors.
      if (item.flags.isStatic && declaredConstructors.containsKey(lookupName)) {
        return true;
      }
      // Instance / static getters conflict with static / instance setter.
      var lookupNameSetter = '${lookupName.asString}='.asLookupName;
      if (declaredSetters[lookupNameSetter] case var setter?) {
        if (setter.flags.isStatic != item.flags.isStatic) {
          return true;
        }
      }
      return false;
    }();
    if (hasConflict) {
      _makeNameConflict(lookupName);
      return;
    }

    declaredGetters[lookupName] = item;
  }

  void addDeclaredMethod(LookupName lookupName, MethodItem item) {
    if (declaredConflicts.containsKey(lookupName)) {
      return;
    }

    var hasConflict = () {
      // Methods conflict with methods and properties.
      if (declaredGetters.containsKey(lookupName) ||
          declaredSetters.containsKey(lookupName.methodToSetter) ||
          declaredMethods.containsKey(lookupName)) {
        return true;
      }
      // Static methods conflict with constructors.
      if (item.flags.isStatic && declaredConstructors.containsKey(lookupName)) {
        return true;
      }
      return false;
    }();
    if (hasConflict) {
      _makeNameConflict(lookupName);
      return;
    }

    declaredMethods[lookupName] = item;
  }

  void addDeclaredSetter(LookupName lookupName, SetterItem item) {
    if (declaredConflicts.containsKey(lookupName)) {
      return;
    }

    var hasConflict = () {
      var lookupNameGetter = lookupName.setterToGetter;
      // Setters conflict with setters and methods.
      if (declaredSetters.containsKey(lookupName) ||
          declaredMethods.containsKey(lookupNameGetter)) {
        return true;
      }
      // Static setters conflict with constructors.
      if (item.flags.isStatic &&
          declaredConstructors.containsKey(lookupNameGetter)) {
        return true;
      }
      // Instance / static setters conflict with static / instance getter.
      if (declaredGetters[lookupNameGetter] case var getter?) {
        if (getter.flags.isStatic != item.flags.isStatic) {
          return true;
        }
      }
      return false;
    }();
    if (hasConflict) {
      _makeNameConflict(lookupName);
      return;
    }

    declaredSetters[lookupName] = item;
  }

  void addInheritedConstructor(LookupName lookupName, ManifestItemId id) {
    // Inherited constructors exist only for class type aliases.
    // So, not conflicts checking it required.
    inheritedConstructors[lookupName] = id;
  }

  void beforeUpdatingMembers() {
    declaredConflicts = {};
    declaredFields = {};
    declaredGetters = {};
    declaredSetters = {};
    declaredMethods = {};
    declaredConstructors = {};
    inheritedConstructors = {};
  }

  ManifestItemId? getConstructorId(LookupName name) {
    return declaredConstructors[name]?.id ??
        inheritedConstructors[name] ??
        declaredConflicts[name];
  }

  ManifestItemId? getDeclaredFieldId(LookupName name) {
    return declaredFields[name]?.id ?? declaredConflicts[name];
  }

  ManifestItemId? getDeclaredGetterId(LookupName name) {
    return declaredGetters[name]?.id ?? declaredConflicts[name];
  }

  ManifestItemId? getDeclaredMethodId(LookupName name) {
    return declaredMethods[name]?.id ?? declaredConflicts[name];
  }

  ManifestItemId? getDeclaredSetterId(LookupName name) {
    return declaredSetters[name]?.id ?? declaredConflicts[name];
  }

  @override
  bool match(MatchContext context, E element) {
    context.addTypeParameters(element.typeParameters);
    return super.match(context, element) &&
        typeParameters.match(context, element.typeParameters) &&
        flags.isSimplyBounded == element.isSimplyBounded;
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    typeParameters.write(sink);
    declaredConflicts.write(sink);
    declaredFields.write(sink);
    declaredGetters.write(sink);
    declaredSetters.write(sink);
    declaredMethods.write(sink);
    declaredConstructors.write(sink);
    inheritedConstructors.write(sink);
  }

  void _makeNameConflict(LookupName lookupName2) {
    var id = ManifestItemId.generate();
    for (var lookupName in lookupName2.relatedNames) {
      declaredConflicts[lookupName] = id;
      declaredFields.remove(lookupName);
      declaredGetters.remove(lookupName);
      declaredSetters.remove(lookupName);
      declaredMethods.remove(lookupName);
      declaredConstructors.remove(lookupName);
      inheritedConstructors.remove(lookupName);
    }
  }
}

/// The item for [InterfaceElementImpl].
sealed class InterfaceItem<E extends InterfaceElementImpl>
    extends InstanceItem<E> {
  bool hasNonFinalField;
  final ManifestType? supertype;
  final List<ManifestType> interfaces;
  final List<ManifestType> mixins;
  final ManifestInterface interface;

  InterfaceItem({
    required super.id,
    required _InterfaceItemFlags super.flags,
    required super.metadata,
    required super.typeParameters,
    required super.declaredConflicts,
    required super.declaredFields,
    required super.declaredGetters,
    required super.declaredSetters,
    required super.declaredMethods,
    required super.declaredConstructors,
    required super.inheritedConstructors,
    required this.hasNonFinalField,
    required this.supertype,
    required this.mixins,
    required this.interfaces,
    required this.interface,
  });

  @override
  _InterfaceItemFlags get flags => super.flags as _InterfaceItemFlags;

  ManifestItemId? getImplementedMethodId(LookupName name) {
    return interface.implemented[name];
  }

  ManifestItemId? getInterfaceMethodId(LookupName name) {
    return interface.map[name];
  }

  ManifestItemId? getSuperImplementedMethodId(int index, LookupName name) {
    if (index < interface.superImplemented.length) {
      return interface.superImplemented[index][name];
    } else {
      return null;
    }
  }

  /// Intentionally omits [hasNonFinalField], which is tracked as a separate
  /// requirement.
  @override
  bool match(MatchContext context, E element) {
    return super.match(context, element) &&
        supertype.match(context, element.supertype) &&
        interfaces.match(context, element.interfaces) &&
        mixins.match(context, element.mixins);
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    sink.writeBool(hasNonFinalField);
    supertype.writeOptional(sink);
    mixins.writeList(sink);
    interfaces.writeList(sink);
    interface.write(sink);
  }
}

class LibraryMetadataItem extends ManifestItem<LibraryElementImpl> {
  LibraryMetadataItem({
    required super.id,
    required super.flags,
    required super.metadata,
  });

  factory LibraryMetadataItem.empty() {
    return LibraryMetadataItem(
      id: ManifestItemId.generate(),
      flags: _ManifestItemFlags.empty(),
      metadata: ManifestMetadata(annotations: []),
    );
  }

  factory LibraryMetadataItem.encode({
    required ManifestItemId id,
    required EncodeContext context,
    required MetadataImpl metadata,
  }) {
    return LibraryMetadataItem(
      id: id,
      flags: _ManifestItemFlags.empty(),
      metadata: ManifestMetadata.encode(context, metadata),
    );
  }

  factory LibraryMetadataItem.read(SummaryDataReader reader) {
    return LibraryMetadataItem(
      id: ManifestItemId.read(reader),
      flags: _ManifestItemFlags.read(reader),
      metadata: ManifestMetadata.read(reader),
    );
  }

  bool get isEmpty => metadata.annotations.isEmpty;
}

class ManifestAnnotation {
  final ManifestNode ast;

  ManifestAnnotation({required this.ast});

  factory ManifestAnnotation.read(SummaryDataReader reader) {
    return ManifestAnnotation(ast: ManifestNode.read(reader));
  }

  bool match(MatchContext context, ElementAnnotationImpl annotation) {
    return ast.match(context, annotation.annotationAst);
  }

  void write(BufferedSink sink) {
    ast.write(sink);
  }

  static ManifestAnnotation encode(
    EncodeContext context,
    ElementAnnotationImpl annotation,
  ) {
    return ManifestAnnotation(
      ast: ManifestNode.encode(context, annotation.annotationAst),
    );
  }
}

/// Manifest version of `Interface` computed by `InheritanceManager`.
///
/// We store only IDs of the interface members, but not type substitutions,
/// because in order to invoke any of these members, you need an instance
/// of the class for this [InterfaceItem]. And any code that can give such
/// instance will reference the class name, directly as a type annotation, or
/// indirectly by invoking a function that references the class as a return
/// type. So, any such code depends on the header of the class, so includes
/// the type arguments for the class that declares the inherited member.
class ManifestInterface {
  /// The ID of the interface, stays the same if all information in the
  /// interface is the same.
  ManifestItemId id;

  /// The map of names to their IDs in the interface.
  Map<LookupName, ManifestItemId> map;
  Map<LookupName, ManifestItemId> implemented;
  List<Map<LookupName, ManifestItemId>> superImplemented;
  Map<LookupName, ManifestItemId> inherited;

  /// We move [map] into here during building the manifest, so that we can
  /// compare after building, and decide if [id] should be updated.
  Map<LookupName, ManifestItemId> mapPrevious = {};
  Map<LookupName, ManifestItemId> implementedPrevious = {};
  List<Map<LookupName, ManifestItemId>> superImplementedPrevious = [];
  Map<LookupName, ManifestItemId> inheritedPrevious = {};

  /// Key: IDs of method declarations.
  /// Value: ID assigned last time.
  /// When the same signatures merge, the result is the same.
  Map<ManifestItemIdList, ManifestItemId> combinedIds = {};

  /// We move [combinedIds] into here during building the manifest, so that
  /// we can fill [combinedIds] with new entries.
  Map<ManifestItemIdList, ManifestItemId> combinedIdsTemp = {};

  ManifestInterface({
    required this.id,
    required this.map,
    required this.implemented,
    required this.superImplemented,
    required this.inherited,
    required this.combinedIds,
  });

  factory ManifestInterface.empty() {
    return ManifestInterface(
      id: ManifestItemId.generate(),
      map: {},
      implemented: {},
      superImplemented: [],
      inherited: {},
      combinedIds: {},
    );
  }

  factory ManifestInterface.read(SummaryDataReader reader) {
    return ManifestInterface(
      id: ManifestItemId.read(reader),
      map: reader.readLookupNameToIdMap(),
      implemented: reader.readLookupNameToIdMap(),
      superImplemented: reader.readTypedList(() {
        return reader.readLookupNameToIdMap();
      }),
      inherited: reader.readLookupNameToIdMap(),
      combinedIds: reader.readMap(
        readKey: () => ManifestItemIdList.read(reader),
        readValue: () => ManifestItemId.read(reader),
      ),
    );
  }

  void afterUpdate() {
    const mapEquality = MapEquality<LookupName, ManifestItemId>();
    const listEquality = ListEquality<Map<LookupName, ManifestItemId>>(
      MapEquality<LookupName, ManifestItemId>(),
    );
    if (!mapEquality.equals(map, mapPrevious) ||
        !mapEquality.equals(implemented, implementedPrevious) ||
        !listEquality.equals(superImplemented, superImplementedPrevious) ||
        !mapEquality.equals(inherited, inheritedPrevious)) {
      id = ManifestItemId.generate();
    }
    mapPrevious = {};
    implementedPrevious = {};
    superImplementedPrevious = [];
    inheritedPrevious = {};
    combinedIdsTemp = {};
  }

  void beforeUpdating() {
    mapPrevious = map;
    map = {};

    implementedPrevious = implemented;
    implemented = {};

    superImplementedPrevious = superImplemented;
    superImplemented = [];

    inheritedPrevious = inherited;
    inherited = {};

    combinedIdsTemp = combinedIds;
    combinedIds = {};
  }

  void write(BufferedSink sink) {
    id.write(sink);
    map.write(sink);
    implemented.write(sink);
    sink.writeList(superImplemented, (map) => map.write(sink));
    inherited.write(sink);
    sink.writeMap(
      combinedIds,
      writeKey: (key) => key.write(sink),
      writeValue: (id) => id.write(sink),
    );
  }
}

sealed class ManifestItem<E extends ElementImpl> {
  /// The unique identifier of this item.
  final ManifestItemId id;
  final _ManifestItemFlags flags;
  final ManifestMetadata metadata;

  ManifestItem({required this.id, required this.flags, required this.metadata});

  @mustCallSuper
  bool match(MatchContext context, E element) {
    return flags.isSynthetic == element.isSynthetic &&
        metadata.match(context, element.effectiveMetadata);
  }

  @mustCallSuper
  void write(BufferedSink sink) {
    id.write(sink);
    flags.write(sink);
    metadata.write(sink);
  }
}

class ManifestLibraryLanguageVersion {
  final Version packageVersion;
  final Version? overrideVersion;

  ManifestLibraryLanguageVersion({
    required this.packageVersion,
    required this.overrideVersion,
  });

  ManifestLibraryLanguageVersion.empty()
    : packageVersion = Version.none,
      overrideVersion = null;

  factory ManifestLibraryLanguageVersion.encode(
    LibraryLanguageVersion languageVersion,
  ) {
    return ManifestLibraryLanguageVersion(
      packageVersion: languageVersion.package,
      overrideVersion: languageVersion.override,
    );
  }

  factory ManifestLibraryLanguageVersion.read(SummaryDataReader reader) {
    return ManifestLibraryLanguageVersion(
      packageVersion: _readVersion(reader),
      overrideVersion: reader.readOptionalObject(() => _readVersion(reader)),
    );
  }

  @override
  int get hashCode {
    return Object.hash(packageVersion, overrideVersion);
  }

  @override
  bool operator ==(Object other) {
    return other is ManifestLibraryLanguageVersion &&
        packageVersion == other.packageVersion &&
        overrideVersion == other.overrideVersion;
  }

  @override
  String toString() {
    var result = '(package: $packageVersion';
    if (overrideVersion case var overrideVersion?) {
      result += ', override: $overrideVersion';
    }
    result += ')';
    return result;
  }

  void write(BufferedSink sink) {
    _writeVersion(sink, packageVersion);
    sink.writeOptionalObject(overrideVersion, (it) => _writeVersion(sink, it));
  }

  static ManifestLibraryLanguageVersion? readOptional(
    SummaryDataReader reader,
  ) {
    return reader.readOptionalObject(
      () => ManifestLibraryLanguageVersion.read(reader),
    );
  }

  static Version _readVersion(SummaryDataReader reader) {
    var major = reader.readUint30();
    var minor = reader.readUint30();
    return Version(major, minor, 0);
  }

  static void _writeVersion(BufferedSink sink, Version version) {
    sink.writeUint30(version.major);
    sink.writeUint30(version.minor);
  }
}

class ManifestMetadata {
  final List<ManifestAnnotation> annotations;

  ManifestMetadata({required this.annotations});

  factory ManifestMetadata.encode(
    EncodeContext context,
    MetadataImpl metadata,
  ) {
    return ManifestMetadata(
      annotations: metadata.annotations.map((annotation) {
        return ManifestAnnotation.encode(context, annotation);
      }).toFixedList(),
    );
  }

  factory ManifestMetadata.read(SummaryDataReader reader) {
    return ManifestMetadata(
      annotations: reader.readTypedList(() {
        return ManifestAnnotation.read(reader);
      }),
    );
  }

  bool match(MatchContext context, MetadataImpl metadata) {
    var metadataAnnotations = metadata.annotations;
    if (annotations.length != metadataAnnotations.length) {
      return false;
    }

    for (var i = 0; i < metadataAnnotations.length; i++) {
      if (!annotations[i].match(context, metadataAnnotations[i])) {
        return false;
      }
    }

    return true;
  }

  void write(BufferedSink sink) {
    sink.writeList(annotations, (x) => x.write(sink));
  }
}

class MethodItem extends ExecutableItem<MethodElementImpl> {
  final TopLevelInferenceError? typeInferenceError;

  MethodItem({
    required super.id,
    required _MethodItemFlags super.flags,
    required super.metadata,
    required super.functionType,
    required this.typeInferenceError,
  });

  factory MethodItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required MethodElementImpl element,
  }) {
    return MethodItem(
      id: id,
      flags: _MethodItemFlags.encode(element),
      metadata: ManifestMetadata.encode(context, element.metadata),
      functionType: element.type.encode(context),
      typeInferenceError: element.typeInferenceError,
    );
  }

  factory MethodItem.read(SummaryDataReader reader) {
    return MethodItem(
      id: ManifestItemId.read(reader),
      flags: _MethodItemFlags.read(reader),
      metadata: ManifestMetadata.read(reader),
      functionType: ManifestFunctionType.read(reader),
      typeInferenceError: TopLevelInferenceError.readOptional(reader),
    );
  }

  @override
  _MethodItemFlags get flags => super.flags as _MethodItemFlags;

  @override
  bool match(MatchContext context, MethodElementImpl element) {
    return super.match(context, element) &&
        flags.isOperatorEqualWithParameterTypeFromObject ==
            element.isOperatorEqualWithParameterTypeFromObject &&
        typeInferenceError == element.typeInferenceError;
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    typeInferenceError.writeOptional(sink);
  }

  static Map<LookupName, MethodItem> readMap(SummaryDataReader reader) {
    return reader.readMap(
      readKey: () => LookupName.read(reader),
      readValue: () => MethodItem.read(reader),
    );
  }
}

class MixinItem extends InterfaceItem<MixinElementImpl> {
  final List<ManifestType> superclassConstraints;
  final List<LookupName> superInvokedNames;

  MixinItem({
    required super.id,
    required _MixinItemFlags super.flags,
    required super.metadata,
    required super.typeParameters,
    required super.supertype,
    required super.interfaces,
    required super.mixins,
    required super.declaredConflicts,
    required super.declaredFields,
    required super.declaredMethods,
    required super.declaredGetters,
    required super.declaredSetters,
    required super.declaredConstructors,
    required super.inheritedConstructors,
    required super.hasNonFinalField,
    required super.interface,
    required this.superclassConstraints,
    required this.superInvokedNames,
  }) : assert(supertype == null),
       assert(mixins.isEmpty),
       assert(superclassConstraints.isNotEmpty);

  factory MixinItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required MixinElementImpl element,
  }) {
    return context.withTypeParameters(element.typeParameters, (typeParameters) {
      return MixinItem(
        id: id,
        flags: _MixinItemFlags.encode(element),
        metadata: ManifestMetadata.encode(context, element.metadata),
        typeParameters: typeParameters,
        declaredConflicts: {},
        declaredFields: {},
        declaredGetters: {},
        declaredSetters: {},
        declaredMethods: {},
        declaredConstructors: {},
        inheritedConstructors: {},
        hasNonFinalField: element.hasNonFinalField,
        interface: ManifestInterface.empty(),
        supertype: element.supertype?.encode(context),
        mixins: element.mixins.encode(context),
        interfaces: element.interfaces.encode(context),
        superclassConstraints: element.superclassConstraints.encode(context),
        superInvokedNames: element.superInvokedNames
            .map((name) => name.asLookupName)
            .toFixedList(),
      );
    });
  }

  factory MixinItem.read(SummaryDataReader reader) {
    return MixinItem(
      id: ManifestItemId.read(reader),
      flags: _MixinItemFlags.read(reader),
      metadata: ManifestMetadata.read(reader),
      typeParameters: ManifestTypeParameter.readList(reader),
      declaredConflicts: reader.readLookupNameToIdMap(),
      declaredFields: FieldItem.readMap(reader),
      declaredGetters: GetterItem.readMap(reader),
      declaredSetters: SetterItem.readMap(reader),
      declaredMethods: MethodItem.readMap(reader),
      declaredConstructors: ConstructorItem.readMap(reader),
      inheritedConstructors: reader.readLookupNameToIdMap(),
      hasNonFinalField: reader.readBool(),
      supertype: ManifestType.readOptional(reader),
      mixins: ManifestType.readList(reader),
      interfaces: ManifestType.readList(reader),
      interface: ManifestInterface.read(reader),
      superclassConstraints: ManifestType.readList(reader),
      superInvokedNames: reader.readLookupNameList(),
    );
  }

  @override
  _MixinItemFlags get flags => super.flags as _MixinItemFlags;

  @override
  bool match(MatchContext context, MixinElementImpl element) {
    return super.match(context, element) &&
        flags.isBase == element.isBase &&
        superclassConstraints.match(context, element.superclassConstraints) &&
        const IterableEquality<String>().equals(
          superInvokedNames.map((lookupName) => lookupName.asString),
          element.superInvokedNames,
        );
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    superclassConstraints.writeList(sink);
    superInvokedNames.write(sink);
  }
}

class SetterItem extends ExecutableItem<SetterElementImpl> {
  SetterItem({
    required super.id,
    required super.flags,
    required super.metadata,
    required super.functionType,
  });

  factory SetterItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required SetterElementImpl element,
  }) {
    return SetterItem(
      id: id,
      flags: _ExecutableItemFlags.encode(element),
      metadata: ManifestMetadata.encode(
        context,
        element.thisOrVariableMetadata,
      ),
      functionType: element.type.encode(context),
    );
  }

  factory SetterItem.read(SummaryDataReader reader) {
    return SetterItem(
      id: ManifestItemId.read(reader),
      flags: _ExecutableItemFlags.read(reader),
      metadata: ManifestMetadata.read(reader),
      functionType: ManifestFunctionType.read(reader),
    );
  }

  static Map<LookupName, SetterItem> readMap(SummaryDataReader reader) {
    return reader.readMap(
      readKey: () => LookupName.read(reader),
      readValue: () => SetterItem.read(reader),
    );
  }
}

class TopLevelFunctionItem extends ExecutableItem<TopLevelFunctionElementImpl> {
  TopLevelFunctionItem({
    required super.id,
    required super.flags,
    required super.metadata,
    required super.functionType,
  });

  factory TopLevelFunctionItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required TopLevelFunctionElementImpl element,
  }) {
    return TopLevelFunctionItem(
      id: id,
      flags: _ExecutableItemFlags.encode(element),
      metadata: ManifestMetadata.encode(context, element.metadata),
      functionType: element.type.encode(context),
    );
  }

  factory TopLevelFunctionItem.read(SummaryDataReader reader) {
    return TopLevelFunctionItem(
      id: ManifestItemId.read(reader),
      flags: _ExecutableItemFlags.read(reader),
      metadata: ManifestMetadata.read(reader),
      functionType: ManifestFunctionType.read(reader),
    );
  }
}

class TopLevelVariableItem extends VariableItem<TopLevelVariableElementImpl> {
  TopLevelVariableItem({
    required super.id,
    required _TopLevelVariableItemFlags super.flags,
    required super.metadata,
    required super.type,
    required super.constInitializer,
  });

  factory TopLevelVariableItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required TopLevelVariableElementImpl element,
  }) {
    return TopLevelVariableItem(
      id: id,
      flags: _TopLevelVariableItemFlags.encode(element),
      metadata: ManifestMetadata.encode(context, element.metadata),
      type: element.type.encode(context),
      constInitializer: element.constantInitializer?.encode(context),
    );
  }

  factory TopLevelVariableItem.read(SummaryDataReader reader) {
    return TopLevelVariableItem(
      id: ManifestItemId.read(reader),
      flags: _TopLevelVariableItemFlags.read(reader),
      metadata: ManifestMetadata.read(reader),
      type: ManifestType.read(reader),
      constInitializer: ManifestNode.readOptional(reader),
    );
  }

  @override
  _TopLevelVariableItemFlags get flags =>
      super.flags as _TopLevelVariableItemFlags;

  @override
  bool match(MatchContext context, TopLevelVariableElementImpl element) {
    return super.match(context, element) &&
        flags.isExternal == element.isExternal;
  }
}

class TypeAliasItem extends ManifestItem<TypeAliasElementImpl> {
  final List<ManifestTypeParameter> typeParameters;
  final ManifestType aliasedType;

  TypeAliasItem({
    required super.id,
    required _TypeAliasItemFlags super.flags,
    required super.metadata,
    required this.typeParameters,
    required this.aliasedType,
  });

  factory TypeAliasItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required TypeAliasElementImpl element,
  }) {
    return context.withTypeParameters(element.typeParameters, (typeParameters) {
      return TypeAliasItem(
        id: id,
        flags: _TypeAliasItemFlags.encode(element),
        metadata: ManifestMetadata.encode(context, element.metadata),
        typeParameters: typeParameters,
        aliasedType: element.aliasedType.encode(context),
      );
    });
  }

  factory TypeAliasItem.read(SummaryDataReader reader) {
    return TypeAliasItem(
      id: ManifestItemId.read(reader),
      flags: _TypeAliasItemFlags.read(reader),
      metadata: ManifestMetadata.read(reader),
      typeParameters: ManifestTypeParameter.readList(reader),
      aliasedType: ManifestType.read(reader),
    );
  }

  @override
  _TypeAliasItemFlags get flags => super.flags as _TypeAliasItemFlags;

  @override
  bool match(MatchContext context, TypeAliasElementImpl element) {
    context.addTypeParameters(element.typeParameters);
    return super.match(context, element) &&
        flags.isSimplyBounded == element.isSimplyBounded &&
        flags.isProperRename == element.isProperRename &&
        typeParameters.match(context, element.typeParameters) &&
        aliasedType.match(context, element.aliasedType);
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    typeParameters.write(sink);
    aliasedType.write(sink);
  }
}

sealed class VariableItem<E extends PropertyInducingElementImpl>
    extends ManifestItem<E> {
  final ManifestType type;
  final ManifestNode? constInitializer;

  VariableItem({
    required super.id,
    required _VariableItemFlags super.flags,
    required super.metadata,
    required this.type,
    required this.constInitializer,
  });

  @override
  _VariableItemFlags get flags => super.flags as _VariableItemFlags;

  @override
  bool match(MatchContext context, E element) {
    return super.match(context, element) &&
        flags.hasInitializer == element.hasInitializer &&
        flags.hasImplicitType == element.hasImplicitType &&
        flags.isConst == element.isConst &&
        flags.isFinal == element.isFinal &&
        flags.isLate == element.isLate &&
        flags.isStatic == element.isStatic &&
        flags.shouldUseTypeForInitializerInference ==
            element.shouldUseTypeForInitializerInference &&
        type.match(context, element.type) &&
        constInitializer.match(context, element.constantInitializer);
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    type.write(sink);
    constInitializer.writeOptional(sink);
  }
}

enum _ClassItemFlag {
  isAbstract,
  isBase,
  isFinal,
  isInterface,
  isMixinApplication,
  isMixinClass,
  isSealed,
}

enum _ConstructorItemFlag { isConst, isFactory }

enum _ExecutableItemFlag {
  hasEnclosingTypeParameterReference,
  hasImplicitReturnType,
  invokesSuperSelf,
  isAbstract,
  isExtensionTypeMember,
  isExternal,
  isSimplyBounded,
  isStatic,
}

enum _ExtensionTypeItemFlag {
  hasImplementsSelfReference,
  hasRepresentationSelfReference,
}

enum _FieldItemFlag {
  hasEnclosingTypeParameterReference,
  isAbstract,
  isCovariant,
  isEnumConstant,
  isExternal,
  isPromotable,
}

enum _InstanceItemFlag { isSimplyBounded }

enum _InterfaceItemFlag { reserved }

enum _ManifestItemFlag { isSynthetic }

enum _MethodItemFlag { isOperatorEqualWithParameterTypeFromObject }

enum _MixinItemFlag { isBase }

enum _TopLevelVariableItemFlag { isExternal }

enum _TypeAliasItemFlag { isProperRename, isSimplyBounded }

enum _VariableItemFlag {
  hasInitializer,
  hasImplicitType,
  isConst,
  isFinal,
  isLate,
  isStatic,
  shouldUseTypeForInitializerInference,
}

extension type _ClassItemFlags._(int _bits) implements _InterfaceItemFlags {
  static final int _base = _InterfaceItemFlags._next;

  factory _ClassItemFlags.encode(ClassElementImpl element) {
    var bits = _InterfaceItemFlags.encode(element)._bits;
    if (element.isAbstract) {
      bits |= _maskFor(_ClassItemFlag.isAbstract);
    }
    if (element.isBase) {
      bits |= _maskFor(_ClassItemFlag.isBase);
    }
    if (element.isFinal) {
      bits |= _maskFor(_ClassItemFlag.isFinal);
    }
    if (element.isInterface) {
      bits |= _maskFor(_ClassItemFlag.isInterface);
    }
    if (element.isMixinApplication) {
      bits |= _maskFor(_ClassItemFlag.isMixinApplication);
    }
    if (element.isMixinClass) {
      bits |= _maskFor(_ClassItemFlag.isMixinClass);
    }
    if (element.isSealed) {
      bits |= _maskFor(_ClassItemFlag.isSealed);
    }
    return _ClassItemFlags._(bits);
  }

  factory _ClassItemFlags.read(SummaryDataReader reader) {
    return _ClassItemFlags._(reader.readUint30());
  }

  bool get isAbstract {
    return _has(_ClassItemFlag.isAbstract);
  }

  bool get isBase {
    return _has(_ClassItemFlag.isBase);
  }

  bool get isFinal {
    return _has(_ClassItemFlag.isFinal);
  }

  bool get isInterface {
    return _has(_ClassItemFlag.isInterface);
  }

  bool get isMixinApplication {
    return _has(_ClassItemFlag.isMixinApplication);
  }

  bool get isMixinClass {
    return _has(_ClassItemFlag.isMixinClass);
  }

  bool get isSealed {
    return _has(_ClassItemFlag.isSealed);
  }

  void write(BufferedSink sink) {
    sink.writeUint30(_bits);
  }

  bool _has(_ClassItemFlag flag) {
    return (_bits & _maskFor(flag)) != 0;
  }

  static int _maskFor(_ClassItemFlag flag) {
    var bit = _base + flag.index;
    assert(bit < 30);
    return 1 << bit;
  }
}

extension type _ConstructorItemFlags._(int _bits)
    implements _ExecutableItemFlags {
  static final int _base = _ExecutableItemFlags._next;

  factory _ConstructorItemFlags.encode(ConstructorElementImpl element) {
    var bits = _ExecutableItemFlags.encode(element)._bits;
    if (element.isConst) {
      bits |= _maskFor(_ConstructorItemFlag.isConst);
    }
    if (element.isFactory) {
      bits |= _maskFor(_ConstructorItemFlag.isFactory);
    }
    return _ConstructorItemFlags._(bits);
  }

  factory _ConstructorItemFlags.read(SummaryDataReader reader) {
    return _ConstructorItemFlags._(reader.readUint30());
  }

  bool get isConst {
    return _has(_ConstructorItemFlag.isConst);
  }

  bool get isFactory {
    return _has(_ConstructorItemFlag.isFactory);
  }

  void write(BufferedSink sink) {
    sink.writeUint30(_bits);
  }

  bool _has(_ConstructorItemFlag flag) {
    return (_bits & _maskFor(flag)) != 0;
  }

  static int _maskFor(_ConstructorItemFlag flag) {
    var bit = _base + flag.index;
    assert(bit < 30);
    return 1 << bit;
  }
}

extension type _ExecutableItemFlags._(int _bits) implements _ManifestItemFlags {
  static final int _base = _ManifestItemFlags._next;
  static final int _next = _base + _ExecutableItemFlag.values.length;

  factory _ExecutableItemFlags.encode(ExecutableElementImpl element) {
    var bits = _ManifestItemFlags.encode(element)._bits;
    if (element.hasEnclosingTypeParameterReference) {
      bits |= _maskFor(_ExecutableItemFlag.hasEnclosingTypeParameterReference);
    }
    if (element.hasImplicitReturnType) {
      bits |= _maskFor(_ExecutableItemFlag.hasImplicitReturnType);
    }
    if (element.invokesSuperSelf) {
      bits |= _maskFor(_ExecutableItemFlag.invokesSuperSelf);
    }
    if (element.isAbstract) {
      bits |= _maskFor(_ExecutableItemFlag.isAbstract);
    }
    if (element.isExtensionTypeMember) {
      bits |= _maskFor(_ExecutableItemFlag.isExtensionTypeMember);
    }
    if (element.isExternal) {
      bits |= _maskFor(_ExecutableItemFlag.isExternal);
    }
    if (element.isSimplyBounded) {
      bits |= _maskFor(_ExecutableItemFlag.isSimplyBounded);
    }
    if (element.isStatic) {
      bits |= _maskFor(_ExecutableItemFlag.isStatic);
    }
    return _ExecutableItemFlags._(bits);
  }

  factory _ExecutableItemFlags.read(SummaryDataReader reader) {
    return _ExecutableItemFlags._(reader.readUint30());
  }

  bool get hasEnclosingTypeParameterReference {
    return _has(_ExecutableItemFlag.hasEnclosingTypeParameterReference);
  }

  bool get hasImplicitReturnType {
    return _has(_ExecutableItemFlag.hasImplicitReturnType);
  }

  bool get invokesSuperSelf {
    return _has(_ExecutableItemFlag.invokesSuperSelf);
  }

  bool get isAbstract {
    return _has(_ExecutableItemFlag.isAbstract);
  }

  bool get isExtensionTypeMember {
    return _has(_ExecutableItemFlag.isExtensionTypeMember);
  }

  bool get isExternal {
    return _has(_ExecutableItemFlag.isExternal);
  }

  bool get isSimplyBounded {
    return _has(_ExecutableItemFlag.isSimplyBounded);
  }

  bool get isStatic {
    return _has(_ExecutableItemFlag.isStatic);
  }

  void write(BufferedSink sink) {
    sink.writeUint30(_bits);
  }

  bool _has(_ExecutableItemFlag flag) {
    return (_bits & _maskFor(flag)) != 0;
  }

  static int _maskFor(_ExecutableItemFlag flag) {
    var bit = _base + flag.index;
    assert(bit < 30);
    return 1 << bit;
  }
}

extension type _ExtensionTypeItemFlags._(int _bits)
    implements _InterfaceItemFlags {
  static final int _base = _InterfaceItemFlags._next;

  factory _ExtensionTypeItemFlags.encode(ExtensionTypeElementImpl element) {
    var bits = _InterfaceItemFlags.encode(element)._bits;
    if (element.hasImplementsSelfReference) {
      bits |= _maskFor(_ExtensionTypeItemFlag.hasImplementsSelfReference);
    }
    if (element.hasRepresentationSelfReference) {
      bits |= _maskFor(_ExtensionTypeItemFlag.hasRepresentationSelfReference);
    }
    return _ExtensionTypeItemFlags._(bits);
  }

  factory _ExtensionTypeItemFlags.read(SummaryDataReader reader) {
    return _ExtensionTypeItemFlags._(reader.readUint30());
  }

  bool get hasImplementsSelfReference {
    return _has(_ExtensionTypeItemFlag.hasImplementsSelfReference);
  }

  bool get hasRepresentationSelfReference {
    return _has(_ExtensionTypeItemFlag.hasRepresentationSelfReference);
  }

  void write(BufferedSink sink) {
    sink.writeUint30(_bits);
  }

  bool _has(_ExtensionTypeItemFlag flag) {
    return (_bits & _maskFor(flag)) != 0;
  }

  static int _maskFor(_ExtensionTypeItemFlag flag) {
    var bit = _base + flag.index;
    assert(bit < 30);
    return 1 << bit;
  }
}

extension type _FieldItemFlags._(int _bits) implements _VariableItemFlags {
  static final int _base = _VariableItemFlags._next;

  factory _FieldItemFlags.encode(FieldElementImpl element) {
    var bits = _VariableItemFlags.encode(element)._bits;
    if (element.hasEnclosingTypeParameterReference) {
      bits |= _maskFor(_FieldItemFlag.hasEnclosingTypeParameterReference);
    }
    if (element.isAbstract) {
      bits |= _maskFor(_FieldItemFlag.isAbstract);
    }
    if (element.isCovariant) {
      bits |= _maskFor(_FieldItemFlag.isCovariant);
    }
    if (element.isEnumConstant) {
      bits |= _maskFor(_FieldItemFlag.isEnumConstant);
    }
    if (element.isExternal) {
      bits |= _maskFor(_FieldItemFlag.isExternal);
    }
    if (element.isPromotable) {
      bits |= _maskFor(_FieldItemFlag.isPromotable);
    }
    return _FieldItemFlags._(bits);
  }

  factory _FieldItemFlags.read(SummaryDataReader reader) {
    return _FieldItemFlags._(reader.readUint30());
  }

  bool get hasEnclosingTypeParameterReference {
    return _has(_FieldItemFlag.hasEnclosingTypeParameterReference);
  }

  bool get isAbstract {
    return _has(_FieldItemFlag.isAbstract);
  }

  bool get isCovariant {
    return _has(_FieldItemFlag.isCovariant);
  }

  bool get isEnumConstant {
    return _has(_FieldItemFlag.isEnumConstant);
  }

  bool get isExternal {
    return _has(_FieldItemFlag.isExternal);
  }

  bool get isPromotable {
    return _has(_FieldItemFlag.isPromotable);
  }

  void write(BufferedSink sink) {
    sink.writeUint30(_bits);
  }

  bool _has(_FieldItemFlag flag) {
    return (_bits & _maskFor(flag)) != 0;
  }

  static int _maskFor(_FieldItemFlag flag) {
    var bit = _base + flag.index;
    assert(bit < 30);
    return 1 << bit;
  }
}

extension type _InstanceItemFlags._(int _bits) implements _ManifestItemFlags {
  static final int _base = _ManifestItemFlags._next;
  static final int _next = _base + _InstanceItemFlag.values.length;

  factory _InstanceItemFlags.encode(InstanceElementImpl element) {
    var bits = _ManifestItemFlags.encode(element)._bits;
    if (element.isSimplyBounded) {
      bits |= _maskFor(_InstanceItemFlag.isSimplyBounded);
    }
    return _InstanceItemFlags._(bits);
  }

  factory _InstanceItemFlags.read(SummaryDataReader reader) {
    return _InstanceItemFlags._(reader.readUint30());
  }

  bool get isSimplyBounded {
    return _has(_InstanceItemFlag.isSimplyBounded);
  }

  void write(BufferedSink sink) {
    sink.writeUint30(_bits);
  }

  bool _has(_InstanceItemFlag flag) {
    return (_bits & _maskFor(flag)) != 0;
  }

  static int _maskFor(_InstanceItemFlag flag) {
    var bit = _base + flag.index;
    assert(bit < 30);
    return 1 << bit;
  }
}

extension type _InterfaceItemFlags._(int _bits) implements _InstanceItemFlags {
  static final int _base = _InstanceItemFlags._next;
  static final int _next = _base + _InterfaceItemFlag.values.length;

  factory _InterfaceItemFlags.encode(InterfaceElementImpl element) {
    var bits = _InstanceItemFlags.encode(element)._bits;
    return _InterfaceItemFlags._(bits);
  }

  factory _InterfaceItemFlags.read(SummaryDataReader reader) {
    return _InterfaceItemFlags._(reader.readUint30());
  }

  void write(BufferedSink sink) {
    sink.writeUint30(_bits);
  }
}

extension type _ManifestItemFlags._(int _bits) {
  static final int _base = 0;
  static final int _next = _base + _ManifestItemFlag.values.length;

  factory _ManifestItemFlags.empty() {
    return _ManifestItemFlags._(0);
  }

  factory _ManifestItemFlags.encode(ElementImpl element) {
    var bits = 0;
    if (element.isSynthetic) {
      bits |= _maskFor(_ManifestItemFlag.isSynthetic);
    }
    return _ManifestItemFlags._(bits);
  }

  factory _ManifestItemFlags.read(SummaryDataReader reader) {
    return _ManifestItemFlags._(reader.readUint30());
  }

  bool get isSynthetic {
    return _has(_ManifestItemFlag.isSynthetic);
  }

  void write(BufferedSink sink) {
    sink.writeUint30(_bits);
  }

  bool _has(_ManifestItemFlag flag) {
    return (_bits & _maskFor(flag)) != 0;
  }

  static int _maskFor(_ManifestItemFlag flag) {
    var bit = _base + flag.index;
    assert(bit < 30);
    return 1 << bit;
  }
}

extension type _MethodItemFlags._(int _bits) implements _ExecutableItemFlags {
  static final int _base = _ExecutableItemFlags._next;

  factory _MethodItemFlags.encode(MethodElementImpl element) {
    var bits = _ExecutableItemFlags.encode(element)._bits;
    if (element.isOperatorEqualWithParameterTypeFromObject) {
      bits |= _maskFor(
        _MethodItemFlag.isOperatorEqualWithParameterTypeFromObject,
      );
    }
    return _MethodItemFlags._(bits);
  }

  factory _MethodItemFlags.read(SummaryDataReader reader) {
    return _MethodItemFlags._(reader.readUint30());
  }

  bool get isOperatorEqualWithParameterTypeFromObject {
    return _has(_MethodItemFlag.isOperatorEqualWithParameterTypeFromObject);
  }

  void write(BufferedSink sink) {
    sink.writeUint30(_bits);
  }

  bool _has(_MethodItemFlag flag) {
    return (_bits & _maskFor(flag)) != 0;
  }

  static int _maskFor(_MethodItemFlag flag) {
    var bit = _base + flag.index;
    assert(bit < 30);
    return 1 << bit;
  }
}

extension type _MixinItemFlags._(int _bits) implements _InterfaceItemFlags {
  static final int _base = _InterfaceItemFlags._next;

  factory _MixinItemFlags.encode(MixinElementImpl element) {
    var bits = _InterfaceItemFlags.encode(element)._bits;
    if (element.isBase) {
      bits |= _maskFor(_MixinItemFlag.isBase);
    }
    return _MixinItemFlags._(bits);
  }

  factory _MixinItemFlags.read(SummaryDataReader reader) {
    return _MixinItemFlags._(reader.readUint30());
  }

  bool get isBase {
    return _has(_MixinItemFlag.isBase);
  }

  void write(BufferedSink sink) {
    sink.writeUint30(_bits);
  }

  bool _has(_MixinItemFlag flag) {
    return (_bits & _maskFor(flag)) != 0;
  }

  static int _maskFor(_MixinItemFlag flag) {
    var bit = _base + flag.index;
    assert(bit < 30);
    return 1 << bit;
  }
}

extension type _TopLevelVariableItemFlags._(int _bits)
    implements _VariableItemFlags {
  static final int _base = _VariableItemFlags._next;

  factory _TopLevelVariableItemFlags.encode(
    TopLevelVariableElementImpl element,
  ) {
    var bits = _VariableItemFlags.encode(element)._bits;
    if (element.isExternal) {
      bits |= _maskFor(_TopLevelVariableItemFlag.isExternal);
    }
    return _TopLevelVariableItemFlags._(bits);
  }

  factory _TopLevelVariableItemFlags.read(SummaryDataReader reader) {
    return _TopLevelVariableItemFlags._(reader.readUint30());
  }

  bool get isExternal {
    return _has(_TopLevelVariableItemFlag.isExternal);
  }

  void write(BufferedSink sink) {
    sink.writeUint30(_bits);
  }

  bool _has(_TopLevelVariableItemFlag flag) {
    return (_bits & _maskFor(flag)) != 0;
  }

  static int _maskFor(_TopLevelVariableItemFlag flag) {
    var bit = _base + flag.index;
    assert(bit < 30);
    return 1 << bit;
  }
}

extension type _TypeAliasItemFlags._(int _bits) implements _ManifestItemFlags {
  static final int _base = _ManifestItemFlags._next;

  factory _TypeAliasItemFlags.encode(TypeAliasElementImpl element) {
    var bits = _ManifestItemFlags.encode(element)._bits;
    if (element.isProperRename) {
      bits |= _maskFor(_TypeAliasItemFlag.isProperRename);
    }
    if (element.isSimplyBounded) {
      bits |= _maskFor(_TypeAliasItemFlag.isSimplyBounded);
    }
    return _TypeAliasItemFlags._(bits);
  }

  factory _TypeAliasItemFlags.read(SummaryDataReader reader) {
    return _TypeAliasItemFlags._(reader.readUint30());
  }

  bool get isProperRename {
    return _has(_TypeAliasItemFlag.isProperRename);
  }

  bool get isSimplyBounded {
    return _has(_TypeAliasItemFlag.isSimplyBounded);
  }

  void write(BufferedSink sink) {
    sink.writeUint30(_bits);
  }

  bool _has(_TypeAliasItemFlag flag) {
    return (_bits & _maskFor(flag)) != 0;
  }

  static int _maskFor(_TypeAliasItemFlag flag) {
    var bit = _base + flag.index;
    assert(bit < 30);
    return 1 << bit;
  }
}

extension type _VariableItemFlags._(int _bits) implements _ManifestItemFlags {
  static final int _base = _ManifestItemFlags._next;
  static final int _next = _base + _VariableItemFlag.values.length;

  factory _VariableItemFlags.encode(PropertyInducingElementImpl element) {
    var bits = _ManifestItemFlags.encode(element)._bits;
    if (element.hasInitializer) {
      bits |= _maskFor(_VariableItemFlag.hasInitializer);
    }
    if (element.hasImplicitType) {
      bits |= _maskFor(_VariableItemFlag.hasImplicitType);
    }
    if (element.isConst) {
      bits |= _maskFor(_VariableItemFlag.isConst);
    }
    if (element.isFinal) {
      bits |= _maskFor(_VariableItemFlag.isFinal);
    }
    if (element.isLate) {
      bits |= _maskFor(_VariableItemFlag.isLate);
    }
    if (element.isStatic) {
      bits |= _maskFor(_VariableItemFlag.isStatic);
    }
    if (element.shouldUseTypeForInitializerInference) {
      bits |= _maskFor(_VariableItemFlag.shouldUseTypeForInitializerInference);
    }
    return _VariableItemFlags._(bits);
  }

  bool get hasImplicitType {
    return _has(_VariableItemFlag.hasImplicitType);
  }

  bool get hasInitializer {
    return _has(_VariableItemFlag.hasInitializer);
  }

  bool get isConst {
    return _has(_VariableItemFlag.isConst);
  }

  bool get isFinal {
    return _has(_VariableItemFlag.isFinal);
  }

  bool get isLate {
    return _has(_VariableItemFlag.isLate);
  }

  bool get isStatic {
    return _has(_VariableItemFlag.isStatic);
  }

  bool get shouldUseTypeForInitializerInference {
    return _has(_VariableItemFlag.shouldUseTypeForInitializerInference);
  }

  void write(BufferedSink sink) {
    sink.writeUint30(_bits);
  }

  bool _has(_VariableItemFlag flag) {
    return (_bits & _maskFor(flag)) != 0;
  }

  static int _maskFor(_VariableItemFlag flag) {
    var bit = _base + flag.index;
    assert(bit < 30);
    return 1 << bit;
  }
}

extension LookupNameToIdMapExtension on Map<LookupName, ManifestItemId> {
  void write(BufferedSink sink) {
    sink.writeMap(
      this,
      writeKey: (name) => name.write(sink),
      writeValue: (items) => items.write(sink),
    );
  }
}

extension LookupNameToItemMapExtension on Map<LookupName, ManifestItem> {
  void write(BufferedSink sink) {
    sink.writeMap(
      this,
      writeKey: (name) => name.write(sink),
      writeValue: (items) => items.write(sink),
    );
  }
}

extension SummaryDataReaderExtension on SummaryDataReader {
  Map<LookupName, V> readLookupNameMap<V>({required V Function() readValue}) {
    return readMap(
      readKey: () => LookupName.read(this),
      readValue: () => readValue(),
    );
  }

  Map<LookupName, ManifestItemId> readLookupNameToIdMap() {
    return readLookupNameMap(readValue: () => ManifestItemId.read(this));
  }
}

extension _AnnotatableElementExtension on ElementImpl {
  MetadataImpl get effectiveMetadata {
    if (this case PropertyAccessorElementImpl accessor) {
      return accessor.thisOrVariableMetadata;
    }
    return metadata;
  }
}

extension _AstNodeExtension on AstNode {
  ManifestNode encode(EncodeContext context) {
    return ManifestNode.encode(context, this);
  }
}

extension _LookupNameToConstructorItemMapExtension
    on Map<LookupName, ConstructorItem> {
  void write(BufferedSink sink) {
    sink.writeMap(
      this,
      writeKey: (name) => name.write(sink),
      writeValue: (items) => items.write(sink),
    );
  }
}

extension _LookupNameToFieldItemMapExtension on Map<LookupName, FieldItem> {
  void write(BufferedSink sink) {
    sink.writeMap(
      this,
      writeKey: (name) => name.write(sink),
      writeValue: (items) => items.write(sink),
    );
  }
}

extension _LookupNameToGetterItemMapExtension on Map<LookupName, GetterItem> {
  void write(BufferedSink sink) {
    sink.writeMap(
      this,
      writeKey: (name) => name.write(sink),
      writeValue: (items) => items.write(sink),
    );
  }
}

extension _LookupNameToMethodItemMapExtension on Map<LookupName, MethodItem> {
  void write(BufferedSink sink) {
    sink.writeMap(
      this,
      writeKey: (name) => name.write(sink),
      writeValue: (items) => items.write(sink),
    );
  }
}

extension _LookupNameToSetterItemMapExtension on Map<LookupName, SetterItem> {
  void write(BufferedSink sink) {
    sink.writeMap(
      this,
      writeKey: (name) => name.write(sink),
      writeValue: (items) => items.write(sink),
    );
  }
}

extension _PropertyAccessExtension on PropertyAccessorElementImpl {
  MetadataImpl get thisOrVariableMetadata {
    if (isSynthetic) {
      return variable.metadata;
    } else {
      return metadata;
    }
  }
}
