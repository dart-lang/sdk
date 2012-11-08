// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CHA_H_
#define VM_CHA_H_

#include "vm/allocation.h"

namespace dart {

class Class;
class Function;
template <typename T> class ZoneGrowableArray;
class String;

class CHA : public AllStatic {
 public:
  // Returns true if the class given by its cid has subclasses.
  static bool HasSubclasses(intptr_t cid);

  // Returns an array containing the cids of the direct and indirect subclasses
  // of the class given by its cid.
  // Must not be called for kInstanceCid.
  static ZoneGrowableArray<intptr_t>* GetSubclassIdsOf(intptr_t cid);

  // Returns an array containing instance functions of the given name and
  // belonging to the classes given by their cids.
  // Cids must not contain kInstanceCid.
  static ZoneGrowableArray<Function*>* GetNamedInstanceFunctionsOf(
      const ZoneGrowableArray<intptr_t>& cids,
      const String& function_name);

  // Returns an array of functions overriding the given function.
  // Must not be called for a function of class Object.
  static ZoneGrowableArray<Function*>* GetOverridesOf(const Function& function);

  // Returns true if any subclass of 'cls' contains the function.
  static bool HasOverride(const Class& cls, const String& function_name);
};

}  // namespace dart

#endif  // VM_CHA_H_
