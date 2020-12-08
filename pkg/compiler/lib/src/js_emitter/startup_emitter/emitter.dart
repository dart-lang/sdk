// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.startup_emitter;

import '../../../compiler_new.dart';
import '../../common.dart';
import '../../common/codegen.dart';
import '../../common/tasks.dart';
import '../../constants/values.dart';
import '../../deferred_load.dart' show OutputUnit;
import '../../dump_info.dart';
import '../../elements/entities.dart';
import '../../io/source_information.dart';
import '../../js/js.dart' as js;
import '../../js_backend/constant_emitter.dart';
import '../../js_backend/namer.dart';
import '../../js_backend/runtime_types_new.dart' show RecipeEncoder;
import '../../options.dart';
import '../../universe/codegen_world_builder.dart' show CodegenWorld;
import '../../world.dart' show JClosedWorld;
import '../js_emitter.dart' show Emitter, ModularEmitter;
import '../model.dart';
import '../native_emitter.dart';
import '../program_builder/program_builder.dart' show ProgramBuilder;
import 'fragment_merger.dart';
import 'model_emitter.dart';

abstract class ModularEmitterBase implements ModularEmitter {
  final ModularNamer _namer;

  ModularEmitterBase(this._namer);

  js.PropertyAccess globalPropertyAccessForClass(ClassEntity element) {
    js.Name name = _namer.globalPropertyNameForClass(element);
    js.PropertyAccess pa =
        new js.PropertyAccess(_namer.readGlobalObjectForClass(element), name);
    return pa;
  }

  js.PropertyAccess globalPropertyAccessForType(Entity element) {
    js.Name name = _namer.globalPropertyNameForType(element);
    js.PropertyAccess pa =
        new js.PropertyAccess(_namer.readGlobalObjectForType(element), name);
    return pa;
  }

  js.PropertyAccess globalPropertyAccessForMember(MemberEntity element) {
    js.Name name = _namer.globalPropertyNameForMember(element);
    js.PropertyAccess pa =
        new js.PropertyAccess(_namer.readGlobalObjectForMember(element), name);
    return pa;
  }

  @override
  js.PropertyAccess constructorAccess(ClassEntity element) {
    return globalPropertyAccessForClass(element);
  }

  @override
  js.Expression isolateLazyInitializerAccess(FieldEntity element) {
    return new js.PropertyAccess(_namer.readGlobalObjectForMember(element),
        _namer.lazyInitializerName(element));
  }

  @override
  js.PropertyAccess staticFunctionAccess(FunctionEntity element) {
    return globalPropertyAccessForMember(element);
  }

  @override
  js.PropertyAccess staticFieldAccess(FieldEntity element) {
    return globalPropertyAccessForMember(element);
  }

  @override
  js.PropertyAccess prototypeAccess(ClassEntity element,
      {bool hasBeenInstantiated}) {
    js.Expression constructor =
        hasBeenInstantiated ? constructorAccess(element) : typeAccess(element);
    return js.js('#.prototype', constructor);
  }

  @override
  js.Expression typeAccess(Entity element) {
    return globalPropertyAccessForType(element);
  }

  @override
  js.Name typeAccessNewRti(Entity element) {
    return _namer.globalPropertyNameForType(element);
  }

  @override
  js.Name typeVariableAccessNewRti(TypeVariableEntity element) {
    return _namer.globalNameForInterfaceTypeVariable(element);
  }

  @override
  js.Expression staticClosureAccess(FunctionEntity element) {
    return new js.Call(
        new js.PropertyAccess(_namer.readGlobalObjectForMember(element),
            _namer.staticClosureName(element)),
        const []);
  }

  @override
  String generateEmbeddedGlobalAccessString(String global) {
    // TODO(floitsch): don't use 'init' as global embedder storage.
    return 'init.$global';
  }
}

class ModularEmitterImpl extends ModularEmitterBase {
  final CodegenRegistry _registry;
  final ModularConstantEmitter _constantEmitter;

