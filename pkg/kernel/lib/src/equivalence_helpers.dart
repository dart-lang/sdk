// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'equivalence.dart';

/// The node or property currently visited by the [EquivalenceVisitor].
abstract class State {
  const State();

  State? get parent;
}

/// State for visiting two AST nodes in [EquivalenceVisitor].
class NodeState extends State {
  final State? parent;
  final Node a;
  final Node b;

  NodeState(this.a, this.b, [this.parent]);
}

/// State for visiting an AST property in [EquivalenceVisitor]
class PropertyState extends State {
  final State? parent;
  final String name;

  PropertyState(this.name, [this.parent]);
}

/// The state of the equivalence visitor.
///
/// This holds the currently found inequivalences and the current assumptions.
/// This also determines whether inequivalence are currently reported.
class CheckingState {
  /// If `true`, inequivalences are currently reported.
  final bool isAsserting;

  CheckingState(
      {this.isAsserting: true,
      UnionFind<Reference>? assumedReferences,
      State? currentState})
      : _assumedReferences = assumedReferences ?? new UnionFind<Reference>(),
        _currentState = currentState;

  /// Create a new [CheckingState] that inherits the [_currentState] and a copy
  /// of the current assumptions. If [isAsserting] is `true`, the new state
  /// will register inequivalences.
  CheckingState createSubState({bool isAsserting: false}) {
    return new CheckingState(
        isAsserting: isAsserting,
        assumedReferences: _assumedReferences.clone(),
        currentState: _currentState)
      .._assumedDeclarationMap.addAll(_assumedDeclarationMap);
  }

  /// Returns a state corresponding to the state which does _not_ register
  /// inequivalences. If this state is already not registering inequivalences,
  /// `this` is returned.
  CheckingState toMatchingState() {
    if (!isAsserting) return this;
    return createSubState(isAsserting: false);
  }

  /// Returns that value that should be used as the result value when
  /// inequivalence are found.
  ///
  /// See [EquivalenceVisitor.resultOnInequivalence] for details.
  bool get resultOnInequivalence => isAsserting;

  /// Map of [Reference]s that are assumed to be equivalent. The keys are
  /// the [Reference]s on the left side of the equivalence relation.
  UnionFind<Reference> _assumedReferences;

  /// Returns `true` if [a] and [b] are currently assumed to be equivalent.
  bool checkAssumedReferences(Reference? a, Reference? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    return _assumedReferences.valuesInSameSet(a, b);
  }

  /// Assume that [a] and [b] are equivalent, if possible.
  ///
  /// Returns `true` if [a] and [b] could be assumed to be equivalent. This
  /// is not the case if either [a] or [b] is `null`.
  bool assumeReferences(Reference? a, Reference? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    _assumedReferences.unionOfValues(a, b);
    return true;
  }

  /// Map of declarations that are assumed to be equivalent.
  Map<dynamic, dynamic> _assumedDeclarationMap = {};

  /// Returns `true` if [a] and [b] are currently assumed to be equivalent.
  bool checkAssumedDeclarations(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    return _assumedDeclarationMap.containsKey(a) &&
        _assumedDeclarationMap[a] == b;
  }

  /// Assume that [a] and [b] are equivalent, if possible.
  ///
  /// Returns `true` if [a] and [b] could be assumed to be equivalent. This
  /// would not be the case if [a] is already assumed to be equivalent to
  /// another declaration.
  bool assumeDeclarations(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (_assumedDeclarationMap.containsKey(a)) {
      return _assumedDeclarationMap[a] == b;
    } else {
      _assumedDeclarationMap[a] = b;
      return true;
    }
  }

  /// The currently visited node or property.
  State? _currentState;

  /// Enters a new property state of a property named [propertyName].
  void pushPropertyState(String propertyName) {
    _currentState = new PropertyState(propertyName, _currentState);
  }

  /// Enters a new node state of nodes [a] and [b].
  void pushNodeState(Node a, Node b) {
    _currentState = new NodeState(a, b, _currentState);
  }

  /// Leaves the current node or property.
  void popState() {
    _currentState = _currentState?.parent;
  }

  /// List of registered inequivalences.
  List<Inequivalence> _inequivalences = [];

  /// Registers the inequivalence [message] on [propertyName].
  void registerInequivalence(String propertyName, String message) {
    _inequivalences.add(new Inequivalence(
        new PropertyState(propertyName, _currentState), message));
  }

  /// Returns `true` if inequivalences have been registered.
  bool get hasInequivalences => _inequivalences.isNotEmpty;

  /// Returns the [EquivalenceResult] for the registered inequivalences. If
  /// [hasInequivalences] is `true`, the result is marked has having
  /// inequivalences, even when none have been registered.
  EquivalenceResult toResult({bool hasInequivalences: false}) =>
      new EquivalenceResult(
          hasInequivalences: hasInequivalences,
          registeredInequivalences: _inequivalences.toList());
}

/// The result of performing equivalence checking.
class EquivalenceResult {
  final bool hasInequivalences;
  final List<Inequivalence> registeredInequivalences;

  EquivalenceResult(
      {this.hasInequivalences: false, required this.registeredInequivalences});

  bool get isEquivalent =>
      !hasInequivalences && registeredInequivalences.isEmpty;

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    for (Inequivalence inequivalence in registeredInequivalences) {
      sb.writeln(inequivalence);
    }
    return sb.toString();
  }
}

/// A registered inequivalence holding the [state] at which is was found and
/// details about the inequivalence.
class Inequivalence {
  final State state;
  final String message;

  Inequivalence(this.state, this.message);

