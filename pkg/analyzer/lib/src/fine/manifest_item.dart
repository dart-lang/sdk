// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/fine/lookup_name.dart';
import 'package:analyzer/src/fine/manifest_ast.dart';
import 'package:analyzer/src/fine/manifest_context.dart';
import 'package:analyzer/src/fine/manifest_id.dart';
import 'package:analyzer/src/fine/manifest_type.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

class ClassItem extends InterfaceItem<ClassElementImpl> {
  final bool isAbstract;
  final bool isBase;
  final bool isFinal;
  final bool isInterface;
  final bool isMixinApplication;
  final bool isMixinClass;
  final bool isSealed;

  ClassItem({
    required super.id,
    required super.isSynthetic,
    required super.metadata,
    required super.typeParameters,
    required super.isSimplyBounded,
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
    required this.isAbstract,
    required this.isBase,
    required this.isFinal,
    required this.isInterface,
    required this.isMixinApplication,
    required this.isMixinClass,
    required this.isSealed,
  });

  factory ClassItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required ClassElementImpl element,
  }) {
    return context.withTypeParameters(element.typeParameters, (typeParameters) {
      return ClassItem(
        id: id,
        isSynthetic: element.isSynthetic,
        metadata: ManifestMetadata.encode(context, element.metadata),
        typeParameters: typeParameters,
        isSimplyBounded: element.isSimplyBounded,
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
        isAbstract: element.isAbstract,
        isBase: element.isBase,
        isFinal: element.isFinal,
        isInterface: element.isInterface,
        isMixinApplication: element.isMixinApplication,
        isMixinClass: element.isMixinClass,
        isSealed: element.isSealed,
      );
    });
  }

  factory ClassItem.read(SummaryDataReader reader) {
    return ClassItem(
      id: ManifestItemId.read(reader),
      isSynthetic: reader.readBool(),
      metadata: ManifestMetadata.read(reader),
      typeParameters: ManifestTypeParameter.readList(reader),
      isSimplyBounded: reader.readBool(),
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
      isAbstract: reader.readBool(),
      isBase: reader.readBool(),
      isFinal: reader.readBool(),
      isInterface: reader.readBool(),
      isMixinApplication: reader.readBool(),
      isMixinClass: reader.readBool(),
      isSealed: reader.readBool(),
    );
  }

  @override
  bool match(MatchContext context, ClassElementImpl element) {
    return super.match(context, element) &&
        isAbstract == element.isAbstract &&
        isBase == element.isBase &&
        isFinal == element.isFinal &&
        isInterface == element.isInterface &&
        isMixinApplication == element.isMixinApplication &&
        isMixinClass == element.isMixinClass &&
        isSealed == element.isSealed;
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    sink.writeBool(isAbstract);
    sink.writeBool(isBase);
    sink.writeBool(isFinal);
    sink.writeBool(isInterface);
    sink.writeBool(isMixinApplication);
    sink.writeBool(isMixinClass);
    sink.writeBool(isSealed);
  }
}

class ConstructorItem extends ExecutableItem<ConstructorElementImpl> {
  final bool isConst;
  final bool isFactory;
  final List<ManifestNode> constantInitializers;

  ConstructorItem({
    required super.id,
    required super.isSynthetic,
    required super.metadata,
    required super.isStatic,
    required super.functionType,
    required this.isConst,
    required this.isFactory,
    required this.constantInitializers,
  });

