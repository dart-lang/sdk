// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/fine/lookup_name.dart';
import 'package:analyzer/src/fine/manifest_id.dart';
import 'package:analyzer/src/fine/manifest_item.dart';
import 'package:analyzer/src/fine/manifest_type.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';

class EncodeContext {
  final LinkedElementFactory elementFactory;
  final Map<TypeParameterElement2, int> _typeParameters = Map.identity();
  final Map<FormalParameterElement, int> _formalParameters = Map.identity();

  EncodeContext({
    required this.elementFactory,
  });

  /// Returns the id of [element], or `null` if from this bundle.
  ManifestItemId? getElementId(Element2 element) {
    return elementFactory.getElementId(element);
  }

  int indexOfFormalParameter(FormalParameterElement element) {
    if (_formalParameters[element] case var result?) {
      return result;
    }

    throw StateError('No formal parameter $element');
  }

  int indexOfTypeParameter(TypeParameterElement2 element) {
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
    List<TypeParameterElement2> typeParameters,
    T Function(List<ManifestTypeParameter> typeParameters) operation,
  ) {
    for (var typeParameter in typeParameters) {
      _typeParameters[typeParameter] = _typeParameters.length;
    }

    var encoded = <ManifestTypeParameter>[
      for (var typeParameter in typeParameters)
        ManifestTypeParameter.encode(this, typeParameter)
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

  /// The top-level element name.
  final String topLevelName;

  /// The member name, e.g. a method name.
  final String? memberName;

  /// The id of the element, if not from the same bundle.
  final ManifestItemId? id;

  ManifestElement({
    required this.libraryUri,
    required this.topLevelName,
    required this.memberName,
    required this.id,
  });

  factory ManifestElement.read(SummaryDataReader reader) {
    return ManifestElement(
      libraryUri: reader.readUri(),
      topLevelName: reader.readStringUtf8(),
      memberName: reader.readOptionalStringUtf8(),
      id: reader.readOptionalObject(() => ManifestItemId.read(reader)),
    );
  }

  @override
  int get hashCode => Object.hash(libraryUri, topLevelName, memberName);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestElement &&
        other.libraryUri == libraryUri &&
        other.topLevelName == topLevelName &&
        other.memberName == memberName;
  }

  /// If [element] matches this description, records the reference and id.
  /// If not, returns `false`, it is a mismatch anyway.
  bool match(MatchContext context, Element2 element) {
    var enclosingElement = element.enclosingElement2!;
    Element2 givenTopLevelElement;
    Element2? givenMemberElement;
    if (enclosingElement is LibraryElement2) {
      givenTopLevelElement = element;
    } else {
      givenTopLevelElement = enclosingElement;
      givenMemberElement = element;
    }
    var givenLibraryUri = enclosingElement.library2!.uri;

    if (givenLibraryUri != libraryUri) {
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
    sink.writeStringUtf8(topLevelName);
    sink.writeOptionalStringUtf8(memberName);
    sink.writeOptionalObject(id, (it) => it.write(sink));
  }

  static ManifestElement encode(
    EncodeContext context,
    Element2 element,
  ) {
    Element2 topLevelElement;
    Element2? memberElement;
    var enclosingElement = element.enclosingElement2!;
    if (enclosingElement is LibraryElement2) {
      topLevelElement = element;
    } else {
      topLevelElement = enclosingElement;
      assert(topLevelElement.enclosingElement2 is LibraryElement2);
      memberElement = element;
    }

    return ManifestElement(
      libraryUri: topLevelElement.library2!.uri,
      topLevelName: topLevelElement.lookupName!,
      memberName: memberElement?.lookupName,
      id: context.getElementId(element),
    );
  }

  static List<ManifestElement> readList(SummaryDataReader reader) {
    return reader.readTypedList(() => ManifestElement.read(reader));
  }
}

class MatchContext {
  final MatchContext? parent;

  /// Any referenced elements, from this bundle or not.
  final Set<Element2> elements = {};

  /// The required identifiers of referenced elements that are not from this
  /// bundle.
  final Map<Element2, ManifestItemId> externalIds = {};

  final Map<TypeParameterElement2, int> _typeParameters = Map.identity();
  final Map<FormalParameterElement, int> _formalParameters = Map.identity();

  MatchContext({
    required this.parent,
  });

  /// Any referenced elements, from this bundle or not.
  List<Element2> get elementList => elements.toList(growable: false);

  void addTypeParameters(List<TypeParameterElement2> typeParameters) {
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

  int indexOfTypeParameter(TypeParameterElement2 element) {
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
    List<TypeParameterElement2> typeParameters,
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
  ManifestItemId? getElementId(Element2 element) {
    Element2 topLevelElement;
    Element2? memberElement;
    if (element.enclosingElement2 is LibraryElement2) {
      topLevelElement = element;
    } else {
      topLevelElement = element.enclosingElement2!;
      memberElement = element;
    }

    // SAFETY: if we can reference the element, it is in a library.
    var libraryUri = topLevelElement.library2!.uri;

    // Prepare the external library manifest.
    var manifest = libraryManifests[libraryUri];
    if (manifest == null) {
      return null;
    }

    // SAFETY: if we can reference the element, it has a name.
    var topLevelName = topLevelElement.lookupName!.asLookupName;
    var topLevelItem = manifest.items[topLevelName];

    // TODO(scheglov): remove it after supporting all elements
    if (topLevelItem == null) {
      return null;
    }

    if (memberElement == null) {
      return topLevelItem.id;
    }

    // TODO(scheglov): When implementation is complete, cast unconditionally.
    if (topLevelItem is InstanceItem) {
      var memberName = memberElement.lookupName!.asLookupName;
      var memberId = topLevelItem.getMemberId(memberName);
      // TODO(scheglov): When implementation is complete, null assert.
      return memberId;
    }

    return null;
  }
}
