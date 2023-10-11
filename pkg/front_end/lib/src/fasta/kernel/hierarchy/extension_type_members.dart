// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/source/source_extension_type_declaration_builder.dart';
import 'package:kernel/ast.dart';

import '../../builder/declaration_builders.dart';
import '../../builder/member_builder.dart';
import '../../messages.dart';
import 'class_member.dart';
import 'hierarchy_node.dart';
import 'members_builder.dart';
import 'members_node.dart';

class ExtensionTypeHierarchyNodeDataForTesting {
  ExtensionTypeHierarchyNodeDataForTesting();
}

class ExtensionTypeMembersNodeBuilder extends MembersNodeBuilder {
  final ExtensionTypeHierarchyNode _hierarchyNode;
  final ClassMembersBuilder _membersBuilder;

  ExtensionTypeMembersNodeBuilder(this._membersBuilder, this._hierarchyNode);

  ExtensionTypeDeclarationBuilder get extensionTypeDeclarationBuilder =>
      _hierarchyNode.extensionTypeDeclarationBuilder;

  @override
  DeclarationBuilder get declarationBuilder => extensionTypeDeclarationBuilder;

  ExtensionTypeMembersNode build() {
    Map<Name, _Tuple> memberMap = {};

    Iterator<MemberBuilder> iterator =
        extensionTypeDeclarationBuilder.fullMemberIterator<MemberBuilder>();
    while (iterator.moveNext()) {
      MemberBuilder memberBuilder = iterator.current;
      for (ClassMember classMember in memberBuilder.localMembers) {
        Name name = classMember.name;
        _Tuple? tuple = memberMap[name];
        if (tuple == null) {
          memberMap[name] = new _Tuple.declareGetable(classMember);
        } else {
          tuple.declaredGetable = classMember;
        }
      }
      for (ClassMember classMember in memberBuilder.localSetters) {
        Name name = classMember.name;
        _Tuple? tuple = memberMap[name];
        if (tuple == null) {
          memberMap[name] = new _Tuple.declareSetable(classMember);
        } else {
          tuple.declaredSetable = classMember;
        }
      }
    }

    void implementNonExtensionType(
        Map<Name, ClassMember>? superInterfaceMembers) {
      if (superInterfaceMembers == null) return;
      for (MapEntry<Name, ClassMember> entry in superInterfaceMembers.entries) {
        Name name = entry.key;
        ClassMember superInterfaceMember = entry.value;
        _Tuple? tuple = memberMap[name];
        if (tuple != null) {
          if (superInterfaceMember.forSetter) {
            tuple.addImplementedNonExtensionTypeSetable(superInterfaceMember);
          } else {
            tuple.addImplementedNonExtensionTypeGetable(superInterfaceMember);
          }
        } else {
          if (superInterfaceMember.forSetter) {
            memberMap[superInterfaceMember.name] =
                new _Tuple.implementNonExtensionTypeSetable(
                    superInterfaceMember);
          } else {
            memberMap[superInterfaceMember.name] =
                new _Tuple.implementNonExtensionTypeGetable(
                    superInterfaceMember);
          }
        }
      }
    }

    void implementExtensionType(Map<Name, ClassMember>? superInterfaceMembers) {
      if (superInterfaceMembers == null) return;
      for (MapEntry<Name, ClassMember> entry in superInterfaceMembers.entries) {
        Name name = entry.key;
        ClassMember superInterfaceMember = entry.value;
        _Tuple? tuple = memberMap[name];
        if (tuple != null) {
          if (superInterfaceMember.forSetter) {
            tuple.addImplementedExtensionTypeSetable(superInterfaceMember);
          } else {
            tuple.addImplementedExtensionTypeGetable(superInterfaceMember);
          }
        } else {
          if (superInterfaceMember.forSetter) {
            memberMap[superInterfaceMember.name] =
                new _Tuple.implementExtensionTypeSetable(superInterfaceMember);
          } else {
            memberMap[superInterfaceMember.name] =
                new _Tuple.implementExtensionTypeGetable(superInterfaceMember);
          }
        }
      }
    }

    List<ClassHierarchyNode>? directSuperclassNodes =
        _hierarchyNode.directSuperclassNodes;
    if (directSuperclassNodes != null) {
      for (ClassHierarchyNode superclassNode in directSuperclassNodes) {
        ClassMembersNode? interfaceNode = _membersBuilder
            .getNodeFromClassBuilder(superclassNode.classBuilder);
        implementNonExtensionType(
            interfaceNode.interfaceMemberMap ?? interfaceNode.classMemberMap);
        implementNonExtensionType(
            interfaceNode.interfaceSetterMap ?? interfaceNode.classSetterMap);
      }
    }
    List<ExtensionTypeHierarchyNode>? directSuperExtensionTypeNodes =
        _hierarchyNode.directSuperExtensionTypeNodes;
    if (directSuperExtensionTypeNodes != null) {
      for (ExtensionTypeHierarchyNode superclassNode
          in directSuperExtensionTypeNodes) {
        ExtensionTypeMembersNode? interfaceNode =
            _membersBuilder.getNodeFromExtensionTypeDeclarationBuilder(
                superclassNode.extensionTypeDeclarationBuilder);
        implementNonExtensionType(interfaceNode.nonExtensionTypeGetableMap);
        implementNonExtensionType(interfaceNode.nonExtensionTypeSetableMap);
        implementExtensionType(interfaceNode.extensionTypeGetableMap);
        implementExtensionType(interfaceNode.extensionTypeSetableMap);
      }
    }

    Map<Name, ClassMember> nonExtensionTypeGetableMap = {};
    Map<Name, ClassMember> nonExtensionTypeSetableMap = {};
    Map<Name, ClassMember> extensionTypeGetableMap = {};
    Map<Name, ClassMember> extensionTypeSetableMap = {};

    void computeExtensionTypeMember(Name name, _Tuple tuple) {
      /// The computation starts by sanitizing the members. Conflicts between
      /// methods and properties (getters/setters) or between static and
      /// instance members are reported. Conflicting members and members
      /// overridden by duplicates are removed.
      ///
      /// Conflicts between the getable and setable are reported afterwards.
      var (_SanitizedMember? getable, _SanitizedMember? setable) =
          tuple.sanitize(this);

      ClassMember? getableMember;
      if (getable != null) {
        getableMember = getable.computeMembers(this,
            nonExtensionTypeMemberMap: nonExtensionTypeGetableMap,
            extensionTypeMemberMap: extensionTypeGetableMap);
      }
      ClassMember? setableMember;
      if (setable != null) {
        setableMember = setable.computeMembers(this,
            nonExtensionTypeMemberMap: nonExtensionTypeSetableMap,
            extensionTypeMemberMap: extensionTypeSetableMap);
      }
      if (extensionTypeDeclarationBuilder
          is SourceExtensionTypeDeclarationBuilder) {
        if (getableMember != null &&
            setableMember != null &&
            getableMember.isProperty &&
            setableMember.isProperty &&
            getableMember.isStatic == setableMember.isStatic &&
            !getableMember.isSameDeclaration(setableMember)) {
          /// We need to check that the getter type is a subtype of the setter
          /// type. For instance
          ///
          ///    extension type ET1(int id) {
          ///       int get property1 => null;
          ///       num get property2 => null;
          ///    }
          ///    extension type ET2(int id) {
          ///       void set property1(num value) {}
          ///       void set property2(int value) {}
          ///    }
          ///    extension type ET3(int id) implements ET1, ET2 {}
          ///
          /// Here `ET1.property1` and `ET2.property1` form a valid getter/
          /// setter pair in `ET3` because the type of the getter
          /// `ET1.property1` is a subtype of the setter `ET2.property1`.
          ///
          /// In contrast the pair `ET1.property2` and `ET2.property2` is
          /// not a valid getter/setter in `ET3` because the type of the getter
          /// `ET1.property2` is _not_ a subtype of the setter
          /// `ET2.property1`.
          ///
          /*_membersBuilder.registerGetterSetterCheck(
              extensionTypeDeclarationBuilder,
              getableMember,
              setableMember);*/
        }
      }
    }

    memberMap.forEach(computeExtensionTypeMember);

    return new ExtensionTypeMembersNode(
        _hierarchyNode.extensionTypeDeclarationBuilder,
        nonExtensionTypeGetableMap,
        nonExtensionTypeSetableMap,
        extensionTypeGetableMap,
        extensionTypeSetableMap);
  }
}

