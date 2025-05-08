// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/fine/base_name_members.dart';
import 'package:analyzer/src/fine/lookup_name.dart';
import 'package:analyzer/src/fine/manifest_ast.dart';
import 'package:analyzer/src/fine/manifest_context.dart';
import 'package:analyzer/src/fine/manifest_id.dart';
import 'package:analyzer/src/fine/manifest_type.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:meta/meta.dart';

class ClassItem extends InterfaceItem<ClassElementImpl2> {
  ClassItem({
    required super.id,
    required super.metadata,
    required super.typeParameters,
    required super.declaredFields,
    required super.declaredMembers,
    required super.interface,
    required super.supertype,
    required super.mixins,
    required super.interfaces,
  });

  factory ClassItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required ClassElementImpl2 element,
  }) {
    return context.withTypeParameters(element.typeParameters2, (
      typeParameters,
    ) {
      return ClassItem(
        id: id,
        metadata: ManifestMetadata.encode(context, element.metadata2),
        typeParameters: typeParameters,
        declaredFields: {},
        declaredMembers: {},
        interface: ManifestInterface.empty(),
        supertype: element.supertype?.encode(context),
        mixins: element.mixins.encode(context),
        interfaces: element.interfaces.encode(context),
      );
    });
  }

  factory ClassItem.read(SummaryDataReader reader) {
    return ClassItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      typeParameters: ManifestTypeParameter.readList(reader),
      declaredFields: InstanceItemFieldItem.readMap(reader),
      declaredMembers: BaseNameMembers.readMap(reader),
      interface: ManifestInterface.read(reader),
      supertype: ManifestType.readOptional(reader),
      mixins: ManifestType.readList(reader),
      interfaces: ManifestType.readList(reader),
    );
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind.class_);
    super.write(sink);
  }
}

/// The item for [InstanceElementImpl2].
sealed class InstanceItem<E extends InstanceElementImpl2>
    extends TopLevelItem<E> {
  final List<ManifestTypeParameter> typeParameters;

  final Map<LookupName, InstanceItemFieldItem> declaredFields;

  /// This name is almost truth, it contains declared constructors, methods,
  /// getters, and setters; both instance and static. But for class type
  /// aliases it also has "inherited" constructors, references to the
  /// superclass constructors.
  final Map<BaseName, BaseNameMembers> declaredMembers;

  final ManifestInterface interface;

  InstanceItem({
    required super.id,
    required super.metadata,
    required this.typeParameters,
    required this.declaredFields,
    required this.declaredMembers,
    required this.interface,
  });

  ManifestItemId? getConstructorId(LookupName name) {
    var baseNameMembers = declaredMembers[name.asBaseName];
    if (baseNameMembers == null) {
      return null;
    }

    return baseNameMembers.constructorId;
  }

  ManifestItemId? getDeclaredMemberId(LookupName name) {
    var baseNameMembers = declaredMembers[name.asBaseName];
    if (baseNameMembers == null) {
      return null;
    }

    if (name.isSetter) {
      return baseNameMembers.setterId;
    }

    if (name.isIndexEq) {
      return baseNameMembers.indexEqId;
    }

    return baseNameMembers.getterOrMethodId;
  }

  ManifestItemId? getInterfaceMethodId(LookupName name) {
    return getDeclaredMemberId(name);
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    typeParameters.writeList(sink);
    declaredFields.write(sink);
    declaredMembers.write(sink);
    interface.write(sink);
  }
}

class InstanceItemFieldItem extends InstanceItemMemberItem<FieldElementImpl2> {
  final ManifestType type;
  final ManifestNode? constInitializer;

  InstanceItemFieldItem({
    required super.id,
    required super.metadata,
    required super.isStatic,
    required this.type,
    required this.constInitializer,
  });

  factory InstanceItemFieldItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required FieldElementImpl2 element,
  }) {
    return InstanceItemFieldItem(
      id: id,
      metadata: ManifestMetadata.encode(context, element.metadata2),
      isStatic: element.isStatic,
      type: element.type.encode(context),
      constInitializer: element.constantInitializer2?.expression.encode(
        context,
      ),
    );
  }

  factory InstanceItemFieldItem.read(SummaryDataReader reader) {
    return InstanceItemFieldItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      isStatic: reader.readBool(),
      type: ManifestType.read(reader),
      constInitializer: ManifestNode.readOptional(reader),
    );
  }

  @override
  bool match(MatchContext context, FieldElementImpl2 element) {
    return super.match(context, element) &&
        type.match(context, element.type) &&
        constInitializer.match(
          context,
          element.constantInitializer2?.expression,
        );
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    type.write(sink);
    constInitializer.writeOptional(sink);
  }

  @override
  void writeKind(BufferedSink sink) {
    sink.writeEnum(_InstanceItemMemberItemKind.getter);
  }

  static Map<LookupName, InstanceItemFieldItem> readMap(
    SummaryDataReader reader,
  ) {
    return reader.readMap(
      readKey: () => LookupName.read(reader),
      readValue: () => InstanceItemFieldItem.read(reader),
    );
  }
}

