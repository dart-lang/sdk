// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/js_model/element_map.dart';

import '../closure.dart';
import '../common.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../inferrer/abstract_value_domain.dart';
import '../inferrer/types.dart';
import '../io/source_information.dart';
import '../js_backend/native_data.dart';
import '../js_backend/interceptor_data.dart';
import '../js_model/closure.dart' show JContextField, JClosureField;
import '../js_model/js_world.dart' show JClosedWorld;
import '../js_model/locals.dart' show GlobalLocalsMap, JLocal;

import 'builder.dart';
import 'nodes.dart';
import 'types.dart';

/// Keeps track of locals (including parameters and phis) when building. The
/// 'this' reference is treated as parameter and hence handled by this class,
/// too.
class LocalsHandler {
  /// The values of locals that can be directly accessed (without redirections
  /// to boxes or closure-fields).
  ///
  /// [directLocals] is iterated, so it is "insertion ordered" to make the
  /// iteration order a function only of insertions and not a function of
  /// e.g. Element hash codes.  I'd prefer to use a SortedMap but some elements
  /// don't have source locations for [Elements.compareByPosition].
  Map<Local, HInstruction> directLocals = {};
  Map<Local, FieldEntity> redirectionMapping = {};
  final KernelSsaGraphBuilder builder;

  MemberEntity? _scopeInfoMember;
  ScopeInfo? _scopeInfo;
  KernelToLocalsMap? _localsMap;

  Map<TypeVariableEntity, TypeVariableLocal> typeVariableLocals = {};
  final Entity executableContext;
  final MemberEntity memberContext;

  /// The type of the current instance. `null` if in a static context.
  ///
  /// This is the type of `this` is the current context, and is often the
  /// 'this type' of the enclosing class of a member.
  ///
  /// If the current instance is concrete, we can handle fixed type argument in
  /// case of inlining. For instance, checking `'foo'` against `String` instead
  /// of `T` in `main`:
  ///
  ///     class Foo<T> {
  ///       T field;
  ///       Foo(this.field);
  ///     }
  ///     main() {
  ///       Foo<String>('foo');
  ///     }
  ///
  final InterfaceType? instanceType;

  final NativeData _nativeData;

  final InterceptorData _interceptorData;

  LocalsHandler(this.builder, this.executableContext, this.memberContext,
      this.instanceType, this._nativeData, this._interceptorData);

  JClosedWorld get _closedWorld => builder.closedWorld;

  AbstractValueDomain get _abstractValueDomain =>
      _closedWorld.abstractValueDomain;

  GlobalTypeInferenceResults get _globalInferenceResults =>
      builder.globalInferenceResults;

  GlobalLocalsMap get _globalLocalsMap =>
      _globalInferenceResults.globalLocalsMap;

  /// Substituted type variables occurring in [type] into the context of
  /// [contextClass].
  DartType substInContext(DartType type) {
    DartType newType = type;
    final iType = instanceType;
    if (iType != null) {
      final typeContext = DartTypes.getClassContext(newType);
      if (typeContext != null) {
        newType = _closedWorld.dartTypes.substByContext(
            newType,
            _closedWorld.dartTypes.asInstanceOf(
                _closedWorld.dartTypes.getThisType(iType.element),
                typeContext)!);
      }
      if (!iType.containsTypeVariables) {
        newType = _closedWorld.dartTypes.substByContext(newType, iType);
      }
    }
    return newType;
  }

  /// Creates a new [LocalsHandler] based on [other]. We only need to
  /// copy the [directLocals], since the other fields can be shared
  /// throughout the AST visit.
  LocalsHandler.from(LocalsHandler other)
      : directLocals = Map<Local, HInstruction>.from(other.directLocals),
        redirectionMapping = other.redirectionMapping,
        executableContext = other.executableContext,
        memberContext = other.memberContext,
        instanceType = other.instanceType,
        builder = other.builder,
        _scopeInfo = other._scopeInfo,
        _scopeInfoMember = other._scopeInfoMember,
        _localsMap = other._localsMap,
        _nativeData = other._nativeData,
        _interceptorData = other._interceptorData,
        activationVariables = other.activationVariables,
        cachedTypeOfThis = other.cachedTypeOfThis,
        cachedTypesOfCapturedVariables = other.cachedTypesOfCapturedVariables;

