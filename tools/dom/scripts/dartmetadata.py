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
from htmlrenamer import renamed_html_members

_logger = logging.getLogger('DartMetadata')

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

    # Methods returning Window can return a local window, or a cross-frame
    # window (=Object) that needs wrapping.
    'DOMWindow': [
      "@Creates('Window|=Object')",
      "@Returns('Window|=Object')",
    ],

    'DOMWindow.openDatabase': [
      "@Creates('SqlDatabase')",
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

    'MouseEvent.relatedTarget': [
      "@Creates('Node')",
      "@Returns('EventTarget|=Object')",
    ],

    # Touch targets are Elements in a Document, or the Document.
    'Touch.target': [
      "@Creates('Element|Document')",
      "@Returns('Element|Document')",
    ],

    'FileReader.result': ["@Creates('String|ByteBuffer|Null')"],

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

    '+IDBRequest': [
      "@Returns('Request')",
      "@Creates('Request')",
    ],

    '+IDBOpenDBRequest': [
      "@Returns('Request')",
      "@Creates('Request')",
    ],

    'MessageEvent.ports': ["@Creates('=List')"],

    'MessageEvent.data': [
      "@annotation_Creates_SerializedScriptValue",
      "@annotation_Returns_SerializedScriptValue",
    ],
    'PopStateEvent.state': [
      "@annotation_Creates_SerializedScriptValue",
      "@annotation_Returns_SerializedScriptValue",
    ],
    'SerializedScriptValue': [
      "@annotation_Creates_SerializedScriptValue",
      "@annotation_Returns_SerializedScriptValue",
    ],

    'SQLResultSetRowList.item': ["@Creates('=Object')"],

    'WebGLRenderingContext.getParameter': [
      # Taken from http://www.khronos.org/registry/webgl/specs/latest/
      # Section 5.14.3 Setting and getting state
      "@Creates('Null|num|String|bool|=List|Float32List|Int32List|Uint32List"
                "|Framebuffer|Renderbuffer|Texture')",
      "@Returns('Null|num|String|bool|=List|Float32List|Int32List|Uint32List"
                "|Framebuffer|Renderbuffer|Texture')",
    ],

    'XMLHttpRequest.response': [
      "@Creates('ByteBuffer|Blob|Document|=Object|=List|String|num')",
    ],
}, dart2jsOnly=True)

_indexed_db_annotations = [
  "@SupportedBrowser(SupportedBrowser.CHROME)",
  "@SupportedBrowser(SupportedBrowser.FIREFOX, '15')",
  "@SupportedBrowser(SupportedBrowser.IE, '10')",
  "@Experimental",
]

_file_system_annotations = [
  "@SupportedBrowser(SupportedBrowser.CHROME)",
  "@Experimental",
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
  "@Experimental",
]

_shadow_dom_annotations = [
  "@SupportedBrowser(SupportedBrowser.CHROME, '26')",
  "@Experimental",
]

_speech_recognition_annotations = [
  "@SupportedBrowser(SupportedBrowser.CHROME, '25')",
  "@Experimental",
]

_svg_annotations = _all_but_ie9_annotations;

_web_sql_annotations = [
  "@SupportedBrowser(SupportedBrowser.CHROME)",
  "@SupportedBrowser(SupportedBrowser.SAFARI)",
  "@Experimental",
]

_webgl_annotations = [
  "@SupportedBrowser(SupportedBrowser.CHROME)",
  "@SupportedBrowser(SupportedBrowser.FIREFOX)",
  "@Experimental",
]

_webkit_experimental_annotations = [
  "@SupportedBrowser(SupportedBrowser.CHROME)",
  "@SupportedBrowser(SupportedBrowser.SAFARI)",
  "@Experimental",
]

