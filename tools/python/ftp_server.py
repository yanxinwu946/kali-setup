from pyftpdlib.handlers import FTPHandler
from pyftpdlib.servers import FTPServer
from pyftpdlib.authorizers import DummyAuthorizer
import logging
import os

LOG_DIR = "/var/www/html/logs"
LOG_FILE = os.path.join(LOG_DIR, "ftp_server.log")

os.makedirs(LOG_DIR, exist_ok=True)

logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

class CustomFTPHandler(FTPHandler):
    def on_connect(self):
        logging.info(f"Connection from {self.remote_ip}:{self.remote_port}")

    def on_disconnect(self):
        logging.info(f"Disconnected {self.remote_ip}:{self.remote_port}")

    def on_login(self, username):
        logging.info(f"User logged in: {username}")

    def on_logout(self, username):
        logging.info(f"User logged out: {username}")

    def on_file_sent(self, file):
        logging.info(f"File sent: {file}")

    def on_file_received(self, file):
        logging.info(f"File received: {file}")

    def on_incomplete_file_sent(self, file):
        logging.warning(f"Incomplete file sent: {file}")

    def on_incomplete_file_received(self, file):
        logging.warning(f"Incomplete file received: {file}")

def main():
    authorizer = DummyAuthorizer()
    authorizer.add_user("ADMIN", "12345", ".", perm="elradfmw")

    handler = CustomFTPHandler
    handler.authorizer = authorizer

    address = ("0.0.0.0", 21)
    server = FTPServer(address, handler)

    print(f"Starting FTP server on {address[0]}:{address[1]}, logging to {LOG_FILE}")
    server.serve_forever()

if __name__ == "__main__":
    main()

