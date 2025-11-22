// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/search/element_visitors.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// Expand [formalParameters] to include all chains of super formals.
Future<void> addNamedSuperFormalParameters(
  SearchEngine searchEngine,
  List<FormalParameterElement> formalParameters,
) async {
  // Indexed-based loop to allow modification while iterating.
  for (var i = 0; i < formalParameters.length; i++) {
    var formalParameter = formalParameters[i];
    if (formalParameter.isNamed) {
      var references = await searchEngine.searchReferences(formalParameter);
      formalParameters.addAll(
        references
            .map((match) => match.element)
            .whereType<SuperFormalParameterElement>(),
      );
    }
  }
}

/// Returns direct children of [parent].
List<Element> getChildren(Element parent, [String? name]) {
  var children = <Element>[];
  visitChildren(parent, (element) {
    if (name == null || element.name == name) {
      children.add(element);
    }
    return false;
  });
  return children;
}

/// Returns direct non-synthetic children of the given [InterfaceElement].
///
/// Includes: fields, accessors and methods.
/// Excludes: constructors and synthetic elements.
List<Element> getClassMembers(InterfaceElement clazz, [String? name]) {
  var members = <Element>[];
  visitChildren(clazz, (Element element) {
    if (element.isSynthetic) {
      return false;
    }
    if (element is ConstructorElement) {
      return false;
    }
    if (name != null && element.displayName != name) {
      return false;
    }
    if (element is ExecutableElement) {
      members.add(element);
    }
    if (element is FieldElement) {
      members.add(element);
    }
    return false;
  });
  return members;
}

/// Returns a [Set] with direct subclasses of [seed].
///
/// The given [searchEngineCache] will be used or filled out as needed
/// so subsequent calls can utilize it to speed up the computation.
Future<Set<InterfaceElement>> getDirectSubClasses(
  SearchEngine searchEngine,
  InterfaceElement seed,
  SearchEngineCache searchEngineCache,
) async {
  var matches = await searchEngine.searchSubtypes(seed, searchEngineCache);
  return matches.map((match) => match.element).cast<InterfaceElement>().toSet();
}

/// Return the non-synthetic children of the given [extension]. This includes
/// fields, accessors and methods, but excludes synthetic elements.
List<Element> getExtensionMembers(ExtensionElement extension, [String? name]) {
  var members = <Element>[];
  visitChildren(extension, (element) {
    if (element.isSynthetic) {
      return false;
    }
    if (name != null && element.displayName != name) {
      return false;
    }
    if (element is ExecutableElement) {
      members.add(element);
    }
    if (element is FieldElement) {
      members.add(element);
    }
    return false;
  });
  return members;
}

/// Returns all implementations of the given [member], including in its
/// superclasses and their subclasses.
Future<Set<Element>> getHierarchyMembers(
  SearchEngine searchEngine,
  Element member, {
  OperationPerformanceImpl? performance,
}) async {
  var (members, _) = await getHierarchyMembersAndParameters(
    searchEngine,
    member,
    performance: performance,
  );
  return members;
}

