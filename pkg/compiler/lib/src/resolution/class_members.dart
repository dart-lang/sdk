// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library resolution.compute_members;

import '../elements/elements.dart'
    show Element,
         Name,
         PublicName,
         Member,
         MemberSignature,
         LibraryElement,
         ClassElement,
         MixinApplicationElement;
import '../dart_types.dart';
import '../dart2jslib.dart'
    show Compiler,
         MessageKind,
         invariant,
         isPrivateName;
import '../helpers/helpers.dart';  // Included for debug helpers.
import '../util/util.dart';

part 'member_impl.dart';

abstract class MembersCreator {
  final ClassElement cls;
  final Compiler compiler;

  final Iterable<String> computedMemberNames;
  final Map<Name, Member> classMembers;

  Map<dynamic/* Member | Element */, Set<MessageKind>> reportedMessages =
      new Map<dynamic, Set<MessageKind>>();

  MembersCreator(Compiler this.compiler,
                 ClassElement this.cls,
                 Iterable<String> this.computedMemberNames,
                 Map<Name, Member> this.classMembers) {
    assert(invariant(cls, cls.isDeclaration,
        message: "Members may only be computed on declarations."));
  }

  void reportMessage(var marker, MessageKind kind, report()) {
    Set<MessageKind> messages =
        reportedMessages.putIfAbsent(marker,
            () => new Set<MessageKind>());
    if (messages.add(kind)) {
      report();
    }
  }

  bool shouldSkipMember(MemberSignature member) {
    return member == null || shouldSkipName(member.name.text);

  }

  bool shouldSkipName(String name) {
    return computedMemberNames != null &&
           computedMemberNames.contains(name);
  }

  /// Compute all members of [cls] with the given names.
  void computeMembersByName(String name, Setlet<Name> names) {
    computeMembers(name, names);
  }

  /// Compute all members of [cls] and checked that [cls] implements its
  /// interface unless it is abstract or declares a `noSuchMethod` method.
  void computeAllMembers() {
    Map<Name, Member> declaredMembers = computeMembers(null, null);
    if (!cls.isAbstract &&
        !declaredMembers.containsKey(const PublicName('noSuchMethod'))) {
      // Check for unimplemented members on concrete classes that neither have
      // a `@proxy` annotation nor declare a `noSuchMethod` method.
      checkInterfaceImplementation();
    }
  }

  /// Compute declared and inherited members of [cls] and return a map of the
  /// declared members.
  ///
  /// If [name] and [names] are not null, the computation is restricted to
  /// members with these names.
  Map<Name, Member> computeMembers(String name, Setlet<Name> names);

  /// Compute the members of the super type(s) of [cls] and store them in
  /// [classMembers].
  ///
  /// If [name] and [names] are not null, the computation is restricted to
  /// members with these names.
  void computeSuperMembers(String name, Setlet<Name> names);

  /// Compute the members of the super class of [cls] and store them in
  /// [classMembers].
  ///
  /// If [name] and [names] are not null, the computation is restricted to
  /// members with these names.
  void computeSuperClassMembers(String name, Setlet<Name> names) {
    InterfaceType supertype = cls.supertype;
    if (supertype == null) return;
    ClassElement superclass = supertype.element;

    // Inherit class and interface members from superclass.
    void inheritClassMember(DeclaredMember member) {
      if (shouldSkipMember(member)) return;
      if (!member.isStatic) {
        DeclaredMember inherited = member.inheritFrom(supertype);
        classMembers[member.name] = inherited;
      }
    }

    if (names != null) {
      _computeClassMember(compiler, superclass, name, names);
      for (Name memberName in names) {
        inheritClassMember(superclass.lookupClassMember(memberName));
      }
    } else {
      computeAllClassMembers(compiler, superclass);
      superclass.forEachClassMember(inheritClassMember);
    }
  }

