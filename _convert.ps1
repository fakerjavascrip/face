$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$names = @('热烈','霸气','沉稳','温柔','活泼','狂暴','威严')
$result = [ordered]@{}
$targetW = 400

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$encParams = New-Object System.Drawing.Imaging.EncoderParameters 1
$encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]78)

foreach ($name in $names) {
    $path = Resolve-Path "素材\$name.png"
    $img  = [System.Drawing.Image]::FromFile($path)
    $newW = $targetW
    $newH = [int]([math]::Round($img.Height * $newW / $img.Width))

    $bmp = New-Object System.Drawing.Bitmap $newW, $newH
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::White)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($img, 0, 0, $newW, $newH)

    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, $jpegCodec, $encParams)
    $bytes = $ms.ToArray()
    $b64   = [Convert]::ToBase64String($bytes)
    $result[$name] = $b64
    Write-Host ("{0}: {1}x{2}  {3} KB  -> base64 {4} KB" -f $name, $newW, $newH, [int]($bytes.Length/1024), [int]($b64.Length/1024))

    $ms.Dispose(); $g.Dispose(); $bmp.Dispose(); $img.Dispose()
}

$json = $result | ConvertTo-Json -Compress
[System.IO.File]::WriteAllText((Join-Path (Get-Location) '_images_b64.json'), $json, [System.Text.UTF8Encoding]::new($false))
Write-Host ("Wrote _images_b64.json  total: {0} KB" -f [int]((Get-Item '_images_b64.json').Length/1024))
