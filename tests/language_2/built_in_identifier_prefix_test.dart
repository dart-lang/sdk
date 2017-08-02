// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that built-in identifiers can be used as library prefixes.

// From The Dart Programming Language Specification, section 11.30
// "Identifier Reference":
//
// "A built-in identifier is one of the identifiers produced by the
// production BUILT IN IDENTIFIER. It is a compile-time error if a
// built-in identifier is used as the declared name of a class, type
// parameter or type alias. It is a compile-time error to use a
// built-in identifier other than dynamic as a type annotation."
//
// Observation: it is not illegal to use a built-in identifier as a library
// prefix.
//
// Observation: it is not legal to use a built-in identifier as a type
// annotation. A type annotation is not fully defined in the
// specification, so we assume this means that the grammar production
// "type" cannot match a built-in identifier. Unfortunately, this
// doesn't prevent us from using built-in identifiers *in* type
// annotations. For example, "final abstract foo;" is illegal as
// "abstract" is used as a type annotation. However, "final
// abstract<dynamic> foo;" is not illegal because "abstract" is used
// as a typeName.

import "package:expect/expect.dart";
import 'built_in_identifier_prefix_library_abstract.dart' as abstract;
import 'built_in_identifier_prefix_library_as.dart' as as;
import 'built_in_identifier_prefix_library_dynamic.dart' as dynamic;
import 'built_in_identifier_prefix_library_export.dart' as export;
import 'built_in_identifier_prefix_library_external.dart' as external;
import 'built_in_identifier_prefix_library_factory.dart' as factory;
import 'built_in_identifier_prefix_library_get.dart' as get;
import 'built_in_identifier_prefix_library_implements.dart' as implements;
import 'built_in_identifier_prefix_library_import.dart' as import;
import 'built_in_identifier_prefix_library_library.dart' as library;
import 'built_in_identifier_prefix_library_operator.dart' as operator;
import 'built_in_identifier_prefix_library_part.dart' as part;
import 'built_in_identifier_prefix_library_set.dart' as set;
import 'built_in_identifier_prefix_library_static.dart' as static;
import 'built_in_identifier_prefix_library_typedef.dart' as typedef;

abstract.A _abstract = new abstract.A();
as.A _as = new as.A();
dynamic.A _dynamic = new dynamic.A();
export.A _export = new export.A();
external.A _external = new external.A();
factory.A _factory = new factory.A();
get.A _get = new get.A();
implements.A _implements = new implements.A();
import.A _import = new import.A();
library.A _library = new library.A();
operator.A _operator = new operator.A();
part.A _part = new part.A();
set.A _set = new set.A();
static.A _static = new static.A();
typedef.A _typedef = new typedef.A();

abstract<dynamic> generic_abstract = new abstract.A();
as<dynamic> generic_as = new as.A();
dynamic<dynamic> generic_dynamic = new dynamic.A();
export<dynamic> generic_export = new export.A();
external<dynamic> generic_external = new external.A();
factory<dynamic> generic_factory = new factory.A();
get<dynamic> generic_get = new get.A();
implements<dynamic> generic_implements = new implements.A();
import<dynamic> generic_import = new import.A();
library<dynamic> generic_library = new library.A();
operator<dynamic> generic_operator = new operator.A();
part<dynamic> generic_part = new part.A();
set<dynamic> generic_set = new set.A();
static<dynamic> generic_static = new static.A();
typedef<dynamic> generic_typedef = new typedef.A();

abstract.B<dynamic> dynamic_B_abstract = new abstract.B();
as.B<dynamic> dynamic_B_as = new as.B();
dynamic.B<dynamic> dynamic_B_dynamic = new dynamic.B();
export.B<dynamic> dynamic_B_export = new export.B();
external.B<dynamic> dynamic_B_external = new external.B();
factory.B<dynamic> dynamic_B_factory = new factory.B();
get.B<dynamic> dynamic_B_get = new get.B();
implements.B<dynamic> dynamic_B_implements = new implements.B();
import.B<dynamic> dynamic_B_import = new import.B();
library.B<dynamic> dynamic_B_library = new library.B();
operator.B<dynamic> dynamic_B_operator = new operator.B();
part.B<dynamic> dynamic_B_part = new part.B();
set.B<dynamic> dynamic_B_set = new set.B();
static.B<dynamic> dynamic_B_static = new static.B();
typedef.B<dynamic> dynamic_B_typedef = new typedef.B();

abstract.B<abstract<dynamic>> parameterized_B_abstract = new abstract.B();
as.B<as<dynamic>> parameterized_B_as = new as.B();
dynamic.B<dynamic<dynamic>> parameterized_B_dynamic = new dynamic.B();
export.B<export<dynamic>> parameterized_B_export = new export.B();
external.B<external<dynamic>> parameterized_B_external = new external.B();
factory.B<factory<dynamic>> parameterized_B_factory = new factory.B();
get.B<get<dynamic>> parameterized_B_get = new get.B();
implements.B<implements<dynamic>> parameterized_B_implements =
  new implements.B();
