# Owner: Steve Ovens
# Date Created: Aug 2015
# Primary Function: This is a file intended to be supporting functions in various scripts
# This file will do nothing if run directly

import sys


class ImportHelper:

    """ This class simply allows for the dynamic loading of modules which are not apart of the stdlib.
     It specifies which module cannot be imported and provides the proper pip install command as output to the user.
    """

    @staticmethod
    def import_error_handling(import_this_module, modulescope):
        try:
            exec("import %s " % import_this_module) in modulescope
        except ImportError:
            print("This program requires %s in order to run. Please run" % import_this_module)
            print("pip install %s" % import_this_module)
            print("To install the missing component")
            sys.exit()
