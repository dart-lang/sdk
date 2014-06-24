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

// TODO (sigurdm): A search function.
// TODO (sigurdm): Output size of classes.
// TODO (sigurdm): Print that we dumped the HTML-file.
// TODO (sigurdm): Include why a given element was included in the output.
// TODO (sigurdm): Include how much output grew because of mirror support.
// TODO (sigurdm): Write each function with parameter names.
// TODO (sigurdm): Write how much space the boilerplate takes.
// TODO (sigurdm): Include javascript names of entities in the output.

const List<String> COLORS = const [
    "#fff",
    "#8dd3c7",
    "#ffffb3",
    "#bebada",
    "#fb8072",
    "#80b1d3",
    "#fdb462",
    "#b3de69",
    "#fccde5",
    "#d9d9d9",
    "#bc80bd",
    "#ccebc5",
    "#ffed6f"];

class CodeSizeCounter {
  final Map<Element, int> generatedSize = new Map<Element, int>();

  int getGeneratedSizeOf(Element element) {
    int result = generatedSize[element];
    return result == null ? 0 : result;
  }

  void countCode(Element element, int added) {
    int before = generatedSize.putIfAbsent(element, () => 0);
    generatedSize[element] = before + added;
  }
}

tag(String element) {
  return (String content, {String cls}) {
    String classString = cls == null ? '' : ' class="$cls"';
    return '<$element$classString>$content</$element>';
  };
}

var div = tag('div');
var span = tag('span');
var code = tag('code');
var h2 = tag('h2');

var esc = const HtmlEscape().convert;

String sizeDescription(int size, ProgramInfo programInfo) {
  if (size == null) {
    return '';
  }
  return span(span(size.toString(), cls: 'value') +
      ' bytes (${size * 100 ~/ programInfo.size}%)', cls: 'size');
}

String sizePercent(int size, ProgramInfo programInfo) {
  if (size == null) {
    return "0.000%";
  } else {
    return (100 * size / programInfo.size).toStringAsFixed(3) + "%";
  }
}

/// An [InfoNode] holds information about a part the program.
abstract class InfoNode {
  String get name;

  int get size;

  void emitHtml(ProgramInfo programInfo, StringSink buffer,
      [String indentation = '']);

  Map<String, dynamic> toJson(ProgramInfo programInfo);
}

/// An [ElementNode] holds information about an [Element]
class ElementInfoNode implements InfoNode {
  /// The name of the represented [Element].
  final String name;

  /// The kind of the [Element] represented.  This is presented to the
  /// user, so it might be more specific than [element.kind].
  final String kind;

  /// The static type of the represented [Element].
  /// [:null:] if this kind of element has no type.
  final String type;

  /// Any extra information to display about the represented [Element].
  final String extra;

  /// A textual description of the modifiers (such as "static", "abstract") of
  /// the represented [Element].
  final String modifiers;

  /// Describes how many bytes the code for the represented [Element] takes up
  /// in the output.
  final int size;

  /// Subnodes containing more detailed information about the represented
  /// [Element], and its members.
  List<InfoNode> contents;

  /// Subnodes containing more detailed information about the represented
  /// [Element], and its members.
  int outputUnitId;

  ElementInfoNode({this.name: "",
      this.kind: "",
      this.type,
      this.modifiers: "",
      this.size,
      this.contents,
      this.extra: "",
      this.outputUnitId});

  Map<String, dynamic> toJson(ProgramInfo programInfo) {
    Map<String, dynamic> json = <String, dynamic>{
      'kind': this.kind,
      'modifiers': this.modifiers,
      'name': this.name,
      'type': this.type,
      'size': this.size,
      'sizePercent': sizePercent(this.size, programInfo),
      'extra': this.extra
    };

    if (this.contents != null) {
      json['children'] =
        this.contents.map((c) => c.toJson(programInfo)).toList();
    }

    return json;
  }

