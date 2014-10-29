#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module provides shared functionality for the systems to generate
native binding from the IDL database."""

import emitter
import os
from generator import *
from htmldartgenerator import *
from idlnode import IDLArgument, IDLAttribute, IDLEnum, IDLMember
from systemhtml import js_support_checks, GetCallbackInfo, HTML_LIBRARY_NAMES

# TODO(vsm): This logic needs to pulled from the source IDL.  These tables are
# an ugly workaround.
_cpp_callback_map = {
  ('DataTransferItem', 'webkitGetAsEntry'): 'DataTransferItemFileSystem',
  ('Document', 'fonts'): 'DocumentFontFaceSet',
  ('Document', 'webkitIsFullScreen'): 'DocumentFullscreen',
  ('Document', 'webkitFullScreenKeyboardInputAllowed'): 'DocumentFullscreen',
  ('Document', 'webkitCurrentFullScreenElement'): 'DocumentFullscreen',
  ('Document', 'webkitCancelFullScreen'): 'DocumentFullscreen',
  ('Document', 'webkitFullscreenEnabled'): 'DocumentFullscreen',
  ('Document', 'webkitFullscreenElement'): 'DocumentFullscreen',
  ('Document', 'webkitExitFullscreen'): 'DocumentFullscreen',
  ('DOMWindow', 'crypto'): 'DOMWindowCrypto',
  ('DOMWindow', 'indexedDB'): 'DOMWindowIndexedDatabase',
  ('DOMWindow', 'speechSynthesis'): 'DOMWindowSpeechSynthesis',
  ('DOMWindow', 'webkitNotifications'): 'DOMWindowNotifications',
  ('DOMWindow', 'storage'): 'DOMWindowQuota',
  ('DOMWindow', 'webkitStorageInfo'): 'DOMWindowQuota',
  ('DOMWindow', 'openDatabase'): 'DOMWindowWebDatabase',
  ('DOMWindow', 'webkitRequestFileSystem'): 'DOMWindowFileSystem',
  ('DOMWindow', 'webkitResolveLocalFileSystemURL'): 'DOMWindowFileSystem',
  ('DOMWindow', 'atob'): 'DOMWindowBase64',
  ('DOMWindow', 'btoa'): 'DOMWindowBase64',
  ('DOMWindow', 'clearTimeout'): 'DOMWindowTimers',
  ('DOMWindow', 'clearInterval'): 'DOMWindowTimers',
  ('DOMWindow', 'createImageBitmap'): 'ImageBitmapFactories',
  ('Element', 'animate'): 'ElementAnimation',
  ('HTMLInputElement', 'webkitEntries'): 'HTMLInputElementFileSystem',
  ('HTMLVideoElement', 'getVideoPlaybackQuality'): 'HTMLVideoElementMediaSource',
  ('Navigator', 'doNotTrack'): 'NavigatorDoNotTrack',
  ('Navigator', 'geolocation'): 'NavigatorGeolocation',
  ('Navigator', 'webkitPersistentStorage'): 'NavigatorStorageQuota',
  ('Navigator', 'webkitTemporaryStorage'): 'NavigatorStorageQuota',
  ('Navigator', 'registerProtocolHandler'): 'NavigatorContentUtils',
  ('Navigator', 'unregisterProtocolHandler'): 'NavigatorContentUtils',
  ('Navigator', 'webkitGetUserMedia'): 'NavigatorMediaStream',
  ('Navigator', 'webkitGetGamepads'): 'NavigatorGamepad',
  ('Navigator', 'requestMIDIAccess'): 'NavigatorWebMIDI',
  ('Navigator', 'vibrate'): 'NavigatorVibration',
  ('Navigator', 'appName'): 'NavigatorID',
  ('Navigator', 'appVersion'): 'NavigatorID',
  ('Navigator', 'appCodeName'): 'NavigatorID',
  ('Navigator', 'platform'): 'NavigatorID',
  ('Navigator', 'product'): 'NavigatorID',
  ('Navigator', 'userAgent'): 'NavigatorID',
  ('Navigator', 'onLine'): 'NavigatorOnLine',
  ('Navigator', 'registerServiceWorker'): 'NavigatorServiceWorker',
  ('Navigator', 'unregisterServiceWorker'): 'NavigatorServiceWorker',
  ('Navigator', 'maxTouchPoints'): 'NavigatorEvents',
  ('WorkerGlobalScope', 'crypto'): 'WorkerGlobalScopeCrypto',
  ('WorkerGlobalScope', 'indexedDB'): 'WorkerGlobalScopeIndexedDatabase',
  ('WorkerGlobalScope', 'webkitNotifications'): 'WorkerGlobalScopeNotifications',
  ('WorkerGlobalScope', 'openDatabase'): 'WorkerGlobalScopeWebDatabase',
  ('WorkerGlobalScope', 'openDatabaseSync'): 'WorkerGlobalScopeWebDatabase',
  ('WorkerGlobalScope', 'performance'): 'WorkerGlobalScopePerformance',
  ('WorkerGlobalScope', 'webkitRequestFileSystem'): 'WorkerGlobalScopeFileSystem',
  ('WorkerGlobalScope', 'webkitRequestFileSystemSync'): 'WorkerGlobalScopeFileSystem',
  ('WorkerGlobalScope', 'webkitResolveLocalFileSystemURL'): 'WorkerGlobalScopeFileSystem',
  ('WorkerGlobalScope', 'webkitResolveLocalFileSystemSyncURL'): 'WorkerGlobalScopeFileSystem',
  ('WorkerGlobalScope', 'atob'): 'DOMWindowBase64',
  ('WorkerGlobalScope', 'btoa'): 'DOMWindowBase64',
  ('WorkerGlobalScope', 'clearTimeout'): 'DOMWindowTimers',
  ('WorkerGlobalScope', 'clearInterval'): 'DOMWindowTimers',
  ('Document', 'rootElement'): 'SVGDocument',
  ('Document', 'childElementCount'): 'ParentNode',
  ('Document', 'firstElementChild'): 'ParentNode',
  ('Document', 'lastElementChild'): 'ParentNode',
  ('DocumentFragment', 'childElementCount'): 'ParentNode',
  ('DocumentFragment', 'firstElementChild'): 'ParentNode',
  ('DocumentFragment', 'lastElementChild'): 'ParentNode',
  ('CharacterData', 'nextElementSibling'): 'ChildNode',
  ('CharacterData', 'previousElementSibling'): 'ChildNode',
  ('Element', 'childElementCount'): 'ParentNode',
  ('Element', 'firstElementChild'): 'ParentNode',
  ('Element', 'lastElementChild'): 'ParentNode',
  ('Element', 'nextElementSibling'): 'ChildNode',
  ('Element', 'previousElementSibling'): 'ChildNode',
  ('SVGAnimationElement', 'requiredExtensions'): 'SVGTests',
  ('SVGAnimationElement', 'requiredFeatures'): 'SVGTests',
  ('SVGAnimationElement', 'systemLanguage'): 'SVGTests',
  ('SVGAnimationElement', 'hasExtension'): 'SVGTests',
  ('SVGGraphicsElement', 'requiredExtensions'): 'SVGTests',
  ('SVGGraphicsElement', 'requiredFeatures'): 'SVGTests',
  ('SVGGraphicsElement', 'systemLanguage'): 'SVGTests',
  ('SVGGraphicsElement', 'hasExtension'): 'SVGTests',
  ('SVGPatternElement', 'requiredExtensions'): 'SVGTests',
  ('SVGPatternElement', 'requiredFeatures'): 'SVGTests',
  ('SVGPatternElement', 'systemLanguage'): 'SVGTests',
  ('SVGPatternElement', 'hasExtension'): 'SVGTests',
  ('SVGUseElement', 'requiredExtensions'): 'SVGTests',
  ('SVGUseElement', 'requiredFeatures'): 'SVGTests',
  ('SVGUseElement', 'systemLanguage'): 'SVGTests',
  ('SVGUseElement', 'hasExtension'): 'SVGTests',
  ('SVGMaskElement', 'requiredExtensions'): 'SVGTests',
  ('SVGMaskElement', 'requiredFeatures'): 'SVGTests',
  ('SVGMaskElement', 'systemLanguage'): 'SVGTests',
  ('SVGMaskElement', 'hasExtension'): 'SVGTests',
  ('SVGViewSpec', 'zoomAndPan'): 'SVGZoomAndPan',
  ('SVGViewSpec', 'setZoomAndPan'): 'SVGZoomAndPan',
  ('SVGViewElement', 'setZoomAndPan'): 'SVGZoomAndPan',
  ('SVGSVGElement', 'setZoomAndPan'): 'SVGZoomAndPan',
  ('Screen', 'orientation'): 'ScreenOrientation',
  ('Screen', 'lockOrientation'): 'ScreenOrientation',
  ('Screen', 'unlockOrientation'): 'ScreenOrientation',
  ('Navigator', 'serviceWorker'): 'NavigatorServiceWorker',
  ('Navigator', 'storageQuota'): 'NavigatorStorageQuota',
  ('Navigator', 'isProtocolHandlerRegistered'): 'NavigatorContentUtils',
  ('SharedWorker', 'workerStart'): 'SharedWorkerPerformance',
}

_cpp_import_map = {
  'ImageBitmapFactories' : 'modules/imagebitmap/ImageBitmapFactories',
  'ScreenOrientation' : 'modules/screen_orientation/ScreenOrientation'
}

_cpp_overloaded_callback_map = {
  ('DOMURL', 'createObjectUrlFromSourceCallback'): 'URLMediaSource',
  ('DOMURL', 'createObjectUrlFromStreamCallback'): 'URLMediaStream',
  ('DOMURL', '_createObjectUrlFromWebKitSourceCallback'): 'URLMediaSource',
  ('DOMURL', '_createObjectURL_2Callback'): 'URLMediaSource',
  ('DOMURL', '_createObjectURL_3Callback'): 'URLMediaStream',
}

_cpp_partial_map = {}

_cpp_no_auto_scope_list = set([
  ('Document', 'body', 'Getter'),
  ('Document', 'getElementById', 'Callback'),
  ('Document', 'getElementsByName', 'Callback'),
  ('Document', 'getElementsByTagName', 'Callback'),
  ('Element', 'getAttribute', 'Callback'),
  ('Element', 'getAttributeNS', 'Callback'),
  ('Element', 'id', 'Getter'),
  ('Element', 'id', 'Setter'),
  ('Element', 'setAttribute', 'Callback'),
  ('Element', 'setAttributeNS', 'Callback'),
  ('Node', 'firstChild', 'Getter'),
  ('Node', 'lastChild', 'Getter'),
  ('Node', 'nextSibling', 'Getter'),
  ('Node', 'previousSibling', 'Getter'),
  ('Node', 'childNodes', 'Getter'),
  ('Node', 'nodeType', 'Getter'),
  ('NodeList', 'length', 'Getter'),
  ('NodeList', 'item', 'Callback'),
  ('WebGLRenderingContext', 'drawingBufferHeight', 'Getter'),
  ('WebGLRenderingContext', 'drawingBufferWidth', 'Getter'),
  ('WebGLRenderingContext', 'activeTexture', 'Callback'),
  ('WebGLRenderingContext', 'attachShader', 'Callback'),
  ('WebGLRenderingContext', 'bindAttribLocation', 'Callback'),
  ('WebGLRenderingContext', 'bindBuffer', 'Callback'),
  ('WebGLRenderingContext', 'bindFramebuffer', 'Callback'),
  ('WebGLRenderingContext', 'bindRenderbuffer', 'Callback'),
  ('WebGLRenderingContext', 'bindTexture', 'Callback'),
  ('WebGLRenderingContext', 'blendColor', 'Callback'),
  ('WebGLRenderingContext', 'blendEquation', 'Callback'),
  ('WebGLRenderingContext', 'blendEquationSeparate', 'Callback'),
  ('WebGLRenderingContext', 'blendFunc', 'Callback'),
  ('WebGLRenderingContext', 'blendFuncSeparate', 'Callback'),
  ('WebGLRenderingContext', 'checkFramebufferStatus', 'Callback'),
  ('WebGLRenderingContext', 'clear', 'Callback'),
  ('WebGLRenderingContext', 'clearColor', 'Callback'),
  ('WebGLRenderingContext', 'clearDepth', 'Callback'),
  ('WebGLRenderingContext', 'clearStencil', 'Callback'),
  ('WebGLRenderingContext', 'colorMask', 'Callback'),
  ('WebGLRenderingContext', 'compileShader', 'Callback'),
  ('WebGLRenderingContext', 'compressedTexImage2D', 'Callback'),
  ('WebGLRenderingContext', 'compressedTexSubImage2D', 'Callback'),
  ('WebGLRenderingContext', 'copyTexImage2D', 'Callback'),
  ('WebGLRenderingContext', 'copyTexSubImage2D', 'Callback'),
  ('WebGLRenderingContext', 'cullFace', 'Callback'),
  ('WebGLRenderingContext', 'deleteBuffer', 'Callback'),
  ('WebGLRenderingContext', 'deleteFramebuffer', 'Callback'),
  ('WebGLRenderingContext', 'deleteProgram', 'Callback'),
  ('WebGLRenderingContext', 'deleteRenderbuffer', 'Callback'),
  ('WebGLRenderingContext', 'deleteShader', 'Callback'),
  ('WebGLRenderingContext', 'deleteTexture', 'Callback'),
  ('WebGLRenderingContext', 'depthFunc', 'Callback'),
  ('WebGLRenderingContext', 'depthMask', 'Callback'),
  ('WebGLRenderingContext', 'depthRange', 'Callback'),
  ('WebGLRenderingContext', 'detachShader', 'Callback'),
  ('WebGLRenderingContext', 'disable', 'Callback'),
  ('WebGLRenderingContext', 'disableVertexAttribArray', 'Callback'),
  ('WebGLRenderingContext', 'drawArrays', 'Callback'),
  ('WebGLRenderingContext', 'drawElements', 'Callback'),
  ('WebGLRenderingContext', 'enable', 'Callback'),
  ('WebGLRenderingContext', 'enableVertexAttribArray', 'Callback'),
  ('WebGLRenderingContext', 'finish', 'Callback'),
  ('WebGLRenderingContext', 'flush', 'Callback'),
  ('WebGLRenderingContext', 'framebufferRenderbuffer', 'Callback'),
  ('WebGLRenderingContext', 'framebufferTexture2D', 'Callback'),
  ('WebGLRenderingContext', 'frontFace', 'Callback'),
  ('WebGLRenderingContext', 'generateMipmap', 'Callback'),
  ('WebGLRenderingContext', 'getActiveAttrib', 'Callback'),
  ('WebGLRenderingContext', 'getActiveUniform', 'Callback'),
  ('WebGLRenderingContext', 'getAttachedShaders', 'Callback'),
  ('WebGLRenderingContext', 'getAttribLocation', 'Callback'),
  ('WebGLRenderingContext', 'hint', 'Callback'),
  ('WebGLRenderingContext', 'isBuffer', 'Callback'),
  ('WebGLRenderingContext', 'isContextLost', 'Callback'),
  ('WebGLRenderingContext', 'isEnabled', 'Callback'),
  ('WebGLRenderingContext', 'isFramebuffer', 'Callback'),
  ('WebGLRenderingContext', 'isProgram', 'Callback'),
  ('WebGLRenderingContext', 'isRenderbuffer', 'Callback'),
  ('WebGLRenderingContext', 'isShader', 'Callback'),
  ('WebGLRenderingContext', 'isTexture', 'Callback'),
  ('WebGLRenderingContext', 'lineWidth', 'Callback'),
  ('WebGLRenderingContext', 'linkProgram', 'Callback'),
  ('WebGLRenderingContext', 'pixelStorei', 'Callback'),
  ('WebGLRenderingContext', 'polygonOffset', 'Callback'),
  ('WebGLRenderingContext', 'scissor', 'Callback'),
  ('WebGLRenderingContext', 'stencilFunc', 'Callback'),
  ('WebGLRenderingContext', 'stencilFuncSeparate', 'Callback'),
  ('WebGLRenderingContext', 'stencilMask', 'Callback'),
  ('WebGLRenderingContext', 'stencilMaskSeparate', 'Callback'),
  ('WebGLRenderingContext', 'stencilOp', 'Callback'),
  ('WebGLRenderingContext', 'stencilOpSeparate', 'Callback'),
  ('WebGLRenderingContext', 'uniform1f', 'Callback'),
  ('WebGLRenderingContext', 'uniform1fv', 'Callback'),
  ('WebGLRenderingContext', 'uniform1i', 'Callback'),
  ('WebGLRenderingContext', 'uniform1iv', 'Callback'),
  ('WebGLRenderingContext', 'uniform2f', 'Callback'),
  ('WebGLRenderingContext', 'uniform2fv', 'Callback'),
  ('WebGLRenderingContext', 'uniform2i', 'Callback'),
  ('WebGLRenderingContext', 'uniform2iv', 'Callback'),
  ('WebGLRenderingContext', 'uniform3f', 'Callback'),
  ('WebGLRenderingContext', 'uniform3fv', 'Callback'),
  ('WebGLRenderingContext', 'uniform3i', 'Callback'),
  ('WebGLRenderingContext', 'uniform3iv', 'Callback'),
  ('WebGLRenderingContext', 'uniform4f', 'Callback'),
  ('WebGLRenderingContext', 'uniform4fv', 'Callback'),
  ('WebGLRenderingContext', 'uniform4i', 'Callback'),
  ('WebGLRenderingContext', 'uniform4iv', 'Callback'),
  ('WebGLRenderingContext', 'uniformMatrix2fv', 'Callback'),
  ('WebGLRenderingContext', 'uniformMatrix3fv', 'Callback'),
  ('WebGLRenderingContext', 'uniformMatrix4fv', 'Callback'),
  ('WebGLRenderingContext', 'useProgram', 'Callback'),
  ('WebGLRenderingContext', 'validateProgram', 'Callback'),
  ('WebGLRenderingContext', 'vertexAttrib1f', 'Callback'),
  ('WebGLRenderingContext', 'vertexAttrib1fv', 'Callback'),
  ('WebGLRenderingContext', 'vertexAttrib2f', 'Callback'),
  ('WebGLRenderingContext', 'vertexAttrib2fv', 'Callback'),
  ('WebGLRenderingContext', 'vertexAttrib3f', 'Callback'),
  ('WebGLRenderingContext', 'vertexAttrib3fv', 'Callback'),
  ('WebGLRenderingContext', 'vertexAttrib4f', 'Callback'),
  ('WebGLRenderingContext', 'vertexAttrib4fv', 'Callback'),
  ('WebGLRenderingContext', 'vertexAttribPointer', 'Callback'),
  ('WebGLRenderingContext', 'viewport', 'Callback'),
])

# TODO(vsm): This should be recoverable from IDL, but we appear to not
# track the necessary info.
_url_utils = ['hash', 'host', 'hostname', 'origin',
              'password', 'pathname', 'port', 'protocol',
              'search', 'username']
_cpp_static_call_map = {
  'DOMURL': _url_utils + ['href', 'toString'],
  'HTMLAnchorElement': _url_utils,
  'HTMLAreaElement': _url_utils,
}

def _GetCPPPartialNames(interface):
  interface_name = interface.ext_attrs.get('ImplementedAs', interface.id)
  if not _cpp_partial_map:
    for (type, member) in _cpp_callback_map.keys():
      if type not in _cpp_partial_map:
        _cpp_partial_map[type] = set([])

      name_with_path = _cpp_callback_map[(type, member)]
      if name_with_path in _cpp_import_map:
        name_with_path = _cpp_import_map[name_with_path]
      _cpp_partial_map[type].add(name_with_path)

    for (type, member) in _cpp_overloaded_callback_map.keys():
      if type not in _cpp_partial_map:
        _cpp_partial_map[type] = set([])
      _cpp_partial_map[type].add(_cpp_overloaded_callback_map[(type, member)])

  if interface_name in _cpp_partial_map:
    return _cpp_partial_map[interface_name]
  else:
    return set([])

def array_type(data_type):
    matched = re.match(r'([\w\d_\s]+)\[\]', data_type)
    if not matched:
        return None
    return matched.group(1)

_sequence_matcher = re.compile('sequence\<(.+)\>')

def TypeIdToBlinkName(interface_id, database):
  # Maybe should use the type_registry here?
  if database.HasEnum(interface_id):
    return "DOMString" # All enums are strings.

  seq_match = _sequence_matcher.match(interface_id)
  if seq_match is not None:
    t = TypeIdToBlinkName(seq_match.group(1), database)
    return "sequence<%s>" % t

  arr_match = array_type(interface_id)
  if arr_match is not None:
    t = TypeIdToBlinkName(arr_match, database)
    return "%s[]" % t

  return interface_id

def _GetCPPTypeName(interface_name, callback_name, cpp_name):
  # TODO(vsm): We need to track the original IDL file name in order to recover
  # the proper CPP name.

  cpp_tuple = (interface_name, callback_name)
  if cpp_tuple in _cpp_callback_map:
    cpp_type_name = _cpp_callback_map[cpp_tuple]
  elif (interface_name, cpp_name) in _cpp_overloaded_callback_map:
    cpp_type_name = _cpp_overloaded_callback_map[(interface_name, cpp_name)]
  else:
    cpp_type_name = interface_name
  return cpp_type_name

def DeriveQualifiedName(library_name, name):
    return library_name + "." + name

def DeriveBlinkClassName(name):
    return "Blink" + name

_type_encoding_map = {
  'long long': "ll",
  'unsigned long': "ul",
  'unsigned long long': "ull",
  'unsigned short': "us",
}

def EncodeType(t):

  seq_match = _sequence_matcher.match(t)
  if seq_match is not None:
    t2 = EncodeType(seq_match.group(1))
    t = "SEQ_%s_SEQ" % t2
    return t

  arr_match = array_type(t)
  if arr_match is not None:
    t = EncodeType(arr_match)
    return "A_%s_A" % t

  return _type_encoding_map.get(t) or t

class DartiumBackend(HtmlDartGenerator):
  """Generates Dart implementation for one DOM IDL interface."""

  def __init__(self, interface, 
               cpp_library_emitter, options):
    super(DartiumBackend, self).__init__(interface, options, True)

    self._interface = interface
    self._cpp_library_emitter = cpp_library_emitter
    self._database = options.database
    self._template_loader = options.templates
    self._type_registry = options.type_registry
    self._interface_type_info = self._type_registry.TypeInfo(self._interface.id)
    self._metadata = options.metadata
    # These get initialized by StartInterface
    self._cpp_header_emitter = None
    self._cpp_impl_emitter = None
    self._members_emitter = None
    self._cpp_declarations_emitter = None
    self._cpp_impl_includes = None
    self._cpp_definitions_emitter = None
    self._cpp_resolver_emitter = None

  def ImplementsMergedMembers(self):
    # We could not add merged functions to implementation class because
    # underlying c++ object doesn't implement them. Merged functions are
    # generated on merged interface implementation instead.
    return False

  def CustomJSMembers(self):
    return {}

  def GenerateCallback(self, info):
    if IsPureInterface(self._interface.id) or IsCustomType(self._interface.id):
      return

    interface = self._interface
    if interface.parents:
      supertype = '%sClassId' % interface.parents[0].type.id
    else:
      supertype = '-1'

    cpp_impl_includes = set(['"' + partial + '.h"'
                             for partial in _GetCPPPartialNames(self._interface)])
    cpp_header_handlers_emitter = emitter.Emitter()
    cpp_impl_handlers_emitter = emitter.Emitter()
    class_name = 'Dart%s' % self._interface.id
    for operation in self._interface.operations:
      function_name = operation.id
      return_type = self.SecureOutputType(operation.type.id)
      parameters = []
      arguments = []
      if operation.ext_attrs.get('CallWith') == 'ThisValue':
        parameters.append('ScriptValue scriptValue')
      conversion_includes = []
      for argument in operation.arguments:
        argument_type_info = self._TypeInfo(argument.type.id)
        parameters.append('%s %s' % (argument_type_info.parameter_type(),
                                     argument.id))
        arguments.append(argument_type_info.to_dart_conversion(argument.id))
        conversion_includes.extend(argument_type_info.conversion_includes())

      # FIXME(vsm): Handle ThisValue attribute.
      if (return_type == 'void'):
        ret = ''
      else:
        ret = '        return 0;\n'

      if operation.ext_attrs.get('CallWith') == 'ThisValue':
        cpp_header_handlers_emitter.Emit(
            '\n'
            '    virtual $RETURN_TYPE $FUNCTION($PARAMETERS) {\n'
            '        DART_UNIMPLEMENTED();\n'
            '$RET'
            '    }\n',
            RETURN_TYPE=return_type,
            RET=ret,
            FUNCTION=function_name,
            PARAMETERS=', '.join(parameters))
        continue

      cpp_header_handlers_emitter.Emit(
          '\n'
          '    virtual $RETURN_TYPE $FUNCTION($PARAMETERS);\n',
          RETURN_TYPE=return_type,
          FUNCTION=function_name,
          PARAMETERS=', '.join(parameters))

      if _IsCustom(operation):
        continue

      cpp_impl_includes |= set(conversion_includes)
      arguments_declaration = 'Dart_Handle arguments[] = { %s }' % ', '.join(arguments)
      if not len(arguments):
        arguments_declaration = 'Dart_Handle* arguments = 0'
      if (return_type == 'void'):
        ret1 = 'return'
        ret2 = ''
      else:
        ret1 = 'return 0'
        ret2 = ' return'
      cpp_impl_handlers_emitter.Emit(
          '\n'
          '$RETURN_TYPE $CLASS_NAME::$FUNCTION($PARAMETERS)\n'
          '{\n'
          '    if (!m_callback.isIsolateAlive())\n'
          '        $RET1;\n'
          '    DartIsolateScope scope(m_callback.isolate());\n'
          '    DartApiScope apiScope;\n'
          '    $ARGUMENTS_DECLARATION;\n'
          '   $RET2 m_callback.handleEvent($ARGUMENT_COUNT, arguments);\n'
          '}\n',
          RETURN_TYPE=return_type,
          RET1=ret1,
          RET2=ret2,
          CLASS_NAME=class_name,
          FUNCTION=function_name,
          PARAMETERS=', '.join(parameters),
          ARGUMENTS_DECLARATION=arguments_declaration,
          ARGUMENT_COUNT=len(arguments))

    cpp_header_emitter = self._cpp_library_emitter.CreateHeaderEmitter(
        self._interface.id,
        self._renamer.GetLibraryName(self._interface),
        True)
    cpp_header_emitter.Emit(
        self._template_loader.Load('cpp_callback_header.template'),
        INTERFACE=self._interface.id,
        HANDLERS=cpp_header_handlers_emitter.Fragments())

    cpp_impl_emitter = self._cpp_library_emitter.CreateSourceEmitter(self._interface.id)
    cpp_impl_emitter.Emit(
        self._template_loader.Load('cpp_callback_implementation.template'),
        INCLUDES=self._GenerateCPPIncludes(cpp_impl_includes),
        INTERFACE=self._interface.id,
        SUPER_INTERFACE=supertype,
        HANDLERS=cpp_impl_handlers_emitter.Fragments(),
        DART_IMPLEMENTATION_CLASS=self._interface_type_info.implementation_name(),
        DART_IMPLEMENTATION_LIBRARY_ID='Dart%sLibraryId' % self._renamer.GetLibraryId(self._interface))

  def ImplementationTemplate(self):
    template = None
    interface_name = self._interface.doc_js_name
    if interface_name == self._interface.id or not self._database.HasInterface(interface_name):
      template_file = 'impl_%s.darttemplate' % interface_name
      template = self._template_loader.TryLoad(template_file)
    if not template:
      template = self._template_loader.Load('dart_implementation.darttemplate')
    return template

  def RootClassName(self):
    return 'NativeFieldWrapperClass2'

  # This code matches up with the _generate_native_entry code in
  # dart_utilities.py in the dartium repository.  Any changes to this
  # should have matching changes on that end.
  def DeriveNativeEntry(self, name, kind, count):
    interface_id = self._interface.id
    database = self._database
    tag = ""
    if kind == 'Getter':
        tag = "%s_Getter" % name
        blink_entry = tag
    elif kind == 'Setter':
        tag = "%s_Setter" % name
        blink_entry = tag
    elif kind == 'Constructor':
        tag = "constructorCallback"
        blink_entry = tag
    elif kind == 'Method':
        tag = "%s_Callback" % name
        blink_entry = tag

    interface_id = TypeIdToBlinkName(interface_id, database)

    def mkPublic(s):
      if s.startswith("_") or s.startswith("$"):
        return "$" + s
      return s

    if count is not None:
      arity = str(count)
      dart_name = mkPublic("_".join([tag, arity]))
    else:
      dart_name = mkPublic(tag)
    resolver_string = "_".join([interface_id, tag])

    return (dart_name, resolver_string)


  def DeriveNativeName(self, name, suffix=""):
      fields = ['$' + name]
      if suffix != "":
          fields.append(suffix)
      return "_".join(fields)

  def DeriveQualifiedBlinkName(self, interface_name, name):
      blinkClass = DeriveQualifiedName(
        "_blink", DeriveBlinkClassName(interface_name))
      blinkInstance = DeriveQualifiedName(blinkClass, "instance")
      return DeriveQualifiedName(blinkInstance, name + "_")

  def NativeSpec(self):
    return ''

  def StartInterface(self, members_emitter):
    # Create emitters for c++ implementation.
    if not IsPureInterface(self._interface.id) and \
        not IsCustomType(self._interface.id):
      self._cpp_header_emitter = self._cpp_library_emitter.CreateHeaderEmitter(
        self._interface.id,
        self._renamer.GetLibraryName(self._interface))
      self._cpp_impl_emitter = \
        self._cpp_library_emitter.CreateSourceEmitter(self._interface.id)
    else:
      self._cpp_header_emitter = emitter.Emitter()
      self._cpp_impl_emitter = emitter.Emitter()

    self._interface_type_info = self._TypeInfo(self._interface.id)
    self._members_emitter = members_emitter

    self._cpp_declarations_emitter = emitter.Emitter()

    self._cpp_impl_includes = \
      set(['"' + partial + '.h"'
           for partial in _GetCPPPartialNames(self._interface)])

    # This is a hack to work around a strange C++ compile error that we weren't
    # able to track down the true cause of.
    if self._interface.id == 'Timing':
      self._cpp_impl_includes.add('"core/animation/TimedItem.h"')

    self._cpp_definitions_emitter = emitter.Emitter()
    self._cpp_resolver_emitter = emitter.Emitter()

    # We need to revisit our treatment of typed arrays, right now
    # it is full of hacks.
    if self._interface.ext_attrs.get('ConstructorTemplate') == 'TypedArray':
      self._cpp_resolver_emitter.Emit(
          '    if (name == "$(INTERFACE_NAME)_constructor_Callback")\n'
          '        return Dart$(INTERFACE_NAME)Internal::constructorCallback;\n',
          INTERFACE_NAME=self._interface.id)

      self._cpp_impl_includes.add('"DartArrayBufferViewCustom.h"');
      self._cpp_definitions_emitter.Emit(
        '\n'
        'static void constructorCallback(Dart_NativeArguments args)\n'
        '{\n'
        '    WebCore::DartArrayBufferViewInternal::constructWebGLArray<Dart$(INTERFACE_NAME)>(args);\n'
        '}\n',
        INTERFACE_NAME=self._interface.id);

  def _EmitConstructorInfrastructure(self,
      constructor_info, cpp_prefix, cpp_suffix, factory_method_name,
      arguments=None, emit_to_native=False, is_custom=False):

    constructor_callback_cpp_name = cpp_prefix + cpp_suffix

    if arguments is None:
        arguments = constructor_info.idl_args[0]
        argument_count = len(arguments)
    else:
        argument_count = len(arguments)

    typed_formals = constructor_info.ParametersAsArgumentList(argument_count)
    parameters = constructor_info.ParametersAsStringOfVariables(argument_count)
    interface_name =  self._interface_type_info.interface_name()

    dart_native_name, constructor_callback_id = \
        self.DeriveNativeEntry(cpp_suffix, 'Constructor', argument_count)

    # Then we emit the impedance matching wrapper to call out to the
    # toplevel wrapper
    if not emit_to_native:
        toplevel_name = \
            self.DeriveQualifiedBlinkName(self._interface.id,
                                          dart_native_name)
        self._members_emitter.Emit(
            '\n  @DocsEditable()\n'
            '  static $INTERFACE_NAME $FACTORY_METHOD_NAME($PARAMETERS) => '
            '$TOPLEVEL_NAME($OUTPARAMETERS);\n',
            INTERFACE_NAME=self._interface_type_info.interface_name(),
            FACTORY_METHOD_NAME=factory_method_name,
            PARAMETERS=typed_formals,
            TOPLEVEL_NAME=toplevel_name,
            OUTPARAMETERS=parameters)

    self._cpp_resolver_emitter.Emit(
        '    if (name == "$ID")\n'
        '        return Dart$(WEBKIT_INTERFACE_NAME)Internal::$CPP_CALLBACK;\n',
        ID=constructor_callback_id,
        WEBKIT_INTERFACE_NAME=self._interface.id,
        CPP_CALLBACK=constructor_callback_cpp_name)

  def GenerateCustomFactory(self, constructor_info):
    if 'CustomConstructor' not in self._interface.ext_attrs:
        return False

    annotations = self._metadata.GetFormattedMetadata(self._library_name,
        self._interface, self._interface.id, '  ')

    self._members_emitter.Emit(
        '\n  $(ANNOTATIONS)factory $CTOR($PARAMS) => _create($FACTORY_PARAMS);\n',
        ANNOTATIONS=annotations,
        CTOR=constructor_info._ConstructorFullName(self._DartType),
        PARAMS=constructor_info.ParametersAsDeclaration(self._DartType),
        FACTORY_PARAMS= \
            constructor_info.ParametersAsArgumentList())

    constructor_callback_cpp_name = 'constructorCallback'
    self._EmitConstructorInfrastructure(
        constructor_info, "", constructor_callback_cpp_name, '_create', 
        is_custom=True)

    self._cpp_declarations_emitter.Emit(
        '\n'
        'void $CPP_CALLBACK(Dart_NativeArguments);\n',
        CPP_CALLBACK=constructor_callback_cpp_name)

    return True

  def IsConstructorArgumentOptional(self, argument):
    return IsOptional(argument)

  def EmitStaticFactoryOverload(self, constructor_info, name, arguments):
    constructor_callback_cpp_name = name + 'constructorCallback'  
    self._EmitConstructorInfrastructure(
        constructor_info, name, 'constructorCallback', name, arguments, 
        emit_to_native=True, 
        is_custom=False)

    ext_attrs = self._interface.ext_attrs

    create_function = 'create'
    if 'NamedConstructor' in ext_attrs:
      create_function = 'createForJSConstructor'
    function_expression = '%s::%s' % (self._interface_type_info.native_type(), create_function)
    self._GenerateNativeCallback(
        constructor_callback_cpp_name,
        False,
        function_expression,
        self._interface,
        arguments,
        self._interface.id,
        False,
        'ConstructorRaisesException' in ext_attrs or 'RaisesException' in ext_attrs,
        True)

  def HasSupportCheck(self):
    # Need to omit a support check if it is conditional in JS.
    return self._interface.doc_js_name in js_support_checks

  def GetSupportCheck(self):
    # Assume that everything is supported on Dartium.
    value = js_support_checks.get(self._interface.doc_js_name)
    if type(value) == tuple:
      return (value[0], 'true')
    else:
      return 'true'

  def FinishInterface(self):
    interface = self._interface
    if interface.parents:
      supertype = '%sClassId' % interface.parents[0].type.id
    else:
      supertype = '-1'

    self._GenerateCPPHeader()

    self._cpp_impl_emitter.Emit(
        self._template_loader.Load('cpp_implementation.template'),
        INTERFACE=self._interface.id,
        SUPER_INTERFACE=supertype,
        INCLUDES=self._GenerateCPPIncludes(self._cpp_impl_includes),
        CALLBACKS=self._cpp_definitions_emitter.Fragments(),
        RESOLVER=self._cpp_resolver_emitter.Fragments(),
        WEBCORE_CLASS_NAME=self._interface_type_info.native_type(),
        WEBCORE_CLASS_NAME_ESCAPED=
        self._interface_type_info.native_type().replace('<', '_').replace('>', '_'),
        DART_IMPLEMENTATION_CLASS=self._interface_type_info.implementation_name(),
        DART_IMPLEMENTATION_LIBRARY_ID='Dart%sLibraryId' % self._renamer.GetLibraryId(self._interface))

  def _GenerateCPPHeader(self):
    to_native_emitter = emitter.Emitter()
    if self._interface_type_info.custom_to_native():
      return_type = 'PassRefPtr<NativeType>'
      to_native_body = ';'
      to_native_arg_body = ';'
    else:
      return_type = 'NativeType*'
      to_native_body = emitter.Format(
          '\n'
          '    {\n'
          '        DartDOMData* domData = DartDOMData::current();\n'
          '        return DartDOMWrapper::unwrapDartWrapper<Dart$INTERFACE>(domData, handle, exception);\n'
          '    }',
          INTERFACE=self._interface.id)
      to_native_arg_body = emitter.Format(
          '\n'
          '    {\n'
          '        return DartDOMWrapper::unwrapDartWrapper<Dart$INTERFACE>(args, index, exception);\n'
          '    }',
          INTERFACE=self._interface.id)

    to_native_emitter.Emit(
        '    static $RETURN_TYPE toNative(Dart_Handle handle, Dart_Handle& exception)$TO_NATIVE_BODY\n'
        '\n'
        '    static $RETURN_TYPE toNativeWithNullCheck(Dart_Handle handle, Dart_Handle& exception)\n'
        '    {\n'
        '        return Dart_IsNull(handle) ? 0 : toNative(handle, exception);\n'
        '    }\n'
        '\n'
        '    static $RETURN_TYPE toNative(Dart_NativeArguments args, int index, Dart_Handle& exception)$TO_NATIVE_ARG_BODY\n'
        '\n'
        '    static $RETURN_TYPE toNativeWithNullCheck(Dart_NativeArguments args, int index, Dart_Handle& exception)\n'
        '    {\n'
        '        // toNative accounts for Null objects also.\n'
        '        return toNative(args, index, exception);\n'
        '    }\n',
        RETURN_TYPE=return_type,
        TO_NATIVE_BODY=to_native_body,
        TO_NATIVE_ARG_BODY=to_native_arg_body,
        INTERFACE=self._interface.id)

    to_dart_emitter = emitter.Emitter()

    ext_attrs = self._interface.ext_attrs

    to_dart_emitter.Emit(
        '    static Dart_Handle toDart(NativeType* value)\n'
        '    {\n'
        '        if (!value)\n'
        '            return Dart_Null();\n'
        '        DartDOMData* domData = DartDOMData::current();\n'
        '        Dart_WeakPersistentHandle result =\n'
        '            DartDOMWrapper::lookupWrapper<Dart$(INTERFACE)>(domData, value);\n'
        '        if (result)\n'
        '            return Dart_HandleFromWeakPersistent(result);\n'
        '        return createWrapper(domData, value);\n'
        '    }\n'
        '    static void returnToDart(Dart_NativeArguments args,\n'
        '                             NativeType* value,\n'
        '                             bool autoDartScope = true)\n'
        '    {\n'
        '        if (value) {\n'
        '            DartDOMData* domData = static_cast<DartDOMData*>(\n'
        '                Dart_GetNativeIsolateData(args));\n'
        '            Dart_WeakPersistentHandle result =\n'
        '                DartDOMWrapper::lookupWrapper<Dart$(INTERFACE)>(domData, value);\n'
        '            if (result)\n'
        '                Dart_SetWeakHandleReturnValue(args, result);\n'
        '            else {\n'
        '                if (autoDartScope) {\n'
        '                    Dart_SetReturnValue(args, createWrapper(domData, value));\n'
        '                } else {\n'
        '                    DartApiScope apiScope;\n'
        '                    Dart_SetReturnValue(args, createWrapper(domData, value));\n'
        '               }\n'
        '            }\n'
        '        }\n'
        '    }\n',
        INTERFACE=self._interface.id)

    if ('CustomToV8' in ext_attrs or
        'PureInterface' in ext_attrs or
        'CPPPureInterface' in ext_attrs or
        'SpecialWrapFor' in ext_attrs or
        ('Custom' in ext_attrs and ext_attrs['Custom'] == 'Wrap') or
        ('Custom' in ext_attrs and ext_attrs['Custom'] == 'ToV8') or
        self._interface_type_info.custom_to_dart()):
      to_dart_emitter.Emit(
          '    static Dart_Handle createWrapper(DartDOMData* domData, NativeType* value);\n')
    else:
      to_dart_emitter.Emit(
          '    static Dart_Handle createWrapper(DartDOMData* domData, NativeType* value)\n'
          '    {\n'
          '        return DartDOMWrapper::createWrapper<Dart$(INTERFACE)>(domData, value, Dart$(INTERFACE)::dartClassId);\n'
          '    }\n',
          INTERFACE=self._interface.id)

    webcore_includes = self._GenerateCPPIncludes(
        self._interface_type_info.webcore_includes())

    is_node_test = lambda interface: interface.id == 'Node'
    is_active_test = lambda interface: 'ActiveDOMObject' in interface.ext_attrs
    is_event_target_test = lambda interface: 'EventTarget' in interface.ext_attrs

    def TypeCheckHelper(test):
      return 'true' if any(map(test, self._database.Hierarchy(self._interface))) else 'false'

    to_active_emitter = emitter.Emitter()
    to_node_emitter = emitter.Emitter()
    to_event_target_emitter = emitter.Emitter()

    if (any(map(is_active_test, self._database.Hierarchy(self._interface)))):
      to_active_emitter.Emit('return toNative(value);')
    else:
      to_active_emitter.Emit('return 0;')

    if (any(map(is_node_test, self._database.Hierarchy(self._interface)))):
      to_node_emitter.Emit('return toNative(value);')
    else:
      to_node_emitter.Emit('return 0;')

    if (any(map(is_event_target_test, self._database.Hierarchy(self._interface)))):
      to_event_target_emitter.Emit('return toNative(value);')
    else:
      to_event_target_emitter.Emit('return 0;')

    v8_interface_include = ''
    # V8AbstractWorker.h does not exist so we have to hard code this case.
    if self._interface.id != 'AbstractWorker':
      # FIXME: We need this to access the WrapperTypeInfo.
      v8_interface_include = '#include "V8%s.h"' % (self._interface.id)

    self._cpp_header_emitter.Emit(
        self._template_loader.Load('cpp_header.template'),
        INTERFACE=self._interface.id,
        WEBCORE_INCLUDES=webcore_includes,
        V8_INTERFACE_INCLUDE=v8_interface_include,
        WEBCORE_CLASS_NAME=self._interface_type_info.native_type(),
        WEBCORE_CLASS_NAME_ESCAPED=
        self._interface_type_info.native_type().replace('<', '_').replace('>', '_'),
        DECLARATIONS=self._cpp_declarations_emitter.Fragments(),
        IS_NODE=TypeCheckHelper(is_node_test),
        IS_ACTIVE=TypeCheckHelper(is_active_test),
        IS_EVENT_TARGET=TypeCheckHelper(is_event_target_test),
        TO_NODE=to_node_emitter.Fragments(),
        TO_ACTIVE=to_active_emitter.Fragments(),
        TO_EVENT_TARGET=to_event_target_emitter.Fragments(),
        TO_NATIVE=to_native_emitter.Fragments(),
        TO_DART=to_dart_emitter.Fragments())

  def EmitAttribute(self, attribute, html_name, read_only):
    self._AddGetter(attribute, html_name, read_only)
    if not read_only:
      self._AddSetter(attribute, html_name)

  def _GenerateAutoSetupScope(self, idl_name, native_suffix):
    return (self._interface.id, idl_name, native_suffix) not in _cpp_no_auto_scope_list

  def _AddGetter(self, attr, html_name, read_only):
    # Temporary hack to force dart:scalarlist clamped array for ImageData.data.
    # TODO(antonm): solve in principled way.
    if self._interface.id == 'ImageData' and html_name == 'data':
      html_name = '_data'
    type_info = self._TypeInfo(attr.type.id)
    return_type = self.SecureOutputType(attr.type.id, False, read_only)
    parameters = []
    dart_declaration = '%s get %s' % (return_type, html_name)
    is_custom = _IsCustom(attr) and (_IsCustomValue(attr, None) or
                                     _IsCustomValue(attr, 'Getter'))
    # This seems to have been replaced with Custom=Getter (see above), but
    # check to be sure we don't see the old syntax
    assert(not ('CustomGetter' in attr.ext_attrs))
    native_suffix = 'Getter'
    auto_scope_setup = self._GenerateAutoSetupScope(attr.id, native_suffix)
    native_entry = \
        self.DeriveNativeEntry(attr.id, 'Getter', None)
    cpp_callback_name = self._GenerateNativeBinding(attr.id, 1,
        dart_declaration, attr.is_static, return_type, parameters,
        native_suffix, is_custom, auto_scope_setup, native_entry=native_entry)
    if is_custom:
      return

    if 'Reflect' in attr.ext_attrs:
      webcore_function_name = self._TypeInfo(attr.type.id).webcore_getter_name()
      if 'URL' in attr.ext_attrs:
        if 'NonEmpty' in attr.ext_attrs:
          webcore_function_name = 'getNonEmptyURLAttribute'
        else:
          webcore_function_name = 'getURLAttribute'
    elif 'ImplementedAs' in attr.ext_attrs:
      webcore_function_name = attr.ext_attrs['ImplementedAs']
    else:
      if attr.id == 'operator':
        webcore_function_name = '_operator'
      elif attr.id == 'target' and attr.type.id == 'SVGAnimatedString':
        webcore_function_name = 'svgTarget'
      elif attr.id == 'CSS':
        webcore_function_name = 'css'
      else:
        webcore_function_name = self._ToWebKitName(attr.id)

    function_expression = self._GenerateWebCoreFunctionExpression(webcore_function_name, attr)
    raises = ('RaisesException' in attr.ext_attrs and
              attr.ext_attrs['RaisesException'] != 'Setter')
    self._GenerateNativeCallback(
        cpp_callback_name,
        True,
        function_expression,
        attr,
        [],
        attr.type.id,
        attr.type.nullable,
        raises,
        auto_scope_setup)

  def _AddSetter(self, attr, html_name):
    type_info = self._TypeInfo(attr.type.id)
    return_type = 'void'
    parameters = ['value']
    ptype = self._DartType(attr.type.id)
    dart_declaration = 'void set %s(%s value)' % (html_name, ptype)
    is_custom = _IsCustom(attr) and (_IsCustomValue(attr, None) or
                                     _IsCustomValue(attr, 'Setter'))
    # This seems to have been replaced with Custom=Setter (see above), but
    # check to be sure we don't see the old syntax
    assert(not ('CustomSetter' in attr.ext_attrs))
    assert(not ('V8CustomSetter' in attr.ext_attrs))
    native_suffix = 'Setter'
    auto_scope_setup = self._GenerateAutoSetupScope(attr.id, native_suffix)
    native_entry = \
        self.DeriveNativeEntry(attr.id, 'Setter', None)
    cpp_callback_name = self._GenerateNativeBinding(attr.id, 2,
        dart_declaration, attr.is_static, return_type, parameters,
        native_suffix, is_custom, auto_scope_setup, native_entry=native_entry)
    if is_custom:
      return

    if 'Reflect' in attr.ext_attrs:
      webcore_function_name = self._TypeInfo(attr.type.id).webcore_setter_name()
    else:
      if 'ImplementedAs' in attr.ext_attrs:
        attr_name = attr.ext_attrs['ImplementedAs']
      else:
        attr_name = attr.id
      webcore_function_name = re.sub(r'^(xml|css|(?=[A-Z])|\w)',
                                     lambda s: s.group(1).upper(),
                                     attr_name)
      webcore_function_name = 'set%s' % webcore_function_name

    function_expression = self._GenerateWebCoreFunctionExpression(webcore_function_name, attr)
    raises = ('RaisesException' in attr.ext_attrs and
              attr.ext_attrs['RaisesException'] != 'Getter')
    self._GenerateNativeCallback(
        cpp_callback_name,
        True,
        function_expression,
        attr,
        [attr],
        'void',
        False,
        raises,
        auto_scope_setup,
        generate_custom_element_scope_if_needed=True)

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
    dart_element_type = self._DartType(element_type)
    if self._HasNativeIndexGetter():
      self._EmitNativeIndexGetter(dart_element_type)
    elif self._HasExplicitIndexedGetter():
      self._EmitExplicitIndexedGetter(dart_element_type)
    else:
      is_custom = any((op.id == 'item' and _IsCustom(op)) for op in self._interface.operations)
      # First emit a toplevel function to do the native call
      # Calls to this are emitted elsewhere,
      dart_native_name, resolver_string = \
          self.DeriveNativeEntry("item", 'Method', 1)

      # Emit the method which calls the toplevel function, along with
      # the [] operator.
      dart_qualified_name = \
          self.DeriveQualifiedBlinkName(self._interface.id,
                                        dart_native_name)
      self._members_emitter.Emit(
          '\n'
          '  $TYPE operator[](int index) {\n'
          '    if (index < 0 || index >= length)\n'
          '      throw new RangeError.range(index, 0, length);\n'
          '    return $(DART_NATIVE_NAME)(this, index);\n'
          '  }\n\n'
          '  $TYPE _nativeIndexedGetter(int index) =>'
          ' $(DART_NATIVE_NAME)(this, index);\n',
          DART_NATIVE_NAME=dart_qualified_name,
          TYPE=self.SecureOutputType(element_type),
          INTERFACE=self._interface.id)

    if self._HasNativeIndexSetter():
      self._EmitNativeIndexSetter(dart_element_type)
    else:
      self._members_emitter.Emit(
          '\n'
          '  void operator[]=(int index, $TYPE value) {\n'
          '    throw new UnsupportedError("Cannot assign element of immutable List.");\n'
          '  }\n',
          TYPE=dart_element_type)

    self.EmitListMixin(dart_element_type)

  def AmendIndexer(self, element_type):
    # If interface is marked as having native indexed
    # getter or setter, we must emit overrides as it's not
    # guaranteed that the corresponding methods in C++ would be
    # virtual.  For example, as of time of writing, even though
    # Uint8ClampedArray inherits from Uint8Array, ::set method
    # is not virtual and accessing it through Uint8Array pointer
    # would lead to wrong semantics (modulo vs. clamping.)
    dart_element_type = self._DartType(element_type)

    if self._HasNativeIndexGetter():
      self._EmitNativeIndexGetter(dart_element_type)
    if self._HasNativeIndexSetter():
      self._EmitNativeIndexSetter(dart_element_type)

  def _HasNativeIndexGetter(self):
    return 'CustomIndexedGetter' in self._interface.ext_attrs

  def _EmitNativeIndexGetter(self, element_type):
    return_type = self.SecureOutputType(element_type, True)
    parameters = ['index']
    dart_declaration = '%s operator[](int index)' % return_type
    self._GenerateNativeBinding('numericIndexGetter', 2,
      dart_declaration, False, return_type, parameters,
      'Callback', True, False)

  def _HasExplicitIndexedGetter(self):
    return any(op.id == 'getItem' for op in self._interface.operations)

  def _EmitExplicitIndexedGetter(self, dart_element_type):
    if any(op.id == 'getItem' for op in self._interface.operations):
      indexed_getter = 'getItem'

    self._members_emitter.Emit(
        '\n'
        '  $TYPE operator[](int index) {\n'
        '    if (index < 0 || index >= length)\n'
        '      throw new RangeError.range(index, 0, length);\n'
        '    return $INDEXED_GETTER(index);\n'
        '  }\n',
        TYPE=dart_element_type,
        INDEXED_GETTER=indexed_getter)

  def _HasNativeIndexSetter(self):
    return 'CustomIndexedSetter' in self._interface.ext_attrs

  def _EmitNativeIndexSetter(self, element_type):
    return_type = 'void'
    formals = ', '.join(['int index', '%s value' % element_type])
    parameters = ['index', 'value']
    dart_declaration = 'void operator[]=(%s)' % formals
    self._GenerateNativeBinding('numericIndexSetter', 3, 
      dart_declaration, False, return_type, parameters,
      'Callback', True, False)

  def EmitOperation(self, info, html_name):
    """
    Arguments:
      info: An OperationInfo object.
    """
    return_type = self.SecureOutputType(info.type_name, False, True)
    formals = info.ParametersAsDeclaration(self._DartType)
    parameters = info.ParametersAsListOfVariables()
    dart_declaration = '%s%s %s(%s)' % (
        'static ' if info.IsStatic() else '',
        return_type,
        html_name,
        formals)

    operation = info.operations[0]
    is_custom = _IsCustom(operation)
    has_optional_arguments = any(IsOptional(argument) for argument in operation.arguments)
    needs_dispatcher = not is_custom and (len(info.operations) > 1 or has_optional_arguments)

    if info.callback_args:
      self._AddFutureifiedOperation(info, html_name)
    elif not needs_dispatcher:
      # Bind directly to native implementation
      argument_count = (0 if info.IsStatic() else 1) + len(info.param_infos)
      native_suffix = 'Callback'
      auto_scope_setup = self._GenerateAutoSetupScope(info.name, native_suffix)
      native_entry = \
          self.DeriveNativeEntry(operation.id, 'Method', len(info.param_infos))
      cpp_callback_name = self._GenerateNativeBinding(
        info.name, argument_count, dart_declaration,
        info.IsStatic(), return_type, parameters,
        native_suffix, is_custom, auto_scope_setup,
        native_entry=native_entry)
      if not is_custom:
        self._GenerateOperationNativeCallback(operation, operation.arguments, cpp_callback_name, auto_scope_setup)
    else:
      self._GenerateDispatcher(info, info.operations, dart_declaration, html_name)

  def _GenerateDispatcher(self, info, operations, dart_declaration, html_name):

    def GenerateCall(
        stmts_emitter, call_emitter, version, operation, argument_count):
      native_suffix = 'Callback'
      actuals = info.ParametersAsListOfVariables(argument_count)
      actuals_s = ", ".join(actuals)
      formals=actuals
      return_type = self.SecureOutputType(operation.type.id)
      native_suffix = 'Callback'
      is_custom = _IsCustom(operation)
      base_name = '_%s_%s' % (operation.id, version)
      static = True
      if not operation.is_static:
        actuals = ['this'] + actuals
        formals = ['mthis'] + formals
      actuals_s = ", ".join(actuals)
      formals_s = ", ".join(formals)
      dart_declaration = '%s(%s)' % (
        base_name, formals_s)
      native_entry = \
          self.DeriveNativeEntry(operation.id, 'Method', argument_count)
      overload_base_name = native_entry[0]
      overload_name = \
          self.DeriveQualifiedBlinkName(self._interface.id,
                                        overload_base_name)
      call_emitter.Emit('$NAME($ARGS)', NAME=overload_name, ARGS=actuals_s)
      auto_scope_setup = \
        self._GenerateAutoSetupScope(base_name, native_suffix)
      cpp_callback_name = self._GenerateNativeBinding(
        base_name, (0 if static else 1) + argument_count,
        dart_declaration, static, return_type, formals,
        native_suffix, is_custom, auto_scope_setup, emit_metadata=False,
        emit_to_native=True, native_entry=native_entry)
      if not is_custom:
        self._GenerateOperationNativeCallback(operation,
          operation.arguments[:argument_count], cpp_callback_name,
          auto_scope_setup)


    self._GenerateDispatcherBody(
        info,
        operations,
        dart_declaration,
        GenerateCall,
        IsOptional)

  def SecondaryContext(self, interface):
    pass

  def _GenerateOperationNativeCallback(self, operation, arguments, cpp_callback_name, auto_scope_setup=True):
    webcore_function_name = operation.ext_attrs.get('ImplementedAs', operation.id)

    function_expression = self._GenerateWebCoreFunctionExpression(webcore_function_name, operation, cpp_callback_name)
    self._GenerateNativeCallback(
        cpp_callback_name,
        not operation.is_static,
        function_expression,
        operation,
        arguments,
        operation.type.id,
        operation.type.nullable,
        'RaisesException' in operation.ext_attrs,
        auto_scope_setup,
        generate_custom_element_scope_if_needed=True)

  def _GenerateNativeCallback(self,
      callback_name,
      needs_receiver,
      function_expression,
      node,
      arguments,
      return_type,
      return_type_is_nullable,
      raises_dom_exception,
      auto_scope_setup=True,
      generate_custom_element_scope_if_needed=False):

    ext_attrs = node.ext_attrs

    if self._IsStatic(node.id):
      needs_receiver = True

    cpp_arguments = []
    runtime_check = None
    raises_exceptions = raises_dom_exception or arguments or needs_receiver
    needs_custom_element_callbacks = False

    # TODO(antonm): unify with ScriptState below.
    call_with = ext_attrs.get('CallWith', '') + ext_attrs.get('ConstructorCallWith', '')
    requires_stack_info = 'ScriptArguments' in call_with or 'ScriptState' in call_with
    if requires_stack_info:
      raises_exceptions = True
      cpp_arguments = ['&state', 'scriptArguments.release()']
      # WebKit uses scriptArguments to reconstruct last argument, so
      # it's not needed and should be just removed.
      arguments = arguments[:-1]

    # TODO(antonm): unify with ScriptState below.
    requires_script_arguments = (ext_attrs.get('CallWith') == 'ScriptArguments' or
                                 ext_attrs.get('ConstructorCallWith') == 'ScriptArguments')
    if requires_script_arguments:
      raises_exceptions = True
      cpp_arguments = ['scriptArguments.release()']
      # WebKit uses scriptArguments to reconstruct last argument, so
      # it's not needed and should be just removed.
      arguments = arguments[:-1]

    requires_script_execution_context = (ext_attrs.get('CallWith') == 'ExecutionContext' or
                                         ext_attrs.get('ConstructorCallWith') == 'ExecutionContext')

    # Hack because our parser misses that these IDL members require an execution
    # context.

    if (self._interface.id == 'FontFace'
        and callback_name in ['familySetter', 'featureSettingsSetter', 'stretchSetter',
                              'styleSetter', 'unicodeRangeSetter', 'variantSetter', 'weightSetter']):
      requires_script_execution_context = True

    requires_document = ext_attrs.get('ConstructorCallWith') == 'Document'

    if requires_script_execution_context:
      raises_exceptions = True
      cpp_arguments = ['context']

    requires_script_state = (ext_attrs.get('CallWith') == 'ScriptState' or
                             ext_attrs.get('ConstructorCallWith') == 'ScriptState')
    if requires_script_state:
      raises_exceptions = True
      cpp_arguments = ['&state']

    requires_dom_window = 'NamedConstructor' in ext_attrs
    if requires_dom_window or requires_document:
      raises_exceptions = True
      cpp_arguments = ['document']

    if 'ImplementedBy' in ext_attrs:
      assert needs_receiver
      self._cpp_impl_includes.add('"%s.h"' % ext_attrs['ImplementedBy'])
      cpp_arguments.append('receiver')

    if 'Reflect' in ext_attrs:
      cpp_arguments = [self._GenerateWebCoreReflectionAttributeName(node)]

    if generate_custom_element_scope_if_needed and (ext_attrs.get('CustomElementCallbacks', 'None') != 'None' or 'Reflect' in ext_attrs):
      self._cpp_impl_includes.add('"core/dom/custom/CustomElementCallbackDispatcher.h"')
      needs_custom_element_callbacks = True

    if return_type_is_nullable:
      cpp_arguments = ['isNull']

    v8EnabledPerContext = ext_attrs.get('synthesizedV8EnabledPerContext', ext_attrs.get('V8EnabledPerContext'))
    v8EnabledAtRuntime = ext_attrs.get('synthesizedV8EnabledAtRuntime', ext_attrs.get('V8EnabledAtRuntime'))
    assert(not (v8EnabledPerContext and v8EnabledAtRuntime))

    if v8EnabledPerContext:
      raises_exceptions = True
      self._cpp_impl_includes.add('"ContextFeatures.h"')
      self._cpp_impl_includes.add('"DOMWindow.h"')
      runtime_check = emitter.Format(
          '        if (!ContextFeatures::$(FEATURE)Enabled(DartUtilities::domWindowForCurrentIsolate()->document())) {\n'
          '            exception = Dart_NewStringFromCString("Feature $FEATURE is not enabled");\n'
          '            goto fail;\n'
          '        }',
          FEATURE=v8EnabledPerContext)

    if v8EnabledAtRuntime:
      raises_exceptions = True
      self._cpp_impl_includes.add('"RuntimeEnabledFeatures.h"')
      runtime_check = emitter.Format(
          '        if (!RuntimeEnabledFeatures::$(FEATURE)Enabled()) {\n'
          '            exception = Dart_NewStringFromCString("Feature $FEATURE is not enabled");\n'
          '            goto fail;\n'
          '        }',
          FEATURE=self._ToWebKitName(v8EnabledAtRuntime))

    body_emitter = self._cpp_definitions_emitter.Emit(
        '\n'
        'static void $CALLBACK_NAME(Dart_NativeArguments args)\n'
        '{\n'
        '$!BODY'
        '}\n',
        CALLBACK_NAME=callback_name)

    if raises_exceptions:
      body_emitter = body_emitter.Emit(
          '    Dart_Handle exception = 0;\n'
          '$!BODY'
          '\n'
          'fail:\n'
          '    Dart_ThrowException(exception);\n'
          '    ASSERT_NOT_REACHED();\n')

    body_emitter = body_emitter.Emit(
        '    {\n'
        '$!BODY'
        '        return;\n'
        '    }\n')

    if runtime_check:
      body_emitter.Emit(
          '$RUNTIME_CHECK\n',
          RUNTIME_CHECK=runtime_check)

    if requires_script_execution_context:
      body_emitter.Emit(
          '        ExecutionContext* context = DartUtilities::scriptExecutionContext();\n'
          '        if (!context) {\n'
          '            exception = Dart_NewStringFromCString("Failed to retrieve a context");\n'
          '            goto fail;\n'
          '        }\n\n')

    if requires_script_state:
      body_emitter.Emit(
          '        ScriptState* currentState = DartUtilities::currentScriptState();\n'
          '        if (!currentState) {\n'
          '            exception = Dart_NewStringFromCString("Failed to retrieve a script state");\n'
          '            goto fail;\n'
          '        }\n'
          '        ScriptState& state = *currentState;\n\n')

    if requires_dom_window or requires_document:
      self._cpp_impl_includes.add('"DOMWindow.h"')

      body_emitter.Emit(
          '        DOMWindow* domWindow = DartUtilities::domWindowForCurrentIsolate();\n'
          '        if (!domWindow) {\n'
          '            exception = Dart_NewStringFromCString("Failed to fetch domWindow");\n'
          '            goto fail;\n'
          '        }\n'
          '        Document& document = *domWindow->document();\n')

    if needs_receiver:
      body_emitter.Emit(
        '        $WEBCORE_CLASS_NAME* receiver = '
        'DartDOMWrapper::receiverChecked<Dart$INTERFACE>(args, exception);\n'
        '        if (exception)\n'
        '            goto fail;\n',
        WEBCORE_CLASS_NAME=self._interface_type_info.native_type(),
        INTERFACE=self._interface.id)

    if requires_stack_info:
      self._cpp_impl_includes.add('"ScriptArguments.h"')
      body_emitter.Emit(
          '\n'
          '        ScriptState* currentState = DartUtilities::currentScriptState();\n'
          '        if (!currentState) {\n'
          '            exception = Dart_NewStringFromCString("Failed to retrieve a script state");\n'
          '            goto fail;\n'
          '        }\n'
          '        ScriptState& state = *currentState;\n'
          '\n'
          '        Dart_Handle customArgument = Dart_GetNativeArgument(args, $INDEX);\n'
          '        RefPtr<ScriptArguments> scriptArguments(DartUtilities::createScriptArguments(customArgument, exception));\n'
          '        if (!scriptArguments)\n'
          '            goto fail;\n',
          INDEX=len(arguments) + 1)

    if requires_script_arguments:
      self._cpp_impl_includes.add('"ScriptArguments.h"')
      body_emitter.Emit(
          '\n'
          '        Dart_Handle customArgument = Dart_GetNativeArgument(args, $INDEX);\n'
          '        RefPtr<ScriptArguments> scriptArguments(DartUtilities::createScriptArguments(customArgument, exception));\n'
          '        if (!scriptArguments)\n'
          '            goto fail;\n',
          INDEX=len(arguments) + 1)

    if needs_custom_element_callbacks:
      body_emitter.Emit('        CustomElementCallbackDispatcher::CallbackDeliveryScope deliveryScope;\n');

    # Emit arguments.
    start_index = 1 if needs_receiver else 0
    for i, argument in enumerate(arguments):
      type_info = self._TypeInfo(argument.type.id)
      self._cpp_impl_includes |= set(type_info.conversion_includes())
      argument_expression_template, type, cls, function = \
          type_info.to_native_info(argument, self._interface.id, callback_name)

      def AllowsNull():
        # TODO(vsm): HTMLSelectElement's indexed setter treats a null as a remove.
        # We need to handle that.
        # assert argument.ext_attrs.get('TreatNullAs', 'NullString') == 'NullString'
        if argument.ext_attrs.get('TreatNullAs') == 'NullString':
          return True

        if argument.type.nullable:
          return True

        if isinstance(argument, IDLAttribute):
          return (argument.type.id == 'DOMString') and \
              ('Reflect' in argument.ext_attrs)

        if isinstance(argument, IDLArgument):
          if IsOptional(argument) and not self._IsArgumentOptionalInWebCore(node, argument):
            return True
          # argument default to null (e.g., DOMString arg = null).
          if argument.default_value_is_null:
            return True
          if _IsOptionalStringArgumentInInitEventMethod(self._interface, node, argument):
            return True

        return False

      if AllowsNull():
        function += 'WithNullCheck'

      argument_name = DartDomNameOfAttribute(argument)
      if type_info.pass_native_by_ref():
        invocation_template =\
            '        $TYPE $ARGUMENT_NAME;\n'\
            '        $CLS::$FUNCTION(args, $INDEX, $ARGUMENT_NAME, exception);\n'
      else:
        if not auto_scope_setup and type_info.native_type() == 'String':
          invocation_template =\
              '        $TYPE $ARGUMENT_NAME = $CLS::$FUNCTION(args, $INDEX, exception, false);\n'
        else:
          invocation_template =\
              '        $TYPE $ARGUMENT_NAME = $CLS::$FUNCTION(args, $INDEX, exception);\n'
      body_emitter.Emit(
          '\n' +
          invocation_template +
          '        if (exception)\n'
          '            goto fail;\n',
          TYPE=type,
          ARGUMENT_NAME=argument_name,
          CLS=cls,
          FUNCTION=function,
          INDEX=start_index + i)
      self._cpp_impl_includes.add('"%s.h"' % cls)
      cpp_arguments.append(argument_expression_template % argument_name)

    body_emitter.Emit('\n')

    if 'NeedsUserGestureCheck' in ext_attrs:
      cpp_arguments.append('DartUtilities::processingUserGesture')

    invocation_emitter = body_emitter
    if raises_dom_exception:
      cpp_arguments.append('es')
      invocation_emitter = body_emitter.Emit(
        '        DartExceptionState es;\n'
        '$!INVOCATION'
        '        if (es.hadException()) {\n'
        '            exception = DartDOMWrapper::exceptionCodeToDartException(es);\n'
        '            goto fail;\n'
        '        }\n')


    interface_name = self._interface_type_info.native_type()

    if needs_receiver:
      # Hack to determine if this came from the _cpp_callback_map.
      # In this case, the getter is mapped to a static method.
      if function_expression.startswith('SVGTests::'):
          cpp_arguments.insert(0, 'receiver')
      elif (not function_expression.startswith('receiver->') and
          not function_expression.startswith(interface_name + '::')):
        if (interface_name in ['DOMWindow', 'Element', 'Navigator', 'WorkerGlobalScope']
            or (interface_name in ['SVGViewSpec', 'SVGViewElement', 'SVGSVGElement']
              and callback_name in ['setZoomAndPan', 'zoomAndPanSetter', 'zoomAndPan'])
            or (interface_name == 'Screen'
              and callback_name in ['_lockOrientation_1Callback', '_lockOrientation_2Callback', 'unlockOrientation', 'orientation'])):
          cpp_arguments.insert(0, 'receiver')
        else:
          cpp_arguments.append('receiver')
      elif self._IsStatic(node.id):
        cpp_arguments.insert(0, 'receiver')

    if interface_name in ['SVGPropertyTearOff<SVGTransform>', 'SVGPropertyTearOff<SVGAngle>', 'SVGMatrixTearOff'] and function_expression.startswith('receiver->'):
      # This is a horrible hack. I don't know why this one case has to be
      # special cased.
      if not (self._interface.id == 'SVGTransformList' and callback_name == 'createSVGTransformFromMatrixCallback'):
        function_expression = 'receiver->propertyReference().%s' % (function_expression[len('receiver->'):])

    function_call = '%s(%s)' % (function_expression, ', '.join(cpp_arguments))
    if return_type == 'void':
      invocation_emitter.Emit(
        '        $FUNCTION_CALL;\n',
        FUNCTION_CALL=function_call)
    else:
      return_type_info = self._TypeInfo(return_type)
      self._cpp_impl_includes |= set(return_type_info.conversion_includes())

      if return_type_is_nullable:
        invocation_emitter.Emit(
          '        bool isNull = false;\n'
          '        $NATIVE_TYPE result = $FUNCTION_CALL;\n'
          '        if (isNull)\n'
          '            return;\n',
          NATIVE_TYPE=return_type_info.parameter_type(),
          FUNCTION_CALL=function_call)
        value_expression = 'result'
      else:
        value_expression = function_call

      # Generate to Dart conversion of C++ value.
      if return_type_info.dart_type() == 'bool':
        set_return_value = 'Dart_SetBooleanReturnValue(args, %s)' % (value_expression)
      elif return_type_info.dart_type() == 'int':
        if return_type_info.native_type() == 'unsigned':
          set_return_value = 'DartUtilities::setDartUnsignedReturnValue(args, %s)' % (value_expression)
        elif return_type_info.native_type() == 'unsigned long long':
          set_return_value = 'DartUtilities::setDartUnsignedLongLongReturnValue(args, %s)' % (value_expression)
        else:
          assert (return_type_info.native_type() == 'int' or return_type_info.native_type() == 'long long')
          set_return_value = 'DartUtilities::setDartIntegerReturnValue(args, %s)' % (value_expression)
      elif return_type_info.dart_type() == 'double':
        set_return_value = 'Dart_SetDoubleReturnValue(args, %s)' % (value_expression)
      elif return_type_info.dart_type() == 'String':
        auto_dart_scope='true' if auto_scope_setup else 'false'
        if ext_attrs and 'TreatReturnedNullStringAs' in ext_attrs:
          set_return_value = 'DartUtilities::setDartStringReturnValueWithNullCheck(args, %s, %s)' % (value_expression, auto_dart_scope)
        else:
          set_return_value = 'DartUtilities::setDartStringReturnValue(args, %s, %s)' % (value_expression, auto_dart_scope)
      elif return_type_info.dart_type() == 'num' and return_type_info.native_type() == 'double':
        set_return_value = 'Dart_SetDoubleReturnValue(args, %s)' % (value_expression)
      else:
        return_to_dart_conversion = return_type_info.return_to_dart_conversion(
            value_expression,
            auto_scope_setup,
            self._interface.id,
            ext_attrs)
        set_return_value = '%s' % (return_to_dart_conversion)
      invocation_emitter.Emit(
        '        $RETURN_VALUE;\n',
        RETURN_VALUE=set_return_value)

  def _GenerateNativeBinding(self, idl_name, argument_count, dart_declaration,
      static, return_type, parameters, native_suffix, is_custom,
      auto_scope_setup=True, emit_metadata=True, emit_to_native=False,
      native_entry=None):
    metadata = []
    if emit_metadata:
      metadata = self._metadata.GetFormattedMetadata(
          self._renamer.GetLibraryName(self._interface),
          self._interface, idl_name, '  ')

    if (native_entry):
        dart_native_name, native_binding = native_entry
    else:
        dart_native_name = \
            self.DeriveNativeName(idl_name, native_suffix)
        native_binding_id = self._interface.id
        native_binding_id = TypeIdToBlinkName(native_binding_id, self._database)
        native_binding = \
            '%s_%s_%s' % (native_binding_id, idl_name, native_suffix)

    if not static:
        formals = ", ".join(['mthis'] + parameters)
        actuals = ", ".join(['this'] + parameters)
    else:
        formals = ", ".join(parameters)
        actuals = ", ".join(parameters)

    if not emit_to_native:
        caller_emitter = self._members_emitter
        full_dart_name = \
            self.DeriveQualifiedBlinkName(self._interface.id,
                                          dart_native_name)
        if IsPureInterface(self._interface.id):
            caller_emitter.Emit(
                '\n'
                '  $METADATA$DART_DECLARATION;\n',
                METADATA=metadata,
                DART_DECLARATION=dart_declaration)
        else:
            caller_emitter.Emit(
                '\n'
                '  $METADATA$DART_DECLARATION => $DART_NAME($ACTUALS);\n',
                METADATA=metadata,
                DART_DECLARATION=dart_declaration,
                DART_NAME=full_dart_name,
                ACTUALS=actuals)
    cpp_callback_name = '%s%s' % (idl_name, native_suffix)

    self._cpp_resolver_emitter.Emit(
        '    if (argumentCount == $ARGC && name == "$NATIVE_BINDING") {\n'
        '        *autoSetupScope = $AUTO_SCOPE_SETUP;\n'
        '        return Dart$(INTERFACE_NAME)Internal::$CPP_CALLBACK_NAME;\n'
        '    }\n',
        ARGC=argument_count,
        NATIVE_BINDING=native_binding,
        INTERFACE_NAME=self._interface.id,
        AUTO_SCOPE_SETUP='true' if auto_scope_setup else 'false',
        CPP_CALLBACK_NAME=cpp_callback_name)

    if is_custom:
      self._cpp_declarations_emitter.Emit(
          '\n'
          'void $CPP_CALLBACK_NAME(Dart_NativeArguments);\n',
          CPP_CALLBACK_NAME=cpp_callback_name)

    return cpp_callback_name

  def _GenerateWebCoreReflectionAttributeName(self, attr):
    namespace = 'HTMLNames'
    svg_exceptions = ['class', 'id', 'onabort', 'onclick', 'onerror', 'onload',
                      'onmousedown', 'onmousemove', 'onmouseout', 'onmouseover',
                      'onmouseup', 'onresize', 'onscroll', 'onunload']
    if self._interface.id.startswith('SVG') and not attr.id in svg_exceptions:
      namespace = 'SVGNames'
    self._cpp_impl_includes.add('"%s.h"' % namespace)

    attribute_name = attr.ext_attrs['Reflect'] or attr.id.lower()
    return 'WebCore::%s::%sAttr' % (namespace, attribute_name)

  def _IsStatic(self, attribute_name):
    cpp_type_name = self._interface_type_info.native_type()
    if cpp_type_name in _cpp_static_call_map:
      return attribute_name in _cpp_static_call_map[cpp_type_name]
    return False

  def _GenerateWebCoreFunctionExpression(self, function_name, idl_node, cpp_callback_name=None):
    if 'ImplementedBy' in idl_node.ext_attrs:
      return '%s::%s' % (idl_node.ext_attrs['ImplementedBy'], function_name)
    cpp_type_name = self._interface_type_info.native_type()
    impl_type_name = _GetCPPTypeName(cpp_type_name, function_name, cpp_callback_name)
    if idl_node.is_static or self._IsStatic(idl_node.id):
      return '%s::%s' % (impl_type_name, function_name)
    if cpp_type_name == impl_type_name:
      return '%s%s' % (self._interface_type_info.receiver(), function_name)
    else:
      return '%s::%s' % (impl_type_name, function_name)

  def _IsArgumentOptionalInWebCore(self, operation, argument):
    if not IsOptional(argument):
      return False
    if 'Callback' in argument.ext_attrs:
      return False
    if operation.id in ['addEventListener', 'removeEventListener'] and argument.id == 'useCapture':
      return False
    if 'DartForceOptional' in argument.ext_attrs:
      return False
    if argument.type.id == 'Dictionary':
      return False
    return True

  def _GenerateCPPIncludes(self, includes):
    return ''.join(['#include %s\n' % include for include in sorted(includes)])

  def _ToWebKitName(self, name):
    name = name[0].lower() + name[1:]
    name = re.sub(r'^(hTML|uRL|jS|xML|xSLT)', lambda s: s.group(1).lower(),
                  name)
    return re.sub(r'^(create|exclusive)',
                  lambda s: 'is' + s.group(1).capitalize(),
                  name)

class CPPLibraryEmitter():
  def __init__(self, emitters, cpp_sources_dir):
    self._emitters = emitters
    self._cpp_sources_dir = cpp_sources_dir
    self._library_headers = dict((lib, []) for lib in HTML_LIBRARY_NAMES)
    self._sources_list = []

  def CreateHeaderEmitter(self, interface_name, library_name, is_callback=False):
    path = os.path.join(self._cpp_sources_dir, 'Dart%s.h' % interface_name)
    if not is_callback:
      self._library_headers[library_name].append(path)
    return self._emitters.FileEmitter(path)

  def CreateSourceEmitter(self, interface_name):
    path = os.path.join(self._cpp_sources_dir, 'Dart%s.cpp' % interface_name)
    self._sources_list.append(path)
    return self._emitters.FileEmitter(path)

  def EmitDerivedSources(self, template, output_dir):
    partitions = 20 # FIXME: this should be configurable.
    sources_count = len(self._sources_list)
    for i in range(0, partitions):
      file_path = os.path.join(output_dir, 'DartDerivedSources%02i.cpp' % (i + 1))
      includes_emitter = self._emitters.FileEmitter(file_path).Emit(template)
      for source_file in self._sources_list[i::partitions]:
        path = os.path.relpath(source_file, output_dir)
        includes_emitter.Emit('#include "$PATH"\n', PATH=path)

  def EmitResolver(self, template, output_dir):
    for library_name in self._library_headers.keys():
      file_path = os.path.join(output_dir, '%s_DartResolver.cpp' % library_name)
      includes_emitter, body_emitter = self._emitters.FileEmitter(file_path).Emit(
        template,
        LIBRARY_NAME=library_name)

      headers = self._library_headers[library_name]
      for header_file in headers:
        path = os.path.relpath(header_file, output_dir)
        includes_emitter.Emit('#include "$PATH"\n', PATH=path)
        body_emitter.Emit(
            '    if (Dart_NativeFunction func = $CLASS_NAME::resolver(name, argumentCount, autoSetupScope))\n'
            '        return func;\n',
            CLASS_NAME=os.path.splitext(os.path.basename(path))[0])

  def EmitClassIdTable(self, database, output_dir, type_registry, renamer):
    def HasConverters(interface):
      is_node_test = lambda interface: interface.id == 'Node'
      is_active_test = lambda interface: 'ActiveDOMObject' in interface.ext_attrs
      is_event_target_test = lambda interface: 'EventTarget' in interface.ext_attrs

      return (any(map(is_node_test, database.Hierarchy(interface))) or
              any(map(is_active_test, database.Hierarchy(interface))) or
              any(map(is_event_target_test, database.Hierarchy(interface))))


    path = os.path.join(output_dir, 'DartWebkitClassIds.h')
    e = self._emitters.FileEmitter(path)
    e.Emit('// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file\n');
    e.Emit('// for details. All rights reserved. Use of this source code is governed by a\n');
    e.Emit('// BSD-style license that can be found in the LICENSE file.\n');
    e.Emit('// WARNING: Do not edit - generated code.\n');
    e.Emit('// See dart/tools/dom/scripts/systemnative.py\n');
    e.Emit('\n');
    e.Emit('#ifndef DartWebkitClassIds_h\n');
    e.Emit('#define DartWebkitClassIds_h\n');
    e.Emit('\n');
    e.Emit('namespace WebCore {\n');
    e.Emit('\n');
    e.Emit('enum {\n');
    e.Emit('    _InvalidClassId = 0,\n');
    e.Emit('    _HistoryCrossFrameClassId,\n');
    e.Emit('    _LocationCrossFrameClassId,\n');
    e.Emit('    _DOMWindowCrossFrameClassId,\n');
    e.Emit('    _DateTimeClassId,\n');
    e.Emit('    _JsObjectClassId,\n');
    e.Emit('    _JsFunctionClassId,\n');
    e.Emit('    _JsArrayClassId,\n');
    e.Emit('    // New types that are not auto-generated should be added here.\n');
    e.Emit('\n');
    for interface in database.GetInterfaces():
      e.Emit('    %sClassId,\n' % interface.id)
    e.Emit('    NumWebkitClassIds\n');
    e.Emit('};\n');
    e.Emit('class ActiveDOMObject;\n'
           'class EventTarget;\n'
           'class Node;\n'
           'typedef ActiveDOMObject* (*ToActiveDOMObject)(void* value);\n'
           'typedef EventTarget* (*ToEventTarget)(void* value);\n'
           'typedef Node* (*ToNode)(void* value);\n'
           'typedef struct {\n'
           '    const char* class_name;\n'
           '    int library_id;\n'
           '    int base_class_id;\n'
           '    ToActiveDOMObject toActiveDOMObject;\n'
           '    ToEventTarget toEventTarget;\n'
           '    ToNode toNode;\n'
           '} DartWrapperTypeInfo;\n'
           'typedef DartWrapperTypeInfo _DartWebkitClassInfo[NumWebkitClassIds];\n'
           '\n'
           'extern _DartWebkitClassInfo DartWebkitClassInfo;\n'
           '\n'
           '} // namespace WebCore\n'
           '#endif // DartWebkitClassIds_h\n');

    path = os.path.join(output_dir, 'DartWebkitClassIds.cpp')
    e = self._emitters.FileEmitter(path)
    e.Emit('// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file\n');
    e.Emit('// for details. All rights reserved. Use of this source code is governed by a\n');
    e.Emit('// BSD-style license that can be found in the LICENSE file.\n');
    e.Emit('// WARNING: Do not edit - generated code.\n');
    e.Emit('// See dart/tools/dom/scripts/systemnative.py\n');
    e.Emit('\n');
    e.Emit('#include "config.h"\n');
    e.Emit('#include "DartWebkitClassIds.h"\n');
    e.Emit('\n');
    e.Emit('#include "bindings/dart/DartLibraryIds.h"\n');
    for interface in database.GetInterfaces():
      if HasConverters(interface):
        e.Emit('#include "Dart%s.h"\n' % interface.id);
    e.Emit('\n');

    e.Emit('namespace WebCore {\n');

    e.Emit('\n');

    e.Emit('ActiveDOMObject* toNullActiveDOMObject(void* value) { return 0; }\n');
    e.Emit('EventTarget* toNullEventTarget(void* value) { return 0; }\n');
    e.Emit('Node* toNullNode(void* value) { return 0; }\n');

    e.Emit("_DartWebkitClassInfo DartWebkitClassInfo = {\n")

    e.Emit('    {\n'
           '        "_InvalidClassId", -1, -1,\n'
           '        toNullActiveDOMObject, toNullEventTarget, toNullNode\n'
           '    },\n');
    e.Emit('    {\n'
           '        "_HistoryCrossFrame", DartHtmlLibraryId, -1,\n'
           '        toNullActiveDOMObject, toNullEventTarget, toNullNode\n'
           '    },\n');
    e.Emit('    {\n'
           '        "_LocationCrossFrame", DartHtmlLibraryId, -1,\n'
           '        toNullActiveDOMObject, toNullEventTarget, toNullNode\n'
           '    },\n');
    e.Emit('    {\n'
           '        "_DOMWindowCrossFrame", DartHtmlLibraryId, -1,\n'
           '        toNullActiveDOMObject, toNullEventTarget, toNullNode\n'
           '    },\n');
    e.Emit('    {\n'
           '        "DateTime", DartCoreLibraryId, -1,\n'
           '        toNullActiveDOMObject, toNullEventTarget, toNullNode\n'
           '    },\n');
    e.Emit('    {\n'
           '        "JsObject", DartJsLibraryId, -1,\n'
           '        toNullActiveDOMObject, toNullEventTarget, toNullNode\n'
           '    },\n');
    e.Emit('    {\n'
           '        "JsFunction", DartJsLibraryId, _JsObjectClassId,\n'
           '        toNullActiveDOMObject, toNullEventTarget, toNullNode\n'
           '    },\n');
    e.Emit('    {\n'
           '        "JsArray", DartJsLibraryId, _JsObjectClassId,\n'
           '        toNullActiveDOMObject, toNullEventTarget, toNullNode\n'
           '    },\n');
    e.Emit('    // New types that are not auto-generated should be added here.\n');
    for interface in database.GetInterfaces():
      name = interface.id
      type_info = type_registry.TypeInfo(name)
      type_info.native_type().replace('<', '_').replace('>', '_')
      e.Emit('    {\n')
      e.Emit('        "%s", ' % type_info.implementation_name())
      e.Emit('Dart%sLibraryId, ' % renamer.GetLibraryId(interface))
      if interface.parents:
        supertype = interface.parents[0].type.id
        e.Emit('%sClassId,\n' % supertype)
      else:
        e.Emit(' -1,\n')
      if HasConverters(interface):
        e.Emit('        Dart%s::toActiveDOMObject, Dart%s::toEventTarget,'
               ' Dart%s::toNode\n' % (name, name, name))
      else:
        e.Emit('        toNullActiveDOMObject, toNullEventTarget, toNullNode\n')
      e.Emit('    },\n')

    e.Emit("};\n");
    e.Emit('\n');
    e.Emit('} // namespace WebCore\n');

def _IsOptionalStringArgumentInInitEventMethod(interface, operation, argument):
  return (
      interface.id.endswith('Event') and
      operation.id.startswith('init') and
      argument.default_value == 'Undefined' and
      argument.type.id == 'DOMString')

def _IsCustom(op_or_attr):
  assert(isinstance(op_or_attr, IDLMember))
  return 'Custom' in op_or_attr.ext_attrs or 'DartCustom' in op_or_attr.ext_attrs

def _IsCustomValue(op_or_attr, value):
  if _IsCustom(op_or_attr):
    return op_or_attr.ext_attrs.get('Custom') == value \
           or op_or_attr.ext_attrs.get('DartCustom') == value
  return False
