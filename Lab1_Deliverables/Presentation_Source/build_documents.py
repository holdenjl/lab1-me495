"""Current build entry point; earlier parameter-only version is archived."""
import runpy
from pathlib import Path
runpy.run_path(str(Path(__file__).with_name("build_revised_documents.py")), run_name="__main__")
