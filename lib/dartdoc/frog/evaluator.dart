// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


#import('file_system.dart');
#import('lang.dart');

interface JsEvaluator {
  var eval(String source);
}

class Evaluator {
  JsEvaluator _jsEvaluator;
  static String _prelude;
  Library _lib;

  static void initWorld(String homedir, List<String> args, FileSystem files) {
    parseOptions(homedir, args, files);
    options.forceDynamic = true;
    options.compileAll = true;

    initializeWorld(files);
    world.process();
    world.resolveAll();

    world.gen = new WorldGenerator(null, new CodeWriter());
    world.gen.markLibrariesUsed([world.coreimpl, world.corelib]);

    world.gen.writeTypes(world.coreimpl);
    world.gen.writeTypes(world.corelib);
    world.gen.writeGlobals();
    _prelude = world.gen.writer.text;

    // Set these here so that we can compile the corelib without its errors
    // killing us
    options.throwOnErrors = true;
    options.throwOnFatal = true;
  }

  _removeMember(String name) {
    _lib.topType._resolvedMembers.remove(name);
    _lib.topType.members.remove(name);
    // Don't rely on the existing member's jsname, because the existing member
    // may be null but the jsname may still be defined. This can happen if
    // multiple Evaluators are instantiated against the same world.
    var jsname = '${_lib.jsname}_$name';
    world._topNames.remove(name);
    world._topNames.remove(jsname);
  }

  Evaluator(JsEvaluator this._jsEvaluator) {
    if (_prelude == null) {
      throw new UnsupportedOperationException(
          "Must call Evaluator.initWorld before creating a Evaluator.");
    }
    this._jsEvaluator.eval(_prelude);
    _lib = new Library(new SourceFile("_ifrog_", ""));
    _lib.imports.add(new LibraryImport(world.corelib));
    _lib.resolve();
  }

  void _ensureVariableDefined(Identifier name,
      [List<Token> modifiers = const [], TypeReference type = null]) {
    var member = _lib.topType.getMember(name.name);
    if (member is FieldMember || member is PropertyMember) return;
    _removeMember(name.name);
    _lib.topType.addField(
        new VariableDefinition(modifiers, type, [name], [null], name.span));
    _lib.topType.getMember(name.name).resolve();
  }

  var eval(String dart) {
    var source = new SourceFile("_ifrog_", dart);
    world.gen.writer = new CodeWriter();

    var code;
    var parsed = new Parser(source, throwOnIncomplete: true,
        optionalSemicolons: true).evalUnit();
    var method = new MethodMember("_ifrog_dummy", _lib.topType, null);
    var methGen = new MethodGenerator(method, null);

    if (parsed is ExpressionStatement) {
      var body = parsed.body;
      // Auto-declare variables that haven't been declared yet, so users can
      // write "a = 1" rather than "var a = 1"
      if (body is BinaryExpression && body.op.kind == TokenKind.ASSIGN &&
          body.x is VarExpression) {
        _ensureVariableDefined(body.x.dynamic.name);
      }
      code = body.visit(methGen).code;

    } else if (parsed is VariableDefinition) {
      var assignments = <Statement>[];
      zip(parsed.names, parsed.values, (name, value) {
        _ensureVariableDefined(name, parsed.modifiers, parsed.type);
        var expr = new BinaryExpression(
            new Token.fake(TokenKind.ASSIGN, parsed.span),
            new VarExpression(name, name.span), value, parsed.span);
        new ExpressionStatement(expr, parsed.span).visit(methGen);
      });
      code = methGen.writer.text;

    } else if (parsed is FunctionDefinition) {
      var methodName = parsed.name.name;
      _removeMember(methodName);
      _lib.topType.addMethod(methodName, parsed);
      MethodMember definedMethod = _lib.topType.getMember(methodName);
      definedMethod.resolve();
      var definedMethGen = new MethodGenerator(definedMethod, null);
      definedMethGen.run();
      definedMethGen.writeDefinition(world.gen.writer, null);
      code = world.gen.writer.text;
    } else if (parsed is TypeDefinition) {
      _removeMember(parsed.name.name);
      parsed.visit(new _LibraryVisitor(_lib));
      var type = _lib.findTypeByName(parsed.name.name);
      type.resolve();
      world.gen.markTypeUsed(type);
      world.gen.writeType(type);
      code = '${world.gen.writer.text}; undefined';
    } else {
      parsed.visit(methGen);
      code = methGen.writer.text;
    }

    world.gen.writer = new CodeWriter();
    world.gen.writeAllDynamicStubs([world.coreimpl, world.corelib, _lib]);

    return this._jsEvaluator.eval('${world.gen.writer.text}; $code');
  }
}
