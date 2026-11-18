# ==================================================================
#  SamuSignal VPS Helper v1.05  -  Ankush New Vision
# ------------------------------------------------------------------
#  KAAM (har 2 min, Task Scheduler se, chhupa hua):
#   1. GitHub (main branch) pe naya commit? -> copytrade-ea ki .mq5
#      files VPS ke har MT5 terminal ke MQL5\Experts me daalta hai.
#   2. Har terminal ki MetaEditor se compile karta hai, errors padhta hai.
#      .ex5 (bina source wale EA) seedha copy hote hain - compile nahi.
#   3. Report (compile result, terminal ka login, Experts log ki aakhri
#      lines, VPS ki RAM) likhta hai:
#        <Common>\Files\SamuCopy\vps.json
#      Bridge EA (v1.02+) ise app tak bhejta hai -> COPY tab "VPS Helper".
#   4. Khud ka naya version bhi GitHub se le leta hai.
#
#  Ye kabhi trade NAHI karta, chart pe EA NAHI lagata/hatata, MT5
#  restart NAHI karta. Naya EA chart pe lagana aapka kaam hai.
#
#  Hatana ho to PowerShell me:
#    Unregister-ScheduledTask -TaskName SamuVpsHelper -Confirm:$false
#
#  CHANGELOG
#   v1.05 (18-Nov-2026) TOKEN HEAL (Investor Account Watcher ka 401):
#                       VPS ke sab MT5 terminal (chart profile .chr, presets
#                       .set, MQL5\Files, Common\Files) me GitHub token
#                       dhoondhta hai, har ek ko GitHub se jaanchta hai, jo
#                       INVESTOR-ID me likh sakta hai (push) wahi token har
#                       terminal ke MQL5\Files\investor_token.txt aur
#                       Common\Files\IW_gh_token.txt me rakhta hai (sirf
#                       jahan kharab / khaali ho). Watcher 60 sec me khud
#                       utha leta hai - phone se paste ki zarurat nahi.
#                       Token kabhi log / report me nahi. Har 10 min.
#   v1.04 (17-Nov-2026) SCANNER REPAIR: 16 Nov raat VPS ki C: disk bhar gayi
#                       thi, scanner apna naya version likhte waqt
#                       C:\SamuScanner\scanner.mjs 0 byte ho gayi -> AI AUTO ko
#                       signal band. Ab har run me jaanch: scanner.mjs (ya
#                       engine\*.js) khaali / adhoori ho to GitHub se sahi
#                       file laakar rakhta hai (disk me 50 MB se kam ho to nahi).
#   v1.03 (12-Nov-2026) .ex5 files bhi (vps-ea / copytrade-ea me rakhi .ex5
#                       seedha har terminal ke MQL5\Experts me copy, compile
#                       nahi). Naya helper version aate hi ek baar poora
#                       deploy dobara jaanchta hai (warna usi commit ki .ex5
#                       chhoot jaati).
#   v1.02 (01-Oct-2026) vps-ea folder bhi (FXBridgeEA wagairah).
#   v1.01 (30-Sep-2026) FIX: vps.json 32 MB ban rahi thi - Windows PowerShell 5
#                       Get-Content ki lines ke saath chhupi PSProvider/PSDrive
#                       details bhi JSON me likh deta hai. Ab sirf saada text.
#                       Report 200 KB se badi ho to logs chhote karke likhta hai.
#   v1.00 (30-Sep-2026) Pehla build.
# ==================================================================

$HelperVer     = '1.05'
$Repo          = 'ankushchhajed7-cmd/samusignal'
$Branch        = 'main'
$DeployFolders = @('copytrade-ea', 'vps-ea') # repo ke in folders ki .mq5 / .ex5 VPS pe jaayengi
$SelfRepoPath  = 'vps-helper/SamuVpsHelper.ps1'
$LogTail       = 12                         # har terminal ke Experts log ki kitni lines

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Headers = @{ 'User-Agent' = 'SamuVpsHelper' }

