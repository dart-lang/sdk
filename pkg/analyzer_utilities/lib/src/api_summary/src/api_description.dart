// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_utilities/src/api_summary/src/api_summary_customizer.dart';
import 'package:analyzer_utilities/src/api_summary/src/extensions.dart';
import 'package:analyzer_utilities/src/api_summary/src/member_sorting.dart';
import 'package:analyzer_utilities/src/api_summary/src/node.dart';
import 'package:analyzer_utilities/src/api_summary/src/unique_namer.dart';
import 'package:analyzer_utilities/src/api_summary/src/uri_sorting.dart';
import 'package:collection/collection.dart';

/// Data structure keeping track of a package's API while walking it to produce
/// `api.txt`.
class ApiDescription {
  final ApiSummaryCustomizer _customizer;

  final String _pkgName;

  /// Top level elements that have already had their child elements dumped.
  ///
  /// If an element is seen again in a different library, it will be followed
  /// with `(see above)` (rather than having its child elements dumped twice).
  final _dumpedTopLevelElements = <Element>{};

  /// Top level elements that have been referenced so far and haven't yet been
  /// processed by [build].
  ///
  /// This is used to ensure that all elements referred to by the public API
  /// (e.g., by being mentioned in the type of an API element) also show up in
  /// the output.
  final _potentiallyDanglingReferences = Queue<Element>();

  final _uniqueNamer = UniqueNamer();

  /// Cache of values returned by [_getOrComputeImmediateSubinterfaceMap], to
  /// avoid unnecessary recomputation.
  final _immediateSubinterfaceCache =
      <LibraryElement, Map<ClassElement, Set<InterfaceElement>>>{};

  ApiDescription(this._pkgName, this._customizer);

  /// Builds a list of [Node] objects representing all the libraries that are
  /// relevant to the package's public API.
  ///
  /// This includes libraries that are in the package's public API as well as
  /// libraries that are referenced by the package's public API (either by being
  /// re-exported as part of the package's public API, or by being used as part
  /// of the type of something in the public API).
  ///
  /// Each library node is pared with a [UriSortKey] indicating the order in
  /// which the nodes should be output.
  Future<List<(UriSortKey, Node)>> build(AnalysisContext context) async {
    _customizer.packageName = _pkgName;
    _customizer.analysisContext = context;
    await _customizer.setupComplete();

    // First, find all the libraries comprising the package's public API, and
    // all the top level elements they export.
    var publicApiLibraries = <LibraryElement>[];
    var topLevelPublicElements = <Element>{};
    for (var file in context.contextRoot.analyzedFiles().sorted()) {
      if (!file.endsWith('.dart')) continue;
      var fileResult = context.currentSession.getFile(file) as FileResult;
      var uri = fileResult.uri;
      if (fileResult.isLibrary && uri.isInPublicLibOf(_pkgName)) {
        var resolvedLibraryResult =
            (await context.currentSession.getResolvedLibrary(file))
                as ResolvedLibraryResult;
        var library = resolvedLibraryResult.element;
        topLevelPublicElements.addAll(
          library.exportNamespace.definedNames2.values,
        );
        publicApiLibraries.add(library);
      }
    }
    _customizer.publicApiLibraries = publicApiLibraries;
    _customizer.topLevelPublicElements = topLevelPublicElements;
    await _customizer.initialScanComplete();

    // Then, dump all the libraries in the package's public API.
    var nodes = <Uri, Node<MemberSortKey>>{};
    for (var library in publicApiLibraries) {
      var node = nodes[library.uri] = Node<MemberSortKey>();
      _dumpLibrary(library, node);
    }

    // Finally, dump anything referenced by those public libraries.
    while (_potentiallyDanglingReferences.isNotEmpty) {
      var element = _potentiallyDanglingReferences.removeFirst();
      if (!_dumpedTopLevelElements.add(element)) continue;
      var containingLibraryUri = element.library!.uri;
      var childNode = Node<MemberSortKey>()
        ..text.add(_uniqueNamer.name(element));
      _dumpElement(element, childNode);
      (nodes[containingLibraryUri] ??= Node<MemberSortKey>()
            ..text.add('$containingLibraryUri:'))
          .childNodes
          .add((MemberSortKey(element), childNode));
    }
    return [
      for (var entry in nodes.entries)
        (UriSortKey(entry.key, _pkgName), entry.value),
    ];
  }

