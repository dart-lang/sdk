// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:front_end/src/base/instrumentation.dart';
import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart';
import 'package:front_end/src/fasta/problems.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_engine.dart';
import 'package:front_end/src/fasta/type_inference/type_inferrer.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_environment.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';
import 'package:kernel/transformations/flags.dart' show TransformerFlag;

/// Set this flag to `true` to cause debugging information about covariance
/// checks to be printed to standard output.
const bool debugCovariance = false;

/// Type of a closure which applies a covariance annotation to a class member.
///
/// This is necessary since we need to determine which covariance annotations
/// need to be added before creating a forwarding stub, but the covariance
/// annotations themselves need to be applied to the forwarding stub.
typedef void _CovarianceFix(FunctionNode function);

/// A [ForwardingNode] represents a method, getter, or setter within a class's
/// interface that is either implemented in the class directly or inherited from
/// a superclass.
///
/// This class allows us to defer the determination of exactly which member is
/// inherited, as well as the propagation of covariance annotations, and
/// the creation of forwarding stubs, until type inference.
class ForwardingNode extends Procedure {
  /// The [InterfaceResolver] that created this [ForwardingNode].
  final InterfaceResolver _interfaceResolver;

  /// A list containing the directly implemented and directly inherited
  /// procedures of the class in question.
  ///
  /// Note that many [ForwardingNode]s share the same [_candidates] list;
  /// consult [_start] and [_end] to see which entries in this list are relevant
  /// to this [ForwardingNode].
  final List<Procedure> _candidates;

  /// Indicates whether this forwarding node is for a setter.
  final bool _setter;

  /// Index of the first entry in [_candidates] relevant to this
  /// [ForwardingNode].
  final int _start;

  /// Index just beyond the last entry in [_candidates] relevant to this
  /// [ForwardingNode].
  final int _end;

  /// The member this node resolves to (if it has been computed); otherwise
  /// `null`.
  Member _resolution;

  ForwardingNode(
      this._interfaceResolver,
      Class class_,
      Name name,
      ProcedureKind kind,
      this._candidates,
      this._setter,
      this._start,
      this._end)
      : super(name, kind, null) {
    parent = class_;
  }

  /// Returns the inherited member, or the forwarding stub, which this node
  /// resolves to.
  Member resolve() => _resolution ??= _resolve();