$Base    = Split-Path -Parent $MyInvocation.MyCommand.Path
$StateF  = Join-Path $Base 'state.json'
$LogF    = Join-Path $Base 'helper.log'
$SrcDir  = Join-Path $Base 'src'
$TermRoot = Join-Path $env:APPDATA 'MetaQuotes\Terminal'
$Common  = Join-Path $TermRoot 'Common\Files\SamuCopy'
$OutF    = Join-Path $Common 'vps.json'

# ek saath do copy na chalein
$mtx = New-Object System.Threading.Mutex($false, 'Local\SamuVpsHelper')
if (-not $mtx.WaitOne(0)) { exit }

$script:RunLog = New-Object System.Collections.ArrayList
function Log([string]$m) {
    $line = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ' ' + $m
    try { Add-Content -Path $LogF -Value $line -Encoding UTF8 } catch {}
    [void]$script:RunLog.Add($line)
    Write-Host $line
}

# ---------- text files (MT5 ke log UTF-16 hote hain) ----------
function Read-Text([string]$path, [int]$lastBytes = 0) {
    if (-not (Test-Path -LiteralPath $path)) { return '' }
    $fs = New-Object System.IO.FileStream($path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]'ReadWrite, Delete')
    try {
        $len = $fs.Length
        $start = 0
        if ($lastBytes -gt 0 -and $len -gt $lastBytes) { $start = $len - $lastBytes; if ($start % 2 -ne 0) { $start++ } }
        $head = New-Object byte[] 2
        [void]$fs.Read($head, 0, 2)
        $uni = ($head[0] -eq 0xFF -and $head[1] -eq 0xFE) -or ($len -gt 1 -and $head[1] -eq 0)
        [void]$fs.Seek($start, [IO.SeekOrigin]::Begin)
        $n = [int]($len - $start)
        $buf = New-Object byte[] $n
        $got = 0
        while ($got -lt $n) { $r = $fs.Read($buf, $got, $n - $got); if ($r -le 0) { break }; $got += $r }
        if ($uni) { $t = [Text.Encoding]::Unicode.GetString($buf, 0, $got) } else { $t = [Text.Encoding]::UTF8.GetString($buf, 0, $got) }
        return $t.TrimStart([char]0xFEFF)
    } finally { $fs.Close() }
}

function Load-State {
    $h = @{}
    if (Test-Path -LiteralPath $StateF) {
        try {
            $o = (Get-Content -LiteralPath $StateF -Raw -Encoding UTF8) | ConvertFrom-Json
            foreach ($p in $o.PSObject.Properties) { $h[$p.Name] = $p.Value }
        } catch { }
    }
    return $h
}
function Save-State($h) {
    $json = $h | ConvertTo-Json -Depth 6 -Compress
    [IO.File]::WriteAllText($StateF, $json, (New-Object Text.UTF8Encoding($false)))
}

function Enc-Path([string]$p) { ($p -split '/' | ForEach-Object { [Uri]::EscapeDataString($_) }) -join '/' }

# ---------- MT5 terminals ----------
function Get-Terminals {
    $list = @()
    if (-not (Test-Path -LiteralPath $TermRoot)) { return $list }
    $procs = @()
    try { $procs = @(Get-Process terminal64 -ErrorAction SilentlyContinue | ForEach-Object { try { $_.Path } catch { '' } }) } catch {}
    foreach ($d in (Get-ChildItem -LiteralPath $TermRoot -Directory)) {
        if ($d.Name -notmatch '^[0-9A-Fa-f]{32}$') { continue }
        if (-not (Test-Path -LiteralPath (Join-Path $d.FullName 'MQL5\Experts'))) { continue }
        $inst = (Read-Text (Join-Path $d.FullName 'origin.txt')).Trim()
        $ed = ''
        if ($inst) { $ed = Join-Path $inst 'metaeditor64.exe' }
        $ini = Read-Text (Join-Path $d.FullName 'config\common.ini')
        $login = ''; $server = ''
        if ($ini -match '(?m)^\s*Login\s*=\s*(\d+)') { $login = $matches[1] }
        if ($ini -match '(?m)^\s*Server\s*=\s*(.+?)\s*$') { $server = $matches[1] }
        $run = $false
        if ($inst) { foreach ($pp in $procs) { if ($pp -and $pp.StartsWith($inst, [StringComparison]::OrdinalIgnoreCase)) { $run = $true } } }
        $name = if ($inst) { Split-Path $inst -Leaf } else { $d.Name.Substring(0, 8) }
        $list += [pscustomobject]@{ Id = $d.Name.Substring(0, 8); Dir = $d.FullName; Inst = $inst; Editor = $ed; Name = $name; Login = $login; Server = $server; Run = $run }
    }
    return $list
}

