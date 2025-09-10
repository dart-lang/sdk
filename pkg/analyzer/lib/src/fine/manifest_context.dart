// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/binary/binary_reader.dart';
import 'package:analyzer/src/binary/binary_writer.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/fine/lookup_name.dart';
import 'package:analyzer/src/fine/manifest_id.dart';
import 'package:analyzer/src/fine/manifest_item.dart';
import 'package:analyzer/src/fine/manifest_type.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';

class EncodeContext {
  final LinkedElementFactory elementFactory;
  final Map<TypeParameterElement, int> _typeParameters = Map.identity();
  final Map<FormalParameterElement, int> _formalParameters = Map.identity();

  EncodeContext({required this.elementFactory});

  /// Returns the id of [element], or `null` if from this bundle.
  ManifestItemId? getElementId(Element element) {
    return elementFactory.getElementId(element);
  }

  int indexOfFormalParameter(FormalParameterElement element) {
    if (_formalParameters[element] case var result?) {
      return result;
    }

    throw StateError('No formal parameter $element');
  }

  int indexOfTypeParameter(TypeParameterElement element) {
    if (_typeParameters[element] case var bottomIndex?) {
      return _typeParameters.length - 1 - bottomIndex;
    }

    return throw StateError('No type parameter $element');
  }

  T withFormalParameters<T>(
    List<FormalParameterElement> formalParameters,
    T Function() operation,
  ) {
    for (var formalParameter in formalParameters) {
      _formalParameters[formalParameter] = _formalParameters.length;
    }
    try {
      return operation();
    } finally {
      for (var formalParameter in formalParameters) {
        _formalParameters.remove(formalParameter);
      }
    }
  }

  T withTypeParameters<T>(
    List<TypeParameterElementImpl> typeParameters,
    T Function(List<ManifestTypeParameter> typeParameters) operation,
  ) {
    for (var typeParameter in typeParameters) {
      _typeParameters[typeParameter] = _typeParameters.length;
    }

    var encoded = <ManifestTypeParameter>[
      for (var typeParameter in typeParameters)
        ManifestTypeParameter.encode(this, typeParameter),
    ];

    try {
      return operation(encoded);
    } finally {
      for (var typeParameter in typeParameters) {
        _typeParameters.remove(typeParameter);
      }
    }
  }
}

/// The description of an element referenced by a result library.
///
/// For example, if we encode `int get foo`, we want to know that the return
/// type of this getter references `int` from `dart:core`. How exactly we
/// arrived to this type is not important (for the manifest, but not for
/// requirements); it could be `final int foo = 0;` or `final foo = 0;`.
///
/// So, when we link the library next time, and compare the result with the
/// previous manifest, we can check if all the referenced elements are the
/// same.
final class ManifestElement {
  /// The URI of the library that declares the element.
  final Uri libraryUri;

  /// The kind, mostly to distinguish fields and getters.
  final ManifestElementKind kind;

  /// The top-level element name.
  final String topLevelName;

  /// The member name, e.g. a method name.
  final String? memberName;

  /// The id of the element, if not from the same bundle.
  final ManifestItemId? id;

  ManifestElement({
    required this.libraryUri,
    required this.kind,
    required this.topLevelName,
    required this.memberName,
    required this.id,
  });

  factory ManifestElement.read(SummaryDataReader reader) {
    return ManifestElement(
      libraryUri: reader.readUri(),
      kind: reader.readEnum(ManifestElementKind.values),
      topLevelName: reader.readStringUtf8(),
      memberName: reader.readOptionalStringUtf8(),
      id: reader.readOptionalObject(() => ManifestItemId.read(reader)),
    );
  }