class ExtensionTypeMembersNode {
  final ExtensionTypeDeclarationBuilder extensionTypeDeclarationBuilder;

  /// All the members of this extension type inherited from non-extension types.
  final Map<Name, ClassMember>? nonExtensionTypeGetableMap;

  /// Similar to [nonExtensionTypeGetableMap] but for setters.
  final Map<Name, ClassMember>? nonExtensionTypeSetableMap;

  /// All the members of this class including [classMembers] of its
  /// superclasses. The members are sorted by [compareDeclarations].
  final Map<Name, ClassMember>? extensionTypeGetableMap;

  /// Similar to [extensionTypeGetableMap] but for setters.
  final Map<Name, ClassMember>? extensionTypeSetableMap;

  ExtensionTypeMembersNode(
      this.extensionTypeDeclarationBuilder,
      this.nonExtensionTypeGetableMap,
      this.nonExtensionTypeSetableMap,
      this.extensionTypeGetableMap,
      this.extensionTypeSetableMap);
}

class _Tuple {
  final Name name;
  ClassMember? _declaredGetable;
  ClassMember? _declaredSetable;
  List<ClassMember>? _implementedNonExtensionTypeGetables;
  List<ClassMember>? _implementedNonExtensionTypeSetables;
  List<ClassMember>? _implementedExtensionTypeGetables;
  List<ClassMember>? _implementedExtensionTypeSetables;