  /// Creates a list of objects which, when their string representations are
  /// concatenated, describes [type].
  ///
  /// The reason we use this method rather than [DartType.toString] is to make
  /// sure that (a) every element mentioned by the type is added to
  /// [_potentiallyDanglingReferences], and (b) if an ambiguous name is used,
  /// the ambiguity will be taken care of by [_uniqueNamer].
  List<Object?> _describeType(DartType type) {
    var suffix = switch (type.nullabilitySuffix) {
      NullabilitySuffix.none => '',
      NullabilitySuffix.star => '*',
      NullabilitySuffix.question => '?',
    };
    switch (type) {
      case DynamicType():
        return ['dynamic'];
      case FunctionType(
        :var returnType,
        :var typeParameters,
        :var formalParameters,
      ):
        var params = <List<Object?>>[];
        var optionalParams = <List<Object?>>[];
        var namedParams = <String, List<Object?>>{};
        for (var formalParameter in formalParameters) {
          if (formalParameter.isNamed) {
            namedParams[formalParameter.name!] = [
              if (formalParameter.isDeprecated) 'deprecated ',
              if (formalParameter.isRequired) 'required ',
              ..._describeType(formalParameter.type),
            ];
          } else if (formalParameter.isOptional) {
            optionalParams.add([
              if (formalParameter.isDeprecated) 'deprecated ',
              ..._describeType(formalParameter.type),
            ]);
          } else {
            params.add([
              if (formalParameter.isDeprecated) 'deprecated ',
              ..._describeType(formalParameter.type),
            ]);
          }
        }
        if (optionalParams.isNotEmpty) {
          params.add(optionalParams.separatedBy(prefix: '[', suffix: ']'));
        }
        if (namedParams.isNotEmpty) {
          params.add(
            namedParams.entries
                .sortedBy((e) => e.key)
                .map((e) => [...e.value, ' ${e.key}'])
                .separatedBy(prefix: '{', suffix: '}'),
          );
        }
        return <Object?>[
          ..._describeType(returnType),
          ' Function',
          if (typeParameters.isNotEmpty)
            ...typeParameters
                .map(_describeTypeParameter)
                .separatedBy(prefix: '<', suffix: '>'),
          '(',
          ...params.separatedBy(),
          ')',
          suffix,
        ];
      case InterfaceType(:var element, :var typeArguments):
        _potentiallyDanglingReferences.addLast(element);
        return [
          _uniqueNamer.name(element),
          if (typeArguments.isNotEmpty)
            ...typeArguments
                .map(_describeType)
                .separatedBy(prefix: '<', suffix: '>'),
          suffix,
        ];
      case RecordType(:var positionalFields, :var namedFields):
        if (positionalFields.length == 1 && namedFields.isEmpty) {
          return [
            '(',
            ..._describeType(positionalFields[0].type),
            ',)',
            suffix,
          ];
        }
        return [
          ...[
            for (var positionalField in positionalFields)
              _describeType(positionalField.type),
            if (namedFields.isNotEmpty)
              namedFields
                  .sortedBy((f) => f.name)
                  .map((f) => [..._describeType(f.type), ' ', f.name])
                  .separatedBy(prefix: '{', suffix: '}'),
          ].separatedBy(prefix: '(', suffix: ')'),
          suffix,
        ];
      case TypeParameterType(:var element):
        return [element.name!, suffix];
      case VoidType():
        return ['void'];
      case dynamic(:var runtimeType):
        throw UnimplementedError('Unexpected type: $runtimeType');
    }
  }

  /// Creates a list of objects which, when their string representations are
  /// concatenated, describes [typeParameter].
  List<Object?> _describeTypeParameter(TypeParameterElement typeParameter) {
    return [
      typeParameter.name!,
      if (typeParameter.bound case var bound?) ...[
        ' extends ',
        ..._describeType(bound),
      ],
    ];
  }