  /// Determines which covariance fixes need to be applied to the given
  /// [interfaceMember].
  ///
  /// [substitution] indicates the necessary substitutions to convert types
  /// named in [interfaceMember] to types in the target class.
  ///
  /// The fixes are not applied immediately (since [interfaceMember] might be
  /// a member of another class, and a forwarding stub may need to be
  /// generated).
  void _computeCovarianceFixes(Substitution substitution,
      Procedure interfaceMember, List<_CovarianceFix> fixes) {
    if (debugCovariance) {
      print('Considering covariance fixes for '
          '${_printProcedure(interfaceMember, enclosingClass)}');
      for (int i = _start; i < _end; i++) {
        print('  Candidate: ${_printProcedure(_candidates[i])}');
      }
    }
    var class_ = enclosingClass;
    var interfaceFunction = interfaceMember.function;
    var interfacePositionalParameters = interfaceFunction.positionalParameters;
    var interfaceNamedParameters = interfaceFunction.namedParameters;
    var interfaceTypeParameters = interfaceFunction.typeParameters;
    bool isImplCreated = false;
    void createImplIfNeeded() {
      if (isImplCreated) return;
      fixes.add(_createForwardingImplIfNeeded);
      isImplCreated = true;
    }

    if (class_.typeParameters.isNotEmpty) {
      IncludesTypeParametersCovariantly needsCheckVisitor =
          ShadowClass.getClassInferenceInfo(class_).needsCheckVisitor ??=
              new IncludesTypeParametersCovariantly(class_.typeParameters);
      bool needsCheck(DartType type) =>
          substitution.substituteType(type).accept(needsCheckVisitor);
      for (int i = 0; i < interfacePositionalParameters.length; i++) {
        var parameter = interfacePositionalParameters[i];
        var isCovariant = needsCheck(parameter.type);
        if (isCovariant != parameter.isGenericCovariantInterface) {
          fixes.add((FunctionNode function) => function.positionalParameters[i]
              .isGenericCovariantInterface = isCovariant);
        }
        if (isCovariant != parameter.isGenericCovariantImpl) {
          createImplIfNeeded();
          fixes.add((FunctionNode function) => function
              .positionalParameters[i].isGenericCovariantImpl = isCovariant);
        }
      }
      for (int i = 0; i < interfaceNamedParameters.length; i++) {
        var parameter = interfaceNamedParameters[i];
        var isCovariant = needsCheck(parameter.type);
        if (isCovariant != parameter.isGenericCovariantInterface) {
          fixes.add((FunctionNode function) => function
              .namedParameters[i].isGenericCovariantInterface = isCovariant);
        }
        if (isCovariant != parameter.isGenericCovariantImpl) {
          createImplIfNeeded();
          fixes.add((FunctionNode function) =>
              function.namedParameters[i].isGenericCovariantImpl = isCovariant);
        }
      }
      for (int i = 0; i < interfaceTypeParameters.length; i++) {
        var typeParameter = interfaceTypeParameters[i];
        var isCovariant = needsCheck(typeParameter.bound);
        if (isCovariant != typeParameter.isGenericCovariantInterface) {
          fixes.add((FunctionNode function) => function
              .typeParameters[i].isGenericCovariantInterface = isCovariant);
        }
        if (isCovariant != typeParameter.isGenericCovariantImpl) {
          createImplIfNeeded();
          fixes.add((FunctionNode function) =>
              function.typeParameters[i].isGenericCovariantImpl = isCovariant);
        }
      }
    }
    for (int i = _start; i < _end; i++) {
      var otherMember = _candidates[i];
      if (identical(otherMember, interfaceMember)) continue;
      var otherFunction = otherMember.function;
      var otherPositionalParameters = otherFunction.positionalParameters;
      for (int j = 0;
          j < interfacePositionalParameters.length &&
              j < otherPositionalParameters.length;
          j++) {
        var parameter = interfacePositionalParameters[j];
        var otherParameter = otherPositionalParameters[j];
        if (otherParameter.isGenericCovariantImpl &&
            !parameter.isGenericCovariantImpl) {
          createImplIfNeeded();
          fixes.add((FunctionNode function) =>
              function.positionalParameters[j].isGenericCovariantImpl = true);
        }
        if (otherParameter.isCovariant && !parameter.isCovariant) {
          createImplIfNeeded();
          fixes.add((FunctionNode function) =>
              function.positionalParameters[j].isCovariant = true);
        }
      }
      for (int j = 0; j < interfaceNamedParameters.length; j++) {
        var parameter = interfaceNamedParameters[j];
        var otherParameter = getNamedFormal(otherFunction, parameter.name);
        if (otherParameter != null) {
          if (otherParameter.isGenericCovariantImpl &&
              !parameter.isGenericCovariantImpl) {
            createImplIfNeeded();
            fixes.add((FunctionNode function) =>
                function.namedParameters[j].isGenericCovariantImpl = true);
          }
          if (otherParameter.isCovariant && !parameter.isCovariant) {
            createImplIfNeeded();
            fixes.add((FunctionNode function) =>
                function.namedParameters[j].isCovariant = true);
          }
        }
      }
      var otherTypeParameters = otherFunction.typeParameters;
      for (int j = 0;
          j < interfaceTypeParameters.length && j < otherTypeParameters.length;
          j++) {
        var typeParameter = interfaceTypeParameters[j];
        var otherTypeParameter = otherTypeParameters[j];
        if (otherTypeParameter.isGenericCovariantImpl &&
            !typeParameter.isGenericCovariantImpl) {
          createImplIfNeeded();
          fixes.add((FunctionNode function) =>
              function.typeParameters[j].isGenericCovariantImpl = true);
        }
      }
    }

    if (debugCovariance && fixes.isNotEmpty) {
      print('  ${fixes.length} fix(es)');
    }
  }