  void emitHtml(ProgramInfo programInfo, StringSink buffer,
      [String indentation = '']) {
    String kindString = span(esc(kind), cls: 'kind');
    String modifiersString = span(esc(modifiers), cls: "modifiers");

    String nameString = span(esc(name), cls: 'name');
    String typeString = type == null
        ? ''
        : span('/* ' + esc(type) + ' */', cls: 'type');
    String extraString = span(esc(extra), cls: 'type');
    String describe = [
        kindString,
        typeString,
        modifiersString,
        nameString,
        sizeDescription(size, programInfo),
        extraString].join(' ');

    if (contents != null) {
      String outputUnitClass = outputUnitId == null
          ? ""
          : " outputUnit${outputUnitId % COLORS.length}";
      buffer.write(indentation);
      buffer.write('<div class="container$outputUnitClass">\n');
      buffer.write('$indentation  ');
      buffer.write(div('+$describe', cls: "details"));
      buffer.write('\n');
      buffer.write('$indentation  <div class="contents">');
      if (contents.isEmpty) {
        buffer.write('No members</div>');
      } else {
        buffer.write('\n');
        for (InfoNode subElementDescription in contents) {
          subElementDescription.emitHtml(programInfo, buffer,
              indentation + '    ');
        }
        buffer.write("\n$indentation  </div>");
      }
      buffer.write("\n$indentation</div>\n");
    } else {
      buffer.writeln(div('$describe', cls: "element"));
    }
  }
}

/// A [CodeInfoNode] holds information about a piece of code.
class CodeInfoNode implements InfoNode {
  /// A short description of the code.
  final String description;

  final String generatedCode;

  get size => generatedCode.length;

  get name => "";

  CodeInfoNode({this.description: "", this.generatedCode});

  void emitHtml(ProgramInfo programInfo, StringBuffer buffer,
      [String indentation = '']) {
    buffer.write(indentation);
    buffer.write(div(description + ' ' +
                     sizeDescription(generatedCode.length, programInfo),
                     cls: 'kind') +
        code(esc(generatedCode)));
    buffer.write('\n');
  }

  Map<String, dynamic> toJson(ProgramInfo programInfo) {
    return <String, dynamic>{
      'kind': 'code',
      'description': description,
      'code': generatedCode,
      'size': generatedCode.length,
      'sizePercent': sizePercent(generatedCode.length, programInfo)
    };
  }
}

/// Instances represent information inferred about the program such as
/// inferred type information or inferred side effects.
class InferredInfoNode implements InfoNode {
  /// Text describing the represented information.
  final String description;

  /// The name of the entity this information is inferred about (for example the
  /// name of a parameter).
  final String name;

  /// The inferred type/side effect.
  final String type;

  get size => 0;

  InferredInfoNode({this.name: "", this.description, this.type});

  Map<String, dynamic> toJson(ProgramInfo programInfo) {
    return <String, dynamic>{
      'kind': 'inferred',
      'name': name,
      'type': type,
      'desc': description
    };
  }

  void emitHtml(ProgramInfo programInfo, StringBuffer buffer,
      [String indentation = '']) {
    buffer.write(indentation);
    buffer.write(
        div('${span("Inferred " + description, cls: "kind")} '
            '${span(esc(name), cls: "name")} '
            '${span(esc(type), cls: "type")} ',
            cls: "attr"));
    buffer.write('\n');
  }
}

/// Instances represent information about a program.
class ProgramInfo {
  /// A list of all the libraries in the program to show information about.
  final List<InfoNode> libraries;

  /// The size of the whole program in bytes.
  final int size;

  /// The time the compilation took place.
  final DateTime compilationMoment;

  /// The time the compilation took to complete.
  final Duration compilationDuration;

  /// The version of dart2js used to compile the program.
  final String dart2jsVersion;

  final Map<OutputUnit, int> outputUnitNumbering;

  ProgramInfo({this.libraries,
               this.size,
               this.compilationMoment,
               this.compilationDuration,
               this.dart2jsVersion,
               this.outputUnitNumbering: null});

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'program_size': size,
      'compile_time': compilationMoment.toString(),
      'compile_duration': compilationDuration.toString(),
      'dart2js_version': dart2jsVersion
    };
  }
}

class InfoDumpVisitor extends ElementVisitor<InfoNode> {
  final Compiler compiler;

  /// Contains the elements visited on the path from the library to here.
  final List<Element> stack = new List<Element>();

  final Map<OutputUnit, int> outputUnitNumbering = new Map<OutputUnit, int>();

  Element get currentElement => stack.last;

  InfoDumpVisitor(Compiler this.compiler);

