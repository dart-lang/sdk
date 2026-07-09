// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/severity.dart'
    show CfeSeverity;
import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart';
import 'package:kernel/type_environment.dart' show TypeEnvironment;
import 'package:kernel/verifier.dart';

import '../codes/cfe_codes.dart' show LocatedMessage, Message, noLength;
import '../base/compiler_context.dart' show CompilerContext;

List<LocatedMessage> verifyComponent(
  CompilerContext context,
  VerificationStage stage,
  Component component, {
  bool skipPlatform = false,
  bool Function(Library library)? librarySkipFilter,
}) {
  CfeVerificationErrorListener listener = new CfeVerificationErrorListener(
    context,
  );
  VerifyingVisitor.check(
    context.options.target,
    stage,
    component,
    skipPlatform: skipPlatform,
    librarySkipFilter: librarySkipFilter,
    listener: listener,
  );
  return listener.errors;
}

class CfeVerificationErrorListener implements VerificationErrorListener {
  final CompilerContext compilerContext;
  List<LocatedMessage> errors = [];

  new(this.compilerContext);

  @override
  // Coverage-ignore(suite): Not run.
  void reportError(
    String details, {
    required TreeNode? node,
    required Uri? problemUri,
    required int? problemOffset,
    required TreeNode? context,
    required TreeNode? origin,
  }) {
    Message message = diag.internalProblemVerificationError.withArguments(
      details: details,
    );
    LocatedMessage locatedMessage = problemUri != null
        ? message.withLocation(
            problemUri,
            problemOffset ?? TreeNode.noOffset,
            noLength,
          )
        : message.withoutLocation();
    List<LocatedMessage>? contextMessages;
    if (origin != null) {
      contextMessages = [
        diag.verificationErrorOriginContext.withLocation(
          origin.location!.file,
          origin.fileOffset,
          noLength,
        ),
      ];
    }
    compilerContext.report(
      locatedMessage,
      CfeSeverity.error,
      context: contextMessages,
    );
    errors.add(locatedMessage);
  }
}

List<LocatedMessage> verifyGetStaticType(
  TypeEnvironment env,
  Component component, {
  bool skipPlatform = false,
}) {
  CfeVerifyGetStaticType visitor = new CfeVerifyGetStaticType(
    env,
    skipPlatform,
  );
  component.accept(visitor);
  return [
    for (StaticTypeError error in visitor.errors)
      // Coverage-ignore(suite): Not run.
      diag.internalProblemVerificationError
          .withArguments(details: error.message)
          .withLocation(
            error.context.location!.file,
            error.context.fileOffset,
            noLength,
          ),
  ];
}

class CfeVerifyGetStaticType extends VerifyGetStaticType {
  final bool skipPlatform;

  new(TypeEnvironment env, this.skipPlatform) : super(env);

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
