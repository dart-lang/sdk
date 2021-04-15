// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:js_ast/src/precedence.dart' as js show PRIMARY;

import '../elements/entities.dart';
import '../js/js.dart' as js;
import '../serialization/serialization.dart';
import '../util/util.dart';

import 'namer.dart';

// TODO(joshualitt): Figure out how to subsume more of the modular naming
// framework into this approach. For example, we are still creating ModularNames
// for the entity referenced in the DeferredHolderExpression.
enum DeferredHolderExpressionKind {
  globalObjectForLibrary,
  globalObjectForClass,
  globalObjectForType,
  globalObjectForMember,
}

class DeferredHolderExpression extends js.DeferredExpression
    implements js.AstContainer {
  static const String tag = 'deferred-holder-expression';

  final DeferredHolderExpressionKind kind;
  final Entity entity;
  js.Expression _value;

  @override
  final js.JavaScriptNodeSourceInformation sourceInformation;

  DeferredHolderExpression(this.kind, this.entity) : sourceInformation = null;
  DeferredHolderExpression._(
      this.kind, this.entity, this._value, this.sourceInformation);

  factory DeferredHolderExpression.readFromDataSource(DataSource source) {
    source.begin(tag);
    var kind = source.readEnum(DeferredHolderExpressionKind.values);
    Entity entity;
    switch (kind) {
      case DeferredHolderExpressionKind.globalObjectForLibrary:
        entity = source.readLibrary();
        break;
      case DeferredHolderExpressionKind.globalObjectForClass:
        entity = source.readClass();
        break;
      case DeferredHolderExpressionKind.globalObjectForType:
        entity = source.readClass();
        break;
      case DeferredHolderExpressionKind.globalObjectForMember:
        entity = source.readMember();
        break;
    }
    source.end(tag);
    return DeferredHolderExpression(kind, entity);
  }

  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeEnum(kind);
    switch (kind) {
      case DeferredHolderExpressionKind.globalObjectForLibrary:
        sink.writeLibrary(entity);
        break;
      case DeferredHolderExpressionKind.globalObjectForClass:
        sink.writeClass(entity);
        break;
      case DeferredHolderExpressionKind.globalObjectForType:
        sink.writeClass(entity);
        break;
      case DeferredHolderExpressionKind.globalObjectForMember:
        sink.writeMember(entity);
        break;
    }
    sink.end(tag);
  }

  set value(js.Expression value) {
    assert(!isFinalized && value != null);
    _value = value;
  }

  @override
  js.Expression get value {
    assert(isFinalized, '$this is unassigned');
    return _value;
  }

  @override
  bool get isFinalized => _value != null;

  @override
  DeferredHolderExpression withSourceInformation(
      js.JavaScriptNodeSourceInformation newSourceInformation) {
    if (newSourceInformation == sourceInformation) return this;
    if (newSourceInformation == null) return this;
    return DeferredHolderExpression._(
        kind, entity, _value, newSourceInformation);
  }

  @override
  int get precedenceLevel => _value?.precedenceLevel ?? js.PRIMARY;

  @override
  int get hashCode {
    return Hashing.objectsHash(kind, entity);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeferredHolderExpression &&
        kind == other.kind &&
        entity == other.entity;
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('DeferredHolderExpression(kind=$kind,entity=$entity,');
    sb.write('value=$_value)');
    return sb.toString();
  }

  @override
  Iterable<js.Node> get containedNodes => isFinalized ? [_value] : const [];
}

abstract class DeferredHolderExpressionFinalizer {
  /// Collects DeferredHolderExpressions from the JavaScript
  /// AST [code];
  void addCode(js.Node code);

  /// Performs analysis on all collected DeferredHolderExpression nodes
  /// finalizes the values to expressions to access the holders.
  void finalize();
}

class DeferredHolderExpressionFinalizerImpl
    implements DeferredHolderExpressionFinalizer {
  _DeferredHolderExpressionCollectorVisitor _visitor;
  final List<DeferredHolderExpression> holderReferences = [];
  final Namer _namer;

  DeferredHolderExpressionFinalizerImpl(this._namer) {
    _visitor = _DeferredHolderExpressionCollectorVisitor(this);
  }

  @override
  void addCode(js.Node code) {
    code.accept(_visitor);
  }

  @override
  void finalize() {
    for (var reference in holderReferences) {
      if (reference.isFinalized) continue;
      switch (reference.kind) {
        case DeferredHolderExpressionKind.globalObjectForLibrary:
          reference.value = _namer
              .readGlobalObjectForLibrary(reference.entity)
              .withSourceInformation(reference.sourceInformation);
          break;
        case DeferredHolderExpressionKind.globalObjectForClass:
          reference.value = _namer
              .readGlobalObjectForClass(reference.entity)
              .withSourceInformation(reference.sourceInformation);
          break;
        case DeferredHolderExpressionKind.globalObjectForType:
          reference.value = _namer
              .readGlobalObjectForType(reference.entity)
              .withSourceInformation(reference.sourceInformation);
          break;
        case DeferredHolderExpressionKind.globalObjectForMember:
          reference.value = _namer
              .readGlobalObjectForMember(reference.entity)
              .withSourceInformation(reference.sourceInformation);
          break;
      }
    }
  }

  void _registerDeferredHolderExpression(DeferredHolderExpression node) {
    holderReferences.add(node);
  }
}

/// Scans a JavaScript AST to collect all the DeferredHolderExpression nodes.
///
/// The state is kept in the finalizer so that this scan could be extended to
/// look for other deferred expressions in one pass.
class _DeferredHolderExpressionCollectorVisitor extends js.BaseVisitor<void> {
  final DeferredHolderExpressionFinalizerImpl _finalizer;

  _DeferredHolderExpressionCollectorVisitor(this._finalizer);

  @override
  void visitNode(js.Node node) {
    assert(node is! DeferredHolderExpression);
    if (node is js.AstContainer) {
      for (js.Node element in node.containedNodes) {
        element.accept(this);
      }
    } else {
      super.visitNode(node);
    }
  }

  @override
  void visitDeferredExpression(js.DeferredExpression node) {
    if (node is DeferredHolderExpression) {
      _finalizer._registerDeferredHolderExpression(node);
    } else {
      visitNode(node);
    }
  }
}
