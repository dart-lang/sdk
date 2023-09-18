// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../elements/entities.dart' show AsyncMarker, MemberEntity, Variance;
import '../universe/record_shape.dart';

/// Returns a textual representation of [node] that include the runtime type and
/// hash code of the node and a one line prefix of the node toString text.
String nodeToDebugString(ir.Node node, [int textLength = 40]) {
  String blockText = node.toString().replaceAll('\n', ' ');
  if (blockText.length > textLength) {
    blockText = blockText.substring(0, textLength - 3) + '...';
  }
  return '(${node.runtimeType}:${node.hashCode})${blockText}';
}

/// Comparator for the canonical order for named parameters.
// TODO(johnniwinther): Remove this when named parameters are sorted in dill.
int namedOrdering(ir.VariableDeclaration a, ir.VariableDeclaration b) {
  return a.name!.compareTo(b.name!);
}

/// Comparator for the declaration order of parameters.
int nativeOrdering(ir.VariableDeclaration a, ir.VariableDeclaration b) {
  return a.fileOffset.compareTo(b.fileOffset);
}

SourceSpan computeSourceSpanFromTreeNode(ir.TreeNode node) {
  // TODO(johnniwinther): Use [ir.Location] directly as a [SourceSpan].
  Uri? uri;
  late int offset;
  for (ir.TreeNode? current = node; current != null; current = current.parent) {
    if (current.fileOffset != ir.TreeNode.noOffset) {
      offset = current.fileOffset;
      // @patch annotations have no location.
      uri = current.location?.file;
      break;
    }
  }
  if (uri != null) {
    return SourceSpan(uri, offset, offset + 1);
  }
  return SourceSpan.unknown();
}

RecordShape recordShapeOfRecordType(ir.RecordType node) {
  return RecordShape(
      node.positional.length,
      node.named.isEmpty
          ? const []
          : node.named.map((n) => n.name).toList(growable: false));
}

/// Computes `recordShapeOfRecordType(node).indexOfFieldName(name)` without
/// creating an intermediate shape.
int indexOfNameInRecordShapeOfRecordType(ir.RecordType node, String name) {
  final nameIndex = node.named.indexWhere((n) => n.name == name);
  if (nameIndex < 0) throw ArgumentError.value(name, 'name');
  final index = node.positional.length + nameIndex;
  assert(index == recordShapeOfRecordType(node).indexOfFieldName(name));
  return index;
}

/// Returns the `AsyncMarker` corresponding to `node.asyncMarker`.
AsyncMarker getAsyncMarker(ir.FunctionNode node) {
  switch (node.asyncMarker) {
    case ir.AsyncMarker.Async:
      return AsyncMarker.ASYNC;
    case ir.AsyncMarker.AsyncStar:
      return AsyncMarker.ASYNC_STAR;
    case ir.AsyncMarker.Sync:
      return AsyncMarker.SYNC;
    case ir.AsyncMarker.SyncStar:
      return AsyncMarker.SYNC_STAR;
    default:
      throw UnsupportedError(
          "Async marker ${node.asyncMarker} is not supported.");
  }
}

/// Returns the `Variance` corresponding to `node.variance`.
Variance convertVariance(ir.TypeParameter node) {
  if (node.isLegacyCovariant) return Variance.legacyCovariant;
  switch (node.variance) {
    case ir.Variance.covariant:
      return Variance.covariant;
    case ir.Variance.contravariant:
      return Variance.contravariant;
    case ir.Variance.invariant:
      return Variance.invariant;
    default:
      throw UnsupportedError("Variance ${node.variance} is not supported.");
  }
}

/// Returns `true` if [node] is a null literal or a null constant.
bool isNullLiteral(ir.Expression node) {
  return node is ir.NullLiteral ||
      (node is ir.ConstantExpression && node.constant is ir.NullConstant);
}

/// Kernel encodes a null-aware expression `a?.b` as
///
///     let final #1 = a in #1 == null ? null : #1.b
///
/// [getNullAwareExpression] recognizes such expressions storing the result in
/// a [NullAwareExpression] object.
///
/// [syntheticVariable] holds the synthesized `#1` variable. [expression] holds
/// the `#1.b` expression. [receiver] returns `a` expression. [parent] returns
/// the parent of the let node, i.e. the parent node of the original null-aware
/// expression. [let] returns the let node created for the encoding.
class NullAwareExpression {
  final ir.Let let;
  final ir.VariableDeclaration syntheticVariable;
  final ir.Expression expression;

  NullAwareExpression(this.let, this.syntheticVariable, this.expression);

  ir.Expression get receiver => syntheticVariable.initializer!;

  ir.TreeNode get parent => let.parent!;

  @override
  String toString() => let.toString();
}

NullAwareExpression? getNullAwareExpression(ir.TreeNode node) {
  if (node is ir.Let) {
    ir.Expression body = node.body;
    if (node.variable.name == null &&
        node.variable.isFinal &&
        body is ir.ConditionalExpression) {
      final condition = body.condition;
      if (condition is ir.EqualsNull) {
        ir.Expression receiver = condition.expression;
        if (receiver is ir.VariableGet && receiver.variable == node.variable) {
          // We have
          //   let #t1 = e0 in #t1 == null ? null : e1
          return NullAwareExpression(node, node.variable, body.otherwise);
        }
      }
    }
  }
  return null;
}

