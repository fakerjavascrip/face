$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.Drawing

$root = $PSScriptRoot
if ([string]::IsNullOrEmpty($root)) { $root = (Get-Location).Path }
Set-Location $root

$srcHtml = Join-Path $root 'emotions.html'
$dstHtml = Join-Path $root 'emotions_embedded.html'

if (-not (Test-Path $srcHtml)) {
    Write-Host "❌ 找不到 emotions.html" -ForegroundColor Red
    exit 1
}
$materialDir = Join-Path $root '素材'
if (-not (Test-Path $materialDir)) {
    Write-Host "❌ 找不到 素材 文件夹" -ForegroundColor Red
    exit 1
}

$names    = @('热烈','霸气','沉稳','温柔','活泼','狂暴','威严')
$targetW  = 400
$quality  = 78

Write-Host "读取 emotions.html ..." -ForegroundColor Cyan
$html = [System.IO.File]::ReadAllText($srcHtml, [System.Text.UTF8Encoding]::new($false))
$originalSize = $html.Length

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$encParams = New-Object System.Drawing.Imaging.EncoderParameters 1
$encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$quality)

$replaced = 0
foreach ($name in $names) {
    $path = Join-Path $materialDir ("$name.png")
    if (-not (Test-Path $path)) {
        Write-Host ("  ⚠️ 缺少 {0}.png，跳过" -f $name) -ForegroundColor Yellow
        continue
    }
    Write-Host ("  处理 {0} ..." -f $name) -ForegroundColor Cyan -NoNewline

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
    $dataUrl = 'data:image/jpeg;base64,' + $b64

    $ms.Dispose(); $g.Dispose(); $bmp.Dispose(); $img.Dispose()

    # 在 emotions.html 源代码里替换 file:"X.png" → file:"<dataUrl>"
    $needle  = 'file:"' + $name + '.png"'
    $replacement = 'file:"' + $dataUrl + '"'

    if ($html.Contains($needle)) {
        $html = $html.Replace($needle, $replacement)
        $replaced++
        Write-Host (" done [{0} KB JPEG → {1} KB base64]" -f ([int]($bytes.Length/1024)), ([int]($b64.Length/1024))) -ForegroundColor Green
    } else {
        Write-Host (" ⚠️ 在 HTML 里未找到 {0}" -f $needle) -ForegroundColor Yellow
    }
}

# 改一下加载提示
$html = $html.Replace('第一次进入需读取 7 张脸谱图。', '已内联 7 张脸谱图，可在任意浏览器直接打开。')
# 让嵌入版默认隐藏导出按钮
$html = $html.Replace('id="exportBtn" style="margin-left:6px;display:none;"', 'id="exportBtn" style="margin-left:6px;display:none;" data-embedded="1"')

[System.IO.File]::WriteAllText($dstHtml, $html, [System.Text.UTF8Encoding]::new($false))

$finalKB = [int]((Get-Item $dstHtml).Length / 1024)
Write-Host ""
Write-Host ("✅ 已生成: {0}" -f $dstHtml) -ForegroundColor Green
Write-Host ("   替换了 {0}/{1} 张脸谱  最终大小 {2} KB" -f $replaced, $names.Count, $finalKB) -ForegroundColor Green
Write-Host ""
Write-Host "用法: 双击 emotions_embedded.html 即可在 Chrome 中使用，无需 素材 文件夹。" -ForegroundColor White