  /// Sets up the scope to use the scope and locals from [member].
  void setupScope(MemberEntity? member) {
    _scopeInfoMember = member;
    if (member != null) {
      _scopeInfo = _closedWorld.closureDataLookup.getScopeInfo(member);
      _localsMap = _globalLocalsMap.getLocalsMap(member);
    } else {
      _scopeInfo = null;
      _localsMap = null;
    }
  }

  /// Returns the member that currently defines the scope as setup in
  /// [setupScope].
  MemberEntity? get scopeMember => _scopeInfoMember;

  Local? get thisLocal => _scopeInfo?.thisLocal;

  /// Redirects accesses from element [from] to element [to]. The [to] element
  /// must be a boxed variable or a variable that is stored in a closure-field.
  void redirectElement(Local from, FieldEntity to) {
    assert(redirectionMapping[from] == null);
    redirectionMapping[from] = to;
    assert(isStoredInClosureField(from) || isBoxed(from));
  }

  HInstruction createBox(SourceInformation? sourceInformation) {
    HInstruction box = HCreateBox(_abstractValueDomain.nonNullType)
      ..sourceInformation = sourceInformation;
    builder.add(box);
    return box;
  }

  /// If the scope (function or loop) [node] has captured variables then this
  /// method creates a box and sets up the redirections.
  void enterScope(
      CapturedScope closureInfo, SourceInformation? sourceInformation,
      {bool forGenerativeConstructorBody = false, HInstruction? inlinedBox}) {
    // See if any variable in the top-scope of the function is captured. If yes
    // we need to create a box-object.
    if (!closureInfo.requiresContextBox) return;
    HInstruction box;
    final contentBox = closureInfo.contextBox!;
    // The scope has captured variables.
    if (forGenerativeConstructorBody) {
      // The box is passed as a parameter to a generative constructor body.
      box = inlinedBox ??
          builder.addParameter(contentBox, _abstractValueDomain.nonNullType);
    } else {
      box = createBox(sourceInformation);
    }
    // Add the box to the known locals.
    directLocals[contentBox] = box;
    // Make sure that accesses to the boxed locals go into the box. We also
    // need to make sure that parameters are copied into the box if necessary.
    closureInfo.forEachBoxedVariable(_localsMap!, (Local from, FieldEntity to) {
      // The [from] can only be a parameter for function-scopes and not
      // loop scopes.
      bool isParameter = (from as JLocal).isRegularParameter;
      if (isParameter && !forGenerativeConstructorBody) {
        // Now that the redirection is set up, the update to the local will
        // write the parameter value into the box.
        // Store the captured parameter in the box. Get the current value
        // before we put the redirection in place.
        // We don't need to update the local for a generative
        // constructor body, because it receives a box that already
        // contains the updates as the last parameter.
        HInstruction instruction = readLocal(from);
        redirectElement(from, to);
        updateLocal(from, instruction);
      } else {
        redirectElement(from, to);
      }
    });
  }

  /// Replaces the current box with a new box and copies over the given list
  /// of elements from the old box into the new box.
  void updateCaptureBox(Local currentBox, List<Local> toBeCopiedElements,
      SourceInformation? sourceInformation) {
    // Create a new box and copy over the values from the old box into the
    // new one.
    HInstruction oldBox = readLocal(currentBox);
    HInstruction newBox = createBox(sourceInformation);
    for (Local boxedVariable in toBeCopiedElements) {
      // [readLocal] uses the [currentBox] to find its box. By replacing it
      // behind its back we can still get to the old values.
      updateLocal(currentBox, oldBox);
      HInstruction oldValue = readLocal(boxedVariable);
      updateLocal(currentBox, newBox);
      updateLocal(boxedVariable, oldValue);
    }
    updateLocal(currentBox, newBox);
  }

