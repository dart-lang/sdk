// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';

class ImplementedComputer {
  final SearchEngine searchEngine;
  final LibraryFragment unitElement;

  List<protocol.ImplementedClass> classes = <protocol.ImplementedClass>[];
  List<protocol.ImplementedMember> members = <protocol.ImplementedMember>[];

  Set<String>? subtypeMembers;

  ImplementedComputer(this.searchEngine, this.unitElement);

  Future<void> compute() async {
    for (var fragment in unitElement.classes2) {
      await _computeForInterfaceElement(fragment.element);
    }
    for (var fragment in unitElement.enums2) {
      await _computeForInterfaceElement(fragment.element);
    }
    for (var fragment in unitElement.extensionTypes2) {
      await _computeForInterfaceElement(fragment.element);
    }
    for (var fragment in unitElement.mixins2) {
      await _computeForInterfaceElement(fragment.element);
    }
  }

  void _addImplementedClass(InterfaceElement2 element) {
    for (var fragment in element.fragments) {
      var offset = fragment.nameOffset2;
      var name = fragment.name2;
      if (offset != null && name != null) {
        classes.add(protocol.ImplementedClass(offset, name.length));
      }
    }
  }

  void _addImplementedMember(Element2 element) {
    for (var fragment in element.fragments) {
      var offset = fragment.nameOffset2;
      var name = fragment.name2;
      if (offset != null && name != null) {
        members.add(protocol.ImplementedMember(offset, name.length));
      }
    }
  }

  void _addMemberIfImplemented(Element2 element) {
    if (element.isSynthetic || _isStatic(element)) {
      return;
    }
    if (_hasOverride(element)) {
      _addImplementedMember(element);
    }
  }

  Future<void> _computeForInterfaceElement(InterfaceElement2 element) async {
    // Always include Object and its members.
    if (element is ClassElement2 && element.isDartCoreObject) {
      _addImplementedClass(element);
      element.getters2.forEach(_addImplementedMember);
      element.setters2.forEach(_addImplementedMember);
      element.fields2.forEach(_addImplementedMember);
      element.methods2.forEach(_addImplementedMember);
      return;
    }

    // Analyze subtypes.
    subtypeMembers = await searchEngine.membersOfSubtypes2(element);
    if (subtypeMembers != null) {
      _addImplementedClass(element);
      element.getters2.forEach(_addMemberIfImplemented);
      element.setters2.forEach(_addMemberIfImplemented);
      element.fields2.forEach(_addMemberIfImplemented);
      element.methods2.forEach(_addMemberIfImplemented);
    }
  }

  bool _hasOverride(Element2 element) {
    var name = element.displayName;
    return subtypeMembers!.contains(name);
  }

  /// Return `true` if the given [element] is a static element.
  static bool _isStatic(Element2 element) {
    if (element is ExecutableElement2) {
      return element.isStatic;
    } else if (element is PropertyInducingElement2) {
      return element.isStatic;
    }
    return false;
  }
}
