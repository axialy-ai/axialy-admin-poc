/****************************************************************************
 * /public_html/aii.axiaba.com/js/home/home.js
 *
 * Contains:
 *  1) initializeHomeTab() - The main entry after loading home-tab.html
 *  2) renderAxialyAdviceForm(advice) - Renders the returned Axialy advice
 *  3) The "Yes, create this package!" logic for storing user input, calling AI
 *     for the analysis package header, showing the overlay, and saving the package.
 ****************************************************************************/

/**
 * Called once the user navigates to Home in layout.js. This is triggered
 * after home-tab.html is loaded into #overview-panel.
 */
function initializeHomeTab() {
  console.log("initializeHomeTab() called for Axialy home.");

  // 1) Hook up the "Get Advice" button
  const submitButton = document.getElementById("axialy-submit-button");
  if (!submitButton) {
    console.warn("No 'Get Advice' button found on home tab.");
    return;
  }
  submitButton.addEventListener("click", async function () {
    await handleGetAdvice();
  });
}

/**
 * Called when the user clicks "Get Advice."
 * - Shows a loader
 * - Calls /api/axialy_helper.php
 * - Renders the Axialy advice
 */
async function handleGetAdvice() {
  const userInputEl = document.getElementById("axialy-user-input");
  const loaderEl = document.getElementById("axialy-loader");
  const formEl = document.getElementById("axialy-form-container");
  const createBtnContainer = document.getElementById(
    "home-create-package-btn-container"
  );

  if (!userInputEl || !loaderEl || !formEl || !createBtnContainer) {
    console.error(
      "Missing some DOM elements for user input, loader, form container, or create-btn container."
    );
    return;
  }

  const userText = userInputEl.value.trim();
  if (!userText) {
    alert("Please enter some text before pressing 'Get Advice'.");
    return;
  }

  // Clear previous content
  formEl.innerHTML = "";
  formEl.style.display = "none";
  // Hide the create-package button
  createBtnContainer.style.display = "none";

  // Show the loader
  loaderEl.style.display = "inline";

  // Prepare the request
  const requestBody = {
    text: userText,
    template: "Axialy/Axialy_Intro_1"
  };
  const apiKey = window.AxiaBAConfig?.api_key || "";
  const baseUrl = window.AxiaBAConfig?.api_base_url || "https://api.axiaba.com";
  const endpoint = baseUrl + "/axialy_helper.php";

  try {
    const res = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-API-Key": apiKey
      },
      body: JSON.stringify(requestBody)
    });

    // Hide loader once we get a response (even if error)
    loaderEl.style.display = "none";

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

    // Render the Axialy advice
    formEl.innerHTML = renderAxialyAdviceForm(advice);
    formEl.style.display = "block";

    // Now show the "Yes, create this package!" button + wire up
    createBtnContainer.style.display = "block";
    const createBtn = document.getElementById("yes-create-package-btn");
    if (createBtn) {
      // If user clicks => create the analysis package
      createBtn.onclick = function () {
        createPackageFromAxialyAdvice(advice);
      };
    }
  } catch (err) {
    loaderEl.style.display = "none";
    console.error("Failed to fetch Axialy advisement:", err);
    alert("Error: " + err.message);
  }
}

/**
 * Builds a read-only "form-like" HTML layout for the given axialy_advice object.
 * This is the same approach as previously in home-tab.js (renderAxialyAdviceForm).
 */
