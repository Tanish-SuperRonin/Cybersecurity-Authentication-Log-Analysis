param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$OutputPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'Cybersecurity_Authentication_Log_Analysis_Report.docx')
)

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Escape-Xml([string]$Text) { return [System.Security.SecurityElement]::Escape($Text) }
function P([string]$Text, [string]$Style = 'Normal', [switch]$PageBreak, [switch]$Center, [switch]$Bold) {
    $align = if ($Center) { '<w:jc w:val="center"/>' } else { '' }
    $br = if ($PageBreak) { '<w:br w:type="page"/>' } else { '' }
    $b = if ($Bold) { '<w:b/>' } else { '' }
    return "<w:p><w:pPr><w:pStyle w:val=`"$Style`"/>$align</w:pPr><w:r><w:rPr>$b</w:rPr>$br<w:t xml:space=`"preserve`">$(Escape-Xml $Text)</w:t></w:r></w:p>"
}
function Bullet([string]$Text) { return "<w:p><w:pPr><w:ind w:left=`"720`" w:hanging=`"360`"/></w:pPr><w:r><w:t>- </w:t></w:r><w:r><w:t xml:space=`"preserve`">$(Escape-Xml $Text)</w:t></w:r></w:p>" }
function Code([string]$Text) {
    $escaped = Escape-Xml $Text
    return "<w:p><w:pPr><w:spacing w:before=`"0`" w:after=`"0`"/><w:shd w:fill=`"F2F2F2`"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii=`"Consolas`" w:hAnsi=`"Consolas`"/><w:sz w:val=`"16`"/></w:rPr><w:t xml:space=`"preserve`">$escaped</w:t></w:r></w:p>"
}
function Table([object[]]$Rows) {
    $xml = '<w:tbl><w:tblPr><w:tblW w:w="0" w:type="auto"/><w:tblBorders><w:top w:val="single" w:sz="8"/><w:left w:val="single" w:sz="8"/><w:bottom w:val="single" w:sz="8"/><w:right w:val="single" w:sz="8"/><w:insideH w:val="single" w:sz="4"/><w:insideV w:val="single" w:sz="4"/></w:tblBorders></w:tblPr>'
    foreach ($row in $Rows) {
        $xml += '<w:tr>'
        foreach ($cell in $row) { $xml += "<w:tc><w:tcPr><w:tcW w:w=`"4500`" w:type=`"dxa`"/></w:tcPr><w:p><w:r><w:t xml:space=`"preserve`">$(Escape-Xml $cell)</w:t></w:r></w:p></w:tc>" }
        $xml += '</w:tr>'
    }
    return $xml + '</w:tbl>'
}
function Placeholder([string]$Caption) {
    return "<w:tbl><w:tblPr><w:tblW w:w=`"0`" w:type=`"auto`"/><w:tblBorders><w:top w:val=`"single`" w:sz=`"12`"/><w:left w:val=`"single`" w:sz=`"12`"/><w:bottom w:val=`"single`" w:sz=`"12`"/><w:right w:val=`"single`" w:sz=`"12`"/></w:tblBorders></w:tblPr><w:tr><w:trPr><w:trHeight w:val=`"3000`" w:hRule=`"atLeast`"/></w:trPr><w:tc><w:tcPr><w:vAlign w:val=`"center`"/></w:tcPr><w:p><w:pPr><w:jc w:val=`"center`"/></w:pPr><w:r><w:rPr><w:b/></w:rPr><w:t>$(Escape-Xml $Caption)</w:t></w:r></w:p><w:p><w:pPr><w:jc w:val=`"center`"/></w:pPr><w:r><w:t>[Paste your Cloudera VM screenshot here]</w:t></w:r></w:p></w:tc></w:tr></w:tbl>"
}

$body = ''
$body += P 'CYBERSECURITY AUTHENTICATION LOG ANALYSIS' 'Title' -Center
$body += P 'Java Hadoop MapReduce Mini Project' 'Subtitle' -Center
$body += P '' 'Normal'
$body += Table @(
    @('Subject', 'Big Data Analytics'),
    @('Project title', 'Cybersecurity Authentication Log Analysis Using Hadoop MapReduce'),
    @('Technology', 'Java, Apache Hadoop MapReduce, HDFS'),
    @('Dataset', 'cybersecurity_auth_logs_5000.csv'),
    @('Student name', '[Enter your name]'),
    @('Enrollment number', '[Enter your enrollment number]'),
    @('College / Class', '[Enter college, course, semester and division]'),
    @('Guide / Faculty', '[Enter faculty name]')
)
$body += P '' 'Normal'
$body += P 'Submitted in partial fulfilment of the requirements of the Big Data Analytics mini project.' 'Normal' -Center
$body += P 'Academic Year: [Enter academic year]' 'Normal' -Center

$body += P '1. Introduction' 'Heading1' -PageBreak
$body += P 'Authentication logs record attempts to access a system. Repeated failed logins from the same source address can be a useful signal for security review. This mini project processes a synthetic authentication-log dataset using Java Hadoop MapReduce and HDFS. It counts failed login events by source IP address and by hour of day, then produces a configurable threshold-based review report.'
$body += P 'The project is designed for educational analysis. A flagged address is a candidate for review, not proof that an attack occurred. The dataset contains synthetic events and controlled repeated failures.'
$body += P 'Objectives' 'Heading2'
foreach ($x in @('Store the CSV authentication log in HDFS.','Ignore the CSV header and safely skip malformed records.','Calculate failed-login totals for each source IP address.','Calculate failed-login totals for each hour of day.','Flag IP addresses whose failed-login count is greater than or equal to a configurable threshold.','Validate the aggregation results with a small manually verifiable test dataset.')) { $body += Bullet $x }

$body += P '2. Dataset Information' 'Heading1'
$body += P 'The supplied file is cybersecurity_auth_logs_5000.csv. Only a description and sample records are shown here; the complete dataset is intentionally not reproduced in this report.'
$body += Table @(
    @('Property', 'Observed value'),
    @('Number of data records', '5,000 (excluding header)'),
    @('Schema', 'timestamp, source_ip, user_id, status'),
    @('Timestamp format', 'yyyy-MM-dd HH:mm:ss'),
    @('Status values', 'SUCCESS and FAILED'),
    @('FAILED records', '1,140'),
    @('SUCCESS records', '3,860'),
    @('Distinct source IP addresses', '121'),
    @('Nature of data', 'Synthetic; for testing and educational use')
)
$body += P 'Column Description' 'Heading2'
$body += Table @(
    @('Column', 'Meaning'),
    @('timestamp', 'Date and time at which the authentication event occurred.'),
    @('source_ip', 'Network source address that initiated the login attempt.'),
    @('user_id', 'User identifier associated with the event.'),
    @('status', 'Authentication result: SUCCESS or FAILED.')
)
$body += P 'Sample records (not the complete dataset)' 'Heading2'
foreach ($x in @('timestamp,source_ip,user_id,status','2026-10-04 18:42:59,192.168.1.196,user081,SUCCESS','2026-10-03 13:04:05,192.168.10.42,user002,FAILED','2026-10-02 12:46:56,192.168.7.25,user243,SUCCESS')) { $body += Code $x }

$body += P '3. Working Flow and Architecture' 'Heading1' -PageBreak
$body += P 'The input CSV is uploaded to HDFS. Hadoop divides the input into splits and sends records to mapper tasks. The mapper parses each record. If the record is valid and its status is FAILED, it emits a key and the value 1. Hadoop shuffle and sort groups the values for identical keys. The reducer adds the values and writes the total back to HDFS.'
$body += P 'Processing Flow' 'Heading2'
foreach ($x in @('Local CSV file -> HDFS input directory','IP job mapper: FAILED record -> (source_ip, 1)','Hourly job mapper: FAILED record -> (hour, 1)','Shuffle and Sort: groups all equal keys together','Reducer: adds all 1 values for each key','HDFS output: IP counts and hourly counts','ThresholdReport: reads IP counts and labels each IP FLAGGED or NOT_FLAGGED')) { $body += Code $x }
$body += P 'MapReduce Components' 'Heading2'
$body += Table @(
    @('Component', 'Role in this project'),
    @('HDFS', 'Stores the input CSV and MapReduce output files.'),
    @('Mapper', 'Filters failed records and emits a key/value pair for each failure.'),
    @('Shuffle and Sort', 'Groups values with the same IP or hour key.'),
    @('Reducer', 'Sums grouped values to produce final counts.'),
    @('ThresholdReport', 'Reads the distributed IP aggregation and creates a TSV review report.')
)
$body += P 'Algorithm and threshold logic' 'Heading2'
foreach ($x in @('Read each line from the CSV file.','Skip the header, blank lines, malformed records, invalid timestamps, and unknown status values.','If status is FAILED, emit (source_ip, 1) for the IP job and (hour, 1) for the hourly job.','For every grouped key, sum the received integer values.','For each IP total, set flag_status to FLAGGED when count is at least the threshold; otherwise set it to NOT_FLAGGED.')) { $body += Bullet $x }
$body += P 'The hourly output is an hour-of-day summary (00 to 23) across all dates. It is not a chronological timeline.'

$body += P '4. Implementation' 'Heading1' -PageBreak
$body += P 'The application uses Hadoop 2.x compatible Java MapReduce APIs. The parser centralizes validation so all jobs treat records consistently. The mandatory jobs are IP-wise and hourly failed-login analysis. User-wise analysis is an optional additional job.'
$body += P 'Execution summary' 'Heading2'
foreach ($x in @('Compile Java files with Hadoop libraries using hadoop classpath.','Create cyberlog-analysis.jar from compiled classes.','Upload cybersecurity_auth_logs_5000.csv to HDFS.','Run IpFailedLoginJob and HourlyFailedLoginJob with distinct output directories.','Run ThresholdReport with the desired threshold, for example 5.','Read results using hdfs dfs -cat and save screenshots for evidence.')) { $body += Bullet $x }

$sourceFiles = @('AuthLogParser.java','IpFailedLoginJob.java','HourlyFailedLoginJob.java','ThresholdReport.java','UserFailedLoginJob.java')
foreach ($file in $sourceFiles) {
    $body += P ("4." + ([array]::IndexOf($sourceFiles, $file) + 1) + " " + $file) 'Heading2'
    $path = Join-Path $ProjectRoot ("src/edu/college/cyberlog/" + $file)
    Get-Content $path | ForEach-Object { $body += Code $_ }
}

$body += P '5. Commands Used for Execution' 'Heading1' -PageBreak
foreach ($x in @(
    'javac -classpath "$(hadoop classpath)" -d build/classes $(find src -name ''*.java'')',
    'jar cvf dist/cyberlog-analysis.jar -C build/classes .',
    'hdfs dfs -mkdir -p /user/$USER/cyberlog/input',
    'hdfs dfs -put -f data/cybersecurity_auth_logs_5000.csv /user/$USER/cyberlog/input/',
    'hadoop jar dist/cyberlog-analysis.jar edu.college.cyberlog.IpFailedLoginJob /user/$USER/cyberlog/input/cybersecurity_auth_logs_5000.csv /user/$USER/cyberlog/output/ip-counts-run1',
    'hadoop jar dist/cyberlog-analysis.jar edu.college.cyberlog.HourlyFailedLoginJob /user/$USER/cyberlog/input/cybersecurity_auth_logs_5000.csv /user/$USER/cyberlog/output/hourly-counts-run1',
    'hadoop jar dist/cyberlog-analysis.jar edu.college.cyberlog.ThresholdReport /user/$USER/cyberlog/output/ip-counts-run1 /user/$USER/cyberlog/output/ip-review-threshold-5.tsv 5'
)) { $body += Code $x }

$body += P '6. Results and Output Screenshots' 'Heading1' -PageBreak
$body += P 'Expected validation result: the total from IP-wise counts and the total from hourly counts must each equal 1,140, the number of valid FAILED records in the full dataset.'
$body += P 'Screenshot 1: HDFS input upload and file verification' 'Heading2'
$body += Placeholder 'SCREENSHOT PLACEHOLDER - HDFS input directory / hdfs dfs -ls output'
$body += P 'Screenshot 2: IP-wise failed-login count output' 'Heading2'
$body += Placeholder 'SCREENSHOT PLACEHOLDER - IpFailedLoginJob output (part-r-00000)'
$body += P 'Screenshot 3: Hourly failed-login count output' 'Heading2'
$body += Placeholder 'SCREENSHOT PLACEHOLDER - HourlyFailedLoginJob output (part-r-00000)'
$body += P 'Screenshot 4: Threshold-based review report' 'Heading2'
$body += Placeholder 'SCREENSHOT PLACEHOLDER - ThresholdReport output showing FLAGGED / NOT_FLAGGED'

$body += P '7. Testing and Validation' 'Heading1' -PageBreak
$body += Table @(
    @('Test case', 'Expected result'),
    @('Successful login', 'Does not increase failed-login counts.'),
    @('One failed login', 'Adds one to the correct source-IP and hour totals.'),
    @('Repeated failures', 'Reducer aggregates all values for the same key.'),
    @('Four failed events', 'IP is NOT_FLAGGED when threshold is 5.'),
    @('Exactly five failed events', 'IP is FLAGGED when threshold is 5.'),
    @('Malformed row', 'Safely ignored; job continues running.'),
    @('Full dataset', 'IP and hourly totals each sum to 1,140.')
)
$body += P 'A separate small fixture was used: one IP has five failures, another has four failures, one record is successful, and one row is malformed. This makes expected results easy to check manually.'

$body += P '8. Conclusion and Future Scope' 'Heading1'
$body += P 'The project successfully demonstrates distributed batch analysis of authentication logs using Java Hadoop MapReduce. It stores input and output in HDFS, filters failed events, aggregates failures by IP and hour, and produces a configurable review report. The measured full-dataset aggregates account for all 1,140 valid FAILED records.'
$body += P 'Limitations and future improvements' 'Heading2'
foreach ($x in @('A high failure count is only an indicator for review, not proof of an attack.','The parser is deliberately simple because the supplied dataset has no quoted CSV fields.','Future versions can add time-window correlation, geolocation or threat-intelligence enrichment, malformed-record counters, analyst alerts, and a production CSV parser.')) { $body += Bullet $x }

$styles = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="22"/></w:rPr></w:rPrDefault></w:docDefaults><w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:qFormat/></w:style><w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:rPr><w:b/><w:sz w:val="38"/><w:color w:val="1F4E78"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Subtitle"><w:name w:val="Subtitle"/><w:rPr><w:sz w:val="26"/><w:color w:val="5B9BD5"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="Heading 1"/><w:basedOn w:val="Normal"/><w:rPr><w:b/><w:sz w:val="30"/><w:color w:val="1F4E78"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="Heading 2"/><w:basedOn w:val="Normal"/><w:rPr><w:b/><w:sz w:val="25"/><w:color w:val="2F75B5"/></w:rPr></w:style></w:styles>
'@
$document = "<?xml version=`"1.0`" encoding=`"UTF-8`" standalone=`"yes`"?><w:document xmlns:w=`"http://schemas.openxmlformats.org/wordprocessingml/2006/main`"><w:body>$body<w:sectPr><w:pgSz w:w=`"12240`" w:h=`"15840`"/><w:pgMar w:top=`"1440`" w:right=`"1440`" w:bottom=`"1440`" w:left=`"1440`"/></w:sectPr></w:body></w:document>"
$contentTypes = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/><Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/><Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/></Types>'
$rels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/><Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/></Relationships>'
$docRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>'
$core = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><dc:title>Cybersecurity Authentication Log Analysis</dc:title><dc:creator>Student</dc:creator><dc:subject>Java Hadoop MapReduce Mini Project</dc:subject></cp:coreProperties>'
$app = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"><Application>Microsoft Office Word</Application></Properties>'

$temp = Join-Path ([System.IO.Path]::GetTempPath()) ('cyberlog-docx-' + [Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path "$temp/_rels", "$temp/word/_rels", "$temp/docProps" -Force | Out-Null
[System.IO.File]::WriteAllText("$temp/[Content_Types].xml", $contentTypes, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText("$temp/_rels/.rels", $rels, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText("$temp/word/document.xml", $document, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText("$temp/word/styles.xml", $styles, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText("$temp/word/_rels/document.xml.rels", $docRels, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText("$temp/docProps/core.xml", $core, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText("$temp/docProps/app.xml", $app, [System.Text.Encoding]::UTF8)
if (Test-Path $OutputPath) { Remove-Item -LiteralPath $OutputPath -Force }
[System.IO.Compression.ZipFile]::CreateFromDirectory($temp, $OutputPath)
Remove-Item -LiteralPath $temp -Recurse -Force
Write-Output "Created: $OutputPath"
