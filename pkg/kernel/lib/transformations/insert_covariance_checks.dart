// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.transformations.insert_covariance_checks;

import '../class_hierarchy.dart';
import '../clone.dart';
import '../core_types.dart';
import '../kernel.dart';
import '../log.dart';
import '../type_algebra.dart';
import '../type_environment.dart';

DartType substituteBounds(DartType type, Map<TypeParameter, DartType> upper,
    Map<TypeParameter, DartType> lower) {
  return Substitution
      .fromUpperAndLowerBounds(upper, lower)
      .substituteType(type);
}

/// Inserts checked entry points for methods in order to enforce type safety
/// in face on covariant subtyping.
///
/// An 'unsafe parameter' is a parameter whose type mentions a class type
/// parameter T, but is not contravariant in T.  For instance, the argument
/// to `List.add` is unsafe, whereas the function parameter to `List.forEach`
/// is safe:
///
///     class List<T> {
///       ...
///       void add(T x) {...} // unsafe
///       void forEach(void action(T x)) {...} // safe
///     }
///
/// For every method with unsafe parameters, a checked entry point suffixed
/// with `$cc` is inserted, which casts the unsafe parameters to their expected
/// types and calls the actual implementation:
///
///     class List<T> {
///       ...
///       void add$cc(Object x) => this.add(x as T);
///     }
///
/// Calls whose interface target declares unsafe parameters are then rewritten
/// to target the `$cc` entry point instead, unless it can be determined that
/// the type argument is exact.  For example:
///
///     void foo(List<num> numbers) {
///       numbers.add(3.5); // before
///       numbers.add$cc(3.5); // after
///     }
///
/// Currently, we only deduce that the type arguments are exact when the
/// receiver is `this`.
class InsertCovarianceChecks {
  final CoreTypes coreTypes;
  ClassHierarchy hierarchy;
  TypeEnvironment types;

  /// Maps unsafe members to their checked entry point, to be used at call sites
  /// where the arguments cannot be guaranteed to satisfy the generic parameter
  /// types of the actual target.
  final Map<Member, Procedure> unsafeMemberEntryPoint = <Member, Procedure>{};

  /// Members that may be invoked through a checked entry point.
  ///
  /// Note that these members are not necessarily unsafe, because a safe member
  /// can override an unsafe member, and thereby be invoked through a checked
  /// entry point.  This set is not therefore not the same as the set of keys
  /// in [unsafeMemberEntryPoint].
  final Set<Member> membersWithCheckedEntryPoint = new Set<Member>();

  InsertCovarianceChecks(this.coreTypes, this.hierarchy);

  void transformProgram(Program program) {
    types = new TypeEnvironment(coreTypes, hierarchy);
    // We transform every class before their subtypes.
    // This ensures that transitive overrides are taken into account.
    var unorderedClasses = program.libraries
        .map((library) => library.classes)
        .expand((classes) => classes);
    var ordered = hierarchy.getOrderedClasses(unorderedClasses);
    ordered.forEach(transformClass);

    program.accept(new _CallTransformer(this));
  }

  void transformClass(Class class_) {
    new _ClassTransformer(class_, this).transformClass();
  }
}

class _ClassTransformer {
  final Class host;
  final ClassHierarchy hierarchy;
  final TypeEnvironment types;
  final InsertCovarianceChecks global;

  final Map<Field, VariableDeclaration> fieldSetterParameter =
      <Field, VariableDeclaration>{};

  final Map<VariableDeclaration, List<DartType>> unsafeParameterTypes =
      new Map<VariableDeclaration, List<DartType>>();

  // The following four maps translate types from the context of a supertype
  // into the context of the current class.
  //
  // When analyzing an override relation "ownMember <: superMember", the two
  // "own" maps translate types from the context of the ownMember, while the
  // "super" maps translate types from the context of superMember.
  //
  // The "substitution" maps translate type parameters to their exact type,
  // while the "upper bound" maps translate type parameters to their erased
  // upper bounds.
  Map<TypeParameter, DartType> ownSubstitution;
  Map<TypeParameter, DartType> ownUpperBounds;
  Map<TypeParameter, DartType> superSubstitution;
  Map<TypeParameter, DartType> superUpperBounds;

  /// Members for which a checked entry point must be created in this current
  /// class, indexed by name.
  Map<Name, Member> membersNeedingCheckedEntryPoint = <Name, Member>{};

  _ClassTransformer(this.host, InsertCovarianceChecks global)
      : hierarchy = global.hierarchy,
        types = global.types,
        this.global = global;

  /// Mark [parameter] unsafe, with [type] as a potential argument type.
  void addUnsafeParameter(
      VariableDeclaration parameter, DartType type, Member member) {
    unsafeParameterTypes.putIfAbsent(parameter, () => <DartType>[]).add(type);
    requireLocalCheckedEntryPoint(member);
  }

