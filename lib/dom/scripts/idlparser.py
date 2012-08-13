#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import re
import subprocess
import tempfile

from pegparser import *

# IDL grammar variants.
WEBIDL_SYNTAX = 0
WEBKIT_SYNTAX = 1
FREMONTCUT_SYNTAX = 2


class IDLParser(object):
  """IDLParser is a PEG based IDL files parser."""

  def __init__(self, syntax=WEBIDL_SYNTAX):
    """Constructor.

    Initializes the IDLParser by defining the grammar and initializing
    a PEGParserinstance.

    Args:
      syntax -- supports either WEBIDL_SYNTAX (0) or WEBKIT_SYNTAX (1)
    """
    self._syntax = syntax
    self._pegparser = PegParser(self._idl_grammar(),
      self._whitespace_grammar(),
      strings_are_tokens=True)

  def _idl_grammar(self):
    """Returns the PEG grammar for IDL parsing."""

    # utilities:
    def syntax_switch(w3c_syntax, webkit_syntax, fremontcut_syntax=None):
      """Returns w3c_syntax or web_syntax, depending on the current
      configuration.
      """
      if self._syntax == WEBIDL_SYNTAX:
        return w3c_syntax
      elif self._syntax == WEBKIT_SYNTAX:
        return webkit_syntax
      elif self._syntax == FREMONTCUT_SYNTAX:
        if fremontcut_syntax is not None:
          return fremontcut_syntax
        return w3c_syntax
      else:
        raise RuntimeError('unsupported IDL syntax %s' % syntax)

    # The following grammar is based on the Web IDL's LL(1) grammar
    # (specified in: http://dev.w3.org/2006/webapi/WebIDL/#idl-grammar).
    # It is adjusted to PEG grammar, as well as to also support
    # WebKit IDL and FremontCut grammar.

    ###################### BEGIN GRAMMAR #####################

    def Id():
      return re.compile(r'[\w\_]+')

    def _Definitions():
      return MAYBE(MANY(_Definition))

    def _Definition():
      return syntax_switch(
        # Web IDL:
        OR(Module, Interface, ExceptionDef, TypeDef, ImplStmt,
           ValueTypeDef, Const),
        # WebKit:
        OR(Module, Interface))

    def Module():
      return syntax_switch(
        # Web IDL:
        [MAYBE(ExtAttrs), 'module', Id, '{', _Definitions, '}',
         MAYBE(';')],
        # WebKit:
        ['module', MAYBE(ExtAttrs), Id, '{', _Definitions, '}',
         MAYBE(';')],
        # FremontCut:
        [MAYBE(_Annotations), MAYBE(ExtAttrs), 'module', Id,
         '{', _Definitions, '}', MAYBE(';')])

    def Interface():
      return syntax_switch(
        # Web IDL:
        [MAYBE(ExtAttrs), 'interface', Id, MAYBE(_ParentInterfaces),
         MAYBE(['{', MAYBE(MANY(_Member)), '}']), ';'],
        # WebKit:
        [OR('interface', 'exception'), MAYBE(ExtAttrs), Id, MAYBE(_ParentInterfaces),
         MAYBE(['{', MAYBE(MANY(_Member)), '}']), MAYBE(';')],
        # FremontCut:
        [MAYBE(_Annotations), MAYBE(ExtAttrs), 'interface',
         Id, MAYBE(_ParentInterfaces), MAYBE(['{', MAYBE(MANY(_Member)),
         '}']), ';'])

    def _Member():
      return syntax_switch(
        # Web IDL:
        OR(Const, Attribute, Operation, ExtAttrs),
        # WebKit:
        OR(Const, Attribute, Operation),
        # FremontCut:
        OR(Const, Attribute, Operation))

    # Interface inheritance:
    def _ParentInterfaces():
      return [':', MANY(ParentInterface, separator=',')]

    def ParentInterface():
      return syntax_switch(
        # Web IDL:
        [InterfaceType],
        # WebKit:
        [InterfaceType],
        # FremontCut:
        [MAYBE(_Annotations), InterfaceType])

    # TypeDef (Web IDL):
    def TypeDef():
      return ['typedef', Type, Id, ';']

    # TypeDef (Old-school W3C IDLs)
    def ValueTypeDef():
      return ['valuetype', Id, Type, ';']

    # Implements Statement (Web IDL):
    def ImplStmt():
      return [ImplStmtImplementor, 'implements', ImplStmtImplemented,
          ';']

    def ImplStmtImplementor():
      return ScopedName

    def ImplStmtImplemented():
      return ScopedName

    # Constants:
    def Const():
      return syntax_switch(
        # Web IDL:
        [MAYBE(ExtAttrs), 'const', Type, Id, '=', ConstExpr, ';'],
        # WebKit:
        [MAYBE(ExtAttrs), 'const', Type, Id, '=', ConstExpr, ';'],
        # FremontCut:
        [MAYBE(_Annotations), MAYBE(ExtAttrs), 'const', Type, Id, '=',
         ConstExpr, ';'])

    def ConstExpr():
      return OR(_BooleanLiteral,
            _IntegerLiteral,
            _FloatLiteral)

    def _BooleanLiteral():
      return re.compile(r'true|false')

    def _IntegerLiteral():
      return OR(re.compile(r'(0x)?[0-9ABCDEF]+'),
            re.compile(r'[0-9]+'))

    def _FloatLiteral():
      return re.compile(r'[0-9]+\.[0-9]*')

    # Attributes:
    def Attribute():
      return syntax_switch(
        # Web IDL:
        [MAYBE(ExtAttrs), MAYBE(Stringifier), MAYBE(ReadOnly),
         'attribute', Type, Id, MAYBE(_AttrRaises), ';'],
        # WebKit:
        [MAYBE(Stringifier), MAYBE(Static), MAYBE(ReadOnly), 'attribute',
         MAYBE(ExtAttrs), Type, Id, MAYBE(_AttrRaises), ';'],
        # FremontCut:
        [MAYBE(_Annotations), MAYBE(ExtAttrs),
         MAYBE(_AttrGetterSetter), MAYBE(Stringifier), MAYBE(ReadOnly),
         'attribute', Type, Id, MAYBE(_AttrRaises), ';'])

    def _AttrRaises():
      return syntax_switch(
        # Web IDL:
        MANY(OR(GetRaises, SetRaises)),
        # WebKit:
        MANY(OR(GetRaises, SetRaises, Raises), separator=','))

    # Special fremontcut feature:
    def _AttrGetterSetter():
      return OR(AttrGetter, AttrSetter)

    def AttrGetter():
      return 'getter'

    def AttrSetter():
      return 'setter'

    def ReadOnly():
      return 'readonly'

    def GetRaises():
      return syntax_switch(
        # Web IDL:
        ['getraises', '(', _ScopedNames, ')'],
        # WebKit:
        ['getter', 'raises', '(', _ScopedNames, ')'])

    def SetRaises():
      return syntax_switch(
        # Web IDL:
        ['setraises', '(', _ScopedNames, ')'],
        # WebKit:
        ['setter', 'raises', '(', _ScopedNames, ')'])

    # Operation:
    def Operation():
      return syntax_switch(
        # Web IDL:
        [MAYBE(ExtAttrs), MAYBE(Static), MAYBE(Stringifier), MAYBE(_Specials),
         ReturnType, MAYBE(Id), '(', _Arguments, ')', MAYBE(Raises),
         ';'],
        # WebKit:
        [MAYBE(ExtAttrs), MAYBE(Static),
         ReturnType, MAYBE(Id), '(', _Arguments, ')',
         MAYBE(Raises), ';'],
        # FremontCut:
        [MAYBE(_Annotations), MAYBE(ExtAttrs), MAYBE(Static), MAYBE(Stringifier),
         MAYBE(_Specials), ReturnType, MAYBE(Id), '(', _Arguments, ')',
         MAYBE(Raises), ';'])

    def Static():
      return 'static'

    def _Specials():
      return MANY(Special)

    def Special():
      return re.compile(r'getter|setter|creator|deleter|caller')

    def Stringifier():
      return 'stringifier'

    def Raises():
      return ['raises', '(', _ScopedNames, ')']

    # Operation arguments:
    def _Arguments():
      return MAYBE(MANY(Argument, ','))

    def Argument():
      return syntax_switch(
        # Web IDL:
        [MAYBE(ExtAttrs), MAYBE(Optional), MAYBE('in'),
         MAYBE(Optional), Type, MAYBE(AnEllipsis), Id],
        # WebKit:
        [MAYBE(Optional), MAYBE('in'), MAYBE(Optional),
         MAYBE(ExtAttrs), Type, Id])

    def Optional():
      return 'optional'

    def AnEllipsis():
      return '...'

    # Exceptions (Web IDL).
    def ExceptionDef():
      return ['exception', Id, '{', MAYBE(MANY(_ExceptionMember)), '}',
          ';']

    def _ExceptionMember():
      return OR(Const, ExceptionField, ExtAttrs)

    def ExceptionField():
      return [Type, Id, ';']

    # Types:
    def Type():
      return _Type

    def ReturnType():
      return OR(VoidType, _Type)

    def InterfaceType():
      return ScopedName

    def ArrayModifiers():
      return re.compile(r'(\[\])+')

    def _Type():
      return OR(
          [OR(AnyType, ObjectType), MAYBE([ArrayModifiers, MAYBE(Nullable)])],
          [_NullableNonArrayType(), MAYBE(ArrayModifiers), MAYBE(Nullable)])

    def _NullableNonArrayType():
      return [OR(_IntegerType, BooleanType, OctetType, FloatType,
             DoubleType, SequenceType, ScopedName)]

    def Nullable():
      return '?'

    def SequenceType():
      return ['sequence', '<', Type, '>']

    def AnyType():
      return 'any'

    def ObjectType():
      return re.compile(r'(object|Object)\b')   # both spellings.

    def VoidType():
      return 'void'

    def _IntegerType():
      return [MAYBE(Unsigned), OR(ByteType, IntType, LongLongType,
                    LongType, OctetType, ShortType)]

    def Unsigned():
      return 'unsigned'

    def ShortType():
      return 'short'

    def LongLongType():
      return ['long', 'long']

    def LongType():
      return 'long'

    def IntType():
      return 'int'

    def ByteType():
      return 'byte'

    def OctetType():
      return 'octet'

    def BooleanType():
      return 'boolean'

    def FloatType():
      return 'float'

    def DoubleType():
      return 'double'

    def _ScopedNames():
      return MANY(ScopedName, separator=',')

    def ScopedName():
      return re.compile(r'[\w\_\:\.\<\>]+')

    # Extended Attributes:
    def ExtAttrs():
      return ['[', MAYBE(MANY(ExtAttr, ',')), ']']

    def ExtAttr():
      return [Id, MAYBE(OR(['=', ExtAttrValue], ExtAttrArgList))]

    def ExtAttrValue():
      return OR(ExtAttrFunctionValue, re.compile(r'[\w&0-9:\-\| ]+'))

    def ExtAttrFunctionValue():
      return [Id, ExtAttrArgList]

    def ExtAttrArgList():
      return ['(', MAYBE(MANY(Argument, ',')), ')']

    # Annotations - used in the FremontCut IDL grammar:
    def _Annotations():
      return MANY(Annotation)

    def Annotation():
      return ['@', Id, MAYBE(_AnnotationBody)]

    def _AnnotationBody():
      return ['(', MAYBE(MANY(AnnotationArg, ',')), ')']

    def AnnotationArg():
      return [Id, MAYBE(['=', AnnotationArgValue])]

    def AnnotationArgValue():
      return re.compile(r'[\w&0-9:/\-\.]+')

    ###################### END GRAMMAR #####################

    # Return the grammar's root rule:
    return MANY(_Definition)

  def _whitespace_grammar(self):
    return OR(re.compile(r'\s+'),
          re.compile(r'//.*'),
          re.compile(r'#.*'),
          re.compile(r'/\*.*?\*/', re.S))

  def _pre_process(self, content, defines, includePaths):
    """Pre-processes the content using gcc.

    WebKit IDLs require pre-processing by gcc. This is done by invoking
    gcc in a sub-process and capturing the results.

    Returns:
      The result of running gcc on the content.

    Args:
      content -- text to process.
      defines -- an array of pre-processor defines.
      includePaths -- an array of path strings.
    """
    # FIXME: Handle gcc not found, or any other processing errors
    gcc = 'gcc'
    cmd = [gcc, '-E', '-P', '-C', '-x', 'c++']
    for define in defines:
      cmd.append('-D%s' % define)
    cmd.append('-')
    pipe = subprocess.Popen(cmd, stdin=subprocess.PIPE,
      stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (content, stderr) = pipe.communicate(content)
    return content

  def parse(self, content, defines=[], includePaths=[]):
    """Parse the give content string.

    The WebKit IDL syntax also allows gcc pre-processing instructions.
    Lists of defined variables and include paths can be provided.

    Returns:
      An abstract syntax tree (AST).

    Args:
      content -- text to parse.
      defines -- an array of pre-processor defines.
      includePaths -- an array of path strings used by the
        gcc pre-processor.
    """
    if self._syntax == WEBKIT_SYNTAX:
      content = self._pre_process(content, defines, includePaths)

    return self._pegparser.parse(content)
