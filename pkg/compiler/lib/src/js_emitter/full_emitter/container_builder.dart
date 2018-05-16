// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.full_emitter.container_builder;

import '../../deferred_load.dart' show OutputUnit;
import '../../elements/elements.dart' show Element, MethodElement;
import '../../elements/entities.dart';
import '../../elements/names.dart';
import '../../js/js.dart' as jsAst;
import '../../js/js.dart' show js;
import '../js_emitter.dart' hide Emitter, EmitterFactory;
import '../model.dart';
import 'emitter.dart';

/// This class should morph into something that makes it easy to build
/// JavaScript representations of libraries, class-sides, and instance-sides.
/// Initially, it is just a placeholder for code that is moved from
/// [CodeEmitterTask].
class ContainerBuilder extends CodeEmitterHelper {
  ContainerBuilder();

  void addMemberMethod(DartMethod method, ClassBuilder builder) {
    FunctionEntity member = method.element;
    OutputUnit outputUnit = backend.outputUnitData.outputUnitForMember(member);
    jsAst.Name name = method.name;
    ParameterStructure parameters = member.parameterStructure;
    jsAst.Expression code = method.code;
    bool needsStubs = method.parameterStubs.isNotEmpty;
    bool canBeApplied = method.canBeApplied;
    bool canTearOff = method.needsTearOff;
    jsAst.Name tearOffName = method.tearOffName;
    jsAst.Name superAlias = method is InstanceMethod ? method.aliasName : null;
    bool hasSuperAlias = superAlias != null;
    jsAst.Expression memberTypeExpression = method.functionType;
    bool needStructuredInfo = canTearOff || canBeApplied || hasSuperAlias;

    bool isIntercepted = false;
    if (method is InstanceMethod) {
      isIntercepted = method.isIntercepted;
    }

    emitter.interceptorEmitter.recordMangledNameOfMemberMethod(member, name);

    if (!needStructuredInfo) {
      compiler.dumpInfoTask
          .registerEntityAst(member, builder.addProperty(name, code));

      for (ParameterStubMethod stub in method.parameterStubs) {
        assert(stub.callName == null);
        jsAst.Property property = builder.addProperty(stub.name, stub.code);
        compiler.dumpInfoTask.registerEntityAst(member, property);
        emitter.interceptorEmitter
            .recordMangledNameOfMemberMethod(member, stub.name);
      }
      return;
    }
    emitter.needsStructuredMemberInfo = true;

    // This element is needed for reflection or needs additional stubs or has a
    // super alias. So we need to retain additional information.

    // The information is stored in an array with this format:
    //
    // 1.   The alias name for this function (optional).
    // 2.   The JS function for this member.
    // 3.   First stub.
    // 4.   Name of first stub.
    // ...
    // M.   Call name of this member.
    // M+1. Call name of first stub.
    // ...
    // N.   Getter name for tearOff.
    // N+1. (Required parameter count << 2) + (member.isAccessor ? 2 : 0) +
    //        (isIntercepted ? 1 : 0)
    // N+2. (Optional parameter count << 1) +
    //                      (parameters.optionalParametersAreNamed ? 1 : 0).
    // N+3. Index to function type in constant pool.
    // N+4. First default argument.
    // ...
    // O.   First parameter name (if needed for reflection or Function.apply).
    // ...
    // P.   Unmangled name (if reflectable).
    // P+1. First metadata (if reflectable).
    // ...
    // TODO(ahe): Consider one of the parameter counts can be replaced by the
    // length property of the JavaScript function object.

    List<jsAst.Expression> expressions = <jsAst.Expression>[];

    // Create the optional aliasing entry if this method is called via super.
    if (hasSuperAlias) {
      expressions.add(js.quoteName(superAlias));
    }

    expressions.add(code);

    bool onlyNeedsSuperAlias = !(canTearOff || canBeApplied || needsStubs);

    if (onlyNeedsSuperAlias) {
      jsAst.ArrayInitializer arrayInit =
          new jsAst.ArrayInitializer(expressions);
      compiler.dumpInfoTask
          .registerEntityAst(member, builder.addProperty(name, arrayInit));
      return;
    }

    jsAst.Literal callSelectorString;
    if (method.callName == null) {
      callSelectorString = new jsAst.LiteralNull();
    } else {
      callSelectorString = js.quoteName(method.callName);
    }

    // On [requiredParameterCount], the lower bit is set if this method can be
    // called reflectively.
    int requiredParameterCount = parameters.requiredParameters << 2;
    if (member.isGetter || member.isSetter) requiredParameterCount += 2;
    if (isIntercepted) requiredParameterCount += 1;

    int optionalParameterCount = parameters.optionalParameters << 1;
    if (parameters.namedParameters.isNotEmpty) optionalParameterCount++;

    var tearOffInfo = <jsAst.Expression>[callSelectorString];

    for (ParameterStubMethod stub in method.parameterStubs) {
      jsAst.Name invocationName = stub.name;
      emitter.interceptorEmitter
          .recordMangledNameOfMemberMethod(member, invocationName);

      expressions.add(stub.code);
      if (member.isInstanceMember) {
        expressions.add(js.quoteName(invocationName));
      }
      jsAst.Name callName = stub.callName;
      jsAst.Literal callSelectorString =
          (callName == null) ? new jsAst.LiteralNull() : js.quoteName(callName);
      tearOffInfo.add(callSelectorString);
    }

    expressions
      ..addAll(tearOffInfo)
      ..add((tearOffName == null || member.isGetter || member.isSetter)
          ? js("null")
          : js.quoteName(tearOffName))
      ..add(js.number(requiredParameterCount))
      ..add(js.number(optionalParameterCount))
      ..add(memberTypeExpression == null ? js("null") : memberTypeExpression);

    if (canBeApplied) {
      expressions.addAll(
          task.metadataCollector.reifyDefaultArguments(member, outputUnit));

      if (member is MethodElement) {
        member.functionSignature.forEachParameter((Element parameter) {
          expressions.add(
              task.metadataCollector.reifyName(parameter.name, outputUnit));
        });
      } else {
        codegenWorldBuilder.forEachParameter(member, (_, String name, _2) {
          expressions.add(task.metadataCollector.reifyName(name, outputUnit));
        });
        // TODO(redemption): Support retaining mirrors metadata.
      }
    }
    Name memberName = member.memberName;
    expressions.add(js.string(namer.privateName(memberName)));

    jsAst.ArrayInitializer arrayInit =
        new jsAst.ArrayInitializer(expressions.toList());
    compiler.dumpInfoTask
        .registerEntityAst(member, builder.addProperty(name, arrayInit));
  }

  void addMemberField(Field field, ClassBuilder builder) {
    // For now, do nothing.
  }
}
