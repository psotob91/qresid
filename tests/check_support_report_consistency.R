root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (basename(root) != "qresid" && dir.exists(file.path(root, "qresid"))) {
  root <- normalizePath(file.path(root, "qresid"), winslash = "/", mustWork = TRUE)
}

required <- c(
  "README.md",
  "qresid.ado",
  "qresid.sthlp",
  "qresid.pkg",
  "stata.toc",
  "docs/README.md",
  "docs/reference.md",
  "docs/supported-specifications.md",
  "docs/validation.md",
  "changelog/CHANGELOG.md"
)

missing <- required[!file.exists(file.path(root, required))]

git_files <- tryCatch(
  system2("git", c("-C", root, "ls-files"), stdout = TRUE, stderr = TRUE),
  error = function(e) character()
)
git_files <- git_files[nzchar(git_files)]
git_files <- git_files[file.exists(file.path(root, git_files))]

read_text <- function(path) {
  paste(readLines(file.path(root, path), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

text_files <- git_files[!grepl("\\.(png|zip)$", git_files, ignore.case = TRUE)]
text <- vapply(text_files, read_text, character(1))

forbidden <- c(paste0("pro", "mpt"), paste0("Co", "dex"),
               paste0("Chat", "GPT"), paste0("reason", "ing"),
               paste0("conver", "sation"))
hits <- lapply(forbidden, function(term) {
  names(text)[grepl(tolower(term), tolower(text), fixed = TRUE)]
})
names(hits) <- forbidden
bad <- hits[lengths(hits) > 0]

pkg <- readLines(file.path(root, "qresid.pkg"), warn = FALSE)
pkg_files <- trimws(sub("^[Ff]\\s+", "", grep("^[Ff]\\s+", pkg, value = TRUE)))
pkg_ok <- identical(pkg_files, c("qresid.ado", "qresid.sthlp"))

extract_links <- function(path) {
  body <- read_text(path)
  matches <- gregexpr("\\[[^]]+\\]\\(([^)]+)\\)", body, perl = TRUE)
  links <- regmatches(body, matches)[[1]]
  if (!length(links)) return(character())
  sub("^\\[[^]]+\\]\\(([^)]+)\\)$", "\\1", links)
}

md_files <- git_files[grepl("\\.md$", git_files, ignore.case = TRUE)]
missing_links <- character()
for (md in md_files) {
  links <- extract_links(md)
  links <- links[!grepl("^(https?://|mailto:|#)", links)]
  links <- sub("#.*$", "", links)
  links <- links[nzchar(links)]
  for (link in links) {
    target <- normalizePath(file.path(dirname(file.path(root, md)), link),
                            winslash = "/", mustWork = FALSE)
    if (!file.exists(target)) {
      missing_links <- c(missing_links, paste0(md, " -> ", link))
    }
  }
}

if (length(missing) || length(bad) || !pkg_ok || length(missing_links)) {
  cat("QRESID_SUPPORT_REPORT_CONSISTENCY_STATUS FAIL\n")
  if (length(missing)) {
    cat("Missing public file(s):", paste(missing, collapse = ", "), "\n")
  }
  if (length(bad)) {
    for (term in names(bad)) {
      cat("Forbidden term", shQuote(term), "in:", paste(bad[[term]], collapse = ", "), "\n")
    }
  }
  if (!pkg_ok) {
    cat("qresid.pkg must list only qresid.ado and qresid.sthlp\n")
  }
  if (length(missing_links)) {
    cat("Missing Markdown link target(s):", paste(missing_links, collapse = "; "), "\n")
  }
  quit(status = 1)
}

cat("QRESID_SUPPORT_REPORT_CONSISTENCY_STATUS PASS\n")