  List<FunctionType> _computeMethodOverriddenTypes(Procedure declaredMethod) {
    var overriddenTypes = <FunctionType>[];
    var declaredTypeParameters = declaredMethod.function.typeParameters;
    for (int i = _start + 1; i < _end; i++) {
      var candidate = _candidates[i];
      var candidateFunction = candidate.function;
      if (candidateFunction == null) {
        // This can happen if there are errors.  Just skip this override.
      }
      var substitution = _substitutionFor(candidate);
      FunctionType overriddenType =
          substitution.substituteType(candidateFunction.functionType);
      var overriddenTypeParameters = overriddenType.typeParameters;
      if (overriddenTypeParameters.length != declaredTypeParameters.length) {
        // Generic arity mismatch.  Don't do any inference for this method.
        // TODO(paulberry): report an error.
        return <FunctionType>[];
      } else if (overriddenTypeParameters.isNotEmpty) {
        var substitutionMap = <TypeParameter, DartType>{};
        for (int i = 0; i < declaredTypeParameters.length; i++) {
          substitutionMap[overriddenTypeParameters[i]] =
              new TypeParameterType(declaredTypeParameters[i]);
        }
        overriddenType = substituteTypeParams(
            overriddenType, substitutionMap, declaredTypeParameters);
      }
      overriddenTypes.add(overriddenType);
    }
    return overriddenTypes;
  }

  void _createForwardingImplIfNeeded(FunctionNode function) {
    if (function.body != null) {
      // There is already an implementation; nothing further needs to be done.
      return;
    }
    // Find the concrete implementation in the superclass; this is what we need
    // to forward to.  If we can't find one, then the method is fully abstract
    // and we don't need to do anything.
    var superclass = enclosingClass.superclass;
    if (superclass == null) return;
    Procedure procedure = function.parent;
    var superTarget = _interfaceResolver._typeEnvironment.hierarchy
        .getDispatchTarget(superclass, procedure.name,
            setter: kind == ProcedureKind.Setter);
    if (superTarget == null) return;
    procedure.isAbstract = false;
    if (!procedure.isForwardingStub) {
      _interfaceResolver._instrumentation?.record(
          Uri.parse(procedure.fileUri),
          procedure.fileOffset,
          'forwardingStub',
          new InstrumentationValueLiteral('implementation'));
    }
    var positionalArguments = function.positionalParameters
        .map<Expression>((parameter) => new VariableGet(parameter))
        .toList();
    var namedArguments = function.namedParameters
        .map((parameter) =>
            new NamedExpression(parameter.name, new VariableGet(parameter)))
        .toList();
    var typeArguments = function.typeParameters
        .map<DartType>((typeParameter) => new TypeParameterType(typeParameter))
        .toList();
    var arguments = new Arguments(positionalArguments,
        types: typeArguments, named: namedArguments);
    Expression superCall;
    switch (kind) {
      case ProcedureKind.Method:
      case ProcedureKind.Operator:
        superCall = new SuperMethodInvocation(name, arguments, superTarget);
        break;
      case ProcedureKind.Getter:
        superCall = new SuperPropertyGet(
            name,
            superTarget is SyntheticAccessor
                ? superTarget._field
                : superTarget);
        break;
      case ProcedureKind.Setter:
        superCall = new SuperPropertySet(
            name,
            positionalArguments[0],
            superTarget is SyntheticAccessor
                ? superTarget._field
                : superTarget);
        break;
      default:
        unhandled('$kind', '_createForwardingImplIfNeeded', -1, null);
        break;
    }
    function.body = new ReturnStatement(superCall)..parent = function;
    procedure.transformerFlags |= TransformerFlag.superCalls;
  }