  @override
  int get hashCode => Object.hash(libraryUri, kind, topLevelName, memberName);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestElement &&
        other.libraryUri == libraryUri &&
        other.kind == kind &&
        other.topLevelName == topLevelName &&
        other.memberName == memberName;
  }

  /// If [element] matches this description, records the reference and id.
  /// If not, returns `false`, it is a mismatch anyway.
  bool match(MatchContext context, Element element) {
    var enclosingElement = element.enclosingElement!;
    Element givenTopLevelElement;
    Element? givenMemberElement;
    if (enclosingElement is LibraryElement) {
      givenTopLevelElement = element;
    } else {
      givenTopLevelElement = enclosingElement;
      givenMemberElement = element;
    }
    var givenLibraryUri = enclosingElement.library!.uri;

    if (givenLibraryUri != libraryUri) {
      return false;
    }
    if (ManifestElementKind.of(element) != kind) {
      return false;
    }
    if (givenTopLevelElement.lookupName != topLevelName) {
      return false;
    }
    if (givenMemberElement?.lookupName != memberName) {
      return false;
    }

    context.elements.add(element);
    if (id case var id?) {
      context.externalIds[element] = id;
    }
    return true;
  }

  void write(BufferedSink sink) {
    sink.writeUri(libraryUri);
    sink.writeEnum(kind);
    sink.writeStringUtf8(topLevelName);
    sink.writeOptionalStringUtf8(memberName);
    id.writeOptional(sink);
  }

  static ManifestElement encode(EncodeContext context, Element element) {
    Element topLevelElement;
    Element? memberElement;
    var enclosingElement = element.enclosingElement!;
    if (enclosingElement is LibraryElement) {
      topLevelElement = element;
    } else {
      topLevelElement = enclosingElement;
      assert(topLevelElement.enclosingElement is LibraryElement);
      memberElement = element;
    }

    return ManifestElement(
      libraryUri: topLevelElement.library!.uri,
      kind: ManifestElementKind.of(element),
      topLevelName: topLevelElement.lookupName!,
      memberName: memberElement?.lookupName,
      id: context.getElementId(element),
    );
  }

  static ManifestElement? encodeOptional(
    EncodeContext context,
    Element? element,
  ) {
    return element != null ? encode(context, element) : null;
  }

  static List<ManifestElement> readList(SummaryDataReader reader) {
    return reader.readTypedList(() => ManifestElement.read(reader));
  }

  static ManifestElement? readOptional(SummaryDataReader reader) {
    return reader.readOptionalObject(() => ManifestElement.read(reader));
  }
}

/// Note, "instance" means inside [InstanceElement], not as "not static".
enum ManifestElementKind {
  class_,
  enum_,
  extension_,
  extensionType,
  mixin_,
  typeAlias,
  topLevelVariable,
  topLevelGetter,
  topLevelSetter,
  topLevelFunction,
  instanceField,
  instanceGetter,
  instanceSetter,
  instanceMethod,
  interfaceConstructor;

  static ManifestElementKind of(Element element) {
    switch (element) {
      case ClassElement():
        return ManifestElementKind.class_;
      case EnumElement():
        return ManifestElementKind.enum_;
      case ExtensionElement():
        return ManifestElementKind.extension_;
      case ExtensionTypeElement():
        return ManifestElementKind.extensionType;
      case MixinElement():
        return ManifestElementKind.mixin_;
      case TopLevelVariableElement():
        return ManifestElementKind.topLevelVariable;
      case GetterElement():
        if (element.enclosingElement is LibraryElement) {
          return ManifestElementKind.topLevelGetter;
        }
        return ManifestElementKind.instanceGetter;
      case SetterElement():
        if (element.enclosingElement is LibraryElement) {
          return ManifestElementKind.topLevelSetter;
        }
        return ManifestElementKind.instanceSetter;
      case TopLevelFunctionElement():
        return ManifestElementKind.topLevelFunction;
      case FieldElement():
        return ManifestElementKind.instanceField;
      case MethodElement():
        return ManifestElementKind.instanceMethod;
      case ConstructorElement():
        return ManifestElementKind.interfaceConstructor;
      case TypeAliasElement():
        return ManifestElementKind.typeAlias;
      default:
        throw StateError('Unexpected (${element.runtimeType}) $element');
    }
  }
}

class MatchContext {
  final MatchContext? parent;

  /// Any referenced elements, from this bundle or not.
  final Set<Element> elements = {};

  /// The required identifiers of referenced elements that are not from this
  /// bundle.
  final Map<Element, ManifestItemId> externalIds = {};

  final Map<TypeParameterElement, int> _typeParameters = Map.identity();
  final Map<FormalParameterElement, int> _formalParameters = Map.identity();

  MatchContext({required this.parent});

  /// Any referenced elements, from this bundle or not.
  List<Element> get elementList => elements.toList(growable: false);

  void addTypeParameters(List<TypeParameterElement> typeParameters) {
    for (var typeParameter in typeParameters) {
      _typeParameters[typeParameter] = _typeParameters.length;
    }
  }

  int indexOfFormalParameter(FormalParameterElement element) {
    if (_formalParameters[element] case var result?) {
      return result;
    }

    throw StateError('No formal parameter $element');
  }

