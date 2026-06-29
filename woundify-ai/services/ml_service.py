import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import KFold, cross_val_score, train_test_split
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, confusion_matrix, roc_curve, auc
from sklearn.preprocessing import LabelEncoder
from typing import Dict, List, Tuple, Any, Optional

# Define the reference bacterial profiles (knowledge base), matching the
# 12-test panel actually run in the lab: Gram, MacConkey, H2S (SSA), EMB,
# NAS, Indole, Motil, Citrate, Urease, VP, MR, TSI.
# emb is ordinal: 0=Colorless, 1=Merah Muda (pink), 2=Hijau Metalik (green sheen)
# tsi is ordinal: 0=Acid/Acid+Gas-H2S(-), 1=Acid/Acid no gas H2S(-),
#                 2=Acid/Alkali H2S(+) [classic Proteus], 3=Alkali/Alkali (non-fermenter)
BACTERIA_PROFILES = [
    {"name": "Staphylococcus aureus", "gram_stain": 1, "is_coccus": 1, "indole": 0, "mr": 1, "vp": 1, "citrate": 0, "h2s": 0, "motil": 0, "urease": 1, "macconkey": 0, "emb": 0, "tsi": 3, "nas": 1, "risk": "HIGH", "biofilm": "HIGH"},
    {"name": "Streptococcus pyogenes", "gram_stain": 1, "is_coccus": 1, "indole": 0, "mr": 1, "vp": 0, "citrate": 0, "h2s": 0, "motil": 0, "urease": 0, "macconkey": 0, "emb": 0, "tsi": 3, "nas": 0, "risk": "MEDIUM", "biofilm": "MEDIUM"},
    {"name": "Enterococcus faecalis", "gram_stain": 1, "is_coccus": 1, "indole": 0, "mr": 1, "vp": 1, "citrate": 0, "h2s": 0, "motil": 0, "urease": 0, "macconkey": 0, "emb": 0, "tsi": 3, "nas": 1, "risk": "MEDIUM", "biofilm": "MEDIUM"},
    {"name": "Escherichia coli", "gram_stain": 0, "is_coccus": 0, "indole": 1, "mr": 1, "vp": 0, "citrate": 0, "h2s": 0, "motil": 1, "urease": 0, "macconkey": 1, "emb": 2, "tsi": 0, "nas": 0, "risk": "MEDIUM", "biofilm": "LOW"},
    {"name": "Pseudomonas aeruginosa", "gram_stain": 0, "is_coccus": 0, "indole": 0, "mr": 0, "vp": 0, "citrate": 1, "h2s": 0, "motil": 1, "urease": 0, "macconkey": 0, "emb": 0, "tsi": 3, "nas": 1, "risk": "HIGH", "biofilm": "HIGH"},
    {"name": "Klebsiella pneumoniae", "gram_stain": 0, "is_coccus": 0, "indole": 0, "mr": 0, "vp": 1, "citrate": 1, "h2s": 0, "motil": 0, "urease": 1, "macconkey": 1, "emb": 1, "tsi": 0, "nas": 0, "risk": "HIGH", "biofilm": "HIGH"},
    {"name": "Proteus mirabilis", "gram_stain": 0, "is_coccus": 0, "indole": 0, "mr": 1, "vp": 0, "citrate": 1, "h2s": 1, "motil": 1, "urease": 1, "macconkey": 0, "emb": 0, "tsi": 2, "nas": 0, "risk": "MEDIUM", "biofilm": "MEDIUM"}
]

FEATURE_NAMES = ["gram_stain", "is_coccus", "indole", "mr", "vp", "citrate", "h2s", "motil", "urease", "macconkey", "emb", "tsi", "nas"]
FEATURE_MAX_VALUES = {"emb": 2, "tsi": 3}  # ordinal (non-binary) features

FEATURE_LABELS = {
    "gram_stain": {1: "Gram positif", 0: "Gram negatif"},
    "is_coccus": {1: "Bentuk kokus", 0: "Bentuk basil"},
    "indole": {1: "Indol positif", 0: "Indol negatif"},
    "mr": {1: "Methyl Red positif", 0: "Methyl Red negatif"},
    "vp": {1: "Voges-Proskauer positif", 0: "Voges-Proskauer negatif"},
    "citrate": {1: "Sitrat positif", 0: "Sitrat negatif"},
    "h2s": {1: "H2S positif", 0: "H2S negatif"},
    "motil": {1: "Motilitas positif", 0: "Motilitas negatif"},
    "urease": {1: "Urease positif", 0: "Urease negatif"},
    "macconkey": {1: "Lactose fermenter (MacConkey)", 0: "Non-lactose fermenter (MacConkey)"},
    "emb": {0: "EMB: koloni colorless", 1: "EMB: koloni merah muda", 2: "EMB: hijau metalik (green sheen)"},
    "tsi": {0: "TSI: Acid/Acid, gas (+), H2S (-)", 1: "TSI: Acid/Acid, gas (-), H2S (-)", 2: "TSI: Acid/Alkali, H2S (+)", 3: "TSI: Alkali/Alkali (non-fermenter)"},
    "nas": {1: "NAS: tumbuh baik", 0: "NAS: tidak tumbuh"},
}

