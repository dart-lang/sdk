#!/usr/bin/python
# Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import json
import os.path
import sys


def _get_browser_compat_data():
    current_dir = os.path.dirname(__file__)

    browser_compat_folder = os.path.abspath(
        os.path.join(current_dir, '..', '..', '..', 'third_party', 'mdn',
                     'browser-compat-data', 'src'))

    if not os.path.exists(browser_compat_folder):
        raise RuntimeError('Browser compatibility data not found at %s' %
                           browser_compat_folder)

    browser_compat_data = {}

    INCLUDE_DIRS = [
        'api',
        'html',
        'svg',
        # TODO(srujzs): add more if needed
    ]

    # Transform to absolute paths
    INCLUDE_DIRS = [
        os.path.join(browser_compat_folder, dir) for dir in INCLUDE_DIRS
    ]

    def process_json_dict(json_dict):
        # Returns a tuple of the interface name and the metadata corresponding
        # to it.
        if 'api' in json_dict:
            # Get the interface name
            api_dict = json_dict['api']
            interface_name = api_dict.keys()[0]
            return (interface_name, api_dict[interface_name])
        elif 'html' in json_dict:
            html_dict = json_dict['html']
            if 'elements' in html_dict:
                elements_dict = html_dict['elements']
                element_name = elements_dict.keys()[0]
                # Convert to WebCore name
                interface = str('HTML' + element_name + 'Element')
                return (interface, elements_dict[element_name])
        elif 'svg' in json_dict:
            svg_dict = json_dict['svg']
            if 'elements' in svg_dict:
                elements_dict = svg_dict['elements']
                element_name = elements_dict.keys()[0]
                # Convert to WebCore name
                interface = str('SVG' + element_name + 'Element')
                return (interface, elements_dict[element_name])
        return (None, None)

    def visitor(arg, dir_path, names):

        def should_process_dir(dir_path):
            if os.path.abspath(dir_path) == browser_compat_folder:
                return True
            for dir in INCLUDE_DIRS:
                if dir_path.startswith(dir):
                    return True
            return False

        if should_process_dir(dir_path):
            for name in names:
                file_name = os.path.join(dir_path, name)
                (interface_path, ext) = os.path.splitext(file_name)
                if ext == '.json':
                    with open(file_name) as src:
                        json_dict = json.load(src)
                        interface, metadata = process_json_dict(json_dict)
                        if not interface is None:
                            # Note: interface and member names do not
                            # necessarily have the same capitalization as
                            # WebCore, so we keep them all lowercase for easier
                            # matching later.
                            interface = interface.lower()
                            metadata = {
                                member.lower(): info
                                for member, info in metadata.items()
                            }

                            if interface in browser_compat_data:
                                browser_compat_data[interface].update(metadata)
                            else:
                                browser_compat_data[interface] = metadata
        else:
            names[:] = []  # Do not go underneath

    os.path.walk(browser_compat_folder, visitor, browser_compat_folder)

    return browser_compat_data


class MDNReader(object):
    # Statically initialize and treat as constant.
    _BROWSER_COMPAT_DATA = _get_browser_compat_data()

    def __init__(self):
        self._compat_overrides = {}

    def _get_attr_compatibility(self, compat_data):
        # Parse schema syntax of MDN data:
        # https://github.com/mdn/browser-compat-data/blob/master/schemas/compat-data.schema.json

        # For now, we will require support for browsers since the last IDL roll.
        # TODO(srujzs): Determine if this is too conservative.
        browser_version_map = {
            'chrome': 63,
            'firefox': 57,
            'safari': 11,
            # We still support the latest version of IE.
            'ie': 11,
            'opera': 50,
        }
        version_key = 'version_added'
        for browser in browser_version_map.keys():
            support_data = compat_data['support']
            if browser not in support_data:
                return False
            support_statement = support_data[browser]
            if isinstance(support_statement, list):  # array_support_statement
                # TODO(srujzs): Parse this list to determine compatibility. Will
                # likely require parsing for 'version_removed' keys. Notes about
                # which browser version enabled this attribute for which
                # platform also complicates things. For now, we assume it's not
                # compatible.
                return False
            if len(support_statement.keys()) > 1:
                # If it's anything more complicated than 'version_added', like
                # 'notes' that specify platform versions, we assume it's not
                # compatible.
                return False
            version = support_statement[version_key]
            if not version or browser_version_map[browser] < float(version):
                # simple_support_statement
                return False
            # If the attribute is experimental, we assume it's not compatible.
            status_data = compat_data['status']
            experimental_key = 'experimental'
            if experimental_key in status_data and \
                status_data[experimental_key]:
                return False
        return True

    def is_compatible(self, attribute):
        # Since capitalization isn't consistent across MDN and WebCore, we
        # compare lowercase equivalents for interface and attribute names.
        interface = attribute.doc_js_interface_name.lower()
        if interface in self._BROWSER_COMPAT_DATA and attribute.id and len(
                attribute.id) > 0:
            interface_dict = self._BROWSER_COMPAT_DATA[interface]
            id_name = attribute.id.lower()
            secure_context_key = 'isSecureContext'
            if interface in self._compat_overrides and id_name in self._compat_overrides[
                    interface]:
                return self._compat_overrides[interface][id_name]
            elif secure_context_key in interface_dict:
                # If the interface requires a secure context, all attributes are
                # implicitly incompatible.
                return False
            elif id_name in interface_dict:
                id_data = interface_dict[id_name]
                return self._get_attr_compatibility(id_data['__compat'])
            else:
                # Might be an attribute that is defined in a parent interface.
                # We defer until attribute emitting to determine if this is the
                # case. Otherwise, return None.
                pass
        return None

    def set_compatible(self, attribute, compatible):
        # Override value in the MDN browser compatibility data.
        if not compatible in [True, False, None]:
            raise ValueError('Cannot set a non-boolean object for compatible')
        interface = attribute.doc_js_interface_name.lower()
        if not interface in self._compat_overrides:
            self._compat_overrides[interface] = {}
        if attribute.id and len(attribute.id) > 0:
            id_name = attribute.id.lower()
            self._compat_overrides[interface][id_name] = compatible
