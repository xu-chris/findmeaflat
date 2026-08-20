#!/bin/bash

# License compliance checker for Elixir dependencies
# Checks for potentially problematic licenses in mix dependencies

set -e

echo "📄 Checking dependency licenses..."

# Elixir-only: deps/ exists after `mix deps.get`. This repo is still Node, so the
# directory is absent until the Elixir rewrite lands. npm licences are covered by
# actions/dependency-review-action in security.yml (allow-licenses).
if [ ! -d deps ]; then
  echo "No deps/ directory - no Elixir project yet, nothing to check."
  {
    echo "# License Compliance Report"
    echo ""
    echo "Generated on: $(date)"
    echo ""
    echo "No \`deps/\` directory: this repository has no Elixir project yet."
    echo "npm dependency licences are enforced by \`dependency-review-action\` in security.yml."
  } > license_report.md
  exit 0
fi

# Create license report
REPORT_FILE="license_report.md"
echo "# License Compliance Report" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "Generated on: $(date)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "## Dependencies and their licenses:" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Define problematic licenses
PROBLEMATIC_LICENSES=(
  "GPL-3.0"
  "AGPL-3.0"
  "SSPL-1.0"
  "CPAL-1.0"
  "CC-BY-NC"
  "CC-BY-SA"
)

PROBLEMATIC_FOUND=false
DEPENDENCIES_CHECKED=0

# Check each dependency
for dep_dir in deps/*/; do
  if [ -d "$dep_dir" ]; then
    dep_name=$(basename "$dep_dir")
    license="Unknown"

    # Try to find license information in mix.exs
    if [ -f "$dep_dir/mix.exs" ]; then
      # Look for license field in mix.exs
      license=$(grep -i "license" "$dep_dir/mix.exs" | head -1 | sed 's/.*["\x27]\([^"'\'']*\)["\x27].*/\1/' 2>/dev/null || echo "Unknown")

      # If not found in mix.exs, check for LICENSE files
      if [ "$license" = "Unknown" ] || [ -z "$license" ]; then
        for license_file in "$dep_dir"LICENSE* "$dep_dir"license* "$dep_dir"License*; do
          if [ -f "$license_file" ]; then
            # Try to extract license type from common patterns
            if grep -qi "MIT" "$license_file"; then
              license="MIT"
              break
            elif grep -qi "Apache.*2" "$license_file"; then
              license="Apache-2.0"
              break
            elif grep -qi "BSD" "$license_file"; then
              license="BSD"
              break
            elif grep -qi "GPL.*3" "$license_file"; then
              license="GPL-3.0"
              break
            elif grep -qi "GPL.*2" "$license_file"; then
              license="GPL-2.0"
              break
            fi
          fi
        done
      fi
    fi

    # Clean up license string
    license=$(echo "$license" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | head -1)
    [ -z "$license" ] && license="Unknown"

    echo "- **$dep_name**: $license" >> "$REPORT_FILE"
    DEPENDENCIES_CHECKED=$((DEPENDENCIES_CHECKED + 1))

    # Check if license is problematic
    for problematic in "${PROBLEMATIC_LICENSES[@]}"; do
      if echo "$license" | grep -qi "$problematic"; then
        echo "⚠️ Potentially problematic license found: $dep_name ($license)"
        PROBLEMATIC_FOUND=true
        break
      fi
    done
  fi
done

echo "" >> "$REPORT_FILE"
echo "## Summary" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "- **Total dependencies checked**: $DEPENDENCIES_CHECKED" >> "$REPORT_FILE"
echo "- **Problematic licenses found**: $([ "$PROBLEMATIC_FOUND" = true ] && echo "Yes ⚠️" || echo "None ✅")" >> "$REPORT_FILE"

if [ "$PROBLEMATIC_FOUND" = true ]; then
  echo "" >> "$REPORT_FILE"
  echo "### ⚠️ Action Required" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "Some dependencies have potentially problematic licenses that may not be compatible with your project's license or commercial use." >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Problematic license types to review:**" >> "$REPORT_FILE"
  for license in "${PROBLEMATIC_LICENSES[@]}"; do
    echo "- $license" >> "$REPORT_FILE"
  done
fi

echo "📊 License report generated: $REPORT_FILE"
echo "📋 Dependencies checked: $DEPENDENCIES_CHECKED"

if [ "$PROBLEMATIC_FOUND" = true ]; then
  echo "⚠️ Found potentially problematic licenses - please review!"
  exit 1
else
  echo "✅ No problematic licenses found"
  exit 0
fi
