#!/usr/bin/env python3
"""Собирает StealAVerity.rbxlx из папки src/ без Rojo.

Запуск: python3 tools/build_rbxlx.py
"""
import itertools
import os
from xml.sax.saxutils import escape

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ref = itertools.count(1)


def item(cls, name, props="", children=""):
    return (
        f'<Item class="{cls}" referent="RBX{next(ref)}">'
        f'<Properties><string name="Name">{escape(name)}</string>{props}</Properties>'
        f"{children}</Item>"
    )


def script_item(path):
    base = os.path.basename(path)[: -len(".luau")]
    if base.endswith(".server"):
        cls, name = "Script", base[: -len(".server")]
    elif base.endswith(".client"):
        cls, name = "LocalScript", base[: -len(".client")]
    else:
        cls, name = "ModuleScript", base
    with open(path, encoding="utf-8") as f:
        source = f.read()
    assert "]]>" not in source, path
    props = f'<ProtectedString name="Source"><![CDATA[{source}]]></ProtectedString>'
    return item(cls, name, props)


def folder_item(name, directory):
    files = sorted(f for f in os.listdir(directory) if f.endswith(".luau"))
    kids = "".join(script_item(os.path.join(directory, f)) for f in files)
    return item("Folder", name, "", kids)


src = os.path.join(ROOT, "src")
services = "".join(
    [
        item("Workspace", "Workspace"),
        item("ReplicatedStorage", "ReplicatedStorage", "", folder_item("Shared", os.path.join(src, "shared"))),
        item("ServerScriptService", "ServerScriptService", "", folder_item("Server", os.path.join(src, "server"))),
        item(
            "StarterPlayer",
            "StarterPlayer",
            "",
            item("StarterPlayerScripts", "StarterPlayerScripts", "", folder_item("Client", os.path.join(src, "client"))),
        ),
    ]
)

out = os.path.join(ROOT, "StealAVerity.rbxlx")
with open(out, "w", encoding="utf-8") as f:
    f.write('<roblox version="4">' + services + "</roblox>")
print("Создан", out)
