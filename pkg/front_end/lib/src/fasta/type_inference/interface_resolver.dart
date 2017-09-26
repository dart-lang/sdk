// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:front_end/src/fasta/problems.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

/// A [ForwardingNode] represents a method, getter, or setter within a class's
/// interface that is either implemented in the class directly or inherited from
/// a superclass.
///
/// This class allows us to defer the determination of exactly which member is
/// inherited, as well as the propagation of covariance annotations, and
/// the creation of forwarding stubs, until type inference.
class ForwardingNode extends Procedure {
  /// The [InterfaceResolver] that created this [ForwardingNode].
  final InterfaceResolver _interfaceResolver;

  /// A list containing the directly implemented and directly inherited
  /// procedures of the class in question.
  ///
  /// Note that many [ForwardingNode]s share the same [_candidates] list;
  /// consult [_start] and [_end] to see which entries in this list are relevant
  /// to this [ForwardingNode].
  final List<Procedure> _candidates;

  /// Indicates whether this forwarding node is for a setter.
  final bool _setter;

  /// Index of the first entry in [_candidates] relevant to this
  /// [ForwardingNode].
  final int _start;

  /// Index just beyond the last entry in [_candidates] relevant to this
  /// [ForwardingNode].
  final int _end;

  /// The member this node resolves to (if it has been computed); otherwise
  /// `null`.
  Member _resolution;

  ForwardingNode(this._interfaceResolver, Class class_, Name name,
      this._candidates, this._setter, this._start, this._end, this._resolution)
      : super(name, null, null) {
    parent = class_;
  }

  /// Returns the inherited member, or the forwarding stub, which this node
  /// resolves to.
  Member resolve() => _resolution ??= _resolve();

  /// Determines which inherited member this node resolves to.
  Member _resolve() {
    // If the class contains a declaration of the member, the resolution is set
    // in the constructor call, so we don't have to deal with that case; we only
    // have to deal with the case where the interface member is inherited from
    // a base class.
    //
    // If there are multiple inheritance candidates, the inherited member is the
    // member whose type is a subtype of all the others.  We can find it by two
    // passes over the list of members.  For the first pass, we step through the
    // candidates, updating bestSoFar each time we find a member whose type is a
    // subtype of the previous bestSoFar.  As we do this, we also work out the
    // necessary substitution for matching up type parameters between this class
    // and the corresponding superclass.
    var bestSoFar = _candidates[_start];
    var bestSubstitutionSoFar = _substitutionFor(bestSoFar);
    var bestTypeSoFar = bestSubstitutionSoFar
        .substituteType(_setter ? bestSoFar.setterType : bestSoFar.getterType);
    for (int i = _start + 1; i < _end; i++) {
      var candidate = _candidates[i];
      var substitution = _substitutionFor(candidate);
      bool isBetter;
      DartType type;
      if (_setter) {
        type = substitution.substituteType(candidate.setterType);
        // Setters are contravariant in their setter type, so we have to reverse
        // the check.
        isBetter = _interfaceResolver._typeEnvironment
            .isSubtypeOf(bestTypeSoFar, type);
      } else {
        type = substitution.substituteType(candidate.getterType);
        isBetter = _interfaceResolver._typeEnvironment
            .isSubtypeOf(type, bestTypeSoFar);
      }
      if (isBetter) {
        bestSoFar = candidate;
        bestSubstitutionSoFar = substitution;
        bestTypeSoFar = type;
      }
    }
    // For the second pass, we verify that bestSoFar is a subtype of all the
    // other potentially inherited members.
    // TODO(paulberry): implement this.

    // TODO(paulberry): now decide whether we need a forwarding stub or not.

    if (bestSoFar is SyntheticAccessor) {
      return bestSoFar._field;
    } else {
      return bestSoFar;
    }
  }

  /// Determines the appropriate substitution to translate type parameters
  /// mentioned in the given [candidate] to type parameters on the parent class.
  Substitution _substitutionFor(Procedure candidate) {
    return Substitution.fromInterfaceType(
        _interfaceResolver._typeEnvironment.hierarchy.getTypeAsInstanceOf(
            enclosingClass.thisType, candidate.enclosingClass));
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
  final TypeEnvironment _typeEnvironment;

  InterfaceResolver(this._typeEnvironment);

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
    List<Procedure> candidates = _typeEnvironment.hierarchy
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
      // If candidates[i] came from this class, then it is the interface member
      // and no forwarding stub needs to be generated.
      var resolvedMember = identical(candidates[i].enclosingClass, class_)
          ? candidates[i]
          : null;
      forwardingNodes[storeIndex++] = new ForwardingNode(
          this, class_, name, candidates, setters, i, j, resolvedMember);
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
    return _typeEnvironment.hierarchy
        .getInterfaceMembers(class_, setters: setters);
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
  /// The field associated with the synthetic accessor.
  final Field _field;

  SyntheticAccessor(
      Name name, ProcedureKind kind, FunctionNode function, this._field)
      : super(name, kind, function);
}