  /// Compute the members declared or directly mixed in [cls].
  ///
  /// If [name] and [names] are not null, the computation is restricted to
  /// members with these names.
  Map<Name, Member> computeClassMembers(String nameText, Setlet<Name> names) {
    Map<Name, Member> declaredMembers = new Map<Name, Member>();

    if (cls.isMixinApplication) {
      MixinApplicationElement mixinApplication = cls;
      if (mixinApplication.mixin != null) {
        // Only mix in class members when the mixin type is not malformed.

        void inheritMixinMember(DeclaredMember member) {
          if (shouldSkipMember(member)) return;
          Name name = member.name;
          if (!member.isAbstract && !member.isStatic) {
            // Abstract and static members are not mixed in.
            DeclaredMember mixedInMember =
                member.inheritFrom(mixinApplication.mixinType);
            DeclaredMember inherited = classMembers[name];
            classMembers[name] = mixedInMember;
            checkValidOverride(mixedInMember, inherited);
          }
        }

        if (names != null) {
          _computeClassMember(compiler, mixinApplication.mixin,
                              nameText, names);
          for (Name memberName in names) {
            inheritMixinMember(
                mixinApplication.mixin.lookupClassMember(memberName));
          }
        } else {
          computeAllClassMembers(compiler, mixinApplication.mixin);
          mixinApplication.mixin.forEachClassMember(inheritMixinMember);
        }
      }
    } else {
      LibraryElement library = cls.library;
      InterfaceType thisType = cls.thisType;

      void createMember(Element element) {
        if (element.isConstructor) return;
        String elementName = element.name;
        if (shouldSkipName(elementName)) return;
        if (nameText != null && elementName != nameText) return;

        void addDeclaredMember(Name name,
                               DartType type, FunctionType functionType) {
          DeclaredMember inherited = classMembers[name];
          DeclaredMember declared;
          if (element.isAbstract) {
            declared = new DeclaredAbstractMember(
                name, element, thisType, type, functionType,
                inherited);
          } else {
            declared =
                new DeclaredMember(name, element, thisType, type, functionType);
          }
          declaredMembers[name] = declared;
          classMembers[name] = declared;
          checkValidOverride(declared, inherited);
        }

        Name name = new Name(element.name, library);
        if (element.isField) {
          DartType type = element.computeType(compiler);
          addDeclaredMember(name, type, new FunctionType.synthesized(type));
          if (!element.isConst && !element.isFinal) {
            addDeclaredMember(name.setter, type,
                new FunctionType.synthesized(
                                 const VoidType(),
                                 <DartType>[type]));
          }
        } else if (element.isGetter) {
          FunctionType functionType = element.computeType(compiler);
          DartType type = functionType.returnType;
          addDeclaredMember(name, type, functionType);
        } else if (element.isSetter) {
          FunctionType functionType = element.computeType(compiler);
          DartType type;
          if (!functionType.parameterTypes.isEmpty) {
            type = functionType.parameterTypes.first;
          } else {
            type = const DynamicType();
          }
          name = name.setter;
          addDeclaredMember(name, type, functionType);
        } else {
          assert(invariant(element, element.isFunction));
          FunctionType type = element.computeType(compiler);
          addDeclaredMember(name, type, type);
        }
      }

      cls.forEachLocalMember(createMember);
      if (cls.isPatched) {
        cls.implementation.forEachLocalMember((Element element) {
          if (element.isDeclaration) {
            createMember(element);
          }
        });
      }
    }

    return declaredMembers;
  }

