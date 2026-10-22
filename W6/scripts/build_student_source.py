"""Bundle student slides, classroom materials and the lab with their relative paths."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import re

ROOT = Path(__file__).resolve().parents[2]
W6 = ROOT / "W6"
source = W6 / "slide/week6.qmd"
text = source.read_text()
assert not re.search(r"\{[^}]*\.notes\b", text), "Student source contains speaker notes"

paths = {
    source,
    W6 / "slide/week6.html",
    W6 / "slide/week6.pdf",
    W6 / "assets/week6.css",
    ROOT / "styles/text-preparation.css",
    ROOT / "image/ntu-logo.png",
    W6 / "downloads/week6-classroom.zip",
    W6 / "downloads/week6-lab.zip",
}
# Include the actual slide images, preserving their QMD-relative locations.
for relative in re.findall(r"!\[[^\]]*\]\(([^)]+)\)", text):
    if not relative.startswith(("https://", "http://", "data:")):
        paths.add((source.parent / relative).resolve())
paths.update(p for p in (W6 / "classroom").rglob("*")
             if p.is_file() and p.suffix in {".R", ".md", ".csv", ".json"})
# Reuse the lab ZIP's explicit student-facing manifest, including worked answers.
# Check freshness so a stale lab ZIP cannot silently enter the source bundle.
with ZipFile(W6 / "downloads/week6-lab.zip") as lab_archive:
    for name in lab_archive.namelist():
        relative = Path(name).relative_to("week6-lab")
        assert relative.parts[:2] == ("W6", "lab"), name
        assert ".." not in relative.parts, name
        path = ROOT / relative
        assert path.read_bytes() == lab_archive.read(name), f"Rebuild the lab ZIP: {relative}"
        paths.add(path)
assert all(path.is_file() for path in paths), "A source dependency is missing"
for path in paths:
    relative = path.relative_to(ROOT)
    assert not {"instructor", "archive", "papers", "analysis"}.intersection(relative.parts)
    assert "presenter" not in path.name

guide = """# Week 6: Human Coding and Document Classification

[Slides: HTML](W6/slide/week6.html) · [Slides: PDF](W6/slide/week6.pdf)

The source package contains the editable student QMD, slide images and styles,
rendered slides, classroom R code and data, and the complete take-home lab with
worked answers. Keep the folder structure intact. Links to earlier weeks open
the online course materials.

## Take-home lab

[Lab HTML](W6/lab/Lab_Session_W6.html) · [R script](W6/lab/Lab_Session_W6.R) ·
[Worked answers](W6/lab/answers/Lab_Session_W6_Answers.html) ·
[Lab ZIP](W6/downloads/week6-lab.zip) · [Instructions](W6/lab/README.md)

Open the handout and run `Lab_Session_W6.R` one section at a time in RStudio,
with the working directory set to `W6/lab/`. The lab's `Data/` folder is included;
no additional extraction or Quarto rendering is required.

## Classroom practice

Open R in `W6/classroom/`. Install the required packages once:

```r
install.packages(c("quanteda", "quanteda.textmodels", "mlr3", "mlr3learners",
                   "e1071", "stringi"), repos = "https://cloud.r-project.org")
```

Load the packages and check the SVM learner before the exercise:

```r
library(quanteda); library(quanteda.textmodels)
library(mlr3); library(mlr3learners)
library(e1071); library(stringi)
lrn("classif.svm")$id
```

The last line should return `"classif.svm"`. Run `W6_classification.R` one checkpoint
at a time in one R session, following C01–C08 and G01–G03, including their substeps.
Run `error_reading.R` after G03 in the same session. The `Data/` folder contains the
Wang, Day & Wu (2022) and Park (2021) data; `Data/README.md` explains the labels.

The standalone classroom ZIP is also included in `W6/downloads/`.

## Edit and compile the slides

Edit `W6/slide/week6.qmd`. With Quarto, R, and the R packages `knitr` and `rmarkdown`
installed, run this command from the extracted `week6-student-source` folder:

```sh
quarto render W6/slide/week6.qmd
```

Keep `styles/`, `image/`, and `W6/assets/` in their supplied locations. The slide
build displays the R examples without executing them. This command builds the
HTML; the supplied PDF is typeset separately.
"""

output = W6 / "downloads/week6-student-source.zip"
with ZipFile(output, "w", ZIP_DEFLATED) as archive:
    archive.writestr("week6-student-source/README.md", guide)
    for path in sorted(paths):
        archive.write(path, str(Path("week6-student-source") / path.relative_to(ROOT)))
print(f"Built {output}: {len(paths) + 1} files, {output.stat().st_size / 1024**2:.1f} MiB")
