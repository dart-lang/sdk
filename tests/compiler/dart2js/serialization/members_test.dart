// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization.class_members_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common/names.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/names.dart';
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/resolution/class_members.dart';
import 'package:compiler/src/serialization/equivalence.dart';
import '../equivalence/check_helpers.dart';
import '../equivalence/check_functions.dart';
import '../memory_compiler.dart';
import 'helper.dart';

main(List<String> args) {
  Arguments arguments = new Arguments.from(args);
  asyncTest(() async {
    SerializedData serializedData =
        await serializeDartCore(arguments: arguments);
    if (arguments.filename != null) {
      Uri entryPoint = Uri.base.resolve(nativeToUriPath(arguments.filename));
      await checkClassMembers(serializedData, entryPoint,
          verbose: arguments.verbose);
    } else {
      await checkClassMembers(serializedData, Uris.dart_core,
          verbose: arguments.verbose);
    }
  });
}

Future checkClassMembers(SerializedData serializedData, Uri entryPoint,
    {bool verbose: false}) async {
  Compiler compilerNormal = compilerFor(options: [Flags.analyzeAll]);
  await compilerNormal.run(entryPoint);

  Compiler compilerDeserialized = compilerFor(
      memorySourceFiles: serializedData.toMemorySourceFiles(),
      resolutionInputs: serializedData.toUris(),
      options: [Flags.analyzeAll]);
  await compilerDeserialized.run(entryPoint);

  checkAllMembers(compilerNormal, compilerDeserialized, verbose: true);
}

void checkAllMembers(Compiler compiler1, Compiler compiler2,
    {bool verbose: false}) {
  checkLoadedLibraryMembers(compiler1, compiler2,
      (Element member1) => member1 is ClassElement, checkMembers,
      verbose: verbose);
}

/// Check equivalence of members of [class1] and [class2].
void checkMembers(
    Compiler compiler1, Element _class1, Compiler compiler2, Element _class2,
    {bool verbose: false}) {
  ClassMemberMixin class1 = _class1;
  ClassMemberMixin class2 = _class2;
  if (verbose) {
    print('Checking $class1 vs $class2');
  }
  MembersCreator.computeAllClassMembers(compiler1.resolution, class1);
  MembersCreator.computeAllClassMembers(compiler2.resolution, class2);

  check(
      class1,
      class2,
      'interfaceMemberAreClassMembers',
      class1.interfaceMembersAreClassMembers,
      class2.interfaceMembersAreClassMembers);
  class1.forEachClassMember((Member member1) {
    Name name1 = member1.name;
    Name name2 = convertName(name1, compiler2);
    checkMember(class1, class2, 'classMember:$name1', member1,
        class2.lookupClassMember(name2));
  });

  class1.forEachInterfaceMember((MemberSignature member1) {
    Name name1 = member1.name;
    Name name2 = convertName(name1, compiler2);
    checkMemberSignature(class1, class2, 'interfaceMember:$name1', member1,
        class2.lookupInterfaceMember(name2));
  });
}

Name convertName(Name name, Compiler compiler) {
  if (name.isPrivate) {
    LibraryElement library1 = name.library;
    LibraryElement library2 =
        compiler.libraryLoader.lookupLibrary(library1.canonicalUri);
    if (!areElementsEquivalent(library1, library2)) {
      throw 'Libraries ${library1} and ${library2} are not equivalent';
    }
    name = new Name(name.text, library2, isSetter: name.isSetter);
  }
  return name;
}

void checkMember(ClassElement class1, ClassElement class2, String property,
    Member member1, Member member2) {
  if (member2 == null) {
    print('$class1 class members:');
    class1.forEachClassMember((m) => print(' ${m.name} $m'));
    print('$class2 class members:');
    class2.forEachClassMember((m) => print(' ${m.name} $m'));
    throw "No member ${member1.name} in $class2 for $property";
  }
  checkMemberSignature(class1, class2, property, member1, member2);
  checkElementIdentities(
      class1, class2, '$property.element', member1.element, member2.element);
  check(class1, class2, '$property.declarer', member1.declarer,
      member2.declarer, areTypesEquivalent);
  check(
      class1, class2, '$property.isStatic', member1.isStatic, member2.isStatic);
  check(class1, class2, '$property.isDeclaredByField',
      member1.isDeclaredByField, member2.isDeclaredByField);
  check(class1, class2, '$property.isAbstract', member1.isAbstract,
      member2.isAbstract);
  if (member1.isAbstract && member1.implementation != null) {
    checkMember(class1, class2, '$property.implementation',
        member1.implementation, member2.implementation);
  }
}

void checkMemberSignature(ClassElement class1, ClassElement class2,
    String property, MemberSignature member1, MemberSignature member2) {
  if (member2 == null) {
    print('$class1 interface members:');
    class1.forEachInterfaceMember((m) => print(' ${m.name} $m'));
    print('$class2 interface members:');
    class2.forEachInterfaceMember((m) => print(' ${m.name} $m'));
    throw "No member ${member1.name} in $class2 for $property";
  }
  check(class1, class2, '$property.name', member1.name, member2.name,
      areNamesEquivalent);
  check(class1, class2, '$property.type', member1.type, member2.type,
      areTypesEquivalent);
  check(class1, class2, '$property.functionType', member1.functionType,
      member2.functionType, areTypesEquivalent);
  check(
      class1, class2, '$property.isGetter', member1.isGetter, member2.isGetter);
  check(
      class1, class2, '$property.isSetter', member1.isSetter, member2.isSetter);
  check(
      class1, class2, '$property.isMethod', member1.isMethod, member2.isMethod);
}
