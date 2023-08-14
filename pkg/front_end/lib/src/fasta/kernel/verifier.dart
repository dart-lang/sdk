// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.verifier;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

import 'package:kernel/ast.dart';
import 'package:kernel/target/targets.dart';

import 'package:kernel/type_environment.dart' show TypeEnvironment;

import 'package:kernel/verifier.dart';

import '../compiler_context.dart' show CompilerContext;

import '../fasta_codes.dart'
    show
        LocatedMessage,
        Message,
        messageVerificationErrorOriginContext,
        noLength,
        templateInternalProblemVerificationError;

List<LocatedMessage> verifyComponent(
    Target target, VerificationStage stage, Component component,
    {bool skipPlatform = false}) {
  FastaVerificationErrorListener listener =
      new FastaVerificationErrorListener();
  VerifyingVisitor verifier = new VerifyingVisitor(target, stage,
      skipPlatform: skipPlatform, listener: listener);
  component.accept(verifier);
  return listener.errors;
}

class FastaVerificationErrorListener implements VerificationErrorListener {
  List<LocatedMessage> errors = [];

  @override
  void reportError(String details,
      {required TreeNode? node,
      required Uri? problemUri,
      required int? problemOffset,
      required TreeNode? context,
      required TreeNode? origin}) {
    Message message =
        templateInternalProblemVerificationError.withArguments(details);
    LocatedMessage locatedMessage = problemUri != null
        ? message.withLocation(
            problemUri, problemOffset ?? TreeNode.noOffset, noLength)
        : message.withoutLocation();
    List<LocatedMessage>? contextMessages;
    if (origin != null) {
      contextMessages = [
        messageVerificationErrorOriginContext.withLocation(
            origin.location!.file, origin.fileOffset, noLength)
      ];
    }
    CompilerContext.current
        .report(locatedMessage, Severity.error, context: contextMessages);
    errors.add(locatedMessage);
  }
}

void verifyGetStaticType(TypeEnvironment env, Component component,
    {bool skipPlatform = false}) {
  component.accept(new FastaVerifyGetStaticType(env, skipPlatform));
}

class FastaVerifyGetStaticType extends VerifyGetStaticType {
  final bool skipPlatform;

  FastaVerifyGetStaticType(TypeEnvironment env, this.skipPlatform) : super(env);

  @override
  void visitLibrary(Library node) {
    // 'dart:test' is used in the unit tests and isn't an actual part of the
    // platform.
    if (skipPlatform &&
        node.importUri.isScheme('dart') &&
        node.importUri.path != "test") {
      return;
    }

    super.visitLibrary(node);
  }
}