# ---------- compile ----------
function Compile-File($t, [string]$dst) {
    $res = [ordered]@{ ok = $false; ne = 0; nw = 0; at = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds(); msg = @() }
    if (-not $t.Editor -or -not (Test-Path -LiteralPath $t.Editor)) { $res.ne = 1; $res.msg = @('metaeditor64.exe nahi mila: ' + $t.Inst); return $res }
    $log = Join-Path $Base 'compile.log'
    if (Test-Path -LiteralPath $log) { Remove-Item -LiteralPath $log -Force }
    $ex5 = [IO.Path]::ChangeExtension($dst, '.ex5')
    $before = [datetime]::MinValue
    if (Test-Path -LiteralPath $ex5) { $before = (Get-Item -LiteralPath $ex5).LastWriteTimeUtc }
    $inc = Join-Path $t.Dir 'MQL5'
    $argsList = @('/compile:"' + $dst + '"', '/log:"' + $log + '"', '/inc:"' + $inc + '"')
    $p = Start-Process -FilePath $t.Editor -ArgumentList $argsList -PassThru -WindowStyle Hidden
    if (-not $p.WaitForExit(180000)) { try { $p.Kill() } catch {}; $res.ne = 1; $res.msg = @('Compile 3 min me pura nahi hua'); return $res }
    Start-Sleep -Milliseconds 300
    $lines = @((Read-Text $log) -split "`r?`n" | Where-Object { $_.Trim() -ne '' })
    $errs  = @($lines | Where-Object { $_ -match '\berror\b' -and $_ -notmatch '^\s*result' -and $_ -notmatch '\b0 error' })
    $warns = @($lines | Where-Object { $_ -match '\bwarning\b' -and $_ -notmatch '^\s*result' })
    $ne = $errs.Count; $nw = $warns.Count
    $rl = @($lines | Where-Object { $_ -match 'result' }) | Select-Object -Last 1
    if ($rl -and $rl -match '(\d+)\s+error') { $ne = [int]$matches[1] }
    if ($rl -and $rl -match '(\d+)\s+warning') { $nw = [int]$matches[1] }
    $after = [datetime]::MinValue
    if (Test-Path -LiteralPath $ex5) { $after = (Get-Item -LiteralPath $ex5).LastWriteTimeUtc }
    $res.ne = $ne; $res.nw = $nw
    $res.ok = ($ne -eq 0 -and $after -gt $before)
    if (-not $res.ok -and $ne -eq 0) { $res.ne = 1; $errs = @('ex5 nahi bani') + $lines }
    $clean = @($errs | Select-Object -First 8 | ForEach-Object {
        $s = $_ -replace '^.*?\\([^\\]+\.mq[5h])', '$1'    # lamba path hatao (sirf file ka naam)
        if ($s.Length -gt 220) { $s = $s.Substring(0, 220) }
        $s })
    $res.msg = $clean
    return $res
}