  /// Checks that [classMember] is a valid implementation for [interfaceMember].
  void checkInterfaceMember(Name name,
                            MemberSignature interfaceMember,
                            Member classMember) {
    if (classMember != null) {
      // TODO(johnniwinther): Check that the class member is a valid override
      // of the interface member.
      return;
    }
    if (interfaceMember is DeclaredMember &&
        interfaceMember.declarer.element == cls) {
      // Abstract method declared in [cls].
      MessageKind kind = MessageKind.ABSTRACT_METHOD;
      if (interfaceMember.isSetter) {
        kind = MessageKind.ABSTRACT_SETTER;
      } else if (interfaceMember.isGetter) {
        kind = MessageKind.ABSTRACT_GETTER;
      }
      reportMessage(
          interfaceMember.element, MessageKind.ABSTRACT_METHOD, () {
        compiler.reportWarning(
            interfaceMember.element, kind,
            {'class': cls.name, 'name': name.text});
      });
    } else {
       reportWarning(MessageKind singleKind,
                     MessageKind multipleKind,
                     MessageKind explicitlyDeclaredKind,
                     [MessageKind implicitlyDeclaredKind]) {
        Member inherited = interfaceMember.declarations.first;
        reportMessage(
            interfaceMember, MessageKind.UNIMPLEMENTED_METHOD, () {
          compiler.reportWarning(cls,
              interfaceMember.declarations.length == 1
                  ? singleKind : multipleKind,
              {'class': cls.name,
               'name': name.text,
               'method': interfaceMember,
               'declarer': inherited.declarer});
          for (Member inherited in interfaceMember.declarations) {
            compiler.reportInfo(inherited.element,
                inherited.isDeclaredByField ?
                    implicitlyDeclaredKind : explicitlyDeclaredKind,
                {'class': inherited.declarer.name,
                 'name': name.text});
          }
        });
      }
      if (interfaceMember.isSetter) {
        reportWarning(MessageKind.UNIMPLEMENTED_SETTER_ONE,
                      MessageKind.UNIMPLEMENTED_SETTER,
                      MessageKind.UNIMPLEMENTED_EXPLICIT_SETTER,
                      MessageKind.UNIMPLEMENTED_IMPLICIT_SETTER);
      } else if (interfaceMember.isGetter) {
        reportWarning(MessageKind.UNIMPLEMENTED_GETTER_ONE,
                      MessageKind.UNIMPLEMENTED_GETTER,
                      MessageKind.UNIMPLEMENTED_EXPLICIT_GETTER,
                      MessageKind.UNIMPLEMENTED_IMPLICIT_GETTER);
      } else if (interfaceMember.isMethod) {
        reportWarning(MessageKind.UNIMPLEMENTED_METHOD_ONE,
                      MessageKind.UNIMPLEMENTED_METHOD,
                      MessageKind.UNIMPLEMENTED_METHOD_CONT);
      }
    }
    // TODO(johnniwinther): If [cls] is not abstract, check that for all
    // interface members, there is a class member whose type is a subtype of
    // the interface member.
  }

  /// Checks that [cls], if it implements Function, has defined call().
  void checkImplementsFunctionWithCall() {
    assert(!cls.isAbstract);

    if (cls.asInstanceOf(compiler.functionClass) == null) return;
    if (cls.lookupMember(Compiler.CALL_OPERATOR_NAME) != null) return;
    // TODO(johnniwinther): Make separate methods for backend exceptions.
    // Avoid warnings on backend implementation classes for closures.
    if (compiler.backend.isBackendLibrary(cls.library)) return;

    reportMessage(compiler.functionClass, MessageKind.UNIMPLEMENTED_METHOD, () {
      compiler.reportWarning(cls, MessageKind.UNIMPLEMENTED_METHOD_ONE,
          {'class': cls.name,
           'name': Compiler.CALL_OPERATOR_NAME,
           'method': Compiler.CALL_OPERATOR_NAME,
           'declarer': compiler.functionClass.name});
    });
  }

  /// Checks that a class member exists for every interface member.
  void checkInterfaceImplementation();