  /// Appends information to [node] describing [element].
  void _dumpElement(Element element, Node<MemberSortKey> node) {
    var enclosingElement = element.enclosingElement;
    if (enclosingElement is LibraryElement &&
        !_customizer.shouldShowDetails(element)) {
      if (!enclosingElement.uri.isIn(_pkgName)) {
        node.text.add(' (referenced)');
      } else {
        node.text.add(' (non-public)');
      }
      return;
    }
    var parentheticals = <List<Object?>>[];
    switch (element) {
      case TypeAliasElement(:var aliasedType, :var typeParameters):
        List<Object?> description = ['type alias'];
        if (typeParameters.isNotEmpty) {
          description.addAll(
            typeParameters
                .map(_describeTypeParameter)
                .separatedBy(prefix: '<', suffix: '>'),
          );
        }
        description.addAll([' for ', ..._describeType(aliasedType)]);
        parentheticals.add(description);
      case InstanceElement():
        switch (element) {
          case InterfaceElement(
            :var typeParameters,
            :var supertype,
            :var interfaces,
          ):
            List<Object?> instanceDescription = [
              switch (element) {
                ClassElement() => 'class',
                EnumElement() => 'enum',
                MixinElement() => 'mixin',
                ExtensionTypeElement() => 'extension type',
                dynamic(:var runtimeType) => 'TODO: $runtimeType',
              },
            ];
            if (typeParameters.isNotEmpty) {
              instanceDescription.addAll(
                typeParameters
                    .map(_describeTypeParameter)
                    .separatedBy(prefix: '<', suffix: '>'),
              );
            }
            if (element is! EnumElement && supertype != null) {
              instanceDescription.addAll([
                ' extends ',
                ..._describeType(supertype),
              ]);
            }
            if (element is MixinElement &&
                element.superclassConstraints.isNotEmpty) {
              instanceDescription.addAll(
                element.superclassConstraints
                    .map(_describeType)
                    .separatedBy(prefix: ' on '),
              );
            }
            if (interfaces.isNotEmpty) {
              instanceDescription.addAll(
                interfaces
                    .map(_describeType)
                    .separatedBy(prefix: ' implements '),
              );
            }
            parentheticals.add(instanceDescription);
            if (element is ClassElement) {
              if (element.isSealed) {
                var parenthetical = <Object>['sealed'];
                parentheticals.add(parenthetical);
                if (_getOrComputeImmediateSubinterfaceMap(
                      element.library,
                    )[element]
                    case var subinterfaces?) {
                  parenthetical.add(' (immediate subtypes: ');
                  // Note: it's tempting to just do
                  // `subinterfaces.map(_uniqueNamer.name).join(', ')`, but that
                  // won't work, because the names returned by
                  // `UniqueName.toString()` aren't finalized until we've
                  // visited the entire API and seen if there are class names
                  // that need to be disambiguated. So we accumulate the
                  // `UniqueName` objects into the `parenthetical` list and rely
                  // on `printNodes` converting everything to a string when the
                  // final API description is being output.
                  var commaNeeded = false;
                  for (var subinterface in subinterfaces) {
                    if (commaNeeded) {
                      parenthetical.add(', ');
                    } else {
                      commaNeeded = true;
                    }
                    parenthetical.add(_uniqueNamer.name(subinterface));
                  }
                  parenthetical.add(')');
                }
              } else {
                if (element.isAbstract) {
                  parentheticals.add(['abstract']);
                }
                if (element.isBase) {
                  parentheticals.add(['base']);
                }
                if (element.isMixinClass) {
                  parentheticals.add(['mixin']);
                }
                if (element.isInterface) {
                  parentheticals.add(['interface']);
                }
                if (element.isFinal) {
                  parentheticals.add(['final']);
                }
              }
            } else if (element is MixinElement) {
              if (element.isBase) {
                parentheticals.add(['base']);
              }
            }
          case ExtensionElement(:var extendedType):
            parentheticals.add([
              'extension on ',
              ..._describeType(extendedType),
            ]);
          case dynamic(:var runtimeType):
            throw UnimplementedError('Unexpected element: $runtimeType');
        }
        for (var member in element.children.sortedBy((m) => m.name ?? '')) {
          if (member.name case var name? when name.startsWith('_')) {
            // Ignore private members
            continue;
          }
          if (member is FieldElement) {
            // Ignore fields; we care about the getters and setters they induce.
            continue;
          }
          if (member is ConstructorElement &&
              element is ClassElement &&
              element.isAbstract &&
              (element.isFinal || element.isInterface || element.isSealed)) {
            // The class can't be constructed from outside of the library that
            // declares it, so its constructors aren't part of the public API.
            continue;
          }
          if (member is ConstructorElement && element is EnumElement) {
            // Enum constructors can't be called from outside the enum itself,
            // so they aren't part of the public API.
            continue;
          }
          var childNode = Node<MemberSortKey>();
          childNode.text.add(member.apiName);
          _dumpElement(member, childNode);
          node.childNodes.add((MemberSortKey(member), childNode));
        }
      case TopLevelFunctionElement(:var type):
        parentheticals.add(['function: ', ..._describeType(type)]);
      case ExecutableElement(:var isStatic):
        String maybeStatic = isStatic ? 'static ' : '';
        switch (element) {
          case GetterElement(:var type):
            parentheticals.add([
              '${maybeStatic}getter: ',
              ..._describeType(type.returnType),
            ]);
          case SetterElement(:var type):
            parentheticals.add([
              '${maybeStatic}setter: ',
              ..._describeType(type.formalParameters.single.type),
            ]);
          case MethodElement(:var type):
            parentheticals.add([
              '${maybeStatic}method: ',
              ..._describeType(type),
            ]);
          case ConstructorElement(:var type):
            parentheticals.add(['constructor: ', ..._describeType(type)]);
          case dynamic(:var runtimeType):
            throw UnimplementedError('Unexpected element: $runtimeType');
        }
      case dynamic(:var runtimeType):
        throw UnimplementedError('Unexpected element: $runtimeType');
    }

    // For synthetic elements such as getters/setters induced by top level
    // variables and fields, annotations can be found on the corresponding
    // non-synthetic element.
    var nonSyntheticElement = element.nonSynthetic;
    if (nonSyntheticElement.metadata.hasDeprecated) {
      parentheticals.add(['deprecated']);
    }
    if (nonSyntheticElement.metadata.hasExperimental) {
      parentheticals.add(['experimental']);
    }

    if (parentheticals.isNotEmpty) {
      node.text.addAll(parentheticals.separatedBy(prefix: ' (', suffix: ')'));
    }
    if (node.childNodes.isNotEmpty) {
      node.text.add(':');
    }
  }

