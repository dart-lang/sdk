// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class FieldFragment implements Fragment {
  @override
  final String name;

  final Uri fileUri;
  final int nameOffset;
  final int endOffset;
  Token? _initializerToken;
  Token? _constInitializerToken;
  final List<MetadataBuilder>? metadata;
  final TypeBuilder type;
  final bool isTopLevel;
  final Modifiers modifiers;
  // TODO(johnniwinther): Create separate fragment for primary constructor
  // fields.
  final bool isPrimaryConstructorField;

  SourceFieldBuilder? _builder;

  FieldFragment(
      {required this.name,
      required this.fileUri,
      required this.nameOffset,
      required this.endOffset,
      required Token? initializerToken,
      required Token? constInitializerToken,
      required this.metadata,
      required this.type,
      required this.isTopLevel,
      required this.modifiers,
      required this.isPrimaryConstructorField})
      : _initializerToken = initializerToken,
        _constInitializerToken = constInitializerToken;

  bool get hasSetter {
    if (modifiers.isConst) {
      return false;
    } else if (modifiers.isFinal) {
      if (modifiers.isLate) {
        return !modifiers.hasInitializer;
      } else {
        return false;
      }
    } else {
      return true;
    }
  }

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
  String toString() => '$runtimeType($name,$fileUri,$nameOffset)';
}