  /// Check that [declared] is a valid override of [superMember].
  void checkValidOverride(Member declared, MemberSignature superMember) {
    if (superMember == null) {
      // No override.
      if (!declared.isStatic) {
        ClassElement superclass = cls.superclass;
        while (superclass != null) {
          Member superMember =
              superclass.lookupClassMember(declared.name);
          if (superMember != null && superMember.isStatic) {
            reportMessage(superMember, MessageKind.INSTANCE_STATIC_SAME_NAME,
                () {
              compiler.reportWarning(
                  declared.element,
                  MessageKind.INSTANCE_STATIC_SAME_NAME,
                  {'memberName': declared.name,
                    'className': superclass.name});
              compiler.reportInfo(superMember.element,
                  MessageKind.INSTANCE_STATIC_SAME_NAME_CONT);
            });
            break;
          }
          superclass = superclass.superclass;
        }
      }
    } else {
      assert(declared.name == superMember.name);
      if (declared.isStatic) {
        for (Member inherited in superMember.declarations) {
          reportMessage(
              inherited.element, MessageKind.NO_STATIC_OVERRIDE, () {
            reportErrorWithContext(
                declared.element, MessageKind.NO_STATIC_OVERRIDE,
                inherited.element, MessageKind.NO_STATIC_OVERRIDE_CONT);
          });
        }
      }

      DartType declaredType = declared.functionType;
      for (Member inherited in superMember.declarations) {

        void reportError(MessageKind errorKind, MessageKind infoKind) {
          reportMessage(
              inherited.element, MessageKind.INVALID_OVERRIDE_METHOD, () {
            compiler.reportError(declared.element, errorKind,
                {'name': declared.name.text,
                 'class': cls.thisType,
                 'inheritedClass': inherited.declarer});
            compiler.reportInfo(inherited.element, infoKind,
                {'name': declared.name.text,
                 'class': inherited.declarer});
          });
        }

        if (declared.isDeclaredByField && inherited.isMethod) {
          reportError(MessageKind.CANNOT_OVERRIDE_METHOD_WITH_FIELD,
              MessageKind.CANNOT_OVERRIDE_METHOD_WITH_FIELD_CONT);
        } else if (declared.isMethod && inherited.isDeclaredByField) {
          reportError(MessageKind.CANNOT_OVERRIDE_FIELD_WITH_METHOD,
              MessageKind.CANNOT_OVERRIDE_FIELD_WITH_METHOD_CONT);
        } else if (declared.isGetter && inherited.isMethod) {
          reportError(MessageKind.CANNOT_OVERRIDE_METHOD_WITH_GETTER,
                      MessageKind.CANNOT_OVERRIDE_METHOD_WITH_GETTER_CONT);
        } else if (declared.isMethod && inherited.isGetter) {
          reportError(MessageKind.CANNOT_OVERRIDE_GETTER_WITH_METHOD,
                      MessageKind.CANNOT_OVERRIDE_GETTER_WITH_METHOD_CONT);
        } else {
          DartType inheritedType = inherited.functionType;
          if (!compiler.types.isSubtype(declaredType, inheritedType)) {
            void reportWarning(var marker,
                               MessageKind warningKind,
                               MessageKind infoKind) {
              reportMessage(marker, MessageKind.INVALID_OVERRIDE_METHOD, () {
                compiler.reportWarning(declared.element, warningKind,
                    {'declaredType': declared.type,
                     'name': declared.name.text,
                     'class': cls.thisType,
                     'inheritedType': inherited.type,
                     'inheritedClass': inherited.declarer});
                compiler.reportInfo(inherited.element, infoKind,
                    {'name': declared.name.text,
                     'class': inherited.declarer});
              });
            }
            if (declared.isDeclaredByField) {
              if (inherited.isDeclaredByField) {
                reportWarning(inherited.element,
                              MessageKind.INVALID_OVERRIDE_FIELD,
                              MessageKind.INVALID_OVERRIDDEN_FIELD);
              } else if (inherited.isGetter) {
                reportWarning(inherited,
                              MessageKind.INVALID_OVERRIDE_GETTER_WITH_FIELD,
                              MessageKind.INVALID_OVERRIDDEN_GETTER);
              } else if (inherited.isSetter) {
                reportWarning(inherited,
                              MessageKind.INVALID_OVERRIDE_SETTER_WITH_FIELD,
                              MessageKind.INVALID_OVERRIDDEN_SETTER);
              }
            } else if (declared.isGetter) {
              if (inherited.isDeclaredByField) {
                reportWarning(inherited,
                              MessageKind.INVALID_OVERRIDE_FIELD_WITH_GETTER,
                              MessageKind.INVALID_OVERRIDDEN_FIELD);
              } else {
                reportWarning(inherited,
                              MessageKind.INVALID_OVERRIDE_GETTER,
                              MessageKind.INVALID_OVERRIDDEN_GETTER);
              }
            } else if (declared.isSetter) {
              if (inherited.isDeclaredByField) {
                reportWarning(inherited,
                              MessageKind.INVALID_OVERRIDE_FIELD_WITH_SETTER,
                              MessageKind.INVALID_OVERRIDDEN_FIELD);
              } else {
                reportWarning(inherited,
                              MessageKind.INVALID_OVERRIDE_SETTER,
                              MessageKind.INVALID_OVERRIDDEN_SETTER);
              }
            } else {
              reportWarning(inherited,
                            MessageKind.INVALID_OVERRIDE_METHOD,
                            MessageKind.INVALID_OVERRIDDEN_METHOD);
            }
          }
        }
      }
    }
  }

