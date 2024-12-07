// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/search/element_visitors.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// Returns direct children of [parent].
List<Element2> getChildren(Element2 parent, [String? name]) {
  var children = <Element2>[];
  visitChildren2(parent, (element) {
    if (name == null || _getBaseName(element) == name) {
      children.add(element);
    }
    return false;
  });
  return children;
}

/// Returns direct non-synthetic children of the given [InterfaceElement2].
///
/// Includes: fields, accessors and methods.
/// Excludes: constructors and synthetic elements.
List<Element2> getClassMembers(InterfaceElement2 clazz, [String? name]) {
  var members = <Element2>[];
  visitChildren2(clazz, (Element2 element) {
    if (element.isSynthetic) {
      return false;
    }
    if (element is ConstructorElement2) {
      return false;
    }
    if (name != null && element.displayName != name) {
      return false;
    }
    if (element is ExecutableElement2) {
      members.add(element);
    }
    if (element is FieldElement2) {
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
Future<Set<InterfaceElement2>> getDirectSubClasses(
  SearchEngine searchEngine,
  InterfaceElement2 seed,
  SearchEngineCache searchEngineCache,
) async {
  var matches = await searchEngine.searchSubtypes2(seed, searchEngineCache);
  return matches
      .map((match) => match.element2)
      .cast<InterfaceElement2>()
      .toSet();
}

/// Return the non-synthetic children of the given [extension]. This includes
/// fields, accessors and methods, but excludes synthetic elements.
List<Element2> getExtensionMembers(
  ExtensionElement2 extension, [
  String? name,
]) {
  var members = <Element2>[];
  visitChildren2(extension, (element) {
    if (element.isSynthetic) {
      return false;
    }
    if (name != null && element.displayName != name) {
      return false;
    }
    if (element is ExecutableElement2) {
      members.add(element);
    }
    if (element is FieldElement2) {
      members.add(element);
    }
    return false;
  });
  return members;
}

/// Return all implementations of the given [member], including in its
/// superclasses and their subclasses.
///
/// If [includeParametersForFields] is true and [member] is a [FieldElement2],
/// any [FieldFormalParameterElement2]s for the member will also be provided
/// (otherwise, the parameter set will be empty in the result).
Future<Set<Element2>> getHierarchyMembers(
  SearchEngine searchEngine,
  Element2 member, {
  OperationPerformanceImpl? performance,
}) async {
  var (members, _) = await getHierarchyMembersAndParameters(
    searchEngine,
    member,
    performance: performance,
  );
  return members;
}

/// Return all implementations of the given [member], including in its
/// superclasses and their subclasses.
///
/// If [includeParametersForFields] is true and [member] is a [FieldElement2],
/// any [FieldFormalParameterElement2]s for the member will also be provided
/// (otherwise, the parameter set will be empty in the result).
Future<(Set<Element2>, Set<FormalParameterElement>)>
getHierarchyMembersAndParameters(
  SearchEngine searchEngine,
  Element2 member2, {
  OperationPerformanceImpl? performance,
  bool includeParametersForFields = false,
}) async {
  performance ??= OperationPerformanceImpl('<root>');
  var members = <Element2>{};
  var parameters = <FormalParameterElement>{};
  // extension member
  var enclosingElement2 = member2.enclosingElement2;
  if (enclosingElement2 is ExtensionElement2) {
    members.add(member2);
    return (members, parameters);
  }
  // static elements
  switch (member2) {
    case ConstructorElement2():
    case FieldElement2(isStatic: true):
    case MethodElement2(isStatic: true):
      members.add(member2);
      return (members, parameters);
  }
  // method, field, etc
  if (enclosingElement2 is InterfaceElement2) {
    var name = member2.displayName;

    var superElementsToSearch =
        enclosingElement2.allSupertypes
            .map((superType) => superType.element3)
            .where((interface) {
              return member2.isPublic || interface.library2 == member2.library2;
            })
            .toList();
    var searchClasses = [...superElementsToSearch, enclosingElement2];
    var subClasses = <InterfaceElement2>{};
    for (var superClass in searchClasses) {
      // ignore if super- class does not declare member
      if (getClassMembers(superClass, name).isEmpty) {
        continue;
      }
      // check all sub- classes
      await performance.runAsync(
        'appendAllSubtypes',
        (performance) => searchEngine.appendAllSubtypes2(
          superClass,
          subClasses,
          performance,
        ),
      );
      subClasses.add(superClass);
    }
    if (member2.isPrivate) {
      subClasses.removeWhere(
        (subClass) => subClass.library2 != member2.library2,
      );
    }
    for (var subClass in subClasses) {
      var subClassMembers = getChildren(subClass, name);
      for (var member in subClassMembers) {
        switch (member) {
          case ConstructorElement2():
            members.add(member);
          case FieldElement2():
            members.add(member);
          case MethodElement2():
            members.add(member);
        }
      }

      if (includeParametersForFields && member2 is FieldElement2) {
        for (var constructor in subClass.constructors2) {
          for (var parameter in constructor.formalParameters) {
            if (parameter is FieldFormalParameterElement2 &&
                parameter.field2 == member2) {
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

/// If the [element] is a named parameter in a [MethodElement2], return all
/// corresponding named parameters in the method hierarchy.
Future<List<FormalParameterElement>> getHierarchyNamedParameters(
  SearchEngine searchEngine,
  FormalParameterElement element,
) async {
  if (element.isNamed) {
    var method = element.enclosingElement2;
    if (method is MethodElement2) {
      var hierarchyParameters = <FormalParameterElement>[];
      var hierarchyMembers = await getHierarchyMembers(searchEngine, method);
      for (var hierarchyMethod in hierarchyMembers) {
        if (hierarchyMethod is MethodElement2) {
          for (var hierarchyParameter in hierarchyMethod.formalParameters) {
            if (hierarchyParameter.isNamed &&
                hierarchyParameter.name3 == element.name3) {
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

/// Returns non-synthetic members of the given [InterfaceElement2] and its super
/// classes.
///
/// Includes: fields, accessors and methods.
///
/// Excludes: constructors and synthetic elements.
List<Element2> getMembers(InterfaceElement2 clazz) {
  var classElements = [...clazz.allSupertypes.map((e) => e.element3), clazz];
  var members = <Element2>[];
  for (var superClass in classElements) {
    members.addAll(getClassMembers(superClass));
  }
  return members;
}

/// If the given [element] is a synthetic [PropertyAccessorElement2] returns
/// its variable, otherwise returns [element].
Element2 getSyntheticAccessorVariable(Element2 element) {
  if (element is PropertyAccessorElement2) {
    if (element.isSynthetic) {
      return element.variable3 ?? element;
    }
  }
  return element;
}

String? _getBaseName(Element2 element) {
  if (element is SetterElement) {
    var name = element.name3;
    return name?.substring(0, name.length - 1);
  }
  return element.name3;
}
