// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.hierarchy;

import 'dart:async';
import 'dart:collection';

import 'package:analysis_services/search/element_visitors.dart';
import 'package:analysis_services/search/search_engine.dart';
import 'package:analyzer/src/generated/element.dart';


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
      return;
    }
    if (element is ConstructorElement) {
      return;
    }
    if (name != null && element.displayName != name) {
      return;
    }
    if (element is ExecutableElement) {
      members.add(element);
    }
    if (element is FieldElement) {
      members.add(element);
    }
  });
  return members;
}


/**
 * Returns a [Set] with direct subclasses of [seed].
 */
Future<Set<ClassElement>> getDirectSubClasses(SearchEngine searchEngine,
    ClassElement seed) {
  return searchEngine.searchSubtypes(seed).then((List<SearchMatch> matches) {
    Set<ClassElement> subClasses = new HashSet<ClassElement>();
    for (SearchMatch match in matches) {
      ClassElement subClass = match.element;
      if (subClass.context == seed.context) {
        subClasses.add(subClass);
      }
    }
    return subClasses;
  });
}


/**
 * @return all implementations of the given {@link ClassMemberElement} is its superclasses and
 *         their subclasses.
 */
Future<Set<ClassMemberElement>> getHierarchyMembers(SearchEngine searchEngine,
    ClassMemberElement member) {
  Set<ClassMemberElement> result = new HashSet<ClassMemberElement>();
  // constructor
  if (member is ConstructorElement) {
    result.add(member);
    return new Future.value(result);
  }
  // method, field, etc
  String name = member.displayName;
  ClassElement memberClass = member.enclosingElement;
  List<Future> futures = <Future>[];
  Set<ClassElement> searchClasses = getSuperClasses(memberClass);
  searchClasses.add(memberClass);
  for (ClassElement superClass in searchClasses) {
    // ignore if super- class does not declare member
    if (getClassMembers(superClass, name).isEmpty) {
      continue;
    }
    // check all sub- classes
    var subClassFuture = getSubClasses(searchEngine, superClass);
    var membersFuture = subClassFuture.then((Set<ClassElement> subClasses) {
      subClasses.add(superClass);
      for (ClassElement subClass in subClasses) {
        List<Element> subClassMembers = getChildren(subClass, name);
        for (Element member in subClassMembers) {
          if (member is ClassMemberElement) {
            result.add(member);
          }
        }
      }
    });
    futures.add(membersFuture);
  }
  return Future.wait(futures).then((_) {
    return result;
  });
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
 * Returns a [Set] with all direct and indirect subclasses of [seed].
 */
Future<Set<ClassElement>> getSubClasses(SearchEngine searchEngine,
    ClassElement seed) {
  Set<ClassElement> subs = new HashSet<ClassElement>();
  // prepare queue
  List<ClassElement> queue = new List<ClassElement>();
  queue.add(seed);
  // schedule subclasss search
  addSubClasses() {
    // add direct subclasses of the next class
    while (queue.isNotEmpty) {
      ClassElement clazz = queue.removeLast();
      if (subs.add(clazz)) {
        return getDirectSubClasses(searchEngine, clazz).then((directSubs) {
          queue.addAll(directSubs);
          return new Future(addSubClasses);
        });
      }
    }
    // done
    subs.remove(seed);
    return subs;
  }
  return new Future(addSubClasses);
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
    for (InterfaceType intf in current.interfaces) {
      queue.add(intf.element);
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