  _Tuple.declareGetable(ClassMember declaredGetable)
      : assert(!declaredGetable.forSetter),
        this._declaredGetable = declaredGetable,
        this.name = declaredGetable.name;

  _Tuple.implementNonExtensionTypeGetable(ClassMember implementedGetable)
      : assert(!implementedGetable.forSetter),
        this.name = implementedGetable.name,
        _implementedNonExtensionTypeGetables = <ClassMember>[
          implementedGetable
        ];

  _Tuple.implementExtensionTypeGetable(ClassMember implementedGetable)
      : assert(!implementedGetable.forSetter),
        this.name = implementedGetable.name,
        _implementedExtensionTypeGetables = <ClassMember>[implementedGetable];

  _Tuple.declareSetable(ClassMember declaredSetable)
      : assert(declaredSetable.forSetter),
        this._declaredSetable = declaredSetable,
        this.name = declaredSetable.name;

  _Tuple.implementNonExtensionTypeSetable(ClassMember implementedSetable)
      : assert(implementedSetable.forSetter),
        this.name = implementedSetable.name,
        _implementedNonExtensionTypeSetables = <ClassMember>[
          implementedSetable
        ];

  _Tuple.implementExtensionTypeSetable(ClassMember implementedSetable)
      : assert(implementedSetable.forSetter),
        this.name = implementedSetable.name,
        _implementedExtensionTypeSetables = <ClassMember>[implementedSetable];

  ClassMember? get declaredGetable => _declaredGetable;

  void set declaredGetable(ClassMember? value) {
    assert(!value!.forSetter);
    assert(
        _declaredGetable == null,
        "Declared member already set to $_declaredGetable, "
        "trying to set it to $value.");
    _declaredGetable = value;
  }

  ClassMember? get declaredSetable => _declaredSetable;

  void set declaredSetable(ClassMember? value) {
    assert(value!.forSetter);
    assert(
        _declaredSetable == null,
        "Declared setter already set to $_declaredSetable, "
        "trying to set it to $value.");
    _declaredSetable = value;
  }

