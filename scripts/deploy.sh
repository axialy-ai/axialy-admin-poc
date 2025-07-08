#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
remote_file_editor.py  ·  v0.6 (2025‑07‑07)
───────────────────────────────────────────
Browse **and now create** files on a remote Linux server over SSH:

  • Double‑click a file to load & edit → **Save ↑** uploads the change.
  • Select a **folder**, hit **New File**, enter a name → paste content
    → **Save ↑** uploads the brand‑new file.

Only external dependency: **paramiko**
    pip install paramiko
"""

from __future__ import annotations
import io, os, pathlib, shlex, threading, tkinter as tk
from tkinter import ttk, messagebox, simpledialog
from tkinter.scrolledtext import ScrolledText

import paramiko


# ────────── SSH helpers ────────────────────────────────────────────────────

def _load_pkey(path: pathlib.Path, password: str | None):
    for cls in (
        paramiko.RSAKey,
        paramiko.Ed25519Key,
        paramiko.ECDSAKey,
        paramiko.DSSKey,
    ):
        try:
            return cls.from_private_key_file(str(path), password=password)
        except (paramiko.SSHException, paramiko.PasswordRequiredException):
            pass
    raise paramiko.SSHException("Unsupported / broken key file")


def _open_ssh(user: str, host: str, pwd: str | None, key_path: pathlib.Path | None) -> paramiko.SSHClient:
    cli = paramiko.SSHClient()
    cli.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    if key_path:
        cli.connect(host, username=user, pkey=_load_pkey(key_path, pwd), timeout=25)
    else:
        cli.connect(host, username=user, password=pwd, timeout=25)
    return cli


def _ssh_ls(cli: paramiko.SSHClient, path: str) -> list[tuple[str, str]]:
    cmd = (
        f"find {shlex.quote(path)} -maxdepth 1 -mindepth 1 "
        r"-printf '%P\t%y\n' 2>/dev/null"
    )
    _stdin, stdout, _ = cli.exec_command(cmd)
    out = stdout.read().decode(errors="replace")
    return [tuple(l.split("\t", 1)) for l in out.splitlines() if l]


# ────────── GUI ────────────────────────────────────────────────────────────

class RemoteFileEditor(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Remote File Editor")
        self.geometry("940x680")
        self.minsize(760, 540)

        self._build_conn_bar()
        self._build_body()

        # bookkeeping
        self._iid_path: dict[str, str] = {}
        self._iid_type: dict[str, str] = {}  # "d" or "f"
        self._loaded_dirs: set[str] = set()
        self.cli: paramiko.SSHClient | None = None
        self.sftp: paramiko.SFTPClient | None = None
        self._current_file: str | None = None
        self._file_original: str = ""

    # ────────── connection bar ───────────────────────────────────────────
    def _build_conn_bar(self):
        bar = ttk.Frame(self, padding=8)
        bar.grid(row=0, column=0, sticky="ew")
        bar.columnconfigure(8, weight=1)

        self.var_user = tk.StringVar(value="root")
        self.var_host = tk.StringVar()
        self.var_pass = tk.StringVar()
        self.var_key = tk.StringVar(value=str(pathlib.Path.home() / ".ssh/id_ed25519"))

        ttk.Label(bar, text="User").grid(row=0, column=0, padx=(0, 2))
        ttk.Entry(bar, textvariable=self.var_user, width=9).grid(row=0, column=1)

        ttk.Label(bar, text="@").grid(row=0, column=2)
        ttk.Entry(bar, textvariable=self.var_host, width=18).grid(row=0, column=3)

        ttk.Label(bar, text="Pass/phrase").grid(row=0, column=4, padx=(12, 2))
        ttk.Entry(bar, textvariable=self.var_pass, width=16, show="•").grid(row=0, column=5)

        ttk.Label(bar, text="Key").grid(row=0, column=6, padx=(12, 2))
        ttk.Entry(bar, textvariable=self.var_key, width=26).grid(row=0, column=7, sticky="ew")

        ttk.Button(bar, text="Connect / Refresh", command=self._connect).grid(row=0, column=9, padx=(12, 0))

    # ────────── tree & editor panes ──────────────────────────────────────
    def _build_body(self):
        body = ttk.Frame(self, padding=(8, 6))
        body.grid(row=1, column=0, sticky="nsew")
        body.columnconfigure(0, weight=1)
        body.columnconfigure(1, weight=2)
        body.rowconfigure(1, weight=1)
        self.rowconfigure(1, weight=1)

        # toolbar
        tbar = ttk.Frame(body)
        tbar.grid(row=0, column=0, sticky="w")
        ttk.Button(tbar, text="Expand all", command=lambda: self._expand_all(True)).grid(row=0, column=0, padx=2)
        ttk.Button(tbar, text="Collapse all", command=lambda: self._expand_all(False)).grid(row=0, column=1, padx=2)
        ttk.Button(tbar, text="Open file ↓", command=self._open_selected).grid(row=0, column=2, padx=(16, 2))

        self.btn_new = ttk.Button(tbar, text="New File", command=self._new_file, state="disabled")
        self.btn_new.grid(row=0, column=3, padx=2)

        self.btn_save = ttk.Button(tbar, text="Save ↑", command=self._save_current, state="disabled")
        self.btn_save.grid(row=0, column=4, padx=2)

        # Tree
        self.tree = ttk.Treeview(body, show="tree", selectmode="browse")
        self.tree.grid(row=1, column=0, sticky="nsew")
        ttk.Scrollbar(body, command=self.tree.yview).grid(row=1, column=0, sticky="nse", padx=(0, 5))
        self.tree.configure(yscroll=lambda *a: None)

        self.tree.bind("<<TreeviewOpen>>", self._on_open_dir)
        self.tree.bind("<Double-1>", lambda _e: self._open_selected())
        self.tree.bind("<Return>", lambda _e: self._open_selected())
        self.tree.bind("<<TreeviewSelect>>", self._on_tree_select)

        # Editor
        self.txt = ScrolledText(body, font=("Consolas", 10), wrap="none", undo=True)
        self.txt.grid(row=1, column=1, sticky="nsew")
        self.txt.bind("<<Modified>>", self._on_modified)

    # ────────── SSH connect ─────────────────────────────────────────────
    def _connect(self):
        host = self.var_host.get().strip()
        if not host:
            return messagebox.showerror("Missing host", "Enter Host / IP first.")
        user = self.var_user.get().strip() or "root"
        key = pathlib.Path(self.var_key.get()) if self.var_key.get().strip() else None
        pwd = self.var_pass.get() or None

        # clear UI
        self.tree.delete(*self.tree.get_children())
        self.txt.delete("1.0", "end")
        self._iid_path.clear(); self._iid_type.clear(); self._loaded_dirs.clear()
        self.btn_save["state"] = "disabled"
        self.btn_new["state"] = "disabled"
        self._current_file = None
        self.title("Remote File Editor")

        def worker():
            try:
                self.cli = _open_ssh(user, host, pwd, key)
                self.sftp = self.cli.open_sftp()
            except Exception as exc:
                self.after(0, lambda: messagebox.showerror("SSH error", str(exc)))
                return
            self.after(0, self._build_root)

        threading.Thread(target=worker, daemon=True).start()

    def _build_root(self):
        iid = self.tree.insert("", "end", text="/", open=False)
        self._iid_path[iid] = "/"
        self._iid_type[iid] = "d"
        self.tree.insert(iid, "end")  # dummy
        self._loaded_dirs.clear()
        self.btn_new["state"] = "normal"

    # ────────── Tree population ─────────────────────────────────────────
    def _on_open_dir(self, _evt):
        iid = self.tree.focus()
        if iid in self._loaded_dirs:
            return
        path = self._iid_path.get(iid, "/")
        self.tree.delete(*self.tree.get_children(iid))  # remove dummy

        def worker():
            try:
                entries = _ssh_ls(self.cli, path)
            except Exception as exc:
                self.after(0, lambda: messagebox.showerror("SSH error", str(exc)))
                return
            entries.sort(key=lambda t: (t[1] != "d", t[0].lower()))
            self.after(0, lambda: self._populate(iid, path, entries))

        threading.Thread(target=worker, daemon=True).start()

    def _populate(self, parent_iid, parent_path, entries):
        for name, typ in entries:
            full = f"{parent_path.rstrip('/')}/{name}"
            iid = self.tree.insert(parent_iid, "end", text=name)
            self._iid_path[iid] = full
            self._iid_type[iid] = typ
            if typ == "d":
                self.tree.insert(iid, "end")  # dummy
        self._loaded_dirs.add(parent_iid)

    def _expand_all(self, expand=True):
        for iid in self.tree.get_children(""):
            self._expand_rec(iid, expand)

    def _expand_rec(self, iid, expand):
        self.tree.item(iid, open=expand)
        for ch in self.tree.get_children(iid):
            self._expand_rec(ch, expand)

    def _on_tree_select(self, _evt):
        """Enable *New File* button when a directory is selected."""
        iid = self.tree.focus()
        if self._iid_type.get(iid) == "d":
            self.btn_new["state"] = "normal"
        else:
            self.btn_new["state"] = "disabled"

    # ────────── open / save / new file ─────────────────────────────────
    def _open_selected(self):
        iid = self.tree.focus()
        path = self._iid_path.get(iid)
        if not path or self._iid_type.get(iid) == "d":
            return  # directory
        self._load_file(path)

    def _new_file(self):
        iid = self.tree.focus() or ""
        if self._iid_type.get(iid) == "f":
            # If user accidentally selected a file, use its parent directory
            iid = self.tree.parent(iid)
        dir_path = self._iid_path.get(iid, "/")

        name = simpledialog.askstring("New file", "Enter new file name:", parent=self)
        if not name:
            return
        if "/" in name or name.strip() == "":
            return messagebox.showerror("Invalid name", "Name must not contain '/' and cannot be empty.")

        new_path = f"{dir_path.rstrip('/')}/{name}"
        self._current_file = new_path
        self._file_original = ""  # brand‑new
        self.txt.delete("1.0", "end")
        self.txt.focus_set()
        self.btn_save["state"] = "disabled"  # becomes enabled on first modification
        self.title(f"Remote File Editor – {new_path} (new)")

        # Update tree immediately
        new_iid = self.tree.insert(iid, "end", text=name)
        self._iid_path[new_iid] = new_path
        self._iid_type[new_iid] = "f"
        self.tree.selection_set(new_iid)
        self.tree.see(new_iid)

    def _load_file(self, path: str):
        if not self.sftp:
            return
        self.txt.delete("1.0", "end"); self.txt.insert("1.0", f"# Loading {path} …\n")
        self.btn_save["state"] = "disabled"

        def worker():
            try:
                with self.sftp.file(path, "rb") as fh:
                    data = fh.read()
                txt = self._decode(data)
            except Exception as exc:
                txt = f"[Error reading {path}: {exc}]"
            self._file_original = txt
            self._current_file = path
            self.after(0, lambda: self._show_text(txt))

        threading.Thread(target=worker, daemon=True).start()

    def _show_text(self, txt: str):
        self.txt.delete("1.0", "end"); self.txt.insert("1.0", txt)
        self.txt.edit_reset(); self.txt.edit_modified(False)
        self.title(f"Remote File Editor – {self._current_file}")

    def _on_modified(self, _evt):
        if not self._current_file:
            return
        dirty = self.txt.get("1.0", "end-1c") != self._file_original
        self.btn_save["state"] = ("normal" if dirty else "disabled")
        self.txt.edit_modified(False)

    def _save_current(self):
        if not self._current_file or not self.sftp:
            return
        new_bytes = self.txt.get("1.0", "end-1c").encode()

        def worker():
            try:
                # Ensure directory exists (simple single‑level create)
                dir_path = os.path.dirname(self._current_file) or "/"
                try:
                    self.sftp.chdir(dir_path)
                except IOError:
                    # mkdir recursion (best effort)
                    parts = dir_path.strip("/").split("/")
                    cur = "/"
                    for p in parts:
                        cur = f"{cur.rstrip('/')}/{p}"
                        try:
                            self.sftp.stat(cur)
                        except IOError:
                            self.sftp.mkdir(cur)

                with self.sftp.file(self._current_file, "wb") as fh:
                    fh.write(new_bytes)
                ok = True
            except Exception as exc:
                ok = False
                self.after(0, lambda: messagebox.showerror("Save error", str(exc)))

            if ok:
                self._file_original = new_bytes.decode(errors="replace")
                self.after(0, lambda: [
                    self.btn_save.configure(state="disabled"),
                    messagebox.showinfo("Saved", f"Uploaded {len(new_bytes):,} bytes."),
                ])

        threading.Thread(target=worker, daemon=True).start()

    # ────────── misc ────────────────────────────────────────────────────
    @staticmethod
    def _decode(b: bytes) -> str:
        for enc in ("utf-8", "utf-8-sig", "latin1"):
            try:
                return b.decode(enc)
            except UnicodeDecodeError:
                continue
        return b.decode("latin1", errors="replace")


if __name__ == "__main__":
    RemoteFileEditor().mainloop()