  factory ConstructorItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required ConstructorElementImpl element,
  }) {
    return context.withFormalParameters(element.formalParameters, () {
      return ConstructorItem(
        id: id,
        isSynthetic: element.isSynthetic,
        metadata: ManifestMetadata.encode(context, element.metadata),
        isStatic: false,
        functionType: element.type.encode(context),
        isConst: element.isConst,
        isFactory: element.isFactory,
        constantInitializers: element.constantInitializers
            .map((initializer) => ManifestNode.encode(context, initializer))
            .toFixedList(),
      );
    });
  }

  factory ConstructorItem.read(SummaryDataReader reader) {
    return ConstructorItem(
      id: ManifestItemId.read(reader),
      isSynthetic: reader.readBool(),
      metadata: ManifestMetadata.read(reader),
      isStatic: reader.readBool(),
      functionType: ManifestFunctionType.read(reader),
      isConst: reader.readBool(),
      isFactory: reader.readBool(),
      constantInitializers: ManifestNode.readList(reader),
    );
  }

  @override
  bool match(MatchContext context, ConstructorElementImpl element) {
    return context.withFormalParameters(element.formalParameters, () {
      return super.match(context, element) &&
          isConst == element.isConst &&
          isFactory == element.isFactory &&
          constantInitializers.match(context, element.constantInitializers);
    });
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    sink.writeBool(isConst);
    sink.writeBool(isFactory);
    constantInitializers.writeList(sink);
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
    required super.isSynthetic,
    required super.metadata,
    required super.typeParameters,
    required super.isSimplyBounded,
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
        isSynthetic: element.isSynthetic,
        metadata: ManifestMetadata.encode(context, element.metadata),
        typeParameters: typeParameters,
        isSimplyBounded: element.isSimplyBounded,
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
      isSynthetic: reader.readBool(),
      metadata: ManifestMetadata.read(reader),
      typeParameters: ManifestTypeParameter.readList(reader),
      isSimplyBounded: reader.readBool(),
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
  final bool isStatic;
  final ManifestFunctionType functionType;

  ExecutableItem({
    required super.id,
    required super.isSynthetic,
    required super.metadata,
    required this.isStatic,
    required this.functionType,
  });

  @override
  bool match(MatchContext context, E element) {
    return super.match(context, element) &&
        isStatic == element.isStatic &&
        functionType.match(context, element.type);
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    sink.writeBool(isStatic);
    functionType.writeNoTag(sink);
  }
}

/// The item for [ExtensionElementImpl].
class ExtensionItem<E extends ExtensionElementImpl> extends InstanceItem<E> {
  final ManifestType extendedType;

  ExtensionItem({
    required super.id,
    required super.isSynthetic,
    required super.metadata,
    required super.typeParameters,
    required super.isSimplyBounded,
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
        isSynthetic: element.isSynthetic,
        metadata: ManifestMetadata.encode(context, element.metadata),
        typeParameters: typeParameters,
        isSimplyBounded: element.isSimplyBounded,
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
      isSynthetic: reader.readBool(),
      metadata: ManifestMetadata.read(reader),
      typeParameters: ManifestTypeParameter.readList(reader),
      isSimplyBounded: reader.readBool(),
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
  final bool hasImplementsSelfReference;
  final bool hasRepresentationSelfReference;
  final ManifestType representationType;
  final ManifestType typeErasure;

  ExtensionTypeItem({
    required super.id,
    required super.isSynthetic,
    required super.metadata,
    required super.typeParameters,
    required super.isSimplyBounded,
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
    required this.hasImplementsSelfReference,
    required this.hasRepresentationSelfReference,
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
        isSynthetic: element.isSynthetic,
        metadata: ManifestMetadata.encode(context, element.metadata),
        typeParameters: typeParameters,
        isSimplyBounded: element.isSimplyBounded,
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
        hasImplementsSelfReference: element.hasImplementsSelfReference,
        hasRepresentationSelfReference: element.hasRepresentationSelfReference,
        representationType: element.representation.type.encode(context),
        typeErasure: element.typeErasure.encode(context),
      );
    });
  }

  factory ExtensionTypeItem.read(SummaryDataReader reader) {
    return ExtensionTypeItem(
      id: ManifestItemId.read(reader),
      isSynthetic: reader.readBool(),
      metadata: ManifestMetadata.read(reader),
      typeParameters: ManifestTypeParameter.readList(reader),
      isSimplyBounded: reader.readBool(),
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
      hasImplementsSelfReference: reader.readBool(),
      hasRepresentationSelfReference: reader.readBool(),
      representationType: ManifestType.read(reader),
      typeErasure: ManifestType.read(reader),
    );
  }