  List<ClassMember>? get implementedNonExtensionTypeGetables =>
      _implementedNonExtensionTypeGetables;

  void addImplementedNonExtensionTypeGetable(ClassMember value) {
    assert(!value.forSetter);
    _implementedNonExtensionTypeGetables ??= <ClassMember>[];
    _implementedNonExtensionTypeGetables!.add(value);
  }

  List<ClassMember>? get implementedNonExtensionTypeSetables =>
      _implementedNonExtensionTypeSetables;

  void addImplementedNonExtensionTypeSetable(ClassMember value) {
    assert(value.forSetter);
    _implementedNonExtensionTypeSetables ??= <ClassMember>[];
    _implementedNonExtensionTypeSetables!.add(value);
  }

  List<ClassMember>? get implementedExtensionTypeGetables =>
      _implementedExtensionTypeGetables;

  void addImplementedExtensionTypeGetable(ClassMember value) {
    assert(!value.forSetter);
    _implementedExtensionTypeGetables ??= <ClassMember>[];
    _implementedExtensionTypeGetables!.add(value);
  }

  List<ClassMember>? get implementedExtensionTypeSetables =>
      _implementedExtensionTypeSetables;

  void addImplementedExtensionTypeSetable(ClassMember value) {
    assert(value.forSetter);
    _implementedExtensionTypeSetables ??= <ClassMember>[];
    _implementedExtensionTypeSetables!.add(value);
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    String comma = '';
    sb.write('Tuple(');
    if (_declaredGetable != null) {
      sb.write(comma);
      sb.write('declaredMember=');
      sb.write(_declaredGetable);
      comma = ',';
    }
    if (_declaredSetable != null) {
      sb.write(comma);
      sb.write('declaredSetter=');
      sb.write(_declaredSetable);
      comma = ',';
    }
    if (_implementedNonExtensionTypeGetables != null) {
      sb.write(comma);
      sb.write('implementedNonExtensionTypeMembers=');
      sb.write(_implementedNonExtensionTypeGetables);
      comma = ',';
    }
    if (_implementedNonExtensionTypeSetables != null) {
      sb.write(comma);
      sb.write('implementedNonExtensionTypeSetters=');
      sb.write(_implementedNonExtensionTypeSetables);
      comma = ',';
    }
    if (_implementedExtensionTypeGetables != null) {
      sb.write(comma);
      sb.write('_implementedExtensionTypeMembers=');
      sb.write(_implementedExtensionTypeGetables);
      comma = ',';
    }
    if (_implementedExtensionTypeSetables != null) {
      sb.write(comma);
      sb.write('_implementedExtensionTypeSetters=');
      sb.write(_implementedExtensionTypeSetables);
      comma = ',';
    }
    sb.write(')');
    return sb.toString();
  }