class InstanceItemGetterItem extends InstanceItemMemberItem<GetterElementImpl> {
  final ManifestType returnType;

  InstanceItemGetterItem({
    required super.id,
    required super.metadata,
    required super.isStatic,
    required this.returnType,
  });

  factory InstanceItemGetterItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required GetterElementImpl element,
  }) {
    return InstanceItemGetterItem(
      id: id,
      metadata: ManifestMetadata.encode(
        context,
        element.thisOrVariableMetadata,
      ),
      isStatic: element.isStatic,
      returnType: element.returnType.encode(context),
    );
  }

  factory InstanceItemGetterItem.read(SummaryDataReader reader) {
    return InstanceItemGetterItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      isStatic: reader.readBool(),
      returnType: ManifestType.read(reader),
    );
  }

  @override
  bool match(MatchContext context, GetterElementImpl element) {
    return super.match(context, element) &&
        returnType.match(context, element.returnType);
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    returnType.write(sink);
  }

  @override
  void writeKind(BufferedSink sink) {
    sink.writeEnum(_InstanceItemMemberItemKind.getter);
  }
}

sealed class InstanceItemMemberItem<E extends AnnotatableElementImpl>
    extends ManifestItem<E> {
  final bool isStatic;

  InstanceItemMemberItem({
    required super.id,
    required super.metadata,
    required this.isStatic,
  });

  @override
  bool match(MatchContext context, E element) {
    if (!super.match(context, element)) {
      return false;
    }

    switch (element) {
      case FieldElementImpl2 element:
        if (element.isStatic != isStatic) {
          return false;
        }
      case ExecutableElementImpl2 element:
        if (element.isStatic != isStatic) {
          return false;
        }
    }

    return true;
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    sink.writeBool(isStatic);
  }

  void writeKind(BufferedSink sink);

  void writeWithKind(BufferedSink sink) {
    writeKind(sink);
    write(sink);
  }

  static InstanceItemMemberItem<AnnotatableElementImpl> read(
    SummaryDataReader reader,
  ) {
    var kind = reader.readEnum(_InstanceItemMemberItemKind.values);
    switch (kind) {
      case _InstanceItemMemberItemKind.field:
        return InstanceItemFieldItem.read(reader);
      case _InstanceItemMemberItemKind.getter:
        return InstanceItemGetterItem.read(reader);
      case _InstanceItemMemberItemKind.method:
        return InstanceItemMethodItem.read(reader);
      case _InstanceItemMemberItemKind.setter:
        return InstanceItemSetterItem.read(reader);
      case _InstanceItemMemberItemKind.constructor:
        return InterfaceItemConstructorItem.read(reader);
    }
  }
}

class InstanceItemMethodItem
    extends InstanceItemMemberItem<MethodElementImpl2> {
  final ManifestFunctionType functionType;

  InstanceItemMethodItem({
    required super.id,
    required super.metadata,
    required super.isStatic,
    required this.functionType,
  });

  factory InstanceItemMethodItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required MethodElementImpl2 element,
  }) {
    return InstanceItemMethodItem(
      id: id,
      metadata: ManifestMetadata.encode(context, element.metadata2),
      isStatic: element.isStatic,
      functionType: element.type.encode(context),
    );
  }

  factory InstanceItemMethodItem.read(SummaryDataReader reader) {
    return InstanceItemMethodItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      isStatic: reader.readBool(),
      functionType: ManifestFunctionType.read(reader),
    );
  }

  @override
  bool match(MatchContext context, MethodElementImpl2 element) {
    return super.match(context, element) &&
        functionType.match(context, element.type);
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    functionType.writeNoTag(sink);
  }

  @override
  void writeKind(BufferedSink sink) {
    sink.writeEnum(_InstanceItemMemberItemKind.method);
  }
}

class InstanceItemSetterItem extends InstanceItemMemberItem<SetterElementImpl> {
  final ManifestType valueType;

  InstanceItemSetterItem({
    required super.id,
    required super.metadata,
    required super.isStatic,
    required this.valueType,
  });

