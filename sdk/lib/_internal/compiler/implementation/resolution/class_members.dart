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

  MembersCreator(Compiler this.compiler, ClassElement this.cls);

  void computeMembers() {
    Map<Name, Set<Member>> inheritedInterfaceMembers =
        _computeSuperMembers();
    Map<Name, Member> declaredMembers = _computeClassMembers();
    _computeInterfaceMembers(inheritedInterfaceMembers, declaredMembers);
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
      classMembers[declared.name] = declared;
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

      cls.forEachLocalMember((Element element) {
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
      });
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

  static void computeClassMembers(Compiler compiler, BaseClassElementX cls) {
    if (cls.classMembers != null) return;
    MembersCreator creator = new MembersCreator(compiler, cls);
    creator.computeMembers();
    cls.classMembers = creator.classMembers;
    cls.interfaceMembers = creator.interfaceMembers;
  }
}
