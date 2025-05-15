#!/bin/bash

# Loop through all mp3 files in the current directory
for file in *.mp3; do
  # Extract filename without extension
  filename="${file%.mp3}"

  # Remove track number and leading space using sed or cut
  title=$(echo "$filename" | sed 's/^[0-9]\+\s*//')

  # Set the ID3 title tag
  id3tag -s "$title" "$file"

  echo "Updated title for '$file' -> '$title'"
done
