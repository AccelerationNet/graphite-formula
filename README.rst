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

Installs all dependencies and the graphite packages themselves, sets
up a minimal system using supervisord_ to run carbon-cache,
carbon-aggregator, and graphite-web as individual python processes.
graphite-web is run using gunicorn_ on ``http://localhost:8080``.
Nginx is proxying ``http://$host`` to ``http://localhost:8080``.

.. _supervisord: http://supervisord.org/
.. _gunicorn: http://gunicorn.org/
