// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dump_info;

import 'dart:convert' show
    HtmlEscape,
    JsonEncoder,
    StringConversionSink,
    ChunkedConversionSink;

import 'elements/elements.dart';
import 'elements/visitor.dart';
import 'dart2jslib.dart' show
    Compiler,
    CompilerTask,
    CodeBuffer;
import 'dart_types.dart' show DartType;
import 'types/types.dart' show TypeMask;
import 'util/util.dart' show modifiersToString;
import 'deferred_load.dart' show OutputUnit;
import 'js_backend/js_backend.dart' show JavaScriptBackend;
import 'js/js.dart' as jsAst;
import 'compilation_info.dart' show CompilationInformation;

/// Maps elements to an id.  Supports lookups in
/// both directions.
class ElementMapper {
  Map<int, Element> _idToElement = {};
  Map<Element, int> _elementToId = {};
  int _idCounter = 0;
  String name;

  ElementMapper(this.name);

  String add(Element e) {
    if (_elementToId.containsKey(e)) {
      return name + "/${_elementToId[e]}";
    }

    _idToElement[_idCounter] = e;
    _elementToId[e] = _idCounter;
    _idCounter += 1;
    return name + "/${_idCounter - 1}";
  }
}

class DividedElementMapper {
  // Mappers for specific kinds of elements.
  ElementMapper _library = new ElementMapper('library');
  ElementMapper _typedef = new ElementMapper('typedef');
  ElementMapper _field = new ElementMapper('field');
  ElementMapper _class = new ElementMapper('class');
  ElementMapper _function = new ElementMapper('function');

  // Convert this database of elements into JSON for rendering
  Map<String, dynamic> _toJson(ElementToJsonVisitor elementToJson) {
    Map<String, dynamic> json = {};
    var m = [_library, _typedef, _field, _class, _function];
    for (ElementMapper mapper in m) {
      Map<String, dynamic> innerMapper = {};
      mapper._idToElement.forEach((k, v) {
        // All these elements are already cached in the
        // jsonCache, so this is just an access.
        var elementJson = elementToJson.process(v);
        if (elementJson != null) {
          innerMapper["$k"] = elementJson;
        }
      });
      json[mapper.name] = innerMapper;
    }
    return json;
  }
}

class ElementToJsonVisitor extends ElementVisitor<Map<String, dynamic>> {
  DividedElementMapper mapper = new DividedElementMapper();
  Compiler compiler;

  CompilationInformation compilationInfo;

  Map<Element, Map<String, dynamic>> jsonCache = {};
  Map<Element, jsAst.Expression> codeCache;

  int programSize;
  DateTime compilationMoment;
  String dart2jsVersion;
  Duration compilationDuration;
  Duration dumpInfoDuration;

  ElementToJsonVisitor(Compiler compiler) {
    this.compiler = compiler;
    this.compilationInfo = compiler.enqueuer.codegen.compilationInfo;

    programSize = compiler.assembledCode.length;
    compilationMoment = new DateTime.now();
    dart2jsVersion = compiler.hasBuildId ? compiler.buildId : null;
    compilationDuration = compiler.totalCompileTime.elapsed;

    for (var library in compiler.libraryLoader.libraries.toList()) {
      library.accept(this);
    }

    dumpInfoDuration = new DateTime.now().difference(compilationMoment);
  }

  // If keeping the element is in question (like if a function has a size
  // of zero), only keep it if it holds dependencies to elsewhere.
  bool shouldKeep(Element element) {
    return compilationInfo.addsToWorkListMap.containsKey(element) ||
           compilationInfo.enqueuesMap.containsKey(element);
  }

  Map<String, dynamic> toJson() {
    return mapper._toJson(this);
  }

  // Memoization of the JSON creating process.
  Map<String, dynamic> process(Element element) {
    return jsonCache.putIfAbsent(element, () => element.accept(this));
  }

  Map<String, dynamic> visitElement(Element element) {
    return null;
  }

  Map<String, dynamic> visitConstructorBodyElement(ConstructorBodyElement e) {
    return visitFunctionElement(e.constructor);
  }

  Map<String, dynamic> visitLibraryElement(LibraryElement element) {
    var id = mapper._library.add(element);
    List<String> children = <String>[];

    String libname = element.getLibraryName();
    libname = libname == "" ? "<unnamed>" : libname;

    int size = compiler.dumpInfoTask.sizeOf(element);

    LibraryElement contentsOfLibrary = element.isPatched
      ? element.patch : element;
    contentsOfLibrary.forEachLocalMember((Element member) {
      Map<String, dynamic> childJson = this.process(member);
      if (childJson == null) return;
      children.add(childJson['id']);
    });

    if (children.length == 0 && !shouldKeep(element)) {
      return null;
    }

    return {
      'kind': 'library',
      'name': libname,
      'size': size,
      'id': id,
      'children': children
    };
  }

  Map<String, dynamic> visitTypedefElement(TypedefElement element) {
    String id = mapper._typedef.add(element);
    return element.alias == null
      ? null
      : {
        'id': id,
        'type': element.alias.toString(),
        'kind': 'typedef',
        'name': element.name
      };
  }

