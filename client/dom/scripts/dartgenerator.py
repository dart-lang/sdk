#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module generates Dart APIs from the IDL database."""

import emitter
import idlnode
import logging
import multiemitter
import os
import re
import shutil
import snippet_manager

_logger = logging.getLogger('dartgenerator')

# IDL->Dart primitive types conversion.
_idl_to_dart_type_conversions = {
    'any': 'Object',
    'custom': 'Dynamic',
    'boolean': 'bool',
    'DOMObject': 'Object',
    'DOMString': 'String',
    'DOMStringList': 'List<String>',
    'DOMTimeStamp': 'int',
    'Date': 'Date',
    # Map to num to enable callers to pass in Dart int, rational
    # types.  Our implementations will need to convert these to
    # doubles or floats as needed.
    'double': 'num',
    'float': 'num',
    'int': 'int',
    # Map to extra precision - int is a bignum in Dart.
    'long': 'int',
    'long long': 'int',
    'object': 'Object',
    # Map to extra precision - int is a bignum in Dart.
    'short': 'int',
    'string': 'String',
    'void': 'void',
    'Array': 'List',
    'sequence': 'List',
    # TODO(vsm): We need to support other types. We could weaken to
    # Object, or inject SSV into the appropriate types.
    'SerializedScriptValue': 'String',
    # TODO(vsm): Automatically recognize types defined in src.
    'TimeoutHandler': 'TimeoutHandler',
    'RequestAnimationFrameCallback': 'RequestAnimationFrameCallback',
    }

_dart_to_idl_type_conversions = dict((v,k) for k, v in
                                     _idl_to_dart_type_conversions.iteritems())

#
# Types which are unreachable until we call something that returns an instance.
#
_evasive_types = set(['CanvasPixelArray',
                      'ImageData',  # Not really unreachable, testing multi-hop
                      'Notification',
                      'NotificationCenter',
                      'TouchList',
                      'Touch'
                      ])

#
# Types with user-invocable constructors.  We do not have enough
# information in IDL to create the signature.
#
# Each entry is of the form:
#   type name: constructor parameters
_constructable_types = {
    'AudioContext': '',
    'FileReader': '',
    'XMLHttpRequest': '',
    'WebKitCSSMatrix': '[String spec]',
    'WebKitPoint': 'num x, num y',
    # dart:html types
    'CSSMatrix': '[String spec]',
    'Point': 'num x, num y',
}

#
# Interface version of the DOM needs to delegate typed array constructors to a
# factory provider.
#
_interface_factories = {
    'Float32Array': '_TypedArrayFactoryProvider',
    'Float64Array': '_TypedArrayFactoryProvider',
    'Int8Array': '_TypedArrayFactoryProvider',
    'Int16Array': '_TypedArrayFactoryProvider',
    'Int32Array': '_TypedArrayFactoryProvider',
    'Uint8Array': '_TypedArrayFactoryProvider',
    'Uint16Array': '_TypedArrayFactoryProvider',
    'Uint32Array': '_TypedArrayFactoryProvider',
}

#
# Custom methods that must be implemented by hand.
#
_custom_methods = set([
    ('DOMWindow', 'setInterval'),
    ('DOMWindow', 'setTimeout'),
    ('WorkerContext', 'setInterval'),
    ('WorkerContext', 'setTimeout'),
    ('CanvasRenderingContext2D', 'setFillStyle'),
    ('CanvasRenderingContext2D', 'setStrokeStyle'),
    ('CanvasRenderingContext2D', 'setFillStyle'),
    ])

#
# Custom getters that must be implemented by hand.
#
_custom_getters = set([
    ('DOMWindow', 'localStorage'),
    ])

#
# Custom native specs for the Frog dom.
#
_frog_dom_custom_native_specs = {
    'Console': '=console',      # Decorate the singleton Console object.
    'DOMWindow': '@*DOMWindow', # DOMWindow aliased with global scope.

    # Temporary hack: make these not be 'hidden'.  Will not work on IE9.
    'Float32Array': 'Float32Array',
    'Float64Array': 'Float64Array',
    'Int8Array': 'Int8Array',
    'Int16Array': 'Int16Array',
    'Int32Array': 'Int32Array',
    'Uint8Array': 'Uint8Array',
    'Uint16Array': 'Uint16Array',
    'Uint32Array': 'Uint32Array',
}

#
# Publically visible types common across all supported browsers.
#
_BROWSER_SHARED_TYPES = [
        'Attr',
        'CDATASection',
        'CSSFontFaceRule',
        'CSSImportRule',
        'CSSMediaRule',
        'CSSPageRule',
        'CSSRule',
        'CSSRuleList',
        'CSSStyleDeclaration',
        'CSSStyleRule',
        'CSSStyleSheet',
        'CanvasRenderingContext2D',
        'CharacterData',
        'ClientRect',
        'ClientRectList',
        'Comment',
        'DOMException',
        'DOMImplementation',
        'DOMParser',
        'Document',
        'DocumentFragment',
        'DocumentType',
        'Element',
        'Event',
        'EventException',
        'HTMLAnchorElement',
        'HTMLAppletElement',
        'HTMLAreaElement',
        'HTMLAudioElement',
        'HTMLBRElement',
        'HTMLBaseElement',
        'HTMLBodyElement',
        'HTMLButtonElement',
        'HTMLCanvasElement',
        'HTMLCollection',
        'HTMLDListElement',
        'HTMLDirectoryElement',
        'HTMLDivElement',
        'HTMLElement',
        'HTMLEmbedElement',
        'HTMLFieldSetElement',
        'HTMLFontElement',
        'HTMLFormElement',
        'HTMLFrameElement',
        'HTMLFrameSetElement',
        'HTMLHRElement',
        'HTMLHeadElement',
        'HTMLHeadingElement',
        'HTMLHtmlElement',
        'HTMLIFrameElement',
        'HTMLImageElement',
        'HTMLInputElement',
        'HTMLLIElement',
        'HTMLLabelElement',
        'HTMLLegendElement',
        'HTMLLinkElement',
        'HTMLMapElement',
        'HTMLMediaElement',
        'HTMLMenuElement',
        'HTMLMetaElement',
        'HTMLModElement',
        'HTMLOListElement',
        'HTMLObjectElement',
        'HTMLOptGroupElement',
        'HTMLOptionElement',
        'HTMLParagraphElement',
        'HTMLParamElement',
        'HTMLPreElement',
        'HTMLQuoteElement',
        'HTMLScriptElement',
        'HTMLSelectElement',
        'HTMLStyleElement',
        'HTMLTableCaptionElement',
        'HTMLTableCellElement',
        'HTMLTableColElement',
        'HTMLTableElement',
        'HTMLTableRowElement',
        'HTMLTableSectionElement',
        'HTMLTextAreaElement',
        'HTMLTitleElement',
        'HTMLUListElement',
        'HTMLVideoElement',
        'KeyboardEvent',
        'MediaError',
        'MediaList',
        'MessageEvent',
        'MouseEvent',
        'MutationEvent',
        'NamedNodeMap',
        'Node',
        'NodeFilter',
        'NodeList',
        'ProcessingInstruction',
        'Range',
        'RangeException',
        'SVGAElement',
        'SVGAngle',
        'SVGAnimatedAngle',
        'SVGAnimatedBoolean',
        'SVGAnimatedEnumeration',
        'SVGAnimatedInteger',
        'SVGAnimatedLength',
        'SVGAnimatedLengthList',
        'SVGAnimatedNumber',
        'SVGAnimatedNumberList',
        'SVGAnimatedPreserveAspectRatio',
        'SVGAnimatedRect',
        'SVGAnimatedString',
        'SVGAnimatedTransformList',
        'SVGCircleElement',
        'SVGClipPathElement',
        'SVGDefsElement',
        'SVGDescElement',
        'SVGElement',
        'SVGEllipseElement',
        'SVGException',
        'SVGGElement',
        'SVGGradientElement',
        'SVGImageElement',
        'SVGLength',
        'SVGLengthList',
        'SVGLineElement',
        'SVGLinearGradientElement',
        'SVGMarkerElement',
        'SVGMaskElement',
        'SVGMatrix',
        'SVGMetadataElement',
        'SVGNumber',
        'SVGNumberList',
        'SVGPathElement',
        'SVGPathSeg',
        'SVGPathSegArcAbs',
        'SVGPathSegArcRel',
        'SVGPathSegClosePath',
        'SVGPathSegCurvetoCubicAbs',
        'SVGPathSegCurvetoCubicRel',
        'SVGPathSegCurvetoCubicSmoothAbs',
        'SVGPathSegCurvetoCubicSmoothRel',
        'SVGPathSegCurvetoQuadraticAbs',
        'SVGPathSegCurvetoQuadraticRel',
        'SVGPathSegCurvetoQuadraticSmoothAbs',
        'SVGPathSegCurvetoQuadraticSmoothRel',
        'SVGPathSegLinetoAbs',
        'SVGPathSegLinetoHorizontalAbs',
        'SVGPathSegLinetoHorizontalRel',
        'SVGPathSegLinetoRel',
        'SVGPathSegLinetoVerticalAbs',
        'SVGPathSegLinetoVerticalRel',
        'SVGPathSegList',
        'SVGPathSegMovetoAbs',
        'SVGPathSegMovetoRel',
        'SVGPatternElement',
        'SVGPoint',
        'SVGPointList',
        'SVGPolygonElement',
        'SVGPolylineElement',
        'SVGPreserveAspectRatio',
        'SVGRadialGradientElement',
        'SVGRect',
        'SVGRectElement',
        'SVGSVGElement',
        'SVGScriptElement',
        'SVGStopElement',
        'SVGStyleElement',
        'SVGSwitchElement',
        'SVGSymbolElement',
        'SVGTSpanElement',
        'SVGTextContentElement',
        'SVGTextElement',
        'SVGTextPathElement',
        'SVGTextPositioningElement',
        'SVGTitleElement',
        'SVGTransform',
        'SVGTransformList',
        'SVGUnitTypes',
        'SVGUseElement',
        'SVGZoomEvent',
        'Storage',
        'StorageEvent',
        'StyleSheet',
        'StyleSheetList',
        'Text',
        'TextMetrics',
        'UIEvent',
        'XMLHttpRequest',
        'XMLSerializer',
]

#
# Simple method substitution when one method had different names on different
# browsers, but are otherwise identical.  The alternates are tried in order and
# the first one defined is used.
#
# This can be probably be removed when Chrome renames initWebKitWheelEvent to
# initWheelEvent.
#
_alternate_methods = {
    ('WheelEvent', 'initWheelEvent'): ['initWebKitWheelEvent', 'initWheelEvent']
}

