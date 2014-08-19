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
import 'dart2jslib.dart' show Backend, CodeBuffer, Compiler, CompilerTask;
import 'types/types.dart' show TypeMask;
import 'deferred_load.dart' show OutputUnit;
import 'js_backend/js_backend.dart' show JavaScriptBackend;
import 'js/js.dart' as jsAst;
import 'universe/universe.dart' show Selector;

/// Maps objects to an id.  Supports lookups in
/// both directions.
class IdMapper<T>{
  Map<int, T> _idToElement = {};
  Map<T, int> _elementToId = {};
  int _idCounter = 0;
  String name;

  IdMapper(this.name);

  Iterable<T> get elements => _elementToId.keys;

  String add(T e) {
    if (_elementToId.containsKey(e)) {
      return name + "/${_elementToId[e]}";
    }

    _idToElement[_idCounter] = e;
    _elementToId[e] = _idCounter;
    _idCounter += 1;
    return name + "/${_idCounter - 1}";
  }
}

class GroupedIdMapper {
  // Mappers for specific kinds of elements.
  IdMapper<LibraryElement> _library = new IdMapper('library');
  IdMapper<TypedefElement> _typedef = new IdMapper('typedef');
  IdMapper<FieldElement> _field = new IdMapper('field');
  IdMapper<ClassElement> _class = new IdMapper('class');
  IdMapper<FunctionElement> _function = new IdMapper('function');
  IdMapper<OutputUnit> _outputUnit = new IdMapper('outputUnit');

  Iterable<Element> get functions => _function.elements;

  // Convert this database of elements into JSON for rendering
  Map<String, dynamic> _toJson(ElementToJsonVisitor elementToJson) {
    Map<String, dynamic> json = {};
    var m = [_library, _typedef, _field, _class, _function];
    for (IdMapper mapper in m) {
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
  GroupedIdMapper mapper = new GroupedIdMapper();
  Compiler compiler;

  Map<Element, Map<String, dynamic>> jsonCache = {};
  Map<Element, jsAst.Expression> codeCache;

  int programSize;
  DateTime compilationMoment;
  String dart2jsVersion;
  Duration compilationDuration;
  Duration dumpInfoDuration;

  ElementToJsonVisitor(Compiler compiler) {
    this.compiler = compiler;

    Backend backend = compiler.backend;
    if (backend is JavaScriptBackend) {
      // Add up the sizes of all output-buffers.
      programSize = backend.emitter.outputBuffers.values.fold(0,
          (a, b) => a + b.length);
    } else {
      programSize = compiler.assembledCode.length;
    }


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
    return compiler.dumpInfoTask.selectorsFromElement.containsKey(element);
  }

  Map<String, dynamic> toJson() {
    return mapper._toJson(this);
  }

  // Memoization of the JSON creating process.
  Map<String, dynamic> process(Element element) {
    return jsonCache.putIfAbsent(element, () => element.accept(this));
  }

  // Returns the id of an [element] if it has already been processed.
  // If the element has not been processed, this function does not
  // process it, and simply returns null instead.
  String idOf(Element element) {
    if (jsonCache.containsKey(element) && jsonCache[element] != null) {
      return jsonCache[element]['id'];
    } else {
      return null;
    }
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

    TypeMask inferredType =
        compiler.typesTask.getGuaranteedTypeOfElement(element);
    // If a field has an empty inferred type it is never used.
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

    OutputUnit outputUnit =
        compiler.deferredLoadTask.outputUnitForElement(element);

    return {
      'id': id,
      'kind': 'field',
      'type': element.type.toString(),
      'inferredType': inferredType.toString(),
      'name': element.name,
      'children': children,
      'size': size,
      'code': code,
      'outputUnit': mapper._outputUnit.add(outputUnit)
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

        // Closures are placed in the library namespace, but
        // we want to attribute them to a function, and by
        // extension, this class.  Process and add the sizes
        // here.
        if (member is MemberElement) {
          for (Element closure in member.nestedClosures) {
            Map<String, dynamic> child = this.process(closure);

            // Look for the parent element of this closure which should
            // be a class.  If it exists, set the display name to
            // the name of the class + the name of the closure function.
            Element parent = closure.enclosingElement;
            Map<String, dynamic> processedParent = this.process(parent);
            if (processedParent != null) {
              child['name'] = "${processedParent['name']}.${child['name']}";
            }

            if (child != null) {
              size += child['size'];
            }
          }
        }
      }
    });


    OutputUnit outputUnit =
        compiler.deferredLoadTask.outputUnitForElement(element);

    return {
      'name': element.name,
      'size': size,
      'kind': 'class',
      'modifiers': modifiers,
      'children': children,
      'id': id,
      'outputUnit': mapper._outputUnit.add(outputUnit)
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
            .getGuaranteedTypeOfElement(parameter).toString(),
          'declaredType': parameter.node.type.toString()
        });
      });
      inferredReturnType = compiler.typesTask
        .getGuaranteedReturnTypeOfElement(element).toString();
      sideEffects = compiler.world.getSideEffectsOfElement(element).toString();
      code = emittedCode.toString();
    }

    if (element is MemberElement) {
      MemberElement member = element as MemberElement;
      for (Element closure in member.nestedClosures) {
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

    OutputUnit outputUnit =
        compiler.deferredLoadTask.outputUnitForElement(element);

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
      'type': element.type.toString(),
      'outputUnit': mapper._outputUnit.add(outputUnit)
    };
  }
}

