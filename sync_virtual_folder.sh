#!/bin/bash

# Find all .ipynb files in the working directory (null-delimited to handle spaces)
mapfile -d '' notebooks < <(find . -maxdepth 1 -name "*.ipynb" -printf "%f\0" | sort -z)

if [ ${#notebooks[@]} -eq 0 ]; then
    echo "No Jupyter notebooks found in the current directory."
    exit 1
fi

# Display numbered list
echo "Select a notebook to overwrite from .virtual_documents:"
echo "---"
for i in "${!notebooks[@]}"; do
    echo "  [$((i+1))] ${notebooks[$i]}"
done
echo "---"

# Prompt for selection
read -p "Enter number (1-${#notebooks[@]}): " choice

# Validate input
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#notebooks[@]} ]; then
    echo "Invalid selection."
    exit 1
fi

selected="${notebooks[$((choice-1))]}"
src=".virtual_documents/${selected}"
dst="./${selected}"

# Check the source exists
if [ ! -f "$src" ]; then
    echo "Source file not found: $src"
    exit 1
fi

# Confirm before overwriting
read -p "Copy '$src' → '$dst'? This will overwrite the existing file. [y/N] " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    # If it's already valid JSON, just copy it directly
    if python3 -c "import json, sys; json.load(open(sys.argv[1]))" "$src" 2>/dev/null; then
        cp -- "$src" "$dst"
    else
        # Try each py format until one works
        converted=false
        for fmt in py:light py:percent py:hydrogen py:sphinx; do
    		jupytext --from "$fmt" --to notebook "$src" --output "$dst" 2>/dev/null
    		if python3 -c "import json, sys; json.load(open(sys.argv[1]))" "$dst" 2>/dev/null; then
        		converted=true
        		break
    		fi
	done        
	if [ "$converted" = false ]; then
            echo "Error: could not convert '$src' — unrecognized format."
            exit 1
        fi
    fi
    echo "Done: '$selected' synced successfully."
else
    echo "Aborted."
fi
