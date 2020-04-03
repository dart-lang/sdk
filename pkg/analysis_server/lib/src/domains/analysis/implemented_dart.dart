// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element.dart';

class ImplementedComputer {
  final SearchEngine searchEngine;
  final CompilationUnitElement unitElement;

  List<protocol.ImplementedClass> classes = <protocol.ImplementedClass>[];
  List<protocol.ImplementedMember> members = <protocol.ImplementedMember>[];

  Set<String> subtypeMembers;

  ImplementedComputer(this.searchEngine, this.unitElement);

  Future<void> compute() async {
    for (var element in unitElement.mixins) {
      await _computeForClassElement(element);
    }
    for (var element in unitElement.types) {
      await _computeForClassElement(element);
    }
  }

  void _addImplementedClass(ClassElement type) {
    var offset = type.nameOffset;
    var length = type.nameLength;
    classes.add(protocol.ImplementedClass(offset, length));
  }

  void _addImplementedMember(Element member) {
    var offset = member.nameOffset;
    var length = member.nameLength;
    members.add(protocol.ImplementedMember(offset, length));
  }

  void _addMemberIfImplemented(Element element) {
    if (element.isSynthetic || _isStatic(element)) {
      return;
    }
    if (_hasOverride(element)) {
      _addImplementedMember(element);
    }
  }

  Future<void> _computeForClassElement(ClassElement element) async {
    // Always include Object and its members.
    if (element.supertype == null && !element.isMixin) {
      _addImplementedClass(element);
      element.accessors.forEach(_addImplementedMember);
      element.fields.forEach(_addImplementedMember);
      element.methods.forEach(_addImplementedMember);
      return;
    }

    // Analyze subtypes.
    subtypeMembers = await searchEngine.membersOfSubtypes(element);
    if (subtypeMembers != null) {
      _addImplementedClass(element);
      element.accessors.forEach(_addMemberIfImplemented);
      element.fields.forEach(_addMemberIfImplemented);
      element.methods.forEach(_addMemberIfImplemented);
    }
  }

  bool _hasOverride(Element element) {
    var name = element.displayName;
    return subtypeMembers.contains(name);
  }

  /// Return `true` if the given [element] is a static element.
  static bool _isStatic(Element element) {
    if (element is ExecutableElement) {
      return element.isStatic;
    } else if (element is PropertyInducingElement) {
      return element.isStatic;
    }
    return false;
  }
}
