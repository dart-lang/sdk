#!/usr/bin/python
# Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import json
import os.path
import re
import sys

_COMPAT_KEY = '__compat'
_EXPERIMENTAL_KEY = 'experimental'
_STATUS_KEY = 'status'
_SUPPORT_KEY = 'support'
_VERSION_ADDED_KEY = 'version_added'


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
                                _unify_metadata(browser_compat_data[interface],
                                                metadata)
                            else:
                                browser_compat_data[interface] = metadata
        else:
            names[:] = []  # Do not go underneath

    # Attempts to unify two compatibility infos by taking the union of both, and
    # for conflicting information, taking the "stricter" of the two versions.
    # Updates `a` in place to represent the union of `a` and `b`.
    def _unify_compat(a, b):

        def _has_compat_data(metadata):
            return _COMPAT_KEY in metadata and _SUPPORT_KEY in metadata[_COMPAT_KEY]

        # Unifies the support statements of both metadata and updates
        # `support_a` in place. If either metadata do not contain simple support
        # statements, defaults attribute to not supported.
        def _unify_support(support_a, support_b):
            for browser in support_a.keys():
                if browser in support_b:
                    if _is_simple_support_statement(support_a[browser]) and _is_simple_support_statement(support_b[browser]):
                        support_a[browser][_VERSION_ADDED_KEY] = _unify_versions(
                            support_a[browser][_VERSION_ADDED_KEY],
                            support_b[browser][_VERSION_ADDED_KEY])
                    else:
                        # Only support simple statements for now.
                        support_a[browser] = {_VERSION_ADDED_KEY: None}
            for browser in support_b.keys():
                if not browser in support_a:
                    support_a[browser] = support_b[browser]

        if not _has_compat_data(b):
            return
        if not _has_compat_data(a):
            a[_COMPAT_KEY] = b[_COMPAT_KEY]
            return

        support_a = a[_COMPAT_KEY][_SUPPORT_KEY]
        support_b = b[_COMPAT_KEY][_SUPPORT_KEY]

        _unify_support(support_a, support_b)

    # Unifies any status info in the two metadata. Modifies `a` in place to
    # represent the union of both `a` and `b`.
    def _unify_status(a, b):

        def _has_status(metadata):
            return _COMPAT_KEY in metadata and _STATUS_KEY in metadata[_COMPAT_KEY]

        # Modifies `status_a` in place to combine "experimental" tags.
        def _unify_experimental(status_a, status_b):
            # If either of the statuses report experimental, assume attribute is
            # experimental.
            status_a[_EXPERIMENTAL_KEY] = status_a.get(
                _EXPERIMENTAL_KEY, False) or status_b.get(_EXPERIMENTAL_KEY, False)

        if not _has_status(b):
            return
        if not _has_status(a):
            a[_COMPAT_KEY] = b[_COMPAT_KEY]
            return

        status_a = a[_COMPAT_KEY][_STATUS_KEY]
        status_b = b[_COMPAT_KEY][_STATUS_KEY]

        _unify_experimental(status_a, status_b)

    # If there exists multiple definitions of the same interface metadata e.g.
    # elements, this attempts to unify the compatibilities for the interface as
    # well as for each attribute.
    def _unify_metadata(a, b):
        # Unify the compatibility statement and status of the API or element.
        _unify_compat(a, b)
        _unify_status(a, b)
        # Unify the compatibility statement and status of each attribute.
        for attr in list(a.keys()):
            if attr == _COMPAT_KEY:
                continue
            if attr in b:
                _unify_compat(a[attr], b[attr])
                _unify_status(a[attr], b[attr])
        for attr in b.keys():
            if not attr in a:
                a[attr] = b[attr]

    os.path.walk(browser_compat_folder, visitor, browser_compat_folder)

    return browser_compat_data


# Given two version values for a given browser, chooses the more strict version.
def _unify_versions(version_a, version_b):
    # Given two valid version strings, compares parts of the version string
    # iteratively.
    def _greater_version(version_a, version_b):
        version_a_split = map(int, version_a.split('.'))
        version_b_split = map(int, version_b.split('.'))
        for i in range(min(len(version_a_split), len(version_b_split))):
            if version_a_split[i] > version_b_split[i]:
                return version_a
            elif version_a_split[i] < version_b_split[i]:
                return version_b
        return version_a if len(version_a_split) > len(
            version_b_split) else version_b

    # Validate that we can handle the given version.
    def _validate_version(version):
        if not version:
            return False
        if version is True:
            return True
        if isinstance(version, str) or isinstance(version, unicode):
            pattern = re.compile('^([0-9]+\.)*[0-9]+$')
            if not pattern.match(version):
                # It's possible for version strings to look like '<35'. We don't
                # attempt to parse the conditional logic, and just default to
                # potentially incompatible.
                return None
            return version
        else:
            raise ValueError(
                'Type of version_a was not handled correctly! type(version) = '
                + str(type(version)))

    version_a = _validate_version(version_a)
    version_b = _validate_version(version_b)
    # If one version reports not supported, default to not supported.
    if not version_a or not version_b:
        return False
    # If one version reports always supported, the other version can only be
    # more strict.
    if version_a is True:
        return version_b
    if version_b is True:
        return version_a

    return _greater_version(version_a, version_b)


# At this time, we only handle simple support statements due to the complexity
# and variability around support statements with multiple elements.
def _is_simple_support_statement(support_statement):
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
    return True


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
            'chrome': '63',
            'firefox': '57',
            'safari': '11',
            # We still support the latest version of IE.
            'ie': '11',
            'opera': '50',
        }
        for browser in browser_version_map.keys():
            support_data = compat_data[_SUPPORT_KEY]
            if browser not in support_data:
                return False
            support_statement = support_data[browser]
            if not _is_simple_support_statement(support_statement):
                return False
            version = support_statement[_VERSION_ADDED_KEY]
            # Compare version strings, target should be the more strict version.
            target = browser_version_map[browser]
            if _unify_versions(version, target) != target:
                return False

            # If the attribute is experimental, we assume it's not compatible.
            status_data = compat_data[_STATUS_KEY]
            if _EXPERIMENTAL_KEY in status_data and status_data[_EXPERIMENTAL_KEY]:
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
                return self._get_attr_compatibility(id_data[_COMPAT_KEY])
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