function renderAxialyAdviceForm(advice) {
  const {
    recap_text,
    advisement_text,
    focus_areas,
    stakeholders_focus_area,
    summary_text,
    next_step_text
  } = advice;

  let html = '<div class="axialy-form-title" style="font-weight:bold;margin-bottom:8px;">Axialy Advisement</div>';

  // Recap
  if (recap_text) {
    html += `
      <div class="axialy-form-section">
        <label>Recap:</label>
        <div>${escapeHtml(recap_text)}</div>
      </div>`;
  }

  // Advisement
  if (advisement_text) {
    html += `
      <div class="axialy-form-section" style="margin-top:1rem;">
        <label>Advisement:</label>
        <div>${escapeHtml(advisement_text)}</div>
      </div>`;
  }

  // Focus Areas (array)
  if (Array.isArray(focus_areas) && focus_areas.length > 0) {
    html += `<div class="axialy-form-section" style="margin-top:1rem;"><label>Focus Areas:</label>`;
    focus_areas.forEach((fa, i) => {
      html += `
        <div style="margin:0.75rem 0;padding:0.5rem;border:1px solid #ccc;border-radius:4px;">
          <strong>Focus Area ${i + 1}: ${escapeHtml(fa.focus_area_name || "")}</strong><br>
          <div style="margin-top:0.5rem;"><em>${escapeHtml(fa.focus_area_value || "")}</em></div>
          <div style="margin-top:0.5rem;">
            <label>Collaboration Approach:</label><br>
            ${escapeHtml(fa.focus_area_collaboration_approach || "")}
          </div>
          ${renderStakeholderSubform(fa.focus_area_stakeholders || [])}
        </div>
      `;
    });
    html += `</div>`;
  }

  // Stakeholders Focus Area
  if (stakeholders_focus_area) {
    const {
      focus_area_name,
      focus_area_value,
      focus_area_collaboration_approach,
      analysis_package_stakeholders
    } = stakeholders_focus_area;
    html += `
      <div class="axialy-form-section" style="margin-top:1rem;">
        <label>${escapeHtml(focus_area_name || "Analysis Package Stakeholders")}</label>
        <div><em>${escapeHtml(focus_area_value || "")}</em></div>
        <div style="margin-top:0.5rem;">
          <label>Collaboration Approach:</label><br>
          ${escapeHtml(focus_area_collaboration_approach || "")}
        </div>
    `;
    if (Array.isArray(analysis_package_stakeholders) && analysis_package_stakeholders.length > 0) {
      html += `
        <div style="margin-top:1rem;">
          <label>Stakeholders:</label>
          <table class="axialy-stakeholder-table" style="width:100%;border-collapse:collapse;">
            <thead>
              <tr>
                <th>Email</th>
                <th>Identity</th>
                <th>Persona</th>
                <th>Codename</th>
                <th>Analysis Context</th>
              </tr>
            </thead>
            <tbody>
      `;
      analysis_package_stakeholders.forEach(st => {
        html += `
          <tr>
            <td>${escapeHtml(st.Email || "")}</td>
            <td>${escapeHtml(st.Identity || "")}</td>
            <td>${escapeHtml(st.Persona || "")}</td>
            <td>${escapeHtml(st.Codename || "")}</td>
            <td>${escapeHtml(st["Analysis Context"] || "")}</td>
          </tr>
        `;
      });
      html += `</tbody></table></div>`;
    }
    html += `</div>`;
  }

  // Summary
  if (summary_text) {
    html += `
      <div class="axialy-form-section" style="margin-top:1rem;">
        <label>Summary:</label>
        <div>${escapeHtml(summary_text)}</div>
      </div>`;
  }

  // Next Step
  if (next_step_text) {
    html += `
      <div class="axialy-form-section" style="margin-top:1rem;">
        <label>Next Step:</label>
        <div>${escapeHtml(next_step_text)}</div>
      </div>`;
  }

  return html;
}

/**
 * Renders a sub-form for an array of "focus_area_stakeholders".
 */
function renderStakeholderSubform(stakeholdersArray) {
  if (!Array.isArray(stakeholdersArray) || stakeholdersArray.length === 0) {
    return "";
  }
  let html = `
    <div style="margin-top:1rem;">
      <label>Stakeholders:</label>
      <table class="axialy-stakeholder-table" style="width:100%;border-collapse:collapse;">
        <thead>
          <tr>
            <th>Persona</th>
            <th>Identity</th>
            <th>Context</th>
          </tr>
        </thead>
        <tbody>
  `;
  stakeholdersArray.forEach(s => {
    html += `
      <tr>
        <td>${escapeHtml(s.stakeholder_persona || "")}</td>
        <td>${escapeHtml(s.stakeholder_identity || "")}</td>
        <td>${escapeHtml(s.stakeholdr_context || "")}</td>
      </tr>
    `;
  });
  html += `</tbody></table></div>`;
  return html;
}

/**
 * Simple HTML escaping to prevent XSS.
 */