def _MatchSourceFilter(filter, thing):
  if not filter:
    return True
  else:
    return any(token in thing.annotations for token in filter)

def _IsDartListType(type):
  return type == 'List' or type.startswith('List<')

def _IsDartCollectionType(type):
  return _IsDartListType(type)


class DartGenerator(object):
  """Utilities to generate Dart APIs and corresponding JavaScript."""

  def __init__(self, auxiliary_dir, snippet_dir, base_package):
    """Constructor for the DartGenerator.

    Args:
      auxiliary_dir -- location of auxiliary handwritten classes
      snippet_dir -- location of implementation snippets
      base_package -- the base package name for the generated code.
    """
    self._auxiliary_dir = auxiliary_dir
    self._snippet_manager = snippet_manager.SnippetManager(snippet_dir)
    self._base_package = base_package
    self._auxiliary_files = {}
    self._dart_templates_re = re.compile(r'[\w.:]+<([\w\.<>:]+)>')

    self._emitters = None  # set later


  def _StripModules(self, type_name):
    return type_name.split('::')[-1]

  def _IsPrimitiveType(self, type_name):
    return (self._ConvertPrimitiveType(type_name) is not None or
            type_name in _dart_to_idl_type_conversions)

  def _IsCompoundType(self, database, type_name):
    if self._IsPrimitiveType(type_name):
      return True

    striped_type_name = self._StripModules(type_name)
    if database.HasInterface(striped_type_name):
      return True

    dart_template_match = self._dart_templates_re.match(type_name)
    if dart_template_match:
      # Dart templates
      parent_type_name = type_name[0 : dart_template_match.start(1) - 1]
      sub_type_name = dart_template_match.group(1)
      return (self._IsCompoundType(database, parent_type_name) and
              self._IsCompoundType(database, sub_type_name))
    return False

  def _IsDartType(self, type_name):
    return '.' in type_name

  def _ConvertPrimitiveType(self, type_name):
    if type_name.startswith('unsigned '):
      type_name = type_name[len('unsigned '):]

    if type_name in _idl_to_dart_type_conversions:
      # Primitive type conversion
      return _idl_to_dart_type_conversions[type_name]
    return None

  def LoadAuxiliary(self):
    def Visitor(_, dirname, names):
      for name in names:
        if name.endswith('.dart'):
          name = name[0:-5]  # strip off ".dart"
        self._auxiliary_files[name] = os.path.join(dirname, name)
    os.path.walk(self._auxiliary_dir, Visitor, None)

  def RenameTypes(self, database, conversion_table=None):
    """Renames interfaces using the given conversion table.

    References through all interfaces will be renamed as well.

    Args:
      database: the database to apply the renames to.
      conversion_table: maps old names to new names.
    """

    if conversion_table is None:
      conversion_table = {}

    # Rename interfaces:
    for old_name, new_name in conversion_table.items():
      if database.HasInterface(old_name):
        _logger.info('renaming interface %s to %s' %
                     (old_name, new_name))
        interface = database.GetInterface(old_name)
        database.DeleteInterface(old_name)
        if not database.HasInterface(new_name):
          interface.id = new_name
          database.AddInterface(interface)

    # Fix references:
    for interface in database.GetInterfaces():
      for idl_type in interface.all(idlnode.IDLType):
        type_name = self._StripModules(idl_type.id)
        if type_name in conversion_table:
          idl_type.id = conversion_table[type_name]

  def FilterMembersWithUnidentifiedTypes(self, database):
    """Removes unidentified types.

    Removes constants, attributes, operations and parents with unidentified
    types.
    """

    for interface in database.GetInterfaces():
      def IsIdentified(idl_node):
        node_name = idl_node.id if idl_node.id else 'parent'
        for idl_type in idl_node.all(idlnode.IDLType):
          type_name = idl_type.id
          if (type_name is not None and
              self._IsCompoundType(database, type_name)):
            continue
          _logger.warn('removing %s in %s which has unidentified type %s' %
                       (node_name, interface.id, type_name))
          return False
        return True

      interface.constants = filter(IsIdentified, interface.constants)
      interface.attributes = filter(IsIdentified, interface.attributes)
      interface.operations = filter(IsIdentified, interface.operations)
      interface.parents = filter(IsIdentified, interface.parents)

  def ConvertToDartTypes(self, database):
    """Converts all IDL types to Dart primitives or qualified types"""

    def ConvertType(interface, type_name):
      """Helper method for converting a type name to the proper
      Dart name"""
      if self._IsPrimitiveType(type_name):
        return self._ConvertPrimitiveType(type_name)

      if self._IsDartType(type_name):
        # This is for when dart qualified names are explicitly
        # defined in the IDLs. Just let them be.
        return type_name

      dart_template_match = self._dart_templates_re.match(type_name)
      if dart_template_match:
        # Dart templates
        parent_type_name = type_name[0 : dart_template_match.start(1) - 1]
        sub_type_name = dart_template_match.group(1)
        return '%s<%s>' % (ConvertType(interface, parent_type_name),
                           ConvertType(interface, sub_type_name))

      return self._StripModules(type_name)

    for interface in database.GetInterfaces():
      for idl_type in interface.all(idlnode.IDLType):
        idl_type.id = ConvertType(interface, idl_type.id)

  def FilterInterfaces(self, database,
                       and_annotations=[],
                       or_annotations=[],
                       exclude_displaced=[],
                       exclude_suppressed=[]):
    """Filters a database to remove interfaces and members that are missing
    annotations.

    The FremontCut IDLs use annotations to specify implementation
    status in various platforms. For example, if a member is annotated
    with @WebKit, this means that the member is supported by WebKit.

    Args:
      database -- the database to filter
      all_annotations -- a list of annotation names a member has to
        have or it will be filtered.
      or_annotations -- if a member has one of these annotations, it
        won't be filtered even if it is missing some of the
        all_annotations.
      exclude_displaced -- if a member has this annotation and it
        is marked as displaced it will always be filtered.
      exclude_suppressed -- if a member has this annotation and it
        is marked as suppressed it will always be filtered.
    """

    # Filter interfaces and members whose annotations don't match.
    for interface in database.GetInterfaces():
      def HasAnnotations(idl_node):
        """Utility for determining if an IDLNode has all
        the required annotations"""
        for a in exclude_displaced:
          if (a in idl_node.annotations
              and 'via' in idl_node.annotations[a]):
            return False
        for a in exclude_suppressed:
          if (a in idl_node.annotations
              and 'suppressed' in idl_node.annotations[a]):
            return False
        for a in or_annotations:
          if a in idl_node.annotations:
            return True
        if and_annotations == []:
          return False
        for a in and_annotations:
          if a not in idl_node.annotations:
            return False
        return True

      if HasAnnotations(interface):
        interface.constants = filter(HasAnnotations, interface.constants)
        interface.attributes = filter(HasAnnotations, interface.attributes)
        interface.operations = filter(HasAnnotations, interface.operations)
        interface.parents = filter(HasAnnotations, interface.parents)
        interface.snippets = filter(HasAnnotations, interface.snippets)
      else:
        database.DeleteInterface(interface.id)

    self.FilterMembersWithUnidentifiedTypes(database)


  def Generate(self, database, output_dir,
               module_source_preference=[], source_filter=None,
               super_database=None, common_prefix=None, super_map={},
               lib_dir = None):
    """Generates Dart and JS files for the loaded interfaces.

    Args:
      database -- database containing interfaces to generate code for.
      output_dir -- directory to write generated files to.
      module_source_preference -- priority order list of source annotations to
        use when choosing a module name, if none specified uses the module name
        from the database.
      source_filter -- if specified, only outputs interfaces that have one of
        these source annotation and rewrites the names of superclasses not
        marked with this source to use the common prefix.
      super_database -- database containing super interfaces that the generated
        interfaces should extend.
      common_prefix -- prefix for the common library, if any.
      lib_file_path -- filename for generated .lib file, None if not required.
      lib_template -- template file in this directory for generated lib file.
    """

    self._emitters = multiemitter.MultiEmitter()
    self._database = database
    self._output_dir = output_dir
    self._dart_callback_file_paths = []

    self._StartGenerateInterfaceLibrary()
    self._StartGenerateJavaScriptMonkeyImpl(output_dir)
    self._StartGenerateWrappingImpl(output_dir)
    self._StartGenerateFrogImpl(output_dir)

    # Render all interfaces into Dart and save them in files.
    dart_file_paths = []
    processed_interfaces = []
    for interface in database.GetInterfaces():

      super_interface = None
      super_name = interface.id

      if not _MatchSourceFilter(source_filter, interface):
        # Skip this interface since it's not present in the required source
        _logger.info('Omitting interface - %s' % interface.id)
        continue

      if super_name in super_map:
        super_name = super_map[super_name]

      if (super_database is not None and
          super_database.HasInterface(super_name)):
        super_interface = super_name

      interface_name = interface.id
      auxiliary_file = self._auxiliary_files.get(interface_name)
      if auxiliary_file is not None:
        _logger.info('Skipping %s because %s exists' % (
            interface_name, auxiliary_file))
        continue


      info = self._RecognizeCallback(interface)
      if info:
        self._ProcessCallback(interface, info)
      else:
        if 'Callback' in interface.ext_attrs:
          _logger.info('Malformed callback: %s' % interface.id)
        self._ProcessInterface(interface, super_interface,
                               source_filter, common_prefix)
      processed_interfaces.append(interface)

    self._GenerateBrowserAnalysis(processed_interfaces, output_dir)


    # Libraries
    if lib_dir:
      # New version: Monkey-patching interface library.
      self.GenerateLibFile('template_monkey_dom.darttemplate',
                           os.path.join(lib_dir, 'monkey_dom.dart'),
                           self._dart_interface_file_paths +
                           self._dart_callback_file_paths)

      # New version: Wrapping implementation combined interface and
      # implementation library.
      self.GenerateLibFile('template_wrapping_dom.darttemplate',
                           os.path.join(lib_dir, 'wrapping_dom.dart'),
                           (self._dart_interface_file_paths +
                            self._dart_callback_file_paths +
                            # FIXME: Move the implementation to a separate
                            # library.
                            self._dart_wrapping_file_paths))

      # New version: Frog
      self.GenerateLibFile('template_frog_dom.darttemplate',
                           os.path.join(lib_dir, 'frog_dom.dart'),
                           self._dart_frog_file_paths +
                           self._dart_callback_file_paths)


    # JavaScript externs files
    self._GenerateJavaScriptExternsMonkey(database, output_dir)
    self._GenerateJavaScriptExternsWrapping(database, output_dir)


  def _RecognizeCallback(self, interface):
    """Returns the info for the callback method if the interface smells like a
    callback.
    """
    if 'Callback' not in interface.ext_attrs: return None
    handlers = [op for op in interface.operations if op.id == 'handleEvent']
    if not handlers: return None
    if not (handlers == interface.operations): return None
    return self._AnalyzeOperation(interface, handlers)

  def _ProcessCallback(self, interface, info):
    """Generates a typedef for the callback interface."""
    interface_name = interface.id
    file_path = self.FilePathForDartInterface(interface_name)
    self._dart_callback_file_paths.append(file_path)
    code = self._emitters.FileEmitter(file_path)

    template_file = 'template_callback.darttemplate'
    code.Emit(''.join(open(template_file).readlines()))
    code.Emit('typedef $TYPE $NAME($ARGS);\n',
              NAME=interface.id,
              TYPE=info.type_name,
              ARGS=info.arg_implementation_declaration)


  def _ProcessInterface(self, interface, super_interface_name,
                        source_filter,
                        common_prefix):
    """."""
    _logger.info('Generating %s' % interface.id)

    dart_interface_generator = self._MakeDartInterfaceGenerator(
        interface,
        common_prefix,
        super_interface_name,
        source_filter)

    monkey_interface_generator = self._MakeMonkeyInterfaceGenerator(interface)

    wrapping_interface_generator = self._MakeWrappingImplInterfaceGenerator(
        interface,
        common_prefix,
        super_interface_name,
        source_filter)

    frog_interface_generator = self._MakeFrogImplInterfaceGenerator(
        interface,
        common_prefix,
        super_interface_name,
        source_filter)

    generators = [dart_interface_generator,
                  monkey_interface_generator,
                  wrapping_interface_generator,
                  frog_interface_generator]

    for generator in generators:
      generator.StartInterface()

    for const in sorted(interface.constants, ConstantOutputOrder):
      for generator in generators:
        generator.AddConstant(const)

    for attr in sorted(interface.attributes, AttributeOutputOrder):
      if attr.type.id == 'EventListener': continue
      if attr.is_fc_getter:
        for generator in generators:
          generator.AddGetter(attr)
      elif attr.is_fc_setter:
        for generator in generators:
          generator.AddSetter(attr)

    # The implementation should define an indexer if the interface directly
    # extends List.
    element_type = MaybeListElementType(interface)
    if element_type:
      for generator in generators:
        generator.AddIndexer(element_type)

    # Group overloaded operations by id
    operationsById = {}
    for operation in interface.operations:
      if operation.id not in operationsById:
        operationsById[operation.id] = []
      operationsById[operation.id].append(operation)

    # Generate operations
    for id in sorted(operationsById.keys()):
      operations = operationsById[id]
      info = self._AnalyzeOperation(interface, operations)
      for generator in generators:
        generator.AddOperation(info)

    # With multiple inheritance, attributes and operations of non-first
    # interfaces need to be added.  Sometimes the attribute or operation is
    # defined in the current interface as well as a parent.  In that case we
    # avoid making a duplicate definition and pray that the signatures match.

    for parent_interface in self._TransitiveSecondaryParents(interface):
      if isinstance(parent_interface, str):  # _IsDartCollectionType(parent_interface)
        continue
      attributes = sorted(parent_interface.attributes,
                          AttributeOutputOrder)
      for attr in attributes:
        if not self._DefinesSameAttribute(interface, attr):
          if attr.is_fc_getter:
            for generator in generators:
              generator.AddSecondaryGetter(parent_interface, attr)
          elif attr.is_fc_setter:
            for generator in generators:
              generator.AddSecondarySetter(parent_interface, attr)

      # Group overloaded operations by id
      operationsById = {}
      for operation in parent_interface.operations:
        if operation.id not in operationsById:
          operationsById[operation.id] = []
        operationsById[operation.id].append(operation)

      # Generate operations
      for id in sorted(operationsById.keys()):
        if not any(op.id == id for op in interface.operations):
          operations = operationsById[id]
          info = self._AnalyzeOperation(interface, operations)
          for generator in generators:
            generator.AddSecondaryOperation(parent_interface, info)

    for generator in generators:
      generator.FinishInterface()
    return

  def _DefinesSameAttribute(self, interface, attr1):
    return any(attr1.id == attr2.id
               and attr1.is_fc_getter == attr2.is_fc_getter
               and attr1.is_fc_setter == attr2.is_fc_setter
               for attr2 in interface.attributes)

  def _TransitiveSecondaryParents(self, interface):
    """Returns a list of all non-primary parents.

    The list contains the interface objects for interfaces defined in the
    database, and the name for undefined interfaces.
    """
    def walk(parents):
      for parent in parents:
        if _IsDartCollectionType(parent.type.id):
          result.append(parent.type.id)
          continue
        if self._database.HasInterface(parent.type.id):
          parent_interface = self._database.GetInterface(parent.type.id)
          result.append(parent_interface)
          walk(parent_interface.parents)

    result = []
    walk(interface.parents[1:])
    return result;

  def _AnalyzeOperation(self, interface, operations):
    """Makes operation calling convention decision for a set of overloads.

    Returns: An OperationInfo object.
    """

    # Zip together arguments from each overload by position, then convert
    # to a dart argument.

    # Given a list of overloaded arguments, choose a suitable name.
    def OverloadedName(args):
      return '_OR_'.join(sorted(set(arg.id for arg in args)))

    # Given a list of overloaded arguments, choose a suitable type.
    def OverloadedType(args):
      typeIds = sorted(set(arg.type.id for arg in args))
      if len(typeIds) == 1:
        return typeIds[0]
      else:
        return TypeName(typeIds, interface)

    # Given a list of overloaded arguments, render a dart argument.
    def DartArg(args):
      filtered = filter(None, args)
      optional = any(not arg or arg.is_optional for arg in args)
      type = OverloadedType(filtered)
      name = OverloadedName(filtered)
      if optional:
        return (name, type, 'null')
      else:
        return (name, type, None)

    def FormatArg(arg_info):
      """Returns an argument declaration fragment for an argument info tuple."""
      (name, type, default) = arg_info
      if default:
        return '%s %s = %s' % (type, name, default)
      else:
        return '%s %s' % (type, name)

    def FormatArgs(args, is_interface):
      required = []
      optional = []
      for (name, type, default) in args:
        if default:
          if is_interface:
            optional.append((name, type, None))
          else:
            optional.append((name, type, default))
        else:
          if optional:
            raise Exception('Optional arguments cannot precede required ones: '
                            + str(args))
          required.append((name, type, None))
      argtexts = map(FormatArg, required)
      if optional:
        argtexts.append('[' + ', '.join(map(FormatArg, optional)) + ']')
      return ', '.join(argtexts)

    args = map(lambda *args: DartArg(args),
               *(op.arguments for op in operations))

    info = OperationInfo()
    info.overloads = operations
    info.declared_name = operations[0].id
    info.name = operations[0].ext_attrs.get('DartName', info.declared_name)
    info.js_name = operations[0].ext_attrs.get('ImplementationFunction',
                                               info.declared_name)
    info.type_name = operations[0].type.id   # TODO: widen.
    info.arg_interface_declaration = FormatArgs(args, True)
    info.arg_implementation_declaration = FormatArgs(args, False)
    info.arg_infos = args
    return info


  def GenerateOldLibFile(self, lib_template, lib_file_path, file_paths):
    """Generates a lib file from a template and a list of files."""
    # Generate the .lib file.
    if lib_file_path:
      # Load template.
      template = ''.join(open(lib_template).readlines())
      lib_file_contents = self._emitters.FileEmitter(lib_file_path)

      # Emit the list of path names.
      list_emitter = lib_file_contents.Emit(template)
      lib_file_dir = os.path.dirname(lib_file_path)
      for path in sorted(file_paths):
        relpath = os.path.relpath(path, lib_file_dir)
        list_emitter.Emit("\n    '$PATH',", PATH=relpath)

  def GenerateLibFile(self, lib_template, lib_file_path, file_paths):
    """Generates a lib file from a template and a list of files."""
    # Load template.
    template = ''.join(open(lib_template).readlines())
    # Generate the .lib file.
    lib_file_contents = self._emitters.FileEmitter(lib_file_path)

    # Emit the list of #source directives.
    list_emitter = lib_file_contents.Emit(template)
    lib_file_dir = os.path.dirname(lib_file_path)
    for path in sorted(file_paths):
      relpath = os.path.relpath(path, lib_file_dir)
      list_emitter.Emit("#source('$PATH');\n", PATH=relpath)


  def Flush(self):
    """Write out all pending files."""
    _logger.info('Flush...')
    self._emitters.Flush()


  def FilePathForDartInterface(self, interface_name):
    """Returns the file path of the Dart interface definition."""
    return os.path.join(self._output_dir, 'src', 'interface',
                        '%s.dart' % interface_name)


  def FilePathForDartWrappingImpl(self, interface_name):
    """Returns the file path of the Dart wrapping implementation."""
    return os.path.join(self._output_dir, 'src', 'wrapping',
                        '_%sWrappingImplementation.dart' % interface_name)

  def FilePathForFrogImpl(self, interface_name):
    """Returns the file path of the Frog implementation."""
    return os.path.join(self._output_dir, 'src', 'frog',
                        '%s.dart' % interface_name)


  def _StartGenerateInterfaceLibrary(self):
    """."""
    self._dart_interface_file_paths = []
    self._dart_wrapping_file_paths = []
    self._dart_frog_file_paths = []


  def _MakeDartInterfaceGenerator(self,
                                  interface,
                                  common_prefix,
                                  super_interface_name,
                                  source_filter):
    """."""
    interface_name = interface.id
    dart_interface_file_path = self.FilePathForDartInterface(interface_name)

    self._dart_interface_file_paths.append(dart_interface_file_path)

    dart_interface_code = self._emitters.FileEmitter(dart_interface_file_path)

    template_file = 'template_interface_%s.darttemplate' % interface_name
    if not os.path.exists(template_file):
      template_file = 'template_interface.darttemplate'
    template = ''.join(open(template_file).readlines())

    snippet = self._snippet_manager.snippet_map.get(interface_name)

    return DartInterfaceGenerator(
        interface, dart_interface_code,
        template,
        snippet, common_prefix, super_interface_name,
        source_filter)


  def _StartGenerateWrappingImpl(self, output_dir):
    """Prepared for generating wrapping implementation.

    - Creates emitter for JS code.
    - Creates emitter for Dart code.
    """
    js_file_name = os.path.join(output_dir, 'wrapping_dom.js')
    code = self._emitters.FileEmitter(js_file_name)
    template = ''.join(open('template_wrapping_dom.js').readlines())
    (self._wrapping_js_natives,
     self._wrapping_map) = code.Emit(template)

    _logger.info('Started Generating %s' % js_file_name)

    # Set of (interface, name, kind), kind is 'attribute' or 'operation'.
    self._wrapping_externs = set()


  def _MakeWrappingImplInterfaceGenerator(self,
                                          interface,
                                          common_prefix,
                                          super_interface_name,
                                          source_filter):
    """."""
    interface_name = interface.id
    dart_wrapping_file_path = self.FilePathForDartWrappingImpl(interface_name)

    self._dart_wrapping_file_paths.append(dart_wrapping_file_path)

    dart_code = self._emitters.FileEmitter(dart_wrapping_file_path)
    dart_code.Emit(
        ''.join(open('template_wrapping_impl.darttemplate').readlines()))
    return WrappingInterfaceGenerator(interface, super_interface_name,
                                      dart_code, self._wrapping_js_natives,
                                      self._wrapping_map,
                                      self._wrapping_externs,
                                      self._BaseDefines(interface))

  def _BaseDefines(self, interface):
    """Returns a set of names (strings) for members defined in a base class.
    """
    def WalkParentChain(interface):
      if interface.parents:
        # Only consider primary parent, secondary parents are not on the
        # implementation class inheritance chain.
        parent = interface.parents[0]
        if _IsDartCollectionType(parent.type.id):
          return
        if self._database.HasInterface(parent.type.id):
          parent_interface = self._database.GetInterface(parent.type.id)
          for attr in parent_interface.attributes:
            result.add(attr.id)
          for op in parent_interface.operations:
            result.add(op.id)
          WalkParentChain(parent_interface)

    result = set()
    WalkParentChain(interface)
    return result;


  def _StartGenerateFrogImpl(self, output_dir):
    """Prepared for generating frog implementation.
    """
    self._interface_names_with_subtypes = set()
    for interface in self._database.GetInterfaces():
      for parent in interface.parents:
        self._interface_names_with_subtypes.add(parent.type.id)

  def _MakeFrogImplInterfaceGenerator(self,
                                      interface,
                                      common_prefix,
                                      super_interface_name,
                                      source_filter):
    """."""
    interface_name = interface.id
    dart_frog_file_path = self.FilePathForFrogImpl(interface_name)

    self._dart_frog_file_paths.append(dart_frog_file_path)

    dart_code = self._emitters.FileEmitter(dart_frog_file_path)
    dart_code.Emit(
        ''.join(open('template_frog_impl.darttemplate').readlines()))
    return FrogInterfaceGenerator(interface, super_interface_name,
                                  self._interface_names_with_subtypes,
                                  dart_code)


  def _StartGenerateJavaScriptMonkeyImpl(self, output_dir):
    """Generate a JavaScript implementation that is coherent with
    generated Dart APIs.
    """
    self._ComputeInheritanceClosure()
    js_file_name = os.path.join(output_dir, 'monkey_dom.js')
    code = self._emitters.FileEmitter(js_file_name)

    template = ''.join(open('template_monkey_dom.js').readlines())

    (self._monkey_global_code,
     self._monkey_init_sequence) = code.Emit(template)

    self._monkey_init_sequence.Emit('var $TEMP;\n', TEMP='_')
    self._protomap = self._GenerateProtoMap()

    _logger.info('Started Generating %s' % js_file_name)

  def _MakeMonkeyInterfaceGenerator(self, interface):
    """Generate JavaScript patch code to match DartC output.
    """
    return MonkeyInterfaceGenerator(self,
                                    interface,
                                    self._monkey_global_code,
                                    self._monkey_init_sequence)

  def _ComputeInheritanceClosure(self):
    def Collect(interface, seen, collected):
      name = interface.id
      if '<' in name:
        # TODO(sra): Handle parameterized types.
        return
      if not name in seen:
        seen.add(name)
        collected.append(name)
        for parent in interface.parents:
          # TODO(sra): Handle parameterized types.
          if not '<' in parent.type.id:
            if self._database.HasInterface(parent.type.id):
              Collect(self._database.GetInterface(parent.type.id),
                      seen, collected)

    self._inheritance_closure = {}
    for interface in self._database.GetInterfaces():
      seen = set()
      collected = []
      Collect(interface, seen, collected)
      self._inheritance_closure[interface.id] = collected

  def _AllImplementedInterfaces(self, interface):
    """Returns a list of the names of all interfaces implemented by 'interface'.
    List includes the name of 'interface'.
    """
    return self._inheritance_closure[interface.id]

  def _GenerateProtoMap(self):
    """Determine which DOM type prototypes can be obtained
    from window properties.
    """
    window = None
    for interface in self._database.GetInterfaces():
      if interface.id == 'DOMWindow':
        window = interface
    prototype_table = {}
    boring_type_ids = set(['bool', 'int', 'Number', 'String'])
    if window:
      for attr in window.attributes:
        if attr.is_fc_getter:
          if attr.type.id not in boring_type_ids:
            prototype_table[attr.type.id] = [attr.id]

    # Manual fixups
    prototype_table['EventListener'] = ['onload']  # avoid webkit specific.
    prototype_table['PerformanceMemoryInfo'] = ['performance', 'memory']
    prototype_table['PerformanceNavigation'] = ['performance', 'navigation']
    prototype_table['PerformanceTiming'] = ['performance', 'timing']

    return prototype_table

  def _GenerateJavaScriptExternsWrapping(self, database, output_dir):
    """Generates a JavaScript externs file.

    Generates an externs file that is consistent with generated JavaScript code
    and Dart APIs for the wrapping implementation.
    """
    externs_file_name = os.path.join(output_dir, 'wrapping_dom_externs.js')
    code = self._emitters.FileEmitter(externs_file_name)
    _logger.info('Started generating %s' % externs_file_name)

    template = ''.join(open('template_wrapping_dom_externs.js').readlines())
    namespace = 'dom_externs'
    members = code.Emit(template, NAMESPACE=namespace)

    # TODO: Filter out externs that are known to the JavaScript back-end.  Some
    # of the known externs have useful declarations like @nosideeffects that
    # might improve back-end analysis.

    names = dict()  # maps name to (interface, kind)
    for (interface, name, kind) in self._wrapping_externs:
      if name not in names:
        names[name] = set()
      names[name].add((interface, kind))

    for name in sorted(names.keys()):
      # Simply export the property name.
      extern = emitter.Format('$NAMESPACE.$NAME;',
                              NAMESPACE=namespace, NAME=name)
      members.EmitRaw(extern)
      # Add a big comment of all the attributes and operations contributing to
      # the export.
      filler = ' ' * (40 - 2 - len(extern))  # '2' for 2 spaces before comment.
      separator = filler + '  //'
      for (interface, kind) in sorted(names[name]):
        members.Emit('$SEP $KIND $INTERFACE.$NAME',
                     NAME=name, INTERFACE=interface, KIND=kind, SEP=separator)
        separator = ','
      members.Emit('\n')

  def _GenerateJavaScriptExternsMonkey(self, database, output_dir):
    """Generates a JavaScript externs file.

    Generates an externs file that is consistent with generated JavaScript code
    and Dart APIs for the monkey-patching implementation.
    """
    js_file_name = os.path.join(output_dir, 'monkey_dom_externs.js')
    code = self._emitters.FileEmitter(js_file_name)

    template = ''.join(open('template_monkey_dom_externs.js').readlines())
    namespace = 'dart_externs'
    (window_code, defs_code) = code.Emit(template, NAMESPACE=namespace)

    self._GenerateJavaScriptExternInterfaces(
        database, namespace, window_code, defs_code)

    _logger.info('Generated %s' % js_file_name)

  def _GenerateJavaScriptExternInterfaces(self,
                                          database,
                                          namespace,
                                          window_code,
                                          prop_code):
    """Generate externs for JavaScript patch code.
    """

    props = set()

    for interface in database.GetInterfaces():
      self._GatherInterfacePropertyNames(interface, props)

    for name in sorted(list(props)):
      prop_code.Emit('$NAMESPACE.prototype.$NAME;\n',
                     NAMESPACE=namespace, NAME=name)

    for interface in database.GetInterfaces():
      window_code.Emit('Window.prototype.$CLASSREF;\n',
                       CLASSREF=interface.id)


  def _GatherInterfacePropertyNames(self, interface, props):
    """Gather the properties that will be defined on the interface.
    """

    # Define getters and setters.
    getters = [attr.id for attr in interface.attributes if attr.is_fc_getter]
    setters = [attr.id for attr in interface.attributes if attr.is_fc_setter]

    for name in getters:
       props.add(name + '$getter')

    for name in setters:
       props.add(name + '$setter')

    # Define members.
    operations = [op.ext_attrs.get('DartName', op.id)
                  for op in interface.operations]
    members = sorted(set(operations))
    for name in members:
       props.add(name + '$member')


  def _GenerateBrowserAnalysis(self, interfaces, output_dir):
    """Generate a JavaScript file that provides info from the browser.
    """
    js_file_name = os.path.join(output_dir, 'browser_analysis.html')
    code = self._emitters.FileEmitter(js_file_name)

    template = """<head>
<script>
function addText(e, text) {
  var node = document.createElement('text');
  node.innerHTML = String(text);
  e.appendChild(node);
}
function check() {
  var supported = [];
  var missing = [];
$!CHECKS
  addText(document.getElementById('agent'), navigator.userAgent);

  function fill(tag, elems) {
    addText(document.getElementById(tag + '_count'), elems.length);
    for (var i = 0; i < elems.length; ++i) {
      var e = document.createElement('div');
      e.innerHTML = '&nbsp;&nbsp;"' + elems[i] + '",'
      document.getElementById(tag).appendChild(e);
    }
  }
  fill('supported', supported);
  fill('missing', missing);
}
window.onload = check;
</script>
</head>
<div>
{ 'userAgent': '<span id='agent'></span>',
</div>
<div>
'supported': [ // (<span id='supported_count'></span>)
<div id='supported' style='font-size: -2;'></div>
],</div>
<div>
'missing':  [ // (<span id='missing_count'></span>)
<div id='missing' style='font-size: -2;'></div>
]}</div>

"""
    checks = code.Emit(template)
    names = sorted(interface.id for interface in interfaces)
    for id in names:
      checks.Emit(
          '  if (typeof $ID == "undefined")\n'
          '    missing.push("$ID");\n'
          '  else\n'
          '    supported.push("$ID");\n',
          ID=id);


