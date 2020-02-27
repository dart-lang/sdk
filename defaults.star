_PROPERTIES = {"clobber": "true"}
_DIMENSIONS = {
    "cpu": "x86-64",
    "host_class": "default",
    "os": "Linux",
    "pool": "luci.dart.try"
}


def _default_dict(defaults, overrides):
    defaults = dict(defaults)
    if overrides:
        defaults.update(overrides)
    return defaults


defaults = struct(
    properties=lambda properties: _default_dict(_PROPERTIES, properties),
    dimensions=lambda dimensions: _default_dict(_DIMENSIONS, dimensions),
)
