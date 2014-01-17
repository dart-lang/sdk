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

  MembersCreator(Compiler this.compiler, ClassElement this.cls);

  void computeMembers() {
    _computeSuperMembers();
    _computeClassMembers();
  }

  void _computeSuperMembers() {
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
    }
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

  static void computeClassMembers(Compiler compiler, BaseClassElementX cls) {
    if (cls.classMembers != null) return;
    MembersCreator creator = new MembersCreator(compiler, cls);
    creator.computeMembers();
    cls.classMembers = creator.classMembers;
  }
}