class OperationInfo(object):
  """Holder for various derived information from a set of overloaded operations.

  Attributes:
    overloads: A list of IDL operation overloads with the same name.
    name: A string, the simple name of the operation.
    type_name: A string, the name of the return type of the operation.
    arg_declarations: A list of strings, Dart argument declarations for the
        member that implements the set of overloads.  Each string is of the form
        "T arg" or "T arg = null".
    arg_infos: A list of (name, type, default_value) tuples.
        default_value is None for mandatory arguments.
  """
  pass


def MaybeListElementType(interface):
  """Returns the List element type T, or None in interface does not implement
  List<T>.
  """
  for parent in interface.parents:
    match = re.match(r'List<(\w*)>$', parent.type.id)
    if match:
      return match.group(1)
  return None

def MaybeTypedArrayElementType(interface):
  """Returns the typed array element type, or None in interface is not a
  TypedArray.
  """
  # Typed arrays implement ArrayBufferView and List<T>.
  for parent in interface.parents:
    if  parent.type.id == 'ArrayBufferView':
      return MaybeListElementType(interface)
  return None


def AttributeOutputOrder(a, b):
  """Canonical output ordering for attributes."""
    # Getters before setters:
  if a.id < b.id: return -1
  if a.id > b.id: return 1
  if a.is_fc_setter < b.is_fc_setter: return -1
  if a.is_fc_setter > b.is_fc_setter: return 1
  return 0

