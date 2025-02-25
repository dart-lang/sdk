// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/fine/lookup_name.dart';
import 'package:analyzer/src/fine/manifest_id.dart';
import 'package:analyzer/src/fine/manifest_type.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';

class EncodeContext {
  final LinkedElementFactory elementFactory;
  final Map<TypeParameterElement2, int> _typeParameters = {};

  EncodeContext({
    required this.elementFactory,
  });

  /// Returns the id of [element], or `null` if from this bundle.
  ManifestItemId? getElementId(Element2 element) {
    return elementFactory.getElementId(element);
  }

  int indexOfTypeParameter(TypeParameterElement2 element) {
    if (_typeParameters[element] case var bottomIndex?) {
      return _typeParameters.length - 1 - bottomIndex;
    }

    return throw StateError('No type parameter $element');
  }

  T withTypeParameters<T>(
    List<TypeParameterElement2> typeParameters,
    T Function(List<ManifestTypeParameter> typeParameters) operation,
  ) {
    for (var typeParameter in typeParameters) {
      _typeParameters[typeParameter] = _typeParameters.length;
    }

    var encoded = <ManifestTypeParameter>[];
    for (var typeParameter in typeParameters) {
      encoded.add(
        ManifestTypeParameter(
          bound: typeParameter.bound?.encode(this),
        ),
      );
    }

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

  /// The name of the element.
  final String name;

  /// The id of the element, if not from the same bundle.
  final ManifestItemId? id;

  ManifestElement({
    required this.libraryUri,
    required this.name,
    required this.id,
  });

  factory ManifestElement.read(SummaryDataReader reader) {
    return ManifestElement(
      libraryUri: reader.readUri(),
      name: reader.readStringUtf8(),
      id: reader.readOptionalObject((reader) {
        return ManifestItemId.read(reader);
      }),
    );
  }

  @override
  int get hashCode => Object.hash(libraryUri, name);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestElement &&
        other.libraryUri == libraryUri &&
        other.name == name;
  }

  /// If [element] matches this description, records the reference and id.
  /// If not, returns `false`, it is a mismatch anyway.
  bool match(MatchContext context, InstanceElement2 element) {
    if (element.library2.uri == libraryUri && element.name3 == name) {
      context.elements.add(element);
      if (id case var id?) {
        context.externalIds[element] = id;
      }
      return true;
    }
    return false;
  }

  void write(BufferedSink sink) {
    sink.writeUri(libraryUri);
    sink.writeStringUtf8(name);
    sink.writeOptionalObject(id, (it) => it.write(sink));
  }

  static ManifestElement encode(
    EncodeContext context,
    InstanceElement2 element,
  ) {
    return ManifestElement(
      libraryUri: element.library2.uri,
      name: element.name3!,
      id: context.getElementId(element),
    );
  }
}

class MatchContext {
  final MatchContext? parent;

  /// Any referenced elements, from this bundle or not.
  final Set<Element2> elements = {};

  /// The required identifiers of referenced elements that are not from this
  /// bundle.
  final Map<Element2, ManifestItemId> externalIds = {};

  final Map<TypeParameterElement2, int> _typeParameters = {};

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
    // SAFETY: if we can reference the element, it has a name.
    var name = element.lookupName!.asLookupName;

    // SAFETY: if we can reference the element, it is in a library.
    var libraryUri = element.library2!.uri;

    // Prepare the external library manifest.
    var manifest = libraryManifests[libraryUri];
    if (manifest == null) {
      return null;
    }

    // SAFETY: every element is in the manifest of the declaring library.
    // TODO(scheglov): if we do null assert, it fails, investigate
    return manifest.items[name]?.id;
  }
}