# Annotations to be placed on generated members.
# The table is indexed as:
#   INTERFACE:     annotations to be added to the interface declaration
#   INTERFACE.MEMBER: annotation to be added to the member declaration
_annotations = monitored.Dict('dartmetadata._annotations', {
  'CSSHostRule': _shadow_dom_annotations,
  'Crypto': _webkit_experimental_annotations,
  'Database': _web_sql_annotations,
  'DatabaseSync': _web_sql_annotations,
  'DOMApplicationCache': [
    "@SupportedBrowser(SupportedBrowser.CHROME)",
    "@SupportedBrowser(SupportedBrowser.FIREFOX)",
    "@SupportedBrowser(SupportedBrowser.IE, '10')",
    "@SupportedBrowser(SupportedBrowser.OPERA)",
    "@SupportedBrowser(SupportedBrowser.SAFARI)",
  ],
  'DOMFileSystem': _file_system_annotations,
  'DOMFileSystemSync': _file_system_annotations,
  'DOMWindow.webkitConvertPointFromNodeToPage': _webkit_experimental_annotations,
  'DOMWindow.webkitConvertPointFromPageToNode': _webkit_experimental_annotations,
  'DOMWindow.indexedDB': _indexed_db_annotations,
  'DOMWindow.openDatabase': _web_sql_annotations,
  'DOMWindow.performance': _performance_annotations,
  'DOMWindow.webkitNotifications': _webkit_experimental_annotations,
  'DOMWindow.webkitRequestFileSystem': _file_system_annotations,
  'DOMWindow.webkitResolveLocalFileSystemURL': _file_system_annotations,
  'Element.onwebkitTransitionEnd': _all_but_ie9_annotations,
  # Placeholder to add experimental flag, implementation for this is
  # pending in a separate CL.
  'Element.webkitMatchesSelector': ['@Experimental()'],
  'Element.webkitCreateShadowRoot': [
    "@SupportedBrowser(SupportedBrowser.CHROME, '25')",
    "@Experimental",
  ],
  'Event.clipboardData': _webkit_experimental_annotations,
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
  'HTMLTrackElement': [
    "@SupportedBrowser(SupportedBrowser.CHROME)",
    "@SupportedBrowser(SupportedBrowser.IE, '10')",
    "@SupportedBrowser(SupportedBrowser.SAFARI)",
  ],
  'IDBFactory': _indexed_db_annotations,
  'IDBDatabase': _indexed_db_annotations,
  'LocalMediaStream': _rtc_annotations,
  'MediaStream': _rtc_annotations,
  'MediaStreamEvent': _rtc_annotations,
  'MediaStreamTrack': _rtc_annotations,
  'MediaStreamTrackEvent': _rtc_annotations,
  'MutationObserver': [
    "@SupportedBrowser(SupportedBrowser.CHROME)",
    "@SupportedBrowser(SupportedBrowser.FIREFOX)",
    "@SupportedBrowser(SupportedBrowser.SAFARI)",
    "@Experimental",
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
  'WebKitCSSMatrix': _webkit_experimental_annotations,
  'WebKitPoint': _webkit_experimental_annotations,
  'WebSocket': _all_but_ie9_annotations,
  'Worker': _all_but_ie9_annotations,
  'XMLHttpRequest.onloadend': _all_but_ie9_annotations,
  'XMLHttpRequest.onprogress': _all_but_ie9_annotations,
  'XMLHttpRequest.response': _all_but_ie9_annotations,
  'XMLHttpRequestProgressEvent': _webkit_experimental_annotations,
  'XSLTProcessor': [
    "@SupportedBrowser(SupportedBrowser.CHROME)",
    "@SupportedBrowser(SupportedBrowser.FIREFOX)",
    "@SupportedBrowser(SupportedBrowser.SAFARI)",
  ],
})


class DartMetadata(object):
  def __init__(self, api_status_path, doc_comments_path):
    self._api_status_path = api_status_path
    status_file = open(self._api_status_path, 'r+')
    self._types = json.load(status_file)
    status_file.close()

    comments_file = open(doc_comments_path, 'r+')
    self._doc_comments = json.load(comments_file)
    comments_file.close()

  def GetFormattedMetadata(self, library_name, interface_name, member_id=None,
      indentation=''):
    """ Gets all comments and annotations for an interface or member.
    """
    return self.FormatMetadata(
        self.GetMetadata(library_name, interface_name, member_id),
        indentation)

  def GetMetadata(self, library_name, interface_name,
        member_name=None, source_member_name=None):
    """ Gets all comments and annotations for an interface or member.

    Args:
      source_member_name: If the member is dependent on a different member
        then this is used to apply the support annotations from the other
        member.
    """
    annotations = self._GetComments(library_name, interface_name, member_name)
    annotations = annotations + self._GetCommonAnnotations(
        interface_name, member_name, source_member_name)

    return annotations

  def GetDart2JSMetadata(self, idl_type, library_name,
      interface_name, member_name,):
    """ Gets all annotations for Dart2JS members- including annotations for
    both dart2js and dartium.
    """
    annotations = self.GetMetadata(library_name, interface_name, member_name)

    ann2 = self._GetDart2JSSpecificAnnotations(idl_type, interface_name, member_name)
    if ann2:
      if annotations:
        annotations.extend(ann2)
      else:
        annotations = ann2
    return annotations

  def _GetCommonAnnotations(self, interface_name, member_name=None,
      source_member_name=None):
    if member_name:
      key = '%s.%s' % (interface_name, member_name)
    else:
      key = interface_name

    annotations = ["@DomName('" + key + "')"]

    # Only add this for members, so we don't add DocsEditable to templated
    # classes (they get it from the default class template)
    if member_name:
      annotations.append('@DocsEditable');

    if key in _annotations:
      annotations.extend(_annotations[key])

    if (member_name and member_name.startswith('webkit') and
        key not in renamed_html_members):
      annotations.extend(_webkit_experimental_annotations)

    if source_member_name:
      member_name = source_member_name

    # TODO(blois): Emit support level annotations
    self._GetSupportLevelAnnotation(interface_name, member_name)

    return annotations

  def _GetComments(self, library_name, interface_name, member_name=None):
    """ Gets all comments for the interface or member and returns a list. """

    # Add documentation from JSON.
    comments = []
    library_name = 'dart.dom.%s' % library_name
    if library_name in self._doc_comments:
      library_info = self._doc_comments[library_name]
      if interface_name in library_info:
        interface_info = library_info[interface_name]
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

  def _GetSupportLevel(self, interface_id, member_id=None):
    """ Looks up the interface or member in the DOM status list and returns the
    support level for it.
    """
    if interface_id in self._types:
      type_info = self._types[interface_id]
    else:
      type_info = {
        'members': {},
        'support_level': 'untriaged',
      }
      self._types[interface_id] = type_info

    if not member_id:
      return type_info.get('support_level')

    members = type_info['members']

    if member_id in members:
      member_info = members[member_id]
    else:
      if member_id == interface_id:
        member_info = {}
      else:
        member_info = {'support_level': 'untriaged'}
      members[member_id] = member_info

    support_level = member_info.get('support_level')
    # If unset then it inherits from the type.
    if not support_level:
      support_level = type_info.get('support_level')
    return support_level

  def _GetSupportLevelAnnotation(self, interface_id, member_id=None):
    support_level = self._GetSupportLevel(interface_id, member_id)

    if support_level == 'untriaged':
      return '@Experimental'
    elif support_level == 'experimental':
      return '@Experimental'
    elif support_level == 'nonstandard':
      return '@Experimental'
    elif support_level == 'stable':
      return
    elif support_level == 'deprecated':
      return '@Deprecated'
    else:
      _logger.warn('Unknown support_level - %s:%s' % (interface.id, member_id))

  def Flush(self):
    json_file = open(self._api_status_path, 'w+')
    json.dump(self._types, json_file, indent=2, separators=(',', ': '), sort_keys=True)
    json_file.close()