/// Returns all implementations of the given [member2], including in its
/// superclasses and their subclasses.
///
/// If [includeParametersForFields] is true and [member2] is a [FieldElement],
/// any [FieldFormalParameterElement]s for the member will also be provided
/// (otherwise, the parameter set will be empty in the result).
Future<(Set<Element>, Set<FormalParameterElement>)>
getHierarchyMembersAndParameters(
  SearchEngine searchEngine,
  Element member2, {
  OperationPerformanceImpl? performance,
  bool includeParametersForFields = false,
}) async {
  performance ??= OperationPerformanceImpl('<root>');
  var members = <Element>{};
  var parameters = <FormalParameterElement>{};
  // extension member
  var enclosingElement = member2.enclosingElement;
  if (enclosingElement is ExtensionElement) {
    members.add(member2);
    return (members, parameters);
  }
  // static elements
  switch (member2) {
    case ConstructorElement():
    case FieldElement(isStatic: true):
    case MethodElement(isStatic: true):
      members.add(member2);
      return (members, parameters);
  }
  // method, field, etc
  if (enclosingElement is InterfaceElement) {
    var name = member2.displayName;

    var superElementsToSearch = enclosingElement.allSupertypes
        .map((superType) => superType.element)
        .where((interface) {
          return member2.isPublic || interface.library == member2.library;
        })
        .toList();
    var searchClasses = [...superElementsToSearch, enclosingElement];
    var subClasses = <InterfaceElement>{};
    for (var superClass in searchClasses) {
      // ignore if super- class does not declare member
      if (getClassMembers(superClass, name).isEmpty) {
        continue;
      }
      // check all sub- classes
      await performance.runAsync(
        'appendAllSubtypes',
        (performance) =>
            searchEngine.appendAllSubtypes(superClass, subClasses, performance),
      );
      subClasses.add(superClass);
    }
    if (member2.isPrivate) {
      subClasses.removeWhere((subClass) => subClass.library != member2.library);
    }
    for (var subClass in subClasses) {
      var subClassMembers = getChildren(subClass, name);
      for (var member in subClassMembers) {
        switch (member) {
          case FieldElement():
            members.add(member);
          case MethodElement():
            members.add(member);
        }
      }

      if (includeParametersForFields && member2 is FieldElement) {
        for (var constructor in subClass.constructors) {
          for (var parameter in constructor.formalParameters) {
            if (parameter is FieldFormalParameterElement &&
                parameter.field == member2) {
              parameters.add(parameter);
            }
          }
        }
      }
    }
    return (members, parameters);
  }

  return (members, parameters);
}

/// If the [element] is a named parameter in a [MethodElement], return all
/// corresponding named parameters in the method hierarchy.
Future<List<FormalParameterElement>> getHierarchyNamedParameters(
  SearchEngine searchEngine,
  FormalParameterElement element,
) async {
  if (element.isNamed) {
    var method = element.enclosingElement;
    if (method is MethodElement) {
      var hierarchyParameters = <FormalParameterElement>[];
      var hierarchyMembers = await getHierarchyMembers(searchEngine, method);
      for (var hierarchyMethod in hierarchyMembers) {
        if (hierarchyMethod is MethodElement) {
          for (var hierarchyParameter in hierarchyMethod.formalParameters) {
            if (hierarchyParameter.isNamed &&
                hierarchyParameter.name == element.name) {
              hierarchyParameters.add(hierarchyParameter);
              break;
            }
          }
        }
      }
      return hierarchyParameters;
    }
  }
  return [element];
}

Future<List<FormalParameterElement>> getHierarchyPositionalParameters(
  SearchEngine searchEngine,
  FormalParameterElement element,
) async {
  if (element.isPositional) {
    var method = element.enclosingElement;
    if (method is MethodElement) {
      var index = method.parameterIndex(element);
      // Should not ever happen but this means we can't find the index.
      if (index == null) {
        return [element];
      }
      var hierarchyParameters = <FormalParameterElement>[];
      var hierarchyMembers = await getHierarchyMembers(searchEngine, method);
      for (var hierarchyMethod in hierarchyMembers) {
        if (hierarchyMethod is MethodElement) {
          for (var hierarchyParameter in hierarchyMethod.formalParameters) {
            if (hierarchyParameter.isPositional &&
                hierarchyMethod.parameterIndex(hierarchyParameter) == index) {
              hierarchyParameters.add(hierarchyParameter);
              break;
            }
          }
        }
      }
      return hierarchyParameters;
    }
  }
  return [element];
}

/// Returns non-synthetic members of the given [InterfaceElement] and its super
/// classes.
///
/// Includes: fields, accessors and methods.
///
/// Excludes: constructors and synthetic elements.
List<Element> getMembers(InterfaceElement clazz) {
  var classElements = [...clazz.allSupertypes.map((e) => e.element), clazz];
  var members = <Element>[];
  for (var superClass in classElements) {
    members.addAll(getClassMembers(superClass));
  }
  return members;
}

/// If the given [element] is a synthetic [PropertyAccessorElement] returns
/// its variable, otherwise returns [element].
Element getSyntheticAccessorVariable(Element element) {
  if (element is PropertyAccessorElement) {
    if (element.isSynthetic) {
      return element.variable;
    }
  }
  return element;
}

extension on MethodElement {
  int? parameterIndex(FormalParameterElement parameter) {
    var index = 0;
    for (var positionalParameter in formalParameters.where(
      (p) => p.isPositional,
    )) {
      if (positionalParameter == parameter) {
        return index;
      }
      index++;
    }
    return null;
  }
}