  ProgramInfo collectDumpInfo() {
    JavaScriptBackend backend = compiler.backend;

    int counter = 0;
    for (OutputUnit outputUnit in compiler.deferredLoadTask.allOutputUnits) {
      outputUnitNumbering[outputUnit] = counter;
      counter += 1;
    }

    List<LibraryElement> sortedLibraries =
        compiler.libraryLoader.libraries.toList();
    sortedLibraries.sort((LibraryElement l1, LibraryElement l2) {
      if (l1.isPlatformLibrary && !l2.isPlatformLibrary) {
        return 1;
      } else if (!l1.isPlatformLibrary && l2.isPlatformLibrary) {
        return -1;
      }
      return l1.getLibraryName().compareTo(l2.getLibraryName());
    });

    List<InfoNode> libraryInfos = new List<InfoNode>();
    libraryInfos.addAll(sortedLibraries
        .map((library) => visit(library))
        .where((info) => info != null));

    return new ProgramInfo(
        compilationDuration: compiler.totalCompileTime.elapsed,
        // TODO (sigurdm): Also count the size of deferred code
        size: compiler.assembledCode.length,
        libraries: libraryInfos,
        compilationMoment: new DateTime.now(),
        dart2jsVersion: compiler.hasBuildId ? compiler.buildId : null,
        outputUnitNumbering: outputUnitNumbering);
  }

  InfoNode visitElement(Element element) {
    compiler.internalError(element,
        "This element of kind ${element.kind} "
        "does not support --dump-info");
    return null;
  }

  InfoNode visitLibraryElement(LibraryElement element) {
    List<InfoNode> contents = new List<InfoNode>();
    int size = compiler.dumpInfoTask.codeSizeCounter
        .getGeneratedSizeOf(element);
    if (size == 0) return null;
    stack.add(element);
    // For some reason the patch library contains the origin libraries members,
    // but the origin library does not contain the patch members.
    LibraryElement contentsLibrary = element.isPatched
        ? element.patch
        : element;
    contentsLibrary.forEachLocalMember((Element member) {
      InfoNode info = member.accept(this);
      if (info != null) {
        contents.add(info);
      }
    });
    stack.removeLast();
    String nameString = element.getLibraryName() == ""
        ? "<unnamed>"
        : element.getLibraryName();
    contents.sort((InfoNode e1, InfoNode e2) {
      return e1.name.compareTo(e2.name);
    });
    return new ElementInfoNode(
        extra: "${element.canonicalUri}",
        kind: "library",
        name: nameString,
        size: size,
        modifiers: "",
        contents: contents);
  }

  InfoNode visitTypedefElement(TypedefElement element) {
    return element.alias == null
        ? null
        : new ElementInfoNode(
            type: element.alias.toString(),
            kind: "typedef",
            name: element.name);
  }

  InfoNode visitFieldElement(FieldElement element) {
    CodeBuffer emittedCode = compiler.dumpInfoTask.codeOf(element);
    TypeMask inferredType = compiler.typesTask
        .getGuaranteedTypeOfElement(element);
    // If a field has an empty inferred type it is never used.
    // Also constant fields do not get output as fields.
    if (inferredType == null || inferredType.isEmpty || element.isConst) {
      return null;
    }
    int size = 0;
    DartType type = element.type;
    List<InfoNode> contents = new List<InfoNode>();
    if (emittedCode != null) {
      contents.add(new CodeInfoNode(
          description: "Generated initializer",
          generatedCode: emittedCode.getText()));
      size = emittedCode.length;
    }
    if (inferredType != null) {
      contents.add(new InferredInfoNode(
          description: "type",
          type: inferredType.toString()));
      stack.add(element);
    }
    for (Element closure in element.nestedClosures) {
      InfoNode info = closure.accept(this);
      if (info != null) {
        contents.add(info);
        size += info.size;
      }
    }
    stack.removeLast();

    return new ElementInfoNode(
        kind: "field",
        type: "$type",
        name: element.name,
        size: size,
        modifiers: modifiersToString(isStatic: element.isStatic,
                                     isFinal: element.isFinal,
                                     isConst: element.isConst),
        contents: contents,
        outputUnitId: outputUnitId(element));
  }

  int outputUnitId(Element element) {
    OutputUnit outputUnit =
            compiler.deferredLoadTask.outputUnitForElement(element);
    return outputUnitNumbering[outputUnit];
  }

  InfoNode visitClassElement(ClassElement element) {
    // If the element is not emitted in the program, we omit it from the output.
    JavaScriptBackend backend = compiler.backend;
    if (!backend.emitter.neededClasses.contains(element)) return null;
    String modifiersString = modifiersToString(isAbstract: element.isAbstract);
    String supersString = element.allSupertypes == null ? "" :
        "implements ${element.allSupertypes}";
    List contents = [];
    stack.add(element);
    element.forEachLocalMember((Element member) {
      InfoNode info = member.accept(this);
      if (info != null) {
        contents.add(info);
      }
    });
    stack.removeLast();
    contents.sort((InfoNode n1, InfoNode n2) {
      return n1.name.compareTo(n2.name);
    });
    return new ElementInfoNode(
        kind: "class",
        name: element.name,
        extra: supersString,
        modifiers: modifiersString,
        contents: contents,
        outputUnitId: outputUnitId(element));
  }