def ConstantOutputOrder(a, b):
  """Canonical output ordering for constants."""
  if a.id < b.id: return -1
  if a.id > b.id: return 1
  return 0


def _FormatNameList(names):
  """Returns JavaScript array literal expression with one name per line."""
  #names = sorted(names)
  if len(names) <= 1:
    expression_string = str(names)  # e.g.  ['length']
  else:
    expression_string = ',\n   '.join(str(names).split(','))
    expression_string = expression_string.replace('[', '[\n    ')
  return expression_string


def IndentText(text, indent):
  """Format lines of text with indent."""
  def FormatLine(line):
    if line.strip():
      return '%s%s\n' % (indent, line)
    else:
      return '\n'
  return ''.join(FormatLine(line) for line in text.split('\n'))

# ------------------------------------------------------------------------------

class DartInterfaceGenerator(object):
  """Generates Dart Interface definition for one DOM IDL interface."""

  def __init__(self, interface, emitter, template,
               extra_snippets, common_prefix, super_interface, source_filter):
    """Generates Dart code for the given interface.

    Args:
      interface -- an IDLInterface instance. It is assumed that all types have
        been converted to Dart types (e.g. int, String), unless they are in the
        same package as the interface.
      extra_snippets -- additional snippet text with method signatures that were
        extracted from the implementation snippet file
      common_prefix -- the prefix for the common library, if any.
      super_interface -- the name of the common interface that this interface
        implements, if any.
      source_filter -- if specified, rewrites the names of any superinterfaces
        that are not from these sources to use the common prefix.
    """
    self._interface = interface
    self._emitter = emitter
    self._template = template
    self._extra_snippets = extra_snippets
    self._common_prefix = common_prefix
    self._super_interface = super_interface
    self._source_filter = source_filter


  def StartInterface(self):
    if self._super_interface:
      typename = self._super_interface
    else:
      typename = self._interface.id

    # TODO(vsm): Add appropriate package / namespace syntax.
    (extends_emitter,
     self._members_emitter,
     self._top_level_emitter) = self._emitter.Emit(
         self._template + '$!TOP_LEVEL',
         ID=typename)

    extends = []
    suppressed_extends = []

    for parent in self._interface.parents:
      # TODO(vsm): Remove source_filter.
      if _MatchSourceFilter(self._source_filter, parent):
        # Parent is a DOM type.
        extends.append(parent.type.id)
      elif '<' in parent.type.id:
        # Parent is a Dart collection type.
        # TODO(vsm): Make this check more robust.
        extends.append(parent.type.id)
      else:
        suppressed_extends.append('%s.%s' %
                                  (self._common_prefix, parent.type.id))

    comment = ' extends'
    if extends:
      extends_emitter.Emit(' extends $SUPERS', SUPERS=', '.join(extends))
      comment = ','
    if suppressed_extends:
      extends_emitter.Emit(' /*$COMMENT $SUPERS */',
                           COMMENT=comment,
                           SUPERS=', '.join(suppressed_extends))

    if typename in _interface_factories:
      extends_emitter.Emit(' factory $F', F=_interface_factories[typename])

    element_type = MaybeTypedArrayElementType(self._interface)
    if element_type:
      self._members_emitter.Emit(
          '\n'
          '  $CTOR(int length);\n'
          '\n'
          '  $CTOR.fromList(List<$TYPE> list);\n'
          '\n'
          '  $CTOR.fromBuffer(ArrayBuffer buffer);\n',
        CTOR=self._interface.id,
        TYPE=element_type)


  def FinishInterface(self):
    # Write snippet text that was inlined in the IDL.
    for snippet in self._interface.snippets:
      self._members_emitter.Emit('\n$LINES',
                                 LINES=IndentText(snippets.text, '  '))

    # TODO(vsm): Test if snippets are extra methods or extra types.
    # Since Dart doesn't permit inner types, append after the interface.
    # Consider moving these types to auxilary classes instead.
    if self._extra_snippets is not None:
      if 'interface' in self._extra_snippets:
        self._top_level_emitter.Emit('\n$TEXT', TEXT=self._extra_snippets)
      else:
        self._members_emitter.Emit('\n$TEXT',
                                   TEXT=IndentText(self._extra_snippets, '  '))

    # TODO(vsm): Use typedef if / when that is supported in Dart.
    # Define variant as subtype.
    if (self._super_interface and
        self._interface.id is not self._super_interface):
      consts_emitter = self._top_level_emitter.Emit(
          '\n'
          'interface $NAME extends $BASE {\n'
          '$!CONSTS'
          '}\n',
          NAME=self._interface.id,
          BASE=self._super_interface)
      for const in sorted(self._interface.constants, ConstantOutputOrder):
        self._EmitConstant(consts_emitter, const)

  def AddConstant(self, constant):
    if (not self._super_interface or
        self._interface.id is self._super_interface):
      self._EmitConstant(self._members_emitter, constant)

  def _EmitConstant(self, emitter, constant):
    emitter.Emit('\n  static final $TYPE $NAME = $VALUE;\n',
                 NAME=constant.id,
                 TYPE=constant.type.id,
                 VALUE=constant.value)

  def AddGetter(self, attr):
    self._members_emitter.Emit('\n  $TYPE get $NAME();\n',
                               NAME=attr.id, TYPE=attr.type.id)

  def AddSetter(self, attr):
    self._members_emitter.Emit('\n  void set $NAME($TYPE value);\n',
                               NAME=attr.id, TYPE=attr.type.id)

  def AddIndexer(self, element_type):
    # Interface inherits all operations from List<element_type>.
    pass

  def AddOperation(self, info):
    """
    Arguments:
      operations - contains the overloads, one or more operations with the same
        name.
    """
    self._members_emitter.Emit('\n'
                               '  $TYPE $NAME($ARGS);\n',
                               TYPE=info.type_name,
                               NAME=info.name,
                               ARGS=info.arg_interface_declaration)

  # Interfaces get secondary members directly via the superinterfaces.
  def AddSecondaryGetter(self, interface, attr):
    pass
  def AddSecondarySetter(self, interface, attr):
    pass
  def AddSecondaryOperation(self, interface, attr):
    pass


