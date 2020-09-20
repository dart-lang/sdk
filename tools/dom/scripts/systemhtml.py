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
from htmlrenamer import generateCallbackInterface

_logger = logging.getLogger('systemhtml')

HTML_LIBRARY_NAMES = [
    'html', 'indexed_db', 'svg', 'web_audio', 'web_gl', 'web_sql'
]

_safe_to_ignore_shadowing_members = monitored.Set(
    'systemhtml._safe_to_ignore_shadowing_members', [
        'SVGElement.tabIndex',
        'SVGStyleElement.title',
    ])

_js_custom_members = monitored.Set(
    'systemhtml._js_custom_members',
    [
        'AudioContext.createGain',
        'AudioContext.createScriptProcessor',
        'CanvasRenderingContext2D.drawImage',
        'CanvasRenderingContext2D.fillText',
        'CanvasRenderingContext2D.lineDashOffset',
        'CanvasRenderingContext2D.setLineDash',
        'Console.memory',
        'ConsoleBase.assertCondition',
        'ConsoleBase.clear',
        'ConsoleBase.count',
        'ConsoleBase.countReset',
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
        'DOMException.toString',
        # ListMixin already provides this method although the implementation
        # is slower. As this class is obsolete anyway, we ignore the slowdown in
        # DOMStringList performance.
        'DOMStringList.contains',
        'Element.animate',
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
        'HTMLAnchorElement.toString',
        'HTMLAreaElement.toString',
        'HTMLTableElement.createTBody',
        'IDBCursor.next',
        'IDBDatabase.transaction',
        'IDBDatabase.transactionList',
        'IDBDatabase.transactionStore',
        'IDBDatabase.transactionStores',
        'KeyboardEvent.initKeyboardEvent',
        'Location.origin',
        'Location.toString',
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
        'URL.toString',
        'WheelEvent.deltaMode',
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
    ],
    dart2jsOnly=True)

_js_custom_constructors = monitored.Set(
    'systemhtml._js_custom_constructors', [
        'AudioContext',
        'Blob',
        'Comment',
        'MutationObserver',
        'PaymentRequest',
        'RTCIceCandidate',
        'RTCPeerConnection',
        'RTCSessionDescription',
        'SpeechRecognition',
    ],
    dart2jsOnly=True)

# Classes that offer only static methods, and therefore we should suppress
# constructor creation.
_static_classes = set(['Url'])

# Callback typedefs with generic List (List<nnn>) convert to List
_callback_list_generics_mapping = monitored.Set(
    'systemhtml._callback_list_generics_mapping', [
        'List<Entry>',
        'List<IntersectionObserverEntry>',
        'List<MutationRecord>',
        'List<_Report>',
        'List<ResizeObserverEntry>',
    ])


# Information for generating element constructors.
#
# TODO(sra): maybe remove all the argument complexity and use cascades.
#
#   var c = new CanvasElement(width: 100, height: 70);
#   var c = new CanvasElement()..width = 100..height = 70;
#
class ElementConstructorInfo(object):

    def __init__(self,
                 name=None,
                 tag=None,
                 params=[],
                 opt_params=[],
                 factory_provider_name='document'):
        self.name = name  # The constructor name 'h1' in 'HeadingElement.h1'
        self.tag = tag or name  # The HTML or SVG tag
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
        # optional parameters are always nullable
        info.param_infos = map(
            lambda tXn: ParamInfo(
                name=tXn[1],
                type_id=tXn[0],
                is_optional=True,
                is_nullable=True,
                default_value=None,
                default_value_is_null=False), self.opt_params)
        info.requires_named_arguments = True
        info.factory_parameters = ['"%s"' % self.tag]
        info.pure_dart_constructor = True
        return info


_html_element_constructors = monitored.Dict(
    'systemhtml._html_element_constructors',
    {
        'HTMLAnchorElement':
        ElementConstructorInfo(tag='a', opt_params=[('DOMString', 'href')]),
        'HTMLAreaElement':
        'area',
        'HTMLButtonElement':
        'button',
        'HTMLBRElement':
        'br',
        'HTMLBaseElement':
        'base',
        'HTMLBodyElement':
        'body',
        'HTMLButtonElement':
        'button',
        'HTMLCanvasElement':
        ElementConstructorInfo(
            tag='canvas', opt_params=[('int', 'width'), ('int', 'height')]),
        'HTMLContentElement':
        'content',
        'HTMLDataListElement':
        'datalist',
        'HTMLDListElement':
        'dl',
        'HTMLDetailsElement':
        'details',
        'HTMLDivElement':
        'div',
        'HTMLEmbedElement':
        'embed',
        'HTMLFieldSetElement':
        'fieldset',
        'HTMLFormElement':
        'form',
        'HTMLHRElement':
        'hr',
        'HTMLHeadElement':
        'head',
        'HTMLHeadingElement': [
            ElementConstructorInfo('h1'),
            ElementConstructorInfo('h2'),
            ElementConstructorInfo('h3'),
            ElementConstructorInfo('h4'),
            ElementConstructorInfo('h5'),
            ElementConstructorInfo('h6')
        ],
        'HTMLHtmlElement':
        'html',
        'HTMLIFrameElement':
        'iframe',
        'HTMLImageElement':
        ElementConstructorInfo(
            tag='img',
            opt_params=[('DOMString', 'src'), ('int', 'width'),
                        ('int', 'height')]),
        'HTMLKeygenElement':
        'keygen',
        'HTMLLIElement':
        'li',
        'HTMLLabelElement':
        'label',
        'HTMLLegendElement':
        'legend',
        'HTMLLinkElement':
        'link',
        'HTMLMapElement':
        'map',
        'HTMLMenuElement':
        'menu',
        'HTMLMetaElement':
        'meta',
        'HTMLMeterElement':
        'meter',
        'HTMLOListElement':
        'ol',
        'HTMLObjectElement':
        'object',
        'HTMLOptGroupElement':
        'optgroup',
        'HTMLOutputElement':
        'output',
        'HTMLParagraphElement':
        'p',
        'HTMLParamElement':
        'param',
        'HTMLPreElement':
        'pre',
        'HTMLProgressElement':
        'progress',
        'HTMLQuoteElement':
        'q',
        'HTMLScriptElement':
        'script',
        'HTMLSelectElement':
        'select',
        'HTMLShadowElement':
        'shadow',
        'HTMLSourceElement':
        'source',
        'HTMLSpanElement':
        'span',
        'HTMLStyleElement':
        'style',
        'HTMLTableCaptionElement':
        'caption',
        'HTMLTableCellElement':
        'td',
        'HTMLTableColElement':
        'col',
        'HTMLTableElement':
        'table',
        'HTMLTableRowElement':
        'tr',
        #'HTMLTableSectionElement'  <thead> <tbody> <tfoot>
        'HTMLTemplateElement':
        'template',
        'HTMLTextAreaElement':
        'textarea',
        'HTMLTitleElement':
        'title',
        'HTMLTrackElement':
        'track',
        'HTMLUListElement':
        'ul',
        'HTMLVideoElement':
        'video'
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


def ElementConstructorInfos(typename,
                            element_constructors,
                            factory_provider_name='_Elements'):
    """Returns list of ElementConstructorInfos about the convenience constructors
  for an Element or SvgElement."""
    # TODO(sra): Handle multiple and named constructors.
    if typename not in element_constructors:
        return []
    infos = element_constructors[typename]
    if isinstance(infos, str):
        infos = ElementConstructorInfo(
            tag=infos, factory_provider_name=factory_provider_name)
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
    'Animation':
    "JS('bool', '!!(document.body.animate)')",
    'AudioContext':
    "JS('bool', '!!(window.AudioContext ||"
    " window.webkitAudioContext)')",
    'Crypto':
    "JS('bool', '!!(window.crypto && window.crypto.getRandomValues)')",
    'Database':
    "JS('bool', '!!(window.openDatabase)')",
    'DOMPoint':
    "JS('bool', '!!(window.DOMPoint) || !!(window.WebKitPoint)')",
    'ApplicationCache':
    "JS('bool', '!!(window.applicationCache)')",
    'DOMFileSystem':
    "JS('bool', '!!(window.webkitRequestFileSystem)')",
    'FormData':
    "JS('bool', '!!(window.FormData)')",
    'HashChangeEvent':
    "Device.isEventTypeSupported('HashChangeEvent')",
    'HTMLShadowElement':
    ElemSupportStr('shadow'),
    'HTMLTemplateElement':
    ElemSupportStr('template'),
    'MediaStreamEvent':
    "Device.isEventTypeSupported('MediaStreamEvent')",
    'MediaStreamTrackEvent':
    "Device.isEventTypeSupported('MediaStreamTrackEvent')",
    'MediaSource':
    "JS('bool', '!!(window.MediaSource)')",
    'Notification':
    "JS('bool', '!!(window.Notification)')",
    'Performance':
    "JS('bool', '!!(window.performance)')",
    'SpeechRecognition':
    "JS('bool', '!!(window.SpeechRecognition || "
    "window.webkitSpeechRecognition)')",
    'SVGExternalResourcesRequired':
    ('supported(SvgElement element)',
     "JS('bool', '#.externalResourcesRequired !== undefined && "
     "#.externalResourcesRequired.animVal !== undefined', "
     "element, element)"),
    'SVGLangSpace':
    ('supported(SvgElement element)',
     "JS('bool', '#.xmlspace !== undefined && #.xmllang !== undefined', "
     "element, element)"),
    'TouchList':
    "JS('bool', '!!document.createTouchList')",
    'WebGLRenderingContext':
    "JS('bool', '!!(window.WebGLRenderingContext)')",
    'WebSocket':
    "JS('bool', 'typeof window.WebSocket != \"undefined\"')",
    'Worker':
    "JS('bool', '(typeof window.Worker != \"undefined\")')",
    'XSLTProcessor':
    "JS('bool', '!!(window.XSLTProcessor)')",
}.items() + dict(
    (key, SvgSupportStr(_svg_element_constructors[key]) if key.
     startswith('SVG') else ElemSupportStr(_html_element_constructors[key]))
    for key in _js_support_checks_basic_element_with_constructors +
    _js_support_checks_additional_element).items())