  InfoNode visitFunctionElement(FunctionElement element) {
    CodeBuffer emittedCode = compiler.dumpInfoTask.codeOf(element);
    int size = 0;
    String nameString = element.name;
    String modifiersString = modifiersToString(
        isStatic: element.isStatic,
        isConst: element.isConst,
        isFactory: element.isFactoryConstructor,
        isExternal: element.isPatched);
    String kindString = "function";
    if (currentElement.isClass) {
      kindString = "method";
    } else if (currentElement.isField ||
               currentElement.isFunction ||
               currentElement.isConstructor) {
      kindString = "closure";
      nameString = "<unnamed>";
    }
    if (element.isConstructor) {
      nameString = element.name == ""
          ? "${element.enclosingElement.name}"
          : "${element.enclosingElement.name}.${element.name}";
      kindString = "constructor";
    }
    List contents = [];
    if (emittedCode != null) {
      FunctionSignature signature = element.functionSignature;
      signature.forEachParameter((parameter) {
        contents.add(new InferredInfoNode(
            description: "parameter",
            name: parameter.name,
            type: compiler.typesTask
              .getGuaranteedTypeOfElement(parameter).toString()));
      });
      contents.add(new InferredInfoNode(
          description: "return type",
          type: compiler.typesTask
            .getGuaranteedReturnTypeOfElement(element).toString()));
      contents.add(new InferredInfoNode(
        description: "side effects",
        type: compiler.world
            .getSideEffectsOfElement(element).toString()));
      contents.add(new CodeInfoNode(
          description: "Generated code",
          generatedCode: emittedCode.getText()));
      size += emittedCode.length;
    }
    stack.add(element);
    for (Element closure in element.nestedClosures) {
      InfoNode info = closure.accept(this);
      if (info != null) {
        contents.add(info);
        size += info.size;
      }
    }
    stack.removeLast();
    if (size == 0) {
      return null;
    }

    return new ElementInfoNode(
        type: element.computeType(compiler).toString(),
        kind: kindString,
        name: nameString,
        size: size,
        modifiers: modifiersString,
        contents: contents,
        outputUnitId: outputUnitId(element));
  }
}

class DumpInfoTask extends CompilerTask {
  DumpInfoTask(Compiler compiler)
      : infoDumpVisitor = new InfoDumpVisitor(compiler),
        super(compiler);

  String name = "Dump Info";

  final CodeSizeCounter codeSizeCounter = new CodeSizeCounter();

  final InfoDumpVisitor infoDumpVisitor;

  final Map<Element, jsAst.Expression>_generatedCode =
      new Map<Element, jsAst.Expression>();

  /// Registers that [code] has been generated for [element] so that it can be
  /// emitted in the info.html.
  void registerGeneratedCode(Element element, jsAst.Expression code) {
    if (compiler.dumpInfo) {
      _generatedCode[element] = code;
    }
  }

  CodeBuffer codeOf(Element element) {
    jsAst.Expression code = _generatedCode[element];
    return code != null
        ? jsAst.prettyPrint(code, compiler)
        : compiler.backend.codeOf(element);
  }

  void dumpInfo() {
    measure(() {
      ProgramInfo info = infoDumpVisitor.collectDumpInfo();

      StringBuffer htmlBuffer = new StringBuffer();
      dumpInfoHtml(info, htmlBuffer);
      compiler.outputProvider('', 'info.html')
        ..add(htmlBuffer.toString())
        ..close();

      StringBuffer jsonBuffer = new StringBuffer();
      dumpInfoJson(info, jsonBuffer);
      compiler.outputProvider('', 'info.json')
        ..add(jsonBuffer.toString())
        ..close();
    });
  }

  void dumpInfoJson(ProgramInfo info, StringSink buffer) {
    Map<String, dynamic> entire = <String, dynamic>{
      'program': info.toJson(),
      'libs': info.libraries.map((lib) => lib.toJson(info)).toList()
    };

    JsonEncoder encoder = const JsonEncoder();
    ChunkedConversionSink<Object> sink =
      encoder.startChunkedConversion(
          new StringConversionSink.fromStringSink(buffer));
    sink.add(entire);
  }