  factory InstanceItemSetterItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required SetterElementImpl element,
  }) {
    return InstanceItemSetterItem(
      id: id,
      metadata: ManifestMetadata.encode(
        context,
        element.thisOrVariableMetadata,
      ),
      isStatic: element.isStatic,
      valueType: element.formalParameters[0].type.encode(context),
    );
  }

  factory InstanceItemSetterItem.read(SummaryDataReader reader) {
    return InstanceItemSetterItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      isStatic: reader.readBool(),
      valueType: ManifestType.read(reader),
    );
  }

  @override
  bool match(MatchContext context, SetterElementImpl element) {
    return super.match(context, element) &&
        valueType.match(context, element.formalParameters[0].type);
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    valueType.write(sink);
  }

  @override
  void writeKind(BufferedSink sink) {
    sink.writeEnum(_InstanceItemMemberItemKind.setter);
  }
}

/// The item for [InterfaceElementImpl2].
sealed class InterfaceItem<E extends InterfaceElementImpl2>
    extends InstanceItem<E> {
  final ManifestType? supertype;
  final List<ManifestType> interfaces;
  final List<ManifestType> mixins;

  InterfaceItem({
    required super.id,
    required super.metadata,
    required super.typeParameters,
    required super.declaredFields,
    required super.declaredMembers,
    required super.interface,
    required this.supertype,
    required this.mixins,
    required this.interfaces,
  });

  @override
  ManifestItemId? getInterfaceMethodId(LookupName name) {
    return interface.map[name];
  }

  @override
  bool match(MatchContext context, E element) {
    context.addTypeParameters(element.typeParameters2);
    return super.match(context, element) &&
        supertype.match(context, element.supertype) &&
        interfaces.match(context, element.interfaces) &&
        mixins.match(context, element.mixins);
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    supertype.writeOptional(sink);
    mixins.writeList(sink);
    interfaces.writeList(sink);
  }
}

class InterfaceItemConstructorItem
    extends InstanceItemMemberItem<ConstructorElementImpl2> {
  final bool isConst;
  final bool isFactory;
  final ManifestFunctionType functionType;
  final List<ManifestNode> constantInitializers;

  InterfaceItemConstructorItem({
    required super.id,
    required super.metadata,
    required super.isStatic,
    required this.isConst,
    required this.isFactory,
    required this.functionType,
    required this.constantInitializers,
  });

  factory InterfaceItemConstructorItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required ConstructorElementImpl2 element,
  }) {
    return context.withFormalParameters(element.formalParameters, () {
      return InterfaceItemConstructorItem(
        id: id,
        metadata: ManifestMetadata.encode(context, element.metadata2),
        isStatic: false,
        isConst: element.isConst,
        isFactory: element.isFactory,
        functionType: element.type.encode(context),
        constantInitializers:
            element.constantInitializers
                .map((initializer) => ManifestNode.encode(context, initializer))
                .toFixedList(),
      );
    });
  }

  factory InterfaceItemConstructorItem.read(SummaryDataReader reader) {
    return InterfaceItemConstructorItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      isStatic: reader.readBool(),
      isConst: reader.readBool(),
      isFactory: reader.readBool(),
      functionType: ManifestFunctionType.read(reader),
      constantInitializers: ManifestNode.readList(reader),
    );
  }

  @override
  bool match(MatchContext context, ConstructorElementImpl2 element) {
    return context.withFormalParameters(element.formalParameters, () {
      return super.match(context, element) &&
          isConst == element.isConst &&
          isFactory == element.isFactory &&
          functionType.match(context, element.type) &&
          constantInitializers.match(context, element.constantInitializers);
    });
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    sink.writeBool(isConst);
    sink.writeBool(isFactory);
    functionType.writeNoTag(sink);
    constantInitializers.writeList(sink);
  }

  @override
  void writeKind(BufferedSink sink) {
    sink.writeEnum(_InstanceItemMemberItemKind.constructor);
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
  /// The map of names to their IDs in the interface.
  final Map<LookupName, ManifestItemId> map;

  /// Key: IDs of method declarations.
  /// Value: ID assigned last time.
  /// When the same signatures merge, the result is the same.
  Map<ManifestItemIdList, ManifestItemId> combinedIds = {};

  /// We move [combinedIds] into here during building the manifest, so that
  /// we can fill [combinedIds] with new entries.
  Map<ManifestItemIdList, ManifestItemId> combinedIdsTemp = {};

  ManifestInterface({required this.map, required this.combinedIds});

  factory ManifestInterface.empty() {
    return ManifestInterface(map: {}, combinedIds: {});
  }

  factory ManifestInterface.read(SummaryDataReader reader) {
    return ManifestInterface(
      map: LookupNameIdMapExtension.read(reader),
      combinedIds: reader.readMap(
        readKey: () => ManifestItemIdList.read(reader),
        readValue: () => ManifestItemId.read(reader),
      ),
    );
  }

  void afterUpdate() {
    combinedIdsTemp = {};
  }

  void beforeUpdating() {
    map.clear();
    combinedIdsTemp = combinedIds;
    combinedIds = {};
  }

  void write(BufferedSink sink) {
    map.write(sink);
    sink.writeMap(
      combinedIds,
      writeKey: (key) => key.write(sink),
      writeValue: (id) => id.write(sink),
    );
  }
}

