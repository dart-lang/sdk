#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module provides shared functionality for the system to generate
Dart:html APIs from the IDL database."""

import emitter
import logging
import monitored
import os
import re
from generator import *
from htmldartgenerator import *

_logger = logging.getLogger('systemhtml')

HTML_LIBRARY_NAMES = ['html', 'indexed_db', 'svg',
                      'web_audio', 'web_gl', 'web_sql']

_js_custom_members = monitored.Set('systemhtml._js_custom_members', [
    'AudioBufferSourceNode.start',
    'AudioBufferSourceNode.stop',
    'AudioContext.createGain',
    'AudioContext.createScriptProcessor',
    'CanvasRenderingContext2D.drawImage',
    'CanvasRenderingContext2D.fill',
    'CanvasRenderingContext2D.fillText',
    'CanvasRenderingContext2D.lineDashOffset',
    'CanvasRenderingContext2D.setLineDash',
    'Console.memory',
    'ConsoleBase.assertCondition',
    'ConsoleBase.clear',
    'ConsoleBase.count',
    'ConsoleBase.debug',
    'ConsoleBase.dir',
    'ConsoleBase.dirxml',
    'ConsoleBase.error',
    'ConsoleBase.group',
    'ConsoleBase.groupCollapsed',
    'ConsoleBase.groupEnd',
    'ConsoleBase.info',
    'ConsoleBase.log',
    'ConsoleBase.markTimeline',
    'ConsoleBase.profile',
    'ConsoleBase.profileEnd',
    'ConsoleBase.table',
    'ConsoleBase.time',
    'ConsoleBase.timeEnd',
    'ConsoleBase.timeStamp',
    'ConsoleBase.trace',
    'ConsoleBase.warn',
    'WebKitCSSKeyframesRule.insertRule',
    'CSSStyleDeclaration.setProperty',
    'CSSStyleDeclaration.__propertyQuery__',
    'Document.createNodeIterator',
    'Document.createTreeWalker',
    'DOMException.name',
    'Element.createShadowRoot',
    'Element.insertAdjacentElement',
    'Element.insertAdjacentHTML',
    'Element.insertAdjacentText',
    'Element.remove',
    'Element.shadowRoot',
    'Element.matches',
    'ElementEvents.mouseWheel',
    'ElementEvents.transitionEnd',
    'FileReader.result',
    'HTMLTableElement.createTBody',
    'IDBCursor.next',
    'IDBDatabase.transaction',
    'IDBDatabase.transactionList',
    'IDBDatabase.transactionStore',
    'IDBDatabase.transactionStores',
    'KeyboardEvent.initKeyboardEvent',
    'Location.origin',
    'MouseEvent.offsetX',
    'MouseEvent.offsetY',
    'Navigator.language',
    'Navigator.webkitGetUserMedia',
    'ScriptProcessorNode._setEventListener',
    'URL.createObjectURL',
    'URL.createObjectUrlFromSource',
    'URL.createObjectUrlFromStream',
    'URL.createObjectUrlFromBlob',
    'URL.revokeObjectURL',
    'WheelEvent.deltaMode',
    'WheelEvent.wheelDeltaX',
    'WheelEvent.wheelDeltaY',
    'Window.cancelAnimationFrame',
    'Window.console',
    'Window.document',
    'Window.indexedDB',
    'Window.location',
    'Window.open',
    'Window.requestAnimationFrame',
    'Window.scrollX',
    'Window.scrollY'
    # 'WorkerContext.indexedDB', # Workers
    ], dart2jsOnly=True)

_js_custom_constructors = monitored.Set('systemhtml._js_custom_constructors', [
    'AudioContext',
    'Blob',
    'Comment',
    'MutationObserver',
    'RTCIceCandidate',
    'RTCPeerConnection',
    'RTCSessionDescription',
    'SpeechRecognition',
    ], dart2jsOnly=True)

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

_html_element_constructors = monitored.Dict(
      'systemhtml._html_element_constructors', {
  'HTMLAnchorElement' :
    ElementConstructorInfo(tag='a', opt_params=[('DOMString', 'href')]),
  'HTMLAreaElement': 'area',
  'HTMLButtonElement': 'button',
  'HTMLBRElement': 'br',
  'HTMLBaseElement': 'base',
  'HTMLBodyElement': 'body',
  'HTMLButtonElement': 'button',
  'HTMLCanvasElement':
    ElementConstructorInfo(tag='canvas',
                           opt_params=[('int', 'width'), ('int', 'height')]),
  'HTMLContentElement': 'content',
  'HTMLDataListElement': 'datalist',
  'HTMLDListElement': 'dl',
  'HTMLDetailsElement': 'details',
  'HTMLDivElement': 'div',
  'HTMLEmbedElement': 'embed',
  'HTMLFieldSetElement': 'fieldset',
  'HTMLFormElement': 'form',
  'HTMLHRElement': 'hr',
  'HTMLHeadElement': 'head',
  'HTMLHeadingElement': [ElementConstructorInfo('h1'),
                     ElementConstructorInfo('h2'),
                     ElementConstructorInfo('h3'),
                     ElementConstructorInfo('h4'),
                     ElementConstructorInfo('h5'),
                     ElementConstructorInfo('h6')],
  'HTMLHtmlElement': 'html',
  'HTMLIFrameElement': 'iframe',
  'HTMLImageElement':
    ElementConstructorInfo(tag='img',
                           opt_params=[('DOMString', 'src'),
                                       ('int', 'width'), ('int', 'height')]),
  'HTMLKeygenElement': 'keygen',
  'HTMLLIElement': 'li',
  'HTMLLabelElement': 'label',
  'HTMLLegendElement': 'legend',
  'HTMLLinkElement': 'link',
  'HTMLMapElement': 'map',
  'HTMLMenuElement': 'menu',
  'HTMLMetaElement': 'meta',
  'HTMLMeterElement': 'meter',
  'HTMLOListElement': 'ol',
  'HTMLObjectElement': 'object',
  'HTMLOptGroupElement': 'optgroup',
  'HTMLOutputElement': 'output',
  'HTMLParagraphElement': 'p',
  'HTMLParamElement': 'param',
  'HTMLPreElement': 'pre',
  'HTMLProgressElement': 'progress',
  'HTMLQuoteElement': 'q',
  'HTMLScriptElement': 'script',
  'HTMLSelectElement': 'select',
  'HTMLShadowElement': 'shadow',
  'HTMLSourceElement': 'source',
  'HTMLSpanElement': 'span',
  'HTMLStyleElement': 'style',
  'HTMLTableCaptionElement': 'caption',
  'HTMLTableCellElement': 'td',
  'HTMLTableColElement': 'col',
  'HTMLTableElement': 'table',
  'HTMLTableRowElement': 'tr',
  #'HTMLTableSectionElement'  <thead> <tbody> <tfoot>
  'HTMLTemplateElement': 'template',
  'HTMLTextAreaElement': 'textarea',
  'HTMLTitleElement': 'title',
  'HTMLTrackElement': 'track',
  'HTMLUListElement': 'ul',
  'HTMLVideoElement': 'video'
})

_svg_element_constructors = monitored.Dict(
      'systemhtml._svg_element_constructors', {
  'SVGAElement': 'a',
  'SVGAltGlyphElement': 'altGlyph',
  'SVGAnimateElement': 'animate',
  'SVGAnimateMotionElement': 'animateMotion',
  'SVGAnimateTransformElement': 'animateTransform',
  'SVGAnimationElement': 'animation',
  'SVGCircleElement': 'circle',
  'SVGClipPathElement': 'clipPath',
  'SVGCursorElement': 'cursor',
  'SVGDefsElement': 'defs',
  'SVGDescElement': 'desc',
  'SVGEllipseElement': 'ellipse',
  'SVGFEBlendElement': 'feBlend',
  'SVGFEColorMatrixElement': 'feColorMatrix',
  'SVGFEComponentTransferElement': 'feComponentTransfer',
  'SVGFEConvolveMatrixElement': 'feConvolveMatrix',
  'SVGFEDiffuseLightingElement': 'feDiffuseLighting',
  'SVGFEDisplacementMapElement': 'feDisplacementMap',
  'SVGFEDistantLightElement': 'feDistantLight',
  'SVGFEFloodElement': 'feFlood',
  'SVGFEFuncAElement': 'feFuncA',
  'SVGFEFuncBElement': 'feFuncB',
  'SVGFEFuncGElement': 'feFuncG',
  'SVGFEFuncRElement': 'feFuncR',
  'SVGFEGaussianBlurElement': 'feGaussianBlur',
  'SVGFEImageElement': 'feImage',
  'SVGFEMergeElement': 'feMerge',
  'SVGFEMergeNodeElement': 'feMergeNode',
  'SVGFEMorphology': 'feMorphology',
  'SVGFEOffsetElement': 'feOffset',
  'SVGFEPointLightElement': 'fePointLight',
  'SVGFESpecularLightingElement': 'feSpecularLighting',
  'SVGFESpotLightElement': 'feSpotLight',
  'SVGFETileElement': 'feTile',
  'SVGFETurbulenceElement': 'feTurbulence',
  'SVGFilterElement': 'filter',
  'SVGForeignObjectElement': 'foreignObject',
  'SVGGlyphElement': 'glyph',
  'SVGGElement': 'g',
  'SVGHKernElement': 'hkern',
  'SVGImageElement': 'image',
  'SVGLinearGradientElement': 'linearGradient',
  'SVGLineElement': 'line',
  'SVGMarkerElement': 'marker',
  'SVGMaskElement': 'mask',
  'SVGMPathElement': 'mpath',
  'SVGPathElement': 'path',
  'SVGPatternElement': 'pattern',
  'SVGPolygonElement': 'polygon',
  'SVGPolylineElement': 'polyline',
  'SVGRadialGradientElement': 'radialGradient',
  'SVGRectElement': 'rect',
  'SVGScriptElement': 'script',
  'SVGSetElement': 'set',
  'SVGStopElement': 'stop',
  'SVGStyleElement': 'style',
  'SVGSwitchElement': 'switch',
  'SVGSymbolElement': 'symbol',
  'SVGTextElement': 'text',
  'SVGTitleElement': 'title',
  'SVGTRefElement': 'tref',
  'SVGTSpanElement': 'tspan',
  'SVGUseElement': 'use',
  'SVGViewElement': 'view',
  'SVGVKernElement': 'vkern',
})

_element_constructors = {
  'html': _html_element_constructors,
  'indexed_db': {},
  'svg': _svg_element_constructors,
  'typed_data': {},
  'web_audio': {},
  'web_gl': {},
  'web_sql': {},
}

_factory_ctr_strings = {
  'html': {
      'provider_name': 'document',
      'constructor_name': 'createElement'
  },
  'indexed_db': {
      'provider_name': 'document',
      'constructor_name': 'createElement'
  },
  'svg': {
    'provider_name': '_SvgElementFactoryProvider',
    'constructor_name': 'createSvgElement_tag',
  },
  'typed_data': {
      'provider_name': 'document',
      'constructor_name': 'createElement'
  },
  'web_audio': {
    'provider_name': 'document',
    'constructor_name': 'createElement'
  },
  'web_gl': {
    'provider_name': 'document',
    'constructor_name': 'createElement'
  },
  'web_sql': {
    'provider_name': 'document',
    'constructor_name': 'createElement'
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
def SvgSupportStr(tagName):
  return 'Svg%s' % ElemSupportStr(tagName)

def ElemSupportStr(tagName):
  return "Element.isTagSupported('%s')" % tagName

_js_support_checks_basic_element_with_constructors = [
  'HTMLContentElement',
  'HTMLDataListElement',
  'HTMLDetailsElement',
  'HTMLEmbedElement',
  'HTMLMeterElement',
  'HTMLObjectElement',
  'HTMLOutputElement',
  'HTMLProgressElement',
  'HTMLTemplateElement',
  'HTMLTrackElement',
]

_js_support_checks_additional_element = [
  # IE creates keygen as Block elements
  'HTMLKeygenElement',
  'SVGAltGlyphElement',
  'SVGAnimateElement',
  'SVGAnimateMotionElement',
  'SVGAnimateTransformElement',
  'SVGCursorElement',
  'SVGFEBlendElement',
  'SVGFEColorMatrixElement',
  'SVGFEComponentTransferElement',
  'SVGFEConvolveMatrixElement',
  'SVGFEDiffuseLightingElement',
  'SVGFEDisplacementMapElement',
  'SVGFEDistantLightElement',
  'SVGFEFloodElement',
  'SVGFEFuncAElement',
  'SVGFEFuncBElement',
  'SVGFEFuncGElement',
  'SVGFEFuncRElement',
  'SVGFEGaussianBlurElement',
  'SVGFEImageElement',
  'SVGFEMergeElement',
  'SVGFEMergeNodeElement',
  'SVGFEMorphology',
  'SVGFEOffsetElement',
  'SVGFEPointLightElement',
  'SVGFESpecularLightingElement',
  'SVGFESpotLightElement',
  'SVGFETileElement',
  'SVGFETurbulenceElement',
  'SVGFilterElement',
  'SVGForeignObjectElement',
  'SVGSetElement',
]

js_support_checks = dict({
    'AudioContext': "JS('bool', '!!(window.AudioContext ||"
        " window.webkitAudioContext)')",
    'Crypto':
        "JS('bool', '!!(window.crypto && window.crypto.getRandomValues)')",
    'Database': "JS('bool', '!!(window.openDatabase)')",
    'ApplicationCache': "JS('bool', '!!(window.applicationCache)')",
    'DOMFileSystem': "JS('bool', '!!(window.webkitRequestFileSystem)')",
    'FormData': "JS('bool', '!!(window.FormData)')",
    'HashChangeEvent': "Device.isEventTypeSupported('HashChangeEvent')",
    'HTMLShadowElement': ElemSupportStr('shadow'),
    'HTMLTemplateElement': ElemSupportStr('template'),
    'MediaStreamEvent': "Device.isEventTypeSupported('MediaStreamEvent')",
    'MediaStreamTrackEvent': "Device.isEventTypeSupported('MediaStreamTrackEvent')",
    'NotificationCenter': "JS('bool', '!!(window.webkitNotifications)')",
    'Performance': "JS('bool', '!!(window.performance)')",
    'SpeechRecognition': "JS('bool', '!!(window.SpeechRecognition || "
        "window.webkitSpeechRecognition)')",
    'SVGExternalResourcesRequired': ('supported(SvgElement element)',
        "JS('bool', '#.externalResourcesRequired !== undefined && "
        "#.externalResourcesRequired.animVal !== undefined', "
        "element, element)"),
    'SVGLangSpace': ('supported(SvgElement element)',
        "JS('bool', '#.xmlspace !== undefined && #.xmllang !== undefined', "
        "element, element)"),
    'TouchList': "JS('bool', '!!document.createTouchList')",
    'WebGLRenderingContext': "JS('bool', '!!(window.WebGLRenderingContext)')",
    'WebKitPoint': "JS('bool', '!!(window.WebKitPoint)')",
    'WebSocket': "JS('bool', 'typeof window.WebSocket != \"undefined\"')",
    'Worker': "JS('bool', '(typeof window.Worker != \"undefined\")')",
    'XSLTProcessor': "JS('bool', '!!(window.XSLTProcessor)')",
  }.items() +
  dict((key,
        SvgSupportStr(_svg_element_constructors[key]) if key.startswith('SVG')
            else ElemSupportStr(_html_element_constructors[key])) for key in
    _js_support_checks_basic_element_with_constructors +
    _js_support_checks_additional_element).items())
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
    self._metadata = options.metadata

  def Generate(self):
    if IsCustomType(self._interface.id):
      pass
    elif 'Callback' in self._interface.ext_attrs:
      self.GenerateCallback()
    else:
      self.GenerateInterface()

  def GenerateCallback(self):
    """Generates a typedef for the callback interface."""
    typedef_name = self._renamer.RenameInterface(self._interface)
    if not typedef_name:
      return

    info = GetCallbackInfo(self._interface)
    code = self._library_emitter.FileEmitter(self._interface.id,
        self._library_name)
    code.Emit(self._template_loader.Load('callback.darttemplate'))

    annotations = self._metadata.GetFormattedMetadata(self._library_name,
        self._interface)

    code.Emit('$(ANNOTATIONS)typedef void $NAME($PARAMS);\n',
              ANNOTATIONS=annotations,
              NAME=typedef_name,
              PARAMS=info.ParametersAsDeclaration(self._DartType))
    self._backend.GenerateCallback(info)

  def GenerateInterface(self):
    interface_name = self._interface_type_info.interface_name()
    implementation_name = self._interface_type_info.implementation_name()
    self._library_emitter.AddTypeEntry(self._library_name,
                                       self._interface.id, implementation_name)

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
    infos = ElementConstructorInfos(self._interface.id,
        _element_constructors[self._library_name], factory_provider_name=
        _factory_ctr_strings[self._library_name]['provider_name'])

    if infos:
      factory_constructor_name = _factory_ctr_strings[
          self._library_name]['constructor_name']

    for info in infos:
      constructors.append(info.ConstructorInfo(self._interface.id))
      if factory_provider and factory_provider != info.factory_provider_name:
        _logger.warn('Conflicting factory provider names: %s != %s' %
          (factory_provider, info.factory_provider_name))
      factory_provider = info.factory_provider_name

    implementation_emitter = self._ImplementationEmitter()

    base_type_info = None
    if self._interface.parents:
      supertype = self._interface.parents[0].type.id
      if not IsDartCollectionType(supertype) and not IsPureInterface(supertype):
        base_type_info = self._type_registry.TypeInfo(supertype)

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

    mixins = self._backend.Mixins()
    mixins_str = ''
    if mixins:
      mixins_str = ' with ' + ', '.join(mixins)
      if not base_class:
        base_class = 'Interceptor'

    annotations = self._metadata.GetFormattedMetadata(
        self._library_name, self._interface, None, '')

    class_modifiers = ''
    if (self._renamer.ShouldSuppressInterface(self._interface) or
        IsPureInterface(self._interface.id)):
      class_modifiers = 'abstract '

    native_spec = ''
    if not IsPureInterface(self._interface.id):
      native_spec = self._backend.NativeSpec()

    implementation_members_emitter = implementation_emitter.Emit(
        self._backend.ImplementationTemplate(),
        LIBRARYNAME='dart.dom.%s' % self._library_name,
        ANNOTATIONS=annotations,
        CLASS_MODIFIERS=class_modifiers,
        CLASSNAME=self._interface_type_info.implementation_name(),
        EXTENDS=' extends %s' % base_class if base_class else '',
        IMPLEMENTS=implements_str,
        MIXINS=mixins_str,
        DOMNAME=self._interface.doc_js_name,
        NATIVESPEC=native_spec)
    stream_getter_signatures_emitter = None
    element_stream_getters_emitter = None
    if type(implementation_members_emitter) == tuple:
        # We add event stream getters for both Element and ElementList, so in
        # impl_Element.darttemplate, we have two additional "holes" for emitters
        # to fill in, with small variations. These store these specialized
        # emitters.
        assert len(implementation_members_emitter) == 3;
        stream_getter_signatures_emitter = \
            implementation_members_emitter[0]
        element_stream_getters_emitter = implementation_members_emitter[1]
        implementation_members_emitter = \
            implementation_members_emitter[2]
    self._backend.StartInterface(implementation_members_emitter)
    self._backend.EmitHelpers(base_class)
    self._event_generator.EmitStreamProviders(
        self._interface,
        self._backend.CustomJSMembers(),
        implementation_members_emitter,
        self._library_name)
    self._backend.AddConstructors(
        constructors, factory_provider, factory_constructor_name)

    isElement = False
    for parent in self._database.Hierarchy(self._interface):
      if parent.id == 'Element':
        isElement = True
    if isElement and self._interface.id != 'Element':
      implementation_members_emitter.Emit(
          '  /**\n'
          '   * Constructor instantiated by the DOM when a custom element has been created.\n'
          '   *\n'
          '   * This can only be called by subclasses from their created constructor.\n'
          '   */\n'
          '  $CLASSNAME.created() : super.created();\n',
          CLASSNAME=self._interface_type_info.implementation_name())

    self._backend.EmitSupportCheck()

    merged_interface = self._interface_type_info.merged_interface()
    if merged_interface:
      self._backend.AddMembers(self._database.GetInterface(merged_interface),
        not self._backend.ImplementsMergedMembers())

    self._backend.AddMembers(self._interface)
    self._backend.AddSecondaryMembers(self._interface)
    self._event_generator.EmitStreamGetters(
        self._interface,
        [],
        implementation_members_emitter,
        self._library_name, stream_getter_signatures_emitter,
        element_stream_getters_emitter)
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

  def __init__(self, interface, options, logging_level=logging.WARNING):
    super(Dart2JSBackend, self).__init__(interface, options, False)

    self._database = options.database
    self._template_loader = options.templates
    self._type_registry = options.type_registry
    self._renamer = options.renamer
    self._metadata = options.metadata
    self._interface_type_info = self._type_registry.TypeInfo(self._interface.id)
    self._current_secondary_parent = None
    self._library_name = self._renamer.GetLibraryName(self._interface)

    _logger.setLevel(logging_level)

  def ImplementsMergedMembers(self):
    return True

  def GenerateCallback(self, info):
    pass

  def AdditionalImplementedInterfaces(self):
    implements = super(Dart2JSBackend, self).AdditionalImplementedInterfaces()
    if self._interface_type_info.list_item_type() and self.HasIndexedGetter():
      implements.append('JavaScriptIndexingBehavior')
    return implements

  def NativeSpec(self):
    native_spec = MakeNativeSpec(self._interface.javascript_binding_name)
    return '@Native("%s")\n' % native_spec

  def ImplementationTemplate(self):
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
    """Return a tuple of the support check function signature and the support
    test itself. If no parameters are supplied, we assume the default."""
    if self._interface.doc_js_name in _js_support_checks_additional_element:
      if self._interface.doc_js_name in _svg_element_constructors:
        lib_prefix = 'Svg'
        constructors = _svg_element_constructors
      else:
        lib_prefix = ''
        constructors = _html_element_constructors
      return (js_support_checks.get(self._interface.doc_js_name) +
          " && (new %sElement.tag('%s') is %s)" % (lib_prefix,
        constructors[self._interface.doc_js_name],
        self._renamer.RenameInterface(self._interface)))
    return js_support_checks.get(self._interface.doc_js_name)

  def GenerateCustomFactory(self, constructor_info):
    # Custom factory will be taken from the template.
    return self._interface.doc_js_name in _js_custom_constructors

  def IsConstructorArgumentOptional(self, argument):
    return argument.optional

  def EmitStaticFactoryOverload(self, constructor_info, name, arguments):
    index = len(arguments)
    arguments = constructor_info.ParametersAsArgumentList(index)
    if arguments:
      arguments = ', ' + arguments
    self._members_emitter.Emit(
        "  static $INTERFACE_NAME $NAME($PARAMETERS) => "
          "JS('$INTERFACE_NAME', 'new $CTOR_NAME($PLACEHOLDERS)'$ARGUMENTS);\n",
        INTERFACE_NAME=self._interface_type_info.interface_name(),
        NAME=name,
        # TODO(antonm): add types to parameters.
        PARAMETERS=constructor_info.ParametersAsArgumentList(index),
        CTOR_NAME=constructor_info.name or self._interface.doc_js_name,
        PLACEHOLDERS=','.join(['#'] * index),
        ARGUMENTS=arguments)

  def SecondaryContext(self, interface):
    if interface is not self._current_secondary_parent:
      self._current_secondary_parent = interface
      self._members_emitter.Emit('\n  // From $WHERE\n', WHERE=interface.id)

  def HasIndexedGetter(self):
    ext_attrs = self._interface.ext_attrs
    has_indexed_getter = 'CustomIndexedGetter' in ext_attrs
    for operation in self._interface.operations:
      if operation.id == 'item' and 'getter' in operation.specials:
        has_indexed_getter = True
        break
    return has_indexed_getter

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

    has_indexed_getter = self.HasIndexedGetter()

    if has_indexed_getter:
      indexed_getter = ('JS("%s", "#[#]", this, index)' %
          self.SecureOutputType(element_type));
    elif any(op.id == 'getItem' for op in self._interface.operations):
      indexed_getter = 'this.getItem(index)'
    elif any(op.id == 'item' for op in self._interface.operations):
      indexed_getter = 'this.item(index)'

    if indexed_getter:
      self._members_emitter.Emit(
          '\n'
          '  $TYPE operator[](int index) {\n'
          '    if (JS("bool", "# >>> 0 !== # || # >= #", index,\n'
          '        index, index, length))\n'
          '      throw new RangeError.index(index, this);\n'
          '    return $INDEXED_GETTER;\n'
          '  }',
          INDEXED_GETTER=indexed_getter,
          TYPE=self.SecureOutputType(element_type, False, True))

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
      self._AddInterfaceAttribute(attribute, html_name, read_only)
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
              TYPE=self.SecureOutputType(attribute.type.id, False, read_only))
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

    output_type = self.SecureOutputType(attribute.type.id, False, read_only)
    input_type = self._NarrowInputType(attribute.type.id)
    metadata = self._Metadata(attribute.type.id, attribute.id, output_type)
    rename = self._RenamingAnnotation(attribute.id, html_name)
    if not read_only:
      self._members_emitter.Emit(
          '\n  $RENAME$METADATA$TYPE $NAME;'
          '\n',
          RENAME=rename,
          METADATA=metadata,
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
          ANNOTATIONS=metadata,
          NAME=html_name,
          TYPE=output_type)

  def _AddAttributeUsingProperties(self, attribute, html_name, read_only):
    self._AddRenamingGetter(attribute, html_name)
    if not read_only:
      self._AddRenamingSetter(attribute, html_name)

  def _AddInterfaceAttribute(self, attribute, html_name, read_only):
    self._members_emitter.Emit(
        '\n  $QUALIFIER$TYPE $NAME;'
        '\n',
        QUALIFIER='final ' if read_only else '',
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
        '\n  $(METADATA)$RETURN_TYPE get $HTML_NAME => '
        '$CONVERT(this._get_$(HTML_NAME));'
        "\n  @JSName('$NAME')"
        '\n  $(JS_METADATA)final $NATIVE_TYPE _get_$HTML_NAME;'
        '\n',
        METADATA=self._metadata.GetFormattedMetadata(
            self._library_name, self._interface, html_name, '  '),
        JS_METADATA=self._Metadata(attr.type.id, html_name, conversion.input_type),
        CONVERT=conversion.function_name,
        HTML_NAME=html_name,
        NAME=attr.id,
        RETURN_TYPE=conversion.output_type,
        NATIVE_TYPE=conversion.input_type)

  def _AddConvertingSetter(self, attr, html_name, conversion):
    self._members_emitter.Emit(
        # TODO(sra): Use metadata to provide native name.
        '\n  void set $HTML_NAME($INPUT_TYPE value) {'
        '\n    this._set_$HTML_NAME = $CONVERT(value);'
        '\n  }'
        '\n  void set _set_$HTML_NAME(/*$NATIVE_TYPE*/ value) {'
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

  def RootClassName(self):
    return 'Interceptor'

  def OmitOperationOverrides(self):
    return True

  def EmitOperation(self, info, html_name):
    """
    Arguments:
      info: An OperationInfo object.
    """
    if self._HasCustomImplementation(info.name):
      return

    if IsPureInterface(self._interface.id):
      self._AddInterfaceOperation(info, html_name)
    elif info.callback_args:
      self._AddFutureifiedOperation(info, html_name)
    elif any(self._OperationRequiresConversions(op) for op in info.overloads):
      # Any conversions needed?
      self._AddOperationWithConversions(info, html_name)
    else:
      self._AddDirectNativeOperation(info, html_name)

  def _AddDirectNativeOperation(self, info, html_name):
    self._members_emitter.Emit(
        '\n'
        '  $RENAME$METADATA$MODIFIERS$TYPE $NAME($PARAMS) native;\n',
        RENAME=self._RenamingAnnotation(info.declared_name, html_name),
        METADATA=self._Metadata(info.type_name, info.declared_name,
            self.SecureOutputType(info.type_name)),
        MODIFIERS='static ' if info.IsStatic() else '',
        TYPE=self.SecureOutputType(info.type_name, False, True),
        NAME=html_name,
        PARAMS=info.ParametersAsDeclaration(self._NarrowInputType))

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
      target = '_%s_%d' % (
          html_name[1:] if html_name.startswith('_') else html_name, version);
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
          '  $RENAME$METADATA$MODIFIERS$TYPE$TARGET($PARAMS) native;\n',
          RENAME=self._RenamingAnnotation(info.declared_name, target),
          METADATA=self._Metadata(info.type_name, info.declared_name, None),
          MODIFIERS='static ' if info.IsStatic() else '',
          TYPE=TypeOrNothing(native_return_type),
          TARGET=target,
          PARAMS=', '.join(target_parameters))

    declaration = '%s%s%s %s(%s)' % (
        self._Metadata(info.type_name, info.declared_name, return_type),
        'static ' if info.IsStatic() else '',
        return_type,
        html_name,
        info.ParametersAsDeclaration(InputType))
    self._GenerateDispatcherBody(
        info,
        operations,
        declaration,
        GenerateCall,
        IsOptional,
        can_omit_type_check=lambda type, pos: type == parameter_types[pos])

  def _AddInterfaceOperation(self, info, html_name):
    self._members_emitter.Emit(
        '\n'
        '  $TYPE $NAME($PARAMS);\n',
        TYPE=self.SecureOutputType(info.type_name, False, True),
        NAME=html_name,
        PARAMS=info.ParametersAsDeclaration(self._NarrowInputType))


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

  def _Metadata(self, idl_type, idl_member_name, dart_type, indent='  '):
    anns = self._metadata.GetDart2JSMetadata(
        idl_type, self._library_name, self._interface, idl_member_name)

    if not self._metadata.AnyConversionAnnotations(
        idl_type, self._interface.id, idl_member_name):
      return_type = self.SecureOutputType(idl_type)
      native_type = self._NarrowToImplementationType(idl_type)
      if native_type != return_type:
        anns = anns + [
          "@Returns('%s')" % native_type,
          "@Creates('%s')" % native_type,
        ]
    if dart_type == 'dynamic' or dart_type == 'Object':
      def js_type_annotation(ann):
        return re.search('^@.*Returns', ann) or re.search('^@.*Creates', ann)
      if not filter(js_type_annotation, anns):
        _logger.warn('Member with wildcard native type: %s.%s' %
            (self._interface.id, idl_member_name))

    return self._metadata.FormatMetadata(anns, indent);

  def CustomJSMembers(self):
    return _js_custom_members

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

  def AddTypeEntry(self, basename, idl_name, dart_name):
    self._dart_libraries.AddTypeEntry(basename, idl_name, dart_name)

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
    self._typeMap = {}

  def AddFile(self, path):
    self._paths.append(path)

  def AddTypeEntry(self, idl_name, dart_name):
    self._typeMap[idl_name] = dart_name

  def Emit(self, emitter, auxiliary_dir):
    def massage_path(path):
      # The most robust way to emit path separators is to use / always.
      return path.replace('\\', '/')

    library_emitter = emitter.FileEmitter(self._dart_path)
    library_file_dir = os.path.dirname(self._dart_path)
    auxiliary_dir = os.path.relpath(auxiliary_dir, library_file_dir)
    emitters = library_emitter.Emit(
        self._template, AUXILIARY_DIR=massage_path(auxiliary_dir))
    if isinstance(emitters, tuple):
      imports_emitter, map_emitter = emitters
    else:
      imports_emitter, map_emitter = emitters, None


    for path in sorted(self._paths):
      relpath = os.path.relpath(path, library_file_dir)
      imports_emitter.Emit(
          "part '$PATH';\n", PATH=massage_path(relpath))

    if map_emitter:
      items = self._typeMap.items()
      items.sort()
      for (idl_name, dart_name) in items:
        map_emitter.Emit(
          "  '$IDL_NAME': () => $DART_NAME,\n",
          IDL_NAME=idl_name,
          DART_NAME=dart_name)


# ------------------------------------------------------------------------------

class DartLibraries():
  def __init__(self, libraries, template_loader, library_type, output_dir):
    self._libraries = {}
    for library_name in libraries:
      self._libraries[library_name] = DartLibrary(
          library_name, template_loader, library_type, output_dir)

  def AddFile(self, basename, library_name, path):
    self._libraries[library_name].AddFile(path)

  def AddTypeEntry(self, library_name, idl_name, dart_name):
    self._libraries[library_name].AddTypeEntry(idl_name, dart_name)

  def Emit(self, emitter, auxiliary_dir):
    for lib in self._libraries.values():
      lib.Emit(emitter, auxiliary_dir)
