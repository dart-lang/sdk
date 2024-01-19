// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/canonical_tables.h"

#include "vm/regexp.h"

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
    const auto& func_a = Function::Cast(a);
    const auto& func_b = Function::Cast(b);
    if (func_a.IsNonImplicitClosureFunction() ||
        func_b.IsNonImplicitClosureFunction()) {
      return a.ptr() == b.ptr();
    }
    const String& name_a = String::Handle(func_a.name());
    const String& name_b = String::Handle(func_b.name());
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
    if (TypeParameter::Cast(a).index() != TypeParameter::Cast(b).index() ||
        TypeParameter::Cast(a).base() != TypeParameter::Cast(b).base()) {
      return false;
    }
    return TypeParameter::Cast(a).parameterized_class_id() ==
           TypeParameter::Cast(b).parameterized_class_id();
  }
  return a.ptr() == b.ptr();
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

CanonicalInstanceKey::CanonicalInstanceKey(const Instance& key) : key_(key) {
  ASSERT(!(key.IsString() || key.IsAbstractType()));
}

bool CanonicalInstanceKey::Matches(const Instance& obj) const {
  ASSERT(!(obj.IsString() || obj.IsAbstractType()));
  if (key_.CanonicalizeEquals(obj)) {
    ASSERT(obj.IsCanonical());
    return true;
  }
  return false;
}

uword CanonicalInstanceKey::Hash() const {
  return key_.CanonicalizeHash();
}

bool CanonicalInstanceTraits::IsMatch(const Object& a, const Object& b) {
  ASSERT(!(a.IsString() || a.IsAbstractType()));
  ASSERT(!(b.IsString() || b.IsAbstractType()));
  return a.ptr() == b.ptr();
}

bool CanonicalInstanceTraits::IsMatch(const CanonicalInstanceKey& a,
                                      const Object& b) {
  return a.Matches(Instance::Cast(b));
}

uword CanonicalInstanceTraits::Hash(const Object& key) {
  ASSERT(!(key.IsString() || key.IsAbstractType()));
  ASSERT(key.IsInstance());
  return Instance::Cast(key).CanonicalizeHash();
}

uword CanonicalInstanceTraits::Hash(const CanonicalInstanceKey& key) {
  return key.Hash();
}

ObjectPtr CanonicalInstanceTraits::NewKey(const CanonicalInstanceKey& obj) {
  return obj.key_.ptr();
}

ObjectPtr CanonicalRegExpTraits::NewKey(const RegExpKey& key) {
  return RegExpEngine::CreateRegExp(Thread::Current(), key.pattern_,
                                    key.flags_);
}

}  // namespace dart
