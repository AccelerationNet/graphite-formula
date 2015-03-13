graphite-formula
================

Formula to set up and configure graphite servers on Debian systems

.. note::

    See the full `Salt Formulas installation and usage instructions
    <http://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_.

Available states
================

.. contents::
    :local:

``graphite``
------------

Installs all dependencies and the graphite packages themselves, and
configured daemons and servers.

* supervisord_ to run carbon-cache, carbon-aggregator, and
  graphite-web
* gunicorn_ running graphite-web on ``http://localhost:8080``
* nginx as a proxy on ``http://$host``
* memcached with appropriate carbon/graphite-web configuration
* carbon-cache listening on standard ports
* carbon-aggregator listening on standard ports
* configured for FHS_ conventions (mostly)

Further customization is available via pillars.

.. _supervisord: http://supervisord.org/
.. _gunicorn: http://gunicorn.org/
.. _FHS: http://www.pathname.com/fhs/


Known Issues
============

* only graphite-web logs are written properly to ``/var/log/carbon``,
  using ``--nodaemon`` for carbon-cache turns off file logging but is
  needed for supervisord_ (or many other process managers). Logs are
  still accessible via ``/var/log/supervisor``
