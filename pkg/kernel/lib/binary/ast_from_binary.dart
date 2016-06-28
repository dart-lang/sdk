// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.ast_from_binary;

import '../ast.dart';
import 'tag.dart';
import 'loader.dart';
import 'dart:convert';

class ParseError {
  String filename;
  int byteIndex;
  String message;
  String path;

  ParseError(this.message, {this.filename, this.byteIndex, this.path});

  String toString() => '$filename:$byteIndex: $message at $path';
}

class BinaryBuilder {
  final BinaryReferenceLoader loader;
  final List<Library> importTable = <Library>[];
  final List<VariableDeclaration> variableStack = <VariableDeclaration>[];
  final List<LabeledStatement> labelStack = <LabeledStatement>[];
  final List<SwitchCase> switchCaseStack = <SwitchCase>[];
  final List<TypeParameter> typeParameterStack = <TypeParameter>[];
  final String filename;
  final List<int> _bytes;
  int _byteIndex = 0;
  Library _currentLibrary;
  List<String> _stringTable;

  // If something goes wrong, this list should indicate what library,
  // class, and member was being built.
  List<String> debugPath = <String>[];

  BinaryBuilder(this.loader, this._bytes, [this.filename]);

  fail(String message) {
    throw new ParseError(message,
        byteIndex: _byteIndex, filename: filename, path: debugPath.join('::'));
  }

  int readByte() => _bytes[_byteIndex++];

  int readUInt() {
    var byte = readByte();
    if (byte & 0x80 == 0) {
      // 0xxxxxxx
      return byte;
    } else if (byte & 0x40 == 0) {
      // 10xxxxxx
      return ((byte & 0x3F) << 8) | readByte();
    } else {
      // 11xxxxxx
      return ((byte & 0x3F) << 24) |
          (readByte() << 16) |
          (readByte() << 8) |
          readByte();
    }
  }

  int readMagicWord() {
    return (readByte() << 24) |
        (readByte() << 16) |
        (readByte() << 8) |
        readByte();
  }

  String readStringEntry() {
    int numBytes = readUInt();
    String string =
        const Utf8Decoder().convert(_bytes, _byteIndex, _byteIndex + numBytes);
    _byteIndex += numBytes;
    return string;
  }

  void readStringTable() {
    int length = readUInt();
    _stringTable = new List<String>(length);
    for (int i = 0; i < length; ++i) {
      _stringTable[i] = readStringEntry();
    }
  }

  String readStringReference() {
    return _stringTable[readUInt()];
  }

  String readStringOrNullIfEmpty() {
    var string = readStringReference();
    return string.isEmpty ? null : string;
  }

  bool readAndCheckOptionTag() {
    int tag = readByte();
    if (tag == Tag.Nothing) {
      return false;
    } else if (tag == Tag.Something) {
      return true;
    } else {
      throw fail('Invalid Option tag: $tag');
    }
  }

  void _fillTreeNodeList(
      List<TreeNode> list, TreeNode buildObject(), TreeNode parent) {
    list.length = readUInt();
    for (int i = 0; i < list.length; ++i) {
      list[i] = buildObject()..parent = parent;
    }
  }

  void _fillNonTreeNodeList(List<Node> list, Node buildObject()) {
    list.length = readUInt();
    for (int i = 0; i < list.length; ++i) {
      list[i] = buildObject();
    }
  }

  TreeNode readProgramOrLibraryFile(Library makeLibrary()) {
    int magic = readMagicWord();
    switch (magic) {
      case Tag.LibraryFile:
        var library = makeLibrary();
        readUntaggedLibraryFile(library);
        return library;
      case Tag.ProgramFile:
        return readUntaggedProgramFile();
      default:
        throw fail('This is not a binary dart file. '
            'Magic number was: ${magic.toRadixString(16)}');
    }
  }

