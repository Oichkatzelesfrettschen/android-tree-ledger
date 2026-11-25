"""Prints one line per project of a repo manifest: url, ref, sha, path.

The ref is the project's upstream attribute (refs/heads/ added to a bare branch
name); a pin without an upstream ref prints "-" so the verifier fails it.
Usage: pins_tsv.py MANIFEST_XML
"""
import sys
import xml.etree.ElementTree as ET

root = ET.parse(sys.argv[1]).getroot()
remotes = {r.get("name"): r.get("fetch").rstrip("/") for r in root.findall("remote")}
default = root.find("default")
dremote = default.get("remote") if default is not None else None


def walk(node, prefix):
    for p in node.findall("project"):
        path = p.get("path") or p.get("name")
        full = f"{prefix}/{path}" if prefix else path
        url = f"{remotes[p.get('remote') or dremote]}/{p.get('name')}"
        ref = p.get("upstream") or "-"
        if ref != "-" and not ref.startswith("refs/"):
            ref = "refs/heads/" + ref
        print(f"{url}\t{ref}\t{p.get('revision')}\t{full}")
        walk(p, full)


walk(root, "")
