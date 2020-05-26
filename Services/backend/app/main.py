#!/usr/bin/env python3
"""
    Description: Tornado based web api service
"""

import os
import sys
import json
import logging

from http import HTTPStatus
import asyncio
import tornado.ioloop
import tornado.web
import redis

# Globals
LOG=None
r=None
app_port=8080

def _init():
    global LOG
    log_level=os.getenv("LOG_LEVEL",'INFO')
    app_port=os.getenv("APP_PORT", 8080)
    redis_host=os.getenv("REDIS_HOST", "localhost")
    redis_port=os.getenv("REDIS_PORT", 6379)

    if 'DEBUG' in log_level:
        logging.basicConfig(level=logging.DEBUG, format='%(asctime)s %(levelname)s %(filename)s %(lineno)d: %(message)s')
        LOG = logging.getLogger()
    else:
        logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(filename)s %(lineno)d: %(message)s')
        LOG = logging.getLogger()

    try:
        r=redis.StrictRedis(host=redis_host, port=redis_port,charset="utf-8", decode_responses=True)
        if r.ping():
            LOG.info("redis connected")
    except Exception as e:
        LOG.error(f"{e}")
        sys.exit()

class RootHandler(tornado.web.RequestHandler):
    """ healthcheck """
    def get(self):
        """ health check probe """
        self.set_status(HTTPStatus.OK)

def _make_app():
    """ Associate end points with handlers """
    return tornado.web.Application([
        (r"/", RootHandler)
        ])

def _main():
    """ main """
    _init()
    try:
        app = _make_app()
        LOG.info(f"backend listening on {app_port}")
        app.listen(app_port)
        tornado.ioloop.IOLoop.current().start()
    except Exception as e:          # pylint: disable=broad-except
        LOG.error(f"Unhandled exception in _main(): {e}")
        ret = 1
    return ret

if __name__ == "__main__":
    try:
        sys.exit(_main())
    except KeyboardInterrupt:       # don't print python trace backs
        print("\nInterrupted.\n")
        try:
            sys.exit(1)
        except SystemExit:
            os._exit(1)             # pylint: disable=protected-access
