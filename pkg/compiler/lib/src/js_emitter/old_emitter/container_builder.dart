// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

/// This class should morph into something that makes it easy to build
/// JavaScript representations of libraries, class-sides, and instance-sides.
/// Initially, it is just a placeholder for code that is moved from
/// [CodeEmitterTask].
class ContainerBuilder extends CodeEmitterHelper {

  void addMemberMethod(DartMethod method, ClassBuilder builder) {
    MethodElement member = method.element;
    String name = method.name;
    FunctionSignature parameters = member.functionSignature;
    jsAst.Expression code = method.code;
    bool needsStubs = method.parameterStubs.isNotEmpty;
    bool canBeApplied = method.canBeApplied;
    bool canBeReflected = method.canBeReflected;
    bool canTearOff = method.needsTearOff;
    String tearOffName = method.tearOffName;
    bool isClosure = method is InstanceMethod && method.isClosure;
    String superAlias = method is InstanceMethod ? method.aliasName : null;
    bool hasSuperAlias = superAlias != null;
    jsAst.Expression memberTypeExpression = method.functionType;

    bool needStructuredInfo =
        canTearOff || canBeReflected || canBeApplied || hasSuperAlias;

    emitter.interceptorEmitter.recordMangledNameOfMemberMethod(member, name);

    if (!needStructuredInfo) {
      compiler.dumpInfoTask.registerElementAst(member,
          builder.addProperty(name, code));

      for (ParameterStubMethod stub in method.parameterStubs) {
        assert(stub.callName == null);
        jsAst.Property property = builder.addProperty(stub.name, stub.code);
        compiler.dumpInfoTask.registerElementAst(member, property);
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
    // N+1. (Required parameter count << 1) + (member.isAccessor ? 1 : 0).
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
      expressions.add(new jsAst.LiteralString('"${superAlias}"'));
    }

    expressions.add(code);

    bool onlyNeedsSuperAlias =
        !(canTearOff || canBeReflected || canBeApplied || needsStubs);

    if (onlyNeedsSuperAlias) {
      jsAst.ArrayInitializer arrayInit =
            new jsAst.ArrayInitializer(expressions);
          compiler.dumpInfoTask.registerElementAst(member,
              builder.addProperty(name, arrayInit));
      return;
    }

    String callSelectorString = 'null';
    if (method.callName != null) {
      callSelectorString = '"${method.callName}"';
    }

    // On [requiredParameterCount], the lower bit is set if this method can be
    // called reflectively.
    int requiredParameterCount = parameters.requiredParameterCount << 1;
    if (member.isAccessor) requiredParameterCount++;

    int optionalParameterCount = parameters.optionalParameterCount << 1;
    if (parameters.optionalParametersAreNamed) optionalParameterCount++;

    // TODO(sra): Don't use LiteralString for non-strings.
    List tearOffInfo = [new jsAst.LiteralString(callSelectorString)];

    for (ParameterStubMethod stub in method.parameterStubs) {
      String invocationName = stub.name;
      emitter.interceptorEmitter
          .recordMangledNameOfMemberMethod(member, invocationName);

      expressions.add(stub.code);
      if (member.isInstanceMember) {
        expressions.add(js.string(invocationName));
      }
      String callName = stub.callName;
      String callSelectorString = (callName == null) ? 'null' : '"$callName"';
      tearOffInfo.add(new jsAst.LiteralString(callSelectorString));
    }

    expressions
        ..addAll(tearOffInfo)
        ..add((tearOffName == null || member.isAccessor)
              ? js("null") : js.string(tearOffName))
        ..add(js.number(requiredParameterCount))
        ..add(js.number(optionalParameterCount))
        ..add(memberTypeExpression == null ? js("null") : memberTypeExpression)
        ..addAll(task.metadataCollector
            .reifyDefaultArguments(member).map(js.number));

    if (canBeReflected || canBeApplied) {
      parameters.forEachParameter((Element parameter) {
        expressions.add(
            js.number(task.metadataCollector.reifyName(parameter.name)));
        if (backend.mustRetainMetadata) {
          Iterable<int> metadataIndices =
              parameter.metadata.map((MetadataAnnotation annotation) {
            ConstantValue constant =
                backend.constants.getConstantValueForMetadata(annotation);
            backend.constants.addCompileTimeConstantForEmission(constant);
            return task.metadataCollector.reifyMetadata(annotation);
          });
          expressions.add(new jsAst.ArrayInitializer(
              metadataIndices.map(js.number).toList()));
        }
      });
    }
    if (canBeReflected) {
      jsAst.LiteralString reflectionName;
      if (member.isConstructor) {
        String reflectionNameString = emitter.getReflectionName(member, name);
        reflectionName =
            new jsAst.LiteralString(
                '"new ${Elements.reconstructConstructorName(member)}"');
      } else {
        reflectionName =
            js.string(namer.privateName(member.memberName));
      }
      expressions
          ..add(reflectionName)
          ..addAll(task.metadataCollector
              .computeMetadata(member).map(js.number));
    } else if (isClosure && canBeApplied) {
      expressions.add(js.string(namer.privateName(member.memberName)));
    }

    jsAst.ArrayInitializer arrayInit =
      new jsAst.ArrayInitializer(expressions.toList());
    compiler.dumpInfoTask.registerElementAst(member,
        builder.addProperty(name, arrayInit));
  }

  void addMemberField(Field field, ClassBuilder builder) {
    // For now, do nothing.
  }
}
