// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.prefix_builder;

import 'builder.dart' show Builder, LibraryBuilder, MemberBuilder;

import '../messages.dart' show warning;

import 'package:kernel/ast.dart' show Member;

import '../dill/dill_member_builder.dart' show DillMemberBuilder;

import '../errors.dart' show internalError;

class PrefixBuilder extends Builder {
  final String name;

  final Map<String, Builder> exports;

  final LibraryBuilder parent;

  PrefixBuilder(this.name, this.exports, LibraryBuilder parent, int charOffset)
      : parent = parent,
        super(parent, charOffset, parent.fileUri);

  Member findTopLevelMember(String name) {
    // TODO(ahe): Move this to KernelPrefixBuilder.
    Builder builder = exports[name];
    if (builder == null) {
      warning(
          parent.fileUri, -1, "'${this.name}' has no member named '$name'.");
    }
    if (builder is DillMemberBuilder) {
      return builder.member.isInstanceMember
          ? internalError("Unexpected instance member in export scope")
          : builder.member;
    } else if (builder is MemberBuilder) {
      return builder.target;
    } else {
      return null;
    }
  }

  @override
  String get fullNameForErrors => name;
}
