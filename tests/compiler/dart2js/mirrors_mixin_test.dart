// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mirrors_mixin_test;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'mirror_system_helper.dart';

const String CLASS_SOURCE = '''
class A {}

class S {}
class M1<T> {}
class M2 {}

class C extends S with M1<A> {}
class D extends S with M1, M2 {}
class E extends S with M2, M1 implements A, M1 {}
class E2 extends E {}

class F = S with M1<A>;
abstract class G = S with M1, M2;
class H = S with M2, M1 implements A, M1;
class H2 extends H {}
''';

void main() {
  asyncTest(() => createMirrorSystem(CLASS_SOURCE).then((MirrorSystem mirrors) {
    LibraryMirror library = mirrors.libraries[SOURCE_URI];

    checkSimpleClass(var cls) {
      Expect.isNotNull(cls);
      Expect.isTrue(cls is ClassMirror);
      Expect.isFalse(isMixinApplication(cls));
      Expect.isFalse(cls.isNameSynthetic);
      Expect.isFalse(isObject(cls));
      Expect.isTrue(isObject(cls.superclass));
      Expect.equals(0, cls.superinterfaces.length);

      Expect.isTrue(isObject(getSuperclass(cls)));
      Expect.isTrue(getAppliedMixins(cls).isEmpty);
      Expect.isTrue(getExplicitInterfaces(cls).isEmpty);
    }

    // class A {}
    var A = library.declarations[#A];
    checkSimpleClass(A);

    // class S {}
    var S = library.declarations[#S];
    checkSimpleClass(S);

    // class M1 {}
    var M1 = library.declarations[#M1];
    checkSimpleClass(M1);

    // class M2 {}
    var M2 = library.declarations[#M2];
    checkSimpleClass(M2);

    // class C extends S with M1<A> {}
    var C = library.declarations[#C];
    Expect.isNotNull(C);
    Expect.isTrue(C is ClassMirror);
    Expect.isFalse(isMixinApplication(C));
    Expect.isFalse(isObject(C));
    Expect.equals(0, C.superinterfaces.length);
    var C_super = C.superclass;
    Expect.isNotNull(C_super);
    Expect.isTrue(C_super is ClassMirror);
    Expect.isTrue(isMixinApplication(C_super));
    Expect.isTrue(C_super.isNameSynthetic);
    Expect.equals(1, C_super.superinterfaces.length);
    Expect.isTrue(containsType(M1, [A], C_super.superinterfaces));
    Expect.isTrue(isInstance(M1, [A], C_super.mixin));
    Expect.isFalse(isObject(C_super));
    Expect.isTrue(isSameDeclaration(S, C_super.superclass));

    Expect.isTrue(isSameDeclaration(S, getSuperclass(C)));
    Expect.isTrue(isSameDeclarationList([M1], getAppliedMixins(C)));
    Expect.isTrue(getExplicitInterfaces(C).isEmpty);

    // D extends S with M1, M2 {}
    var D = library.declarations[#D];
    Expect.isNotNull(D);
    Expect.isTrue(D is ClassMirror);
    Expect.isFalse(isMixinApplication(D));
    Expect.isFalse(isObject(D));
    Expect.equals(0, D.superinterfaces.length);
    var D_super = D.superclass;
    Expect.isNotNull(D_super);
    Expect.isTrue(D_super is ClassMirror);
    Expect.isTrue(isMixinApplication(D_super));
    Expect.isTrue(D_super.isNameSynthetic);
    Expect.equals(1, D_super.superinterfaces.length);
    Expect.isTrue(containsDeclaration(M2, D_super.superinterfaces));
    Expect.isTrue(isSameDeclaration(M2, D_super.mixin));
    Expect.isFalse(isObject(D_super));
    Expect.isFalse(isSameDeclaration(S, D_super.superclass));
    var D_super_super = D_super.superclass;
    Expect.isNotNull(D_super_super);
    Expect.isTrue(D_super_super is ClassMirror);
    Expect.isTrue(isMixinApplication(D_super_super));
    Expect.isTrue(D_super_super.isNameSynthetic);
    Expect.equals(1, D_super_super.superinterfaces.length);
    Expect.isTrue(containsDeclaration(M1, D_super_super.superinterfaces));
    Expect.isTrue(isSameDeclaration(M1, D_super_super.mixin));
    Expect.isFalse(isObject(D_super_super));
    Expect.isTrue(isSameDeclaration(S, D_super_super.superclass));

    Expect.isTrue(isSameDeclaration(S, getSuperclass(D)));
    Expect.isTrue(isSameDeclarationList([M1, M2], getAppliedMixins(D)));
    Expect.isTrue(getExplicitInterfaces(D).isEmpty);

    // class E extends S with M2, M1 implements A, M1 {}
    var E = library.declarations[#E];
    Expect.isNotNull(E);
    Expect.isTrue(E is ClassMirror);
    Expect.isFalse(isMixinApplication(E));
    Expect.isFalse(isObject(E));
    Expect.equals(2, E.superinterfaces.length);
    Expect.isTrue(containsDeclaration(A, E.superinterfaces));
    Expect.isTrue(containsDeclaration(M1, E.superinterfaces));
    var E_super = E.superclass;
    Expect.isNotNull(E_super);
    Expect.isTrue(E_super is ClassMirror);
    Expect.isTrue(isMixinApplication(E_super));
    Expect.isTrue(E_super.isNameSynthetic);
    Expect.equals(1, E_super.superinterfaces.length);
    Expect.isTrue(containsDeclaration(M1, E_super.superinterfaces));
    Expect.isTrue(isSameDeclaration(M1, E_super.mixin));
    Expect.isFalse(isObject(E_super));
    Expect.isFalse(isSameDeclaration(S, E_super.superclass));
    var E_super_super = E_super.superclass;
    Expect.isNotNull(E_super_super);
    Expect.isTrue(E_super_super is ClassMirror);
    Expect.isTrue(isMixinApplication(E_super_super));
    Expect.isTrue(E_super_super.isNameSynthetic);
    Expect.equals(1, E_super_super.superinterfaces.length);
    Expect.isTrue(containsDeclaration(M2, E_super_super.superinterfaces));
    Expect.isTrue(isSameDeclaration(M2, E_super_super.mixin));
    Expect.isFalse(isObject(E_super_super));
    Expect.isTrue(isSameDeclaration(S, E_super_super.superclass));

    Expect.isTrue(isSameDeclaration(S, getSuperclass(E)));
    Expect.isTrue(isSameDeclarationList([M2, M1], getAppliedMixins(E)));
    Expect.isTrue(isSameDeclarationSet([A, M1], getExplicitInterfaces(E)));

    // class E2 extends E {}
    var E2 = library.declarations[#E2];
    Expect.isTrue(isSameDeclaration(E, getSuperclass(E2)));
    Expect.isTrue(getAppliedMixins(E2).isEmpty);
    Expect.isTrue(getExplicitInterfaces(E2).isEmpty);

    // class F = S with M1<A>;
    var F = library.declarations[#F];
    Expect.isNotNull(F);
    Expect.isTrue(F is ClassMirror);
    Expect.isFalse(F.isAbstract);
    Expect.isTrue(isMixinApplication(F));
    Expect.isFalse(F.isNameSynthetic);
    Expect.equals(#F, F.simpleName);
    Expect.isFalse(isObject(F));
    Expect.equals(1, F.superinterfaces.length);
    Expect.isTrue(containsDeclaration(M1, F.superinterfaces));
    Expect.isTrue(isInstance(M1, [A], F.mixin));
    var F_super = F.superclass;
    Expect.isNotNull(F_super);
    Expect.isTrue(F_super is ClassMirror);
    Expect.isFalse(isMixinApplication(F_super));
    Expect.isFalse(isObject(F_super));
    Expect.isTrue(isSameDeclaration(S, F_super));

    Expect.isTrue(isSameDeclaration(S, getSuperclass(F)));
    Expect.isTrue(isSameDeclarationList([M1], getAppliedMixins(F)));
    Expect.isTrue(getExplicitInterfaces(F).isEmpty);

    // typedef G = abstract S with M1, M2;
    var G = library.declarations[#G];
    Expect.isNotNull(G);
    Expect.isTrue(G is ClassMirror);
    Expect.isTrue(G.isAbstract);
    Expect.isTrue(isMixinApplication(G));
    Expect.isFalse(G.isNameSynthetic);
    Expect.equals(#G, G.simpleName);
    Expect.isFalse(isObject(G));
    Expect.equals(1, G.superinterfaces.length);
    Expect.isTrue(containsDeclaration(M2, G.superinterfaces));
    Expect.isTrue(isSameDeclaration(M2, G.mixin));
    var G_super = G.superclass;
    Expect.isNotNull(G_super);
    Expect.isTrue(G_super is ClassMirror);
    Expect.isTrue(isMixinApplication(G_super));
    Expect.equals(1, G_super.superinterfaces.length);
    Expect.isTrue(containsDeclaration(M1, G_super.superinterfaces));
    Expect.isTrue(isSameDeclaration(M1, G_super.mixin));
    Expect.isFalse(isObject(G_super));
    Expect.isTrue(isSameDeclaration(S, G_super.superclass));

    Expect.isTrue(isSameDeclaration(S, getSuperclass(G)));
    Expect.isTrue(isSameDeclarationList([M1, M2], getAppliedMixins(G)));
    Expect.isTrue(getExplicitInterfaces(G).isEmpty);

    // typedef H = S with M2, M1 implements A, M1;
    var H = library.declarations[#H];
    Expect.isNotNull(H);
    Expect.isTrue(H is ClassMirror);
    Expect.isFalse(H.isAbstract);
    Expect.isTrue(isMixinApplication(H));
    Expect.isFalse(H.isNameSynthetic);
    Expect.equals(#H, H.simpleName);
    Expect.isFalse(isObject(H));
    Expect.equals(3, H.superinterfaces.length);
    Expect.isTrue(containsDeclaration(A, H.superinterfaces));
    Expect.isTrue(containsDeclaration(M1, H.superinterfaces));
    Expect.isFalse(containsDeclaration(M2, H.superinterfaces));
    Expect.isTrue(isSameDeclaration(M1, H.mixin));
    var H_super = H.superclass;
    Expect.isNotNull(H_super);
    Expect.isTrue(H_super is ClassMirror);
    Expect.isTrue(isMixinApplication(H_super));
    Expect.equals(1, H_super.superinterfaces.length);
    Expect.isTrue(containsDeclaration(M2, H_super.superinterfaces));
    Expect.isTrue(isSameDeclaration(M2, H_super.mixin));
    Expect.isFalse(isObject(H_super));
    Expect.isTrue(isSameDeclaration(S, H_super.superclass));

    Expect.isTrue(isSameDeclaration(S, getSuperclass(H)));
    Expect.isTrue(isSameDeclarationList([M2, M1], getAppliedMixins(H)));
    Expect.isTrue(isSameDeclarationSet([A, M1], getExplicitInterfaces(H)));

    // class H2 extends H {}
    var H2 = library.declarations[#H2];
    Expect.isTrue(isSameDeclaration(H, getSuperclass(H2)));
    Expect.isTrue(getAppliedMixins(H2).isEmpty);
    Expect.isTrue(getExplicitInterfaces(H2).isEmpty);
  }));
}