  Map<String, dynamic> visitFieldElement(FieldElement element) {
    String id = mapper._field.add(element);
    List<String> children = [];
    StringBuffer emittedCode = compiler.dumpInfoTask.codeOf(element);

    // If a field has an empty inferred type it is never used.
    TypeMask inferredType =
      compiler.typesTask.getGuaranteedTypeOfElement(element);
    if (inferredType == null || inferredType.isEmpty || element.isConst) {
      return null;
    }

    int size = compiler.dumpInfoTask.sizeOf(element);
    String code;

    if (emittedCode != null) {
      size += emittedCode.length;
      code = emittedCode.toString();
    }

    for (Element closure in element.nestedClosures) {
      var childJson = this.process(closure);
      if (childJson != null) {
        children.add(childJson['id']);
        if (childJson.containsKey('size')) {
          size += childJson['size'];
        }
      }
    }

    return {
      'id': id,
      'kind': 'field',
      'type': element.type.toString(),
      'inferredType': inferredType.toString(),
      'name': element.name,
      'children': children,
      'size': size,
      'code': code
    };
  }

  Map<String, dynamic> visitClassElement(ClassElement element) {
    String id = mapper._class.add(element);
    List<String> children = [];

    int size = compiler.dumpInfoTask.sizeOf(element);

    // Omit element if it is not needed.
    JavaScriptBackend backend = compiler.backend;
    if (!backend.emitter.neededClasses.contains(element)) return null;
    Map<String, dynamic> modifiers = { 'abstract': element.isAbstract };

    element.forEachLocalMember((Element member) {
      Map<String, dynamic> childJson = this.process(member);
      if (childJson != null) {
        children.add(childJson['id']);
      }
    });

    return {
      'name': element.name,
      'size': size,
      'kind': 'class',
      'modifiers': modifiers,
      'children': children,
      'id': id
    };
  }

  Map<String, dynamic> visitFunctionElement(FunctionElement element) {
    String id = mapper._function.add(element);
    String name = element.name;
    String kind = "function";
    List<String> children = [];
    List<Map<String, dynamic>> parameters = [];
    String inferredReturnType = null;
    String returnType = null;
    String sideEffects = null;
    String code = "";

    StringBuffer emittedCode = compiler.dumpInfoTask.codeOf(element);
    int size = compiler.dumpInfoTask.sizeOf(element);

    Map<String, dynamic> modifiers = {
      'static': element.isStatic,
      'const': element.isConst,
      'factory': element.isFactoryConstructor,
      'external': element.isPatched
    };

    var enclosingElement = element.enclosingElement;
    if (enclosingElement.isField ||
               enclosingElement.isFunction ||
               element.isClosure ||
               enclosingElement.isConstructor) {
      kind = "closure";
      name = "<unnamed>";
    } else if (enclosingElement.isClass) {
      kind = 'method';
    }

    if (element.isConstructor) {
      name == ""
        ? "${element.enclosingElement.name}"
        : "${element.enclosingElement.name}.${element.name}";
      kind = "constructor";
    }

    if (emittedCode != null) {
      FunctionSignature signature = element.functionSignature;
      returnType = signature.type.returnType.toString();
      signature.forEachParameter((parameter) {
        parameters.add({
          'name': parameter.name,
          'type': compiler.typesTask
            .getGuaranteedTypeOfElement(parameter).toString()
        });
      });
      inferredReturnType = compiler.typesTask
        .getGuaranteedReturnTypeOfElement(element).toString();
      sideEffects = compiler.world.getSideEffectsOfElement(element).toString();
      code = emittedCode.toString();
    }
    if (element is MethodElement) {
      for (Element closure in element.nestedClosures) {
        Map<String, dynamic> child = this.process(closure);
        if (child != null) {
          children.add(child['id']);
          size += child['size'];
        }
      }
    }

    if (size == 0 && !shouldKeep(element)) {
      return null;
    }

    return {
      'kind': kind,
      'name': name,
      'id': id,
      'modifiers': modifiers,
      'children': children,
      'size': size,
      'returnType': returnType,
      'inferredReturnType': inferredReturnType,
      'parameters': parameters,
      'sideEffects': sideEffects,
      'code': code,
      'type': element.computeType(compiler).toString()
    };
  }
}


class DumpInfoTask extends CompilerTask {
  DumpInfoTask(Compiler compiler)
      : super(compiler);

  String name = "Dump Info";

  ElementToJsonVisitor infoCollector;

  // A set of javascript AST nodes that we care about the size of.
  // This set is automatically populated when registerElementAst()
  // is called.
  final Set<jsAst.Node> _tracking = new Set<jsAst.Node>();
  // A mapping from Dart Elements to Javascript AST Nodes.
  final Map<Element, List<jsAst.Node>> _elementToNodes =
    <Element, List<jsAst.Node>>{};
  // A mapping from Javascript AST Nodes to the size of their
  // pretty-printed contents.
  final Map<jsAst.Node, int> _nodeToSize = <jsAst.Node, int>{};
  final Map<jsAst.Node, int> _nodeBeforeSize = <jsAst.Node, int>{};
  final Map<Element, int> _fieldNameToSize = <Element, int>{};