  /// Sanitizing the members of this tuple.
  ///
  /// Conflicts between methods and properties (getters/setters) or between
  /// static and instance members are reported. Conflicting members and members
  /// overridden by duplicates are removed.
  ///
  /// For this [definingGetable] and [definingSetable] hold the first member
  /// of its kind found among declared, mixed in, extended and implemented
  /// members.
  ///
  /// Conflicts between [definingGetable] and [definingSetable] are reported
  /// afterwards.
  (_SanitizedMember?, _SanitizedMember?) sanitize(
      ExtensionTypeMembersNodeBuilder builder) {
    ClassMember? definingGetable;
    ClassMember? definingSetable;

    ClassMember? declaredGetable = this.declaredGetable;
    if (declaredGetable != null) {
      /// extension type ExtensionType(int id) {
      ///   method() {}
      /// }
      definingGetable = declaredGetable;
    }
    ClassMember? declaredSetable = this.declaredSetable;
    if (declaredSetable != null) {
      /// extension type ExtensionType(int id) {
      ///   set setter(value) {}
      /// }
      definingSetable = declaredSetable;
    }

    List<ClassMember>? implementedNonExtensionTypeGetables;
    List<ClassMember>? tupleImplementedNonExtensionTypeGetables =
        this.implementedNonExtensionTypeGetables;
    if (tupleImplementedNonExtensionTypeGetables != null &&
        // Skip implemented members if we already have a duplicate.
        !(definingGetable != null && definingGetable.isDuplicate)) {
      for (int i = 0;
          i < tupleImplementedNonExtensionTypeGetables.length;
          i++) {
        ClassMember? implementedGetable =
            tupleImplementedNonExtensionTypeGetables[i];
        if (implementedGetable.isStatic || implementedGetable.isDuplicate) {
          /// We treat
          ///
          ///   class Interface {
          ///     static method1() {}
          ///     method2() {}
          ///     method2() {}
          ///   }
          ///   extension type ExtensionType(Interface id)
          ///       implements Interface {}
          ///
          /// as
          ///
          ///   class Interface {}
          ///   extension type ExtensionType(Interface id)
          ///       implements Interface {}
          ///
          implementedGetable = null;
        } else {
          if (definingGetable == null) {
            ///   class Interface {
            ///     method() {}
            ///   }
            ///   extension type ExtensionType(Interface id)
            ///       implements Interface {}
            definingGetable = implementedGetable;
          } else if (definingGetable.isStatic) {
            ///   class Interface {
            ///     method() {}
            ///   }
            ///   extension type ExtensionType(Interface id)
            ///       implements Interface {
            ///     static method() {}
            ///   }
            ///
            builder.reportInheritanceConflict(
                definingGetable, implementedGetable);
            implementedGetable = null;
          }
        }
        if (implementedGetable == null) {
          // On the first skipped member we add all previous.
          implementedNonExtensionTypeGetables ??=
              tupleImplementedNonExtensionTypeGetables.take(i).toList();
        } else if (implementedNonExtensionTypeGetables != null) {
          // If already skipping members we add [implementedGetable]
          // explicitly.
          implementedNonExtensionTypeGetables.add(implementedGetable);
        }
      }
      if (implementedNonExtensionTypeGetables == null) {
        // No members were skipped so we use the full list.
        implementedNonExtensionTypeGetables =
            tupleImplementedNonExtensionTypeGetables;
      } else if (implementedNonExtensionTypeGetables.isEmpty) {
        // No members were included.
        implementedNonExtensionTypeGetables = null;
      }
    }

    List<ClassMember>? implementedNonExtensionTypeSetables;
    List<ClassMember>? tupleImplementedNonExtensionTypeSetables =
        this.implementedNonExtensionTypeSetables;
    if (tupleImplementedNonExtensionTypeSetables != null &&
        // Skip implemented setters if we already have a duplicate.
        !(definingSetable != null && definingSetable.isDuplicate)) {
      for (int i = 0;
          i < tupleImplementedNonExtensionTypeSetables.length;
          i++) {
        ClassMember? implementedSetable =
            tupleImplementedNonExtensionTypeSetables[i];
        if (implementedSetable.isStatic || implementedSetable.isDuplicate) {
          /// We treat
          ///
          ///   class Interface {
          ///     static set setter1(value) {}
          ///     set setter2(value) {}
          ///     set setter2(value) {}
          ///   }
          ///   extension type ExtensionType(Interface id)
          ///       implements Interface {}
          ///
          /// as
          ///
          ///   class Interface {}
          ///   extension type ExtensionType(Interface id)
          ///       implements Interface {}
          ///
          implementedSetable = null;
        } else {
          if (definingSetable == null) {
            /// class Interface {
            ///   set setter(value) {}
            /// }
            /// class Class implements Interface {}
            definingSetable = implementedSetable;
          } else if (definingSetable.isStatic) {
            ///   class Interface {
            ///     set setter(value) {}
            ///   }
            ///   extension type ExtensionType(Interface id)
            ///       implements Interface {
            ///     static set setter(value) {}
            ///   }
            ///
            builder.reportInheritanceConflict(
                definingSetable, implementedSetable);
            implementedSetable = null;
          }
        }
        if (implementedSetable == null) {
          // On the first skipped setter we add all previous.
          implementedNonExtensionTypeSetables ??=
              tupleImplementedNonExtensionTypeSetables.take(i).toList();
        } else if (implementedNonExtensionTypeSetables != null) {
          // If already skipping setters we add [implementedSetable]
          // explicitly.
          implementedNonExtensionTypeSetables.add(implementedSetable);
        }
      }
      if (implementedNonExtensionTypeSetables == null) {
        // No setters were skipped so we use the full list.
        implementedNonExtensionTypeSetables =
            tupleImplementedNonExtensionTypeSetables;
      } else if (implementedNonExtensionTypeSetables.isEmpty) {
        // No setters were included.
        implementedNonExtensionTypeSetables = null;
      }
    }

    List<ClassMember>? implementedExtensionTypeGetables;
    List<ClassMember>? tupleImplementedExtensionTypeGetables =
        this.implementedExtensionTypeGetables;
    if (tupleImplementedExtensionTypeGetables != null &&
        // Skip implemented members if we already have a duplicate.
        !(definingGetable != null && definingGetable.isDuplicate)) {
      for (int i = 0; i < tupleImplementedExtensionTypeGetables.length; i++) {
        ClassMember? implementedGetable =
            tupleImplementedExtensionTypeGetables[i];
        if (implementedGetable.isStatic || implementedGetable.isDuplicate) {
          /// We treat
          ///
          ///   extension type ExtensionSuperType(int id) {
          ///     static method1() {}
          ///     method2() {}
          ///     method2() {}
          ///   }
          ///   extension type ExtensionType(int id)
          ///       implements ExtensionSuperType {}
          ///
          /// as
          ///
          ///   extension type ExtensionSuperType(int id) {}
          ///   extension type ExtensionType(Interface id)
          ///       implements ExtensionSuperType {}
          ///
          implementedGetable = null;
        } else {
          if (definingGetable == null) {
            ///   extension type ExtensionSuperType(int id) {
            ///     method() {}
            ///   }
            ///   extension type ExtensionType(int id)
            ///       implements Interface {}
            definingGetable = implementedGetable;
          } else if (definingGetable.isStatic) {
            ///   extension type ExtensionSuperType(int id) {
            ///     method() {}
            ///   }
            ///   extension type ExtensionType(Interface id)
            ///       implements Interface {
            ///     static method() {}
            ///   }
            builder.reportInheritanceConflict(
                definingGetable, implementedGetable);
            implementedGetable = null;
          }
        }
        if (implementedGetable == null) {
          // On the first skipped member we add all previous.
          implementedExtensionTypeGetables ??=
              tupleImplementedExtensionTypeGetables.take(i).toList();
        } else if (implementedExtensionTypeGetables != null) {
          // If already skipping members we add [implementedGetable]
          // explicitly.
          implementedExtensionTypeGetables.add(implementedGetable);
        }
      }
      if (implementedExtensionTypeGetables == null) {
        // No members were skipped so we use the full list.
        implementedExtensionTypeGetables =
            tupleImplementedExtensionTypeGetables;
      } else if (implementedExtensionTypeGetables.isEmpty) {
        // No members were included.
        implementedExtensionTypeGetables = null;
      }
    }

    List<ClassMember>? implementedExtensionTypeSetables;
    List<ClassMember>? tupleImplementedExtensionTypeSetables =
        this.implementedExtensionTypeSetables;
    if (tupleImplementedExtensionTypeSetables != null &&
        // Skip implemented setters if we already have a duplicate.
        !(definingSetable != null && definingSetable.isDuplicate)) {
      for (int i = 0; i < tupleImplementedExtensionTypeSetables.length; i++) {
        ClassMember? implementedSetable =
            tupleImplementedExtensionTypeSetables[i];
        if (implementedSetable.isStatic || implementedSetable.isDuplicate) {
          /// We treat
          ///
          ///   class Interface {
          ///     static set setter1(value) {}
          ///     set setter2(value) {}
          ///     set setter2(value) {}
          ///   }
          ///   extension type ExtensionType(Interface id)
          ///       implements Interface {}
          ///
          /// as
          ///
          ///   class Interface {}
          ///   extension type ExtensionType(Interface id)
          ///       implements Interface {}
          ///
          implementedSetable = null;
        } else {
          if (definingSetable == null) {
            /// class Interface {
            ///   set setter(value) {}
            /// }
            /// class Class implements Interface {}
            definingSetable = implementedSetable;
          } else if (definingSetable.isStatic) {
            ///   class Interface {
            ///     set setter(value) {}
            ///   }
            ///   extension type ExtensionType(Interface id)
            ///       implements Interface {
            ///     static set setter(value) {}
            ///   }
            builder.reportInheritanceConflict(
                definingSetable, implementedSetable);
            implementedSetable = null;
          }
        }
        if (implementedSetable == null) {
          // On the first skipped setter we add all previous.
          implementedExtensionTypeSetables ??=
              tupleImplementedExtensionTypeSetables.take(i).toList();
        } else if (implementedExtensionTypeSetables != null) {
          // If already skipping setters we add [implementedSetable]
          // explicitly.
          implementedExtensionTypeSetables.add(implementedSetable);
        }
      }
      if (implementedExtensionTypeSetables == null) {
        // No setters were skipped so we use the full list.
        implementedExtensionTypeSetables =
            tupleImplementedExtensionTypeSetables;
      } else if (implementedExtensionTypeSetables.isEmpty) {
        // No setters were included.
        implementedExtensionTypeSetables = null;
      }
    }

    if (definingGetable != null && definingSetable != null) {
      if (definingGetable.isStatic != definingSetable.isStatic ||
          definingGetable.isProperty != definingSetable.isProperty) {
        builder.reportInheritanceConflict(definingGetable, definingSetable);
        // TODO(johnniwinther): Should we remove [definingSetable]? If we
        // leave it in this conflict will also be reported in subclasses. If
        // we remove it, any write to the setable will be unresolved.
      }
    }
    return (
      definingGetable != null
          ? new _SanitizedMember(
              name,
              definingGetable,
              declaredGetable,
              implementedNonExtensionTypeGetables,
              implementedExtensionTypeGetables)
          : null,
      definingSetable != null
          ? new _SanitizedMember(
              name,
              definingSetable,
              declaredSetable,
              implementedNonExtensionTypeSetables,
              implementedExtensionTypeSetables)
          : null
    );
  }
}