  /// Creates a forwarding stub based on the given [target].
  Procedure _createForwardingStub(Substitution substitution, Procedure target) {
    VariableDeclaration copyParameter(VariableDeclaration parameter) {
      return new VariableDeclaration(parameter.name,
          type: substitution.substituteType(parameter.type));
    }

    var targetTypeParameters = target.function.typeParameters;
    List<TypeParameter> typeParameters;
    if (targetTypeParameters.isNotEmpty) {
      typeParameters =
          new List<TypeParameter>.filled(targetTypeParameters.length, null);
      var additionalSubstitution = <TypeParameter, DartType>{};
      for (int i = 0; i < targetTypeParameters.length; i++) {
        var targetTypeParameter = targetTypeParameters[i];
        var typeParameter = new TypeParameter(targetTypeParameter.name, null);
        typeParameters[i] = typeParameter;
        additionalSubstitution[targetTypeParameter] =
            new TypeParameterType(typeParameter);
      }
      substitution = Substitution.combine(
          substitution, Substitution.fromMap(additionalSubstitution));
      for (int i = 0; i < typeParameters.length; i++) {
        typeParameters[i].bound =
            substitution.substituteType(targetTypeParameters[i].bound);
      }
    }
    var positionalParameters =
        target.function.positionalParameters.map(copyParameter).toList();
    var namedParameters =
        target.function.namedParameters.map(copyParameter).toList();
    var function = new FunctionNode(null,
        positionalParameters: positionalParameters,
        namedParameters: namedParameters,
        typeParameters: typeParameters,
        requiredParameterCount: target.function.requiredParameterCount,
        returnType: substitution.substituteType(target.function.returnType));
    return new Procedure(name, kind, function,
        isAbstract: true,
        isForwardingStub: true,
        fileUri: enclosingClass.fileUri)
      ..fileOffset = enclosingClass.fileOffset
      ..parent = enclosingClass;
  }

  void _inferMethodType(Procedure declaredMethod) {
    // First collect types of overridden methods
    var overriddenTypes = _computeMethodOverriddenTypes(declaredMethod);

    // Now infer types.
    DartType matchTypes(Iterable<DartType> types) {
      var iterator = types.iterator;
      if (!iterator.moveNext()) {
        // No overridden types.  Infer `dynamic`.
        return const DynamicType();
      }
      var inferredType = iterator.current;
      while (iterator.moveNext()) {
        if (inferredType != iterator.current) {
          // TODO(paulberry): Types don't match.  Report an error.
          return const DynamicType();
        }
      }
      return inferredType;
    }

    if (ShadowProcedure.hasImplicitReturnType(declaredMethod)) {
      var inferredType =
          matchTypes(overriddenTypes.map((type) => type.returnType));
      _interfaceResolver._instrumentation?.record(
          Uri.parse(enclosingClass.fileUri),
          declaredMethod.fileOffset,
          'topType',
          new InstrumentationValueForType(inferredType));
      declaredMethod.function.returnType = inferredType;
    }
    var positionalParameters = declaredMethod.function.positionalParameters;
    for (int i = 0; i < positionalParameters.length; i++) {
      if (ShadowVariableDeclaration
          .isImplicitlyTyped(positionalParameters[i])) {
        // Note that if the parameter is not present in the overridden method,
        // getPositionalParameterType treats it as dynamic.  This is consistent
        // with the behavior called for in the informal top level type inference
        // spec, which says:
        //
        //     If there is no corresponding parameter position in the overridden
        //     method to infer from and the signatures are compatible, it is
        //     treated as dynamic (e.g. overriding a one parameter method with a
        //     method that takes a second optional parameter).  Note: if there
        //     is no corresponding parameter position in the overriden method to
        //     infer from and the signatures are incompatible (e.g. overriding a
        //     one parameter method with a method that takes a second
        //     non-optional parameter), the inference result is not defined and
        //     tools are free to either emit an error, or to defer the error to
        //     override checking.
        var inferredType = matchTypes(
            overriddenTypes.map((type) => getPositionalParameterType(type, i)));
        _interfaceResolver._instrumentation?.record(
            Uri.parse(enclosingClass.fileUri),
            positionalParameters[i].fileOffset,
            'topType',
            new InstrumentationValueForType(inferredType));
        positionalParameters[i].type = inferredType;
      }
    }
    var namedParameters = declaredMethod.function.namedParameters;
    for (int i = 0; i < namedParameters.length; i++) {
      if (ShadowVariableDeclaration.isImplicitlyTyped(namedParameters[i])) {
        var name = namedParameters[i].name;
        var inferredType = matchTypes(
            overriddenTypes.map((type) => getNamedParameterType(type, name)));
        _interfaceResolver._instrumentation?.record(
            Uri.parse(enclosingClass.fileUri),
            namedParameters[i].fileOffset,
            'topType',
            new InstrumentationValueForType(inferredType));
        namedParameters[i].type = inferredType;
      }
    }
  }