# ---------- v1.04: VPS scanner repair ----------
$ScanDir   = 'C:\SamuScanner'
$ScanRaw   = 'https://raw.githubusercontent.com/ankushchhajed7-cmd/samusignal/main/vps-scanner/scanner.mjs'
$ScanPages = 'https://ankushchhajed7-cmd.github.io/SAMUSIGNAL-AI/src/'
$ScanEng   = @('symbols.js', 'data.js', 'engine.js', 'ai.js', 'candlerules.js')
function Test-GoodFile([string]$f, [int]$minLen, [string[]]$must) {
    if (-not (Test-Path -LiteralPath $f)) { return $false }
    if ((Get-Item -LiteralPath $f).Length -lt $minLen) { return $false }
    $t = [IO.File]::ReadAllText($f)
    foreach ($m in $must) { if ($t.IndexOf($m) -lt 0) { return $false } }
    return $true
}
function Fix-File([string]$url, [string]$dst, [int]$minLen, [string[]]$must) {
    $tmp = $dst + '.fix'
    try {
        Invoke-WebRequest -Uri $url -OutFile $tmp -Headers $Headers -UseBasicParsing
        if (Test-GoodFile $tmp $minLen $must) {
            Move-Item -LiteralPath $tmp -Destination $dst -Force
            Log ('Scanner repair: ' + (Split-Path $dst -Leaf) + ' GitHub se dobara rakhi')
            return $true
        }
        Log ('Scanner repair: ' + (Split-Path $dst -Leaf) + ' download theek nahi aaya')
    } catch { Log ('Scanner repair ERROR: ' + (Split-Path $dst -Leaf) + ' - ' + $_.Exception.Message) }
    Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    return $false
}
function Repair-Scanner {
    if (-not (Test-Path -LiteralPath $ScanDir)) { return }
    try {
        $drv = Get-PSDrive -Name $ScanDir.Substring(0, 1) -ErrorAction SilentlyContinue
        if ($drv -and $drv.Free -lt 50MB) { Log 'Scanner repair: disk me 50 MB se kam jagah - pehle jagah khaali karo'; return }
    } catch {}
    $sf = Join-Path $ScanDir 'scanner.mjs'
    if (-not (Test-GoodFile $sf 10000 @('VPS Scanner v', 'Promise.all([pMain'))) {
        Log 'Scanner repair: scanner.mjs khaali / adhoori mili'
        [void](Fix-File $ScanRaw $sf 10000 @('VPS Scanner v', 'Promise.all([pMain'))
    }
    $ed = Join-Path $ScanDir 'engine'
    if (Test-Path -LiteralPath $ed) {
        foreach ($e in $ScanEng) {
            $ef = Join-Path $ed $e
            if (-not (Test-GoodFile $ef 300 @('export '))) {
                Log ('Scanner repair: engine\' + $e + ' khaali / adhoori mili')
                [void](Fix-File ($ScanPages + $e) $ef 300 @('export '))
            }
        }
    }
}


# ---------- v1.05 TOKEN HEAL (Investor Account Watcher) ----------
$HealRepo  = 'ankushchhajed7-cmd/INVESTOR-ID'
$HealFile  = 'investor_token.txt'
$HealCommon = Join-Path $TermRoot 'Common\Files\IW_gh_token.txt'
function Test-GhToken([string]$tok) {
    # 2 = likh sakta hai (push), 1 = sirf padh sakta, 0 = kharab / 401
    try {
        $h = @{ 'User-Agent' = 'SamuVpsHelper'; 'Accept' = 'application/vnd.github+json'; 'Authorization' = ('Bearer ' + $tok) }
        $r = Invoke-RestMethod -Uri ("https://api.github.com/repos/$HealRepo") -Headers $h -UseBasicParsing -TimeoutSec 15
        if ($r.permissions -and $r.permissions.push) { return 2 }
        return 1
    } catch { return 0 }
}
function Get-TokCandidates([string]$text) {
    $out = @()
    if (-not $text) { return $out }
    foreach ($m in [regex]::Matches($text, 'github_pat_[A-Za-z0-9_]{60,}')) { $out += $m.Value }
    foreach ($m in [regex]::Matches($text, '(?<![A-Za-z0-9_])ghp_[A-Za-z0-9]{36}(?![A-Za-z0-9])')) { $out += $m.Value }
    return $out
}
function Write-TokFile([string]$path, [string]$tok) {
    $dir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [IO.File]::WriteAllText($path, $tok, (New-Object Text.ASCIIEncoding))
}
function Heal-Tokens($terms) {
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    if ($state['healAt'] -and ($now - [long]$state['healAt']) -lt 600) { return }
    $state['healAt'] = $now
    # 1. sab jagah se token ikattha (kahan mila - sirf ginti log hogi)
    $cands = New-Object System.Collections.ArrayList
    $files = @()
    if (Test-Path -LiteralPath $HealCommon) { $files += $HealCommon }
    foreach ($t in $terms) {
        foreach ($sub in @('MQL5\Profiles', 'MQL5\Presets', 'MQL5\Files')) {
            $d = Join-Path $t.Dir $sub
            if (-not (Test-Path -LiteralPath $d)) { continue }
            $files += @(Get-ChildItem -LiteralPath $d -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { ($_.Extension -in @('.chr', '.set', '.txt', '.tpl')) -and $_.Length -lt 2MB } | ForEach-Object { $_.FullName })
        }
    }
    foreach ($f in $files) {
        try { foreach ($c in (Get-TokCandidates (Read-Text $f))) { if (-not $cands.Contains($c)) { [void]$cands.Add($c) } } } catch {}
    }
    if ($cands.Count -eq 0) { Log 'Token heal: VPS par koi GitHub token nahi mila'; return }
    # 2. jaancho - pehle wo jo abhi Common me hai
    $good = ''
    $nBad = 0
    foreach ($c in @($cands | Select-Object -First 25)) {
        $r = Test-GhToken $c
        if ($r -eq 2) { $good = $c; break } else { $nBad++ }
    }
    if (-not $good) { Log ('Token heal: ' + $cands.Count + ' token mile, koi bhi INVESTOR-ID me likh nahi sakta (sab 401 / sirf padhne wale)'); $state['heal'] = 'koi sahi token nahi'; return }
    # 3. jahan kharab / khaali ho wahan sahi token rakho
    $fixed = @()
    $cur = ''
    if (Test-Path -LiteralPath $HealCommon) { $cur = (Read-Text $HealCommon).Trim() }
    if ($cur -ne $good) { try { Write-TokFile $HealCommon $good; $fixed += 'Common' } catch { Log ('Token heal: Common me likh nahi paya - ' + $_.Exception.Message) } }
    foreach ($t in $terms) {
        $tf = Join-Path $t.Dir ('MQL5\Files\' + $HealFile)
        $old = ''
        if (Test-Path -LiteralPath $tf) { $old = (Read-Text $tf).Trim() }
        if ($old -eq $good) { continue }
        # sirf un terminal me jahan Investor Watcher laga hai / file pehle se hai / login hai
        $hasWatcher = (Test-Path -LiteralPath $tf) -or (@(Get-ChildItem -LiteralPath (Join-Path $t.Dir 'MQL5\Profiles') -Recurse -Filter '*.chr' -ErrorAction SilentlyContinue |
            Where-Object { (Read-Text $_.FullName) -match 'Investor Account Watcher' }).Count -gt 0)
        if (-not $hasWatcher) { continue }
        if ($old -and (Test-GhToken $old) -eq 2) { continue }      # uska apna token bhi chalta hai - mat chhedo
        try { Write-TokFile $tf $good; $fixed += ($t.Name + '/' + $t.Login.Substring([Math]::Max(0, $t.Login.Length - 4))) } catch { Log ('Token heal: ' + $t.Name + ' me likh nahi paya - ' + $_.Exception.Message) }
    }
    $msg = 'Token heal: ' + $cands.Count + ' token mile, sahi token mila (' + $nBad + ' kharab chhode)'
    if ($fixed.Count -gt 0) { $msg += '; theek kiya: ' + ($fixed -join ', ') } else { $msg += '; sab jagah pehle se sahi' }
    Log $msg
    $state['heal'] = $msg
    # 4. GitHub par chhoti report (token nahi, sirf haal) - Claude dekh sake
    try {
        $body = [ordered]@{ at = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'); helper = $HelperVer; found = $cands.Count; bad = $nBad; fixed = @($fixed); msg = $msg } | ConvertTo-Json -Compress
        $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($body))
        $h = @{ 'User-Agent' = 'SamuVpsHelper'; 'Accept' = 'application/vnd.github+json'; 'Authorization' = ('Bearer ' + $good) }
        $url = "https://api.github.com/repos/$HealRepo/contents/data/_vps/heal.json"
        $sha = $null
        try { $sha = (Invoke-RestMethod -Uri $url -Headers $h -UseBasicParsing -TimeoutSec 15).sha } catch {}
        $put = [ordered]@{ message = 'vps token heal'; content = $b64; branch = 'main' }
        if ($sha) { $put.sha = $sha }
        Invoke-RestMethod -Method Put -Uri $url -Headers $h -Body ($put | ConvertTo-Json -Compress) -ContentType 'application/json' -UseBasicParsing -TimeoutSec 20 | Out-Null
    } catch {}
}

# ==================================================================
$state = Load-State
$ghErr = ''
$commit = ''
try {
    if (-not (Test-Path -LiteralPath $SrcDir)) { New-Item -ItemType Directory -Path $SrcDir -Force | Out-Null }
    if (-not (Test-Path -LiteralPath $Common)) { New-Item -ItemType Directory -Path $Common -Force | Out-Null }
    try {
        if ((Test-Path -LiteralPath $LogF) -and (Get-Item -LiteralPath $LogF).Length -gt 300KB) {
            $keep = Get-Content -LiteralPath $LogF -Tail 400
            Set-Content -LiteralPath $LogF -Value $keep -Encoding UTF8
        }
    } catch {}

    try { Repair-Scanner } catch { Log ('Scanner repair error: ' + $_.Exception.Message) }   # v1.04

    $terms = @(Get-Terminals)

    try { Heal-Tokens $terms; Save-State $state } catch { Log ('Token heal error: ' + $_.Exception.Message) }   # v1.05

    # ---- GitHub: naya commit? ----
    try {
        $h2 = @{ 'User-Agent' = 'SamuVpsHelper'; 'Accept' = 'application/vnd.github.sha' }
        $c = (Invoke-WebRequest -Uri ("https://api.github.com/repos/$Repo/commits/$Branch") -Headers $h2 -UseBasicParsing).Content
        if ($c -is [byte[]]) { $c = [Text.Encoding]::ASCII.GetString($c) }
        $commit = ([string]$c).Trim()
        if ($commit -notmatch '^[0-9a-f]{40}$') { $ghErr = 'GitHub ka jawab samajh nahi aaya'; $commit = '' }
    } catch { $ghErr = 'GitHub se jawab nahi: ' + $_.Exception.Message }

    $termSig = ($terms | ForEach-Object { $_.Id }) -join ','
    $folderSig = $DeployFolders -join ','
    $need = $commit -and (($state['commit'] -ne $commit) -or ($state['terms'] -ne $termSig) -or ($state['folders'] -ne $folderSig) -or ($state['hv'] -ne $HelperVer))

    if ($need) {
        $tree = Invoke-RestMethod -Uri ("https://api.github.com/repos/$Repo/git/trees/" + $commit + "?recursive=1") -Headers $Headers -UseBasicParsing
        $blobs = @($tree.tree | Where-Object { $_.type -eq 'blob' })

        # ---- khud ka naya version ----
        $self = $blobs | Where-Object { $_.path -eq $SelfRepoPath } | Select-Object -First 1
        if ($self -and $state['self'] -ne $self.sha) {
            $tmp = Join-Path $Base 'SamuVpsHelper.new'
            Invoke-WebRequest -Uri ("https://raw.githubusercontent.com/$Repo/$commit/" + (Enc-Path $self.path)) -OutFile $tmp -Headers $Headers -UseBasicParsing
            $txt = [IO.File]::ReadAllText($tmp)
            if ($txt -match 'SamuSignal VPS Helper' -and $txt.Length -gt 2000) {
                if ($state['self']) {
                    Copy-Item -LiteralPath $tmp -Destination (Join-Path $Base 'SamuVpsHelper.ps1') -Force
                    Log 'Helper ka naya version aaya - agli baar se chalega'
                }
                $state['self'] = $self.sha
            }
            Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        }

        # ---- EA files ----
        $files = @($blobs | Where-Object {
            $p = $_.path
            (($p -like '*.mq5') -or ($p -like '*.ex5')) -and (@($DeployFolders | Where-Object { $p -like ($_ + '/*') }).Count -gt 0) })
        $allOk = $true
        foreach ($f in $files) {
            $name = Split-Path $f.path -Leaf
            $cache = Join-Path $SrcDir $name
            if ($state['src|' + $f.path] -ne $f.sha -or -not (Test-Path -LiteralPath $cache)) {
                try {
                    $tmp = $cache + '.tmp'
                    Invoke-WebRequest -Uri ("https://raw.githubusercontent.com/$Repo/$commit/" + (Enc-Path $f.path)) -OutFile $tmp -Headers $Headers -UseBasicParsing
                    Move-Item -LiteralPath $tmp -Destination $cache -Force
                    $state['src|' + $f.path] = $f.sha
                    Log ('GitHub se aaya: ' + $name)
                } catch {
                    $allOk = $false
                    $ghErr = 'Download nahi hua: ' + $name + ' - ' + $_.Exception.Message
                    Log $ghErr
                    continue
                }
            }
            $isEx5 = $name -like '*.ex5'
            foreach ($t in $terms) {
                $key = 'cmp|' + $t.Id + '|' + $name
                if ($isEx5) {
                    # bina source wala EA: sirf copy, compile nahi
                    $dst = Join-Path $t.Dir ('MQL5\Experts\' + $name)
                    if ($state[$key] -eq $f.sha -and (Test-Path -LiteralPath $dst)) { continue }
                    try {
                        Copy-Item -LiteralPath $cache -Destination $dst -Force
                        $r = [ordered]@{ ok = $true; ne = 0; nw = 0; at = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds(); msg = @('ex5 copy hui (compile ki zarurat nahi)') }
                        $state[$key] = $f.sha
                        Log ('EX5 copy OK: ' + $name + ' -> ' + $t.Name)
                    } catch {
                        $r = [ordered]@{ ok = $false; ne = 1; nw = 0; at = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds(); msg = @('ex5 copy nahi hui: ' + $_.Exception.Message) }
                        Log ('EX5 copy ERROR: ' + $name + ' -> ' + $t.Name + ' - ' + $_.Exception.Message)
                    }
                    $state['res|' + $t.Id + '|' + $name] = $r
                    Save-State $state
                    continue
                }
                $dst = Join-Path $t.Dir ('MQL5\Experts\' + $name)
                $ex5 = [IO.Path]::ChangeExtension($dst, '.ex5')
                if ($state[$key] -eq $f.sha -and (Test-Path -LiteralPath $ex5)) { continue }
                if ($state[$key] -eq ('fail:' + $f.sha)) { continue }      # isi version ka error pehle hi bata diya
                try {
                    Copy-Item -LiteralPath $cache -Destination $dst -Force
                    $r = Compile-File $t $dst
                } catch {
                    $r = [ordered]@{ ok = $false; ne = 1; nw = 0; at = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds(); msg = @('Helper: ' + $_.Exception.Message) }
                }
                $state['res|' + $t.Id + '|' + $name] = $r
                if ($r.ok) {
                    $state[$key] = $f.sha
                    Log ('Compile OK: ' + $name + ' -> ' + $t.Name + ' (' + $r.nw + ' warning)')
                } else {
                    $state[$key] = 'fail:' + $f.sha
                    Log ('Compile ERROR: ' + $name + ' -> ' + $t.Name + ' (' + $r.ne + ' error)')
                }
                Save-State $state
            }
        }
        if ($allOk) { $state['commit'] = $commit }
        $state['terms'] = $termSig
        $state['folders'] = $folderSig
        if ($allOk) { $state['hv'] = $HelperVer }
        $state['files'] = @($files | ForEach-Object { Split-Path $_.path -Leaf })
        Save-State $state
    }
} catch {
    $ghErr = 'Helper error: ' + $_.Exception.Message
    Log $ghErr
}

# ---------- report ----------
try {
    $terms = @(Get-Terminals)
    $fileNames = @()
    if ($state['files']) { $fileNames = @($state['files']) }
    $today = Get-Date -Format 'yyyyMMdd'
    $tOut = @()
    foreach ($t in $terms) {
        $fl = @()
        foreach ($n in $fileNames) {
            $r = $state['res|' + $t.Id + '|' + $n]
            if ($null -eq $r) { continue }
            $fl += [ordered]@{ f = [string]$n; ok = [bool]$r.ok; ne = [int]$r.ne; nw = [int]$r.nw; at = [long]$r.at; msg = @($r.msg | ForEach-Object { '' + $_ }) }
        }
        $lg = @()
        $lf = Join-Path $t.Dir ('MQL5\Logs\' + $today + '.log')
        if (-not (Test-Path -LiteralPath $lf)) {
            $last = Get-ChildItem -LiteralPath (Join-Path $t.Dir 'MQL5\Logs') -Filter '*.log' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime | Select-Object -Last 1
            if ($last) { $lf = $last.FullName }
        }
        if (Test-Path -LiteralPath $lf) {
            $lg = @((Read-Text $lf 49152) -split "`r?`n" | Where-Object { $_.Trim() -ne '' } | Select-Object -Last $LogTail | ForEach-Object {
                $s = ($_ -replace '\t', ' ').Trim()
                if ($s.Length -gt 200) { $s = $s.Substring(0, 200) }
                $s })
        }
        $tOut += [ordered]@{ id = $t.Id; name = $t.Name; login = $t.Login; server = $t.Server; run = [bool]$t.Run; files = @($fl); log = @($lg) }
    }
    $mem = $null
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $mem = [ordered]@{ tot = [math]::Round($os.TotalVisibleMemorySize / 1024); free = [math]::Round($os.FreePhysicalMemory / 1024) }
    } catch {}
    $short = ''
    if ($state['commit']) { $short = ([string]$state['commit']).Substring(0, 7) }
    $rep = [ordered]@{
        v = $HelperVer
        at = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        host = $env:COMPUTERNAME
        commit = $short
        err = $ghErr
        mem = $mem
        terms = @($tOut)
        log = @(Get-Content -LiteralPath $LogF -Tail 15 -ErrorAction SilentlyContinue | ForEach-Object { '' + $_ })
    }
    $json = $rep | ConvertTo-Json -Depth 6 -Compress
    if ($json.Length -gt 200000) {                      # kabhi bhi badi na ho (Bridge har 2 sec padhta hai)
        foreach ($t in $tOut) { $t.log = @() }
        $rep.log = @('report badi thi - logs hataye')
        $json = $rep | ConvertTo-Json -Depth 6 -Compress
    }
    if ($json.Length -gt 200000) { $json = '{"v":"' + $HelperVer + '","at":' + $rep.at + ',"err":"report bahut badi - helper.log dekho"}' }
    $tmp = $OutF + '.tmp'
    [IO.File]::WriteAllText($tmp, $json, (New-Object Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $tmp -Destination $OutF -Force
} catch {
    try { Add-Content -Path $LogF -Value ((Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ' Report error: ' + $_.Exception.Message) } catch {}
}
$mtx.ReleaseMutex()