# JavaScript element class names of elements for which createElement does not
# always return exactly the right element, either because it might not be
# supported, or some browser does something weird.
_js_unreliable_element_factories = set(
    _js_support_checks_basic_element_with_constructors +
    _js_support_checks_additional_element + [
        'HTMLEmbedElement',
        'HTMLObjectElement',
        'HTMLShadowElement',
        'HTMLTemplateElement',
    ])

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
        self._interface_type_info = self._type_registry.TypeInfo(
            self._interface.id)
        self._library_name = self._renamer.GetLibraryName(self._interface)
        self._metadata = options.metadata

    def Generate(self):
        if IsCustomType(self._interface.id):
            pass
        elif 'Callback' in self._interface.ext_attrs:
            if len(GetCallbackHandlers(self._interface)) > 0:
                self.GenerateCallback()
            elif generateCallbackInterface(self._interface.id):
                self.GenerateInterface()
            else:
                return
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

        annotations = self._metadata.GetFormattedMetadata(
            self._library_name, self._interface)

        params = info.ParametersAsDeclaration(self._DartType)

        types = params.split()
        if len(types) > 0:
            mapType = types[0] in _callback_list_generics_mapping
            if mapType is True:
                types[0] = 'List'
                params = " ".join(types)

        code.Emit(
            '$(ANNOTATIONS)typedef void $NAME($PARAMS);\n',
            ANNOTATIONS=annotations,
            NAME=typedef_name,
            PARAMS=params)
        self._backend.GenerateCallback(info)

    def GenerateInterface(self):
        interface_name = self._interface_type_info.interface_name()

        implementation_name = self._interface_type_info.implementation_name()
        self._library_emitter.AddTypeEntry(
            self._library_name, self._interface.id, implementation_name)

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
        infos = ElementConstructorInfos(
            self._interface.id,
            _element_constructors[self._library_name],
            factory_provider_name=_factory_ctr_strings[self._library_name]
            ['provider_name'])

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
            if not IsDartCollectionType(supertype) and not IsPureInterface(
                    supertype, self._database):
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
            elif (base_class == 'NativeFieldWrapperClass2' and
                  self._options.dart_js_interop and
                  not (isinstance(self._backend, Dart2JSBackend))):
                base_class = 'DartHtmlDomObject'

        annotations = self._metadata.GetFormattedMetadata(
            self._library_name, self._interface, None, '')

        class_modifiers = ''
        if (self._renamer.ShouldSuppressInterface(self._interface) or
                IsPureInterface(self._interface.id, self._database)):
            # XMLHttpRequestProgressEvent can't be abstract we need to instantiate
            # for JsInterop.
            if (not (isinstance(self._backend, Dart2JSBackend)) and
                (self._interface.id == 'XMLHttpRequestProgressEvent' or
                 self._interface.id == 'DOMStringMap')):
                # Suppress abstract for XMLHttpRequestProgressEvent and DOMStringMap
                # for Dartium.  Need to be able to instantiate the class; can't be abstract.
                class_modifiers = ''
            else:
                # For Dartium w/ JsInterop these suppressed interfaces are needed to
                # instanciate the internal classes.
                if (self._renamer.ShouldSuppressInterface(self._interface) and
                        not (isinstance(self._backend, Dart2JSBackend)) and
                        self._options.dart_js_interop):
                    class_modifiers = ''
                else:
                    class_modifiers = 'abstract '

        native_spec = ''
        if not IsPureInterface(self._interface.id, self._database):
            native_spec = self._backend.NativeSpec()

        class_name = self._interface_type_info.implementation_name()

        js_interop_wrapper = '''

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  {0}.internal_() : super.internal_();

'''.format(class_name)
        if base_class == 'NativeFieldWrapperClass2' or base_class == 'DartHtmlDomObject':
            js_interop_wrapper = '''

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  {0}.internal_() {{ }}
'''.format(class_name)
            # Change to use the synthesized class so we can construct with a mixin
            # classes prefixed with name of NativeFieldWrapperClass2 don't have a
            # default constructor so classes with mixins can't be new'd.
            if (self._options.templates._conditions['DARTIUM'] and
                    self._options.dart_js_interop and
                (self._interface.id == 'NamedNodeMap' or
                 self._interface.id == 'CSSStyleDeclaration')):
                base_class = 'DartHtmlDomObject'

        maplikeKeyType = ''
        maplikeValueType = ''
        if self._interface.isMaplike:
            maplikeKeyType = self._type_registry.\
                _TypeInfo(self._interface.maplike_key_value[0].id).dart_type()
            maplikeValueType = 'dynamic'
            mixins_str = " with MapMixin<%s, %s>" % (maplikeKeyType,
                                                     maplikeValueType)

        implementation_members_emitter = implementation_emitter.Emit(
            self._backend.ImplementationTemplate(),
            LIBRARYNAME='dart.dom.%s' % self._library_name,
            ANNOTATIONS=annotations,
            CLASS_MODIFIERS=class_modifiers,
            CLASSNAME=class_name,
            EXTENDS=' extends %s' % base_class if base_class else '',
            IMPLEMENTS=implements_str,
            MIXINS=mixins_str,
            DOMNAME=self._interface.doc_js_name,
            NATIVESPEC=native_spec,
            KEYTYPE=maplikeKeyType,
            VALUETYPE=maplikeValueType,
            NULLABLE='?',
            NULLSAFECAST=True,
            NULLASSERT='!')
        stream_getter_signatures_emitter = None
        element_stream_getters_emitter = None
        if type(implementation_members_emitter) == tuple:
            # We add event stream getters for both Element and ElementList, so in
            # impl_Element.darttemplate, we have two additional "holes" for emitters
            # to fill in, with small variations. These store these specialized
            # emitters.
            assert len(implementation_members_emitter) == 3
            stream_getter_signatures_emitter = \
                implementation_members_emitter[0]
            element_stream_getters_emitter = implementation_members_emitter[1]
            implementation_members_emitter = \
                implementation_members_emitter[2]
        self._backend.StartInterface(implementation_members_emitter)
        self._backend.EmitHelpers(base_class)
        self._event_generator.EmitStreamProviders(
            self._interface, self._backend.CustomJSMembers(),
            implementation_members_emitter, self._library_name)
        self._backend.AddConstructors(constructors, factory_provider,
                                      factory_constructor_name)

        isElement = False
        for parent in self._database.Hierarchy(self._interface):
            if parent.id == 'Element':
                isElement = True

        # Write out the JsInterop code.
        if (implementation_members_emitter and
                self._options.templates._conditions['DARTIUM'] and
                self._options.dart_js_interop and
                not IsPureInterface(self._interface.id, self._database)):
            implementation_members_emitter.Emit(js_interop_wrapper)

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
            self._backend.AddMembers(
                self._database.GetInterface(merged_interface),
                not self._backend.ImplementsMergedMembers())

        self._backend.AddMembers(self._interface, False,
                                 self._options.dart_js_interop)
        self._backend.AddSecondaryMembers(self._interface)
        self._event_generator.EmitStreamGetters(
            self._interface, [], implementation_members_emitter,
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
''' TODO(terry): Current idl_parser (Chrome) doesn't keep the Promise type e.g.,
                 Promise<T> in the AST so there is no way to pull this out.  Need
                 to investigate getting the Chrome folks to fix.  However, they
                 don't use this in the C++ code generation and don't have a need
                 for this feature.  For now I have a table that maps to the
                 parameterized Promise type.
'''
promise_attributes = monitored.Dict(
    'systemhtml.promise_attr_type', {
        "Animation.finished": {
            "type": "Animation",
            "creates": "Animation"
        },
        "Animation.ready": {
            "type": "Animation",
            "creates": "Animation"
        },
        "BeforeInstallPromptEvent.userChoice": {
            "type": "dictionary"
        },
        "FontFace.loaded": {
            "type": "FontFace",
            "creates": "FontFace"
        },
        "FontFaceSet.ready": {
            "type": "FontFaceSet",
            "creates": "FontFaceSet"
        },
        "MediaKeySession.closed": {
            "type": "void"
        },
        "PresentationReceiver.connectionList": {
            "type": "PresentationConnectionList",
            "creates": "PresentationConnectionList"
        },
        "ServiceWorkerContainer.ready": {
            "type": "ServiceWorkerRegistration",
            "creates": "ServiceWorkerRegistration"
        },
    })

promise_operations = monitored.Dict(
    'systemhtml.promise_oper_type', {
        "Clipboard.read": {
            "type": "DataTransfer",
            "creates": "DataTransfer"
        },
        "Clipboard.readText": {
            "type": "String"
        },
        "FontFace.load": {
            "type": "FontFace",
            "creates": "FontFace"
        },
        "FontFaceSet.load": {
            "type": "List<dynamic>"
        },
        "OffscreenCanvas.load": {
            "type": "Blob",
            "creates": "Blob"
        },
        "BackgroundFetchManager.fetch": {
            "type": "BackgroundFetchRegistration",
            "creates": "BackgroundFetchRegistration"
        },
        "BackgroundFetchManager.get": {
            "type": "BackgroundFetchRegistration",
            "creates": "BackgroundFetchRegistration"
        },
        "BackgroundFetchManager.getIds": {
            "type": "List<dynamic>"
        },
        "BackgroundFetchRegistration.abort": {
            "type": "bool"
        },
        "SyncManager.getTags": {
            "type": "List<dynamic>"
        },
        "BudgetService.getCost": {
            "type": "double"
        },
        "BudgetService.getBudget": {
            "type": "BudgetState",
            "creates": "BudgetState"
        },
        "BudgetService.reserve": {
            "type": "bool"
        },
        "Body.blob": {
            "type": "Blob",
            "creates": "Blob"
        },
        "Body.formData": {
            "type": "FormData",
            "creates": "FormData"
        },
        "Body.text": {
            "type": "String"
        },
        "ImageCapture.getPhotoCapabilities": {
            "type": "PhotoCapabilities",
            "creates": "PhotoCapabilities"
        },
        "ImageCapture.getPhotoSettings": {
            "type": "dictionary"
        },
        "ImageCapture.takePhoto": {
            "type": "Blob",
            "creates": "Blob"
        },
        "ImageCapture.grabFrame": {
            "type": "ImageBitmap",
            "creates": "ImageBitmap"
        },
        "Navigator.getInstalledRelatedApps": {
            "type": "RelatedApplication",
            "creates": "RelatedApplication"
        },
        "OffscreenCanvas.convertToBlob": {
            "type": "Blob",
            "creates": "Blob"
        },
        "MediaCapabilities.decodingInfo": {
            "type": "MediaCapabilitiesInfo",
            "creates": "MediaCapabilitiesInfo"
        },
        "MediaCapabilities.encodingInfo": {
            "type": "MediaCapabilitiesInfo",
            "creates": "MediaCapabilitiesInfo"
        },
        "MediaDevices.enumerateDevices": {
            "type": "List<dynamic>"
        },
        "MediaDevices.getUserMedia": {
            "type": "MediaStream",
            "creates": "MediaStream"
        },
        "ServiceWorkerRegistration.getNotifications": {
            "type": "List<dynamic>"
        },
        "PaymentInstruments.delete": {
            "type": "bool"
        },
        "PaymentInstruments.get": {
            "type": "dictionary"
        },
        "PaymentInstruments.keys": {
            "type": "List<dynamic>"
        },
        "PaymentInstrumentshas.": {
            "type": "bool"
        },
        "PaymentRequest.show": {
            "type": "PaymentResponse",
            "creates": "PaymentResponse"
        },
        "PaymentRequest.canMakePayment": {
            "type": "bool"
        },
        "PaymentRequestEvent.openWindow": {
            "type": "WindowClient",
            "creates": "WindowClient"
        },
        "RTCPeerConnection.createOffer": {
            "type": "RtcSessionDescription",
            "creates": "RtcSessionDescription"
        },
        "RTCPeerConnection.createAnswer": {
            "type": "RtcSessionDescription",
            "creates": "RtcSessionDescription"
        },
        "RTCPeerConnection.getStats": {
            "type": "RtcStatsReport",
            "maplike": "RTCStatsReport",
            "creates": "RtcStatsReport"
        },
        "RTCPeerConnection.generateCertificate": {
            "type": "RtcCertificate",
            "creates": "RtcCertificate"
        },
        "Permissions.query": {
            "type": "PermissionStatus",
            "creates": "PermissionStatus"
        },
        "Permissions.request": {
            "type": "PermissionStatus",
            "creates": "PermissionStatus"
        },
        "Permissions.revoke": {
            "type": "PermissionStatus",
            "creates": "PermissionStatus"
        },
        "Permissions.requestAll": {
            "type": "PermissionStatus",
            "creates": "PermissionStatus"
        },
        "PresentationRequest.start": {
            "type": "PresentationConnection",
            "creates": "PresentationConnection"
        },
        "PresentationRequest.reconnect": {
            "type": "PresentationConnection",
            "creates": "PresentationConnection"
        },
        "PresentationRequest.getAvailability": {
            "type": "PresentationAvailability",
            "creates": "PresentationAvailability"
        },
        "PushManager.subscribe": {
            "type": "PushSubscription",
            "creates": "PushSubscription"
        },
        "PushManager.getSubscription": {
            "type": "PushSubscription",
            "creates": "PushSubscription"
        },
        "PushSubscription.unsubscribe": {
            "type": "bool"
        },
        "StorageManager.persisted": {
            "type": "bool"
        },
        "StorageManager.persist": {
            "type": "bool"
        },
        "StorageManager.estimate": {
            "type": "dictionary"
        },
        "RemotePlayback.watchAvailability": {
            "type": "int"
        },
        "Clients.matchAll": {
            "type": "List<dynamic>"
        },
        "Clients.openWindow": {
            "type": "WindowClient",
            "creates": "WindowClient"
        },
        "NavigationPreloadManager.getState": {
            "type": "dictionary"
        },
        "ServiceWorkerContainer.register": {
            "type": "ServiceWorkerRegistration",
            "creates": "ServiceWorkerRegistration"
        },
        "ServiceWorkerContainer.getRegistration": {
            "type": "ServiceWorkerRegistration",
            "creates": "ServiceWorkerRegistration"
        },
        "ServiceWorkerContainer.getRegistrations": {
            "type": "List<dynamic>"
        },
        "ServiceWorkerGlobalScope.fetch": {
            "creates": "_Response"
        },
        "ServiceWorkerRegistration.unregister": {
            "type": "bool"
        },
        "WindowClient.focus": {
            "type": "WindowClient",
            "creates": "WindowClient"
        },
        "WindowClient.navigate": {
            "type": "WindowClient",
            "creates": "WindowClient"
        },
        "BarcodeDetector.detect": {
            "type": "List<dynamic>"
        },
        "FaceDetector.detect": {
            "type": "List<dynamic>"
        },
        "TextDetector.detect": {
            "type": "List<dynamic>"
        },
        "BaseAudioContext.decodeAudioData": {
            "type": "AudioBuffer",
            "creates": "AudioBuffer"
        },
        "OfflineAudioContext.startRendering": {
            "type": "AudioBuffer",
            "creates": "AudioBuffer"
        },
        "CacheStorage.match": {
            "creates": "_Response"
        },
        "CacheStorage.open": {
            "creates": "_Cache"
        },
        "CredentialsContainer.create": {
            "creates": "Credential"
        },
        "CredentialsContainer.get": {
            "creates": "Credential"
        },
        "CredentialsContainer.store": {
            "creates": "Credential"
        },
        "FetchEvent.preloadResponse": {
            "creates": "_Response"
        },
        "MediaKeySystemAccess.createMediaKeys": {
            "creates": "MediaKeys"
        },
        "Navigator.getVRDisplays": {
            "creates": "VRDisplay"
        },
        "Navigator.requestMediaKeySystemAccess": {
            "creates": "MediaKeySystemAccess"
        },
        "VRSession.requestFrameOfReference": {
            "creates": "VRFrameOfReference"
        },
        "Window.fetch": {
            "creates": "_Response"
        },
        "WorkerGlobalScope.fetch": {
            "creates": "_Response"
        },
    })

promise_generateCall = monitored.Set('systemhtml.promise_generateCall', [
    "Navigator.requestKeyboardLock",
])


def _IsPromiseOperationGenerateCall(interface_operation):
    return interface_operation in promise_generateCall


def _GetPromiseOperationType(interface_operation):
    if interface_operation in promise_operations:
        return promise_operations[interface_operation]
    return None


def _GetPromiseAttributeType(interface_operation):
    if interface_operation in promise_attributes:
        return promise_attributes[interface_operation]
    return None

# Compatibility is used to help determine attribute nullability i.e. if the
# attribute is not compatible across all browsers, the getter/setter is marked
# as nullable. There are cases where the attribute belongs to a class that
# implements an interface whose methods are not in the IDL, however.
# Since attribute getters need to match their overridden method declaration,
# there are conflicts when the overriding method is not compatible, the
# overriding method is, and they're not already nullable. This dict marks the
# attributes where there is a conflict that cannot be resolved with code
# generation or within src/template files.
compat_conflicts = {
    # These interfaces implement Rectangle, which is a Dart interface. In order
    # to match the interface of Rectangle, they must be marked as non-nullable.
    'DOMRectReadOnly': ['bottom', 'height', 'left', 'right', 'top', 'width'],
    'DOMRect': ['height', 'width'],
}


class Dart2JSBackend(HtmlDartGenerator):
    """Generates a dart2js class for the dart:html library from a DOM IDL
  interface.
  """

    def __init__(self, interface, options, logging_level=logging.WARNING):
        super(Dart2JSBackend, self).__init__(interface, options, False, _logger)

        self._database = options.database
        self._template_loader = options.templates
        self._type_registry = options.type_registry
        self._renamer = options.renamer
        self._metadata = options.metadata
        self._interface_type_info = self._type_registry.TypeInfo(
            self._interface.id)
        self._current_secondary_parent = None
        self._library_name = self._renamer.GetLibraryName(self._interface)
        # Global constants for all WebGLRenderingContextBase, WebGL2RenderingContextBase, WebGLDrawBuffers
        self._gl_constants = []
        _logger.setLevel(logging_level)

    def ImplementsMergedMembers(self):
        return True

    def GenerateCallback(self, info):
        pass

    def AdditionalImplementedInterfaces(self):
        implements = super(Dart2JSBackend,
                           self).AdditionalImplementedInterfaces()
        if self._interface_type_info.list_item_type() and self.HasIndexedGetter(
        ):
            item_type = self._type_registry.TypeInfo(
                self._interface_type_info.list_item_type()).dart_type()
            if self._interface_type_info.list_item_type_nullable():
                item_type += '?'
            implements.append('JavaScriptIndexingBehavior<%s>' % item_type)
        return implements

    def NativeSpec(self):
        native_spec = MakeNativeSpec(self._interface.javascript_binding_name)
        return '@Native("%s")\n' % native_spec

    def ImplementationTemplate(self):
        template_file = ('impl_%s.darttemplate' % self._interface.doc_js_name)
        template_file_content = self._template_loader.TryLoad(template_file)
        if not (template_file_content):
            if self._interface.isMaplike and self._interface.isMaplike_ro:
                # TODO(terry): There are no mutable maplikes yet.
                template_file_content = self._template_loader.Load(
                    'dart2js_maplike_impl.darttemplate')
            else:
                template_file_content = self._template_loader.Load(
                    'dart2js_impl.darttemplate')
        return template_file_content

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
                    " && (new %sElement.tag('%s') is %s)" %
                    (lib_prefix, constructors[self._interface.doc_js_name],
                     self._renamer.RenameInterface(self._interface)))
        return js_support_checks.get(self._interface.doc_js_name)

    def GenerateCustomFactory(self, constructor_info):
        # Custom factory will be taken from the template.
        return self._interface.doc_js_name in _js_custom_constructors

    def MakeFactoryCall(self, factory, method, arguments, constructor_info):
        if factory is 'document' and method is 'createElement' \
            and not ',' in arguments \
            and not self._HasUnreliableFactoryConstructor():
            return emitter.Format(
                "JS$CAST("
                "'returns:$INTERFACE_NAME;creates:$INTERFACE_NAME;new:true',"
                " '#.$METHOD(#)', $FACTORY, $ARGUMENTS)",
                CAST='<' + self._interface_type_info.interface_name() + '>',
                INTERFACE_NAME=self._interface_type_info.interface_name(),
                FACTORY=factory,
                METHOD=method,
                ARGUMENTS=arguments)
        return emitter.Format('$FACTORY.$METHOD($ARGUMENTS)$CAST',
                              FACTORY=factory,
                              METHOD=method,
                              ARGUMENTS=arguments,
                              CAST=' as ' +
                              self._interface_type_info.interface_name())

    def _HasUnreliableFactoryConstructor(self):
        return self._interface.doc_js_name in _js_unreliable_element_factories

    def IsConstructorArgumentOptional(self, argument):
        return argument.optional

    def EmitStaticFactoryOverload(self, constructor_info, name, arguments):
        if self._interface_type_info.has_generated_interface():
            # Use dart_type name, we're generating.
            interface_name = self._interface_type_info.interface_name()
        else:
            # Use the implementation name the interface is suppressed.
            interface_name = self._interface_type_info.implementation_name()

        index = len(arguments)
        arguments = constructor_info.ParametersAsArgumentList(index)
        if arguments:
            arguments = ', ' + arguments
        self._members_emitter.Emit(
            "  static $INTERFACE_NAME $NAME($PARAMETERS) => "
            "JS('$INTERFACE_NAME', 'new $CTOR_NAME($PLACEHOLDERS)'$ARGUMENTS);\n",
            INTERFACE_NAME=interface_name,
            NAME=name,
            # TODO(antonm): add types to parameters.
            PARAMETERS=constructor_info.ParametersAsArgumentList(index),
            CTOR_NAME=constructor_info.name or self._interface.doc_js_name,
            PLACEHOLDERS=','.join(['#'] * index),
            ARGUMENTS=arguments)

    def SecondaryContext(self, interface):
        if interface is not self._current_secondary_parent:
            self._current_secondary_parent = interface
            self._members_emitter.Emit(
                '\n  // From $WHERE\n', WHERE=interface.id)

    def HasIndexedGetter(self):
        ext_attrs = self._interface.ext_attrs
        has_indexed_getter = 'CustomIndexedGetter' in ext_attrs
        for operation in self._interface.operations:
            if operation.id == 'item' and 'getter' in operation.specials \
                and not self._OperationRequiresConversions(operation):
                has_indexed_getter = True
                break
            if operation.id == '__getter__' and 'getter' in operation.specials \
                and not self._OperationRequiresConversions(operation):
                has_indexed_getter = True
                break
        return has_indexed_getter

    def AddIndexer(self, element_type, nullable):
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

        indexed_getter = False
        indexed_getter_nullable = nullable
        if has_indexed_getter:
            indexed_getter = ('JS("%s%s", "#[#]", this, index)' %
                              (self.SecureOutputType(element_type),
                               "|Null" if nullable else ""))
        else:
            for op in self._interface.operations:
                if op.id == 'getItem':
                    indexed_getter = 'this.getItem(index)'
                    indexed_getter_nullable = OperationTypeIsNullable(op)
                    break
            if not indexed_getter:
                for op in self._interface.operations:
                    if op.id == 'item':
                        indexed_getter = 'this.item(index)'
                        indexed_getter_nullable = OperationTypeIsNullable(op)
                        break

        if indexed_getter:
            self._members_emitter.Emit(
                '\n'
                '  $TYPE operator[](int index) {\n'
                '    if (JS("bool", "# >>> 0 !== # || # >= #", index,\n'
                '        index, index, length))\n'
                '      throw new RangeError.index(index, this);\n'
                '    return $INDEXED_GETTER$NULLASSERT;\n'
                '  }',
                INDEXED_GETTER=indexed_getter,
                TYPE=self.SecureOutputType(element_type,
                                           is_dart_type=False,
                                           can_narrow_type=True,
                                           nullable=nullable),
                # If the type of the operation is not nullable but the getter
                # is, we must assert non-null.
                NULLASSERT='!' if not nullable and indexed_getter_nullable \
                    else '')

        if 'CustomIndexedSetter' in self._interface.ext_attrs:
            self._members_emitter.Emit(
                '\n'
                '  void operator[]=(int index, $TYPE$NULLABLE value) {'
                ' JS("void", "#[#] = #", this, index, value); }',
                TYPE=self._NarrowInputType(element_type),
                NULLABLE='?' if nullable else '')
        else:
            theType = self._NarrowInputType(element_type)
            if theType == 'DomRectList':
                theType = ''

            self._members_emitter.Emit(
                '\n'
                '  void operator[]=(int index, $TYPE$NULLABLE value) {\n'
                '    throw new UnsupportedError("Cannot assign element of immutable List.");\n'
                '  }\n',
                TYPE=theType,
                NULLABLE='?' if nullable else '')

        self.EmitListMixin(self._DartType(element_type), nullable)

    def EmitAttribute(self, attribute, html_name, read_only):
        if self._HasCustomImplementation(attribute.id):
            return

        if IsPureInterface(self._interface.id, self._database):
            self._AddAttributeUsingProperties(attribute, html_name, read_only)
            return

        output_type = self.SecureOutputType(attribute.type.id,
                                            can_narrow_type=read_only,
                                            nullable=attribute.type.nullable)

        rename = self._RenamingAnnotation(attribute.id, html_name)
        metadata = self._Metadata(attribute.type.id, attribute.id, output_type,
            attribute.type.nullable)

        is_compat = self._mdn_reader.is_compatible(attribute)

        # If the attribute is shadowing, we can't generate a shadowing
        # getter or setter (Issue 1633).
        # TODO(sra): _FindShadowedAttribute does not take into account the html
        # renaming. We should be looking for another attribute that has the
        # same html_name. Two attributes with the same IDL name might not match
        # if one is renamed.
        # TODO(srujzs): Determine if logic behind shadowing is still true here
        # and below with the transition to natives.
        (super_attribute,
         super_attribute_interface) = self._FindShadowedAttribute(attribute)

        if super_attribute:
            if is_compat is None:
                # If there is no compatibility info on this attribute, we use
                # the parent attribute's compatibility info.
                is_compat = self._mdn_reader.is_compatible(super_attribute)
                self._mdn_reader.set_compatible(attribute, is_compat)
            if read_only or self._SafeToIgnoreShadowingMember(html_name):
                if attribute.type.id == super_attribute.type.id:
                    # Compatible attribute, use the superclass property.  This
                    # works because JavaScript will do its own dynamic dispatch.

                    # Nullability is determined by attribute compatibility.
                    nullable = not is_compat or attribute.type.nullable
                    self._members_emitter.Emit(
                        '\n'
                        '  // Use implementation from $SUPER.\n'
                        '  // $GET_TYPE get $NAME native;\n'
                        '  // void set $NAME($SET_TYPE value) native;\n',
                        SUPER=super_attribute_interface,
                        NAME=html_name,
                        GET_TYPE=self.SecureOutputType(attribute.type.id,
                            can_narrow_type=read_only,
                            nullable=nullable),
                        SET_TYPE=self.SecureOutputType(attribute.type.id,
                            can_narrow_type=read_only,
                            nullable=nullable or \
                                'TreatNullAs' in attribute.ext_attrs))
                    return
            self._members_emitter.Emit('\n  // Shadowing definition.')
            self._AddAttributeUsingProperties(attribute, html_name, read_only,
                rename, metadata)
            return

        # If the attribute is shadowed incompatibly in a subclass then we also
        # can't just generate it as a getter/setter. In particular, this happens
        # with DomMatrixReadOnly and its subclass DomMatrix. Force the
        # superclass to generate getters. Hardcoding the known problem classes
        # for now.
        # TODO(alanknight): Fix this more generally.
        if (self._interface.id == 'DOMMatrixReadOnly' or
                self._interface.id == 'DOMPointReadOnly' or
                self._interface.id == 'DOMRectReadOnly'):
            self._AddAttributeUsingProperties(attribute, html_name, read_only,
                rename, metadata)
            return

        # If the type has a conversion we need a getter or setter to contain the
        # conversion code.
        if (self._OutputConversion(attribute.type.id, attribute.id) or
                self._InputConversion(attribute.type.id, attribute.id)):
            self._AddAttributeUsingProperties(attribute, html_name, read_only,
                rename, metadata)
            return

        input_type = self._NarrowInputType(attribute.type.id)
        if attribute.type.nullable or not is_compat:
            input_type += '?'
        if not read_only:
            if attribute.type.id == 'Promise':
                _logger.warn('R/W member is a Promise: %s.%s' %
                             (self._interface.id, html_name))
            self._AddAttributeUsingProperties(attribute, html_name, read_only,
                                              rename, metadata)
        else:
            if attribute.type.id == 'Promise':
                lookupOp = "%s.%s" % (self._interface.id, html_name)
                promiseFound = _GetPromiseAttributeType(lookupOp)
                promiseType = 'Future'
                promiseCall = 'promiseToFuture'
                type_description = ''
                if promiseFound is not (None):
                    paramType = promiseFound.get('type')
                    if 'maplike' in promiseFound:
                        promiseCall = 'promiseToFuture<dynamic>'
                        promiseType = 'Future'
                    elif paramType == 'dictionary':
                        # It's a dictionary so return as a Map.
                        promiseCall = 'promiseToFutureAsMap'
                        output_conversion = self._OutputConversion("Dictionary",
                                                                   None)
                        nullability = '?' if output_conversion.nullable_output \
                            else ''
                        promiseType = 'Future<Map<String, dynamic>' + \
                            nullability + '>'
                    elif paramType:
                        promiseCall = 'promiseToFuture<%s>' % paramType
                        promiseType = 'Future<%s>' % paramType

                    if 'creates' in promiseFound:
                        createsType = promiseFound['creates']
                        type_description = 'creates:%s;' % createsType

                if attribute.type.nullable:
                    promiseType += '?'

                template = '\n  $RENAME$(ANNOTATIONS)$TYPE get $NAME => $PROMISE_CALL(JS("$TYPE_DESC", "#.$NAME", this));\n'

                self._members_emitter.Emit(
                    template,
                    RENAME=rename,
                    ANNOTATIONS=metadata,
                    TYPE=promiseType,
                    PROMISE_CALL=promiseCall,
                    TYPE_DESC=type_description,
                    NAME=html_name,)
            else:
                # Need to use a getter for list.length properties so we can
                # add a setter which throws an exception, satisfying List
                # API.
                if self._interface_type_info.list_item_type() and \
                    html_name == 'length':
                    template = (
                        '\n  $RENAME$(ANNOTATIONS)$TYPE get $NAME => ' +
                        'JS("$TYPE", "#.$NAME", this);\n')
                    self._members_emitter.Emit(
                        template,
                        RENAME=rename,
                        ANNOTATIONS=metadata,
                        NAME=html_name,
                        TYPE=input_type
                        if output_type == 'double' else output_type)
                else:
                    # Transform to native getters/setters.
                    # TODO(srujzs): Should the logic for types and doubles from
                    # above and before stay the same here?
                    self._AddAttributeUsingProperties(attribute, html_name,
                        read_only, rename, metadata)

    def _IsACompatibilityConflict(self, interface, attr):
        if interface in compat_conflicts and attr.id in compat_conflicts[
                interface]:
            is_compat = self._mdn_reader.is_compatible(attr)
            if is_compat or attr.type.nullable:
                # Only attributes that are not compatible and not nullable
                # belong in this list.
                raise ValueError(
                    interface + '.' + attr.id +
                    ' has no conflict between compatibility and nullability.')
            else:
                return True
        return False

    def _AddAttributeUsingProperties(self, attribute, html_name, read_only,
                                     rename=None, metadata=None):
        self._AddRenamingGetter(attribute, html_name, rename, metadata)
        if not read_only:
            # No metadata for setters.
            self._AddRenamingSetter(attribute, html_name, rename)

    def _AddRenamingGetter(self, attr, html_name, rename, metadata):
        conversion = self._OutputConversion(attr.type.id, attr.id)
        if conversion:
            return self._AddConvertingGetter(attr, html_name, conversion)
        # If the attribute is incompatible, it must be marked nullable.
        is_compat = self._mdn_reader.is_compatible(attr)
        return_type = self.SecureOutputType(attr.type.id,
                                            nullable=(not is_compat) or
                                            attr.type.nullable)
        native_type = self._NarrowToImplementationType(attr.type.id)
        non_null_return_type = self.SecureOutputType(attr.type.id,
                                                     nullable=False)
        if self._IsACompatibilityConflict(self._interface.id, attr):
            if not rename:
                rename = '@JSName(\'%s\')' % html_name
            template = """\n
                // The following getter is incompatible with some browsers but
                // must be made non-nullable to match the overridden method.
                \n  $RENAME
                \n  $METADATA
                \n  $STATIC $TYPE get _$HTML_NAME native;
                \n
                \n  $STATIC $NONNULLTYPE get $HTML_NAME => _$HTML_NAME$NULLASSERT;"""
        else:
            template = """\n  $RENAME
                \n  $METADATA
                \n  $STATIC $TYPE get $HTML_NAME native;
                \n"""
        self._members_emitter.Emit(template,
                                   RENAME=rename if rename else '',
                                   METADATA=metadata if metadata else '',
                                   HTML_NAME=html_name,
                                   STATIC='static' if attr.is_static else '',
                                   TYPE=return_type,
                                   NULLASSERT='!',
                                   NONNULLTYPE=non_null_return_type)

    def _AddRenamingSetter(self, attr, html_name, rename):
        conversion = self._InputConversion(attr.type.id, attr.id)
        if conversion:
            return self._AddConvertingSetter(attr, html_name, conversion)
        nullable_type = attr.type.nullable or 'TreatNullAs' in attr.ext_attrs
        # If this attr has an output conversion, it is possible that there is a
        # converting getter. We need to make sure the setter type matches the
        # getter type.
        conversion = self._OutputConversion(attr.type.id, attr.id)
        # If the attribute is incompatible, it must be marked nullable.
        is_compat = self._mdn_reader.is_compatible(attr)
        if (conversion and conversion.nullable_output) or not is_compat:
            nullable_type = True
        if self._IsACompatibilityConflict(self._interface.id, attr):
            # Force non-nullable if it's a manual conflict.
            nullable_type = False
        self._members_emitter.Emit(
            '\n  $RENAME'
            '\n  $STATIC set $HTML_NAME($TYPE value) native;'
            '\n',
            RENAME=rename if rename else '',
            HTML_NAME=html_name,
            STATIC='static ' if attr.is_static else '',
            TYPE=self.SecureOutputType(attr.type.id, nullable=nullable_type))

    def _AddConvertingGetter(self, attr, html_name, conversion):
        # dynamic should not be marked with ?
        nullable_out = conversion.nullable_output and \
            not conversion.output_type == 'dynamic'
        # Nullability is determined by attribute compatibility.
        is_compat = self._mdn_reader.is_compatible(attr)
        nullable_in = (not is_compat or attr.type.nullable) and \
            not conversion.input_type == 'dynamic'
        self._members_emitter.Emit(
            '\n  $(METADATA)$RETURN_TYPE$NULLABLE_OUT get $HTML_NAME => '
            '$CONVERT(this._get_$(HTML_NAME)$NULLASSERT);'
            "\n  @JSName('$NAME')"
            '\n  $(JS_METADATA)$NATIVE_TYPE$NULLABLE_IN get _get_$HTML_NAME native;'
            '\n',
            METADATA=self._metadata.GetFormattedMetadata(
                self._library_name, self._interface, html_name, '  '),
            JS_METADATA=self._Metadata(attr.type.id, html_name,
                                       conversion.input_type,
                                       conversion.nullable_output),
            CONVERT=conversion.function_name,
            HTML_NAME=html_name,
            NAME=attr.id,
            RETURN_TYPE=conversion.output_type,
            NULLABLE_OUT='?' if nullable_out else '',
            NATIVE_TYPE=conversion.input_type,
            NULLABLE_IN='?' if nullable_in else '',
            NULLASSERT='!' if nullable_in and \
                not conversion.nullable_input else '')

    def _AddConvertingSetter(self, attr, html_name, conversion):
        # If the attribute is incompatible, it must be marked nullable.
        is_compat = self._mdn_reader.is_compatible(attr)
        # If the attribute is nullable, the setter should be nullable.
        nullable_in = ((attr.type.nullable or 'TreatNullAs' in attr.ext_attrs) \
            and not conversion.input_type == 'dynamic') or not is_compat
        nullable_out = conversion.nullable_output and \
            not conversion.output_type == 'dynamic'
        self._members_emitter.Emit(
            # TODO(sra): Use metadata to provide native name.
            '\n  set $HTML_NAME($INPUT_TYPE$NULLABLE_IN value) {'
            '\n    this._set_$HTML_NAME = $CONVERT(value$NULLASSERT);'
            '\n  }'
            '\n  set _set_$HTML_NAME(/*$NATIVE_TYPE$NULLABLE_OUT*/ value) {'
            '\n    JS("void", "#.$NAME = #", this, value);'
            '\n  }'
            '\n',
            CONVERT=conversion.function_name,
            HTML_NAME=html_name,
            NAME=attr.id,
            INPUT_TYPE=conversion.input_type,
            NULLABLE_IN='?' if nullable_in else '',
            NATIVE_TYPE=conversion.output_type,
            NULLABLE_OUT='?' if nullable_out else '',
            NULLASSERT='!' if nullable_in and \
                not conversion.nullable_input else '')

    def AmendIndexer(self, element_type):
        pass

    def RootClassName(self):
        return 'Interceptor'

    def OmitOperationOverrides(self):
        return True

    def EmitOperation(self, info, html_name, dart_js_interop=False):
        """
    Arguments:
      info: An OperationInfo object.
    """
        if self._HasCustomImplementation(info.name):
            return

        if IsPureInterface(self._interface.id, self._database):
            self._AddInterfaceOperation(info, html_name)
        elif info.callback_args:
            self._AddFutureifiedOperation(info, html_name)
        else:
            if any(
                    self._OperationRequiresConversions(op)
                    for op in info.overloads):
                lookupOp = "%s.%s" % (self._interface.id, html_name)
                if (_GetPromiseOperationType(lookupOp) or info.type_name == 'Promise') and \
                  not _IsPromiseOperationGenerateCall(lookupOp):
                    self._AddDirectNativeOperation(info, html_name)
                else:
                    # Any conversions needed?
                    self._AddOperationWithConversions(info, html_name)
            else:
                self._AddDirectNativeOperation(info, html_name)

    def _computeResultType(self, checkType):
        # TODO(terry): Work around bug in dart2js compiler e.g.,
        #     typedef void CustomElementConstructor();
        #     CustomElementConstructor registerElement(String type, [Map options])
        # Needs to become:
        #     Function registerElement(String type, [Map options])
        resultType = checkType
        if self._database.HasInterface(resultType):
            resultInterface = self._database.GetInterface(resultType)
            if 'Callback' in resultInterface.ext_attrs:
                resultType = 'Function'
        return resultType

    def _zeroArgs(self, argsNames):
        return 'JS("$TYPE_DESC", "#.$JSNAME()", this)'

    def _manyArgs(self, numberArgs, argsNames):
        argsPound = "#" if numberArgs == 1 else ("#, " * numberArgs)[:-2]
        template = '    JS("$TYPE_DESC", "#.$JSNAME(%s)", this, %s)'
        return template % (argsPound, argsNames)

    """ If argument conversionsMapToDictionary is a list first entry is argument
      name and second entry signals if argument is optional (True). """

    def _promiseToFutureCode(self, argsNames, conversionsMapToDictionary=None):
        numberArgs = argsNames.count(',') + 1
        jsCall = self._zeroArgs(argsNames) if len(argsNames) == 0 else \
            self._manyArgs(numberArgs, argsNames)

        futureTemplate = []
        if conversionsMapToDictionary is None:
            futureTemplate = [
                '\n'
                '  $RENAME$METADATA$MODIFIERS $TYPE $NAME($PARAMS) => $PROMISE_CALL(',
                jsCall, ');\n'
            ]
        else:
            mapArg = conversionsMapToDictionary[0]
            tempVariable = '%s_dict' % mapArg
            mapArgOptional = conversionsMapToDictionary[1]

            if argsNames.endswith('%s' % mapArg):
                argsNames = '%s_dict' % argsNames
                jsCall = self._zeroArgs(argsNames) if len(argsNames) == 0 else \
                    self._manyArgs(numberArgs, argsNames)
            if mapArgOptional:
                futureTemplate = [
                    # We will need to convert the Map argument to a Dictionary, test if mapArg is there (optional) then convert.
                    '\n'
                    '  $RENAME$METADATA$MODIFIERS $TYPE $NAME($PARAMS) {\n',
                    '    var ',
                    tempVariable,
                    ' = null;\n',
                    '    if (',
                    mapArg,
                    ' != null) {\n',
                    '      ',
                    tempVariable,
                    ' = convertDartToNative_Dictionary(',
                    mapArg,
                    ');\n',
                    '    }\n',
                    '    return $PROMISE_CALL(',
                    jsCall,
                    ');\n',
                    '  }\n'
                ]
            else:
                futureTemplate = [
                    # We will need to convert the Map argument to a Dictionary, the Map argument is not optional.
                    '\n'
                    '  $RENAME$METADATA$MODIFIERS $TYPE $NAME($PARAMS) {\n',
                    '    var ',
                    tempVariable,
                    ' = convertDartToNative_Dictionary(',
                    mapArg,
                    ');\n',
                    '    return $PROMISE_CALL(',
                    jsCall,
                    ');\n',
                    '  }\n'
                ]

        return "".join(futureTemplate)

    def _AddDirectNativeOperation(self, info, html_name):
        force_optional = True if html_name.startswith('_') else False
        resultType = self._computeResultType(info.type_name)

        if info.type_name == 'Promise' and not (force_optional):
            lookupOp = "%s.%s" % (self._interface.id, html_name)
            promiseFound = _GetPromiseOperationType(lookupOp)
            promiseType = 'Future'
            promiseCall = 'promiseToFuture'
            type_description = ''
            if promiseFound is not (None):
                paramType = promiseFound.get('type')
                if 'maplike' in promiseFound:
                    if paramType == 'dictionary':
                        promiseCall = 'promiseToFuture<dynamic>'
                        promiseType = 'Future'
                    elif paramType:
                        promiseCall = 'promiseToFuture<%s>' % paramType
                        promiseType = 'Future<%s>' % paramType
                elif paramType == 'dictionary':
                    # It's a dictionary so return as a Map.
                    promiseCall = 'promiseToFutureAsMap'
                    output_conversion = self._OutputConversion("Dictionary",
                                                               None)
                    nullability = '?' if output_conversion.nullable_output \
                        else ''
                    promiseType = 'Future<Map<String, dynamic>' + \
                        nullability + '>'
                elif paramType:
                    promiseCall = 'promiseToFuture<%s>' % paramType
                    promiseType = 'Future<%s>' % paramType

                if 'creates' in promiseFound:
                    createsType = promiseFound['creates']
                    type_description = 'creates:%s;' % createsType

            argsNames = info.ParametersAsArgumentList()
            dictionary_argument = info.dictionaryArgumentName()
            codeTemplate = self._promiseToFutureCode(argsNames,
                                                     dictionary_argument)
            if info.type_nullable:
                promiseType += '?'
            self._members_emitter.Emit(
                codeTemplate,
                RENAME=self._RenamingAnnotation(info.declared_name, html_name),
                METADATA=self._Metadata(info.type_name, info.declared_name,
                                        self.SecureOutputType(info.type_name,
                                            nullable=info.type_nullable),
                                        info.type_nullable),
                MODIFIERS='static ' if info.IsStatic() else '',
                TYPE=promiseType,
                PROMISE_CALL=promiseCall,
                NAME=html_name,
                TYPE_DESC=type_description,
                JSNAME=info.declared_name,
                PARAMS=info.ParametersAsDeclaration(self._NarrowInputType,
                                                    force_optional))
        else:
            self._members_emitter.Emit(
                '\n'
                '  $RENAME$METADATA$MODIFIERS$TYPE $NAME($PARAMS) native;\n',
                RENAME=self._RenamingAnnotation(info.declared_name, html_name),
                METADATA=self._Metadata(info.type_name, info.declared_name,
                                        self.SecureOutputType(info.type_name,
                                            nullable=info.type_nullable),
                                        info.type_nullable),
                MODIFIERS='static ' if info.IsStatic() else '',
                TYPE=self.SecureOutputType(resultType,
                                           can_narrow_type=True,
                                           nullable=info.type_nullable),
                NAME=html_name,
                PARAMS=info.ParametersAsDeclaration(self._NarrowInputType,
                                                    force_optional))

    def _AddOperationWithConversions(self, info, html_name):
        # Assert all operations have same return type.
        assert len(set([op.type.id for op in info.operations])) == 1

        resultType = self._computeResultType(info.type_name)

        output_conversion = self._OutputConversion(resultType,
                                                   info.declared_name)
        if output_conversion:
            return_type = output_conversion.output_type
            native_return_type = output_conversion.input_type
        else:
            return_type = resultType if resultType == 'Function' else self._NarrowInputType(
                resultType)
            native_return_type = return_type

        parameter_names = [param_info.name for param_info in info.param_infos]
        parameter_types = [
            self._InputType(param_info.type_id, info)
            for param_info in info.param_infos
        ]
        operations = info.operations

        def InputType(type_name):
            return self._InputType(type_name, info)

        def GenerateCall(stmts_emitter, call_emitter, version, operation,
                         argument_count):
            target = '_%s_%d' % (html_name[1:] if html_name.startswith('_') else
                                 html_name, version)

            (target_parameters, arguments,
             calling_params) = self._ConvertArgumentTypes(
                 stmts_emitter, operation.arguments, argument_count, info)

            argument_list = ', '.join(arguments)
            # TODO(sra): If the native method has zero type checks, we can 'inline' is
            # and call it directly with a JS-expression.
            call = '%s(%s)' % (target, argument_list)

            if output_conversion:
                call = '%s(%s)' % (output_conversion.function_name, call)
                if output_conversion.nullable_output and not info.type_nullable:
                    # Return type of operation is not nullable while conversion
                    # is, so we need to assert non-null.
                    call += '!'

            call_emitter.Emit(call)

            if (native_return_type == 'Future'):
                hashArgs = ''
                if argument_count > 0:
                    if argument_count < 20:
                        hashArgs = '#,#,#,#,#,#,#,#,#,#,#,#,#,#,#,#,#,#,#,#,#' [:
                                                                                argument_count
                                                                                *
                                                                                2
                                                                                -
                                                                                1]
                    else:
                        print "ERROR: Arguments exceede 20 - please fix Python code to handle more."
                self._members_emitter.Emit(
                    '  $RENAME$METADATA$MODIFIERS$TYPE$TARGET($PARAMS) =>\n'
                    '      promiseToFuture(JS("", "#.$JSNAME($HASH_STR)", this$CALLING_PARAMS));\n',
                    RENAME=self._RenamingAnnotation(info.declared_name, target),
                    METADATA=self._Metadata(info.type_name, info.declared_name,
                                            None, info.type_nullable),
                    MODIFIERS='static ' if info.IsStatic() else '',
                    TYPE=TypeOrNothing(native_return_type,
                        nullable=info.type_nullable),
                    TARGET=target,
                    PARAMS=', '.join(target_parameters),
                    JSNAME=operation.id,
                    HASH_STR=hashArgs,
                    CALLING_PARAMS=calling_params)
            else:
                self._members_emitter.Emit(
                    '  $RENAME$METADATA$MODIFIERS$TYPE$TARGET($PARAMS) native;\n',
                    RENAME=self._RenamingAnnotation(info.declared_name, target),
                    METADATA=self._Metadata(info.type_name, info.declared_name,
                                            None, info.type_nullable),
                    MODIFIERS='static ' if info.IsStatic() else '',
                    TYPE=TypeOrNothing(native_return_type,
                        nullable=info.type_nullable),
                    TARGET=target,
                    PARAMS=', '.join(target_parameters))

        # private methods don't need named arguments.
        full_name = '%s.%s' % (self._interface.id, info.declared_name)
        force_optional = False if hasNamedFormals(full_name) and not (
            html_name.startswith('_')) else True

        nullsafe_return_type = return_type;
        if info.type_nullable:
            nullsafe_return_type += '?'

        declaration = '%s%s%s %s(%s)' % (
            self._Metadata(info.type_name, info.declared_name, return_type,
                info.type_nullable),
            'static ' if info.IsStatic() else '', nullsafe_return_type,
            html_name, info.ParametersAsDeclaration(InputType, force_optional))
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
            TYPE=self.SecureOutputType(info.type_name, can_narrow_type=True,
                nullable=info.type_nullable),
            NAME=html_name,
            PARAMS=info.ParametersAsDeclaration(self._NarrowInputType))

    def _OperationRequiresConversions(self, operation):
        return (self._OperationRequiresOutputConversion(operation) or
                self._OperationRequiresInputConversions(operation))

    def _OperationRequiresOutputConversion(self, operation):
        return self._OutputConversion(operation.type.id, operation.id)

    def _OperationRequiresInputConversions(self, operation):
        return any(
            self._InputConversion(arg.type.id, operation.id)
            for arg in operation.arguments)

    def _OutputConversion(self, idl_type, member):
        return FindConversion(idl_type, 'get', self._interface.id, member)

    def _InputConversion(self, idl_type, member):
        return FindConversion(idl_type, 'set', self._interface.id, member)

    def _HasCustomImplementation(self, member_name):
        member_name = '%s.%s' % (self._interface.doc_js_name, member_name)
        return member_name in _js_custom_members

    def _SafeToIgnoreShadowingMember(self, member_name):
        member_name = '%s.%s' % (self._interface.doc_js_name, member_name)
        return member_name in _safe_to_ignore_shadowing_members

    def _RenamingAnnotation(self, idl_name, member_name):
        if member_name != idl_name:
            return "@JSName('%s')\n  " % idl_name
        return ''

    def _Metadata(self, idl_type, idl_member_name, dart_type, nullable,
            indent='  '):
        anns = self._metadata.GetDart2JSMetadata(
            idl_type, self._library_name, self._interface, idl_member_name)

        if not self._metadata.AnyConversionAnnotations(
                idl_type, self._interface.id, idl_member_name):
            return_type = self.SecureOutputType(idl_type)
            native_type = self._NarrowToImplementationType(idl_type)

            null_union = '' if not nullable else '|Null'
            if native_type != return_type:
                anns = anns + [
                    "@Returns('%s%s')" % (native_type, null_union),
                    "@Creates('%s')" % native_type,
                ]
        if dart_type == 'dynamic' or dart_type == 'Object?':
            # We emit non-nullable Object annotations but exclude nullable
            # Object annotations since that's the default.

            def js_type_annotation(ann):
                return re.search('^@.*Returns', ann) or re.search(
                    '^@.*Creates', ann)

            if not filter(js_type_annotation, anns):
                _logger.warn('Member with wildcard native type: %s.%s' %
                             (self._interface.id, idl_member_name))

        return self._metadata.FormatMetadata(anns, indent)

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
                if IsPureInterface(parent.type.id, self._database):
                    return (None, None)
                if self._database.HasInterface(parent.type.id):
                    interfaces_to_search_in = []
                    parent_interface_name = parent.type.id
                    interfaces_to_search_in.append(parent_interface_name)
                    parent_type_info = self._type_registry.TypeInfo(
                        parent_interface_name)
                    if parent_type_info.merged_into():
                        # IDL parent was merged into another interface, which became a
                        # parent interface in Dart.
                        parent_interface_name = parent_type_info.merged_into()
                        interfaces_to_search_in.append(parent_interface_name)
                    elif parent_type_info.merged_interface():
                        # IDL parent has another interface that was merged into it.
                        interfaces_to_search_in.append(
                            parent_type_info.merged_interface())

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

    def EmitLibraries(self, auxiliary_dir, dart_js_interop):
        self._dart_libraries.Emit(self._multiemitter, auxiliary_dir)


