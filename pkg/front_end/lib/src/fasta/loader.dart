// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.loader;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

import 'package:kernel/ast.dart' show Class, DartType, ExtensionTypeDeclaration;

import 'builder/declaration_builders.dart';
import 'builder/library_builder.dart';
import 'builder/type_builder.dart';

import 'messages.dart' show FormattedMessage, LocatedMessage, Message;

import 'target_implementation.dart' show TargetImplementation;

const String untranslatableUriScheme = "org-dartlang-untranslatable-uri";

abstract class Loader {
  TargetImplementation get target;

  LibraryBuilder? lookupLibraryBuilder(Uri importUri);

  /// Register [message] as a problem with a severity determined by the
  /// intrinsic severity of the message.
  FormattedMessage? addProblem(
      Message message, int charOffset, int length, Uri? fileUri,
      {bool wasHandled = false,
      List<LocatedMessage>? context,
      Severity? severity,
      bool problemOnLibrary = false,
      List<Uri>? involvedFiles});

  ClassBuilder computeClassBuilderFromTargetClass(Class cls);

  ExtensionTypeDeclarationBuilder
      computeExtensionTypeBuilderFromTargetExtensionType(
          ExtensionTypeDeclaration extensionType);

  TypeBuilder computeTypeBuilder(DartType type);

  LibraryBuilder get coreLibrary;
}
