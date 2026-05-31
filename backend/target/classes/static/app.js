const api = {
  base: "",
  token: "",
  latestPatientId: null,
  latestLab: null,
};

const summaryCards = document.getElementById("summaryCards");
const patientTable = document.getElementById("patientTable");
const patientSelect = document.getElementById("patientSelect");
const historyList = document.getElementById("historyList");
const analysisResult = document.getElementById("analysisResult");
const loginStatus = document.getElementById("loginStatus");

const loginForm = document.getElementById("loginForm");
const patientForm = document.getElementById("patientForm");
const labForm = document.getElementById("labForm");
const refreshPatients = document.getElementById("refreshPatients");
const runAnalysis = document.getElementById("runAnalysis");

const cardTemplate = (title, value, subtitle) => `
  <div class="metric">
    <span class="muted">${title}</span>
    <strong>${value}</strong>
    <span class="muted">${subtitle}</span>
  </div>
`;

async function request(path, options = {}) {
  const response = await fetch(`${api.base}${path}`, {
    headers: {
      "Content-Type": "application/json",
      ...(api.token ? { Authorization: `Bearer ${api.token}` } : {}),
      ...(options.headers || {}),
    },
    ...options,
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(text || `Request failed with ${response.status}`);
  }

  if (response.status === 204) {
    return null;
  }

  return response.json();
}

function formatDateTime(value) {
  return new Date(value).toLocaleString();
}

async function loadDashboard() {
  const [summary, patients] = await Promise.all([
    request("/api/dashboard/summary"),
    request("/api/patients"),
  ]);

  summaryCards.innerHTML = [
    cardTemplate("Registered Patients", summary.patients, "Active records in registry"),
    cardTemplate("Lab Results", summary.labResults, "Uploaded or recorded samples"),
    cardTemplate("High Risk Cases", summary.highRiskCases, "Signals requiring review"),
    cardTemplate("Top Bacteria", summary.topBacteria, "Most frequent suggested pattern"),
  ].join("");

  patientTable.innerHTML = patients.map((patient) => `
    <tr>
      <td>${patient.fullName}</td>
      <td>${patient.medicalRecordNumber}</td>
      <td>${patient.age}</td>
      <td>${patient.sex}</td>
      <td>${patient.diabetesType}</td>
      <td>${patient.woundStage}</td>
    </tr>
  `).join("");

  patientSelect.innerHTML = patients.map((patient) => `<option value="${patient.id}">${patient.fullName} (${patient.medicalRecordNumber})</option>`).join("");
  api.latestPatientId = patients[0]?.id || null;
  if (api.latestPatientId) {
    patientSelect.value = api.latestPatientId;
    await loadHistory(api.latestPatientId);
  }
}

async function loadHistory(patientId) {
  if (!patientId) {
    historyList.innerHTML = '<div class="muted">No patient selected.</div>';
    return;
  }

  const history = await request(`/api/history/${patientId}`);
  api.latestLab = history[0] || null;

  if (!history.length) {
    historyList.innerHTML = '<div class="muted">No laboratory history yet.</div>';
    return;
  }

  historyList.innerHTML = history.map((item) => `
    <article class="history-item">
      <strong>${item.gramStain}</strong>
      <div class="muted">${item.colonyMorphology}</div>
      <div class="muted">IMViC: I ${item.indole} | MR ${item.methylRed} | VP ${item.vogesProskauer} | C ${item.citrate}</div>
      <div class="muted">${item.cultureResult}</div>
      <div class="muted">${formatDateTime(item.createdAt)}</div>
    </article>
  `).join("");
}

async function runLatestAnalysis() {
  const patientId = patientSelect.value;
  const history = await request(`/api/history/${patientId}`);
  if (!history.length) {
    analysisResult.innerHTML = '<strong>No lab data found.</strong><p class="muted">Save a result first.</p>';
    return;
  }

  const lab = history[0];
  const prediction = await request("/api/ai/analyze", {
    method: "POST",
    body: JSON.stringify({
      gramStain: lab.gramStain,
      colonyMorphology: lab.colonyMorphology,
      indole: lab.indole,
      methylRed: lab.methylRed,
      vogesProskauer: lab.vogesProskauer,
      citrate: lab.citrate,
      cultureResult: lab.cultureResult,
      antibioticSensitivity: lab.antibioticSensitivity,
      woundNotes: "Diabetic wound monitoring case",
    }),
  });

  analysisResult.innerHTML = `
    <strong>Possible bacteria:</strong> ${prediction.possibleBacteria.join(", ")}<br /><br />
    <strong>Infection risk:</strong> ${prediction.infectionRisk}<br />
    <strong>Chronic wound risk:</strong> ${prediction.chronicWoundRisk}<br />
    <strong>Complication risk:</strong> ${prediction.complicationRisk}<br />
    <strong>Antibiotic resistance risk:</strong> ${prediction.antibioticResistanceRisk}<br />
    <strong>Confidence:</strong> ${Math.round(prediction.confidence * 100)}%<br /><br />
    <strong>Recommendation:</strong> ${prediction.recommendation}
  `;
}

loginForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  const username = document.getElementById("loginUsername").value;
  const password = document.getElementById("loginPassword").value;

  try {
    const result = await request("/api/auth/login", {
      method: "POST",
      body: JSON.stringify({ username, password }),
    });
    api.token = result.token;
    loginStatus.textContent = `Signed in as ${result.username}`;
    loginStatus.style.color = "#4cf1c2";
    await loadDashboard();
  } catch (error) {
    loginStatus.textContent = error.message;
    loginStatus.style.color = "#ff7f7f";
  }
});

patientForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  const formData = new FormData(patientForm);
  const payload = Object.fromEntries(formData.entries());
  payload.age = Number(payload.age);

  try {
    await request("/api/patients", {
      method: "POST",
      body: JSON.stringify(payload),
    });
    patientForm.reset();
    await loadDashboard();
  } catch (error) {
    analysisResult.innerHTML = `<strong>Failed to save patient</strong><p class="muted">${error.message}</p>`;
  }
});

labForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  const payload = Object.fromEntries(new FormData(labForm).entries());

  try {
    await request("/api/lab-results", {
      method: "POST",
      body: JSON.stringify(payload),
    });
    await loadDashboard();
    await loadHistory(payload.patientId);
  } catch (error) {
    analysisResult.innerHTML = `<strong>Failed to save lab result</strong><p class="muted">${error.message}</p>`;
  }
});

patientSelect.addEventListener("change", async () => {
  await loadHistory(patientSelect.value);
});

refreshPatients.addEventListener("click", loadDashboard);
runAnalysis.addEventListener("click", runLatestAnalysis);

loadDashboard().catch((error) => {
  analysisResult.innerHTML = `<strong>Unable to load dashboard</strong><p class="muted">${error.message}</p>`;
});