  @override
  String toString() {
    List<State> states = [];
    State? state = this.state;
    while (state != null) {
      states.add(state);
      state = state.parent;
    }
    StringBuffer sb = new StringBuffer();
    sb.writeln(message);
    String indent = ' ';
    for (State state in states.reversed) {
      if (state is NodeState) {
        sb.writeln();
        sb.write(indent);
        indent = ' $indent';
        if (state.a.runtimeType == state.b.runtimeType) {
          if (state.a is NamedNode) {
            sb.write(state.a.runtimeType);
            sb.write('(');
            sb.write(state.a.toText(defaultAstTextStrategy));
            sb.write(')');
          } else {
            sb.write(state.a.runtimeType);
          }
        } else {
          sb.write('(${state.a.runtimeType}/${state.b.runtimeType})');
        }
      } else if (state is PropertyState) {
        sb.write('.${state.name}');
      } else {
        throw new UnsupportedError('Unexpected state ${state.runtimeType}');
      }
    }
    return sb.toString();
  }
}

/// Enum for different kinds of [ReferenceName]s.
enum ReferenceNameKind {
  /// A reference name without information.
  Unknown,

  /// A reference name of a library.
  Library,

  /// A reference name of a class or extension.
  Declaration,

  /// A reference name of a typedef or member.
  Member,
}

/// Abstract representation of a [Reference] or [CanonicalName].
///
/// This is used to determine nominality of [Reference]s consistently,
/// regardless of whether the [Reference] has an attached node or canonical
/// name.
class ReferenceName {
  final ReferenceNameKind kind;
  final ReferenceName? parent;
  final String? name;
  final String? uri;

  ReferenceName.internal(this.kind, this.name, [this.parent, this.uri]);

  factory ReferenceName.fromNamedNode(NamedNode node) {
    if (node is Library) {
      return new ReferenceName.internal(
          ReferenceNameKind.Library, node.importUri.toString());
    } else if (node is Extension) {
      return new ReferenceName.internal(ReferenceNameKind.Declaration,
          node.name, new ReferenceName.fromNamedNode(node.enclosingLibrary));
    } else if (node is Class) {
      return new ReferenceName.internal(ReferenceNameKind.Declaration,
          node.name, new ReferenceName.fromNamedNode(node.enclosingLibrary));
    } else if (node is Typedef) {
      return new ReferenceName.internal(ReferenceNameKind.Member, node.name,
          new ReferenceName.fromNamedNode(node.enclosingLibrary));
    } else if (node is Member) {
      Class? enclosingClass = node.enclosingClass;
      Reference? libraryReference = node.name.libraryName;
      String? uri;
      if (libraryReference != null) {
        Library? library = libraryReference.node as Library?;
        if (library != null) {
          uri = library.importUri.toString();
        } else {
          uri = libraryReference.canonicalName?.name;
        }
      }
      if (enclosingClass != null) {
        return new ReferenceName.internal(
            ReferenceNameKind.Member,
            node.name.text,
            new ReferenceName.fromNamedNode(enclosingClass),
            uri);
      } else {
        return new ReferenceName.internal(
            ReferenceNameKind.Member,
            node.name.text,
            new ReferenceName.fromNamedNode(node.enclosingLibrary),
            uri);
      }
    } else {
      throw new ArgumentError(
          'Unexpected named node ${node} (${node.runtimeType})');
    }
  }

  factory ReferenceName.fromCanonicalName(CanonicalName canonicalName) {
    List<CanonicalName> parents = [];
    CanonicalName? parent = canonicalName;
    while (parent != null) {
      parents.add(parent);
      parent = parent.parent;
    }
    parents = parents.reversed.toList();
    ReferenceName? referenceName;
    ReferenceNameKind kind = ReferenceNameKind.Declaration;
    for (int index = 1; index < parents.length; index++) {
      if (index == 1) {
        // Library reference.
        referenceName = new ReferenceName.internal(
            ReferenceNameKind.Library, parents[index].name);
      } else if (CanonicalName.isSymbolicName(parents[index].name)) {
        // Skip symbolic names
        kind = ReferenceNameKind.Member;
      } else {
        if (index + 2 == parents.length) {
          // This is a private name.
          referenceName = new ReferenceName.internal(ReferenceNameKind.Member,
              parents[index + 1].name, referenceName, parents[index].name);
          break;
        } else {
          referenceName = new ReferenceName.internal(
              kind, parents[index].name, referenceName);
        }
      }
    }
    return referenceName ??
        new ReferenceName.internal(ReferenceNameKind.Unknown, null);
  }

  String? get libraryUri {
    if (kind == ReferenceNameKind.Library) {
      return name;
    } else {
      return parent?.libraryUri;
    }
  }

  String? get declarationName {
    if (kind == ReferenceNameKind.Declaration) {
      return name;
    } else {
      return parent?.declarationName;
    }
  }

  String? get memberName {
    if (kind == ReferenceNameKind.Member) {
      return name;
    }
    return null;
  }

  String? get memberUri {
    if (kind == ReferenceNameKind.Member) {
      return uri;
    }
    return null;
  }

  static ReferenceName? fromReference(Reference? reference) {
    if (reference == null) {
      return null;
    }
    NamedNode? node = reference.node;
    if (node != null) {
      return new ReferenceName.fromNamedNode(node);
    }
    CanonicalName? canonicalName = reference.canonicalName;
    if (canonicalName != null) {
      return new ReferenceName.fromCanonicalName(canonicalName);
    }
    return new ReferenceName.internal(ReferenceNameKind.Unknown, null);
  }

  @override
  int get hashCode =>
      name.hashCode * 13 + uri.hashCode * 17 + parent.hashCode * 19;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReferenceName &&
        name == other.name &&
        uri == other.uri &&
        parent == other.parent;
  }

  @override
  String toString() {
    if (parent != null) {
      return '${parent}/$name';
    } else if (name != null) {
      return '/$name';
    } else {
      return '<null>';
    }
  }
}
