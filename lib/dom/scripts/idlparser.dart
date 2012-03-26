// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IDL grammar variants.
final int WEBIDL_SYNTAX = 0;
final int WEBKIT_SYNTAX = 1;
final int FREMONTCUT_SYNTAX = 2;

/**
 * IDLFile is the top-level node in each IDL file. It may contain modules or
 * interfaces.
 */
class IDLFile extends IDLNode {

  String filename;
  List<IDLModule> modules;
  List<IDLInterface> interfaces;

  IDLFile(this.filename, this.modules, this.interfaces);
}

/**
 * IDLModule has an id, and may contain interfaces, type defs andimplements
 * statements.
 */
class IDLModule extends IDLNode {
  String id;
  List interfaces;
  List typedefs;
  List implementsStatements;

  IDLModule(String this.id, IDLExtAttrs extAttrs, IDLAnnotations annotations,
            List<IDLNode> elements) {
    setExtAttrs(extAttrs);
    this.annotations = annotations;
    this.interfaces = elements.filter((e) => e is IDLInterface);
    this.typedefs = elements.filter((e) => e is IDLTypeDef);
    this.implementsStatements =
        elements.filter((e) => e is IDLImplementsStatement);
  }

  toString() => '<IDLModule $id $extAttrs $annotations>';
}

class IDLNode {
  IDLExtAttrs extAttrs;
  IDLAnnotations annotations;
  IDLNode();

  setExtAttrs(IDLExtAttrs ea) {
    assert(ea != null);
    this.extAttrs = ea != null ? ea : new IDLExtAttrs();
  }
}

class IDLType extends IDLNode {
  String id;
  IDLType parameter;
  bool nullable = false;
  IDLType(String this.id, [IDLType this.parameter, bool this.nullable = false]);

  // TODO: Figure out why this constructor was failing in mysterious ways.
  // IDLType.nullable(IDLType base) {
  //   return new IDLType(base.id, base.parameter, true);
  // }

  //String toString() => '<IDLType $nullable $id $parameter>';
  String toString() {
    String nullableTag = nullable ? '?' : '';
    return '<IDLType $id${parameter == null ? '' : ' $parameter'}$nullableTag>';
  }
}

class IDLTypeDef extends IDLNode {
  String id;
  IDLType type;
  IDLTypeDef(String this.id, IDLType this.type);

  toString() => '<IDLTypeDef $id $type>';
}

class IDLImplementsStatement extends IDLNode {
}

class IDLInterface extends IDLNode {
  String id;
  List parents;
  List operations;
  List attributes;
  List constants;
  List snippets;

  bool isSupplemental;
  bool isNoInterfaceObject;
  bool isFcSuppressed;

  IDLInterface(String this.id, IDLExtAttrs ea, IDLAnnotations ann,
               List this.parents, List members) {
    setExtAttrs(ea);
    this.annotations = ann;
    if (this.parents == null) this.parents = [];

    operations = members.filter((e) => e is IDLOperation);
    attributes = members.filter((e) => e is IDLAttribute);
    constants = members.filter((e) => e is IDLConstant);
    snippets = members.filter((e) => e is IDLSnippet);

    isSupplemental = extAttrs.has('Supplemental');
    isNoInterfaceObject = extAttrs.has('NoInterfaceObject');
    isFcSuppressed = extAttrs.has('Suppressed');
  }

  toString() => '<IDLInterface $id $extAttrs $annotations>';
}

class IDLMember extends IDLNode {
  String id;
  IDLType type;
  bool isFcSuppressed;

  IDLMember(String this.id, IDLType this.type, IDLExtAttrs ea, IDLAnnotations ann) {
    setExtAttrs(ea);
    this.annotations = ann;

    isFcSuppressed = extAttrs.has('Suppressed');
  }
}

class IDLOperation extends IDLMember {
  List arguments;

  // Ignore all forms of raises for now.
  List specials;
  bool isStringifier;

  IDLOperation(String id, IDLType type, IDLExtAttrs ea, IDLAnnotations ann,
               List this.arguments, List this.specials, bool this.isStringifier)
      : super(id, type, ea, ann) {
  }

