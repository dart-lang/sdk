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
import 'package:kernel/transformations/flags.dart' show TransformerFlag;
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

/// Set this flag to `true` to cause debugging information about covariance
/// checks to be printed to standard output.
const bool debugCovariance = false;

/// Type of a closure which applies a covariance annotation to a class member.
///
/// This is necessary since we need to determine which covariance annotations
/// need to be added before creating a forwarding stub, but the covariance
/// annotations themselves need to be applied to the forwarding stub.
typedef void _CovarianceFix(FunctionNode function);

/// Concrete class derived from [InferenceNode] to represent type inference of
/// getters, setters, and fields based on inheritance.
class AccessorInferenceNode extends MemberInferenceNode {
  AccessorInferenceNode(InterfaceResolver interfaceResolver,
      Procedure declaredMethod, List<Member> candidates, int start, int end)
      : super(interfaceResolver, declaredMethod, candidates, start, end);

  @override
  void resolveInternal() {
    var declaredMethod = _declaredMethod;
    var kind = declaredMethod.kind;
    var overriddenTypes = _computeAccessorOverriddenTypes();
    if (!isCircular) {
      var inferredType = _matchTypes(overriddenTypes);
      if (declaredMethod is SyntheticAccessor) {
        declaredMethod._field.type = inferredType;
      } else {
        if (kind == ProcedureKind.Getter) {
          declaredMethod.function.returnType = inferredType;
        } else {
          declaredMethod.function.positionalParameters[0].type = inferredType;
        }
      }
    }
  }