class Selection {
  final Element selectedElement;
  final Selector selector;
  Selection(this.selectedElement, this.selector);
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

  final Map<Element, Set<Selector>> selectorsFromElement = {};

  /**
   * Registers that a function uses a selector in the
   * function body
   */
  void elementUsesSelector(Element element, Selector selector) {
    if (compiler.dumpInfo) {
      selectorsFromElement
          .putIfAbsent(element, () => new Set<Selector>())
          .add(selector);
    }
  }

  /**
   * Returns an iterable of [Selection]s that are used by
   * [element].  Each [Selection] contains an element that is
   * used and the selector that selected the element.
   */
  Iterable<Selection> getRetaining(Element element) {
    if (!selectorsFromElement.containsKey(element)) {
      return const <Selection>[];
    } else {
      return selectorsFromElement[element].expand(
        (selector) {
          return compiler.world.allFunctions.filter(selector).map((element) {
            return new Selection(element, selector);
          });
        });
    }
  }

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
    DateTime startToJsonTime = new DateTime.now();

    Map<String, List<String>> holding = <String, List<String>>{};
    for (Element fn in infoCollector.mapper.functions) {
      Iterable<Selection> pulling = getRetaining(fn);
      // Don't bother recording an empty list of dependencies.
      if (pulling.length > 0) {
        String fnId = infoCollector.idOf(fn);
        // Some dart2js builtin functions are not
        // recorded.  Don't register these.
        if (fnId != null) {
          holding[fnId] = pulling
            .map((selection) {
              return <String, String>{
                "id": infoCollector.idOf(selection.selectedElement),
                "mask": selection.selector.mask.toString()
              };
            })
            // Filter non-null ids for the same reason as above.
            .where((a) => a['id'] != null)
            .toList();
        }
      }
    }

    List<Map<String, dynamic>> outputUnits =
        new List<Map<String, dynamic>>();

    JavaScriptBackend backend = compiler.backend;

    for (OutputUnit outputUnit in
        infoCollector.mapper._outputUnit._elementToId.keys) {
      String id = infoCollector.mapper._outputUnit.add(outputUnit);
      outputUnits.add(<String, dynamic> {
        'id': id,
        'name': outputUnit.name,
        'size': backend.emitter.outputBuffers[outputUnit].length,
      });
    }

    Map<String, dynamic> outJson = {
      'elements': infoCollector.toJson(),
      'holding': holding,
      'outputUnits': outputUnits,
      'dump_version': 3,
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
