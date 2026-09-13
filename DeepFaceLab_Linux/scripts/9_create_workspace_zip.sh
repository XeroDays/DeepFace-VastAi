#!/usr/bin/env bash
source env.sh

if ! command -v zip &> /dev/null; then
    echo "Installing zip utility..."
    apt-get update -qq && apt-get install -y -qq zip 2>/dev/null || true
fi

ZIP_FILE="workspace.zip"
rm -f "$ZIP_FILE"

echo "Creating $ZIP_FILE from $DFL_WORKSPACE..."

if command -v zip &> /dev/null; then
    zip -r -q "$ZIP_FILE" "$DFL_WORKSPACE"
else
    $DFL_PYTHON -c "import shutil; shutil.make_archive('workspace', 'zip', '.', 'workspace')"
fi

echo "Done! Archive saved at: $(pwd)/$ZIP_FILE"
