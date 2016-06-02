# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# This file has been automatically generated.  Please do not edit it manually.
# To regenerate the file, use the script
# "pkg/analysis_server/tool/spec/generate_files".

import json
from .core import *


def decode_union(data, discriminator, choices):
    return choices[data[discriminator]]

# server.getVersion params
#
# Clients may not extend, implement or mix-in this class.
class ServerGetVersionParams(object):
    def to_request(self, id):
        return Request(id, "server.getVersion", None)

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# server.getVersion result
#
# {
#   "version": String
# }
#
# Clients may not extend, implement or mix-in this class.
class ServerGetVersionResult(HasToJson):

    def __init__(self, version):
        self._version = version
    # The version number of the analysis server.
    @property
    def version(self):
        return self._version
    # The version number of the analysis server.
    @version.setter
    def version(self, value):
        assert value is not None
        self._version = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            version = None
            if "version" in json_data:
                version = (json_data["version"])
            else:
                raise Exception('missing key: "version"')
            return ServerGetVersionResult(version)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_response(response):
        return ServerGetVersionResult.from_json(response._result)

    def to_json(self):
        result = {}
        result["version"] = self.version
        return result

    def to_response(self, id):
        return Response(id, result=self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass
# server.shutdown params
#
# Clients may not extend, implement or mix-in this class.
class ServerShutdownParams(object):
    def to_request(self, id):
        return Request(id, "server.shutdown", None)

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass
# server.shutdown result
#
# Clients may not extend, implement or mix-in this class.
class ServerShutdownResult(object):
    def to_response(self, id):
        return Response(id, result=None)

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# server.setSubscriptions params
#
# {
#   "subscriptions": List<ServerService>
# }
#
# Clients may not extend, implement or mix-in this class.
class ServerSetSubscriptionsParams(HasToJson):

    def __init__(self, subscriptions):
        self._subscriptions = subscriptions
    # A list of the services being subscribed to.
    @property
    def subscriptions(self):
        return self._subscriptions
    # A list of the services being subscribed to.
    @subscriptions.setter
    def subscriptions(self, value):
        assert value is not None
        self._subscriptions = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            subscriptions = None
            if "subscriptions" in json_data:
                subscriptions = json_data["subscriptions"]
            else:
                raise Exception('missing key: "subscriptions"')
            return ServerSetSubscriptionsParams(subscriptions)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return ServerSetSubscriptionsParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["subscriptions"] = self.subscriptions
        return result

    def to_request(self, id):
        return Request(id, "server.setSubscriptions", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass
# server.setSubscriptions result
#
# Clients may not extend, implement or mix-in this class.
class ServerSetSubscriptionsResult(object):
    def to_response(self, id):
        return Response(id, result=None)

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# server.connected params
#
# {
#   "version": String
# }
#
# Clients may not extend, implement or mix-in this class.
class ServerConnectedParams(HasToJson):

    def __init__(self, version):
        self._version = version
    # The version number of the analysis server.
    @property
    def version(self):
        return self._version
    # The version number of the analysis server.
    @version.setter
    def version(self, value):
        assert value is not None
        self._version = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            version = None
            if "version" in json_data:
                version = (json_data["version"])
            else:
                raise Exception('missing key: "version"')
            return ServerConnectedParams(version)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_notification(notification):
        return ServerConnectedParams.from_json(notification._params)

    def to_json(self):
        result = {}
        result["version"] = self.version
        return result

    def to_notification(self):
        return Notification("server.connected", self.to_json());

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# server.error params
#
# {
#   "isFatal": bool
#   "message": String
#   "stackTrace": String
# }
#
# Clients may not extend, implement or mix-in this class.
class ServerErrorParams(HasToJson):

    def __init__(self, isFatal, message, stackTrace):
        self._isFatal = isFatal
        self._message = message
        self._stackTrace = stackTrace
    # True if the error is a fatal error, meaning that the server will shutdown
    # automatically after sending this notification.
    @property
    def isFatal(self):
        return self._isFatal
    # True if the error is a fatal error, meaning that the server will shutdown
    # automatically after sending this notification.
    @isFatal.setter
    def isFatal(self, value):
        assert value is not None
        self._isFatal = value

    # The error message indicating what kind of error was encountered.
    @property
    def message(self):
        return self._message
    # The error message indicating what kind of error was encountered.
    @message.setter
    def message(self, value):
        assert value is not None
        self._message = value

    # The stack trace associated with the generation of the error, used for
    # debugging the server.
    @property
    def stackTrace(self):
        return self._stackTrace
    # The stack trace associated with the generation of the error, used for
    # debugging the server.
    @stackTrace.setter
    def stackTrace(self, value):
        assert value is not None
        self._stackTrace = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            isFatal = None
            if "isFatal" in json_data:
                isFatal = (json_data["isFatal"])
            else:
                raise Exception('missing key: "isFatal"')
            message = None
            if "message" in json_data:
                message = (json_data["message"])
            else:
                raise Exception('missing key: "message"')
            stackTrace = None
            if "stackTrace" in json_data:
                stackTrace = (json_data["stackTrace"])
            else:
                raise Exception('missing key: "stackTrace"')
            return ServerErrorParams(isFatal, message, stackTrace)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_notification(notification):
        return ServerErrorParams.from_json(notification._params)

    def to_json(self):
        result = {}
        result["isFatal"] = self.isFatal
        result["message"] = self.message
        result["stackTrace"] = self.stackTrace
        return result

    def to_notification(self):
        return Notification("server.error", self.to_json());

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# server.status params
#
# {
#   "analysis": optional AnalysisStatus
#   "pub": optional PubStatus
# }
#
# Clients may not extend, implement or mix-in this class.
class ServerStatusParams(HasToJson):

    def __init__(self, analysis=None, pub=None):
        self._analysis = analysis
        self._pub = pub
    # The current status of analysis, including whether analysis is being
    # performed and if so what is being analyzed.
    @property
    def analysis(self):
        return self._analysis
    # The current status of analysis, including whether analysis is being
    # performed and if so what is being analyzed.
    @analysis.setter
    def analysis(self, value):
        self._analysis = value

    # The current status of pub execution, indicating whether we are currently
    # running pub.
    @property
    def pub(self):
        return self._pub
    # The current status of pub execution, indicating whether we are currently
    # running pub.
    @pub.setter
    def pub(self, value):
        self._pub = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            analysis = None
            if "analysis" in json_data:
                analysis = AnalysisStatus.from_json(json_data["analysis"])

            pub = None
            if "pub" in json_data:
                pub = PubStatus.from_json(json_data["pub"])

            return ServerStatusParams(analysis=analysis, pub=pub)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_notification(notification):
        return ServerStatusParams.from_json(notification._params)

    def to_json(self):
        result = {}
        if self.analysis is not None:
            result["analysis"] = analysis.to_json()
        if self.pub is not None:
            result["pub"] = pub.to_json()
        return result

    def to_notification(self):
        return Notification("server.status", self.to_json());

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.getErrors params
#
# {
#   "file": FilePath
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisGetErrorsParams(HasToJson):

    def __init__(self, file):
        self._file = file
    # The file for which errors are being requested.
    @property
    def file(self):
        return self._file
    # The file for which errors are being requested.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            return AnalysisGetErrorsParams(file)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return AnalysisGetErrorsParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["file"] = self.file
        return result

    def to_request(self, id):
        return Request(id, "analysis.getErrors", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.getErrors result
#
# {
#   "errors": List<AnalysisError>
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisGetErrorsResult(HasToJson):

    def __init__(self, errors):
        self._errors = errors
    # The errors associated with the file.
    @property
    def errors(self):
        return self._errors
    # The errors associated with the file.
    @errors.setter
    def errors(self, value):
        assert value is not None
        self._errors = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            errors = None
            if "errors" in json_data:
                errors = [AnalysisError.from_json(item) for item in json_data["errors"]]
            else:
                raise Exception('missing key: "errors"')
            return AnalysisGetErrorsResult(errors)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_response(response):
        return AnalysisGetErrorsResult.from_json(response._result)

    def to_json(self):
        result = {}
        result["errors"] = [x.to_json() for x in self.errors]
        return result

    def to_response(self, id):
        return Response(id, result=self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.getHover params
#
# {
#   "file": FilePath
#   "offset": int
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisGetHoverParams(HasToJson):

    def __init__(self, file, offset):
        self._file = file
        self._offset = offset
    # The file in which hover information is being requested.
    @property
    def file(self):
        return self._file
    # The file in which hover information is being requested.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    # The offset for which hover information is being requested.
    @property
    def offset(self):
        return self._offset
    # The offset for which hover information is being requested.
    @offset.setter
    def offset(self, value):
        assert value is not None
        self._offset = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            offset = None
            if "offset" in json_data:
                offset = (json_data["offset"])
            else:
                raise Exception('missing key: "offset"')
            return AnalysisGetHoverParams(file, offset)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return AnalysisGetHoverParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["file"] = self.file
        result["offset"] = self.offset
        return result

    def to_request(self, id):
        return Request(id, "analysis.getHover", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.getHover result
#
# {
#   "hovers": List<HoverInformation>
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisGetHoverResult(HasToJson):

    def __init__(self, hovers):
        self._hovers = hovers
    # The hover information associated with the location. The list will be
    # empty if no information could be determined for the location. The list
    # can contain multiple items if the file is being analyzed in multiple
    # contexts in conflicting ways (such as a part that is included in multiple
    # libraries).
    @property
    def hovers(self):
        return self._hovers
    # The hover information associated with the location. The list will be
    # empty if no information could be determined for the location. The list
    # can contain multiple items if the file is being analyzed in multiple
    # contexts in conflicting ways (such as a part that is included in multiple
    # libraries).
    @hovers.setter
    def hovers(self, value):
        assert value is not None
        self._hovers = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            hovers = None
            if "hovers" in json_data:
                hovers = [HoverInformation.from_json(item) for item in json_data["hovers"]]
            else:
                raise Exception('missing key: "hovers"')
            return AnalysisGetHoverResult(hovers)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_response(response):
        return AnalysisGetHoverResult.from_json(response._result)

    def to_json(self):
        result = {}
        result["hovers"] = [x.to_json() for x in self.hovers]
        return result

    def to_response(self, id):
        return Response(id, result=self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.getReachableSources params
#
# {
#   "file": FilePath
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisGetReachableSourcesParams(HasToJson):

    def __init__(self, file):
        self._file = file
    # The file for which reachable source information is being requested.
    @property
    def file(self):
        return self._file
    # The file for which reachable source information is being requested.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            return AnalysisGetReachableSourcesParams(file)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return AnalysisGetReachableSourcesParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["file"] = self.file
        return result

    def to_request(self, id):
        return Request(id, "analysis.getReachableSources", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.getReachableSources result
#
# {
#   "sources": Map<String, List<String>>
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisGetReachableSourcesResult(HasToJson):

    def __init__(self, sources):
        self._sources = sources
    # A mapping from source URIs to directly reachable source URIs. For
    # example, a file "foo.dart" that imports "bar.dart" would have the
    # corresponding mapping { "file:///foo.dart" : ["file:///bar.dart"] }. If
    # "bar.dart" has further imports (or exports) there will be a mapping from
    # the URI "file:///bar.dart" to them. To check if a specific URI is
    # reachable from a given file, clients can check for its presence in the
    # resulting key set.
    @property
    def sources(self):
        return self._sources
    # A mapping from source URIs to directly reachable source URIs. For
    # example, a file "foo.dart" that imports "bar.dart" would have the
    # corresponding mapping { "file:///foo.dart" : ["file:///bar.dart"] }. If
    # "bar.dart" has further imports (or exports) there will be a mapping from
    # the URI "file:///bar.dart" to them. To check if a specific URI is
    # reachable from a given file, clients can check for its presence in the
    # resulting key set.
    @sources.setter
    def sources(self, value):
        assert value is not None
        self._sources = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            sources = None
            if "sources" in json_data:
                sources = { k: [(item) for item in v] for k, v in json_data["sources"].items() }
            else:
                raise Exception('missing key: "sources"')
            return AnalysisGetReachableSourcesResult(sources)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_response(response):
        return AnalysisGetReachableSourcesResult.from_json(response._result)

    def to_json(self):
        result = {}
        result["sources"] = self.sources
        return result

    def to_response(self, id):
        return Response(id, result=self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass
# analysis.getLibraryDependencies params
#
# Clients may not extend, implement or mix-in this class.
class AnalysisGetLibraryDependenciesParams(object):
    def to_request(self, id):
        return Request(id, "analysis.getLibraryDependencies", None)

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.getLibraryDependencies result
#
# {
#   "libraries": List<FilePath>
#   "packageMap": Map<String, Map<String, List<FilePath>>>
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisGetLibraryDependenciesResult(HasToJson):

    def __init__(self, libraries, packageMap):
        self._libraries = libraries
        self._packageMap = packageMap
    # A list of the paths of library elements referenced by files in existing
    # analysis roots.
    @property
    def libraries(self):
        return self._libraries
    # A list of the paths of library elements referenced by files in existing
    # analysis roots.
    @libraries.setter
    def libraries(self, value):
        assert value is not None
        self._libraries = value

    # A mapping from context source roots to package maps which map package
    # names to source directories for use in client-side package URI
    # resolution.
    @property
    def packageMap(self):
        return self._packageMap
    # A mapping from context source roots to package maps which map package
    # names to source directories for use in client-side package URI
    # resolution.
    @packageMap.setter
    def packageMap(self, value):
        assert value is not None
        self._packageMap = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            libraries = None
            if "libraries" in json_data:
                libraries = [(item) for item in json_data["libraries"]]
            else:
                raise Exception('missing key: "libraries"')
            packageMap = None
            if "packageMap" in json_data:
                packageMap = { k: { k: [(item) for item in v] for k, v in v.items() } for k, v in json_data["packageMap"].items() }
            else:
                raise Exception('missing key: "packageMap"')
            return AnalysisGetLibraryDependenciesResult(libraries, packageMap)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_response(response):
        return AnalysisGetLibraryDependenciesResult.from_json(response._result)

    def to_json(self):
        result = {}
        result["libraries"] = self.libraries
        result["packageMap"] = self.packageMap
        return result

    def to_response(self, id):
        return Response(id, result=self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.getNavigation params
#
# {
#   "file": FilePath
#   "offset": int
#   "length": int
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisGetNavigationParams(HasToJson):

    def __init__(self, file, offset, length):
        self._file = file
        self._offset = offset
        self._length = length
    # The file in which navigation information is being requested.
    @property
    def file(self):
        return self._file
    # The file in which navigation information is being requested.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    # The offset of the region for which navigation information is being
    # requested.
    @property
    def offset(self):
        return self._offset
    # The offset of the region for which navigation information is being
    # requested.
    @offset.setter
    def offset(self, value):
        assert value is not None
        self._offset = value

    # The length of the region for which navigation information is being
    # requested.
    @property
    def length(self):
        return self._length
    # The length of the region for which navigation information is being
    # requested.
    @length.setter
    def length(self, value):
        assert value is not None
        self._length = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            offset = None
            if "offset" in json_data:
                offset = (json_data["offset"])
            else:
                raise Exception('missing key: "offset"')
            length = None
            if "length" in json_data:
                length = (json_data["length"])
            else:
                raise Exception('missing key: "length"')
            return AnalysisGetNavigationParams(file, offset, length)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return AnalysisGetNavigationParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["file"] = self.file
        result["offset"] = self.offset
        result["length"] = self.length
        return result

    def to_request(self, id):
        return Request(id, "analysis.getNavigation", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.getNavigation result
#
# {
#   "files": List<FilePath>
#   "targets": List<NavigationTarget>
#   "regions": List<NavigationRegion>
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisGetNavigationResult(HasToJson):

    def __init__(self, files, targets, regions):
        self._files = files
        self._targets = targets
        self._regions = regions
    # A list of the paths of files that are referenced by the navigation
    # targets.
    @property
    def files(self):
        return self._files
    # A list of the paths of files that are referenced by the navigation
    # targets.
    @files.setter
    def files(self, value):
        assert value is not None
        self._files = value

    # A list of the navigation targets that are referenced by the navigation
    # regions.
    @property
    def targets(self):
        return self._targets
    # A list of the navigation targets that are referenced by the navigation
    # regions.
    @targets.setter
    def targets(self, value):
        assert value is not None
        self._targets = value

    # A list of the navigation regions within the requested region of the file.
    @property
    def regions(self):
        return self._regions
    # A list of the navigation regions within the requested region of the file.
    @regions.setter
    def regions(self, value):
        assert value is not None
        self._regions = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            files = None
            if "files" in json_data:
                files = [(item) for item in json_data["files"]]
            else:
                raise Exception('missing key: "files"')
            targets = None
            if "targets" in json_data:
                targets = [NavigationTarget.from_json(item) for item in json_data["targets"]]
            else:
                raise Exception('missing key: "targets"')
            regions = None
            if "regions" in json_data:
                regions = [NavigationRegion.from_json(item) for item in json_data["regions"]]
            else:
                raise Exception('missing key: "regions"')
            return AnalysisGetNavigationResult(files, targets, regions)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_response(response):
        return AnalysisGetNavigationResult.from_json(response._result)

    def to_json(self):
        result = {}
        result["files"] = self.files
        result["targets"] = [x.to_json() for x in self.targets]
        result["regions"] = [x.to_json() for x in self.regions]
        return result

    def to_response(self, id):
        return Response(id, result=self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.reanalyze params
#
# {
#   "roots": optional List<FilePath>
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisReanalyzeParams(HasToJson):

    def __init__(self, roots=None):
        self._roots = roots
    # A list of the analysis roots that are to be re-analyzed.
    @property
    def roots(self):
        return self._roots
    # A list of the analysis roots that are to be re-analyzed.
    @roots.setter
    def roots(self, value):
        self._roots = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            roots = None
            if "roots" in json_data:
                roots = [(item) for item in json_data["roots"]]

            return AnalysisReanalyzeParams(roots=roots)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return AnalysisReanalyzeParams.from_json(request._params)

    def to_json(self):
        result = {}
        if self.roots is not None:
            result["roots"] = self.roots
        return result

    def to_request(self, id):
        return Request(id, "analysis.reanalyze", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass
# analysis.reanalyze result
#
# Clients may not extend, implement or mix-in this class.
class AnalysisReanalyzeResult(object):
    def to_response(self, id):
        return Response(id, result=None)

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.setAnalysisRoots params
#
# {
#   "included": List<FilePath>
#   "excluded": List<FilePath>
#   "packageRoots": optional Map<FilePath, FilePath>
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisSetAnalysisRootsParams(HasToJson):

    def __init__(self, included, excluded, packageRoots=None):
        self._included = included
        self._excluded = excluded
        self._packageRoots = packageRoots
    # A list of the files and directories that should be analyzed.
    @property
    def included(self):
        return self._included
    # A list of the files and directories that should be analyzed.
    @included.setter
    def included(self, value):
        assert value is not None
        self._included = value

    # A list of the files and directories within the included directories that
    # should not be analyzed.
    @property
    def excluded(self):
        return self._excluded
    # A list of the files and directories within the included directories that
    # should not be analyzed.
    @excluded.setter
    def excluded(self, value):
        assert value is not None
        self._excluded = value

    # A mapping from source directories to package roots that should override
    # the normal package: URI resolution mechanism.
    #
    # If a package root is a directory, then the analyzer will behave as though
    # the associated source directory in the map contains a special
    # pubspec.yaml file which resolves any package: URI to the corresponding
    # path within that package root directory. The effect is the same as
    # specifying the package root directory as a "--package_root" parameter to
    # the Dart VM when executing any Dart file inside the source directory.
    #
    # If a package root is a file, then the analyzer will behave as though that
    # file is a ".packages" file in the source directory. The effect is the
    # same as specifying the file as a "--packages" parameter to the Dart VM
    # when executing any Dart file inside the source directory.
    #
    # Files in any directories that are not overridden by this mapping have
    # their package: URI's resolved using the normal pubspec.yaml mechanism. If
    # this field is absent, or the empty map is specified, that indicates that
    # the normal pubspec.yaml mechanism should always be used.
    @property
    def packageRoots(self):
        return self._packageRoots
    # A mapping from source directories to package roots that should override
    # the normal package: URI resolution mechanism.
    #
    # If a package root is a directory, then the analyzer will behave as though
    # the associated source directory in the map contains a special
    # pubspec.yaml file which resolves any package: URI to the corresponding
    # path within that package root directory. The effect is the same as
    # specifying the package root directory as a "--package_root" parameter to
    # the Dart VM when executing any Dart file inside the source directory.
    #
    # If a package root is a file, then the analyzer will behave as though that
    # file is a ".packages" file in the source directory. The effect is the
    # same as specifying the file as a "--packages" parameter to the Dart VM
    # when executing any Dart file inside the source directory.
    #
    # Files in any directories that are not overridden by this mapping have
    # their package: URI's resolved using the normal pubspec.yaml mechanism. If
    # this field is absent, or the empty map is specified, that indicates that
    # the normal pubspec.yaml mechanism should always be used.
    @packageRoots.setter
    def packageRoots(self, value):
        self._packageRoots = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            included = None
            if "included" in json_data:
                included = [(item) for item in json_data["included"]]
            else:
                raise Exception('missing key: "included"')
            excluded = None
            if "excluded" in json_data:
                excluded = [(item) for item in json_data["excluded"]]
            else:
                raise Exception('missing key: "excluded"')
            packageRoots = None
            if "packageRoots" in json_data:
                packageRoots = { k: (v) for k, v in json_data["packageRoots"].items() }

            return AnalysisSetAnalysisRootsParams(included, excluded, packageRoots=packageRoots)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return AnalysisSetAnalysisRootsParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["included"] = self.included
        result["excluded"] = self.excluded
        if self.packageRoots is not None:
            result["packageRoots"] = self.packageRoots
        return result

    def to_request(self, id):
        return Request(id, "analysis.setAnalysisRoots", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass
# analysis.setAnalysisRoots result
#
# Clients may not extend, implement or mix-in this class.
class AnalysisSetAnalysisRootsResult(object):
    def to_response(self, id):
        return Response(id, result=None)

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.setGeneralSubscriptions params
#
# {
#   "subscriptions": List<GeneralAnalysisService>
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisSetGeneralSubscriptionsParams(HasToJson):

    def __init__(self, subscriptions):
        self._subscriptions = subscriptions
    # A list of the services being subscribed to.
    @property
    def subscriptions(self):
        return self._subscriptions
    # A list of the services being subscribed to.
    @subscriptions.setter
    def subscriptions(self, value):
        assert value is not None
        self._subscriptions = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            subscriptions = None
            if "subscriptions" in json_data:
                subscriptions = json_data["subscriptions"]
            else:
                raise Exception('missing key: "subscriptions"')
            return AnalysisSetGeneralSubscriptionsParams(subscriptions)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return AnalysisSetGeneralSubscriptionsParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["subscriptions"] = self.subscriptions
        return result

    def to_request(self, id):
        return Request(id, "analysis.setGeneralSubscriptions", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass
# analysis.setGeneralSubscriptions result
#
# Clients may not extend, implement or mix-in this class.
class AnalysisSetGeneralSubscriptionsResult(object):
    def to_response(self, id):
        return Response(id, result=None)

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.setPriorityFiles params
#
# {
#   "files": List<FilePath>
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisSetPriorityFilesParams(HasToJson):

    def __init__(self, files):
        self._files = files
    # The files that are to be a priority for analysis.
    @property
    def files(self):
        return self._files
    # The files that are to be a priority for analysis.
    @files.setter
    def files(self, value):
        assert value is not None
        self._files = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            files = None
            if "files" in json_data:
                files = [(item) for item in json_data["files"]]
            else:
                raise Exception('missing key: "files"')
            return AnalysisSetPriorityFilesParams(files)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return AnalysisSetPriorityFilesParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["files"] = self.files
        return result

    def to_request(self, id):
        return Request(id, "analysis.setPriorityFiles", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass
# analysis.setPriorityFiles result
#
# Clients may not extend, implement or mix-in this class.
class AnalysisSetPriorityFilesResult(object):
    def to_response(self, id):
        return Response(id, result=None)

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.setSubscriptions params
#
# {
#   "subscriptions": Map<AnalysisService, List<FilePath>>
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisSetSubscriptionsParams(HasToJson):

    def __init__(self, subscriptions):
        self._subscriptions = subscriptions
    # A table mapping services to a list of the files being subscribed to the
    # service.
    @property
    def subscriptions(self):
        return self._subscriptions
    # A table mapping services to a list of the files being subscribed to the
    # service.
    @subscriptions.setter
    def subscriptions(self, value):
        assert value is not None
        self._subscriptions = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            subscriptions = None
            if "subscriptions" in json_data:
                subscriptions = { k: [(item) for item in v] for k, v in json_data["subscriptions"].items() }
            else:
                raise Exception('missing key: "subscriptions"')
            return AnalysisSetSubscriptionsParams(subscriptions)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return AnalysisSetSubscriptionsParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["subscriptions"] = { k: v for k, v in self.subscriptions }
        return result

    def to_request(self, id):
        return Request(id, "analysis.setSubscriptions", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass
# analysis.setSubscriptions result
#
# Clients may not extend, implement or mix-in this class.
class AnalysisSetSubscriptionsResult(object):
    def to_response(self, id):
        return Response(id, result=None)

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.updateContent params
#
# {
#   "files": Map<FilePath, AddContentOverlay | ChangeContentOverlay | RemoveContentOverlay>
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisUpdateContentParams(HasToJson):

    def __init__(self, files):
        self._files = files
    # A table mapping the files whose content has changed to a description of
    # the content change.
    @property
    def files(self):
        return self._files
    # A table mapping the files whose content has changed to a description of
    # the content change.
    @files.setter
    def files(self, value):
        assert value is not None
        self._files = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            files = None
            if "files" in json_data:
                files = { k: decode_union(v, "type", {"add": lambda json: AddContentOverlay.from_json(json), "change": lambda json: ChangeContentOverlay.from_json(json), "remove": lambda json: RemoveContentOverlay.from_json(json)})  for k, v in json_data["files"].items() }
            else:
                raise Exception('missing key: "files"')
            return AnalysisUpdateContentParams(files)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return AnalysisUpdateContentParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["files"] = { k: v.to_json() for k, v in self.files }
        return result

    def to_request(self, id):
        return Request(id, "analysis.updateContent", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.updateContent result
#
# {
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisUpdateContentResult(HasToJson):

    def __init__(self):
        pass

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            return AnalysisUpdateContentResult()
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_response(response):
        return AnalysisUpdateContentResult.from_json(response._result)

    def to_json(self):
        result = {}
        return result

    def to_response(self, id):
        return Response(id, result=self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.updateOptions params
#
# {
#   "options": AnalysisOptions
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisUpdateOptionsParams(HasToJson):

    def __init__(self, options):
        self._options = options
    # The options that are to be used to control analysis.
    @property
    def options(self):
        return self._options
    # The options that are to be used to control analysis.
    @options.setter
    def options(self, value):
        assert value is not None
        self._options = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            options = None
            if "options" in json_data:
                options = AnalysisOptions.from_json(json_data["options"])
            else:
                raise Exception('missing key: "options"')
            return AnalysisUpdateOptionsParams(options)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return AnalysisUpdateOptionsParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["options"] = options.to_json()
        return result

    def to_request(self, id):
        return Request(id, "analysis.updateOptions", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass
# analysis.updateOptions result
#
# Clients may not extend, implement or mix-in this class.
class AnalysisUpdateOptionsResult(object):
    def to_response(self, id):
        return Response(id, result=None)

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.analyzedFiles params
#
# {
#   "directories": List<FilePath>
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisAnalyzedFilesParams(HasToJson):

    def __init__(self, directories):
        self._directories = directories
    # A list of the paths of the files that are being analyzed.
    @property
    def directories(self):
        return self._directories
    # A list of the paths of the files that are being analyzed.
    @directories.setter
    def directories(self, value):
        assert value is not None
        self._directories = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            directories = None
            if "directories" in json_data:
                directories = [(item) for item in json_data["directories"]]
            else:
                raise Exception('missing key: "directories"')
            return AnalysisAnalyzedFilesParams(directories)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_notification(notification):
        return AnalysisAnalyzedFilesParams.from_json(notification._params)

    def to_json(self):
        result = {}
        result["directories"] = self.directories
        return result

    def to_notification(self):
        return Notification("analysis.analyzedFiles", self.to_json());

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.errors params
#
# {
#   "file": FilePath
#   "errors": List<AnalysisError>
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisErrorsParams(HasToJson):

    def __init__(self, file, errors):
        self._file = file
        self._errors = errors
    # The file containing the errors.
    @property
    def file(self):
        return self._file
    # The file containing the errors.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    # The errors contained in the file.
    @property
    def errors(self):
        return self._errors
    # The errors contained in the file.
    @errors.setter
    def errors(self, value):
        assert value is not None
        self._errors = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            errors = None
            if "errors" in json_data:
                errors = [AnalysisError.from_json(item) for item in json_data["errors"]]
            else:
                raise Exception('missing key: "errors"')
            return AnalysisErrorsParams(file, errors)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_notification(notification):
        return AnalysisErrorsParams.from_json(notification._params)

    def to_json(self):
        result = {}
        result["file"] = self.file
        result["errors"] = [x.to_json() for x in self.errors]
        return result

    def to_notification(self):
        return Notification("analysis.errors", self.to_json());

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.flushResults params
#
# {
#   "files": List<FilePath>
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisFlushResultsParams(HasToJson):

    def __init__(self, files):
        self._files = files
    # The files that are no longer being analyzed.
    @property
    def files(self):
        return self._files
    # The files that are no longer being analyzed.
    @files.setter
    def files(self, value):
        assert value is not None
        self._files = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            files = None
            if "files" in json_data:
                files = [(item) for item in json_data["files"]]
            else:
                raise Exception('missing key: "files"')
            return AnalysisFlushResultsParams(files)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_notification(notification):
        return AnalysisFlushResultsParams.from_json(notification._params)

    def to_json(self):
        result = {}
        result["files"] = self.files
        return result

    def to_notification(self):
        return Notification("analysis.flushResults", self.to_json());

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.folding params
#
# {
#   "file": FilePath
#   "regions": List<FoldingRegion>
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisFoldingParams(HasToJson):

    def __init__(self, file, regions):
        self._file = file
        self._regions = regions
    # The file containing the folding regions.
    @property
    def file(self):
        return self._file
    # The file containing the folding regions.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    # The folding regions contained in the file.
    @property
    def regions(self):
        return self._regions
    # The folding regions contained in the file.
    @regions.setter
    def regions(self, value):
        assert value is not None
        self._regions = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            regions = None
            if "regions" in json_data:
                regions = [FoldingRegion.from_json(item) for item in json_data["regions"]]
            else:
                raise Exception('missing key: "regions"')
            return AnalysisFoldingParams(file, regions)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_notification(notification):
        return AnalysisFoldingParams.from_json(notification._params)

    def to_json(self):
        result = {}
        result["file"] = self.file
        result["regions"] = [x.to_json() for x in self.regions]
        return result

    def to_notification(self):
        return Notification("analysis.folding", self.to_json());

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.highlights params
#
# {
#   "file": FilePath
#   "regions": List<HighlightRegion>
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisHighlightsParams(HasToJson):

    def __init__(self, file, regions):
        self._file = file
        self._regions = regions
    # The file containing the highlight regions.
    @property
    def file(self):
        return self._file
    # The file containing the highlight regions.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    # The highlight regions contained in the file. Each highlight region
    # represents a particular syntactic or semantic meaning associated with
    # some range. Note that the highlight regions that are returned can overlap
    # other highlight regions if there is more than one meaning associated with
    # a particular region.
    @property
    def regions(self):
        return self._regions
    # The highlight regions contained in the file. Each highlight region
    # represents a particular syntactic or semantic meaning associated with
    # some range. Note that the highlight regions that are returned can overlap
    # other highlight regions if there is more than one meaning associated with
    # a particular region.
    @regions.setter
    def regions(self, value):
        assert value is not None
        self._regions = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            regions = None
            if "regions" in json_data:
                regions = [HighlightRegion.from_json(item) for item in json_data["regions"]]
            else:
                raise Exception('missing key: "regions"')
            return AnalysisHighlightsParams(file, regions)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_notification(notification):
        return AnalysisHighlightsParams.from_json(notification._params)

    def to_json(self):
        result = {}
        result["file"] = self.file
        result["regions"] = [x.to_json() for x in self.regions]
        return result

    def to_notification(self):
        return Notification("analysis.highlights", self.to_json());

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.implemented params
#
# {
#   "file": FilePath
#   "classes": List<ImplementedClass>
#   "members": List<ImplementedMember>
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisImplementedParams(HasToJson):

    def __init__(self, file, classes, members):
        self._file = file
        self._classes = classes
        self._members = members
    # The file with which the implementations are associated.
    @property
    def file(self):
        return self._file
    # The file with which the implementations are associated.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    # The classes defined in the file that are implemented or extended.
    @property
    def classes(self):
        return self._classes
    # The classes defined in the file that are implemented or extended.
    @classes.setter
    def classes(self, value):
        assert value is not None
        self._classes = value

    # The member defined in the file that are implemented or overridden.
    @property
    def members(self):
        return self._members
    # The member defined in the file that are implemented or overridden.
    @members.setter
    def members(self, value):
        assert value is not None
        self._members = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            classes = None
            if "classes" in json_data:
                classes = [ImplementedClass.from_json(item) for item in json_data["classes"]]
            else:
                raise Exception('missing key: "classes"')
            members = None
            if "members" in json_data:
                members = [ImplementedMember.from_json(item) for item in json_data["members"]]
            else:
                raise Exception('missing key: "members"')
            return AnalysisImplementedParams(file, classes, members)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_notification(notification):
        return AnalysisImplementedParams.from_json(notification._params)

    def to_json(self):
        result = {}
        result["file"] = self.file
        result["classes"] = [x.to_json() for x in self.classes]
        result["members"] = [x.to_json() for x in self.members]
        return result

    def to_notification(self):
        return Notification("analysis.implemented", self.to_json());

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.invalidate params
#
# {
#   "file": FilePath
#   "offset": int
#   "length": int
#   "delta": int
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisInvalidateParams(HasToJson):

    def __init__(self, file, offset, length, delta):
        self._file = file
        self._offset = offset
        self._length = length
        self._delta = delta
    # The file whose information has been invalidated.
    @property
    def file(self):
        return self._file
    # The file whose information has been invalidated.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    # The offset of the invalidated region.
    @property
    def offset(self):
        return self._offset
    # The offset of the invalidated region.
    @offset.setter
    def offset(self, value):
        assert value is not None
        self._offset = value

    # The length of the invalidated region.
    @property
    def length(self):
        return self._length
    # The length of the invalidated region.
    @length.setter
    def length(self, value):
        assert value is not None
        self._length = value

    # The delta to be applied to the offsets in information that follows the
    # invalidated region in order to update it so that it doesn't need to be
    # re-requested.
    @property
    def delta(self):
        return self._delta
    # The delta to be applied to the offsets in information that follows the
    # invalidated region in order to update it so that it doesn't need to be
    # re-requested.
    @delta.setter
    def delta(self, value):
        assert value is not None
        self._delta = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            offset = None
            if "offset" in json_data:
                offset = (json_data["offset"])
            else:
                raise Exception('missing key: "offset"')
            length = None
            if "length" in json_data:
                length = (json_data["length"])
            else:
                raise Exception('missing key: "length"')
            delta = None
            if "delta" in json_data:
                delta = (json_data["delta"])
            else:
                raise Exception('missing key: "delta"')
            return AnalysisInvalidateParams(file, offset, length, delta)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_notification(notification):
        return AnalysisInvalidateParams.from_json(notification._params)

    def to_json(self):
        result = {}
        result["file"] = self.file
        result["offset"] = self.offset
        result["length"] = self.length
        result["delta"] = self.delta
        return result

    def to_notification(self):
        return Notification("analysis.invalidate", self.to_json());

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.navigation params
#
# {
#   "file": FilePath
#   "regions": List<NavigationRegion>
#   "targets": List<NavigationTarget>
#   "files": List<FilePath>
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisNavigationParams(HasToJson):

    def __init__(self, file, regions, targets, files):
        self._file = file
        self._regions = regions
        self._targets = targets
        self._files = files
    # The file containing the navigation regions.
    @property
    def file(self):
        return self._file
    # The file containing the navigation regions.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    # The navigation regions contained in the file. The regions are sorted by
    # their offsets. Each navigation region represents a list of targets
    # associated with some range. The lists will usually contain a single
    # target, but can contain more in the case of a part that is included in
    # multiple libraries or in Dart code that is compiled against multiple
    # versions of a package. Note that the navigation regions that are returned
    # do not overlap other navigation regions.
    @property
    def regions(self):
        return self._regions
    # The navigation regions contained in the file. The regions are sorted by
    # their offsets. Each navigation region represents a list of targets
    # associated with some range. The lists will usually contain a single
    # target, but can contain more in the case of a part that is included in
    # multiple libraries or in Dart code that is compiled against multiple
    # versions of a package. Note that the navigation regions that are returned
    # do not overlap other navigation regions.
    @regions.setter
    def regions(self, value):
        assert value is not None
        self._regions = value

    # The navigation targets referenced in the file. They are referenced by
    # NavigationRegions by their index in this array.
    @property
    def targets(self):
        return self._targets
    # The navigation targets referenced in the file. They are referenced by
    # NavigationRegions by their index in this array.
    @targets.setter
    def targets(self, value):
        assert value is not None
        self._targets = value

    # The files containing navigation targets referenced in the file. They are
    # referenced by NavigationTargets by their index in this array.
    @property
    def files(self):
        return self._files
    # The files containing navigation targets referenced in the file. They are
    # referenced by NavigationTargets by their index in this array.
    @files.setter
    def files(self, value):
        assert value is not None
        self._files = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            regions = None
            if "regions" in json_data:
                regions = [NavigationRegion.from_json(item) for item in json_data["regions"]]
            else:
                raise Exception('missing key: "regions"')
            targets = None
            if "targets" in json_data:
                targets = [NavigationTarget.from_json(item) for item in json_data["targets"]]
            else:
                raise Exception('missing key: "targets"')
            files = None
            if "files" in json_data:
                files = [(item) for item in json_data["files"]]
            else:
                raise Exception('missing key: "files"')
            return AnalysisNavigationParams(file, regions, targets, files)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_notification(notification):
        return AnalysisNavigationParams.from_json(notification._params)

    def to_json(self):
        result = {}
        result["file"] = self.file
        result["regions"] = [x.to_json() for x in self.regions]
        result["targets"] = [x.to_json() for x in self.targets]
        result["files"] = self.files
        return result

    def to_notification(self):
        return Notification("analysis.navigation", self.to_json());

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.occurrences params
#
# {
#   "file": FilePath
#   "occurrences": List<Occurrences>
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisOccurrencesParams(HasToJson):

    def __init__(self, file, occurrences):
        self._file = file
        self._occurrences = occurrences
    # The file in which the references occur.
    @property
    def file(self):
        return self._file
    # The file in which the references occur.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    # The occurrences of references to elements within the file.
    @property
    def occurrences(self):
        return self._occurrences
    # The occurrences of references to elements within the file.
    @occurrences.setter
    def occurrences(self, value):
        assert value is not None
        self._occurrences = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            occurrences = None
            if "occurrences" in json_data:
                occurrences = [Occurrences.from_json(item) for item in json_data["occurrences"]]
            else:
                raise Exception('missing key: "occurrences"')
            return AnalysisOccurrencesParams(file, occurrences)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_notification(notification):
        return AnalysisOccurrencesParams.from_json(notification._params)

    def to_json(self):
        result = {}
        result["file"] = self.file
        result["occurrences"] = [x.to_json() for x in self.occurrences]
        return result

    def to_notification(self):
        return Notification("analysis.occurrences", self.to_json());

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.outline params
#
# {
#   "file": FilePath
#   "kind": FileKind
#   "libraryName": optional String
#   "outline": Outline
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisOutlineParams(HasToJson):

    def __init__(self, file, kind, outline, libraryName=None):
        self._file = file
        self._kind = kind
        self._libraryName = libraryName
        self._outline = outline
    # The file with which the outline is associated.
    @property
    def file(self):
        return self._file
    # The file with which the outline is associated.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    # The kind of the file.
    @property
    def kind(self):
        return self._kind
    # The kind of the file.
    @kind.setter
    def kind(self, value):
        assert value is not None
        self._kind = value

    # The name of the library defined by the file using a "library" directive,
    # or referenced by a "part of" directive. If both "library" and "part of"
    # directives are present, then the "library" directive takes precedence.
    # This field will be omitted if the file has neither "library" nor "part
    # of" directives.
    @property
    def libraryName(self):
        return self._libraryName
    # The name of the library defined by the file using a "library" directive,
    # or referenced by a "part of" directive. If both "library" and "part of"
    # directives are present, then the "library" directive takes precedence.
    # This field will be omitted if the file has neither "library" nor "part
    # of" directives.
    @libraryName.setter
    def libraryName(self, value):
        self._libraryName = value

    # The outline associated with the file.
    @property
    def outline(self):
        return self._outline
    # The outline associated with the file.
    @outline.setter
    def outline(self, value):
        assert value is not None
        self._outline = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            kind = None
            if "kind" in json_data:
                kind = json_data["kind"]
            else:
                raise Exception('missing key: "kind"')
            libraryName = None
            if "libraryName" in json_data:
                libraryName = (json_data["libraryName"])

            outline = None
            if "outline" in json_data:
                outline = Outline.from_json(json_data["outline"])
            else:
                raise Exception('missing key: "outline"')
            return AnalysisOutlineParams(file, kind, outline, libraryName=libraryName)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_notification(notification):
        return AnalysisOutlineParams.from_json(notification._params)

    def to_json(self):
        result = {}
        result["file"] = self.file
        result["kind"] = kind.to_json()
        if self.libraryName is not None:
            result["libraryName"] = self.libraryName
        result["outline"] = outline.to_json()
        return result

    def to_notification(self):
        return Notification("analysis.outline", self.to_json());

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# analysis.overrides params
#
# {
#   "file": FilePath
#   "overrides": List<Override>
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisOverridesParams(HasToJson):

    def __init__(self, file, overrides):
        self._file = file
        self._overrides = overrides
    # The file with which the overrides are associated.
    @property
    def file(self):
        return self._file
    # The file with which the overrides are associated.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    # The overrides associated with the file.
    @property
    def overrides(self):
        return self._overrides
    # The overrides associated with the file.
    @overrides.setter
    def overrides(self, value):
        assert value is not None
        self._overrides = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            overrides = None
            if "overrides" in json_data:
                overrides = [Override.from_json(item) for item in json_data["overrides"]]
            else:
                raise Exception('missing key: "overrides"')
            return AnalysisOverridesParams(file, overrides)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_notification(notification):
        return AnalysisOverridesParams.from_json(notification._params)

    def to_json(self):
        result = {}
        result["file"] = self.file
        result["overrides"] = [x.to_json() for x in self.overrides]
        return result

    def to_notification(self):
        return Notification("analysis.overrides", self.to_json());

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# completion.getSuggestions params
#
# {
#   "file": FilePath
#   "offset": int
# }
#
# Clients may not extend, implement or mix-in this class.
class CompletionGetSuggestionsParams(HasToJson):

    def __init__(self, file, offset):
        self._file = file
        self._offset = offset
    # The file containing the point at which suggestions are to be made.
    @property
    def file(self):
        return self._file
    # The file containing the point at which suggestions are to be made.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    # The offset within the file at which suggestions are to be made.
    @property
    def offset(self):
        return self._offset
    # The offset within the file at which suggestions are to be made.
    @offset.setter
    def offset(self, value):
        assert value is not None
        self._offset = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            offset = None
            if "offset" in json_data:
                offset = (json_data["offset"])
            else:
                raise Exception('missing key: "offset"')
            return CompletionGetSuggestionsParams(file, offset)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return CompletionGetSuggestionsParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["file"] = self.file
        result["offset"] = self.offset
        return result

    def to_request(self, id):
        return Request(id, "completion.getSuggestions", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# completion.getSuggestions result
#
# {
#   "id": CompletionId
# }
#
# Clients may not extend, implement or mix-in this class.
class CompletionGetSuggestionsResult(HasToJson):

    def __init__(self, id):
        self._id = id
    # The identifier used to associate results with this completion request.
    @property
    def id(self):
        return self._id
    # The identifier used to associate results with this completion request.
    @id.setter
    def id(self, value):
        assert value is not None
        self._id = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            id = None
            if "id" in json_data:
                id = (json_data["id"])
            else:
                raise Exception('missing key: "id"')
            return CompletionGetSuggestionsResult(id)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_response(response):
        return CompletionGetSuggestionsResult.from_json(response._result)

    def to_json(self):
        result = {}
        result["id"] = self.id
        return result

    def to_response(self, id):
        return Response(id, result=self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# completion.results params
#
# {
#   "id": CompletionId
#   "replacementOffset": int
#   "replacementLength": int
#   "results": List<CompletionSuggestion>
#   "isLast": bool
# }
#
# Clients may not extend, implement or mix-in this class.
class CompletionResultsParams(HasToJson):

    def __init__(self, id, replacementOffset, replacementLength, results, isLast):
        self._id = id
        self._replacementOffset = replacementOffset
        self._replacementLength = replacementLength
        self._results = results
        self._isLast = isLast
    # The id associated with the completion.
    @property
    def id(self):
        return self._id
    # The id associated with the completion.
    @id.setter
    def id(self, value):
        assert value is not None
        self._id = value

    # The offset of the start of the text to be replaced. This will be
    # different than the offset used to request the completion suggestions if
    # there was a portion of an identifier before the original offset. In
    # particular, the replacementOffset will be the offset of the beginning of
    # said identifier.
    @property
    def replacementOffset(self):
        return self._replacementOffset
    # The offset of the start of the text to be replaced. This will be
    # different than the offset used to request the completion suggestions if
    # there was a portion of an identifier before the original offset. In
    # particular, the replacementOffset will be the offset of the beginning of
    # said identifier.
    @replacementOffset.setter
    def replacementOffset(self, value):
        assert value is not None
        self._replacementOffset = value

    # The length of the text to be replaced if the remainder of the identifier
    # containing the cursor is to be replaced when the suggestion is applied
    # (that is, the number of characters in the existing identifier).
    @property
    def replacementLength(self):
        return self._replacementLength
    # The length of the text to be replaced if the remainder of the identifier
    # containing the cursor is to be replaced when the suggestion is applied
    # (that is, the number of characters in the existing identifier).
    @replacementLength.setter
    def replacementLength(self, value):
        assert value is not None
        self._replacementLength = value

    # The completion suggestions being reported. The notification contains all
    # possible completions at the requested cursor position, even those that do
    # not match the characters the user has already typed. This allows the
    # client to respond to further keystrokes from the user without having to
    # make additional requests.
    @property
    def results(self):
        return self._results
    # The completion suggestions being reported. The notification contains all
    # possible completions at the requested cursor position, even those that do
    # not match the characters the user has already typed. This allows the
    # client to respond to further keystrokes from the user without having to
    # make additional requests.
    @results.setter
    def results(self, value):
        assert value is not None
        self._results = value

    # True if this is that last set of results that will be returned for the
    # indicated completion.
    @property
    def isLast(self):
        return self._isLast
    # True if this is that last set of results that will be returned for the
    # indicated completion.
    @isLast.setter
    def isLast(self, value):
        assert value is not None
        self._isLast = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            id = None
            if "id" in json_data:
                id = (json_data["id"])
            else:
                raise Exception('missing key: "id"')
            replacementOffset = None
            if "replacementOffset" in json_data:
                replacementOffset = (json_data["replacementOffset"])
            else:
                raise Exception('missing key: "replacementOffset"')
            replacementLength = None
            if "replacementLength" in json_data:
                replacementLength = (json_data["replacementLength"])
            else:
                raise Exception('missing key: "replacementLength"')
            results = None
            if "results" in json_data:
                results = [CompletionSuggestion.from_json(item) for item in json_data["results"]]
            else:
                raise Exception('missing key: "results"')
            isLast = None
            if "isLast" in json_data:
                isLast = (json_data["isLast"])
            else:
                raise Exception('missing key: "isLast"')
            return CompletionResultsParams(id, replacementOffset, replacementLength, results, isLast)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_notification(notification):
        return CompletionResultsParams.from_json(notification._params)

    def to_json(self):
        result = {}
        result["id"] = self.id
        result["replacementOffset"] = self.replacementOffset
        result["replacementLength"] = self.replacementLength
        result["results"] = [x.to_json() for x in self.results]
        result["isLast"] = self.isLast
        return result

    def to_notification(self):
        return Notification("completion.results", self.to_json());

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# search.findElementReferences params
#
# {
#   "file": FilePath
#   "offset": int
#   "includePotential": bool
# }
#
# Clients may not extend, implement or mix-in this class.
class SearchFindElementReferencesParams(HasToJson):

    def __init__(self, file, offset, includePotential):
        self._file = file
        self._offset = offset
        self._includePotential = includePotential
    # The file containing the declaration of or reference to the element used
    # to define the search.
    @property
    def file(self):
        return self._file
    # The file containing the declaration of or reference to the element used
    # to define the search.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    # The offset within the file of the declaration of or reference to the
    # element.
    @property
    def offset(self):
        return self._offset
    # The offset within the file of the declaration of or reference to the
    # element.
    @offset.setter
    def offset(self, value):
        assert value is not None
        self._offset = value

    # True if potential matches are to be included in the results.
    @property
    def includePotential(self):
        return self._includePotential
    # True if potential matches are to be included in the results.
    @includePotential.setter
    def includePotential(self, value):
        assert value is not None
        self._includePotential = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            offset = None
            if "offset" in json_data:
                offset = (json_data["offset"])
            else:
                raise Exception('missing key: "offset"')
            includePotential = None
            if "includePotential" in json_data:
                includePotential = (json_data["includePotential"])
            else:
                raise Exception('missing key: "includePotential"')
            return SearchFindElementReferencesParams(file, offset, includePotential)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return SearchFindElementReferencesParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["file"] = self.file
        result["offset"] = self.offset
        result["includePotential"] = self.includePotential
        return result

    def to_request(self, id):
        return Request(id, "search.findElementReferences", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# search.findElementReferences result
#
# {
#   "id": optional SearchId
#   "element": optional Element
# }
#
# Clients may not extend, implement or mix-in this class.
class SearchFindElementReferencesResult(HasToJson):

    def __init__(self, id=None, element=None):
        self._id = id
        self._element = element
    # The identifier used to associate results with this search request.
    #
    # If no element was found at the given location, this field will be absent,
    # and no results will be reported via the search.results notification.
    @property
    def id(self):
        return self._id
    # The identifier used to associate results with this search request.
    #
    # If no element was found at the given location, this field will be absent,
    # and no results will be reported via the search.results notification.
    @id.setter
    def id(self, value):
        self._id = value

    # The element referenced or defined at the given offset and whose
    # references will be returned in the search results.
    #
    # If no element was found at the given location, this field will be absent.
    @property
    def element(self):
        return self._element
    # The element referenced or defined at the given offset and whose
    # references will be returned in the search results.
    #
    # If no element was found at the given location, this field will be absent.
    @element.setter
    def element(self, value):
        self._element = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            id = None
            if "id" in json_data:
                id = (json_data["id"])

            element = None
            if "element" in json_data:
                element = Element.from_json(json_data["element"])

            return SearchFindElementReferencesResult(id=id, element=element)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_response(response):
        return SearchFindElementReferencesResult.from_json(response._result)

    def to_json(self):
        result = {}
        if self.id is not None:
            result["id"] = self.id
        if self.element is not None:
            result["element"] = element.to_json()
        return result

    def to_response(self, id):
        return Response(id, result=self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# search.findMemberDeclarations params
#
# {
#   "name": String
# }
#
# Clients may not extend, implement or mix-in this class.
class SearchFindMemberDeclarationsParams(HasToJson):

    def __init__(self, name):
        self._name = name
    # The name of the declarations to be found.
    @property
    def name(self):
        return self._name
    # The name of the declarations to be found.
    @name.setter
    def name(self, value):
        assert value is not None
        self._name = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            name = None
            if "name" in json_data:
                name = (json_data["name"])
            else:
                raise Exception('missing key: "name"')
            return SearchFindMemberDeclarationsParams(name)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return SearchFindMemberDeclarationsParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["name"] = self.name
        return result

    def to_request(self, id):
        return Request(id, "search.findMemberDeclarations", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# search.findMemberDeclarations result
#
# {
#   "id": SearchId
# }
#
# Clients may not extend, implement or mix-in this class.
class SearchFindMemberDeclarationsResult(HasToJson):

    def __init__(self, id):
        self._id = id
    # The identifier used to associate results with this search request.
    @property
    def id(self):
        return self._id
    # The identifier used to associate results with this search request.
    @id.setter
    def id(self, value):
        assert value is not None
        self._id = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            id = None
            if "id" in json_data:
                id = (json_data["id"])
            else:
                raise Exception('missing key: "id"')
            return SearchFindMemberDeclarationsResult(id)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_response(response):
        return SearchFindMemberDeclarationsResult.from_json(response._result)

    def to_json(self):
        result = {}
        result["id"] = self.id
        return result

    def to_response(self, id):
        return Response(id, result=self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# search.findMemberReferences params
#
# {
#   "name": String
# }
#
# Clients may not extend, implement or mix-in this class.
class SearchFindMemberReferencesParams(HasToJson):

    def __init__(self, name):
        self._name = name
    # The name of the references to be found.
    @property
    def name(self):
        return self._name
    # The name of the references to be found.
    @name.setter
    def name(self, value):
        assert value is not None
        self._name = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            name = None
            if "name" in json_data:
                name = (json_data["name"])
            else:
                raise Exception('missing key: "name"')
            return SearchFindMemberReferencesParams(name)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return SearchFindMemberReferencesParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["name"] = self.name
        return result

    def to_request(self, id):
        return Request(id, "search.findMemberReferences", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# search.findMemberReferences result
#
# {
#   "id": SearchId
# }
#
# Clients may not extend, implement or mix-in this class.
class SearchFindMemberReferencesResult(HasToJson):

    def __init__(self, id):
        self._id = id
    # The identifier used to associate results with this search request.
    @property
    def id(self):
        return self._id
    # The identifier used to associate results with this search request.
    @id.setter
    def id(self, value):
        assert value is not None
        self._id = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            id = None
            if "id" in json_data:
                id = (json_data["id"])
            else:
                raise Exception('missing key: "id"')
            return SearchFindMemberReferencesResult(id)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_response(response):
        return SearchFindMemberReferencesResult.from_json(response._result)

    def to_json(self):
        result = {}
        result["id"] = self.id
        return result

    def to_response(self, id):
        return Response(id, result=self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# search.findTopLevelDeclarations params
#
# {
#   "pattern": String
# }
#
# Clients may not extend, implement or mix-in this class.
class SearchFindTopLevelDeclarationsParams(HasToJson):

    def __init__(self, pattern):
        self._pattern = pattern
    # The regular expression used to match the names of the declarations to be
    # found.
    @property
    def pattern(self):
        return self._pattern
    # The regular expression used to match the names of the declarations to be
    # found.
    @pattern.setter
    def pattern(self, value):
        assert value is not None
        self._pattern = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            pattern = None
            if "pattern" in json_data:
                pattern = (json_data["pattern"])
            else:
                raise Exception('missing key: "pattern"')
            return SearchFindTopLevelDeclarationsParams(pattern)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return SearchFindTopLevelDeclarationsParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["pattern"] = self.pattern
        return result

    def to_request(self, id):
        return Request(id, "search.findTopLevelDeclarations", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# search.findTopLevelDeclarations result
#
# {
#   "id": SearchId
# }
#
# Clients may not extend, implement or mix-in this class.
class SearchFindTopLevelDeclarationsResult(HasToJson):

    def __init__(self, id):
        self._id = id
    # The identifier used to associate results with this search request.
    @property
    def id(self):
        return self._id
    # The identifier used to associate results with this search request.
    @id.setter
    def id(self, value):
        assert value is not None
        self._id = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            id = None
            if "id" in json_data:
                id = (json_data["id"])
            else:
                raise Exception('missing key: "id"')
            return SearchFindTopLevelDeclarationsResult(id)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_response(response):
        return SearchFindTopLevelDeclarationsResult.from_json(response._result)

    def to_json(self):
        result = {}
        result["id"] = self.id
        return result

    def to_response(self, id):
        return Response(id, result=self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# search.getTypeHierarchy params
#
# {
#   "file": FilePath
#   "offset": int
#   "superOnly": optional bool
# }
#
# Clients may not extend, implement or mix-in this class.
class SearchGetTypeHierarchyParams(HasToJson):

    def __init__(self, file, offset, superOnly=None):
        self._file = file
        self._offset = offset
        self._superOnly = superOnly
    # The file containing the declaration or reference to the type for which a
    # hierarchy is being requested.
    @property
    def file(self):
        return self._file
    # The file containing the declaration or reference to the type for which a
    # hierarchy is being requested.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    # The offset of the name of the type within the file.
    @property
    def offset(self):
        return self._offset
    # The offset of the name of the type within the file.
    @offset.setter
    def offset(self, value):
        assert value is not None
        self._offset = value

    # True if the client is only requesting superclasses and interfaces
    # hierarchy.
    @property
    def superOnly(self):
        return self._superOnly
    # True if the client is only requesting superclasses and interfaces
    # hierarchy.
    @superOnly.setter
    def superOnly(self, value):
        self._superOnly = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            offset = None
            if "offset" in json_data:
                offset = (json_data["offset"])
            else:
                raise Exception('missing key: "offset"')
            superOnly = None
            if "superOnly" in json_data:
                superOnly = (json_data["superOnly"])

            return SearchGetTypeHierarchyParams(file, offset, superOnly=superOnly)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return SearchGetTypeHierarchyParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["file"] = self.file
        result["offset"] = self.offset
        if self.superOnly is not None:
            result["superOnly"] = self.superOnly
        return result

    def to_request(self, id):
        return Request(id, "search.getTypeHierarchy", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# search.getTypeHierarchy result
#
# {
#   "hierarchyItems": optional List<TypeHierarchyItem>
# }
#
# Clients may not extend, implement or mix-in this class.
class SearchGetTypeHierarchyResult(HasToJson):

    def __init__(self, hierarchyItems=None):
        self._hierarchyItems = hierarchyItems
    # A list of the types in the requested hierarchy. The first element of the
    # list is the item representing the type for which the hierarchy was
    # requested. The index of other elements of the list is unspecified, but
    # correspond to the integers used to reference supertype and subtype items
    # within the items.
    #
    # This field will be absent if the code at the given file and offset does
    # not represent a type, or if the file has not been sufficiently analyzed
    # to allow a type hierarchy to be produced.
    @property
    def hierarchyItems(self):
        return self._hierarchyItems
    # A list of the types in the requested hierarchy. The first element of the
    # list is the item representing the type for which the hierarchy was
    # requested. The index of other elements of the list is unspecified, but
    # correspond to the integers used to reference supertype and subtype items
    # within the items.
    #
    # This field will be absent if the code at the given file and offset does
    # not represent a type, or if the file has not been sufficiently analyzed
    # to allow a type hierarchy to be produced.
    @hierarchyItems.setter
    def hierarchyItems(self, value):
        self._hierarchyItems = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            hierarchyItems = None
            if "hierarchyItems" in json_data:
                hierarchyItems = [TypeHierarchyItem.from_json(item) for item in json_data["hierarchyItems"]]

            return SearchGetTypeHierarchyResult(hierarchyItems=hierarchyItems)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_response(response):
        return SearchGetTypeHierarchyResult.from_json(response._result)

    def to_json(self):
        result = {}
        if self.hierarchyItems is not None:
            result["hierarchyItems"] = [x.to_json() for x in self.hierarchyItems]
        return result

    def to_response(self, id):
        return Response(id, result=self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# search.results params
#
# {
#   "id": SearchId
#   "results": List<SearchResult>
#   "isLast": bool
# }
#
# Clients may not extend, implement or mix-in this class.
class SearchResultsParams(HasToJson):

    def __init__(self, id, results, isLast):
        self._id = id
        self._results = results
        self._isLast = isLast
    # The id associated with the search.
    @property
    def id(self):
        return self._id
    # The id associated with the search.
    @id.setter
    def id(self, value):
        assert value is not None
        self._id = value

    # The search results being reported.
    @property
    def results(self):
        return self._results
    # The search results being reported.
    @results.setter
    def results(self, value):
        assert value is not None
        self._results = value

    # True if this is that last set of results that will be returned for the
    # indicated search.
    @property
    def isLast(self):
        return self._isLast
    # True if this is that last set of results that will be returned for the
    # indicated search.
    @isLast.setter
    def isLast(self, value):
        assert value is not None
        self._isLast = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            id = None
            if "id" in json_data:
                id = (json_data["id"])
            else:
                raise Exception('missing key: "id"')
            results = None
            if "results" in json_data:
                results = [SearchResult.from_json(item) for item in json_data["results"]]
            else:
                raise Exception('missing key: "results"')
            isLast = None
            if "isLast" in json_data:
                isLast = (json_data["isLast"])
            else:
                raise Exception('missing key: "isLast"')
            return SearchResultsParams(id, results, isLast)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_notification(notification):
        return SearchResultsParams.from_json(notification._params)

    def to_json(self):
        result = {}
        result["id"] = self.id
        result["results"] = [x.to_json() for x in self.results]
        result["isLast"] = self.isLast
        return result

    def to_notification(self):
        return Notification("search.results", self.to_json());

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# edit.format params
#
# {
#   "file": FilePath
#   "selectionOffset": int
#   "selectionLength": int
#   "lineLength": optional int
# }
#
# Clients may not extend, implement or mix-in this class.
class EditFormatParams(HasToJson):

    def __init__(self, file, selectionOffset, selectionLength, lineLength=None):
        self._file = file
        self._selectionOffset = selectionOffset
        self._selectionLength = selectionLength
        self._lineLength = lineLength
    # The file containing the code to be formatted.
    @property
    def file(self):
        return self._file
    # The file containing the code to be formatted.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    # The offset of the current selection in the file.
    @property
    def selectionOffset(self):
        return self._selectionOffset
    # The offset of the current selection in the file.
    @selectionOffset.setter
    def selectionOffset(self, value):
        assert value is not None
        self._selectionOffset = value

    # The length of the current selection in the file.
    @property
    def selectionLength(self):
        return self._selectionLength
    # The length of the current selection in the file.
    @selectionLength.setter
    def selectionLength(self, value):
        assert value is not None
        self._selectionLength = value

    # The line length to be used by the formatter.
    @property
    def lineLength(self):
        return self._lineLength
    # The line length to be used by the formatter.
    @lineLength.setter
    def lineLength(self, value):
        self._lineLength = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            selectionOffset = None
            if "selectionOffset" in json_data:
                selectionOffset = (json_data["selectionOffset"])
            else:
                raise Exception('missing key: "selectionOffset"')
            selectionLength = None
            if "selectionLength" in json_data:
                selectionLength = (json_data["selectionLength"])
            else:
                raise Exception('missing key: "selectionLength"')
            lineLength = None
            if "lineLength" in json_data:
                lineLength = (json_data["lineLength"])

            return EditFormatParams(file, selectionOffset, selectionLength, lineLength=lineLength)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return EditFormatParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["file"] = self.file
        result["selectionOffset"] = self.selectionOffset
        result["selectionLength"] = self.selectionLength
        if self.lineLength is not None:
            result["lineLength"] = self.lineLength
        return result

    def to_request(self, id):
        return Request(id, "edit.format", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# edit.format result
#
# {
#   "edits": List<SourceEdit>
#   "selectionOffset": int
#   "selectionLength": int
# }
#
# Clients may not extend, implement or mix-in this class.
class EditFormatResult(HasToJson):

    def __init__(self, edits, selectionOffset, selectionLength):
        self._edits = edits
        self._selectionOffset = selectionOffset
        self._selectionLength = selectionLength
    # The edit(s) to be applied in order to format the code. The list will be
    # empty if the code was already formatted (there are no changes).
    @property
    def edits(self):
        return self._edits
    # The edit(s) to be applied in order to format the code. The list will be
    # empty if the code was already formatted (there are no changes).
    @edits.setter
    def edits(self, value):
        assert value is not None
        self._edits = value

    # The offset of the selection after formatting the code.
    @property
    def selectionOffset(self):
        return self._selectionOffset
    # The offset of the selection after formatting the code.
    @selectionOffset.setter
    def selectionOffset(self, value):
        assert value is not None
        self._selectionOffset = value

    # The length of the selection after formatting the code.
    @property
    def selectionLength(self):
        return self._selectionLength
    # The length of the selection after formatting the code.
    @selectionLength.setter
    def selectionLength(self, value):
        assert value is not None
        self._selectionLength = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            edits = None
            if "edits" in json_data:
                edits = [SourceEdit.from_json(item) for item in json_data["edits"]]
            else:
                raise Exception('missing key: "edits"')
            selectionOffset = None
            if "selectionOffset" in json_data:
                selectionOffset = (json_data["selectionOffset"])
            else:
                raise Exception('missing key: "selectionOffset"')
            selectionLength = None
            if "selectionLength" in json_data:
                selectionLength = (json_data["selectionLength"])
            else:
                raise Exception('missing key: "selectionLength"')
            return EditFormatResult(edits, selectionOffset, selectionLength)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_response(response):
        return EditFormatResult.from_json(response._result)

    def to_json(self):
        result = {}
        result["edits"] = [x.to_json() for x in self.edits]
        result["selectionOffset"] = self.selectionOffset
        result["selectionLength"] = self.selectionLength
        return result

    def to_response(self, id):
        return Response(id, result=self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# edit.getAssists params
#
# {
#   "file": FilePath
#   "offset": int
#   "length": int
# }
#
# Clients may not extend, implement or mix-in this class.
class EditGetAssistsParams(HasToJson):

    def __init__(self, file, offset, length):
        self._file = file
        self._offset = offset
        self._length = length
    # The file containing the code for which assists are being requested.
    @property
    def file(self):
        return self._file
    # The file containing the code for which assists are being requested.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    # The offset of the code for which assists are being requested.
    @property
    def offset(self):
        return self._offset
    # The offset of the code for which assists are being requested.
    @offset.setter
    def offset(self, value):
        assert value is not None
        self._offset = value

    # The length of the code for which assists are being requested.
    @property
    def length(self):
        return self._length
    # The length of the code for which assists are being requested.
    @length.setter
    def length(self, value):
        assert value is not None
        self._length = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            offset = None
            if "offset" in json_data:
                offset = (json_data["offset"])
            else:
                raise Exception('missing key: "offset"')
            length = None
            if "length" in json_data:
                length = (json_data["length"])
            else:
                raise Exception('missing key: "length"')
            return EditGetAssistsParams(file, offset, length)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return EditGetAssistsParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["file"] = self.file
        result["offset"] = self.offset
        result["length"] = self.length
        return result

    def to_request(self, id):
        return Request(id, "edit.getAssists", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# edit.getAssists result
#
# {
#   "assists": List<SourceChange>
# }
#
# Clients may not extend, implement or mix-in this class.
class EditGetAssistsResult(HasToJson):

    def __init__(self, assists):
        self._assists = assists
    # The assists that are available at the given location.
    @property
    def assists(self):
        return self._assists
    # The assists that are available at the given location.
    @assists.setter
    def assists(self, value):
        assert value is not None
        self._assists = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            assists = None
            if "assists" in json_data:
                assists = [SourceChange.from_json(item) for item in json_data["assists"]]
            else:
                raise Exception('missing key: "assists"')
            return EditGetAssistsResult(assists)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_response(response):
        return EditGetAssistsResult.from_json(response._result)

    def to_json(self):
        result = {}
        result["assists"] = [x.to_json() for x in self.assists]
        return result

    def to_response(self, id):
        return Response(id, result=self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# edit.getAvailableRefactorings params
#
# {
#   "file": FilePath
#   "offset": int
#   "length": int
# }
#
# Clients may not extend, implement or mix-in this class.
class EditGetAvailableRefactoringsParams(HasToJson):

    def __init__(self, file, offset, length):
        self._file = file
        self._offset = offset
        self._length = length
    # The file containing the code on which the refactoring would be based.
    @property
    def file(self):
        return self._file
    # The file containing the code on which the refactoring would be based.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    # The offset of the code on which the refactoring would be based.
    @property
    def offset(self):
        return self._offset
    # The offset of the code on which the refactoring would be based.
    @offset.setter
    def offset(self, value):
        assert value is not None
        self._offset = value

    # The length of the code on which the refactoring would be based.
    @property
    def length(self):
        return self._length
    # The length of the code on which the refactoring would be based.
    @length.setter
    def length(self, value):
        assert value is not None
        self._length = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            offset = None
            if "offset" in json_data:
                offset = (json_data["offset"])
            else:
                raise Exception('missing key: "offset"')
            length = None
            if "length" in json_data:
                length = (json_data["length"])
            else:
                raise Exception('missing key: "length"')
            return EditGetAvailableRefactoringsParams(file, offset, length)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return EditGetAvailableRefactoringsParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["file"] = self.file
        result["offset"] = self.offset
        result["length"] = self.length
        return result

    def to_request(self, id):
        return Request(id, "edit.getAvailableRefactorings", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# edit.getAvailableRefactorings result
#
# {
#   "kinds": List<RefactoringKind>
# }
#
# Clients may not extend, implement or mix-in this class.
class EditGetAvailableRefactoringsResult(HasToJson):

    def __init__(self, kinds):
        self._kinds = kinds
    # The kinds of refactorings that are valid for the given selection.
    @property
    def kinds(self):
        return self._kinds
    # The kinds of refactorings that are valid for the given selection.
    @kinds.setter
    def kinds(self, value):
        assert value is not None
        self._kinds = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            kinds = None
            if "kinds" in json_data:
                kinds = json_data["kinds"]
            else:
                raise Exception('missing key: "kinds"')
            return EditGetAvailableRefactoringsResult(kinds)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_response(response):
        return EditGetAvailableRefactoringsResult.from_json(response._result)

    def to_json(self):
        result = {}
        result["kinds"] = self.kinds
        return result

    def to_response(self, id):
        return Response(id, result=self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# edit.getFixes params
#
# {
#   "file": FilePath
#   "offset": int
# }
#
# Clients may not extend, implement or mix-in this class.
class EditGetFixesParams(HasToJson):

    def __init__(self, file, offset):
        self._file = file
        self._offset = offset
    # The file containing the errors for which fixes are being requested.
    @property
    def file(self):
        return self._file
    # The file containing the errors for which fixes are being requested.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    # The offset used to select the errors for which fixes will be returned.
    @property
    def offset(self):
        return self._offset
    # The offset used to select the errors for which fixes will be returned.
    @offset.setter
    def offset(self, value):
        assert value is not None
        self._offset = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            offset = None
            if "offset" in json_data:
                offset = (json_data["offset"])
            else:
                raise Exception('missing key: "offset"')
            return EditGetFixesParams(file, offset)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return EditGetFixesParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["file"] = self.file
        result["offset"] = self.offset
        return result

    def to_request(self, id):
        return Request(id, "edit.getFixes", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# edit.getFixes result
#
# {
#   "fixes": List<AnalysisErrorFixes>
# }
#
# Clients may not extend, implement or mix-in this class.
class EditGetFixesResult(HasToJson):

    def __init__(self, fixes):
        self._fixes = fixes
    # The fixes that are available for the errors at the given offset.
    @property
    def fixes(self):
        return self._fixes
    # The fixes that are available for the errors at the given offset.
    @fixes.setter
    def fixes(self, value):
        assert value is not None
        self._fixes = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            fixes = None
            if "fixes" in json_data:
                fixes = [AnalysisErrorFixes.from_json(item) for item in json_data["fixes"]]
            else:
                raise Exception('missing key: "fixes"')
            return EditGetFixesResult(fixes)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_response(response):
        return EditGetFixesResult.from_json(response._result)

    def to_json(self):
        result = {}
        result["fixes"] = [x.to_json() for x in self.fixes]
        return result

    def to_response(self, id):
        return Response(id, result=self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# edit.getRefactoring params
#
# {
#   "kind": RefactoringKind
#   "file": FilePath
#   "offset": int
#   "length": int
#   "validateOnly": bool
#   "options": optional RefactoringOptions
# }
#
# Clients may not extend, implement or mix-in this class.
class EditGetRefactoringParams(HasToJson):

    def __init__(self, kind, file, offset, length, validateOnly, options=None):
        self._kind = kind
        self._file = file
        self._offset = offset
        self._length = length
        self._validateOnly = validateOnly
        self._options = options
    # The kind of refactoring to be performed.
    @property
    def kind(self):
        return self._kind
    # The kind of refactoring to be performed.
    @kind.setter
    def kind(self, value):
        assert value is not None
        self._kind = value

    # The file containing the code involved in the refactoring.
    @property
    def file(self):
        return self._file
    # The file containing the code involved in the refactoring.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    # The offset of the region involved in the refactoring.
    @property
    def offset(self):
        return self._offset
    # The offset of the region involved in the refactoring.
    @offset.setter
    def offset(self, value):
        assert value is not None
        self._offset = value

    # The length of the region involved in the refactoring.
    @property
    def length(self):
        return self._length
    # The length of the region involved in the refactoring.
    @length.setter
    def length(self, value):
        assert value is not None
        self._length = value

    # True if the client is only requesting that the values of the options be
    # validated and no change be generated.
    @property
    def validateOnly(self):
        return self._validateOnly
    # True if the client is only requesting that the values of the options be
    # validated and no change be generated.
    @validateOnly.setter
    def validateOnly(self, value):
        assert value is not None
        self._validateOnly = value

    # Data used to provide values provided by the user. The structure of the
    # data is dependent on the kind of refactoring being performed. The data
    # that is expected is documented in the section titled Refactorings,
    # labeled as “Options”. This field can be omitted if the refactoring does
    # not require any options or if the values of those options are not known.
    @property
    def options(self):
        return self._options
    # Data used to provide values provided by the user. The structure of the
    # data is dependent on the kind of refactoring being performed. The data
    # that is expected is documented in the section titled Refactorings,
    # labeled as “Options”. This field can be omitted if the refactoring does
    # not require any options or if the values of those options are not known.
    @options.setter
    def options(self, value):
        self._options = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            kind = None
            if "kind" in json_data:
                kind = json_data["kind"]
            else:
                raise Exception('missing key: "kind"')
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            offset = None
            if "offset" in json_data:
                offset = (json_data["offset"])
            else:
                raise Exception('missing key: "offset"')
            length = None
            if "length" in json_data:
                length = (json_data["length"])
            else:
                raise Exception('missing key: "length"')
            validateOnly = None
            if "validateOnly" in json_data:
                validateOnly = (json_data["validateOnly"])
            else:
                raise Exception('missing key: "validateOnly"')
            options = None
            if "options" in json_data:
                options = RefactoringOptions.from_json(json_data["options"], kind)

            return EditGetRefactoringParams(kind, file, offset, length, validateOnly, options=options)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        params = EditGetRefactoringParams.from_json(
            "params", request._params)
        REQUEST_ID_REFACTORING_KINDS[request.id] = params.kind
        return params

    def to_json(self):
        result = {}
        result["kind"] = kind.to_json()
        result["file"] = self.file
        result["offset"] = self.offset
        result["length"] = self.length
        result["validateOnly"] = self.validateOnly
        if self.options is not None:
            result["options"] = options.to_json()
        return result

    def to_request(self, id):
        return Request(id, "edit.getRefactoring", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# edit.getRefactoring result
#
# {
#   "initialProblems": List<RefactoringProblem>
#   "optionsProblems": List<RefactoringProblem>
#   "finalProblems": List<RefactoringProblem>
#   "feedback": optional RefactoringFeedback
#   "change": optional SourceChange
#   "potentialEdits": optional List<String>
# }
#
# Clients may not extend, implement or mix-in this class.
class EditGetRefactoringResult(HasToJson):

    def __init__(self, initialProblems, optionsProblems, finalProblems, feedback=None, change=None, potentialEdits=None):
        self._initialProblems = initialProblems
        self._optionsProblems = optionsProblems
        self._finalProblems = finalProblems
        self._feedback = feedback
        self._change = change
        self._potentialEdits = potentialEdits
    # The initial status of the refactoring, i.e. problems related to the
    # context in which the refactoring is requested. The array will be empty if
    # there are no known problems.
    @property
    def initialProblems(self):
        return self._initialProblems
    # The initial status of the refactoring, i.e. problems related to the
    # context in which the refactoring is requested. The array will be empty if
    # there are no known problems.
    @initialProblems.setter
    def initialProblems(self, value):
        assert value is not None
        self._initialProblems = value

    # The options validation status, i.e. problems in the given options, such
    # as light-weight validation of a new name, flags compatibility, etc. The
    # array will be empty if there are no known problems.
    @property
    def optionsProblems(self):
        return self._optionsProblems
    # The options validation status, i.e. problems in the given options, such
    # as light-weight validation of a new name, flags compatibility, etc. The
    # array will be empty if there are no known problems.
    @optionsProblems.setter
    def optionsProblems(self, value):
        assert value is not None
        self._optionsProblems = value

    # The final status of the refactoring, i.e. problems identified in the
    # result of a full, potentially expensive validation and / or change
    # creation. The array will be empty if there are no known problems.
    @property
    def finalProblems(self):
        return self._finalProblems
    # The final status of the refactoring, i.e. problems identified in the
    # result of a full, potentially expensive validation and / or change
    # creation. The array will be empty if there are no known problems.
    @finalProblems.setter
    def finalProblems(self, value):
        assert value is not None
        self._finalProblems = value

    # Data used to provide feedback to the user. The structure of the data is
    # dependent on the kind of refactoring being created. The data that is
    # returned is documented in the section titled Refactorings, labeled as
    # “Feedback”.
    @property
    def feedback(self):
        return self._feedback
    # Data used to provide feedback to the user. The structure of the data is
    # dependent on the kind of refactoring being created. The data that is
    # returned is documented in the section titled Refactorings, labeled as
    # “Feedback”.
    @feedback.setter
    def feedback(self, value):
        self._feedback = value

    # The changes that are to be applied to affect the refactoring. This field
    # will be omitted if there are problems that prevent a set of changes from
    # being computed, such as having no options specified for a refactoring
    # that requires them, or if only validation was requested.
    @property
    def change(self):
        return self._change
    # The changes that are to be applied to affect the refactoring. This field
    # will be omitted if there are problems that prevent a set of changes from
    # being computed, such as having no options specified for a refactoring
    # that requires them, or if only validation was requested.
    @change.setter
    def change(self, value):
        self._change = value

    # The ids of source edits that are not known to be valid. An edit is not
    # known to be valid if there was insufficient type information for the
    # server to be able to determine whether or not the code needs to be
    # modified, such as when a member is being renamed and there is a reference
    # to a member from an unknown type. This field will be omitted if the
    # change field is omitted or if there are no potential edits for the
    # refactoring.
    @property
    def potentialEdits(self):
        return self._potentialEdits
    # The ids of source edits that are not known to be valid. An edit is not
    # known to be valid if there was insufficient type information for the
    # server to be able to determine whether or not the code needs to be
    # modified, such as when a member is being renamed and there is a reference
    # to a member from an unknown type. This field will be omitted if the
    # change field is omitted or if there are no potential edits for the
    # refactoring.
    @potentialEdits.setter
    def potentialEdits(self, value):
        self._potentialEdits = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            initialProblems = None
            if "initialProblems" in json_data:
                initialProblems = [RefactoringProblem.from_json(item) for item in json_data["initialProblems"]]
            else:
                raise Exception('missing key: "initialProblems"')
            optionsProblems = None
            if "optionsProblems" in json_data:
                optionsProblems = [RefactoringProblem.from_json(item) for item in json_data["optionsProblems"]]
            else:
                raise Exception('missing key: "optionsProblems"')
            finalProblems = None
            if "finalProblems" in json_data:
                finalProblems = [RefactoringProblem.from_json(item) for item in json_data["finalProblems"]]
            else:
                raise Exception('missing key: "finalProblems"')
            feedback = None
            if "feedback" in json_data:
                feedback = RefactoringFeedback.from_json(json_data["feedback"], json)

            change = None
            if "change" in json_data:
                change = SourceChange.from_json(json_data["change"])

            potentialEdits = None
            if "potentialEdits" in json_data:
                potentialEdits = [(item) for item in json_data["potentialEdits"]]

            return EditGetRefactoringResult(initialProblems, optionsProblems, finalProblems, feedback=feedback, change=change, potentialEdits=potentialEdits)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_response(response):
        return EditGetRefactoringResult.from_json(response._result)

    def to_json(self):
        result = {}
        result["initialProblems"] = [x.to_json() for x in self.initialProblems]
        result["optionsProblems"] = [x.to_json() for x in self.optionsProblems]
        result["finalProblems"] = [x.to_json() for x in self.finalProblems]
        if self.feedback is not None:
            result["feedback"] = feedback.to_json()
        if self.change is not None:
            result["change"] = change.to_json()
        if self.potentialEdits is not None:
            result["potentialEdits"] = self.potentialEdits
        return result

    def to_response(self, id):
        return Response(id, result=self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# edit.sortMembers params
#
# {
#   "file": FilePath
# }
#
# Clients may not extend, implement or mix-in this class.
class EditSortMembersParams(HasToJson):

    def __init__(self, file):
        self._file = file
    # The Dart file to sort.
    @property
    def file(self):
        return self._file
    # The Dart file to sort.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            return EditSortMembersParams(file)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return EditSortMembersParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["file"] = self.file
        return result

    def to_request(self, id):
        return Request(id, "edit.sortMembers", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# edit.sortMembers result
#
# {
#   "edit": SourceFileEdit
# }
#
# Clients may not extend, implement or mix-in this class.
class EditSortMembersResult(HasToJson):

    def __init__(self, edit):
        self._edit = edit
    # The file edit that is to be applied to the given file to effect the
    # sorting.
    @property
    def edit(self):
        return self._edit
    # The file edit that is to be applied to the given file to effect the
    # sorting.
    @edit.setter
    def edit(self, value):
        assert value is not None
        self._edit = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            edit = None
            if "edit" in json_data:
                edit = SourceFileEdit.from_json(json_data["edit"])
            else:
                raise Exception('missing key: "edit"')
            return EditSortMembersResult(edit)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_response(response):
        return EditSortMembersResult.from_json(response._result)

    def to_json(self):
        result = {}
        result["edit"] = edit.to_json()
        return result

    def to_response(self, id):
        return Response(id, result=self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# edit.organizeDirectives params
#
# {
#   "file": FilePath
# }
#
# Clients may not extend, implement or mix-in this class.
class EditOrganizeDirectivesParams(HasToJson):

    def __init__(self, file):
        self._file = file
    # The Dart file to organize directives in.
    @property
    def file(self):
        return self._file
    # The Dart file to organize directives in.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            return EditOrganizeDirectivesParams(file)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return EditOrganizeDirectivesParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["file"] = self.file
        return result

    def to_request(self, id):
        return Request(id, "edit.organizeDirectives", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# edit.organizeDirectives result
#
# {
#   "edit": SourceFileEdit
# }
#
# Clients may not extend, implement or mix-in this class.
class EditOrganizeDirectivesResult(HasToJson):

    def __init__(self, edit):
        self._edit = edit
    # The file edit that is to be applied to the given file to effect the
    # organizing.
    @property
    def edit(self):
        return self._edit
    # The file edit that is to be applied to the given file to effect the
    # organizing.
    @edit.setter
    def edit(self, value):
        assert value is not None
        self._edit = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            edit = None
            if "edit" in json_data:
                edit = SourceFileEdit.from_json(json_data["edit"])
            else:
                raise Exception('missing key: "edit"')
            return EditOrganizeDirectivesResult(edit)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_response(response):
        return EditOrganizeDirectivesResult.from_json(response._result)

    def to_json(self):
        result = {}
        result["edit"] = edit.to_json()
        return result

    def to_response(self, id):
        return Response(id, result=self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# execution.createContext params
#
# {
#   "contextRoot": FilePath
# }
#
# Clients may not extend, implement or mix-in this class.
class ExecutionCreateContextParams(HasToJson):

    def __init__(self, contextRoot):
        self._contextRoot = contextRoot
    # The path of the Dart or HTML file that will be launched, or the path of
    # the directory containing the file.
    @property
    def contextRoot(self):
        return self._contextRoot
    # The path of the Dart or HTML file that will be launched, or the path of
    # the directory containing the file.
    @contextRoot.setter
    def contextRoot(self, value):
        assert value is not None
        self._contextRoot = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            contextRoot = None
            if "contextRoot" in json_data:
                contextRoot = (json_data["contextRoot"])
            else:
                raise Exception('missing key: "contextRoot"')
            return ExecutionCreateContextParams(contextRoot)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return ExecutionCreateContextParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["contextRoot"] = self.contextRoot
        return result

    def to_request(self, id):
        return Request(id, "execution.createContext", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# execution.createContext result
#
# {
#   "id": ExecutionContextId
# }
#
# Clients may not extend, implement or mix-in this class.
class ExecutionCreateContextResult(HasToJson):

    def __init__(self, id):
        self._id = id
    # The identifier used to refer to the execution context that was created.
    @property
    def id(self):
        return self._id
    # The identifier used to refer to the execution context that was created.
    @id.setter
    def id(self, value):
        assert value is not None
        self._id = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            id = None
            if "id" in json_data:
                id = (json_data["id"])
            else:
                raise Exception('missing key: "id"')
            return ExecutionCreateContextResult(id)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_response(response):
        return ExecutionCreateContextResult.from_json(response._result)

    def to_json(self):
        result = {}
        result["id"] = self.id
        return result

    def to_response(self, id):
        return Response(id, result=self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# execution.deleteContext params
#
# {
#   "id": ExecutionContextId
# }
#
# Clients may not extend, implement or mix-in this class.
class ExecutionDeleteContextParams(HasToJson):

    def __init__(self, id):
        self._id = id
    # The identifier of the execution context that is to be deleted.
    @property
    def id(self):
        return self._id
    # The identifier of the execution context that is to be deleted.
    @id.setter
    def id(self, value):
        assert value is not None
        self._id = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            id = None
            if "id" in json_data:
                id = (json_data["id"])
            else:
                raise Exception('missing key: "id"')
            return ExecutionDeleteContextParams(id)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return ExecutionDeleteContextParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["id"] = self.id
        return result

    def to_request(self, id):
        return Request(id, "execution.deleteContext", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass
# execution.deleteContext result
#
# Clients may not extend, implement or mix-in this class.
class ExecutionDeleteContextResult(object):
    def to_response(self, id):
        return Response(id, result=None)

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# execution.mapUri params
#
# {
#   "id": ExecutionContextId
#   "file": optional FilePath
#   "uri": optional String
# }
#
# Clients may not extend, implement or mix-in this class.
class ExecutionMapUriParams(HasToJson):

    def __init__(self, id, file=None, uri=None):
        self._id = id
        self._file = file
        self._uri = uri
    # The identifier of the execution context in which the URI is to be mapped.
    @property
    def id(self):
        return self._id
    # The identifier of the execution context in which the URI is to be mapped.
    @id.setter
    def id(self, value):
        assert value is not None
        self._id = value

    # The path of the file to be mapped into a URI.
    @property
    def file(self):
        return self._file
    # The path of the file to be mapped into a URI.
    @file.setter
    def file(self, value):
        self._file = value

    # The URI to be mapped into a file path.
    @property
    def uri(self):
        return self._uri
    # The URI to be mapped into a file path.
    @uri.setter
    def uri(self, value):
        self._uri = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            id = None
            if "id" in json_data:
                id = (json_data["id"])
            else:
                raise Exception('missing key: "id"')
            file = None
            if "file" in json_data:
                file = (json_data["file"])

            uri = None
            if "uri" in json_data:
                uri = (json_data["uri"])

            return ExecutionMapUriParams(id, file=file, uri=uri)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return ExecutionMapUriParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["id"] = self.id
        if self.file is not None:
            result["file"] = self.file
        if self.uri is not None:
            result["uri"] = self.uri
        return result

    def to_request(self, id):
        return Request(id, "execution.mapUri", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# execution.mapUri result
#
# {
#   "file": optional FilePath
#   "uri": optional String
# }
#
# Clients may not extend, implement or mix-in this class.
class ExecutionMapUriResult(HasToJson):

    def __init__(self, file=None, uri=None):
        self._file = file
        self._uri = uri
    # The file to which the URI was mapped. This field is omitted if the uri
    # field was not given in the request.
    @property
    def file(self):
        return self._file
    # The file to which the URI was mapped. This field is omitted if the uri
    # field was not given in the request.
    @file.setter
    def file(self, value):
        self._file = value

    # The URI to which the file path was mapped. This field is omitted if the
    # file field was not given in the request.
    @property
    def uri(self):
        return self._uri
    # The URI to which the file path was mapped. This field is omitted if the
    # file field was not given in the request.
    @uri.setter
    def uri(self, value):
        self._uri = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])

            uri = None
            if "uri" in json_data:
                uri = (json_data["uri"])

            return ExecutionMapUriResult(file=file, uri=uri)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_response(response):
        return ExecutionMapUriResult.from_json(response._result)

    def to_json(self):
        result = {}
        if self.file is not None:
            result["file"] = self.file
        if self.uri is not None:
            result["uri"] = self.uri
        return result

    def to_response(self, id):
        return Response(id, result=self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# execution.setSubscriptions params
#
# {
#   "subscriptions": List<ExecutionService>
# }
#
# Clients may not extend, implement or mix-in this class.
class ExecutionSetSubscriptionsParams(HasToJson):

    def __init__(self, subscriptions):
        self._subscriptions = subscriptions
    # A list of the services being subscribed to.
    @property
    def subscriptions(self):
        return self._subscriptions
    # A list of the services being subscribed to.
    @subscriptions.setter
    def subscriptions(self, value):
        assert value is not None
        self._subscriptions = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            subscriptions = None
            if "subscriptions" in json_data:
                subscriptions = json_data["subscriptions"]
            else:
                raise Exception('missing key: "subscriptions"')
            return ExecutionSetSubscriptionsParams(subscriptions)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_request(request):
        return ExecutionSetSubscriptionsParams.from_json(request._params)

    def to_json(self):
        result = {}
        result["subscriptions"] = self.subscriptions
        return result

    def to_request(self, id):
        return Request(id, "execution.setSubscriptions", self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass
# execution.setSubscriptions result
#
# Clients may not extend, implement or mix-in this class.
class ExecutionSetSubscriptionsResult(object):
    def to_response(self, id):
        return Response(id, result=None)

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# execution.launchData params
#
# {
#   "file": FilePath
#   "kind": optional ExecutableKind
#   "referencedFiles": optional List<FilePath>
# }
#
# Clients may not extend, implement or mix-in this class.
class ExecutionLaunchDataParams(HasToJson):

    def __init__(self, file, kind=None, referencedFiles=None):
        self._file = file
        self._kind = kind
        self._referencedFiles = referencedFiles
    # The file for which launch data is being provided. This will either be a
    # Dart library or an HTML file.
    @property
    def file(self):
        return self._file
    # The file for which launch data is being provided. This will either be a
    # Dart library or an HTML file.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    # The kind of the executable file. This field is omitted if the file is not
    # a Dart file.
    @property
    def kind(self):
        return self._kind
    # The kind of the executable file. This field is omitted if the file is not
    # a Dart file.
    @kind.setter
    def kind(self, value):
        self._kind = value

    # A list of the Dart files that are referenced by the file. This field is
    # omitted if the file is not an HTML file.
    @property
    def referencedFiles(self):
        return self._referencedFiles
    # A list of the Dart files that are referenced by the file. This field is
    # omitted if the file is not an HTML file.
    @referencedFiles.setter
    def referencedFiles(self, value):
        self._referencedFiles = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            kind = None
            if "kind" in json_data:
                kind = json_data["kind"]

            referencedFiles = None
            if "referencedFiles" in json_data:
                referencedFiles = [(item) for item in json_data["referencedFiles"]]

            return ExecutionLaunchDataParams(file, kind=kind, referencedFiles=referencedFiles)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_notification(notification):
        return ExecutionLaunchDataParams.from_json(notification._params)

    def to_json(self):
        result = {}
        result["file"] = self.file
        if self.kind is not None:
            result["kind"] = kind.to_json()
        if self.referencedFiles is not None:
            result["referencedFiles"] = self.referencedFiles
        return result

    def to_notification(self):
        return Notification("execution.launchData", self.to_json());

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass
# diagnostic.getDiagnostics params
#
# Clients may not extend, implement or mix-in this class.
class DiagnosticGetDiagnosticsParams(object):
    def to_request(self, id):
        return Request(id, "diagnostic.getDiagnostics", None)

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# diagnostic.getDiagnostics result
#
# {
#   "contexts": List<ContextData>
# }
#
# Clients may not extend, implement or mix-in this class.
class DiagnosticGetDiagnosticsResult(HasToJson):

    def __init__(self, contexts):
        self._contexts = contexts
    # The list of analysis contexts.
    @property
    def contexts(self):
        return self._contexts
    # The list of analysis contexts.
    @contexts.setter
    def contexts(self, value):
        assert value is not None
        self._contexts = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            contexts = None
            if "contexts" in json_data:
                contexts = [ContextData.from_json(item) for item in json_data["contexts"]]
            else:
                raise Exception('missing key: "contexts"')
            return DiagnosticGetDiagnosticsResult(contexts)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def from_response(response):
        return DiagnosticGetDiagnosticsResult.from_json(response._result)

    def to_json(self):
        result = {}
        result["contexts"] = [x.to_json() for x in self.contexts]
        return result

    def to_response(self, id):
        return Response(id, result=self.to_json())

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# AddContentOverlay
#
# {
#   "type": "add"
#   "content": String
# }
#
# Clients may not extend, implement or mix-in this class.
class AddContentOverlay(HasToJson):

    def __init__(self, content):
        self._content = content
    # The new content of the file.
    @property
    def content(self):
        return self._content
    # The new content of the file.
    @content.setter
    def content(self, value):
        assert value is not None
        self._content = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            if json_data["type"] != "add":
                raise ValueError("equal " + "add" + " " + str(json_data))
            content = None
            if "content" in json_data:
                content = (json_data["content"])
            else:
                raise Exception('missing key: "content"')
            return AddContentOverlay(content)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["type"] = "add"
        result["content"] = self.content
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# AnalysisError
#
# {
#   "severity": AnalysisErrorSeverity
#   "type": AnalysisErrorType
#   "location": Location
#   "message": String
#   "correction": optional String
#   "hasFix": optional bool
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisError(HasToJson):

    def __init__(self, severity, type, location, message, correction=None, hasFix=None):
        self._severity = severity
        self._type = type
        self._location = location
        self._message = message
        self._correction = correction
        self._hasFix = hasFix
    # The severity of the error.
    @property
    def severity(self):
        return self._severity
    # The severity of the error.
    @severity.setter
    def severity(self, value):
        assert value is not None
        self._severity = value

    # The type of the error.
    @property
    def type(self):
        return self._type
    # The type of the error.
    @type.setter
    def type(self, value):
        assert value is not None
        self._type = value

    # The location associated with the error.
    @property
    def location(self):
        return self._location
    # The location associated with the error.
    @location.setter
    def location(self, value):
        assert value is not None
        self._location = value

    # The message to be displayed for this error. The message should indicate
    # what is wrong with the code and why it is wrong.
    @property
    def message(self):
        return self._message
    # The message to be displayed for this error. The message should indicate
    # what is wrong with the code and why it is wrong.
    @message.setter
    def message(self, value):
        assert value is not None
        self._message = value

    # The correction message to be displayed for this error. The correction
    # message should indicate how the user can fix the error. The field is
    # omitted if there is no correction message associated with the error code.
    @property
    def correction(self):
        return self._correction
    # The correction message to be displayed for this error. The correction
    # message should indicate how the user can fix the error. The field is
    # omitted if there is no correction message associated with the error code.
    @correction.setter
    def correction(self, value):
        self._correction = value

    # A hint to indicate to interested clients that this error has an
    # associated fix (or fixes). The absence of this field implies there are
    # not known to be fixes. Note that since the operation to calculate whether
    # fixes apply needs to be performant it is possible that complicated tests
    # will be skipped and a false negative returned. For this reason, this
    # attribute should be treated as a "hint". Despite the possibility of false
    # negatives, no false positives should be returned. If a client sees this
    # flag set they can proceed with the confidence that there are in fact
    # associated fixes.
    @property
    def hasFix(self):
        return self._hasFix
    # A hint to indicate to interested clients that this error has an
    # associated fix (or fixes). The absence of this field implies there are
    # not known to be fixes. Note that since the operation to calculate whether
    # fixes apply needs to be performant it is possible that complicated tests
    # will be skipped and a false negative returned. For this reason, this
    # attribute should be treated as a "hint". Despite the possibility of false
    # negatives, no false positives should be returned. If a client sees this
    # flag set they can proceed with the confidence that there are in fact
    # associated fixes.
    @hasFix.setter
    def hasFix(self, value):
        self._hasFix = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            severity = None
            if "severity" in json_data:
                severity = json_data["severity"]
            else:
                raise Exception('missing key: "severity"')
            type = None
            if "type" in json_data:
                type = json_data["type"]
            else:
                raise Exception('missing key: "type"')
            location = None
            if "location" in json_data:
                location = Location.from_json(json_data["location"])
            else:
                raise Exception('missing key: "location"')
            message = None
            if "message" in json_data:
                message = (json_data["message"])
            else:
                raise Exception('missing key: "message"')
            correction = None
            if "correction" in json_data:
                correction = (json_data["correction"])

            hasFix = None
            if "hasFix" in json_data:
                hasFix = (json_data["hasFix"])

            return AnalysisError(severity, type, location, message, correction=correction, hasFix=hasFix)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["severity"] = severity.to_json()
        result["type"] = type.to_json()
        result["location"] = location.to_json()
        result["message"] = self.message
        if self.correction is not None:
            result["correction"] = self.correction
        if self.hasFix is not None:
            result["hasFix"] = self.hasFix
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# AnalysisErrorFixes
#
# {
#   "error": AnalysisError
#   "fixes": List<SourceChange>
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisErrorFixes(HasToJson):

    def __init__(self, error, fixes=None):
        self._error = error
        self._fixes = fixes
    # The error with which the fixes are associated.
    @property
    def error(self):
        return self._error
    # The error with which the fixes are associated.
    @error.setter
    def error(self, value):
        assert value is not None
        self._error = value

    # The fixes associated with the error.
    @property
    def fixes(self):
        return self._fixes
    # The fixes associated with the error.
    @fixes.setter
    def fixes(self, value):
        assert value is not None
        self._fixes = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            error = None
            if "error" in json_data:
                error = AnalysisError.from_json(json_data["error"])
            else:
                raise Exception('missing key: "error"')
            fixes = None
            if "fixes" in json_data:
                fixes = [SourceChange.from_json(item) for item in json_data["fixes"]]
            else:
                raise Exception('missing key: "fixes"')
            return AnalysisErrorFixes(error, fixes=fixes)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["error"] = error.to_json()
        result["fixes"] = [x.to_json() for x in self.fixes]
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# AnalysisErrorSeverity
#
# enum {
#   INFO
#   WARNING
#   ERROR
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisErrorSeverity:
    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"

# AnalysisErrorType
#
# enum {
#   CHECKED_MODE_COMPILE_TIME_ERROR
#   COMPILE_TIME_ERROR
#   HINT
#   LINT
#   STATIC_TYPE_WARNING
#   STATIC_WARNING
#   SYNTACTIC_ERROR
#   TODO
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisErrorType:
    CHECKED_MODE_COMPILE_TIME_ERROR = "CHECKED_MODE_COMPILE_TIME_ERROR"
    COMPILE_TIME_ERROR = "COMPILE_TIME_ERROR"
    HINT = "HINT"
    LINT = "LINT"
    STATIC_TYPE_WARNING = "STATIC_TYPE_WARNING"
    STATIC_WARNING = "STATIC_WARNING"
    SYNTACTIC_ERROR = "SYNTACTIC_ERROR"
    TODO = "TODO"

# AnalysisOptions
#
# {
#   "enableAsync": optional bool
#   "enableDeferredLoading": optional bool
#   "enableEnums": optional bool
#   "enableNullAwareOperators": optional bool
#   "enableSuperMixins": optional bool
#   "generateDart2jsHints": optional bool
#   "generateHints": optional bool
#   "generateLints": optional bool
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisOptions(HasToJson):

    def __init__(self, enableAsync=None, enableDeferredLoading=None, enableEnums=None, enableNullAwareOperators=None, enableSuperMixins=None, generateDart2jsHints=None, generateHints=None, generateLints=None):
        self._enableAsync = enableAsync
        self._enableDeferredLoading = enableDeferredLoading
        self._enableEnums = enableEnums
        self._enableNullAwareOperators = enableNullAwareOperators
        self._enableSuperMixins = enableSuperMixins
        self._generateDart2jsHints = generateDart2jsHints
        self._generateHints = generateHints
        self._generateLints = generateLints
    # Deprecated: this feature is always enabled.
    #
    # True if the client wants to enable support for the proposed async
    # feature.
    @property
    def enableAsync(self):
        return self._enableAsync
    # Deprecated: this feature is always enabled.
    #
    # True if the client wants to enable support for the proposed async
    # feature.
    @enableAsync.setter
    def enableAsync(self, value):
        self._enableAsync = value

    # Deprecated: this feature is always enabled.
    #
    # True if the client wants to enable support for the proposed deferred
    # loading feature.
    @property
    def enableDeferredLoading(self):
        return self._enableDeferredLoading
    # Deprecated: this feature is always enabled.
    #
    # True if the client wants to enable support for the proposed deferred
    # loading feature.
    @enableDeferredLoading.setter
    def enableDeferredLoading(self, value):
        self._enableDeferredLoading = value

    # Deprecated: this feature is always enabled.
    #
    # True if the client wants to enable support for the proposed enum feature.
    @property
    def enableEnums(self):
        return self._enableEnums
    # Deprecated: this feature is always enabled.
    #
    # True if the client wants to enable support for the proposed enum feature.
    @enableEnums.setter
    def enableEnums(self, value):
        self._enableEnums = value

    # Deprecated: this feature is always enabled.
    #
    # True if the client wants to enable support for the proposed "null aware
    # operators" feature.
    @property
    def enableNullAwareOperators(self):
        return self._enableNullAwareOperators
    # Deprecated: this feature is always enabled.
    #
    # True if the client wants to enable support for the proposed "null aware
    # operators" feature.
    @enableNullAwareOperators.setter
    def enableNullAwareOperators(self, value):
        self._enableNullAwareOperators = value

    # True if the client wants to enable support for the proposed "less
    # restricted mixins" proposal (DEP 34).
    @property
    def enableSuperMixins(self):
        return self._enableSuperMixins
    # True if the client wants to enable support for the proposed "less
    # restricted mixins" proposal (DEP 34).
    @enableSuperMixins.setter
    def enableSuperMixins(self, value):
        self._enableSuperMixins = value

    # True if hints that are specific to dart2js should be generated. This
    # option is ignored if generateHints is false.
    @property
    def generateDart2jsHints(self):
        return self._generateDart2jsHints
    # True if hints that are specific to dart2js should be generated. This
    # option is ignored if generateHints is false.
    @generateDart2jsHints.setter
    def generateDart2jsHints(self, value):
        self._generateDart2jsHints = value

    # True if hints should be generated as part of generating errors and
    # warnings.
    @property
    def generateHints(self):
        return self._generateHints
    # True if hints should be generated as part of generating errors and
    # warnings.
    @generateHints.setter
    def generateHints(self, value):
        self._generateHints = value

    # True if lints should be generated as part of generating errors and
    # warnings.
    @property
    def generateLints(self):
        return self._generateLints
    # True if lints should be generated as part of generating errors and
    # warnings.
    @generateLints.setter
    def generateLints(self, value):
        self._generateLints = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            enableAsync = None
            if "enableAsync" in json_data:
                enableAsync = (json_data["enableAsync"])

            enableDeferredLoading = None
            if "enableDeferredLoading" in json_data:
                enableDeferredLoading = (json_data["enableDeferredLoading"])

            enableEnums = None
            if "enableEnums" in json_data:
                enableEnums = (json_data["enableEnums"])

            enableNullAwareOperators = None
            if "enableNullAwareOperators" in json_data:
                enableNullAwareOperators = (json_data["enableNullAwareOperators"])

            enableSuperMixins = None
            if "enableSuperMixins" in json_data:
                enableSuperMixins = (json_data["enableSuperMixins"])

            generateDart2jsHints = None
            if "generateDart2jsHints" in json_data:
                generateDart2jsHints = (json_data["generateDart2jsHints"])

            generateHints = None
            if "generateHints" in json_data:
                generateHints = (json_data["generateHints"])

            generateLints = None
            if "generateLints" in json_data:
                generateLints = (json_data["generateLints"])

            return AnalysisOptions(enableAsync=enableAsync, enableDeferredLoading=enableDeferredLoading, enableEnums=enableEnums, enableNullAwareOperators=enableNullAwareOperators, enableSuperMixins=enableSuperMixins, generateDart2jsHints=generateDart2jsHints, generateHints=generateHints, generateLints=generateLints)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        if self.enableAsync is not None:
            result["enableAsync"] = self.enableAsync
        if self.enableDeferredLoading is not None:
            result["enableDeferredLoading"] = self.enableDeferredLoading
        if self.enableEnums is not None:
            result["enableEnums"] = self.enableEnums
        if self.enableNullAwareOperators is not None:
            result["enableNullAwareOperators"] = self.enableNullAwareOperators
        if self.enableSuperMixins is not None:
            result["enableSuperMixins"] = self.enableSuperMixins
        if self.generateDart2jsHints is not None:
            result["generateDart2jsHints"] = self.generateDart2jsHints
        if self.generateHints is not None:
            result["generateHints"] = self.generateHints
        if self.generateLints is not None:
            result["generateLints"] = self.generateLints
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# AnalysisService
#
# enum {
#   FOLDING
#   HIGHLIGHTS
#   IMPLEMENTED
#   INVALIDATE
#   NAVIGATION
#   OCCURRENCES
#   OUTLINE
#   OVERRIDES
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisService:
    FOLDING = "FOLDING"
    HIGHLIGHTS = "HIGHLIGHTS"
    IMPLEMENTED = "IMPLEMENTED"
    # This service is not currently implemented and will become a
    # GeneralAnalysisService in a future release.
    INVALIDATE = "INVALIDATE"
    NAVIGATION = "NAVIGATION"
    OCCURRENCES = "OCCURRENCES"
    OUTLINE = "OUTLINE"
    OVERRIDES = "OVERRIDES"

# AnalysisStatus
#
# {
#   "isAnalyzing": bool
#   "analysisTarget": optional String
# }
#
# Clients may not extend, implement or mix-in this class.
class AnalysisStatus(HasToJson):

    def __init__(self, isAnalyzing, analysisTarget=None):
        self._isAnalyzing = isAnalyzing
        self._analysisTarget = analysisTarget
    # True if analysis is currently being performed.
    @property
    def isAnalyzing(self):
        return self._isAnalyzing
    # True if analysis is currently being performed.
    @isAnalyzing.setter
    def isAnalyzing(self, value):
        assert value is not None
        self._isAnalyzing = value

    # The name of the current target of analysis. This field is omitted if
    # analyzing is false.
    @property
    def analysisTarget(self):
        return self._analysisTarget
    # The name of the current target of analysis. This field is omitted if
    # analyzing is false.
    @analysisTarget.setter
    def analysisTarget(self, value):
        self._analysisTarget = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            isAnalyzing = None
            if "isAnalyzing" in json_data:
                isAnalyzing = (json_data["isAnalyzing"])
            else:
                raise Exception('missing key: "isAnalyzing"')
            analysisTarget = None
            if "analysisTarget" in json_data:
                analysisTarget = (json_data["analysisTarget"])

            return AnalysisStatus(isAnalyzing, analysisTarget=analysisTarget)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["isAnalyzing"] = self.isAnalyzing
        if self.analysisTarget is not None:
            result["analysisTarget"] = self.analysisTarget
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# ChangeContentOverlay
#
# {
#   "type": "change"
#   "edits": List<SourceEdit>
# }
#
# Clients may not extend, implement or mix-in this class.
class ChangeContentOverlay(HasToJson):

    def __init__(self, edits):
        self._edits = edits
    # The edits to be applied to the file.
    @property
    def edits(self):
        return self._edits
    # The edits to be applied to the file.
    @edits.setter
    def edits(self, value):
        assert value is not None
        self._edits = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            if json_data["type"] != "change":
                raise ValueError("equal " + "change" + " " + str(json_data))
            edits = None
            if "edits" in json_data:
                edits = [SourceEdit.from_json(item) for item in json_data["edits"]]
            else:
                raise Exception('missing key: "edits"')
            return ChangeContentOverlay(edits)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["type"] = "change"
        result["edits"] = [x.to_json() for x in self.edits]
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# CompletionSuggestion
#
# {
#   "kind": CompletionSuggestionKind
#   "relevance": int
#   "completion": String
#   "selectionOffset": int
#   "selectionLength": int
#   "isDeprecated": bool
#   "isPotential": bool
#   "docSummary": optional String
#   "docComplete": optional String
#   "declaringType": optional String
#   "element": optional Element
#   "returnType": optional String
#   "parameterNames": optional List<String>
#   "parameterTypes": optional List<String>
#   "requiredParameterCount": optional int
#   "hasNamedParameters": optional bool
#   "parameterName": optional String
#   "parameterType": optional String
#   "importUri": optional String
# }
#
# Clients may not extend, implement or mix-in this class.
class CompletionSuggestion(HasToJson):

    def __init__(self, kind, relevance, completion, selectionOffset, selectionLength, isDeprecated, isPotential, docSummary=None, docComplete=None, declaringType=None, element=None, returnType=None, parameterNames=None, parameterTypes=None, requiredParameterCount=None, hasNamedParameters=None, parameterName=None, parameterType=None, importUri=None):
        self._kind = kind
        self._relevance = relevance
        self._completion = completion
        self._selectionOffset = selectionOffset
        self._selectionLength = selectionLength
        self._isDeprecated = isDeprecated
        self._isPotential = isPotential
        self._docSummary = docSummary
        self._docComplete = docComplete
        self._declaringType = declaringType
        self._element = element
        self._returnType = returnType
        self._parameterNames = parameterNames
        self._parameterTypes = parameterTypes
        self._requiredParameterCount = requiredParameterCount
        self._hasNamedParameters = hasNamedParameters
        self._parameterName = parameterName
        self._parameterType = parameterType
        self._importUri = importUri
    # The kind of element being suggested.
    @property
    def kind(self):
        return self._kind
    # The kind of element being suggested.
    @kind.setter
    def kind(self, value):
        assert value is not None
        self._kind = value

    # The relevance of this completion suggestion where a higher number
    # indicates a higher relevance.
    @property
    def relevance(self):
        return self._relevance
    # The relevance of this completion suggestion where a higher number
    # indicates a higher relevance.
    @relevance.setter
    def relevance(self, value):
        assert value is not None
        self._relevance = value

    # The identifier to be inserted if the suggestion is selected. If the
    # suggestion is for a method or function, the client might want to
    # additionally insert a template for the parameters. The information
    # required in order to do so is contained in other fields.
    @property
    def completion(self):
        return self._completion
    # The identifier to be inserted if the suggestion is selected. If the
    # suggestion is for a method or function, the client might want to
    # additionally insert a template for the parameters. The information
    # required in order to do so is contained in other fields.
    @completion.setter
    def completion(self, value):
        assert value is not None
        self._completion = value

    # The offset, relative to the beginning of the completion, of where the
    # selection should be placed after insertion.
    @property
    def selectionOffset(self):
        return self._selectionOffset
    # The offset, relative to the beginning of the completion, of where the
    # selection should be placed after insertion.
    @selectionOffset.setter
    def selectionOffset(self, value):
        assert value is not None
        self._selectionOffset = value

    # The number of characters that should be selected after insertion.
    @property
    def selectionLength(self):
        return self._selectionLength
    # The number of characters that should be selected after insertion.
    @selectionLength.setter
    def selectionLength(self, value):
        assert value is not None
        self._selectionLength = value

    # True if the suggested element is deprecated.
    @property
    def isDeprecated(self):
        return self._isDeprecated
    # True if the suggested element is deprecated.
    @isDeprecated.setter
    def isDeprecated(self, value):
        assert value is not None
        self._isDeprecated = value

    # True if the element is not known to be valid for the target. This happens
    # if the type of the target is dynamic.
    @property
    def isPotential(self):
        return self._isPotential
    # True if the element is not known to be valid for the target. This happens
    # if the type of the target is dynamic.
    @isPotential.setter
    def isPotential(self, value):
        assert value is not None
        self._isPotential = value

    # An abbreviated version of the Dartdoc associated with the element being
    # suggested, This field is omitted if there is no Dartdoc associated with
    # the element.
    @property
    def docSummary(self):
        return self._docSummary
    # An abbreviated version of the Dartdoc associated with the element being
    # suggested, This field is omitted if there is no Dartdoc associated with
    # the element.
    @docSummary.setter
    def docSummary(self, value):
        self._docSummary = value

    # The Dartdoc associated with the element being suggested, This field is
    # omitted if there is no Dartdoc associated with the element.
    @property
    def docComplete(self):
        return self._docComplete
    # The Dartdoc associated with the element being suggested, This field is
    # omitted if there is no Dartdoc associated with the element.
    @docComplete.setter
    def docComplete(self, value):
        self._docComplete = value

    # The class that declares the element being suggested. This field is
    # omitted if the suggested element is not a member of a class.
    @property
    def declaringType(self):
        return self._declaringType
    # The class that declares the element being suggested. This field is
    # omitted if the suggested element is not a member of a class.
    @declaringType.setter
    def declaringType(self, value):
        self._declaringType = value

    # Information about the element reference being suggested.
    @property
    def element(self):
        return self._element
    # Information about the element reference being suggested.
    @element.setter
    def element(self, value):
        self._element = value

    # The return type of the getter, function or method or the type of the
    # field being suggested. This field is omitted if the suggested element is
    # not a getter, function or method.
    @property
    def returnType(self):
        return self._returnType
    # The return type of the getter, function or method or the type of the
    # field being suggested. This field is omitted if the suggested element is
    # not a getter, function or method.
    @returnType.setter
    def returnType(self, value):
        self._returnType = value

    # The names of the parameters of the function or method being suggested.
    # This field is omitted if the suggested element is not a setter, function
    # or method.
    @property
    def parameterNames(self):
        return self._parameterNames
    # The names of the parameters of the function or method being suggested.
    # This field is omitted if the suggested element is not a setter, function
    # or method.
    @parameterNames.setter
    def parameterNames(self, value):
        self._parameterNames = value

    # The types of the parameters of the function or method being suggested.
    # This field is omitted if the parameterNames field is omitted.
    @property
    def parameterTypes(self):
        return self._parameterTypes
    # The types of the parameters of the function or method being suggested.
    # This field is omitted if the parameterNames field is omitted.
    @parameterTypes.setter
    def parameterTypes(self, value):
        self._parameterTypes = value

    # The number of required parameters for the function or method being
    # suggested. This field is omitted if the parameterNames field is omitted.
    @property
    def requiredParameterCount(self):
        return self._requiredParameterCount
    # The number of required parameters for the function or method being
    # suggested. This field is omitted if the parameterNames field is omitted.
    @requiredParameterCount.setter
    def requiredParameterCount(self, value):
        self._requiredParameterCount = value

    # True if the function or method being suggested has at least one named
    # parameter. This field is omitted if the parameterNames field is omitted.
    @property
    def hasNamedParameters(self):
        return self._hasNamedParameters
    # True if the function or method being suggested has at least one named
    # parameter. This field is omitted if the parameterNames field is omitted.
    @hasNamedParameters.setter
    def hasNamedParameters(self, value):
        self._hasNamedParameters = value

    # The name of the optional parameter being suggested. This field is omitted
    # if the suggestion is not the addition of an optional argument within an
    # argument list.
    @property
    def parameterName(self):
        return self._parameterName
    # The name of the optional parameter being suggested. This field is omitted
    # if the suggestion is not the addition of an optional argument within an
    # argument list.
    @parameterName.setter
    def parameterName(self, value):
        self._parameterName = value

    # The type of the options parameter being suggested. This field is omitted
    # if the parameterName field is omitted.
    @property
    def parameterType(self):
        return self._parameterType
    # The type of the options parameter being suggested. This field is omitted
    # if the parameterName field is omitted.
    @parameterType.setter
    def parameterType(self, value):
        self._parameterType = value

    # The import to be added if the suggestion is out of scope and needs an
    # import to be added to be in scope.
    @property
    def importUri(self):
        return self._importUri
    # The import to be added if the suggestion is out of scope and needs an
    # import to be added to be in scope.
    @importUri.setter
    def importUri(self, value):
        self._importUri = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            kind = None
            if "kind" in json_data:
                kind = json_data["kind"]
            else:
                raise Exception('missing key: "kind"')
            relevance = None
            if "relevance" in json_data:
                relevance = (json_data["relevance"])
            else:
                raise Exception('missing key: "relevance"')
            completion = None
            if "completion" in json_data:
                completion = (json_data["completion"])
            else:
                raise Exception('missing key: "completion"')
            selectionOffset = None
            if "selectionOffset" in json_data:
                selectionOffset = (json_data["selectionOffset"])
            else:
                raise Exception('missing key: "selectionOffset"')
            selectionLength = None
            if "selectionLength" in json_data:
                selectionLength = (json_data["selectionLength"])
            else:
                raise Exception('missing key: "selectionLength"')
            isDeprecated = None
            if "isDeprecated" in json_data:
                isDeprecated = (json_data["isDeprecated"])
            else:
                raise Exception('missing key: "isDeprecated"')
            isPotential = None
            if "isPotential" in json_data:
                isPotential = (json_data["isPotential"])
            else:
                raise Exception('missing key: "isPotential"')
            docSummary = None
            if "docSummary" in json_data:
                docSummary = (json_data["docSummary"])

            docComplete = None
            if "docComplete" in json_data:
                docComplete = (json_data["docComplete"])

            declaringType = None
            if "declaringType" in json_data:
                declaringType = (json_data["declaringType"])

            element = None
            if "element" in json_data:
                element = Element.from_json(json_data["element"])

            returnType = None
            if "returnType" in json_data:
                returnType = (json_data["returnType"])

            parameterNames = None
            if "parameterNames" in json_data:
                parameterNames = [(item) for item in json_data["parameterNames"]]

            parameterTypes = None
            if "parameterTypes" in json_data:
                parameterTypes = [(item) for item in json_data["parameterTypes"]]

            requiredParameterCount = None
            if "requiredParameterCount" in json_data:
                requiredParameterCount = (json_data["requiredParameterCount"])

            hasNamedParameters = None
            if "hasNamedParameters" in json_data:
                hasNamedParameters = (json_data["hasNamedParameters"])

            parameterName = None
            if "parameterName" in json_data:
                parameterName = (json_data["parameterName"])

            parameterType = None
            if "parameterType" in json_data:
                parameterType = (json_data["parameterType"])

            importUri = None
            if "importUri" in json_data:
                importUri = (json_data["importUri"])

            return CompletionSuggestion(kind, relevance, completion, selectionOffset, selectionLength, isDeprecated, isPotential, docSummary=docSummary, docComplete=docComplete, declaringType=declaringType, element=element, returnType=returnType, parameterNames=parameterNames, parameterTypes=parameterTypes, requiredParameterCount=requiredParameterCount, hasNamedParameters=hasNamedParameters, parameterName=parameterName, parameterType=parameterType, importUri=importUri)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["kind"] = kind.to_json()
        result["relevance"] = self.relevance
        result["completion"] = self.completion
        result["selectionOffset"] = self.selectionOffset
        result["selectionLength"] = self.selectionLength
        result["isDeprecated"] = self.isDeprecated
        result["isPotential"] = self.isPotential
        if self.docSummary is not None:
            result["docSummary"] = self.docSummary
        if self.docComplete is not None:
            result["docComplete"] = self.docComplete
        if self.declaringType is not None:
            result["declaringType"] = self.declaringType
        if self.element is not None:
            result["element"] = element.to_json()
        if self.returnType is not None:
            result["returnType"] = self.returnType
        if self.parameterNames is not None:
            result["parameterNames"] = self.parameterNames
        if self.parameterTypes is not None:
            result["parameterTypes"] = self.parameterTypes
        if self.requiredParameterCount is not None:
            result["requiredParameterCount"] = self.requiredParameterCount
        if self.hasNamedParameters is not None:
            result["hasNamedParameters"] = self.hasNamedParameters
        if self.parameterName is not None:
            result["parameterName"] = self.parameterName
        if self.parameterType is not None:
            result["parameterType"] = self.parameterType
        if self.importUri is not None:
            result["importUri"] = self.importUri
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# CompletionSuggestionKind
#
# enum {
#   ARGUMENT_LIST
#   IMPORT
#   IDENTIFIER
#   INVOCATION
#   KEYWORD
#   NAMED_ARGUMENT
#   OPTIONAL_ARGUMENT
#   PARAMETER
# }
#
# Clients may not extend, implement or mix-in this class.
class CompletionSuggestionKind:
    # A list of arguments for the method or function that is being invoked. For
    # this suggestion kind, the completion field is a textual representation of
    # the invocation and the parameterNames, parameterTypes, and
    # requiredParameterCount attributes are defined.
    ARGUMENT_LIST = "ARGUMENT_LIST"
    IMPORT = "IMPORT"
    # The element identifier should be inserted at the completion location. For
    # example "someMethod" in import 'myLib.dart' show someMethod; . For
    # suggestions of this kind, the element attribute is defined and the
    # completion field is the element's identifier.
    IDENTIFIER = "IDENTIFIER"
    # The element is being invoked at the completion location. For example,
    # "someMethod" in x.someMethod(); . For suggestions of this kind, the
    # element attribute is defined and the completion field is the element's
    # identifier.
    INVOCATION = "INVOCATION"
    # A keyword is being suggested. For suggestions of this kind, the
    # completion is the keyword.
    KEYWORD = "KEYWORD"
    # A named argument for the current callsite is being suggested. For
    # suggestions of this kind, the completion is the named argument identifier
    # including a trailing ':' and space.
    NAMED_ARGUMENT = "NAMED_ARGUMENT"
    OPTIONAL_ARGUMENT = "OPTIONAL_ARGUMENT"
    PARAMETER = "PARAMETER"

# ContextData
#
# {
#   "name": String
#   "explicitFileCount": int
#   "implicitFileCount": int
#   "workItemQueueLength": int
#   "cacheEntryExceptions": List<String>
# }
#
# Clients may not extend, implement or mix-in this class.
class ContextData(HasToJson):

    def __init__(self, name, explicitFileCount, implicitFileCount, workItemQueueLength, cacheEntryExceptions):
        self._name = name
        self._explicitFileCount = explicitFileCount
        self._implicitFileCount = implicitFileCount
        self._workItemQueueLength = workItemQueueLength
        self._cacheEntryExceptions = cacheEntryExceptions
    # The name of the context.
    @property
    def name(self):
        return self._name
    # The name of the context.
    @name.setter
    def name(self, value):
        assert value is not None
        self._name = value

    # Explicitly analyzed files.
    @property
    def explicitFileCount(self):
        return self._explicitFileCount
    # Explicitly analyzed files.
    @explicitFileCount.setter
    def explicitFileCount(self, value):
        assert value is not None
        self._explicitFileCount = value

    # Implicitly analyzed files.
    @property
    def implicitFileCount(self):
        return self._implicitFileCount
    # Implicitly analyzed files.
    @implicitFileCount.setter
    def implicitFileCount(self, value):
        assert value is not None
        self._implicitFileCount = value

    # The number of work items in the queue.
    @property
    def workItemQueueLength(self):
        return self._workItemQueueLength
    # The number of work items in the queue.
    @workItemQueueLength.setter
    def workItemQueueLength(self, value):
        assert value is not None
        self._workItemQueueLength = value

    # Exceptions associated with cache entries.
    @property
    def cacheEntryExceptions(self):
        return self._cacheEntryExceptions
    # Exceptions associated with cache entries.
    @cacheEntryExceptions.setter
    def cacheEntryExceptions(self, value):
        assert value is not None
        self._cacheEntryExceptions = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            name = None
            if "name" in json_data:
                name = (json_data["name"])
            else:
                raise Exception('missing key: "name"')
            explicitFileCount = None
            if "explicitFileCount" in json_data:
                explicitFileCount = (json_data["explicitFileCount"])
            else:
                raise Exception('missing key: "explicitFileCount"')
            implicitFileCount = None
            if "implicitFileCount" in json_data:
                implicitFileCount = (json_data["implicitFileCount"])
            else:
                raise Exception('missing key: "implicitFileCount"')
            workItemQueueLength = None
            if "workItemQueueLength" in json_data:
                workItemQueueLength = (json_data["workItemQueueLength"])
            else:
                raise Exception('missing key: "workItemQueueLength"')
            cacheEntryExceptions = None
            if "cacheEntryExceptions" in json_data:
                cacheEntryExceptions = [(item) for item in json_data["cacheEntryExceptions"]]
            else:
                raise Exception('missing key: "cacheEntryExceptions"')
            return ContextData(name, explicitFileCount, implicitFileCount, workItemQueueLength, cacheEntryExceptions)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["name"] = self.name
        result["explicitFileCount"] = self.explicitFileCount
        result["implicitFileCount"] = self.implicitFileCount
        result["workItemQueueLength"] = self.workItemQueueLength
        result["cacheEntryExceptions"] = self.cacheEntryExceptions
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# Element
#
# {
#   "kind": ElementKind
#   "name": String
#   "location": optional Location
#   "flags": int
#   "parameters": optional String
#   "returnType": optional String
#   "typeParameters": optional String
# }
#
# Clients may not extend, implement or mix-in this class.
class Element(HasToJson):

    FLAG_ABSTRACT = 0x01
    FLAG_CONST = 0x02
    FLAG_FINAL = 0x04
    FLAG_STATIC = 0x08
    FLAG_PRIVATE = 0x10
    FLAG_DEPRECATED = 0x20

    def make_flags(isAbstract=False, isConst=False, isFinal=False, isStatic=False, isPrivate=False, isDeprecated=False):
        flags = 0
        if (isAbstract): flags |= Element.FLAG_ABSTRACT
        if (isConst): flags |= Element.FLAG_CONST
        if (isFinal): flags |= Element.FLAG_FINAL
        if (isStatic): flags |= Element.FLAG_STATIC
        if (isPrivate): flags |= Element.FLAG_PRIVATE
        if (isDeprecated): flags |= Element.FLAG_DEPRECATED
        return flags

    def __init__(self, kind, name, flags, location=None, parameters=None, returnType=None, typeParameters=None):
        self._kind = kind
        self._name = name
        self._location = location
        self._flags = flags
        self._parameters = parameters
        self._returnType = returnType
        self._typeParameters = typeParameters
    # The kind of the element.
    @property
    def kind(self):
        return self._kind
    # The kind of the element.
    @kind.setter
    def kind(self, value):
        assert value is not None
        self._kind = value

    # The name of the element. This is typically used as the label in the
    # outline.
    @property
    def name(self):
        return self._name
    # The name of the element. This is typically used as the label in the
    # outline.
    @name.setter
    def name(self, value):
        assert value is not None
        self._name = value

    # The location of the name in the declaration of the element.
    @property
    def location(self):
        return self._location
    # The location of the name in the declaration of the element.
    @location.setter
    def location(self, value):
        self._location = value

    # A bit-map containing the following flags:
    #
    # - 0x01 - set if the element is explicitly or implicitly abstract
    # - 0x02 - set if the element was declared to be ‘const’
    # - 0x04 - set if the element was declared to be ‘final’
    # - 0x08 - set if the element is a static member of a class or is a
    #   top-level function or field
    # - 0x10 - set if the element is private
    # - 0x20 - set if the element is deprecated
    @property
    def flags(self):
        return self._flags
    # A bit-map containing the following flags:
    #
    # - 0x01 - set if the element is explicitly or implicitly abstract
    # - 0x02 - set if the element was declared to be ‘const’
    # - 0x04 - set if the element was declared to be ‘final’
    # - 0x08 - set if the element is a static member of a class or is a
    #   top-level function or field
    # - 0x10 - set if the element is private
    # - 0x20 - set if the element is deprecated
    @flags.setter
    def flags(self, value):
        assert value is not None
        self._flags = value

    # The parameter list for the element. If the element is not a method or
    # function this field will not be defined. If the element doesn't have
    # parameters (e.g. getter), this field will not be defined. If the element
    # has zero parameters, this field will have a value of "()".
    @property
    def parameters(self):
        return self._parameters
    # The parameter list for the element. If the element is not a method or
    # function this field will not be defined. If the element doesn't have
    # parameters (e.g. getter), this field will not be defined. If the element
    # has zero parameters, this field will have a value of "()".
    @parameters.setter
    def parameters(self, value):
        self._parameters = value

    # The return type of the element. If the element is not a method or
    # function this field will not be defined. If the element does not have a
    # declared return type, this field will contain an empty string.
    @property
    def returnType(self):
        return self._returnType
    # The return type of the element. If the element is not a method or
    # function this field will not be defined. If the element does not have a
    # declared return type, this field will contain an empty string.
    @returnType.setter
    def returnType(self, value):
        self._returnType = value

    # The type parameter list for the element. If the element doesn't have type
    # parameters, this field will not be defined.
    @property
    def typeParameters(self):
        return self._typeParameters
    # The type parameter list for the element. If the element doesn't have type
    # parameters, this field will not be defined.
    @typeParameters.setter
    def typeParameters(self, value):
        self._typeParameters = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            kind = None
            if "kind" in json_data:
                kind = json_data["kind"]
            else:
                raise Exception('missing key: "kind"')
            name = None
            if "name" in json_data:
                name = (json_data["name"])
            else:
                raise Exception('missing key: "name"')
            location = None
            if "location" in json_data:
                location = Location.from_json(json_data["location"])

            flags = None
            if "flags" in json_data:
                flags = (json_data["flags"])
            else:
                raise Exception('missing key: "flags"')
            parameters = None
            if "parameters" in json_data:
                parameters = (json_data["parameters"])

            returnType = None
            if "returnType" in json_data:
                returnType = (json_data["returnType"])

            typeParameters = None
            if "typeParameters" in json_data:
                typeParameters = (json_data["typeParameters"])

            return Element(kind, name, flags, location=location, parameters=parameters, returnType=returnType, typeParameters=typeParameters)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @property
    def isAbstract(self):
        return (this.flags & Element.FLAG_ABSTRACT) != 0

    @property
    def isConst(self):
        return (this.flags & Element.FLAG_CONST) != 0

    @property
    def isFinal(self):
        return (this.flags & Element.FLAG_FINAL) != 0

    @property
    def isStatic(self):
        return (this.flags & Element.FLAG_STATIC) != 0

    @property
    def isPrivate(self):
        return (this.flags & Element.FLAG_PRIVATE) != 0

    @property
    def isDeprecated(self):
        return (this.flags & Element.FLAG_DEPRECATED) != 0


    def to_json(self):
        result = {}
        result["kind"] = kind.to_json()
        result["name"] = self.name
        if self.location is not None:
            result["location"] = location.to_json()
        result["flags"] = self.flags
        if self.parameters is not None:
            result["parameters"] = self.parameters
        if self.returnType is not None:
            result["returnType"] = self.returnType
        if self.typeParameters is not None:
            result["typeParameters"] = self.typeParameters
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# ElementKind
#
# enum {
#   CLASS
#   CLASS_TYPE_ALIAS
#   COMPILATION_UNIT
#   CONSTRUCTOR
#   ENUM
#   ENUM_CONSTANT
#   FIELD
#   FILE
#   FUNCTION
#   FUNCTION_TYPE_ALIAS
#   GETTER
#   LABEL
#   LIBRARY
#   LOCAL_VARIABLE
#   METHOD
#   PARAMETER
#   PREFIX
#   SETTER
#   TOP_LEVEL_VARIABLE
#   TYPE_PARAMETER
#   UNIT_TEST_GROUP
#   UNIT_TEST_TEST
#   UNKNOWN
# }
#
# Clients may not extend, implement or mix-in this class.
class ElementKind:
    CLASS = "CLASS"
    CLASS_TYPE_ALIAS = "CLASS_TYPE_ALIAS"
    COMPILATION_UNIT = "COMPILATION_UNIT"
    CONSTRUCTOR = "CONSTRUCTOR"
    ENUM = "ENUM"
    ENUM_CONSTANT = "ENUM_CONSTANT"
    FIELD = "FIELD"
    FILE = "FILE"
    FUNCTION = "FUNCTION"
    FUNCTION_TYPE_ALIAS = "FUNCTION_TYPE_ALIAS"
    GETTER = "GETTER"
    LABEL = "LABEL"
    LIBRARY = "LIBRARY"
    LOCAL_VARIABLE = "LOCAL_VARIABLE"
    METHOD = "METHOD"
    PARAMETER = "PARAMETER"
    PREFIX = "PREFIX"
    SETTER = "SETTER"
    TOP_LEVEL_VARIABLE = "TOP_LEVEL_VARIABLE"
    TYPE_PARAMETER = "TYPE_PARAMETER"
    # Deprecated: support for tests was removed.
    UNIT_TEST_GROUP = "UNIT_TEST_GROUP"
    # Deprecated: support for tests was removed.
    UNIT_TEST_TEST = "UNIT_TEST_TEST"
    UNKNOWN = "UNKNOWN"

# ExecutableFile
#
# {
#   "file": FilePath
#   "kind": ExecutableKind
# }
#
# Clients may not extend, implement or mix-in this class.
class ExecutableFile(HasToJson):

    def __init__(self, file, kind):
        self._file = file
        self._kind = kind
    # The path of the executable file.
    @property
    def file(self):
        return self._file
    # The path of the executable file.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    # The kind of the executable file.
    @property
    def kind(self):
        return self._kind
    # The kind of the executable file.
    @kind.setter
    def kind(self, value):
        assert value is not None
        self._kind = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            kind = None
            if "kind" in json_data:
                kind = json_data["kind"]
            else:
                raise Exception('missing key: "kind"')
            return ExecutableFile(file, kind)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["file"] = self.file
        result["kind"] = kind.to_json()
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# ExecutableKind
#
# enum {
#   CLIENT
#   EITHER
#   NOT_EXECUTABLE
#   SERVER
# }
#
# Clients may not extend, implement or mix-in this class.
class ExecutableKind:
    CLIENT = "CLIENT"
    EITHER = "EITHER"
    NOT_EXECUTABLE = "NOT_EXECUTABLE"
    SERVER = "SERVER"

# ExecutionService
#
# enum {
#   LAUNCH_DATA
# }
#
# Clients may not extend, implement or mix-in this class.
class ExecutionService:
    LAUNCH_DATA = "LAUNCH_DATA"

# FileKind
#
# enum {
#   LIBRARY
#   PART
# }
#
# Clients may not extend, implement or mix-in this class.
class FileKind:
    LIBRARY = "LIBRARY"
    PART = "PART"

# FoldingKind
#
# enum {
#   COMMENT
#   CLASS_MEMBER
#   DIRECTIVES
#   DOCUMENTATION_COMMENT
#   TOP_LEVEL_DECLARATION
# }
#
# Clients may not extend, implement or mix-in this class.
class FoldingKind:
    COMMENT = "COMMENT"
    CLASS_MEMBER = "CLASS_MEMBER"
    DIRECTIVES = "DIRECTIVES"
    DOCUMENTATION_COMMENT = "DOCUMENTATION_COMMENT"
    TOP_LEVEL_DECLARATION = "TOP_LEVEL_DECLARATION"

# FoldingRegion
#
# {
#   "kind": FoldingKind
#   "offset": int
#   "length": int
# }
#
# Clients may not extend, implement or mix-in this class.
class FoldingRegion(HasToJson):

    def __init__(self, kind, offset, length):
        self._kind = kind
        self._offset = offset
        self._length = length
    # The kind of the region.
    @property
    def kind(self):
        return self._kind
    # The kind of the region.
    @kind.setter
    def kind(self, value):
        assert value is not None
        self._kind = value

    # The offset of the region to be folded.
    @property
    def offset(self):
        return self._offset
    # The offset of the region to be folded.
    @offset.setter
    def offset(self, value):
        assert value is not None
        self._offset = value

    # The length of the region to be folded.
    @property
    def length(self):
        return self._length
    # The length of the region to be folded.
    @length.setter
    def length(self, value):
        assert value is not None
        self._length = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            kind = None
            if "kind" in json_data:
                kind = json_data["kind"]
            else:
                raise Exception('missing key: "kind"')
            offset = None
            if "offset" in json_data:
                offset = (json_data["offset"])
            else:
                raise Exception('missing key: "offset"')
            length = None
            if "length" in json_data:
                length = (json_data["length"])
            else:
                raise Exception('missing key: "length"')
            return FoldingRegion(kind, offset, length)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["kind"] = kind.to_json()
        result["offset"] = self.offset
        result["length"] = self.length
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# GeneralAnalysisService
#
# enum {
#   ANALYZED_FILES
# }
#
# Clients may not extend, implement or mix-in this class.
class GeneralAnalysisService:
    ANALYZED_FILES = "ANALYZED_FILES"

# HighlightRegion
#
# {
#   "type": HighlightRegionType
#   "offset": int
#   "length": int
# }
#
# Clients may not extend, implement or mix-in this class.
class HighlightRegion(HasToJson):

    def __init__(self, type, offset, length):
        self._type = type
        self._offset = offset
        self._length = length
    # The type of highlight associated with the region.
    @property
    def type(self):
        return self._type
    # The type of highlight associated with the region.
    @type.setter
    def type(self, value):
        assert value is not None
        self._type = value

    # The offset of the region to be highlighted.
    @property
    def offset(self):
        return self._offset
    # The offset of the region to be highlighted.
    @offset.setter
    def offset(self, value):
        assert value is not None
        self._offset = value

    # The length of the region to be highlighted.
    @property
    def length(self):
        return self._length
    # The length of the region to be highlighted.
    @length.setter
    def length(self, value):
        assert value is not None
        self._length = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            type = None
            if "type" in json_data:
                type = json_data["type"]
            else:
                raise Exception('missing key: "type"')
            offset = None
            if "offset" in json_data:
                offset = (json_data["offset"])
            else:
                raise Exception('missing key: "offset"')
            length = None
            if "length" in json_data:
                length = (json_data["length"])
            else:
                raise Exception('missing key: "length"')
            return HighlightRegion(type, offset, length)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["type"] = type.to_json()
        result["offset"] = self.offset
        result["length"] = self.length
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# HighlightRegionType
#
# enum {
#   ANNOTATION
#   BUILT_IN
#   CLASS
#   COMMENT_BLOCK
#   COMMENT_DOCUMENTATION
#   COMMENT_END_OF_LINE
#   CONSTRUCTOR
#   DIRECTIVE
#   DYNAMIC_TYPE
#   DYNAMIC_LOCAL_VARIABLE_DECLARATION
#   DYNAMIC_LOCAL_VARIABLE_REFERENCE
#   DYNAMIC_PARAMETER_DECLARATION
#   DYNAMIC_PARAMETER_REFERENCE
#   ENUM
#   ENUM_CONSTANT
#   FIELD
#   FIELD_STATIC
#   FUNCTION
#   FUNCTION_DECLARATION
#   FUNCTION_TYPE_ALIAS
#   GETTER_DECLARATION
#   IDENTIFIER_DEFAULT
#   IMPORT_PREFIX
#   INSTANCE_FIELD_DECLARATION
#   INSTANCE_FIELD_REFERENCE
#   INSTANCE_GETTER_DECLARATION
#   INSTANCE_GETTER_REFERENCE
#   INSTANCE_METHOD_DECLARATION
#   INSTANCE_METHOD_REFERENCE
#   INSTANCE_SETTER_DECLARATION
#   INSTANCE_SETTER_REFERENCE
#   INVALID_STRING_ESCAPE
#   KEYWORD
#   LABEL
#   LIBRARY_NAME
#   LITERAL_BOOLEAN
#   LITERAL_DOUBLE
#   LITERAL_INTEGER
#   LITERAL_LIST
#   LITERAL_MAP
#   LITERAL_STRING
#   LOCAL_FUNCTION_DECLARATION
#   LOCAL_FUNCTION_REFERENCE
#   LOCAL_VARIABLE
#   LOCAL_VARIABLE_DECLARATION
#   LOCAL_VARIABLE_REFERENCE
#   METHOD
#   METHOD_DECLARATION
#   METHOD_DECLARATION_STATIC
#   METHOD_STATIC
#   PARAMETER
#   SETTER_DECLARATION
#   TOP_LEVEL_VARIABLE
#   PARAMETER_DECLARATION
#   PARAMETER_REFERENCE
#   STATIC_FIELD_DECLARATION
#   STATIC_GETTER_DECLARATION
#   STATIC_GETTER_REFERENCE
#   STATIC_METHOD_DECLARATION
#   STATIC_METHOD_REFERENCE
#   STATIC_SETTER_DECLARATION
#   STATIC_SETTER_REFERENCE
#   TOP_LEVEL_FUNCTION_DECLARATION
#   TOP_LEVEL_FUNCTION_REFERENCE
#   TOP_LEVEL_GETTER_DECLARATION
#   TOP_LEVEL_GETTER_REFERENCE
#   TOP_LEVEL_SETTER_DECLARATION
#   TOP_LEVEL_SETTER_REFERENCE
#   TOP_LEVEL_VARIABLE_DECLARATION
#   TYPE_NAME_DYNAMIC
#   TYPE_PARAMETER
#   UNRESOLVED_INSTANCE_MEMBER_REFERENCE
#   VALID_STRING_ESCAPE
# }
#
# Clients may not extend, implement or mix-in this class.
class HighlightRegionType:
    ANNOTATION = "ANNOTATION"
    BUILT_IN = "BUILT_IN"
    CLASS = "CLASS"
    COMMENT_BLOCK = "COMMENT_BLOCK"
    COMMENT_DOCUMENTATION = "COMMENT_DOCUMENTATION"
    COMMENT_END_OF_LINE = "COMMENT_END_OF_LINE"
    CONSTRUCTOR = "CONSTRUCTOR"
    DIRECTIVE = "DIRECTIVE"
    # Only for version 1 of highlight.
    DYNAMIC_TYPE = "DYNAMIC_TYPE"
    # Only for version 2 of highlight.
    DYNAMIC_LOCAL_VARIABLE_DECLARATION = "DYNAMIC_LOCAL_VARIABLE_DECLARATION"
    # Only for version 2 of highlight.
    DYNAMIC_LOCAL_VARIABLE_REFERENCE = "DYNAMIC_LOCAL_VARIABLE_REFERENCE"
    # Only for version 2 of highlight.
    DYNAMIC_PARAMETER_DECLARATION = "DYNAMIC_PARAMETER_DECLARATION"
    # Only for version 2 of highlight.
    DYNAMIC_PARAMETER_REFERENCE = "DYNAMIC_PARAMETER_REFERENCE"
    ENUM = "ENUM"
    ENUM_CONSTANT = "ENUM_CONSTANT"
    # Only for version 1 of highlight.
    FIELD = "FIELD"
    # Only for version 1 of highlight.
    FIELD_STATIC = "FIELD_STATIC"
    # Only for version 1 of highlight.
    FUNCTION = "FUNCTION"
    # Only for version 1 of highlight.
    FUNCTION_DECLARATION = "FUNCTION_DECLARATION"
    FUNCTION_TYPE_ALIAS = "FUNCTION_TYPE_ALIAS"
    # Only for version 1 of highlight.
    GETTER_DECLARATION = "GETTER_DECLARATION"
    IDENTIFIER_DEFAULT = "IDENTIFIER_DEFAULT"
    IMPORT_PREFIX = "IMPORT_PREFIX"
    # Only for version 2 of highlight.
    INSTANCE_FIELD_DECLARATION = "INSTANCE_FIELD_DECLARATION"
    # Only for version 2 of highlight.
    INSTANCE_FIELD_REFERENCE = "INSTANCE_FIELD_REFERENCE"
    # Only for version 2 of highlight.
    INSTANCE_GETTER_DECLARATION = "INSTANCE_GETTER_DECLARATION"
    # Only for version 2 of highlight.
    INSTANCE_GETTER_REFERENCE = "INSTANCE_GETTER_REFERENCE"
    # Only for version 2 of highlight.
    INSTANCE_METHOD_DECLARATION = "INSTANCE_METHOD_DECLARATION"
    # Only for version 2 of highlight.
    INSTANCE_METHOD_REFERENCE = "INSTANCE_METHOD_REFERENCE"
    # Only for version 2 of highlight.
    INSTANCE_SETTER_DECLARATION = "INSTANCE_SETTER_DECLARATION"
    # Only for version 2 of highlight.
    INSTANCE_SETTER_REFERENCE = "INSTANCE_SETTER_REFERENCE"
    # Only for version 2 of highlight.
    INVALID_STRING_ESCAPE = "INVALID_STRING_ESCAPE"
    KEYWORD = "KEYWORD"
    LABEL = "LABEL"
    # Only for version 2 of highlight.
    LIBRARY_NAME = "LIBRARY_NAME"
    LITERAL_BOOLEAN = "LITERAL_BOOLEAN"
    LITERAL_DOUBLE = "LITERAL_DOUBLE"
    LITERAL_INTEGER = "LITERAL_INTEGER"
    LITERAL_LIST = "LITERAL_LIST"
    LITERAL_MAP = "LITERAL_MAP"
    LITERAL_STRING = "LITERAL_STRING"
    # Only for version 2 of highlight.
    LOCAL_FUNCTION_DECLARATION = "LOCAL_FUNCTION_DECLARATION"
    # Only for version 2 of highlight.
    LOCAL_FUNCTION_REFERENCE = "LOCAL_FUNCTION_REFERENCE"
    # Only for version 1 of highlight.
    LOCAL_VARIABLE = "LOCAL_VARIABLE"
    LOCAL_VARIABLE_DECLARATION = "LOCAL_VARIABLE_DECLARATION"
    # Only for version 2 of highlight.
    LOCAL_VARIABLE_REFERENCE = "LOCAL_VARIABLE_REFERENCE"
    # Only for version 1 of highlight.
    METHOD = "METHOD"
    # Only for version 1 of highlight.
    METHOD_DECLARATION = "METHOD_DECLARATION"
    # Only for version 1 of highlight.
    METHOD_DECLARATION_STATIC = "METHOD_DECLARATION_STATIC"
    # Only for version 1 of highlight.
    METHOD_STATIC = "METHOD_STATIC"
    # Only for version 1 of highlight.
    PARAMETER = "PARAMETER"
    # Only for version 1 of highlight.
    SETTER_DECLARATION = "SETTER_DECLARATION"
    # Only for version 1 of highlight.
    TOP_LEVEL_VARIABLE = "TOP_LEVEL_VARIABLE"
    # Only for version 2 of highlight.
    PARAMETER_DECLARATION = "PARAMETER_DECLARATION"
    # Only for version 2 of highlight.
    PARAMETER_REFERENCE = "PARAMETER_REFERENCE"
    # Only for version 2 of highlight.
    STATIC_FIELD_DECLARATION = "STATIC_FIELD_DECLARATION"
    # Only for version 2 of highlight.
    STATIC_GETTER_DECLARATION = "STATIC_GETTER_DECLARATION"
    # Only for version 2 of highlight.
    STATIC_GETTER_REFERENCE = "STATIC_GETTER_REFERENCE"
    # Only for version 2 of highlight.
    STATIC_METHOD_DECLARATION = "STATIC_METHOD_DECLARATION"
    # Only for version 2 of highlight.
    STATIC_METHOD_REFERENCE = "STATIC_METHOD_REFERENCE"
    # Only for version 2 of highlight.
    STATIC_SETTER_DECLARATION = "STATIC_SETTER_DECLARATION"
    # Only for version 2 of highlight.
    STATIC_SETTER_REFERENCE = "STATIC_SETTER_REFERENCE"
    # Only for version 2 of highlight.
    TOP_LEVEL_FUNCTION_DECLARATION = "TOP_LEVEL_FUNCTION_DECLARATION"
    # Only for version 2 of highlight.
    TOP_LEVEL_FUNCTION_REFERENCE = "TOP_LEVEL_FUNCTION_REFERENCE"
    # Only for version 2 of highlight.
    TOP_LEVEL_GETTER_DECLARATION = "TOP_LEVEL_GETTER_DECLARATION"
    # Only for version 2 of highlight.
    TOP_LEVEL_GETTER_REFERENCE = "TOP_LEVEL_GETTER_REFERENCE"
    # Only for version 2 of highlight.
    TOP_LEVEL_SETTER_DECLARATION = "TOP_LEVEL_SETTER_DECLARATION"
    # Only for version 2 of highlight.
    TOP_LEVEL_SETTER_REFERENCE = "TOP_LEVEL_SETTER_REFERENCE"
    # Only for version 2 of highlight.
    TOP_LEVEL_VARIABLE_DECLARATION = "TOP_LEVEL_VARIABLE_DECLARATION"
    TYPE_NAME_DYNAMIC = "TYPE_NAME_DYNAMIC"
    TYPE_PARAMETER = "TYPE_PARAMETER"
    # Only for version 2 of highlight.
    UNRESOLVED_INSTANCE_MEMBER_REFERENCE = "UNRESOLVED_INSTANCE_MEMBER_REFERENCE"
    # Only for version 2 of highlight.
    VALID_STRING_ESCAPE = "VALID_STRING_ESCAPE"

# HoverInformation
#
# {
#   "offset": int
#   "length": int
#   "containingLibraryPath": optional String
#   "containingLibraryName": optional String
#   "containingClassDescription": optional String
#   "dartdoc": optional String
#   "elementDescription": optional String
#   "elementKind": optional String
#   "parameter": optional String
#   "propagatedType": optional String
#   "staticType": optional String
# }
#
# Clients may not extend, implement or mix-in this class.
class HoverInformation(HasToJson):

    def __init__(self, offset, length, containingLibraryPath=None, containingLibraryName=None, containingClassDescription=None, dartdoc=None, elementDescription=None, elementKind=None, parameter=None, propagatedType=None, staticType=None):
        self._offset = offset
        self._length = length
        self._containingLibraryPath = containingLibraryPath
        self._containingLibraryName = containingLibraryName
        self._containingClassDescription = containingClassDescription
        self._dartdoc = dartdoc
        self._elementDescription = elementDescription
        self._elementKind = elementKind
        self._parameter = parameter
        self._propagatedType = propagatedType
        self._staticType = staticType
    # The offset of the range of characters that encompasses the cursor
    # position and has the same hover information as the cursor position.
    @property
    def offset(self):
        return self._offset
    # The offset of the range of characters that encompasses the cursor
    # position and has the same hover information as the cursor position.
    @offset.setter
    def offset(self, value):
        assert value is not None
        self._offset = value

    # The length of the range of characters that encompasses the cursor
    # position and has the same hover information as the cursor position.
    @property
    def length(self):
        return self._length
    # The length of the range of characters that encompasses the cursor
    # position and has the same hover information as the cursor position.
    @length.setter
    def length(self, value):
        assert value is not None
        self._length = value

    # The path to the defining compilation unit of the library in which the
    # referenced element is declared. This data is omitted if there is no
    # referenced element, or if the element is declared inside an HTML file.
    @property
    def containingLibraryPath(self):
        return self._containingLibraryPath
    # The path to the defining compilation unit of the library in which the
    # referenced element is declared. This data is omitted if there is no
    # referenced element, or if the element is declared inside an HTML file.
    @containingLibraryPath.setter
    def containingLibraryPath(self, value):
        self._containingLibraryPath = value

    # The name of the library in which the referenced element is declared. This
    # data is omitted if there is no referenced element, or if the element is
    # declared inside an HTML file.
    @property
    def containingLibraryName(self):
        return self._containingLibraryName
    # The name of the library in which the referenced element is declared. This
    # data is omitted if there is no referenced element, or if the element is
    # declared inside an HTML file.
    @containingLibraryName.setter
    def containingLibraryName(self, value):
        self._containingLibraryName = value

    # A human-readable description of the class declaring the element being
    # referenced. This data is omitted if there is no referenced element, or if
    # the element is not a class member.
    @property
    def containingClassDescription(self):
        return self._containingClassDescription
    # A human-readable description of the class declaring the element being
    # referenced. This data is omitted if there is no referenced element, or if
    # the element is not a class member.
    @containingClassDescription.setter
    def containingClassDescription(self, value):
        self._containingClassDescription = value

    # The dartdoc associated with the referenced element. Other than the
    # removal of the comment delimiters, including leading asterisks in the
    # case of a block comment, the dartdoc is unprocessed markdown. This data
    # is omitted if there is no referenced element, or if the element has no
    # dartdoc.
    @property
    def dartdoc(self):
        return self._dartdoc
    # The dartdoc associated with the referenced element. Other than the
    # removal of the comment delimiters, including leading asterisks in the
    # case of a block comment, the dartdoc is unprocessed markdown. This data
    # is omitted if there is no referenced element, or if the element has no
    # dartdoc.
    @dartdoc.setter
    def dartdoc(self, value):
        self._dartdoc = value

    # A human-readable description of the element being referenced. This data
    # is omitted if there is no referenced element.
    @property
    def elementDescription(self):
        return self._elementDescription
    # A human-readable description of the element being referenced. This data
    # is omitted if there is no referenced element.
    @elementDescription.setter
    def elementDescription(self, value):
        self._elementDescription = value

    # A human-readable description of the kind of element being referenced
    # (such as “class” or “function type alias”). This data is omitted if there
    # is no referenced element.
    @property
    def elementKind(self):
        return self._elementKind
    # A human-readable description of the kind of element being referenced
    # (such as “class” or “function type alias”). This data is omitted if there
    # is no referenced element.
    @elementKind.setter
    def elementKind(self, value):
        self._elementKind = value

    # A human-readable description of the parameter corresponding to the
    # expression being hovered over. This data is omitted if the location is
    # not in an argument to a function.
    @property
    def parameter(self):
        return self._parameter
    # A human-readable description of the parameter corresponding to the
    # expression being hovered over. This data is omitted if the location is
    # not in an argument to a function.
    @parameter.setter
    def parameter(self, value):
        self._parameter = value

    # The name of the propagated type of the expression. This data is omitted
    # if the location does not correspond to an expression or if there is no
    # propagated type information.
    @property
    def propagatedType(self):
        return self._propagatedType
    # The name of the propagated type of the expression. This data is omitted
    # if the location does not correspond to an expression or if there is no
    # propagated type information.
    @propagatedType.setter
    def propagatedType(self, value):
        self._propagatedType = value

    # The name of the static type of the expression. This data is omitted if
    # the location does not correspond to an expression.
    @property
    def staticType(self):
        return self._staticType
    # The name of the static type of the expression. This data is omitted if
    # the location does not correspond to an expression.
    @staticType.setter
    def staticType(self, value):
        self._staticType = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            offset = None
            if "offset" in json_data:
                offset = (json_data["offset"])
            else:
                raise Exception('missing key: "offset"')
            length = None
            if "length" in json_data:
                length = (json_data["length"])
            else:
                raise Exception('missing key: "length"')
            containingLibraryPath = None
            if "containingLibraryPath" in json_data:
                containingLibraryPath = (json_data["containingLibraryPath"])

            containingLibraryName = None
            if "containingLibraryName" in json_data:
                containingLibraryName = (json_data["containingLibraryName"])

            containingClassDescription = None
            if "containingClassDescription" in json_data:
                containingClassDescription = (json_data["containingClassDescription"])

            dartdoc = None
            if "dartdoc" in json_data:
                dartdoc = (json_data["dartdoc"])

            elementDescription = None
            if "elementDescription" in json_data:
                elementDescription = (json_data["elementDescription"])

            elementKind = None
            if "elementKind" in json_data:
                elementKind = (json_data["elementKind"])

            parameter = None
            if "parameter" in json_data:
                parameter = (json_data["parameter"])

            propagatedType = None
            if "propagatedType" in json_data:
                propagatedType = (json_data["propagatedType"])

            staticType = None
            if "staticType" in json_data:
                staticType = (json_data["staticType"])

            return HoverInformation(offset, length, containingLibraryPath=containingLibraryPath, containingLibraryName=containingLibraryName, containingClassDescription=containingClassDescription, dartdoc=dartdoc, elementDescription=elementDescription, elementKind=elementKind, parameter=parameter, propagatedType=propagatedType, staticType=staticType)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["offset"] = self.offset
        result["length"] = self.length
        if self.containingLibraryPath is not None:
            result["containingLibraryPath"] = self.containingLibraryPath
        if self.containingLibraryName is not None:
            result["containingLibraryName"] = self.containingLibraryName
        if self.containingClassDescription is not None:
            result["containingClassDescription"] = self.containingClassDescription
        if self.dartdoc is not None:
            result["dartdoc"] = self.dartdoc
        if self.elementDescription is not None:
            result["elementDescription"] = self.elementDescription
        if self.elementKind is not None:
            result["elementKind"] = self.elementKind
        if self.parameter is not None:
            result["parameter"] = self.parameter
        if self.propagatedType is not None:
            result["propagatedType"] = self.propagatedType
        if self.staticType is not None:
            result["staticType"] = self.staticType
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# ImplementedClass
#
# {
#   "offset": int
#   "length": int
# }
#
# Clients may not extend, implement or mix-in this class.
class ImplementedClass(HasToJson):

    def __init__(self, offset, length):
        self._offset = offset
        self._length = length
    # The offset of the name of the implemented class.
    @property
    def offset(self):
        return self._offset
    # The offset of the name of the implemented class.
    @offset.setter
    def offset(self, value):
        assert value is not None
        self._offset = value

    # The length of the name of the implemented class.
    @property
    def length(self):
        return self._length
    # The length of the name of the implemented class.
    @length.setter
    def length(self, value):
        assert value is not None
        self._length = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            offset = None
            if "offset" in json_data:
                offset = (json_data["offset"])
            else:
                raise Exception('missing key: "offset"')
            length = None
            if "length" in json_data:
                length = (json_data["length"])
            else:
                raise Exception('missing key: "length"')
            return ImplementedClass(offset, length)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["offset"] = self.offset
        result["length"] = self.length
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# ImplementedMember
#
# {
#   "offset": int
#   "length": int
# }
#
# Clients may not extend, implement or mix-in this class.
class ImplementedMember(HasToJson):

    def __init__(self, offset, length):
        self._offset = offset
        self._length = length
    # The offset of the name of the implemented member.
    @property
    def offset(self):
        return self._offset
    # The offset of the name of the implemented member.
    @offset.setter
    def offset(self, value):
        assert value is not None
        self._offset = value

    # The length of the name of the implemented member.
    @property
    def length(self):
        return self._length
    # The length of the name of the implemented member.
    @length.setter
    def length(self, value):
        assert value is not None
        self._length = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            offset = None
            if "offset" in json_data:
                offset = (json_data["offset"])
            else:
                raise Exception('missing key: "offset"')
            length = None
            if "length" in json_data:
                length = (json_data["length"])
            else:
                raise Exception('missing key: "length"')
            return ImplementedMember(offset, length)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["offset"] = self.offset
        result["length"] = self.length
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# LinkedEditGroup
#
# {
#   "positions": List<Position>
#   "length": int
#   "suggestions": List<LinkedEditSuggestion>
# }
#
# Clients may not extend, implement or mix-in this class.
class LinkedEditGroup(HasToJson):

    def __init__(self, positions, length, suggestions):
        self._positions = positions
        self._length = length
        self._suggestions = suggestions
    # The positions of the regions that should be edited simultaneously.
    @property
    def positions(self):
        return self._positions
    # The positions of the regions that should be edited simultaneously.
    @positions.setter
    def positions(self, value):
        assert value is not None
        self._positions = value

    # The length of the regions that should be edited simultaneously.
    @property
    def length(self):
        return self._length
    # The length of the regions that should be edited simultaneously.
    @length.setter
    def length(self, value):
        assert value is not None
        self._length = value

    # Pre-computed suggestions for what every region might want to be changed
    # to.
    @property
    def suggestions(self):
        return self._suggestions
    # Pre-computed suggestions for what every region might want to be changed
    # to.
    @suggestions.setter
    def suggestions(self, value):
        assert value is not None
        self._suggestions = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            positions = None
            if "positions" in json_data:
                positions = [Position.from_json(item) for item in json_data["positions"]]
            else:
                raise Exception('missing key: "positions"')
            length = None
            if "length" in json_data:
                length = (json_data["length"])
            else:
                raise Exception('missing key: "length"')
            suggestions = None
            if "suggestions" in json_data:
                suggestions = [LinkedEditSuggestion.from_json(item) for item in json_data["suggestions"]]
            else:
                raise Exception('missing key: "suggestions"')
            return LinkedEditGroup(positions, length, suggestions)
        else:
            raise ValueError("wrong type: %s" % json_data)

    # Construct an empty LinkedEditGroup.
    @staticmethod
    def empty():
        return LinkedEditGroup([], 0, [])

    def to_json(self):
        result = {}
        result["positions"] = [x.to_json() for x in self.positions]
        result["length"] = self.length
        result["suggestions"] = [x.to_json() for x in self.suggestions]
        return result

    # Add a new position and change the length.
    def add_position(self, position, length):
        self.positions.append(position)
        self.length = length;

    # Add a new suggestion.
    def add_suggestion(self, suggestion):
        self.suggestions.append(suggestion);

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# LinkedEditSuggestion
#
# {
#   "value": String
#   "kind": LinkedEditSuggestionKind
# }
#
# Clients may not extend, implement or mix-in this class.
class LinkedEditSuggestion(HasToJson):

    def __init__(self, value, kind):
        self._value = value
        self._kind = kind
    # The value that could be used to replace all of the linked edit regions.
    @property
    def value(self):
        return self._value
    # The value that could be used to replace all of the linked edit regions.
    @value.setter
    def value(self, value):
        assert value is not None
        self._value = value

    # The kind of value being proposed.
    @property
    def kind(self):
        return self._kind
    # The kind of value being proposed.
    @kind.setter
    def kind(self, value):
        assert value is not None
        self._kind = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            value = None
            if "value" in json_data:
                value = (json_data["value"])
            else:
                raise Exception('missing key: "value"')
            kind = None
            if "kind" in json_data:
                kind = json_data["kind"]
            else:
                raise Exception('missing key: "kind"')
            return LinkedEditSuggestion(value, kind)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["value"] = self.value
        result["kind"] = kind.to_json()
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# LinkedEditSuggestionKind
#
# enum {
#   METHOD
#   PARAMETER
#   TYPE
#   VARIABLE
# }
#
# Clients may not extend, implement or mix-in this class.
class LinkedEditSuggestionKind:
    METHOD = "METHOD"
    PARAMETER = "PARAMETER"
    TYPE = "TYPE"
    VARIABLE = "VARIABLE"

# Location
#
# {
#   "file": FilePath
#   "offset": int
#   "length": int
#   "startLine": int
#   "startColumn": int
# }
#
# Clients may not extend, implement or mix-in this class.
class Location(HasToJson):

    def __init__(self, file, offset, length, startLine, startColumn):
        self._file = file
        self._offset = offset
        self._length = length
        self._startLine = startLine
        self._startColumn = startColumn
    # The file containing the range.
    @property
    def file(self):
        return self._file
    # The file containing the range.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    # The offset of the range.
    @property
    def offset(self):
        return self._offset
    # The offset of the range.
    @offset.setter
    def offset(self, value):
        assert value is not None
        self._offset = value

    # The length of the range.
    @property
    def length(self):
        return self._length
    # The length of the range.
    @length.setter
    def length(self, value):
        assert value is not None
        self._length = value

    # The one-based index of the line containing the first character of the
    # range.
    @property
    def startLine(self):
        return self._startLine
    # The one-based index of the line containing the first character of the
    # range.
    @startLine.setter
    def startLine(self, value):
        assert value is not None
        self._startLine = value

    # The one-based index of the column containing the first character of the
    # range.
    @property
    def startColumn(self):
        return self._startColumn
    # The one-based index of the column containing the first character of the
    # range.
    @startColumn.setter
    def startColumn(self, value):
        assert value is not None
        self._startColumn = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            offset = None
            if "offset" in json_data:
                offset = (json_data["offset"])
            else:
                raise Exception('missing key: "offset"')
            length = None
            if "length" in json_data:
                length = (json_data["length"])
            else:
                raise Exception('missing key: "length"')
            startLine = None
            if "startLine" in json_data:
                startLine = (json_data["startLine"])
            else:
                raise Exception('missing key: "startLine"')
            startColumn = None
            if "startColumn" in json_data:
                startColumn = (json_data["startColumn"])
            else:
                raise Exception('missing key: "startColumn"')
            return Location(file, offset, length, startLine, startColumn)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["file"] = self.file
        result["offset"] = self.offset
        result["length"] = self.length
        result["startLine"] = self.startLine
        result["startColumn"] = self.startColumn
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# NavigationRegion
#
# {
#   "offset": int
#   "length": int
#   "targets": List<int>
# }
#
# Clients may not extend, implement or mix-in this class.
class NavigationRegion(HasToJson):

    def __init__(self, offset, length, targets):
        self._offset = offset
        self._length = length
        self._targets = targets
    # The offset of the region from which the user can navigate.
    @property
    def offset(self):
        return self._offset
    # The offset of the region from which the user can navigate.
    @offset.setter
    def offset(self, value):
        assert value is not None
        self._offset = value

    # The length of the region from which the user can navigate.
    @property
    def length(self):
        return self._length
    # The length of the region from which the user can navigate.
    @length.setter
    def length(self, value):
        assert value is not None
        self._length = value

    # The indexes of the targets (in the enclosing navigation response) to
    # which the given region is bound. By opening the target, clients can
    # implement one form of navigation. This list cannot be empty.
    @property
    def targets(self):
        return self._targets
    # The indexes of the targets (in the enclosing navigation response) to
    # which the given region is bound. By opening the target, clients can
    # implement one form of navigation. This list cannot be empty.
    @targets.setter
    def targets(self, value):
        assert value is not None
        self._targets = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            offset = None
            if "offset" in json_data:
                offset = (json_data["offset"])
            else:
                raise Exception('missing key: "offset"')
            length = None
            if "length" in json_data:
                length = (json_data["length"])
            else:
                raise Exception('missing key: "length"')
            targets = None
            if "targets" in json_data:
                targets = [(item) for item in json_data["targets"]]
            else:
                raise Exception('missing key: "targets"')
            return NavigationRegion(offset, length, targets)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["offset"] = self.offset
        result["length"] = self.length
        result["targets"] = self.targets
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# NavigationTarget
#
# {
#   "kind": ElementKind
#   "fileIndex": int
#   "offset": int
#   "length": int
#   "startLine": int
#   "startColumn": int
# }
#
# Clients may not extend, implement or mix-in this class.
class NavigationTarget(HasToJson):

    def __init__(self, kind, fileIndex, offset, length, startLine, startColumn):
        self._kind = kind
        self._fileIndex = fileIndex
        self._offset = offset
        self._length = length
        self._startLine = startLine
        self._startColumn = startColumn
    # The kind of the element.
    @property
    def kind(self):
        return self._kind
    # The kind of the element.
    @kind.setter
    def kind(self, value):
        assert value is not None
        self._kind = value

    # The index of the file (in the enclosing navigation response) to navigate
    # to.
    @property
    def fileIndex(self):
        return self._fileIndex
    # The index of the file (in the enclosing navigation response) to navigate
    # to.
    @fileIndex.setter
    def fileIndex(self, value):
        assert value is not None
        self._fileIndex = value

    # The offset of the region from which the user can navigate.
    @property
    def offset(self):
        return self._offset
    # The offset of the region from which the user can navigate.
    @offset.setter
    def offset(self, value):
        assert value is not None
        self._offset = value

    # The length of the region from which the user can navigate.
    @property
    def length(self):
        return self._length
    # The length of the region from which the user can navigate.
    @length.setter
    def length(self, value):
        assert value is not None
        self._length = value

    # The one-based index of the line containing the first character of the
    # region.
    @property
    def startLine(self):
        return self._startLine
    # The one-based index of the line containing the first character of the
    # region.
    @startLine.setter
    def startLine(self, value):
        assert value is not None
        self._startLine = value

    # The one-based index of the column containing the first character of the
    # region.
    @property
    def startColumn(self):
        return self._startColumn
    # The one-based index of the column containing the first character of the
    # region.
    @startColumn.setter
    def startColumn(self, value):
        assert value is not None
        self._startColumn = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            kind = None
            if "kind" in json_data:
                kind = json_data["kind"]
            else:
                raise Exception('missing key: "kind"')
            fileIndex = None
            if "fileIndex" in json_data:
                fileIndex = (json_data["fileIndex"])
            else:
                raise Exception('missing key: "fileIndex"')
            offset = None
            if "offset" in json_data:
                offset = (json_data["offset"])
            else:
                raise Exception('missing key: "offset"')
            length = None
            if "length" in json_data:
                length = (json_data["length"])
            else:
                raise Exception('missing key: "length"')
            startLine = None
            if "startLine" in json_data:
                startLine = (json_data["startLine"])
            else:
                raise Exception('missing key: "startLine"')
            startColumn = None
            if "startColumn" in json_data:
                startColumn = (json_data["startColumn"])
            else:
                raise Exception('missing key: "startColumn"')
            return NavigationTarget(kind, fileIndex, offset, length, startLine, startColumn)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["kind"] = kind.to_json()
        result["fileIndex"] = self.fileIndex
        result["offset"] = self.offset
        result["length"] = self.length
        result["startLine"] = self.startLine
        result["startColumn"] = self.startColumn
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# Occurrences
#
# {
#   "element": Element
#   "offsets": List<int>
#   "length": int
# }
#
# Clients may not extend, implement or mix-in this class.
class Occurrences(HasToJson):

    def __init__(self, element, offsets, length):
        self._element = element
        self._offsets = offsets
        self._length = length
    # The element that was referenced.
    @property
    def element(self):
        return self._element
    # The element that was referenced.
    @element.setter
    def element(self, value):
        assert value is not None
        self._element = value

    # The offsets of the name of the referenced element within the file.
    @property
    def offsets(self):
        return self._offsets
    # The offsets of the name of the referenced element within the file.
    @offsets.setter
    def offsets(self, value):
        assert value is not None
        self._offsets = value

    # The length of the name of the referenced element.
    @property
    def length(self):
        return self._length
    # The length of the name of the referenced element.
    @length.setter
    def length(self, value):
        assert value is not None
        self._length = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            element = None
            if "element" in json_data:
                element = Element.from_json(json_data["element"])
            else:
                raise Exception('missing key: "element"')
            offsets = None
            if "offsets" in json_data:
                offsets = [(item) for item in json_data["offsets"]]
            else:
                raise Exception('missing key: "offsets"')
            length = None
            if "length" in json_data:
                length = (json_data["length"])
            else:
                raise Exception('missing key: "length"')
            return Occurrences(element, offsets, length)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["element"] = element.to_json()
        result["offsets"] = self.offsets
        result["length"] = self.length
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# Outline
#
# {
#   "element": Element
#   "offset": int
#   "length": int
#   "children": optional List<Outline>
# }
#
# Clients may not extend, implement or mix-in this class.
class Outline(HasToJson):

    def __init__(self, element, offset, length, children=None):
        self._element = element
        self._offset = offset
        self._length = length
        self._children = children
    # A description of the element represented by this node.
    @property
    def element(self):
        return self._element
    # A description of the element represented by this node.
    @element.setter
    def element(self, value):
        assert value is not None
        self._element = value

    # The offset of the first character of the element. This is different than
    # the offset in the Element, which if the offset of the name of the
    # element. It can be used, for example, to map locations in the file back
    # to an outline.
    @property
    def offset(self):
        return self._offset
    # The offset of the first character of the element. This is different than
    # the offset in the Element, which if the offset of the name of the
    # element. It can be used, for example, to map locations in the file back
    # to an outline.
    @offset.setter
    def offset(self, value):
        assert value is not None
        self._offset = value

    # The length of the element.
    @property
    def length(self):
        return self._length
    # The length of the element.
    @length.setter
    def length(self, value):
        assert value is not None
        self._length = value

    # The children of the node. The field will be omitted if the node has no
    # children.
    @property
    def children(self):
        return self._children
    # The children of the node. The field will be omitted if the node has no
    # children.
    @children.setter
    def children(self, value):
        self._children = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            element = None
            if "element" in json_data:
                element = Element.from_json(json_data["element"])
            else:
                raise Exception('missing key: "element"')
            offset = None
            if "offset" in json_data:
                offset = (json_data["offset"])
            else:
                raise Exception('missing key: "offset"')
            length = None
            if "length" in json_data:
                length = (json_data["length"])
            else:
                raise Exception('missing key: "length"')
            children = None
            if "children" in json_data:
                children = [Outline.from_json(item) for item in json_data["children"]]

            return Outline(element, offset, length, children=children)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["element"] = element.to_json()
        result["offset"] = self.offset
        result["length"] = self.length
        if self.children is not None:
            result["children"] = [x.to_json() for x in self.children]
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# Override
#
# {
#   "offset": int
#   "length": int
#   "superclassMember": optional OverriddenMember
#   "interfaceMembers": optional List<OverriddenMember>
# }
#
# Clients may not extend, implement or mix-in this class.
class Override(HasToJson):

    def __init__(self, offset, length, superclassMember=None, interfaceMembers=None):
        self._offset = offset
        self._length = length
        self._superclassMember = superclassMember
        self._interfaceMembers = interfaceMembers
    # The offset of the name of the overriding member.
    @property
    def offset(self):
        return self._offset
    # The offset of the name of the overriding member.
    @offset.setter
    def offset(self, value):
        assert value is not None
        self._offset = value

    # The length of the name of the overriding member.
    @property
    def length(self):
        return self._length
    # The length of the name of the overriding member.
    @length.setter
    def length(self, value):
        assert value is not None
        self._length = value

    # The member inherited from a superclass that is overridden by the
    # overriding member. The field is omitted if there is no superclass member,
    # in which case there must be at least one interface member.
    @property
    def superclassMember(self):
        return self._superclassMember
    # The member inherited from a superclass that is overridden by the
    # overriding member. The field is omitted if there is no superclass member,
    # in which case there must be at least one interface member.
    @superclassMember.setter
    def superclassMember(self, value):
        self._superclassMember = value

    # The members inherited from interfaces that are overridden by the
    # overriding member. The field is omitted if there are no interface
    # members, in which case there must be a superclass member.
    @property
    def interfaceMembers(self):
        return self._interfaceMembers
    # The members inherited from interfaces that are overridden by the
    # overriding member. The field is omitted if there are no interface
    # members, in which case there must be a superclass member.
    @interfaceMembers.setter
    def interfaceMembers(self, value):
        self._interfaceMembers = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            offset = None
            if "offset" in json_data:
                offset = (json_data["offset"])
            else:
                raise Exception('missing key: "offset"')
            length = None
            if "length" in json_data:
                length = (json_data["length"])
            else:
                raise Exception('missing key: "length"')
            superclassMember = None
            if "superclassMember" in json_data:
                superclassMember = OverriddenMember.from_json(json_data["superclassMember"])

            interfaceMembers = None
            if "interfaceMembers" in json_data:
                interfaceMembers = [OverriddenMember.from_json(item) for item in json_data["interfaceMembers"]]

            return Override(offset, length, superclassMember=superclassMember, interfaceMembers=interfaceMembers)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["offset"] = self.offset
        result["length"] = self.length
        if self.superclassMember is not None:
            result["superclassMember"] = superclassMember.to_json()
        if self.interfaceMembers is not None:
            result["interfaceMembers"] = [x.to_json() for x in self.interfaceMembers]
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# OverriddenMember
#
# {
#   "element": Element
#   "className": String
# }
#
# Clients may not extend, implement or mix-in this class.
class OverriddenMember(HasToJson):

    def __init__(self, element, className):
        self._element = element
        self._className = className
    # The element that is being overridden.
    @property
    def element(self):
        return self._element
    # The element that is being overridden.
    @element.setter
    def element(self, value):
        assert value is not None
        self._element = value

    # The name of the class in which the member is defined.
    @property
    def className(self):
        return self._className
    # The name of the class in which the member is defined.
    @className.setter
    def className(self, value):
        assert value is not None
        self._className = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            element = None
            if "element" in json_data:
                element = Element.from_json(json_data["element"])
            else:
                raise Exception('missing key: "element"')
            className = None
            if "className" in json_data:
                className = (json_data["className"])
            else:
                raise Exception('missing key: "className"')
            return OverriddenMember(element, className)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["element"] = element.to_json()
        result["className"] = self.className
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# Position
#
# {
#   "file": FilePath
#   "offset": int
# }
#
# Clients may not extend, implement or mix-in this class.
class Position(HasToJson):

    def __init__(self, file, offset):
        self._file = file
        self._offset = offset
    # The file containing the position.
    @property
    def file(self):
        return self._file
    # The file containing the position.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    # The offset of the position.
    @property
    def offset(self):
        return self._offset
    # The offset of the position.
    @offset.setter
    def offset(self, value):
        assert value is not None
        self._offset = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            offset = None
            if "offset" in json_data:
                offset = (json_data["offset"])
            else:
                raise Exception('missing key: "offset"')
            return Position(file, offset)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["file"] = self.file
        result["offset"] = self.offset
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# PubStatus
#
# {
#   "isListingPackageDirs": bool
# }
#
# Clients may not extend, implement or mix-in this class.
class PubStatus(HasToJson):

    def __init__(self, isListingPackageDirs):
        self._isListingPackageDirs = isListingPackageDirs
    # True if the server is currently running pub to produce a list of package
    # directories.
    @property
    def isListingPackageDirs(self):
        return self._isListingPackageDirs
    # True if the server is currently running pub to produce a list of package
    # directories.
    @isListingPackageDirs.setter
    def isListingPackageDirs(self, value):
        assert value is not None
        self._isListingPackageDirs = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            isListingPackageDirs = None
            if "isListingPackageDirs" in json_data:
                isListingPackageDirs = (json_data["isListingPackageDirs"])
            else:
                raise Exception('missing key: "isListingPackageDirs"')
            return PubStatus(isListingPackageDirs)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["isListingPackageDirs"] = self.isListingPackageDirs
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# RefactoringKind
#
# enum {
#   CONVERT_GETTER_TO_METHOD
#   CONVERT_METHOD_TO_GETTER
#   EXTRACT_LOCAL_VARIABLE
#   EXTRACT_METHOD
#   INLINE_LOCAL_VARIABLE
#   INLINE_METHOD
#   MOVE_FILE
#   RENAME
#   SORT_MEMBERS
# }
#
# Clients may not extend, implement or mix-in this class.
class RefactoringKind:
    CONVERT_GETTER_TO_METHOD = "CONVERT_GETTER_TO_METHOD"
    CONVERT_METHOD_TO_GETTER = "CONVERT_METHOD_TO_GETTER"
    EXTRACT_LOCAL_VARIABLE = "EXTRACT_LOCAL_VARIABLE"
    EXTRACT_METHOD = "EXTRACT_METHOD"
    INLINE_LOCAL_VARIABLE = "INLINE_LOCAL_VARIABLE"
    INLINE_METHOD = "INLINE_METHOD"
    MOVE_FILE = "MOVE_FILE"
    RENAME = "RENAME"
    SORT_MEMBERS = "SORT_MEMBERS"

# RefactoringMethodParameter
#
# {
#   "id": optional String
#   "kind": RefactoringMethodParameterKind
#   "type": String
#   "name": String
#   "parameters": optional String
# }
#
# Clients may not extend, implement or mix-in this class.
class RefactoringMethodParameter(HasToJson):

    def __init__(self, kind, type, name, id=None, parameters=None):
        self._id = id
        self._kind = kind
        self._type = type
        self._name = name
        self._parameters = parameters
    # The unique identifier of the parameter. Clients may omit this field for
    # the parameters they want to add.
    @property
    def id(self):
        return self._id
    # The unique identifier of the parameter. Clients may omit this field for
    # the parameters they want to add.
    @id.setter
    def id(self, value):
        self._id = value

    # The kind of the parameter.
    @property
    def kind(self):
        return self._kind
    # The kind of the parameter.
    @kind.setter
    def kind(self, value):
        assert value is not None
        self._kind = value

    # The type that should be given to the parameter, or the return type of the
    # parameter's function type.
    @property
    def type(self):
        return self._type
    # The type that should be given to the parameter, or the return type of the
    # parameter's function type.
    @type.setter
    def type(self, value):
        assert value is not None
        self._type = value

    # The name that should be given to the parameter.
    @property
    def name(self):
        return self._name
    # The name that should be given to the parameter.
    @name.setter
    def name(self, value):
        assert value is not None
        self._name = value

    # The parameter list of the parameter's function type. If the parameter is
    # not of a function type, this field will not be defined. If the function
    # type has zero parameters, this field will have a value of "()".
    @property
    def parameters(self):
        return self._parameters
    # The parameter list of the parameter's function type. If the parameter is
    # not of a function type, this field will not be defined. If the function
    # type has zero parameters, this field will have a value of "()".
    @parameters.setter
    def parameters(self, value):
        self._parameters = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            id = None
            if "id" in json_data:
                id = (json_data["id"])

            kind = None
            if "kind" in json_data:
                kind = json_data["kind"]
            else:
                raise Exception('missing key: "kind"')
            type = None
            if "type" in json_data:
                type = (json_data["type"])
            else:
                raise Exception('missing key: "type"')
            name = None
            if "name" in json_data:
                name = (json_data["name"])
            else:
                raise Exception('missing key: "name"')
            parameters = None
            if "parameters" in json_data:
                parameters = (json_data["parameters"])

            return RefactoringMethodParameter(kind, type, name, id=id, parameters=parameters)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        if self.id is not None:
            result["id"] = self.id
        result["kind"] = kind.to_json()
        result["type"] = self.type
        result["name"] = self.name
        if self.parameters is not None:
            result["parameters"] = self.parameters
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# RefactoringFeedback
#
# {
# }
#
# Clients may not extend, implement or mix-in this class.
class RefactoringFeedback(HasToJson):

    def __init__(self):
        pass

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            return RefactoringFeedback()
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# RefactoringOptions
#
# {
# }
#
# Clients may not extend, implement or mix-in this class.
class RefactoringOptions(HasToJson):

    def __init__(self):
        pass

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            return RefactoringOptions()
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# RefactoringMethodParameterKind
#
# enum {
#   REQUIRED
#   POSITIONAL
#   NAMED
# }
#
# Clients may not extend, implement or mix-in this class.
class RefactoringMethodParameterKind:
    REQUIRED = "REQUIRED"
    POSITIONAL = "POSITIONAL"
    NAMED = "NAMED"

# RefactoringProblem
#
# {
#   "severity": RefactoringProblemSeverity
#   "message": String
#   "location": optional Location
# }
#
# Clients may not extend, implement or mix-in this class.
class RefactoringProblem(HasToJson):

    def __init__(self, severity, message, location=None):
        self._severity = severity
        self._message = message
        self._location = location
    # The severity of the problem being represented.
    @property
    def severity(self):
        return self._severity
    # The severity of the problem being represented.
    @severity.setter
    def severity(self, value):
        assert value is not None
        self._severity = value

    # A human-readable description of the problem being represented.
    @property
    def message(self):
        return self._message
    # A human-readable description of the problem being represented.
    @message.setter
    def message(self, value):
        assert value is not None
        self._message = value

    # The location of the problem being represented. This field is omitted
    # unless there is a specific location associated with the problem (such as
    # a location where an element being renamed will be shadowed).
    @property
    def location(self):
        return self._location
    # The location of the problem being represented. This field is omitted
    # unless there is a specific location associated with the problem (such as
    # a location where an element being renamed will be shadowed).
    @location.setter
    def location(self, value):
        self._location = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            severity = None
            if "severity" in json_data:
                severity = json_data["severity"]
            else:
                raise Exception('missing key: "severity"')
            message = None
            if "message" in json_data:
                message = (json_data["message"])
            else:
                raise Exception('missing key: "message"')
            location = None
            if "location" in json_data:
                location = Location.from_json(json_data["location"])

            return RefactoringProblem(severity, message, location=location)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["severity"] = severity.to_json()
        result["message"] = self.message
        if self.location is not None:
            result["location"] = location.to_json()
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# RefactoringProblemSeverity
#
# enum {
#   INFO
#   WARNING
#   ERROR
#   FATAL
# }
#
# Clients may not extend, implement or mix-in this class.
class RefactoringProblemSeverity:
    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"
    FATAL = "FATAL"

# RemoveContentOverlay
#
# {
#   "type": "remove"
# }
#
# Clients may not extend, implement or mix-in this class.
class RemoveContentOverlay(HasToJson):

    def __init__(self):
        pass

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            if json_data["type"] != "remove":
                raise ValueError("equal " + "remove" + " " + str(json_data))
            return RemoveContentOverlay()
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["type"] = "remove"
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# RequestError
#
# {
#   "code": RequestErrorCode
#   "message": String
#   "stackTrace": optional String
# }
#
# Clients may not extend, implement or mix-in this class.
class RequestError(HasToJson):

    def __init__(self, code, message, stackTrace=None):
        self._code = code
        self._message = message
        self._stackTrace = stackTrace
    # A code that uniquely identifies the error that occurred.
    @property
    def code(self):
        return self._code
    # A code that uniquely identifies the error that occurred.
    @code.setter
    def code(self, value):
        assert value is not None
        self._code = value

    # A short description of the error.
    @property
    def message(self):
        return self._message
    # A short description of the error.
    @message.setter
    def message(self, value):
        assert value is not None
        self._message = value

    # The stack trace associated with processing the request, used for
    # debugging the server.
    @property
    def stackTrace(self):
        return self._stackTrace
    # The stack trace associated with processing the request, used for
    # debugging the server.
    @stackTrace.setter
    def stackTrace(self, value):
        self._stackTrace = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            code = None
            if "code" in json_data:
                code = json_data["code"]
            else:
                raise Exception('missing key: "code"')
            message = None
            if "message" in json_data:
                message = (json_data["message"])
            else:
                raise Exception('missing key: "message"')
            stackTrace = None
            if "stackTrace" in json_data:
                stackTrace = (json_data["stackTrace"])

            return RequestError(code, message, stackTrace=stackTrace)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["code"] = code.to_json()
        result["message"] = self.message
        if self.stackTrace is not None:
            result["stackTrace"] = self.stackTrace
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# RequestErrorCode
#
# enum {
#   CONTENT_MODIFIED
#   FILE_NOT_ANALYZED
#   FORMAT_INVALID_FILE
#   FORMAT_WITH_ERRORS
#   GET_ERRORS_INVALID_FILE
#   GET_NAVIGATION_INVALID_FILE
#   GET_REACHABLE_SOURCES_INVALID_FILE
#   INVALID_ANALYSIS_ROOT
#   INVALID_EXECUTION_CONTEXT
#   INVALID_FILE_PATH_FORMAT
#   INVALID_OVERLAY_CHANGE
#   INVALID_PARAMETER
#   INVALID_REQUEST
#   NO_INDEX_GENERATED
#   ORGANIZE_DIRECTIVES_ERROR
#   REFACTORING_REQUEST_CANCELLED
#   SERVER_ALREADY_STARTED
#   SERVER_ERROR
#   SORT_MEMBERS_INVALID_FILE
#   SORT_MEMBERS_PARSE_ERRORS
#   UNANALYZED_PRIORITY_FILES
#   UNKNOWN_REQUEST
#   UNKNOWN_SOURCE
#   UNSUPPORTED_FEATURE
# }
#
# Clients may not extend, implement or mix-in this class.
class RequestErrorCode:
    # An "analysis.getErrors" or "analysis.getNavigation" request could not be
    # satisfied because the content of the file changed before the requested
    # results could be computed.
    CONTENT_MODIFIED = "CONTENT_MODIFIED"
    # A request specified a FilePath which does not match a file in an analysis
    # root, or the requested operation is not available for the file.
    FILE_NOT_ANALYZED = "FILE_NOT_ANALYZED"
    # An "edit.format" request specified a FilePath which does not match a Dart
    # file in an analysis root.
    FORMAT_INVALID_FILE = "FORMAT_INVALID_FILE"
    # An "edit.format" request specified a file that contains syntax errors.
    FORMAT_WITH_ERRORS = "FORMAT_WITH_ERRORS"
    # An "analysis.getErrors" request specified a FilePath which does not match
    # a file currently subject to analysis.
    GET_ERRORS_INVALID_FILE = "GET_ERRORS_INVALID_FILE"
    # An "analysis.getNavigation" request specified a FilePath which does not
    # match a file currently subject to analysis.
    GET_NAVIGATION_INVALID_FILE = "GET_NAVIGATION_INVALID_FILE"
    # An "analysis.getReachableSources" request specified a FilePath which does
    # not match a file currently subject to analysis.
    GET_REACHABLE_SOURCES_INVALID_FILE = "GET_REACHABLE_SOURCES_INVALID_FILE"
    # A path passed as an argument to a request (such as analysis.reanalyze) is
    # required to be an analysis root, but isn't.
    INVALID_ANALYSIS_ROOT = "INVALID_ANALYSIS_ROOT"
    # The context root used to create an execution context does not exist.
    INVALID_EXECUTION_CONTEXT = "INVALID_EXECUTION_CONTEXT"
    # The format of the given file path is invalid, e.g. is not absolute and
    # normalized.
    INVALID_FILE_PATH_FORMAT = "INVALID_FILE_PATH_FORMAT"
    # An "analysis.updateContent" request contained a ChangeContentOverlay
    # object which can't be applied, due to an edit having an offset or length
    # that is out of range.
    INVALID_OVERLAY_CHANGE = "INVALID_OVERLAY_CHANGE"
    # One of the method parameters was invalid.
    INVALID_PARAMETER = "INVALID_PARAMETER"
    # A malformed request was received.
    INVALID_REQUEST = "INVALID_REQUEST"
    # The "--no-index" flag was passed when the analysis server created, but
    # this API call requires an index to have been generated.
    NO_INDEX_GENERATED = "NO_INDEX_GENERATED"
    # An "edit.organizeDirectives" request specified a Dart file that cannot be
    # analyzed. The reason is described in the message.
    ORGANIZE_DIRECTIVES_ERROR = "ORGANIZE_DIRECTIVES_ERROR"
    # Another refactoring request was received during processing of this one.
    REFACTORING_REQUEST_CANCELLED = "REFACTORING_REQUEST_CANCELLED"
    # The analysis server has already been started (and hence won't accept new
    # connections).
    #
    # This error is included for future expansion; at present the analysis
    # server can only speak to one client at a time so this error will never
    # occur.
    SERVER_ALREADY_STARTED = "SERVER_ALREADY_STARTED"
    # An internal error occurred in the analysis server. Also see the
    # server.error notification.
    SERVER_ERROR = "SERVER_ERROR"
    # An "edit.sortMembers" request specified a FilePath which does not match a
    # Dart file in an analysis root.
    SORT_MEMBERS_INVALID_FILE = "SORT_MEMBERS_INVALID_FILE"
    # An "edit.sortMembers" request specified a Dart file that has scan or
    # parse errors.
    SORT_MEMBERS_PARSE_ERRORS = "SORT_MEMBERS_PARSE_ERRORS"
    # An "analysis.setPriorityFiles" request includes one or more files that
    # are not being analyzed.
    #
    # This is a legacy error; it will be removed before the API reaches version
    # 1.0.
    UNANALYZED_PRIORITY_FILES = "UNANALYZED_PRIORITY_FILES"
    # A request was received which the analysis server does not recognize, or
    # cannot handle in its current configuration.
    UNKNOWN_REQUEST = "UNKNOWN_REQUEST"
    # The analysis server was requested to perform an action on a source that
    # does not exist.
    UNKNOWN_SOURCE = "UNKNOWN_SOURCE"
    # The analysis server was requested to perform an action which is not
    # supported.
    #
    # This is a legacy error; it will be removed before the API reaches version
    # 1.0.
    UNSUPPORTED_FEATURE = "UNSUPPORTED_FEATURE"

# SearchResult
#
# {
#   "location": Location
#   "kind": SearchResultKind
#   "isPotential": bool
#   "path": List<Element>
# }
#
# Clients may not extend, implement or mix-in this class.
class SearchResult(HasToJson):

    def __init__(self, location, kind, isPotential, path):
        self._location = location
        self._kind = kind
        self._isPotential = isPotential
        self._path = path
    # The location of the code that matched the search criteria.
    @property
    def location(self):
        return self._location
    # The location of the code that matched the search criteria.
    @location.setter
    def location(self, value):
        assert value is not None
        self._location = value

    # The kind of element that was found or the kind of reference that was
    # found.
    @property
    def kind(self):
        return self._kind
    # The kind of element that was found or the kind of reference that was
    # found.
    @kind.setter
    def kind(self, value):
        assert value is not None
        self._kind = value

    # True if the result is a potential match but cannot be confirmed to be a
    # match. For example, if all references to a method m defined in some class
    # were requested, and a reference to a method m from an unknown class were
    # found, it would be marked as being a potential match.
    @property
    def isPotential(self):
        return self._isPotential
    # True if the result is a potential match but cannot be confirmed to be a
    # match. For example, if all references to a method m defined in some class
    # were requested, and a reference to a method m from an unknown class were
    # found, it would be marked as being a potential match.
    @isPotential.setter
    def isPotential(self, value):
        assert value is not None
        self._isPotential = value

    # The elements that contain the result, starting with the most immediately
    # enclosing ancestor and ending with the library.
    @property
    def path(self):
        return self._path
    # The elements that contain the result, starting with the most immediately
    # enclosing ancestor and ending with the library.
    @path.setter
    def path(self, value):
        assert value is not None
        self._path = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            location = None
            if "location" in json_data:
                location = Location.from_json(json_data["location"])
            else:
                raise Exception('missing key: "location"')
            kind = None
            if "kind" in json_data:
                kind = json_data["kind"]
            else:
                raise Exception('missing key: "kind"')
            isPotential = None
            if "isPotential" in json_data:
                isPotential = (json_data["isPotential"])
            else:
                raise Exception('missing key: "isPotential"')
            path = None
            if "path" in json_data:
                path = [Element.from_json(item) for item in json_data["path"]]
            else:
                raise Exception('missing key: "path"')
            return SearchResult(location, kind, isPotential, path)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["location"] = location.to_json()
        result["kind"] = kind.to_json()
        result["isPotential"] = self.isPotential
        result["path"] = [x.to_json() for x in self.path]
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# SearchResultKind
#
# enum {
#   DECLARATION
#   INVOCATION
#   READ
#   READ_WRITE
#   REFERENCE
#   UNKNOWN
#   WRITE
# }
#
# Clients may not extend, implement or mix-in this class.
class SearchResultKind:
    # The declaration of an element.
    DECLARATION = "DECLARATION"
    # The invocation of a function or method.
    INVOCATION = "INVOCATION"
    # A reference to a field, parameter or variable where it is being read.
    READ = "READ"
    # A reference to a field, parameter or variable where it is being read and
    # written.
    READ_WRITE = "READ_WRITE"
    # A reference to an element.
    REFERENCE = "REFERENCE"
    # Some other kind of search result.
    UNKNOWN = "UNKNOWN"
    # A reference to a field, parameter or variable where it is being written.
    WRITE = "WRITE"

# ServerService
#
# enum {
#   STATUS
# }
#
# Clients may not extend, implement or mix-in this class.
class ServerService:
    STATUS = "STATUS"

# SourceChange
#
# {
#   "message": String
#   "edits": List<SourceFileEdit>
#   "linkedEditGroups": List<LinkedEditGroup>
#   "selection": optional Position
# }
#
# Clients may not extend, implement or mix-in this class.
class SourceChange(HasToJson):

    def __init__(self, message, edits=None, linkedEditGroups=None, selection=None):
        self._message = message
        self._edits = edits
        self._linkedEditGroups = linkedEditGroups
        self._selection = selection
    # A human-readable description of the change to be applied.
    @property
    def message(self):
        return self._message
    # A human-readable description of the change to be applied.
    @message.setter
    def message(self, value):
        assert value is not None
        self._message = value

    # A list of the edits used to effect the change, grouped by file.
    @property
    def edits(self):
        return self._edits
    # A list of the edits used to effect the change, grouped by file.
    @edits.setter
    def edits(self, value):
        assert value is not None
        self._edits = value

    # A list of the linked editing groups used to customize the changes that
    # were made.
    @property
    def linkedEditGroups(self):
        return self._linkedEditGroups
    # A list of the linked editing groups used to customize the changes that
    # were made.
    @linkedEditGroups.setter
    def linkedEditGroups(self, value):
        assert value is not None
        self._linkedEditGroups = value

    # The position that should be selected after the edits have been applied.
    @property
    def selection(self):
        return self._selection
    # The position that should be selected after the edits have been applied.
    @selection.setter
    def selection(self, value):
        self._selection = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            message = None
            if "message" in json_data:
                message = (json_data["message"])
            else:
                raise Exception('missing key: "message"')
            edits = None
            if "edits" in json_data:
                edits = [SourceFileEdit.from_json(item) for item in json_data["edits"]]
            else:
                raise Exception('missing key: "edits"')
            linkedEditGroups = None
            if "linkedEditGroups" in json_data:
                linkedEditGroups = [LinkedEditGroup.from_json(item) for item in json_data["linkedEditGroups"]]
            else:
                raise Exception('missing key: "linkedEditGroups"')
            selection = None
            if "selection" in json_data:
                selection = Position.from_json(json_data["selection"])

            return SourceChange(message, edits=edits, linkedEditGroups=linkedEditGroups, selection=selection)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["message"] = self.message
        result["edits"] = [x.to_json() for x in self.edits]
        result["linkedEditGroups"] = [x.to_json() for x in self.linkedEditGroups]
        if self.selection is not None:
            result["selection"] = selection.to_json()
        return result

    # Adds [edit] to the [FileEdit] for the given [file].
    def add_edit(self, file, fileStamp, edit):
        add_edit_to_source_change(self, file, fileStamp, edit)

    # Adds the given [FileEdit].
    def add_file_edit(edit):
        self.edits.append(edit);

    # Adds the given [LinkedEditGroup].
    def add_linked_edit_group(linkedEditGroup):
        self.linkedEditGroups.append(linkedEditGroup)

    # Returns the [FileEdit] for the given [file], maybe `null`.
    def get_file_edit(self, file):
        return get_change_file_edit(self, file)

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# SourceEdit
#
# {
#   "offset": int
#   "length": int
#   "replacement": String
#   "id": optional String
# }
#
# Clients may not extend, implement or mix-in this class.
class SourceEdit(HasToJson):

    # Get the result of applying a set of [edits] to the given [code]. Edits
    # are applied in the order they appear in [edits].
    @staticmethod
    def apply_sequence(code, edits):
        return self.apply_Sequence_of_edits(code, edits)

    def __init__(self, offset, length, replacement, id=None):
        self._offset = offset
        self._length = length
        self._replacement = replacement
        self._id = id
    # The offset of the region to be modified.
    @property
    def offset(self):
        return self._offset
    # The offset of the region to be modified.
    @offset.setter
    def offset(self, value):
        assert value is not None
        self._offset = value

    # The length of the region to be modified.
    @property
    def length(self):
        return self._length
    # The length of the region to be modified.
    @length.setter
    def length(self, value):
        assert value is not None
        self._length = value

    # The code that is to replace the specified region in the original code.
    @property
    def replacement(self):
        return self._replacement
    # The code that is to replace the specified region in the original code.
    @replacement.setter
    def replacement(self, value):
        assert value is not None
        self._replacement = value

    # An identifier that uniquely identifies this source edit from other edits
    # in the same response. This field is omitted unless a containing structure
    # needs to be able to identify the edit for some reason.
    #
    # For example, some refactoring operations can produce edits that might not
    # be appropriate (referred to as potential edits). Such edits will have an
    # id so that they can be referenced. Edits in the same response that do not
    # need to be referenced will not have an id.
    @property
    def id(self):
        return self._id
    # An identifier that uniquely identifies this source edit from other edits
    # in the same response. This field is omitted unless a containing structure
    # needs to be able to identify the edit for some reason.
    #
    # For example, some refactoring operations can produce edits that might not
    # be appropriate (referred to as potential edits). Such edits will have an
    # id so that they can be referenced. Edits in the same response that do not
    # need to be referenced will not have an id.
    @id.setter
    def id(self, value):
        self._id = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            offset = None
            if "offset" in json_data:
                offset = (json_data["offset"])
            else:
                raise Exception('missing key: "offset"')
            length = None
            if "length" in json_data:
                length = (json_data["length"])
            else:
                raise Exception('missing key: "length"')
            replacement = None
            if "replacement" in json_data:
                replacement = (json_data["replacement"])
            else:
                raise Exception('missing key: "replacement"')
            id = None
            if "id" in json_data:
                id = (json_data["id"])

            return SourceEdit(offset, length, replacement, id=id)
        else:
            raise ValueError("wrong type: %s" % json_data)

    # The end of the region to be modified.
    @property
    def end(self):
        return self.offset + self.length

    def to_json(self):
        result = {}
        result["offset"] = self.offset
        result["length"] = self.length
        result["replacement"] = self.replacement
        if self.id is not None:
            result["id"] = self.id
        return result

    # Get the result of applying the edit to the given [code].
    def apply(self, code):
        return self.apply_edit(code, self)

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# SourceFileEdit
#
# {
#   "file": FilePath
#   "fileStamp": long
#   "edits": List<SourceEdit>
# }
#
# Clients may not extend, implement or mix-in this class.
class SourceFileEdit(HasToJson):

    def __init__(self, file, fileStamp, edits=None):
        self._file = file
        self._fileStamp = fileStamp
        self._edits = edits
    # The file containing the code to be modified.
    @property
    def file(self):
        return self._file
    # The file containing the code to be modified.
    @file.setter
    def file(self, value):
        assert value is not None
        self._file = value

    # The modification stamp of the file at the moment when the change was
    # created, in milliseconds since the "Unix epoch". Will be -1 if the file
    # did not exist and should be created. The client may use this field to
    # make sure that the file was not changed since then, so it is safe to
    # apply the change.
    @property
    def fileStamp(self):
        return self._fileStamp
    # The modification stamp of the file at the moment when the change was
    # created, in milliseconds since the "Unix epoch". Will be -1 if the file
    # did not exist and should be created. The client may use this field to
    # make sure that the file was not changed since then, so it is safe to
    # apply the change.
    @fileStamp.setter
    def fileStamp(self, value):
        assert value is not None
        self._fileStamp = value

    # A list of the edits used to effect the change.
    @property
    def edits(self):
        return self._edits
    # A list of the edits used to effect the change.
    @edits.setter
    def edits(self, value):
        assert value is not None
        self._edits = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            file = None
            if "file" in json_data:
                file = (json_data["file"])
            else:
                raise Exception('missing key: "file"')
            fileStamp = None
            if "fileStamp" in json_data:
                fileStamp = (json_data["fileStamp"])
            else:
                raise Exception('missing key: "fileStamp"')
            edits = None
            if "edits" in json_data:
                edits = [SourceEdit.from_json(item) for item in json_data["edits"]]
            else:
                raise Exception('missing key: "edits"')
            return SourceFileEdit(file, fileStamp, edits=edits)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["file"] = self.file
        result["fileStamp"] = self.fileStamp
        result["edits"] = [x.to_json() for x in self.edits]
        return result

    # Adds the given [Edit] to the list.
    def add(self, edit):
        self.add_edit_for_source(self, edit)

    # Adds the given [Edit]s.
    def add_all(self, edits):
        self.add_all_edits_for_source(self, edits);

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# TypeHierarchyItem
#
# {
#   "classElement": Element
#   "displayName": optional String
#   "memberElement": optional Element
#   "superclass": optional int
#   "interfaces": List<int>
#   "mixins": List<int>
#   "subclasses": List<int>
# }
#
# Clients may not extend, implement or mix-in this class.
class TypeHierarchyItem(HasToJson):

    def __init__(self, classElement, displayName=None, memberElement=None, superclass=None, interfaces=None, mixins=None, subclasses=None):
        self._classElement = classElement
        self._displayName = displayName
        self._memberElement = memberElement
        self._superclass = superclass
        self._interfaces = interfaces
        self._mixins = mixins
        self._subclasses = subclasses
    # The class element represented by this item.
    @property
    def classElement(self):
        return self._classElement
    # The class element represented by this item.
    @classElement.setter
    def classElement(self, value):
        assert value is not None
        self._classElement = value

    # The name to be displayed for the class. This field will be omitted if the
    # display name is the same as the name of the element. The display name is
    # different if there is additional type information to be displayed, such
    # as type arguments.
    @property
    def displayName(self):
        return self._displayName
    # The name to be displayed for the class. This field will be omitted if the
    # display name is the same as the name of the element. The display name is
    # different if there is additional type information to be displayed, such
    # as type arguments.
    @displayName.setter
    def displayName(self, value):
        self._displayName = value

    # The member in the class corresponding to the member on which the
    # hierarchy was requested. This field will be omitted if the hierarchy was
    # not requested for a member or if the class does not have a corresponding
    # member.
    @property
    def memberElement(self):
        return self._memberElement
    # The member in the class corresponding to the member on which the
    # hierarchy was requested. This field will be omitted if the hierarchy was
    # not requested for a member or if the class does not have a corresponding
    # member.
    @memberElement.setter
    def memberElement(self, value):
        self._memberElement = value

    # The index of the item representing the superclass of this class. This
    # field will be omitted if this item represents the class Object.
    @property
    def superclass(self):
        return self._superclass
    # The index of the item representing the superclass of this class. This
    # field will be omitted if this item represents the class Object.
    @superclass.setter
    def superclass(self, value):
        self._superclass = value

    # The indexes of the items representing the interfaces implemented by this
    # class. The list will be empty if there are no implemented interfaces.
    @property
    def interfaces(self):
        return self._interfaces
    # The indexes of the items representing the interfaces implemented by this
    # class. The list will be empty if there are no implemented interfaces.
    @interfaces.setter
    def interfaces(self, value):
        assert value is not None
        self._interfaces = value

    # The indexes of the items representing the mixins referenced by this
    # class. The list will be empty if there are no classes mixed in to this
    # class.
    @property
    def mixins(self):
        return self._mixins
    # The indexes of the items representing the mixins referenced by this
    # class. The list will be empty if there are no classes mixed in to this
    # class.
    @mixins.setter
    def mixins(self, value):
        assert value is not None
        self._mixins = value

    # The indexes of the items representing the subtypes of this class. The
    # list will be empty if there are no subtypes or if this item represents a
    # supertype of the pivot type.
    @property
    def subclasses(self):
        return self._subclasses
    # The indexes of the items representing the subtypes of this class. The
    # list will be empty if there are no subtypes or if this item represents a
    # supertype of the pivot type.
    @subclasses.setter
    def subclasses(self, value):
        assert value is not None
        self._subclasses = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            classElement = None
            if "classElement" in json_data:
                classElement = Element.from_json(json_data["classElement"])
            else:
                raise Exception('missing key: "classElement"')
            displayName = None
            if "displayName" in json_data:
                displayName = (json_data["displayName"])

            memberElement = None
            if "memberElement" in json_data:
                memberElement = Element.from_json(json_data["memberElement"])

            superclass = None
            if "superclass" in json_data:
                superclass = (json_data["superclass"])

            interfaces = None
            if "interfaces" in json_data:
                interfaces = [(item) for item in json_data["interfaces"]]
            else:
                raise Exception('missing key: "interfaces"')
            mixins = None
            if "mixins" in json_data:
                mixins = [(item) for item in json_data["mixins"]]
            else:
                raise Exception('missing key: "mixins"')
            subclasses = None
            if "subclasses" in json_data:
                subclasses = [(item) for item in json_data["subclasses"]]
            else:
                raise Exception('missing key: "subclasses"')
            return TypeHierarchyItem(classElement, displayName=displayName, memberElement=memberElement, superclass=superclass, interfaces=interfaces, mixins=mixins, subclasses=subclasses)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["classElement"] = classElement.to_json()
        if self.displayName is not None:
            result["displayName"] = self.displayName
        if self.memberElement is not None:
            result["memberElement"] = memberElement.to_json()
        if self.superclass is not None:
            result["superclass"] = self.superclass
        result["interfaces"] = self.interfaces
        result["mixins"] = self.mixins
        result["subclasses"] = self.subclasses
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass
# convertGetterToMethod feedback
#
# Clients may not extend, implement or mix-in this class.
class ConvertGetterToMethodFeedback(object):
    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass
# convertGetterToMethod options
#
# Clients may not extend, implement or mix-in this class.
class ConvertGetterToMethodOptions(object):
    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass
# convertMethodToGetter feedback
#
# Clients may not extend, implement or mix-in this class.
class ConvertMethodToGetterFeedback(object):
    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass
# convertMethodToGetter options
#
# Clients may not extend, implement or mix-in this class.
class ConvertMethodToGetterOptions(object):
    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# extractLocalVariable feedback
#
# {
#   "coveringExpressionOffsets": optional List<int>
#   "coveringExpressionLengths": optional List<int>
#   "names": List<String>
#   "offsets": List<int>
#   "lengths": List<int>
# }
#
# Clients may not extend, implement or mix-in this class.
class ExtractLocalVariableFeedback(RefactoringFeedback, HasToJson):

    def __init__(self, names, offsets, lengths, coveringExpressionOffsets=None, coveringExpressionLengths=None):
        self._coveringExpressionOffsets = coveringExpressionOffsets
        self._coveringExpressionLengths = coveringExpressionLengths
        self._names = names
        self._offsets = offsets
        self._lengths = lengths
    # The offsets of the expressions that cover the specified selection, from
    # the down most to the up most.
    @property
    def coveringExpressionOffsets(self):
        return self._coveringExpressionOffsets
    # The offsets of the expressions that cover the specified selection, from
    # the down most to the up most.
    @coveringExpressionOffsets.setter
    def coveringExpressionOffsets(self, value):
        self._coveringExpressionOffsets = value

    # The lengths of the expressions that cover the specified selection, from
    # the down most to the up most.
    @property
    def coveringExpressionLengths(self):
        return self._coveringExpressionLengths
    # The lengths of the expressions that cover the specified selection, from
    # the down most to the up most.
    @coveringExpressionLengths.setter
    def coveringExpressionLengths(self, value):
        self._coveringExpressionLengths = value

    # The proposed names for the local variable.
    @property
    def names(self):
        return self._names
    # The proposed names for the local variable.
    @names.setter
    def names(self, value):
        assert value is not None
        self._names = value

    # The offsets of the expressions that would be replaced by a reference to
    # the variable.
    @property
    def offsets(self):
        return self._offsets
    # The offsets of the expressions that would be replaced by a reference to
    # the variable.
    @offsets.setter
    def offsets(self, value):
        assert value is not None
        self._offsets = value

    # The lengths of the expressions that would be replaced by a reference to
    # the variable. The lengths correspond to the offsets. In other words, for
    # a given expression, if the offset of that expression is offsets[i], then
    # the length of that expression is lengths[i].
    @property
    def lengths(self):
        return self._lengths
    # The lengths of the expressions that would be replaced by a reference to
    # the variable. The lengths correspond to the offsets. In other words, for
    # a given expression, if the offset of that expression is offsets[i], then
    # the length of that expression is lengths[i].
    @lengths.setter
    def lengths(self, value):
        assert value is not None
        self._lengths = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            coveringExpressionOffsets = None
            if "coveringExpressionOffsets" in json_data:
                coveringExpressionOffsets = [(item) for item in json_data["coveringExpressionOffsets"]]

            coveringExpressionLengths = None
            if "coveringExpressionLengths" in json_data:
                coveringExpressionLengths = [(item) for item in json_data["coveringExpressionLengths"]]

            names = None
            if "names" in json_data:
                names = [(item) for item in json_data["names"]]
            else:
                raise Exception('missing key: "names"')
            offsets = None
            if "offsets" in json_data:
                offsets = [(item) for item in json_data["offsets"]]
            else:
                raise Exception('missing key: "offsets"')
            lengths = None
            if "lengths" in json_data:
                lengths = [(item) for item in json_data["lengths"]]
            else:
                raise Exception('missing key: "lengths"')
            return ExtractLocalVariableFeedback(names, offsets, lengths, coveringExpressionOffsets=coveringExpressionOffsets, coveringExpressionLengths=coveringExpressionLengths)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        if self.coveringExpressionOffsets is not None:
            result["coveringExpressionOffsets"] = self.coveringExpressionOffsets
        if self.coveringExpressionLengths is not None:
            result["coveringExpressionLengths"] = self.coveringExpressionLengths
        result["names"] = self.names
        result["offsets"] = self.offsets
        result["lengths"] = self.lengths
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# extractLocalVariable options
#
# {
#   "name": String
#   "extractAll": bool
# }
#
# Clients may not extend, implement or mix-in this class.
class ExtractLocalVariableOptions(RefactoringOptions, HasToJson):

    def __init__(self, name, extractAll):
        self._name = name
        self._extractAll = extractAll
    # The name that the local variable should be given.
    @property
    def name(self):
        return self._name
    # The name that the local variable should be given.
    @name.setter
    def name(self, value):
        assert value is not None
        self._name = value

    # True if all occurrences of the expression within the scope in which the
    # variable will be defined should be replaced by a reference to the local
    # variable. The expression used to initiate the refactoring will always be
    # replaced.
    @property
    def extractAll(self):
        return self._extractAll
    # True if all occurrences of the expression within the scope in which the
    # variable will be defined should be replaced by a reference to the local
    # variable. The expression used to initiate the refactoring will always be
    # replaced.
    @extractAll.setter
    def extractAll(self, value):
        assert value is not None
        self._extractAll = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            name = None
            if "name" in json_data:
                name = (json_data["name"])
            else:
                raise Exception('missing key: "name"')
            extractAll = None
            if "extractAll" in json_data:
                extractAll = (json_data["extractAll"])
            else:
                raise Exception('missing key: "extractAll"')
            return ExtractLocalVariableOptions(name, extractAll)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def fromRefactoringParams(refactoringParams, request):
        return ExtractLocalVariableOptions.from_json(refactoringParams.options)

    def to_json(self):
        result = {}
        result["name"] = self.name
        result["extractAll"] = self.extractAll
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# extractMethod feedback
#
# {
#   "offset": int
#   "length": int
#   "returnType": String
#   "names": List<String>
#   "canCreateGetter": bool
#   "parameters": List<RefactoringMethodParameter>
#   "offsets": List<int>
#   "lengths": List<int>
# }
#
# Clients may not extend, implement or mix-in this class.
class ExtractMethodFeedback(RefactoringFeedback, HasToJson):

    def __init__(self, offset, length, returnType, names, canCreateGetter, parameters, offsets, lengths):
        self._offset = offset
        self._length = length
        self._returnType = returnType
        self._names = names
        self._canCreateGetter = canCreateGetter
        self._parameters = parameters
        self._offsets = offsets
        self._lengths = lengths
    # The offset to the beginning of the expression or statements that will be
    # extracted.
    @property
    def offset(self):
        return self._offset
    # The offset to the beginning of the expression or statements that will be
    # extracted.
    @offset.setter
    def offset(self, value):
        assert value is not None
        self._offset = value

    # The length of the expression or statements that will be extracted.
    @property
    def length(self):
        return self._length
    # The length of the expression or statements that will be extracted.
    @length.setter
    def length(self, value):
        assert value is not None
        self._length = value

    # The proposed return type for the method. If the returned element does not
    # have a declared return type, this field will contain an empty string.
    @property
    def returnType(self):
        return self._returnType
    # The proposed return type for the method. If the returned element does not
    # have a declared return type, this field will contain an empty string.
    @returnType.setter
    def returnType(self, value):
        assert value is not None
        self._returnType = value

    # The proposed names for the method.
    @property
    def names(self):
        return self._names
    # The proposed names for the method.
    @names.setter
    def names(self, value):
        assert value is not None
        self._names = value

    # True if a getter could be created rather than a method.
    @property
    def canCreateGetter(self):
        return self._canCreateGetter
    # True if a getter could be created rather than a method.
    @canCreateGetter.setter
    def canCreateGetter(self, value):
        assert value is not None
        self._canCreateGetter = value

    # The proposed parameters for the method.
    @property
    def parameters(self):
        return self._parameters
    # The proposed parameters for the method.
    @parameters.setter
    def parameters(self, value):
        assert value is not None
        self._parameters = value

    # The offsets of the expressions or statements that would be replaced by an
    # invocation of the method.
    @property
    def offsets(self):
        return self._offsets
    # The offsets of the expressions or statements that would be replaced by an
    # invocation of the method.
    @offsets.setter
    def offsets(self, value):
        assert value is not None
        self._offsets = value

    # The lengths of the expressions or statements that would be replaced by an
    # invocation of the method. The lengths correspond to the offsets. In other
    # words, for a given expression (or block of statements), if the offset of
    # that expression is offsets[i], then the length of that expression is
    # lengths[i].
    @property
    def lengths(self):
        return self._lengths
    # The lengths of the expressions or statements that would be replaced by an
    # invocation of the method. The lengths correspond to the offsets. In other
    # words, for a given expression (or block of statements), if the offset of
    # that expression is offsets[i], then the length of that expression is
    # lengths[i].
    @lengths.setter
    def lengths(self, value):
        assert value is not None
        self._lengths = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            offset = None
            if "offset" in json_data:
                offset = (json_data["offset"])
            else:
                raise Exception('missing key: "offset"')
            length = None
            if "length" in json_data:
                length = (json_data["length"])
            else:
                raise Exception('missing key: "length"')
            returnType = None
            if "returnType" in json_data:
                returnType = (json_data["returnType"])
            else:
                raise Exception('missing key: "returnType"')
            names = None
            if "names" in json_data:
                names = [(item) for item in json_data["names"]]
            else:
                raise Exception('missing key: "names"')
            canCreateGetter = None
            if "canCreateGetter" in json_data:
                canCreateGetter = (json_data["canCreateGetter"])
            else:
                raise Exception('missing key: "canCreateGetter"')
            parameters = None
            if "parameters" in json_data:
                parameters = [RefactoringMethodParameter.from_json(item) for item in json_data["parameters"]]
            else:
                raise Exception('missing key: "parameters"')
            offsets = None
            if "offsets" in json_data:
                offsets = [(item) for item in json_data["offsets"]]
            else:
                raise Exception('missing key: "offsets"')
            lengths = None
            if "lengths" in json_data:
                lengths = [(item) for item in json_data["lengths"]]
            else:
                raise Exception('missing key: "lengths"')
            return ExtractMethodFeedback(offset, length, returnType, names, canCreateGetter, parameters, offsets, lengths)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["offset"] = self.offset
        result["length"] = self.length
        result["returnType"] = self.returnType
        result["names"] = self.names
        result["canCreateGetter"] = self.canCreateGetter
        result["parameters"] = [x.to_json() for x in self.parameters]
        result["offsets"] = self.offsets
        result["lengths"] = self.lengths
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# extractMethod options
#
# {
#   "returnType": String
#   "createGetter": bool
#   "name": String
#   "parameters": List<RefactoringMethodParameter>
#   "extractAll": bool
# }
#
# Clients may not extend, implement or mix-in this class.
class ExtractMethodOptions(RefactoringOptions, HasToJson):

    def __init__(self, returnType, createGetter, name, parameters, extractAll):
        self._returnType = returnType
        self._createGetter = createGetter
        self._name = name
        self._parameters = parameters
        self._extractAll = extractAll
    # The return type that should be defined for the method.
    @property
    def returnType(self):
        return self._returnType
    # The return type that should be defined for the method.
    @returnType.setter
    def returnType(self, value):
        assert value is not None
        self._returnType = value

    # True if a getter should be created rather than a method. It is an error
    # if this field is true and the list of parameters is non-empty.
    @property
    def createGetter(self):
        return self._createGetter
    # True if a getter should be created rather than a method. It is an error
    # if this field is true and the list of parameters is non-empty.
    @createGetter.setter
    def createGetter(self, value):
        assert value is not None
        self._createGetter = value

    # The name that the method should be given.
    @property
    def name(self):
        return self._name
    # The name that the method should be given.
    @name.setter
    def name(self, value):
        assert value is not None
        self._name = value

    # The parameters that should be defined for the method.
    #
    # It is an error if a REQUIRED or NAMED parameter follows a POSITIONAL
    # parameter. It is an error if a REQUIRED or POSITIONAL parameter follows a
    # NAMED parameter.
    #
    # - To change the order and/or update proposed parameters, add parameters
    #   with the same identifiers as proposed.
    # - To add new parameters, omit their identifier.
    # - To remove some parameters, omit them in this list.
    @property
    def parameters(self):
        return self._parameters
    # The parameters that should be defined for the method.
    #
    # It is an error if a REQUIRED or NAMED parameter follows a POSITIONAL
    # parameter. It is an error if a REQUIRED or POSITIONAL parameter follows a
    # NAMED parameter.
    #
    # - To change the order and/or update proposed parameters, add parameters
    #   with the same identifiers as proposed.
    # - To add new parameters, omit their identifier.
    # - To remove some parameters, omit them in this list.
    @parameters.setter
    def parameters(self, value):
        assert value is not None
        self._parameters = value

    # True if all occurrences of the expression or statements should be
    # replaced by an invocation of the method. The expression or statements
    # used to initiate the refactoring will always be replaced.
    @property
    def extractAll(self):
        return self._extractAll
    # True if all occurrences of the expression or statements should be
    # replaced by an invocation of the method. The expression or statements
    # used to initiate the refactoring will always be replaced.
    @extractAll.setter
    def extractAll(self, value):
        assert value is not None
        self._extractAll = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            returnType = None
            if "returnType" in json_data:
                returnType = (json_data["returnType"])
            else:
                raise Exception('missing key: "returnType"')
            createGetter = None
            if "createGetter" in json_data:
                createGetter = (json_data["createGetter"])
            else:
                raise Exception('missing key: "createGetter"')
            name = None
            if "name" in json_data:
                name = (json_data["name"])
            else:
                raise Exception('missing key: "name"')
            parameters = None
            if "parameters" in json_data:
                parameters = [RefactoringMethodParameter.from_json(item) for item in json_data["parameters"]]
            else:
                raise Exception('missing key: "parameters"')
            extractAll = None
            if "extractAll" in json_data:
                extractAll = (json_data["extractAll"])
            else:
                raise Exception('missing key: "extractAll"')
            return ExtractMethodOptions(returnType, createGetter, name, parameters, extractAll)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def fromRefactoringParams(refactoringParams, request):
        return ExtractMethodOptions.from_json(refactoringParams.options)

    def to_json(self):
        result = {}
        result["returnType"] = self.returnType
        result["createGetter"] = self.createGetter
        result["name"] = self.name
        result["parameters"] = [x.to_json() for x in self.parameters]
        result["extractAll"] = self.extractAll
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# inlineLocalVariable feedback
#
# {
#   "name": String
#   "occurrences": int
# }
#
# Clients may not extend, implement or mix-in this class.
class InlineLocalVariableFeedback(RefactoringFeedback, HasToJson):

    def __init__(self, name, occurrences):
        self._name = name
        self._occurrences = occurrences
    # The name of the variable being inlined.
    @property
    def name(self):
        return self._name
    # The name of the variable being inlined.
    @name.setter
    def name(self, value):
        assert value is not None
        self._name = value

    # The number of times the variable occurs.
    @property
    def occurrences(self):
        return self._occurrences
    # The number of times the variable occurs.
    @occurrences.setter
    def occurrences(self, value):
        assert value is not None
        self._occurrences = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            name = None
            if "name" in json_data:
                name = (json_data["name"])
            else:
                raise Exception('missing key: "name"')
            occurrences = None
            if "occurrences" in json_data:
                occurrences = (json_data["occurrences"])
            else:
                raise Exception('missing key: "occurrences"')
            return InlineLocalVariableFeedback(name, occurrences)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["name"] = self.name
        result["occurrences"] = self.occurrences
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass
# inlineLocalVariable options
#
# Clients may not extend, implement or mix-in this class.
class InlineLocalVariableOptions(object):
    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# inlineMethod feedback
#
# {
#   "className": optional String
#   "methodName": String
#   "isDeclaration": bool
# }
#
# Clients may not extend, implement or mix-in this class.
class InlineMethodFeedback(RefactoringFeedback, HasToJson):

    def __init__(self, methodName, isDeclaration, className=None):
        self._className = className
        self._methodName = methodName
        self._isDeclaration = isDeclaration
    # The name of the class enclosing the method being inlined. If not a class
    # member is being inlined, this field will be absent.
    @property
    def className(self):
        return self._className
    # The name of the class enclosing the method being inlined. If not a class
    # member is being inlined, this field will be absent.
    @className.setter
    def className(self, value):
        self._className = value

    # The name of the method (or function) being inlined.
    @property
    def methodName(self):
        return self._methodName
    # The name of the method (or function) being inlined.
    @methodName.setter
    def methodName(self, value):
        assert value is not None
        self._methodName = value

    # True if the declaration of the method is selected. So all references
    # should be inlined.
    @property
    def isDeclaration(self):
        return self._isDeclaration
    # True if the declaration of the method is selected. So all references
    # should be inlined.
    @isDeclaration.setter
    def isDeclaration(self, value):
        assert value is not None
        self._isDeclaration = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            className = None
            if "className" in json_data:
                className = (json_data["className"])

            methodName = None
            if "methodName" in json_data:
                methodName = (json_data["methodName"])
            else:
                raise Exception('missing key: "methodName"')
            isDeclaration = None
            if "isDeclaration" in json_data:
                isDeclaration = (json_data["isDeclaration"])
            else:
                raise Exception('missing key: "isDeclaration"')
            return InlineMethodFeedback(methodName, isDeclaration, className=className)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        if self.className is not None:
            result["className"] = self.className
        result["methodName"] = self.methodName
        result["isDeclaration"] = self.isDeclaration
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# inlineMethod options
#
# {
#   "deleteSource": bool
#   "inlineAll": bool
# }
#
# Clients may not extend, implement or mix-in this class.
class InlineMethodOptions(RefactoringOptions, HasToJson):

    def __init__(self, deleteSource, inlineAll):
        self._deleteSource = deleteSource
        self._inlineAll = inlineAll
    # True if the method being inlined should be removed. It is an error if
    # this field is true and inlineAll is false.
    @property
    def deleteSource(self):
        return self._deleteSource
    # True if the method being inlined should be removed. It is an error if
    # this field is true and inlineAll is false.
    @deleteSource.setter
    def deleteSource(self, value):
        assert value is not None
        self._deleteSource = value

    # True if all invocations of the method should be inlined, or false if only
    # the invocation site used to create this refactoring should be inlined.
    @property
    def inlineAll(self):
        return self._inlineAll
    # True if all invocations of the method should be inlined, or false if only
    # the invocation site used to create this refactoring should be inlined.
    @inlineAll.setter
    def inlineAll(self, value):
        assert value is not None
        self._inlineAll = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            deleteSource = None
            if "deleteSource" in json_data:
                deleteSource = (json_data["deleteSource"])
            else:
                raise Exception('missing key: "deleteSource"')
            inlineAll = None
            if "inlineAll" in json_data:
                inlineAll = (json_data["inlineAll"])
            else:
                raise Exception('missing key: "inlineAll"')
            return InlineMethodOptions(deleteSource, inlineAll)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def fromRefactoringParams(refactoringParams, request):
        return InlineMethodOptions.from_json(refactoringParams.options)

    def to_json(self):
        result = {}
        result["deleteSource"] = self.deleteSource
        result["inlineAll"] = self.inlineAll
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass
# moveFile feedback
#
# Clients may not extend, implement or mix-in this class.
class MoveFileFeedback(object):
    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# moveFile options
#
# {
#   "newFile": FilePath
# }
#
# Clients may not extend, implement or mix-in this class.
class MoveFileOptions(RefactoringOptions, HasToJson):

    def __init__(self, newFile):
        self._newFile = newFile
    # The new file path to which the given file is being moved.
    @property
    def newFile(self):
        return self._newFile
    # The new file path to which the given file is being moved.
    @newFile.setter
    def newFile(self, value):
        assert value is not None
        self._newFile = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            newFile = None
            if "newFile" in json_data:
                newFile = (json_data["newFile"])
            else:
                raise Exception('missing key: "newFile"')
            return MoveFileOptions(newFile)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def fromRefactoringParams(refactoringParams, request):
        return MoveFileOptions.from_json(refactoringParams.options)

    def to_json(self):
        result = {}
        result["newFile"] = self.newFile
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# rename feedback
#
# {
#   "offset": int
#   "length": int
#   "elementKindName": String
#   "oldName": String
# }
#
# Clients may not extend, implement or mix-in this class.
class RenameFeedback(RefactoringFeedback, HasToJson):

    def __init__(self, offset, length, elementKindName, oldName):
        self._offset = offset
        self._length = length
        self._elementKindName = elementKindName
        self._oldName = oldName
    # The offset to the beginning of the name selected to be renamed.
    @property
    def offset(self):
        return self._offset
    # The offset to the beginning of the name selected to be renamed.
    @offset.setter
    def offset(self, value):
        assert value is not None
        self._offset = value

    # The length of the name selected to be renamed.
    @property
    def length(self):
        return self._length
    # The length of the name selected to be renamed.
    @length.setter
    def length(self, value):
        assert value is not None
        self._length = value

    # The human-readable description of the kind of element being renamed (such
    # as “class” or “function type alias”).
    @property
    def elementKindName(self):
        return self._elementKindName
    # The human-readable description of the kind of element being renamed (such
    # as “class” or “function type alias”).
    @elementKindName.setter
    def elementKindName(self, value):
        assert value is not None
        self._elementKindName = value

    # The old name of the element before the refactoring.
    @property
    def oldName(self):
        return self._oldName
    # The old name of the element before the refactoring.
    @oldName.setter
    def oldName(self, value):
        assert value is not None
        self._oldName = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            offset = None
            if "offset" in json_data:
                offset = (json_data["offset"])
            else:
                raise Exception('missing key: "offset"')
            length = None
            if "length" in json_data:
                length = (json_data["length"])
            else:
                raise Exception('missing key: "length"')
            elementKindName = None
            if "elementKindName" in json_data:
                elementKindName = (json_data["elementKindName"])
            else:
                raise Exception('missing key: "elementKindName"')
            oldName = None
            if "oldName" in json_data:
                oldName = (json_data["oldName"])
            else:
                raise Exception('missing key: "oldName"')
            return RenameFeedback(offset, length, elementKindName, oldName)
        else:
            raise ValueError("wrong type: %s" % json_data)

    def to_json(self):
        result = {}
        result["offset"] = self.offset
        result["length"] = self.length
        result["elementKindName"] = self.elementKindName
        result["oldName"] = self.oldName
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass

# rename options
#
# {
#   "newName": String
# }
#
# Clients may not extend, implement or mix-in this class.
class RenameOptions(RefactoringOptions, HasToJson):

    def __init__(self, newName):
        self._newName = newName
    # The name that the element should have after the refactoring.
    @property
    def newName(self):
        return self._newName
    # The name that the element should have after the refactoring.
    @newName.setter
    def newName(self, value):
        assert value is not None
        self._newName = value

    @classmethod
    def from_json(cls, json_data):
        if json_data is None:
            json_data = {}
        if isinstance(json_data, dict):
            newName = None
            if "newName" in json_data:
                newName = (json_data["newName"])
            else:
                raise Exception('missing key: "newName"')
            return RenameOptions(newName)
        else:
            raise ValueError("wrong type: %s" % json_data)

    @staticmethod
    def fromRefactoringParams(refactoringParams, request):
        return RenameOptions.from_json(refactoringParams.options)

    def to_json(self):
        result = {}
        result["newName"] = self.newName
        return result

    def __str__(self):
        return json.dumps(self.to_json())

    def __eq__(self, other):
        # TODO: implement this
        pass

    def __hash__(self):
        # TODO: implement this
        pass
