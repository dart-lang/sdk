// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element.dart';

class ImplementedComputer {
  final SearchEngine searchEngine;
  final LibraryFragment unitElement;

  List<protocol.ImplementedClass> classes = <protocol.ImplementedClass>[];
  List<protocol.ImplementedMember> members = <protocol.ImplementedMember>[];

  Set<String>? subtypeMembers;

  ImplementedComputer(this.searchEngine, this.unitElement);

  Future<void> compute() async {
    for (var fragment in unitElement.classes) {
      await _computeForInterfaceElement(fragment.element);
    }
    for (var fragment in unitElement.enums) {
      await _computeForInterfaceElement(fragment.element);
    }
    for (var fragment in unitElement.extensionTypes) {
      await _computeForInterfaceElement(fragment.element);
    }
    for (var fragment in unitElement.mixins) {
      await _computeForInterfaceElement(fragment.element);
    }
  }

  void _addImplementedClass(InterfaceElement element) {
    for (var fragment in element.fragments) {
      var offset = fragment.nameOffset;
      var name = fragment.name;
      if (offset != null && name != null) {
        classes.add(protocol.ImplementedClass(offset, name.length));
      }
    }
  }

  void _addImplementedMember(Element element) {
    for (var fragment in element.fragments) {
      var offset = fragment.nameOffset;
      var name = fragment.name;
      if (offset != null && name != null) {
        members.add(protocol.ImplementedMember(offset, name.length));
      }
    }
  }

  void _addMemberIfImplemented(Element element) {
    if (_isStatic(element)) {
      return;
    }
    if (_hasOverride(element)) {
      _addImplementedMember(element);
    }
  }

  Future<void> _computeForInterfaceElement(InterfaceElement element) async {
    // Always include Object and its members.
    if (element is ClassElement && element.isDartCoreObject) {
      _addImplementedClass(element);
      element.getters.forEach(_addImplementedMember);
      element.setters.forEach(_addImplementedMember);
      element.fields.forEach(_addImplementedMember);
      element.methods.forEach(_addImplementedMember);
      return;
    }

    // Analyze subtypes.
    subtypeMembers = await searchEngine.membersOfSubtypes(element);
    if (subtypeMembers != null) {
      _addImplementedClass(element);
      element.getters
          .where((e) => e.isOriginDeclaration)
          .forEach(_addMemberIfImplemented);
      element.setters
          .where((e) => e.isOriginDeclaration)
          .forEach(_addMemberIfImplemented);
      element.fields
          .where((e) => e.isOriginDeclaration)
          .forEach(_addMemberIfImplemented);
      element.methods.forEach(_addMemberIfImplemented);
    }
  }

  bool _hasOverride(Element element) {
    var name = element.displayName;
    return subtypeMembers!.contains(name);
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