/// The [ClassMember]s involved in defined the [name] getable or setable of
/// an extension type.
///
/// The values are sanitized to avoid duplicates and conflicting members.
///
/// The [_definingMember] hold the first member found among declared and
/// implemented members.
///
/// This is computed by [_Tuple.sanitize].
class _SanitizedMember {
  final Name name;

  /// The member which defines whether the computation is for a method, a getter
  /// or a setter.
  final ClassMember _definingMember;

  /// The member declared in the current extension type, if any.
  final ClassMember? _declaredMember;

  /// The members inherited from the non-extension type supertypes, if none this
  /// is `null`.
  final List<ClassMember>? _implementedNonExtensionTypeMembers;

  /// The members inherited from the extension type supertypes, if none this is
  /// `null`.
  final List<ClassMember>? _implementedExtensionTypeMembers;

  _SanitizedMember(
      this.name,
      this._definingMember,
      this._declaredMember,
      this._implementedNonExtensionTypeMembers,
      this._implementedExtensionTypeMembers);

  /// Computes the class and interface members for this [_SanitizedMember].
  ///
  /// The computed class and interface members are added to [classMemberMap]
  /// and [interfaceMemberMap], respectively.
  ///
  /// [
  ClassMember? computeMembers(ExtensionTypeMembersNodeBuilder builder,
      {required Map<Name, ClassMember> nonExtensionTypeMemberMap,
      required Map<Name, ClassMember> extensionTypeMemberMap}) {
    ExtensionTypeDeclarationBuilder extensionTypeDeclarationBuilder =
        builder.extensionTypeDeclarationBuilder;
    if (_declaredMember != null) {
      return extensionTypeMemberMap[name] = _declaredMember;
    } else if (_implementedExtensionTypeMembers != null) {
      Set<ClassMember> extensionTypeMemberDeclarations = toSet(
          extensionTypeDeclarationBuilder, _implementedExtensionTypeMembers);
      if (_implementedNonExtensionTypeMembers != null) {
        List<LocatedMessage> context = [];
        Set<ClassMember> nonExtensionTypeMemberDeclarations = toSet(
            extensionTypeDeclarationBuilder,
            _implementedNonExtensionTypeMembers);
        for (ClassMember classMember in extensionTypeMemberDeclarations) {
          context.add((extensionTypeMemberDeclarations.length > 1
                  ? messageExtensionTypeMemberOneOfContext
                  : messageExtensionTypeMemberContext)
              .withLocation(classMember.fileUri, classMember.charOffset,
                  name.text.length));
        }
        for (ClassMember classMember in nonExtensionTypeMemberDeclarations) {
          context.add((nonExtensionTypeMemberDeclarations.length > 1
                  ? messageNonExtensionTypeMemberOneOfContext
                  : messageNonExtensionTypeMemberContext)
              .withLocation(classMember.fileUri, classMember.charOffset,
                  name.text.length));
        }
        extensionTypeDeclarationBuilder.addProblem(
            templateImplementNonExtensionTypeAndExtensionTypeMember
                .withArguments(extensionTypeDeclarationBuilder.name, name.text),
            extensionTypeDeclarationBuilder.charOffset,
            extensionTypeDeclarationBuilder.name.length,
            context: context);
      } else if (extensionTypeMemberDeclarations.length > 1) {
        List<LocatedMessage> context = [];
        for (ClassMember classMember in extensionTypeMemberDeclarations) {
          context.add(messageExtensionTypeMemberOneOfContext.withLocation(
              classMember.fileUri, classMember.charOffset, name.text.length));
        }
        extensionTypeDeclarationBuilder.addProblem(
            templateImplementMultipleExtensionTypeMembers.withArguments(
                extensionTypeDeclarationBuilder.name, name.text),
            extensionTypeDeclarationBuilder.charOffset,
            extensionTypeDeclarationBuilder.name.length,
            context: context);
      }
      return extensionTypeMemberMap[name] =
          extensionTypeMemberDeclarations.first;
    } else if (_implementedNonExtensionTypeMembers != null) {
      if (_implementedNonExtensionTypeMembers.length == 1) {
        return nonExtensionTypeMemberMap[name] =
            _implementedNonExtensionTypeMembers.first;
      } else {
        ClassMember classMember = new SynthesizedNonExtensionTypeMember(
            extensionTypeDeclarationBuilder,
            name,
            _implementedNonExtensionTypeMembers,
            isProperty: _definingMember.isProperty,
            forSetter: _definingMember.forSetter);
        builder._membersBuilder.registerMemberComputation(classMember);
        return nonExtensionTypeMemberMap[name] = classMember;
      }
    } else {
      throw new UnsupportedError("Unexpected sanitized member state: $this");
    }
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    String comma = '';
    sb.write('_SanitizedMember(');
    sb.write(comma);
    sb.write('_definingMember=');
    sb.write(_definingMember);
    comma = ',';
    if (_declaredMember != null) {
      sb.write(comma);
      sb.write('_declaredMember=');
      sb.write(_declaredMember);
      comma = ',';
    }
    if (_implementedNonExtensionTypeMembers != null) {
      sb.write(comma);
      sb.write('_implementedNonExtensionTypeMembers=');
      sb.write(_implementedNonExtensionTypeMembers);
      comma = ',';
    }
    if (_implementedExtensionTypeMembers != null) {
      sb.write(comma);
      sb.write('_implementedExtensionTypeMembers=');
      sb.write(_implementedExtensionTypeMembers);
      comma = ',';
    }
    sb.write(')');
    return sb.toString();
  }
}
