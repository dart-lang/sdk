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

class ClassItem extends InterfaceItem {
  ClassItem({
    required super.libraryUri,
    required super.name,
    required super.id,
    required super.typeParameters,
    required super.supertype,
    required super.interfaces,
    required super.mixins,
    required super.members,
  });

  factory ClassItem.fromElement({
    required LookupName name,
    required ManifestItemId id,
    required EncodeContext context,
    required ClassElementImpl2 element,
  }) {
    return context.withTypeParameters(
      element.typeParameters2,
      (typeParameters) {
        return ClassItem(
          libraryUri: element.library2.uri,
          name: name,
          id: id,
          typeParameters: typeParameters,
          supertype: element.supertype?.encode(context),
          mixins: element.mixins.encode(context),
          interfaces: element.interfaces.encode(context),
          members: {},
        );
      },
    );
  }

  factory ClassItem.read(SummaryDataReader reader) {
    return ClassItem(
      libraryUri: reader.readUri(),
      name: LookupName.read(reader),
      id: ManifestItemId.read(reader),
      typeParameters: ManifestTypeParameter.readList(reader),
      members: InstanceItem._readMembers(reader),
      supertype: ManifestType.readOptional(reader),
      mixins: ManifestType.readList(reader),
      interfaces: ManifestType.readList(reader),
    );
  }

  MatchContext? match(ClassElementImpl2 element) {
    return super._matchInterfaceElement(element);
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind.class_);
    super._write(sink);
  }
}

class ExportItem extends TopLevelItem {
  ExportItem({
    required super.libraryUri,
    required super.name,
    required super.id,
  });

  factory ExportItem.read(SummaryDataReader reader) {
    return ExportItem(
      libraryUri: reader.readUri(),
      name: LookupName.read(reader),
      id: ManifestItemId.read(reader),
    );
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind.export_);
    sink.writeUri(libraryUri);
    name.write(sink);
    id.write(sink);
  }
}

/// The item for [InstanceElementImpl2].
sealed class InstanceItem extends TopLevelItem {
  final List<ManifestTypeParameter> typeParameters;
  final Map<LookupName, InstanceItemMemberItem> members;

  InstanceItem({
    required super.libraryUri,
    required super.name,
    required super.id,
    required this.typeParameters,
    required this.members,
  });

  void _write(BufferedSink sink) {
    sink.writeUri(libraryUri);
    name.write(sink);
    id.write(sink);
    typeParameters.writeList(sink);
    sink.writeMap(
      members,
      writeKey: (name) => name.write(sink),
      writeValue: (member) => member.write(sink),
    );
  }

  static Map<LookupName, InstanceItemMemberItem> _readMembers(
    SummaryDataReader reader,
  ) {
    return reader.readMap(
      readKey: () => LookupName.read(reader),
      readValue: () => InstanceItemMemberItem.read(reader),
    );
  }
}

class InstanceItemGetterItem extends InstanceItemMemberItem {
  final ManifestType returnType;

  InstanceItemGetterItem({
    required super.name,
    required super.id,
    required this.returnType,
  });

  factory InstanceItemGetterItem.fromElement({
    required LookupName name,
    required ManifestItemId id,
    required EncodeContext context,
    required GetterElement2OrMember element,
  }) {
    return InstanceItemGetterItem(
      name: name,
      id: id,
      returnType: element.returnType.encode(context),
    );
  }

  factory InstanceItemGetterItem.read(SummaryDataReader reader) {
    return InstanceItemGetterItem(
      name: LookupName.read(reader),
      id: ManifestItemId.read(reader),
      returnType: ManifestType.read(reader),
    );
  }

  MatchContext? match(
    MatchContext instanceContext,
    GetterElement2OrMember element,
  ) {
    var context = MatchContext(parent: instanceContext);
    if (!returnType.match(context, element.returnType)) {
      return null;
    }
    return context;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind2.instanceGetter);
    name.write(sink);
    id.write(sink);
    returnType.write(sink);
  }
}

sealed class InstanceItemMemberItem extends ManifestItem {
  final LookupName name;
  final ManifestItemId id;

  InstanceItemMemberItem({
    required this.name,
    required this.id,
  });

  factory InstanceItemMemberItem.read(SummaryDataReader reader) {
    var kind = reader.readEnum(_ManifestItemKind2.values);
    switch (kind) {
      case _ManifestItemKind2.instanceGetter:
        return InstanceItemGetterItem.read(reader);
      case _ManifestItemKind2.instanceMethod:
        return InstanceItemMethodItem.read(reader);
      case _ManifestItemKind2.interfaceConstructor:
        return InterfaceItemConstructorItem.read(reader);
    }
  }
}

class InstanceItemMethodItem extends InstanceItemMemberItem {
  final ManifestFunctionType functionType;

  InstanceItemMethodItem({
    required super.name,
    required super.id,
    required this.functionType,
  });

  factory InstanceItemMethodItem.fromElement({
    required LookupName name,
    required ManifestItemId id,
    required EncodeContext context,
    required MethodElement2OrMember element,
  }) {
    return InstanceItemMethodItem(
      name: name,
      id: id,
      functionType: element.type.encode(context),
    );
  }

