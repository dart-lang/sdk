// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domains.analysis.implemented_dart;

import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element.dart';

class ImplementedComputer {
  final SearchEngine searchEngine;
  final CompilationUnitElement unitElement;

  List<protocol.ImplementedClass> classes = <protocol.ImplementedClass>[];
  List<protocol.ImplementedMember> members = <protocol.ImplementedMember>[];

  Set<ClassElement> subtypes;

  ImplementedComputer(this.searchEngine, this.unitElement);

  compute() async {
    for (ClassElement type in unitElement.types) {
      // always include Object and its members
      if (type.supertype == null) {
        _addImplementedClass(type);
        type.accessors.forEach(_addImplementedMember);
        type.fields.forEach(_addImplementedMember);
        type.methods.forEach(_addImplementedMember);
        continue;
      }
      // analyze ancestors
      subtypes = await getSubClasses(searchEngine, type);
      if (subtypes.isNotEmpty) {
        _addImplementedClass(type);
      }
      type.accessors.forEach(_addMemberIfImplemented);
      type.fields.forEach(_addMemberIfImplemented);
      type.methods.forEach(_addMemberIfImplemented);
    }
  }

  void _addImplementedClass(ClassElement type) {
    int offset = type.nameOffset;
    int length = type.nameLength;
    classes.add(new protocol.ImplementedClass(offset, length));
  }

  void _addImplementedMember(Element member) {
    int offset = member.nameOffset;
    int length = member.nameLength;
    members.add(new protocol.ImplementedMember(offset, length));
  }

  void _addMemberIfImplemented(Element element) {
    if (element.isSynthetic || _isStatic(element)) {
      return;
    }
    String name = element.displayName;
    if (name != null && _hasOverride(name)) {
      _addImplementedMember(element);
    }
  }

  bool _hasOverride(String name) {
    for (ClassElement subtype in subtypes) {
      MethodElement method = subtype.getMethod(name);
      if (method != null) {
        return !method.isStatic;
      }
      FieldElement field = subtype.getField(name);
      if (field != null) {
        return !field.isStatic;
      }
    }
    return false;
  }

  /**
   * Return `true` if the given [element] is a static element.
   */
  static bool _isStatic(Element element) {
    if (element is ExecutableElement) {
      return element.isStatic;
    } else if (element is PropertyInducingElement) {
      return element.isStatic;
    }
    return false;
  }
}