  /// Documentation wanted -- johnniwinther
  ///
  /// Invariant: [function] must be an implementation element.
  void startFunction(MemberEntity element, Map<Local, AbstractValue> parameters,
      Set<Local> elidedParameters, SourceInformation? sourceInformation,
      {required bool isGenerativeConstructorBody}) {
    setupScope(element);

    CapturedScope scopeData =
        _closedWorld.closureDataLookup.getCapturedScope(element);

    parameters.forEach((Local local, AbstractValue typeMask) {
      if (isGenerativeConstructorBody) {
        if (scopeData.isBoxedVariable(_localsMap!, local)) {
          // The parameter will be a field in the box passed as the
          // last parameter. So no need to have it.
          return;
        }
      }
      HInstruction parameter = builder.addParameter(local, typeMask,
          isElided: elidedParameters.contains(local));
      builder.parameters[local] = parameter;
      directLocals[local] = parameter;
    });
    builder.elidedParameters = elidedParameters;

    enterScope(scopeData, sourceInformation,
        forGenerativeConstructorBody: isGenerativeConstructorBody);

    // When we remove the element model, we can just use the first check
    // (because the underlying elements won't all be *both* ScopeInfos and
    // ClosureRepresentationInfos).
    final scopeInfo = _scopeInfo;
    if (scopeInfo is ClosureRepresentationInfo && scopeInfo.isClosure) {
      ClosureRepresentationInfo closureData = scopeInfo;
      // If the freeVariableMapping is not empty, then this function was a
      // nested closure that captures variables. Redirect the captured
      // variables to fields in the closure.
      closureData.forEachFreeVariable(_localsMap!,
          (Local from, FieldEntity to) {
        redirectElement(from, to);
      });
      // Inside closure redirect references to itself to [:this:].
      HThis thisInstruction = HThis(closureData.thisLocal as ThisLocal?,
          _abstractValueDomain.nonNullType);
      builder.graph.thisInstruction = thisInstruction;
      builder.graph.entry.addAtEntry(thisInstruction);
      updateLocal(closureData.getClosureEntity(_localsMap!)!, thisInstruction);
    } else if (element.isInstanceMember) {
      // Once closures have been mapped to classes their instance members might
      // not have any thisElement if the closure was created inside a static
      // context.
      final thisLocal = scopeInfo!.thisLocal as ThisLocal;
      HThis thisInstruction = HThis(thisLocal, getTypeOfThis());
      builder.graph.thisInstruction = thisInstruction;
      builder.graph.entry.addAtEntry(thisInstruction);
      directLocals[thisLocal] = thisInstruction;
    }

    // If this method is an intercepted method, add the extra
    // parameter to it, that is the actual receiver for intercepted
    // classes, or the same as [:this:] for non-intercepted classes.
    final cls = element.enclosingClass;

    // When the class extends a native class, the instance is pre-constructed
    // and passed to the generative constructor factory function as a parameter.
    // Instead of allocating and initializing the object, the constructor
    // 'upgrades' the native subclass object by initializing the Dart fields.
    bool isNativeUpgradeFactory = element is ConstructorEntity &&
        element.isGenerativeConstructor &&
        _nativeData.isNativeOrExtendsNative(cls);
    if (_interceptorData.isInterceptedMethod(element)) {
      SyntheticLocal parameter = createLocal('receiver');
      HParameterValue value = HParameterValue(parameter, getTypeOfThis());
      builder.graph.explicitReceiverParameter = value;
      builder.graph.entry.addAfter(directLocals[scopeInfo!.thisLocal], value);
      if (builder.lastAddedParameter == null) {
        // If this is the first parameter inserted, make sure it stays first.
        builder.lastAddedParameter = value;
      }
      directLocals[scopeInfo.thisLocal!] = value;
    } else if (isNativeUpgradeFactory) {
      SyntheticLocal parameter = createLocal('receiver');
      // Unlike `this`, receiver is nullable since direct calls to generative
      // constructor call the constructor with `null`.
      HParameterValue value = HParameterValue(parameter,
          _closedWorld.abstractValueDomain.createNullableExact(cls!));
      builder.graph.explicitReceiverParameter = value;
      builder.graph.entry.addAtEntry(value);
      if (builder.lastAddedParameter == null) {
        // If this is the first parameter inserted, make sure it stays first.
        builder.lastAddedParameter = value;
      }
    }
  }

