#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module provides shared functionality for the system to generate
Dart:html APIs from the IDL database."""

import emitter
import os
from generator import *

_js_custom_members = set([
    'AudioBufferSourceNode.start',
    'AudioBufferSourceNode.stop',
    'CSSStyleDeclaration.setProperty',
    'Element.insertAdjacentElement',
    'Element.insertAdjacentHTML',
    'Element.insertAdjacentText',
    'Element.remove',
    'ElementEvents.mouseWheel',
    'IDBDatabase.transaction',
    'IFrameElement.contentWindow',
    'MouseEvent.offsetX',
    'MouseEvent.offsetY',
    'SelectElement.selectedOptions',
    'TableElement.createTBody',
    'LocalWindow.document',
    'LocalWindow.indexedDB',
    'LocalWindow.location',
    'LocalWindow.open',
    'LocalWindow.top',
    'LocalWindow.webkitCancelAnimationFrame',
    'LocalWindow.webkitRequestAnimationFrame',
    ])

# This map controls merging of interfaces in dart:html library.
# All constants, attributes, and operations of merged interface (key) are
# added to target interface (value). All references to the merged interface
# (e.g. parameter types, return types, parent interfaces) are replaced with
# target interface. There are two important restrictions:
# 1) Merged and target interfaces shouldn't have common members, otherwise there
# would be duplicated declarations in generated Dart code.
# 2) Merged interface should be direct child of target interface, so the
# children of merged interface are not affected by the merge.
# As a consequence, target interface implementation and its direct children
# interface implementations should implement merged attribute accessors and
# operations. For example, SVGElement and Element implementation classes should
# implement HTMLElement.insertAdjacentElement(), HTMLElement.innerHTML, etc.
_merged_html_interfaces = {
   'HTMLDocument': 'Document',
   'HTMLElement': 'Element'
}

# Types that are accessible cross-frame in a limited fashion.
# In these cases, the base type (e.g., Window) provides restricted access
# while the subtype (e.g., LocalWindow) provides full access to the
# corresponding objects if there are from the same frame.
_secure_base_types = {
  'LocalWindow': 'Window',
  'LocalLocation': 'Location',
  'LocalHistory': 'History',
}

def SecureOutputType(generator, type_name, is_dart_type=False):
  if is_dart_type:
    dart_name = type_name
  else:
    dart_name = generator._DartType(type_name)
  if dart_name in _secure_base_types:
    return _secure_base_types[dart_name]
  return dart_name

# Information for generating element constructors.
#
# TODO(sra): maybe remove all the argument complexity and use cascades.
#
#   var c = new CanvasElement(width: 100, height: 70);
#   var c = new CanvasElement()..width = 100..height = 70;
#
class ElementConstructorInfo(object):
  def __init__(self, name=None, tag=None,
               params=[], opt_params=[],
               factory_provider_name='_Elements'):
    self.name = name          # The constructor name 'h1' in 'HeadingElement.h1'
    self.tag = tag or name    # The HTML tag
    self.params = params
    self.opt_params = opt_params
    self.factory_provider_name = factory_provider_name

  def ConstructorInfo(self, interface_name):
    info = OperationInfo()
    info.overloads = None
    info.declared_name = interface_name
    info.name = interface_name
    info.constructor_name = self.name
    info.js_name = None
    info.type_name = interface_name
    info.param_infos = map(lambda tXn: ParamInfo(tXn[1], None, tXn[0], 'null'),
                           self.opt_params)
    return info

_html_element_constructors = {
  'AnchorElement' :
    ElementConstructorInfo(tag='a', opt_params=[('DOMString', 'href')]),
  'AreaElement': 'area',
  'ButtonElement': 'button',
  'BRElement': 'br',
  'BaseElement': 'base',
  'BodyElement': 'body',
  'ButtonElement': 'button',
  'CanvasElement':
    ElementConstructorInfo(tag='canvas',
                           opt_params=[('int', 'width'), ('int', 'height')]),
  'ContentElement': 'content',
  'DataListElement': 'datalist',
  'DListElement': 'dl',
  'DetailsElement': 'details',
  'DivElement': 'div',
  'EmbedElement': 'embed',
  'FieldSetElement': 'fieldset',
  'FormElement': 'form',
  'HRElement': 'hr',
  'HeadElement': 'head',
  'HeadingElement': [ElementConstructorInfo('h1'),
                     ElementConstructorInfo('h2'),
                     ElementConstructorInfo('h3'),
                     ElementConstructorInfo('h4'),
                     ElementConstructorInfo('h5'),
                     ElementConstructorInfo('h6')],
  'HtmlElement': 'html',
  'IFrameElement': 'iframe',
  'ImageElement':
    ElementConstructorInfo(tag='img',
                           opt_params=[('DOMString', 'src'),
                                       ('int', 'width'), ('int', 'height')]),
  'InputElement':
    ElementConstructorInfo(tag='input', opt_params=[('DOMString', 'type')]),
  'KeygenElement': 'keygen',
  'LIElement': 'li',
  'LabelElement': 'label',
  'LegendElement': 'legend',
  'LinkElement': 'link',
  'MapElement': 'map',
  'MenuElement': 'menu',
  'MeterElement': 'meter',
  'OListElement': 'ol',
  'ObjectElement': 'object',
  'OptGroupElement': 'optgroup',
  'OutputElement': 'output',
  'ParagraphElement': 'p',
  'ParamElement': 'param',
  'PreElement': 'pre',
  'ProgressElement': 'progress',
  'ScriptElement': 'script',
  'SelectElement': 'select',
  'SourceElement': 'source',
  'SpanElement': 'span',
  'StyleElement': 'style',
  'TableCaptionElement': 'caption',
  'TableCellElement': 'td',
  'TableColElement': 'col',
  'TableElement': 'table',
  'TableRowElement': 'tr',
  #'TableSectionElement'  <thead> <tbody> <tfoot>
  'TextAreaElement': 'textarea',
  'TitleElement': 'title',
  'TrackElement': 'track',
  'UListElement': 'ul',
  'VideoElement': 'video'
}

def HtmlElementConstructorInfos(typename):
  """Returns list of ElementConstructorInfos about the convenience constructors
  for an Element."""
  # TODO(sra): Handle multiple and named constructors.
  if typename not in _html_element_constructors:
    return []
  infos = _html_element_constructors[typename]
  if isinstance(infos, str):
    infos = ElementConstructorInfo(tag=infos)
  if not isinstance(infos, list):
    infos = [infos]
  return infos

def EmitHtmlElementFactoryConstructors(emitter, infos, typename, class_name,
                                       rename_type):
  for info in infos:
    constructor_info = info.ConstructorInfo(typename)

    inits = emitter.Emit(
        '\n'
        '  static $RETURN_TYPE $CONSTRUCTOR($PARAMS) {\n'
        '    $CLASS _e = _document.$dom_createElement("$TAG");\n'
        '$!INITS'
        '    return _e;\n'
        '  }\n',
        RETURN_TYPE=rename_type(constructor_info.type_name),
        CONSTRUCTOR=constructor_info.ConstructorFactoryName(rename_type),
        CLASS=class_name,
        TAG=info.tag,
        PARAMS=constructor_info.ParametersInterfaceDeclaration(rename_type))
    for param in constructor_info.param_infos:
      inits.Emit('    if ($E != null) _e.$E = $E;\n', E=param.name)

# ------------------------------------------------------------------------------

class HtmlDartInterfaceGenerator(object):
  """Generates dart interface and implementation for the DOM IDL interface."""

  def __init__(self, options, library_emitter, event_generator, interface,
               backend):
    self._renamer = options.renamer
    self._database = options.database
    self._template_loader = options.templates
    self._type_registry = options.type_registry
    self._library_emitter = library_emitter
    self._event_generator = event_generator
    self._interface = interface
    self._backend = backend
    self._html_interface_name = options.renamer.RenameInterface(self._interface)

  def Generate(self):
    if 'Callback' in self._interface.ext_attrs:
      self.GenerateCallback()
    else:
      self.GenerateInterface()

  def GenerateCallback(self):
    """Generates a typedef for the callback interface."""
    handlers = [operation for operation in self._interface.operations
                if operation.id == 'handleEvent']
    info = AnalyzeOperation(self._interface, handlers)
    code = self._library_emitter.FileEmitter(self._interface.id)
    code.Emit(self._template_loader.Load('callback.darttemplate'))
    code.Emit('typedef $TYPE $NAME($PARAMS);\n',
              NAME=self._interface.id,
              TYPE=self._DartType(info.type_name),
              PARAMS=info.ParametersImplementationDeclaration(self._DartType))
    self._backend.GenerateCallback(info)

  def GenerateInterface(self):
    if (not self._interface.id in _merged_html_interfaces and
        # Don't re-generate types that have been converted to native dart types.
        self._html_interface_name not in nativified_classes):
      interface_emitter = self._library_emitter.FileEmitter(
          self._html_interface_name)
    else:
      interface_emitter = emitter.Emitter()

    template_file = 'interface_%s.darttemplate' % self._html_interface_name
    interface_template = (self._template_loader.TryLoad(template_file) or
                          self._template_loader.Load('interface.darttemplate'))

    typename = self._html_interface_name

    implements = []
    suppressed_implements = []

    for parent in self._interface.parents:
      # TODO(vsm): Remove source_filter.
      if MatchSourceFilter(parent):
        # Parent is a DOM type.
        implements.append(self._DartType(parent.type.id))
      elif '<' in parent.type.id:
        # Parent is a Dart collection type.
        # TODO(vsm): Make this check more robust.
        implements.append(self._DartType(parent.type.id))
      else:
        suppressed_implements.append('%s.%s' %
            (self._common_prefix, self._DartType(parent.type.id)))

    if typename in _secure_base_types:
      implements.append(_secure_base_types[typename])

    comment = ' extends'
    implements_str = ''
    if implements:
      implements_str += ' implements ' + ', '.join(implements)
      comment = ','
    if suppressed_implements:
      implements_str += ' /*%s %s */' % (comment,
          ', '.join(suppressed_implements))

    factory_provider = None
    if typename in interface_factories:
      factory_provider = interface_factories[typename]

    constructors = []
    constructor_info = AnalyzeConstructor(self._interface)
    if constructor_info:
      constructors.append(constructor_info)
      factory_provider = '_' + typename + 'FactoryProvider'
      factory_provider_emitter = self._library_emitter.FileEmitter(
          '_%sFactoryProvider' % self._html_interface_name)
      self._backend.EmitFactoryProvider(
          constructor_info, factory_provider, factory_provider_emitter)

    infos = HtmlElementConstructorInfos(typename)
    if infos:
      template = self._template_loader.Load(
          'factoryprovider_Elements.darttemplate')
      EmitHtmlElementFactoryConstructors(
          self._library_emitter.FileEmitter('_Elements', template),
          infos,
          self._interface.id,
          self._backend.ImplementationClassName(),
          self._DartType)

    for info in infos:
      constructors.append(info.ConstructorInfo(self._interface.id))
      if factory_provider:
        assert factory_provider == info.factory_provider_name
      else:
        factory_provider = info.factory_provider_name

    # TODO(vsm): Add appropriate package / namespace syntax.
    (self._type_comment_emitter,
     self._members_emitter,
     self._top_level_emitter) = interface_emitter.Emit(
         interface_template + '$!TOP_LEVEL',
         ID=typename,
         EXTENDS=implements_str)

    self._type_comment_emitter.Emit("/// @domName $DOMNAME",
        DOMNAME=self._interface.doc_js_name)

    if self._backend.HasImplementation():
      if not self._interface.id in _merged_html_interfaces:
        name = self._html_interface_name
        if self._html_interface_name in nativified_classes:
          name = nativified_classes[self._html_interface_name]
        basename = '%sImpl' % name
      else:
        basename = '%sImpl_Merged' % self._html_interface_name
      implementation_emitter = self._library_emitter.FileEmitter(basename)
    else:
      implementation_emitter = emitter.Emitter()

    base_class = self._backend.BaseClassName()
    implemented_interfaces = [self._html_interface_name] +\
                             self._backend.AdditionalImplementedInterfaces()
    self._implementation_members_emitter = implementation_emitter.Emit(
        self._backend.ImplementationTemplate(),
        CLASSNAME=self._backend.ImplementationClassName(),
        EXTENDS=' extends %s' % base_class if base_class else '',
        IMPLEMENTS=' implements ' + ', '.join(implemented_interfaces),
        NATIVESPEC=self._backend.NativeSpec())
    self._backend.StartInterface(self._implementation_members_emitter)

    for constructor_info in constructors:
      constructor_info.GenerateFactoryInvocation(
          self._DartType, self._members_emitter, factory_provider)

    element_type = MaybeTypedArrayElementTypeInHierarchy(
        self._interface, self._database)
    if element_type:
      self._members_emitter.Emit(
          '\n'
          '  factory $CTOR(int length) =>\n'
          '    $FACTORY.create$(CTOR)(length);\n'
          '\n'
          '  factory $CTOR.fromList(List<$TYPE> list) =>\n'
          '    $FACTORY.create$(CTOR)_fromList(list);\n'
          '\n'
          '  factory $CTOR.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => \n'
          '    $FACTORY.create$(CTOR)_fromBuffer(buffer, byteOffset, length);\n',
        CTOR=self._interface.id,
        TYPE=self._DartType(element_type),
        FACTORY=factory_provider)

    events_interface = self._event_generator.ProcessInterface(
        self._interface, self._html_interface_name,
        self._backend.CustomJSMembers(),
        interface_emitter, implementation_emitter)
    if events_interface:
      self._EmitEventGetter(events_interface, '_%sImpl' % events_interface)

    old_backend = self._backend
    if not self._backend.ImplementsMergedMembers():
      self._backend = HtmlGeneratorDummyBackend()
    for merged_interface in _merged_html_interfaces:
      if _merged_html_interfaces[merged_interface] == self._interface.id:
        merged_interface = self._database.GetInterface(merged_interface)
        self.AddMembers(merged_interface)
    self._backend = old_backend

    self.AddMembers(self._interface)
    self.AddSecondaryMembers(self._interface)
    self._backend.FinishInterface()

  def AddMembers(self, interface):
    for const in sorted(interface.constants, ConstantOutputOrder):
      self.AddConstant(const)

    for attr in sorted(interface.attributes, ConstantOutputOrder):
      if attr.type.id != 'EventListener':
        self.AddAttribute(attr)

    # The implementation should define an indexer if the interface directly
    # extends List.
    (element_type, requires_indexer) = ListImplementationInfo(
          interface, self._database)
    if element_type:
      if requires_indexer:
        self.AddIndexer(element_type)
      else:
        self.AmendIndexer(element_type)
    # Group overloaded operations by id
    operationsById = {}
    for operation in interface.operations:
      if operation.id not in operationsById:
        operationsById[operation.id] = []
      operationsById[operation.id].append(operation)

    # Generate operations
    for id in sorted(operationsById.keys()):
      operations = operationsById[id]
      info = AnalyzeOperation(interface, operations)
      self.AddOperation(info)

  def AddSecondaryMembers(self, interface):
    # With multiple inheritance, attributes and operations of non-first
    # interfaces need to be added.  Sometimes the attribute or operation is
    # defined in the current interface as well as a parent.  In that case we
    # avoid making a duplicate definition and pray that the signatures match.
    secondary_parents = self._TransitiveSecondaryParents(interface)
    for parent_interface in secondary_parents:
      if isinstance(parent_interface, str):  # IsDartCollectionType(parent_interface)
        continue
      for attr in sorted(parent_interface.attributes, ConstantOutputOrder):
        if not FindMatchingAttribute(interface, attr):
          self.AddSecondaryAttribute(parent_interface, attr)

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
          info = AnalyzeOperation(interface, operations)
          self.AddSecondaryOperation(parent_interface, info)

  def AddIndexer(self, element_type):
    self._backend.AddIndexer(element_type)

  def AmendIndexer(self, element_type):
    self._backend.AmendIndexer(element_type)

  def AddAttribute(self, attribute, is_secondary=False):
    dom_name = DartDomNameOfAttribute(attribute)
    html_name = self._renamer.RenameMember(
      self._interface.id, dom_name, 'get:')
    if not html_name or self._IsPrivate(html_name):
      return


    html_setter_name = self._renamer.RenameMember(
        self._interface.id, dom_name, 'set:')
    read_only = (attribute.is_read_only or 'Replaceable' in attribute.ext_attrs
                 or not html_setter_name)

    # We don't yet handle inconsistent renames of the getter and setter yet.
    assert(not html_setter_name or html_name == html_setter_name)

    if not is_secondary:
      self._members_emitter.Emit('\n  /** @domName $DOMINTERFACE.$DOMNAME */',
          DOMINTERFACE=attribute.doc_js_interface_name,
          DOMNAME=dom_name)
      if read_only:
        template = '\n  abstract $TYPE get $NAME;\n'
      else:
        template = '\n  $TYPE $NAME;\n'

      self._members_emitter.Emit(template,
                                 NAME=html_name,
                                 TYPE=SecureOutputType(self, attribute.type.id))

    self._backend.AddAttribute(attribute, html_name, read_only)

  def AddSecondaryAttribute(self, interface, attribute):
    self._backend.SecondaryContext(interface)
    self.AddAttribute(attribute, True)

  def AddOperation(self, info, skip_declaration=False):
    """
    Arguments:
      operations - contains the overloads, one or more operations with the same
        name.
    """
    html_name = self._renamer.RenameMember(self._interface.id, info.name)
    if not html_name:
      if info.name == 'item':
        # FIXME: item should be renamed to operator[], not removed.
        self._backend.AddOperation(info, '_item')
      return

    if not self._IsPrivate(html_name) and not skip_declaration:
      self._members_emitter.Emit('\n  /** @domName $DOMINTERFACE.$DOMNAME */',
          DOMINTERFACE=info.overloads[0].doc_js_interface_name,
          DOMNAME=info.name)

      if info.IsStatic():
        # FIXME: provide a type.
        self._members_emitter.Emit('\n'
                                  '  static final $NAME = $IMPL_CLASS_NAME.$NAME;\n',
                                  IMPL_CLASS_NAME=self._backend.ImplementationClassName(),
                                  NAME=html_name)
      else:
        self._members_emitter.Emit('\n'
                                  '  $TYPE $NAME($PARAMS);\n',
                                  TYPE=SecureOutputType(self, info.type_name),
                                  NAME=html_name,
                                  PARAMS=info.ParametersInterfaceDeclaration(self._DartType))
    self._backend.AddOperation(info, html_name)

  def AddSecondaryOperation(self, interface, info):
    self._backend.SecondaryContext(interface)
    self.AddOperation(info, True)

  def AddConstant(self, constant):
    type = TypeOrNothing(self._DartType(constant.type.id), constant.type.id)
    self._members_emitter.Emit('\n  static const $TYPE$NAME = $VALUE;\n',
                               NAME=constant.id,
                               TYPE=type,
                               VALUE=constant.value)

  def _EmitEventGetter(self, events_interface, events_class):
    self._members_emitter.Emit(
        '\n  /**'
        '\n   * @domName EventTarget.addEventListener, '
        'EventTarget.removeEventListener, EventTarget.dispatchEvent'
        '\n   */'
        '\n  $TYPE get on;\n',
        TYPE=events_interface)

    self._implementation_members_emitter.Emit(
        '\n  $TYPE get on =>\n    new $TYPE(this);\n',
        TYPE=events_class)

  def _TransitiveSecondaryParents(self, interface):
    """Returns a list of all non-primary parents.

    The list contains the interface objects for interfaces defined in the
    database, and the name for undefined interfaces.
    """
    def walk(parents):
      for parent in parents:
        if IsDartCollectionType(parent.type.id):
          result.append(parent.type.id)
          continue
        if self._database.HasInterface(parent.type.id):
          parent_interface = self._database.GetInterface(parent.type.id)
          result.append(parent_interface)
          walk(parent_interface.parents)

    result = []
    if interface.parents:
      parent = interface.parents[0]
      if IsPureInterface(parent.type.id):
        walk(interface.parents)
      else:
        walk(interface.parents[1:])
    return result

  def _DartType(self, type_name):
    return self._type_registry.DartType(type_name)

  def _IsPrivate(self, name):
    return name.startswith('_')


class HtmlGeneratorDummyBackend(object):
  def AddAttribute(self, attribute, html_name, read_only):
    pass

  def AddOperation(self, info, html_name):
    pass


# ------------------------------------------------------------------------------

class Dart2JSBackend(object):
  """Generates a dart2js class for the dart:html library from a DOM IDL
  interface.
  """

  def __init__(self, interface, options):
    self._interface = interface
    self._database = options.database
    self._template_loader = options.templates
    self._type_registry = options.type_registry
    self._html_interface_name = options.renamer.RenameInterface(self._interface)
    self._current_secondary_parent = None

  def HasImplementation(self):
    return not (IsPureInterface(self._interface.id) or
                self._interface.id in _merged_html_interfaces)

  def ImplementationClassName(self):
    return self._ImplClassName(self._html_interface_name)

  def ImplementsMergedMembers(self):
    return True

  def _ImplClassName(self, type_name):
    name = type_name
    if type_name in nativified_classes:
      name = nativified_classes[type_name]
    return '_%sImpl' % name

  def GenerateCallback(self, info):
    pass

  def BaseClassName(self):
    if not self._interface.parents:
      return None
    supertype = self._interface.parents[0].type.id
    if IsDartCollectionType(supertype):
      # List methods are injected in AddIndexer.
      return None
    if IsPureInterface(supertype):
      return None
    elif supertype == 'NodeList':
      # Special case as NodeList gets converted to List<Node>.
      return '_NodeListImpl'
    return self._ImplClassName(self._DartType(supertype))

  def AdditionalImplementedInterfaces(self):
    # TODO: Include all implemented interfaces, including other Lists.
    implements = []
    element_type = MaybeTypedArrayElementType(self._interface)
    if element_type:
      implements.append('List<%s>' % self._DartType(element_type))
    if self._HasJavaScriptIndexingBehaviour():
      implements.append('JavaScriptIndexingBehavior')
    return implements

  def NativeSpec(self):
    native_spec = MakeNativeSpec(self._interface.javascript_binding_name)
    return ' native "%s"' % native_spec

  def ImplementationTemplate(self):
    template_file = 'impl_%s.darttemplate' % self._html_interface_name
    return (self._template_loader.TryLoad(template_file) or
            self._template_loader.Load('dart2js_impl.darttemplate'))

  def StartInterface(self, emitter):
    self._members_emitter = emitter

  def FinishInterface(self):
    pass

  def EmitFactoryProvider(self, constructor_info, factory_provider, emitter):
    template_file = ('factoryprovider_%s.darttemplate' %
                     self._html_interface_name)
    template = self._template_loader.TryLoad(template_file)
    if not template:
      template = self._template_loader.Load('factoryprovider.darttemplate')

    emitter.Emit(
        template,
        FACTORYPROVIDER=factory_provider,
        CONSTRUCTOR=self._html_interface_name,
        PARAMETERS=constructor_info.ParametersImplementationDeclaration(self._DartType),
        NAMED_CONSTRUCTOR=constructor_info.name or self._html_interface_name,
        ARGUMENTS=constructor_info.ParametersAsArgumentList())

  def SecondaryContext(self, interface):
    if interface is not self._current_secondary_parent:
      self._current_secondary_parent = interface
      self._members_emitter.Emit('\n  // From $WHERE\n', WHERE=interface.id)

  def AddIndexer(self, element_type):
    """Adds all the methods required to complete implementation of List."""
    # We would like to simply inherit the implementation of everything except
    # length, [], and maybe []=.  It is possible to extend from a base
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
        '  $TYPE operator[](int index) native "return this[index];";\n',
        TYPE=self._NarrowOutputType(element_type))

    if 'CustomIndexedSetter' in self._interface.ext_attrs:
      self._members_emitter.Emit(
          '\n'
          '  void operator[]=(int index, $TYPE value) native "this[index] = value";\n',
          TYPE=self._NarrowInputType(element_type))
    else:
      # The HTML library implementation of NodeList has a custom indexed setter
      # implementation that uses the parent node the NodeList is associated
      # with if one is available.
      if self._interface.id != 'NodeList':
        self._members_emitter.Emit(
            '\n'
            '  void operator[]=(int index, $TYPE value) {\n'
            '    throw new UnsupportedOperationException("Cannot assign element of immutable List.");\n'
            '  }\n',
            TYPE=self._NarrowInputType(element_type))

    # TODO(sra): Use separate mixins for mutable implementations of List<T>.
    # TODO(sra): Use separate mixins for typed array implementations of List<T>.
    if self._interface.id != 'NodeList':
      template_file = 'immutable_list_mixin.darttemplate'
      template = self._template_loader.Load(template_file)
      self._members_emitter.Emit(template, E=self._DartType(element_type))

  def AddAttribute(self, attribute, html_name, read_only):
    if self._HasCustomImplementation(attribute.id):
      return

    if attribute.id != html_name:
      self._AddAttributeUsingProperties(attribute, html_name, read_only)
      return

    # If the attribute is shadowing, we can't generate a shadowing
    # field (Issue 1633).
    # TODO(sra): _FindShadowedAttribute does not take into account the html
    #  renaming.  we should be looking for another attribute that has the same
    #  html_name.  Two attributes with the same IDL name might not match if one
    #  is renamed.
    (super_attribute, super_attribute_interface) = self._FindShadowedAttribute(
        attribute, _merged_html_interfaces)
    if super_attribute:
      if read_only:
        if attribute.type.id == super_attribute.type.id:
          # Compatible attribute, use the superclass property.  This works
          # because JavaScript will do its own dynamic dispatch.
          self._members_emitter.Emit(
              '\n'
              '  // Use implementation from $SUPER.\n'
              '  // final $TYPE $NAME;\n',
              SUPER=super_attribute_interface,
              NAME=DartDomNameOfAttribute(attribute),
              TYPE=self._NarrowOutputType(attribute.type.id))
          return
      self._members_emitter.Emit('\n  // Shadowing definition.')
      self._AddAttributeUsingProperties(attribute, html_name, read_only)
      return

    # If the type has a conversion we need a getter or setter to contain the
    # conversion code.
    if (self._OutputConversion(attribute.type.id, attribute.id) or
        self._InputConversion(attribute.type.id, attribute.id)):
      self._AddAttributeUsingProperties(attribute, html_name, read_only)
      return

    output_type = self._NarrowOutputType(attribute.type.id)
    input_type = self._NarrowInputType(attribute.type.id)
    if not read_only:
      self._members_emitter.Emit(
          '\n  $TYPE $NAME;\n',
          NAME=DartDomNameOfAttribute(attribute),
          TYPE=output_type)
    else:
      self._members_emitter.Emit(
          '\n  final $TYPE $NAME;\n',
          NAME=DartDomNameOfAttribute(attribute),
          TYPE=output_type)

  def _AddAttributeUsingProperties(self, attribute, html_name, read_only):
    self._AddRenamingGetter(attribute, html_name)
    if not read_only:
      self._AddRenamingSetter(attribute, html_name)

  def _AddRenamingGetter(self, attr, html_name):
    conversion = self._OutputConversion(attr.type.id, attr.id)
    if conversion:
      return self._AddConvertingGetter(attr, html_name, conversion)
    return_type = self._NarrowOutputType(attr.type.id)
    self._members_emitter.Emit(
        '\n  $TYPE get $HTML_NAME() native "return this.$NAME;";\n',
        HTML_NAME=html_name,
        NAME=attr.id,
        TYPE=return_type)

  def _AddRenamingSetter(self, attr, html_name):
    conversion = self._InputConversion(attr.type.id, attr.id)
    if conversion:
      return self._AddConvertingSetter(attr, html_name, conversion)
    self._members_emitter.Emit(
        '\n  void set $HTML_NAME($TYPE value)'
        ' native "this.$NAME = value;";\n',
        HTML_NAME=html_name,
        NAME=attr.id,
        TYPE=self._NarrowInputType(attr.type.id))

  def _AddConvertingGetter(self, attr, html_name, conversion):
    self._members_emitter.Emit(
        '\n  $RETURN_TYPE get $HTML_NAME => $CONVERT(this._$(HTML_NAME));'
        '\n  $NATIVE_TYPE get _$HTML_NAME() native "return this.$NAME;";'
        '\n',
        CONVERT=conversion.function_name,
        HTML_NAME=html_name,
        NAME=attr.id,
        RETURN_TYPE=conversion.output_type,
        NATIVE_TYPE=conversion.input_type)

  def _AddConvertingSetter(self, attr, html_name, conversion):
    self._members_emitter.Emit(
        '\n  void set $HTML_NAME($INPUT_TYPE value) {'
        ' this._$HTML_NAME = $CONVERT(value); }'
        '\n  void set _$HTML_NAME(/*$NATIVE_TYPE*/ value)'
        ' native "this.$NAME = value;";'
        '\n',
        CONVERT=conversion.function_name,
        HTML_NAME=html_name,
        NAME=attr.id,
        INPUT_TYPE=conversion.input_type,
        NATIVE_TYPE=conversion.output_type)

  def AmendIndexer(self, element_type):
    pass

  def AddOperation(self, info, html_name):
    """
    Arguments:
      info: An OperationInfo object.
    """
    if self._HasCustomImplementation(info.name):
      return

    # Any conversions needed?
    if any(self._OperationRequiresConversions(op) for op in info.overloads):
      self._AddOperationWithConversions(info, html_name)
    else:
      self._AddDirectNativeOperation(info, html_name)

  def _AddDirectNativeOperation(self, info, html_name):
    # Do we need a native body?
    if html_name != info.declared_name:
      return_type = self._NarrowOutputType(info.type_name)

      operation_emitter = self._members_emitter.Emit('$!SCOPE',
          MODIFIERS='static ' if info.IsStatic() else '',
          TYPE=return_type,
          HTML_NAME=html_name,
          NAME=info.declared_name,
          PARAMS=info.ParametersImplementationDeclaration(
              lambda type_name: self._NarrowInputType(type_name)))

      operation_emitter.Emit(
          '\n'
          #'  // @native("$NAME")\n;'
          '  $MODIFIERS$TYPE $(HTML_NAME)($PARAMS) native "$NAME";\n')
    else:
      self._members_emitter.Emit(
          '\n'
          '  $MODIFIERS$TYPE $NAME($PARAMS) native;\n',
          MODIFIERS='static ' if info.IsStatic() else '',
          TYPE=self._NarrowOutputType(info.type_name),
          NAME=info.name,
          PARAMS=info.ParametersImplementationDeclaration(
              lambda type_name: self._NarrowInputType(type_name)))

  def _AddOperationWithConversions(self, info, html_name):
    # Assert all operations have same return type.
    assert len(set([op.type.id for op in info.operations])) == 1
    info = info.CopyAndWidenDefaultParameters()
    output_conversion = self._OutputConversion(info.type_name,
                                               info.declared_name)
    if output_conversion:
      return_type = output_conversion.output_type
      native_return_type = output_conversion.input_type
    else:
      return_type = self._NarrowInputType(info.type_name)
      native_return_type = return_type

    def InputType(type_name):
      conversion = self._InputConversion(type_name, info.declared_name)
      if conversion:
        return conversion.input_type
      else:
        return self._NarrowInputType(type_name)

    body = self._members_emitter.Emit(
        '\n'
        '  $MODIFIERS$TYPE $(HTML_NAME)($PARAMS) {\n'
        '$!BODY'
        '  }\n',
        MODIFIERS='static ' if info.IsStatic() else '',
        TYPE=return_type,
        HTML_NAME=html_name,
        PARAMS=info.ParametersImplementationDeclaration(InputType))

    parameter_names = [param_info.name for param_info in info.param_infos]
    parameter_types = [InputType(param_info.dart_type)
                       for param_info in info.param_infos]
    operations = info.operations

    method_version = [0]
    temp_version = [0]

    def GenerateCall(operation, argument_count, checks):
      checks = filter(lambda e: e != 'true', checks)
      if checks:
        (stmts_emitter, call_emitter) = body.Emit(
            '    if ($CHECKS) {\n$!STMTS$!CALL    }\n',
            INDENT='      ',
            CHECKS=' &&\n        '.join(checks))
      else:
        (stmts_emitter, call_emitter) = body.Emit('$!A$!B', INDENT='    ');

      method_version[0] += 1
      target = '_%s_%d' % (html_name, method_version[0]);
      arguments = []
      target_parameters = []
      for position, arg in enumerate(operation.arguments[:argument_count]):
        conversion = self._InputConversion(arg.type.id, operation.id)
        param_name = operation.arguments[position].id
        if conversion:
          temp_version[0] += 1
          temp_name = '%s_%s' % (param_name, temp_version[0])
          temp_type = conversion.output_type
          stmts_emitter.Emit(
              '$(INDENT)$TYPE $NAME = $CONVERT($ARG);\n',
              TYPE=TypeOrVar(temp_type),
              NAME=temp_name,
              CONVERT=conversion.function_name,
              ARG=parameter_names[position])
          arguments.append(temp_name)
          param_type = temp_type
          verified_type = temp_type  # verified by assignment in checked mode.
        else:
          arguments.append(parameter_names[position])
          param_type = self._NarrowInputType(arg.type.id)
          # Verified by argument checking on entry to the dispatcher.
          verified_type = InputType(info.param_infos[position].dart_type)

        # The native method does not need an argument type if we know the type.
        # But we do need the native methods to have correct function types, so
        # be conservative.
        if param_type == verified_type:
          if param_type in ['String', 'num', 'int', 'double', 'bool', 'Object']:
            param_type = 'Dynamic'
        target_parameters.append(
            '%s%s' % (TypeOrNothing(param_type), param_name))

      argument_list = ', '.join(arguments)
      # TODO(sra): If the native method has zero type checks, we can 'inline' is
      # and call it directly with a JS-expression.
      call = '%s(%s)' % (target, argument_list)

      if output_conversion:
        call = '%s(%s)' % (output_conversion.function_name, call)

      if operation.type.id == 'void':
        call_emitter.Emit('$(INDENT)$CALL;\n$(INDENT)return;\n',
                          CALL=call)
      else:
        call_emitter.Emit('$(INDENT)return $CALL;\n', CALL=call)

      self._members_emitter.Emit(
          '  $TYPE$TARGET($PARAMS) native "$NATIVE";\n',
          TYPE=TypeOrNothing(native_return_type),
          TARGET=target,
          PARAMS=', '.join(target_parameters),
          NATIVE=info.declared_name)

    def GenerateChecksAndCall(operation, argument_count):
      checks = ['!?%s' % name for name in parameter_names]
      for i in range(0, argument_count):
        argument = operation.arguments[i]
        parameter_name = parameter_names[i]
        test_type = self._DartType(argument.type.id)
        if test_type in ['Dynamic', 'Object']:
          checks[i] = '?%s' % parameter_name
        elif test_type == parameter_types[i]:
          checks[i] = 'true'
        else:
          checks[i] = '(%s is %s || %s === null)' % (
              parameter_name, test_type, parameter_name)
      # There can be multiple presence checks.  We need them all since a later
      # optional argument could have been passed by name, leaving 'holes'.
      GenerateCall(operation, argument_count, checks)

    # TODO: Optimize the dispatch to avoid repeated checks.
    if len(operations) > 1:
      for operation in operations:
        for position, argument in enumerate(operation.arguments):
          if self._IsOptional(operation, argument):
            GenerateChecksAndCall(operation, position)
        GenerateChecksAndCall(operation, len(operation.arguments))
      body.Emit(
          '    throw const Exception("Incorrect number or type of arguments");'
          '\n');
    else:
      operation = operations[0]
      argument_count = len(operation.arguments)
      for position, argument in list(enumerate(operation.arguments))[::-1]:
        if self._IsOptional(operation, argument):
          check = '?%s' % parameter_names[position]
          GenerateCall(operation, position + 1, [check])
          argument_count = position
      GenerateCall(operation, argument_count, [])


  def _IsOptional(self, operation, argument):
    return IsOptional(argument)


  def _OperationRequiresConversions(self, operation):
    return (self._OperationRequiresOutputConversion(operation) or
            self._OperationRequiresInputConversions(operation))

  def _OperationRequiresOutputConversion(self, operation):
    return self._OutputConversion(operation.type.id, operation.id)

  def _OperationRequiresInputConversions(self, operation):
    return any(self._InputConversion(arg.type.id, operation.id)
               for arg in operation.arguments)

  def _OutputConversion(self, idl_type, member):
    return FindConversion(idl_type, 'get', self._interface.id, member)

  def _InputConversion(self, idl_type, member):
    return FindConversion(idl_type, 'set', self._interface.id, member)

  def _HasCustomImplementation(self, member_name):
    member_name = '%s.%s' % (self._html_interface_name, member_name)
    return member_name in _js_custom_members

  def CustomJSMembers(self):
    return _js_custom_members

  def _HasJavaScriptIndexingBehaviour(self):
    """Returns True if the native object has an indexer and length property."""
    (element_type, requires_indexer) = ListImplementationInfo(
        self._interface, self._database)
    if element_type and requires_indexer: return True
    return False

  def _NarrowToImplementationType(self, type_name):
    if type_name == 'Dynamic':
      return type_name
    return self._type_registry.TypeInfo(type_name).narrow_dart_type()

  def _NarrowInputType(self, type_name):
    return self._NarrowToImplementationType(type_name)

  def _NarrowOutputType(self, type_name):
    secure_name = SecureOutputType(self, type_name)
    if (type_name == secure_name):
      return self._NarrowToImplementationType(type_name)
    else:
      return secure_name

  def _FindShadowedAttribute(self, attr, merged_interfaces={}):
    """Returns (attribute, superinterface) or (None, None)."""
    def FindInParent(interface):
      """Returns matching attribute in parent, or None."""
      if interface.parents:
        parent = interface.parents[0]
        if IsDartCollectionType(parent.type.id):
          return (None, None)
        if IsPureInterface(parent.type.id):
          return (None, None)
        if self._database.HasInterface(parent.type.id):
          interfaces_to_search_in = []
          if parent.type.id in merged_interfaces:
            # IDL parent was merged into another interface, which became a
            # parent interface in Dart.
            interfaces_to_search_in.append(parent.type.id)
            parent_interface_name = merged_interfaces[parent.type.id]
          else:
            parent_interface_name = parent.type.id

          for interface_name in merged_interfaces:
            if merged_interfaces[interface_name] == parent_interface_name:
              # IDL parent has another interface that was merged into it.
              interfaces_to_search_in.append(interface_name)

          interfaces_to_search_in.append(parent_interface_name)
          for interface_name in interfaces_to_search_in:
            interface = self._database.GetInterface(interface_name)
            attr2 = FindMatchingAttribute(interface, attr)
            if attr2:
              return (attr2, parent_interface_name)

          return FindInParent(
              self._database.GetInterface(parent_interface_name))
      return (None, None)

    return FindInParent(self._interface) if attr else (None, None)

  def _DartType(self, type_name):
    return self._type_registry.DartType(type_name)

# ------------------------------------------------------------------------------

class DartLibraryEmitter():
  def __init__(self, multiemitter, template, dart_sources_dir):
    self._multiemitter = multiemitter
    self._template = template
    self._dart_sources_dir = dart_sources_dir
    self._path_to_emitter = {}

  def FileEmitter(self, basename, template=None):
    path = os.path.join(self._dart_sources_dir, '%s.dart' % basename)
    if not path in self._path_to_emitter:
      emitter = self._multiemitter.FileEmitter(path)
      if not template is None:
        emitter = emitter.Emit(template)
      self._path_to_emitter[path] = emitter
    return self._path_to_emitter[path]

  def EmitLibrary(self, library_file_path, auxiliary_dir):
    def massage_path(path):
      # The most robust way to emit path separators is to use / always.
      return path.replace('\\', '/')

    library_emitter = self._multiemitter.FileEmitter(library_file_path)
    library_file_dir = os.path.dirname(library_file_path)
    auxiliary_dir = os.path.relpath(auxiliary_dir, library_file_dir)
    imports_emitter = library_emitter.Emit(
        self._template, AUXILIARY_DIR=massage_path(auxiliary_dir))
    for path in sorted(self._path_to_emitter.keys()):
      relpath = os.path.relpath(path, library_file_dir)
      imports_emitter.Emit(
          "#source('$PATH');\n", PATH=massage_path(relpath))