  /// Computes the types of the getters and setters overridden by
  /// [_declaredMethod], with appropriate type parameter substitutions.
  List<DartType> _computeAccessorOverriddenTypes() {
    var overriddenTypes = <DartType>[];
    for (int i = _start; i < _end; i++) {
      var candidate = _candidates[i];
      Procedure resolvedCandidate;
      if (candidate is ForwardingNode) {
        resolvedCandidate = candidate.resolve();
      } else {
        resolvedCandidate = candidate;
      }
      DartType overriddenType;
      if (resolvedCandidate is SyntheticAccessor) {
        var field = resolvedCandidate._field;
        ShadowMember.resolveInferenceNode(field);
        overriddenType = field.type;
      } else if (resolvedCandidate.function != null) {
        switch (resolvedCandidate.kind) {
          case ProcedureKind.Getter:
            overriddenType = resolvedCandidate.function.returnType;
            break;
          case ProcedureKind.Setter:
            overriddenType =
                resolvedCandidate.function.positionalParameters[0].type;
            break;
          default:
            // Illegal override (error will be reported elsewhere).  Just skip
            // this override.
            continue;
        }
      } else {
        // This can happen if there are errors.  Just skip this override.
        continue;
      }
      overriddenTypes.add(_interfaceResolver
          ._substitutionFor(resolvedCandidate, _declaredMethod.enclosingClass)
          .substituteType(overriddenType));
    }
    return overriddenTypes;
  }
}

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
  final List<Member> _candidates;

  /// Index of the first entry in [_candidates] relevant to this
  /// [ForwardingNode].
  final int _start;

  /// Index just beyond the last entry in [_candidates] relevant to this
  /// [ForwardingNode].
  final int _end;

  /// The member this node resolves to (if it has been computed); otherwise
  /// `null`.
  Member _resolution;

  /// The result of finalizing this node (if the node has been finalized);
  /// otherwise `null`.
  Member _finalResolution;

  /// If this forwarding node represents a member that needs type inference, the
  /// corresponding [InferenceNode]; otherwise `null`.
  InferenceNode _inferenceNode;

  ForwardingNode(this._interfaceResolver, this._inferenceNode, Class class_,
      Name name, ProcedureKind kind, this._candidates, this._start, this._end)
      : super(name, kind, null) {
    parent = class_;
  }

  /// Finishes handling of this node by propagating covariance and creating
  /// forwarding stubs if necessary.
  Procedure finalize() => _finalResolution ??= _finalize();

  /// Returns the declared or inherited member this node resolves to.
  ///
  /// Does not create forwarding stubs.
  Procedure resolve() => _resolution ??= _resolve();

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

    IncludesTypeParametersCovariantly needsCheckVisitor =
        class_.typeParameters.isEmpty
            ? null
            : ShadowClass.getClassInferenceInfo(class_).needsCheckVisitor ??=
                new IncludesTypeParametersCovariantly(class_.typeParameters);
    bool needsCheck(DartType type) => needsCheckVisitor == null
        ? false
        : substitution.substituteType(type).accept(needsCheckVisitor);
    needsCheckVisitor?.inCovariantContext = false;
    var isGenericContravariant = needsCheck(interfaceFunction.returnType);
    needsCheckVisitor?.inCovariantContext = true;
    if (isGenericContravariant != interfaceMember.isGenericContravariant) {
      fixes.add((FunctionNode function) {
        Procedure procedure = function.parent;
        procedure.isGenericContravariant = isGenericContravariant;
      });
    }
    for (int i = 0; i < interfacePositionalParameters.length; i++) {
      var parameter = interfacePositionalParameters[i];
      var isGenericCovariantInterface = needsCheck(parameter.type);
      if (isGenericCovariantInterface !=
          parameter.isGenericCovariantInterface) {
        fixes.add((FunctionNode function) => function.positionalParameters[i]
            .isGenericCovariantInterface = isGenericCovariantInterface);
      }
      var isGenericCovariantImpl =
          isGenericCovariantInterface || parameter.isGenericCovariantImpl;
      var isCovariant = parameter.isCovariant;
      var superParameter = parameter;
      for (int j = _start; j < _end; j++) {
        var otherMember = _finalizedCandidate(j);
        if (otherMember is ForwardingNode) continue;
        var otherPositionalParameters =
            otherMember.function.positionalParameters;
        if (otherPositionalParameters.length <= i) continue;
        var otherParameter = otherPositionalParameters[i];
        if (j == _start) superParameter = otherParameter;
        if (identical(otherMember, interfaceMember)) continue;
        if (otherParameter.isGenericCovariantImpl) {
          isGenericCovariantImpl = true;
        }
        if (otherParameter.isCovariant) {
          isCovariant = true;
        }
      }
      if (isGenericCovariantImpl != superParameter.isGenericCovariantImpl) {
        createImplIfNeeded();
      }
      if (isGenericCovariantImpl != parameter.isGenericCovariantImpl) {
        fixes.add((FunctionNode function) => function.positionalParameters[i]
            .isGenericCovariantImpl = isGenericCovariantImpl);
      }
      if (isCovariant != superParameter.isCovariant) {
        createImplIfNeeded();
      }
      if (isCovariant != parameter.isCovariant) {
        fixes.add((FunctionNode function) =>
            function.positionalParameters[i].isCovariant = isCovariant);
      }
    }
    for (int i = 0; i < interfaceNamedParameters.length; i++) {
      var parameter = interfaceNamedParameters[i];
      var isGenericCovariantInterface = needsCheck(parameter.type);
      if (isGenericCovariantInterface !=
          parameter.isGenericCovariantInterface) {
        fixes.add((FunctionNode function) => function.namedParameters[i]
            .isGenericCovariantInterface = isGenericCovariantInterface);
      }
      var isGenericCovariantImpl =
          isGenericCovariantInterface || parameter.isGenericCovariantImpl;
      var isCovariant = parameter.isCovariant;
      var superParameter = parameter;
      for (int j = _start; j < _end; j++) {
        var otherMember = _finalizedCandidate(j);
        if (otherMember is ForwardingNode) continue;
        var otherParameter =
            getNamedFormal(otherMember.function, parameter.name);
        if (otherParameter == null) continue;
        if (j == _start) superParameter = otherParameter;
        if (identical(otherMember, interfaceMember)) continue;
        if (otherParameter.isGenericCovariantImpl) {
          isGenericCovariantImpl = true;
        }
        if (otherParameter.isCovariant) {
          isCovariant = true;
        }
      }
      if (isGenericCovariantImpl != superParameter.isGenericCovariantImpl) {
        createImplIfNeeded();
      }
      if (isGenericCovariantImpl != parameter.isGenericCovariantImpl) {
        fixes.add((FunctionNode function) => function.namedParameters[i]
            .isGenericCovariantImpl = isGenericCovariantImpl);
      }
      if (isCovariant != superParameter.isCovariant) {
        createImplIfNeeded();
      }
      if (isCovariant != parameter.isCovariant) {
        fixes.add((FunctionNode function) =>
            function.namedParameters[i].isCovariant = isCovariant);
      }
    }
    for (int i = 0; i < interfaceTypeParameters.length; i++) {
      var typeParameter = interfaceTypeParameters[i];
      var isGenericCovariantInterface = needsCheck(typeParameter.bound);
      if (isGenericCovariantInterface !=
          typeParameter.isGenericCovariantInterface) {
        fixes.add((FunctionNode function) => function.typeParameters[i]
            .isGenericCovariantInterface = isGenericCovariantInterface);
      }
      var isGenericCovariantImpl =
          isGenericCovariantInterface || typeParameter.isGenericCovariantImpl;
      var superTypeParameter = typeParameter;
      for (int j = _start; j < _end; j++) {
        var otherMember = _finalizedCandidate(j);
        if (otherMember is ForwardingNode) continue;
        var otherTypeParameters = otherMember.function.typeParameters;
        if (otherTypeParameters.length <= i) continue;
        var otherTypeParameter = otherTypeParameters[i];
        if (j == _start) superTypeParameter = otherTypeParameter;
        if (identical(otherMember, interfaceMember)) continue;
        if (otherTypeParameter.isGenericCovariantImpl) {
          isGenericCovariantImpl = true;
        }
      }
      if (isGenericCovariantImpl != superTypeParameter.isGenericCovariantImpl) {
        createImplIfNeeded();
      }
      if (isGenericCovariantImpl != typeParameter.isGenericCovariantImpl) {
        fixes.add((FunctionNode function) => function
            .typeParameters[i].isGenericCovariantImpl = isGenericCovariantImpl);
      }
    }

    if (debugCovariance && fixes.isNotEmpty) {
      print('  ${fixes.length} fix(es)');
    }
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
          type: substitution.substituteType(parameter.type),
          isCovariant: parameter.isCovariant)
        ..isGenericCovariantImpl = parameter.isGenericCovariantImpl
        ..isGenericCovariantInterface = parameter.isGenericCovariantInterface;
    }

    var targetTypeParameters = target.function.typeParameters;
    List<TypeParameter> typeParameters;
    if (targetTypeParameters.isNotEmpty) {
      typeParameters =
          new List<TypeParameter>.filled(targetTypeParameters.length, null);
      var additionalSubstitution = <TypeParameter, DartType>{};
      for (int i = 0; i < targetTypeParameters.length; i++) {
        var targetTypeParameter = targetTypeParameters[i];
        var typeParameter = new TypeParameter(targetTypeParameter.name, null)
          ..isGenericCovariantImpl = targetTypeParameter.isGenericCovariantImpl
          ..isGenericCovariantInterface =
              targetTypeParameter.isGenericCovariantInterface;
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
      ..parent = enclosingClass
      ..isGenericContravariant = target.isGenericContravariant;
  }

  /// Creates a forwarding stubs for this node if necessary, and propagates
  /// covariance information.
  Procedure _finalize() {
    var inheritedMember = resolve();
    var inheritedMemberSubstitution =
        _interfaceResolver._substitutionFor(inheritedMember, enclosingClass);
    bool isDeclaredInThisClass =
        identical(inheritedMember.enclosingClass, enclosingClass);

    // Now decide whether we need a forwarding stub or not, and propagate
    // covariance.
    var covarianceFixes = <_CovarianceFix>[];
    if (_interfaceResolver.strongMode) {
      _computeCovarianceFixes(
          inheritedMemberSubstitution, inheritedMember, covarianceFixes);
    }
    if (!isDeclaredInThisClass &&
        (!identical(inheritedMember, _resolvedCandidate(_start)) ||
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
      return inheritedMember;
    }
  }

  /// Returns the [i]th element of [_candidates], finalizing it if necessary.
  Procedure _finalizedCandidate(int i) {
    Procedure candidate = _candidates[i];
    return candidate is ForwardingNode &&
            _interfaceResolver.isTypeInferencePrepared
        ? candidate.finalize()
        : candidate;
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
    if (procedure.function == null) {
      buffer.write(procedure.toString());
    } else {
      procedure.accept(new Printer(buffer));
    }
    var text = buffer.toString();
    var newlineIndex = text.indexOf('\n');
    if (newlineIndex != -1) {
      text = text.substring(0, newlineIndex);
    }
    return '$class_: $text';
  }

  /// Determines which inherited member this node resolves to, and also performs
  /// type inference.
  Procedure _resolve() {
    Procedure inheritedMember = _candidates[_start];
    bool isDeclaredInThisClass =
        identical(inheritedMember.enclosingClass, enclosingClass);
    if (isDeclaredInThisClass) {
      if (_inferenceNode != null) {
        _inferenceNode.resolve();
        _inferenceNode = null;
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
      inheritedMember = _resolvedCandidate(_end - 1);
      var inheritedMemberSubstitution =
          _interfaceResolver._substitutionFor(inheritedMember, enclosingClass);
      var inheritedMemberType = inheritedMember is ForwardingNode
          ? const DynamicType()
          : inheritedMemberSubstitution.substituteType(
              kind == ProcedureKind.Setter
                  ? inheritedMember.setterType
                  : inheritedMember.getterType);
      for (int i = _end - 2; i >= _start; i--) {
        var candidate = _resolvedCandidate(i);
        var substitution =
            _interfaceResolver._substitutionFor(candidate, enclosingClass);
        bool isBetter;
        DartType type;
        if (kind == ProcedureKind.Setter) {
          type = candidate is ForwardingNode
              ? const DynamicType()
              : substitution.substituteType(candidate.setterType);
          // Setters are contravariant in their setter type, so we have to
          // reverse the check.
          isBetter = _interfaceResolver._typeEnvironment
              .isSubtypeOf(inheritedMemberType, type);
        } else {
          type = candidate is ForwardingNode
              ? const DynamicType()
              : substitution.substituteType(candidate.getterType);
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
    return inheritedMember;
  }

  /// Returns the [i]th element of [_candidates], resolving it if necessary.
  Procedure _resolvedCandidate(int i) {
    Procedure candidate = _candidates[i];
    return candidate is ForwardingNode &&
            _interfaceResolver.isTypeInferencePrepared
        ? candidate.resolve()
        : candidate;
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
}

/// An [InterfaceResolver] keeps track of the information necessary to resolve
/// method calls, gets, and sets within a chunk of code being compiled, to
/// infer covariance annotations, and to create forwarwding stubs when necessary
/// to meet covariance requirements.
class InterfaceResolver {
  final TypeInferenceEngineImpl _typeInferenceEngine;

  final TypeEnvironment _typeEnvironment;

  final Instrumentation _instrumentation;

  final bool strongMode;

  InterfaceResolver(this._typeInferenceEngine, this._typeEnvironment,
      this._instrumentation, this.strongMode);

  /// Indicates whether the "prepare" phase of type inference is complete.
  bool get isTypeInferencePrepared =>
      _typeInferenceEngine.isTypeInferencePrepared;

  /// Populates [apiMembers] with a list of the implemented and inherited
  /// members of the given [class_]'s interface.
  ///
  /// Members of the class's interface that need to be resolved later are
  /// represented by a [ForwardingNode] object.
  ///
  /// If [setters] is `true`, the list will be populated by setters; otherwise
  /// it will be populated by getters and methods.
  void createApiMembers(
      Class class_, List<Member> getters, List<Member> setters) {
    var candidates = ClassHierarchy.mergeSortedLists(
        getCandidates(class_, false), getCandidates(class_, true));
    // Now create getter and perhaps setter forwarding nodes for each unique
    // name.
    getters.length = candidates.length;
    setters.length = candidates.length;
    int getterIndex = 0;
    int setterIndex = 0;
    forEachApiMember(candidates, (int getterStart, int setterEnd, Name name) {
      // TODO(paulberry): check for illegal getter/method mixing

      Procedure declaredGetter;
      int i = getterStart;
      int inheritedGetterStart;
      int getterEnd;
      if (_kindOf(candidates[i]) == ProcedureKind.Setter) {
        inheritedGetterStart = i;
      } else {
        if (identical(candidates[i].enclosingClass, class_)) {
          declaredGetter = candidates[i++];
        }
        inheritedGetterStart = i;
        while (
            i < setterEnd && _kindOf(candidates[i]) != ProcedureKind.Setter) {
          ++i;
        }
      }
      getterEnd = i;
      Procedure declaredSetter;
      int inheritedSetterStart;
      if (i < setterEnd && identical(candidates[i].enclosingClass, class_)) {
        declaredSetter = candidates[i];
        inheritedSetterStart = i + 1;
      } else {
        inheritedSetterStart = i;
      }

      InferenceNode getterInferenceNode;
      if (getterStart < getterEnd) {
        if (declaredGetter != null) {
          getterInferenceNode = _createInferenceNode(
              class_,
              declaredGetter,
              candidates,
              inheritedGetterStart,
              getterEnd,
              inheritedSetterStart,
              setterEnd);
        }
        var forwardingNode = new ForwardingNode(
            this,
            getterInferenceNode,
            class_,
            name,
            _kindOf(candidates[getterStart]),
            candidates,
            getterStart,
            getterEnd);
        if (!forwardingNode.isGetter) {
          // Methods and operators can be finalized immediately.
          getters[getterIndex++] = forwardingNode.finalize();
        } else {
          // Getters need to be resolved later, as part of type
          // inference, so just save the forwarding node for now.
          getters[getterIndex++] = forwardingNode;
        }
      }
      if (getterEnd < setterEnd) {
        InferenceNode setterInferenceNode;
        if (declaredSetter != null) {
          if (declaredSetter is SyntheticAccessor) {
            setterInferenceNode = getterInferenceNode;
          } else {
            setterInferenceNode = _createInferenceNode(
                class_,
                declaredSetter,
                candidates,
                inheritedSetterStart,
                setterEnd,
                inheritedGetterStart,
                getterEnd);
          }
        }
        var forwardingNode = new ForwardingNode(
            this,
            setterInferenceNode,
            class_,
            name,
            ProcedureKind.Setter,
            candidates,
            getterEnd,
            setterEnd);
        // Setters need to be resolved later, as part of type
        // inference, so just save the forwarding node for now.
        setters[setterIndex++] = forwardingNode;
      }
    });
    getters.length = getterIndex;
    setters.length = setterIndex;
  }

  void finalizeCovariance(Class class_, List<Member> apiMembers) {
    for (int i = 0; i < apiMembers.length; i++) {
      var member = apiMembers[i];
      Member resolution;
      if (member is ForwardingNode) {
        apiMembers[i] = resolution = member.finalize();
      } else {
        resolution = member;
      }
      if (resolution is Procedure &&
          resolution.isForwardingStub &&
          identical(resolution.enclosingClass, class_)) {
        if (strongMode) class_.addMember(resolution);
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

  /// Creates the appropriate [InferenceNode] for inferring [procedure] in the
  /// context of [class_].
  ///
  /// [candidates] a list containing the procedures overridden by [procedure],
  /// if any.  [start] is the index of the first such procedure, and [end] is
  /// the past-the-end index of the last such procedure.
  ///
  /// For getters and setters, [crossStart] and [crossEnd] are the start and end
  /// indices of the corresponding overridden setters/getters, respectively.
  InferenceNode _createInferenceNode(
      Class class_,
      Procedure procedure,
      List<Member> candidates,
      int start,
      int end,
      int crossStart,
      int crossEnd) {
    if (!_requiresTypeInference(procedure)) return null;
    switch (procedure.kind) {
      case ProcedureKind.Getter:
      case ProcedureKind.Setter:
        if (strongMode && start < end) {
          return new AccessorInferenceNode(
              this, procedure, candidates, start, end);
        } else if (strongMode && crossStart < crossEnd) {
          return new AccessorInferenceNode(
              this, procedure, candidates, crossStart, crossEnd);
        } else if (procedure is SyntheticAccessor &&
            procedure._field.initializer != null) {
          var node = new FieldInitializerInferenceNode(
              _typeInferenceEngine, procedure._field);
          ShadowField.setInferenceNode(procedure._field, node);
          return node;
        }
        return null;
      default: // Method || Operator
        if (strongMode) {
          return new MethodInferenceNode(
              this, procedure, candidates, start, end);
        }
        return null;
    }
  }

  /// Retrieves a list of the interface members of the given [class_].
  ///
  /// If [setters] is true, setters are retrieved; otherwise getters and methods
  /// are retrieved.
  List<Member> _getInterfaceMembers(Class class_, bool setters) {
    // If class_ is being compiled from source, retrieve its forwarding nodes.
    var inferenceInfo = ShadowClass.getClassInferenceInfo(class_);
    if (inferenceInfo != null) {
      return setters ? inferenceInfo.setters : inferenceInfo.gettersAndMethods;
    } else {
      return _typeEnvironment.hierarchy
          .getInterfaceMembers(class_, setters: setters);
    }
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

    void recordContravariance(int fileOffset, bool isGenericContravariant) {
      if (isGenericContravariant) {
        _instrumentation.record(uri, fileOffset, 'genericContravariant',
            new InstrumentationValueLiteral('true'));
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
      recordContravariance(
          procedure.fileOffset, procedure.isGenericContravariant);
    }
    for (var field in class_.fields) {
      if (field.isStatic) continue;
      recordCovariance(field.fileOffset, field.isCovariant,
          field.isGenericCovariantInterface, field.isGenericCovariantImpl);
      recordContravariance(field.fileOffset, field.isGenericContravariant);
    }
  }

  /// Determines the appropriate substitution to translate type parameters
  /// mentioned in the given [candidate] to type parameters on [class_].
  Substitution _substitutionFor(Procedure candidate, Class class_) {
    return Substitution.fromInterfaceType(_typeEnvironment.hierarchy
        .getTypeAsInstanceOf(class_.thisType, candidate.enclosingClass));
  }

  /// Executes [callback] once for each uniquely named member of [candidates].
  ///
  /// The [start] and [end] values passed to [callback] are the start and
  /// past-the-end indices into [candidates] of a group of members having the
  /// same name.  The [name] value passed to [callback] is the common name.
  static void forEachApiMember(
      List<Member> candidates, void callback(int start, int end, Name name)) {
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

  static ProcedureKind _kindOf(Procedure procedure) => procedure.kind;

  /// Determines whether the given [procedure] will require type inference.
  static bool _requiresTypeInference(Procedure procedure) {
    if (procedure is SyntheticAccessor) {
      return ShadowField.isImplicitlyTyped(procedure._field);
    }
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

/// Abstract class derived from [InferenceNode] to represent type inference of
/// methods, getters, and setters based on inheritance.
abstract class MemberInferenceNode extends InferenceNode {
  final InterfaceResolver _interfaceResolver;

  /// The method whose return type and/or parameter types should be inferred.
  final Procedure _declaredMethod;

  /// A list containing the methods overridden by [_declaredMethod], if any.
  final List<Member> _candidates;

  /// The index of the first method in [_candidates] overridden by
  /// [_declaredMethod].
  final int _start;

  /// The past-the-end index of the last method in [_candidates] overridden by
  /// [_declaredMethod].
  final int _end;

  MemberInferenceNode(this._interfaceResolver, this._declaredMethod,
      this._candidates, this._start, this._end);

  DartType _matchTypes(Iterable<DartType> types) {
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
}

/// Concrete class derived from [InferenceNode] to represent type inference of
/// methods.
class MethodInferenceNode extends MemberInferenceNode {
  MethodInferenceNode(InterfaceResolver interfaceResolver,
      Procedure declaredMethod, List<Member> candidates, int start, int end)
      : super(interfaceResolver, declaredMethod, candidates, start, end);

  @override
  void resolveInternal() {
    var declaredMethod = _declaredMethod;
    var overriddenTypes = _computeMethodOverriddenTypes();
    if (ShadowProcedure.hasImplicitReturnType(declaredMethod)) {
      declaredMethod.function.returnType =
          _matchTypes(overriddenTypes.map((type) => type.returnType));
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
        positionalParameters[i].type = _matchTypes(
            overriddenTypes.map((type) => getPositionalParameterType(type, i)));
      }
    }
    var namedParameters = declaredMethod.function.namedParameters;
    for (int i = 0; i < namedParameters.length; i++) {
      if (ShadowVariableDeclaration.isImplicitlyTyped(namedParameters[i])) {
        var name = namedParameters[i].name;
        namedParameters[i].type = _matchTypes(
            overriddenTypes.map((type) => getNamedParameterType(type, name)));
      }
    }
    // Circularities should never occur with method inference, since the
    // inference of a method can only depend on the methods above it in the
    // class hierarchy.
    assert(!isCircular);
  }

  /// Computes the types of the methods overridden by [_declaredMethod], with
  /// appropriate type parameter substitutions.
  List<FunctionType> _computeMethodOverriddenTypes() {
    var overriddenTypes = <FunctionType>[];
    var declaredTypeParameters = _declaredMethod.function.typeParameters;
    for (int i = _start; i < _end; i++) {
      var candidate = _candidates[i];
      if (candidate is SyntheticAccessor) {
        // This can happen if there are errors.  Just skip this override.
        continue;
      }
      var candidateFunction = candidate.function;
      if (candidateFunction == null) {
        // This can happen if there are errors.  Just skip this override.
        continue;
      }
      var substitution = _interfaceResolver._substitutionFor(
          candidate, _declaredMethod.enclosingClass);
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
}

/// A [SyntheticAccessor] represents the getter or setter implied by a field.
class SyntheticAccessor extends Procedure {
  /// The field associated with the synthetic accessor.
  final Field _field;

  SyntheticAccessor(
      Name name, ProcedureKind kind, FunctionNode function, this._field)
      : super(
            name,
            kind,
            kind == ProcedureKind.Setter
                ? new SyntheticAccessorFunctionNode.setter(_field)
                : new SyntheticAccessorFunctionNode.getter(_field),
            fileUri: _field.fileUri) {
    fileOffset = _field.fileOffset;
  }

  @override
  DartType get getterType => _field.type;

  @override
  bool get isGenericContravariant =>
      kind == ProcedureKind.Getter && _field.isGenericContravariant;

  @override
  void set isGenericContravariant(bool value) {
    assert(kind == ProcedureKind.Getter);
    _field.isGenericContravariant = value;
  }

  static getField(SyntheticAccessor accessor) => accessor._field;
}

/// A [SyntheticAccessorFunctionNode] represents the [FunctionNode] part of the
/// getter or setter implied by a field.
///
/// For getters, [returnType] maps to the underlying field's type, so that if
/// type inference fills in the type of the field, the change will automatically
/// be reflected in the synthetic getter.
class SyntheticAccessorFunctionNode extends FunctionNode {
  final Field _field;

  SyntheticAccessorFunctionNode.getter(this._field)
      : super(new ReturnStatement());

  SyntheticAccessorFunctionNode.setter(this._field)
      : super(new ReturnStatement(),
            positionalParameters: [new SyntheticSetterParameter(_field)]);

  @override
  DartType get returnType =>
      positionalParameters.isEmpty ? _field.type : const VoidType();
}

/// A [SyntheticSetterParameter] represents the "value" parameter of the setter
/// implied by a field.
///
/// The getters [isCovariant], [isGenericCovariantImpl],
/// [isGenericCovariantInterface], and [type] map to the underlying field's
/// properties, so that if these properties are modified on the field, the
/// change will automatically be reflected in the synthetic setter.  Similarly,
/// the setters [isCovariant], [isGenericCovariantImpl], and
/// [isGenericCovariantInterface] update the corresponding properties on the
/// field, so that covariance propagation logic can act uniformly on [Procedure]
/// objects without having to have special case handling for fields.
class SyntheticSetterParameter extends VariableDeclaration {
  final Field _field;

  SyntheticSetterParameter(this._field)
      : super('_', isCovariant: _field.isCovariant);

  @override
  bool get isCovariant => _field.isCovariant;

  @override
  void set isCovariant(bool value) {
    _field.isCovariant = value;
  }

  @override
  bool get isGenericCovariantImpl => _field.isGenericCovariantImpl;

  @override
  void set isGenericCovariantImpl(bool value) {
    _field.isGenericCovariantImpl = value;
  }

  @override
  bool get isGenericCovariantInterface => _field.isGenericCovariantInterface;

  @override
  void set isGenericCovariantInterface(bool value) {
    _field.isGenericCovariantInterface = value;
  }

  @override
  DartType get type => _field.type;
}