  /// Returns true if the local can be accessed directly. Boxed variables or
  /// captured variables that are stored in the closure-field return [:false:].
  bool isAccessedDirectly(Local local) {
    return !redirectionMapping.containsKey(local) &&
        !_scopeInfo!.localIsUsedInTryOrSync(_localsMap!, local);
  }

  bool isStoredInClosureField(Local local) {
    if (isAccessedDirectly(local)) return false;
    if (_scopeInfo is! ClosureRepresentationInfo) return false;
    final redirectTarget = redirectionMapping[local];
    if (redirectTarget == null) return false;
    return redirectTarget is JClosureField;
  }

  bool isBoxed(Local local) {
    if (isAccessedDirectly(local)) return false;
    if (isStoredInClosureField(local)) return false;
    return redirectionMapping.containsKey(local);
  }

  bool _isUsedInTryOrGenerator(Local local) {
    return _scopeInfo!.localIsUsedInTryOrSync(_localsMap!, local);
  }

  /// Returns an [HInstruction] for the given element. If the element is
  /// boxed or stored in a closure then the method generates code to retrieve
  /// the value.
  HInstruction readLocal(Local local, {SourceInformation? sourceInformation}) {
    if (isAccessedDirectly(local)) {
      HInstruction? value = directLocals[local];
      if (value == null) {
        if (local is TypeVariableLocal) {
          failedAt(
              CURRENT_ELEMENT_SPANNABLE,
              "Runtime type information not available for $local "
              "in ${directLocals.keys} for $executableContext.");
        } else {
          failedAt(
              local,
              "Cannot find value $local in ${directLocals.keys} for "
              "$executableContext.");
        }
      }
      if (sourceInformation != null) {
        value = HRef(value, sourceInformation);
        builder.add(value);
      }
      return value;
    } else if (isStoredInClosureField(local)) {
      final closureData = _scopeInfo as ClosureRepresentationInfo;
      final redirect = redirectionMapping[local]!;
      HInstruction receiver =
          readLocal(closureData.getClosureEntity(_localsMap!)!);
      AbstractValue type = local is BoxLocal
          ? _abstractValueDomain.nonNullType
          : getTypeOfCapturedVariable(redirect);
      HInstruction fieldGet = HFieldGet(
          redirect, receiver, type, sourceInformation,
          isAssignable: redirect.isAssignable);
      builder.add(fieldGet);
      return fieldGet;
    } else if (isBoxed(local)) {
      FieldEntity? redirect = redirectionMapping[local];
      // In the function that declares the captured variable the box is
      // accessed as direct local. Inside the nested closure the box is
      // accessed through a closure-field.
      // Calling [readLocal] makes sure we generate the correct code to get
      // the box.
      BoxLocal localBox = (redirect as JContextField).box;

      HInstruction box = readLocal(localBox);
      HInstruction lookup = HFieldGet(
          redirect, box, getTypeOfCapturedVariable(redirect), sourceInformation,
          isAssignable: redirect.isAssignable);
      builder.add(lookup);
      return lookup;
    } else {
      assert(_isUsedInTryOrGenerator(local));
      HLocalValue localValue = getLocal(local);
      HInstruction instruction = HLocalGet(local, localValue,
          _abstractValueDomain.dynamicType, sourceInformation);
      builder.add(instruction);
      return instruction;
    }
  }

  HInstruction readThis({SourceInformation? sourceInformation}) {
    return readLocal(_scopeInfo!.thisLocal!,
        sourceInformation: sourceInformation);
  }

