// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domains.analysis.implemented_dart;

import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/element.dart';

class ImplementedComputer {
  final SearchEngine searchEngine;
  final CompilationUnitElement unitElement;

  List<protocol.ImplementedClass> classes = <protocol.ImplementedClass>[];
  List<protocol.ImplementedMember> members = <protocol.ImplementedMember>[];

  Set<ClassElement> subtypes;

  ImplementedComputer(this.searchEngine, this.unitElement);

  compute() async {
    for (ClassElement type in unitElement.types) {
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
    String name = type.name;
    if (name != null) {
      int offset = type.nameOffset;
      int length = name.length;
      classes.add(new protocol.ImplementedClass(offset, length));
    }
  }

  void _addImplementedMember(Element member) {
    String name = member.displayName;
    if (name != null) {
      int offset = member.nameOffset;
      int length = name.length;
      members.add(new protocol.ImplementedMember(offset, length));
    }
  }

  void _addMemberIfImplemented(Element element) {
    if (!element.isSynthetic) {
      String name = element.displayName;
      if (name != null && _hasOverride(name)) {
        _addImplementedMember(element);
      }
    }
  }

  bool _hasOverride(String name) {
    for (ClassElement subtype in subtypes) {
      if (subtype.getMethod(name) != null) {
        return true;
      }
      if (subtype.getField(name) != null) {
        return true;
      }
    }
    return false;
  }
}