  /// Returns a string describing the signature of [procedure], along with the
  /// class it's in.
  ///
  /// Only used if [debugCovariance] is `true`.
  ///
  /// If [class_] is provided, it is used instead of [procedure]'s enclosing
  /// class.
  String _printProcedure(Procedure procedure, [Class class_]) {
    class_ ??= procedure.enclosingClass;
    var buffer = new StringBuffer();
    procedure.accept(new Printer(buffer));
    var text = buffer.toString();
    var newlineIndex = text.indexOf('\n');
    if (newlineIndex != -1) {
      text = text.substring(0, newlineIndex);
    }
    return '$class_: $text';
  }

  /// Determines which inherited member this node resolves to, and also performs
  /// type inference.
  Member _resolve() {
    var inheritedMember = _candidates[_start];
    var inheritedMemberSubstitution = Substitution.empty;
    bool isDeclaredInThisClass =
        identical(inheritedMember.enclosingClass, enclosingClass);
    if (isDeclaredInThisClass) {
      if (kind == ProcedureKind.Getter || kind == ProcedureKind.Setter) {
        // TODO(paulberry): do type inference.
      } else if (_interfaceResolver.strongMode &&
          _requiresTypeInference(inheritedMember)) {
        _inferMethodType(inheritedMember);
      }
    } else {
      // If there are multiple inheritance candidates, the inherited member is
      // the member whose type is a subtype of all the others.  We can find it
      // by two passes over the list of members.  For the first pass, we step
      // through the candidates, updating inheritedMember each time we find a
      // member whose type is a subtype of the previous inheritedMember.  As we
      // do this, we also work out the necessary substitution for matching up
      // type parameters between this class and the corresponding superclass.
      //
      // Since the subtyping relation is reflexive, we will favor the most
      // recently visited candidate in the case where the types are the same.
      // We want to favor earlier candidates, so we visit the candidate list
      // backwards.
      inheritedMember = _candidates[_end - 1];
      inheritedMemberSubstitution = _substitutionFor(inheritedMember);
      var inheritedMemberType = inheritedMemberSubstitution.substituteType(
          _setter ? inheritedMember.setterType : inheritedMember.getterType);
      for (int i = _end - 2; i >= _start; i--) {
        var candidate = _candidates[i];
        var substitution = _substitutionFor(candidate);
        bool isBetter;
        DartType type;
        if (_setter) {
          type = substitution.substituteType(candidate.setterType);
          // Setters are contravariant in their setter type, so we have to
          // reverse the check.
          isBetter = _interfaceResolver._typeEnvironment
              .isSubtypeOf(inheritedMemberType, type);
        } else {
          type = substitution.substituteType(candidate.getterType);
          isBetter = _interfaceResolver._typeEnvironment
              .isSubtypeOf(type, inheritedMemberType);
        }
        if (isBetter) {
          inheritedMember = candidate;
          inheritedMemberSubstitution = substitution;
          inheritedMemberType = type;
        }
      }
      // For the second pass, we verify that inheritedMember is a subtype of all
      // the other potentially inherited members.
      // TODO(paulberry): implement this.
    }

    // Now decide whether we need a forwarding stub or not, and propagate
    // covariance.
    var covarianceFixes = <_CovarianceFix>[];
    if (_interfaceResolver.strongMode) {
      _computeCovarianceFixes(
          inheritedMemberSubstitution, inheritedMember, covarianceFixes);
    }
    if (!isDeclaredInThisClass &&
        (!identical(inheritedMember, _candidates[_start]) ||
            covarianceFixes.isNotEmpty)) {
      var stub =
          _createForwardingStub(inheritedMemberSubstitution, inheritedMember);
      var function = stub.function;
      for (var fix in covarianceFixes) {
        fix(function);
      }
      return stub;
    } else {
      var function = inheritedMember.function;
      for (var fix in covarianceFixes) {
        fix(function);
      }
      if (inheritedMember is SyntheticAccessor) {
        var field = inheritedMember._field;
        if (inheritedMember.kind == ProcedureKind.Setter) {
          // Propagate covariance fixes to the field.
          var setterParameter = function.positionalParameters[0];
          field.isCovariant = setterParameter.isCovariant;
          field.isGenericCovariantInterface =
              setterParameter.isGenericCovariantInterface;
          field.isGenericCovariantImpl = setterParameter.isGenericCovariantImpl;
        }
        return field;
      } else {
        return inheritedMember;
      }
    }
  }

