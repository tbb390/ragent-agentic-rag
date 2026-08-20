param(
    [int]$DocumentsPerDomain = 10,
    [string]$OutputDirectory = "resources/test-data/performance"
)

$ErrorActionPreference = "Stop"
$outputRoot = Join-Path (Resolve-Path ".") $OutputDirectory
$documentRoot = Join-Path $outputRoot "documents"
New-Item -ItemType Directory -Force -Path $documentRoot | Out-Null

$domains = @(
    @{ Key = "expense"; Name = "Expense Reimbursement"; Owner = "Finance"; Limit = 5000; Sla = 5 },
    @{ Key = "purchase"; Name = "Procurement"; Owner = "Procurement Office"; Limit = 20000; Sla = 7 },
    @{ Key = "leave"; Name = "Attendance and Leave"; Owner = "Human Resources"; Limit = 3; Sla = 2 },
    @{ Key = "security"; Name = "Information Security"; Owner = "Security Center"; Limit = 2; Sla = 1 },
    @{ Key = "operations"; Name = "System Operations"; Owner = "Platform Engineering"; Limit = 4; Sla = 1 }
)

$questions = [System.Collections.Generic.List[object]]::new()
$documents = [System.Collections.Generic.List[object]]::new()

foreach ($domain in $domains) {
    for ($version = 1; $version -le $DocumentsPerDomain; $version++) {
        $docId = "{0}-policy-{1:d2}" -f $domain.Key, $version
        $fileName = "$docId.md"
        $effectiveMonth = (($version - 1) % 12) + 1
        $approvalLimit = $domain.Limit + ($version * 100)
        $sla = $domain.Sla + ($version % 3)
        $hotline = "400-{0:d3}-{1:d4}" -f (100 + $version), (2000 + $version)
        $content = @"
# $($domain.Name) Policy V$version

## Document metadata

- Document ID: $docId
- Owning department: $($domain.Owner)
- Effective date: 2026-$('{0:d2}' -f $effectiveMonth)-01
- Escalation hotline: $hotline

## Scope

This policy applies to employees, interns, and authorized contractors. Every request must use the applicant's own account. Requests involving customer data, financial data, or production systems must follow the principle of least privilege.

## Approval rules

A request not exceeding $approvalLimit units requires manager approval. A request above this threshold also requires review by $($domain.Owner). The applicant must submit the request within ten business days with contracts, receipts, prior approvals, and a risk statement where applicable.

## Workflow

1. Create a request in the company portal and reference document `$docId`.
2. Upload the business justification, amount breakdown, and supporting files.
3. The direct manager completes the initial review within $sla business days.
4. The system determines additional review based on value, data classification, and resource type.
5. The execution team processes approved requests and publishes status in the portal.

## Service level and escalation

The standard processing time is $sla business days. If the request remains unresolved, call $hotline and provide the request ID. Emergency requests must describe impact, estimated loss, and recovery time. An emergency label alone does not bypass approval.

## Exceptions and audit

Fabricated evidence, unauthorized access, duplicate requests, or splitting a request to avoid approval stops the workflow and notifies $($domain.Owner). The applicant has two business days to respond. Three violations trigger a formal audit.

## Example

A complete request for $($approvalLimit - 50) units can be approved by the direct manager. A request for $($approvalLimit + 50) units requires an additional $($domain.Owner) review and must not be split into smaller requests.
"@
        Set-Content -Path (Join-Path $documentRoot $fileName) -Value $content -Encoding UTF8
        $documents.Add([ordered]@{
            id = $docId
            file = "documents/$fileName"
            domain = $domain.Key
            owner = $domain.Owner
            approvalLimit = $approvalLimit
            slaDays = $sla
        })

        $questions.Add([ordered]@{
            id = "$docId-q1"
            question = "What is the approval threshold in $($domain.Name) Policy V$version?"
            expectedAnswer = "$approvalLimit units"
            expectedDocumentIds = @($docId)
            tags = @($domain.Key, "exact-number")
        })
        $questions.Add([ordered]@{
            id = "$docId-q2"
            question = "How many business days is the standard processing time in $($domain.Name) Policy V$version?"
            expectedAnswer = "$sla business days"
            expectedDocumentIds = @($docId)
            tags = @($domain.Key, "sla")
        })
        $questions.Add([ordered]@{
            id = "$docId-q3"
            question = "Which department owns $docId and what is its escalation hotline?"
            expectedAnswer = "$($domain.Owner), $hotline"
            expectedDocumentIds = @($docId)
            tags = @($domain.Key, "multi-fact")
        })
    }
}

$questions | ForEach-Object { $_ | ConvertTo-Json -Compress -Depth 5 } |
    Set-Content -Path (Join-Path $outputRoot "eval-dataset.jsonl") -Encoding UTF8

$manifest = [ordered]@{
    generatedAt = (Get-Date).ToString("s")
    documentCount = $documents.Count
    questionCount = $questions.Count
    documentsPerDomain = $DocumentsPerDomain
    domains = $domains.Key
    documents = $documents
}
$manifest | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $outputRoot "manifest.json") -Encoding UTF8

Write-Output "Generated $($documents.Count) documents and $($questions.Count) evaluation questions in $outputRoot"