  toString() => '<IDLOperation $type $id ${printList(arguments)}>';
}

class IDLAttribute extends IDLMember {
}

class IDLConstant extends IDLMember {
  var value;
  IDLConstant(String id, IDLType type, IDLExtAttrs ea, IDLAnnotations ann,
              var this.value)
      : super(id, type, ea, ann);
}

class IDLSnippet extends IDLMember {
  String text;
  IDLSnippet(IDLAnnotations ann, String this.text)
      : super(null, null, new IDLExtAttrs(), ann);
}

/** Maps string to something. */
class IDLDictNode {
  Map<String, Object> map;
  IDLDictNode() {
    map = new Map<String, Object>();
  }

  setMap(List associationList) {
    if (associationList == null) return;
    for (var element in associationList) {
      var name = element[0];
      var value = element[1];
      map[name] = value;
    }
  }

  bool has(String key) => map.containsKey(key);

  formatMap() {
    if (map.isEmpty())
      return '';
    StringBuffer sb = new StringBuffer();
    map.forEach((k, v) {
        sb.add(' $k');
        if (v != null) {
          sb.add('=$v');
        }
      });
    return sb.toString();
  }

}

class IDLExtAttrs extends IDLDictNode {
  IDLExtAttrs([List attrs = const []]) : super() {
    setMap(attrs);
  }

  toString() => '<IDLExtAttrs${formatMap()}>';
}

class IDLArgument extends IDLNode {
  String id;
  IDLType type;
  bool isOptional;
  bool isIn;
  bool hasElipsis;
  IDLArgument(String this.id, IDLType this.type, IDLExtAttrs extAttrs,
              bool this.isOptional, bool this.isIn, bool this.hasElipsis) {
    setExtAttrs(extAttrs);
  }

  toString() => '<IDLArgument $id>';
}

class IDLAnnotations extends IDLDictNode {
  IDLAnnotations(List annotations) : super() {
    for (var annotation in annotations) {
      map[annotation.id] = annotation;
    }
  }

  toString() => '<IDLAnnotations${formatMap()}>';
}

class IDLAnnotation extends IDLDictNode {
  String id;
  IDLAnnotation(String this.id, List args) : super() {
    setMap(args);
  }

  toString() => '<IDLAnnotation $id${formatMap()}>';
}

class IDLExtAttrFunctionValue extends IDLNode {
  String name;
  List arguments;
  IDLExtAttrFunctionValue(String this.name, this.arguments);

  toString() => '<IDLExtAttrFunctionValue $name(${arguments.length})>';
}

class IDLParentInterface extends IDLNode {}

////////////////////////////////////////////////////////////////////////////////

class IDLParser {
  final int syntax;
  Grammar grammar;
  var axiom;

  IDLParser([syntax=WEBIDL_SYNTAX]) : syntax = syntax {
    grammar = new Grammar();
    axiom = _makeParser();
  }

  syntax_switch([WebIDL, WebKit, FremontCut]) {
    assert(WebIDL != null && WebKit != null);  // Not options, just want names.
    if (syntax == WEBIDL_SYNTAX)
      return WebIDL;
    if (syntax == WEBKIT_SYNTAX)
      return WebKit;
    if (syntax == FREMONTCUT_SYNTAX)
      return FremontCut == null ?  WebIDL : FremontCut;
    throw new Exception('unsupported IDL syntax $syntax');
  }