  factory InstanceItemMethodItem.read(SummaryDataReader reader) {
    return InstanceItemMethodItem(
      name: LookupName.read(reader),
      id: ManifestItemId.read(reader),
      functionType: ManifestFunctionType.read(reader),
    );
  }

  MatchContext? match(
    MatchContext instanceContext,
    MethodElement2OrMember element,
  ) {
    var context = MatchContext(parent: instanceContext);
    if (!functionType.match(context, element.type)) {
      return null;
    }
    return context;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind2.instanceMethod);
    name.write(sink);
    id.write(sink);
    functionType.writeNoTag(sink);
  }
}

/// The item for [InterfaceElementImpl2].
sealed class InterfaceItem extends InstanceItem {
  final ManifestType? supertype;
  final List<ManifestType> interfaces;
  final List<ManifestType> mixins;

  InterfaceItem({
    required super.libraryUri,
    required super.name,
    required super.id,
    required super.typeParameters,
    required super.members,
    required this.supertype,
    required this.interfaces,
    required this.mixins,
  });

  MatchContext? _matchInterfaceElement(InterfaceElementImpl2 element) {
    var context = MatchContext(parent: null);
    context.addTypeParameters(element.typeParameters2);
    if (supertype.match(context, element.supertype) &&
        interfaces.match(context, element.interfaces) &&
        mixins.match(context, element.mixins)) {
      return context;
    }
    return null;
  }

  @override
  void _write(BufferedSink sink) {
    super._write(sink);
    supertype.writeOptional(sink);
    mixins.writeList(sink);
    interfaces.writeList(sink);
  }
}

class InterfaceItemConstructorItem extends InstanceItemMemberItem {
  final bool isConst;
  final bool isFactory;
  final ManifestFunctionType functionType;

  InterfaceItemConstructorItem({
    required super.name,
    required super.id,
    required this.isConst,
    required this.isFactory,
    required this.functionType,
  });

  factory InterfaceItemConstructorItem.fromElement({
    required LookupName name,
    required ManifestItemId id,
    required EncodeContext context,
    required ConstructorElementImpl2 element,
  }) {
    // TODO(scheglov): initializers
    return InterfaceItemConstructorItem(
      name: name,
      id: id,
      isConst: element.isConst,
      isFactory: element.isFactory,
      functionType: element.type.encode(context),
    );
  }

  factory InterfaceItemConstructorItem.read(SummaryDataReader reader) {
    return InterfaceItemConstructorItem(
      name: LookupName.read(reader),
      id: ManifestItemId.read(reader),
      isConst: reader.readBool(),
      isFactory: reader.readBool(),
      functionType: ManifestFunctionType.read(reader),
    );
  }

  MatchContext? match(
    MatchContext instanceContext,
    ConstructorElementImpl2 element,
  ) {
    var context = MatchContext(parent: instanceContext);
    if (isConst != element.isConst) {
      return null;
    }
    if (isFactory != element.isFactory) {
      return null;
    }
    if (!functionType.match(context, element.type)) {
      return null;
    }
    return context;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind2.interfaceConstructor);
    name.write(sink);
    id.write(sink);
    sink.writeBool(isConst);
    sink.writeBool(isFactory);
    functionType.writeNoTag(sink);
  }
}

class ManifestAnnotation {
  final ManifestNode ast;

  ManifestAnnotation({
    required this.ast,
  });

  factory ManifestAnnotation.read(SummaryDataReader reader) {
    return ManifestAnnotation(
      ast: ManifestNode.read(reader),
    );
  }