  void reportErrorWithContext(Element errorneousElement,
                              MessageKind errorMessage,
                              Element contextElement,
                              MessageKind contextMessage) {
    compiler.reportError(
        errorneousElement,
        errorMessage,
        {'memberName': contextElement.name,
         'className': contextElement.enclosingClass.name});
    compiler.reportInfo(contextElement, contextMessage);
  }

  /// Compute all class and interface names by the [name] in [cls].
  static void computeClassMembersByName(Compiler compiler,
                                        ClassMemberMixin cls,
                                        String name) {
    if (cls.isMemberComputed(name)) return;
    LibraryElement library = cls.library;
    _computeClassMember(compiler, cls, name,
        new Setlet<Name>()..add(new Name(name, library))
                          ..add(new Name(name, library, isSetter: true)));
  }

  static void _computeClassMember(Compiler compiler,
                                  ClassMemberMixin cls,
                                  String name,
                                  Setlet<Name> names) {
    cls.computeClassMember(compiler, name, names);
  }

  /// Compute all class and interface names in [cls].
  static void computeAllClassMembers(Compiler compiler, ClassMemberMixin cls) {
    cls.computeAllClassMembers(compiler);
  }
}

/// Class member creator for classes where the interface members are known to
/// be a subset of the class members.
class ClassMembersCreator extends MembersCreator {
  ClassMembersCreator(Compiler compiler,
                      ClassElement cls,
                      Iterable<String> computedMemberNames,
                      Map<Name, Member> classMembers)
      : super(compiler, cls, computedMemberNames, classMembers);

  Map<Name, Member> computeMembers(String name, Setlet<Name> names) {
    computeSuperMembers(name, names);
    return computeClassMembers(name, names);
  }

  void computeSuperMembers(String name, Setlet<Name> names) {
    computeSuperClassMembers(name, names);
  }

  void checkInterfaceImplementation() {
    LibraryElement library = cls.library;
    classMembers.forEach((Name name, Member classMember) {
      if (!name.isAccessibleFrom(library)) return;
     checkInterfaceMember(name, classMember, classMember.implementation);
    });
  }
}

/// Class Member creator for classes where the interface members might be
/// different from the class members.
class InterfaceMembersCreator extends MembersCreator {
  final Map<Name, MemberSignature> interfaceMembers;

  InterfaceMembersCreator(Compiler compiler,
                          ClassElement cls,
                          Iterable<String> computedMemberNames,
                          Map<Name, Member> classMembers,
                          Map<Name, MemberSignature> this.interfaceMembers)
      : super(compiler, cls, computedMemberNames, classMembers);

  Map<Name, Member> computeMembers(String name, Setlet<Name> names) {
    Map<Name, Setlet<Member>> inheritedInterfaceMembers =
        computeSuperMembers(name, names);
    Map<Name, Member> declaredMembers = computeClassMembers(name, names);
    computeInterfaceMembers(inheritedInterfaceMembers, declaredMembers);
    return declaredMembers;
  }

  /// Compute the members of the super type(s) of [cls]. The class members are
  /// stored if the [classMembers] map and the inherited interface members are
  /// returned.
  ///
  /// If [name] and [names] are not null, the computation is restricted to
  /// members with these names.
  Map<Name, Setlet<Member>> computeSuperMembers(String name,
                                                Setlet<Name> names) {
    computeSuperClassMembers(name, names);
    return computeSuperInterfaceMembers(name, names);
  }

