// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/src/services/search/element_visitors.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/**
 * Returns direct children of [parent].
 */
List<Element> getChildren(Element parent, [String name]) {
  List<Element> children = <Element>[];
  visitChildren(parent, (Element element) {
    if (name == null || element.displayName == name) {
      children.add(element);
    }
  });
  return children;
}

/**
 * Returns direct non-synthetic children of the given [ClassElement].
 *
 * Includes: fields, accessors and methods.
 * Excludes: constructors and synthetic elements.
 */
List<Element> getClassMembers(ClassElement clazz, [String name]) {
  List<Element> members = <Element>[];
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

/**
 * Returns a [Set] with direct subclasses of [seed].
 */
Future<Set<ClassElement>> getDirectSubClasses(
    SearchEngine searchEngine, ClassElement seed) async {
  List<SearchMatch> matches = await searchEngine.searchSubtypes(seed);
  return matches.map((match) => match.element).cast<ClassElement>().toSet();
}

/**
 * @return all implementations of the given {@link ClassMemberElement} is its superclasses and
 *         their subclasses.
 */
Future<Set<ClassMemberElement>> getHierarchyMembers(
    SearchEngine searchEngine, ClassMemberElement member) async {
  Set<ClassMemberElement> result = new HashSet<ClassMemberElement>();
  // static elements
  if (member.isStatic || member is ConstructorElement) {
    result.add(member);
    return new Future.value(result);
  }
  // method, field, etc
  String name = member.displayName;
  ClassElement memberClass = member.enclosingElement;
  Set<ClassElement> searchClasses = getSuperClasses(memberClass);
  searchClasses.add(memberClass);
  for (ClassElement superClass in searchClasses) {
    // ignore if super- class does not declare member
    if (getClassMembers(superClass, name).isEmpty) {
      continue;
    }
    // check all sub- classes
    Set<ClassElement> subClasses =
        await searchEngine.searchAllSubtypes(superClass);
    subClasses.add(superClass);
    for (ClassElement subClass in subClasses) {
      List<Element> subClassMembers = getChildren(subClass, name);
      for (Element member in subClassMembers) {
        if (member is ClassMemberElement) {
          result.add(member);
        }
      }
    }
  }
  return result;
}

/**
 * Returns non-synthetic members of the given [ClassElement] and its super
 * classes.
 *
 * Includes: fields, accessors and methods.
 * Excludes: constructors and synthetic elements.
 */
List<Element> getMembers(ClassElement clazz) {
  List<Element> members = <Element>[];
  members.addAll(getClassMembers(clazz));
  Set<ClassElement> superClasses = getSuperClasses(clazz);
  for (ClassElement superClass in superClasses) {
    members.addAll(getClassMembers(superClass));
  }
  return members;
}

/**
 * Returns a [Set] with all direct and indirect superclasses of [seed].
 */
Set<ClassElement> getSuperClasses(ClassElement seed) {
  Set<ClassElement> result = new HashSet<ClassElement>();
  // prepare queue
  List<ClassElement> queue = new List<ClassElement>();
  queue.add(seed);
  // process queue
  while (!queue.isEmpty) {
    ClassElement current = queue.removeLast();
    // add if not checked already
    if (!result.add(current)) {
      continue;
    }
    // append supertype
    {
      InterfaceType superType = current.supertype;
      if (superType != null) {
        queue.add(superType.element);
      }
    }
    // append interfaces
    for (InterfaceType interface in current.interfaces) {
      queue.add(interface.element);
    }
  }
  // we don't need "seed" itself
  result.remove(seed);
  return result;
}

/**
 * If the given [element] is a synthetic [PropertyAccessorElement] returns
 * its variable, otherwise returns [element].
 */
Element getSyntheticAccessorVariable(Element element) {
  if (element is PropertyAccessorElement) {
    if (element.isSynthetic) {
      return element.variable;
    }
  }
  return element;
}