  /**
   * A callback that can be called before a jsAst [node] is
   * pretty-printed. The size of the code buffer ([aftersize])
   * is also passed.
   */
  void enteringAst(jsAst.Node node, int beforeSize) {
    if (isTracking(node)) {
      _nodeBeforeSize[node] = beforeSize;
    }
  }

  /**
   * A callback that can be called after a jsAst [node] is
   * pretty-printed. The size of the code buffer ([aftersize])
   * is also passed.
   */
  void exitingAst(jsAst.Node node, int afterSize) {
    if (isTracking(node)) {
      int diff = afterSize - _nodeBeforeSize[node];
      recordAstSize(node, diff);
    }
  }

  // Returns true if we care about tracking the size of
  // this node.
  bool isTracking(jsAst.Node code) {
    if (compiler.dumpInfo) {
      return _tracking.contains(code);
    } else {
      return false;
    }
  }

  // Registers that a javascript AST node `code` was produced by the
  // dart Element `element`.
  void registerElementAst(Element element, jsAst.Node code) {
    if (compiler.dumpInfo) {
      _elementToNodes
        .putIfAbsent(element, () => new List<jsAst.Node>())
        .add(code);
      _tracking.add(code);
    }
  }

  // Records the size of a dart AST node after it has been
  // pretty-printed into the output buffer.
  void recordAstSize(jsAst.Node code, int size) {
    if (compiler.dumpInfo) {
      //TODO: should I be incrementing here instead?
      _nodeToSize[code] = size;
    }
  }

  // Field names are treated differently by the dart compiler
  // so they must be recorded seperately.
  void recordFieldNameSize(Element element, int size) {
    _fieldNameToSize[element] = size;
  }

  // Returns the size of the source code that
  // was generated for an element.  If no source
  // code was produced, return 0.
  int sizeOf(Element element) {
    if (_fieldNameToSize.containsKey(element)) {
      return _fieldNameToSize[element];
    }
    if (_elementToNodes.containsKey(element)) {
      return _elementToNodes[element]
        .map(sizeOfNode)
        .fold(0, (a, b) => a + b);
    } else {
      return 0;
    }
  }

  int sizeOfNode(jsAst.Node node) {
    if (_nodeToSize.containsKey(node)) {
      return _nodeToSize[node];
    } else {
      return 0;
    }
  }

  StringBuffer codeOf(Element element) {
    List<jsAst.Node> code = _elementToNodes[element];
    if (code == null) return null;
    // Concatenate rendered ASTs.
    StringBuffer sb = new StringBuffer();
    for (jsAst.Node ast in code) {
      sb.writeln(jsAst.prettyPrint(ast, compiler).getText());
    }
    return sb;
  }

  void collectInfo() {
    infoCollector = new ElementToJsonVisitor(compiler);
  }

  void dumpInfo() {
    measure(() {
      if (infoCollector == null) {
        collectInfo();
      }

      StringBuffer jsonBuffer = new StringBuffer();
      dumpInfoJson(jsonBuffer);
      compiler.outputProvider('', 'info.json')
        ..add(jsonBuffer.toString())
        ..close();
    });
  }


  void dumpInfoJson(StringSink buffer) {
    JsonEncoder encoder = const JsonEncoder();

    // `A` uses and depends on the functions `Bs`.
    //     A         Bs
    Map<String, List<String>> holding = <String, List<String>>{};

    DateTime startToJsonTime = new DateTime.now();

    CompilationInformation compilationInfo =
      infoCollector.compiler.enqueuer.codegen.compilationInfo;
    compilationInfo.addsToWorkListMap.forEach((func, deps) {
      if (func != null) {
        var funcJson = infoCollector.process(func);
        if (funcJson != null) {
          var funcId = funcJson['id'];

          List<String> heldList = <String>[];

          for (var held in deps) {
            // "process" to get the ids of the elements.
            var heldJson = infoCollector.process(held);
            if (heldJson != null) {
              var heldId = heldJson['id'];
              heldList.add(heldId);
            }
          }
          holding[funcId] = heldList;
        }
      }
    });

    Map<String, dynamic> outJson = {
      'elements': infoCollector.toJson(),
      'holding': holding,
      'dump_version': 1,
    };

    Duration toJsonDuration = new DateTime.now().difference(startToJsonTime);

    Map<String, dynamic> generalProgramInfo = <String, dynamic> {
      'size': infoCollector.programSize,
      'dart2jsVersion': infoCollector.dart2jsVersion,
      'compilationMoment': infoCollector.compilationMoment.toString(),
      'compilationDuration': infoCollector.compilationDuration.toString(),
      'toJsonDuration': toJsonDuration.toString(),
      'dumpInfoDuration': infoCollector.dumpInfoDuration.toString(),
      'noSuchMethodEnabled': compiler.enabledNoSuchMethod
    };

    outJson['program'] = generalProgramInfo;

    ChunkedConversionSink<Object> sink =
      encoder.startChunkedConversion(
          new StringConversionSink.fromStringSink(buffer));
    sink.add(outJson);
  }
}
