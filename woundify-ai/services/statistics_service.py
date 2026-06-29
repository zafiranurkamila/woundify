import numpy as np
import pandas as pd
from scipy import stats
from sklearn.linear_model import LogisticRegression
from typing import Dict, List, Tuple, Any

def calculate_descriptive_stats(data: List[float]) -> Dict[str, float]:
    """
    Computes Mean, Median, and Standard Deviation.
    """
    if not data:
        return {"mean": 0.0, "median": 0.0, "std_dev": 0.0, "count": 0}
    arr = np.array(data)
    return {
        "mean": float(np.mean(arr)),
        "median": float(np.median(arr)),
        "std_dev": float(np.std(arr, ddof=1)) if len(arr) > 1 else 0.0,
        "count": len(data)
    }

def calculate_normality_shapiro(data: List[float]) -> Dict[str, Any]:
    """
    Performs Shapiro-Wilk test for normality.
    """
    if len(data) < 3:
        return {"error": "At least 3 data points required for Shapiro-Wilk test."}
    
    stat, p_value = stats.shapiro(data)
    return {
        "w_statistic": float(stat),
        "p_value": float(p_value),
        "is_normal": bool(p_value > 0.05)  # Null hypothesis: data is normally distributed
    }

def calculate_pearson_correlation(x: List[float], y: List[float]) -> Dict[str, Any]:
    """
    Calculates Pearson Correlation Coefficient.
    """
    if len(x) != len(y) or len(x) < 2:
        return {"error": "Inputs must be of equal length and contain at least 2 points."}
        
    r, p_value = stats.pearsonr(x, y)
    return {
        "r_coefficient": float(r),
        "p_value": float(p_value),
        "strength": "strong" if abs(r) > 0.7 else "moderate" if abs(r) > 0.3 else "weak"
    }

def calculate_linear_regression(x: List[float], y: List[float]) -> Dict[str, Any]:
    """
    Fits y = a + bx and returns constants.
    """
    if len(x) != len(y) or len(x) < 2:
        return {"error": "Inputs must be of equal length and contain at least 2 points."}
        
    slope, intercept, r_value, p_value, std_err = stats.linregress(x, y)
    return {
        "a_intercept": float(intercept),
        "b_slope": float(slope),
        "r_squared": float(r_value ** 2),
        "p_value": float(p_value),
        "std_err": float(std_err),
        "formula": f"y = {intercept:.4f} + {slope:.4f} * x"
    }

def calculate_logistic_regression(X: List[List[float]], y: List[int]) -> Dict[str, Any]:
    """
    Fits logistic regression for binary classification.
    """
    if len(X) != len(y) or len(y) < 5:
        return {"error": "At least 5 data points required for logistic regression."}
        
    X_arr = np.array(X)
    y_arr = np.array(y)
    
    # Train model
    model = LogisticRegression()
    model.fit(X_arr, y_arr)
    
    accuracy = float(model.score(X_arr, y_arr))
    coefficients = model.coef_[0].tolist()
    intercept = float(model.intercept_[0])
    
    return {
        "accuracy": accuracy,
        "coefficients": coefficients,
        "intercept": intercept,
        "predictions": model.predict(X_arr).tolist()
    }

def calculate_t_test(group1: List[float], group2: List[float], paired: bool = False) -> Dict[str, Any]:
    """
    Performs t-Test (independent or paired).
    """
    if len(group1) < 2 or len(group2) < 2:
        return {"error": "Both groups must contain at least 2 points."}
        
    if paired:
        if len(group1) != len(group2):
            return {"error": "Groups must be equal size for paired t-Test."}
        stat, p_val = stats.ttest_rel(group1, group2)
    else:
        stat, p_val = stats.ttest_ind(group1, group2, equal_var=False)
        
    return {
        "t_statistic": float(stat),
        "p_value": float(p_val),
        "statistically_significant": bool(p_val < 0.05)
    }

def calculate_cronbach_alpha(matrix: List[List[float]]) -> Dict[str, Any]:
    """
    Computes Cronbach's Alpha for Usability/UAT questionnaire reliability testing.
    Expects a matrix of shape [respondents, questions].
    """
    df = pd.DataFrame(matrix)
    k = df.shape[1]
    if k <= 1:
        return {"error": "Scale must contain more than 1 item.", "alpha": 0.0}
        
    item_vars = df.var(ddof=1)
    total_scores = df.sum(axis=1)
    total_var = total_scores.var(ddof=1)
    
    if total_var == 0:
        return {
            "alpha": 0.0,
            "interpretation": "Invalid: Total variance is 0.",
            "k_items": k
        }
        
    alpha = (k / (k - 1)) * (1 - (item_vars.sum() / total_var))
    
    # Interpretation
    if alpha >= 0.9:
        interpretation = "Excellent internal consistency"
    elif alpha >= 0.8:
        interpretation = "Good internal consistency"
    elif alpha >= 0.7:
        interpretation = "Acceptable internal consistency"
    elif alpha >= 0.6:
        interpretation = "Questionable internal consistency"
    else:
        interpretation = "Poor internal consistency / Unreliable"
        
    return {
        "alpha": float(alpha),
        "interpretation": interpretation,
        "k_items": k,
        "respondents": df.shape[0]
    }

def calculate_pearson_validity(matrix: List[List[float]]) -> Dict[str, Any]:
    """
    Computes product-moment validity (Item-Total Pearson Correlation) for each questionnaire item.
    Matrix: [respondents, questions].
    """
    df = pd.DataFrame(matrix)
    k = df.shape[1]
    total_scores = df.sum(axis=1)
    
    results = []
    r_table_df5_p05 = 0.361 # Standard threshold for 30 degrees of freedom, or rough baseline
    
    for i in range(k):
        item_scores = df.iloc[:, i]
        r_coeff, p_val = stats.pearsonr(item_scores, total_scores)
        
        # Calculate dynamic r-table significance check (rough approximation)
        df_deg = len(item_scores) - 2
        # Let's say if p-val < 0.05, it is statistically valid
        is_valid = bool(p_val < 0.05 and r_coeff > 0.3)
        
        results.append({
            "item_index": i + 1,
            "r_xy": float(r_coeff),
            "p_value": float(p_val),
            "is_valid": is_valid,
            "recommendation": "Retain item" if is_valid else "Revise or remove item"
        })
        
    return {
        "items": results,
        "sample_size": df.shape[0],
        "valid_count": sum(1 for item in results if item["is_valid"]),
        "all_valid": all(item["is_valid"] for item in results)
    }
