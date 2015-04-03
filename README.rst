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

Installs the carbon-cache_ and carbon-aggregator_ daemons, with all dependencies.

* started via upstart_
* memcached listening on standard local ports
* carbon-cache_ listening on standard ports
* carbon-aggregator_ listening on standard ports
* configured for FHS_ conventions (mostly)

Further customization is available via pillars.

.. _FHS: http://www.pathname.com/fhs/
.. _upstart: http://upstart.ubuntu.com
.. _carbon-cache: http://graphite.readthedocs.org/en/latest/carbon-daemons.html#carbon-cache-py
.. _carbon-aggregator: http://graphite.readthedocs.org/en/latest/carbon-daemons.html#carbon-aggregator-py

``graphite.uwsgi``
------------------

Installs the graphite_ web application.

* started via upstart_
* uwsgi_ running the django application listening on ``/var/run/graphite/socket``
* nginx config files ready for inclusion
* logs to ``/var/log/graphite``
* uses memcached

Further customization is available via pillars.

.. _uwsgi: http://uwsgi-docs.readthedocs.org
.. _graphite: http://graphite.readthedocs.org

``graphite.nginx``
------------------

Installs nginx_ server to serve the graphite_ website. Very minimal
configuration mostly indented of testing. I recommend managing NOT
using this state and including the nginx_ config files created by
``graphite.uwsgi``

.. _nginx: http://nginx.org/

Known Issues
============

* the upstart scripts for the ``carbon-*`` daemons are a bad hack. The
  carbon daemons perform their own daemonization, and this does not
  play nicely with upstart. You can set some unrelated flags to get
  carbon daemons to NOT daemonize, but then they don't log. To get
  proper logging, we let the carbon daemons daemonize themselves, and
  manage them in upstart via ``pre-start`` and ``pre-stop`` hooks