  /// Get a parameter representing the argument to the implicit setter
  /// for [field].
  VariableDeclaration getFieldSetterParameter(Field field) {
    return fieldSetterParameter.putIfAbsent(field, () {
      return new VariableDeclaration('${field.name.name}_', type: field.type);
    });
  }

  /// Mark [field] as unsafe, with [type] as a potential argument to its setter.
  void addUnsafeField(Field field, DartType type) {
    addUnsafeParameter(getFieldSetterParameter(field), type, field);
  }

  /// True if [member] can be invoked through a checked entry point.
  ///
  /// This does not imply that the member has unsafe parameters.
  bool hasCheckedEntryPoint(Member member, {bool setter: false}) {
    if (!setter && member is Field) {
      return false; // Field getters never have checked entry points.
    }
    return global.membersWithCheckedEntryPoint.contains(member);
  }

  /// Ensures that a checked entry point for [member] will be emitted in the
  /// current class.
  void requireLocalCheckedEntryPoint(Member member) {
    membersNeedingCheckedEntryPoint[member.name] = member;
    global.membersWithCheckedEntryPoint.add(member);
  }

  void transformClass() {
    if (host.isMixinApplication) {
      // TODO(asgerf): We need a way to support mixin applications with unsafe
      //   overrides. This version assumes mixins have been resolved by cloning.
      //   We could generate a subclass of the mixin application containing the
      //   checked entry points.
      throw 'Mixin applications must be resolved before inserting covariance '
          'checks';
    }
    // Find parameters with an unsafe reference to a class type parameter.
    if (host.typeParameters.isNotEmpty) {
      var upperBounds = getUpperBoundSubstitutionMap(host);
      for (var field in host.fields) {
        if (field.hasImplicitSetter) {
          var rawType = substituteBounds(field.type, upperBounds, {});
          if (!identical(rawType, field.type)) {
            requireLocalCheckedEntryPoint(field);
            addUnsafeField(field, rawType);
          }
        }
      }
      for (var procedure in host.procedures) {
        if (procedure.isStatic) continue;
        void handleParameter(VariableDeclaration parameter) {
          var rawType = substituteBounds(parameter.type, upperBounds, {});
          if (!identical(rawType, parameter.type)) {
            requireLocalCheckedEntryPoint(procedure);
            addUnsafeParameter(parameter, rawType, procedure);
          }
        }

        procedure.function.positionalParameters.forEach(handleParameter);
        procedure.function.namedParameters.forEach(handleParameter);
      }
    }

    // Find (possibly inherited) members that override a method that has
    // unsafe parameters.
    hierarchy.forEachOverridePair(host,
        (Member ownMember, Member superMember, bool isSetter) {
      if (hasCheckedEntryPoint(superMember, setter: isSetter)) {
        requireLocalCheckedEntryPoint(ownMember);
      }
      if (superMember.enclosingClass.typeParameters.isEmpty) return;
      ownSubstitution = getSubstitutionMap(
          hierarchy.getClassAsInstanceOf(host, ownMember.enclosingClass));
      ownUpperBounds = getUpperBoundSubstitutionMap(ownMember.enclosingClass);
      superSubstitution = getSubstitutionMap(
          hierarchy.getClassAsInstanceOf(host, superMember.enclosingClass));
      superUpperBounds =
          getUpperBoundSubstitutionMap(superMember.enclosingClass);
      if (ownMember is Procedure) {
        if (superMember is Procedure) {
          checkProcedureOverride(ownMember, superMember);
        } else if (superMember is Field && isSetter) {
          checkSetterFieldOverride(ownMember, superMember);
        }
      } else if (isSetter) {
        checkFieldOverride(ownMember, superMember);
      }
    });

    for (Member member in membersNeedingCheckedEntryPoint.values) {
      ownSubstitution = getSubstitutionMap(
          hierarchy.getClassAsInstanceOf(host, member.enclosingClass));
      ownSubstitution = ensureMutable(ownSubstitution);
      generateCheckedEntryPoint(member);
    }
  }

  /// Compute an upper bound of the types in [inputTypes].
  ///
  /// We use this to compute a trustworthy type for a parameter, given a list
  /// of types that may actually be passed into the parameter.
  DartType getSafeType(List<DartType> inputTypes) {
    var safeType = inputTypes[0];
    for (int i = 1; i < inputTypes.length; ++i) {
      if (inputTypes[i] != safeType) {
        // Multiple types are being overridden. Fall back to dynamic.
        // There are cases where a better upper bound could be found, but they
        // are quite rare.
        return const DynamicType();
      }
    }
    return safeType;
  }

  void fail(String message) {
    log.warning('[unsoundness] $message');
  }