# Given a sorted sequence of type identifiers, return an appropriate type
# name
def TypeName(typeIds, interface):
  # Dynamically type this field for now.
  return 'var'


# ------------------------------------------------------------------------------

class WrappingInterfaceGenerator(object):
  """Generates Dart and JS implementation for one DOM IDL interface."""

  def __init__(self, interface, super_interface, dart_code, js_code, type_map,
               externs, base_members):
    """Generates Dart and JS code for the given interface.

    Args:

      interface: an IDLInterface instance. It is assumed that all types have
          been converted to Dart types (e.g. int, String), unless they are in
          the same package as the interface.
      super_interface: A string or None, the name of the common interface that
         this interface implements, if any.
      dart_code: an Emitter for the file containing the Dart implementation
          class.
      js_code: an Emitter for the file containing JS code.
      type_map: an Emitter for the map from tokens to wrapper factory.
      externs: a set of (class, property, kind) externs.  kind is 'attribute' or
          'operation'.
      base_members: a set of names of members defined in a base class.  This is
          used to avoid static member 'overriding' in the generated Dart code.
    """
    self._interface = interface
    self._super_interface = super_interface
    self._dart_code = dart_code
    self._js_code = js_code
    self._type_map = type_map
    self._externs = externs
    self._base_members = base_members
    self._current_secondary_parent = None


  def StartInterface(self):
    interface = self._interface
    interface_name = interface.id

    self._class_name = self._ImplClassName(interface_name)
    self._type_map.Emit('  "$INTERFACE": native_$(CLASS)_create_$(CLASS),\n',
                        INTERFACE=interface_name, CLASS=self._class_name)

    base = 'DOMWrapperBase'
    if interface.parents:
      supertype = interface.parents[0].type.id
      # FIXME: We're currently injecting List<..> and EventTarget as
      # supertypes in dart.idl. We should annotate/preserve as
      # attributes instead.  For now, this hack lets the interfaces
      # inherit, but not the classes.
      if (not _IsDartListType(supertype) and
          not supertype == 'EventTarget'):
        base = self._ImplClassName(supertype)
      if _IsDartCollectionType(supertype):
        # List methods are injected in AddIndexer.
        pass
      elif supertype == 'EventTarget':
        # Most implementors of EventTarget specify the EventListener operations
        # again.  If the operations are not specified, try to inherit from the
        # EventTarget implementation.
        #
        # Applies to MessagePort.
        if not [op for op in interface.operations if op.id == 'addEventListener']:
          base = self._ImplClassName(supertype)
      else:
        base = self._ImplClassName(supertype)

    (self._members_emitter,
     self._top_level_emitter) = self._dart_code.Emit(
        '\n'
        'class $CLASS extends $BASE implements $INTERFACE {\n'
        '  $CLASS() : super() {}\n'
        '\n'
        '  static create_$CLASS() native {\n'
        '    return new $CLASS();\n'
        '  }\n'
        '$!MEMBERS'
        '\n'
        '  String get typeName() { return "$INTERFACE"; }\n'
        '}\n'
        '$!TOP_LEVEL',
        CLASS=self._class_name, BASE=base, INTERFACE=interface_name)

  def _ImplClassName(self, type_name):
    return '_' + type_name + 'WrappingImplementation'

  def FinishInterface(self):
    """."""
    pass

  def AddConstant(self, constant):
    # Constants are already defined on the interface.
    pass

  def _MethodName(self, prefix, name):
    method_name = prefix + name
    if name in self._base_members:  # Avoid illegal Dart 'static override'.
      method_name = method_name + '_' + self._interface.id
    return method_name

  def AddGetter(self, attr):
    # FIXME: Instead of injecting the interface name into the method when it is
    # also implemented in the base class, suppress the method altogether if it
    # has the same signature.  I.e., let the JS do the virtual dispatch instead.
    method_name = self._MethodName('_get_', attr.id)
    self._members_emitter.Emit(
        '\n'
        '  $TYPE get $NAME() { return $METHOD(this); }\n'
        '  static $TYPE $METHOD(var _this) native;\n',
        NAME=attr.id, TYPE=attr.type.id, METHOD=method_name)
    if (self._interface.id, attr.id) not in _custom_getters:
      self._js_code.Emit(
          '\n'
          'function native_$(CLASS)_$(METHOD)(_this) {\n'
          '  try {\n'
          '    return __dom_wrap(_this.$dom.$NAME);\n'
          '  } catch (e) {\n'
          '    throw __dom_wrap_exception(e);\n'
          '  }\n'
          '}\n',
          CLASS=self._class_name, NAME=attr.id, METHOD=method_name)
      self._externs.add((self._interface.id, attr.id, 'attribute'))

  def AddSetter(self, attr):
    # FIXME: See comment on getter.
    method_name = self._MethodName('_set_', attr.id)
    self._members_emitter.Emit(
        '\n'
        '  void set $NAME($TYPE value) { $METHOD(this, value); }\n'
        '  static void $METHOD(var _this, $TYPE value) native;\n',
        NAME=attr.id, TYPE=attr.type.id, METHOD=method_name)
    self._js_code.Emit(
        '\n'
        'function native_$(CLASS)_$(METHOD)(_this, value) {\n'
        '  try {\n'
        '    _this.$dom.$NAME = __dom_unwrap(value);\n'
        '  } catch (e) {\n'
        '    throw __dom_wrap_exception(e);\n'
        '  }\n'
        '}\n',
        CLASS=self._class_name, NAME=attr.id, METHOD=method_name)
    self._externs.add((self._interface.id, attr.id, 'attribute'))

  def AddSecondaryGetter(self, interface, attr):
    self._SecondaryContext(interface)
    self.AddGetter(attr)

  def AddSecondarySetter(self, interface, attr):
    self._SecondaryContext(interface)
    self.AddSetter(attr)

  def AddSecondaryOperation(self, interface, info):
    self._SecondaryContext(interface)
    self.AddOperation(info)

  def _SecondaryContext(self, interface):
    if interface is not self._current_secondary_parent:
      self._current_secondary_parent = interface
      self._members_emitter.Emit('\n  // From $WHERE\n', WHERE=interface.id)

  def AddIndexer(self, element_type):
    """Adds all the methods required to complete implementation of List."""
    # We would like to simply inherit the implementation of everything except
    # get length(), [], and maybe []=.  It is possible to extend from a base
    # array implementation class only when there is no other implementation
    # inheritance.  There might be no implementation inheritance other than
    # DOMBaseWrapper for many classes, but there might be some where the
    # array-ness is introduced by a non-root interface:
    #
    #   interface Y extends X, List<T> ...
    #
    # In the non-root case we have to choose between:
    #
    #   class YImpl extends XImpl { add List<T> methods; }
    #
    # and
    #
    #   class YImpl extends ListBase<T> { copies of transitive XImpl methods; }
    #
    if ('HasIndexGetter' in self._interface.ext_attrs or
        'HasNumericIndexGetter' in self._interface.ext_attrs):
      method_name = '_index'
      self._members_emitter.Emit(
          '\n'
          '  $TYPE operator[](int index) { return $METHOD(this, index); }\n'
          '  static $TYPE $METHOD(var _this, int index) native;\n',
          TYPE=element_type, METHOD=method_name)
      self._js_code.Emit(
          '\n'
          'function native_$(CLASS)_$(METHOD)(_this, index) {\n'
          '  try {\n'
          '    return __dom_wrap(_this.$dom[index]);\n'
          '  } catch (e) {\n'
          '    throw __dom_wrap_exception(e);\n'
          '  }\n'
          '}\n',
          CLASS=self._class_name, METHOD=method_name)
    else:
      self._members_emitter.Emit(
          '\n'
          '  $TYPE operator[](int index) {\n'
          '    return item(index);\n'
          '  }\n',
          TYPE=element_type)


    if 'HasCustomIndexSetter' in self._interface.ext_attrs:
      method_name = '_set_index'
      self._members_emitter.Emit(
          '\n'
          '  void operator[]=(int index, $TYPE value) {\n'
          '    return $METHOD(this, index, value);\n'
          '  }\n'
          '  static $METHOD(_this, index, value) native;\n',
          TYPE=element_type, METHOD=method_name)
      self._js_code.Emit(
          '\n'
          'function native_$(CLASS)_$(METHOD)(_this, index, value) {\n'
          '  try {\n'
          '    return _this.$dom[index] = __dom_unwrap(value);\n'
          '  } catch (e) {\n'
          '    throw __dom_wrap_exception(e);\n'
          '  }\n'
          '}\n',
          CLASS=self._class_name, METHOD=method_name)
    else:
      self._members_emitter.Emit(
          '\n'
          '  void operator[]=(int index, $TYPE value) {\n'
          '    throw new UnsupportedOperationException("Cannot assign element of immutable List.");\n'
          '  }\n',
          TYPE=element_type)

    self._members_emitter.Emit(
        '\n'
        '  void add($TYPE value) {\n'
        '    throw new UnsupportedOperationException("Cannot add to immutable List.");\n'
        '  }\n'
        '\n'
        '  void addLast($TYPE value) {\n'
        '    throw new UnsupportedOperationException("Cannot add to immutable List.");\n'
        '  }\n'
        '\n'
        '  void addAll(Collection<$TYPE> collection) {\n'
        '    throw new UnsupportedOperationException("Cannot add to immutable List.");\n'
        '  }\n'
        '\n'
        '  void sort(int compare($TYPE a, $TYPE b)) {\n'
        '    throw new UnsupportedOperationException("Cannot sort immutable List.");\n'
        '  }\n'
        '\n'
        '  void copyFrom(List<Object> src, int srcStart, '
        'int dstStart, int count) {\n'
        '    throw new UnsupportedOperationException("This object is immutable.");\n'
        '  }\n'
        '\n'
        '  int indexOf($TYPE element, [int start = 0]) {\n'
        '    return _Lists.indexOf(this, element, start, this.length);\n'
        '  }\n'
        '\n'
        '  int lastIndexOf($TYPE element, [int start = null]) {\n'
        '    if (start === null) start = length - 1;\n'
        '    return _Lists.lastIndexOf(this, element, start);\n'
        '  }\n'
        '\n'
        '  int clear() {\n'
        '    throw new UnsupportedOperationException("Cannot clear immutable List.");\n'
        '  }\n'
        '\n'
        '  $TYPE removeLast() {\n'
        '    throw new UnsupportedOperationException("Cannot removeLast on immutable List.");\n'
        '  }\n'
        '\n'
        '  $TYPE last() {\n'
        '    return this[length - 1];\n'
        '  }\n'
        '\n'
        '  void forEach(void f($TYPE element)) {\n'
        '    _Collections.forEach(this, f);\n'
        '  }\n'
        '\n'
        '  Collection<$TYPE> filter(bool f($TYPE element)) {\n'
        '    return _Collections.filter(this, new List<$TYPE>(), f);\n'
        '  }\n'
        '\n'
        '  bool every(bool f($TYPE element)) {\n'
        '    return _Collections.every(this, f);\n'
        '  }\n'
        '\n'
        '  bool some(bool f($TYPE element)) {\n'
        '    return _Collections.some(this, f);\n'
        '  }\n'
        '\n'
        '  void setRange(int start, int length, List<$TYPE> from, [int startFrom]) {\n'
        '    throw new UnsupportedOperationException("Cannot setRange on immutable List.");\n'
        '  }\n'
        '\n'
        '  void removeRange(int start, int length) {\n'
        '    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");\n'
        '  }\n'
        '\n'
        '  void insertRange(int start, int length, [$TYPE initialValue]) {\n'
        '    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");\n'
        '  }\n'
        '\n'
        '  List<$TYPE> getRange(int start, int length) {\n'
        '    throw new NotImplementedException();\n'
        '  }\n'
        '\n'
        '  bool isEmpty() {\n'
        '    return length == 0;\n'
        '  }\n'
        '\n'
        '  Iterator<$TYPE> iterator() {\n'
        '    return new _FixedSizeListIterator<$TYPE>(this);\n'
        '  }\n',
        TYPE=element_type)

  def AddOperation(self, info):
    """
    Arguments:
      info: An OperationInfo object.
    """
    body = self._members_emitter.Emit(
        '\n'
        '  $TYPE $NAME($ARGS) {\n'
        '$!BODY'
        '  }\n',
        TYPE=info.type_name,
        NAME=info.name,
        ARGS=info.arg_implementation_declaration)

    # Process in order of ascending number of arguments to ensure missing
    # optional arguments are processed early.
    overloads = sorted(info.overloads,
                       key=lambda overload: len(overload.arguments))
    self._native_version = 0
    fallthrough = self.GenerateDispatch(body, info, '    ', 0, overloads)
    if fallthrough:
      body.Emit('    throw "Incorrect number or type of arguments";\n');
    self._externs.add((self._interface.id, info.js_name, 'operation'))

  def GenerateSingleOperation(self,  emitter, info, indent, operation):
    """Generates a call to a single operation.

    Arguments:
      emitter: an Emitter for the body of a block of code.
      info: the compound information about the operation and its overloads.
      indent: an indentation string for generated code.
      operation: the IDLOperation to call.
    """
    # TODO(sra): Do we need to distinguish calling with missing optional
    # arguments from passing 'null' which is represented as 'undefined'?
    def UnwrapArgExpression(name, type):
      # TODO: Type specific unwrapping.
      return '__dom_unwrap(%s)' % (name)

    def ArgNameAndUnwrapper(arg_info, overload_arg):
      (name, type, value) = arg_info
      return (name, UnwrapArgExpression(name, type))

    names_and_unwrappers = [ArgNameAndUnwrapper(info.arg_infos[i], arg)
                            for (i, arg) in enumerate(operation.arguments)]
    unwrap_args = [unwrap_arg for (_, unwrap_arg) in names_and_unwrappers]
    arg_names = [name for (name, _) in names_and_unwrappers]

    self._native_version += 1
    native_name = self._MethodName('_', info.name)
    if self._native_version > 1:
      native_name = '%s_%s' % (native_name, self._native_version)

    argument_expressions = ', '.join(['this'] + arg_names)
    if info.type_name != 'void':
      emitter.Emit('$(INDENT)return $NATIVENAME($ARGS);\n',
                   INDENT=indent,
                   NATIVENAME=native_name,
                   ARGS=argument_expressions)
    else:
      emitter.Emit('$(INDENT)$NATIVENAME($ARGS);\n'
                   '$(INDENT)return;\n',
                   INDENT=indent,
                   NATIVENAME=native_name,
                   ARGS=argument_expressions)

    self._members_emitter.Emit('  static $TYPE $NAME($PARAMS) native;\n',
                               NAME=native_name,
                               TYPE=info.type_name,
                               PARAMS=', '.join(['receiver'] + arg_names) )

    if (self._interface.id, info.name) not in _custom_methods:
      alternates = _alternate_methods.get( (self._interface.id, info.name) )
      if alternates:
        (js_name_1, js_name_2) = alternates
        self._js_code.Emit(
            '\n'
            'function native_$(CLASS)_$(NATIVENAME)($PARAMS) {\n'
            '  try {\n'
            '    var _method = _this.$dom.$JSNAME1 || _this.$dom.$JSNAME2;\n'
            '    return __dom_wrap(_method.call($ARGS));\n'
            '  } catch (e) {\n'
            '    throw __dom_wrap_exception(e);\n'
            '  }\n'
            '}\n',
            CLASS=self._class_name,
            NAME=info.name,
            JSNAME1=js_name_1,
            JSNAME2=js_name_2,
            NATIVENAME=native_name,
            PARAMS=', '.join(['_this'] + arg_names),
            ARGS=', '.join(['_this.$dom'] + unwrap_args))
      else:
        self._js_code.Emit(
            '\n'
            'function native_$(CLASS)_$(NATIVENAME)($PARAMS) {\n'
            '  try {\n'
            '    return __dom_wrap(_this.$dom.$JSNAME($ARGS));\n'
            '  } catch (e) {\n'
            '    throw __dom_wrap_exception(e);\n'
            '  }\n'
            '}\n',
            CLASS=self._class_name,
            NAME=info.name,
            JSNAME=info.js_name,
            NATIVENAME=native_name,
            PARAMS=', '.join(['_this'] + arg_names),
            ARGS=', '.join(unwrap_args))


  def GenerateDispatch(self, emitter, info, indent, position, overloads):
    """Generates a dispatch to one of the overloads.

    Arguments:
      emitter: an Emitter for the body of a block of code.
      info: the compound information about the operation and its overloads.
      indent: an indentation string for generated code.
      position: the index of the parameter to dispatch on.
      overloads: a list of the remaining IDLOperations to dispatch.

    Returns True if the dispatch can fall through on failure, False if the code
    always dispatches.
    """

    def NullCheck(name):
      return '%s === null' % name

    def TypeCheck(name, type):
      return '%s is %s' % (name, type)

    if position == len(info.arg_infos):
      assert len(overloads) == 1
      operation = overloads[0]
      self.GenerateSingleOperation(emitter, info, indent, operation)
      return False

    # FIXME: Consider a simpler dispatch that iterates over the
    # overloads and generates an overload specific check.  Revisit
    # when we move to named optional arguments.

    # Partition the overloads to divide and conquer on the dispatch.
    positive = []
    negative = []
    first_overload = overloads[0]
    (param_name, param_type, param_default) = info.arg_infos[position]

    if position < len(first_overload.arguments):
      # FIXME: This will not work if the second overload has a more
      # precise type than the first.  E.g.,
      # void foo(Node x);
      # void foo(Element x);
      type = first_overload.arguments[position].type.id
      test = TypeCheck(param_name, type)
      pred = lambda op: len(op.arguments) > position and op.arguments[position].type.id == type
    else:
      type = None
      test = NullCheck(param_name)
      pred = lambda op: position >= len(op.arguments)

    for overload in overloads:
      if pred(overload):
        positive.append(overload)
      else:
        negative.append(overload)

    if positive and negative:
      (true_code, false_code) = emitter.Emit(
          '$(INDENT)if ($COND) {\n'
          '$!TRUE'
          '$(INDENT)} else {\n'
          '$!FALSE'
          '$(INDENT)}\n',
          COND=test, INDENT=indent)
      fallthrough1 = self.GenerateDispatch(
          true_code, info, indent + '  ', position + 1, positive)
      fallthrough2 = self.GenerateDispatch(
          false_code, info, indent + '  ', position, negative)
      return fallthrough1 or fallthrough2

    if negative:
      raise 'Internal error, must be all positive'

    # All overloads require the same test.  Do we bother?

    # If the test is the same as the method's formal parameter then checked mode
    # will have done the test already. (It could be null too but we ignore that
    # case since all the overload behave the same and we don't know which types
    # in the IDL are not nullable.)
    if type == param_type:
      return self.GenerateDispatch(
          emitter, info, indent, position + 1, positive)

    # Otherwise the overloads have the same type but the type is a substype of
    # the method's synthesized formal parameter. e.g we have overloads f(X) and
    # f(Y), implemented by the synthesized method f(Z) where X<Z and Y<Z. The
    # dispatch has removed f(X), leaving only f(Y), but there is no guarantee
    # that Y = Z-X, so we need to check for Y.
    true_code = emitter.Emit(
        '$(INDENT)if ($COND) {\n'
        '$!TRUE'
        '$(INDENT)}\n',
        COND=test, INDENT=indent)
    self.GenerateDispatch(
        true_code, info, indent + '  ', position + 1, positive)
    return True