function escapeHtml(str = "") {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

/****************************************************************************
 *  “Yes, create this package!” button flow
 *  Steps:
 *    1. Store user Axialy input -> /store_summary.php -> get input_text_summaries_id
 *    2. /ai_helper.php with "Analysis_Package_Header" -> gather header data
 *    3. Show "Review Analysis Package Summary" overlay
 *    4. On "Save Now", call /save_analysis_package.php with focus area data
 ****************************************************************************/
async function createPackageFromAxialyAdvice(axialyAdvice) {
  try {
    const userInputEl = document.getElementById("axialy-user-input");
    if (!userInputEl) {
      throw new Error("Unable to find #axialy-user-input.");
    }
    const rawUserInput = userInputEl.value.trim();
    if (!rawUserInput) {
      alert("No user input found to store.");
      return;
    }

    // 1) Store user input in input_text_summaries
    const summaryPayload = {
      input_text_title: "Axialy Input (Home Tab)",
      input_text_summary: "Auto-saved from Home Tab",
      input_text: rawUserInput,
      api_utc: new Date().toISOString().replace("T", " ").substring(0, 19)
    };
    const res1 = await fetch("/store_summary.php", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(summaryPayload)
    });
    if (!res1.ok) {
      throw new Error(`store_summary failed: ${res1.status} - ${res1.statusText}`);
    }
    const data1 = await res1.json();
    if (data1.status !== "success") {
      throw new Error("Failed to store summary: " + data1.message);
    }
    // Remember the ID
    window.inputTextSummariesId = Array.isArray(data1.input_text_summaries_ids)
      ? data1.input_text_summaries_ids[0]
      : data1.input_text_summaries_ids;

    // 2) Call /api/ai_helper.php with Analysis_Package_Header + axialyAdvice
    OverlayModule.showLoadingOverlay("Requesting Analysis Package Header...");
    const apHeaderBody = {
      text: JSON.stringify(axialyAdvice),
      template: "Analysis_Package_Header"
    };
    const apiKey = window.AxiaBAConfig?.api_key || "";
    const baseUrl = window.AxiaBAConfig?.api_base_url || "https://api.axiaba.com";
    const endpoint = baseUrl + "/ai_helper.php";

    const res2 = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-API-Key": apiKey
      },
      body: JSON.stringify(apHeaderBody)
    });
    if (!res2.ok) {
      OverlayModule.hideOverlay();
      throw new Error(`AI helper error: ${res2.status} - ${res2.statusText}`);
    }
    const data2 = await res2.json();
    OverlayModule.hideOverlay();

    if (data2.status !== "success" || !data2.data || !data2.data["Analysis Package Header"]) {
      throw new Error("AI returned invalid package header. " + data2.message);
    }
    const headerObject = data2.data["Analysis Package Header"][0] || {};

    // 3) Show "Review Analysis Package Summary" overlay
    OverlayModule.showHeaderReviewOverlay(
      headerObject,
      // onSave
      async (updatedHeader) => {
        OverlayModule.showLoadingMask("Creating analysis package...");
        try {
          // 4) Actually create the analysis package in save_analysis_package.php
          const collectedData = buildFocusAreaData(axialyAdvice);
          const payload = {
            headerData: updatedHeader,
            collectedData: collectedData,
            input_text_summaries_id: window.inputTextSummariesId
          };

          const res3 = await fetch("/save_analysis_package.php", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(payload)
          });
          const data3 = await res3.json();
          if (data3.status !== "success") {
            throw new Error("Failed to save analysis package: " + data3.message);
          }

          // All good
          const successMsg = `Analysis Package saved (ID ${data3.analysis_package_headers_id}): ${data3.package_name}`;
          OverlayModule.showMessageOverlay(successMsg, function () {
            OverlayModule.hideOverlay();
            // Optionally clear out UI, etc.
            clearHomeTabInputs();
          });
        } catch (err) {
          alert("Error creating package: " + err.message);
          OverlayModule.hideOverlay();
        }
      },
      // onCancel
      () => {
        console.log("User canceled package creation from home tab overlay.");
      }
    );
  } catch (err) {
    alert("Error while creating package: " + err.message);
  }
}

/**
 * Helper to convert Axialy advice into the "collectedData" array
 * that save_analysis_package.php expects (like from the Generate tab).
 */
function buildFocusAreaData(axialyAdvice) {
  let collected = [];

  // 1) If there's an array of focus_areas
  if (Array.isArray(axialyAdvice.focus_areas)) {
    axialyAdvice.focus_areas.forEach((fa) => {
      collected.push({
        focus_area_label: fa.focus_area_name || "Unnamed Focus Area",
        input_text_summaries_id: window.inputTextSummariesId,
        properties: {
          focus_area_value: fa.focus_area_value || "",
          collaboration_approach: fa.focus_area_collaboration_approach || ""
        }
      });
    });
  }

  // 2) If there's a "stakeholders_focus_area"
  if (axialyAdvice.stakeholders_focus_area) {
    const sfa = axialyAdvice.stakeholders_focus_area;
    collected.push({
      focus_area_label: sfa.focus_area_name || "Analysis Package Stakeholders",
      input_text_summaries_id: window.inputTextSummariesId,
      properties: {
        focus_area_value: sfa.focus_area_value || "",
        collaboration_approach: sfa.focus_area_collaboration_approach || ""
        // Could also store "analysis_package_stakeholders" array in props if needed
      }
    });
  }

  return collected;
}

/**
 * Clears the user input field, hides the form container & create-btn, etc.
 */
function clearHomeTabInputs() {
  const userInputEl = document.getElementById("axialy-user-input");
  if (userInputEl) {
    userInputEl.value = "";
  }
  const formEl = document.getElementById("axialy-form-container");
  if (formEl) {
    formEl.innerHTML = "";
    formEl.style.display = "none";
  }
  const createBtnContainer = document.getElementById("home-create-package-btn-container");
  if (createBtnContainer) {
    createBtnContainer.style.display = "none";
  }
  window.inputTextSummariesId = null;
}

// Immediately invoke a console log for debugging, if desired:
console.log("home.js loaded: Ready to call initializeHomeTab() after the HTML is inserted.");