  Map<Name, Setlet<Member>> computeSuperInterfaceMembers(String name,
                                                         Setlet<Name> names) {


    InterfaceType supertype = cls.supertype;
    assert(invariant(cls, supertype != null,
        message: "Interface members computed for $cls."));
    ClassElement superclass = supertype.element;

    Map<Name, Setlet<Member>> inheritedInterfaceMembers =
        new Map<Name, Setlet<Member>>();

    void inheritInterfaceMember(InterfaceType supertype,
                                MemberSignature member) {
      if (shouldSkipMember(member)) return;
      Setlet<Member> members =
          inheritedInterfaceMembers.putIfAbsent(
              member.name, () => new Setlet<Member>());
      for (DeclaredMember declaredMember in member.declarations) {
        members.add(declaredMember.inheritFrom(supertype));
      }
    }

    void inheritInterfaceMembers(InterfaceType supertype) {
      supertype.element.forEachInterfaceMember((MemberSignature member) {
        inheritInterfaceMember(supertype, member);
      });
    }

    if (names != null) {
      for (Name memberName in names) {
        inheritInterfaceMember(supertype,
            superclass.lookupInterfaceMember(memberName));
      }
    } else {
      inheritInterfaceMembers(supertype);
    }

    // Inherit interface members from superinterfaces.
    for (Link<DartType> link = cls.interfaces;
         !link.isEmpty;
         link = link.tail) {
      InterfaceType superinterface = link.head;
      if (names != null) {
        MembersCreator._computeClassMember(
            compiler, superinterface.element, name, names);
        for (Name memberName in names) {
          inheritInterfaceMember(superinterface,
              superinterface.element.lookupInterfaceMember(memberName));
        }
      } else {
        MembersCreator.computeAllClassMembers(compiler, superinterface.element);
        inheritInterfaceMembers(superinterface);
      }
    }

    return inheritedInterfaceMembers;
  }

  /// Checks that a class member exists for every interface member.
  void checkInterfaceImplementation() {
    LibraryElement library = cls.library;
    checkImplementsFunctionWithCall();
    interfaceMembers.forEach((Name name, MemberSignature interfaceMember) {
      if (!name.isAccessibleFrom(library)) return;
      Member classMember = classMembers[name];
      if (classMember != null) classMember = classMember.implementation;
      checkInterfaceMember(name, interfaceMember, classMember);
    });
  }

  /// Compute the interface members of [cls] given the set of inherited
  /// interface members [inheritedInterfaceMembers] and declared members
  /// [declaredMembers]. The computed members are stored in [interfaceMembers].
  void computeInterfaceMembers(
        Map<Name, Setlet<Member>> inheritedInterfaceMembers,
        Map<Name, Member> declaredMembers) {
    InterfaceType thisType = cls.thisType;
    // Compute the interface members by overriding the inherited members with
    // a declared member or by computing a single, possibly synthesized,
    // inherited member.
    inheritedInterfaceMembers.forEach(
        (Name name, Setlet<Member> inheritedMembers) {
      Member declared = declaredMembers[name];
      if (declared != null) {
        // Check that [declaredMember] is a valid override
        for (Member inherited in inheritedMembers) {
          checkValidOverride(declared, inherited);
        }
        if (!declared.isStatic) {
          interfaceMembers[name] = declared;
        }
      } else if (inheritedMembers.length == 1) {
        interfaceMembers[name] = inheritedMembers.single;
      } else {
        bool someAreGetters = false;
        bool allAreGetters = true;
        Map<DartType, Setlet<Member>> subtypesOfAllInherited =
            new Map<DartType, Setlet<Member>>();
        outer: for (Member inherited in inheritedMembers) {
          if (inherited.isGetter) {
            someAreGetters = true;
            if (!allAreGetters) break outer;
          } else {
            allAreGetters = false;
            if (someAreGetters) break outer;
          }
          for (MemberSignature other in inheritedMembers) {
            if (!compiler.types.isSubtype(inherited.functionType,
                                          other.functionType)) {
              continue outer;
            }
          }
          subtypesOfAllInherited.putIfAbsent(inherited.functionType,
              () => new Setlet<Member>()).add(inherited);
        }
        if (someAreGetters && !allAreGetters) {
          compiler.reportWarning(cls,
                                 MessageKind.INHERIT_GETTER_AND_METHOD,
                                 {'class': thisType, 'name': name.text });
          for (Member inherited in inheritedMembers) {
            MessageKind kind;
            if (inherited.isMethod) {
              kind = MessageKind.INHERITED_METHOD;
            } else {
              assert(invariant(cls, inherited.isGetter,
                  message: 'Conflicting member is neither a method nor a '
                           'getter.'));
              if (inherited.isDeclaredByField) {
                kind = MessageKind.INHERITED_IMPLICIT_GETTER;
              } else {
                kind = MessageKind.INHERITED_EXPLICIT_GETTER;
              }
            }
            compiler.reportInfo(inherited.element, kind,
                {'class': inherited.declarer, 'name': name.text });
          }
          interfaceMembers[name] = new ErroneousMember(inheritedMembers);
        } else if (subtypesOfAllInherited.length == 1) {
          // All signatures have the same type.
          Setlet<Member> members = subtypesOfAllInherited.values.first;
          MemberSignature inherited = members.first;
          if (members.length != 1) {
            // Multiple signatures with the same type => return a
            // synthesized signature.
            inherited = new SyntheticMember(
                members, inherited.type, inherited.functionType);
          }
          interfaceMembers[name] = inherited;
        } else {
          _inheritedSynthesizedMember(name, inheritedMembers);
        }
      }
    });

    // Add the non-overriding instance methods to the interface members.
    declaredMembers.forEach((Name name, Member member) {
      if (!member.isStatic) {
        interfaceMembers.putIfAbsent(name, () => member);
      }
    });
  }