LOW_CONFIDENCE_THRESHOLD = 0.5


class WoundifyMlEngine:
    def __init__(self):
        self.model = RandomForestClassifier(n_estimators=50, random_state=42)
        self.label_encoder = LabelEncoder()
        self._generate_and_train()
        
    def _generate_and_train(self):
        # Generate a synthetic clinical dataset with noise (250 entries) based on the reference patterns
        np.random.seed(42)
        data = []
        
        for _ in range(250):
            profile = np.random.choice(BACTERIA_PROFILES)
            # Add noise with a 5% flip rate for IMViC or staining characteristics (to simulate real-world lab errors)
            row = {"bacteria": profile["name"]}
            for feature in FEATURE_NAMES:
                true_value = profile[feature]
                max_value = FEATURE_MAX_VALUES.get(feature, 1)
                if np.random.rand() > 0.05:
                    row[feature] = true_value
                else:
                    # 5% lab-error noise: binary features flip, ordinal features (emb/tsi) shift by one step
                    row[feature] = max_value - true_value if max_value == 1 else min(max_value, true_value + 1)
            data.append(row)
            
        df = pd.DataFrame(data)
        X = df.drop("bacteria", axis=1)
        y = self.label_encoder.fit_transform(df["bacteria"])
        
        self.X_train, self.X_test, self.y_train, self.y_test = train_test_split(
            X, y, test_size=0.2, random_state=42
        )
        self.model.fit(self.X_train, self.y_train)

    def predict_bacteria(self, gram_stain: str, shape: str, indole: str, mr: str, vp: str, citrate: str,
                         h2s: str = "NEGATIVE", motil: str = "NEGATIVE", urease: str = "NEGATIVE",
                         macconkey: str = "NON_LACTOSE_FERMENTER", emb: int = 0, tsi: int = 3,
                         nas: str = "NEGATIVE") -> Dict[str, Any]:
        """
        Predicts bacteria based on lab inputs, with a top-3 differential and
        a human-readable explanation of which inputs drove the prediction.
        """
        # Encode inputs
        feature_values = {
            "gram_stain": 1 if gram_stain == "GRAM_POSITIVE" else 0,
            "is_coccus": 1 if "COCCUS" in shape.upper() else 0,
            "indole": 1 if indole == "POSITIVE" else 0,
            "mr": 1 if mr == "POSITIVE" else 0,
            "vp": 1 if vp == "POSITIVE" else 0,
            "citrate": 1 if citrate == "POSITIVE" else 0,
            "h2s": 1 if h2s == "POSITIVE" else 0,
            "motil": 1 if motil == "POSITIVE" else 0,
            "urease": 1 if urease == "POSITIVE" else 0,
            "macconkey": 1 if macconkey == "LACTOSE_FERMENTER" else 0,
            "emb": max(0, min(2, emb)),
            "tsi": max(0, min(3, tsi)),
            "nas": 1 if nas == "POSITIVE" else 0,
        }

        features = np.array([[feature_values[name] for name in FEATURE_NAMES]])
        probs = self.model.predict_proba(features)[0]
        pred_idx = int(np.argmax(probs))

        predicted_name = self.label_encoder.inverse_transform([pred_idx])[0]
        confidence = float(probs[pred_idx])

        # Top-3 differential diagnosis
        ranked_idx = np.argsort(probs)[::-1][:3]
        differential = [
            {
                "bacteria": self.label_encoder.inverse_transform([idx])[0],
                "probability": float(probs[idx]),
            }
            for idx in ranked_idx
        ]

        # Reasoning: most important features for this model, described with the input's actual value
        importances = self.model.feature_importances_
        top_feature_idx = np.argsort(importances)[::-1][:3]
        reasoning = [
            FEATURE_LABELS[FEATURE_NAMES[idx]][feature_values[FEATURE_NAMES[idx]]]
            for idx in top_feature_idx
        ]

        return {
            "predicted_bacteria": predicted_name,
            "confidence": confidence,
            "differential": differential,
            "reasoning": reasoning,
            "low_confidence": confidence < LOW_CONFIDENCE_THRESHOLD,
        }

    def predict_risks(self, bacteria_name: str, patient_age: int, diabetes_type: str, hba1c: Optional[float] = None) -> Dict[str, str]:
        """
        Predicts clinical risks based on bacterial profile and patient statistics.
        """
        # Find base risk profile
        base_risk = "MEDIUM"
        biofilm_risk = "LOW"
        for profile in BACTERIA_PROFILES:
            if profile["name"] == bacteria_name:
                base_risk = profile["risk"]
                biofilm_risk = profile["biofilm"]
                break
                
        # Risk factors weighting
        hba1c_val = hba1c if hba1c is not None else 7.5
        uncontrolled_diabetes = hba1c_val > 8.0
        elderly = patient_age > 65
        
        # 1. Infection Risk
        if uncontrolled_diabetes and base_risk == "HIGH":
            infection_risk = "HIGH"
        elif base_risk == "HIGH" or uncontrolled_diabetes or elderly:
            infection_risk = "MEDIUM"
        else:
            infection_risk = "LOW"
            
        # 2. Chronic Wound Infection Risk (strongly linked to biofilm formers like S. aureus or Pseudomonas)
        if biofilm_risk == "HIGH" and uncontrolled_diabetes:
            chronic_risk = "HIGH"
        elif biofilm_risk == "HIGH" or biofilm_risk == "MEDIUM":
            chronic_risk = "MEDIUM"
        else:
            chronic_risk = "LOW"
            
        # 3. Complication Risk (Amputation/Sepsis)
        if chronic_risk == "HIGH" and elderly:
            complication_risk = "HIGH"
        elif chronic_risk == "HIGH" or (infection_risk == "HIGH" and uncontrolled_diabetes):
            complication_risk = "MEDIUM"
        else:
            complication_risk = "LOW"
            
        return {
            "infection_risk": infection_risk,
            "chronic_risk": chronic_risk,
            "complication_risk": complication_risk
        }

    def predict_antibiotic_resistance(self, bacteria_name: str) -> Dict[str, Any]:
        """
        Predicts antibiotic resistance trends and supportive recommendations.
        """
        # Basic profiles for common diabetic wound bacteria
        resistance_map = {
            "Staphylococcus aureus": {
                "resistant": ["Penicillin", "Oxacillin", "Erythromycin"],
                "susceptible": ["Vancomycin", "Linezolid", "Ciprofloxacin"],
                "recommendation": "Risk of MRSA. Consider Vancomycin if oxacillin resistant. Keep wound clean, apply silver dressings."
            },
            "Pseudomonas aeruginosa": {
                "resistant": ["Ampicillin", "Ceftriaxone", "Co-trimoxazole"],
                "susceptible": ["Ciprofloxacin", "Gentamicin", "Ceftazidime", "Imipenem"],
                "recommendation": "Highly adaptable gram-negative bacteria. Susceptible to Piperacillin-Tazobactam or Ceftazidime. Debridement is critical."
            },
            "Escherichia coli": {
                "resistant": ["Ampicillin", "Amoxicillin"],
                "susceptible": ["Ceftriaxone", "Gentamicin", "Ciprofloxacin"],
                "recommendation": "Coliform bacilli. Susceptible to 3rd generation cephalosporins. Optimize blood glucose control."
            },
            "Klebsiella pneumoniae": {
                "resistant": ["Ampicillin", "Carbenicillin"],
                "susceptible": ["Meropenem", "Amikacin", "Levofloxacin"],
                "recommendation": "High risk of ESBL production. Prefer Carbapenems if ESBL-positive. Hydration and systemic review."
            }
        }
        
        default = {
            "resistant": ["Ampicillin"],
            "susceptible": ["Ciprofloxacin", "Ceftriaxone"],
            "recommendation": "Broad spectrum antibiotics suggested. Tailor treatment upon detailed lab antibiogram receipt."
        }
        
        return resistance_map.get(bacteria_name, default)

    def evaluate_model_performance(self) -> Dict[str, Any]:
        """
        Runs internal K-Fold evaluation and calculates metrics on test splits.
        """
        y_pred = self.model.predict(self.X_test)
        y_prob = self.model.predict_proba(self.X_test)
        
        # Standard metrics
        acc = accuracy_score(self.y_test, y_pred)
        prec = precision_score(self.y_test, y_pred, average='weighted', zero_division=0)
        rec = recall_score(self.y_test, y_pred, average='weighted', zero_division=0)
        f1 = f1_score(self.y_test, y_pred, average='weighted', zero_division=0)
        
        # Confusion matrix
        cm = confusion_matrix(self.y_test, y_pred)
        labels = self.label_encoder.classes_.tolist()
        
        # K-Fold Cross Validation (5 folds)
        kf = KFold(n_splits=5, shuffle=True, random_state=42)
        X = pd.concat([self.X_train, self.X_test])
        y = np.concatenate([self.y_train, self.y_test])
        cv_scores = cross_val_score(self.model, X, y, cv=kf, scoring='accuracy')
        
        # ROC / AUC metrics (for multi-class, let's return average AUC or simplified one-vs-rest)
        # We calculate the ROC curve for class index 0 (as an example of multi-class ROC representation)
        fpr, tpr, _ = roc_curve(self.y_test == 0, y_prob[:, 0])
        auc_score = auc(fpr, tpr)
        
        return {
            "accuracy": float(acc),
            "precision": float(prec),
            "recall": float(rec),
            "f1_score": float(f1),
            "confusion_matrix": cm.tolist(),
            "classes": labels,
            "k_fold_scores": cv_scores.tolist(),
            "k_fold_mean": float(np.mean(cv_scores)),
            "roc": {
                "fpr": fpr.tolist(),
                "tpr": tpr.tolist(),
                "auc": float(auc_score)
            }
        }

ml_engine = WoundifyMlEngine()