  void readLibraryFile(Library library) {
    int magic = readMagicWord();
    if (magic != Tag.LibraryFile) {
      if (magic == Tag.ProgramFile) {
        throw fail('This is a program file, not a library.');
      }
      throw fail('This is not a binary dart file. '
          'Magic number was: ${magic.toRadixString(16)}');
    }
    readUntaggedLibraryFile(library);
  }

  void readUntaggedLibraryFile(Library library) {
    this._currentLibrary = library;
    readStringTable();
    readImportTable();
    readLibrary();
  }

  Program readProgramFile() {
    int magic = readMagicWord();
    if (magic != Tag.ProgramFile) {
      if (magic == Tag.LibraryFile) {
        throw fail('This is a library file, not a program.');
      }
      throw fail('This is not a binary dart file. '
          'Magic number was: ${magic.toRadixString(16)}');
    }
    return readUntaggedProgramFile();
  }

  Program readUntaggedProgramFile() {
    readStringTable();
    importTable.length = readUInt();
    for (int i = 0; i < importTable.length; ++i) {
      importTable[i] = new Library(null);
    }
    for (int i = 0; i < importTable.length; ++i) {
      _currentLibrary = importTable[i];
      readLibrary();
    }
    var mainMethod = readMemberReference();
    return new Program(importTable)..mainMethod = mainMethod;
  }

  void readImportTable() {
    importTable.length = readUInt();
    if (importTable.isEmpty) {
      throw fail('File must contain at least one import (the self reference)');
    }
    String self = readStringReference();
    if (!self.isEmpty) {
      throw fail('First import must be empty (the self reference)');
    }
    importTable[0] = _currentLibrary;
    for (int i = 1; i < importTable.length; ++i) {
      var importPath = readStringReference();
      importTable[i] = loader.getLibraryReference(_currentLibrary, importPath);
    }
  }

  void _fillLazilyLoadedList(
      List<TreeNode> list, void buildObject(int tag, int index)) {
    int length = readUInt();
    list.length = length;
    for (int i = 0; i < length; ++i) {
      int tag = readByte();
      buildObject(tag, i);
    }
  }

  Library readLibraryReference() {
    int index = readUInt();
    return importTable[index];
  }

  Class readClassReference() {
    int tag = readByte();
    var library = readLibraryReference();
    int index = readUInt();
    return loader.getClassReference(library, tag, index);
  }

  Member readMemberReference() {
    int tag = readByte();
    switch (tag) {
      case Tag.LibraryFieldReference:
      case Tag.LibraryProcedureReference:
        var library = readLibraryReference();
        var index = readUInt();
        return loader.getLibraryMemberReference(library, tag, index);

      case Tag.ClassFieldReference:
      case Tag.ClassConstructorReference:
      case Tag.ClassProcedureReference:
        var classNode = readClassReference();
        var index = readUInt();
        return loader.getClassMemberReference(classNode, tag, index);

      default:
        throw fail('Invalid member reference tag: $tag');
    }
  }

  Name readName() {
    String text = readStringReference();
    if (text.isNotEmpty && text[0] == '_') {
      return new Name(text, readLibraryReference());
    } else {
      return new Name(text);
    }
  }

  Uri readImportUri() {
    return Uri.parse(readStringReference());
  }

  void readLibrary() {
    _currentLibrary.name = readStringOrNullIfEmpty();
    _currentLibrary.importUri = readImportUri();
    debugPath.add(_currentLibrary.name ??
        _currentLibrary.importUri?.toString() ??
        'library');
    _fillLazilyLoadedList(_currentLibrary.classes, (int tag, int index) {
      readClass(loader.getClassReference(_currentLibrary, tag, index), tag);
    });
    _fillLazilyLoadedList(_currentLibrary.fields, (int tag, int index) {
      readField(
          loader.getLibraryMemberReference(_currentLibrary, tag, index), tag);
    });
    _fillLazilyLoadedList(_currentLibrary.procedures, (int tag, int index) {
      readProcedure(
          loader.getLibraryMemberReference(_currentLibrary, tag, index), tag);
    });
    debugPath.removeLast();
  }

