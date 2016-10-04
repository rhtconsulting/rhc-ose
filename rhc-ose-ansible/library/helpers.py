#!/usr/bin/python
# helper functions go here to be called by various scripts


def error_out(message=None, error_code=1):
    import sys
    if message is not None:
        print message
    if type(error_code) == int:
        sys.exit(error_code)
    else:
        sys.exit()