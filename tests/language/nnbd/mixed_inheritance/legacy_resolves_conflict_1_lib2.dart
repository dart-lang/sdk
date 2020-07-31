// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Import a legacy library which defines legacy classes each of which brings
// together conflicting null-safe superinterfaces (e.g. `A<int>` and `A<int?>)
// and/or brings together members with the same name whose member signatures
// conflict on nullability.

// Each class defined here overrides all of the members from a legacy class
// using either nullable or non-nullable types. This test validates that there
// are no errors triggered by this override: that is, that neither the presence
// of indirect conflicting interfaces, nor of multiple conflicting member
// signatures causes an error.

import 'legacy_resolves_conflict_1_legacy_lib.dart';

// Naming conventions: Class `De#` extends `C#`, where `#` stands for a number
// in 0..63, and declares members whose member signatures use non-nullable
// types. Class `De#q` extends `C#`, and declares members whose member
// signatures use nullable types (`q` refers to the question marks). Class
// `Di#` implements `C#`, is abstract, and does not declare any members.

class De0 extends C0 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De0q extends C0 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di0 implements C0 {}

class De1 extends C1 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De1q extends C1 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di1 implements C1 {}

class De2 extends C2 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De2q extends C2 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di2 implements C2 {}

class De3 extends C3 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De3q extends C3 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di3 implements C3 {}

class De4 extends C4 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De4q extends C4 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di4 implements C4 {}

class De5 extends C5 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De5q extends C5 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di5 implements C5 {}

class De6 extends C6 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De6q extends C6 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di6 implements C6 {}

class De7 extends C7 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De7q extends C7 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di7 implements C7 {}

class De8 extends C8 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De8q extends C8 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di8 implements C8 {}

class De9 extends C9 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De9q extends C9 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di9 implements C9 {}

class De10 extends C10 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De10q extends C10 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di10 implements C10 {}

class De11 extends C11 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De11q extends C11 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di11 implements C11 {}

class De12 extends C12 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De12q extends C12 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di12 implements C12 {}

class De13 extends C13 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De13q extends C13 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di13 implements C13 {}

class De14 extends C14 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De14q extends C14 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di14 implements C14 {}

class De15 extends C15 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De15q extends C15 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di15 implements C15 {}

class De16 extends C16 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De16q extends C16 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di16 implements C16 {}

class De17 extends C17 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De17q extends C17 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di17 implements C17 {}

class De18 extends C18 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De18q extends C18 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di18 implements C18 {}

class De19 extends C19 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De19q extends C19 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di19 implements C19 {}

class De20 extends C20 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De20q extends C20 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di20 implements C20 {}

class De21 extends C21 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De21q extends C21 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di21 implements C21 {}

class De22 extends C22 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De22q extends C22 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di22 implements C22 {}

class De23 extends C23 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De23q extends C23 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di23 implements C23 {}

class De24 extends C24 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De24q extends C24 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di24 implements C24 {}

class De25 extends C25 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De25q extends C25 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di25 implements C25 {}

class De26 extends C26 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De26q extends C26 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di26 implements C26 {}

class De27 extends C27 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De27q extends C27 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di27 implements C27 {}

class De28 extends C28 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De28q extends C28 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di28 implements C28 {}

class De29 extends C29 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De29q extends C29 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di29 implements C29 {}

class De30 extends C30 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De30q extends C30 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di30 implements C30 {}

class De31 extends C31 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De31q extends C31 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di31 implements C31 {}

class De32 extends C32 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De32q extends C32 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di32 implements C32 {}

class De33 extends C33 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De33q extends C33 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di33 implements C33 {}

class De34 extends C34 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De34q extends C34 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di34 implements C34 {}

class De35 extends C35 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De35q extends C35 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di35 implements C35 {}

class De36 extends C36 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De36q extends C36 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di36 implements C36 {}

class De37 extends C37 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De37q extends C37 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di37 implements C37 {}

class De38 extends C38 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De38q extends C38 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di38 implements C38 {}

class De39 extends C39 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De39q extends C39 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di39 implements C39 {}

class De40 extends C40 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De40q extends C40 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di40 implements C40 {}

class De41 extends C41 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De41q extends C41 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di41 implements C41 {}

class De42 extends C42 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De42q extends C42 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di42 implements C42 {}

class De43 extends C43 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De43q extends C43 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di43 implements C43 {}

class De44 extends C44 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De44q extends C44 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di44 implements C44 {}

class De45 extends C45 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De45q extends C45 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di45 implements C45 {}

class De46 extends C46 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De46q extends C46 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di46 implements C46 {}

class De47 extends C47 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De47q extends C47 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di47 implements C47 {}

class De48 extends C48 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De48q extends C48 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di48 implements C48 {}

class De49 extends C49 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De49q extends C49 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di49 implements C49 {}

class De50 extends C50 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De50q extends C50 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di50 implements C50 {}

class De51 extends C51 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De51q extends C51 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di51 implements C51 {}

class De52 extends C52 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De52q extends C52 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di52 implements C52 {}

class De53 extends C53 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De53q extends C53 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di53 implements C53 {}

class De54 extends C54 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De54q extends C54 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di54 implements C54 {}

class De55 extends C55 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De55q extends C55 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di55 implements C55 {}

class De56 extends C56 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De56q extends C56 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di56 implements C56 {}

class De57 extends C57 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De57q extends C57 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di57 implements C57 {}

class De58 extends C58 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De58q extends C58 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di58 implements C58 {}

class De59 extends C59 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De59q extends C59 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di59 implements C59 {}

class De60 extends C60 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De60q extends C60 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di60 implements C60 {}

class De61 extends C61 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De61q extends C61 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di61 implements C61 {}

class De62 extends C62 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De62q extends C62 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di62 implements C62 {}

class De63 extends C63 {
  List<int> get a => [];
  set a(List<int> _) {}
  int m(int x) => x;
}

class De63q extends C63 {
  List<int?> get a => [];
  set a(List<int?> _) {}
  int? m(int? x) => x;
}

abstract class Di63 implements C63 {}