# ------------------------------------------------------------------------------

class MonkeyInterfaceGenerator(object):
  """Generates JS code for monkey-patched implementation of DOM."""

  def __init__(self, generator, interface, global_code, init_sequence):
    self._generator = generator
    self._interface = interface
    self._global_code = global_code
    self._init_sequence = init_sequence

  def StartInterface(self):
    temp = '_'
    (fixup, guard) = self._init_sequence.Emit('$!FIXUP$!GUARD',
                                              ID=self._interface.id, TEMP=temp)
    global_helper_code = self._global_code.Emit('$!HELPERS',
                                                ID=self._interface.id)
    # Define a function that initializes the class prototype and constructor.
    (init_proto_code, fix_members_code, init_class_code) = global_helper_code.Emit(
        'function DOM$fixClass$$ID(c) {\n'
        '  if (c.prototype) {\n'
        '$!INIT_PROTO_CODE'
        '  }\n'
        '$!FIX_MEMBERS_CODE$!INIT_CLASS_CODE'
        '}\n');
    fix_members_code.Bind('CLASSREF', 'c');
    init_class_code.Bind('CLASSREF', 'c');
    init_proto_code.Bind('PROTOREF', 'c.prototype');

    # Generate code that finds the constructor
    if self._interface.id in self._generator._protomap:
      # Use an existing field to find the actual prototype.
      exemplar_access_path = self._generator._protomap[self._interface.id]
      fetch_alternate = self._FetchAlternateConstructor(
          'w', self._interface.id, exemplar_access_path, temp);
      fixup.Emit(
          '  if (!w.$ID && $FETCH) {\n'
          '    w.$ID = $TEMP;\n'
          '  }\n', FETCH=fetch_alternate)

    call_fix_class = guard.Emit(
        '  if (($TEMP = w.$ID)) {\n'
        '    w.$ID$Dart = $TEMP;\n'
        '    $!CALL\n'
        '  }\n')

    if self._InterfaceIsAugmentedOnDemand(self._interface):
      self._GenerateOnDemandInterfaceSetupHelpers(self._interface,
                                                  global_helper_code)
      call_fix_class.Emit('DOM$fixClassOnDemand$$ID($TEMP);')
    else:
      call_fix_class.Emit('DOM$fixClass$$ID($TEMP);')

    self._fix_members_code = fix_members_code
    self._class_code = init_class_code
    self._proto_code = init_proto_code
    self._batched_operation_names = []

  def FinishInterface(self):
    # Any operations left over for fixMembers?
    if self._batched_operation_names:
      member_string = _FormatNameList(self._batched_operation_names)
      self._fix_members_code.Emit('  DOM$fixMembers($CLASSREF, $NAMES);\n',
                                  NAMES=member_string)

    # Define instanceof metadata.
    names = self._generator._AllImplementedInterfaces(self._interface)
    for name in names:
      # TODO(sra): Make this more compact.
      # TODO(sra): Generate metadata for parameterized superclasses.
      self._class_code.Emit('  $CLASSREF.$implements$$NAME$Dart = 1;\n',
                            NAME=name)

  def _InterfaceIsAugmentedOnDemand(self, interface):
    return interface.id in _evasive_types

  def _GenerateOnDemandInterfaceSetupHelpers(self, interface, code):
    """Generate functions that can initialize a prototype given an instance."""
    code.Emit(
        'function DOM$fixClassOnDemand$$ID(c) {\n'
        '  if (c.DOM$initialized === true)\n'
        '    return;\n'
        '  c.DOM$initialized = true;\n'
        '  DOM$fixClass$$ID(c);\n'
        '}\n'
        'function DOM$fixValue$$ID(value) {\n'
        '  if (value == null)\n'
        '    return DOM$EnsureDartNull(value);\n'
        '  if (typeof value != "object")\n'
        '    return value;\n'
        '  var constructor = value.constructor;\n'
        '  if (constructor == null)\n'
        '    return value;\n'
        '  DOM$fixClassOnDemand$$ID(constructor);\n'
        '  return value;\n'
        '}\n')


  def _FetchAlternateConstructor(self, root, typename, accessors, temp):
    """Returns an expression that fetches the constructor for |typename|.

    The expression also assigns the constructor to temp.

    The constructor is generated by traversing a path of property accessors to
    find an exemplar object and then creating a fake constructor for the type of
    the object..  The temp is also used to avoid re-evaluation of the path
    prefixes.
    """
    # TODO(sra): Rather than return the fake constructor:
    #   {prototype: window.blah.blah.__proto__}
    # perhaps we should return the real constructor:
    #   window.blah.blah.constructor
    prefix = root;
    steps = []
    for accessor in accessors + ['__proto__']:
      steps.append("(%s = %s.%s)" % (temp, prefix, accessor));
      prefix = temp
    return "%s && (%s = {prototype: %s})" % (' && '.join(steps), temp, temp)

  def AddConstant(self, constant):
    pass

  def AddGetter(self, attr):
    """Emits code to initialize an attribute getter."""
    if attr.type.id in _evasive_types:
      self._proto_code.Emit('    $PROTOREF.$NAME$getter = function() {'
                            ' return DOM$fixValue$$TYPE(this.$NAME);'
                            ' };\n',
                            NAME=attr.id, TYPE=attr.type.id)
    else:
      self._proto_code.Emit('    $PROTOREF.$NAME$getter = function() {'
                            ' return DOM$EnsureDartNull(this.$NAME);'
                            ' };\n',
                            NAME=attr.id)

  def AddSetter(self, attr):
    """Emits code to initialize an attribute setter."""
    # TODO(sra): Pick implementation depending on checked/unchecked mode.
    self._proto_code.Emit('    $PROTOREF.$NAME$setter = function(value) {'
                          ' this.$NAME = value;'
                          ' };\n',
                          NAME=attr.id)

  def AddIndexer(self, element_type):
    """Emits code to initialize an indexer."""
    # Does the indexer return an evasive type?
    if element_type in _evasive_types:
      self._proto_code.Emit(
          '    $PROTOREF.INDEX$operator = function(k) {'
          ' return DOM$fixValue$$TYPE(this[k]);'
          ' };\n',
          TYPE=element_type)
    else:
      self._proto_code.Emit(
          '    $PROTOREF.INDEX$operator = function(k) {'
          ' return DOM$EnsureDartNull(this[k]);'
          ' };\n')
    # TODO(sra): Check for read-only indexers.
    # TODO(sra): Validate 'v' argument when checked.
    self._proto_code.Emit(
        '    $PROTOREF.ASSIGN_INDEX$operator = function(k, v) {'
        ' this[k] = v;'
        ' };\n')

  def AddOperation(self, info):
    """
    Arguments:
      info: An OperationInfo object.
    """
    name = info.name

    returned_types = [op.type.id for op in info.overloads]
    if any(type in _evasive_types for type in returned_types):
      if len(set(returned_types)) > 1:
        raise Exception('Cannot fix types on the fly when types different %s' %
                        returned_types);

      self._class_code.Emit(
          '  $CLASSREF.prototype.$NAME$member = function() {\n'
          '    return DOM$fixValue$$TYPE(this.$JSNAME.apply(this, arguments));\n'
          '  };\n',
          NAME=info.name, JSNAME=info.js_name, TYPE=returned_types[0])
    elif info.name != info.js_name:
      self._class_code.Emit(
          '  $CLASSREF.prototype.$NAME$member = function() {\n'
          '    return DOM$EnsureDartNull(this.$JSNAME.apply(this, arguments));\n'
          '  };\n',
          NAME=info.name, JSNAME=info.js_name, TYPE=returned_types[0])
    else:
      self._batched_operation_names.append(info.name)

  def AddSecondaryGetter(self, interface, attr):
    self.AddGetter(attr)

  def AddSecondarySetter(self, interface, attr):
    self.AddSetter(attr)

  def AddSecondaryOperation(self, interface, info):
    self.AddOperation(info)

