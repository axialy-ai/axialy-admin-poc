// /js/refine/axialy.js
var RefineAxialyModule = (function() {

    /**
     * Runs the Axialy analysis on all packages, returning an “axially_advice” object
     * that we display in an overlay. We assume the user currently has no package selected.
     */
    async function runAssessment() {
        try {
            // 1) We need the full array of packages with metrics:
            let packages = RefineStateModule.getAllPackages();
            if (!packages || !Array.isArray(packages) || packages.length === 0) {
                // If not in memory, we fetch them again
                const showDeletedToggle = document.getElementById('show-deleted-toggle');
                const showDeleted = showDeletedToggle && showDeletedToggle.checked;
                packages = await RefineApiModule.fetchPackages("", showDeleted);
            }
            if (!Array.isArray(packages) || packages.length === 0) {
                alert("No packages found to assess.");
                return;
            }

            // 2) Prepare request to our new endpoint
            const baseUrl   = window.AxiaBAConfig?.api_base_url || "https://api.axiaba.com";
            const endpoint  = baseUrl + "/axially_analysis_package_assessor.php";
            const apiKey    = window.AxiaBAConfig?.api_key || "";

            // We'll send the entire array of packages as "analysis_packages"
            const payload = {
                analysis_packages: packages,
                template: "Axialy/Axialy_Assess_Analysis_Packages"
                // optionally can add { metadata:{} } if desired
            };

            RefineUtilsModule.showPageMaskSpinner("Assessing your packages via Axialy...");

            const res = await fetch(endpoint, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-API-Key": apiKey
                },
                body: JSON.stringify(payload)
            });
            RefineUtilsModule.hidePageMaskSpinner();

            if (!res.ok) {
                throw new Error(`Server returned ${res.status} - ${res.statusText}`);
            }
            const data = await res.json();
            if (data.error) {
                throw new Error(data.error);
            }
            const advice = data.axialy_advice;
            if (!advice) {
                throw new Error("No axialy_advice found in server response.");
            }

            // 3) Display the overlay with advice
            renderAxialyAssessment(advice);

        } catch (err) {
            RefineUtilsModule.hidePageMaskSpinner();
            console.error("[RefineAxialyModule] runAssessment() error:", err);
            alert("Error retrieving Axialy assessment: " + err.message);
        }
    }

    /**
     * Renders the returned 'axialy_advice' object in the overlay.
     */
    function renderAxialyAssessment(axialyAdvice) {
        const overlay       = document.getElementById('axially-assessment-overlay');
        const contentArea   = document.getElementById('axially-assessment-content');
        const closeBtn      = document.getElementById('close-axially-assessment-overlay');
        if (!overlay || !contentArea || !closeBtn) {
            alert("Could not locate Axially Assessment overlay elements in the DOM.");
            return;
        }

        // Build HTML
        let html = "";

        if (axialyAdvice.scenario_title) {
            html += `<h3>${escapeHtml(axialyAdvice.scenario_title)}</h3>`;
        }
        if (axialyAdvice.recap_text) {
            html += `<div style="margin-bottom:1em;"><strong>Recap:</strong> ${escapeHtml(axialyAdvice.recap_text)}</div>`;
        }
        if (axialyAdvice.advisement_text) {
            html += `<div style="margin-bottom:1em;"><strong>Advisement:</strong> ${escapeHtml(axialyAdvice.advisement_text)}</div>`;
        }

        if (Array.isArray(axialyAdvice.package_assessments) && axialyAdvice.package_assessments.length > 0) {
            html += `<div style="margin-bottom:1em;"><strong>Package Assessments:</strong></div>`;
            html += `<ul style="padding-left:1.2em;">`;
            axialyAdvice.package_assessments.forEach((pa, idx) => {
                const rank  = escapeHtml(pa.assessment_ranking || "");
                const advic = escapeHtml(pa.assessment_advisement || "");
                html += `<li><em>${rank}</em><br>${advic}</li>`;
            });
            html += `</ul>`;
        }

        if (axialyAdvice.summary_text) {
            html += `<div style="margin-bottom:1em;"><strong>Summary:</strong> ${escapeHtml(axialyAdvice.summary_text)}</div>`;
        }
        if (axialyAdvice.next_step_text) {
            html += `<div style="margin-bottom:1em;"><strong>Next Steps:</strong> ${escapeHtml(axialyAdvice.next_step_text)}</div>`;
        }

        contentArea.innerHTML = html;
        overlay.style.display = 'flex';

        closeBtn.onclick = () => {
            overlay.style.display = 'none';
        };
    }

    // Helper for HTML escape
    function escapeHtml(str) {
        if (!str) return "";
        return str
          .replace(/&/g, "&amp;")
          .replace(/</g, "&lt;")
          .replace(/>/g, "&gt;")
          .replace(/"/g, "&quot;");
    }

    // Expose
    return {
        runAssessment: runAssessment
    };
})();
