// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'common.dart';
import 'elements/entities.dart';
import 'js_model/closure.dart';
import 'js_model/element_map.dart';
import 'serialization/serialization.dart';

/// Class that provides information for how closures are rewritten/represented
/// to preserve Dart semantics when compiled to JavaScript. Given a particular
/// node to look up, it returns a information about the internal representation
/// of how closure conversion is implemented. T is an ir.Node or Node.
abstract class ClosureData {
  /// Deserializes a [ClosureData] object from [source].
  factory ClosureData.readFromDataSource(
          JsToElementMap elementMap, DataSource source) =
      ClosureDataImpl.readFromDataSource;

  /// Serializes this [ClosureData] to [sink].
  void writeToDataSink(DataSink sink);

  /// Look up information about the variables that have been mutated and are
  /// used inside the scope of [node].
  ScopeInfo getScopeInfo(MemberEntity member);

  ClosureRepresentationInfo getClosureInfo(ir.LocalFunction localFunction);

  /// Look up information about a loop, in case any variables it declares need
  /// to be boxed/snapshotted.
  CapturedLoopScope getCapturedLoopScope(ir.Node loopNode);

  /// Accessor to the information about scopes that closures capture. Used by
  /// the SSA builder.
  CapturedScope getCapturedScope(MemberEntity entity);

  /// If [entity] is a closure call method or closure signature method, the
  /// original enclosing member is returned. Otherwise [entity] is returned.
  ///
  /// A member and its nested closure share the underlying AST, we need to
  /// ensure that locals are shared between them. We therefore store the
  /// locals in the global locals map using the enclosing member as key.
  MemberEntity getEnclosingMember(MemberEntity entity);
}

/// Enum used for identifying [ScopeInfo] subclasses in serialization.
enum ScopeInfoKind {
  scopeInfo,
  capturedScope,
  capturedLoopScope,
  closureRepresentationInfo,
}

/// Class that represents one level of scoping information, whether this scope
/// is a closure or not. This is specifically used to store information
/// about the usage of variables in try or sync blocks, because they need to be
/// boxed.
///
/// Variables that are used in a try must be treated as boxed because the
/// control flow can be non-linear. Also parameters to a `sync*` generator must
/// be boxed, because of the way we rewrite sync* functions. See also comments
/// in [ClosureClassMap.useLocal].
class ScopeInfo {
  const ScopeInfo();

  /// Deserializes a [ScopeInfo] object from [source].
  factory ScopeInfo.readFromDataSource(DataSource source) {
    ScopeInfoKind kind = source.readEnum(ScopeInfoKind.values);
    switch (kind) {
      case ScopeInfoKind.scopeInfo:
        return JsScopeInfo.readFromDataSource(source);
      case ScopeInfoKind.capturedScope:
        return JsCapturedScope.readFromDataSource(source);
      case ScopeInfoKind.capturedLoopScope:
        return JsCapturedLoopScope.readFromDataSource(source);
      case ScopeInfoKind.closureRepresentationInfo:
        return JsClosureClassInfo.readFromDataSource(source);
    }
    throw UnsupportedError('Unexpected ScopeInfoKind $kind');
  }

  /// Serializes this [ScopeInfo] to [sink].
  void writeToDataSink(DataSink sink) {
    throw UnsupportedError('${runtimeType}.writeToDataSink');
  }

  /// Convenience reference pointer to the element representing `this`.
  /// If this scope is not in an instance member, it will be null.
  Local get thisLocal => null;

  /// Returns true if this [variable] is used inside a `try` block or a `sync*`
  /// generator (this is important to know because boxing/redirection needs to
  /// happen for those local variables).
  ///
  /// Variables that are used in a try must be treated as boxed because the
  /// control flow can be non-linear.
  ///
  /// Also parameters to a `sync*` generator must be boxed, because of the way
  /// we rewrite sync* functions. See also comments in
  /// [ClosureClassMap.useLocal].
  bool localIsUsedInTryOrSync(KernelToLocalsMap localsMap, Local variable) =>
      false;

  /// Loop through each variable that has been defined in this scope, modified
  /// anywhere (this scope or another scope) and used in another scope. Because
  /// it is used in another scope, these variables need to be "boxed", creating
  /// a thin wrapper around accesses to these variables so that accesses get
  /// the correct updated value. The variables in localsUsedInTryOrSync may
  /// be included in this set.
  ///
  /// In the case of loops, this is the set of iteration variables (or any
  /// variables declared in the for loop expression (`for (...here...)`) that
  /// need to be boxed to snapshot their value.
  void forEachBoxedVariable(
      KernelToLocalsMap localsMap, f(Local local, FieldEntity field)) {}

  /// True if [variable] has been mutated and is also used in another scope.
  bool isBoxedVariable(KernelToLocalsMap localsMap, Local variable) => false;
}