sealed class ManifestItem<E extends AnnotatableElementImpl> {
  /// The unique identifier of this item.
  final ManifestItemId id;
  final ManifestMetadata metadata;

  ManifestItem({required this.id, required this.metadata});

  @mustCallSuper
  bool match(MatchContext context, E element) {
    return metadata.match(context, element.effectiveMetadata);
  }

  @mustCallSuper
  void write(BufferedSink sink) {
    id.write(sink);
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
      annotations:
          metadata.annotations.map((annotation) {
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

class MixinItem extends InterfaceItem<MixinElementImpl2> {
  final List<ManifestType> superclassConstraints;

  MixinItem({
    required super.id,
    required super.metadata,
    required super.typeParameters,
    required super.supertype,
    required super.interfaces,
    required super.mixins,
    required super.declaredFields,
    required super.declaredMembers,
    required super.interface,
    required this.superclassConstraints,
  }) : assert(supertype == null),
       assert(mixins.isEmpty),
       assert(superclassConstraints.isNotEmpty);

  factory MixinItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required MixinElementImpl2 element,
  }) {
    return context.withTypeParameters(element.typeParameters2, (
      typeParameters,
    ) {
      return MixinItem(
        id: id,
        metadata: ManifestMetadata.encode(context, element.metadata2),
        typeParameters: typeParameters,
        declaredFields: {},
        declaredMembers: {},
        interface: ManifestInterface.empty(),
        supertype: element.supertype?.encode(context),
        mixins: element.mixins.encode(context),
        interfaces: element.interfaces.encode(context),
        superclassConstraints: element.superclassConstraints.encode(context),
      );
    });
  }

  factory MixinItem.read(SummaryDataReader reader) {
    return MixinItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      typeParameters: ManifestTypeParameter.readList(reader),
      declaredFields: InstanceItemFieldItem.readMap(reader),
      declaredMembers: BaseNameMembers.readMap(reader),
      interface: ManifestInterface.read(reader),
      supertype: ManifestType.readOptional(reader),
      mixins: ManifestType.readList(reader),
      interfaces: ManifestType.readList(reader),
      superclassConstraints: ManifestType.readList(reader),
    );
  }

  @override
  bool match(MatchContext context, MixinElementImpl2 element) {
    return super.match(context, element) &&
        superclassConstraints.match(context, element.superclassConstraints);
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind.mixin_);
    super.write(sink);
    superclassConstraints.writeList(sink);
  }
}

class TopLevelFunctionItem extends TopLevelItem<TopLevelFunctionElementImpl> {
  final ManifestFunctionType functionType;

  TopLevelFunctionItem({
    required super.id,
    required super.metadata,
    required this.functionType,
  });

  factory TopLevelFunctionItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required TopLevelFunctionElementImpl element,
  }) {
    return TopLevelFunctionItem(
      id: id,
      metadata: ManifestMetadata.encode(context, element.metadata2),
      functionType: element.type.encode(context),
    );
  }

  factory TopLevelFunctionItem.read(SummaryDataReader reader) {
    return TopLevelFunctionItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      functionType: ManifestFunctionType.read(reader),
    );
  }

  @override
  bool match(MatchContext context, TopLevelFunctionElementImpl element) {
    return super.match(context, element) &&
        functionType.match(context, element.type);
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind.topLevelFunction);
    super.write(sink);
    functionType.writeNoTag(sink);
  }
}

class TopLevelGetterItem extends TopLevelItem<GetterElementImpl> {
  final ManifestType returnType;
  final ManifestNode? constInitializer;

  TopLevelGetterItem({
    required super.id,
    required super.metadata,
    required this.returnType,
    required this.constInitializer,
  });

