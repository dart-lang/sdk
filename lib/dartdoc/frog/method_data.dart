// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class MethodCallData {
  MethodData data;

  MethodMember method;

  MethodGenerator _methodGenerator;

  MethodCallData(this.data, this.method);

  bool matches(MethodCallData other) {
    return method == other.method;
  }

  void run() {
    if (_methodGenerator !== null) return;

    _methodGenerator = new MethodGenerator(method, data.context);
    _methodGenerator.run();
  }
}


/**
 * Stores a reference to a single actual method body as well as
 * potential specializations for either concrete generic types or
 * optimizations for concrete argument types.
 */
class MethodData {
  MethodMember baseMethod;
  Statement body;
  bool needsTypeParams = false;

  CallingContext context;

  List<MethodCallData> _calls;

  MethodData(this.baseMethod, [this.context]): _calls = [] {
    body = baseMethod.definition.body;
    if (baseMethod.isConstructor) {
      needsTypeParams = true;
    }
  }

  void analyze() {
    var ma = new MethodAnalyzer(baseMethod, body);
    ma.analyze(context);
    // TODO(jimhug): Add support for specializing on type parameters.
    /*
    if (ma.hasTypeParams) {
      needsTypeParams = true;
    }
    */
  }

  Value eval(MethodMember method, Value newObject, Arguments args) {
    if (method !== baseMethod) {
      if (!needsTypeParams) method = baseMethod;
    }

    // TODO(jimhug): Reconcile with run method below.
    var gen = new MethodGenerator(method, context);
    return gen.evalBody(newObject, args);
  }


  invokeCall(MethodCallData callData) {
    for (var cd in _calls) {
      if (cd.matches(callData)) {
        return cd.run();
      }
    }
    _calls.add(callData);
    callData.run();
  }

  void run(MethodMember method) {
    if (body === null && !method.isConstructor && !method.isNative) return;

    if (method !== baseMethod) {
      if (!needsTypeParams) method = baseMethod;
    }

    var callData = new MethodCallData(this, method);
    method.declaringType.genericType.markUsed();

    invokeCall(callData);
  }

  bool writeDefinition(MethodMember method, CodeWriter writer) {
   var gen = null;
   // TODO(jimhug): Handle multiple matches.
   for (var cd in _calls) {
      if (cd.method == method) {
        gen = cd._methodGenerator;
      }
    }

    if (gen != null) {
      if (method.isNative && method == baseMethod) {
        if (!method.hasNativeBody) return true;
        gen.writer = new CodeWriter();
        gen.writer.write(method.definition.nativeBody);
        gen._paramCode = map(method.parameters, (p) => p.name);
      }
      gen.writeDefinition(writer, null);
      return true;
    } else {
      return false;
    }
  }

  void createFunction(CodeWriter writer) {
    this.run(baseMethod);
    writeDefinition(baseMethod, writer);
  }

  //TODO(jimhug): context belongs in constructor, not here.
  Value createLambda(LambdaExpression node, CallingContext context) {
    //TODO(jimhug): Only create the lambda if it is needed.
    final lambdaGen = new MethodGenerator(baseMethod, context);
    if (baseMethod.name != '') {
      // Note: we don't want to put this in our enclosing scope because the
      // name shouldn't be visible except inside the lambda. We also don't want
      // to put the name directly in the lambda's scope because parameters are
      // allowed to shadow it. So we create an extra scope for it to go into.
      lambdaGen._scope.create(baseMethod.name, baseMethod.functionType,
        baseMethod.definition.span, isFinal:true);
      lambdaGen._pushBlock(baseMethod.definition);
    }

    _calls.add(new MethodCallData(this, baseMethod));

    lambdaGen.run();
    if (baseMethod.name != '') {
      lambdaGen._popBlock(baseMethod.definition);
    }

    final writer = new CodeWriter();
    lambdaGen.writeDefinition(writer, node);
    return new Value(baseMethod.functionType, writer.text,
      baseMethod.definition.span);
  }
}