/// Class representing the usage of a scope that has been captured in the
/// context of a closure.
class CapturedScope extends ScopeInfo {
  const CapturedScope();

  /// Deserializes a [CapturedScope] object from [source].
  factory CapturedScope.readFromDataSource(DataSource source) {
    ScopeInfoKind kind = source.readEnum(ScopeInfoKind.values);
    switch (kind) {
      case ScopeInfoKind.scopeInfo:
      case ScopeInfoKind.closureRepresentationInfo:
        throw UnsupportedError('Unexpected CapturedScope kind $kind');
      case ScopeInfoKind.capturedScope:
        return JsCapturedScope.readFromDataSource(source);
      case ScopeInfoKind.capturedLoopScope:
        return JsCapturedLoopScope.readFromDataSource(source);
    }
    throw UnsupportedError('Unexpected ScopeInfoKind $kind');
  }

  /// If true, this closure accesses a variable that was defined in an outside
  /// scope and this variable gets modified at some point (sometimes we say that
  /// variable has been "captured"). In this situation, access to this variable
  /// is controlled via a wrapper (box) so that updates to this variable
  /// are done in a way that is in line with Dart's closure rules.
  bool get requiresContextBox => false;

  /// Accessor to the local environment in which a particular closure node is
  /// executed. This will encapsulate the value of any variables that have been
  /// scoped into this context from outside. This is an accessor to the
  /// contextBox that [requiresContextBox] is testing is required.
  Local get contextBox => null;
}

/// Class that describes the actual mechanics of how values of variables
/// instantiated in a loop are captured inside closures in the loop body.
/// Unlike JS, the value of a declared loop iteration variable in any closure
/// is captured/snapshotted inside at each iteration point, as if we created a
/// new local variable for that value inside the loop. For example, for the
/// following loop:
///
///     var lst = [];
///     for (int i = 0; i < 5; i++) lst.add(()=>i);
///     var result = list.map((f) => f()).toList();
///
/// `result` will be [0, 1, 2, 3, 4], whereas were this JS code
/// the result would be [5, 5, 5, 5, 5]. Because of this difference we need to
/// create a closure for these sorts of loops to capture the variable's value at
/// each iteration, by boxing the iteration variable[s].
class CapturedLoopScope extends CapturedScope {
  const CapturedLoopScope();

  /// Deserializes a [CapturedLoopScope] object from [source].
  factory CapturedLoopScope.readFromDataSource(DataSource source) {
    ScopeInfoKind kind = source.readEnum(ScopeInfoKind.values);
    switch (kind) {
      case ScopeInfoKind.scopeInfo:
      case ScopeInfoKind.closureRepresentationInfo:
      case ScopeInfoKind.capturedScope:
        throw UnsupportedError('Unexpected CapturedLoopScope kind $kind');
      case ScopeInfoKind.capturedLoopScope:
        return JsCapturedLoopScope.readFromDataSource(source);
    }
    throw UnsupportedError('Unexpected ScopeInfoKind $kind');
  }

  /// True if this loop scope declares in the first part of the loop
  /// `for (<here>;...;...)` any variables that need to be boxed.
  bool get hasBoxedLoopVariables => false;

  /// The set of iteration variables (or variables declared in the for loop
  /// expression (`for (<here>; ... ; ...)`) that need to be boxed to snapshot
  /// their value. These variables are also included in the set of
  /// `forEachBoxedVariable` method. The distinction between these two sets is
  /// in this example:
  ///
  ///     run(f) => f();
  ///     var a;
  ///     for (int i = 0; i < 3; i++) {
  ///       var b = 3;
  ///       a = () => b = i;
  ///     }
  ///
  /// `i` would be a part of the boxedLoopVariables AND boxedVariables, but b
  /// would only be a part of boxedVariables.
  List<Local> getBoxedLoopVariables(KernelToLocalsMap localsMap) =>
      const <Local>[];
}

/// Class that describes the actual mechanics of how the converted, rewritten
/// closure is implemented. For example, for the following closure (named foo
/// for convenience):
///
///   var foo = (x) => y + x;
///
/// We would produce the following class to control access to these variables in
/// the following way (modulo naming of variables, assuming that y is modified
/// elsewhere in its scope):
///
///    class FooClosure {
///       int y;
///       FooClosure(this.y);
///       call(x) => this.y + x;
///    }
///
///  and then to execute this closure, for example:
///
///     var foo = new FooClosure(1);
///     foo.call(2);
///
/// if `y` is modified elsewhere within its scope, accesses to y anywhere in the
/// code will be controlled via a box object.
///
/// Because in these examples `y` was declared in some other, outer scope, but
/// used in the inner scope of this closure, we say `y` is a "captured"
/// variable.
/// TODO(efortuna): Make interface simpler in subsequent refactorings.
class ClosureRepresentationInfo extends ScopeInfo {
  const ClosureRepresentationInfo();