  _makeParser() {
    Grammar g = grammar;

    // TODO: move syntax_switch back to here.

    var idStartCharSet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_';
    var idNextCharSet = idStartCharSet + '0123456789';
    var hexCharSet = '0123456789ABCDEFabcdef';

    var idStartChar = CHAR(idStartCharSet);
    var idNextChar = CHAR(idNextCharSet);

    var digit = CHAR('0123456789');

    var Id = TEXT(LEX('an identifier',[idStartChar, MANY(idNextChar, min:0)]));

    var IN = SKIP(LEX("'in'", ['in',NOT(idNextChar)]));

    var BooleanLiteral = OR(['true', 'false']);
    var IntegerLiteral = TEXT(LEX('hex-literal', OR([['0x', MANY(CHAR(hexCharSet))],
                                      [MANY(digit)]])));
    var FloatLiteral = TEXT(LEX('float-literal', [MANY(digit), '.', MANY(digit, min:0)]));


    var Argument = g['Argument'];
    var Module = g['Module'];
    var Member = g['Member'];
    var Interface = g['Interface'];
    var ExceptionDef = g['ExceptionDef'];
    var Type = g['Type'];
    var TypeDef = g['TypeDef'];
    var ImplStmt = g['ImplStmt'];
    var ValueTypeDef = g['ValueTypeDef'];
    var Const = g['Const'];
    var Attribute = g['Attribute'];
    var Operation = g['Operation'];
    var Snippet = g['Snippet'];
    var ExtAttrs = g['ExtAttrs'];
    var MaybeExtAttrs = g['MaybeExtAttrs'];
    var MaybeAnnotations = g['MaybeAnnotations'];
    var ParentInterfaces = g['ParentInterfaces'];


    final ScopedName = TEXT(LEX('scoped-name', MANY(CHAR(idStartCharSet + '_:.<>'))));

    final ScopedNames = MANY(ScopedName, separator:',');

    // Types

    final IntegerTypeName = OR([
        ['byte', () => 'byte'],
        ['int', () => 'int'],
        ['long', 'long', () => 'long long'],
        ['long', () => 'long'],
        ['octet', () => 'octet'],
        ['short', () => 'short']]);

    final IntegerType = OR([
        ['unsigned', IntegerTypeName, (name) => new IDLType('unsigned $name')],
        [IntegerTypeName, (name) => new IDLType(name)]]);

    final BooleanType = ['boolean', () => new IDLType('boolean')];
    final OctetType = ['octet', () => new IDLType('octet')];
    final FloatType = ['float', () => new IDLType('float')];
    final DoubleType = ['double', () => new IDLType('double')];

    final SequenceType = ['sequence', '<', Type, '>',
                          (type) => new IDLType('sequence', type)];

    final ScopedNameType = [ScopedName, (name) => new IDLType(name)];

    final NullableType =
        [OR([IntegerType, BooleanType, OctetType, FloatType,
             DoubleType, SequenceType, ScopedNameType]),
         MAYBE('?'),
         (type, nullable) =>
             nullable ? new IDLType(type.id, type.parameter, true) : type];

    final VoidType = ['void', () => new IDLType('void')];
    final AnyType = ['any', () => new IDLType('any')];
    final ObjectType = ['object', () => new IDLType('object')];

    Type.def = OR([AnyType, ObjectType, NullableType]);

    final ReturnType = OR([VoidType, Type]);

    var Definition = syntax_switch(
        WebIDL: OR([Module, Interface, ExceptionDef, TypeDef, ImplStmt,
                    ValueTypeDef, Const]),
        WebKit: OR([Module, Interface]));

    var Definitions = MANY(Definition, min:0);

    Module.def = syntax_switch(
        WebIDL: [MaybeExtAttrs, 'module', Id, '{', Definitions, '}',
                 SKIP(MAYBE(';')),
                 (ea, id, defs) => new IDLModule(id, ea, null, defs)],
        WebKit: ['module', MaybeExtAttrs, Id, '{', Definitions, '}',
                 SKIP(MAYBE(';')),
                 (ea, id, defs) => new IDLModule(id, ea, null, defs)],
        FremontCut: [MaybeAnnotations, MaybeExtAttrs, 'module', Id,
                     '{', Definitions, '}', SKIP(MAYBE(';')),
                     (ann, ea, id, defs) => new IDLModule(id, ea, ann, defs)]);

    Interface.def = syntax_switch(
        WebIDL: [MaybeExtAttrs, 'interface', Id, MAYBE(ParentInterfaces),
                 MAYBE(['{', MANY0(Member), '}']), ';',
                 (ea, id, p, ms) => new IDLInterface(id, ea, null, p, ms)],
        WebKit: ['interface', MaybeExtAttrs, Id, MAYBE(ParentInterfaces),
                 MAYBE(['{', MANY0(Member), '}']), ';',
                 (ea, id, p, ms) => new IDLInterface(id, ea, null, p, ms)],
        FremontCut: [MaybeAnnotations, MaybeExtAttrs, 'interface',
                     Id, MAYBE(ParentInterfaces),
                     MAYBE(['{', MANY0(Member), '}']), ';',
                     (ann, ea, id, p, ms) => new IDLInterface(id, ea, ann, p, ms)]);

    Member.def = syntax_switch(
        WebIDL: OR([Const, Attribute, Operation, ExtAttrs]),
        WebKit: OR([Const, Attribute, Operation]),
        FremontCut: OR([Const, Attribute, Operation, Snippet]));

    var InterfaceType = ScopedName;

    var ParentInterface = syntax_switch(
        WebIDL: [InterfaceType],
        WebKit: [InterfaceType],
        FremontCut: [MaybeAnnotations, InterfaceType]);

    ParentInterfaces.def = [':', MANY(ParentInterface, ',')];

    // TypeDef (Web IDL):
    TypeDef.def = ['typedef', Type, Id, ';', (type, id) => new IDLTypeDef(id, type)];

    // TypeDef (Old-school W3C IDLs)
    ValueTypeDef.def = ['valuetype', Id, Type, ';'];

    // Implements Statement (Web IDL):
    var ImplStmtImplementor = ScopedName;
    var ImplStmtImplemented = ScopedName;

    ImplStmt.def = [ImplStmtImplementor, 'implements', ImplStmtImplemented, ';'];

    var ConstExpr = OR([BooleanLiteral, IntegerLiteral, FloatLiteral]);

    Const.def = syntax_switch(
        WebIDL: [MaybeExtAttrs, 'const', Type, Id, '=', ConstExpr, ';',
                 (ea, type, id, v) => new IDLConstant(id, type, ea, null, v)],
        WebKit: ['const', MaybeExtAttrs, Type, Id, '=', ConstExpr, ';',
                 (ea, type, id, v) => new IDLConstant(id, type, ea, null, v)],
        FremontCut: [MaybeAnnotations, MaybeExtAttrs,
                     'const', Type, Id, '=', ConstExpr, ';',
                     (ann, ea, type, id, v) =>
                         new IDLConstant(id, type, ea, ann, v)]);

    // Attributes

    var Stringifier = 'stringifier';
    var AttrGetter = 'getter';
    var AttrSetter = 'setter';
    var ReadOnly = 'readonly';
    var AttrGetterSetter = OR([AttrGetter, AttrSetter]);

    var GetRaises = syntax_switch(
        WebIDL: ['getraises', '(', ScopedNames, ')'],
        WebKit: ['getter', 'raises', '(', ScopedNames, ')']);

    var SetRaises = syntax_switch(
        WebIDL: ['setraises', '(', ScopedNames, ')'],
        WebKit: ['setter', 'raises', '(', ScopedNames, ')']);

    var Raises = ['raises', '(', ScopedNames, ')'];

    var AttrRaises = syntax_switch(
        WebIDL: MANY(OR([GetRaises, SetRaises])),
        WebKit: MANY(OR([GetRaises, SetRaises, Raises]), separator:','));

    Attribute.def = syntax_switch(
        WebIDL: [MaybeExtAttrs, MAYBE(Stringifier), MAYBE(ReadOnly),
                 'attribute', Type, Id, MAYBE(AttrRaises), ';'],
        WebKit: [MAYBE(Stringifier), MAYBE(ReadOnly), 'attribute',
                 MaybeExtAttrs, Type, Id, MAYBE(AttrRaises), ';'],
        FremontCut: [MaybeAnnotations, MaybeExtAttrs,
                     MAYBE(AttrGetterSetter), MAYBE(Stringifier), MAYBE(ReadOnly),
                     'attribute', Type, Id, MAYBE(AttrRaises), ';'
                     ]);

    // Operations

    final Special = TEXT(OR(['getter', 'setter', 'creator', 'deleter', 'caller']));
    final Specials = MANY(Special);

    final Optional = 'optional';
    final AnEllipsis = '...';

    Argument.def = syntax_switch(
        WebIDL: SEQ(MaybeExtAttrs, MAYBE(Optional), MAYBE(IN),
                    MAYBE(Optional), Type, MAYBE(AnEllipsis), Id,
                    (e, opt1, isin, opt2, type, el, id) =>
                        new IDLArgument(id, type, e, opt1 || opt2, isin, el)),

        WebKit: SEQ(MAYBE(Optional), MAYBE('in'), MAYBE(Optional),
                    MaybeExtAttrs, Type, Id
                    (opt1, isin, opt2, e, type, id) =>
                        new IDLArgument(id, type, e, opt1 || opt2, isin, false)));

    final Arguments = MANY0(Argument, ',');

    Operation.def = syntax_switch(
        WebIDL: [MaybeExtAttrs, MAYBE(Stringifier), MAYBE(Specials),
                 ReturnType, MAYBE(Id), '(', Arguments, ')', MAYBE(Raises), ';',
                 (ea, isStringifier, specials, type, id, args, raises) =>
                     new IDLOperation(id, type, ea, null, args, specials, isStringifier)
                 ],
        WebKit: [MaybeExtAttrs, ReturnType, MAYBE(Id), '(', Arguments, ')',
                 MAYBE(Raises), ';',
                 (ea, type, id, args, raises) =>
                     new IDLOperation(id, type, ea, null, args, [], false)
                 ],
        FremontCut: [MaybeAnnotations, MaybeExtAttrs, MAYBE(Stringifier),
                     MAYBE(Specials), ReturnType, MAYBE(Id), '(', Arguments, ')',
                     MAYBE(Raises), ';',
                     (ann, ea, isStringifier, specials, type, id, args, raises) =>
                       new IDLOperation(id, type, ea, ann, args, specials, isStringifier)
                     ]);

    // Exceptions

    final ExceptionField = [Type, Id, ';'];
    final ExceptionMember = OR([Const, ExceptionField, ExtAttrs]);
    ExceptionDef.def = ['exception', Id, '{', MANY0(ExceptionMember), '}', ';'];

    // ExtendedAttributes

    var ExtAttrArgList = ['(', MANY0(Argument, ','), ')'];

    var ExtAttrFunctionValue =
        [Id, '(', MANY0(Argument, ','), ')',
         (name, args) => new IDLExtAttrFunctionValue(name, args)
         ];

    var ExtAttrValue = OR([ExtAttrFunctionValue,
                           TEXT(LEX('value', MANY(CHAR(idNextCharSet + '&:-|'))))]);

    var ExtAttr = [Id, MAYBE(OR([['=', ExtAttrValue], ExtAttrArgList]))];

    ExtAttrs.def = ['[', MANY(ExtAttr, ','), ']',
                    (list) => new IDLExtAttrs(list)];;

    MaybeExtAttrs.def = OR(ExtAttrs,
                           [ () => new IDLExtAttrs() ] );

    // Annotations - used in the FremontCut IDL grammar.

    var AnnotationArgValue = TEXT(LEX('xx', MANY(CHAR(idNextCharSet + '&:-|'))));

    var AnnotationArg = [Id, MAYBE(['=', AnnotationArgValue])];

    var AnnotationBody = ['(', MANY0(AnnotationArg, ','), ')'];

    var Annotation = ['@', Id, MAYBE(AnnotationBody),
                      (id, body) => new IDLAnnotation(id, body)];

    MaybeAnnotations.def = [MANY0(Annotation), (list) => new IDLAnnotations(list)];

    // Snippets - used in the FremontCut IDL grammar.

    final SnippetText = TEXT(LEX('snippet body', MANY0([NOT('}'), CHAR()])));
    Snippet.def = [MaybeAnnotations, 'snippet', '{', SnippetText, '}', ';',
                   (ann, text) => new IDLSnippet(ann, text)];


    grammar.whitespace =
        OR([MANY(CHAR(' \t\r\n')),
            ['//', MANY0([NOT(CHAR('\r\n')), CHAR()])],
            ['#', MANY0([NOT(CHAR('\r\n')), CHAR()])],
            ['/*', MANY0([NOT('*/'), CHAR()]), '*/']]);

    // Top level - at least one definition.
    return MANY(Definition);

  }
}
