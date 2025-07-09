


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!DEPRECATED!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!










<?php
// /home/i17z4s936h3j/public_html/app.axiaba.com/view_document.php
require_once __DIR__ . '/includes/db_connection.php';

$docKey = $_GET['doc_key'] ?? 'user_guide';

// 1) Find the doc
$stmt = $pdo->prepare("SELECT * FROM documents WHERE doc_key=? LIMIT 1");
$stmt->execute([$docKey]);
$docRow = $stmt->fetch(PDO::FETCH_ASSOC);
if(!$docRow) {
    die("Document not found: $docKey");
}
// 2) Find the active version
if(!$docRow['active_version_id']){
    die("No active version for '$docKey'.");
}
$stmt2 = $pdo->prepare("SELECT * FROM document_versions WHERE id=?");
$stmt2->execute([$docRow['active_version_id']]);
$verRow = $stmt2->fetch(PDO::FETCH_ASSOC);
if(!$verRow){
    die("Active version record not found.");
}

// 3) Render
$fileFormat = $verRow['file_content_format'];
$fileContent= $verRow['file_content'];

// If format = 'md', you can parse Markdown into HTML
// If format = 'html', just echo it
// etc. For brevity, we do a naive approach for Markdown:
function convertMarkdownToHtml($md){
    // A real library is recommended. We'll do naive:
    return nl2br(htmlspecialchars($md)); 
}

?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8"/>
    <title>Viewing Document: <?php echo htmlspecialchars($docKey); ?></title>
</head>
<body>
<h1><?php echo htmlspecialchars($docRow['doc_name']); ?></h1>
<div>
<?php
switch($fileFormat){
  case 'md':
    echo convertMarkdownToHtml($fileContent);
    break;
  case 'html':
    echo $fileContent; // be sure you trust it or sanitize
    break;
  case 'json':
    echo '<pre>'.htmlspecialchars($fileContent).'</pre>';
    break;
  case 'xml':
    echo '<pre>'.htmlspecialchars($fileContent).'</pre>';
    break;
}
?>
</div>
</body>
</html>