  void readClass(Class node, int tag) {
    assert(node != null);
    switch (tag) {
      case Tag.NormalClass:
        readNormalClass(node);
        break;
      case Tag.MixinClass:
        readMixinClass(node);
        break;
      default:
        throw fail('Invalid class tag: $tag');
    }
  }

  void readNormalClass(NormalClass node) {
    int flags = readByte();
    node.isAbstract = flags & 0x1 != 0;
    node.name = readStringOrNullIfEmpty();
    debugPath.add(node.name ?? 'normal-class');
    readAndPushTypeParameterList(node.typeParameters, node);
    node.supertype = readDartTypeOption();
    _fillNonTreeNodeList(node.implementedTypes, readDartType);
    _fillLazilyLoadedList(node.fields, (int tag, int index) {
      readField(loader.getClassMemberReference(node, tag, index), tag);
    });
    _fillLazilyLoadedList(node.constructors, (int tag, int index) {
      readConstructor(loader.getClassMemberReference(node, tag, index), tag);
    });
    _fillLazilyLoadedList(node.procedures, (int tag, int index) {
      readProcedure(loader.getClassMemberReference(node, tag, index), tag);
    });
    typeParameterStack.length = 0;
    debugPath.removeLast();
  }

  void readMixinClass(MixinClass node) {
    int flags = readByte();
    node.isAbstract = flags & 0x1 != 0;
    node.name = readStringOrNullIfEmpty();
    debugPath.add(node.name ?? 'mixin-class');
    readAndPushTypeParameterList(node.typeParameters, node);
    node.supertype = readDartType();
    node.mixedInType = readDartType();
    _fillNonTreeNodeList(node.implementedTypes, readDartType);
    _fillLazilyLoadedList(node.constructors, (int tag, int index) {
      readConstructor(loader.getClassMemberReference(node, tag, index), tag);
    });
    typeParameterStack.length = 0;
    debugPath.removeLast();
  }

  void readField(Field node, int tag) {
    // Note: as with readProcedure and readConstructor, the tag parameter
    // is unused, but we pass it in to clarify that the tag has already been
    // consumed from the input.
    assert(tag == Tag.Field);
    node.flags = readByte();
    node.name = readName();
    debugPath.add(node.name?.name ?? 'field');
    node.type = readDartType();
    node.initializer = readExpressionOption();
    node.initializer?.parent = node;
    debugPath.removeLast();
  }

  void readConstructor(Constructor node, int tag) {
    assert(tag == Tag.Constructor);
    node.flags = readByte();
    node.name = readName();
    debugPath.add(node.name?.name ?? 'constructor');
    node.function = readFunctionNode()..parent = node;
    pushVariableDeclarations(node.function.positionalParameters);
    pushVariableDeclarations(node.function.namedParameters);
    _fillTreeNodeList(node.initializers, readInitializer, node);
    variableStack.length = 0;
    debugPath.removeLast();
  }

  void readProcedure(Procedure node, int tag) {
    assert(tag == Tag.Procedure);
    int kindIndex = readByte();
    node.kind = ProcedureKind.values[kindIndex];
    node.flags = readByte();
    node.name = readName();
    debugPath.add(node.name?.name ?? 'procedure');
    node.function = readFunctionNodeOption();
    node.function?.parent = node;
    debugPath.removeLast();
  }

  Initializer readInitializer() {
    int tag = readByte();
    switch (tag) {
      case Tag.InvalidInitializer:
        return new InvalidInitializer();
      case Tag.FieldInitializer:
        return new FieldInitializer(readMemberReference(), readExpression());
      case Tag.SuperInitializer:
        return new SuperInitializer(readMemberReference(), readArguments());
      case Tag.RedirectingInitializer:
        return new RedirectingInitializer(
            readMemberReference(), readArguments());
      case Tag.LocalInitializer:
        return new LocalInitializer(readAndPushVariableDeclaration());
      default:
        throw fail('Invalid initializer tag: $tag');
    }
  }