  HLocalValue getLocal(Local local, {SourceInformation? sourceInformation}) {
    // If the element is a parameter, we already have a
    // HParameterValue for it. We cannot create another one because
    // it could then have another name than the real parameter. And
    // the other one would not know it is just a copy of the real
    // parameter.
    if (builder.parameters.containsKey(local)) {
      return builder.parameters[local] as HLocalValue;
    }

    return activationVariables.putIfAbsent(local, () {
      HLocalValue localValue =
          HLocalValue(local, _abstractValueDomain.nonNullType)
            ..sourceInformation = sourceInformation;
      builder.graph.entry.addAtExit(localValue);
      return localValue;
    });
  }

  Local getTypeVariableAsLocal(TypeVariableType type) {
    return typeVariableLocals[type.element] ??= TypeVariableLocal(type.element);
  }

  /// Sets the [element] to [value]. If the element is boxed or stored in a
  /// closure then the method generates code to set the value.
  void updateLocal(Local local, HInstruction value,
      {SourceInformation? sourceInformation}) {
    if (value is HRef) {
      HRef ref = value;
      value = ref.value;
    }
    assert(!isStoredInClosureField(local),
        "Local $local is stored in a closure field.");
    if (isAccessedDirectly(local)) {
      directLocals[local] = value;
    } else if (isBoxed(local)) {
      FieldEntity redirect = redirectionMapping[local]!;
      BoxLocal localBox = (redirect as JContextField).box;

      // The box itself could be captured, or be local. A local variable that
      // is captured will be boxed, but the box itself will be a local.
      // Inside the closure the box is stored in a closure-field and cannot
      // be accessed directly.
      HInstruction box = readLocal(localBox);
      builder.add(HFieldSet(redirect, box, value)
        ..sourceInformation = sourceInformation);
    } else {
      assert(_isUsedInTryOrGenerator(local));
      HLocalValue localValue = getLocal(local);
      builder.add(
          HLocalSet(local, localValue, value, _abstractValueDomain.dynamicType)
            ..sourceInformation = sourceInformation);
    }
  }

  /// This function, startLoop, must be called before visiting any children of
  /// the loop. In particular it needs to be called before executing the
  /// initializers.
  ///
  /// The [LocalsHandler] will make the boxes and updates at the right moment.
  /// The builder just needs to call [enterLoopBody] and [enterLoopUpdates]
  /// (for [ast.For] loops) at the correct places. For phi-handling
  /// [beginLoopHeader] and [endLoop] must also be called.
  ///
  /// The correct place for the box depends on the given loop. In most cases
  /// the box will be created when entering the loop-body: while, do-while, and
  /// for-in (assuming the call to [:next:] is inside the body) can always be
  /// constructed this way.
  ///
  /// Things are slightly more complicated for [ast.For] loops. If no declared
  /// loop variable is boxed then the loop-body approach works here too. If a
  /// loop-variable is boxed we need to introduce a new box for the
  /// loop-variable before we enter the initializer so that the initializer
  /// writes the values into the box. In any case we need to create the box
  /// before the condition since the condition could box the variable.
  /// Since the first box is created outside the actual loop we have a second
  /// location where a box is created: just before the updates. This is
  /// necessary since updates are considered to be part of the next iteration
  /// (and can again capture variables).
  ///
  /// For example the following Dart code prints 1 3 -- 3 4.
  ///
  ///     var fs = [];
  ///     for (var i = 0; i < 3; (f() { fs.add(f); print(i); i++; })()) {
  ///       i++;
  ///     }
  ///     print("--");
  ///     for (var i = 0; i < 2; i++) fs[i]();
  ///
  /// We solve this by emitting the following code (only for [ast.For] loops):
  ///  <Create box>    <== move the first box creation outside the loop.
  ///  <initializer>;
  ///  loop-entry:
  ///    if (!<condition>) goto loop-exit;
  ///    <body>
  ///    <update box>  // create a new box and copy the captured loop-variables.
  ///    <updates>
  ///    goto loop-entry;
  ///  loop-exit:
  void startLoop(
      CapturedLoopScope loopInfo, SourceInformation? sourceInformation) {
    if (loopInfo.hasBoxedLoopVariables) {
      // If there are boxed loop variables then we set up the box and
      // redirections already now. This way the initializer can write its
      // values into the box.
      // For other loops the box will be created when entering the body.
      enterScope(loopInfo, sourceInformation);
    }
  }

