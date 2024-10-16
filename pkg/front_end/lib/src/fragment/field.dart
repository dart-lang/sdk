// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class FieldFragment implements Fragment {
  final String name;
  final Uri fileUri;
  final int charOffset;
  final int charEndOffset;
  Token? _initializerToken;
  Token? _constInitializerToken;
  final List<MetadataBuilder>? metadata;
  final TypeBuilder type;
  final bool isTopLevel;
  final Modifiers modifiers;

  SourceFieldBuilder? _builder;

  FieldFragment(
      {required this.name,
      required this.fileUri,
      required this.charOffset,
      required this.charEndOffset,
      required Token? initializerToken,
      required Token? constInitializerToken,
      required this.metadata,
      required this.type,
      required this.isTopLevel,
      required this.modifiers})
      : _initializerToken = initializerToken,
        _constInitializerToken = constInitializerToken;

  Token? get initializerToken {
    Token? result = _initializerToken;
    // Ensure that we don't hold onto the token.
    _initializerToken = null;
    return result;
  }

  Token? get constInitializerToken {
    Token? result = _constInitializerToken;
    // Ensure that we don't hold onto the token.
    _constInitializerToken = null;
    return result;
  }

  @override
  SourceFieldBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceFieldBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$charOffset)';
}
