#!/usr/bin/env python3
"""Check the W6 downloads without reading missing files from outside each ZIP.

Run from any directory: python3 W6/scripts/check_bundle_links.py
Optional positional arguments select other ZIPs built with the same layout.
Only the Python standard library is required. Markdown code fences and inline
code are excluded from link discovery. Lab QMD links use their published HTML
locations, matching render_lab.py's relocation of the rendered documents.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass, field
from html import unescape
from html.parser import HTMLParser
from pathlib import Path, PurePosixPath
import re
import tempfile
from urllib.parse import unquote, urlsplit
from zipfile import BadZipFile, ZipFile


REPO = Path(__file__).resolve().parents[2]
DEFAULT_ARCHIVES = (
    REPO / "W6/downloads/week6-lab.zip",
    REPO / "W6/downloads/week6-student-source.zip",
)
GENERATED_GUIDES = {"week6-student-source/README.md"}
DOCUMENT_SUFFIXES = {".html", ".htm", ".md", ".qmd", ".css"}


@dataclass(frozen=True)
class Link:
    url: str
    line: int


@dataclass
class Document:
    links: list[Link] = field(default_factory=list)
    anchors: set[str] = field(default_factory=set)


def blank(text: str) -> str:
    """Mask code while retaining line numbers for useful diagnostics."""
    return "".join("\n" if char == "\n" else " " for char in text)


def css_links(text: str, first_line: int = 1) -> list[Link]:
    text = re.sub(r"/\*.*?\*/", lambda match: blank(match[0]), text, flags=re.S)
    # @import url(...) is already covered by url(); also allow quoted imports.
    pattern = r"url\(\s*(?:\"([^\"]*)\"|'([^']*)'|([^)]*))\s*\)|@import\s+[\"']([^\"']+)[\"']"
    return [
        Link(next(value for value in match.groups() if value is not None).strip(),
             first_line + text.count("\n", 0, match.start()))
        for match in re.finditer(pattern, text, re.I)
    ]


class HTMLLinks(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.document = Document()
        self.in_style = False

    def handle_starttag(self, tag: str, attributes: list[tuple[str, str | None]]) -> None:
        attrs = dict(attributes)
        line = self.getpos()[0]
        for key in (("id", "name") if tag == "a" else ("id",)):
            if attrs.get(key):
                self.document.anchors.add(attrs[key])
        for key in ("href", "src", "poster", "data-src", "data-background-image",
                    "data-background-video", "data-background-audio"):
            if attrs.get(key):
                self.document.links.append(Link(attrs[key], line))
        if tag == "object" and attrs.get("data"):
            self.document.links.append(Link(attrs["data"], line))
        if attrs.get("srcset"):
            # Data URIs may contain commas, so split only after a descriptor or
            # a candidate URL followed by a comma and whitespace.
            candidates = re.split(r"\s+\d+(?:\.\d+)?[wx]\s*,\s*|,\s+", attrs["srcset"])
            for candidate in candidates:
                url = re.sub(r"\s+\d+(?:\.\d+)?[wx]\s*$", "", candidate).strip()
                if url:
                    self.document.links.append(Link(url, line))
        if attrs.get("style"):
            self.document.links.extend(css_links(attrs["style"], line))
        if tag == "style":
            self.in_style = True

    handle_startendtag = handle_starttag

    def handle_endtag(self, tag: str) -> None:
        if tag == "style":
            self.in_style = False

    def handle_data(self, data: str) -> None:
        if self.in_style:
            self.document.links.extend(css_links(data, self.getpos()[0]))


def without_markdown_code(text: str) -> str:
    lines = text.splitlines(keepends=True)
    fence = None
    for index, line in enumerate(lines):
        marker = re.match(r"^\s{0,3}(`{3,}|~{3,})(.*)$", line)
        if fence is not None:
            lines[index] = blank(line)
            if marker and marker[1][0] == fence[0] and len(marker[1]) >= len(fence) and not marker[2].strip():
                fence = None
        elif marker:
            fence = marker[1]
            lines[index] = blank(line)
    text = "".join(lines)
    # Raw code blocks and inline code are literal examples, too.
    text = re.sub(r"<(pre|code|script)\b[^>]*>.*?</\1\s*>",
                  lambda match: blank(match[0]), text, flags=re.S | re.I)
    return re.sub(r"(`+)(.*?)\1", lambda match: blank(match[0]), text, flags=re.S)


def destination(text: str, start: int) -> tuple[str, int] | None:
    """Read a Markdown destination, allowing balanced parentheses in paths."""
    index = start
    while index < len(text) and text[index].isspace():
        index += 1
    if index == len(text):
        return None
    if text[index] == "<":
        end = text.find(">", index + 1)
        return (text[index + 1:end], end + 1) if end != -1 else None
    begin = index
    depth = 0
    while index < len(text):
        char = text[index]
        if char == "\\" and index + 1 < len(text):
            index += 2
            continue
        if char == "(":
            depth += 1
        elif char == ")":
            if depth == 0:
                break
            depth -= 1
        elif char.isspace() and depth == 0:
            break
        index += 1
    return (text[begin:index], index) if index > begin else None


def markdown_document(text: str) -> Document:
    text = without_markdown_code(text)
    parser = HTMLLinks()
    parser.feed(text)
    document = parser.document
    definitions = {}
    for match in re.finditer(r"^\s{0,3}\[([^]\n]+)\]:[ \t]*(.*)$", text, re.M):
        target = destination(match[2], 0)
        if target:
            definitions[" ".join(match[1].lower().split())] = target[0]
            document.links.append(Link(target[0], text.count("\n", 0, match.start()) + 1))
    # Skip the definition lines when discovering inline and reference links.
    text = re.sub(r"^\s{0,3}\[[^]\n]+\]:[^\n]*", lambda match: blank(match[0]), text, flags=re.M)
    for match in re.finditer(r"!?\[((?:\\.|\[[^]\n]*\]|[^]\\\n])*)\](?:\[([^]\n]*)\])?", text):
        end = match.end()
        url = None
        if end < len(text) and text[end] == "(":
            target = destination(text, end + 1)
            if target:
                url = target[0]
        else:
            label = match[2] if match[2] else match[1]
            url = definitions.get(" ".join(label.lower().split()))
        if url:
            url = re.sub(r"\\([\\`*{}\[\]()#+.!_<> -])", r"\1", url)
            document.links.append(Link(unescape(url), text.count("\n", 0, match.start()) + 1))
    # Pandoc/Quarto headings and explicit attributes cover the local anchors in
    # source documents. Rendered HTML IDs are preferred when that file exists.
    counts = {}
    for match in re.finditer(r"^\s{0,3}#{1,6}\s+(.+?)\s*#*\s*$", text, re.M):
        heading = match[1]
        explicit = re.search(r"\{[^}]*#([^\s}]+)[^}]*\}", heading)
        if explicit:
            document.anchors.add(explicit[1])
        heading = re.sub(r"\{[^}]*\}|<[^>]*>", "", heading).lower()
        heading = re.sub(r"[^\w\s.\-]", "", heading)
        heading = re.sub(r"^[^\w]*", "", heading).strip()
        slug = re.sub(r"\s+", "-", heading)
        count = counts.get(slug, 0)
        counts[slug] = count + 1
        document.anchors.add(slug if not count else f"{slug}-{count}")
    for match in re.finditer(r"\{[^}\n]*#([^\s}]+)[^}\n]*\}", text):
        document.anchors.add(match[1])
    # The deck's YAML CSS list is a source dependency even though HTML embeds it.
    frontmatter = re.match(r"\A---\s*\n(.*?)\n---\s*(?:\n|$)", text, re.S)
    if frontmatter:
        resource_keys = "css|logo|bibliography|csl|include-in-header|include-before-body|include-after-body"
        for match in re.finditer(rf"^\s*(?:{resource_keys}):\s*(.+)$", frontmatter[1], re.M):
            value = match[1].strip()
            if value.startswith("[") and value.endswith("]"):
                values = value[1:-1].split(",")
            else:
                values = [value]
            for value in values:
                value = value.strip().strip("\"'")
                if value and value not in {"true", "false", "null"} and not value.startswith(("{", "|", ">")):
                    document.links.append(Link(value, text.count("\n", 0, frontmatter.start(1) + match.start()) + 1))
    return document


def published_path(path: Path) -> Path:
    if path.suffix == ".qmd" and path.parent.name == "source":
        lab = path.parent.parent
        if path.stem == "Lab_Session_W6":
            return lab / "Lab_Session_W6.html"
        if path.stem == "Lab_Session_W6_Answers":
            return lab / "answers/Lab_Session_W6_Answers.html"
    return path


def inspect_archive(archive: Path, repo: Path) -> tuple[int, int]:
    problems = []
    links_checked = 0
    payloads_checked = 0
    with tempfile.TemporaryDirectory(prefix="w6-links-") as temporary:
        extracted = Path(temporary).resolve()
        with ZipFile(archive) as bundle:
            names = [entry.filename for entry in bundle.infolist() if not entry.is_dir()]
            if len(names) != len(set(names)):
                problems.append("archive has duplicate file entries")
            roots = {PurePosixPath(name).parts[0] for name in names}
            if len(roots) != 1:
                raise ValueError("archive must have one top-level package directory")
            package = extracted / next(iter(roots))
            for name in names:
                relative = PurePosixPath(name)
                if relative.is_absolute() or ".." in relative.parts:
                    raise ValueError(f"unsafe archive path: {name}")
                target = extracted.joinpath(*relative.parts)
                target.parent.mkdir(parents=True, exist_ok=True)
                content = bundle.read(name)
                target.write_bytes(content)
                if name not in GENERATED_GUIDES:
                    workspace = repo.joinpath(*relative.parts[1:])
                    payloads_checked += 1
                    if not workspace.is_file():
                        problems.append(f"{name}: workspace counterpart is missing")
                    elif content != workspace.read_bytes():
                        problems.append(f"{name}: archive content differs from workspace")
        documents = {}
        for path in package.rglob("*"):
            if path.suffix.lower() not in DOCUMENT_SUFFIXES or not path.is_file():
                continue
            text = path.read_text(encoding="utf-8")
            if path.suffix.lower() in {".html", ".htm"}:
                parser = HTMLLinks()
                parser.feed(text)
                documents[path] = parser.document
            elif path.suffix.lower() == ".css":
                documents[path] = Document(css_links(text))
            else:
                documents[path] = markdown_document(text)
        for path, document in documents.items():
            origin = published_path(path)
            seen = set()
            for link in document.links:
                raw = link.url.strip()
                if not raw or raw in {"#", "#/"} or raw.startswith("#:~:text="):
                    continue
                if re.fullmatch(r"#/\d+(?:/\d+)*", raw):
                    continue  # Reveal slide-number navigation, not element IDs.
                url = urlsplit(raw)
                if url.netloc or (url.scheme and url.scheme.lower() != "file"):
                    continue
                if raw in seen:
                    continue
                seen.add(raw)
                links_checked += 1
                label = f"{path.relative_to(package)}:{link.line}: {raw}"
                if url.scheme == "file" or url.path.startswith(("/", "\\")):
                    problems.append(f"{label}: absolute local URL is not portable")
                    continue
                target = (origin.parent / unquote(url.path)).resolve() if url.path else origin.resolve()
                if not target.is_relative_to(package):
                    problems.append(f"{label}: target leaves the extracted package")
                elif not target.is_file():
                    problems.append(f"{label}: target file is missing")
                elif url.fragment and target.suffix.lower() in {".html", ".htm", ".md", ".qmd"}:
                    fragment = unquote(url.fragment).lstrip("/")
                    if fragment.startswith(":~:text="):
                        continue
                    anchor_document = documents.get(target, Document())
                    rendered = published_path(target) if target.suffix == ".qmd" else target.with_suffix(".html")
                    if target.suffix in {".md", ".qmd"} and rendered in documents:
                        anchor_document = documents[rendered]
                    if fragment not in anchor_document.anchors:
                        problems.append(f"{label}: target anchor #{fragment} is missing")
    for problem in problems:
        print(f"FAIL {archive.name}: {problem}")
    status = "PASS" if not problems else "FAIL"
    print(f"{status} {archive.name}: {payloads_checked} workspace payloads, "
          f"{links_checked} local links/dependencies, {len(problems)} problems")
    return len(problems), links_checked


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archives", nargs="*", type=Path, help="ZIPs to inspect (default: W6 lab and student source)")
    parser.add_argument("--repo-root", type=Path, default=REPO, help="workspace root used for byte comparisons")
    args = parser.parse_args()
    failures = 0
    for archive in args.archives or DEFAULT_ARCHIVES:
        try:
            count, _ = inspect_archive(archive.resolve(), args.repo_root.resolve())
            failures += count
        except (OSError, BadZipFile, ValueError, UnicodeError) as error:
            print(f"FAIL {archive}: {error}")
            failures += 1
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
