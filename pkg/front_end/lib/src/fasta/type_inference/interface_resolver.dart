// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:front_end/src/fasta/problems.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

/// A [ForwardingNode] represents a method, getter, or setter within a class's
/// interface that is either implemented in the class directly or inherited from
/// a superclass.
///
/// This class allows us to defer the determination of exactly which member is
/// inherited, as well as the propagation of covariance annotations, and
/// the creation of forwarding stubs, until type inference.
class ForwardingNode extends Procedure {
  /// A list containing the directly implemented and directly inherited
  /// procedures of the class in question.
  ///
  /// Note that many [ForwardingNode]s share the same [_candidates] list;
  /// consult [_start] and [_end] to see which entries in this list are relevant
  /// to this [ForwardingNode].
  final List<Procedure> _candidates;

  /// Index of the first entry in [_candidates] relevant to this
  /// [ForwardingNode].
  final int _start;

  /// Index just beyond the last entry in [_candidates] relevant to this
  /// [ForwardingNode].
  final int _end;

  ForwardingNode(
      Class class_, Name name, this._candidates, this._start, this._end)
      : super(name, null, null) {
    parent = class_;
  }

  /// For testing: get the list of candidates relevant to a given node.
  static List<Procedure> getCandidates(ForwardingNode node) {
    return node._candidates.sublist(node._start, node._end);
  }
}

/// An [InterfaceResolver] keeps track of the information necessary to resolve
/// method calls, gets, and sets within a chunk of code being compiled, to
/// infer covariance annotations, and to create forwarwding stubs when necessary
/// to meet covariance requirements.
class InterfaceResolver {
  final ClassHierarchy _classHierarchy;

  InterfaceResolver(this._classHierarchy);

  /// Populates [forwardingNodes] with a list of the implemented and inherited
  /// members of the given [class_]'s interface.
  ///
  /// Each member of the class's interface is represented by a [ForwardingNode]
  /// object.
  ///
  /// If [setters] is `true`, the list will be populated by setters; otherwise
  /// it will be populated by getters and methods.
  void createForwardingNodes(
      Class class_, List<ForwardingNode> forwardingNodes, bool setters) {
    // First create a list of candidates for inheritance based on the members
    // declared directly in the class.
    List<Procedure> candidates = _classHierarchy
        .getDeclaredMembers(class_, setters: setters)
        .map((member) => _makeCandidate(member, setters))
        .toList();
    // Merge in candidates from superclasses.
    if (class_.superclass != null) {
      candidates = _mergeCandidates(candidates, class_.superclass, setters);
    }
    for (var supertype in class_.implementedTypes) {
      candidates = _mergeCandidates(candidates, supertype.classNode, setters);
    }
    // Now create a forwarding node for each unique name.
    forwardingNodes.length = candidates.length;
    int storeIndex = 0;
    int i = 0;
    while (i < candidates.length) {
      var name = candidates[i].name;
      int j = i + 1;
      while (j < candidates.length && candidates[j].name == name) {
        j++;
      }
      forwardingNodes[storeIndex++] =
          new ForwardingNode(class_, name, candidates, i, j);
      i = j;
    }
    forwardingNodes.length = storeIndex;
  }

  /// Retrieves a list of the interface members of the given [class_].
  ///
  /// If [setters] is true, setters are retrieved; otherwise getters and methods
  /// are retrieved.
  List<Member> _getInterfaceMembers(Class class_, bool setters) {
    // TODO(paulberry): if class_ is being compiled from source, retrieve its
    // forwarding nodes.
    return _classHierarchy.getInterfaceMembers(class_, setters: setters);
  }

  /// Transforms [member] into a candidate for interface inheritance.
  ///
  /// Fields are transformed into getters and setters; methods are passed
  /// through unchanged.
  Procedure _makeCandidate(Member member, bool setter) {
    if (member is Procedure) return member;
    if (member is Field) {
      // TODO(paulberry): ensure that the field type is propagated to the
      // getter/setter during type inference.
      if (setter) {
        var valueParam = new VariableDeclaration('_');
        var function = new FunctionNode(null,
            positionalParameters: [valueParam], returnType: const VoidType());
        return new SyntheticAccessor(
            member.name, ProcedureKind.Setter, function, member)
          ..parent = member.enclosingClass;
      } else {
        var function = new FunctionNode(null);
        return new SyntheticAccessor(
            member.name, ProcedureKind.Getter, function, member)
          ..parent = member.enclosingClass;
      }
    }
    return unhandled('${member.runtimeType}', '_makeCandidate', -1, null);
  }

  /// Merges together the list of interface inheritance candidates in
  /// [candidates] with interface inheritance candidates from superclass
  /// [class_].
  ///
  /// Any candidates from [class_] are converted into interface inheritance
  /// candidates using [_makeCandidate].
  List<Procedure> _mergeCandidates(
      List<Procedure> candidates, Class class_, bool setters) {
    List<Member> members = _getInterfaceMembers(class_, setters);
    if (candidates.isEmpty) {
      return members.map((member) => _makeCandidate(member, setters)).toList();
    }
    if (members.isEmpty) return candidates;
    List<Procedure> result = <Procedure>[]..length =
        candidates.length + members.length;
    int storeIndex = 0;
    int i = 0, j = 0;
    while (i < candidates.length && j < members.length) {
      Procedure candidate = candidates[i];
      Member member = members[j];
      int compare = ClassHierarchy.compareMembers(candidate, member);
      if (compare <= 0) {
        result[storeIndex++] = candidate;
        ++i;
        // If the same member occurs in both lists, skip the duplicate.
        if (identical(candidate, member)) ++j;
      } else {
        result[storeIndex++] = _makeCandidate(member, setters);
        ++j;
      }
    }
    while (i < candidates.length) {
      result[storeIndex++] = candidates[i++];
    }
    while (j < members.length) {
      result[storeIndex++] = _makeCandidate(members[j++], setters);
    }
    result.length = storeIndex;
    return result;
  }
}

/// A [SyntheticAccessor] represents the getter or setter implied by a field.
class SyntheticAccessor extends Procedure {
  SyntheticAccessor(
      Name name, ProcedureKind kind, FunctionNode function, Field field)
      : super(name, kind, function);
}