  FunctionNode readFunctionNodeOption() {
    return readAndCheckOptionTag() ? readFunctionNode() : null;
  }

  FunctionNode readFunctionNode() {
    AsyncMarker asyncMarker = AsyncMarker.values[readByte()];
    int typeParameterStackHeight = typeParameterStack.length;
    var typeParameters = readAndPushTypeParameterList();
    var requiredParameterCount = readUInt();
    int variableStackHeight = variableStack.length;
    var positional = readAndPushVariableDeclarationList();
    var named = readAndPushVariableDeclarationList();
    var returnType = readDartType();
    var body = readStatementOption();
    variableStack.length = variableStackHeight;
    typeParameterStack.length = typeParameterStackHeight;
    return new FunctionNode(body,
        typeParameters: typeParameters,
        requiredParameterCount: requiredParameterCount,
        positionalParameters: positional,
        namedParameters: named,
        returnType: returnType,
        asyncMarker: asyncMarker);
  }

  void pushVariableDeclaration(VariableDeclaration variable) {
    variableStack.add(variable);
  }

  void pushVariableDeclarations(List<VariableDeclaration> variables) {
    variableStack.addAll(variables);
  }

  VariableDeclaration readVariableReference() {
    int index = readUInt();
    if (index >= variableStack.length) {
      throw fail('Invalid variable index: $index');
    }
    return variableStack[index];
  }

  String logicalOperatorToString(int index) {
    switch (index) {
      case 0:
        return '&&';
      case 1:
        return '||';
      case 2:
        return '??';
      default:
        throw fail('Invalid logical operator index: $index');
    }
  }

  List<Expression> readExpressionList() {
    return new List<Expression>.generate(readUInt(), (i) => readExpression());
  }

  Expression readExpressionOption() {
    return readAndCheckOptionTag() ? readExpression() : null;
  }