# ------------------------------------------------------------------------------
class DartLibrary():

    def __init__(self, name, template_loader, library_type, output_dir,
                 dart_js_interop):
        self._template = template_loader.Load(
            '%s_%s.darttemplate' % (name, library_type))
        self._dart_path = os.path.join(output_dir,
                                       '%s_%s.dart' % (name, library_type))
        self._paths = []
        self._typeMap = {}
        self._dart_js_interop = dart_js_interop

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
            self._template,
            AUXILIARY_DIR=massage_path(auxiliary_dir),
            NULLABLE='?')
        if isinstance(emitters, tuple):
            imports_emitter, map_emitter = emitters
        else:
            imports_emitter, map_emitter = emitters, None

        for path in sorted(self._paths):
            relpath = os.path.relpath(path, library_file_dir)
            imports_emitter.Emit("part '$PATH';\n", PATH=massage_path(relpath))

        # Emit the $!TYPE_MAP
        if map_emitter:
            items = self._typeMap.items()
            items.sort()
            for (idl_name, dart_name) in items:
                map_emitter.Emit(
                    "  '$IDL_NAME': () => $DART_NAME.instanceRuntimeType,\n",
                    IDL_NAME=idl_name,
                    DART_NAME=dart_name)


# ------------------------------------------------------------------------------


class DartLibraries():

    def __init__(self, libraries, template_loader, library_type, output_dir,
                 dart_js_interop):
        self._libraries = {}
        for library_name in libraries:
            self._libraries[library_name] = DartLibrary(
                library_name, template_loader, library_type, output_dir,
                dart_js_interop)

    def AddFile(self, basename, library_name, path):
        self._libraries[library_name].AddFile(path)

    def AddTypeEntry(self, library_name, idl_name, dart_name):
        self._libraries[library_name].AddTypeEntry(idl_name, dart_name)

    def Emit(self, emitter, auxiliary_dir):
        for lib in self._libraries.values():
            lib.Emit(emitter, auxiliary_dir)