  /// Deserializes a [ClosureRepresentationInfo] object from [source].
  factory ClosureRepresentationInfo.readFromDataSource(DataSource source) {
    ScopeInfoKind kind = source.readEnum(ScopeInfoKind.values);
    switch (kind) {
      case ScopeInfoKind.scopeInfo:
      case ScopeInfoKind.capturedScope:
      case ScopeInfoKind.capturedLoopScope:
        throw UnsupportedError(
            'Unexpected ClosureRepresentationInfo kind $kind');
      case ScopeInfoKind.closureRepresentationInfo:
        return JsClosureClassInfo.readFromDataSource(source);
    }
    throw UnsupportedError('Unexpected ScopeInfoKind $kind');
  }

  /// The original local function before any translation.
  ///
  /// Will be null for methods.
  Local getClosureEntity(KernelToLocalsMap localsMap) => null;

  /// The entity for the class used to represent the rewritten closure in the
  /// emitted JavaScript.
  ///
  /// Closures are rewritten in the form of classes that have fields to control
  /// the redirection and editing of captured variables.
  ClassEntity get closureClassEntity => null;

  /// The function that implements the [local] function as a `call` method on
  /// the closure class.
  FunctionEntity get callMethod => null;

  /// The signature method for [callMethod] if needed.
  FunctionEntity get signatureMethod => null;

  /// List of locals that this closure class has created corresponding field
  /// entities for.
  @deprecated
  List<Local> getCreatedFieldEntities(KernelToLocalsMap localsMap) =>
      const <Local>[];

  /// As shown in the example in the comments at the top of this class, we
  /// create fields in the closure class for each captured variable. This is an
  /// accessor the [local] for which [field] was created.
  /// Returns the [local] for which [field] was created.
  Local getLocalForField(KernelToLocalsMap localsMap, FieldEntity field) {
    failedAt(field, "No local for $field.");
    return null;
  }

  /// Convenience pointer to the field entity representation in the closure
  /// class of the element representing `this`.
  FieldEntity get thisFieldEntity => null;

  /// Loop through each variable that has been boxed in this closure class. Only
  /// captured variables that are mutated need to be "boxed" (which basically
  /// puts a thin layer between updates and reads to this variable to ensure
  /// that every place that accesses it gets the correct updated value). This
  /// includes looping over variables that were boxed from other scopes, not
  /// strictly variables defined in this closure, unlike the behavior in
  /// the superclass ScopeInfo.
  @override
  void forEachBoxedVariable(
      KernelToLocalsMap localsMap, f(Local local, FieldEntity field)) {}

  /// Loop through each free variable in this closure. Free variables are the
  /// variables that have been captured *just* in this closure, not in nested
  /// scopes.
  void forEachFreeVariable(
      KernelToLocalsMap localsMap, f(Local variable, FieldEntity field)) {}

  // TODO(efortuna): Remove this method. The old system was using
  // ClosureClassMaps for situations other than closure class maps, and that's
  // just confusing.
  bool get isClosure => false;
}

/// A local variable that contains the box object holding the [BoxFieldElement]
/// fields.
class BoxLocal extends Local {
  final ClassEntity container;

  BoxLocal(this.container);

  @override
  String get name => container.name;

  @override
  bool operator ==(other) {
    return other is BoxLocal && other.container == container;
  }

  @override
  int get hashCode => container.hashCode;

  @override
  String toString() => 'BoxLocal($name)';
}

/// A local variable used encode the direct (uncaptured) references to [this].
class ThisLocal extends Local {
  final ClassEntity enclosingClass;

  ThisLocal(this.enclosingClass);

  @override
  String get name => 'this';

  @override
  bool operator ==(other) {
    return other is ThisLocal && other.enclosingClass == enclosingClass;
  }

  @override
  int get hashCode => enclosingClass.hashCode;
}

/// A type variable as a local variable.
class TypeVariableLocal implements Local {
  final TypeVariableEntity typeVariable;

  TypeVariableLocal(this.typeVariable);

  @override
  String get name => typeVariable.name;

  @override
  int get hashCode => typeVariable.hashCode;

  @override
  bool operator ==(other) {
    if (other is! TypeVariableLocal) return false;
    return typeVariable == other.typeVariable;
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write('type_variable_local(');
    sb.write(typeVariable);
    sb.write(')');
    return sb.toString();
  }
}

///
/// Move the below classes to a JS model eventually.
///
abstract class JSEntity implements MemberEntity {
  String get declaredName;
}

abstract class PrivatelyNamedJSEntity implements JSEntity {
  Entity get rootOfScope;
}