  /// Create phis at the loop entry for local variables (ready for the values
  /// from the back edge).  Populate the phis with the current values.
  void beginLoopHeader(HBasicBlock loopEntry) {
    // Create a copy because we modify the map while iterating over it.
    Map<Local, HInstruction> savedDirectLocals =
        Map<Local, HInstruction>.from(directLocals);

    // Create phis for all elements in the definitions environment.
    savedDirectLocals.forEach((Local local, HInstruction instruction) {
      if (isAccessedDirectly(local)) {
        // We know 'this' cannot be modified.
        if (local != _scopeInfo!.thisLocal) {
          HPhi phi = HPhi.singleInput(
              local, instruction, _abstractValueDomain.dynamicType);
          loopEntry.addPhi(phi);
          directLocals[local] = phi;
        } else {
          directLocals[local] = instruction;
        }
      }
    });
  }

  void enterLoopBody(
      CapturedLoopScope loopInfo, SourceInformation? sourceInformation) {
    // If there are no declared boxed loop variables then we did not create the
    // box before the initializer and we have to create the box now.
    if (!loopInfo.hasBoxedLoopVariables) {
      enterScope(loopInfo, sourceInformation);
    }
  }

  void enterLoopUpdates(
      CapturedLoopScope loopInfo, SourceInformation? sourceInformation) {
    // If there are declared boxed loop variables then the updates might have
    // access to the box and we must switch to a new box before executing the
    // updates.
    // In all other cases a new box will be created when entering the body of
    // the next iteration.
    if (loopInfo.hasBoxedLoopVariables) {
      updateCaptureBox(loopInfo.contextBox!,
          loopInfo.getBoxedLoopVariables(_localsMap!), sourceInformation);
    }
  }

  /// Goes through the phis created in beginLoopHeader entry and adds the
  /// input from the back edge (from the current value of directLocals) to them.
  void endLoop(HBasicBlock loopEntry) {
    // If the loop has an aborting body, we don't update the loop
    // phis.
    if (loopEntry.predecessors.length == 1) return;
    loopEntry.forEachPhi((HPhi phi) {
      final element = phi.sourceElement;
      final postLoopDefinition = directLocals[element]!;
      phi.addInput(postLoopDefinition);
    });
  }

  /// Merge [otherLocals] into this locals handler, creating phi-nodes when
  /// there is a conflict.
  /// If a phi node is necessary, it will use this handler's instruction as the
  /// first input, and the otherLocals instruction as the second.
  void mergeWith(LocalsHandler otherLocals, HBasicBlock joinBlock) {
    // If an element is in one map but not the other we can safely
    // ignore it. It means that a variable was declared in the
    // block. Since variable declarations are scoped the declared
    // variable cannot be alive outside the block. Note: this is only
    // true for nodes where we do joins.
    Map<Local, HInstruction> joinedLocals = {};
    otherLocals.directLocals.forEach((Local local, HInstruction instruction) {
      // We know 'this' cannot be modified.
      if (local == _scopeInfo!.thisLocal) {
        assert(directLocals[local] == instruction);
        joinedLocals[local] = instruction;
      } else {
        final mine = directLocals[local];
        if (mine == null) return;
        if (identical(instruction, mine)) {
          joinedLocals[local] = instruction;
        } else {
          final phi = HPhi.manyInputs(local, <HInstruction>[mine, instruction],
              _abstractValueDomain.dynamicType);
          joinBlock.addPhi(phi);
          joinedLocals[local] = phi;
        }
      }
    });
    directLocals = joinedLocals;
  }