  Expression readExpression() {
    int tagByte = readByte();
    int tag = tagByte & Tag.SpecializedTagHighBit == 0
        ? tagByte
        : (tagByte & Tag.SpecializedTagMask);
    switch (tag) {
      case Tag.InvalidExpression:
        return new InvalidExpression();
      case Tag.VariableGet:
        return new VariableGet(readVariableReference());
      case Tag.SpecializedVariableGet:
        int index = tagByte & Tag.SpecializedPayloadMask;
        return new VariableGet(variableStack[index]);
      case Tag.VariableSet:
        return new VariableSet(readVariableReference(), readExpression());
      case Tag.SpecializedVariableSet:
        int index = tagByte & Tag.SpecializedPayloadMask;
        return new VariableSet(variableStack[index], readExpression());
      case Tag.PropertyGet:
        return new PropertyGet(readExpression(), readName());
      case Tag.PropertySet:
        return new PropertySet(readExpression(), readName(), readExpression());
      case Tag.SuperPropertyGet:
        return new SuperPropertyGet(readMemberReference());
      case Tag.SuperPropertySet:
        return new SuperPropertySet(readMemberReference(), readExpression());
      case Tag.StaticGet:
        return new StaticGet(readMemberReference());
      case Tag.StaticSet:
        return new StaticSet(readMemberReference(), readExpression());
      case Tag.MethodInvocation:
        return new MethodInvocation(
            readExpression(), readName(), readArguments());
      case Tag.SuperMethodInvocation:
        return new SuperMethodInvocation(
            readMemberReference(), readArguments());
      case Tag.StaticInvocation:
        return new StaticInvocation(readMemberReference(), readArguments(),
            isConst: false);
      case Tag.ConstStaticInvocation:
        return new StaticInvocation(readMemberReference(), readArguments(),
            isConst: true);
      case Tag.ConstructorInvocation:
        return new ConstructorInvocation(readMemberReference(), readArguments(),
            isConst: false);
      case Tag.ConstConstructorInvocation:
        return new ConstructorInvocation(readMemberReference(), readArguments(),
            isConst: true);
      case Tag.Not:
        return new Not(readExpression());
      case Tag.LogicalExpression:
        return new LogicalExpression(readExpression(),
            logicalOperatorToString(readByte()), readExpression());
      case Tag.ConditionalExpression:
        return new ConditionalExpression(
            readExpression(), readExpression(), readExpression());
      case Tag.StringConcatenation:
        return new StringConcatenation(readExpressionList());
      case Tag.IsExpression:
        return new IsExpression(readExpression(), readDartType());
      case Tag.AsExpression:
        return new AsExpression(readExpression(), readDartType());
      case Tag.StringLiteral:
        return new StringLiteral(readStringReference());
      case Tag.SpecializedIntLiteral:
        int biasedValue = tagByte & Tag.SpecializedPayloadMask;
        return new IntLiteral(biasedValue - Tag.SpecializedIntLiteralBias);
      case Tag.PositiveIntLiteral:
        return new IntLiteral(readUInt());
      case Tag.NegativeIntLiteral:
        return new IntLiteral(-readUInt());
      case Tag.BigIntLiteral:
        return new IntLiteral(int.parse(readStringReference()));
      case Tag.DoubleLiteral:
        return new DoubleLiteral(double.parse(readStringReference()));
      case Tag.TrueLiteral:
        return new BoolLiteral(true);
      case Tag.FalseLiteral:
        return new BoolLiteral(false);
      case Tag.NullLiteral:
        return new NullLiteral();
      case Tag.SymbolLiteral:
        return new SymbolLiteral(readStringReference());
      case Tag.TypeLiteral:
        return new TypeLiteral(readDartType());
      case Tag.ThisExpression:
        return new ThisExpression();
      case Tag.Rethrow:
        return new Rethrow();
      case Tag.Throw:
        return new Throw(readExpression());
      case Tag.ListLiteral:
        var typeArgument = readDartType();
        return new ListLiteral(readExpressionList(),
            typeArgument: typeArgument, isConst: false);
      case Tag.ConstListLiteral:
        var typeArgument = readDartType();
        return new ListLiteral(readExpressionList(),
            typeArgument: typeArgument, isConst: true);
      case Tag.MapLiteral:
        var keyType = readDartType();
        var valueType = readDartType();
        return new MapLiteral(readMapEntryList(),
            keyType: keyType, valueType: valueType, isConst: false);
      case Tag.ConstMapLiteral:
        var keyType = readDartType();
        var valueType = readDartType();
        return new MapLiteral(readMapEntryList(),
            keyType: keyType, valueType: valueType, isConst: true);
      case Tag.AwaitExpression:
        return new AwaitExpression(readExpression());
      case Tag.FunctionExpression:
        return new FunctionExpression(readFunctionNode());
      case Tag.Let:
        var variable = readVariableDeclaration();
        int stackHeight = variableStack.length;
        pushVariableDeclaration(variable);
        var body = readExpression();
        variableStack.length = stackHeight;
        return new Let(variable, body);
      default:
        throw fail('Invalid expression tag: $tag');
    }
  }

  List<MapEntry> readMapEntryList() {
    return new List<MapEntry>.generate(readUInt(), (i) => readMapEntry());
  }

  MapEntry readMapEntry() {
    return new MapEntry(readExpression(), readExpression());
  }

  List<Statement> readStatementList() {
    return new List<Statement>.generate(readUInt(), (i) => readStatement());
  }

  Statement readStatementOrNullIfEmpty() {
    var node = readStatement();
    if (node is EmptyStatement) {
      return null;
    } else {
      return node;
    }
  }

  Statement readStatementOption() {
    return readAndCheckOptionTag() ? readStatement() : null;
  }

