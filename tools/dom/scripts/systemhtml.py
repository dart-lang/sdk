#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module provides shared functionality for the system to generate
Dart:html APIs from the IDL database."""

import emitter
import os
from generator import *
from htmldartgenerator import *

_js_custom_members = set([
    'ArrayBuffer.slice',
    'AudioBufferSourceNode.start',
    'AudioBufferSourceNode.stop',
    'AudioContext.createGain',
    'AudioContext.createScriptProcessor',
    'Console.memory',
    'Console.profiles',
    'Console.assertCondition',
    'Console.count',
    'Console.debug',
    'Console.dir',
    'Console.dirxml',
    'Console.error',
    'Console.group',
    'Console.groupCollapsed',
    'Console.groupEnd',
    'Console.info',
    'Console.log',
    'Console.markTimeline',
    'Console.profile',
    'Console.profileEnd',
    'Console.time',
    'Console.timeEnd',
    'Console.timeStamp',
    'Console.trace',
    'Console.warn',
    'CSSStyleDeclaration.setProperty',
    'Element.insertAdjacentElement',
    'Element.insertAdjacentHTML',
    'Element.insertAdjacentText',
    'Element.webkitMatchesSelector',
    'Element.remove',
    'ElementEvents.mouseWheel',
    'DOMException.name',
    'HTMLCanvasElement.getContext',
    'HTMLTableElement.createTBody',
    'IDBDatabase.transaction',
    'KeyboardEvent.initKeyboardEvent',
    'MouseEvent.offsetX',
    'MouseEvent.offsetY',
    'Navigator.language',
    'Navigator.webkitGetUserMedia',
    'URL.createObjectURL',
    'URL.revokeObjectURL',
    'WheelEvent.wheelDeltaX',
    'WheelEvent.wheelDeltaY',
    'Window.cancelAnimationFrame',
    'Window.console',
    'Window.document',
    'Window.indexedDB',
    'Window.location',
    'Window.open',
    'Window.requestAnimationFrame',
    'Window.webkitCancelAnimationFrame',
    'Window.webkitRequestAnimationFrame',
    'WorkerContext.indexedDB',
    ])

js_support_checks = {
  'ArrayBuffer': "JS('bool', 'typeof window.ArrayBuffer != \"undefined\"')",
  'Database': "JS('bool', '!!(window.openDatabase)')",
  'DOMApplicationCache': "JS('bool', '!!(window.applicationCache)')",
  'DOMFileSystem': "JS('bool', '!!(window.webkitRequestFileSystem)')",
  'HashChangeEvent': "Event._isTypeSupported('HashChangeEvent')",
  'HTMLContentElement': "Element.isTagSupported('content')",
  'HTMLDataListElement': "Element.isTagSupported('datalist')",
  'HTMLDetailsElement': "Element.isTagSupported('details')",
  'HTMLEmbedElement': "Element.isTagSupported('embed')",
  # IE creates keygen as Block elements
  'HTMLKeygenElement': "Element.isTagSupported('keygen') "
      "&& (new Element.tag('keygen') is KeygenElement)",
  'HTMLMeterElement': "Element.isTagSupported('meter')",
  'HTMLObjectElement': "Element.isTagSupported('object')",
  'HTMLOutputElement': "Element.isTagSupported('output')",
  'HTMLProgressElement': "Element.isTagSupported('progress')",
  'HTMLShadowElement': "Element.isTagSupported('shadow')",
  'HTMLTrackElement': "Element.isTagSupported('track')",
  'MediaStreamEvent': "Event._isTypeSupported('MediaStreamEvent')",
  'MediaStreamTrackEvent': "Event._isTypeSupported('MediaStreamTrackEvent')",
  'NotificationCenter': "JS('bool', '!!(window.webkitNotifications)')",
  'Performance': "JS('bool', '!!(window.performance)')",
  'SpeechRecognition': "JS('bool', '!!(window.SpeechRecognition || "
      "window.webkitSpeechRecognition)')",
  'XMLHttpRequestProgressEvent':
      "Event._isTypeSupported('XMLHttpRequestProgressEvent')",
  'WebKitCSSMatrix': "JS('bool', '!!(window.WebKitCSSMatrix)')",
  'WebKitPoint': "JS('bool', '!!(window.WebKitPoint)')",
  'WebSocket': "JS('bool', 'typeof window.WebSocket != \"undefined\"')",
  'XSLTProcessor': "JS('bool', '!!(window.XSLTProcessor)')",
}

# Classes that offer only static methods, and therefore we should suppress
# constructor creation.
_static_classes = set(['Url'])

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
               factory_provider_name='document'):
    self.name = name          # The constructor name 'h1' in 'HeadingElement.h1'
    self.tag = tag or name    # The HTML or SVG tag
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
    info.param_infos = map(lambda tXn: ParamInfo(tXn[1], tXn[0], True),
                           self.opt_params)
    info.requires_named_arguments = True
    info.factory_parameters = ['"%s"' % self.tag]
    info.pure_dart_constructor = True
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

_svg_element_constructors = {
  'AElement': 'a',
  'AnimateColorElement': 'animateColor',
  'AnimateElement': 'animate',
  'AnimateMotionElement': 'animateMotion',
  'AnimateTransformElement': 'animateTransform',
  'AnimationElement': 'animation',
  'CircleElement': 'circle',
  'ClipPathElement': 'clipPath',
  'CursorElement': 'cursor',
  'DefsElement': 'defs',
  'DescElement': 'desc',
  'EllipseElement': 'ellipse',
  'FilterElement': 'filter',
  'FontElement': 'font',
  'FontFaceElement': 'font-face',
  'FontFaceFormatElement': 'font-face-format',
  'FontFaceNameElement': 'font-face-name',
  'FontFaceSrcElement': 'font-face-src',
  'FontFaceUriElement': 'font-face-uri',
  'ForeignObjectElement': 'foreignObject',
  'GlyphElement': 'glyph',
  'GElement': 'g',
  'HKernElement': 'hkern',
  'ImageElement': 'image',
  'LinearGradientElement': 'linearGradient',
  'LineElement': 'line',
  'MarkerElement': 'marker',
  'MaskElement': 'mask',
  'MPathElement': 'mpath',
  'PathElement': 'path',
  'PatternElement': 'pattern',
  'PolygonElement': 'polygon',
  'PolylineElement': 'polyline',
  'RadialGradientElement': 'radialGradient',
  'RectElement': 'rect',
  'ScriptElement': 'script',
  'SetElement': 'set',
  'StopElement': 'stop',
  'StyleElement': 'style',
  'SwitchElement': 'switch',
  'SymbolElement': 'symbol',
  'TextElement': 'text',
  'TitleElement': 'title',
  'TRefElement': 'tref',
  'TSpanElement': 'tspan',
  'UseElement': 'use',
  'ViewElement': 'view',
  'VKernElement': 'vkern',
}

_element_constructors = {
  'html': _html_element_constructors,
  'indexed_db': {},
  'svg': _svg_element_constructors,
  'web_audio': {},
}

_factory_ctr_strings = {
  'html': {
      'provider_name': 'document',
      'constructor_name': '$dom_createElement'
  },
  'indexed_db': {
      'provider_name': 'document',
      'constructor_name': '$dom_createElement'
  },
  'svg': {
    'provider_name': '_SvgElementFactoryProvider',
    'constructor_name': 'createSvgElement_tag',
  },
  'web_audio': {
    'provider_name': 'document',
    'constructor_name': '$dom_createElement'
  },
}

def ElementConstructorInfos(typename, element_constructors,
                            factory_provider_name='_Elements'):
  """Returns list of ElementConstructorInfos about the convenience constructors
  for an Element or SvgElement."""
  # TODO(sra): Handle multiple and named constructors.
  if typename not in element_constructors:
    return []
  infos = element_constructors[typename]
  if isinstance(infos, str):
    infos = ElementConstructorInfo(tag=infos,
        factory_provider_name=factory_provider_name)
  if not isinstance(infos, list):
    infos = [infos]
  return infos

# ------------------------------------------------------------------------------

class HtmlDartInterfaceGenerator(object):
  """Generates dart interface and implementation for the DOM IDL interface."""

  def __init__(self, options, library_emitter, event_generator, interface,
               backend):
    self._renamer = options.renamer
    self._database = options.database
    self._template_loader = options.templates
    self._type_registry = options.type_registry
    self._options = options
    self._library_emitter = library_emitter
    self._event_generator = event_generator
    self._interface = interface
    self._backend = backend
    self._interface_type_info = self._type_registry.TypeInfo(self._interface.id)
    self._library_name = self._renamer.GetLibraryName(self._interface)

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
    code = self._library_emitter.FileEmitter(self._interface.id,
        self._library_name)
    code.Emit(self._template_loader.Load('callback.darttemplate'))

    typedef_name = self._renamer.RenameInterface(self._interface)
    code.Emit('typedef void $NAME($PARAMS);\n',
              NAME=typedef_name,
              PARAMS=info.ParametersDeclaration(self._DartType))
    self._backend.GenerateCallback(info)

  def GenerateInterface(self):
    interface_name = self._interface_type_info.interface_name()

    factory_provider = None
    if interface_name in interface_factories:
      factory_provider = interface_factories[interface_name]
    factory_constructor_name = None

    constructors = []
    if interface_name in _static_classes:
      constructor_info = None
    else:
      constructor_info = AnalyzeConstructor(self._interface)
    if constructor_info:
      constructors.append(constructor_info)
      # TODO(antonm): consider removing it later.
      factory_provider = interface_name

    # HTML Elements and SVG Elements have convenience constructors.
    infos = ElementConstructorInfos(interface_name,
        _element_constructors[self._library_name], factory_provider_name=
        _factory_ctr_strings[self._library_name]['provider_name'])

    if infos:
      factory_constructor_name = _factory_ctr_strings[
          self._library_name]['constructor_name']

    for info in infos:
      constructors.append(info.ConstructorInfo(self._interface.id))
      if factory_provider:
        assert factory_provider == info.factory_provider_name
      else:
        factory_provider = info.factory_provider_name

    implementation_emitter = self._ImplementationEmitter()

    base_type_info = None
    if self._interface.parents:
      supertype = self._interface.parents[0].type.id
      if not IsDartCollectionType(supertype) and not IsPureInterface(supertype):
        base_type_info = self._type_registry.TypeInfo(supertype)
        if base_type_info.merged_into() \
            and self._backend.ImplementsMergedMembers():
          base_type_info = self._type_registry.TypeInfo(
              base_type_info.merged_into())

    if base_type_info:
      base_class = base_type_info.implementation_name()
    else:
      base_class = self._backend.RootClassName()

    implements = self._backend.AdditionalImplementedInterfaces()
    for parent in self._interface.parents:
      parent_type_info = self._type_registry.TypeInfo(parent.type.id)
      if parent_type_info.interface_name() != base_class and \
          parent_type_info != base_type_info:
        implements.append(parent_type_info.interface_name())

    secure_base_name = self._backend.SecureBaseName(interface_name)
    if secure_base_name:
      implements.append(secure_base_name)

    implements_str = ''
    if implements:
      implements_str = ' implements ' + ', '.join(set(implements))

    annotations = FormatAnnotationsAndComments(
        GetAnnotationsAndComments(self._interface.doc_js_name,
                              library_name=self._library_name), '')

    self._implementation_members_emitter = implementation_emitter.Emit(
        self._backend.ImplementationTemplate(),
        LIBRARYNAME=self._library_name,
        ANNOTATIONS=annotations,
        CLASSNAME=self._interface_type_info.implementation_name(),
        EXTENDS=' extends %s' % base_class if base_class else '',
        IMPLEMENTS=implements_str,
        DOMNAME=self._interface.doc_js_name,
        NATIVESPEC=self._backend.NativeSpec())
    self._backend.StartInterface(self._implementation_members_emitter)

    self._backend.EmitHelpers(base_class)
    self._event_generator.EmitStreamProviders(
        self._interface,
        self._backend.CustomJSMembers(),
        self._implementation_members_emitter,
        self._library_name)
    self._backend.AddConstructors(
        constructors, factory_provider, factory_constructor_name)

    self._backend.EmitSupportCheck()

    events_class_name = self._event_generator.ProcessInterface(
        self._interface, interface_name,
        self._backend.CustomJSMembers(),
        implementation_emitter)
    if events_class_name:
      self._backend.EmitEventGetter(events_class_name)

    merged_interface = self._interface_type_info.merged_interface()
    if merged_interface:
      self._backend.AddMembers(self._database.GetInterface(merged_interface),
        not self._backend.ImplementsMergedMembers())

    self._backend.AddMembers(self._interface)
    self._backend.AddSecondaryMembers(self._interface)
    self._event_generator.EmitStreamGetters(
        self._interface,
        [],
        self._implementation_members_emitter,
        self._library_name)
    self._backend.FinishInterface()

  def _ImplementationEmitter(self):
    basename = self._interface_type_info.implementation_name()
    if (self._interface_type_info.merged_into() and
        self._backend.ImplementsMergedMembers()):
      # Merged members are implemented in target interface implementation.
      return emitter.Emitter()
    return self._library_emitter.FileEmitter(basename, self._library_name)

  def _DartType(self, type_name):
    return self._type_registry.DartType(type_name)


# ------------------------------------------------------------------------------

class Dart2JSBackend(HtmlDartGenerator):
  """Generates a dart2js class for the dart:html library from a DOM IDL
  interface.
  """

  def __init__(self, interface, options):
    super(Dart2JSBackend, self).__init__(interface, options)

    self._database = options.database
    self._template_loader = options.templates
    self._type_registry = options.type_registry
    self._renamer = options.renamer
    self._interface_type_info = self._type_registry.TypeInfo(self._interface.id)
    self._current_secondary_parent = None
    self._library_name = self._renamer.GetLibraryName(self._interface)

  def ImplementsMergedMembers(self):
    return True

  def GenerateCallback(self, info):
    pass

  def RootClassName(self):
    return None

  def AdditionalImplementedInterfaces(self):
    implements = super(Dart2JSBackend, self).AdditionalImplementedInterfaces()
    if self._interface_type_info.list_item_type():
      implements.append('JavaScriptIndexingBehavior')
    return implements

  def NativeSpec(self):
    native_spec = MakeNativeSpec(self._interface.javascript_binding_name)
    return ' native "%s"' % native_spec

  def ImplementationTemplate(self):
    if IsPureInterface(self._interface.id):
      return self._template_loader.Load('pure_interface.darttemplate')

    template_file = ('impl_%s.darttemplate' %
                     self._interface.doc_js_name)
    return (self._template_loader.TryLoad(template_file) or
            self._template_loader.Load('dart2js_impl.darttemplate'))

  def StartInterface(self, members_emitter):
    self._members_emitter = members_emitter

  def FinishInterface(self):
    pass

  def HasSupportCheck(self):
    return self._interface.doc_js_name in js_support_checks

  def GetSupportCheck(self):
    return js_support_checks.get(self._interface.doc_js_name)

  def EmitStaticFactory(self, constructor_info):
    WITH_CUSTOM_STATIC_FACTORY = [
        'AudioContext',
        'Blob',
        'MutationObserver',
        'SpeechRecognition',
    ]

    if self._interface.doc_js_name in WITH_CUSTOM_STATIC_FACTORY:
      return

    has_optional = any(param_info.is_optional
        for param_info in constructor_info.param_infos)

    def FormatJS(index):
      arguments = constructor_info.ParametersAsArgumentList(index)
      if arguments:
        arguments = ', ' + arguments
      return "JS('%s', 'new %s(%s)'%s)" % (
          self._interface_type_info.interface_name(),
          constructor_info.name or self._interface.doc_js_name,
          ','.join(['#'] * index),
          arguments)

    if not has_optional:
      self._members_emitter.Emit(
          "  static $INTERFACE_NAME _create($PARAMETERS_DECLARATION) => $JS;\n",
          INTERFACE_NAME=self._interface_type_info.interface_name(),
          PARAMETERS_DECLARATION=constructor_info.ParametersDeclaration(
              self._DartType),
          JS=FormatJS(len(constructor_info.param_infos)))
    else:
      dispatcher_emitter = self._members_emitter.Emit(
          "  static $INTERFACE_NAME _create($PARAMETERS_DECLARATION) {\n"
          "$!DISPATCHER"
          "    return $JS;\n"
          "  }\n",
          INTERFACE_NAME=self._interface_type_info.interface_name(),
          PARAMETERS_DECLARATION=constructor_info.ParametersDeclaration(
              self._DartType),
          JS=FormatJS(len(constructor_info.param_infos)))

      for index, param_info in enumerate(constructor_info.param_infos):
        if param_info.is_optional:
          dispatcher_emitter.Emit(
            "    if (!?$OPT_PARAM_NAME) {\n"
            "      return $JS;\n"
            "    }\n",
            OPT_PARAM_NAME=constructor_info.param_infos[index].name,
            JS=FormatJS(index))

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
        '  $TYPE operator[](int index) => JS("$TYPE", "#[#]", this, index);\n',
        TYPE=self.SecureOutputType(element_type))

    if 'CustomIndexedSetter' in self._interface.ext_attrs:
      self._members_emitter.Emit(
          '\n'
          '  void operator[]=(int index, $TYPE value) {'
          ' JS("void", "#[#] = #", this, index, value); }',
          TYPE=self._NarrowInputType(element_type))
    else:
      self._members_emitter.Emit(
          '\n'
          '  void operator[]=(int index, $TYPE value) {\n'
          '    throw new UnsupportedError("Cannot assign element of immutable List.");\n'
          '  }\n',
          TYPE=self._NarrowInputType(element_type))

    self.EmitListMixin(self._DartType(element_type))

  def EmitAttribute(self, attribute, html_name, read_only):
    if self._HasCustomImplementation(attribute.id):
      return

    if IsPureInterface(self._interface.id):
      self._AddInterfaceAttribute(attribute, html_name)
      return

    # If the attribute is shadowing, we can't generate a shadowing
    # field (Issue 1633).
    # TODO(sra): _FindShadowedAttribute does not take into account the html
    #  renaming.  we should be looking for another attribute that has the same
    #  html_name.  Two attributes with the same IDL name might not match if one
    #  is renamed.
    (super_attribute, super_attribute_interface) = self._FindShadowedAttribute(
        attribute)
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
              NAME=html_name,
              TYPE=self.SecureOutputType(attribute.type.id))
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

    output_type = self.SecureOutputType(attribute.type.id)
    input_type = self._NarrowInputType(attribute.type.id)
    annotations = self._Annotations(attribute.type.id, attribute.id)
    rename = self._RenamingAnnotation(attribute.id, html_name)
    if not read_only:
      self._members_emitter.Emit(
          '\n  $RENAME$ANNOTATIONS$TYPE $NAME;'
          '\n',
          RENAME=rename,
          ANNOTATIONS=annotations,
          NAME=html_name,
          TYPE=output_type)
    else:
      template = '\n  $RENAME$(ANNOTATIONS)final $TYPE $NAME;\n'
      # Need to use a getter for list.length properties so we can add a
      # setter which throws an exception, satisfying List API.
      if self._interface_type_info.list_item_type() and html_name == 'length':
        template = ('\n  $RENAME$(ANNOTATIONS)$TYPE get $NAME => ' +
            'JS("$TYPE", "#.$NAME", this);\n')
      self._members_emitter.Emit(
          template,
          RENAME=rename,
          ANNOTATIONS=annotations,
          NAME=html_name,
          TYPE=output_type)

  def _AddAttributeUsingProperties(self, attribute, html_name, read_only):
    self._AddRenamingGetter(attribute, html_name)
    if not read_only:
      self._AddRenamingSetter(attribute, html_name)

  def _AddInterfaceAttribute(self, attribute, html_name):
    self._members_emitter.Emit(
        '\n  $TYPE $NAME;'
        '\n',
        NAME=html_name,
        TYPE=self.SecureOutputType(attribute.type.id))

  def _AddRenamingGetter(self, attr, html_name):

    conversion = self._OutputConversion(attr.type.id, attr.id)
    if conversion:
      return self._AddConvertingGetter(attr, html_name, conversion)
    return_type = self.SecureOutputType(attr.type.id)
    native_type = self._NarrowToImplementationType(attr.type.id)
    self._members_emitter.Emit(
        # TODO(sra): Use metadata to provide native name.
        '\n  $TYPE get $HTML_NAME => JS("$NATIVE_TYPE", "#.$NAME", this);'
        '\n',
        HTML_NAME=html_name,
        NAME=attr.id,
        TYPE=return_type,
        NATIVE_TYPE=native_type)

  def _AddRenamingSetter(self, attr, html_name):

    conversion = self._InputConversion(attr.type.id, attr.id)
    if conversion:
      return self._AddConvertingSetter(attr, html_name, conversion)
    self._members_emitter.Emit(
        # TODO(sra): Use metadata to provide native name.
        '\n  void set $HTML_NAME($TYPE value) {'
        '\n    JS("void", "#.$NAME = #", this, value);'
        '\n  }'
        '\n',
        HTML_NAME=html_name,
        NAME=attr.id,
        TYPE=self._NarrowInputType(attr.type.id))

  def _AddConvertingGetter(self, attr, html_name, conversion):
    self._members_emitter.Emit(
        '\n  $RETURN_TYPE get $HTML_NAME => $CONVERT(this._$(HTML_NAME));'
        "\n  @JSName('$NAME')"
        '\n  $(ANNOTATIONS)final $NATIVE_TYPE _$HTML_NAME;'
        '\n',
        ANNOTATIONS=self._Annotations(attr.type.id, html_name),
        CONVERT=conversion.function_name,
        HTML_NAME=html_name,
        NAME=attr.id,
        RETURN_TYPE=conversion.output_type,
        NATIVE_TYPE=conversion.input_type)

  def _AddConvertingSetter(self, attr, html_name, conversion):
    self._members_emitter.Emit(
        # TODO(sra): Use metadata to provide native name.
        '\n  void set $HTML_NAME($INPUT_TYPE value) {'
        '\n    this._$HTML_NAME = $CONVERT(value);'
        '\n  }'
        '\n  void set _$HTML_NAME(/*$NATIVE_TYPE*/ value) {'
        '\n    JS("void", "#.$NAME = #", this, value);'
        '\n  }'
        '\n',
        CONVERT=conversion.function_name,
        HTML_NAME=html_name,
        NAME=attr.id,
        INPUT_TYPE=conversion.input_type,
        NATIVE_TYPE=conversion.output_type)

  def AmendIndexer(self, element_type):
    pass

  def EmitOperation(self, info, html_name):
    """
    Arguments:
      info: An OperationInfo object.
    """
    if self._HasCustomImplementation(info.name):
      return

    if IsPureInterface(self._interface.id):
      self._AddInterfaceOperation(info, html_name)
    elif any(self._OperationRequiresConversions(op) for op in info.overloads):
      # Any conversions needed?
      self._AddOperationWithConversions(info, html_name)
    else:
      self._AddDirectNativeOperation(info, html_name)

  def _AddDirectNativeOperation(self, info, html_name):
    self._members_emitter.Emit(
        '\n'
        '  $RENAME$ANNOTATIONS$MODIFIERS$TYPE $NAME($PARAMS) native;\n',
        RENAME=self._RenamingAnnotation(info.declared_name, html_name),
        ANNOTATIONS=self._Annotations(info.type_name, info.declared_name),
        MODIFIERS='static ' if info.IsStatic() else '',
        TYPE=self.SecureOutputType(info.type_name),
        NAME=html_name,
        PARAMS=info.ParametersDeclaration(self._NarrowInputType))

  def _AddOperationWithConversions(self, info, html_name):
    # Assert all operations have same return type.
    assert len(set([op.type.id for op in info.operations])) == 1
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
        return self._NarrowInputType(type_name) if type_name else 'dynamic'

    parameter_names = [param_info.name for param_info in info.param_infos]
    parameter_types = [InputType(param_info.type_id)
                       for param_info in info.param_infos]
    operations = info.operations

    temp_version = [0]

    def GenerateCall(
        stmts_emitter, call_emitter, version, operation, argument_count):
      target = '_%s_%d' % (html_name, version);
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

          verified_type = InputType(info.param_infos[position].type_id)
          # The native method does not need an argument type if we know the type.
          # But we do need the native methods to have correct function types, so
          # be conservative.
          if param_type == verified_type:
            if param_type in ['String', 'num', 'int', 'double', 'bool', 'Object']:
              param_type = 'dynamic'

        target_parameters.append(
            '%s%s' % (TypeOrNothing(param_type), param_name))

      argument_list = ', '.join(arguments)
      # TODO(sra): If the native method has zero type checks, we can 'inline' is
      # and call it directly with a JS-expression.
      call = '%s(%s)' % (target, argument_list)

      if output_conversion:
        call = '%s(%s)' % (output_conversion.function_name, call)

      call_emitter.Emit(call)

      self._members_emitter.Emit(
          '  $RENAME$ANNOTATIONS$MODIFIERS$TYPE$TARGET($PARAMS) native;\n',
          RENAME=self._RenamingAnnotation(info.declared_name, target),
          ANNOTATIONS=self._Annotations(info.type_name, info.declared_name),
          MODIFIERS='static ' if info.IsStatic() else '',
          TYPE=TypeOrNothing(native_return_type),
          TARGET=target,
          PARAMS=', '.join(target_parameters))

    declaration = '%s%s %s(%s)' % (
        'static ' if info.IsStatic() else '',
        return_type,
        html_name,
        info.ParametersDeclaration(InputType))
    self._GenerateDispatcherBody(
        operations,
        parameter_names,
        declaration,
        GenerateCall,
        self._IsOptional,
        can_omit_type_check=lambda type, pos: type == parameter_types[pos])

  def _AddInterfaceOperation(self, info, html_name):
    self._members_emitter.Emit(
        '\n'
        '  $TYPE $NAME($PARAMS);\n',
        TYPE=self.SecureOutputType(info.type_name),
        NAME=info.name,
        PARAMS=info.ParametersDeclaration(self._NarrowInputType))

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
    member_name = '%s.%s' % (self._interface.doc_js_name, member_name)
    return member_name in _js_custom_members

  def _RenamingAnnotation(self, idl_name, member_name):
    if member_name != idl_name:
      return  "@JSName('%s')\n  " % idl_name
    return ''

  def _Annotations(self, idl_type, idl_member_name, indent='  '):
    anns = FindDart2JSAnnotationsAndComments(idl_type, self._interface.id,
        idl_member_name, self._library_name)

    if not AnyConversionAnnotations(idl_type, self._interface.id,
                                  idl_member_name):
      return_type = self.SecureOutputType(idl_type)
      native_type = self._NarrowToImplementationType(idl_type)
      if native_type != return_type:
        anns = anns + [
          "@Returns('%s')" % native_type,
          "@Creates('%s')" % native_type,
        ]
    return FormatAnnotationsAndComments(anns, indent);

  def CustomJSMembers(self):
    return _js_custom_members

  def _NarrowToImplementationType(self, type_name):
    return self._type_registry.TypeInfo(type_name).narrow_dart_type()

  def _NarrowInputType(self, type_name):
    return self._NarrowToImplementationType(type_name)

  def _FindShadowedAttribute(self, attr):
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
          parent_interface_name = parent.type.id
          interfaces_to_search_in.append(parent_interface_name)
          parent_type_info = self._type_registry.TypeInfo(parent_interface_name)
          if parent_type_info.merged_into():
            # IDL parent was merged into another interface, which became a
            # parent interface in Dart.
            parent_interface_name = parent_type_info.merged_into()
            interfaces_to_search_in.append(parent_interface_name)
          elif parent_type_info.merged_interface():
            # IDL parent has another interface that was merged into it.
            interfaces_to_search_in.append(parent_type_info.merged_interface())

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
  def __init__(self, multiemitter, dart_sources_dir, dart_libraries):
    self._multiemitter = multiemitter
    self._dart_sources_dir = dart_sources_dir
    self._path_to_emitter = {}
    self._dart_libraries = dart_libraries

  def FileEmitter(self, basename, library_name, template=None):
    aux_dir = os.path.join(self._dart_sources_dir, library_name)
    path = os.path.join(aux_dir, '%s.dart' % basename)
    if not path in self._path_to_emitter:
      emitter = self._multiemitter.FileEmitter(path)
      if not template is None:
        emitter = emitter.Emit(template)
      self._path_to_emitter[path] = emitter

      self._dart_libraries.AddFile(basename, library_name, path)
    return self._path_to_emitter[path]

  def EmitLibraries(self, auxiliary_dir):
    self._dart_libraries.Emit(self._multiemitter, auxiliary_dir)

# ------------------------------------------------------------------------------
class DartLibrary():
  def __init__(self, name, template_loader, library_type, output_dir):
    self._template = template_loader.Load(
        '%s_%s.darttemplate' % (name, library_type))
    self._dart_path = os.path.join(
        output_dir, '%s_%s.dart' % (name, library_type))
    self._paths = []

  def AddFile(self, path):
    self._paths.append(path)

  def Emit(self, emitter, auxiliary_dir):
    def massage_path(path):
      # The most robust way to emit path separators is to use / always.
      return path.replace('\\', '/')

    library_emitter = emitter.FileEmitter(self._dart_path)
    library_file_dir = os.path.dirname(self._dart_path)
    auxiliary_dir = os.path.relpath(auxiliary_dir, library_file_dir)
    imports_emitter = library_emitter.Emit(
        self._template, AUXILIARY_DIR=massage_path(auxiliary_dir))

    for path in sorted(self._paths):
      relpath = os.path.relpath(path, library_file_dir)
      imports_emitter.Emit(
          "part '$PATH';\n", PATH=massage_path(relpath))

# ------------------------------------------------------------------------------

class DartLibraries():
  def __init__(self, libraries, template_loader, library_type, output_dir):
    self._libraries = {}
    for library_name in libraries:
      self._libraries[library_name] = DartLibrary(
          library_name, template_loader, library_type, output_dir)

  def AddFile(self, basename, library_name, path):
    self._libraries[library_name].AddFile(path)

  def Emit(self, emitter, auxiliary_dir):
    for lib in self._libraries.values():
      lib.Emit(emitter, auxiliary_dir)
