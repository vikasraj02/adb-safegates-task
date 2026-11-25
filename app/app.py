"""Minimal Hello World web app (standard library only -> no pip deps)."""
import os
import socket
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(os.environ.get("PORT", "8080"))
VERSION = os.environ.get("APP_VERSION", "dev")

PAGE = """<!doctype html>
<html lang="en"><head><meta charset="utf-8"><title>Hello World</title>
<style>body{{font-family:system-ui,sans-serif;display:grid;place-items:center;
height:100vh;margin:0;background:#0f172a;color:#e2e8f0}}
.card{{text-align:center}}small{{color:#94a3b8}}</style></head>
<body><div class="card"><h1>Hello, World!</h1>
<p>Served from pod <b>{host}</b></p><small>version: {version}</small></div></body></html>"""


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/healthz":
            body, ctype = b"ok", "text/plain"
        else:
            body = PAGE.format(host=socket.gethostname(), version=VERSION).encode()
            ctype = "text/html; charset=utf-8"
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    print(f"Listening on 0.0.0.0:{PORT}", flush=True)
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
