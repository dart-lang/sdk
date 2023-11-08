// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'pattern_types_lib1.dart';
import 'pattern_types_lib2.dart';

typedef Dynamic = dynamic;
typedef Function1 = void Function();
typedef Function1_ = Function1?;
typedef Record1 = (int, {String named});
typedef Record1_ = Record1?;
typedef Class_ = Class?;

class Class {
  var field;
  void method() {}
  bool operator <(int i) => true;
  int operator >(int i) => 0;
  operator ==(other) => true;
}

class Class2 {
  bool operator <(Class2 i) => true;
  operator ==(covariant Class2 other) => true;
}

extension on Class {
  int get extensionGetter => 42;
  void extensionMethod() {}
  bool operator <=(int i) => true;
  int operator >=(int i) => 0;
  int get ambiguousField => 42;
}

extension on Class {
  String get ambiguousField => '42';
}

extension on String {
  bool operator <=(other) => true;
}

extension on String {
  bool operator <=(other) => true;
}


/* // TODO(johnniwinther): Enable this when extension type declarations are
       supported.
extension type ExtensionType(int it) {
  int get getter => 42;
  void method() {}

  bool operator <(int i) => true;
  int operator >(int i) => 0;
}
typedef ExtensionType_ = ExtensionType?;
*/

objectPattern(o) {
  switch (o) {
    case Null(: var hashCode): // object member get
    case Null(: var toString): // object member tear-off
    case Class(: var field): // instance member get
    case Class(: var method): // instance member tear-off
    case Class(: var extensionGetter): // extension member get
    case Class(: var extensionMethod): // extension member tear-off
    case Dynamic(: var dynamicAccess): // dynamic get
    case Function1(: var call): // function tear off
    case Record1(: var $1): // record index get
    case Record1(: var named): // record named get
    case Class(: var missing): // Error: missing getter
    case Class_(: var field): // Error: nullable member get
    case Class_(: var method): // Error: nullable member tear-off
    case Class_(: var extensionGetter): // Error: nullable extension member get
    case Class_(: var extensionMethod): // Error: nullable extension tear-off
    case Function1_(: var call): // Error: nullable function tear-off
    case Record1_(: var $1): // Error: nullable record index get
    case Record1_(: var named): // Error: nullable record named get
    case Class(: var ambiguousField): // Error: ambiguous get
    case Invalid(: field): // invalid get
/* // TODO(johnniwinther): Enable this when extension type declarations are
       supported.
    case ExtensionType(: var it): // extension type representation field get
    case ExtensionType(: var getter): // extension type member get
    case ExtensionType(: var method): // extension type member tear-off
*/
  }
}

relationalPattern(dynamic dyn, Never never, Class cls, Class? cls_,
    Invalid invalid, String string, Class2 cls2, Class2? cls2_,
    /* // TODO(johnniwinther): Enable this when extension type declarations are
           supported.
    , ExtensionType extensionType*/) {
  if (dyn case == 0) {} // object ==
  if (dyn case != 0) {} // object == negated
  if (dyn case < 0) {} // dynamic <
  if (dyn case <= 0) {} // dynamic <=
  if (dyn case > 0) {} // dynamic >
  if (dyn case >= 0) {} // dynamic >=
  if (never case == 0) {} // never ==
  if (never case != 0) {} // never == negated
  if (never case < 0) {} // never <
  if (never case <= 0) {} // never <=
  if (never case > 0) {} // never >
  if (never case >= 0) {} // never >=
  if (cls case == 0) {} // instance ==
  if (cls case != 0) {} // instance == negated
  if (cls case < 0) {} // instance <
  if (cls case <= 0) {} // extension <=
  if (cls case < '0') {} // Error: invalid instance < argument
  if (cls case <= '0') {} // Error: invalid extension <= argument
  if (cls case > 0) {} // Error: invalid instance >
  if (cls case >= 0) {} // Error: invalid extension >=
  if (cls_ case == 0) {} // object ==
  if (cls_ case != 0) {} // object == negated
  if (cls_ case < 0) {} // Error: nullable instance <
  if (cls_ case <= 0) {} // Error: nullable extension <=
  if (string case < 0) {} // Error: missing <
  if (string case <= 0) {} // Error: ambiguous <=
  if (invalid case == 0) {} // Error: ambiguous ==
  if (invalid case < 0) {} // invalid <
  if (cls2 case == const Class2()) {} // instance ==
  if (cls2 case == 0) {} // Error: invalid instance == argument
  if (cls2 case != const Class2()) {} // instance == negated
  if (cls2 case != 0) {} // Error: invalid instance == argument negated
  if (cls2 case < const Class2()) {} // instance <
  if (cls2 case < 0) {} // Error: invalid instance < argument
  if (cls2_ case == null) {} // instance ==
  /* // TODO(johnniwinther): Enable this when extension type declarations are
         supported.
  if (extensionType case < 0) {} // extension type <
  if (extensionType case < '0') {} // Error: invalid extension type < argument
  if (extensionType case > 0) {} // Error: invalid extension type >
  */
}