  /// When control flow merges, this method can be used to merge several
  /// localsHandlers into a new one using phis.  The new localsHandler is
  /// returned.  Unless it is also in the list, the current localsHandler is not
  /// used for its values, only for its declared variables. This is a way to
  /// exclude local values from the result when they are no longer in scope.
  LocalsHandler mergeMultiple(
      List<LocalsHandler> localsHandlers, HBasicBlock joinBlock) {
    assert(localsHandlers.length > 0);
    if (localsHandlers.length == 1) return localsHandlers.single;
    Map<Local, HInstruction> joinedLocals = {};
    HInstruction? thisValue = null;
    directLocals.forEach((Local local, HInstruction instruction) {
      if (local != _scopeInfo!.thisLocal) {
        HPhi phi = HPhi.noInputs(local, _abstractValueDomain.dynamicType);
        joinedLocals[local] = phi;
        joinBlock.addPhi(phi);
      } else {
        // We know that "this" never changes, if it's there.
        // Save it for later. While merging, there is no phi for "this",
        // so we don't have to special case it in the merge loop.
        thisValue = instruction;
      }
    });
    for (LocalsHandler handler in localsHandlers) {
      handler.directLocals.forEach((Local local, HInstruction instruction) {
        final phi = joinedLocals[local] as HPhi?;
        if (phi != null) {
          phi.addInput(instruction);
        }
      });
    }
    if (thisValue != null) {
      // If there was a "this" for the scope, add it to the new locals.
      joinedLocals[_scopeInfo!.thisLocal!] = thisValue!;
    }

    // Remove locals that are not in all handlers.
    directLocals = {};
    joinedLocals.forEach((Local local, HInstruction instruction) {
      if (local != _scopeInfo!.thisLocal &&
          instruction.inputs.length != localsHandlers.length) {
        joinBlock.removePhi(instruction as HPhi);
      } else {
        directLocals[local] = instruction;
      }
    });
    return this;
  }

  AbstractValue? cachedTypeOfThis;

  AbstractValue getTypeOfThis() {
    AbstractValue? result = cachedTypeOfThis;
    if (result == null) {
      final local = _scopeInfo!.thisLocal as ThisLocal;
      ClassEntity cls = local.enclosingClass;
      if (_closedWorld.isUsedAsMixin(cls)) {
        // If the enclosing class is used as a mixin, [:this:] can be
        // of the class that mixins the enclosing class. These two
        // classes do not have a subclass relationship, so, for
        // simplicity, we mark the type as an interface type.
        result = _abstractValueDomain.createNonNullSubtype(cls);
      } else {
        result = _abstractValueDomain.createNonNullSubclass(cls);
      }
      cachedTypeOfThis = result;
    }
    return result;
  }

  Map<FieldEntity, AbstractValue> cachedTypesOfCapturedVariables = {};

  AbstractValue getTypeOfCapturedVariable(FieldEntity element) {
    return cachedTypesOfCapturedVariables.putIfAbsent(element, () {
      return AbstractValueFactory.inferredTypeForMember(
          element, _globalInferenceResults);
    });
  }

  /// Variables stored in the current activation. These variables are
  /// being updated in try/catch blocks, and should be
  /// accessed indirectly through [HLocalGet] and [HLocalSet].
  Map<Local, HLocalValue> activationVariables = {};

  SyntheticLocal createLocal(String name) {
    return SyntheticLocal(name, executableContext, memberContext);
  }
}

/// A synthetic local variable only used with the SSA graph.
///
/// For instance used for holding return value of function or the exception of a
/// try-catch statement.
class SyntheticLocal extends Local {
  @override
  final String name;
  final Entity executableContext;
  final MemberEntity memberContext;

  // Avoid slow Object.hashCode.
  @override
  final int hashCode = _nextHashCode = (_nextHashCode + 1).toUnsigned(30);
  static int _nextHashCode = 0;

  SyntheticLocal(this.name, this.executableContext, this.memberContext);

  @override
  toString() => 'SyntheticLocal($name)';
}