  /// Create and inherit a synthesized member for [inheritedMembers].
  void _inheritedSynthesizedMember(Name name,
                                   Setlet<Member> inheritedMembers) {
    // Multiple signatures with different types => create the synthesized
    // version.
    int minRequiredParameters;
    int maxPositionalParameters;
    Set<String> names = new Set<String>();
    for (MemberSignature member in inheritedMembers) {
      int requiredParameters = 0;
      int optionalParameters = 0;
      if (member.isSetter) {
        requiredParameters = 1;
      }
      if (member.type.isFunctionType) {
        FunctionType type = member.type;
        type.namedParameters.forEach(
            (String name) => names.add(name));
        requiredParameters = type.parameterTypes.length;
        optionalParameters = type.optionalParameterTypes.length;
      }
      int positionalParameters = requiredParameters + optionalParameters;
      if (minRequiredParameters == null ||
          minRequiredParameters > requiredParameters) {
        minRequiredParameters = requiredParameters;
      }
      if (maxPositionalParameters == null ||
          maxPositionalParameters < positionalParameters) {
        maxPositionalParameters = positionalParameters;
      }
    }
    int optionalParameters =
        maxPositionalParameters - minRequiredParameters;
    // TODO(johnniwinther): Support function types with both optional
    // and named parameters?
    if (optionalParameters == 0 || names.isEmpty) {
      DartType dynamic = const DynamicType();
      List<DartType> requiredParameterTypes =
          new List.filled(minRequiredParameters, dynamic);
      List<DartType> optionalParameterTypes =
          new List.filled(optionalParameters, dynamic);
      List<String> namedParameters =
          names.toList()..sort((a, b) => a.compareTo(b));
      List<DartType> namedParameterTypes =
          new List.filled(namedParameters.length, dynamic);
      FunctionType memberType = new FunctionType.synthesized(
          const DynamicType(),
          requiredParameterTypes,
          optionalParameterTypes,
          namedParameters, namedParameterTypes);
      DartType type = memberType;
      if (inheritedMembers.first.isGetter ||
          inheritedMembers.first.isSetter) {
        type = const DynamicType();
      }
      interfaceMembers[name] =
          new SyntheticMember(inheritedMembers, type, memberType);
    }
  }
}

abstract class ClassMemberMixin implements ClassElement {
  /// When [classMembers] and [interfaceMembers] have not been fully computed
  /// [computedMembersNames] holds the names for which members have already been
  /// computed.
  ///
  /// If [computedMemberNames], [classMembers] and [interfaceMembers] are `null`
  /// no members have been computed, if only [computedMemberNames] is `null` all
  /// members have been computed. A non-null [computedMemberNames] implicitly
  /// includes `call`.
  Iterable<String> computedMemberNames;