  Statement readStatement() {
    int tag = readByte();
    switch (tag) {
      case Tag.InvalidStatement:
        return new InvalidStatement();
      case Tag.ExpressionStatement:
        return new ExpressionStatement(readExpression());
      case Tag.Block:
        int stackHeight = variableStack.length;
        var body = readStatementList();
        variableStack.length = stackHeight;
        return new Block(body);
      case Tag.EmptyStatement:
        return new EmptyStatement();
      case Tag.AssertStatement:
        return new AssertStatement(readExpression(), readExpressionOption());
      case Tag.LabeledStatement:
        var label = new LabeledStatement(null);
        labelStack.add(label);
        label.body = readStatement()..parent = label;
        labelStack.removeLast();
        return label;
      case Tag.BreakStatement:
        int index = readUInt();
        return new BreakStatement(labelStack[index]);
      case Tag.WhileStatement:
        return new WhileStatement(readExpression(), readStatement());
      case Tag.DoStatement:
        return new DoStatement(readStatement(), readExpression());
      case Tag.ForStatement:
        int variableStackHeight = variableStack.length;
        var variables = readAndPushVariableDeclarationList();
        var condition = readExpressionOption();
        var updates = readExpressionList();
        var body = readStatement();
        variableStack.length = variableStackHeight;
        return new ForStatement(variables, condition, updates, body);
      case Tag.ForInStatement:
      case Tag.AsyncForInStatement:
        bool isAsync = tag == Tag.AsyncForInStatement;
        int variableStackHeight = variableStack.length;
        var variable = readAndPushVariableDeclaration();
        var iterable = readExpression();
        var body = readStatement();
        variableStack.length = variableStackHeight;
        return new ForInStatement(variable, iterable, body,
            isAsync: isAsync);
      case Tag.SwitchStatement:
        var expression = readExpression();
        int count = readUInt();
        List<SwitchCase> cases =
            new List<SwitchCase>.generate(count, (i) => new SwitchCase.empty());
        switchCaseStack.addAll(cases);
        for (int i = 0; i < cases.length; ++i) {
          var caseNode = cases[i];
          _fillTreeNodeList(caseNode.expressions, readExpression, caseNode);
          caseNode.isDefault = readByte() == 1;
          caseNode.body = readStatement()..parent = caseNode;
        }
        switchCaseStack.length -= count;
        return new SwitchStatement(expression, cases);
      case Tag.ContinueSwitchStatement:
        int index = readUInt();
        return new ContinueSwitchStatement(switchCaseStack[index]);
      case Tag.IfStatement:
        return new IfStatement(
            readExpression(), readStatement(), readStatementOrNullIfEmpty());
      case Tag.ReturnStatement:
        return new ReturnStatement(readExpressionOption());
      case Tag.TryCatch:
        return new TryCatch(readStatement(), readCatchList());
      case Tag.TryFinally:
        return new TryFinally(readStatement(), readStatement());
      case Tag.YieldStatement:
        int flags = readByte();
        return new YieldStatement(readExpression(),
            isYieldStar: flags & 0x1 != 0);
      case Tag.VariableDeclaration:
        var variable = readVariableDeclaration();
        variableStack.add(variable); // Will be popped by the enclosing scope.
        return variable;
      case Tag.FunctionDeclaration:
        var variable = readVariableDeclaration();
        variableStack.add(variable); // Will be popped by the enclosing scope.
        var function = readFunctionNode();
        return new FunctionDeclaration(variable, function);
      default:
        throw fail('Invalid statement tag: $tag');
    }
  }

  List<Catch> readCatchList() {
    return new List<Catch>.generate(readUInt(), (i) => readCatch());
  }

  Catch readCatch() {
    int variableStackHeight = variableStack.length;
    var guard = readDartType();
    var exception = readAndPushVariableDeclarationOption();
    var stackTrace = readAndPushVariableDeclarationOption();
    var body = readStatement();
    variableStack.length = variableStackHeight;
    return new Catch(exception, body, guard: guard, stackTrace: stackTrace);
  }

