// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'in_out_in_lib1.dart';
import 'in_out_in_lib2.dart';

// Class doesn't implement `SuperExtra.optionalArgumentsMethod`.
class Class /* error */ extends LegacyClass implements SuperQ {
  test() {
    int i;
    // Valid call to `SuperQ.nullabilityMethod`, returns int?.
    var v1 = nullabilityMethod(null); // ok
    // Valid super call to `LegacyClass.nullabilityMethod`, returns int*.
    i = super.nullabilityMethod(null); // ok
    // Valid call to `SuperExtra.optionalArgumentsMethod`, returns int*.
    i = optionalArgumentsMethod(null, null); // ok
    // Valid super call to `SuperExtra.optionalArgumentsMethod`, returns int*.
    i = super.optionalArgumentsMethod(null); // ok
    // Invalid super call to `SuperExtra.optionalArgumentsMethod`.
    super.optionalArgumentsMethod(null, null); // error
    // Read of `SuperQ.nullabilityGetter`, return int?.
    var v2 = nullabilityGetter; // ok
    // Valid read of `LegacyClass.nullabilityGetter`, return int*.
    i = super.nullabilityGetter; // ok
    // Valid write to `SuperQ.nullabilitySetter`.
    nullabilitySetter = null; // ok
    // Valid write to `LegacyClass.nullabilitySetter`.
    super.nullabilitySetter = null; // ok
  }
}

// ClassQ doesn't implement `SuperExtra.optionalArgumentsMethod`.
class ClassQ /* error */ extends LegacyClassQ implements Super {
  test() {
    int i;
    // Invalid call to `Super.nullabilityMethod`, returns int!.
    nullabilityMethod(null); // error
    // Valid call to `LegacyClassQ.nullabilityMethod`, returns int*.
    i = super.nullabilityMethod(null); // ok
    // Valid call to `SuperExtra.optionalArgumentsMethod`, returns int*.
    i = optionalArgumentsMethod(null, null); // ok
    // Valid super call to `SuperExtra.optionalArgumentsMethod`, returns int*.
    i = super.optionalArgumentsMethod(null); // ok
    // Invalid super call to `SuperExtra.optionalArgumentsMethod`.
    super.optionalArgumentsMethod(null, null); // error
    // Read of `Super.nullabilityGetter`, return int.
    i = nullabilityGetter; // ok
    // Valid read of `LegacyClassQ.nullabilityGetter`, return int*.
    i = super.nullabilityGetter; // ok
    // Invalid write to `Super.nullabilitySetter`.
    nullabilitySetter = null; // error
    // Valid write to `LegacyClassQ.nullabilitySetter`.
    super.nullabilitySetter = null; // ok
  }
}

// ClassMixedIn doesn't implement `SuperExtra.optionalArgumentsMethod`.
class ClassMixedIn /* error */ extends LegacyMixedIn implements SuperQ {
  test() {
    int i;
    // Valid call to `SuperQ.nullabilityMethod`, returns int?.
    var v1 = nullabilityMethod(null); // ok
    // Valid super call to `LegacyMixedIn.nullabilityMethod`, returns int*.
    i = super.nullabilityMethod(null); // ok
    // Valid call to `SuperExtra.optionalArgumentsMethod`, returns int*.
    i = optionalArgumentsMethod(null, null); // ok
    // Valid super call to `SuperExtra.optionalArgumentsMethod`, returns int*.
    i = super.optionalArgumentsMethod(null); // ok
    // Invalid super call to `SuperExtra.optionalArgumentsMethod`.
    super.optionalArgumentsMethod(null, null); // error
    // Read of `SuperQ.nullabilityGetter`, return int?.
    var v2 = nullabilityGetter; // ok
    // Valid read of `LegacyMixedIn.nullabilityGetter`, return int*.
    i = super.nullabilityGetter; // ok
    // Valid write to `SuperQ.nullabilitySetter`.
    nullabilitySetter = null; // ok
    // Valid write to `LegacyMixedIn.nullabilitySetter`.
    super.nullabilitySetter = null; // ok
  }
}

// ClassMixedInQ doesn't implement `SuperExtra.optionalArgumentsMethod`.
class ClassMixedInQ /* error */ extends LegacyMixedInQ implements Super {
  test() {
    int i;
    // Invalid call to `Super.nullabilityMethod`, returns int!.
    nullabilityMethod(null); // error
    // Valid call to `LegacyMixedInQ.nullabilityMethod`, returns int*.
    i = super.nullabilityMethod(null); // ok
    // Valid call to `SuperExtra.optionalArgumentsMethod`, returns int*.
    i = optionalArgumentsMethod(null, null); // ok
    // Valid super call to `SuperExtra.optionalArgumentsMethod`, returns int*.
    i = super.optionalArgumentsMethod(null); // ok
    // Invalid super call to `SuperExtra.optionalArgumentsMethod`.
    super.optionalArgumentsMethod(null, null); // error
    // Read of `Super.nullabilityGetter`, return int.
    i = nullabilityGetter; // ok
    // Valid read of `LegacyMixedInQ.nullabilityGetter`, return int*.
    i = super.nullabilityGetter; // ok
    // Invalid write to `Super.nullabilitySetter`.
    nullabilitySetter = null; // error
    // Valid write to `LegacyMixedInQ.nullabilitySetter`.
    super.nullabilitySetter = null; // ok
  }
}

main() {}
