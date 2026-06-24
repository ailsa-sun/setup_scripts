#!/usr/bin/env bash
set -euo pipefail

# ─── Colors ───
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}→${NC} $1"; }
success() { echo -e "${GREEN}✔${NC} $1"; }
error()   { echo -e "${RED}✖${NC} $1" >&2; }

# ─── Usage ───
usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  -n <name>         Project/repo name (required)
  -d <description>  Short project description
  -l <license>      License type: mit, apache, gpl3, bsd2, none (default: mit)
  -g <gitignore>    Gitignore template: node, python, go, rust, java, c, none (default: none)
  -r <remote_url>   GitHub/GitLab remote URL to link
  -b <branch>       Default branch name (default: main)
  -p                Make repo private when creating on GitHub (requires gh CLI)
  --github          Create a GitHub repo automatically (requires gh CLI)
  -h                Show this help
EOF
    exit 1
}

# ─── Defaults ───
NAME=""
DESC=""
LICENSE="mit"
GITIGNORE="none"
REMOTE=""
BRANCH="main"
CREATE_GITHUB=false
GITHUB_PRIVATE=false

# ─── Parse args ───
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n) NAME="$2";        shift 2 ;;
        -d) DESC="$2";        shift 2 ;;
        -l) LICENSE="$2";     shift 2 ;;
        -g) GITIGNORE="$2";   shift 2 ;;
        -r) REMOTE="$2";      shift 2 ;;
        -b) BRANCH="$2";      shift 2 ;;
        -p) GITHUB_PRIVATE=true; shift ;;
        --github) CREATE_GITHUB=true; shift ;;
        -h) usage ;;
        *)  error "Unknown option: $1"; usage ;;
    esac
done

if [[ -z "$NAME" ]]; then
    error "Project name is required."
    usage
fi

PROJECT_DIR="$(pwd)/$NAME"

# ─── Guard ───
if [[ -d "$PROJECT_DIR" ]]; then
    error "Directory '$PROJECT_DIR' already exists."
    exit 1
fi

echo ""
echo -e "${BOLD}Setting up repository: $NAME${NC}"
echo "────────────────────────────────────────"

# ─── Create directory & init ───
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"
git init -b "$BRANCH" --quiet
success "Initialized git repo with branch '$BRANCH'"

# ─── README ───
cat > README.md <<EOF
# $NAME

${DESC:-A new project.}

## Getting Started

\`\`\`bash
git clone <remote-url>
cd $NAME
\`\`\`

## License

$(if [[ "$LICENSE" != "none" ]]; then echo "See [LICENSE](LICENSE) for details."; else echo "TBD"; fi)
EOF
success "Created README.md"

# ─── License ───
generate_license() {
    local year
    year=$(date +%Y)
    local author
    author=$(git config user.name 2>/dev/null || echo "Your Name")

    case "$1" in
        mit)
            cat <<LICEOF
MIT License

Copyright (c) $year $author

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
LICEOF
            ;;
        apache)
            cat <<LICEOF
Copyright $year $author

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
LICEOF
            ;;
        gpl3)
            cat <<LICEOF
Copyright (C) $year $author

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.
LICEOF
            ;;
        bsd2)
            cat <<LICEOF
Copyright $year $author

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
LICEOF
            ;;
        none) return ;;
        *) error "Unknown license: $1"; return ;;
    esac
}

if [[ "$LICENSE" != "none" ]]; then
    generate_license "$LICENSE" > LICENSE
    success "Created LICENSE ($LICENSE)"
fi

# ─── .gitignore ───
generate_gitignore() {
    # Common to all
    cat <<'GIEOF'
# ─── OS ───
.DS_Store
Thumbs.db
desktop.ini

# ─── Editors ───
.vscode/
.idea/
*.swp
*.swo
*~

# ─── Environment ───
.env
.env.local
.env.*.local
GIEOF

    case "$1" in
        node)
            cat <<'GIEOF'

# ─── Node ───
node_modules/
dist/
build/
coverage/
*.tgz
.npm
.eslintcache
.next/
.nuxt/
.cache/
package-lock.json.bak
GIEOF
            ;;
        python)
            cat <<'GIEOF'

# ─── Python ───
__pycache__/
*.py[cod]
*$py.class
*.egg-info/
dist/
build/
.eggs/
*.egg
venv/
.venv/
.tox/
.pytest_cache/
.mypy_cache/
htmlcov/
.coverage
GIEOF
            ;;
        go)
            cat <<'GIEOF'

# ─── Go ───
bin/
vendor/
*.exe
*.exe~
*.dll
*.so
*.dylib
*.test
*.out
go.work
GIEOF
            ;;
        rust)
            cat <<'GIEOF'

# ─── Rust ───
target/
Cargo.lock
**/*.rs.bk
GIEOF
            ;;
        java)
            cat <<'GIEOF'

# ─── Java ───
*.class
*.jar
*.war
*.ear
target/
.gradle/
build/
out/
.settings/
.classpath
.project
GIEOF
            ;;
        c)
            cat <<'GIEOF'

# ─── C/C++ ───
*.o
*.obj
*.so
*.dylib
*.dll
*.a
*.lib
*.exe
*.out
build/
cmake-build-*/
GIEOF
            ;;
        none) ;;
        *) error "Unknown gitignore template: $1" ;;
    esac
}

generate_gitignore "$GITIGNORE" > .gitignore
success "Created .gitignore ($GITIGNORE)"

# ─── CHANGELOG ───
cat > CHANGELOG.md <<EOF
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- Initial project setup
EOF
success "Created CHANGELOG.md"

# ─── EditorConfig ───
cat > .editorconfig <<'EOF'
root = true

[*]
indent_style = space
indent_size = 4
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.{yml,yaml,json,md}]
indent_size = 2

[Makefile]
indent_style = tab
EOF
success "Created .editorconfig"

# ─── Initial commit ───
git add -A
git commit -m "Initial commit: project scaffolding" --quiet
success "Created initial commit"

# ─── Remote ───
if [[ -n "$REMOTE" ]]; then
    git remote add origin "$REMOTE"
    success "Added remote origin: $REMOTE"
fi

# ─── GitHub repo creation ───
if [[ "$CREATE_GITHUB" == true ]]; then
    if ! command -v gh &>/dev/null; then
        error "GitHub CLI (gh) is not installed. Skipping GitHub repo creation."
        info  "Install it: https://cli.github.com"
    else
        info "Creating GitHub repository ..."
        GH_FLAGS="--source=. --push"
        [[ -n "$DESC" ]]               && GH_FLAGS+=" --description \"$DESC\""
        [[ "$GITHUB_PRIVATE" == true ]] && GH_FLAGS+=" --private" || GH_FLAGS+=" --public"

        eval gh repo create "$NAME" "$GH_FLAGS"
        success "GitHub repository created and pushed"
    fi
fi

# ─── Summary ───
echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  Repository '$NAME' is ready${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo ""
echo "  Location:    $PROJECT_DIR"
echo "  Branch:      $BRANCH"
echo "  License:     $LICENSE"
echo "  Gitignore:   $GITIGNORE"
[[ -n "$REMOTE" ]] && echo "  Remote:      $REMOTE"
echo ""
echo "  Files created:"
echo "    README.md"
echo "    CHANGELOG.md"
echo "    .gitignore"
echo "    .editorconfig"
[[ "$LICENSE" != "none" ]] && echo "    LICENSE"
echo ""
echo -e "  ${CYAN}cd $NAME${NC} to get started"
echo ""
