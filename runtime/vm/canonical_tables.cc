// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/canonical_tables.h"

namespace dart {

bool MetadataMapTraits::IsMatch(const Object& a, const Object& b) {
  // In the absence of hot reload, this can just be an identity check. With
  // reload, some old program elements may be retained by the stack, closures
  // or mirrors, which are absent from the new version of the library's
  // metadata table. This name-based matching fuzzy maps the old program
  // elements to corresponding new elements, preserving the behavior of the old
  // metaname+fields scheme.
  if (a.IsLibrary() && b.IsLibrary()) {
    const String& url_a = String::Handle(Library::Cast(a).url());
    const String& url_b = String::Handle(Library::Cast(b).url());
    return url_a.Equals(url_b);
  } else if (a.IsClass() && b.IsClass()) {
    const String& name_a = String::Handle(Class::Cast(a).Name());
    const String& name_b = String::Handle(Class::Cast(b).Name());
    return name_a.Equals(name_b);
  } else if (a.IsFunction() && b.IsFunction()) {
    const String& name_a = String::Handle(Function::Cast(a).name());
    const String& name_b = String::Handle(Function::Cast(b).name());
    if (!name_a.Equals(name_b)) {
      return false;
    }
    const Object& owner_a = Object::Handle(Function::Cast(a).Owner());
    const Object& owner_b = Object::Handle(Function::Cast(b).Owner());
    return IsMatch(owner_a, owner_b);
  } else if (a.IsField() && b.IsField()) {
    const String& name_a = String::Handle(Field::Cast(a).name());
    const String& name_b = String::Handle(Field::Cast(b).name());
    if (!name_a.Equals(name_b)) {
      return false;
    }
    const Object& owner_a = Object::Handle(Field::Cast(a).Owner());
    const Object& owner_b = Object::Handle(Field::Cast(b).Owner());
    return IsMatch(owner_a, owner_b);
  } else if (a.IsTypeParameter() && b.IsTypeParameter()) {
    const String& name_a = String::Handle(TypeParameter::Cast(a).name());
    const String& name_b = String::Handle(TypeParameter::Cast(b).name());
    if (!name_a.Equals(name_b)) {
      return false;
    }
    const Object& owner_a = Object::Handle(TypeParameter::Cast(a).Owner());
    const Object& owner_b = Object::Handle(TypeParameter::Cast(b).Owner());
    return IsMatch(owner_a, owner_b);
  }
  return a.raw() == b.raw();
}

uword MetadataMapTraits::Hash(const Object& key) {
  if (key.IsLibrary()) {
    return String::Hash(Library::Cast(key).url());
  } else if (key.IsClass()) {
    return String::Hash(Class::Cast(key).Name());
  } else if (key.IsFunction()) {
    return CombineHashes(String::Hash(Function::Cast(key).name()),
                         Hash(Object::Handle(Function::Cast(key).Owner())));
  } else if (key.IsField()) {
    return CombineHashes(String::Hash(Field::Cast(key).name()),
                         Hash(Object::Handle(Field::Cast(key).Owner())));
  } else if (key.IsTypeParameter()) {
    return TypeParameter::Cast(key).Hash();
  } else if (key.IsNamespace()) {
    return Hash(Library::Handle(Namespace::Cast(key).target()));
  }
  UNREACHABLE();
}

}  // namespace dart