  int indexOfTypeParameter(TypeParameterElement element) {
    if (_typeParameters[element] case var result?) {
      return _typeParameters.length - 1 - result;
    }

    if (parent case var parent?) {
      var parentIndex = parent.indexOfTypeParameter(element);
      return _typeParameters.length + parentIndex;
    }

    throw StateError('No type parameter $element');
  }

  T withFormalParameters<T>(
    List<FormalParameterElement> formalParameters,
    T Function() operation,
  ) {
    for (var formalParameter in formalParameters) {
      _formalParameters[formalParameter] = _formalParameters.length;
    }
    try {
      return operation();
    } finally {
      for (var formalParameter in formalParameters) {
        _formalParameters.remove(formalParameter);
      }
    }
  }

  T withTypeParameters<T>(
    List<TypeParameterElement> typeParameters,
    T Function() operation,
  ) {
    addTypeParameters(typeParameters);
    try {
      return operation();
    } finally {
      for (var typeParameter in typeParameters) {
        _typeParameters.remove(typeParameter);
      }
    }
  }
}

extension LinkedElementFactoryExtension on LinkedElementFactory {
  /// Returns the id of [element], or `null` if from this bundle.
  ManifestItemId? getElementId(Element element) {
    Element topLevelElement;
    Element? memberElement;
    if (element.enclosingElement is LibraryElement) {
      topLevelElement = element;
    } else {
      topLevelElement = element.enclosingElement!;
      memberElement = element;
    }

    // SAFETY: if we can reference the element, it is in a library.
    var libraryUri = topLevelElement.library!.uri;

    // Prepare the external library manifest.
    var manifest = libraryManifests[libraryUri];
    if (manifest == null) {
      return null;
    }

    // SAFETY: if we can reference the element, it has a name.
    var topLevelName = topLevelElement.lookupName!.asLookupName;
    ManifestItem? topLevelItem;
    switch (topLevelElement) {
      case ClassElement():
        topLevelItem = manifest.declaredClasses[topLevelName];
      case EnumElement():
        topLevelItem = manifest.declaredEnums[topLevelName];
      case ExtensionElement():
        topLevelItem = manifest.declaredExtensions[topLevelName];
      case ExtensionTypeElement():
        topLevelItem = manifest.declaredExtensionTypes[topLevelName];
      case MixinElement():
        topLevelItem = manifest.declaredMixins[topLevelName];
      case GetterElement():
        return manifest.declaredGetters[topLevelName]!.id;
      case SetterElement():
        return manifest.declaredSetters[topLevelName]!.id;
      case TopLevelFunctionElement():
        return manifest.declaredFunctions[topLevelName]!.id;
      case TopLevelVariableElement():
        return manifest.declaredVariables[topLevelName]!.id;
      case TypeAliasElement():
        return manifest.declaredTypeAliases[topLevelName]!.id;
    }

    if (topLevelItem == null) {
      throw StateError(
        'Missing element manifest: (${topLevelElement.runtimeType}) '
        '$topLevelElement in $libraryUri',
      );
    }

    if (memberElement == null) {
      return topLevelItem.id;
    }

    // If not top-level element, then a member in [InstanceElement].
    var memberName = memberElement.lookupName!.asLookupName;
    topLevelItem as InstanceItem;

    switch (element) {
      case FieldElement():
        if (topLevelItem.getDeclaredFieldId(memberName) case var result?) {
          return result;
        }
      case GetterElement():
        if (topLevelItem.getDeclaredGetterId(memberName) case var result?) {
          return result;
        }
      case SetterElement():
        if (topLevelItem.getDeclaredSetterId(memberName) case var result?) {
          return result;
        }
      case MethodElement():
        if (topLevelItem.getDeclaredMethodId(memberName) case var result?) {
          return result;
        }
    }

    // If we get here, the top-level container is not [ExtensionElement].
    // So, it must be [InterfaceElement].
    topLevelItem as InterfaceItem;

    if (element is ConstructorElement) {
      return topLevelItem.getConstructorId(memberName)!;
    }

    // In rare cases the member is not declared by the element, but added
    // to the interface as a result of top-merge.
    return topLevelItem.getInterfaceMethodId(memberName) ??
        (throw '[runtimeType: ${element.runtimeType}]'
            '[topLevelName: $topLevelName]'
            '[memberName: $memberName]');
  }
}

extension ManifestElementExtension on ManifestElement? {
  bool match(MatchContext context, Element? element) {
    if (this case var self?) {
      return element != null && self.match(context, element);
    }
    return element == null;
  }

  void writeOptional(BufferedSink sink) {
    sink.writeOptionalObject(this, (it) {
      it.write(sink);
    });
  }
}