  bool match(MatchContext context, ElementAnnotationImpl annotation) {
    var annotationAst = annotation.annotationAst;
    if (!ast.match(context, annotationAst)) {
      return false;
    }
    return true;
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

sealed class ManifestItem {
  void write(BufferedSink sink);
}

class ManifestMetadata {
  final List<ManifestAnnotation> annotations;

  ManifestMetadata({
    required this.annotations,
  });

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

class TopLevelFunctionItem extends TopLevelItem {
  final ManifestFunctionType functionType;

  TopLevelFunctionItem({
    required super.libraryUri,
    required super.name,
    required super.id,
    required this.functionType,
  });

  factory TopLevelFunctionItem.fromElement({
    required LookupName name,
    required ManifestItemId id,
    required EncodeContext context,
    required TopLevelFunctionElementImpl element,
  }) {
    return TopLevelFunctionItem(
      libraryUri: element.library2.uri,
      name: name,
      id: id,
      functionType: element.type.encode(context),
    );
  }

  factory TopLevelFunctionItem.read(SummaryDataReader reader) {
    return TopLevelFunctionItem(
      libraryUri: reader.readUri(),
      name: LookupName.read(reader),
      id: ManifestItemId.read(reader),
      functionType: ManifestFunctionType.read(reader),
    );
  }

  MatchContext? match(
    TopLevelFunctionElementImpl element,
  ) {
    var context = MatchContext(parent: null);
    if (!functionType.match(context, element.type)) {
      return null;
    }

    return context;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind.topLevelFunction);
    sink.writeUri(libraryUri);
    name.write(sink);
    id.write(sink);
    functionType.writeNoTag(sink);
  }
}

class TopLevelGetterItem extends TopLevelItem {
  final ManifestMetadata metadata;
  final ManifestType returnType;
  final ManifestNode? constInitializer;

  TopLevelGetterItem({
    required super.libraryUri,
    required super.name,
    required super.id,
    required this.metadata,
    required this.returnType,
    required this.constInitializer,
  });

  factory TopLevelGetterItem.fromElement({
    required LookupName name,
    required ManifestItemId id,
    required EncodeContext context,
    required GetterElementImpl element,
  }) {
    return TopLevelGetterItem(
      libraryUri: element.library2.uri,
      name: name,
      id: id,
      metadata: ManifestMetadata.encode(context, element.metadata2),
      returnType: element.returnType.encode(context),
      constInitializer: element.constInitializer?.encode(context),
    );
  }

  factory TopLevelGetterItem.read(SummaryDataReader reader) {
    return TopLevelGetterItem(
      libraryUri: reader.readUri(),
      name: LookupName.read(reader),
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      returnType: ManifestType.read(reader),
      constInitializer: ManifestNode.readOptional(reader),
    );
  }

  MatchContext? match(GetterElementImpl element) {
    var context = MatchContext(parent: null);

    if (!metadata.match(context, element.metadata2)) {
      return null;
    }

    if (!returnType.match(context, element.returnType)) {
      return null;
    }

    if (!constInitializer.match(context, element.constInitializer)) {
      return null;
    }

    return context;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind.topLevelGetter);
    sink.writeUri(libraryUri);
    name.write(sink);
    id.write(sink);
    metadata.write(sink);
    returnType.write(sink);
    constInitializer.writeOptional(sink);
  }
}

sealed class TopLevelItem extends ManifestItem {
  /// The URI of the declaring library, mostly for debugging.
  final Uri libraryUri;

  /// The name of the item, mostly for debugging.
  final LookupName name;

  /// The unique identifier of this item.
  final ManifestItemId id;

  TopLevelItem({
    required this.libraryUri,
    required this.name,
    required this.id,
  });

  factory TopLevelItem.read(SummaryDataReader reader) {
    var kind = reader.readEnum(_ManifestItemKind.values);
    switch (kind) {
      case _ManifestItemKind.class_:
        return ClassItem.read(reader);
      case _ManifestItemKind.export_:
        return ExportItem.read(reader);
      case _ManifestItemKind.topLevelFunction:
        return TopLevelFunctionItem.read(reader);
      case _ManifestItemKind.topLevelGetter:
        return TopLevelGetterItem.read(reader);
      case _ManifestItemKind.topLevelSetter:
        return TopLevelSetterItem.read(reader);
    }
  }
}

class TopLevelSetterItem extends TopLevelItem {
  final ManifestMetadata metadata;
  final ManifestType valueType;

  TopLevelSetterItem({
    required super.libraryUri,
    required super.name,
    required super.id,
    required this.metadata,
    required this.valueType,
  });

  factory TopLevelSetterItem.fromElement({
    required LookupName name,
    required ManifestItemId id,
    required EncodeContext context,
    required SetterElementImpl element,
  }) {
    return TopLevelSetterItem(
      libraryUri: element.library2.uri,
      name: name,
      id: id,
      metadata: ManifestMetadata.encode(context, element.metadata2),
      valueType: element.formalParameters[0].type.encode(context),
    );
  }

  factory TopLevelSetterItem.read(SummaryDataReader reader) {
    return TopLevelSetterItem(
      libraryUri: reader.readUri(),
      name: LookupName.read(reader),
      id: ManifestItemId.read(reader),
      metadata: ManifestMetadata.read(reader),
      valueType: ManifestType.read(reader),
    );
  }

  MatchContext? match(SetterElementImpl element) {
    var context = MatchContext(parent: null);

    if (!metadata.match(context, element.metadata2)) {
      return null;
    }

    if (!valueType.match(context, element.formalParameters[0].type)) {
      return null;
    }

    return context;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind.topLevelSetter);
    sink.writeUri(libraryUri);
    name.write(sink);
    id.write(sink);
    metadata.write(sink);
    valueType.write(sink);
  }
}

enum _ManifestItemKind {
  class_,
  export_,
  topLevelFunction,
  topLevelGetter,
  topLevelSetter,
}

enum _ManifestItemKind2 {
  instanceGetter,
  instanceMethod,
  interfaceConstructor,
}

extension _AstNodeExtension on AstNode {
  ManifestNode encode(EncodeContext context) {
    return ManifestNode.encode(context, this);
  }
}

extension _GetterElementImplExtension on GetterElementImpl {
  Expression? get constInitializer {
    Expression? constInitializer;
    if (isSynthetic) {
      var variable = variable3!;
      if (variable.isConst) {
        constInitializer = variable.constantInitializer2?.expression;
      }
    }

    // TODO(scheglov): support all expressions
    switch (constInitializer) {
      case IntegerLiteral():
      case SimpleIdentifier():
        break;
      default:
        constInitializer = null;
    }
    return constInitializer;
  }
}
