param([switch]$PosterOnly, [switch]$HandoutOnly)
$ErrorActionPreference = 'Stop'
$deliveryPath = Split-Path -Parent $PSScriptRoot

if (-not $HandoutOnly) {
    $ppt = New-Object -ComObject PowerPoint.Application
    $existingPptCount = $ppt.Presentations.Count
    $pres = $null
    try {
        $inputPpt = Join-Path $deliveryPath 'Gulo_3000_Poster.pptx'
        $outputPpt = Join-Path $deliveryPath 'Gulo_3000_Poster.pdf'
        $pres = $ppt.Presentations.Open($inputPpt, -1, 0, 0)
        $overflow = @()
        foreach ($shape in $pres.Slides.Item(1).Shapes) {
            if ($shape.HasTextFrame -and $shape.TextFrame.HasText) {
                $bound = $shape.TextFrame.TextRange.BoundHeight
                if ($bound -gt $shape.Height + 1) {
                    $overflow += [pscustomobject]@{Text=$shape.TextFrame.TextRange.Text; Height=$shape.Height; BoundHeight=$bound}
                }
            }
        }
        ConvertTo-Json -InputObject @($overflow) -Depth 3 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'poster_text_overflow.json')
        $pres.SaveAs($outputPpt, 32)
        Write-Output "Poster exported; overflowing text boxes: $($overflow.Count)"
    } finally {
        if ($null -ne $pres) { $pres.Close(); [void][Runtime.InteropServices.Marshal]::ReleaseComObject($pres) }
        if ($existingPptCount -eq 0) { $ppt.Quit() }
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($ppt)
    }
}

if (-not $PosterOnly) {
    # Use deterministic three-page layout; Word PDF export stalled on this host.
    $taskPython = 'C:\Program Files\FreeCAD 1.1\bin\python.exe'
    & $taskPython (Join-Path $PSScriptRoot 'build_handout_pdf.py')
    if ($LASTEXITCODE -ne 0) { throw 'Handout PDF build failed.' }
}
