# patch_icons.ps1
# Run from project root. Creates .bak backups for modified files.
$files = Get-ChildItem -Path .\lib -Filter *.dart -Recurse

foreach ($f in $files) {
    $path = $f.FullName
    $text = Get-Content -Raw -Path $path

    $orig = $text

    # 1) Replace occurrences of "icon.codePoint.toString()" -> "icon.codePoint"
    $text = $text -replace 'icon\.codePoint\.toString\(\)', 'icon.codePoint'

    # 2) Replace "color.value.toString()" -> "color.value"
    $text = $text -replace 'color\.value\.toString\(\)', 'color.value'

    # 3) Replace occurrences of "category?.icon ?? <fallback>"
    $text = $text -replace 'category\?\.\s*icon\s*\?\?\s*', '(category != null) ? (kCategoryIconConstants[category.id] ?? IconData(category.iconCodePoint, fontFamily: ''MaterialIcons'')) : '

    # 4) Replace direct "category.icon"
    $text = $text -replace 'category\.icon\b', 'kCategoryIconConstants[category.id] ?? IconData(category.iconCodePoint, fontFamily: ''MaterialIcons'')'

    # 5) Replace raw IconData(category.iconCodePoint, ... )
    $text = $text -replace 'IconData\(\s*category\.iconCodePoint\s*,', 'kCategoryIconConstants[category.id] ?? IconData(category.iconCodePoint,'

    if ($text -ne $orig) {
        Copy-Item -Path $path -Destination "$path.bak" -Force
        Set-Content -Path $path -Value $text -Force
        Write-Host "Patched: $path"
    }
}

Write-Host "Done. Please review .bak files for changes. You can restore from .bak if needed."