  /// Determines the appropriate substitution to translate type parameters
  /// mentioned in the given [candidate] to type parameters on the parent class.
  Substitution _substitutionFor(Procedure candidate) {
    return Substitution.fromInterfaceType(
        _interfaceResolver._typeEnvironment.hierarchy.getTypeAsInstanceOf(
            enclosingClass.thisType, candidate.enclosingClass));
  }

  static void createForwardingImplIfNeededForTesting(
      ForwardingNode node, FunctionNode function) {
    node._createForwardingImplIfNeeded(function);
  }

  /// Public method allowing tests to access [_createForwardingStub].
  ///
  /// This method is static so that it can be easily eliminated by tree shaking
  /// when not needed.
  static Procedure createForwardingStubForTesting(
      ForwardingNode node, Substitution substitution, Procedure target) {
    return node._createForwardingStub(substitution, target);
  }

  /// For testing: get the list of candidates relevant to a given node.
  static List<Procedure> getCandidates(ForwardingNode node) {
    return node._candidates.sublist(node._start, node._end);
  }

  static bool _requiresTypeInference(Procedure procedure) {
    if (ShadowProcedure.hasImplicitReturnType(procedure)) return true;
    var function = procedure.function;
    for (var parameter in function.positionalParameters) {
      if (ShadowVariableDeclaration.isImplicitlyTyped(parameter)) return true;
    }
    for (var parameter in function.namedParameters) {
      if (ShadowVariableDeclaration.isImplicitlyTyped(parameter)) return true;
    }
    return false;
  }
}

/// An [InterfaceResolver] keeps track of the information necessary to resolve
/// method calls, gets, and sets within a chunk of code being compiled, to
/// infer covariance annotations, and to create forwarwding stubs when necessary
/// to meet covariance requirements.
class InterfaceResolver {
  final TypeEnvironment _typeEnvironment;

  final Instrumentation _instrumentation;

  final bool strongMode;

  InterfaceResolver(
      this._typeEnvironment, this._instrumentation, this.strongMode);

  /// Populates [apiMembers] with a list of the implemented and inherited
  /// members of the given [class_]'s interface.
  ///
  /// Members of the class's interface that need to be resolved later are
  /// represented by a [ForwardingNode] object.
  ///
  /// If [setters] is `true`, the list will be populated by setters; otherwise
  /// it will be populated by getters and methods.
  void createApiMembers(Class class_, List<Member> apiMembers, bool setters) {
    List<Procedure> candidates = getCandidates(class_, setters);
    // Now create a forwarding node for each unique name.
    apiMembers.length = candidates.length;
    int storeIndex = 0;
    forEachApiMember(candidates, (int start, int end, Name name) {
      // TODO(paulberry): check for illegal getter/method mixing
      var kind = candidates[start].kind;
      var forwardingNode = new ForwardingNode(
          this, class_, name, kind, candidates, setters, start, end);
      if (kind == ProcedureKind.Method || kind == ProcedureKind.Operator) {
        // Methods and operators can be resolved immediately.
        apiMembers[storeIndex++] = forwardingNode.resolve();
      } else {
        // Getters and setters need to be resolved later, as part of type
        // inference, so just save the forwarding node for now.
        apiMembers[storeIndex++] = forwardingNode;
      }
    });
    apiMembers.length = storeIndex;
  }