  @override
  bool match(MatchContext context, ExtensionTypeElementImpl element) {
    return super.match(context, element) &&
        hasImplementsSelfReference == element.hasImplementsSelfReference &&
        hasRepresentationSelfReference ==
            element.hasRepresentationSelfReference &&
        representationType.match(context, element.representation.type) &&
        typeErasure.match(context, element.typeErasure);
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    sink.writeBool(hasImplementsSelfReference);
    sink.writeBool(hasRepresentationSelfReference);
    representationType.write(sink);
    typeErasure.write(sink);
  }
}

class FieldItem extends VariableItem<FieldElementImpl> {
  final bool isStatic;

  FieldItem({
    required super.id,
    required super.isSynthetic,
    required super.metadata,
    required super.isConst,
    required super.isFinal,
    required super.isLate,
    required super.type,
    required super.constInitializer,
    required this.isStatic,
  });

  factory FieldItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required FieldElementImpl element,
  }) {
    return FieldItem(
      id: id,
      isSynthetic: element.isSynthetic,
      metadata: ManifestMetadata.encode(context, element.metadata),
      isConst: element.isConst,
      isFinal: element.isFinal,
      isLate: element.isLate,
      type: element.type.encode(context),
      constInitializer: element.constantInitializer?.encode(context),
      isStatic: element.isStatic,
    );
  }

  factory FieldItem.read(SummaryDataReader reader) {
    return FieldItem(
      id: ManifestItemId.read(reader),
      isSynthetic: reader.readBool(),
      metadata: ManifestMetadata.read(reader),
      isConst: reader.readBool(),
      isFinal: reader.readBool(),
      isLate: reader.readBool(),
      type: ManifestType.read(reader),
      constInitializer: ManifestNode.readOptional(reader),
      isStatic: reader.readBool(),
    );
  }

  @override
  bool match(MatchContext context, FieldElementImpl element) {
    return super.match(context, element) && isStatic == element.isStatic;
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    sink.writeBool(isStatic);
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
    required super.isSynthetic,
    required super.metadata,
    required super.isStatic,
    required super.functionType,
  });

  factory GetterItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required GetterElementImpl element,
  }) {
    return GetterItem(
      id: id,
      isSynthetic: element.isSynthetic,
      metadata: ManifestMetadata.encode(
        context,
        element.thisOrVariableMetadata,
      ),
      isStatic: element.isStatic,
      functionType: element.type.encode(context),
    );
  }

  factory GetterItem.read(SummaryDataReader reader) {
    return GetterItem(
      id: ManifestItemId.read(reader),
      isSynthetic: reader.readBool(),
      metadata: ManifestMetadata.read(reader),
      isStatic: reader.readBool(),
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
  final bool isSimplyBounded;

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
    required super.isSynthetic,
    required super.metadata,
    required this.typeParameters,
    required this.isSimplyBounded,
    required this.declaredConflicts,
    required this.declaredFields,
    required this.declaredGetters,
    required this.declaredSetters,
    required this.declaredMethods,
    required this.declaredConstructors,
    required this.inheritedConstructors,
  });

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
      return declaredGetters[lookupName]?.isStatic ??
          declaredSetters[lookupName]?.isStatic ??
          declaredMethods[lookupName]?.isStatic ??
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
      if (item.isStatic && declaredConstructors.containsKey(lookupName)) {
        return true;
      }
      // Instance / static getters conflict with static / instance setter.
      var lookupNameSetter = '${lookupName.asString}='.asLookupName;
      if (declaredSetters[lookupNameSetter] case var setter?) {
        if (setter.isStatic != item.isStatic) {
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
      if (item.isStatic && declaredConstructors.containsKey(lookupName)) {
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
      if (item.isStatic && declaredConstructors.containsKey(lookupNameGetter)) {
        return true;
      }
      // Instance / static setters conflict with static / instance getter.
      if (declaredGetters[lookupNameGetter] case var getter?) {
        if (getter.isStatic != item.isStatic) {
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
        isSimplyBounded == element.isSimplyBounded;
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    typeParameters.write(sink);
    sink.writeBool(isSimplyBounded);
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
    required super.isSynthetic,
    required super.metadata,
    required super.typeParameters,
    required super.isSimplyBounded,
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
  final bool isSynthetic;
  final ManifestMetadata metadata;

  ManifestItem({
    required this.id,
    required this.isSynthetic,
    required this.metadata,
  });

  @mustCallSuper
  bool match(MatchContext context, E element) {
    return isSynthetic == element.isSynthetic &&
        metadata.match(context, element.effectiveMetadata);
  }

  @mustCallSuper
  void write(BufferedSink sink) {
    id.write(sink);
    sink.writeBool(isSynthetic);
    metadata.write(sink);
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
  MethodItem({
    required super.id,
    required super.isSynthetic,
    required super.metadata,
    required super.isStatic,
    required super.functionType,
  });

  factory MethodItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required MethodElementImpl element,
  }) {
    return MethodItem(
      id: id,
      isSynthetic: element.isSynthetic,
      metadata: ManifestMetadata.encode(context, element.metadata),
      isStatic: element.isStatic,
      functionType: element.type.encode(context),
    );
  }

  factory MethodItem.read(SummaryDataReader reader) {
    return MethodItem(
      id: ManifestItemId.read(reader),
      isSynthetic: reader.readBool(),
      metadata: ManifestMetadata.read(reader),
      isStatic: reader.readBool(),
      functionType: ManifestFunctionType.read(reader),
    );
  }

  static Map<LookupName, MethodItem> readMap(SummaryDataReader reader) {
    return reader.readMap(
      readKey: () => LookupName.read(reader),
      readValue: () => MethodItem.read(reader),
    );
  }
}

class MixinItem extends InterfaceItem<MixinElementImpl> {
  final bool isBase;
  final List<ManifestType> superclassConstraints;
  final List<LookupName> superInvokedNames;

  MixinItem({
    required super.id,
    required super.isSynthetic,
    required super.metadata,
    required super.typeParameters,
    required super.isSimplyBounded,
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
    required this.isBase,
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
        isSynthetic: element.isSynthetic,
        metadata: ManifestMetadata.encode(context, element.metadata),
        typeParameters: typeParameters,
        isSimplyBounded: element.isSimplyBounded,
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
        isBase: element.isBase,
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
      isSynthetic: reader.readBool(),
      metadata: ManifestMetadata.read(reader),
      typeParameters: ManifestTypeParameter.readList(reader),
      isSimplyBounded: reader.readBool(),
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
      isBase: reader.readBool(),
      superclassConstraints: ManifestType.readList(reader),
      superInvokedNames: reader.readLookupNameList(),
    );
  }

  @override
  bool match(MatchContext context, MixinElementImpl element) {
    return super.match(context, element) &&
        isBase == element.isBase &&
        superclassConstraints.match(context, element.superclassConstraints) &&
        const IterableEquality<String>().equals(
          superInvokedNames.map((lookupName) => lookupName.asString),
          element.superInvokedNames,
        );
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    sink.writeBool(isBase);
    superclassConstraints.writeList(sink);
    superInvokedNames.write(sink);
  }
}

class SetterItem extends ExecutableItem<SetterElementImpl> {
  SetterItem({
    required super.id,
    required super.isSynthetic,
    required super.metadata,
    required super.isStatic,
    required super.functionType,
  });

  factory SetterItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required SetterElementImpl element,
  }) {
    return SetterItem(
      id: id,
      isSynthetic: element.isSynthetic,
      metadata: ManifestMetadata.encode(
        context,
        element.thisOrVariableMetadata,
      ),
      isStatic: element.isStatic,
      functionType: element.type.encode(context),
    );
  }

  factory SetterItem.read(SummaryDataReader reader) {
    return SetterItem(
      id: ManifestItemId.read(reader),
      isSynthetic: reader.readBool(),
      metadata: ManifestMetadata.read(reader),
      isStatic: reader.readBool(),
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
    required super.isSynthetic,
    required super.metadata,
    required super.isStatic,
    required super.functionType,
  });

  factory TopLevelFunctionItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required TopLevelFunctionElementImpl element,
  }) {
    return TopLevelFunctionItem(
      id: id,
      isSynthetic: element.isSynthetic,
      metadata: ManifestMetadata.encode(context, element.metadata),
      isStatic: element.isStatic,
      functionType: element.type.encode(context),
    );
  }

  factory TopLevelFunctionItem.read(SummaryDataReader reader) {
    return TopLevelFunctionItem(
      id: ManifestItemId.read(reader),
      isSynthetic: reader.readBool(),
      metadata: ManifestMetadata.read(reader),
      isStatic: reader.readBool(),
      functionType: ManifestFunctionType.read(reader),
    );
  }
}

