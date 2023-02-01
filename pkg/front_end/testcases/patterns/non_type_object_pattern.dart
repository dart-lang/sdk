// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'non_type_object_pattern.dart' as prefix;

var NonType = 0;

extension Extension on int {}

testUnresolved(o) {
  var Unresolved(:int field) = o;
  final Unresolved(:o) = o;

  if (o case Unresolved(:var field)) {}

  switch (o) {
    case Unresolved(:var field):
    break;
  }
  o = switch (o) {
    Unresolved(:var field) => "matched",
    _ => ""
  };
}

testNonType(o) {
  var NonType(:int field) = o;
  final NonType(:o) = o;

  if (o case NonType(:var field)) {}

  switch (o) {
    case NonType(:var field):
    break;
  }
  o = switch (o) {
    NonType(:var field) => "matched",
    _ => ""
  };
}

testExtension(o) {
  var Extension(:int field) = o;
  final Extension(:o) = o;

  if (o case Extension(:var field)) {}

  switch (o) {
    case Extension(:var field):
    break;
  }
  o = switch (o) {
    Extension(:var field) => "matched",
    _ => ""
  };
}

testPrefixedUnresolved(o) {
  var prefix.Unresolved(:int field) = o;
  final prefix.Unresolved(:o) = o;

  if (o case prefix.Unresolved(:var field)) {}

  switch (o) {
    case prefix.Unresolved(:var field):
    break;
  }
  o = switch (o) {
   prefix.Unresolved(:var field) => "matched",
    _ => ""
  };
}

testPrefixedNonType(o) {
  var prefix.NonType(:int field) = o;
  final prefix.NonType(:o) = o;

  if (o case prefix.NonType(:var field)) {}

  switch (o) {
    case prefix.NonType(:var field):
    break;
  }
  o = switch (o) {
    prefix.NonType(:var field) => "matched",
    _ => ""
  };
}

testPrefixedExtension(o) {
  var prefix.Extension(:int field) = o;
  final prefix.Extension(:o) = o;

  if (o case prefix.Extension(:var field)) {}

  switch (o) {
    case prefix.Extension(:var field):
    break;
  }
  o = switch (o) {
    prefix.Extension(:var field) => "matched",
    _ => ""
  };
}

testUnresolvedPrefix(o) {
  var unresolved.Type(:int field) = o;
  final unresolved.Type(:o) = o;

  if (o case unresolved.Type(:var field)) {}

  switch (o) {
    case unresolved.Type(:var field):
    break;
  }
  o = switch (o) {
    unresolved.Type(:var field) => "matched",
    _ => ""
  };
}

testMemberAccess(o) {
  var NonType.hashCode(:int field) = o;
  final NonType.hashCode(:o) = o;

  if (o case NonType.hashCode(:var field)) {}

  switch (o) {
    case NonType.hashCode(:var field):
    break;
  }
  o = switch (o) {
    NonType.hashCode(:var field) => "matched",
    _ => ""
  };
}
