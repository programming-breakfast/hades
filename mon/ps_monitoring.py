import os
import tornado.ioloop
from tornado.httpclient import HTTPError, AsyncHTTPClient
from tornado.gen import coroutine, Task
from tornado.ioloop import IOLoop
import time
import json
from tornado.options import define, options
import tornado.httpserver
import tornado.web
import logging
import tornado.netutil
import psutil

class StatusHandler(tornado.web.RequestHandler):
    def get(self):
        processes = {}
        pids = self.get_argument('pids', '').split(',')
        for pid in pids:
            try:
                process = psutil.Process(int(pid))

                processes[pid] = {
                    "cpu": {
                        'user': process.cpu_times()[0],
                        'system': process.cpu_times()[1],
                        'percent': process.cpu_percent(),
                    },
                    "memory": dict(map(lambda i: (i[0], i[1] / (1024 * 1024)), process.memory_info_ex()._asdict().items()))
                }
            except:
                logging.info("Can not receive data from pid#%s", pid)
        logging.info("hook recived data %s", pids)
        self.set_status(200)
        self.add_header('Content-Type', 'application/json')
        self.write(json.dumps(processes))

if __name__ == "__main__":
    define("port", default=8000, help="run on the given port", type=int)
    define("host", default='0.0.0.0', help="run on the given host", type=str)
    define("nameserver", default='8.8.8.8', help="default dns server", type=str)

    tornado.options.parse_command_line()

    app = tornado.web.Application(handlers=[
        (r"^/status$", StatusHandler)
    ], gzip=True, compress_response=True, debug=True)
    http_server = tornado.httpserver.HTTPServer(app)
    http_server.listen(options.port, address=options.host)
    tornado.ioloop.IOLoop.current().start()