  factory TopLevelGetterItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required GetterElementImpl element,
  }) {
    return TopLevelGetterItem(
      id: id,
      metadata: ManifestMetadata.encode(
        context,
        element.thisOrVariableMetadata,
      ),
      returnType: element.returnType.encode(context),
      constInitializer: element.constInitializer?.encode(context),
    );
  }

  factory TopLevelGetterItem.read(SummaryDataReader reader) {
    return TopLevelGetterItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      returnType: ManifestType.read(reader),
      constInitializer: ManifestNode.readOptional(reader),
    );
  }

  @override
  bool match(MatchContext context, GetterElementImpl element) {
    return super.match(context, element) &&
        returnType.match(context, element.returnType) &&
        constInitializer.match(context, element.constInitializer);
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind.topLevelGetter);
    super.write(sink);
    returnType.write(sink);
    constInitializer.writeOptional(sink);
  }
}

sealed class TopLevelItem<E extends AnnotatableElementImpl>
    extends ManifestItem<E> {
  TopLevelItem({required super.id, required super.metadata});

  static TopLevelItem<AnnotatableElementImpl> read(SummaryDataReader reader) {
    var kind = reader.readEnum(_ManifestItemKind.values);
    switch (kind) {
      case _ManifestItemKind.class_:
        return ClassItem.read(reader);
      case _ManifestItemKind.mixin_:
        return MixinItem.read(reader);
      case _ManifestItemKind.topLevelFunction:
        return TopLevelFunctionItem.read(reader);
      case _ManifestItemKind.topLevelGetter:
        return TopLevelGetterItem.read(reader);
      case _ManifestItemKind.topLevelSetter:
        return TopLevelSetterItem.read(reader);
    }
  }
}

class TopLevelSetterItem extends TopLevelItem<SetterElementImpl> {
  final ManifestType valueType;

  TopLevelSetterItem({
    required super.id,
    required super.metadata,
    required this.valueType,
  });

  factory TopLevelSetterItem.fromElement({
    required ManifestItemId id,
    required EncodeContext context,
    required SetterElementImpl element,
  }) {
    return TopLevelSetterItem(
      id: id,
      metadata: ManifestMetadata.encode(
        context,
        element.thisOrVariableMetadata,
      ),
      valueType: element.formalParameters[0].type.encode(context),
    );
  }

  factory TopLevelSetterItem.read(SummaryDataReader reader) {
    return TopLevelSetterItem(
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      valueType: ManifestType.read(reader),
    );
  }

  @override
  bool match(MatchContext context, SetterElementImpl element) {
    return super.match(context, element) &&
        valueType.match(context, element.formalParameters[0].type);
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind.topLevelSetter);
    super.write(sink);
    valueType.write(sink);
  }
}

enum _InstanceItemMemberItemKind { field, constructor, method, getter, setter }

enum _ManifestItemKind {
  class_,
  mixin_,
  topLevelFunction,
  topLevelGetter,
  topLevelSetter,
}

extension FieldItemMapExtension on Map<LookupName, InstanceItemFieldItem> {
  void write(BufferedSink sink) {
    sink.writeMap(
      this,
      writeKey: (name) => name.write(sink),
      writeValue: (items) => items.write(sink),
    );
  }
}

extension LookupNameIdMapExtension on Map<LookupName, ManifestItemId> {
  void write(BufferedSink sink) {
    sink.writeMap(
      this,
      writeKey: (name) => name.write(sink),
      writeValue: (items) => items.write(sink),
    );
  }

  static Map<LookupName, ManifestItemId> read(SummaryDataReader reader) {
    return reader.readMap(
      readKey: () => LookupName.read(reader),
      readValue: () => ManifestItemId.read(reader),
    );
  }
}

extension _AnnotatableElementExtension on AnnotatableElementImpl {
  MetadataImpl get effectiveMetadata {
    if (this case PropertyAccessorElementImpl2 accessor) {
      return accessor.thisOrVariableMetadata;
    }
    return metadata2;
  }
}

extension _AstNodeExtension on AstNode {
  ManifestNode encode(EncodeContext context) {
    return ManifestNode.encode(context, this);
  }
}

extension _GetterElementImplExtension on GetterElementImpl {
  // TODO(scheglov): remove it when add top-level variable
  Expression? get constInitializer {
    if (isSynthetic) {
      var variable = variable3!;
      if (variable.isConst) {
        return variable.constantInitializer2?.expression;
      }
    }
    return null;
  }
}

extension _PropertyAccessExtension on PropertyAccessorElementImpl2 {
  MetadataImpl get thisOrVariableMetadata {
    if (isSynthetic) {
      return variable3!.metadata2;
    } else {
      return metadata2;
    }
  }
}
