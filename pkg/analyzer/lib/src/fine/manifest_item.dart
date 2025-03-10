// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/fine/lookup_name.dart';
import 'package:analyzer/src/fine/manifest_context.dart';
import 'package:analyzer/src/fine/manifest_id.dart';
import 'package:analyzer/src/fine/manifest_type.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

class ClassItem extends TopLevelItem {
  final List<ManifestTypeParameter> typeParameters;
  final ManifestType? supertype;
  final List<ManifestType> interfaces;
  final List<ManifestType> mixins;
  final Map<LookupName, InstanceMemberItem> members;

  ClassItem({
    required super.libraryUri,
    required super.name,
    required super.id,
    required this.typeParameters,
    required this.supertype,
    required this.interfaces,
    required this.mixins,
    required this.members,
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
          interfaces: element.interfaces.encode(context),
          mixins: element.mixins.encode(context),
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
      typeParameters: reader.readTypedList(
        () => ManifestTypeParameter.read(reader),
      ),
      supertype: reader.readOptionalObject((_) => ManifestType.read(reader)),
      interfaces: reader.readTypedList(() => ManifestType.read(reader)),
      mixins: reader.readTypedList(() => ManifestType.read(reader)),
      members: reader.readMap(
        readKey: () => LookupName.read(reader),
        readValue: () => InstanceMemberItem.read(reader),
      ),
    );
  }

  MatchContext? match(ClassElementImpl2 element) {
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
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind.class_);
    sink.writeUri(libraryUri);
    name.write(sink);
    id.write(sink);
    sink.writeList(typeParameters, (e) => e.write(sink));
    sink.writeOptionalObject(supertype, (x) => x.write(sink));
    sink.writeList(interfaces, (x) => x.write(sink));
    sink.writeList(mixins, (x) => x.write(sink));
    sink.writeMap(
      members,
      writeKey: (name) => name.write(sink),
      writeValue: (member) => member.write(sink),
    );
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

class InstanceGetterItem extends InstanceMemberItem {
  final ManifestType returnType;

  InstanceGetterItem({
    required super.name,
    required super.id,
    required this.returnType,
  });

  factory InstanceGetterItem.fromElement({
    required LookupName name,
    required ManifestItemId id,
    required EncodeContext context,
    required GetterElement2OrMember element,
  }) {
    return InstanceGetterItem(
      name: name,
      id: id,
      returnType: element.returnType.encode(context),
    );
  }

  factory InstanceGetterItem.read(SummaryDataReader reader) {
    return InstanceGetterItem(
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
    if (returnType.match(context, element.returnType)) {
      return context;
    }
    return null;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind2.instanceGetter);
    name.write(sink);
    id.write(sink);
    returnType.write(sink);
  }
}

abstract class InstanceMemberItem extends ManifestItem {
  final LookupName name;
  final ManifestItemId id;

  InstanceMemberItem({
    required this.name,
    required this.id,
  });

  factory InstanceMemberItem.read(SummaryDataReader reader) {
    var kind = reader.readEnum(_ManifestItemKind2.values);
    switch (kind) {
      case _ManifestItemKind2.instanceGetter:
        return InstanceGetterItem.read(reader);
      case _ManifestItemKind2.instanceMethod:
        return InstanceMethodItem.read(reader);
    }
  }
}

class InstanceMethodItem extends InstanceMemberItem {
  final List<ManifestTypeParameter> typeParameters;
  final ManifestType returnType;
  final List<ManifestType> formalParameterTypes;

  InstanceMethodItem({
    required super.name,
    required super.id,
    required this.typeParameters,
    required this.returnType,
    required this.formalParameterTypes,
  });

  factory InstanceMethodItem.fromElement({
    required LookupName name,
    required ManifestItemId id,
    required EncodeContext context,
    required MethodElement2OrMember element,
  }) {
    return context.withTypeParameters(
      element.typeParameters2,
      (typeParameters) {
        return InstanceMethodItem(
          name: name,
          id: id,
          typeParameters: typeParameters,
          returnType: element.returnType.encode(context),
          // TODO(scheglov): not only types
          formalParameterTypes: element.formalParameters
              .map((formalParameter) => formalParameter.type)
              .encode(context)
              .toFixedList(),
        );
      },
    );
  }

  factory InstanceMethodItem.read(SummaryDataReader reader) {
    return InstanceMethodItem(
      name: LookupName.read(reader),
      id: ManifestItemId.read(reader),
      typeParameters: reader.readTypedList(
        () => ManifestTypeParameter.read(reader),
      ),
      returnType: ManifestType.read(reader),
      formalParameterTypes: reader.readTypedList(
        () => ManifestType.read(reader),
      ),
    );
  }

  MatchContext? match(
    MatchContext instanceContext,
    MethodElement2OrMember element,
  ) {
    var context = MatchContext(parent: instanceContext);
    context.addTypeParameters(element.typeParameters2);

    if (!ManifestTypeParameter.matchList(
        context, typeParameters, element.typeParameters2)) {
      return null;
    }

    if (returnType.match(context, element.returnType) &&
        formalParameterTypes.match(
            context, element.formalParameters.map((e) => e.type).toList())) {
      return context;
    }
    return null;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind2.instanceMethod);
    name.write(sink);
    id.write(sink);
    sink.writeList(typeParameters, (e) => e.write(sink));
    returnType.write(sink);
    sink.writeList(formalParameterTypes, (type) {
      type.write(sink);
    });
  }
}

sealed class ManifestItem {
  void write(BufferedSink sink);
}

class TopLevelGetterItem extends TopLevelItem {
  final ManifestType returnType;

  TopLevelGetterItem({
    required super.libraryUri,
    required super.name,
    required super.id,
    required this.returnType,
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
      returnType: element.returnType.encode(context),
    );
  }

  factory TopLevelGetterItem.read(SummaryDataReader reader) {
    return TopLevelGetterItem(
      libraryUri: reader.readUri(),
      name: LookupName.read(reader),
      id: ManifestItemId.read(reader),
      returnType: ManifestType.read(reader),
    );
  }

  MatchContext? match(GetterElementImpl element) {
    var context = MatchContext(parent: null);
    if (returnType.match(context, element.returnType)) {
      return context;
    }
    return null;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind.topLevelGetter);
    sink.writeUri(libraryUri);
    name.write(sink);
    id.write(sink);
    returnType.write(sink);
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
      case _ManifestItemKind.topLevelGetter:
        return TopLevelGetterItem.read(reader);
    }
  }
}

enum _ManifestItemKind {
  class_,
  export_,
  topLevelGetter,
}

enum _ManifestItemKind2 {
  instanceGetter,
  instanceMethod,
}
