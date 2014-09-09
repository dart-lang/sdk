#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module provides shared functionality to provide Dart metadata for
DOM APIs.
"""

import copy
import json
import logging
import monitored
import os
import re
from generator import ConstantOutputOrder
from htmlrenamer import renamed_html_members, html_interface_renames

_logger = logging.getLogger('dartmetadata')

# Annotations to be placed on native members.  The table is indexed by the IDL
# interface and member name, and by IDL return or field type name.  Both are
# used to assemble the annotations:
#
#   INTERFACE.MEMBER: annotations for member.
#   +TYPE:            add annotations only if there are member annotations.
#   -TYPE:            add annotations only if there are no member annotations.
#   TYPE:             add regardless of member annotations.

_dart2js_annotations = monitored.Dict('dartmetadata._dart2js_annotations', {

    'ArrayBufferView': [
      "@Creates('TypedData')",
      "@Returns('TypedData|Null')",
    ],

    'CanvasRenderingContext2D.createImageData': [
      "@Creates('ImageData|=Object')",
    ],

    'CanvasRenderingContext2D.getImageData': [
      "@Creates('ImageData|=Object')",
    ],

    'CanvasRenderingContext2D.webkitGetImageDataHD': [
      "@Creates('ImageData|=Object')",
    ],

    'CanvasRenderingContext2D.fillStyle': [
      "@Creates('String|CanvasGradient|CanvasPattern')",
      "@Returns('String|CanvasGradient|CanvasPattern')",
    ],

    'CanvasRenderingContext2D.strokeStyle': [
      "@Creates('String|CanvasGradient|CanvasPattern')",
      "@Returns('String|CanvasGradient|CanvasPattern')",
    ],

    'CustomEvent._detail': [
      "@Creates('Null')",
    ],

    # Normally Window is nevernull, but starting from a <template> element in
    # JavaScript, this will be null:
    #     template.content.ownerDocument.defaultView
    'Document.window': [
      "@Creates('Window|=Object|Null')",
      "@Returns('Window|=Object|Null')",
    ],

    'Document.getElementsByTagName': [
      "@Creates('NodeList|HtmlCollection')",
      "@Returns('NodeList|HtmlCollection')",
    ],

    'Document.getElementsByClassName': [
      "@Creates('NodeList|HtmlCollection')",
      "@Returns('NodeList|HtmlCollection')",
    ],

    # Methods returning Window can return a local window, or a cross-frame
    # window (=Object) that needs wrapping.
    'Window': [
      "@Creates('Window|=Object')",
      "@Returns('Window|=Object')",
    ],

    'Window.openDatabase': [
      "@Creates('SqlDatabase')",
    ],

    'Window.showModalDialog': [
      "@Creates('Null')",
    ],

    'Element.webkitGetRegionFlowRanges': [
      "@Creates('JSExtendableArray')",
      "@Returns('JSExtendableArray')",
    ],

    'Element.getElementsByTagName': [
      "@Creates('NodeList|HtmlCollection')",
      "@Returns('NodeList|HtmlCollection')",
    ],

    'Element.getElementsByClassName': [
      "@Creates('NodeList|HtmlCollection')",
      "@Returns('NodeList|HtmlCollection')",
    ],

    "ErrorEvent.error": [
      "@Creates('Null')", # Only returns values created elsewhere.
    ],

    # To be in callback with the browser-created Event, we had to have called
    # addEventListener on the target, so we avoid
    'Event.currentTarget': [
      "@Creates('Null')",
      "@Returns('EventTarget|=Object')",
    ],

    # Only nodes in the DOM bubble and have target !== currentTarget.
    'Event.target': [
      "@Creates('Node')",
      "@Returns('EventTarget|=Object')",
    ],

    'File.lastModifiedDate': [
      "@Creates('Null')", # JS date object.
    ],

    'FocusEvent.relatedTarget': [
      "@Creates('Null')",
    ],

    'HTMLInputElement.valueAsDate': [
      "@Creates('Null')", # JS date object.
    ],

    # Rather than have the result of an IDBRequest as a union over all possible
    # results, we mark the result as instantiating any classes, and mark
    # each operation with the classes that it could cause to be asynchronously
    # instantiated.
    'IDBRequest.result': ["@Creates('Null')"],

    # The source is usually a participant in the operation that generated the
    # IDBRequest.
    'IDBRequest.source':  ["@Creates('Null')"],

    'IDBFactory.open': ["@Creates('Database')"],
    'IDBFactory.webkitGetDatabaseNames': ["@Creates('DomStringList')"],

    'IDBObjectStore.put': ["@_annotation_Creates_IDBKey"],
    'IDBObjectStore.add': ["@_annotation_Creates_IDBKey"],
    'IDBObjectStore.get': ["@annotation_Creates_SerializedScriptValue"],
    'IDBObjectStore.openCursor': ["@Creates('Cursor')"],

    'IDBIndex.get': ["@annotation_Creates_SerializedScriptValue"],
    'IDBIndex.getKey': [
      "@annotation_Creates_SerializedScriptValue",
      # The source is the object store behind the index.
      "@Creates('ObjectStore')",
    ],
    'IDBIndex.openCursor': ["@Creates('Cursor')"],
    'IDBIndex.openKeyCursor': ["@Creates('Cursor')"],

    'IDBCursorWithValue.value': [
      '@annotation_Creates_SerializedScriptValue',
      '@annotation_Returns_SerializedScriptValue',
    ],

    'IDBCursor.key': [
      "@_annotation_Creates_IDBKey",
      "@_annotation_Returns_IDBKey",
    ],

    'IDBCursor.primaryKey': [
      "@_annotation_Creates_IDBKey",
      "@_annotation_Returns_IDBKey",
    ],

    'IDBCursor.source': [
      "@Creates('Null')",
      "@Returns('ObjectStore|Index|Null')",
    ],

    'IDBDatabase.version': [
      "@Creates('int|String|Null')",
      "@Returns('int|String|Null')",
    ],

    'IDBIndex.keyPath': [
      "@annotation_Creates_SerializedScriptValue",
    ],

    'IDBKeyRange.lower': [
      "@annotation_Creates_SerializedScriptValue",
    ],

    'IDBKeyRange.upper': [
      "@annotation_Creates_SerializedScriptValue",
    ],

    'IDBObjectStore.keyPath': [
      "@annotation_Creates_SerializedScriptValue",
    ],

    '+IDBOpenDBRequest': [
      "@Returns('Request')",
      "@Creates('Request')",
    ],

    '+IDBRequest': [
      "@Returns('Request')",
      "@Creates('Request')",
    ],

    'IDBVersionChangeEvent.newVersion': [
      "@Creates('int|String|Null')",
      "@Returns('int|String|Null')",
    ],

    'IDBVersionChangeEvent.oldVersion': [
      "@Creates('int|String|Null')",
      "@Returns('int|String|Null')",
    ],

    'ImageData.data': [
      "@Creates('NativeUint8ClampedList')",
      "@Returns('NativeUint8ClampedList')",
    ],

    'MediaStream.getAudioTracks': [
      "@Creates('JSExtendableArray')",
      "@Returns('JSExtendableArray')",
    ],

    'MediaStream.getVideoTracks': [
      "@Creates('JSExtendableArray')",
      "@Returns('JSExtendableArray')",
    ],

    'MessageEvent.data': [
      "@annotation_Creates_SerializedScriptValue",
      "@annotation_Returns_SerializedScriptValue",
    ],

    'MessageEvent.ports': ["@Creates('JSExtendableArray')"],

    'MessageEvent.source': [
      "@Creates('Null')",
      "@Returns('EventTarget|=Object')",
    ],

    'Metadata.modificationTime': [
      "@Creates('Null')", # JS date object.
    ],

    'MouseEvent.relatedTarget': [
      "@Creates('Node')",
      "@Returns('EventTarget|=Object')",
    ],

    'PopStateEvent.state': [
      "@annotation_Creates_SerializedScriptValue",
      "@annotation_Returns_SerializedScriptValue",
    ],

    'RTCStatsReport.timestamp': [
      "@Creates('Null')", # JS date object.
    ],

    'SerializedScriptValue': [
      "@annotation_Creates_SerializedScriptValue",
      "@annotation_Returns_SerializedScriptValue",
    ],

    'ShadowRoot.getElementsByTagName': [
      "@Creates('NodeList|HtmlCollection')",
      "@Returns('NodeList|HtmlCollection')",
    ],

    'ShadowRoot.getElementsByClassName': [
      "@Creates('NodeList|HtmlCollection')",
      "@Returns('NodeList|HtmlCollection')",
    ],

    'SQLResultSetRowList.item': ["@Creates('=Object')"],

    # Touch targets are Elements in a Document, or the Document.
    'Touch.target': [
      "@Creates('Element|Document')",
      "@Returns('Element|Document')",
    ],

    'TrackEvent.track': [
      "@Creates('Null')",
    ],

    'WebGLRenderingContext.getBufferParameter': [
      "@Creates('int|Null')",
      "@Returns('int|Null')",
    ],

    'WebGLRenderingContext.getFramebufferAttachmentParameter': [
      "@Creates('int|Renderbuffer|Texture|Null')",
      "@Returns('int|Renderbuffer|Texture|Null')",
    ],

    'WebGLRenderingContext.getProgramParameter': [
      "@Creates('int|bool|Null')",
      "@Returns('int|bool|Null')",
    ],

    'WebGLRenderingContext.getRenderbufferParameter': [
      "@Creates('int|Null')",
      "@Returns('int|Null')",
    ],

    'WebGLRenderingContext.getShaderParameter': [
      "@Creates('int|bool|Null')",
      "@Returns('int|bool|Null')",
    ],

    'WebGLRenderingContext.getTexParameter': [
      "@Creates('int|Null')",
      "@Returns('int|Null')",
    ],

    'WebGLRenderingContext.getUniform': [
      "@Creates('Null|num|String|bool|JSExtendableArray|"
                "NativeFloat32List|NativeInt32List|NativeUint32List')",
      "@Returns('Null|num|String|bool|JSExtendableArray|"
                "NativeFloat32List|NativeInt32List|NativeUint32List')",
    ],

    'WebGLRenderingContext.getVertexAttrib': [
      "@Creates('Null|num|bool|NativeFloat32List|Buffer')",
      "@Returns('Null|num|bool|NativeFloat32List|Buffer')",
    ],

    'WebGLRenderingContext.getParameter': [
      # Taken from http://www.khronos.org/registry/webgl/specs/latest/
      # Section 5.14.3 Setting and getting state
      "@Creates('Null|num|String|bool|JSExtendableArray|"
                "NativeFloat32List|NativeInt32List|NativeUint32List|"
                "Framebuffer|Renderbuffer|Texture')",
      "@Returns('Null|num|String|bool|JSExtendableArray|"
                "NativeFloat32List|NativeInt32List|NativeUint32List|"
                "Framebuffer|Renderbuffer|Texture')",
    ],

    'WebGLRenderingContext.getContextAttributes': [
      "@Creates('ContextAttributes|=Object')",
    ],

    'XMLHttpRequest.response': [
      "@Creates('NativeByteBuffer|Blob|Document|=Object|JSExtendableArray"
                "|String|num')",
    ],
}, dart2jsOnly=True)

_blink_experimental_annotations = [
  "@SupportedBrowser(SupportedBrowser.CHROME)",
  "@Experimental()",
]

_indexed_db_annotations = [
  "@SupportedBrowser(SupportedBrowser.CHROME)",
  "@SupportedBrowser(SupportedBrowser.FIREFOX, '15')",
  "@SupportedBrowser(SupportedBrowser.IE, '10')",
  "@Experimental()",
]

_file_system_annotations = [
  "@SupportedBrowser(SupportedBrowser.CHROME)",
  "@Experimental()",
]

_all_but_ie9_annotations = [
  "@SupportedBrowser(SupportedBrowser.CHROME)",
  "@SupportedBrowser(SupportedBrowser.FIREFOX)",
  "@SupportedBrowser(SupportedBrowser.IE, '10')",
  "@SupportedBrowser(SupportedBrowser.SAFARI)",
]

_history_annotations = _all_but_ie9_annotations

_no_ie_annotations = [
  "@SupportedBrowser(SupportedBrowser.CHROME)",
  "@SupportedBrowser(SupportedBrowser.FIREFOX)",
  "@SupportedBrowser(SupportedBrowser.SAFARI)",
]

_performance_annotations = [
  "@SupportedBrowser(SupportedBrowser.CHROME)",
  "@SupportedBrowser(SupportedBrowser.FIREFOX)",
  "@SupportedBrowser(SupportedBrowser.IE)",
]

_rtc_annotations = [ # Note: Firefox nightly builds also support this.
  "@SupportedBrowser(SupportedBrowser.CHROME)",
  "@Experimental()",
]

_shadow_dom_annotations = [
  "@SupportedBrowser(SupportedBrowser.CHROME, '26')",
  "@Experimental()",
]

_speech_recognition_annotations = [
  "@SupportedBrowser(SupportedBrowser.CHROME, '25')",
  "@Experimental()",
]

_svg_annotations = _all_but_ie9_annotations;

_web_sql_annotations = [
  "@SupportedBrowser(SupportedBrowser.CHROME)",
  "@SupportedBrowser(SupportedBrowser.SAFARI)",
  "@Experimental()",
]

_webgl_annotations = [
  "@SupportedBrowser(SupportedBrowser.CHROME)",
  "@SupportedBrowser(SupportedBrowser.FIREFOX)",
  "@Experimental()",
]

_web_audio_annotations = _webgl_annotations

_webkit_experimental_annotations = [
  "@SupportedBrowser(SupportedBrowser.CHROME)",
  "@SupportedBrowser(SupportedBrowser.SAFARI)",
  "@Experimental()",
]

# Annotations to be placed on generated members.
# The table is indexed as:
#   INTERFACE:     annotations to be added to the interface declaration
#   INTERFACE.MEMBER: annotation to be added to the member declaration
_annotations = monitored.Dict('dartmetadata._annotations', {
  'CSSHostRule': _shadow_dom_annotations,
  'WebKitCSSMatrix': _webkit_experimental_annotations,
  'Crypto': _webkit_experimental_annotations,
  'Database': _web_sql_annotations,
  'DatabaseSync': _web_sql_annotations,
  'ApplicationCache': [
    "@SupportedBrowser(SupportedBrowser.CHROME)",
    "@SupportedBrowser(SupportedBrowser.FIREFOX)",
    "@SupportedBrowser(SupportedBrowser.IE, '10')",
    "@SupportedBrowser(SupportedBrowser.OPERA)",
    "@SupportedBrowser(SupportedBrowser.SAFARI)",
  ],
  'AudioBufferSourceNode': _web_audio_annotations,
  'AudioContext': _web_audio_annotations,
  'DOMFileSystem': _file_system_annotations,
  'DOMFileSystemSync': _file_system_annotations,
  'WebKitPoint': _webkit_experimental_annotations,
  'Window.webkitConvertPointFromNodeToPage': _webkit_experimental_annotations,
  'Window.webkitConvertPointFromPageToNode': _webkit_experimental_annotations,
  'Window.indexedDB': _indexed_db_annotations,
  'Window.openDatabase': _web_sql_annotations,
  'Window.performance': _performance_annotations,
  'Window.webkitNotifications': _webkit_experimental_annotations,
  'Window.webkitRequestFileSystem': _file_system_annotations,
  'Window.webkitResolveLocalFileSystemURL': _file_system_annotations,
  'Element.createShadowRoot': [
    "@SupportedBrowser(SupportedBrowser.CHROME, '25')",
    "@Experimental()",
  ],
  'Element.ontransitionend': _all_but_ie9_annotations,
  # Placeholder to add experimental flag, implementation for this is
  # pending in a separate CL.
  'Element.webkitMatchesSelector': ['@Experimental()'],
  'Event.clipboardData': [
    "@SupportedBrowser(SupportedBrowser.CHROME)",
    "@SupportedBrowser(SupportedBrowser.FIREFOX)",
    "@SupportedBrowser(SupportedBrowser.SAFARI)",
    "@Experimental()",
  ],
  'FormData': _all_but_ie9_annotations,
  'HashChangeEvent': [
    "@SupportedBrowser(SupportedBrowser.CHROME)",
    "@SupportedBrowser(SupportedBrowser.FIREFOX)",
    "@SupportedBrowser(SupportedBrowser.SAFARI)",
  ],
  'History.pushState': _history_annotations,
  'History.replaceState': _history_annotations,
  'HTMLContentElement': _shadow_dom_annotations,
  'HTMLDataListElement': _all_but_ie9_annotations,
  'HTMLDetailsElement': _webkit_experimental_annotations,
  'HTMLEmbedElement': [
    "@SupportedBrowser(SupportedBrowser.CHROME)",
    "@SupportedBrowser(SupportedBrowser.IE)",
    "@SupportedBrowser(SupportedBrowser.SAFARI)",
  ],
  'HTMLKeygenElement': _webkit_experimental_annotations,
  'HTMLMeterElement': _no_ie_annotations,
  'HTMLObjectElement': [
    "@SupportedBrowser(SupportedBrowser.CHROME)",
    "@SupportedBrowser(SupportedBrowser.IE)",
    "@SupportedBrowser(SupportedBrowser.SAFARI)",
  ],
  'HTMLOutputElement': _no_ie_annotations,
  'HTMLProgressElement': _all_but_ie9_annotations,
  'HTMLShadowElement': _shadow_dom_annotations,
  'HTMLTemplateElement': _blink_experimental_annotations,
  'HTMLTrackElement': [
    "@SupportedBrowser(SupportedBrowser.CHROME)",
    "@SupportedBrowser(SupportedBrowser.IE, '10')",
    "@SupportedBrowser(SupportedBrowser.SAFARI)",
  ],
  'IDBFactory': _indexed_db_annotations,
  'IDBDatabase': _indexed_db_annotations,
  'MediaStream': _rtc_annotations,
  'MediaStreamEvent': _rtc_annotations,
  'MediaStreamTrack': _rtc_annotations,
  'MediaStreamTrackEvent': _rtc_annotations,
  'MutationObserver': [
    "@SupportedBrowser(SupportedBrowser.CHROME)",
    "@SupportedBrowser(SupportedBrowser.FIREFOX)",
    "@SupportedBrowser(SupportedBrowser.SAFARI)",
    "@Experimental()",
  ],
  'NotificationCenter': _webkit_experimental_annotations,
  'Performance': _performance_annotations,
  'PopStateEvent': _history_annotations,
  'RTCIceCandidate': _rtc_annotations,
  'RTCPeerConnection': _rtc_annotations,
  'RTCSessionDescription': _rtc_annotations,
  'ShadowRoot': _shadow_dom_annotations,
  'SpeechRecognition': _speech_recognition_annotations,
  'SpeechRecognitionAlternative': _speech_recognition_annotations,
  'SpeechRecognitionError': _speech_recognition_annotations,
  'SpeechRecognitionEvent': _speech_recognition_annotations,
  'SpeechRecognitionResult': _speech_recognition_annotations,
  'SVGAltGlyphElement': _no_ie_annotations,
  'SVGAnimateElement': _no_ie_annotations,
  'SVGAnimateMotionElement': _no_ie_annotations,
  'SVGAnimateTransformElement': _no_ie_annotations,
  'SVGFEBlendElement': _svg_annotations,
  'SVGFEColorMatrixElement': _svg_annotations,
  'SVGFEComponentTransferElement': _svg_annotations,
  'SVGFEConvolveMatrixElement': _svg_annotations,
  'SVGFEDiffuseLightingElement': _svg_annotations,
  'SVGFEDisplacementMapElement': _svg_annotations,
  'SVGFEDistantLightElement': _svg_annotations,
  'SVGFEFloodElement': _svg_annotations,
  'SVGFEFuncAElement': _svg_annotations,
  'SVGFEFuncBElement': _svg_annotations,
  'SVGFEFuncGElement': _svg_annotations,
  'SVGFEFuncRElement': _svg_annotations,
  'SVGFEGaussianBlurElement': _svg_annotations,
  'SVGFEImageElement': _svg_annotations,
  'SVGFEMergeElement': _svg_annotations,
  'SVGFEMergeNodeElement': _svg_annotations,
  'SVGFEMorphologyElement': _svg_annotations,
  'SVGFEOffsetElement': _svg_annotations,
  'SVGFEPointLightElement': _svg_annotations,
  'SVGFESpecularLightingElement': _svg_annotations,
  'SVGFESpotLightElement': _svg_annotations,
  'SVGFETileElement': _svg_annotations,
  'SVGFETurbulenceElement': _svg_annotations,
  'SVGFilterElement': _svg_annotations,
  'SVGForeignObjectElement': _no_ie_annotations,
  'SVGSetElement': _no_ie_annotations,
  'SQLTransaction': _web_sql_annotations,
  'SQLTransactionSync': _web_sql_annotations,
  'WebGLRenderingContext': _webgl_annotations,
  'WebSocket': _all_but_ie9_annotations,
  'Worker': _all_but_ie9_annotations,
  'XMLHttpRequest.overrideMimeType': _no_ie_annotations,
  'XMLHttpRequest.response': _all_but_ie9_annotations,
  'XMLHttpRequestEventTarget.onloadend': _all_but_ie9_annotations,
  'XMLHttpRequestEventTarget.onprogress': _all_but_ie9_annotations,
  'XSLTProcessor': [
    "@SupportedBrowser(SupportedBrowser.CHROME)",
    "@SupportedBrowser(SupportedBrowser.FIREFOX)",
    "@SupportedBrowser(SupportedBrowser.SAFARI)",
  ],
})

# TODO(blois): minimize noise and enable by default.
_monitor_type_metadata = False

class DartMetadata(object):
  def __init__(self, api_status_path, doc_comments_path,
               logging_level=logging.WARNING):
    _logger.setLevel(logging_level)
    self._api_status_path = api_status_path
    status_file = open(self._api_status_path, 'r+')
    self._types = json.load(status_file)
    status_file.close()

    comments_file = open(doc_comments_path, 'r+')
    self._doc_comments = json.load(comments_file)
    comments_file.close()

    if _monitor_type_metadata:
      monitored_interfaces = {}
      for interface_id, interface_data in self._types.iteritems():
        monitored_interface = interface_data.copy()
        monitored_interface['members'] = monitored.Dict(
            'dartmetadata.%s' % interface_id, interface_data['members'])

        monitored_interfaces[interface_id] = monitored_interface

      self._monitored_types = monitored.Dict('dartmetadata._monitored_types',
          monitored_interfaces)
    else:
      self._monitored_types = self._types

  def GetFormattedMetadata(self, library_name, interface, member_id=None,
      indentation=''):
    """ Gets all comments and annotations for an interface or member.
    """
    return self.FormatMetadata(
        self.GetMetadata(library_name, interface, member_id),
        indentation)

  def GetMetadata(self, library_name, interface,
        member_name=None, source_member_name=None):
    """ Gets all comments and annotations for an interface or member.

    Args:
      source_member_name: If the member is dependent on a different member
        then this is used to apply the support annotations from the other
        member.
    """
    annotations = self._GetComments(library_name, interface, member_name)
    annotations = annotations + self._GetCommonAnnotations(
        interface, member_name, source_member_name)

    return annotations

  def GetDart2JSMetadata(self, idl_type, library_name,
      interface, member_name,):
    """ Gets all annotations for Dart2JS members- including annotations for
    both dart2js and dartium.
    """
    annotations = self.GetMetadata(library_name, interface, member_name)

    ann2 = self._GetDart2JSSpecificAnnotations(idl_type, interface.id, member_name)
    if ann2:
      if annotations:
        annotations.extend(ann2)
      else:
        annotations = ann2
    return annotations

  def IsSuppressed(self, interface, member_name):
    annotations = self._GetSupportLevelAnnotations(interface.id, member_name)
    return any(
        annotation.startswith('@removed') for annotation in annotations)

  def _GetCommonAnnotations(self, interface, member_name=None,
      source_member_name=None):
    if member_name:
      key = '%s.%s' % (interface.id, member_name)
      dom_name = '%s.%s' % (interface.javascript_binding_name, member_name)
    else:
      key = interface.id
      dom_name = interface.javascript_binding_name

    annotations = ["@DomName('" + dom_name + "')"]

    # Only add this for members, so we don't add DocsEditable to templated
    # classes (they get it from the default class template)
    if member_name:
      annotations.append('@DocsEditable()');

    if key in _annotations:
      annotations.extend(_annotations[key])

    if (not member_name and
        interface.javascript_binding_name.startswith('WebKit') and
        interface.id not in html_interface_renames):
      annotations.extend(_webkit_experimental_annotations)

    if (member_name and member_name.startswith('webkit') and
        key not in renamed_html_members):
      annotations.extend(_webkit_experimental_annotations)

    if source_member_name:
      member_name = source_member_name

    support_annotations = self._GetSupportLevelAnnotations(
        interface.id, member_name)

    for annotation in support_annotations:
      if annotation not in annotations:
        annotations.append(annotation)

    return annotations

  def _GetComments(self, library_name, interface, member_name=None):
    """ Gets all comments for the interface or member and returns a list. """

    # Add documentation from JSON.
    comments = []
    library_name = 'dart.dom.%s' % library_name
    if library_name in self._doc_comments:
      library_info = self._doc_comments[library_name]
      if interface.id in library_info:
        interface_info = library_info[interface.id]
        if member_name:
          if 'members' in interface_info and member_name in interface_info['members']:
            comments = interface_info['members'][member_name]
        elif 'comment' in interface_info:
          comments = interface_info['comment']

    if comments:
      comments = ['\n'.join(comments)]

    return comments


  def AnyConversionAnnotations(self, idl_type, interface_name, member_name):
    if (_annotations.get('%s.%s' % (interface_name, member_name)) or
        self._GetDart2JSSpecificAnnotations(idl_type, interface_name, member_name)):
      return True
    else:
      return False

  def FormatMetadata(self, metadata, indentation):
    if metadata:
      newline = '\n%s' % indentation
      result = newline.join(metadata) + newline
      return result
    return ''

  def _GetDart2JSSpecificAnnotations(self, idl_type, interface_name, member_name):
    """ Finds dart2js-specific annotations. This does not include ones shared with
    dartium.
    """
    ann1 = _dart2js_annotations.get("%s.%s" % (interface_name, member_name))
    if ann1:
      ann2 = _dart2js_annotations.get('+' + idl_type)
      if ann2:
        return ann2 + ann1
      ann2 = _dart2js_annotations.get(idl_type)
      if ann2:
        return ann2 + ann1
      return ann1

    ann2 = _dart2js_annotations.get('-' + idl_type)
    if ann2:
      return ann2
    ann2 = _dart2js_annotations.get(idl_type)
    return ann2

  def _GetSupportInfo(self, interface_id, member_id=None):
    """ Looks up the interface or member in the DOM status list and returns the
    support level for it.
    """
    if interface_id in self._monitored_types:
      type_info = self._monitored_types[interface_id]
    else:
      type_info = {
        'members': {},
        'support_level': 'untriaged',
      }
      self._types[interface_id] = type_info

    if not member_id:
      return type_info

    members = type_info['members']

    if member_id in members:
      member_info = members[member_id]
    else:
      if member_id == interface_id:
        member_info = {}
      else:
        member_info = {'support_level': 'untriaged'}
      members[member_id] = member_info

    return member_info

  def _GetSupportLevelAnnotations(self, interface_id, member_id=None):
    """ Gets annotations for API support status.
    """
    support_info = self._GetSupportInfo(interface_id, member_id)

    dart_action = support_info.get('dart_action')
    support_level = support_info.get('support_level')
    comment = support_info.get('comment')
    annotations = []
    # TODO(blois): should add an annotation for the comment, but keeping out
    # to keep the initial diff a bit more localized.
    #if comment:
    #  annotations.append('// %s' % comment)

    if dart_action:
      if dart_action == 'unstable':
        annotations.append('@Unstable()')
      elif dart_action == 'experimental':
        if comment:
          annotations.append('// %s' % comment)
        annotations.append('@Experimental() // %s' % support_level)
      elif dart_action == 'suppress':
        if comment:
          annotations.append('// %s' % comment)
        anAnnotation = 'deprecated'
        if member_id:
          anAnnotation = 'removed'
        annotations.append('@%s // %s' % (anAnnotation, support_level))
        pass
      elif dart_action == 'stable':
        pass
      else:
        _logger.warn('Unknown dart_action - %s:%s' % (interface_id, member_id))
    elif support_level == 'untriaged':
      annotations.append('@Experimental() // untriaged')
    elif support_level == 'experimental':
      if comment:
        annotations.append('// %s' % comment)
      annotations.append('@Experimental()')
    elif support_level == 'nonstandard':
      if comment:
        annotations.append('// %s' % comment)
      annotations.append('@Experimental() // non-standard')
    elif support_level == 'stable':
      pass
    elif support_level == 'deprecated':
      if comment:
        annotations.append('// %s' % comment)
      annotations.append('@deprecated')
    elif support_level is None:
      pass
    else:
      _logger.warn('Unknown support_level - %s:%s' % (interface_id, member_id))

    return annotations

  def Flush(self):
    json_file = open(self._api_status_path, 'w+')
    json.dump(self._types, json_file, indent=2, separators=(',', ': '), sort_keys=True)
    json_file.close()