  ModularEmitterImpl(
      ModularNamer namer, this._registry, CompilerOptions options)
      : _constantEmitter = new ModularConstantEmitter(options),
        super(namer);

  @override
  js.Expression constantReference(ConstantValue constant) {
    if (constant.isFunction) {
      FunctionConstantValue function = constant;
      return staticClosureAccess(function.element);
    }
    js.Expression expression = _constantEmitter.generate(constant);
    if (expression != null) {
      return expression;
    }
    expression =
        new ModularExpression(ModularExpressionKind.constant, constant);
    _registry.registerModularExpression(expression);
    return expression;
  }

  @override
  js.Expression generateEmbeddedGlobalAccess(String global) {
    js.Expression expression = new ModularExpression(
        ModularExpressionKind.embeddedGlobalAccess, global);
    _registry.registerModularExpression(expression);
    return expression;
  }
}

class EmitterImpl extends ModularEmitterBase implements Emitter {
  final DiagnosticReporter _reporter;
  final JClosedWorld _closedWorld;
  final RecipeEncoder _rtiRecipeEncoder;
  final CompilerTask _task;
  ModelEmitter _emitter;
  final NativeEmitter _nativeEmitter;

  @override
  Program programForTesting;

  @override
  List<PreFragment> preDeferredFragmentsForTesting;

  EmitterImpl(
      CompilerOptions options,
      this._reporter,
      CompilerOutput outputProvider,
      DumpInfoTask dumpInfoTask,
      Namer namer,
      this._closedWorld,
      this._rtiRecipeEncoder,
      this._nativeEmitter,
      SourceInformationStrategy sourceInformationStrategy,
      this._task,
      bool shouldGenerateSourceMap)
      : super(namer) {
    _emitter = new ModelEmitter(
        options,
        _reporter,
        outputProvider,
        dumpInfoTask,
        namer,
        _closedWorld,
        _task,
        this,
        _nativeEmitter,
        sourceInformationStrategy,
        _rtiRecipeEncoder,
        shouldGenerateSourceMap);
  }

  @override
  Namer get _namer => super._namer;

  @override
  int emitProgram(ProgramBuilder programBuilder, CodegenWorld codegenWorld) {
    Program program = _task.measureSubtask('build program', () {
      return programBuilder.buildProgram();
    });
    if (retainDataForTesting) {
      programForTesting = program;
    }
    return _task.measureSubtask('emit program', () {
      var size = _emitter.emitProgram(program, codegenWorld);
      if (retainDataForTesting) {
        preDeferredFragmentsForTesting =
            _emitter.preDeferredFragmentsForTesting;
      }
      return size;
    });
  }

  @override
  js.Expression interceptorClassAccess(ClassEntity element) {
    return globalPropertyAccessForClass(element);
  }

  @override
  bool isConstantInlinedOrAlreadyEmitted(ConstantValue constant) {
    return _emitter.isConstantInlinedOrAlreadyEmitted(constant);
  }

  @override
  int compareConstants(ConstantValue a, ConstantValue b) {
    return _emitter.compareConstants(a, b);
  }

  @override
  js.Expression constantReference(ConstantValue value) {
    return _emitter.generateConstantReference(value);
  }

  @override
  js.Expression generateEmbeddedGlobalAccess(String global) {
    return js.js(generateEmbeddedGlobalAccessString(global));
  }

  @override
  // TODO(herhut): Use a single shared function.
  js.Expression generateFunctionThatReturnsNull() {
    return js.js('function() {}');
  }

  @override
  js.Expression interceptorPrototypeAccess(ClassEntity e) {
    return js.js('#.prototype', interceptorClassAccess(e));
  }

  @override
  int generatedSize(OutputUnit unit) {
    if (_emitter.omittedOutputUnits.contains(unit)) {
      return 0;
    }
    return _emitter.emittedOutputBuffers[unit].length;
  }
}
