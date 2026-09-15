"""App-wide logging setup.

Uvicorn configures the root logger, so this just adds a consistent
``msafe.*`` namespace and lets the level be tuned via env var without
touching call sites.
"""

import logging
import os

_CONFIGURED = False


def configure_logging() -> None:
    global _CONFIGURED
    if _CONFIGURED:
        return

    level = os.getenv("LOG_LEVEL", "INFO").upper()
    logging.basicConfig(
        level=level,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
    logging.getLogger("msafe").setLevel(level)
    _CONFIGURED = True


def get_logger(name: str) -> logging.Logger:
    configure_logging()
    return logging.getLogger(f"msafe.{name}")
