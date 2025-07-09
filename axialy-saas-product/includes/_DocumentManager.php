<?php
// /app.axiaba.com/includes/DocumentManager.php
// A simple class for managing documents & their versions

require_once __DIR__ . '/db_connection.php'; // or your path to DB
// Optionally: require Auth check if you want all admin logic behind auth

class DocumentManager
{
    private $pdo;

    public function __construct($pdo)
    {
        $this->pdo = $pdo;
    }

    /**
     * Fetch all documents.
     */
    public function getAllDocuments()
    {
        $stmt = $this->pdo->query("
            SELECT d.*, dv.version_number AS active_version_number
            FROM documents d
            LEFT JOIN document_versions dv 
                   ON dv.id = d.active_version_id
            ORDER BY d.created_at DESC
        ");
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Create a new document entry.
     */
    public function createDocument($docKey, $docName)
    {
        $sql = "
            INSERT INTO documents (doc_key, doc_name, created_at)
            VALUES (:doc_key, :doc_name, NOW())
        ";
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute([
            ':doc_key' => $docKey,
            ':doc_name'=> $docName
        ]);
        return $this->pdo->lastInsertId();
    }

    /**
     * Fetch a single document by ID.
     */
    public function getDocumentById($docId)
    {
        $stmt = $this->pdo->prepare("SELECT * FROM documents WHERE id = ?");
        $stmt->execute([$docId]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    /**
     * Update a document's name or doc_key. 
     * (No versions changed here.)
     */
    public function updateDocument($docId, $docKey, $docName)
    {
        $sql = "
            UPDATE documents
            SET doc_key = :doc_key,
                doc_name= :doc_name,
                updated_at = NOW()
            WHERE id = :doc_id
        ";
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute([
            ':doc_key' => $docKey,
            ':doc_name'=> $docName,
            ':doc_id'  => $docId
        ]);
        return $stmt->rowCount();
    }

    /**
     * Delete a document (and all versions).
     */
    public function deleteDocument($docId)
    {
        // Because of ON DELETE CASCADE, removing from documents
        // should remove all versions automatically. 
        $sql = "DELETE FROM documents WHERE id = ?";
        $stmt= $this->pdo->prepare($sql);
        $stmt->execute([$docId]);
        return $stmt->rowCount();
    }

    /**
     * Create a new version for a given document.
     * This does NOT set it active automatically.
     */
    public function createNewVersion($docId, $fileContent, $fileContentFormat)
    {
        // 1) Find the current max version
        $stmtMax = $this->pdo->prepare("
            SELECT MAX(version_number) AS max_ver
            FROM document_versions
            WHERE documents_id = ?
        ");
        $stmtMax->execute([$docId]);
        $maxVer = (int)$stmtMax->fetchColumn();

        $newVersion = $maxVer + 1;

        $sql = "
            INSERT INTO document_versions
            (documents_id, version_number, file_content, file_content_format, created_at)
            VALUES (:docId, :verNum, :content, :format, NOW())
        ";
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute([
            ':docId'   => $docId,
            ':verNum'  => $newVersion,
            ':content' => $fileContent,
            ':format'  => $fileContentFormat
        ]);
        return $this->pdo->lastInsertId();
    }

    /**
     * Get all versions for a document, sorted descending by created_at.
     */
    public function getAllVersions($docId)
    {
        $sql = "
            SELECT dv.*
            FROM document_versions dv
            WHERE dv.documents_id = ?
            ORDER BY dv.created_at DESC
        ";
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute([$docId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Get a single version by its ID.
     */
    public function getVersionById($versionId)
    {
        $stmt = $this->pdo->prepare("SELECT * FROM document_versions WHERE id = ?");
        $stmt->execute([$versionId]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    /**
     * Sets a given version as active for the parent document.
     * - Clears PDF/DOCX from the previously active version
     * - Updates the document's active_version_id
     */
    public function setActiveVersion($docId, $versionId)
    {
        // 1) Find the old active version
        $doc = $this->getDocumentById($docId);
        $oldActiveId = $doc['active_version_id'] ?? null;

        // 2) Update the documents table
        $sql = "
            UPDATE documents
            SET active_version_id = :verId,
                updated_at = NOW()
            WHERE id = :docId
        ";
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute([
            ':verId' => $versionId,
            ':docId' => $docId
        ]);

        // 3) If old active version is different, clear out PDF/DOCX
        if ($oldActiveId && (int)$oldActiveId !== (int)$versionId) {
            $sqlClear = "
                UPDATE document_versions
                SET file_pdf_data  = NULL,
                    file_docx_data = NULL,
                    updated_at = NOW()
                WHERE id = :oldId
            ";
            $stmtClear = $this->pdo->prepare($sqlClear);
            $stmtClear->execute([':oldId' => $oldActiveId]);
        }

        return true;
    }

    /**
     * Optionally generate & store PDF or DOCX for an active version 
     * (Placeholder for actual generation library).
     */
    public function storeFileDataForActiveVersion($versionId, $pdfData, $docxData)
    {
        // Make sure this version is active
        $ver = $this->getVersionById($versionId);
        if (!$ver) {
            throw new \Exception("Version not found.");
        }

        // Check if this version is indeed the active one on its document
        $doc = $this->getDocumentById($ver['documents_id']);
        if ($doc['active_version_id'] != $versionId) {
            throw new \Exception("Cannot store PDF/DOCX for a non-active version. Please set active first.");
        }

        $sql = "
            UPDATE document_versions
            SET file_pdf_data = :pdf,
                file_docx_data= :docx,
                updated_at = NOW()
            WHERE id = :vId
        ";
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute([
            ':pdf'  => $pdfData,
            ':docx' => $docxData,
            ':vId'  => $versionId
        ]);
        return $stmt->rowCount();
    }
}