# ------------------------------------------------------------------------------

class FrogInterfaceGenerator(object):
  """Generates a Frog class for a DOM IDL interface."""

  def __init__(self, interface, super_interface, interfaces_with_subtypes,
               dart_code):
    """Generates Dart code for the given interface.

    Args:

      interface: an IDLInterface instance. It is assumed that all types have
          been converted to Dart types (e.g. int, String), unless they are in
          the same package as the interface.
      super_interface: A string or None, the name of the common interface that
          this interface implements, if any.
      interfaces_with_subtypes: A set of strings names of interfaces that have
          at least one subtype.
      dart_code: an Emitter for the file containing the Dart implementation
          class.
    """
    self._interface = interface
    self._super_interface = super_interface
    self._interfaces_with_subtypes = interfaces_with_subtypes
    self._dart_code = dart_code
    self._current_secondary_parent = None


  def StartInterface(self):
    interface = self._interface
    interface_name = interface.id

    self._class_name = self._ImplClassName(interface_name)

    base = None
    if interface.parents:
      supertype = interface.parents[0].type.id
      # FIXME: We're currently injecting List<..> and EventTarget as
      # supertypes in dart.idl. We should annotate/preserve as
      # attributes instead.  For now, this hack lets the interfaces
      # inherit, but not the classes.
      if (not _IsDartListType(supertype) and
          not supertype == 'EventTarget'):
        base = self._ImplClassName(supertype)
      if _IsDartCollectionType(supertype):
        # List methods are injected in AddIndexer.
        pass
      elif supertype == 'EventTarget':
        # Most implementors of EventTarget specify the EventListener operations
        # again.  If the operations are not specified, try to inherit from the
        # EventTarget implementation.
        #
        # Applies to MessagePort.
        if not [op for op in interface.operations if op.id == 'addEventListener']:
          base = self._ImplClassName(supertype)
      else:
        base = self._ImplClassName(supertype)

    if base:
      extends = " extends " + base
    else:
      extends = ""

    if interface_name in _frog_dom_custom_native_specs:
      native_spec = _frog_dom_custom_native_specs[interface_name]
    else:
      # Is the type's JavaScript constructor accessible from the global scope?
      # If so, we can directly patch the prototype.  We don't really want to do
      # this yet because the dynamic patching mechanism is tricky and we want to
      # test it a lot.  But patching is currently broken on FireFox for non-leaf
      # types, so 'hide' only the leaf types.
      is_hidden = interface_name not in _BROWSER_SHARED_TYPES
      if interface_name not in self._interfaces_with_subtypes:
        is_hidden = True

      native_spec = '*' if is_hidden else ''
      native_spec += interface_name

    # TODO: Include all implemented interfaces, including other Lists.
    implements = ''
    element_type = MaybeTypedArrayElementType(self._interface)
    if element_type:
      implements = ' implements List<' + element_type + '>'

    (self._members_emitter, self._base_emitter) = self._dart_code.Emit(
        '\n'
        'class $CLASS$BASE$IMPLEMENTS native "$NATIVE" {\n'
        '$!MEMBERS'
        '$!ADDITIONS'
        '}\n',
        CLASS=self._class_name, BASE=extends,
        INTERFACE=interface_name,
        IMPLEMENTS=implements,
        NATIVE=native_spec)

    if interface_name in _constructable_types.keys():
      self._members_emitter.Emit(
          '  $NAME($PARAMS) native;\n\n',
          NAME=interface_name,
          PARAMS=_constructable_types[interface_name])

    element_type = MaybeTypedArrayElementType(interface)
    if element_type:
      self.AddTypedArrayConstructors(element_type)

    if not base:
      # Emit shared base functionality here as we have no common base type.
      self._base_emitter.Emit(
          '\n'
          '  var dartObjectLocalStorage;\n'
          '\n'
          '  String get typeName() native;\n')

  def _ImplClassName(self, type_name):
    return type_name

  def FinishInterface(self):
    """."""
    pass

  def AddConstant(self, constant):
    # Since we are currently generating native classes without interfaces,
    # generate the constants as part of the class.  This will need to go away
    # if we revert back to generating interfaces.
    self._members_emitter.Emit('\n  static final $TYPE $NAME = $VALUE;\n',
                               NAME=constant.id,
                               TYPE=constant.type.id,
                               VALUE=constant.value)

    pass

  def AddGetter(self, attr):
    # Declare as a field in the native class.
    # TODO(vsm): Mark this as native somehow.
    self._members_emitter.Emit(
        '\n'
        '  $TYPE $NAME;\n',
        NAME=attr.id, TYPE=attr.type.id, INTERFACE=self._interface.id)

  def AddSetter(self, attr):
    # TODO(vsm): Suppress for now.  Should emit if there is no getter.
    pass

  def AddSecondaryGetter(self, interface, attr):
    self._SecondaryContext(interface)
    self.AddGetter(attr)

  def AddSecondarySetter(self, interface, attr):
    self._SecondaryContext(interface)
    self.AddSetter(attr)

  def AddSecondaryOperation(self, interface, info):
    self._SecondaryContext(interface)
    self.AddOperation(info)

  def _SecondaryContext(self, interface):
    if interface is not self._current_secondary_parent:
      self._current_secondary_parent = interface
      self._members_emitter.Emit('\n  // From $WHERE\n', WHERE=interface.id)

  def AddIndexer(self, element_type):
    """Adds all the methods required to complete implementation of List."""
    # We would like to simply inherit the implementation of everything except
    # get length(), [], and maybe []=.  It is possible to extend from a base
    # array implementation class only when there is no other implementation
    # inheritance.  There might be no implementation inheritance other than
    # DOMBaseWrapper for many classes, but there might be some where the
    # array-ness is introduced by a non-root interface:
    #
    #   interface Y extends X, List<T> ...
    #
    # In the non-root case we have to choose between:
    #
    #   class YImpl extends XImpl { add List<T> methods; }
    #
    # and
    #
    #   class YImpl extends ListBase<T> { copies of transitive XImpl methods; }
    #
    self._members_emitter.Emit(
        '\n'
        '  $TYPE operator[](int index) native;\n',
        TYPE=element_type)

    if 'HasCustomIndexSetter' in self._interface.ext_attrs:
      self._members_emitter.Emit(
          '\n'
          '  void operator[]=(int index, $TYPE value) native;\n',
          TYPE=element_type)
    else:
      self._members_emitter.Emit(
          '\n'
          '  void operator[]=(int index, $TYPE value) {\n'
          '    throw new UnsupportedOperationException("Cannot assign element of immutable List.");\n'
          '  }\n',
          TYPE=element_type)


  def AddTypedArrayConstructors(self, element_type):
    self._members_emitter.Emit(
        '\n'
        '  factory $CTOR(int length) =>  _construct(length);\n'
        '\n'
        '  factory $CTOR.fromList(List<$TYPE> list) => _construct(list);\n'
        '\n'
        '  factory $CTOR.fromBuffer(ArrayBuffer buffer) => _construct(buffer);\n'
        '\n'
        '  static _construct(arg) native \'return new $CTOR(arg);\';\n',
        CTOR=self._interface.id,
        TYPE=element_type)


  def AddOperation(self, info):
    """
    Arguments:
      info: An OperationInfo object.
    """
    # TODO(vsm): Handle overloads.
    self._members_emitter.Emit(
        '\n'
        '  $TYPE $NAME($ARGS) native;\n',
        TYPE=info.type_name,
        NAME=info.name,
        ARGS=info.arg_implementation_declaration)