class TopLevelVariableItem extends VariableItem<TopLevelVariableElementImpl> {
  TopLevelVariableItem({
    required super.id,
    required super.isSynthetic,
    required super.metadata,
    required super.isConst,
    required super.isFinal,
    required super.isLate,
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
      isSynthetic: element.isSynthetic,
      metadata: ManifestMetadata.encode(context, element.metadata),
      isConst: element.isConst,
      isFinal: element.isFinal,
      isLate: element.isLate,
      type: element.type.encode(context),
      constInitializer: element.constantInitializer?.encode(context),
    );
  }

  factory TopLevelVariableItem.read(SummaryDataReader reader) {
    return TopLevelVariableItem(
      id: ManifestItemId.read(reader),
      isSynthetic: reader.readBool(),
      metadata: ManifestMetadata.read(reader),
      isConst: reader.readBool(),
      isFinal: reader.readBool(),
      isLate: reader.readBool(),
      type: ManifestType.read(reader),
      constInitializer: ManifestNode.readOptional(reader),
    );
  }
}

class TypeAliasItem extends ManifestItem<TypeAliasElementImpl> {
  final List<ManifestTypeParameter> typeParameters;
  final ManifestType aliasedType;

  TypeAliasItem({
    required super.id,
    required super.isSynthetic,
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
        isSynthetic: element.isSynthetic,
        metadata: ManifestMetadata.encode(context, element.metadata),
        typeParameters: typeParameters,
        aliasedType: element.aliasedType.encode(context),
      );
    });
  }

  factory TypeAliasItem.read(SummaryDataReader reader) {
    return TypeAliasItem(
      id: ManifestItemId.read(reader),
      isSynthetic: reader.readBool(),
      metadata: ManifestMetadata.read(reader),
      typeParameters: ManifestTypeParameter.readList(reader),
      aliasedType: ManifestType.read(reader),
    );
  }

  @override
  bool match(MatchContext context, TypeAliasElementImpl element) {
    context.addTypeParameters(element.typeParameters);
    return super.match(context, element) &&
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

sealed class VariableItem<E extends VariableElementImpl>
    extends ManifestItem<E> {
  final bool isConst;
  final bool isFinal;
  final bool isLate;
  final ManifestType type;
  final ManifestNode? constInitializer;

  VariableItem({
    required super.id,
    required super.isSynthetic,
    required super.metadata,
    required this.isConst,
    required this.isFinal,
    required this.isLate,
    required this.type,
    required this.constInitializer,
  });

  @override
  bool match(MatchContext context, E element) {
    return super.match(context, element) &&
        isConst == element.isConst &&
        isFinal == element.isFinal &&
        isLate == element.isLate &&
        type.match(context, element.type) &&
        constInitializer.match(context, element.constantInitializer);
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    sink.writeBool(isConst);
    sink.writeBool(isFinal);
    sink.writeBool(isLate);
    type.write(sink);
    constInitializer.writeOptional(sink);
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
