#!/bin/bash

outer_archive="$1"
inner_archive="$2"
file_to_remove="$3"

# Decompress the outer archive
gzip -d "$outer_archive"
outer_tar="${outer_archive%.gz}"

# Extract the inner archive
tar -xf "$outer_tar" "$inner_archive"

# Decompress the inner archive
gzip -d "$inner_archive"
inner_tar="${inner_archive%.gz}"

# Remove the file from the inner archive
tar --delete -f "$inner_tar" --wildcards "*${file_to_remove}"

# Compress the inner archive and update the outer archive
gzip "$inner_tar"
tar --delete -f "$outer_tar" "${inner_archive}"
tar -uf "$outer_tar" "${inner_tar}.gz"

# Compress the outer archive and remove the extracted inner archive
gzip "$outer_tar"
rm "${inner_tar}.gz"

# end