  void checkFieldOverride(Field field, Member superMember) {
    var fieldType =
        substituteBounds(field.type, ownUpperBounds, ownSubstitution);
    var superType = substituteBounds(
        superMember.setterType, superUpperBounds, superSubstitution);
    if (!types.isSubtypeOf(superType, fieldType)) {
      addUnsafeField(field, superType);
    }
  }

  void checkSetterFieldOverride(Procedure ownMember, Field superMember) {
    assert(ownMember.isSetter);
    var ownParameter = ownMember.function.positionalParameters[0];
    var ownType =
        substituteBounds(ownParameter.type, ownUpperBounds, ownSubstitution);
    var superType = substituteBounds(
        superMember.setterType, superUpperBounds, superSubstitution);
    if (!types.isSubtypeOf(superType, ownType)) {
      addUnsafeParameter(ownParameter, superType, ownMember);
    }
  }

  void checkProcedureOverride(Procedure ownMember, Procedure superMember) {
    var ownFunction = ownMember.function;
    var superFunction = superMember.function;
    // We perform some checks here to avoid crashing, but the frontend is
    // responsible for generating IR that does not violate these restrictions.
    if (ownFunction.requiredParameterCount >
        superFunction.requiredParameterCount) {
      fail('$ownMember requires more parameters than $superMember');
      return;
    }
    if (ownFunction.positionalParameters.length <
        superFunction.positionalParameters.length) {
      fail('$ownMember allows fewer parameters than $superMember');
      return;
    }
    if (ownFunction.typeParameters.length !=
        superFunction.typeParameters.length) {
      fail('$ownMember declares a different number of type parameters '
          'than $superMember');
      return;
    }
    if (superFunction.typeParameters.isNotEmpty) {
      // Ensure these maps are not constant, so we can add bindings for the
      // function type parameters.
      superSubstitution = ensureMutable(superSubstitution);
      superUpperBounds = ensureMutable(superUpperBounds);
    }
    for (int i = 0; i < superFunction.typeParameters.length; ++i) {
      var ownTypeParameter = ownFunction.typeParameters[i];
      var superTypeParameter = superFunction.typeParameters[i];
      var type = new TypeParameterType(ownTypeParameter);
      superSubstitution[superTypeParameter] = type;
      superUpperBounds[superTypeParameter] = type;
    }
    void checkParameterPair(
        VariableDeclaration ownParameter, VariableDeclaration superParameter) {
      var ownType = substitute(ownParameter.type, ownSubstitution);
      var superType = substituteBounds(
          superParameter.type, superUpperBounds, superSubstitution);
      if (!types.isSubtypeOf(superType, ownType)) {
        addUnsafeParameter(ownParameter, superType, ownMember);
      }
    }

    for (int i = 0; i < superFunction.positionalParameters.length; ++i) {
      checkParameterPair(ownFunction.positionalParameters[i],
          superFunction.positionalParameters[i]);
    }
    for (int i = 0; i < superFunction.namedParameters.length; ++i) {
      var superParameter = superFunction.namedParameters[i];
      bool found = false;
      for (int j = 0; j < ownFunction.namedParameters.length; ++j) {
        var ownParameter = ownFunction.namedParameters[j];
        if (ownParameter.name == superParameter.name) {
          found = true;
          checkParameterPair(ownParameter, superParameter);
          break;
        }
      }
      if (!found) {
        fail('$ownMember is missing the named parameter '
            '${superParameter.name} from $superMember');
      }
    }
  }

  void generateCheckedEntryPoint(Member member) {
    // TODO(asgerf): It may be worthwhile to try to reuse a checked entry
    //   point from the supertype when the same checks are needed and the
    //   dispatch target is the same.
    if (member is Procedure) {
      generateCheckedProcedure(member);
    } else {
      generateCheckedFieldSetter(member);
    }
  }