  void finalizeCovariance(Class class_, List<Member> apiMembers) {
    for (int i = 0; i < apiMembers.length; i++) {
      var member = apiMembers[i];
      Member resolution;
      if (member is ForwardingNode) {
        apiMembers[i] = resolution = member.resolve();
      } else {
        resolution = member;
      }
      if (resolution is Procedure &&
          resolution.isForwardingStub &&
          identical(resolution.enclosingClass, class_)) {
        if (strongMode) {
          // Note: dartbug.com/30965 prevents us from adding forwarding stubs to
          // mixin applications, so we skip for now.
          // TODO(paulberry): get rid of this if-test after the bug is fixed.
          if (class_.mixedInType == null) {
            class_.addMember(resolution);
          }
        }
        _instrumentation?.record(
            Uri.parse(class_.location.file),
            class_.fileOffset,
            'forwardingStub',
            new InstrumentationValueForForwardingStub(resolution));
      }
    }
  }

  /// Gets a list of members implemented or potentially inherited by [class_],
  /// sorted so that members with the same name are contiguous.
  ///
  /// If [setters] is `true`, setters are reported; otherwise getters, methods,
  /// and operators are reported.
  List<Procedure> getCandidates(Class class_, bool setters) {
    // First create a list of candidates for inheritance based on the members
    // declared directly in the class.
    List<Procedure> candidates = _typeEnvironment.hierarchy
        .getDeclaredMembers(class_, setters: setters)
        .map((member) => makeCandidate(member, setters))
        .toList();
    // Merge in candidates from superclasses.
    if (class_.superclass != null) {
      candidates = _mergeCandidates(candidates, class_.superclass, setters);
    }
    for (var supertype in class_.implementedTypes) {
      candidates = _mergeCandidates(candidates, supertype.classNode, setters);
    }
    return candidates;
  }

  /// If instrumentation is enabled, records the covariance bits for the given
  /// [class_] to [_instrumentation].
  void recordInstrumentation(Class class_) {
    if (_instrumentation != null) {
      _recordInstrumentation(class_);
    }
  }

  /// Retrieves a list of the interface members of the given [class_].
  ///
  /// If [setters] is true, setters are retrieved; otherwise getters and methods
  /// are retrieved.
  List<Member> _getInterfaceMembers(Class class_, bool setters) {
    // TODO(paulberry): if class_ is being compiled from source, retrieve its
    // forwarding nodes.
    return _typeEnvironment.hierarchy
        .getInterfaceMembers(class_, setters: setters);
  }

  /// Merges together the list of interface inheritance candidates in
  /// [candidates] with interface inheritance candidates from superclass
  /// [class_].
  ///
  /// Any candidates from [class_] are converted into interface inheritance
  /// candidates using [_makeCandidate].
  List<Procedure> _mergeCandidates(
      List<Procedure> candidates, Class class_, bool setters) {
    List<Member> members = _getInterfaceMembers(class_, setters);
    if (candidates.isEmpty) {
      return members.map((member) => makeCandidate(member, setters)).toList();
    }
    if (members.isEmpty) return candidates;
    List<Procedure> result = <Procedure>[]..length =
        candidates.length + members.length;
    int storeIndex = 0;
    int i = 0, j = 0;
    while (i < candidates.length && j < members.length) {
      Procedure candidate = candidates[i];
      Member member = members[j];
      int compare = ClassHierarchy.compareMembers(candidate, member);
      if (compare <= 0) {
        result[storeIndex++] = candidate;
        ++i;
        // If the same member occurs in both lists, skip the duplicate.
        if (identical(candidate, member)) ++j;
      } else {
        result[storeIndex++] = makeCandidate(member, setters);
        ++j;
      }
    }
    while (i < candidates.length) {
      result[storeIndex++] = candidates[i++];
    }
    while (j < members.length) {
      result[storeIndex++] = makeCandidate(members[j++], setters);
    }
    result.length = storeIndex;
    return result;
  }

