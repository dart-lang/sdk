// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.modifier_builder;

import '../modifier.dart'
    show
        abstractMask,
        constMask,
        covariantMask,
        externalMask,
        finalMask,
        namedMixinApplicationMask,
        staticMask;

import '../util/relativize.dart' show relativizeUri;

import 'builder.dart' show Builder;

String relativizeUriWithParent(Uri uri, Builder parent) {
  // TODO(ahe): We should be able to get rid of this method if relativeFileUri
  // is removed.
  if (parent is ModifierBuilder && uri == parent.fileUri) {
    return parent.relativeFileUri;
  } else {
    uri ??= parent?.fileUri;
    return uri == null ? null : relativizeUri(uri);
  }
}

abstract class ModifierBuilder extends Builder {
  final int charOffset;

  // TODO(ahe): This can be shared with the underlying kernel node if we switch
  // to using URIs everywhere.
  final Uri fileUri;

  final String relativeFileUri;

  ModifierBuilder(Builder parent, this.charOffset, [Uri fileUri])
      : fileUri = fileUri ?? parent?.fileUri,
        relativeFileUri = relativizeUriWithParent(fileUri, parent),
        super(parent, charOffset, fileUri ?? parent?.fileUri);

  int get modifiers;

  bool get isAbstract => (modifiers & abstractMask) != 0;

  bool get isConst => (modifiers & constMask) != 0;

  bool get isCovariant => (modifiers & covariantMask) != 0;

  bool get isExternal => (modifiers & externalMask) != 0;

  bool get isFinal => (modifiers & finalMask) != 0;

  bool get isStatic => (modifiers & staticMask) != 0;

  bool get isNamedMixinApplication {
    return (modifiers & namedMixinApplicationMask) != 0;
  }

  bool get isClassMember => false;

  String get name;

  bool get isNative => false;

  String get debugName;

  StringBuffer printOn(StringBuffer buffer) {
    return buffer..write(name ?? fullNameForErrors);
  }

  String toString() => "$debugName(${printOn(new StringBuffer())})";
}