  List<DartType> readDartTypeList() {
    return new List<DartType>.generate(readUInt(), (i) => readDartType());
  }

  DartType readDartTypeOption() {
    return readAndCheckOptionTag() ? readDartType() : null;
  }

  DartType readDartType() {
    int tag = readByte();
    switch (tag) {
      case Tag.InvalidType:
        return const InvalidType();
      case Tag.DynamicType:
        return const DynamicType();
      case Tag.VoidType:
        return const VoidType();
      case Tag.InterfaceType:
        return new InterfaceType(readClassReference(), readDartTypeList());
      case Tag.SimpleInterfaceType:
        return new InterfaceType(readClassReference(), const <DartType>[]);
      case Tag.FunctionType:
        int typeParameterStackHeight = typeParameterStack.length;
        var typeParameters = readAndPushTypeParameterList();
        var requiredParameterCount = readUInt();
        var positional = readDartTypeList();
        int namedParameterCount = readUInt();
        var named = <String, DartType>{};
        for (int i = 0; i < namedParameterCount; ++i) {
          var name = readStringReference();
          var type = readDartType();
          named[name] = type;
        }
        var returnType = readDartType();
        typeParameterStack.length = typeParameterStackHeight;
        return new FunctionType(positional, returnType,
            typeParameters: typeParameters,
            requiredParameterCount: requiredParameterCount,
            namedParameters: named);
      case Tag.SimpleFunctionType:
        var positional = readDartTypeList();
        var returnType = readDartType();
        return new FunctionType(positional, returnType);
      case Tag.TypeParameterType:
        int index = readUInt();
        return new TypeParameterType(typeParameterStack[index]);
      default:
        throw fail('Invalid dart type tag: $tag');
    }
  }

  List<TypeParameter> readAndPushTypeParameterList([List<TypeParameter> list,
      TreeNode parent]) {
    int length = readUInt();
    if (length == 0) return list ?? <TypeParameter>[];
    if (list == null) {
      list = new List<TypeParameter>.generate(
          length, (i) => new TypeParameter(null, null)..parent = parent);
    } else {
      list.length = length;
      for (int i = 0; i < length; ++i) {
        list[i] = new TypeParameter(null, null)..parent = parent;
      }
    }
    typeParameterStack.addAll(list);
    for (int i = 0; i < list.length; ++i) {
      readTypeParameter(list[i]);
    }
    return list;
  }

  void readTypeParameter(TypeParameter node) {
    node.name = readStringOrNullIfEmpty();
    node.bound = readDartType();
  }

  Arguments readArguments() {
    var typeArguments = readDartTypeList();
    var positional = readExpressionList();
    var named = readNamedExpressionList();
    return new Arguments(positional, types: typeArguments, named: named);
  }

  List<NamedExpression> readNamedExpressionList() {
    return new List<NamedExpression>.generate(
        readUInt(), (i) => readNamedExpression());
  }

  NamedExpression readNamedExpression() {
    return new NamedExpression(readStringReference(), readExpression());
  }

  List<VariableDeclaration> readAndPushVariableDeclarationList() {
    return new List<VariableDeclaration>.generate(
        readUInt(), (i) => readAndPushVariableDeclaration());
  }

  VariableDeclaration readAndPushVariableDeclarationOption() {
    return readAndCheckOptionTag() ? readAndPushVariableDeclaration() : null;
  }

  VariableDeclaration readAndPushVariableDeclaration() {
    var variable = readVariableDeclaration();
    variableStack.add(variable);
    return variable;
  }

  VariableDeclaration readVariableDeclaration() {
    int flags = readByte();
    return new VariableDeclaration(readStringOrNullIfEmpty(),
        type: readDartType(),
        initializer: readExpressionOption(),
        isFinal: flags & 0x1 != 0,
        isConst: flags & 0x2 != 0);
  }
}