  /// Records the covariance bits for the given [class_] to [_instrumentation].
  ///
  /// Caller is responsible for checking whether [_instrumentation] is `null`.
  void _recordInstrumentation(Class class_) {
    var uri = Uri.parse(class_.fileUri);
    void recordCovariance(int fileOffset, bool isExplicitlyCovariant,
        bool isGenericCovariantInterface, bool isGenericCovariantImpl) {
      var covariance = <String>[];
      if (isExplicitlyCovariant) covariance.add('explicit');
      if (isGenericCovariantInterface) covariance.add('genericInterface');
      if (!isExplicitlyCovariant && isGenericCovariantImpl) {
        covariance.add('genericImpl');
      }
      if (covariance.isNotEmpty) {
        _instrumentation.record(uri, fileOffset, 'covariance',
            new InstrumentationValueLiteral(covariance.join(', ')));
      }
    }

    for (var procedure in class_.procedures) {
      if (procedure.isStatic) continue;
      // Forwarding stubs are annotated separately
      if (procedure.isForwardingStub) continue;
      void recordFormalAnnotations(VariableDeclaration formal) {
        recordCovariance(formal.fileOffset, formal.isCovariant,
            formal.isGenericCovariantInterface, formal.isGenericCovariantImpl);
      }

      void recordTypeParameterAnnotations(TypeParameter typeParameter) {
        recordCovariance(
            typeParameter.fileOffset,
            false,
            typeParameter.isGenericCovariantInterface,
            typeParameter.isGenericCovariantImpl);
      }

      procedure.function.positionalParameters.forEach(recordFormalAnnotations);
      procedure.function.namedParameters.forEach(recordFormalAnnotations);
      procedure.function.typeParameters.forEach(recordTypeParameterAnnotations);
    }
    for (var field in class_.fields) {
      if (field.isStatic) continue;
      recordCovariance(field.fileOffset, field.isCovariant,
          field.isGenericCovariantInterface, field.isGenericCovariantImpl);
    }
  }

  /// Executes [callback] once for each uniquely named member of [candidates].
  ///
  /// The [start] and [end] values passed to [callback] are the start and
  /// past-the-end indices into [candidates] of a group of members having the
  /// same name.  The [name] value passed to [callback] is the common name.
  static void forEachApiMember(List<Procedure> candidates,
      void callback(int start, int end, Name name)) {
    int i = 0;
    while (i < candidates.length) {
      var name = candidates[i].name;
      int j = i + 1;
      while (j < candidates.length && candidates[j].name == name) {
        j++;
      }
      callback(i, j, name);
      i = j;
    }
  }

  /// Transforms [member] into a candidate for interface inheritance.
  ///
  /// Fields are transformed into getters and setters; methods are passed
  /// through unchanged.
  static Procedure makeCandidate(Member member, bool setter) {
    if (member is Procedure) return member;
    if (member is Field) {
      // TODO(paulberry): don't set the type or covariance annotations here,
      // since they might not have been inferred yet.  Instead, ensure that this
      // information is propagated to the getter/setter during type inference.
      var type = member.type;
      var isGenericCovariantImpl = member.isGenericCovariantImpl;
      var isGenericCovariantInterface = member.isGenericCovariantInterface;
      var isCovariant = member.isCovariant;
      if (setter) {
        var valueParam = new VariableDeclaration('_', type: type)
          ..isGenericCovariantImpl = isGenericCovariantImpl
          ..isGenericCovariantInterface = isGenericCovariantInterface
          ..isCovariant = isCovariant;
        var function = new FunctionNode(null,
            positionalParameters: [valueParam], returnType: const VoidType());
        return new SyntheticAccessor(
            member.name, ProcedureKind.Setter, function, member)
          ..parent = member.enclosingClass;
      } else {
        var function = new FunctionNode(null, returnType: type);
        return new SyntheticAccessor(
            member.name, ProcedureKind.Getter, function, member)
          ..parent = member.enclosingClass;
      }
    }
    return unhandled('${member.runtimeType}', 'makeCandidate', -1, null);
  }
}

/// A [SyntheticAccessor] represents the getter or setter implied by a field.
class SyntheticAccessor extends Procedure {
  /// The field associated with the synthetic accessor.
  final Field _field;

  SyntheticAccessor(
      Name name, ProcedureKind kind, FunctionNode function, this._field)
      : super(name, kind, function);
}