  /// Appends information to [node] describing [element].
  void _dumpLibrary(LibraryElement library, Node<MemberSortKey> node) {
    var uri = library.uri;
    node.text.addAll([uri, ':']);
    var definedNames = library.exportNamespace.definedNames2;
    for (var key in definedNames.keys.sorted()) {
      var element = definedNames[key]!;
      var childNode = Node<MemberSortKey>()
        ..text.add(_uniqueNamer.name(element));
      if (!_dumpedTopLevelElements.add(element)) {
        childNode.text.add(' (see above)');
      } else {
        _dumpElement(element, childNode);
      }
      node.childNodes.add((MemberSortKey(element), childNode));
    }
  }

  /// Returns a map from each sealed class in [library] to the set of its
  /// immediate sub-interfaces.
  ///
  /// If this method has been called before with the same [library], a cached
  /// map is returned from [_immediateSubinterfaceCache]. Otherwise a fresh map
  /// is computed.
  Map<ClassElement, Set<InterfaceElement>>
  _getOrComputeImmediateSubinterfaceMap(LibraryElement library) {
    if (_immediateSubinterfaceCache[library] case var m?) return m;
    var result = <ClassElement, Set<InterfaceElement>>{};
    for (var interface in [
      ...library.classes,
      ...library.mixins,
      ...library.enums,
      ...library.extensionTypes,
    ]..sortBy((e) => e.name!)) {
      for (var superinterface in [
        interface.supertype,
        ...interface.interfaces,
        ...interface.mixins,
        if (interface is MixinElement) ...interface.superclassConstraints,
      ]) {
        if (superinterface == null) continue;
        var superinterfaceElement = superinterface.element;
        if (superinterfaceElement is ClassElement &&
            superinterfaceElement.isSealed) {
          (result[superinterfaceElement] ??= {}).add(interface);
        }
      }
    }
    _immediateSubinterfaceCache[library] = result;
    return result;
  }
}
