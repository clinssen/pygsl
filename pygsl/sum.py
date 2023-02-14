# This file was automatically generated by SWIG (http://www.swig.org).
# Version 4.0.2
#
# Do not make changes to this file unless you know what you are doing--modify
# the SWIG interface file instead.

"""
Sum modul for Levin u-transform

This module provides a function for accelerating the convergence of
series based on the Levin u-transform.  This method takes a small
number of terms from the start of a series and uses a systematic
approximation to compute an extrapolated value and an estimate of its
error. The u-transform works for both convergent and divergent
series, including asymptotic series.
"""

from sys import version_info as _swig_python_version_info
if _swig_python_version_info < (2, 7, 0):
    raise RuntimeError("Python 2.7 or later required")

# Pull in all the attributes from the low-level C/C++ module
if __package__ or "." in __name__:
    from ._sum import *
else:
    from _sum import *

try:
    import builtins as __builtin__
except ImportError:
    import __builtin__

def _swig_repr(self):
    try:
        strthis = "proxy of " + self.this.__repr__()
    except __builtin__.Exception:
        strthis = ""
    return "<%s.%s; %s >" % (self.__class__.__module__, self.__class__.__name__, strthis,)


def _swig_setattr_nondynamic_instance_variable(set):
    def set_instance_attr(self, name, value):
        if name == "thisown":
            self.this.own(value)
        elif name == "this":
            set(self, name, value)
        elif hasattr(self, name) and isinstance(getattr(type(self), name), property):
            set(self, name, value)
        else:
            raise AttributeError("You cannot add instance attributes to %s" % self)
    return set_instance_attr


def _swig_setattr_nondynamic_class_variable(set):
    def set_class_attr(cls, name, value):
        if hasattr(cls, name) and not isinstance(getattr(cls, name), property):
            set(cls, name, value)
        else:
            raise AttributeError("You cannot add class attributes to %s" % cls)
    return set_class_attr


def _swig_add_metaclass(metaclass):
    """Class decorator for adding a metaclass to a SWIG wrapped class - a slimmed down version of six.add_metaclass"""
    def wrapper(cls):
        return metaclass(cls.__name__, cls.__bases__, cls.__dict__.copy())
    return wrapper


class _SwigNonDynamicMeta(type):
    """Meta class to enforce nondynamic attributes (no new attributes) for a class"""
    __setattr__ = _swig_setattr_nondynamic_class_variable(type.__setattr__)



def levin_sum(a, truncate=False, info_dict=None):
    """Return (sum(a), err) where sum(a) is the extrapolated
    sum of the infinite series a and err is an error estimate.

    Uses the Levin u-transform method.

    Parameters:
      a : A list or array of floating point numbers assumed
          to be the first terms in a series.
      truncate: If True, then use a more efficient algorithm, but with
          a less accurate error estimate
      info_dict: If info_dict is provided, then two entries will
          be added: 'terms_used' will be the number of terms
          used and 'sum_plain' will be the sum of these terms
          without acceleration.

    Notes: The error estimate is made assuming that the terms a are
    computed to machined precision.

    Example: Computing the zeta function 
    zeta(2) = 1/1**2 + 1/2**2 + 1/3**2 + ... = pi**2/6

    >>> from math import pi
    >>> zeta_2 = pi**2/6
    >>> a = [1.0/n**2 for n in range(1,21)]
    >>> info_dict = {}
    >>> (ans, err_est) = levin_sum(a, info_dict=info_dict)
    >>> ans, zeta_2             # doctest: +ELLIPSIS
    1.644934066..., 1.644934066...
    >>> err = abs(ans - zeta_2)
    >>> err < err_est
    True
    >>> (ans, err_est) = levin_sum(a, truncate=False)
    >>> ans             # doctest: +ELLIPSIS
    1.644934066...
    """
    if truncate:
        l = _levin_utrunc(len(a))
    else:
        l = _levin(len(a))

    ans = l.accel(a)
    if info_dict is not None:
        info_dict['sum_plain'] = l.sum_plain()
        info_dict['terms_used'] = l.get_terms_used()
    del l
    return ans