import.B<import<dynamic>> parameterized_B_import = new import.B();
library.B<library<dynamic>> parameterized_B_library = new library.B();
operator.B<operator<dynamic>> parameterized_B_operator = new operator.B();
part.B<part<dynamic>> parameterized_B_part = new part.B();
set.B<set<dynamic>> parameterized_B_set = new set.B();
static.B<static<dynamic>> parameterized_B_static = new static.B();
typedef.B<typedef<dynamic>> parameterized_B_typedef = new typedef.B();

class UseA {
  abstract.A abstract = new abstract.A();
  as.A as = new as.A();
  dynamic.A dynamic = new dynamic.A();
  export.A export = new export.A();
  external.A external = new external.A();
  factory.A factory = new factory.A();
  get.A get = new get.A();
  implements.A implements = new implements.A();
  import.A import = new import.A();
  library.A library = new library.A();
  operator.A operator = new operator.A();
  part.A part = new part.A();
  set.A set = new set.A();
  static.A static = new static.A();
  typedef.A typedef = new typedef.A();
}

main() {
  bool assertionsEnabled = false;
  assert(assertionsEnabled = true);

  Expect.isTrue(_abstract is abstract.A);
  Expect.isTrue(_as is as.A);
  Expect.isTrue(_dynamic is dynamic.A);
  Expect.isTrue(_export is export.A);
  Expect.isTrue(_external is external.A);
  Expect.isTrue(_factory is factory.A);
  Expect.isTrue(_get is get.A);
  Expect.isTrue(_implements is implements.A);
  Expect.isTrue(_import is import.A);
  Expect.isTrue(_library is library.A);
  Expect.isTrue(_operator is operator.A);
  Expect.isTrue(_part is part.A);
  Expect.isTrue(_set is set.A);
  Expect.isTrue(_static is static.A);
  Expect.isTrue(_typedef is typedef.A);

  Expect.isTrue(dynamic_B_abstract is abstract.B);
  Expect.isTrue(dynamic_B_as is as.B);
  Expect.isTrue(dynamic_B_dynamic is dynamic.B);
  Expect.isTrue(dynamic_B_export is export.B);
  Expect.isTrue(dynamic_B_external is external.B);
  Expect.isTrue(dynamic_B_factory is factory.B);
  Expect.isTrue(dynamic_B_get is get.B);
  Expect.isTrue(dynamic_B_implements is implements.B);
  Expect.isTrue(dynamic_B_import is import.B);
  Expect.isTrue(dynamic_B_library is library.B);
  Expect.isTrue(dynamic_B_operator is operator.B);
  Expect.isTrue(dynamic_B_part is part.B);
  Expect.isTrue(dynamic_B_set is set.B);
  Expect.isTrue(dynamic_B_static is static.B);
  Expect.isTrue(dynamic_B_typedef is typedef.B);

  var x = new UseA();
  Expect.isTrue(x.abstract is abstract.A);
  Expect.isTrue(x.as is as.A);
  Expect.isTrue(x.dynamic is dynamic.A);
  Expect.isTrue(x.export is export.A);
  Expect.isTrue(x.external is external.A);
  Expect.isTrue(x.factory is factory.A);
  Expect.isTrue(x.get is get.A);
  Expect.isTrue(x.implements is implements.A);
  Expect.isTrue(x.import is import.A);
  Expect.isTrue(x.library is library.A);
  Expect.isTrue(x.operator is operator.A);
  Expect.isTrue(x.part is part.A);
  Expect.isTrue(x.set is set.A);
  Expect.isTrue(x.static is static.A);
  Expect.isTrue(x.typedef is typedef.A);

  // Most of the following variables have malformed type annotations.
  if (assertionsEnabled) return;

  Expect.isTrue(generic_abstract is abstract.A);
  Expect.isTrue(generic_as is as.A);
  Expect.isTrue(generic_dynamic is dynamic.A);
  Expect.isTrue(generic_export is export.A);
  Expect.isTrue(generic_external is external.A);
  Expect.isTrue(generic_factory is factory.A);
  Expect.isTrue(generic_get is get.A);
  Expect.isTrue(generic_implements is implements.A);
  Expect.isTrue(generic_import is import.A);
  Expect.isTrue(generic_library is library.A);
  Expect.isTrue(generic_operator is operator.A);
  Expect.isTrue(generic_part is part.A);
  Expect.isTrue(generic_set is set.A);
  Expect.isTrue(generic_static is static.A);
  Expect.isTrue(generic_typedef is typedef.A);

  Expect.isTrue(parameterized_B_abstract is abstract.B);
  Expect.isTrue(parameterized_B_as is as.B);
  Expect.isTrue(parameterized_B_dynamic is dynamic.B);
  Expect.isTrue(parameterized_B_export is export.B);
  Expect.isTrue(parameterized_B_external is external.B);
  Expect.isTrue(parameterized_B_factory is factory.B);
  Expect.isTrue(parameterized_B_get is get.B);
  Expect.isTrue(parameterized_B_implements is implements.B);
  Expect.isTrue(parameterized_B_import is import.B);
  Expect.isTrue(parameterized_B_library is library.B);
  Expect.isTrue(parameterized_B_operator is operator.B);
  Expect.isTrue(parameterized_B_part is part.B);
  Expect.isTrue(parameterized_B_set is set.B);
  Expect.isTrue(parameterized_B_static is static.B);
  Expect.isTrue(parameterized_B_typedef is typedef.B);
}