/// Check whether [node] is immediately guarded by a
/// [ir.CheckLibraryIsLoaded], and hence the node is a deferred access.
ir.LibraryDependency? getDeferredImport(ir.TreeNode node) {
  // Note: this code relies on the CFE generating the code as we expect it here.
  // If one day we optimize away redundant CheckLibraryIsLoaded instructions,
  // we'd need to derive this information directly from the CFE (See #35005),
  ir.TreeNode? parent = node.parent;

  // TODO(sigmund): remove when CFE generates the correct tree (#35320). For
  // instance, it currently generates
  //
  //   let _ = check(prefix) in (prefix::field.property)
  //
  // instead of:
  //
  //   (let _ = check(prefix) in prefix::field).property
  if (node is ir.StaticGet || node is ir.ConstantExpression) {
    while (parent is ir.InstanceGet ||
        parent is ir.DynamicGet ||
        parent is ir.InstanceTearOff ||
        parent is ir.FunctionTearOff ||
        parent is ir.InstanceInvocation ||
        parent is ir.InstanceGetterInvocation ||
        parent is ir.DynamicInvocation ||
        parent is ir.FunctionInvocation) {
      parent = parent!.parent;
    }
  }

  if (parent is ir.Let) {
    var initializer = parent.variable.initializer;
    if (initializer is ir.CheckLibraryIsLoaded) {
      return initializer.import;
    }
  }
  return null;
}

class _FreeVariableVisitor implements ir.DartTypeVisitor<bool> {
  const _FreeVariableVisitor();

  bool visit(ir.DartType type) {
    return type.accept(this);
  }

  bool visitList(List<ir.DartType> types) {
    for (ir.DartType type in types) {
      if (visit(type)) return true;
    }
    return false;
  }

  @override
  bool visitTypedefType(ir.TypedefType node) {
    return visitList(node.typeArguments);
  }

  @override
  bool visitTypeParameterType(ir.TypeParameterType node) {
    return true;
  }

  @override
  bool visitIntersectionType(ir.IntersectionType node) {
    return true;
  }

  @override
  bool visitFunctionType(ir.FunctionType node) {
    if (visit(node.returnType)) return true;
    if (visitList(node.positionalParameters)) return true;
    for (ir.NamedType namedType in node.namedParameters) {
      if (visit(namedType.type)) return true;
    }
    return false;
  }

  @override
  bool visitRecordType(ir.RecordType node) {
    if (visitList(node.positional)) return true;
    for (ir.NamedType namedType in node.named) {
      if (visit(namedType.type)) return true;
    }
    return false;
  }

  @override
  bool visitInterfaceType(ir.InterfaceType node) {
    return visitList(node.typeArguments);
  }

  @override
  bool visitExtensionType(ir.ExtensionType node) {
    return visit(node.typeErasure);
  }

  @override
  bool visitFutureOrType(ir.FutureOrType node) {
    return visit(node.typeArgument);
  }

  @override
  bool visitNeverType(ir.NeverType node) => false;

  @override
  bool visitNullType(ir.NullType node) => false;

  @override
  bool visitVoidType(ir.VoidType node) => false;

  @override
  bool visitDynamicType(ir.DynamicType node) => false;

  @override
  bool visitInvalidType(ir.InvalidType node) => false;

  @override
  bool visitAuxiliaryType(ir.AuxiliaryType node) {
    throw UnsupportedError(
        'Unsupported auxiliary type $node (${node.runtimeType}).');
  }
}

/// Returns `true` if [type] contains a type variable.
///
/// All type variables (class type variables, generic method type variables,
/// and function type variables) are considered.
bool containsFreeVariables(ir.DartType type) =>
    type.accept(const _FreeVariableVisitor());

/// Returns true if [importUri] corresponds to dart:html and related libraries.
bool _isWebLibrary(Uri importUri) =>
    importUri.isScheme('dart') &&
        (importUri.path == 'html' ||
            importUri.path == 'svg' ||
            importUri.path == 'indexed_db' ||
            importUri.path == 'web_audio' ||
            importUri.path == 'web_gl' ||
            importUri.path == 'web_sql' ||
            importUri.path == 'html_common') ||
    // Mock web library path for testing.
    importUri.path
        .contains('native_null_assertions/web_library_interfaces.dart');

bool nodeIsInWebLibrary(ir.TreeNode? node) {
  if (node == null) return false;
  if (node is ir.Library) return _isWebLibrary(node.importUri);
  return nodeIsInWebLibrary(node.parent);
}

bool memberEntityIsInWebLibrary(MemberEntity entity) {
  var importUri = entity.library.canonicalUri;
  return _isWebLibrary(importUri);
}

/// Returns the effective target of a super access of [target].
///
/// If [target] is a concrete mixin stub then the stub target is returned
/// instead of the concrete mixin stub. This is done to avoid unnecessary
/// indirections in super accesses.
///
/// See [ir.ProcedureStubKind.ConcreteMixinStub] for why concrete mixin stubs
/// are inserted in the first place.
ir.Member? getEffectiveSuperTarget(ir.Member? target) {
  if (target is ir.Procedure) {
    if (target.stubKind == ir.ProcedureStubKind.ConcreteMixinStub) {
      return getEffectiveSuperTarget(target.stubTarget);
    }
    // TODO(johnniwinther): Remove this when the CFE reports an error on
    // missing concrete super targets.
    if (target.isAbstract) {
      return null;
    }
  }
  return target;
}