  /// If `true` interface members are the non-static class member.
  bool interfaceMembersAreClassMembers = true;

  Map<Name, Member> classMembers;
  Map<Name, MemberSignature> interfaceMembers;

  /// Creates the necessary maps and [MembersCreator] for compute members of
  /// this class.
  MembersCreator _prepareCreator(Compiler compiler) {
    if (classMembers == null) {
      classMembers = new Map<Name, Member>();

      if (interfaceMembersAreClassMembers) {
        ClassMemberMixin superclass = this.superclass;
        if ((superclass != null &&
             (!superclass.interfaceMembersAreClassMembers ||
              superclass.isMixinApplication)) ||
             !interfaces.isEmpty) {
          interfaceMembersAreClassMembers = false;
        }
      }
      if (!interfaceMembersAreClassMembers) {
        interfaceMembers = new Map<Name, MemberSignature>();
      }
    }
    return interfaceMembersAreClassMembers
        ? new ClassMembersCreator(compiler, this,
            computedMemberNames, classMembers)
        : new InterfaceMembersCreator(compiler, this,
            computedMemberNames, classMembers, interfaceMembers);
  }

  static Iterable<String> _EMPTY_MEMBERS_NAMES = const <String>[];

  /// Compute the members by the name [name] for this class. [names] collects
  /// the set of possible variations of [name], including getter, setter and
  /// and private names.
  void computeClassMember(Compiler compiler, String name, Setlet<Name> names) {
    if (isMemberComputed(name)) return;
    if (isPrivateName(name)) {
      names..add(new Name(name, library))
           ..add(new Name(name, library, isSetter: true));
    }
    MembersCreator creator = _prepareCreator(compiler);
    creator.computeMembersByName(name, names);
    if (computedMemberNames == null) {
      computedMemberNames = _EMPTY_MEMBERS_NAMES;
    }
    if (name != Compiler.CALL_OPERATOR_NAME) {
      Setlet<String> set;
      if (identical(computedMemberNames, _EMPTY_MEMBERS_NAMES)) {
        computedMemberNames = set = new Setlet<String>();
      } else {
        set = computedMemberNames;
      }
      set.add(name);
    }
  }

  void computeAllClassMembers(Compiler compiler) {
    if (areAllMembersComputed()) return;
    MembersCreator creator = _prepareCreator(compiler);
    creator.computeAllMembers();
    computedMemberNames = null;
    assert(invariant(this, areAllMembersComputed()));
  }

  bool areAllMembersComputed() {
    return computedMemberNames == null && classMembers != null;
  }

  bool isMemberComputed(String name) {
    if (computedMemberNames == null) {
      return classMembers != null;
    } else {
      return name == Compiler.CALL_OPERATOR_NAME ||
             computedMemberNames.contains(name);
    }
  }

  Member lookupClassMember(Name name) {
    assert(invariant(this,
        isMemberComputed(name.text),
        message: "Member ${name} has not been computed for $this."));
    return classMembers[name];
  }

  void forEachClassMember(f(Member member)) {
    assert(invariant(this, areAllMembersComputed(),
        message: "Members have not been fully computed for $this."));
    classMembers.forEach((_, member) => f(member));
  }

  MemberSignature lookupInterfaceMember(Name name) {
    assert(invariant(this, isMemberComputed(name.text),
        message: "Member ${name.text} has not been computed for $this."));
    if (interfaceMembersAreClassMembers) {
      Member member = classMembers[name];
      if (member != null && member.isStatic) return null;
      return member;
    }
    return interfaceMembers[name];
  }

  void forEachInterfaceMember(f(MemberSignature member)) {
    assert(invariant(this, areAllMembersComputed(),
        message: "Members have not been fully computed for $this."));
    if (interfaceMembersAreClassMembers) {
      classMembers.forEach((_, member) {
        if (!member.isStatic) f(member);
      });
    } else {
      interfaceMembers.forEach((_, member) => f(member));
    }
  }
}
