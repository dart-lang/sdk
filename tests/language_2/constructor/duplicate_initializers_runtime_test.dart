// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that initializers are not duplicated

 class Class {
   Class(var v) : field_ = v
   // Test against duplicate final field initialization in initializing list.

   ;
   Class.field(this.field_)
   // Test against duplicate final field initialization between initializing
   // formals and initializer list.

   ;
   // Test against duplicate final field initialization in initializing formals.
   Class.two_fields(this.field_

       );
   final field_;
 }

 main() {
   new Class(42);
   new Class.field(42);
   new Class.two_fields(42

       );
 }
