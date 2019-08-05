builder = None


def set_builder(created_builder):
    global builder
    builder = created_builder


def get_interfaces_info():
    global builder
    return builder._info_collector.interfaces_info
