// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.modifier;

import 'problems.dart' show unhandled;

enum ModifierEnum {
  Abstract,
  Const,
  Covariant,
  External,
  Final,
  Static,

  // Not a real modifier.
  Var,
}

const int abstractMask = 1;

const int constMask = abstractMask << 1;

const int covariantMask = constMask << 1;

const int externalMask = covariantMask << 1;

const int finalMask = externalMask << 1;

const int staticMask = finalMask << 1;

const int namedMixinApplicationMask = staticMask << 1;

/// Not a real modifier, and by setting it to zero, it is automatically ignored
/// by [Modifier.validate] below.
const int varMask = 0;

const Modifier Abstract = const Modifier(ModifierEnum.Abstract, abstractMask);

const Modifier Const = const Modifier(ModifierEnum.Const, constMask);

const Modifier Covariant =
    const Modifier(ModifierEnum.Covariant, covariantMask);

const Modifier External = const Modifier(ModifierEnum.External, externalMask);

const Modifier Final = const Modifier(ModifierEnum.Final, finalMask);

const Modifier Static = const Modifier(ModifierEnum.Static, staticMask);

/// Not a real modifier.
const Modifier Var = const Modifier(ModifierEnum.Var, varMask);

class Modifier {
  final ModifierEnum kind;

  final int mask;

  const Modifier(this.kind, this.mask);

  factory Modifier.fromString(String string) {
    if (identical('abstract', string)) return Abstract;
    if (identical('const', string)) return Const;
    if (identical('covariant', string)) return Covariant;
    if (identical('external', string)) return External;
    if (identical('final', string)) return Final;
    if (identical('static', string)) return Static;
    if (identical('var', string)) return Var;
    return unhandled(string, "Modifier.fromString", -1, null);
  }

  toString() => "modifier(${'$kind'.substring('ModifierEnum.'.length)})";

  static int validate(List<Modifier> modifiers, {bool isAbstract: false}) {
    // TODO(ahe): Rename this method, validation is now taken care of by the
    // parser.
    int result = isAbstract ? abstractMask : 0;
    if (modifiers == null) return result;
    for (Modifier modifier in modifiers) {
      result |= modifier.mask;
    }
    return result;
  }
}