  void dumpInfoHtml(ProgramInfo info, StringSink buffer) {
    int totalSize = info.size;

    buffer.writeln("""
<html>
  <head>
    <title>Dart2JS compilation information</title>
       <style>
        code {margin-left: 20px; display: block; white-space: pre; }
        div.container, div.contained, div.element, div.attr {
          margin-top:0px;
          margin-bottom: 0px;
        }
        div.container, div.element, div.attr {
          white-space: nowrap;
        }
        .contents {
          margin-left: 20px;
        }
        div.contained {margin-left: 20px;}
        div {/*border: 1px solid;*/}
        span.kind {}
        span.modifiers {font-weight:bold;}
        span.name {font-weight:bold; font-family: monospace;}
        span.type {font-family: monospace; color:blue;}
""");
    for (int i = 0; i < COLORS.length; i++) {
      buffer.writeln("        .outputUnit$i "
          "{border-left: 4px solid ${COLORS[i]}}");
    }
    buffer.writeln("""
       </style>
     </head>
     <body>
       <h1>Dart2js compilation information</h1>""");
    if (info.outputUnitNumbering.length > 1) {
      for (OutputUnit outputUnit in info.outputUnitNumbering.keys) {
        String color = COLORS[info.outputUnitNumbering[outputUnit]
             % COLORS.length];
        JavaScriptBackend backend = compiler.backend;
        int size = backend.emitter.outputBuffers[outputUnit].length;
        buffer.writeln('<div style='
            '"background:$color;">'
            '${outputUnit.partFileName(compiler)} $size bytes</div>');
      }
    }
    buffer.writeln(h2('Compilation took place: '
                      '${info.compilationMoment}'));
    buffer.writeln(h2('Compilation took: '
                      '${info.compilationDuration.inSeconds} seconds'));
    buffer.writeln(h2('Output size: ${info.size} bytes'));
    if (info.dart2jsVersion != null) {
      buffer.writeln(h2('Dart2js version: ${info.dart2jsVersion}'));
    }

    buffer.writeln('<a href="#" class="sort_by_size">Sort by size</a>\n');

    buffer.writeln('<div class="contents">');
    info.libraries.forEach((InfoNode node) {
      node.emitHtml(info, buffer);
    });
    buffer.writeln('</div>');

    // TODO (sigurdm): This script should be written in dart
    buffer.writeln(r"""
    <script type="text/javascript">
      function toggler(element) {
        return function(e) {
          element.hidden = !element.hidden;
        };
      }
      var containers = document.getElementsByClassName('container');
      for (var i = 0; i < containers.length; i++) {
        var container = containers[i];
        container.querySelector('.details').addEventListener('click',
          toggler(container.querySelector('.contents')), false);
        container.querySelector('.contents').hidden = true;
      }

      function sortBySize() {
        var toSort = document.querySelectorAll('.contents');
        for (var i = 0; i < toSort.length; ++i) {
          sortNodes(toSort[i], function(a, b) {
            if (a[1] !== b[1]) {
              return a[1] > b[1] ? -1 : 1;
            }
            return a[2] === b[2] ? 0 : a[2] > b[2] ? 1 : -1;
          });
        }
      }

      function findSize(node) {
        var size = 0;
        var details = node.querySelector('.details');
        if (details) {
          var sizeElement = details.querySelector('.size');
          if (sizeElement) {
            size = parseInt(sizeElement.textContent);
          } else {
            // For classes, sum up the contents for sorting purposes.
            var kind = details.querySelector('.kind');
            if (kind && kind.textContent === 'class') {
              var contents = node.querySelector('.contents');
              if (contents) {
                var child = contents.firstElementChild;
                while (child) {
                  size += findSize(child);
                  child = child.nextElementSibling;
                }
              }
            }
          }
        }
        return size;
      }

      function findName(node) {
        var name = '';
        var nameNode = node.querySelector('.name');
        if (nameNode) {
          return nameNode.textContent;
        }
        return node.textContent;
      }
      function sortNodes(node, fn) {
        var items = [];
        var child = node.firstElementChild;
        while (child) {
          items.push([child, findSize(child), findName(child)]);
          child = child.nextElementSibling;
        }
        items.sort(fn);
        for (var i = 0; i < items.length; ++i) {
          node.appendChild(items[i][0]);
        }
      }
      document.querySelector('.sort_by_size').addEventListener('click',
          function() {
            sortBySize();
          }, false);
    </script>
  </body>
</html>""");
  }
}