  void generateCheckedProcedure(Procedure procedure) {
    var function = procedure.function;

    // Clone the function without its body.
    var body = function.body;
    function.body = null;
    var cloner = new CloneVisitor(typeSubstitution: ownSubstitution);
    Procedure checkedProcedure = cloner.clone(procedure);
    FunctionNode checkedFunction = checkedProcedure.function;
    function.body = body;

    checkedFunction.asyncMarker = AsyncMarker.Sync;
    checkedProcedure.isExternal = false;

    Expression getParameter(VariableDeclaration parameter) {
      var cloneParameter = cloner.variables[parameter];
      var unsafeInputs = unsafeParameterTypes[parameter];
      if (unsafeInputs == null) {
        return new VariableGet(cloneParameter); // No check needed.
      }
      // Change the actual parameter type to the safe type, and cast to the
      // type declared on the original parameter.
      // Use the cloner to map function type parameters to the cloned
      // function type parameters (in case the function is generic).
      var targetType = cloneParameter.type;
      cloneParameter.type = cloner.visitType(getSafeType(unsafeInputs));
      return new AsExpression(new VariableGet(cloneParameter), targetType)
        ..fileOffset = parameter.fileOffset;
    }

    // TODO: Insert checks for type parameter bounds.
    var types = checkedFunction.typeParameters
        .map((p) => new TypeParameterType(p))
        .toList();
    var positional = function.positionalParameters.map(getParameter).toList();
    var named = function.namedParameters
        .map((p) => new NamedExpression(p.name, getParameter(p)))
        .toList();

    checkedProcedure.name = covariantCheckedName(procedure.name);
    host.addMember(checkedProcedure);

    // Only generate a body if the original method had one.
    if (!procedure.isAbstract && !procedure.isInExternalLibrary) {
      var call = procedure.isSetter
          ? new DirectPropertySet(
              new ThisExpression(), procedure, positional[0])
          : new DirectMethodInvocation(new ThisExpression(), procedure,
              new Arguments(positional, named: named, types: types));
      var checkedBody = function.returnType is VoidType
          ? new ExpressionStatement(call)
          : new ReturnStatement(call);
      checkedFunction.body = checkedBody..parent = checkedFunction;
    }

    if (procedure.enclosingClass == host) {
      global.unsafeMemberEntryPoint[procedure] = checkedProcedure;
    }
  }

  void generateCheckedFieldSetter(Field field) {
    var parameter = getFieldSetterParameter(field);
    var unsafeTypes = unsafeParameterTypes[parameter];
    Expression argument = new VariableGet(parameter);
    if (unsafeTypes != null) {
      var castType = substitute(field.type, ownSubstitution);
      argument = new AsExpression(argument, castType)
        ..fileOffset = field.fileOffset;
      var inputType = substitute(getSafeType(unsafeTypes), ownSubstitution);
      parameter.type = inputType;
    }

    Statement body = field.isInExternalLibrary
        ? null
        : new ExpressionStatement(
            new DirectPropertySet(new ThisExpression(), field, argument));

    var setter = new Procedure(
        covariantCheckedName(field.name),
        ProcedureKind.Setter,
        new FunctionNode(body, positionalParameters: [parameter]))
      ..fileUri = field.fileUri;
    host.addMember(setter);

    if (field.enclosingClass == host) {
      global.unsafeMemberEntryPoint[field] = setter;
    }
  }

  /// Generates a synthetic name representing the covariant-checked entry point
  /// to a method.
  static Name covariantCheckedName(Name name) {
    return new Name('${name.name}\$cc', name.library);
  }

  static Map<TypeParameter, DartType> ensureMutable(
      Map<TypeParameter, DartType> map) {
    if (map.isEmpty) return <TypeParameter, DartType>{};
    return map;
  }
}

// TODO(asgerf): We should be able to avoid checked calls in a lot more cases:
//  - the arguments to every unsafe parameter is null or is omitted
//  - allocation site of receiver can easily be seen statically
class _CallTransformer extends RecursiveVisitor {
  final InsertCovarianceChecks global;
  final TypeEnvironment types;
  final Map<Member, Procedure> checkedInterfaceMethod;

  _CallTransformer(InsertCovarianceChecks global)
      : checkedInterfaceMethod = global.unsafeMemberEntryPoint,
        types = global.types,
        this.global = global;

  Member getChecked(Expression receiver, Member member) {
    var checked = checkedInterfaceMethod[member];
    if (checked == null) return member;
    if (!receiverNeedsChecks(receiver)) return member;
    return checked;
  }

  bool receiverNeedsChecks(Expression node) {
    if (node is ThisExpression) return false;
    var type = node.getStaticType(types);
    if (type is InterfaceType && type.typeArguments.every(isSealedType)) {
      return false;
    }
    return true;
  }

  bool isSealedType(DartType type) {
    return type is InterfaceType && types.isSealedClass(type.classNode);
  }

  bool isTrustedLibrary(Library node) {
    return node.importUri.scheme == 'dart';
  }

  @override
  visitClass(Class node) {
    types.thisType = node.thisType;
    node.visitChildren(this);
  }

  @override
  visitLibrary(Library node) {
    if (!isTrustedLibrary(node)) {
      node.visitChildren(this);
    }
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    var target = getChecked(node.receiver, node.interfaceTarget);
    if (target != null) {
      node.interfaceTarget = target;
      node.name = target.name;
    }
    node.visitChildren(this);
  }

  @override
  visitPropertySet(PropertySet node) {
    var target = getChecked(node.receiver, node.interfaceTarget);
    if (target != null) {
      node.interfaceTarget = target;
      node.name = target.name;
    }
    node.visitChildren(this);
  }
}
