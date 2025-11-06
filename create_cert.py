import sys
import datetime
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from pathlib import Path

CERT_PATH = Path.cwd().joinpath("server.crt")
KEY_PATH = Path.cwd().joinpath("server.key")


def create_cert():
    private_key = rsa.generate_private_key(
        public_exponent=65537, key_size=2048
    )

    cert = (
        x509.CertificateBuilder()
        .subject_name(x509.Name([]))
        .issuer_name(x509.Name([]))
        .public_key(private_key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(datetime.datetime.now(datetime.timezone.utc))
        .not_valid_after(
            datetime.datetime.now(datetime.timezone.utc)
            + datetime.timedelta(days=3650)
        )
        .sign(private_key, hashes.SHA256())
    )

    cert_pem = cert.public_bytes(serialization.Encoding.PEM)
    key_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    )

    with open(CERT_PATH, "wb") as f:
        f.write(cert_pem)
    with open(KEY_PATH, "wb") as f:
        f.write(key_pem)


def print_help():
    """Prints the help message for the script."""
    print("Usage: python create_cert.py")
    print("\nCreates a self-signed certificate and a private key.")
    print("The files will be saved as 'server.crt' and 'server.key' in the current directory.")


if __name__ == "__main__":
    if "-h" in sys.argv:
        print_help()
        sys.exit(0)
    create_cert()