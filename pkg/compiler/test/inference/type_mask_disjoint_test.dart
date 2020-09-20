// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/inferrer/abstract_value_domain.dart';
import 'package:compiler/src/inferrer/typemasks/masks.dart';
import 'package:compiler/src/world.dart';

import '../helpers/memory_compiler.dart';

const String CODE = """
class A {}
class B extends A {}
class C extends A {}

class D implements A {}

class E {}
class F extends E {}
class G implements E {}

class H {}
class I implements H {}
class J extends D implements I {}

class K {}
class M extends K with A {}

class N extends H with I {}

main() {
  print([new A(), new B(), new C(), new D(), new E(), new F(), new G(),
      new H(), new I(), new J(), new K(), new M(), new N()]);
}
""";

main() {
  runTests() async {
    CompilationResult result =
        await runCompiler(memorySourceFiles: {'main.dart': CODE});
    Expect.isTrue(result.isSuccess);
    Compiler compiler = result.compiler;
    JClosedWorld world = compiler.backendClosedWorldForTesting;
    ElementEnvironment elementEnvironment = world.elementEnvironment;
    AbstractValueDomain commonMasks = world.abstractValueDomain;

    /// Checks the expectation of `isDisjoint` for two mask. Also checks that
    /// the result is consistent with an equivalent (but slower) implementation
    /// based on intersection.
    checkMask(TypeMask m1, TypeMask m2, {areDisjoint: false}) {
      print('masks: $m1 $m2');
      Expect.equals(areDisjoint, m1.isDisjoint(m2, world));
      Expect.equals(areDisjoint, m2.isDisjoint(m1, world));
      var i1 = m1.intersection(m2, commonMasks);
      Expect.equals(areDisjoint, i1.isEmpty && !i1.isNullable);
      var i2 = m2.intersection(m1, commonMasks);
      Expect.equals(areDisjoint, i2.isEmpty && !i2.isNullable);
    }

    Map _maskCache = {};
    Map _elementCache = {};

    /// Parses a descriptor of a flat mask. A descriptor is of the form "AXY"
    /// where:
    ///   A: either a type T or " " (base class or empty)
    ///   X: can be either ! or " " (nullable/nonnullable)
    ///   Y: can be either " " (no flag), = (exact), < (subclass), * (subtype)
    ///
    /// Examples:
    ///   "-! " - empty, non-null
    ///   "-  " - null
    ///   "Type!=" - non-null exact Type
    ///   "Type =" - nullable exact Type
    ///   "Type!<" - non-null subclass of Type
    ///   "Type!*" - non-null subtype of Type
    TypeMask maskOf(String descriptor) =>
        _maskCache.putIfAbsent(descriptor, () {
          Expect.isTrue(descriptor.length >= 3);
          var type = descriptor.substring(0, descriptor.length - 2);
          bool isNullable = descriptor[descriptor.length - 2] != '!';
          bool isExact = descriptor[descriptor.length - 1] == '=';
          bool isSubclass = descriptor[descriptor.length - 1] == '<';
          bool isSubtype = descriptor[descriptor.length - 1] == '*';

          if (type == " ") {
            Expect.isFalse(isExact || isSubclass || isSubtype);
            return isNullable
                ? new TypeMask.empty()
                : new TypeMask.nonNullEmpty();
          }

          Expect.isTrue(isExact || isSubclass || isSubtype);
          var element = _elementCache.putIfAbsent(type, () {
            if (type == " ") return null;
            ClassEntity cls = elementEnvironment.lookupClass(
                elementEnvironment.mainLibrary, type);
            Expect.isNotNull(cls, "No class '$type' found.");
            return cls;
          });

          var mask = isExact
              ? new TypeMask.nonNullExact(element, world)
              : (isSubclass
                  ? new TypeMask.nonNullSubclass(element, world)
                  : new TypeMask.nonNullSubtype(element, world));
          return isNullable ? mask.nullable() : mask;
        });

    /// Checks the expectation of `isDisjoint` for two mask descriptors (see
    /// [maskOf] for details).
    check(String typeMaskDescriptor1, String typeMaskDescriptor2,
        {areDisjoint: true}) {
      print('[$typeMaskDescriptor1] & [$typeMaskDescriptor2]');
      checkMask(maskOf(typeMaskDescriptor1), maskOf(typeMaskDescriptor2),
          areDisjoint: areDisjoint);
    }

    checkUnions(List<String> descriptors1, List<String> descriptors2,
        {areDisjoint: true}) {
      print('[$descriptors1] & [$descriptors2]');
      var m1 =
          new TypeMask.unionOf(descriptors1.map(maskOf).toList(), commonMasks);
      var m2 =
          new TypeMask.unionOf(descriptors2.map(maskOf).toList(), commonMasks);
      checkMask(m1, m2, areDisjoint: areDisjoint);
    }

    // Empty
    check(' ! ', ' ! '); // both non-null
    check(' ! ', '   '); // one non-null
    check('   ', ' ! '); // one non-null
    check('   ', '   ', areDisjoint: false); // null is common

    // Exact
    check('A!=', 'A!=', areDisjoint: false);
    check('A!=', 'B!=');
    check('A!=', 'E!=');
    check('A =', 'E =', areDisjoint: false); // null is common
    check('M!=', 'K!=');
    check('M!=', 'A!=');

    // Exact with subclass
    check('A!=', 'A!<', areDisjoint: false);
    check('B!=', 'A!<', areDisjoint: false);
    check('A!=', 'B!<');
    check('A!=', 'E!<');
    check('A =', 'E!<');
    check('A =', 'E <', areDisjoint: false);
    check('M!=', 'K!<', areDisjoint: false);
    check('M!=', 'A!<');

    // Exact with subtype
    check('A!=', 'A!*', areDisjoint: false);
    check('B!=', 'A!*', areDisjoint: false);
    check('A!=', 'B!*');
    check('A!=', 'E!*');
    check('A!=', 'I!*');
    check('J!=', 'H!*', areDisjoint: false);
    check('M!=', 'K!*', areDisjoint: false);
    check('M!=', 'A!*', areDisjoint: false);

    // Subclass with subclass
    check('A!<', 'A!<', areDisjoint: false);
    check('A!<', 'B!<', areDisjoint: false);
    check('A!<', 'E!<');
    check('A!<', 'H!<');
    check('D!<', 'I!<');
    check('H!<', 'I!*', areDisjoint: false);

    // Subclass with subtype
    check('A!<', 'A!*', areDisjoint: false);
    check('A!<', 'B!*', areDisjoint: false);
    check('A!<', 'E!*');
    check('A!<', 'H!*');
    check('D!<', 'I!*', areDisjoint: false);

    // Subtype with subtype
    check('A!*', 'A!*', areDisjoint: false);
    check('A!*', 'B!*', areDisjoint: false);
    check('A!*', 'E!*');
    check('A!*', 'H!*', areDisjoint: false);
    check('D!*', 'I!*', areDisjoint: false);

    // Unions!
    checkUnions(['B!=', 'C!='], ['A!=']);
    checkUnions(['B!=', 'C!='], ['A =']);
    checkUnions(['B!=', 'C ='], ['A ='], areDisjoint: false);

    checkUnions(['B!=', 'C!='], ['A!<'], areDisjoint: false);
    checkUnions(['B!=', 'C!='], ['B!='], areDisjoint: false);
    checkUnions(['A!<', 'E!<'], ['C!='], areDisjoint: false);
    checkUnions(['A!<', 'E!<'], ['F!='], areDisjoint: false);

    checkUnions(['A!=', 'E!='], ['C!=', 'F!=']);
    checkUnions(['A!=', 'E!='], ['A!=', 'F!='], areDisjoint: false);
    checkUnions(['B!=', 'E!='], ['A!<', 'F!='], areDisjoint: false);
    checkUnions(['A!<', 'E!<'], ['C!=', 'F!='], areDisjoint: false);
    checkUnions(['A!=', 'E!='], ['C!=', 'F!=']);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
