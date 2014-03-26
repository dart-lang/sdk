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
import '../elements/modelx.dart'
    show BaseClassElementX;
import '../dart_types.dart';
import '../dart2jslib.dart'
    show Compiler,
         MessageKind,
         invariant;
import '../util/util.dart';

part 'member_impl.dart';

class MembersCreator {
  final ClassElement cls;
  final Compiler compiler;

  Map<Name, Member> classMembers = new Map<Name, Member>();
  Map<Name, MemberSignature> interfaceMembers =
      new Map<Name, MemberSignature>();

  Map<dynamic/* Member | Element */, Set<MessageKind>> reportedMessages =
      new Map<dynamic, Set<MessageKind>>();

  MembersCreator(Compiler this.compiler, ClassElement this.cls) {
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

  void computeMembers() {
    Map<Name, Set<Member>> inheritedInterfaceMembers =
        _computeSuperMembers();
    Map<Name, Member> declaredMembers = _computeClassMembers();
    _computeInterfaceMembers(inheritedInterfaceMembers, declaredMembers);

    if (!cls.modifiers.isAbstract() &&
        !declaredMembers.containsKey(const PublicName('noSuchMethod'))) {
      // Check for unimplemented members on concrete classes that neither have
      // a `@proxy` annotation nor declare a `noSuchMethod` method.
      checkInterfaceImplementation();
    }
  }

  Map<Name, Set<Member>> _computeSuperMembers() {
    Map<Name, Set<Member>> inheritedInterfaceMembers =
        new Map<Name, Set<Member>>();

    void inheritInterfaceMembers(InterfaceType supertype) {
      supertype.element.forEachInterfaceMember((MemberSignature member) {
        Set<Member> members =
            inheritedInterfaceMembers.putIfAbsent(
                member.name, () => new Set<Member>());
        for (DeclaredMember declaredMember in member.declarations) {
          members.add(declaredMember.inheritFrom(supertype));
        }
      });
    }

    // Inherit class and interface members from superclass.
    InterfaceType superclass = cls.supertype;
    if (superclass != null) {
      computeClassMembers(compiler, superclass.element);
      superclass.element.forEachClassMember((DeclaredMember member) {
        if (!member.isStatic) {
          DeclaredMember inherited = member.inheritFrom(superclass);
          classMembers[member.name] = inherited;
        }
      });
      inheritInterfaceMembers(superclass);
    }

    // Inherit interface members from superinterfaces.
    for (Link<DartType> link = cls.interfaces;
         !link.isEmpty;
         link = link.tail) {
      InterfaceType superinterface = link.head;
      computeClassMembers(compiler, superinterface.element);
      inheritInterfaceMembers(superinterface);
    }

    return inheritedInterfaceMembers;
  }

  Map<Name, Member> _computeClassMembers() {
    Map<Name, Member> declaredMembers = new Map<Name, Member>();

    void overrideMember(DeclaredMember declared) {
      DeclaredMember inherited = classMembers[declared.name];
      classMembers[declared.name] = declared;
      checkValidOverride(declared, inherited);
    }

    if (cls.isMixinApplication) {
      MixinApplicationElement mixinApplication = cls;
      if (mixinApplication.mixin != null) {
        // Only mix in class members when the mixin type is not malformed.
        computeClassMembers(compiler, mixinApplication.mixin);

        mixinApplication.mixin.forEachClassMember((DeclaredMember member) {
          if (!member.isStatic) {
            // Abstract and static members are not mixed in.
            DeclaredMember mixedInMember =
                member.inheritFrom(mixinApplication.mixinType);
            overrideMember(mixedInMember);
          }
        });
      }
    } else {
      LibraryElement library = cls.getLibrary();
      InterfaceType thisType = cls.thisType;

      void createMember(Element element) {
        if (element.isConstructor()) return;

        Name name = new Name(element.name, library);
        if (element.isField()) {
          DartType type = element.computeType(compiler);
          declaredMembers[name] = new DeclaredMember(
              name, element, thisType, type,
              new FunctionType(compiler.functionClass, type));
          if (!element.modifiers.isConst() &&
              !element.modifiers.isFinal()) {
            name = name.setter;
            declaredMembers[name] = new DeclaredMember(
                name, element, thisType, type,
                new FunctionType(compiler.functionClass,
                                 compiler.types.voidType,
                                 const Link<DartType>().prepend(type)));
          }
        } else if (element.isGetter()) {
          FunctionType functionType = element.computeType(compiler);
          DartType type = functionType.returnType;
          declaredMembers[name] =
              new DeclaredMember(name, element, thisType, type, functionType);
        } else if (element.isSetter()) {
          FunctionType functionType = element.computeType(compiler);
          DartType type;
          if (!functionType.parameterTypes.isEmpty) {
            type = functionType.parameterTypes.head;
          } else {
            type = compiler.types.dynamicType;
          }
          name = name.setter;
          declaredMembers[name] = new DeclaredMember(
              name, element, thisType, type, functionType);
        } else {
          assert(invariant(element, element.isFunction()));
          FunctionType type = element.computeType(compiler);
          declaredMembers[name] = new DeclaredMember(
              name, element, thisType, type, type);
        }
      };

      cls.forEachLocalMember(createMember);
      if (cls.isPatched) {
        cls.implementation.forEachLocalMember((Element element) {
          if (element.isDeclaration) {
            createMember(element);
          }
        });
      }
    }

    declaredMembers.values.forEach((Member member) {
      if (!member.element.isAbstract) {
        overrideMember(member);
      }
    });

    return declaredMembers;
  }

  void _computeInterfaceMembers(
        Map<Name, Set<Member>> inheritedInterfaceMembers,
        Map<Name, Member> declaredMembers) {
    InterfaceType thisType = cls.thisType;
    // Compute the interface members by overriding the inherited members with
    // a declared member or by computing a single, possibly synthesized,
    // inherited member.
    inheritedInterfaceMembers.forEach(
        (Name name, Set<Member> inheritedMembers) {
      Member declared = declaredMembers[name];
      if (declared != null) {
        // Check that [declaredMember] is a valid override
        for (Member inherited in inheritedMembers) {
          checkValidOverride(declared, inherited);
        }
        if (!declared.isStatic) {
          interfaceMembers[name] = declared;
        }
      } else {
        bool someAreGetters = false;
        bool allAreGetters = true;
        Map<DartType, Set<Member>> subtypesOfAllInherited =
            new Map<DartType, Set<Member>>();
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
              () => new Set<Member>()).add(inherited);
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
          Set<Member> members = subtypesOfAllInherited.values.first;
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
                                   Set<Member> inheritedMembers) {
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
      if (member.type.kind == TypeKind.FUNCTION) {
        FunctionType type = member.type;
        type.namedParameters.forEach(
            (String name) => names.add(name));
        requiredParameters = type.parameterTypes.slowLength();
        optionalParameters = type.optionalParameterTypes.slowLength();
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
      Link<DartType> requiredParameterTypes = const Link<DartType>();
      while (--minRequiredParameters >= 0) {
        requiredParameterTypes =
            requiredParameterTypes.prepend(compiler.types.dynamicType);
      }
      Link<DartType> optionalParameterTypes = const Link<DartType>();
      while (--optionalParameters >= 0) {
        optionalParameterTypes =
            optionalParameterTypes.prepend(compiler.types.dynamicType);
      }
      Link<String> namedParameters = const Link<String>();
      Link<DartType> namedParameterTypes = const Link<DartType>();
      List<String> namesReversed =
          names.toList()..sort((a, b) => -a.compareTo(b));
      for (String name in namesReversed) {
        namedParameters = namedParameters.prepend(name);
        namedParameterTypes =
            namedParameterTypes.prepend(compiler.types.dynamicType);
      }
      FunctionType memberType = new FunctionType(
          compiler.functionClass,
          compiler.types.dynamicType,
          requiredParameterTypes,
          optionalParameterTypes,
          namedParameters, namedParameterTypes);
      DartType type = memberType;
      if (inheritedMembers.first.isGetter ||
          inheritedMembers.first.isSetter) {
        type = compiler.types.dynamicType;
      }
      interfaceMembers[name] = new SyntheticMember(
          inheritedMembers, type, memberType);
    }
  }

  /// Checks that a class member exists for every interface member.
  void checkInterfaceImplementation() {
    LibraryElement library = cls.getLibrary();

    interfaceMembers.forEach((Name name, MemberSignature interfaceMember) {
      if (!name.isAccessibleFrom(library)) return;
      Member classMember = classMembers[name];
      if (classMember != null) return;
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
    });
  }

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
         'className': contextElement.getEnclosingClass().name});
    compiler.reportInfo(contextElement, contextMessage);
  }

  static void computeClassMembers(Compiler compiler, BaseClassElementX cls) {
    if (cls.classMembers != null) return;
    MembersCreator creator = new MembersCreator(compiler, cls);
    creator.computeMembers();
    cls.classMembers = creator.classMembers;
    cls.interfaceMembers = creator.interfaceMembers;
  }
}
