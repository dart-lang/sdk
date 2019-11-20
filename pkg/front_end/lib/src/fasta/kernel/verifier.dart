// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.verifier;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

import 'package:kernel/ast.dart'
    show
        AsExpression,
        BottomType,
        Class,
        Component,
        DartType,
        DynamicType,
        ExpressionStatement,
        Field,
        FunctionType,
        InterfaceType,
        InvalidType,
        Library,
        Member,
        NeverType,
        Nullability,
        Procedure,
        StaticInvocation,
        SuperMethodInvocation,
        SuperPropertyGet,
        SuperPropertySet,
        TreeNode,
        TypeParameter,
        VoidType;

import 'package:kernel/transformations/flags.dart' show TransformerFlag;

import 'package:kernel/verifier.dart' show VerifyingVisitor;

import '../compiler_context.dart' show CompilerContext;

import '../fasta_codes.dart'
    show LocatedMessage, noLength, templateInternalProblemVerificationError;

import '../type_inference/type_schema.dart' show UnknownType;

import 'redirecting_factory_body.dart'
    show RedirectingFactoryBody, getRedirectingFactoryBody;

List<LocatedMessage> verifyComponent(Component component,
    {bool isOutline, bool afterConst, bool skipPlatform: false}) {
  FastaVerifyingVisitor verifier =
      new FastaVerifyingVisitor(isOutline, afterConst, skipPlatform);
  component.accept(verifier);
  return verifier.errors;
}

class FastaVerifyingVisitor extends VerifyingVisitor {
  final List<LocatedMessage> errors = <LocatedMessage>[];
  Library currentLibrary = null;

  Uri fileUri;
  final bool skipPlatform;

  FastaVerifyingVisitor(bool isOutline, bool afterConst, this.skipPlatform)
      : super(isOutline: isOutline, afterConst: afterConst);

  Uri checkLocation(TreeNode node, String name, Uri fileUri) {
    if (name == null || name.contains("#")) {
      // TODO(ahe): Investigate if these checks can be enabled:
      // if (node.fileUri != null && node is! Library) {
      //   problem(node, "A synthetic node shouldn't have a fileUri",
      //       context: node);
      // }
      // if (node.fileOffset != -1) {
      //   problem(node, "A synthetic node shouldn't have a fileOffset",
      //       context: node);
      // }
      return fileUri;
    } else {
      if (fileUri == null) {
        problem(node, "'$name' has no fileUri", context: node);
        return fileUri;
      }
      if (node.fileOffset == -1 && node is! Library) {
        problem(node, "'$name' has no fileOffset", context: node);
      }
      return fileUri;
    }
  }

  void checkSuperInvocation(TreeNode node) {
    Member containingMember = getContainingMember(node);
    if (containingMember == null) {
      problem(node, 'Super call outside of any member');
    } else {
      if (containingMember.transformerFlags & TransformerFlag.superCalls == 0) {
        problem(
            node, 'Super call in a member lacking TransformerFlag.superCalls');
      }
    }
  }

  Member getContainingMember(TreeNode node) {
    while (node != null) {
      if (node is Member) return node;
      node = node.parent;
    }
    return null;
  }

  @override
  problem(TreeNode node, String details, {TreeNode context}) {
    node ??= (context ?? this.context);
    int offset = node?.fileOffset ?? -1;
    Uri file = node?.location?.file ?? fileUri;
    Uri uri = file == null ? null : file;
    LocatedMessage message = templateInternalProblemVerificationError
        .withArguments(details)
        .withLocation(uri, offset, noLength);
    CompilerContext.current.report(message, Severity.error);
    errors.add(message);
  }

  @override
  visitAsExpression(AsExpression node) {
    super.visitAsExpression(node);
    if (node.fileOffset == -1) {
      TreeNode parent = node.parent;
      while (parent != null) {
        if (parent.fileOffset != -1) break;
        parent = parent.parent;
      }
      problem(parent, "No offset for $node", context: node);
    }
  }

  @override
  visitExpressionStatement(ExpressionStatement node) {
    // Bypass verification of the [StaticGet] in [RedirectingFactoryBody] as
    // this is a static get without a getter.
    if (node is! RedirectingFactoryBody) {
      super.visitExpressionStatement(node);
    }
  }

  @override
  visitLibrary(Library node) {
    // Issue(http://dartbug.com/32530)
    if (skipPlatform && node.importUri.scheme == 'dart') {
      return;
    }
    fileUri = checkLocation(node, node.name, node.fileUri);
    currentLibrary = node;
    super.visitLibrary(node);
    currentLibrary = null;
  }

  @override
  visitClass(Class node) {
    fileUri = checkLocation(node, node.name, node.fileUri);
    super.visitClass(node);
  }

  @override
  visitField(Field node) {
    fileUri = checkLocation(node, node.name.name, node.fileUri);
    super.visitField(node);
  }

  @override
  visitProcedure(Procedure node) {
    fileUri = checkLocation(node, node.name.name, node.fileUri);
    super.visitProcedure(node);
  }

  bool isNullType(DartType node) {
    if (node is InterfaceType) {
      Uri importUri = node.classNode.enclosingLibrary.importUri;
      return node.classNode.name == "Null" &&
          importUri.scheme == "dart" &&
          importUri.path == "core";
    }
    return false;
  }

  @override
  defaultDartType(DartType node) {
    if (node is UnknownType) {
      // Note: we can't pass [node] to [problem] because it's not a [TreeNode].
      problem(null, "Unexpected appearance of the unknown type.");
    }
    bool neverLegacy = isNullType(node) ||
        node is DynamicType ||
        node is InvalidType ||
        node is VoidType ||
        node is NeverType ||
        node is BottomType;
    bool expectedLegacy =
        !currentLibrary.isNonNullableByDefault && !neverLegacy;
    if (expectedLegacy && node.nullability != Nullability.legacy) {
      problem(
          null, "Found a non-legacy type '${node}' in an opted-out library.");
    }
    Nullability nodeNullability =
        node is InvalidType ? Nullability.undetermined : node.nullability;
    if (currentLibrary.isNonNullableByDefault &&
        nodeNullability == Nullability.legacy) {
      problem(null, "Found a legacy type '${node}' in an opted-in library.");
    }
    super.defaultDartType(node);
  }

  @override
  visitFunctionType(FunctionType node) {
    if (node.typeParameters.isNotEmpty) {
      for (TypeParameter typeParameter in node.typeParameters) {
        if (typeParameter.parent != null) {
          problem(
              null,
              "Type parameters of function types shouldn't have parents: "
              "$node.");
        }
      }
    }
    super.visitFunctionType(node);
  }

  @override
  visitInterfaceType(InterfaceType node) {
    if (isNullType(node) && node.nullability != Nullability.nullable) {
      problem(null, "Found a not nullable Null type: ${node}");
    }
    super.visitInterfaceType(node);
  }

  @override
  visitSuperMethodInvocation(SuperMethodInvocation node) {
    checkSuperInvocation(node);
    super.visitSuperMethodInvocation(node);
  }

  @override
  visitSuperPropertyGet(SuperPropertyGet node) {
    checkSuperInvocation(node);
    super.visitSuperPropertyGet(node);
  }

  @override
  visitSuperPropertySet(SuperPropertySet node) {
    checkSuperInvocation(node);
    super.visitSuperPropertySet(node);
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    super.visitStaticInvocation(node);
    RedirectingFactoryBody body = getRedirectingFactoryBody(node.target);
    if (body != null) {
      problem(node, "Attempt to invoke redirecting factory.");
    }
  }
}
